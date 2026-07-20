local _G = _G
local love = love
local string = string
local table = table
local math = math
local ipairs = ipairs
local pairs = pairs
local pcall = pcall
local tostring = tostring
local tonumber = tonumber
local type = type
local string_format = string.format
local table_insert = table.insert
local table_remove = table.remove
local table_concat = table.concat
local math_floor = math.floor
local math_max = math.max
local math_min = math.min

local audiocache = {}

local function ensureAudioCache(collections)
    if type(collections) ~= "table" then
        return nil
    end

    local cache = rawget(collections, "_runtimeAudioCache")
    if type(cache) ~= "table" then
        cache = {}
        collections._runtimeAudioCache = cache
    end
    return cache
end

local function getEntryPath(entry)
    if type(entry) == "table" then
        if type(entry.sourcePath) == "string" and entry.sourcePath ~= "" then
            return entry.sourcePath
        end
        if type(entry.name) == "string" and entry.name ~= "" and type(entry.data) ~= "string" then
            return entry.name
        end
        return nil
    end

    if type(entry) == "string" and entry ~= "" then
        return entry
    end

    return nil
end

function audiocache.getEntryKey(entry)
    if type(entry) == "table" then
        local cachedKey = rawget(entry, "_audioCacheKey")
        if type(cachedKey) == "string" and cachedKey ~= "" then
            return cachedKey
        end

        local key = nil
        local archive = tostring(entry.archive or "")
        if type(entry.data) == "string" then
            key = table_concat({
                "blob",
                archive,
                tostring(entry.name or "audio"),
                tostring(#entry.data)
            }, ":")
        else
            local path = getEntryPath(entry)
            if path then
                key = "path:" .. path
            elseif archive ~= "" or tostring(entry.name or "") ~= "" then
                key = "meta:" .. archive .. ":" .. tostring(entry.name or "")
            end
        end

        if key then
            entry._audioCacheKey = key
        end
        return key
    end

    local path = getEntryPath(entry)
    if path then
        return "path:" .. path
    end

    return nil
end

local function decodeEntryToSoundData(entry)
    if not love or not love.sound then
        return nil
    end

    if type(entry) == "table" and type(entry.data) == "string" then
        local fileName = entry.name or "audio"
        local okFileData, fileData = pcall(love.filesystem.newFileData, entry.data, fileName)
        if okFileData and fileData then
            local okSoundData, soundData = pcall(love.sound.newSoundData, fileData)
            if okSoundData and soundData then
                return soundData
            end
        end
        return nil
    end

    local path = getEntryPath(entry)
    if path then
        -- 邨ｶ蟇ｾ繝代せ・・ppData 縺ｪ縺ｩ・峨・蝣ｴ蜷医√∪縺・Lﾃ坊E 縺ｮ繝輔ぃ繧､繝ｫ繧ｷ繧ｹ繝・Β邨檎罰縺ｧ隱ｭ繧√↑縺・°隧ｦ縺ｿ繧・
        local fileName = path:match("([^/\\]+)$") or "audio"

        local function path_to_save_relative(p)
            if not (love and love.filesystem and love.filesystem.getSaveDirectory) then
                return nil
            end
            local ok, saveDir = pcall(love.filesystem.getSaveDirectory)
            if not ok or type(saveDir) ~= "string" then return nil end
            -- 豁｣隕丞喧
            local normSave = saveDir:gsub("\\","/")
            local normPath = p:gsub("\\","/")
            if normPath:sub(1, #normSave) == normSave then
                local rel = normPath:sub(#normSave + 2)
                if rel == "" then rel = "." end
                return rel
            end
            return nil
        end

        -- Lﾃ坊E 縺ｮ save 繝・ぅ繝ｬ繧ｯ繝医Μ蜀・↓縺ゅｋ縺玖ｩｦ縺・
        local rel = path_to_save_relative(path)
        if rel and love and love.filesystem and love.filesystem.getInfo then
            local okRead, contents = pcall(love.filesystem.read, rel)
            if okRead and contents then
                local okFileData, fileData = pcall(love.filesystem.newFileData, contents, fileName)
                if okFileData and fileData then
                    local okSoundData, soundData = pcall(love.sound.newSoundData, fileData)
                    if okSoundData and soundData then
                        return soundData
                    end
                end
                -- 逶ｴ謗･繝代せ譁・ｭ怜・縺ｧ newSoundData 繧定ｩｦ縺呻ｼ・ﾃ坊E 繝輔ぃ繧､繝ｫ繧ｷ繧ｹ繝・Β蜀・ヱ繧ｹ縺ｨ縺励※・・
                local okSoundData2, soundData2 = pcall(love.sound.newSoundData, rel)
                if okSoundData2 and soundData2 then
                    return soundData2
                end
            end
        end

        -- 荳願ｨ倥〒隱ｭ繧√↑縺・ｴ蜷医・譌｢蟄倥・繝輔か繝ｼ繝ｫ繝舌ャ繧ｯ・育ｵｶ蟇ｾ繝代せ: io.open / 逶ｸ蟇ｾ: love.filesystem 縺ｫ繧医ｋ隱ｭ縺ｿ霎ｼ縺ｿ・・
        local fileContent = nil
        local filePath = path

        if filePath:match("^[A-Za-z]:") or filePath:match("^/") then
            local f = io.open(filePath, "rb")
            if f then
                fileContent = f:read("*a")
                f:close()
            end
        else
            -- Try relative filesystem path first.
            if love.filesystem and love.filesystem.getInfo and love.filesystem.getInfo(filePath, "file") then
                local okRead, contents = pcall(love.filesystem.read, filePath)
                if okRead and type(contents) == "string" and contents ~= "" then
                    fileContent = contents
                end
            end
            if not fileContent then
                local f = io.open(filePath, "rb")
                if f then
                    fileContent = f:read("*a")
                    f:close()
                end
            end
        end

        if fileContent then
            local okFileData, fileData = pcall(love.filesystem.newFileData, fileContent, fileName)
            if okFileData and fileData then
                local okSoundData, soundData = pcall(love.sound.newSoundData, fileData)
                if okSoundData and soundData then
                    return soundData
                end
            end
        elseif love.filesystem and love.filesystem.getInfo and love.filesystem.getInfo(filePath, "file") then
            local okFileData, fileData = pcall(love.filesystem.newFileData, filePath)
            if okFileData and fileData then
                local okSoundData, soundData = pcall(love.sound.newSoundData, fileData)
                if okSoundData and soundData then
                    return soundData
                end
            end
        else
            local okSoundData, soundData = pcall(love.sound.newSoundData, filePath)
            if okSoundData and soundData then
                return soundData
            end
        end
    end

    return nil
end

function audiocache.preloadEntry(collections, entry)
    local cache = ensureAudioCache(collections)
    local key = audiocache.getEntryKey(entry)

    if cache and key and cache[key] ~= nil then
        return cache[key]
    end

    local record = {
        key = key,
        soundData = decodeEntryToSoundData(entry)
    }

    if cache and key then
        cache[key] = record
    end

    if type(entry) == "table" then
        entry._audioCacheKey = key or entry._audioCacheKey
    end

    return record
end

function audiocache.getPreloadedSoundData(collections, entry)
    local cache = ensureAudioCache(collections)
    local key = audiocache.getEntryKey(entry)
    local record = (cache and key and cache[key]) or nil

    if not record then
        record = audiocache.preloadEntry(collections, entry)
    end

    if record then
        return record.soundData
    end

    return nil
end

function audiocache.preloadCollectionAudio(collections)
    local audioEntries = type(collections) == "table" and collections.audio or nil
    local loaded = 0
    local total = 0

    for _, entry in ipairs(audioEntries or {}) do
        total = total + 1
        local record = audiocache.preloadEntry(collections, entry)
        if record and record.soundData then
            loaded = loaded + 1
        end
    end

    return loaded, total
end

return audiocache


