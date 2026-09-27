--[[
変数表
play:play.luaの内容
dotfont:ドットフォント
logofont:ロゴフォント
playdata:ゲームプレイ中の難易度・曲名・スコア等データ
discordSDK:Discord Game SDKのモジュール
appId:DiscordアプリケーションID
presence:Discord Rich Presenceの状態を表すテーブル
discordEnabled:Discord Rich Presenceが有効かどうかのフラグ
nextPresenceUpdate:次にDiscord Rich Presenceを更新する時刻

Cloudwolker認証:
App.setLogin(data)を呼び出すことで、dataテーブルの内容がApp.loginに反映される。

dataテーブルの構造:
{
    authenticated: boolean,
    userid: string,
    user_token: string,
    username: string,
    userId: string,
    avatarUrl: string,
}

Cloudwolker:
Discord OAuth
    ↓
https://shiftline-cloudwolker.cloudoam.workers.dev/auth/discord
    ↓
Discord
    ↓
shiftline://auth?ticket=...
    ↓
/auth/ticket
    ↓
Cloudwolker session token
    ↓
App.login.user_token
]]



App = App or {}

App.login = App.login or {
    authenticated = false,
    userid = "",
    user_token = "",
    username = "",
    userId = "",
    avatarUrl = "",
    avatarVersion = 0,
    expiresAt = 0,
}



function App.setLogin(data)
    if type(data) ~= "table" then
        return
    end

    local login = App.login

    if data.authenticated ~= nil then
        login.authenticated = data.authenticated
    end

    if data.userid ~= nil then
        login.userid = tostring(data.userid)
    end

    if data.user_token ~= nil then
        login.user_token = tostring(data.user_token)
    end

    if data.username ~= nil then
        login.username = tostring(data.username)
    end

    if data.userId ~= nil then
        login.userId = tostring(data.userId)
    end

    if data.avatarUrl ~= nil then
        login.avatarUrl = tostring(data.avatarUrl)
    end

    if data.avatarVersion ~= nil then
        login.avatarVersion = tonumber(data.avatarVersion) or 0
    end

    if data.expiresAt ~= nil then
        login.expiresAt = tonumber(data.expiresAt) or 0
    end
end



local CLOUDWOLKER_BASE_URL =
    "https://shiftline-cloudwolker.cloudoam.workers.dev"

local CLOUDWOLKER_DISCORD_LOGIN_URL =
    CLOUDWOLKER_BASE_URL .. "/auth/discord"

local CLOUDWOLKER_TICKET_URL =
    CLOUDWOLKER_BASE_URL .. "/auth/ticket"

local CLOUDWOLKER_SESSION_FILE =
    "cloudwolker_session.json"



local okCloudwolkerJSON, CloudwolkerJSON =
    pcall(require, "JSON")

local okCloudwolkerHTTP, CloudwolkerHTTP =
    pcall(require, "socket.http")

local okCloudwolkerLtn12, CloudwolkerLtn12 =
    pcall(require, "ltn12")



local function cloudwolkerLog(level, ...)
    local logger = log and log[level]

    if type(logger) == "function" then
        logger("[Cloudwolker]", ...)
    end
end



local function cloudwolkerUrlEncode(value)
    value = tostring(value or "")

    return value:gsub(
        "([^%w%-_%.~])",
        function(c)
            return string.format(
                "%%%02X",
                string.byte(c)
            )
        end
    )
end



local function cloudwolkerUrlDecode(value)
    if type(value) ~= "string" then
        return ""
    end

    value = value:gsub("+", " ")

    value = value:gsub(
        "%%(%x%x)",
        function(hex)
            return string.char(
                tonumber(hex, 16)
            )
        end
    )

    return value
end



local function cloudwolkerParseQuery(query)
    local result = {}

    if type(query) ~= "string" then
        return result
    end

    for part in query:gmatch("[^&]+") do
        local key, value =
            part:match("^([^=]*)=(.*)$")

        if key then
            result[
                cloudwolkerUrlDecode(key)
            ] =
                cloudwolkerUrlDecode(value)
        else
            result[
                cloudwolkerUrlDecode(part)
            ] = ""
        end
    end

    return result
end



local function cloudwolkerParseURI(uri)
    if type(uri) ~= "string" then
        return nil
    end

    local scheme, rest =
        uri:match("^([%w%+%-%.]+)://(.+)$")

    if not scheme or not rest then
        return nil
    end

    scheme = scheme:lower()

    local authorityAndPath, query =
        rest:match("^([^?]*)%?(.*)$")

    if not authorityAndPath then
        authorityAndPath = rest
    end

    if scheme ~= "shiftline" then
        return nil
    end

    local path =
        authorityAndPath:match("^([^#]*)")

    return {
        scheme = scheme,
        path = path or "",
        query = cloudwolkerParseQuery(query),
    }
end



local function cloudwolkerHttpGet(url, headers)
    if not okCloudwolkerHTTP
        or not CloudwolkerHTTP then

        return nil,
            nil,
            "socket.http が利用できません"
    end

    if not okCloudwolkerLtn12
        or not CloudwolkerLtn12 then

        return nil,
            nil,
            "ltn12 が利用できません"
    end

    local responseBody = {}

    local requestHeaders = {
        ["User-Agent"] = "ShiftLine/" .. tostring(appId or "game"),
        ["Accept"] = "application/json",
    }

    if type(headers) == "table" then
        for key, value in pairs(headers) do
            requestHeaders[key] = value
        end
    end

    local ok, result, code, responseHeaders, status =
        pcall(
            CloudwolkerHTTP.request,
            {
                url = url,
                method = "GET",
                headers = requestHeaders,
                sink = CloudwolkerLtn12.sink.table(
                    responseBody
                ),
                redirect = true,
                maxredirects = 3,
            }
        )

    if not ok then
        return nil,
            nil,
            tostring(result)
    end

    local body =
        table.concat(responseBody)

    return body,
        tonumber(code),
        status or responseHeaders
end



local function cloudwolkerSaveSession()
    if not okCloudwolkerJSON
        or not CloudwolkerJSON then

        cloudwolkerLog(
            "warn",
            "JSON module is unavailable; session cannot be cached"
        )

        return false
    end

    if type(App.login.user_token) ~= "string"
        or App.login.user_token == "" then

        return false
    end

    local data = {
        token = App.login.user_token,
        expiresAt = App.login.expiresAt or 0,

        user = {
            id = App.login.userId,
            displayName = App.login.username,
            avatarVersion = App.login.avatarVersion or 0,
            avatarUrl = App.login.avatarUrl,
        },
    }

    local ok, encoded =
        pcall(
            CloudwolkerJSON.encode,
            data
        )

    if not ok then
        cloudwolkerLog(
            "warn",
            "Failed to encode cached session",
            tostring(encoded)
        )

        return false
    end

    local writeOK, writeError =
        love.filesystem.write(
            CLOUDWOLKER_SESSION_FILE,
            encoded
        )

    if not writeOK then
        cloudwolkerLog(
            "warn",
            "Failed to save cached session",
            tostring(writeError)
        )

        return false
    end

    return true
end



local function cloudwolkerClearSession()
    if love.filesystem.getInfo(
        CLOUDWOLKER_SESSION_FILE
    ) then
        love.filesystem.remove(
            CLOUDWOLKER_SESSION_FILE
        )
    end

    App.setLogin({
        authenticated = false,
        userid = "",
        user_token = "",
        username = "",
        userId = "",
        avatarUrl = "",
        avatarVersion = 0,
        expiresAt = 0,
    })
end



local function cloudwolkerLoadSession()
    if not love.filesystem.getInfo(
        CLOUDWOLKER_SESSION_FILE
    ) then
        return false
    end

    local contents, readError =
        love.filesystem.read(
            CLOUDWOLKER_SESSION_FILE
        )

    if not contents then
        cloudwolkerLog(
            "warn",
            "Failed to read cached session",
            tostring(readError)
        )

        return false
    end

    if not okCloudwolkerJSON
        or not CloudwolkerJSON then

        return false
    end

    local ok, data =
        pcall(
            CloudwolkerJSON.decode,
            contents
        )

    if not ok
        or type(data) ~= "table" then

        cloudwolkerClearSession()
        return false
    end

    local token =
        data.token

    local expiresAt =
        tonumber(data.expiresAt or 0) or 0

    if type(token) ~= "string"
        or token == "" then

        cloudwolkerClearSession()
        return false
    end

    if expiresAt > 0
        and expiresAt <= os.time() then

        cloudwolkerLog(
            "info",
            "Cached Cloudwolker session expired"
        )

        cloudwolkerClearSession()
        return false
    end

    local user =
        type(data.user) == "table"
        and data.user
        or {}

    App.setLogin({
        authenticated = true,
        userid = tostring(user.id or ""),
        user_token = token,
        username = tostring(
            user.displayName or ""
        ),
        userId = tostring(user.id or ""),
        avatarUrl = tostring(
            user.avatarUrl or ""
        ),
        avatarVersion =
            tonumber(user.avatarVersion or 0)
            or 0,
        expiresAt = expiresAt,
    })

    cloudwolkerLog(
        "info",
        "Cached Cloudwolker session restored"
    )

    return true
end



local function cloudwolkerApplyTicketResponse(data)
    if type(data) ~= "table" then
        return false,
            "Cloudwolker response is not an object"
    end

    if data.ok ~= true then
        return false,
            tostring(
                data.error
                or "Cloudwolker authentication failed"
            )
    end

    if type(data.token) ~= "string"
        or data.token == "" then

        return false,
            "Cloudwolker session token is missing"
    end

    if type(data.user) ~= "table" then
        return false,
            "Cloudwolker user data is missing"
    end

    local user =
        data.user

    local userId =
        tostring(user.id or "")

    if userId == "" then
        return false,
            "Cloudwolker user ID is missing"
    end

    App.setLogin({
        authenticated = true,
        userid = userId,
        user_token = data.token,
        username = tostring(
            user.displayName or "ShiftLine User"
        ),
        userId = userId,
        avatarUrl = tostring(
            user.avatarUrl or ""
        ),
        avatarVersion =
            tonumber(user.avatarVersion or 0)
            or 0,
        expiresAt =
            tonumber(data.expiresAt or 0)
            or 0,
    })

    cloudwolkerSaveSession()

    cloudwolkerLog(
        "info",
        "Cloudwolker authentication completed",
        "userId=" .. userId
    )

    return true
end



local function cloudwolkerExchangeTicket(ticket)
    if type(ticket) ~= "string"
        or ticket == "" then

        return false,
            "Login ticket is empty"
    end

    local url =
        CLOUDWOLKER_TICKET_URL ..
        "?ticket=" ..
        cloudwolkerUrlEncode(ticket)

    cloudwolkerLog(
        "info",
        "Exchanging Cloudwolker login ticket"
    )

    local body, code, errorMessage =
        cloudwolkerHttpGet(url)

    if not body then
        return false,
            errorMessage
            or "Cloudwolker HTTP request failed"
    end

    if code ~= 200 then
        return false,
            "Cloudwolker ticket HTTP " ..
            tostring(code)
    end

    if not okCloudwolkerJSON
        or not CloudwolkerJSON then

        return false,
            "JSON module is unavailable"
    end

    local ok, data =
        pcall(
            CloudwolkerJSON.decode,
            body
        )

    if not ok then
        return false,
            "Cloudwolker JSON decode failed: " ..
            tostring(data)
    end

    return cloudwolkerApplyTicketResponse(
        data
    )
end



function App.cloudwolkerLogin()
    if not love.system
        or type(love.system.openURL) ~= "function" then

        return false,
            "love.system.openURL is unavailable"
    end

    local ok, result =
        pcall(
            love.system.openURL,
            CLOUDWOLKER_DISCORD_LOGIN_URL
        )

    if not ok then
        return false,
            tostring(result)
    end

    cloudwolkerLog(
        "info",
        "Discord login browser opened"
    )

    return true
end



function App.cloudwolkerLogout()
    cloudwolkerClearSession()
end



function App.cloudwolkerIsAuthenticated()
    return
        App.login.authenticated == true
        and type(App.login.user_token) == "string"
        and App.login.user_token ~= ""
end



function App.cloudwolkerGetToken()
    if not App.cloudwolkerIsAuthenticated() then
        return nil
    end

    return App.login.user_token
end



local function getCloudwolkerAuthFromArguments()
    if type(arg) ~= "table" then
        return nil
    end

    for _, value in ipairs(arg) do
        if type(value) == "string" then
            local parsed =
                cloudwolkerParseURI(value)

            if parsed
                and parsed.path == "auth" then

                return parsed.query
            end
        end
    end

    return nil
end



local function processCloudwolkerLaunchArguments()
    local query =
        getCloudwolkerAuthFromArguments()

    if not query then
        return false
    end

    local errorMessage =
        query.error

    if errorMessage
        and errorMessage ~= "" then

        cloudwolkerLog(
            "warn",
            "Cloudwolker authentication returned an error",
            errorMessage
        )

        return false
    end

    local ticket =
        query.ticket

    if type(ticket) ~= "string"
        or ticket == "" then

        cloudwolkerLog(
            "warn",
            "Cloudwolker auth callback did not contain a ticket"
        )

        return false
    end

    local ok, errorText =
        cloudwolkerExchangeTicket(
            ticket
        )

    if not ok then
        cloudwolkerLog(
            "error",
            "Cloudwolker ticket exchange failed",
            tostring(errorText)
        )

        return false
    end

    return true
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

local discordSDK = require "lib.SDK"
local appId = require("applicationId")



local function isLovebirdAllowed()
    return true
end

local lovebird = nil

if isLovebirdAllowed() then
    local okLovebird, lb =
        pcall(require, "lovebird")

    if okLovebird and lb then
        lovebird = lb
    end
end

local gamejolt = require "gamejolt"
local openingloader = require "openingloader"
local opening = require "opening"
local gamemodeselect = require "gamemodeselect"
local play = require "gameplay.play"
local musicselect = require "musicselect"
local userbadge = require "userbadge"
local settings = require "settings"
local console = require "console"
local story = require "storyselecter"
local result = require "result"
local reporter = require "error_reporter"
local paths = require "core.paths"
local coreAudio = require "core.audio"
local coreInput = require "core.input"
local coreWindow = require "core.window"
local songmanager = require "songs.songmanager"
local songloader = require "songs.songloader"

local presence = {}
local discordActivityInvites = {}
local discordEnabled = false
local nextPresenceUpdate = 0
local discordJoinSecretPrefix = "shiftline:"
local discordLargeImageKey =
    os.getenv("SHIFTLINE_DISCORD_LARGE_IMAGE_KEY")
    or "ico"

local programnumber=0
local coreScene = require "core.scene"
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
    [4] = require "gameplay.play",
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
    startup = {
        collections = nil,
        previewSources = nil
    }
}



local function prepareStartupAssets()
    if openingloader and openingloader.getCollections then
        main.startup.collections =
            openingloader.getCollections()
            or main.startup.collections
    end

    if main.startup.collections then
        songloader.loadCollections(
            main.startup.collections,
            "local"
        )

        if musicselect.setCollections then
            musicselect.setCollections(
                main.startup.collections
            )
        end

        if musicselect.setStartupAssets then
            coreScene.attach(program)

            musicselect.setStartupAssets(
                main.startup.collections,
                main.startup.previewSources or {}
            )
        end
    end
end



function main.getStartupAssets()
    return main.startup
end



local function getDiscordGameplayState(
    difficulty,
    title
)
    local fields = {}

    if type(title) == "string"
        and title ~= "" then

        fields[#fields + 1] = title
    end

    if type(difficulty) == "string"
        and difficulty ~= "" then

        fields[#fields + 1] =
            string.upper(difficulty)
    end

    return #fields > 0
        and table.concat(fields, " | ")
        or nil
end



local function getDiscordPresenceFields()
    if programnumber == 3 then
        return "Song Select", nil
    end

    if programnumber == 4 then
        local title =
            type(musicname) == "string"
            and musicname ~= ""
            and musicname
            or "ShiftLine"

        local difficulty =
            type(musicdifficulty) == "string"
            and musicdifficulty ~= ""
            and string.upper(musicdifficulty)
            or nil

        return
            "Playing: " .. title,
            getDiscordGameplayState(
                difficulty
            )
    end

    if programnumber >= 9
        and programnumber <= 12 then

        if programnumber == 11 then
            local title =
                type(musicname) == "string"
                and musicname ~= ""
                and musicname
                or nil

            local difficulty =
                type(musicdifficulty) == "string"
                and musicdifficulty ~= ""
                and musicdifficulty
                or nil

            return
                "Online",
                getDiscordGameplayState(
                    difficulty,
                    title
                )
        end

        return "Online", nil
    end

    return nil, nil
end



local function getDiscordJoinSecretFromArguments()
    if type(arg) ~= "table" then
        return nil
    end

    for _, value in ipairs(arg) do
        if type(value) == "string" then
            local secret =
                value:match(
                    "^discord%-[^:]+://join/(.+)$"
                )

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

    local osName =
        love.system.getOS()

    if osName ~= "Windows"
        and osName ~= "OS X" then

        return false
    end

    local source =
        love.filesystem.getSource()

    if type(source) ~= "string"
        or source == "" then

        log.warn(
            "Discord RPC: LÖVE source could not be determined"
        )

        return false
    end

    source =
        source:gsub(
            "[/\\]+$",
            ""
        )

    log.info(
        "Discord RPC: LÖVE source = " ..
        source
    )

    local launcherPath

    if osName == "Windows" then

        if source:lower():match("%.exe$") then
            launcherPath = source
        else
            launcherPath =
                source ..
                "/ShiftLineLauncher.exe"
        end

    elseif osName == "OS X" then

        if source:lower():match("%.app$") then
            launcherPath = source
        else
            launcherPath =
                source ..
                "/ShiftLineLauncher.app"
        end
    end

    if not launcherPath then
        return false
    end

    log.info(
        "Discord RPC: launcher path = " ..
        launcherPath
    )

    local info =
        love.filesystem.getInfo(
            launcherPath
        )

    if not info then
        log.warn(
            "Discord RPC: launcher not found: " ..
            launcherPath
        )

        return false
    end

    local function quote(value)
        return '"' ..
            value:gsub('"', '\\"') ..
            '"'
    end


    if osName == "OS X" then

        local result =
            os.execute(
                "/System/Library/Frameworks/CoreServices.framework/" ..
                "Frameworks/LaunchServices.framework/Support/lsregister " ..
                "-f " ..
                quote(launcherPath)
            )

        if result ~= true
            and result ~= 0 then

            log.warn(
                "Discord RPC: macOS launcher registration failed: " ..
                tostring(result)
            )

            return false
        end

        log.info(
            "Discord RPC: macOS launcher registered: " ..
            launcherPath
        )

        return true
    end


    local schemes = {
        "discord-" .. appId,
        "shiftline"
    }

    for _, scheme in ipairs(schemes) do

        local key =
            "HKCU\\Software\\Classes\\" ..
            scheme

        local command =
            quote(launcherPath) ..
            ' "%1"'

        local result =
            os.execute(
                "reg add " ..
                quote(key) ..
                " /ve /t REG_SZ /d " ..
                quote("URL:" .. scheme) ..
                " /f"
            )

        if result ~= true
            and result ~= 0 then

            log.warn(
                "Discord RPC: protocol registration failed: " ..
                scheme ..
                " / " ..
                tostring(result)
            )

            return false
        end

        result =
            os.execute(
                "reg add " ..
                quote(key) ..
                ' /v "URL Protocol" /t REG_SZ /d "" /f'
            )

        if result ~= true
            and result ~= 0 then

            log.warn(
                "Discord RPC: protocol metadata registration failed: " ..
                scheme ..
                " / " ..
                tostring(result)
            )

            return false
        end

        result =
            os.execute(
                "reg add " ..
                quote(
                    key ..
                    "\\shell\\open\\command"
                ) ..
                " /ve /t REG_SZ /d " ..
                quote(command) ..
                " /f"
            )

        if result ~= true
            and result ~= 0 then

            log.warn(
                "Discord RPC: launcher command registration failed: " ..
                scheme ..
                " / " ..
                tostring(result)
            )

            return false
        end

        log.info(
            "Protocol registered: " ..
            scheme
        )
    end

    log.info(
        "Discord RPC: launcher = " ..
        launcherPath
    )

    return true
end



function setDiscordJoinSecret(joinSecret)
    if type(joinSecret) ~= "string" then
        return
    end

    if not discordEnabled then
        return
    end

    presence.joinSecret =
        joinSecret

    discordSDK.update(
        presence
    )
end



local function handleDiscordEvent(event)
    if type(event) ~= "table" then
        return
    end

    if event.type == "activity_invite" then

        if #discordActivityInvites < 16 then
            discordActivityInvites[
                #discordActivityInvites + 1
            ] = event

            log.info(
                "Discord Social SDK: Activity Invite received from " ..
                tostring(event.senderName)
            )
        else

            discordSDK.respondToActivityInvite(
                event.id,
                false
            )

            log.warn(
                "Discord Social SDK: Activity Invite queue is full"
            )
        end

    elseif event.type == "join" then

        local secret =
            event.secret

        if type(secret) ~= "string"
            or secret == "" then

            return
        end

        local roomID =
            secret:match(
                "^" ..
                discordJoinSecretPrefix ..
                "(.+)$"
            )
            or secret

        if roomID == "" then
            return
        end

        log.info(
            "Discord Social SDK: joining room from activity"
        )

        onlineMode = true
        main.online = true

        if programnumber ~= 9 then
            changeProgram(9)
        end

        if online_room
            and online_room.joinWithRoomID then

            online_room.joinWithRoomID(
                roomID
            )
        end

    elseif event.type == "spectate" then

        log.info(
            "Discord Social SDK: spectate event received"
        )

    elseif event.type == "join_request" then

        log.info(
            "Discord Social SDK: join request from " ..
            tostring(event.username)
        )
    end
end



local function getDiscordInviteDialogBounds()
    local width, height =
        love.graphics.getDimensions()

    local dialogWidth =
        math.min(
            620,
            width - 32
        )

    local dialogHeight = 190

    return
        (width - dialogWidth) / 2,
        (height - dialogHeight) / 2,
        dialogWidth,
        dialogHeight
end



local function respondToNextDiscordInvite(accept)
    local invite =
        table.remove(
            discordActivityInvites,
            1
        )

    if invite then
        discordSDK.respondToActivityInvite(
            invite.id,
            accept
        )
    end
end



local function drawDiscordInviteDialog()
    local invite =
        discordActivityInvites[1]

    if not invite then
        return
    end

    local x, y, width, height =
        getDiscordInviteDialogBounds()

    local language =
        settings.settingsdata.miscsettings.language
        or "jp"

    local wantsToJoin =
        invite.action == 5

    local title
    local prompt
    local controls

    if language == "en" then

        title =
            wantsToJoin
            and "Join request"
            or "Activity invite"

        prompt =
            wantsToJoin
            and (
                invite.senderName ..
                " wants to join your session"
            )
            or (
                invite.senderName ..
                " invited you to join"
            )

        controls =
            "Enter: accept    Esc: dismiss"

    else

        title =
            wantsToJoin
            and "参加リクエスト"
            or "アクティビティ招待"

        prompt =
            wantsToJoin
            and (
                invite.senderName ..
                " さんが参加を希望しています"
            )
            or (
                invite.senderName ..
                " さんから参加招待が届きました"
            )

        controls =
            "Enter: 承認    Esc: 辞退"
    end

    love.graphics.push("all")

    love.graphics.setColor(
        0, 0, 0, 0.9
    )

    love.graphics.rectangle(
        "fill",
        x,
        y,
        width,
        height,
        4
    )

    love.graphics.setColor(
        1, 1, 1, 0.4
    )

    love.graphics.rectangle(
        "line",
        x,
        y,
        width,
        height,
        4
    )

    love.graphics.setColor(
        1, 1, 1, 1
    )

    love.graphics.printf(
        title,
        x + 24,
        y + 22,
        width - 48,
        "center"
    )

    love.graphics.printf(
        prompt,
        x + 24,
        y + 68,
        width - 48,
        "center"
    )

    love.graphics.printf(
        controls,
        x + 24,
        y + height - 48,
        width - 48,
        "center"
    )

    love.graphics.pop()
end



local function registerDiscordLaunchCommand()
    if not discordEnabled
        or not love.filesystem.getSource then

        return
    end

    local source =
        love.filesystem.getSource()
        :gsub("[/\\]+$", "")

    local launcherPath =
        source ..
        "/../ShiftLineLauncher.exe"

    local info =
        love.filesystem.getInfo(
            launcherPath
        )

    if not info then
        log.warn(
            "Discord Social SDK: launcher not found: " ..
            launcherPath
        )

        return
    end

    local command =
        '"' ..
        launcherPath:gsub(
            '"',
            '\\"'
        ) ..
        '" --online'

    discordSDK.registerLaunchCommand(
        command
    )
end



function love.load()

    local icon =
        love.image.newImageData(
            "img/ico.png"
        )

    love.window.setIcon(icon)

    paths.ensure()

    love.audio.setVolume(0.5)

    log.outfile =
        "ShiftLine.log"

    log.level =
        "trace"

    log.info("boot")

    math.randomseed(
        os.time()
    )

    reporter.resendIfExists()


    cursor =
        love.mouse.newCursor(
            "img/cursor.png",
            0,
            0
        )

    love.mouse.setCursor(
        cursor
    )


    settings.load()

    coreAudio.setVolume(
        settings.settingsdata.audiosettings.mastervolume
    )


    programsettings()
    program.load()


    -- Cloudwolker session
    -- 既存セッションがあればDiscordログインを省略する
    cloudwolkerLoadSession()

    -- shiftline://auth?ticket=... からの復帰
    processCloudwolkerLaunchArguments()


    -- Discord
    log.info(
        "Discord Social SDK: checking initialize"
    )

    discordEnabled =
        discordSDK.start(
            appId
        )

    if not discordEnabled then

        log.info(
            "Discord disabled: missing module or platform library"
        )

    else

        registerDiscordLaunchCommand()

    end


    local now =
        os.time()

    local details, state =
        getDiscordPresenceFields()

    presence = {
        state = state,
        details = details,
        startTimestamp = now,
        partyId = "",
        partySize = 1,
        partyMax = 1,
        largeImageKey =
            discordLargeImageKey ~= ""
            and discordLargeImageKey
            or nil,
        largeImageText = "ShiftLine",
        matchSecret = nil,
        joinSecret = nil,
        spectateSecret = nil,
    }


    if discordEnabled then
        discordSDK.update(
            presence
        )
    end


    nextPresenceUpdate = 0
end



function love.update(dt)

    online_connect.update()


    local details, state =
        getDiscordPresenceFields()

    if presence.details ~= details
        or presence.state ~= state then

        presence.details = details
        presence.state = state

        nextPresenceUpdate = 0
    end


    local roomID =
        online_connect.getRoomID()

    local hasRoomID =
        type(roomID) == "string"
        and roomID ~= ""


    if hasRoomID then

        presence.partyId =
            roomID

        presence.joinSecret =
            discordJoinSecretPrefix ..
            roomID

        presence.partySize =
            online_connect.isConnected()
            and online_connect.getPartyCount()
            or 1

        presence.partyMax = 4
        presence.instance = 1

    else

        presence.partyId = nil
        presence.joinSecret = nil
        presence.partySize = 1
        presence.partyMax = 1
        presence.instance = 0

    end


    if discordEnabled then

        local now =
            love.timer.getTime()

        if nextPresenceUpdate < now then

            discordSDK.update(
                presence
            )

            nextPresenceUpdate =
                now + 2.0
        end

        discordSDK.updateCallback()

        for _ = 1, 8 do

            local event =
                discordSDK.pollEvent()

            if not event then
                break
            end

            handleDiscordEvent(
                event
            )
        end
    end


    if lovebird then
        pcall(
            lovebird.update
        )
    end


    if onlineMode then
        main.online=true
    end


    if programnumber == 0
        and openingloader.endprocess then

        prepareStartupAssets()
        changeProgram(1)

    elseif programnumber == 1
        and opening.endprocess then

        changeProgram(2)

    elseif programnumber == 2
        and gamemodeselect.endprocess
        and gamemodeselect.selectedmode == 0 then

        changeProgram(1)

    elseif programnumber == 2
        and gamemodeselect.endprocess
        and gamemodeselect.selectedmode == 1 then

        changeProgram(3)

    elseif programnumber == 2
        and gamemodeselect.endprocess
        and gamemodeselect.selectedmode == 2 then

        storyMode =true
        changeProgram(6)

    elseif programnumber == 2
        and gamemodeselect.endprocess
        and gamemodeselect.selectedmode == 3 then

        changeProgram(5)

    elseif programnumber == 2
        and gamemodeselect.endprocess
        and gamemodeselect.selectedmode == 4 then

        changeProgram(9)

    elseif programnumber == 6
        and story.endprocess then

        changeProgram(2)

    elseif programnumber ==3
        and musicselect.endprocess
        and musicselect.selectmode == 1 then

        changeProgram(2)

    elseif programnumber ==3
        and musicselect.endprocess
        and musicselect.selectmode == 2 then

        local playCollections = nil

        musiclevel =
            musicselect.selectedLevelValue

        musicdifficulty =
            musicselect.selectedDifficulty

        musicname =
            musicselect.musicname

        musicartist =
            musicselect.musicartist

        local diffName =
            musicselect.selectedDifficulty

        selectindex =
            musicselect.selectedIndex


        if play.setCollections
            and musicselect.getCollections then

            play.setCollections(
                playCollections
                or (
                    musicselect.getPlayCollections
                    and musicselect.getPlayCollections()
                )
                or musicselect.getCollections()
            )
        end

        gamestatus =
            string.format(
                "%s [%s]",
                musicname,
                string.upper(diffName)
            )

        changeProgram(4)

    elseif programnumber ==3
        and musicselect.endprocess
        and musicselect.selectmode == 8 then

        local playCollections = nil

        musiclevel =
            musicselect.selectedLevelValue

        musicdifficulty =
            musicselect.selectedDifficulty

        musicname =
            musicselect.musicname

        musicartist =
            musicselect.musicartist

        local diffName =
            musicselect.selectedDifficulty

        selectindex =
            musicselect.selectedIndex


        if play.setCollections
            and musicselect.getCollections then

            play.setCollections(
                playCollections
                or (
                    musicselect.getPlayCollections
                    and musicselect.getPlayCollections()
                )
                or musicselect.getCollections()
            )
        end

        gamestatus =
            string.format(
                "%s [%s] (Editor)",
                musicname,
                string.upper(diffName)
            )

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

    elseif program == online
        or program == online_room
        or program == online_musicselect
        or program == online_play
        or program == online_result then

        gamestatus = "Online"
    end



    programsettings()

    coreScene.update(dt)


    if programnumber ~= 9
        and programnumber ~= 10
        and programnumber ~= 11
        and programnumber ~= 12 then

        userbadge.update(dt)
    end


    love.mouse.setVisible(true)


    if program == online
        or program == online_room
        or program == online_musicselect
        or program == online_play
        or program == online_result then

        presence.partyMax = 4
        presence.partySize =
            online_connect.getPartyCount()
    end

end



love.mousepressed = function(
    x,
    y,
    button,
    istouch,
    presses
)

    if #discordActivityInvites > 0 then

        if button == 1 then

            local dialogX,
                dialogY,
                dialogWidth,
                dialogHeight =
                getDiscordInviteDialogBounds()

            if x >= dialogX
                and x <= dialogX + dialogWidth
                and y >= dialogY + dialogHeight - 56
                and y <= dialogY + dialogHeight then

                respondToNextDiscordInvite(
                    x < dialogX + dialogWidth / 2
                )
            end
        end

        return
    end


    if console
        and console.active then

        return
    end


    if program.mousepressed then

        program.mousepressed(
            x,
            y,
            button,
            istouch,
            presses
        )
    end
end



function love.mousemoved(
    x,
    y,
    dx,
    dy,
    istouch
)

    if console
        and console.active then

        return
    end


    if program
        and program.mousemoved then

        program.mousemoved(
            x,
            y,
            dx,
            dy,
            istouch
        )
    end
end



function love.mousereleased(
    x,
    y,
    button,
    istouch,
    presses
)

    if console
        and console.active then

        return
    end


    if program.mousereleased then

        program.mousereleased(
            x,
            y,
            button,
            istouch,
            presses
        )
    end
end



function love.wheelmoved(x, y)

    if console
        and console.active then

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

    coreScene.draw()


    if programnumber ~= 0
        and programnumber ~= 4
        and programnumber ~= 9
        and programnumber ~= 10
        and programnumber ~= 11
        and programnumber ~= 12 then

        userbadge.draw()
    end


    if program.drawOverlay then
        program.drawOverlay()
    end


    if console
        and console.active then

        console.draw()
    end


    drawDiscordInviteDialog()

end



function love.resize(w, h)

    if program
        and program.updateLayout then

        pcall(
            program.updateLayout,
            true
        )
    end


    if program
        and program.resize then

        pcall(
            program.resize,
            w,
            h
        )
    end
end



function programsettings()

    program =
        programs[programnumber]

    _G.program =
        program

    _G.programnumber =
        programnumber

    coreScene.attach(
        program
    )
end



function changeProgram(num)

    if program
        and program.quit then

        program.quit()
    end

    programnumber =
        num

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
        discordSDK.shutdown()
    end

    log.info(
        "exit game"
    )
end



function love.errhand(msg)

    local trace =
        debug.traceback(
            tostring(msg),
            2
        )

    reporter.report(
        msg,
        trace
    )

    return function()

        love.graphics.clear(
            0.1,
            0.1,
            0.1
        )

        love.graphics.setColor(
            1,
            1,
            1,
            1
        )

        love.graphics.print(
            "A fatal error occurred.\n\n" ..
            trace,
            20,
            20
        )

        love.graphics.present()
    end
end



function love.textinput(t)

    if console
        and console.active then

        if console.textinput then
            console.textinput(t)
        end

        return
    end


    if program
        and program.textinput then

        program.textinput(t)

        return
    end


    if settings
        and type(settings.textinput) == "function" then

        settings.textinput(t)
    end
end



function love.keypressed(
    key,
    scancode,
    isrepeat
)

    if #discordActivityInvites > 0 then

        if key == "return"
            or key == "space"
            or key == "kpenter" then

            respondToNextDiscordInvite(
                true
            )

        elseif key == "escape" then

            respondToNextDiscordInvite(
                false
            )
        end

        return
    end


    if coreInput.keypressed(
        key,
        scancode,
        isrepeat
    ) then

        return
    end


    if key == "f10"
        and console then

        console.toggle()

        return
    end


    if console
        and console.active then

        if console.keypressed then

            console.keypressed(
                key,
                scancode,
                isrepeat
            )
        end

        return
    end


    if key == "f1"
        and programnumber == 8 then

        if program.keypressed then

            program.keypressed(
                key,
                scancode,
                isrepeat
            )
        end

        return
    end


    if key == "f1" then

        settings.openMenu()

        return
    end


    if program.keypressed then

        program.keypressed(
            key,
            scancode,
            isrepeat
        )
    end
end



function love.keyreleased(
    key,
    scancode
)

    coreInput.keyreleased(
        key,
        scancode
    )


    if console
        and console.active then

        if console.keyreleased then

            console.keyreleased(
                key,
                scancode
            )
        end

        return
    end


    if program.keyreleased then

        program.keyreleased(
            key,
            scancode
        )
    end
end



function love.textedited(
    text,
    start,
    length
)

    if program.textedited then

        program.textedited(
            text,
            start,
            length
        )
    end
end



return main