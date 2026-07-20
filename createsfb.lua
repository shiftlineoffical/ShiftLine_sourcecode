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

--[[
sfb邵ｺ・ｨ邵ｺ・ｯ


郢ｧ・｢郢晢ｽｼ郢ｧ・ｫ郢ｧ・､郢晄じ繝ｵ郢ｧ・｡郢ｧ・､郢晢ｽｫ邵ｺ・ｯ隹ｺ・｡邵ｺ・ｮ3邵ｺ・､邵ｺ・ｮ鬩幢ｽｨ陋ｻ繝ｻ縲定ｮ貞玄繝ｻ邵ｺ蜉ｱ竏ｪ邵ｺ蜷ｶﾂ繝ｻ

HEADER
INDEX
DATA

邵ｺ譏ｴ・檎ｸｺ讒ｭ・檎ｸｺ・ｮ陟厄ｽｹ陷托ｽｲ邵ｺ・ｯ隹ｺ・｡邵ｺ・ｮ鬨ｾ螢ｹ・顔ｸｺ・ｧ邵ｺ蜷ｶﾂ繝ｻ

HEADER繝ｻ蛹ｻ繝ｻ郢昴・繝繝ｻ繝ｻ

郢晁ｼ斐＜郢ｧ・､郢晢ｽｫ邵ｺ・ｮ驕橸ｽｮ鬯俶ｧｭ・・搏・ｺ隴幢ｽｬ隲繝ｻ・ｰ・ｱ郢ｧ蜻亥ｶ檎ｸｺ髦ｪ竏ｪ邵ｺ蜷ｶﾂ繝ｻ

關薙・

magic
version
fileCount

陟厄ｽｹ陷托ｽｲ繝ｻ繝ｻ

邵ｺ阮吶・郢晁ｼ斐＜郢ｧ・､郢晢ｽｫ邵ｺ迹壹・陋ｻ繝ｻ繝ｻ郢晁ｼ斐°郢晢ｽｼ郢晄ｧｭ繝｣郢晏現ﾂｰ驕抵ｽｺ髫ｱ髦ｪ笘・ｹｧ繝ｻ

闖ｴ蜍淞荵昴Ψ郢ｧ・｡郢ｧ・､郢晢ｽｫ邵ｺ謔溘・邵ｺ・｣邵ｺ・ｦ邵ｺ繝ｻ・狗ｸｺ迢苓｡咲ｹｧ繝ｻ

關謎ｹ昶斡邵ｺ・ｰ

KBA1

邵ｺ・ｨ邵ｺ繝ｻ竕ｧ隴√・・ｭ蜉ｱ・定ｭ崢陋ｻ譏ｴ竊馴р・ｮ邵ｺ荳岩・
邵ｲ蠕鯉ｼ・ｹｧ蠕後・KBA郢ｧ・｢郢晢ｽｼ郢ｧ・ｫ郢ｧ・､郢晄じ笆｡邵ｲ髦ｪ竊定崕繝ｻﾂｰ郢ｧ鄙ｫ竏ｪ邵ｺ蜷ｶﾂ繝ｻ

INDEX繝ｻ蛹ｻ縺・ｹ晢ｽｳ郢昴・繝｣郢ｧ・ｯ郢ｧ・ｹ繝ｻ繝ｻ

郢ｧ・､郢晢ｽｳ郢昴・繝｣郢ｧ・ｯ郢ｧ・ｹ邵ｺ・ｯ 騾ｶ・ｮ隹ｺ・｡邵ｺ・ｧ邵ｺ蜷ｶﾂ繝ｻ
邵ｺ阮呻ｼ・ｸｺ・ｫ邵ｲ蠕娯・邵ｺ・ｮ郢晁ｼ斐＜郢ｧ・､郢晢ｽｫ邵ｺ蠕娯・邵ｺ阮吮・邵ｺ繧・ｽ狗ｸｺ荵敖髦ｪ・定ｭ厄ｽｸ邵ｺ髦ｪ竏ｪ邵ｺ蜷ｶﾂ繝ｻ

陷ｷ繝ｻ繝ｵ郢ｧ・｡郢ｧ・､郢晢ｽｫ邵ｺ・ｫ邵ｺ・､邵ｺ繝ｻ窶ｻ隹ｺ・｡邵ｺ・ｮ隲繝ｻ・ｰ・ｱ郢ｧ蜻域亜邵ｺ・｡邵ｺ・ｾ邵ｺ蜷ｶﾂ繝ｻ

fileName
offset
size

隲｢荳櫁｢悶・繝ｻ

隲繝ｻ・ｰ・ｱ    隲｢荳櫁｢・
fileName    郢晁ｼ斐＜郢ｧ・､郢晢ｽｫ陷ｷ繝ｻ
offset  郢昴・繝ｻ郢ｧ邵ｺ・ｮ鬮｢蜿･・ｧ蛟ｶ・ｽ蜥ｲ・ｽ・ｮ
size    郢昴・繝ｻ郢ｧ郢ｧ・ｵ郢ｧ・､郢ｧ・ｺ

關薙・

chart.bin offset=120 size=200
song.ogg offset=320 size=2000000
bg.png offset=2000320 size=400000
DATA繝ｻ蛹ｻ繝ｧ郢晢ｽｼ郢ｧ繝ｻ繝ｻ

邵ｺ阮呻ｼ・ｸｺ・ｫ邵ｺ・ｯ 陞ｳ貊・怙邵ｺ・ｮ郢晁ｼ斐＜郢ｧ・､郢晢ｽｫ陷繝ｻ・ｮ・ｹ郢ｧ蛛ｵ笳守ｸｺ・ｮ邵ｺ・ｾ邵ｺ・ｾ陷茨ｽ･郢ｧ蠕娯穐邵ｺ蜷ｶﾂ繝ｻ

chart.bin 邵ｺ・ｮ闕ｳ・ｭ髴・ｽｫ
song.ogg 邵ｺ・ｮ闕ｳ・ｭ髴・ｽｫ
bg.png 邵ｺ・ｮ闕ｳ・ｭ髴・ｽｫ

邵ｺ貅倪味陷雁･竊・鬯・・蛻・ｸｺ・ｫ闕ｳ・ｦ邵ｺ・ｹ郢ｧ荵昶味邵ｺ莉｣縲堤ｸｺ蜷ｶﾂ繝ｻ

2. offset繝ｻ莠包ｽｽ蜥ｲ・ｽ・ｮ繝ｻ蟲ｨ繝ｻ髢繝ｻ竏ｴ隴・ｽｹ

郢晁ｼ斐＜郢ｧ・､郢晢ｽｫ邵ｺ・ｯ 郢晁・縺・ｹ昜ｺ･繝ｻ邵ｺ・ｧ邵ｺ蜷ｶﾂ繝ｻ

關謎ｹ昶斡邵ｺ・ｰ

ABCDE

邵ｺ・ｪ郢ｧ繝ｻ

闖ｴ蜥ｲ・ｽ・ｮ    隴√・・ｭ繝ｻ
-- 0   A
1   B
2   C
3   D
4   E

邵ｺ阮吶・ 闖ｴ蜥ｲ・ｽ・ｮ騾｡・ｪ陷ｿ・ｷ邵ｺ繝ｻoffset 邵ｺ・ｧ邵ｺ蜷ｶﾂ繝ｻ

邵ｺ・､邵ｺ・ｾ郢ｧ繝ｻ

offset = 郢晁ｼ斐＜郢ｧ・､郢晢ｽｫ邵ｺ・ｮ闖ｴ霈斐Σ郢ｧ・､郢晁ご蟯ｼ邵ｺ繝ｻ


3. 郢ｧ・｢郢晢ｽｼ郢ｧ・ｫ郢ｧ・､郢晄じ繝ｻ闖ｴ諛医・隰・洸・ｰ繝ｻ

郢ｧ・｢郢晢ｽｼ郢ｧ・ｫ郢ｧ・､郢晄じ・定抄諛奇ｽ狗ｸｺ・ｨ邵ｺ髦ｪ繝ｻ隹ｺ・｡邵ｺ・ｮ鬯・・蛻・ｸｺ・ｫ邵ｺ・ｪ郢ｧ鄙ｫ竏ｪ邵ｺ蜷ｶﾂ繝ｻ

遶ｭ・ｰ 陷茨ｽ･郢ｧ蠕鯉ｽ狗ｹ晁ｼ斐＜郢ｧ・､郢晢ｽｫ郢ｧ蜻茨ｽｱ・ｺ郢ｧ竏夲ｽ・

關薙・

chart.txt
song.ogg
bg.png
遶ｭ・｡ 郢昴・繝ｻ郢ｧ郢ｧ・ｵ郢ｧ・､郢ｧ・ｺ郢ｧ螳夲ｽｪ邵ｺ・ｹ郢ｧ繝ｻ
chart.txt = 200 bytes
song.ogg = 2,000,000 bytes
bg.png = 400,000 bytes
遶ｭ・｢ offset郢ｧ蜻茨ｽｱ・ｺ郢ｧ竏夲ｽ・

闔会ｽｮ邵ｺ・ｫ

HEADER + INDEX = 120 bytes

邵ｺ・ｪ郢ｧ繝ｻ

chart.txt offset = 120
song.ogg offset = 320
bg.png offset = 2000320
遶ｭ・｣ INDEX郢ｧ蜻亥ｶ檎ｸｺ繝ｻ
chart.txt 120 200
song.ogg 320 2000000
bg.png 2000320 400000
遶ｭ・､ DATA郢ｧ蜻亥ｶ檎ｸｺ繝ｻ
chart.txt邵ｺ・ｮ闕ｳ・ｭ髴・ｽｫ
song.ogg邵ｺ・ｮ闕ｳ・ｭ髴・ｽｫ
bg.png邵ｺ・ｮ闕ｳ・ｭ髴・ｽｫ
4. 髫ｱ・ｭ邵ｺ髴趣ｽｼ邵ｺ邵ｺ・ｮ闔画・・ｵ繝ｻ竏ｩ

郢ｧ・ｲ郢晢ｽｼ郢晢｣ｰ陋幢ｽｴ邵ｺ・ｯ隹ｺ・｡邵ｺ・ｮ鬯・・蛻・ｸｺ・ｧ髫ｱ・ｭ邵ｺ邵ｺ・ｾ邵ｺ蜷ｶﾂ繝ｻ

遶ｭ・ｰ HEADER郢ｧ螳夲ｽｪ・ｭ郢ｧﾂ
magic
fileCount
遶ｭ・｡ INDEX郢ｧ螳夲ｽｪ・ｭ郢ｧﾂ

郢ｧ・､郢晢ｽｳ郢昴・繝｣郢ｧ・ｯ郢ｧ・ｹ郢ｧ雋槭・鬩幢ｽｨ郢晢ｽ｡郢晢ｽ｢郢晢ｽｪ邵ｺ・ｫ闖ｫ譎擾ｽｭ蛟･・邵ｺ・ｾ邵ｺ蜷ｶﾂ繝ｻ

關薙・

chart.txt -> offset 120 size 200
song.ogg -> offset 320 size 2000000
遶ｭ・｢ 陟｢繝ｻ・ｦ竏壺・郢昴・繝ｻ郢ｧ邵ｺ・ｰ邵ｺ鬘鯉ｽｪ・ｭ郢ｧﾂ

關謎ｹ昶斡邵ｺ・ｰ

chart.txt

郢ｧ螳夲ｽｪ・ｭ郢ｧﾂ邵ｺ・ｨ邵ｺ繝ｻ

郢晁ｼ斐＜郢ｧ・､郢晢ｽｫ闖ｴ蜥ｲ・ｽ・ｮ = 120
郢ｧ・ｵ郢ｧ・､郢ｧ・ｺ = 200

邵ｺ・ｪ邵ｺ・ｮ邵ｺ・ｧ

120邵ｲ繝ｻ20郢晁・縺・ｹ昴・

郢ｧ螳夲ｽｪ・ｭ邵ｺ邵ｺ・ｾ邵ｺ蜷ｶﾂ繝ｻ




notedata邵ｺ・ｮ隶堤洸ﾂ・ｰ
notedata = {
    easy = {
        [1]邵ｺ・ｨ邵ｺ・ｯ邵ｲ繝ｻ陝・・・ｯﾂ騾ｶ・ｮ邵ｺ・ｮ邵ｺ阮吮・
        [1] = {
            action="...",
            measure={4,4},
            bpm=120,
            hs=1.5,
            scrollmove={...},
            move={...}
        },
        [2] = {...}
    }
}


starttiming邵ｺ・ｮ隶堤洸ﾂ・ｰ
{
    easy = {measure={},bpm={},hs={},scrollmove={},move={},gogostart={},gogoend={},gravity={}},
    normal = {measure={},bpm={},hs={},scrollmove={},move={},gogostart={},gogoend={},gravity={}},
    hard = {measure={},bpm={},hs={},scrollmove={},move={},gogostart={},gogoend={},gravity={}},
    extra = {measure={},bpm={},hs={},scrollmove={},move={},gogostart={},gogoend={},gravity={}},
    custom = {measure={},bpm={},hs={},scrollmove={},move={},gogostart={},gogoend={},gravity={}}
}



chart.bin邵ｺ・ｮ隶堤洸ﾂ・ｰ
-- chart.bin 邵ｺ・ｮ闕ｳ・ｭ髴・ｽｫ繝ｻ蝓滓椢陝・懊・邵ｺ・ｨ邵ｺ蜉ｱ窶ｻ闖ｫ譎擾ｽｭ蛛・ｽｼ繝ｻ
return {
  meta = {
    title = "Sample Song",
    artist = "Artist Name",
    bpm = 180,
    offset = 0,
    demostart = 0,
    demoend = 30
  },
  lanes = {
    easy = {
      [1] = {
        {time = 0.500, type = "tap"},
        {time = 1.000, type = "tap"},
        {time = 1.500, type = "hold_start"},
        {time = 3.000, type = "hold_end"}
      },
      [2] = {
        {time = 0.750, type = "tap"},
        {time = 2.250, type = "tap"}
      }
    },
    normal = {
      [1] = {
        {time = 0.400, type = "tap"},
        {time = 0.900, type = "tap"},
        {time = 1.400, type = "tap"},
      },
      [2] = {
        {time = 0.600, type = "tap"},
        {time = 1.200, type = "tap"},
      }
    },
    hard = {},
    extra = {},
    custom = {}
  },
  laneTimes = {
    easy = {
      [1] = "500,1000,1500,3000",
      [2] = "750,2250"
    },
    normal = {
      [1] = "400,900,1400",
      [2] = "600,1200"
    },
    hard = {},
    extra = {},
    custom = {}
  },
  actions = {
    easy = {
      {time = 0.000, type = "BPM", measure = 1, args = {180}},
      {time = 16.000, type = "Lyric", measure = 2, text = 邵ｺ繧・旺邵ｺ繝ｻ, offset = 0.5}
    },
    normal = {},
    hard = {},
    extra = {},
    custom = {}
  }
}



]]


local createsfb = {}

local log = require("log")

-- readFile: love.filesystem.read 縺ｮ繝輔か繝ｼ繝ｫ繝舌ャ繧ｯ縺ｨ縺励※繝輔ぃ繧､繝ｫ繧堤峩謗･隱ｭ繧
local function readFile(path)
    local ok, data = pcall(love.filesystem.read, path)
    if ok and type(data) == "string" and data ~= "" then
        return data
    end
    local f, err = io.open(path, "rb")
    if f then
        local content = f:read("*a")
        f:close()
        return content
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

    local items = love.filesystem.getDirectoryItems(dirPath) or {}
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

        local ciPath, ciName = findFileCaseInsensitive(songfolder, preferredName)
        if ciPath then
            return ciPath, ciName, "meta_case_insensitive"
        end
    end

    local items = love.filesystem.getDirectoryItems(songfolder) or {}
    table.sort(items)
    for _, item in ipairs(items) do
        local lower = string.lower(item)
        if lower:match("%.wav$") or lower:match("%.ogg$") or lower:match("%.mp3$") then
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
        "jacket.jpeg",
    }
    for _, item in ipairs(candidates) do
        local p = songfolder .. "/" .. item
        if love.filesystem.getInfo(p, "file") then
            return p, item
        end
    end

    local items = love.filesystem.getDirectoryItems(songfolder) or {}
    table.sort(items)
    for _, item in ipairs(items) do
        local lower = string.lower(item)
        if lower:match("^jacket%.png$") or lower:match("^jacket%.jpg$") or lower:match("^jacket%.jpeg$") then
            local p = songfolder .. "/" .. item
            if love.filesystem.getInfo(p, "file") then
                return p, item
            end
        end
    end

    return nil, nil
end

local scratchsfl = require("scratchsfl")

local sflfoldname = scratchsfl.foldname
local filelist = scratchsfl.list
local sflpath = scratchsfl.path


local sflmeta = {}
local sfldiff = {}
local sfllevel = {}

local function trimString(text)
    return type(text) == "string" and text:gsub("^%s+", ""):gsub("%s+$", "") or text
end

local function parseDiffHeader(header)
    if type(header) ~= "string" then
        return nil, nil
    end

    header = trimString(header)
    local idxToken, levelToken
    local quoteChar = nil
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
        elseif ch == '"' or ch == "'" then
            quoteChar = ch
        elseif ch == "," then
            tokenCount = tokenCount + 1
            local token = trimString(header:sub(tokenStart, i - 1))
            if tokenCount == 1 then
                idxToken = token
            elseif tokenCount == 2 then
                levelToken = token
                break
            end
            tokenStart = i + 1
        end
    end

    if tokenCount == 1 then
        levelToken = trimString(header:sub(tokenStart))
    end

    if not idxToken then
        return nil, nil
    end

    idxToken = trimString(idxToken)
    local idx = tonumber(idxToken)
    return idx, levelToken
end

local function parseDiffLevel(diffMeta)
    local _, levelToken = parseDiffHeader(diffMeta)
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
        local startPos, openParen = data:find("diff%s*%(", pos)
        if not startPos then
            break
        end

        local headerStart = openParen + 1
        local i = headerStart
        local quoteChar = nil
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

        local header = data:sub(headerStart, headerEnd - 1)
        local bodyStart = headerEnd + 1
        local braceStart = data:find("{", bodyStart)
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

        local body = data:sub(braceStart + 1, bodyEnd - 1)
        table_insert(blocks, {header = trimString(header), body = trimString(body)})
        pos = bodyEnd + 1
    end

    return blocks
end

local notedata = {
    easy = {},
    normal = {},
    hard = {},
    extra = {},
    custom = {}
}

local chartdata = {}

local starttiming = {
    easy = {measure={},bpm={},hs={},scrollmove={},move={},gogostart={},gogoend={},gravity={}},
    normal = {measure={},bpm={},hs={},scrollmove={},move={},gogostart={},gogoend={},gravity={}},
    hard = {measure={},bpm={},hs={},scrollmove={},move={},gogostart={},gogoend={},gravity={}},
    extra = {measure={},bpm={},hs={},scrollmove={},move={},gogostart={},gogoend={},gravity={}},
    custom = {measure={},bpm={},hs={},scrollmove={},move={},gogostart={},gogoend={},gravity={}}
}

local measuretime = {
    easy = {},
    normal = {},
    hard = {},
    extra = {},
    custom = {}
}

local diffs = {"easy","normal","hard","extra","custom"}

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
        elseif n >= 0 and n <= 4 then
            return diffs[n + 1]
        end
    end
    return nil
end

local function isMeaningfulDiffBody(body)
    return type(body) == "string" and body:match("%S") ~= nil
end

local function parseSflDiffs(data)
    local textDiff = {easy=nil, normal=nil, hard=nil, extra=nil, custom=nil}
    local levelDiff = {easy=nil, normal=nil, hard=nil, extra=nil, custom=nil}
    if type(data) ~= "string" then
        return textDiff, levelDiff
    end

    -- Build index detection from actual diff blocks first.
    local indices = {}
    local blocks = extractSflDiffBlocks(data)
    for _, blockInfo in ipairs(blocks) do
        local idxNum = parseDiffHeader(blockInfo.header)
        if idxNum then
            table_insert(indices, idxNum)
        end
    end
    if #indices == 0 then
        -- Fallback for malformed blocks that still have diff metadata.
        for idx, _ in string.gmatch(data, 'diff%s*%(%s*([0-9]+)%s*,%s*([0-9%.]+)') do
            local idxNum = tonumber(idx)
            if idxNum then
                table_insert(indices, idxNum)
            end
        end
    end
    log.trace("  parseSflDiffs: Found diff indices: " .. table_concat(indices, ", "))

    local zeroBased = false
    local oneBased = false
    for _,v in ipairs(indices) do
        if v == 0 then zeroBased = true end
        if v >= 1 and v <= 5 then oneBased = true end
    end

    if zeroBased then
        oneBased = false
    elseif not oneBased then
        oneBased = true
    end
    log.trace("  parseSflDiffs: zeroBased=" .. tostring(zeroBased) .. ", oneBased=" .. tostring(oneBased))

    -- Extract both level and the actual diff text block.
    local count = 0
    for _, blockInfo in ipairs(blocks) do
        local idxNum, levelToken = parseDiffHeader(blockInfo.header)
        local tag = getDiffTagFromIndex(idxNum, zeroBased)
        if tag then
            if levelToken then
                levelDiff[tag] = levelToken
            else
                local fallbackLevel = parseDiffLevel(blockInfo.header)
                if fallbackLevel then
                    levelDiff[tag] = fallbackLevel
                end
            end

            if isMeaningfulDiffBody(blockInfo.body) then
                textDiff[tag] = blockInfo.body
                count = count + 1
                log.trace("  parseSflDiffs: idx=" .. tostring(idxNum) .. " -> tag=" .. tag .. " -> level=" .. tostring(levelDiff[tag]))
            else
                textDiff[tag] = nil
                levelDiff[tag] = nil
                log.trace("  parseSflDiffs: idx=" .. tostring(idxNum) .. " -> tag=" .. tag .. " -> empty body ignored")
            end
        else
            log.trace("  parseSflDiffs: idx=" .. tostring(idxNum) .. " -> no tag found")
        end
    end
    log.debug("  parseSflDiffs: Extracted " .. count .. " difficulty levels - easy=" .. tostring(levelDiff.easy) .. ", normal=" .. tostring(levelDiff.normal) .. 
              ", hard=" .. tostring(levelDiff.hard) .. ", extra=" .. tostring(levelDiff.extra) .. ", custom=" .. tostring(levelDiff.custom))

    return textDiff, levelDiff
end

local function parseSflLaneNotes(text)
    local notes = {}
    local noteCount = 0
    if type(text) ~= "string" then
        return notes
    end

    local function trimLocal(line)
        return (line:gsub("^%s+", ""):gsub("%s+$", ""))
    end

    local measureNum = 0
    local currentGravity = 1  -- 迴ｾ蝨ｨ縺ｮ驥榊鴨譁ｹ蜷・
    local fullWidthHash = "\239\188\131" -- UTF-8 for U+FF03
    local normalized = text
    if normalized:sub(-1) ~= ";" then
        normalized = normalized .. ";"
    end

    for measureBlock in normalized:gmatch("([^;]-);") do
        measureNum = measureNum + 1
        local laneCursor = 0

        for line in measureBlock:gmatch("[^\r\n]+") do
            local clean = trimLocal(line:gsub("//.*$", ""))
            if clean ~= "" then
                clean = clean:gsub(fullWidthHash, "#")
                if clean:sub(1, 1) == "#" then
                    local cmd, rest = clean:match("^#([%w_]+)%s*(.*)")
                    if cmd and string.lower(cmd) == "gravity" then
                        local g = tonumber((rest or ""):match("([%-%d%.]+)"))
                        if g then
                            currentGravity = g
                        end
                    end
                else
                    local noSpace = clean:gsub("%s+", "")
                    local lineWithComma = noSpace
                    if lineWithComma:sub(-1) ~= "," then
                        lineWithComma = lineWithComma .. ","
                    end

                    for segment in lineWithComma:gmatch("([^,]*),") do
                        laneCursor = laneCursor + 1
                        local laneIndex = laneCursor
                        if laneIndex <= 6 then
                            local segmentLen = #segment
                            if segmentLen > 0 then
                                for pos = 1, segmentLen do
                                    local c = segment:sub(pos, pos)
                                    if c ~= "0" then
                                        local noteType = tonumber(c)
                                        if noteType then
                                            noteCount = noteCount + 1
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
        easy = {measure={},bpm={},hs={},scrollmove={},move={},gogostart={},gogoend={},gravity={}},
        normal = {measure={},bpm={},hs={},scrollmove={},move={},gogostart={},gogoend={},gravity={}},
        hard = {measure={},bpm={},hs={},scrollmove={},move={},gogostart={},gogoend={},gravity={}},
        extra = {measure={},bpm={},hs={},scrollmove={},move={},gogostart={},gogoend={},gravity={}},
        custom = {measure={},bpm={},hs={},scrollmove={},move={},gogostart={},gogoend={},gravity={}}
    }

    measuretime = {
        easy = {},
        normal = {},
        hard = {},
        extra = {},
        custom = {}
    }
end

local function basicSerialize(t)
    local function serializeValue(v)
        if type(v) == "table" then
            return basicSerialize(v)
        elseif type(v) == "string" then
            return string_format("%q", v)
        end
        return tostring(v)
    end

    local parts = {}
    local partsCount = 0
    for k, v in pairs(t) do
        partsCount = partsCount + 1
        local key = (type(k) == "string") and string_format("[%q]", k) or string_format("[%d]", k)
        parts[partsCount] = key .. "=" .. serializeValue(v)
    end

    return "{" .. table_concat(parts, ",") .. "}"
end

local function buildDirectCollectionsFromSongs()
    local localScratchsfl = require("scratchsfl")
    localScratchsfl.load()

    local foldnames = localScratchsfl.foldname or {}
    sflpath = localScratchsfl.path or {}
    local basePaths = localScratchsfl.basePath or {}

    local loadedCollections = {
        audio = {},
        charts = {},
        images = {}
    }

    log.info("createsfb.load(): direct song scan started (" .. tostring(#foldnames) .. " song(s))")

    for i = 1, #foldnames do
        local foldName = foldnames[i]
        local basePath = basePaths[i] or "lib/data/Songs"
        local songfolder = basePath .. "/" .. foldName
        local archiveKey = "song:" .. tostring(foldName or i)

        resetSingleSongAnalysisState()

        local ok, err = pcall(function()
            analyze_single_song(i)

            local hasParsedDiffBlock = false
            for _, diff in ipairs(diffs) do
                if sfldiff[i] and sfldiff[i][diff] ~= nil then
                    hasParsedDiffBlock = true
                    break
                end
            end

            if not hasParsedDiffBlock then
                log.info("  direct load: skipping song with no parsed difficulty blocks: " .. tostring(foldName))
                return
            end

            local chartTable = createchartbin(i)
            local chartData = "return " .. basicSerialize(chartTable)

            loadedCollections.charts[#loadedCollections.charts + 1] = {
                name = sflpath[i] or (songfolder .. "/chart.sfl"),
                data = chartData,
                archive = archiveKey
            }

            local musicName = sflmeta[i] and sflmeta[i].musicfile
            local musicpath, resolvedMusicName, resolveMode = findAudioInFolder(songfolder, musicName)
            if musicpath then
                if resolveMode ~= "meta_exact" then
                    log.info("  direct load: music resolved by fallback (" .. tostring(resolveMode) .. "): " .. tostring(resolvedMusicName))
                end
                loadedCollections.audio[#loadedCollections.audio + 1] = {
                    name = musicpath,
                    archive = archiveKey,
                    sourcePath = musicpath
                }
            else
                log.warn("  direct load: music file not found in " .. tostring(songfolder) .. " (meta=" .. tostring(musicName) .. ")")
            end

            local jacketPath = findJacketInFolder(songfolder)
            if jacketPath then
                loadedCollections.images[#loadedCollections.images + 1] = {
                    name = jacketPath,
                    archive = archiveKey,
                    sourcePath = jacketPath
                }
            end
        end)

        if not ok then
            log.warn("  direct load: failed to parse song '" .. tostring(foldName) .. "': " .. tostring(err))
        end
    end

    return loadedCollections
end


function createsfb.load(opts)
    if type(opts) == "boolean" then
        opts = {forceRebuildAll = opts}
    elseif type(opts) ~= "table" then
        opts = {}
    end
    local forceRebuildAll = opts.forceRebuildAll == true
    log.info("createsfb.load() called (direct mode, forceRebuildAll=" .. tostring(forceRebuildAll) .. ")")

    local loadedCollections = nil
    local ok, err = pcall(function()
        loadedCollections = buildDirectCollectionsFromSongs()
    end)
    if not ok then
        log.error("createsfb.load() failed in direct mode: " .. tostring(err))
        return nil
    end

    loadedCollections = loadedCollections or {audio = {}, charts = {}, images = {}}

    log.info(string_format(
        "createsfb.load(): direct collections audio=%d charts=%d images=%d",
        #(loadedCollections.audio or {}),
        #(loadedCollections.charts or {}),
        #(loadedCollections.images or {})
    ))

    log.info("createsfb.load() completed (direct mode)")
    return loadedCollections
end

local function buildArchiveNameFromFoldName(foldname)
    local archiveBase = foldname or "song"
    archiveBase = archiveBase:gsub("[%c%?%*\\/<>|:\"]", "")
    if archiveBase == "" then
        archiveBase = "song"
    end
    return archiveBase .. ".sfb"
end

local function parseGenresFromSfl(data)
    local genres = {}
    local genreCount = 0
    local seen = {}

    local function addGenre(value)
        if type(value) ~= "string" then
            return
        end
        local cleaned = value:match("^%s*(.-)%s*$") or value
        if cleaned ~= "" and not seen[cleaned] then
            seen[cleaned] = true
            genreCount = genreCount + 1
            genres[genreCount] = cleaned
        end
    end

    if type(data) == "string" then
        for g in data:gmatch('genre%s*%(%s*"([^"]-)"%s*%)') do
            addGenre(g)
        end
        for g in data:gmatch("genre%s*%(%s*'([^']-)'%s*%)") do
            addGenre(g)
        end
    end

    if genreCount == 0 then
        genres[1] = "Unknown"
    end

    return genres
end



function loadsflfile()
    if type(sflpath) ~= "table" or #sflpath == 0 then
        log.warn("loadsflfile: no sflpath available")
        return
    end

    for i = 1, #sflpath do

        local data = readFile(sflpath[i])

        sflmeta[i] = {}
        sfldiff[i] = {}

        local parsedSfldiff, parsedSfllevel = nil, nil
        if type(data) == "string" then
            sflmeta[i].title,
            sflmeta[i].musicfile,
            sflmeta[i].bpm =
            data:match('meta%("([^"]+)",([^,]+),([^%)]+)%)')
            sflmeta[i].url = data:match('url%("([^"]+)"%)')
            sflmeta[i].artist = data:match('artist%("([^"]+)"%)')
            sflmeta[i].offset = data:match('offset%(([^%)]+)%)')
            sflmeta[i].volume = data:match('volume%(([^%)]+)%)')
            sflmeta[i].demostart = data:match('demostart%(([^%)]+)%)')
            sflmeta[i].demoend = data:match('demoend%(([^%)]+)%)')
            sflmeta[i].genre = parseGenresFromSfl(data)

            parsedSfldiff, parsedSfllevel = parseSflDiffs(data)
        end

        parsedSfllevel = parsedSfllevel or {}
        sfldiff[i] = parsedSfldiff

        sfllevel[i] = {}
        for _, diff in ipairs(diffs) do
            sfllevel[i][diff] = parsedSfllevel[diff]
        end
        sfllevel[i].hasLevel = false
        for _, diff in ipairs(diffs) do
            if sfllevel[i][diff] and sfllevel[i][diff] ~= "" then
                sfllevel[i].hasLevel = true
                break
            end
        end
    end

end



function createnotedata()

    if type(sflpath) ~= "table" or #sflpath == 0 then
        log.warn("createnotedata: no sflpath available")
        return
    end

    loadsflfile()

    for i = 1, #sflpath do

        for _,diff in ipairs(diffs) do

            if sfldiff[i][diff] then
                notedata[diff][i] = sfldiff[i][diff]
            end

        end

    end

end



function analysissfl()

    if type(sflpath) ~= "table" or #sflpath == 0 then
        log.warn("analysissfl: no sflpath available")
        return
    end

    createnotedata()

    local function parseNotes(text)
        return parseSflLaneNotes(text)
    end

    for i = 1, #sflpath do

        for _,diff in ipairs(diffs) do

            local actiontext = notedata[diff][i]

            if actiontext then

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

                local data = notedata[diff][i]

                for down,up in actiontext:gmatch("#Measure%s+(%d+)%s+(%d+)") do
                    data.measure = {tonumber(down),tonumber(up)}
                end

                for bpm in actiontext:gmatch("#BPM%s+([%d%.]+)") do
                    data.bpm = tonumber(bpm)
                end

                for hs in actiontext:gmatch("#HS%s+([%d%.]+)") do
                    data.hs = tonumber(hs)
                end

                for scroll,speed,timing,easing in actiontext:gmatch("#ScrollMove%s+([^%s]+)%s+([^%s]+)%s+([^%s]+)%s+([^%s]+)") do

                    table_insert(data.scrollmove,{
                        scroll = tonumber(scroll),
                        speed = tonumber(speed),
                        timing = tonumber(timing),
                        easing = easing
                    })

                end

                for note,from,to,timing,easing in actiontext:gmatch("#Move%s+([^%s]+)%s+([^%s]+)%s+([^%s]+)%s+([^%s]+)%s+([^%s]+)") do

                    table_insert(data.move,{
                        note = tonumber(note),
                        from = tonumber(from),
                        to = tonumber(to),
                        timing = tonumber(timing),
                        easing = easing
                    })

                end

                if actiontext:find("#GogoStart") then
                    data.gogostart = true
                end

                if actiontext:find("#GogoEnd") then
                    data.gogoend = true
                end

                for g in actiontext:gmatch("#Gravity%s+([^%s]+)") do
                    data.gravity = tonumber(g)
                end

            end

        end

    end

end



function loadaction()

    if type(sflpath) ~= "table" or #sflpath == 0 then
        log.warn("loadaction: no sflpath available")
        return
    end

    analysissfl()

    for i = 1, #sflpath do

        for _,diff in ipairs(diffs) do

            local data = notedata[diff][i]

            if data then

                if data.measure then
                    table_insert(starttiming[diff].measure,{i,data.measure})
                end

                if data.bpm then
                    table_insert(starttiming[diff].bpm,{i,data.bpm})
                end

                if data.hs then
                    table_insert(starttiming[diff].hs,{i,data.hs})
                end

                if #data.scrollmove > 0 then
                    table_insert(starttiming[diff].scrollmove,{i,data.scrollmove})
                end

                if #data.move > 0 then
                    table_insert(starttiming[diff].move,{i,data.move})
                end

                if data.gogostart then
                    table_insert(starttiming[diff].gogostart,{i,true})
                end

                if data.gogoend then
                    table_insert(starttiming[diff].gogoend,{i,true})
                end

                if data.gravity then
                    table_insert(starttiming[diff].gravity,{i,data.gravity})
                end

            end

        end

    end

end



function calculationmeasuretime()

    if type(sflpath) ~= "table" or #sflpath == 0 then
        log.warn("calculationmeasuretime: no sflpath available")
        return
    end

    loadaction()

    for _, diff in ipairs(diffs) do

        for i = 1, #sflpath do

            local data = notedata[diff][i]

            if data and data.measure then

                local down = data.measure[1]
                local up = data.measure[2]

                local bpm = data.bpm or tonumber(sflmeta[i].bpm)

                if bpm then
                    measuretime[diff][i] = 240 / bpm * (up/down)
                end

            end

        end

    end

end


-- (闕ｳ・ｭ騾｡・･: writeU8, writeU32 邵ｺ・ｪ邵ｺ・ｩ邵ｺ・ｮ髯ｬ諛ｷ蜍ｧ鬮｢・｢隰ｨ・ｰ郢ｧ繝ｻnotedata 驕ｲ蟲ｨ繝ｻ陞溽判辟夊楜螟ゑｽｾ・ｩ邵ｺ・ｯ邵ｺ譏ｴ繝ｻ邵ｺ・ｾ邵ｺ・ｾ)

-- 郢晢ｽｫ郢晢ｽｼ郢晄懊・邵ｺ・ｧ陞ｳ迚吶・邵ｺ・ｫ陞ｳ貅ｯ・｡蠕後堤ｸｺ髦ｪ・狗ｹｧ蛹ｻ竕ｧ邵ｺ・ｫ邵ｲ竏ｬ・ｧ・｣隴ｫ莉吶・騾・・・堤ｸｲ蠕後≧郢晢ｽｳ郢昴・繝｣郢ｧ・ｯ郢ｧ・ｹ i邵ｲ髦ｪ竊楢汞・ｾ陟｢諛奇ｼ・ｸｺ蟶吮穐邵ｺ繝ｻ
function loadsflfile_indexed(i)
    if type(sflpath) ~= "table" or not sflpath[i] then
        log.warn("loadsflfile_indexed: invalid index or sflpath")
        return
    end

    local data = readFile(sflpath[i])
    if not data then return end

    sflmeta[i] = {}
    sfldiff[i] = {}

local parsedSfldiff, parsedSfllevel = nil, nil

        sflmeta[i].title,
    sflmeta[i].musicfile,
    sflmeta[i].bpm =
    data:match('meta%("([^"]+)",([^,]+),([^%)]+)%)')

    sflmeta[i].artist = data:match('artist%("([^"]+)"%)')
    sflmeta[i].offset = data:match('offset%(([^%)]+)%)')
    sflmeta[i].volume = data:match('volume%(([^%)]+)%)')
    sflmeta[i].demostart = data:match('demostart%(([^%)]+)%)')
    sflmeta[i].demoend = data:match('demoend%(([^%)]+)%)')
    sflmeta[i].url = data:match('url%s*%(%s*["\'](.-)["\']%s*%)')
    sflmeta[i].genre = parseGenresFromSfl(data)

    local parsedSfldiff, parsedSfllevel = parseSflDiffs(data)

    sfldiff[i] = parsedSfldiff

    sfllevel[i] = {}
    for _, diff in ipairs(diffs) do
        sfllevel[i][diff] = parsedSfllevel[diff]
    end

    sfllevel[i].hasLevel = false
    for _, diff in ipairs(diffs) do
        if sfllevel[i][diff] and sfllevel[i][diff] ~= "" then
            sfllevel[i].hasLevel = true
            break
        end
    end
end

diffs = {"easy","normal","hard","extra","custom"}

------------------------------------------------
-- 髫ｴ諞ｺ謫・囓・｣隴ｫ繝ｻ
------------------------------------------------
function analyze_single_song(i)
    if type(sflpath) ~= "table" or not sflpath[i] then
        log.warn("analyze_single_song: invalid index or missing sflpath[" .. tostring(i) .. "]")
        return
    end

    loadsflfile_indexed(i)
    
    log.debug("  analyze_single_song: index=" .. i)
    log.debug("    title=" .. tostring(sflmeta[i].title))
    log.debug("    sfllevel[i]=" .. tostring(sfllevel[i]))
    if sfllevel[i] then
        log.debug("      easy=" .. tostring(sfllevel[i].easy))
        log.debug("      normal=" .. tostring(sfllevel[i].normal))
        log.debug("      hard=" .. tostring(sfllevel[i].hard))
        log.debug("      extra=" .. tostring(sfllevel[i].extra))
        log.debug("      custom=" .. tostring(sfllevel[i].custom))
        log.debug("      hasLevel=" .. tostring(sfllevel[i].hasLevel))
    end

    local function parseNotes(text)
        return parseSflLaneNotes(text)
    end

    for _, diff in ipairs(diffs) do

        local actiontext = nil
        if sfldiff[i] then
            actiontext = sfldiff[i][diff]
        end
        if (not actiontext or actiontext == "") and notedata[diff] then
            actiontext = notedata[diff][i]
        end

        if actiontext then

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

            local data = notedata[diff][i]

            for down, up in actiontext:gmatch("#Measure%s+(%d+)%s+(%d+)") do
                data.measure = {tonumber(down), tonumber(up)}
            end

            for bpm in actiontext:gmatch("#BPM%s+([%d%.]+)") do
                data.bpm = tonumber(bpm)
            end

            for hs in actiontext:gmatch("#HS%s+([%d%.]+)") do
                data.hs = tonumber(hs)
            end
            for gravity in actiontext:gmatch("#gravity%s+([%-%d%.]+)") do
                data.gravity = tonumber(gravity)
            end

            if data.measure then
                table_insert(starttiming[diff].measure,{i,data.measure})
            end

            if data.bpm then
                table_insert(starttiming[diff].bpm,{i,data.bpm})
            end

            if data.hs then
                table_insert(starttiming[diff].hs,{i,data.hs})
            end

            if data.gravity then
                table_insert(starttiming[diff].gravity,{i,data.gravity})
            end

            if data.measure then

                local down = data.measure[1]
                local up = data.measure[2]

                local bpm = data.bpm

                if not bpm then
                    if sflmeta[i] then
                        bpm = tonumber(sflmeta[i].bpm)
                    end
                end

                if bpm then
                    measuretime[diff][i] = 240 / bpm * (up / down)
                end

            end

        end
    end
end


------------------------------------------------
-- chart.bin闖ｴ諛医・
------------------------------------------------
local function trimLine(line)
    return (line:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function buildMeasureTiming(actionText, baseBpm)
    local measures = {}
    if type(actionText) ~= "string" then
        return measures
    end

    local currentBpm = tonumber(baseBpm) or 120
    local currentDown = 4
    local currentUp = 4
    local currentTime = 0
    local measureIndex = 0
    local fullWidthHash = "\239\188\131" -- UTF-8 for U+FF03

    for measureBlock in actionText:gmatch("([^;]-);") do
        measureIndex = measureIndex + 1

        for line in measureBlock:gmatch("[^\r\n]+") do
            local clean = trimLine(line)
            if clean ~= "" and not clean:match("^//") then
                clean = clean:gsub(fullWidthHash, "#")
                if clean:sub(1, 1) == "#" then
                    local cmd, rest = clean:match("^#([%w_]+)%s*(.*)")
                    if cmd == "BPM" then
                        local v = tonumber(rest:match("([%d%.]+)"))
                        if v then currentBpm = v end
                    elseif cmd == "Measure" then
                        local down, up = rest:match("([%d%.]+)%s+([%d%.]+)")
                        if down and up then
                            currentDown = tonumber(down) or currentDown
                            currentUp = tonumber(up) or currentUp
                        end
                    end
                end
            end
        end

        local measureSec = 0
        if currentBpm and currentBpm ~= 0 then
            measureSec = 240 / currentBpm * (currentUp / currentDown)
        end

        measures[measureIndex] = {
            start = currentTime,
            duration = measureSec,
            bpm = currentBpm,
            measure = {currentDown, currentUp}
        }

        currentTime = currentTime + measureSec
    end

    return measures
end

local function parseActionEvents(actionText, measures)
    local events = {}
    if type(actionText) ~= "string" then
        return events
    end

    local measureIndex = 0
    local fullWidthHash = "\239\188\131" -- UTF-8 for U+FF03

    for measureBlock in actionText:gmatch("([^;]-);") do
        measureIndex = measureIndex + 1
        local info = measures[measureIndex] or {start = 0, duration = 0, bpm = 0}
        local measureStart = info.start or 0
        local beatSec = 0
        if info.bpm and info.bpm ~= 0 then
            beatSec = 60 / info.bpm
        end

        for line in measureBlock:gmatch("[^\r\n]+") do
            local clean = trimLine(line)
            if clean ~= "" and not clean:match("^//") then
                clean = clean:gsub(fullWidthHash, "#")
                if clean:sub(1, 1) == "#" then
                    local cmd, rest = clean:match("^#([%w_]+)%s*(.*)")
                    if cmd then
                        local event = {time = measureStart, type = cmd, measure = measureIndex}
                        if cmd == "Lyric" then
                            local lyric, offset = rest:match("^\"(.-)\"%s*([%-%d%.]*)")
                            lyric = lyric or ""
                            local offsetNum = tonumber(offset)
                            event.text = lyric
                            if offsetNum then
                                event.offset = offsetNum
                                if beatSec > 0 then
                                    event.time = measureStart + offsetNum * beatSec
                                    event.offsetSec = offsetNum * beatSec
                                end
                            end
                        else
                            local args = {}
                            for token in rest:gmatch("[^%s]+") do
                                local num = tonumber(token)
                                table_insert(args, num ~= nil and num or token)
                            end
                            event.args = args
                        end
                        table_insert(events, event)
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
        local key = string.lower(noteType)
        return noteTypeMap[key] or 0
    end
    return 0
end

local function secToMs(sec)
    local n = tonumber(sec) or 0
    return math_floor(n * 1000 + 0.5)
end

function createchartbin(i)
    local chart = {}

    ------------------------------------------------
    -- META
    ------------------------------------------------
    local title, artist, bpm, offset = "", "", 0, 0
    local volume = 1.0
    if sflmeta[i] then
        title  = sflmeta[i].title  or ""
        artist = sflmeta[i].artist or ""
        bpm    = tonumber(sflmeta[i].bpm)    or 0
        offset = tonumber(sflmeta[i].offset) or 0
        demostart = tonumber(sflmeta[i].demostart) or 0
        demoend = tonumber(sflmeta[i].demoend) or 0
        volume = tonumber(sflmeta[i].volume) or 1.0
        url = sflmeta[i].url or ""
        genre = sflmeta[i].genre
    end
    
    log.debug("  createchartbin: Creating chart for index " .. i .. ", title=" .. title)
    log.debug("  sfllevel[" .. i .. "]=" .. tostring(sfllevel[i]))
    if sfllevel[i] then
        log.debug("    easy=" .. tostring(sfllevel[i].easy) .. ", normal=" .. tostring(sfllevel[i].normal) .. 
                  ", hard=" .. tostring(sfllevel[i].hard) .. ", extra=" .. tostring(sfllevel[i].extra) .. 
                  ", custom=" .. tostring(sfllevel[i].custom))
    end

    chart.meta = {
        title  = title,
        artist = artist,
        bpm    = bpm,
        offset = offset,
        volume = volume,
        demostart = demostart,
        demoend = demoend,
        levels = sfllevel[i] or {},
        hasLevel = (sfllevel[i] and sfllevel[i].hasLevel) or false,
        level = (sfllevel[i] and (
            sfllevel[i].easy or sfllevel[i].normal or sfllevel[i].hard or sfllevel[i].extra or sfllevel[i].custom
        )) or nil,
        url = sflmeta[i].url,
        genre = sflmeta[i].genre
    }

    ------------------------------------------------
    -- LANE邵ｺ譁絶・邵ｺ・ｮ驕倩ｲ櫁・闖ｴ髦ｪ繝ｮ郢晢ｽｼ郢昴・
    ------------------------------------------------
    -- 郢晢ｽｬ郢晏生ﾎ晁崕・･邵ｺ・ｫ郢晢ｽｬ郢晢ｽｼ郢晢ｽｳ郢ｧ郢ｧ・､郢晄ｺ佩ｦ郢ｧ・ｰ郢ｧ蟶晏ｯ秘坎繝ｻ
    local laneTiming = {}
    local measureTimeline = {}
    local actionsByDiff = {}

    for _, diff in ipairs(diffs) do
        laneTiming[diff] = {}
        actionsByDiff[diff] = {}

        local diffText = nil
        if sfldiff[i] and sfldiff[i][diff] then
            diffText = sfldiff[i][diff]
        elseif notedata[diff] and notedata[diff][i] and notedata[diff][i].action then
            diffText = notedata[diff][i].action
        end

        if diffText then
            measureTimeline[diff] = buildMeasureTiming(diffText, bpm)
            actionsByDiff[diff] = parseActionEvents(diffText, measureTimeline[diff])
        end

        local data = notedata[diff][i]
        if data and data.notes then
            for _, note in ipairs(data.notes) do
                local lane = tonumber(note.lane) or note.lane
                local sec  = 0

                -- 陝・・・ｯﾂ隴弱ｋ菫｣ * 陝・・・ｯﾂ陷繝ｻ・ｽ蜥ｲ・ｽ・ｮ邵ｺ・ｧ驕伜争驪､驍ゅ・
                local m = measureTimeline[diff] and measureTimeline[diff][note.measure]
                if m then
                    sec = (m.start or 0) + (note.pos or 0) * (m.duration or 0)
                elseif measuretime[diff] and measuretime[diff][i] then
                    sec = (note.measure-1) * measuretime[diff][i] + (note.pos or 0) * measuretime[diff][i]
                end

                laneTiming[diff][lane] = laneTiming[diff][lane] or {}
                local laneNotes = laneTiming[diff][lane]
                laneNotes[#laneNotes + 1] = {
                    time = sec,
                    timeMs = secToMs(sec),
                    type = noteTypeToNumber(note.type),
                    gravity = tonumber(note.gravity)
                }
            end
        end
    end

    -- 陷ｷ繝ｻﾎ樒ｹ晢ｽｼ郢晢ｽｳ邵ｺ・ｧ隴弱ｋ菫｣鬯・・縺溽ｹ晢ｽｼ郢晁肩・ｼ逎ｯ螻ｮ隴冗§・ｺ・ｦ邵ｺ譁絶・繝ｻ繝ｻ
    for _, diff in ipairs(diffs) do
        for lane, notes in pairs(laneTiming[diff]) do
            table.sort(notes, function(a,b) return (a.timeMs or 0) < (b.timeMs or 0) end)
        end
    end

    chart.lanes = laneTiming

    -- Create unified notes format with lane information (遘呈焚縺ｨlane繧偵ユ繝ｼ繝悶Ν蛹・
    local notes = {}
    for _, diff in ipairs(diffs) do
        notes[diff] = {}
        for lane, laneNotes in pairs(laneTiming[diff]) do
            for _, n in ipairs(laneNotes) do
                notes[diff][#notes[diff] + 1] = {
                    time = n.time,
                    timeMs = n.timeMs or secToMs(n.time),
                    lane = lane,
                    type = n.type,
                    gravity = n.gravity
                }
            end
        end
        -- Sort by time
        table.sort(notes[diff], function(a,b) return (a.timeMs or 0) < (b.timeMs or 0) end)
    end
    chart.notes = notes

    -- 陷ｷ繝ｻﾎ樒ｹ晢ｽｼ郢晢ｽｳ邵ｺ譁絶・邵ｺ・ｫ郢晏ｼｱ繝ｻ郢昴・繝ｻ隴弱ｋ菫｣郢ｧ蛛ｵﾎ醍ｹ晢ｽｪ驕伜・縲堤ｹｧ・ｫ郢晢ｽｳ郢晄ｧｫ邇・崕繝ｻ・願ｭ√・・ｭ諤懊・邵ｺ・ｫ陞溽判驪､繝ｻ逎ｯ螻ｮ隴冗§・ｺ・ｦ邵ｺ譁絶・繝ｻ繝ｻ
    local laneTimes = {}
    local laneNumbers = {}
    for _, diff in ipairs(diffs) do
        laneTimes[diff] = {}
        laneNumbers[diff] = {}
        for lane, notes in pairs(laneTiming[diff]) do
            local times = {}
            local numeric = {times = {}, types = {}, pairs = {}}
            local timesCount = 0
            for _, n in ipairs(notes) do
                local noteMs = n.timeMs or secToMs(n.time)
                local noteType = noteTypeToNumber(n.type)
                timesCount = timesCount + 1
                times[timesCount] = noteMs
                numeric.times[timesCount] = noteMs
                numeric.types[timesCount] = noteType
                numeric.pairs[timesCount] = {noteMs, noteType}
            end
            laneTimes[diff][lane] = table_concat(times, ",")
            laneNumbers[diff][lane] = numeric
        end
    end
    chart.laneTimes = laneTimes
    chart.laneNumbers = laneNumbers
    chart.actions = actionsByDiff

    return chart
end














------------------------------------------------
-- SFB闖ｴ諛医・
------------------------------------------------
function createsfbfile(opts)
    opts = opts or {}
    local forceRebuildAll = opts.forceRebuildAll == true

    local scratchsfl = require("scratchsfl")
    scratchsfl.load()

    local foldnames = scratchsfl.foldname
    sflpath = scratchsfl.path

    if #foldnames == 0 then
        log.warn("No songs found")
        return
    end

    log.info("Starting SFB file creation. Found " .. #foldnames .. " song(s). forceRebuildAll=" .. tostring(forceRebuildAll))

    if forceRebuildAll then
        -- Remove previously generated archives to avoid stale/misencoded mixes.
        local rootItems = love.filesystem.getDirectoryItems("") or {}
        for _, name in ipairs(rootItems) do
            if type(name) == "string" and name:match("%.sfb$") then
                love.filesystem.remove(name)
            end
        end
    end

    for i = 1, #foldnames do
        local archiveName = buildArchiveNameFromFoldName(foldnames[i])
        if not forceRebuildAll and love.filesystem.getInfo(archiveName) then
            log.info("Skipping existing archive [" .. i .. "/" .. #foldnames .. "]: " .. archiveName)
            goto skip_song
        end

        log.info("Processing [" .. i .. "/" .. #foldnames .. "]: " .. foldnames[i])

        -- variable initialization for this iteration
        sflmeta[i] = {}
        sfldiff[i] = {}
        notedata = { easy={}, normal={}, hard={}, extra={}, custom={} }
        starttiming = {
            easy={measure={},bpm={},hs={},scrollmove={},move={},gogostart={},gogoend={},gravity={}},
            normal={measure={},bpm={},hs={},scrollmove={},move={},gogostart={},gogoend={},gravity={}},
            hard={measure={},bpm={},hs={},scrollmove={},move={},gogostart={},gogoend={},gravity={}},
            extra={measure={},bpm={},hs={},scrollmove={},move={},gogostart={},gogoend={},gravity={}},
            custom={measure={},bpm={},hs={},scrollmove={},move={},gogostart={},gogoend={},gravity={}}
        }
        measuretime = { easy={}, normal={}, hard={}, extra={}, custom={} }

        -- chart analysis with error handling
        local ok, err = pcall(function() analyze_single_song(i) end)
        if not ok then
            log.warn("  analyze_single_song() failed for folder '" .. foldnames[i] .. "': " .. tostring(err))
            goto skip_song
        end

        ------------------------------------------------
        -- 郢晁ｼ斐＜郢ｧ・､郢晢ｽｫ陷ｿ譛ｱ蟇・
        ------------------------------------------------
        local songfolder = "lib/data/Songs/" .. foldnames[i]
        local files = {}

        -- 1. 髢ｭ譴ｧ蜍ｹ騾包ｽｻ陷剃ｸ翫・陷ｿ髢・ｾ繝ｻ
        local bgpath, jacketName = findJacketInFolder(songfolder)
        if bgpath then
            local ext = string.match(string.lower(jacketName or bgpath), "%.([%w]+)$")
            if ext then
                table_insert(files, {
                    name = "jacket." .. ext,
                    data = readFile(bgpath)
                })
            else
                -- fallback
                table_insert(files, {
                    name = "jacket",
                    data = readFile(bgpath)
                })
            end
        end

        -- 2. 鬮ｻ・ｳ隶鯉ｽｽ郢晁ｼ斐＜郢ｧ・､郢晢ｽｫ邵ｺ・ｮ陷ｿ髢・ｾ繝ｻ
        local musicName = sflmeta[i] and sflmeta[i].musicfile
        local musicpath, resolvedMusicName, resolveMode = findAudioInFolder(songfolder, musicName)
        if musicpath then
            if resolveMode ~= "meta_exact" then
                log.info("  Info: Music file resolved by fallback (" .. resolveMode .. "): " .. tostring(resolvedMusicName))
            end
            table_insert(files, {
                name = sanitizeEntryName(resolvedMusicName, "music.wav"),
                data = readFile(musicpath)
            })
        else
            log.warn("  Warning: Music file not found in folder: " .. songfolder .. " (meta=" .. tostring(musicName) .. ")")
        end

        -- 3. [隴厄ｽｲ陷ｷ豎・bin 邵ｺ・ｮ闖ｴ諛医・繝ｻ蛹ｻ繝ｦ郢晢ｽｼ郢晄じﾎ晉ｹｧ蜻域椢陝・懊・陋ｹ蜴・ｽｼ繝ｻ
        local chartTable = createchartbin(i)
        -- 驍・ｽ｡陷雁･竊醍ｹ昴・繝ｻ郢晄じﾎ晉ｹｧ・ｷ郢晢ｽｪ郢ｧ・｢郢晢ｽｩ郢ｧ・､郢ｧ・ｺ (JSON郢晢ｽｩ郢ｧ・､郢晄じﾎ帷ｹ晢ｽｪ邵ｺ蠕娯旺郢ｧ荵昶・郢ｧ蟲ｨ笳守ｸｺ・｡郢ｧ蟲ｨ・定ｬ暦ｽｨ陞ゑｽｨ)
        local function basicSerialize(t)
            local function serializeValue(v)
                if type(v) == "table" then return basicSerialize(v)
                elseif type(v) == "string" then return string_format("%q", v)
                else return tostring(v) end
            end
            local parts = {}
            for k, v in pairs(t) do
                local key = (type(k) == "string") and string_format("[%q]", k) or string_format("[%d]", k)
                table_insert(parts, key .. "=" .. serializeValue(v))
            end
            return "{" .. table_concat(parts, ",") .. "}"
        end
        
        local chartData = "return " .. basicSerialize(chartTable)

        -- Logging after serialization - check first 500 chars of serialization
        log.debug("  After basicSerialize - first 500 chars of chartData:")
        log.debug("    " .. chartData:sub(1, 500))

        -- 隴厄ｽｲ陷ｷ謳ｾ・ｼ繝ｻitle繝ｻ蟲ｨ・堤ｹ晏生繝ｻ郢ｧ・ｹ邵ｺ・ｫ郢晁ｼ斐＜郢ｧ・､郢晢ｽｫ陷ｷ髦ｪ・帝墓ｻ薙・邵ｲ繧俄伯陷会ｽｹ隴√・・ｭ蜉ｱ繝ｻ陷台ｼ∝求邵ｲ繝ｻ
        local chartFileName = (sflmeta[i] and sflmeta[i].title) or foldnames[i] or "chart"
        chartFileName = chartFileName:gsub("[%c%?%*\\/<>|:\"]", "")
        if chartFileName == "" then
            chartFileName = "chart"
        end
        chartFileName = chartFileName .. ".bin"

        table_insert(files, {
            name = sanitizeEntryName(chartFileName, "chart.bin"),
            data = chartData
        })

        ------------------------------------------------
        -- 陷・ｽｺ陷牙ｸ帙・郢晁ｼ斐＜郢ｧ・､郢晢ｽｫ陷ｷ髦ｪ・定ｱ趣ｽｺ郢ｧ竏夲ｽ九・蛹ｻ繝ｵ郢ｧ・ｩ郢晢ｽｫ郢敖陷ｷ髦ｪ繝ｻ郢晢ｽｼ郢ｧ・ｹ繝ｻ繝ｻ
        ------------------------------------------------
        -- 隴鯉ｽ｢邵ｺ・ｫ陝・ｼ懈Β邵ｺ蜷ｶ・玖ｭ厄ｽｲ邵ｺ・ｯ郢ｧ・ｹ郢ｧ・ｭ郢昴・繝ｻ繝ｻ莠包ｽｸ蟠趣ｽｶ・ｳ陋ｻ繝ｻ繝ｻ邵ｺ騾墓ｻ薙・繝ｻ繝ｻ
        if love.filesystem.getInfo(archiveName) then
            love.filesystem.remove(archiveName)
            log.info("  Overwriting: " .. archiveName)
        end
            ------------------------------------------------
            -- 郢ｧ・｢郢晢ｽｼ郢ｧ・ｫ郢ｧ・､郢昜ｹ溷・隰後・(HEADER + INDEX + DATA)
            ------------------------------------------------
            -- 郢晏･繝｣郢敖郢晢ｽｼ闖ｴ諛医・ (Magic, Version, FileCount)
            local header = "SFB1\n1\n" .. #files .. "\n"

            -- 郢ｧ・､郢晢ｽｳ郢昴・繝｣郢ｧ・ｯ郢ｧ・ｹ邵ｺ・ｮ闔会ｽｮ髫ｪ閧ｲ・ｮ證ｦ・ｼ蛹ｻ縺檎ｹ晁ｼ斐◎郢昴・繝ｨ驍よ懊・騾包ｽｨ繝ｻ繝ｻ
            -- 郢晁ｼ斐＜郢ｧ・､郢晢ｽｫ陷ｷ繝ｻ郢ｧ・ｪ郢晁ｼ斐◎郢昴・繝ｨ,郢ｧ・ｵ郢ｧ・､郢ｧ・ｺ\n
            local tempIndexParts = {}
            local tempIndexCount = 0
            for _, f in ipairs(files) do
                tempIndexCount = tempIndexCount + 1
                tempIndexParts[tempIndexCount] = f.name .. ",0000000000,0000000000\n"
            end
            local tempIndex = table_concat(tempIndexParts)

            -- 郢昴・繝ｻ郢ｧ鬮｢蜿･・ｧ蛟ｶ・ｽ蜥ｲ・ｽ・ｮ = 郢晏･繝｣郢敖郢晢ｽｼ鬮滂ｽｷ + 郢ｧ・､郢晢ｽｳ郢昴・繝｣郢ｧ・ｯ郢ｧ・ｹ鬮滂ｽｷ
            local dataOffset = #header + #tempIndex
            local indexParts = {}
            local indexCount = 0
            local currentOffset = dataOffset

            -- 雎・ｽ｣邵ｺ蜉ｱ・樒ｹｧ・､郢晢ｽｳ郢昴・繝｣郢ｧ・ｯ郢ｧ・ｹ邵ｺ・ｮ隶堤距・ｯ繝ｻ
            for _, f in ipairs(files) do
                local fileSize = #f.data
                indexCount = indexCount + 1
                indexParts[indexCount] = f.name .. "," .. string_format("%010d", currentOffset) .. "," .. string_format("%010d", fileSize) .. "\n"
                currentOffset = currentOffset + fileSize
            end
            local index = table_concat(indexParts)

            -- 隴厄ｽｸ邵ｺ蟠趣ｽｾ・ｼ邵ｺ
            -- 郢晏･繝｣郢敖郢晢ｽｼ邵ｺ・ｨ郢ｧ・､郢晢ｽｳ郢昴・繝｣郢ｧ・ｯ郢ｧ・ｹ郢ｧ蜻亥ｶ檎ｸｺ蟠趣ｽｾ・ｼ郢ｧﾂ
            love.filesystem.write(archiveName, header .. index)
            
            -- 陷ｷ繝ｻ繝ｵ郢ｧ・｡郢ｧ・､郢晢ｽｫ邵ｺ・ｮ陞ｳ貅倥Ι郢晢ｽｼ郢ｧ郢ｧ螳夲ｽｿ・ｽ髫ｪ蛛・ｽｼ繝ｻppend繝ｻ蟲ｨ笘・ｹｧ繝ｻ
            for _, f in ipairs(files) do
                love.filesystem.append(archiveName, f.data)
            end

            log.info("  Success! Saved as: " .. archiveName)

        ::skip_song::
    end
end


-- 蜊倅ｸ譖ｲ縺ｮ蜀咲函謌仙・逅・畑蜈ｬ髢矩未謨ｰ
function createsfb.regenerateSingleSong(songIndex)
    log.info("createsfb.regenerateSingleSong() called for index=" .. tostring(songIndex))
    
    local scratchsfl = require("scratchsfl")
    scratchsfl.load()
    
    local foldnames = scratchsfl.foldname
    if not foldnames or songIndex < 1 or songIndex > #foldnames then
        log.warn("Invalid song index: " .. tostring(songIndex))
        return nil
    end
    
    log.info("Processing single song [" .. songIndex .. "]: " .. foldnames[songIndex])
    
    -- 蜊倅ｸ譖ｲ逕ｨ縺ｫ螟画焚繧貞・譛溷喧
    sflmeta[songIndex] = {}
    sfldiff[songIndex] = {}
    notedata = { easy={}, normal={}, hard={}, extra={}, custom={} }
    starttiming = {
        easy={measure={},bpm={},hs={},scrollmove={},move={},gogostart={},gogoend={},gravity={}},
        normal={measure={},bpm={},hs={},scrollmove={},move={},gogostart={},gogoend={},gravity={}},
        hard={measure={},bpm={},hs={},scrollmove={},move={},gogostart={},gogoend={},gravity={}},
        extra={measure={},bpm={},hs={},scrollmove={},move={},gogostart={},gogoend={},gravity={}},
        custom={measure={},bpm={},hs={},scrollmove={},move={},gogostart={},gogoend={},gravity={}}
    }
    measuretime = { easy={}, normal={}, hard={}, extra={}, custom={} }
    
    -- 蜊倅ｸ譖ｲ縺ｮ隗｣譫仙・逅・
    local ok, err = pcall(function() analyze_single_song(songIndex) end)
    if not ok then
        log.warn("analyze_single_song() failed for index " .. songIndex .. ": " .. tostring(err))
        return nil
    end
    
    -- 繝輔ぃ繧､繝ｫ蜃ｦ逅・ｼ域里蟄倥・ createsfbfile 蜀・・繝ｭ繧ｸ繝・け繧貞盾辣ｧ・・
    local songfolder = "lib/data/Songs/" .. foldnames[songIndex]
    local files = {}
    
    -- 繧ｸ繝｣繧ｱ繝・ヨ逕ｻ蜒上・蜿門ｾ・
    local bgpath, jacketName = findJacketInFolder(songfolder)
    if bgpath then
        local ext = string.match(string.lower(jacketName or bgpath), "%.([%w]+)$")
        if ext then
            table_insert(files, {
                name = "jacket." .. ext,
                data = readFile(bgpath)
            })
        else
            table_insert(files, {
                name = "jacket",
                data = readFile(bgpath)
            })
        end
    end
    
    -- 髻ｳ讌ｽ繝輔ぃ繧､繝ｫ縺ｮ蜿門ｾ・
    local musicName = sflmeta[songIndex] and sflmeta[songIndex].musicfile
    local musicpath, resolvedMusicName, resolveMode = findAudioInFolder(songfolder, musicName)
    if musicpath then
        if resolveMode ~= "meta_exact" then
            log.info("Music file resolved by fallback (" .. resolveMode .. "): " .. tostring(resolvedMusicName))
        end
        table_insert(files, {
            name = sanitizeEntryName(resolvedMusicName, "music.wav"),
            data = readFile(musicpath)
        })
    else
        log.warn("Music file not found in folder: " .. songfolder .. " (meta=" .. tostring(musicName) .. ")")
    end
    
    -- 繝√Ε繝ｼ繝・bin 縺ｮ菴懈・
    local chartTable = createchartbin(songIndex)
    local function basicSerialize(t)
        local function serializeValue(v)
            if type(v) == "table" then return basicSerialize(v)
            elseif type(v) == "string" then return string_format("%q", v)
            else return tostring(v) end
        end
        local parts = {}
        for k, v in pairs(t) do
            local key = (type(k) == "string") and string_format("[%q]", k) or string_format("[%d]", k)
            table_insert(parts, key .. "=" .. serializeValue(v))
        end
        return "{" .. table_concat(parts, ",") .. "}"
    end
    
    local chartData = "return " .. basicSerialize(chartTable)
    
    local chartFileName = (sflmeta[songIndex] and sflmeta[songIndex].title) or foldnames[songIndex] or "chart"
    chartFileName = chartFileName:gsub("[%c%?%*\\/<>|:\"]", "")
    if chartFileName == "" then
        chartFileName = "chart"
    end
    chartFileName = chartFileName .. ".bin"
    
    table_insert(files, {
        name = sanitizeEntryName(chartFileName, "chart.bin"),
        data = chartData
    })
    
    -- 蜃ｺ蜉帙い繝ｼ繧ｫ繧､繝悶ヵ繧｡繧､繝ｫ蜷阪ｒ豎ｺ繧√ｋ
    local archiveBase = foldnames[songIndex] or "song"
    archiveBase = archiveBase:gsub("[%c%?%*\\/<>|:\"]", "")
    if archiveBase == "" then
        archiveBase = "song"
    end
    local archiveName = archiveBase .. ".sfb"
    
    -- 譌｢縺ｫ蟄伜惠縺吶ｋ蝣ｴ蜷医・繧ｹ繧ｭ繝・・縺吶ｋ縺句炎髯､縺吶ｋ
    if love.filesystem.getInfo(archiveName) then
        love.filesystem.remove(archiveName)
        log.info("Overwriting: " .. archiveName)
    end
    
    -- SFB繝輔ぃ繧､繝ｫ逕滓・
    local header = "SFB1\n1\n" .. #files .. "\n"
    local tempIndexParts = {}
    local tempIndexCount = 0
    for _, f in ipairs(files) do
        tempIndexCount = tempIndexCount + 1
        tempIndexParts[tempIndexCount] = f.name .. ",0000000000,0000000000\n"
    end
    local tempIndex = table_concat(tempIndexParts)
    
    local dataOffset = #header + #tempIndex
    local indexParts = {}
    local indexCount = 0
    local currentOffset = dataOffset
    
    for _, f in ipairs(files) do
        local fileSize = #f.data
        indexCount = indexCount + 1
        indexParts[indexCount] = f.name .. "," .. string_format("%010d", currentOffset) .. "," .. string_format("%010d", fileSize) .. "\n"
        currentOffset = currentOffset + fileSize
    end
    local index = table_concat(indexParts)
    
    love.filesystem.write(archiveName, header .. index)
    for _, f in ipairs(files) do
        love.filesystem.append(archiveName, f.data)
    end
    
    log.info("Single song SFB regenerated: " .. archiveName)
    return archiveName
end


return createsfb








