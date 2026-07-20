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

sfb蠖｢蠑上荳ｭ霄ｫ
SFB1
繝輔ぃ繧､繝ｫ謨ｰ
繝輔ぃ繧､繝ｫ蜷・繧ｪ繝輔そ繝・ヨ,繧ｵ繧､繧ｺ
繝輔ぃ繧､繝ｫ蜷・繧ｪ繝輔そ繝・ヨ,繧ｵ繧､繧ｺ
繝輔ぃ繧､繝ｫ蜷・繧ｪ繝輔そ繝・ヨ,繧ｵ繧､繧ｺ
繝輔ぃ繧､繝ｫ繝・・繧ｿ

繝・・繧ｿ縺ｮ貂｡縺玲婿
sfbloader.load()縺ｧsfb繝輔ぃ繧､繝ｫ繧定ｪｭ縺ｿ霎ｼ繧
sfbloader.load()縺ｯ繝・・繝悶Ν繧定ｿ斐☆



meta繝・・繧ｿ螟画焚蜷・
musicName
musicartist
musicbpm
musicvolume
demostart
demoend
musicurl




]]





local sfbloader = {}

local log = require "log"

local function readLineFromString(data, pos)
    if not data or pos > #data then return nil, pos end
    local s, e = data:find("\n", pos, true)
    if s then
        local line = data:sub(pos, s - 1)
        if line:sub(-1) == "\r" then
            line = line:sub(1, -2)
        end
        return line, e + 1
    else
        local line = data:sub(pos)
        if line:sub(-1) == "\r" then
            line = line:sub(1, -2)
        end
        return line, #data + 1
    end
end

function sfbloader.load()
    log.info("sfbloader.load() started")
    local result = {
        audio = {},
        images = {},
        charts = {}
    }

    local files = love.filesystem.getDirectoryItems("")
    log.info("Found " .. #files .. " item(s) in root directory")
    
    local sfbCount = 0
    for _, filename in ipairs(files) do
        if filename:match("%.sfb$") then
            sfbCount = sfbCount + 1
            log.info("Found SFB file: " .. filename)
            local rawData = love.filesystem.read(filename)
            local data = nil
            if type(rawData) == "string" then
                data = rawData
            elseif rawData and rawData.getString then
                data = rawData:getString()
            end
            if type(data) == "string" then
                local pos = 1
                local magic
                magic, pos = readLineFromString(data, pos)
                local _versionLine
                _versionLine, pos = readLineFromString(data, pos)
                local countLine
                countLine, pos = readLineFromString(data, pos)

                local fileCount = tonumber(countLine)

                if magic == "SFB1" and fileCount then
                    local index = {}
                    local indexCount = 0
                    for i = 1, fileCount do
                        local line
                        line, pos = readLineFromString(data, pos)
                        if line then
                            local name, offset, size = line:match("([^,]+),([^,]+),([^,]+)")
                            if name and offset and size then
                                indexCount = indexCount + 1
                                index[indexCount] = {
                                    name = name,
                                    offset = tonumber(offset),
                                    size = tonumber(size)
                                }
                            end
                        end
                    end

                    local indexEnd = pos - 1
                    local minOffset = nil
                    for _, info in ipairs(index) do
                        if info.offset then
                            if not minOffset or info.offset < minOffset then
                                minOffset = info.offset
                            end
                        end
                    end
                    if minOffset and minOffset > indexEnd then
                        local delta = minOffset - indexEnd
                        for _, info in ipairs(index) do
                            info.offset = info.offset - delta
                        end
                    end

                    for _, info in ipairs(index) do
                        local startPos = info.offset + 1
                        local endPos = info.offset + info.size
                        if startPos >= 1 and endPos <= #data then
                            local rawData = data:sub(startPos, endPos)

                            local fileEntry = {
                                name = info.name,
                                data = rawData,
                                archive = filename
                            }

                            local infoName = info.name or ""
                            local lowerName = string.lower(infoName)
                            local ext = infoName:match("%.([^%.]+)$")
                            if not ext then
                                local jacketExt = lowerName:match("^jacket(%w+)$")
                                if jacketExt then
                                    ext = jacketExt
                                end
                            end
                            if ext then
                                ext = string.lower(ext)
                            end

                            if ext == "ogg" or ext == "wav" or ext == "mp3" then
                                result.audio[#result.audio + 1] = fileEntry
                            elseif ext == "png" or ext == "jpg" or ext == "jpeg" or lowerName:find("jacket", 1, true) then
                                result.images[#result.images + 1] = fileEntry
                            elseif ext == "bin" or ext == "lua" then
                                result.charts[#result.charts + 1] = fileEntry
                            end
                        end
                    end
                end
            end
        end
    end

    log.info("SFB files found: " .. sfbCount)
    log.info("Loaded audio files: " .. #result.audio)
    log.info("Loaded image files: " .. #result.images)
    log.info("Loaded chart files: " .. #result.charts)
    
    return result
end

return sfbloader


