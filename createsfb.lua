local createsfb = {}

local log = require("log")
local scratchsfl = require("scratchsfl")

local sflRawDataCache = {}

local sflfoldname = {}
local filelist = {}
local sflpath = {}
local sflbasePath = {}

local function refreshScratchSfl()
    local ok, err = pcall(function()
        scratchsfl.load()
    end)

    if not ok then
        log.error("scratchsfl.load() failed: " .. tostring(err))
        return false
    end

    sflfoldname = scratchsfl.foldname or {}
    filelist = scratchsfl.list or {}
    sflpath = scratchsfl.path or {}
    sflbasePath = scratchsfl.basePath or {}

    log.info(
        "scratchsfl refreshed: songs=" ..
        tostring(#sflfoldname) ..
        ", sfl=" ..
        tostring(#sflpath)
    )

    return true
end

local sflReadThreadCode = [[
local jobs, results = ...

while true do
    local job = jobs:demand()

    if job == false then
        break
    end

    local index = job[1]
    local path = job[2]

    local ok, dataOrErr = pcall(love.filesystem.read, path)

    if ok and type(dataOrErr) == "string" then
        results:push({
            index = index,
            path = path,
            data = dataOrErr,
            error = nil
        })
    else
        results:push({
            index = index,
            path = path,
            data = "",
            error = tostring(dataOrErr)
        })
    end
end
]]

local function getSflReadWorkerCount(songCount)
    if songCount <= 1 then
        return songCount
    end

    local cpuCount = 1

    pcall(function()
        if love.system and love.system.getProcessorCount then
            cpuCount = tonumber(love.system.getProcessorCount()) or 1
        end
    end)

    return math.max(
        1,
        math.min(
            songCount,
            math.max(1, cpuCount - 1),
            8
        )
    )
end

local function preloadSflFilesParallel(paths)
    if type(paths) ~= "table" or #paths == 0 then
        return
    end

    if not love.thread then
        log.warn("Parallel SFL loading unavailable: love.thread is not loaded.")
        return
    end

    local jobs = love.thread.newChannel()
    local results = love.thread.newChannel()

    local workerCount = getSflReadWorkerCount(#paths)
    local threads = {}

    log.info(
        "Parallel SFL loading: " ..
        tostring(#paths) ..
        " file(s), " ..
        tostring(workerCount) ..
        " worker(s)"
    )

    for workerIndex = 1, workerCount do
        local thread = love.thread.newThread(sflReadThreadCode)

        threads[#threads + 1] = thread

        local ok, err = pcall(function()
            thread:start(jobs, results)
        end)

        if not ok then
            log.warn(
                "Failed to start SFL worker " ..
                tostring(workerIndex) ..
                ": " ..
                tostring(err)
            )
        end
    end

    for i = 1, #paths do
        jobs:push({
            i,
            paths[i]
        })
    end

    for _ = 1, workerCount do
        jobs:push(false)
    end

    local completed = 0

    while completed < #paths do
        local result = results:demand()

        if result and result.path then
            completed = completed + 1

            if type(result.data) == "string" then
                sflRawDataCache[result.path] = result.data

                if result.data == "" then
                    log.warn(
                        "Parallel SFL read returned empty data: " ..
                        tostring(result.path)
                    )
                end
            else
                sflRawDataCache[result.path] = ""

                log.warn(
                    "Parallel SFL read failed [" ..
                    tostring(result.index) ..
                    "]: " ..
                    tostring(result.path) ..
                    " (" ..
                    tostring(result.error) ..
                    ")"
                )
            end
        end
    end

    for _, thread in ipairs(threads) do
        pcall(function()
            thread:wait()
        end)
    end

    log.info(
        "Parallel SFL loading completed: " ..
        tostring(completed) ..
        "/" ..
        tostring(#paths)
    )
end

local function getCachedSflData(path)
    if type(path) ~= "string" or path == "" then
        return nil
    end

    local cached = sflRawDataCache[path]

    if type(cached) == "string" then
        return cached
    end

    return nil
end

local function readFile(path)
    if type(path) ~= "string" or path == "" then
        return nil
    end

    local cached = getCachedSflData(path)

    if cached ~= nil and cached ~= "" then
        return cached
    end

    local ok, data = pcall(love.filesystem.read, path)

    if ok and type(data) == "string" then
        return data
    end

    return nil
end

local function sanitizeEntryName(name, fallback)
    local n = tostring(name or fallback or "file")

    n = n:gsub("[\r\n,]", "_")

    if n == "" then
        n = fallback or "file"
    end

    return n
end

local function findFileCaseInsensitive(dirPath, targetName)
    if type(dirPath) ~= "string" or dirPath == "" then
        return nil
    end

    if type(targetName) ~= "string" or targetName == "" then
        return nil
    end

    local ok, items = pcall(
        love.filesystem.getDirectoryItems,
        dirPath
    )

    if not ok or type(items) ~= "table" then
        return nil
    end

    local wanted = string.lower(targetName)

    for _, item in ipairs(items) do
        if string.lower(item) == wanted then
            local candidate = dirPath .. "/" .. item

            if love.filesystem.getInfo(candidate, "file") then
                return candidate, item
            end
        end
    end

    return nil
end

local function findAudioInFolder(songfolder, preferredName)
    if type(songfolder) ~= "string" or songfolder == "" then
        return nil, nil, "invalid_folder"
    end

    if type(preferredName) == "string" and preferredName ~= "" then
        local directPath = songfolder .. "/" .. preferredName

        if love.filesystem.getInfo(directPath, "file") then
            return directPath, preferredName, "meta_exact"
        end

        local ciPath, ciName =
            findFileCaseInsensitive(
                songfolder,
                preferredName
            )

        if ciPath then
            return ciPath, ciName, "meta_case_insensitive"
        end
    end

    local ok, items = pcall(
        love.filesystem.getDirectoryItems,
        songfolder
    )

    if not ok or type(items) ~= "table" then
        return nil, nil, "directory_error"
    end

    table.sort(items)

    for _, item in ipairs(items) do
        local lower = string.lower(item)

        if lower:match("%.wav$")
            or lower:match("%.ogg$")
            or lower:match("%.mp3$") then

            local candidate = songfolder .. "/" .. item

            if love.filesystem.getInfo(candidate, "file") then
                return candidate, item, "folder_scan"
            end
        end
    end

    return nil, nil, "not_found"
end

local function findJacketInFolder(songfolder)
    if type(songfolder) ~= "string" or songfolder == "" then
        return nil, nil
    end

    local candidates = {
        "jacket.png",
        "jacket.jpg",
        "jacket.jpeg"
    }

    for _, item in ipairs(candidates) do
        local path = songfolder .. "/" .. item

        if love.filesystem.getInfo(path, "file") then
            return path, item
        end
    end

    local ok, items = pcall(
        love.filesystem.getDirectoryItems,
        songfolder
    )

    if not ok or type(items) ~= "table" then
        return nil, nil
    end

    table.sort(items)

    for _, item in ipairs(items) do
        local lower = string.lower(item)

        if lower == "jacket.png"
            or lower == "jacket.jpg"
            or lower == "jacket.jpeg" then

            local path = songfolder .. "/" .. item

            if love.filesystem.getInfo(path, "file") then
                return path, item
            end
        end
    end

    return nil, nil
end

local sflmeta = {}
local sfldiff = {}
local sfllevel = {}

local notedata = {
    easy = {},
    normal = {},
    hard = {},
    extra = {},
    custom = {}
}

local chartdata = {}

local starttiming = {
    easy = {
        measure = {},
        bpm = {},
        hs = {},
        scrollmove = {},
        move = {},
        gogostart = {},
        gogoend = {},
        gravity = {}
    },
    normal = {
        measure = {},
        bpm = {},
        hs = {},
        scrollmove = {},
        move = {},
        gogostart = {},
        gogoend = {},
        gravity = {}
    },
    hard = {
        measure = {},
        bpm = {},
        hs = {},
        scrollmove = {},
        move = {},
        gogostart = {},
        gogoend = {},
        gravity = {}
    },
    extra = {
        measure = {},
        bpm = {},
        hs = {},
        scrollmove = {},
        move = {},
        gogostart = {},
        gogoend = {},
        gravity = {}
    },
    custom = {
        measure = {},
        bpm = {},
        hs = {},
        scrollmove = {},
        move = {},
        gogostart = {},
        gogoend = {},
        gravity = {}
    }
}

local measuretime = {
    easy = {},
    normal = {},
    hard = {},
    extra = {},
    custom = {}
}

local diffs = {
    "easy",
    "normal",
    "hard",
    "extra",
    "custom"
}

local function trimString(text)
    if type(text) ~= "string" then
        return text
    end

    return text:gsub("^%s+", ""):gsub("%s+$", "")
end

local function parseDiffHeader(header)
    if type(header) ~= "string" then
        return nil, nil
    end

    header = trimString(header)

    local idxToken
    local levelToken
    local quoteChar
    local escape = false
    local tokenStart = 1
    local tokenCount = 0

    for i = 1, #header do
        local ch = header:sub(i, i)

        if escape then
            escape = false
        elseif quoteChar then
            if ch == "\\" then
                escape = true
            elseif ch == quoteChar then
                quoteChar = nil
            end
        else
            if ch == '"' or ch == "'" then
                quoteChar = ch
            elseif ch == "," then
                tokenCount = tokenCount + 1

                local token =
                    trimString(
                        header:sub(tokenStart, i - 1)
                    )

                if tokenCount == 1 then
                    idxToken = token
                elseif tokenCount == 2 then
                    levelToken = token
                    break
                end

                tokenStart = i + 1
            end
        end
    end

    if tokenCount == 1 then
        levelToken =
            trimString(
                header:sub(tokenStart)
            )
    end

    if not idxToken then
        return nil, nil
    end

    local idx = tonumber(
        trimString(idxToken)
    )

    return idx, levelToken
end

local function parseDiffLevel(diffMeta)
    local _, levelToken =
        parseDiffHeader(diffMeta)

    if not levelToken or levelToken == "" then
        return nil
    end

    return levelToken
end

local function extractSflDiffBlocks(data)
    local blocks = {}

    if type(data) ~= "string" then
        return blocks
    end

    local pos = 1

    while true do
        local startPos, openParen =
            data:find("diff%s*%(", pos)

        if not startPos then
            break
        end

        local headerStart = openParen + 1
        local i = headerStart
        local quoteChar
        local headerEnd

        while i <= #data do
            local ch = data:sub(i, i)

            if quoteChar then
                if ch == "\\" then
                    i = i + 1
                elseif ch == quoteChar then
                    quoteChar = nil
                end
            else
                if ch == '"' or ch == "'" then
                    quoteChar = ch
                elseif ch == ")" then
                    headerEnd = i
                    break
                end
            end

            i = i + 1
        end

        if not headerEnd then
            break
        end

        local header =
            data:sub(
                headerStart,
                headerEnd - 1
            )

        local bodyStart = headerEnd + 1
        local braceStart =
            data:find("{", bodyStart)

        if not braceStart then
            break
        end

        local depth = 0
        local bodyEnd

        quoteChar = nil
        i = braceStart

        while i <= #data do
            local ch = data:sub(i, i)

            if quoteChar then
                if ch == "\\" then
                    i = i + 1
                elseif ch == quoteChar then
                    quoteChar = nil
                end
            else
                if ch == '"' or ch == "'" then
                    quoteChar = ch
                elseif ch == "{" then
                    depth = depth + 1
                elseif ch == "}" then
                    depth = depth - 1

                    if depth == 0 then
                        bodyEnd = i
                        break
                    end
                end
            end

            i = i + 1
        end

        if not bodyEnd then
            break
        end

        local body =
            data:sub(
                braceStart + 1,
                bodyEnd - 1
            )

        blocks[#blocks + 1] = {
            header = trimString(header),
            body = trimString(body)
        }

        pos = bodyEnd + 1
    end

    return blocks
end

local function getDiffTagFromIndex(idx, zeroBased)
    if not idx then
        return nil
    end

    local n = tonumber(idx)

    if not n then
        return nil
    end

    if zeroBased then
        if n >= 0 and n <= 4 then
            return diffs[n + 1]
        end
    else
        if n >= 1 and n <= 5 then
            return diffs[n]
        end

        if n >= 0 and n <= 4 then
            return diffs[n + 1]
        end
    end

    return nil
end

local function isMeaningfulDiffBody(body)
    return type(body) == "string"
        and body:match("%S") ~= nil
end

local function parseSflDiffs(data)
    local textDiff = {
        easy = nil,
        normal = nil,
        hard = nil,
        extra = nil,
        custom = nil
    }

    local levelDiff = {
        easy = nil,
        normal = nil,
        hard = nil,
        extra = nil,
        custom = nil
    }

    if type(data) ~= "string" then
        return textDiff, levelDiff
    end

    local indices = {}
    local blocks = extractSflDiffBlocks(data)

    for _, blockInfo in ipairs(blocks) do
        local idxNum =
            parseDiffHeader(blockInfo.header)

        if idxNum then
            indices[#indices + 1] = idxNum
        end
    end

    if #indices == 0 then
        for idx in data:gmatch(
            'diff%s*%(%s*([0-9]+)'
        ) do
            local idxNum = tonumber(idx)

            if idxNum then
                indices[#indices + 1] = idxNum
            end
        end
    end

    local zeroBased = false
    local oneBased = false

    for _, value in ipairs(indices) do
        if value == 0 then
            zeroBased = true
        end

        if value >= 1 and value <= 5 then
            oneBased = true
        end
    end

    if zeroBased then
        oneBased = false
    elseif not oneBased then
        oneBased = true
    end

    local count = 0

    for _, blockInfo in ipairs(blocks) do
        local idxNum, levelToken =
            parseDiffHeader(blockInfo.header)

        local tag =
            getDiffTagFromIndex(
                idxNum,
                zeroBased
            )

        if tag then
            if levelToken then
                levelDiff[tag] = levelToken
            end

            if isMeaningfulDiffBody(blockInfo.body) then
                textDiff[tag] = blockInfo.body
                count = count + 1
            else
                textDiff[tag] = nil
                levelDiff[tag] = nil
            end
        end
    end

    log.debug(
        "parseSflDiffs: Extracted " ..
        tostring(count) ..
        " difficulty levels"
    )

    return textDiff, levelDiff
end

local function parseSflLaneNotes(text)
    local notes = {}
    local noteCount = 0

    if type(text) ~= "string" then
        return notes
    end

    local function trimLocal(line)
        return line:gsub(
            "^%s+",
            ""
        ):gsub(
            "%s+$",
            ""
        )
    end

    local measureNum = 0
    local currentGravity = 1
    local fullWidthHash = "\239\188\131"

    local normalized = text

    if normalized:sub(-1) ~= ";" then
        normalized = normalized .. ";"
    end

    for measureBlock in normalized:gmatch(
        "([^;]-);"
    ) do
        measureNum = measureNum + 1

        local laneCursor = 0

        for line in measureBlock:gmatch(
            "[^\r\n]+"
        ) do
            local clean =
                trimLocal(
                    line:gsub("//.*$", "")
                )

            if clean ~= "" then
                clean =
                    clean:gsub(
                        fullWidthHash,
                        "#"
                    )

                if clean:sub(1, 1) == "#" then
                    local cmd, rest =
                        clean:match(
                            "^#([%w_]+)%s*(.*)"
                        )

                    if cmd
                        and string.lower(cmd) == "gravity" then

                        local g =
                            tonumber(
                                (rest or ""):match(
                                    "([%-%d%.]+)"
                                )
                            )

                        if g then
                            currentGravity = g
                        end
                    end
                else
                    local noSpace =
                        clean:gsub("%s+", "")

                    local lineWithComma =
                        noSpace

                    if lineWithComma:sub(-1) ~= "," then
                        lineWithComma =
                            lineWithComma .. ","
                    end

                    for segment in lineWithComma:gmatch(
                        "([^,]*),"
                    ) do
                        laneCursor = laneCursor + 1

                        local laneIndex = laneCursor

                        if laneIndex <= 6 then
                            local segmentLen = #segment

                            if segmentLen > 0 then
                                for pos = 1, segmentLen do
                                    local c =
                                        segment:sub(
                                            pos,
                                            pos
                                        )

                                    if c ~= "0" then
                                        local noteType =
                                            tonumber(c)

                                        if noteType then
                                            noteCount =
                                                noteCount + 1

                                            notes[noteCount] = {
                                                lane = laneIndex,
                                                measure = measureNum,
                                                pos = (pos - 1) / segmentLen,
                                                type = noteType,
                                                gravity = currentGravity
                                            }
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return notes
end

local function resetSingleSongAnalysisState()
    notedata = {
        easy = {},
        normal = {},
        hard = {},
        extra = {},
        custom = {}
    }

    starttiming = {
        easy = {
            measure = {},
            bpm = {},
            hs = {},
            scrollmove = {},
            move = {},
            gogostart = {},
            gogoend = {},
            gravity = {}
        },
        normal = {
            measure = {},
            bpm = {},
            hs = {},
            scrollmove = {},
            move = {},
            gogostart = {},
            gogoend = {},
            gravity = {}
        },
        hard = {
            measure = {},
            bpm = {},
            hs = {},
            scrollmove = {},
            move = {},
            gogostart = {},
            gogoend = {},
            gravity = {}
        },
        extra = {
            measure = {},
            bpm = {},
            hs = {},
            scrollmove = {},
            move = {},
            gogostart = {},
            gogoend = {},
            gravity = {}
        },
        custom = {
            measure = {},
            bpm = {},
            hs = {},
            scrollmove = {},
            move = {},
            gogostart = {},
            gogoend = {},
            gravity = {}
        }
    }

    measuretime = {
        easy = {},
        normal = {},
        hard = {},
        extra = {},
        custom = {}
    }
end

local function basicSerialize(value)
    if type(value) == "table" then
        local parts = {}

        for k, v in pairs(value) do
            local key

            if type(k) == "string" then
                key = string.format("[%q]", k)
            else
                key = string.format("[%d]", k)
            end

            parts[#parts + 1] =
                key .. "=" .. basicSerialize(v)
        end

        return "{" .. table.concat(parts, ",") .. "}"
    elseif type(value) == "string" then
        return string.format("%q", value)
    elseif value == nil then
        return "nil"
    end

    return tostring(value)
end

local function parseGenresFromSfl(data)
    local genres = {}
    local genreCount = 0
    local seen = {}

    local function addGenre(value)
        if type(value) ~= "string" then
            return
        end

        local cleaned =
            value:match("^%s*(.-)%s*$")
            or value

        if cleaned ~= "" and not seen[cleaned] then
            seen[cleaned] = true
            genreCount = genreCount + 1
            genres[genreCount] = cleaned
        end
    end

    if type(data) == "string" then
        for g in data:gmatch(
            'genre%s*%(%s*"([^"]-)"%s*%)'
        ) do
            addGenre(g)
        end

        for g in data:gmatch(
            "genre%s*%(%s*'([^']-)'%s*%)"
        ) do
            addGenre(g)
        end
    end

    if genreCount == 0 then
        genres[1] = "Unknown"
    end

    return genres
end

function loadsflfile()
    if type(sflpath) ~= "table" then
        return
    end

    for i = 1, #sflpath do
        local path = sflpath[i]

        local data =
            getCachedSflData(path)

        if data == nil then
            data = readFile(path) or ""
        end

        sflmeta[i] = {}
        sfldiff[i] = {}

        if data == "" then
            log.warn(
                "SFL file is empty: " ..
                tostring(path)
            )
        else
            sflmeta[i].title,
            sflmeta[i].musicfile,
            sflmeta[i].bpm =
                data:match(
                    'meta%("([^"]+)",([^,]+),([^%)]+)%)'
                )

            sflmeta[i].url =
                data:match(
                    'url%s*%(%s*["\'](.-)["\']%s*%)'
                )

            sflmeta[i].artist =
                data:match(
                    'artist%s*%(%s*["\'](.-)["\']%s*%)'
                )

            sflmeta[i].offset =
                data:match(
                    'offset%s*%(([^%)]+)%)'
                )

            sflmeta[i].volume =
                data:match(
                    'volume%s*%(([^%)]+)%)'
                )

            sflmeta[i].demostart =
                data:match(
                    'demostart%s*%(([^%)]+)%)'
                )

            sflmeta[i].demoend =
                data:match(
                    'demoend%s*%(([^%)]+)%)'
                )

            sflmeta[i].genre =
                parseGenresFromSfl(data)

            local parsedSfldiff, parsedSfllevel =
                parseSflDiffs(data)

            sfldiff[i] = parsedSfldiff

            sfllevel[i] = {}

            for _, diff in ipairs(diffs) do
                sfllevel[i][diff] =
                    parsedSfllevel[diff]
            end

            sfllevel[i].hasLevel = false

            for _, diff in ipairs(diffs) do
                if sfllevel[i][diff]
                    and sfllevel[i][diff] ~= "" then

                    sfllevel[i].hasLevel = true
                    break
                end
            end
        end
    end
end

function loadsflfile_indexed(i)
    if type(i) ~= "number" then
        return
    end

    if not sflpath[i] then
        return
    end

    local data =
        getCachedSflData(sflpath[i])

    if data == nil then
        data =
            readFile(sflpath[i]) or ""
    end

    if data == "" then
        log.warn(
            "SFL file is empty: " ..
            tostring(sflpath[i])
        )
        return
    end

    sflmeta[i] = {}
    sfldiff[i] = {}

    sflmeta[i].title,
    sflmeta[i].musicfile,
    sflmeta[i].bpm =
        data:match(
            'meta%("([^"]+)",([^,]+),([^%)]+)%)'
        )

    sflmeta[i].artist =
        data:match(
            'artist%s*%(%s*["\'](.-)["\']%s*%)'
        )

    sflmeta[i].offset =
        data:match(
            'offset%s*%(([^%)]+)%)'
        )

    sflmeta[i].volume =
        data:match(
            'volume%s*%(([^%)]+)%)'
        )

    sflmeta[i].demostart =
        data:match(
            'demostart%s*%(([^%)]+)%)'
        )

    sflmeta[i].demoend =
        data:match(
            'demoend%s*%(([^%)]+)%)'
        )

    sflmeta[i].url =
        data:match(
            'url%s*%(%s*["\'](.-)["\']%s*%)'
        )

    sflmeta[i].genre =
        parseGenresFromSfl(data)

    local parsedSfldiff, parsedSfllevel =
        parseSflDiffs(data)

    sfldiff[i] = parsedSfldiff

    sfllevel[i] = {}

    for _, diff in ipairs(diffs) do
        sfllevel[i][diff] =
            parsedSfllevel[diff]
    end

    sfllevel[i].hasLevel = false

    for _, diff in ipairs(diffs) do
        if sfllevel[i][diff]
            and sfllevel[i][diff] ~= "" then

            sfllevel[i].hasLevel = true
            break
        end
    end
end

function createnotedata()
    loadsflfile()

    for i = 1, #sflpath do
        for _, diff in ipairs(diffs) do
            if sfldiff[i]
                and sfldiff[i][diff] then

                notedata[diff][i] =
                    sfldiff[i][diff]
            end
        end
    end
end

function analysissfl()
    createnotedata()

    for i = 1, #sflpath do
        for _, diff in ipairs(diffs) do
            local actiontext =
                notedata[diff][i]

            if type(actiontext) == "string" then
                notedata[diff][i] = {
                    action = actiontext,
                    measure = nil,
                    bpm = nil,
                    hs = nil,
                    scrollmove = {},
                    move = {},
                    gogostart = false,
                    gogoend = false,
                    gravity = nil,
                    notes =
                        parseSflLaneNotes(actiontext)
                }

                local data =
                    notedata[diff][i]

                for down, up in actiontext:gmatch(
                    "#Measure%s+(%d+)%s+(%d+)"
                ) do
                    data.measure = {
                        tonumber(down),
                        tonumber(up)
                    }
                end

                for bpm in actiontext:gmatch(
                    "#BPM%s+([%d%.]+)"
                ) do
                    data.bpm = tonumber(bpm)
                end

                for hs in actiontext:gmatch(
                    "#HS%s+([%d%.]+)"
                ) do
                    data.hs = tonumber(hs)
                end

                for scroll, speed, timing, easing
                    in actiontext:gmatch(
                        "#ScrollMove%s+([^%s]+)%s+([^%s]+)%s+([^%s]+)%s+([^%s]+)"
                    ) do

                    data.scrollmove[#data.scrollmove + 1] = {
                        scroll = tonumber(scroll),
                        speed = tonumber(speed),
                        timing = tonumber(timing),
                        easing = easing
                    }
                end

                for note, from, to, timing, easing
                    in actiontext:gmatch(
                        "#Move%s+([^%s]+)%s+([^%s]+)%s+([^%s]+)%s+([^%s]+)%s+([^%s]+)"
                    ) do

                    data.move[#data.move + 1] = {
                        note = tonumber(note),
                        from = tonumber(from),
                        to = tonumber(to),
                        timing = tonumber(timing),
                        easing = easing
                    }
                end

                if actiontext:find("#GogoStart", 1, true) then
                    data.gogostart = true
                end

                if actiontext:find("#GogoEnd", 1, true) then
                    data.gogoend = true
                end

                for g in actiontext:gmatch(
                    "#Gravity%s+([^%s]+)"
                ) do
                    data.gravity = tonumber(g)
                end
            end
        end
    end
end

function loadaction()
    analysissfl()

    for i = 1, #sflpath do
        for _, diff in ipairs(diffs) do
            local data =
                notedata[diff][i]

            if data then
                if data.measure then
                    starttiming[diff].measure[#starttiming[diff].measure + 1] = {
                        i,
                        data.measure
                    }
                end

                if data.bpm then
                    starttiming[diff].bpm[#starttiming[diff].bpm + 1] = {
                        i,
                        data.bpm
                    }
                end

                if data.hs then
                    starttiming[diff].hs[#starttiming[diff].hs + 1] = {
                        i,
                        data.hs
                    }
                end

                if #data.scrollmove > 0 then
                    starttiming[diff].scrollmove[#starttiming[diff].scrollmove + 1] = {
                        i,
                        data.scrollmove
                    }
                end

                if #data.move > 0 then
                    starttiming[diff].move[#starttiming[diff].move + 1] = {
                        i,
                        data.move
                    }
                end

                if data.gogostart then
                    starttiming[diff].gogostart[#starttiming[diff].gogostart + 1] = {
                        i,
                        true
                    }
                end

                if data.gogoend then
                    starttiming[diff].gogoend[#starttiming[diff].gogoend + 1] = {
                        i,
                        true
                    }
                end

                if data.gravity then
                    starttiming[diff].gravity[#starttiming[diff].gravity + 1] = {
                        i,
                        data.gravity
                    }
                end
            end
        end
    end
end

function calculationmeasuretime()
    loadaction()

    for _, diff in ipairs(diffs) do
        for i = 1, #sflpath do
            local data =
                notedata[diff][i]

            if data and data.measure then
                local down = data.measure[1]
                local up = data.measure[2]

                local bpm =
                    data.bpm
                    or tonumber(
                        sflmeta[i] and sflmeta[i].bpm
                    )

                if bpm and down ~= 0 then
                    measuretime[diff][i] =
                        240 / bpm * (up / down)
                end
            end
        end
    end
end

function analyze_single_song(i)
    loadsflfile_indexed(i)

    if not sflmeta[i] then
        error(
            "SFL metadata could not be loaded for index " ..
            tostring(i)
        )
    end

    local function parseNotes(text)
        return parseSflLaneNotes(text)
    end

    for _, diff in ipairs(diffs) do
        local actiontext

        if sfldiff[i] then
            actiontext = sfldiff[i][diff]
        end

        if not actiontext
            and notedata[diff]
            and notedata[diff][i]
            and notedata[diff][i].action then

            actiontext =
                notedata[diff][i].action
        end

        if type(actiontext) == "string"
            and actiontext ~= "" then

            notedata[diff][i] = {
                action = actiontext,
                measure = nil,
                bpm = nil,
                hs = nil,
                scrollmove = {},
                move = {},
                gogostart = false,
                gogoend = false,
                gravity = nil,
                notes = parseNotes(actiontext)
            }

            local data =
                notedata[diff][i]

            for down, up in actiontext:gmatch(
                "#Measure%s+(%d+)%s+(%d+)"
            ) do
                data.measure = {
                    tonumber(down),
                    tonumber(up)
                }
            end

            for bpm in actiontext:gmatch(
                "#BPM%s+([%d%.]+)"
            ) do
                data.bpm = tonumber(bpm)
            end

            for hs in actiontext:gmatch(
                "#HS%s+([%d%.]+)"
            ) do
                data.hs = tonumber(hs)
            end

            for gravity in actiontext:gmatch(
                "#Gravity%s+([%-%d%.]+)"
            ) do
                data.gravity =
                    tonumber(gravity)
            end

            if data.measure then
                starttiming[diff].measure[#starttiming[diff].measure + 1] = {
                    i,
                    data.measure
                }
            end

            if data.bpm then
                starttiming[diff].bpm[#starttiming[diff].bpm + 1] = {
                    i,
                    data.bpm
                }
            end

            if data.hs then
                starttiming[diff].hs[#starttiming[diff].hs + 1] = {
                    i,
                    data.hs
                }
            end

            if data.gravity then
                starttiming[diff].gravity[#starttiming[diff].gravity + 1] = {
                    i,
                    data.gravity
                }
            end

            if data.measure then
                local down = data.measure[1]
                local up = data.measure[2]

                local chartBpm =
                    data.bpm

                if not chartBpm then
                    chartBpm =
                        tonumber(
                            sflmeta[i].bpm
                        )
                end

                if chartBpm
                    and down
                    and down ~= 0 then

                    measuretime[diff][i] =
                        240 /
                        chartBpm *
                        (up / down)
                end
            end
        end
    end
end

local function trimLine(line)
    return line:gsub(
        "^%s+",
        ""
    ):gsub(
        "%s+$",
        ""
    )
end

local function buildMeasureTiming(actionText, baseBpm)
    local measures = {}

    if type(actionText) ~= "string" then
        return measures
    end

    local currentBpm =
        tonumber(baseBpm) or 120

    local currentDown = 4
    local currentUp = 4
    local currentTime = 0
    local measureIndex = 0
    local fullWidthHash = "\239\188\131"

    for measureBlock in actionText:gmatch(
        "([^;]-);"
    ) do
        measureIndex = measureIndex + 1

        for line in measureBlock:gmatch(
            "[^\r\n]+"
        ) do
            local clean = trimLine(line)

            if clean ~= ""
                and not clean:match("^//") then

                clean =
                    clean:gsub(
                        fullWidthHash,
                        "#"
                    )

                if clean:sub(1, 1) == "#" then
                    local cmd, rest =
                        clean:match(
                            "^#([%w_]+)%s*(.*)"
                        )

                    if cmd == "BPM" then
                        local v =
                            tonumber(
                                rest:match(
                                    "([%d%.]+)"
                                )
                            )

                        if v then
                            currentBpm = v
                        end
                    elseif cmd == "Measure" then
                        local down, up =
                            rest:match(
                                "([%d%.]+)%s+([%d%.]+)"
                            )

                        if down and up then
                            currentDown =
                                tonumber(down)
                                or currentDown

                            currentUp =
                                tonumber(up)
                                or currentUp
                        end
                    end
                end
            end
        end

        local measureSec = 0

        if currentBpm
            and currentBpm ~= 0
            and currentDown ~= 0 then

            measureSec =
                240 /
                currentBpm *
                (currentUp / currentDown)
        end

        measures[measureIndex] = {
            start = currentTime,
            duration = measureSec,
            bpm = currentBpm,
            measure = {
                currentDown,
                currentUp
            }
        }

        currentTime =
            currentTime + measureSec
    end

    return measures
end

local function parseActionEvents(actionText, measures)
    local events = {}

    if type(actionText) ~= "string" then
        return events
    end

    local measureIndex = 0
    local fullWidthHash = "\239\188\131"

    for measureBlock in actionText:gmatch(
        "([^;]-);"
    ) do
        measureIndex = measureIndex + 1

        local info =
            measures[measureIndex]
            or {
                start = 0,
                duration = 0,
                bpm = 0
            }

        local measureStart =
            info.start or 0

        local beatSec = 0

        if info.bpm and info.bpm ~= 0 then
            beatSec =
                60 / info.bpm
        end

        for line in measureBlock:gmatch(
            "[^\r\n]+"
        ) do
            local clean =
                trimLine(line)

            if clean ~= ""
                and not clean:match("^//") then

                clean =
                    clean:gsub(
                        fullWidthHash,
                        "#"
                    )

                if clean:sub(1, 1) == "#" then
                    local cmd, rest =
                        clean:match(
                            "^#([%w_]+)%s*(.*)"
                        )

                    if cmd then
                        local event = {
                            time = measureStart,
                            type = cmd,
                            measure = measureIndex
                        }

                        if cmd == "Lyric" then
                            local lyric, offset =
                                rest:match(
                                    '^"(.-)"%s*([%-%d%.]*)'
                                )

                            lyric = lyric or ""

                            local offsetNum =
                                tonumber(offset)

                            event.text = lyric

                            if offsetNum then
                                event.offset =
                                    offsetNum

                                if beatSec > 0 then
                                    event.time =
                                        measureStart +
                                        offsetNum *
                                        beatSec

                                    event.offsetSec =
                                        offsetNum *
                                        beatSec
                                end
                            end
                        else
                            local args = {}

                            for token in rest:gmatch(
                                "[^%s]+"
                            ) do
                                local num =
                                    tonumber(token)

                                args[#args + 1] =
                                    num ~= nil
                                    and num
                                    or token
                            end

                            event.args = args
                        end

                        events[#events + 1] =
                            event
                    end
                end
            end
        end
    end

    return events
end

local noteTypeMap = {
    tap = 1,
    hit = 1,
    normal = 1,
    hold = 2,
    hold_start = 2,
    holdend = 3,
    hold_end = 3,
    release = 3,
    flick = 4,
    slide = 5,
    scratch = 6,
    mine = 7
}

local function noteTypeToNumber(noteType)
    local n = tonumber(noteType)

    if n then
        return n
    end

    if type(noteType) == "string" then
        local key =
            string.lower(noteType)

        return noteTypeMap[key] or 0
    end

    return 0
end

local function secToMs(sec)
    local n =
        tonumber(sec) or 0

    return math.floor(
        n * 1000 + 0.5
    )
end

function createchartbin(i)
    local chart = {}

    local title = ""
    local artist = ""
    local bpm = 0
    local offset = 0
    local volume = 1.0
    local demostart = 0
    local demoend = 0
    local url = ""
    local genre = {}

    if sflmeta[i] then
        title =
            sflmeta[i].title or ""

        artist =
            sflmeta[i].artist or ""

        bpm =
            tonumber(
                sflmeta[i].bpm
            ) or 0

        offset =
            tonumber(
                sflmeta[i].offset
            ) or 0

        demostart =
            tonumber(
                sflmeta[i].demostart
            ) or 0

        demoend =
            tonumber(
                sflmeta[i].demoend
            ) or 0

        volume =
            tonumber(
                sflmeta[i].volume
            ) or 1.0

        url =
            sflmeta[i].url or ""

        genre =
            sflmeta[i].genre or {}
    end

    chart.meta = {
        title = title,
        artist = artist,
        bpm = bpm,
        offset = offset,
        volume = volume,
        demostart = demostart,
        demoend = demoend,
        levels = sfllevel[i] or {},
        hasLevel =
            (
                sfllevel[i]
                and sfllevel[i].hasLevel
            )
            or false,
        level =
            (
                sfllevel[i]
                and (
                    sfllevel[i].easy
                    or sfllevel[i].normal
                    or sfllevel[i].hard
                    or sfllevel[i].extra
                    or sfllevel[i].custom
                )
            )
            or nil,
        url = url,
        genre = genre
    }

    local laneTiming = {}
    local measureTimeline = {}
    local actionsByDiff = {}

    for _, diff in ipairs(diffs) do
        laneTiming[diff] = {}
        actionsByDiff[diff] = {}

        local diffText

        if sfldiff[i]
            and sfldiff[i][diff] then

            diffText =
                sfldiff[i][diff]

        elseif notedata[diff]
            and notedata[diff][i]
            and notedata[diff][i].action then

            diffText =
                notedata[diff][i].action
        end

        if diffText then
            measureTimeline[diff] =
                buildMeasureTiming(
                    diffText,
                    bpm
                )

            actionsByDiff[diff] =
                parseActionEvents(
                    diffText,
                    measureTimeline[diff]
                )
        end

        local data =
            notedata[diff][i]

        if data and data.notes then
            for _, note in ipairs(data.notes) do
                local lane =
                    tonumber(note.lane)
                    or note.lane

                local sec = 0

                local m =
                    measureTimeline[diff]
                    and measureTimeline[diff][note.measure]

                if m then
                    sec =
                        (m.start or 0) +
                        (note.pos or 0) *
                        (m.duration or 0)

                elseif measuretime[diff]
                    and measuretime[diff][i] then

                    sec =
                        (note.measure - 1) *
                        measuretime[diff][i] +
                        (note.pos or 0) *
                        measuretime[diff][i]
                end

                laneTiming[diff][lane] =
                    laneTiming[diff][lane]
                    or {}

                local laneNotes =
                    laneTiming[diff][lane]

                laneNotes[#laneNotes + 1] = {
                    time = sec,
                    timeMs = secToMs(sec),
                    type =
                        noteTypeToNumber(
                            note.type
                        ),
                    gravity =
                        tonumber(note.gravity)
                }
            end
        end
    end

    for _, diff in ipairs(diffs) do
        for _, notesForLane
            in pairs(laneTiming[diff]) do

            table.sort(
                notesForLane,
                function(a, b)
                    return
                        (a.timeMs or 0) <
                        (b.timeMs or 0)
                end
            )
        end
    end

    chart.lanes = laneTiming

    local notes = {}

    for _, diff in ipairs(diffs) do
        notes[diff] = {}

        for lane, laneNotes
            in pairs(laneTiming[diff]) do

            for _, n in ipairs(laneNotes) do
                notes[diff][#notes[diff] + 1] = {
                    time = n.time,
                    timeMs =
                        n.timeMs
                        or secToMs(n.time),
                    lane = lane,
                    type = n.type,
                    gravity = n.gravity
                }
            end
        end

        table.sort(
            notes[diff],
            function(a, b)
                return
                    (a.timeMs or 0) <
                    (b.timeMs or 0)
            end
        )
    end

    chart.notes = notes

    local laneTimes = {}
    local laneNumbers = {}

    for _, diff in ipairs(diffs) do
        laneTimes[diff] = {}
        laneNumbers[diff] = {}

        for lane, laneNotes
            in pairs(laneTiming[diff]) do

            local times = {}
            local numeric = {
                times = {},
                types = {},
                pairs = {}
            }

            for _, n in ipairs(laneNotes) do
                local noteMs =
                    n.timeMs
                    or secToMs(n.time)

                local noteType =
                    noteTypeToNumber(
                        n.type
                    )

                times[#times + 1] =
                    noteMs

                numeric.times[#numeric.times + 1] =
                    noteMs

                numeric.types[#numeric.types + 1] =
                    noteType

                numeric.pairs[#numeric.pairs + 1] = {
                    noteMs,
                    noteType
                }
            end

            laneTimes[diff][lane] =
                table.concat(times, ",")

            laneNumbers[diff][lane] =
                numeric
        end
    end

    chart.laneTimes = laneTimes
    chart.laneNumbers = laneNumbers
    chart.actions = actionsByDiff

    return chart
end

local function getSongBasePath(index)
    local base =
        sflbasePath[index]

    if type(base) ~= "string"
        or base == "" then

        base = "lib/data/Songs"
    end

    return base
end

local function getSongFolder(index)
    local foldName =
        sflfoldname[index]

    if type(foldName) ~= "string"
        or foldName == "" then

        return nil
    end

    return
        getSongBasePath(index) ..
        "/" ..
        foldName
end

local function hasParsedDifficulty(index)
    if not sfldiff[index] then
        return false
    end

    for _, diff in ipairs(diffs) do
        if type(sfldiff[index][diff]) == "string"
            and sfldiff[index][diff]:match("%S") then

            return true
        end
    end

    return false
end

local function collectSongFiles(index)
    local songfolder =
        getSongFolder(index)

    if not songfolder then
        return nil, "invalid_song_folder"
    end

    local files = {}

    local bgpath, jacketName =
        findJacketInFolder(songfolder)

    if bgpath then
        local ext =
            string.match(
                string.lower(
                    jacketName or bgpath
                ),
                "%.([%w]+)$"
            )

        local data =
            readFile(bgpath)

        if data then
            files[#files + 1] = {
                name =
                    ext
                    and "jacket." .. ext
                    or "jacket",
                data = data
            }
        end
    end

    local musicName =
        sflmeta[index]
        and sflmeta[index].musicfile

    local musicpath,
        resolvedMusicName,
        resolveMode =
        findAudioInFolder(
            songfolder,
            musicName
        )

    if musicpath then
        if resolveMode ~= "meta_exact" then
            log.info(
                "Music resolved by " ..
                tostring(resolveMode) ..
                ": " ..
                tostring(resolvedMusicName)
            )
        end

        local musicData =
            readFile(musicpath)

        if musicData then
            files[#files + 1] = {
                name =
                    sanitizeEntryName(
                        resolvedMusicName,
                        "music.wav"
                    ),
                data = musicData
            }
        end
    else
        log.warn(
            "Music file not found: " ..
            tostring(songfolder) ..
            " (meta=" ..
            tostring(musicName) ..
            ")"
        )
    end

    local chartTable =
        createchartbin(index)

    local chartData =
        "return " ..
        basicSerialize(chartTable)

    local chartFileName =
        (
            sflmeta[index]
            and sflmeta[index].title
        )
        or sflfoldname[index]
        or "chart"

    chartFileName =
        chartFileName:gsub(
            "[%c%?%*\\/<>|:\"]",
            ""
        )

    if chartFileName == "" then
        chartFileName = "chart"
    end

    chartFileName =
        chartFileName .. ".bin"

    files[#files + 1] = {
        name =
            sanitizeEntryName(
                chartFileName,
                "chart.bin"
            ),
        data = chartData
    }

    return files
end

local function buildArchiveNameFromFoldName(foldname)
    local archiveBase =
        tostring(foldname or "song")

    archiveBase =
        archiveBase:gsub(
            "[%c%?%*\\/<>|:\"]",
            ""
        )

    if archiveBase == "" then
        archiveBase = "song"
    end

    return archiveBase .. ".sfb"
end

local function writeSfbArchive(archiveName, files)
    if type(archiveName) ~= "string"
        or archiveName == "" then

        return false, "invalid_archive_name"
    end

    if type(files) ~= "table"
        or #files == 0 then

        return false, "no_files"
    end

    for _, file in ipairs(files) do
        if type(file.data) ~= "string" then
            return false,
                "invalid_data:" ..
                tostring(file.name)
        end
    end

    local header =
        "SFB1\n1\n" ..
        tostring(#files) ..
        "\n"

    local tempIndexParts = {}

    for _, file in ipairs(files) do
        tempIndexParts[#tempIndexParts + 1] =
            tostring(file.name) ..
            ",0000000000,0000000000\n"
    end

    local tempIndex =
        table.concat(tempIndexParts)

    local dataOffset =
        #header +
        #tempIndex

    local indexParts = {}
    local currentOffset = dataOffset

    for _, file in ipairs(files) do
        local fileSize =
            #file.data

        indexParts[#indexParts + 1] =
            tostring(file.name) ..
            "," ..
            string.format(
                "%010d",
                currentOffset
            ) ..
            "," ..
            string.format(
                "%010d",
                fileSize
            ) ..
            "\n"

        currentOffset =
            currentOffset +
            fileSize
    end

    local index =
        table.concat(indexParts)

    local ok, err =
        love.filesystem.write(
            archiveName,
            header .. index
        )

    if not ok then
        return false,
            tostring(err)
    end

    for _, file in ipairs(files) do
        local appendOk, appendErr =
            love.filesystem.append(
                archiveName,
                file.data
            )

        if not appendOk then
            return false,
                tostring(appendErr)
        end
    end

    return true
end

local function buildDirectCollectionsFromSongs()
    if not refreshScratchSfl() then
        return {
            audio = {},
            charts = {},
            images = {}
        }
    end

    local foldnames =
        sflfoldname

    local loadedCollections = {
        audio = {},
        charts = {},
        images = {}
    }

    log.info(
        "createsfb.load(): direct song scan started (" ..
        tostring(#foldnames) ..
        " song(s))"
    )

    if #sflpath > 0 then
        preloadSflFilesParallel(sflpath)
    end

    for i = 1, #foldnames do
        local foldName =
            foldnames[i]

        local songfolder =
            getSongFolder(i)

        local archiveKey =
            "song:" ..
            tostring(foldName or i)

        resetSingleSongAnalysisState()

        local ok, err =
            pcall(function()
                analyze_single_song(i)

                if not hasParsedDifficulty(i) then
                    log.info(
                        "Skipping song without parsed difficulties: " ..
                        tostring(foldName)
                    )

                    return
                end

                local chartTable =
                    createchartbin(i)

                local chartData =
                    "return " ..
                    basicSerialize(
                        chartTable
                    )

                loadedCollections.charts[
                    #loadedCollections.charts + 1
                ] = {
                    name =
                        sflpath[i]
                        or (
                            tostring(songfolder)
                            .. "/chart.sfl"
                        ),
                    data = chartData,
                    archive = archiveKey
                }

                local musicName =
                    sflmeta[i]
                    and sflmeta[i].musicfile

                local musicpath,
                    resolvedMusicName,
                    resolveMode =
                    findAudioInFolder(
                        songfolder,
                        musicName
                    )

                if musicpath then
                    local musicData =
                        readFile(musicpath)

                    if musicData then
                        loadedCollections.audio[
                            #loadedCollections.audio + 1
                        ] = {
                            name = musicpath,
                            archive = archiveKey,
                            sourcePath = musicpath,
                            data = musicData
                        }
                    end

                    if resolveMode ~= "meta_exact" then
                        log.info(
                            "Music fallback: " ..
                            tostring(
                                resolvedMusicName
                            )
                        )
                    end
                end

                local jacketPath =
                    findJacketInFolder(
                        songfolder
                    )

                if jacketPath then
                    local jacketData =
                        readFile(jacketPath)

                    if jacketData then
                        loadedCollections.images[
                            #loadedCollections.images + 1
                        ] = {
                            name = jacketPath,
                            archive = archiveKey,
                            sourcePath = jacketPath,
                            data = jacketData
                        }
                    end
                end
            end)

        if not ok then
            log.warn(
                "Song parse failed [" ..
                tostring(i) ..
                "] " ..
                tostring(foldName) ..
                ": " ..
                tostring(err)
            )
        end
    end

    return loadedCollections
end

function createsfb.load(opts)
    if type(opts) == "boolean" then
        opts = {
            forceRebuildAll = opts
        }
    elseif type(opts) ~= "table" then
        opts = {}
    end

    local forceRebuildAll =
        opts.forceRebuildAll == true

    log.info(
        "createsfb.load() called, forceRebuildAll=" ..
        tostring(forceRebuildAll)
    )

    local loadedCollections

    local ok, err =
        pcall(function()
            loadedCollections =
                buildDirectCollectionsFromSongs()
        end)

    if not ok then
        log.error(
            "createsfb.load() failed: " ..
            tostring(err)
        )

        return nil
    end

    local audioCount = 0
    local chartCount = 0
    local imageCount = 0

    if loadedCollections then
        audioCount =
            #(loadedCollections.audio or {})

        chartCount =
            #(loadedCollections.charts or {})

        imageCount =
            #(loadedCollections.images or {})
    end

    log.info(
        string.format(
            "createsfb.load(): audio=%d charts=%d images=%d",
            audioCount,
            chartCount,
            imageCount
        )
    )

    return loadedCollections
end

function createsfbfile(opts)
    opts = opts or {}

    local forceRebuildAll =
        opts.forceRebuildAll == true

    if not refreshScratchSfl() then
        log.error(
            "Unable to load song list."
        )
        return
    end

    if #sflfoldname == 0 then
        log.warn(
            "No songs found after scratchsfl.load()"
        )
        return
    end

    if #sflpath > 0 then
        preloadSflFilesParallel(sflpath)
    end

    log.info(
        "Starting SFB creation. Found " ..
        tostring(#sflfoldname) ..
        " song(s)."
    )

    if forceRebuildAll then
        local rootItems =
            love.filesystem.getDirectoryItems("")
            or {}

        for _, name in ipairs(rootItems) do
            if type(name) == "string"
                and name:match("%.sfb$") then

                love.filesystem.remove(name)
            end
        end
    end

    for i = 1, #sflfoldname do
        local foldName =
            sflfoldname[i]

        local archiveName =
            buildArchiveNameFromFoldName(
                foldName
            )

        if not forceRebuildAll
            and love.filesystem.getInfo(
                archiveName
            ) then

            log.info(
                "Skipping existing archive [" ..
                tostring(i) ..
                "/" ..
                tostring(#sflfoldname) ..
                "]: " ..
                archiveName
            )

            goto skip_song
        end

        resetSingleSongAnalysisState()

        log.info(
            "Processing [" ..
            tostring(i) ..
            "/" ..
            tostring(#sflfoldname) ..
            "]: " ..
            tostring(foldName)
        )

        local ok, err =
            pcall(function()
                analyze_single_song(i)
            end)

        if not ok then
            log.warn(
                "analyze_single_song() failed for '" ..
                tostring(foldName) ..
                "': " ..
                tostring(err)
            )

            goto skip_song
        end

        if not hasParsedDifficulty(i) then
            log.warn(
                "No parsed difficulty blocks: " ..
                tostring(foldName)
            )

            goto skip_song
        end

        local files, filesErr =
            collectSongFiles(i)

        if not files then
            log.warn(
                "Failed to collect files: " ..
                tostring(filesErr)
            )

            goto skip_song
        end

        if love.filesystem.getInfo(
            archiveName
        ) then
            love.filesystem.remove(
                archiveName
            )
        end

        local writeOk, writeErr =
            writeSfbArchive(
                archiveName,
                files
            )

        if not writeOk then
            log.error(
                "Failed to create " ..
                archiveName ..
                ": " ..
                tostring(writeErr)
            )
        else
            log.info(
                "Success! Saved as: " ..
                archiveName
            )
        end

        ::skip_song::
    end
end

function createsfb.regenerateSingleSong(songIndex)
    songIndex =
        tonumber(songIndex)

    if not songIndex then
        return nil
    end

    if not refreshScratchSfl() then
        return nil
    end

    if songIndex < 1
        or songIndex > #sflfoldname then

        log.warn(
            "Invalid song index: " ..
            tostring(songIndex)
        )

        return nil
    end

    if sflpath[songIndex] then
        preloadSflFilesParallel({
            sflpath[songIndex]
        })
    end

    local foldName =
        sflfoldname[songIndex]

    resetSingleSongAnalysisState()

    local ok, err =
        pcall(function()
            analyze_single_song(
                songIndex
            )
        end)

    if not ok then
        log.warn(
            "analyze_single_song() failed: " ..
            tostring(err)
        )

        return nil
    end

    if not hasParsedDifficulty(
        songIndex
    ) then
        log.warn(
            "No parsed difficulty blocks for: " ..
            tostring(foldName)
        )

        return nil
    end

    local files, filesErr =
        collectSongFiles(
            songIndex
        )

    if not files then
        log.warn(
            "Failed to collect files: " ..
            tostring(filesErr)
        )

        return nil
    end

    local archiveName =
        buildArchiveNameFromFoldName(
            foldName
        )

    if love.filesystem.getInfo(
        archiveName
    ) then
        love.filesystem.remove(
            archiveName
        )
    end

    local writeOk, writeErr =
        writeSfbArchive(
            archiveName,
            files
        )

    if not writeOk then
        log.error(
            "Single song SFB generation failed: " ..
            tostring(writeErr)
        )

        return nil
    end

    log.info(
        "Single song SFB regenerated: " ..
        tostring(archiveName)
    )

    return archiveName
end

return createsfb