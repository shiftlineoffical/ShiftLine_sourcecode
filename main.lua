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









local score


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
        return "起動中"
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
        main.pendingDiscordJoinSecret = joinSecret
        onlineMode = true
        changeProgram(6)
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
    love.audio.setVolume(0.5)
    -- Set up logging to file
    log.outfile = "ShiftLine.log"
    log.level = "trace"
    log.info("boot")
    math.randomseed(os.time())
    reporter.resendIfExists()

    -- マウスカーソル
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
            log.error(string.format("Discord: initialize failed (%s)", tostring(err)))
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
    local state = "ソロプレイ中"



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
    elseif programnumber == 6 and story.endprocess then--ストーリーセレクターから戻る
        changeProgram(2)
    elseif programnumber ==3 and musicselect.endprocess and musicselect.selectmode == 1 then
        changeProgram(2)
    elseif programnumber ==3 and musicselect.endprocess and musicselect.selectmode == 2 then
        local playCollections = nil
        musiclevel = musicselect.selectedLevelValue
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
    end




    programsettings()
    if program.update then
        program.update(dt)
    end

    userbadge.update(dt)
    
        love.mouse.setVisible(true)
end


love.mousepressed = function(x, y, button, istouch, presses)
    if console and console.active then
        return
    end

    if program.mousepressed then
        program.mousepressed(x, y, button, istouch, presses)
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

    if program.textinput then
        program.textinput(t)
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
