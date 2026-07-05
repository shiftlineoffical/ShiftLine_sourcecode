---@diagnostic disable: undefined-global, undefined-field
local log = require "log"
local i18n = require "i18n"
local ok_gamejolt, gamejolt = pcall(require, "gamejolt")
local ok_gamejoltuser, gamejoltuser = pcall(require, "gamejoltuser")

---@class GlobalEnv
---@field editorStarted boolean
---@field editorAutoplay boolean
---@field bgmSource any
---@field chartRuntime any
---@field programnumber number
---@field displayx number
---@field displayy number
---@field musictime number
---@field musictimer number
---@field finished boolean
---@field paused boolean
---@field score any
---@field songStarted boolean
---@field waitingResume boolean
---@field name string
---@field artist string
---@field level string
---@field jacketimg any
---@field program any
---@field musicload number
---@field chartLoaded boolean
---@field lanegravity number
---@field notegravity number
---@field metaDisplayShown boolean
---@field metaDisplayFinished boolean

console = {
    active = false,
    input = "",
    lines = {},
    maxLines = 28,
    flags = {
        debug_titles = true,
        debug_omitnotes = true,
        debug_slowlad_typing = true,
        debug_exam = true,
        debug_offline = true,
        debug_cansendmayself = true,
        debug_nottification = true,
        debug_story_reload = true,
        debug_removeresult = true,
        debug_boxtage = true,
        debug_story = true,
        debug_reward = true,
        debug_printerror = true,
        debug_createexam = true,
        debug_hidefuture = true,
        debug_legacysongs = true,
        debug_immediate_destroye = true,
        debug_consolescreen = true,
        editor_reloadonreset = true,
        editor_resetscene = true,
        editor_enable = true,
        lang_dubpagish = true,
        lang_export = true,
        lang_test = true,
        sfl_list_set = true,
        skin_show = true
    },
    playerData = {},
    playerDataBackup = {},
    suggestionIndex = 1,
    errors = {},
    maxErrors = 100
}

local consoleFontCache = {}

local function getConsoleFont()
    local lang = "jp"
    if i18n and i18n.getLanguage then
        pcall(function()
            lang = i18n.getLanguage()
        end)
    end

    local key = tostring(lang) .. ":20"
    if consoleFontCache[key] then
        return consoleFontCache[key]
    end

    local font
    if love and love.graphics and love.graphics.newFont then
        if lang == "jp" then
            local fontPath = "lib/data/fonts/NotoSansJP-Regular.ttf"
            local ok, result = pcall(love.graphics.newFont, fontPath, 20)
            if ok and result then
                font = result
            end
        end
        if not font then
            font = love.graphics.newFont(20)
        end
    else
        font = nil
    end

    consoleFontCache[key] = font
    return font
end

local function writeAppDataFile(name, content)
    if not love or not love.filesystem or not love.filesystem.write then
        return
    end
    local filename = name .. ".txt"
    local ok, err = pcall(love.filesystem.write, filename, content or "")
    if not ok then
        console.addLine("failed to write " .. filename .. ": " .. tostring(err))
    else
        console.addLine("wrote AppData file: " .. filename)
    end
end

local function trim(s)
    return (s or ""):match("^%s*(.-)%s*$") or ""
end

local function formatValue(value)
    if value == nil then
        return "nil"
    end
    if type(value) == "boolean" then
        return tostring(value)
    end
    if type(value) == "number" then
        return tostring(value)
    end
    if type(value) == "string" then
        return value
    end
    if type(value) == "table" then
        local result = "{"
        local count = 0
        for k, v in pairs(value) do
            count = count + 1
            if count > 5 then
                result = result .. ", ..."
                break
            end
            result = result .. tostring(k) .. ":" .. tostring(v) .. ", "
        end
        if result:sub(-2) == ", " then
            result = result:sub(1, -3)
        end
        return result .. "}"
    end
    return tostring(value)
end

local function ensureFlag(name)
    if console.flags[name] == nil then
        console.flags[name] = false
    end
    return console.flags[name]
end

local function toggleFlag(name)
    console.flags[name] = not ensureFlag(name)
    console.addLine(name .. " = " .. tostring(console.flags[name]))
    if console.flags[name] and console.debugCommands[name] then
        console.debugCommands[name]()
    end
end

local function setFlag(name, value)
    console.flags[name] = value
    console.addLine(name .. " = " .. tostring(console.flags[name]))
    if value and console.debugCommands[name] then
        console.debugCommands[name]()
    end
end

local function gotoScene(id)
    if type(id) ~= "number" then
        return false
    end
    if type(changeProgram) == "function" then
        changeProgram(id)
        console.addLine("gotoScene(" .. id .. ")")
        return true
    end
    console.addLine("gotoScene: changeProgram unavailable")
    return false
end

local function triggerDebugEvent(name)
    if type(console.debugCommands[name]) == "function" then
        console.debugCommands[name]()
    end
end

local function startStoryDebug()
    console.addLine("startStoryDebug()")
    gotoScene(6)
end

local function startExamDebug()
    console.addLine("startExamDebug()")
    if type(createExam) == "function" then
        createExam()
    else
        console.addLine("startExamDebug: createExam unavailable")
    end
end

local function showRewardDebug()
    console.addLine("showRewardDebug()")
    if type(_G) == "table" then
        _G.rewardOpen = true
    end
end

local function reloadStoryDebug()
    console.addLine("reloadStoryDebug()")
    if type(reloadCurrentChart) == "function" then
        reloadCurrentChart()
    else
        console.addLine("reloadStoryDebug: reloadCurrentChart unavailable")
    end
end

local function createExamDebug()
    console.addLine("createExamDebug()")
    startExamDebug()
end

local function showGameJoltUserData()
    if not ok_gamejoltuser or not gamejoltuser then
        console.addLine("gamejoltuser module unavailable")
        return
    end
    console.addLine("gamejoltuser.userid=" .. tostring(gamejoltuser.userid))
    console.addLine("gamejoltuser.user_token=" .. tostring(gamejoltuser.user_token))
    console.addLine("gamejoltuser.autologin=" .. tostring(gamejoltuser.autologin))
end

local function executeAudioCommand(cmd)
    if cmd == "audio_musiclist" then
        if type(getMusicList) == "function" then
            local ok, result = pcall(getMusicList)
            if ok then
                console.addLine("music list ready")
                if type(result) == "table" then
                    for i = 1, math.min(10, #result) do
                        console.addLine("- " .. tostring(result[i]))
                    end
                end
            else
                console.addLine("audio_musiclist failed")
            end
        else
            console.addLine("audio_musiclist: unavailable")
        end
        return
    end

    if cmd == "audio_sfxlist" then
        console.addLine("audio_sfxlist: unavailable")
    end
end

local function executePlayerCommand(cmd, args)
    local parts = {}
    for part in (args or ""):gmatch("%S+") do
        table.insert(parts, part)
    end

    if cmd == "player_data_set" then
        if #parts < 2 then
            console.addLine("usage: player_data_set key value")
            return
        end
        console.playerData[parts[1]] = parts[2]
        console.addLine("player data set: " .. parts[1] .. "=" .. tostring(parts[2]))
        return
    end

    if cmd == "player_data_get" then
        if #parts < 1 then
            console.addLine("usage: player_data_get key")
            return
        end
        console.addLine(parts[1] .. " = " .. formatValue(console.playerData[parts[1]]))
        return
    end

    if cmd == "player_data_show" then
        console.addLine("playerData = " .. formatValue(console.playerData))
        return
    end

    if cmd == "player_data_backup" or cmd == "player_data_bukup" then
        console.playerDataBackup = {}
        for k, v in pairs(console.playerData) do
            console.playerDataBackup[k] = v
        end
        console.addLine("playerData backup created")
        return
    end

    if cmd == "player_delete" then
        if #parts < 1 then
            console.addLine("usage: player_delete key")
            return
        end
        console.playerData[parts[1]] = nil
        console.addLine("player data deleted: " .. parts[1])
        return
    end

    if cmd == "player_verify" or cmd == "player_verfy" then
        local count = 0
        for _ in pairs(console.playerData) do
            count = count + 1
        end
        console.addLine("player data entries=" .. count .. ", backup=" .. tostring(next(console.playerDataBackup) ~= nil))
        return
    end
end

local function copyConsoleOutput()
    local text = table.concat(console.lines, "\n")
    if love.system and love.system.setClipboardText then
        love.system.setClipboardText(text)
        console.addLine("console output copied to clipboard")
    else
        console.addLine("clipboard unavailable")
    end
end

console.debugCommands = {}
local commandSpecs = {
    help = {desc = "Show help", handler = function() console.showHelp() end},
    debug_printerror = {desc = "Toggle debug_printerror", handler = function() toggleFlag("debug_printerror") end},
    gamejoltuser_data = {desc = "Show GameJolt user data", handler = function() showGameJoltUserData() end}
}

local availableCommands = {}
for name, spec in pairs(commandSpecs) do
    if spec and type(spec) == "table" then
        table.insert(availableCommands, {name = name, desc = spec.desc or ""})
    end
end

table.sort(availableCommands, function(a, b) return a.name < b.name end)

local function getMatchingCommands(prefix)
    local trimmed = trim(prefix)
    if trimmed == "" then
        return {}
    end
    local lower = trimmed:lower()
    local results = {}
    for _, cmd in ipairs(availableCommands) do
        if cmd.name:find(lower, 1, true) then
            table.insert(results, cmd)
        end
    end
    return results
end

function console.clear()
    console.lines = {}
end

function console.getProgramName(num)
    local programNames = {
        [0] = "openingloader",
        [1] = "opening",
        [2] = "gamemodeselect",
        [3] = "musicselect",
        [4] = "play",
        [5] = "settings",
        [6] = "story",
        [7] = "result",
        [8] = "editor"
    }
    return programNames[num] or tostring(num)
end

function console.getCurrentProgramSummary()
    local currentNum = _G.programnumber or -1
    local currentName = console.getProgramName(currentNum)
    return string.format("program=%s(%d)", currentName, currentNum)
end

function console.showHelp()
    console.addLine("Available commands:")
    for _, cmd in ipairs(availableCommands) do
        console.addLine(string.format("  %-24s %s", cmd.name, cmd.desc))
    end
end

function console.showStatus()
    console.addLine(console.getCurrentProgramSummary())
    console.addLine("editorStarted=" .. formatValue(_G.editorStarted) .. ", editorAutoplay=" .. formatValue(_G.editorAutoplay))
    console.addLine("musicload=" .. formatValue(_G.musicload) .. ", bgmSource=" .. formatValue(_G.bgmSource ~= nil))
    console.addLine("musictime=" .. formatValue(_G.musictime) .. ", musictimer=" .. formatValue(_G.musictimer))
    console.addLine("finished=" .. formatValue(_G.finished) .. ", paused=" .. formatValue(_G.paused))
    console.addLine("chartLoaded=" .. formatValue(_G.chartRuntime and _G.chartRuntime.chart ~= nil))
end

function console.showProgram()
    console.addLine(console.getCurrentProgramSummary())
    if _G.program then
        console.addLine("program table=" .. tostring(_G.program))
    end
end

function console.showEditor()
    console.addLine("editorStarted=" .. formatValue(_G.editorStarted) .. ", editorAutoplay=" .. formatValue(_G.editorAutoplay))
    console.addLine("lanegravity=" .. formatValue(_G.lanegravity) .. ", notegravity=" .. formatValue(_G.notegravity))
    console.addLine("musicload=" .. formatValue(_G.musicload) .. ", musicstarted=" .. formatValue(_G.songStarted))
    console.addLine("musictime=" .. formatValue(_G.musictime) .. ", musictimer=" .. formatValue(_G.musictimer))
end

function console.showPlay()
    console.addLine("score=" .. formatValue(_G.score and _G.score.score) .. ", maxcombo=" .. formatValue(_G.score and _G.score.maxcombo))
    console.addLine("songStarted=" .. formatValue(_G.songStarted) .. ", waitingResume=" .. formatValue(_G.waitingResume))
    console.addLine("metaDisplayShown=" .. formatValue(_G.metaDisplayShown) .. ", metaDisplayFinished=" .. formatValue(_G.metaDisplayFinished))
end

function console.showSong()
    local songData
    if type(getSelectedSongDisplayData) == "function" then
        local ok, result = pcall(getSelectedSongDisplayData)
        if ok then
            songData = result
        end
    end
    if songData then
        console.addLine("title=" .. formatValue(songData.title) .. ", artist=" .. formatValue(songData.artist))
        console.addLine("level=" .. formatValue(songData.level) .. ", levelColor=" .. formatValue(songData.levelColor))
    else
        console.addLine("song data is not available")
    end
end

function console.showGlobals()
    console.addLine("displayx=" .. formatValue(_G.displayx) .. ", displayy=" .. formatValue(_G.displayy))
    console.addLine("name=" .. formatValue(_G.name) .. ", artist=" .. formatValue(_G.artist) .. ", level=" .. formatValue(_G.level))
    console.addLine("jacketimg=" .. formatValue(_G.jacketimg ~= nil) .. ", bgmSource=" .. formatValue(_G.bgmSource ~= nil))
end

function console.addLine(text)
    local line = tostring(text or "")
    table.insert(console.lines, line)
    while #console.lines > console.maxLines do
        table.remove(console.lines, 1)
    end
end

function console.logError(msg, traceback_str, count)
    local text = tostring(msg or "")
    if traceback_str and traceback_str ~= "" then
        text = text .. "\n" .. tostring(traceback_str)
    end
    console.addLine("[ERROR] " .. text)
    if type(count) == "number" then
        console.errors[count] = text
    end
end

function console.submitCommand()
    local command = trim(console.input)
    console.addLine("> " .. command)
    console.input = ""
    if command == "" then
        return
    end

    local cmd, args = command:match("^(%S+)%s*(.*)$")
    cmd = cmd and cmd:lower() or ""
    args = args or ""

    local spec = commandSpecs[cmd]
    if spec and spec.handler then
        spec.handler(args)
        return
    end

    console.addLine("unknown command: " .. cmd .. ". type help")
end

function console.toggle()
    console.active = not console.active
    if love.keyboard and love.keyboard.setTextInput then
        love.keyboard.setTextInput(console.active)
    end
    if console.active then
        console.addLine("Console opened. type help for commands.")
    else
        console.clear()
    end
end

function console.keypressed(key, scancode, isrepeat)
    if key == "escape" then
        console.toggle()
        return
    end
    if key == "backspace" then
        if #console.input > 0 then
            console.input = console.input:sub(1, -2)
        end
        return
    end
    if key == "tab" then
        local matches = getMatchingCommands(console.input)
        if #matches > 0 then
            console.input = matches[1].name .. " "
        end
        return
    end
    if key == "c" and love.keyboard and love.keyboard.isDown and (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) then
        copyConsoleOutput()
        return
    end
    if key == "return" or key == "kpenter" then
        console.submitCommand()
        return
    end
end

function console.textinput(t)
    console.input = console.input .. t
end

function console.draw()
    local width = _G.displayx or love.graphics.getWidth()
    local height = _G.displayy or love.graphics.getHeight()
    local font = getConsoleFont()
    local oldFont = love.graphics.getFont()
    if font then
        love.graphics.setFont(font)
    end
    local lineHeight = (font and font:getHeight() or 20) + 4
    local leftWidth = math.max(280, math.floor(width * 0.28))

    love.graphics.push()
    love.graphics.setColor(0, 0, 0, 0.88)
    love.graphics.rectangle("fill", 0, 0, width, height)

    love.graphics.setColor(0.1, 0.1, 0.1, 0.95)
    love.graphics.rectangle("fill", 10, 10, leftWidth - 20, height - 80)

    love.graphics.setColor(1, 1, 1, 0.95)
    love.graphics.print("Command suggestions", 16, 14)
    love.graphics.setColor(0.5, 0.5, 0.5, 0.9)
    love.graphics.line(16, 34, leftWidth - 16, 34)

    local matches = getMatchingCommands(console.input)
    local suggestY = 40
    if trim(console.input) == "" then
        love.graphics.setColor(0.7, 0.7, 0.7, 0.9)
        love.graphics.print("Type to search commands...", 16, suggestY)
        suggestY = suggestY + lineHeight
    else
        for i = 1, math.min(#matches, math.floor((height - 120) / (lineHeight * 2))) do
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(matches[i].name, 16, suggestY)
            love.graphics.setColor(0.8, 0.8, 0.8, 0.8)
            love.graphics.print(matches[i].desc, 18, suggestY + (font and font:getHeight() or 16))
            suggestY = suggestY + lineHeight * 2
        end
        if #matches == 0 then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print("No matching command", 16, suggestY)
            suggestY = suggestY + lineHeight
        end
    end

    love.graphics.setColor(1, 1, 1, 0.95)
    love.graphics.print("Console output", leftWidth + 16, 14)
    love.graphics.setColor(0.5, 0.5, 0.5, 0.9)
    love.graphics.line(leftWidth + 16, 34, width - 16, 34)

    local y = 40
    local maxLines = math.floor((height - 120) / lineHeight)
    local start = math.max(1, #console.lines - maxLines + 1)
    for i = start, #console.lines do
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(console.lines[i], leftWidth + 16, y)
        y = y + lineHeight
    end

    love.graphics.setColor(0.15, 0.15, 0.15, 0.98)
    love.graphics.rectangle("fill", 10, height - 50, width - 20, 40)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("> " .. console.input, 16, height - 42)

    love.graphics.pop()
    if oldFont then
        love.graphics.setFont(oldFont)
    end
end

return console
