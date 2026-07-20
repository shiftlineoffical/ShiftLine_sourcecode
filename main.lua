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
---@diagnostic disable: undefined-field, undefined-global, duplicate-set-field, undefined-doc-name, unused-local
---@type any
local _G = _G
---@type any
local love = love
---@class love
---@class _G

--[[
螟画焚陦ｨ
play:play.lua縺ｮ蜀・ｮｹ
dotfont:繝峨ャ繝医ヵ繧ｩ繝ｳ繝・
logofont:繝ｭ繧ｴ繝輔か繝ｳ繝・
playdata:繧ｲ繝ｼ繝繝励Ξ繧､荳ｭ縺ｮ髮｣譏灘ｺｦ繝ｻ譖ｲ蜷阪・繧ｹ繧ｳ繧｢遲峨ョ繝ｼ繧ｿ
discordRPC:Discord Rich Presence縺ｮ繝｢繧ｸ繝･繝ｼ繝ｫ
appId:Discord繧｢繝励Μ繧ｱ繝ｼ繧ｷ繝ｧ繝ｳID
presence:Discord Rich Presence縺ｮ迥ｶ諷九ｒ陦ｨ縺吶ユ繝ｼ繝悶Ν
discordEnabled:Discord Rich Presence縺梧怏蜉ｹ縺九←縺・°縺ｮ繝輔Λ繧ｰ
nextPresenceUpdate:谺｡縺ｫDiscord Rich Presence繧呈峩譁ｰ縺吶ｋ譎ょ綾






gamejolt繝・・繧ｿ縺ｮ蜿励￠蜿悶ｊ譁ｹ
App.setLogin(data)繧貞他縺ｳ蜃ｺ縺吶％縺ｨ縺ｧ縲‥ata繝・・繝悶Ν縺ｮ蜀・ｮｹ縺窟pp.login縺ｫ蜿肴丐縺輔ｌ繧九・
data繝・・繝悶Ν縺ｮ讒矩縺ｯ莉･荳九・騾壹ｊ:
{
    authenticated: boolean, // 隱崎ｨｼ縺輔ｌ縺ｦ縺・ｋ縺九←縺・°
    userid: string, // 繝ｦ繝ｼ繧ｶ繝ｼID
    user_token: string, // 繝ｦ繝ｼ繧ｶ繝ｼ繝医・繧ｯ繝ｳ
    username: string, // 繝ｦ繝ｼ繧ｶ繝ｼ蜷・
    userId: string, // 繝ｦ繝ｼ繧ｶ繝ｼID・・serid縺ｨ蜷後§蜀・ｮｹ・・
    avatarUrl: string, // 繧｢繝舌ち繝ｼURL
}





]]



App = App or {}
App.login = App.login or {
    authenticated = false,
    userid = "",
    user_token = "",
    username = "",
    userId = "",
    avatarUrl = "",
}

function App.setLogin(data)
    if type(data) ~= "table" then return end
    local login = App.login
    if data.authenticated ~= nil then login.authenticated = data.authenticated end
    if data.userid ~= nil then login.userid = data.userid end
    if data.user_token ~= nil then login.user_token = data.user_token end
    if data.username ~= nil then login.username = data.username end
    if data.userId ~= nil then login.userId = data.userId end
    if data.avatarUrl ~= nil then login.avatarUrl = data.avatarUrl end
end








local discordRPC = {}
local isWindows = false
if love and love.system and love.system.getOS then
    isWindows = (love.system.getOS() == "Windows")
end
if isWindows then
    local okDiscord, drpc = pcall(require, "discordRPC")
    if okDiscord and drpc then
        discordRPC = drpc
    end
end
local appId = require"applicationId"
local log = require "log"

local function isLovebirdAllowed()
    return true
end

local lovebird = nil
if isLovebirdAllowed() then
    local okLovebird, lb = pcall(require, "lovebird")
    if okLovebird and lb then
        lovebird = lb
    end
end
local gamejolt = require "gamejolt"
local openingloader= require "openingloader"
local opening = require "opening"
local gamemodeselect = require "gamemodeselect"
local play = require "play"
local musicselect = require "musicselect"
local userbadge = require "userbadge"
local settings = require "settings"
local console = require "console"
local story = require "storyselecter"
local result = require "result"
local reporter = require "error_reporter"

local presence = {}
local discordEnabled = false
local nextPresenceUpdate = 0

local programnumber=0
local program




hs=1



--讌ｽ譖ｲ繝｡繧ｿ
jacket =""
level =""
name = ""
artist =""
score = {
    score = 0,
    maxcombo = 0,
    perfect = 0,
    great = 0,
    good = 0,
    bad = 0,
    miss = 0
}


--繝ｭ繧ｰ髢｢騾｣
log=require("log")
log.outfile = "ShiftLine.log"
log.usecolor = true
log.level = "trace"



local programs = {
    [0] = require "openingloader",
    [1] = require "opening",
    [2] = require "gamemodeselect",
    [3] = require "musicselect",
    [4] = require "play",
    [5] = require "settings",
    [6] = require "storyselecter",
    [7] = require "result",
    [8] = require "editor"
}

local gamestatus = ""
local main = {
    online = false,
    pendingDiscordJoinSecret = nil,
    startup = {
        collections = nil,
        previewSources = nil
    }
}

local function prepareStartupAssets()
    if main.startup.collections and musicselect.setStartupAssets then
        musicselect.setStartupAssets(main.startup.collections, main.startup.previewSources or {})
    end
end

function main.getStartupAssets()
    return main.startup
end





local function getSongTitleForPresence()
    local title = gamestatus
    if type(title) ~= "string" or title == "" then
        return "襍ｷ蜍穂ｸｭ"
    end
    return title
end

function setDiscordJoinSecret(joinSecret)
    if type(joinSecret) ~= "string" then
        return
    end
    if not discordEnabled then
        return
    end
    presence.joinSecret = joinSecret
    discordRPC.updatePresence(presence)
end

function discordRPC.ready(userId, username, discriminator, avatar)
    log.info(string_format("Discord: ready (%s, %s, %s, %s)", userId, username, discriminator, avatar))
end

function discordRPC.disconnected(errorCode, message)
    log.warn(string_format("Discord: disconnected (%d: %s)", errorCode, message))
end

function discordRPC.errored(errorCode, message)
    log.error(string_format("Discord: error (%d: %s)", errorCode, message))
end

function discordRPC.joinGame(joinSecret)
    log.info(string_format("Discord: join (%s)", joinSecret))
    if type(joinSecret) == "string" and joinSecret ~= "" then
        main.pendingDiscordJoinSecret = joinSecret
        onlineMode = true
        changeProgram(6)
    end
end

function discordRPC.spectateGame(spectateSecret)
    log.info(string_format("Discord: spectate (%s)", spectateSecret))
end

function discordRPC.joinRequest(userId, username, discriminator, avatar)
    log.info(string_format("Discord: join request (%s, %s, %s, %s)", userId, username, discriminator, avatar))
    discordRPC.respond(userId, "yes")
end




---@diagnostic disable-next-line: undefined-field
function love.load()
    love.audio.setVolume(0.5)
    -- Set up logging to file
    log.outfile = "ShiftLine.log"
    log.level = "trace"
    log.info("boot")
    math.randomseed(os.time())
    reporter.resendIfExists()

    -- 繝槭え繧ｹ繧ｫ繝ｼ繧ｽ繝ｫ
    cursor = love.mouse.newCursor("img/cursor.png", 0, 0)
    love.mouse.setCursor(cursor)

    -- Load and apply saved settings before starting the first program.
    settings.load()

    programsettings()
    program.load()

    -- Discord
    if isWindows and discordRPC and type(discordRPC.initialize) == "function" then
        local ok, err = pcall(discordRPC.initialize, appId, true)
        if ok then
            discordEnabled = true
        else
            discordEnabled = false
            log.error(string_format("Discord: initialize failed (%s)", tostring(err)))
        end
    else
        discordEnabled = false
        log.info("Discord disabled: non-Windows platform or missing module")
    end


    local partyMax
    if onlineMode then
        partyMax = 4
    else
        partyMax = 1
    end
    local state = "繧ｽ繝ｭ繝励Ξ繧､荳ｭ"



    local now = os.time()
    presence = {
        state = state,
        details = getSongTitleForPresence(),
        startTimestamp = now,
        partyId = "",
        partySize = 1,
        partyMax = partyMax,
        matchSecret = "match secret",
        joinSecret = "join secret",
        spectateSecret = "spectate secret",
        }

    if discordEnabled then
        discordRPC.updatePresence(presence)
    end



    nextPresenceUpdate = 0
end

---@diagnostic disable-next-line: undefined-field
function love.update(dt)





    local songTitle = getSongTitleForPresence()
    if presence.details ~= songTitle then
        presence.details = songTitle
        nextPresenceUpdate = 0
    end

    if discordEnabled then
        local now = love.timer.getTime()
        if nextPresenceUpdate < now then
            discordRPC.updatePresence(presence)
            nextPresenceUpdate = now + 2.0
        end
        discordRPC.runCallbacks()
    end

    if lovebird then
        pcall(lovebird.update)
    end

    if onlineMode then
        main.online=true
    end





    --繝励Ο繧ｰ繝ｩ繝縺ｮ遘ｻ陦・
    if programnumber == 0 and openingloader.endprocess then
        changeProgram(1)
        
    elseif programnumber == 1 and opening.endprocess then
        changeProgram(2)
    elseif programnumber == 2 and gamemodeselect.endprocess and gamemodeselect.selectedmode == 0 then--繧ｿ繧､繝医Ν縺ｸ
        changeProgram(1)
    elseif programnumber == 2 and gamemodeselect.endprocess and gamemodeselect.selectedmode == 1 then--繧ｽ繝ｭ讌ｽ譖ｲ繧ｻ繝ｬ繧ｯ繝・
        changeProgram(3)
    elseif programnumber == 2 and gamemodeselect.endprocess and gamemodeselect.selectedmode == 2 then--繧ｹ繝医・繝ｪ繝ｼ繝｢繝ｼ繝・
        storyMode =true
        changeProgram(6)
    elseif programnumber == 2 and gamemodeselect.endprocess and gamemodeselect.selectedmode == 3 then--險ｭ螳・
        changeProgram(5)
    elseif programnumber == 6 and story.endprocess then--繧ｹ繝医・繝ｪ繝ｼ繧ｻ繝ｬ繧ｯ繧ｿ繝ｼ縺九ｉ謌ｻ繧・
        changeProgram(2)
    elseif programnumber ==3 and musicselect.endprocess and musicselect.selectmode == 1 then
        changeProgram(2)
    elseif programnumber ==3 and musicselect.endprocess and musicselect.selectmode == 2 then
        local playCollections = nil
        musiclevel = musicselect.selectedDifficulty or "easy"
        musicname = musicselect.musicname
        musicartist = musicselect.musicartist
        local diffName = musicselect.selectedDifficulty
        selectindex = musicselect.selectedIndex

        if play.setCollections and musicselect.getCollections then
            play.setCollections(playCollections or (musicselect.getPlayCollections and musicselect.getPlayCollections()) or musicselect.getCollections())
        end
        gamestatus = string_format("%s [%s]", musicname, string.upper(diffName))
        changeProgram(4)
    elseif programnumber ==3 and musicselect.endprocess and musicselect.selectmode == 8 then
        -- 繧ｨ繝・ぅ繧ｿ繝｢繝ｼ繝峨↓驕ｷ遘ｻ・・lay + E 繧ｭ繝ｼ・・
        local playCollections = nil
        musiclevel = musicselect.selectedDifficulty or "easy"
        musicname = musicselect.musicname
        musicartist = musicselect.musicartist
        local diffName = musicselect.selectedDifficulty
        selectindex = musicselect.selectedIndex

        if play.setCollections and musicselect.getCollections then
            play.setCollections(playCollections or (musicselect.getPlayCollections and musicselect.getPlayCollections()) or musicselect.getCollections())
        end
        gamestatus = string_format("%s [%s] (Editor)", musicname, string.upper(diffName))
        changeProgram(8)
    end


    if program == opening then
        gamestatus = "Title"
    elseif program == gamemodeselect then
        gamestatus = "Modeselect"
    elseif program == story then
        gamestatus = "Storymode"
    elseif program == settings then
        gamestatus = "Setting"
    elseif program == musicselect then
        gamestatus = "Musicselect"
    elseif program == result then
        gamestatus = "Result"
    end




    programsettings()
    if program.update then
        program.update(dt)
    end

    userbadge.update(dt)
    
        love.mouse.setVisible(true)
end


---@diagnostic disable-next-line: undefined-field
function love.mousepressed(x, y, button, istouch, presses)
    if console and console.active then
        return
    end

    if program and program.mousepressed then
        program.mousepressed(x, y, button, istouch, presses)
    end
end

---@diagnostic disable-next-line: undefined-field
function love.mousereleased(x, y, button, istouch, presses)
    if console and console.active then
        return
    end

    if program.mousereleased then
        program.mousereleased(x, y, button, istouch, presses)
    end
end

---@diagnostic disable-next-line: undefined-field
function love.wheelmoved(x, y)
    if console and console.active then
        return
    end

    if program.wheelmoved then
        program.wheelmoved(x, y)
    end
end




---@diagnostic disable-next-line: undefined-field
function love.draw()
    programsettings()
    if program.draw then
        program.draw()
    end

    if programnumber ~= 0 and programnumber ~= 4 then
        userbadge.draw()
    end

    if program.drawOverlay then
        program.drawOverlay()
    end

    if console and console.active then
        console.draw()
    end

end

---@diagnostic disable-next-line: undefined-field
function love.resize(w, h)
    if program and program.updateLayout then
        pcall(program.updateLayout, true)
    end
    if program and program.resize then
        pcall(program.resize, w, h)
    end
end

function programsettings()
    program = programs[programnumber]
    ---@diagnostic disable-next-line: undefined-field
    _G.program = program
    ---@diagnostic disable-next-line: undefined-field
    _G.programnumber = programnumber
end



function changeProgram(num)

    if program and program.quit then
        program.quit()
    end

    programnumber = num
    programsettings()

    if program.load then
        program.load()
    end
    nextPresenceUpdate = 0

end






---@diagnostic disable-next-line: undefined-field
function love.quit()
    programsettings()
    if program.quit then
        program.quit()
    end
    settings.save()
    gamejolt.quit()
    if discordEnabled then
        discordRPC.shutdown()
    end
    log.info("exit game")
end




---@diagnostic disable-next-line: undefined-field
function love.errhand(msg)
    local trace = debug.traceback(tostring(msg), 2)
    reporter.report(msg, trace)
    return function()
        love.graphics.clear(0.1, 0.1, 0.1)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("A fatal error occurred.\n\n" .. trace, 20, 20)
        love.graphics.present()
    end
end

---@diagnostic disable-next-line: undefined-field
function love.textinput(t)
    if console and console.active then
        if console.textinput then
            console.textinput(t)
        end
        return
    end

    if program.textinput then
        program.textinput(t)
    end
end



---@diagnostic disable-next-line: undefined-field
function love.keypressed(key, scancode, isrepeat)
    if key == "f10" and console then
        console.toggle()
        return
    end

    if console and console.active then
        if console.keypressed then
            console.keypressed(key, scancode, isrepeat)
        end
        return
    end

    if key == "f1" and programnumber == 8 then
        if program.keypressed then
            program.keypressed(key, scancode, isrepeat)
        end
        return
    end

    if key == "f1" then
        settings.openMenu()
        return
    end
    if program.keypressed then
        program.keypressed(key, scancode, isrepeat)
    end
end

---@diagnostic disable-next-line: undefined-field
function love.keyreleased(key, scancode)
    if console and console.active then
        if console.keyreleased then
            console.keyreleased(key, scancode)
        end
        return
    end

    if program.keyreleased then
        program.keyreleased(key, scancode)
    end
end



---@diagnostic disable-next-line: undefined-field
function love.textedited(text, start, length)
    if program.textedited then
        program.textedited(text, start, length)
    end
end



return main


