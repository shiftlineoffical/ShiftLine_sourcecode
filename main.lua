--[[
変数表
play:play.luaの内容
dotfont:ドットフォント
logofont:ロゴフォント
playdata:ゲームプレイ中の難易度・曲名・スコア等データ
discordRPC:Discord Rich Presenceのモジュール
appId:DiscordアプリケーションID
presence:Discord Rich Presenceの状態を表すテーブル
discordEnabled:Discord Rich Presenceが有効かどうかのフラグ
nextPresenceUpdate:次にDiscord Rich Presenceを更新する時刻






gamejoltデータの受け取り方
App.setLogin(data)を呼び出すことで、dataテーブルの内容がApp.loginに反映される。
dataテーブルの構造は以下の通り:
{
    authenticated: boolean, // 認証されているかどうか
    userid: string, // ユーザーID
    user_token: string, // ユーザートークン
    username: string, // ユーザー名
    userId: string, // ユーザーID（useridと同じ内容）
    avatarUrl: string, // アバターURL
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



local gamejoltusername=""
local gamejoltusericon




local online =require("online")
local online_room = require("online_room")
local online_musicselect = require("online_musicselect")
local online_play = require("online_play")
local online_result = require("online_result")
local online_connect = require("online_connect")



local log = require "log"

local score

musicdifficulty = ""
musiclevel = ""

local log = require "log"

local discordRPC = {}

log.info("Discord RPC: loading module...")

local okDiscord, drpc = pcall(require, "discordRPC")

log.info("Discord RPC: require result = " .. tostring(okDiscord))
log.info("Discord RPC: module = " .. tostring(drpc))

if okDiscord and drpc then
    discordRPC = drpc
    log.info("Discord RPC: module loaded")
    log.info("Discord RPC: initialize = " .. tostring(discordRPC.initialize))
else
    log.error("Discord RPC: require failed: " .. tostring(drpc))
end

local appId = require("applicationId")




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
local discordJoinSecretPrefix = "shiftline:"

local programnumber=0
local program




hs=1



--楽曲メタ
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


--ログ関連
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
    [8] = require "editor",
    [9] = online_room,
    [10] = online_musicselect,
    [11] = online_play,
    [12] = online_result
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
    if openingloader and openingloader.getCollections then
        main.startup.collections = openingloader.getCollections() or main.startup.collections
    end

    if main.startup.collections then
        if musicselect.setCollections then
            musicselect.setCollections(main.startup.collections)
        end
        if musicselect.setStartupAssets then
            musicselect.setStartupAssets(main.startup.collections, main.startup.previewSources or {})
        end
    end
end

function main.getStartupAssets()
    return main.startup
end





local function getSongTitleForPresence()
    local title = gamestatus
    if type(title) ~= "string" or title == "" then
        return "起動中"
    end
    return title
end

local function getDiscordJoinSecretFromArguments()
    if type(arg) ~= "table" then
        return nil
    end

    for _, value in ipairs(arg) do
        if type(value) == "string" then
            local secret = value:match("^discord%-[^:]+://join/(.+)$")
            if secret and secret ~= "" then
                return secret
            end
        end
    end

    return nil
end

local function registerDiscordLauncherProtocol()
    if not love.system then
        return false
    end

    local source = love.filesystem.getSource()
    if type(source) ~= "string" or source == "" then
        return false
    end

    source = source:gsub("[/\\]+$", "")
    log.info("Discord RPC: LÖVE source", source)
    local sourceFile = io.open(source, "rb")
    if sourceFile then
        sourceFile:close()
        source = source:match("^(.*)[/\\][^/\\]+$")
    end

    local sourceParent = source and source:match("^(.*)[/\\][^/\\]+$")
    if not sourceParent then
        log.warn("Discord RPC: launcher directory could not be determined")
        return false
    end

    local osName = love.system.getOS()
    local launcherPath
    if osName == "Windows" then
        local candidates = {
            sourceParent .. "/ShiftLineLauncher.exe",
            sourceParent .. "/ShiftLineLauncher/ShiftLineLauncher.exe"
        }
        for _, candidate in ipairs(candidates) do
            local candidateFile = io.open(candidate, "rb")
            if candidateFile then
                candidateFile:close()
                launcherPath = candidate
                break
            end
        end
    elseif osName == "OS X" then
        local candidates = {
            sourceParent .. "/ShiftLineLauncher.app",
            sourceParent .. "/ShiftLineLauncher/ShiftLineLauncher.app"
        }
        for _, candidate in ipairs(candidates) do
            local candidateInfo = io.open(candidate .. "/Contents/Info.plist", "rb")
            if candidateInfo then
                candidateInfo:close()
                launcherPath = candidate
                break
            end
        end
    else
        return false
    end

    if not launcherPath then
        log.warn("Discord RPC: launcher executable not found", sourceParent)
        return false
    end

    local launcherFile = io.open(launcherPath, "rb")
    local launcherExists = launcherFile ~= nil
    if launcherFile then
        launcherFile:close()
    end
    if not launcherExists and osName == "OS X" then
        local infoPlist = launcherPath .. "/Contents/Info.plist"
        launcherFile = io.open(infoPlist, "rb")
        launcherExists = launcherFile ~= nil
        if launcherFile then
            launcherFile:close()
        end
    end
    if not launcherExists then
        log.warn("Discord RPC: launcher executable not found", launcherPath)
        return false
    end

    local scheme = "discord-" .. appId
    local function quote(value)
        return '"' .. value:gsub('"', '\\"') .. '"'
    end

    if osName == "OS X" then
        local result = os.execute(
            "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f " ..
            quote(launcherPath)
        )
        if result ~= true and result ~= 0 then
            log.warn("Discord RPC: macOS launcher registration failed", tostring(result))
            return false
        end

        log.info("Discord RPC: macOS launcher detected", scheme, launcherPath)
        return true
    end

    local command = quote(launcherPath) .. " \"%1\""
    log.info("Discord RPC: Windows launcher command", command)
    local result = os.execute(
        "reg add " .. quote("HKCU\\Software\\Classes\\" .. scheme) ..
        " /ve /t REG_SZ /d " .. quote("URL:" .. scheme) .. " /f"
    )
    if result ~= true and result ~= 0 then
        log.warn("Discord RPC: protocol registration failed", tostring(result))
        return false
    end

    result = os.execute(
        "reg add " .. quote("HKCU\\Software\\Classes\\" .. scheme) ..
        " /v \"URL Protocol\" /t REG_SZ /d \"\" /f"
    )
    if result ~= true and result ~= 0 then
        log.warn("Discord RPC: protocol metadata registration failed", tostring(result))
        return false
    end

    result = os.execute(
        "reg add " .. quote("HKCU\\Software\\Classes\\" .. scheme .. "\\shell\\open\\command") ..
        " /ve /t REG_SZ /d " .. quote(command) .. " /f"
    )
    if result ~= true and result ~= 0 then
        log.warn("Discord RPC: launcher command registration failed", tostring(result))
        return false
    end

    log.info("Discord RPC: launcher protocol registered", scheme, launcherPath)
    return true
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
    log.info(string.format("Discord: ready (%s, %s, %s, %s)", userId, username, discriminator, avatar))
end

function discordRPC.disconnected(errorCode, message)
    log.warn(string.format("Discord: disconnected (%d: %s)", errorCode, message))
end

function discordRPC.errored(errorCode, message)
    log.error(string.format("Discord: error (%d: %s)", errorCode, message))
end

function discordRPC.joinGame(joinSecret)
    log.info(string.format("Discord: join (%s)", joinSecret))
    if type(joinSecret) == "string" and joinSecret ~= "" then
        local roomID = joinSecret:match("^" .. discordJoinSecretPrefix .. "(.+)$")
        main.pendingDiscordJoinSecret = roomID or joinSecret
    end
end

function discordRPC.spectateGame(spectateSecret)
    log.info(string.format("Discord: spectate (%s)", spectateSecret))
end

function discordRPC.joinRequest(userId, username, discriminator, avatar)
    log.info(string.format("Discord: join request (%s, %s, %s, %s)", userId, username, discriminator, avatar))
    discordRPC.respond(userId, "yes")
end




function love.load()
local icon = love.image.newImageData("img/ico.png")
    love.window.setIcon(icon)



    love.audio.setVolume(0.5)
    -- Set up logging to file
    log.outfile = "ShiftLine.log"
    log.level = "trace"
    log.info("boot")
    math.randomseed(os.time())
    reporter.resendIfExists()

    registerDiscordLauncherProtocol()

    -- マウスカーソル
    cursor = love.mouse.newCursor("img/cursor.png", 0, 0)
    love.mouse.setCursor(cursor)

    -- Load and apply saved settings before starting the first program.
    settings.load()

    programsettings()
    program.load()

    -- Discord
    log.info("Discord RPC: checking initialize")
log.info("Discord RPC: type = " .. type(discordRPC))
log.info("Discord RPC: initialize type = " .. type(discordRPC.initialize))

if type(discordRPC.initialize) == "function" then

    local ok, err = pcall(discordRPC.initialize, appId, false, nil)
        if ok then
            discordEnabled = true
        else
            discordEnabled = false
            log.error(string.format("Discord: initialize failed (%s)", tostring(err)))
        end
    else
        discordEnabled = false
        log.info("Discord disabled: missing module or platform library")
    end


    local partyMax
    if onlineMode then
        partyMax = 4
    else
        partyMax = 1
    end
    local state = "ソロプレイ中"



    local now = os.time()
    presence = {
        state = state,
        details = getSongTitleForPresence(),
        startTimestamp = now,
        partyId = "",
        partySize = 1,
        partyMax = partyMax,
        matchSecret = nil,
        joinSecret = nil,
        spectateSecret = nil,
        }

    if discordEnabled then
        discordRPC.updatePresence(presence)
    end

    main.pendingDiscordJoinSecret = getDiscordJoinSecretFromArguments()


    nextPresenceUpdate = 0
end

function love.update(dt)

    online_connect.update()





    local songTitle = getSongTitleForPresence()
    if presence.details ~= songTitle then
        presence.details = songTitle
        nextPresenceUpdate = 0
    end

    local roomID = online_connect.getRoomID()
    local hasRoomID = type(roomID) == "string" and roomID ~= ""

    if hasRoomID then
        presence.partyId = roomID
        presence.joinSecret = discordJoinSecretPrefix .. roomID
        presence.partySize = online_connect.isConnected()
            and online_connect.getPartyCount()
            or 1
        presence.partyMax = 4
        presence.instance = 1

        log.debug("Discord RPC: online party", "room=" .. roomID, "size=" .. tostring(presence.partySize) .. "/4", "instance=1")
    else
        presence.partyId = nil
        presence.joinSecret = nil
        presence.partySize = 1
        presence.partyMax = 1
        presence.instance = 0
    end

    if discordEnabled then
        local now = love.timer.getTime()
        if nextPresenceUpdate < now then
            discordRPC.updatePresence(presence)
            nextPresenceUpdate = now + 2.0
        end
        discordRPC.runCallbacks()
    end

    local pendingJoinSecret = main.pendingDiscordJoinSecret
    if pendingJoinSecret then
        main.pendingDiscordJoinSecret = nil
        onlineMode = true
        changeProgram(9)
        if online_room and online_room.joinWithRoomID then
            online_room.joinWithRoomID(pendingJoinSecret)
        end
    end

    if lovebird then
        pcall(lovebird.update)
    end

    if onlineMode then
        main.online=true
    end





    --プログラムの移行
    if programnumber == 0 and openingloader.endprocess then
        changeProgram(1)
        
    elseif programnumber == 1 and opening.endprocess then
        changeProgram(2)
    elseif programnumber == 2 and gamemodeselect.endprocess and gamemodeselect.selectedmode == 0 then--タイトルへ
        changeProgram(1)
    elseif programnumber == 2 and gamemodeselect.endprocess and gamemodeselect.selectedmode == 1 then--ソロ楽曲セレクト
        changeProgram(3)
    elseif programnumber == 2 and gamemodeselect.endprocess and gamemodeselect.selectedmode == 2 then--ストーリーモード
        storyMode =true
        changeProgram(6)
    elseif programnumber == 2 and gamemodeselect.endprocess and gamemodeselect.selectedmode == 3 then--設定
        changeProgram(5)
    elseif programnumber == 2 and gamemodeselect.endprocess and gamemodeselect.selectedmode == 4 then--オンライン
        changeProgram(9)
    elseif programnumber == 6 and story.endprocess then--ストーリーセレクターから戻る
        changeProgram(2)
    elseif programnumber ==3 and musicselect.endprocess and musicselect.selectmode == 1 then
        changeProgram(2)
    elseif programnumber ==3 and musicselect.endprocess and musicselect.selectmode == 2 then
        local playCollections = nil
        musiclevel = musicselect.selectedLevelValue
        musicdifficulty = musicselect.selectedDifficulty
        musicname = musicselect.musicname
        musicartist = musicselect.musicartist
        local diffName = musicselect.selectedDifficulty
        selectindex = musicselect.selectedIndex

        if play.setCollections and musicselect.getCollections then
            play.setCollections(playCollections or (musicselect.getPlayCollections and musicselect.getPlayCollections()) or musicselect.getCollections())
        end
        gamestatus = string.format("%s [%s]", musicname, string.upper(diffName))
        changeProgram(4)
    elseif programnumber ==3 and musicselect.endprocess and musicselect.selectmode == 8 then
        -- エディタモードに遷移（Play + E キー）
        local playCollections = nil
        musiclevel = musicselect.selectedLevelValue
        musicdifficulty = musicselect.selectedDifficulty
        musicname = musicselect.musicname
        musicartist = musicselect.musicartist
        local diffName = musicselect.selectedDifficulty
        selectindex = musicselect.selectedIndex

        if play.setCollections and musicselect.getCollections then
            play.setCollections(playCollections or (musicselect.getPlayCollections and musicselect.getPlayCollections()) or musicselect.getCollections())
        end
        gamestatus = string.format("%s [%s] (Editor)", musicname, string.upper(diffName))
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
    elseif program == play then
        gamestatus = "Play"
    elseif program == online or program == online_room or program == online_musicselect or program == online_play or program == online_result then
        gamestatus = "Online"
    end




    programsettings()
    if program.update then
        program.update(dt)
    end

    userbadge.update(dt)
    love.mouse.setVisible(true)



    --DiscordRPCのゲームIDの変更
    if program == online or program == online_room or program == online_musicselect or program == online_play or program == online_result then
        presence.details = "オンラインプレイ中"
        presence.partyMax = 4
        presence.partySize = online_connect.getPartyCount()
    end

end


love.mousepressed = function(x, y, button, istouch, presses)
    if console and console.active then
        return
    end

    if program.mousepressed then
        program.mousepressed(x, y, button, istouch, presses)
    end
end

function love.mousemoved(x, y, dx, dy, istouch)
    if console and console.active then
        return
    end

    if program and program.mousemoved then
        program.mousemoved(x, y, dx, dy, istouch)
    end
end

function love.mousereleased(x, y, button, istouch, presses)
    if console and console.active then
        return
    end

    if program.mousereleased then
        program.mousereleased(x, y, button, istouch, presses)
    end
end

function love.wheelmoved(x, y)
    if console and console.active then
        if console.wheelmoved then
            console.wheelmoved(x, y)
        end
        return
    end

    if program.wheelmoved then
        program.wheelmoved(x, y)
    end
end




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
    _G.program = program
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

function love.textinput(t)
    if console and console.active then
        if console.textinput then
            console.textinput(t)
        end
        return
    end

    if program and program.textinput then
        program.textinput(t)
        return
    end

    if settings and type(settings.textinput) == "function" then
        settings.textinput(t)
    end
end



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



function love.textedited(text, start, length)
    if program.textedited then
        program.textedited(text, start, length)
    end
end



return main