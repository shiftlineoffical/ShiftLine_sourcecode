--[[
loding%割合
10% アップデート確認
60% sfbファイル確認/作成
30% Gamejolt関連


]]






local play = require "play"
local musicselect = require "musicselect"
local log = require "log"
local i18n = require "i18n"
local audiocache = require "audiocache"
local ui = require("lib.ui")
local openingloader={}

--ロゴ関連
displayy = love.graphics.getHeight()
displayx= love.graphics.getWidth()
local logotransparency=0
local lodingfont
local logo
local logox,logoy
local sfb


--LODING%表示関連
local endsaccess=0


--アプリバージョン
local appversion="0.3.5"
local nowappversion
local nowappdownloadurl



--sfb作成関連
local createsfb=require("createsfb")

local gamejolt=require "gamejolt"




local timer = 0

local fadingIn = true
local fadingOut = false




local http = require("socket.http")

local function getPathSeparator()
    return package.config:sub(1, 1)
end

local function joinPath(a, b)
    local sep = getPathSeparator()
    if a:sub(-1) == sep then
        return a .. b
    end
    return a .. sep .. b
end

local function getInstallDir()
    local base = nil
    if love.filesystem.getSourceBaseDirectory then
        base = love.filesystem.getSourceBaseDirectory()
    end
    if not base or base == "" then
        base = love.filesystem.getWorkingDirectory()
    end

    if love.system and love.system.getOS then
        local osName = love.system.getOS()
        if osName == "OS X" and type(base) == "string" then
            local appStart = base:find("%.app/")
            if appStart then
                local appPath = base:sub(1, appStart + 3)
                local parent = appPath:match("^(.*)/[^/]+%.app$")
                if parent and parent ~= "" then
                    return parent
                end
                return appPath
            end
        end
    end

    return base
end

local function fileExists(path)
    local f = io.open(path, "rb")
    if f then
        f:close()
        return true
    end
    return false
end

local function ensureUpdaterOnDisk(targetDir, updaterName)
    updaterName = updaterName or "update_console.ps1"
    local updaterPath = joinPath(targetDir, updaterName)
    if fileExists(updaterPath) then
        return true, updaterPath
    end

    local data, readErr = love.filesystem.read(updaterName)
    if not data then
        return false, "failed to read updater from package: " .. tostring(readErr)
    end

    local f, err = io.open(updaterPath, "wb")
    if not f then
        return false, "failed to write updater: " .. tostring(err)
    end
    f:write(data)
    f:close()
    return true, updaterPath
end

local function cmdQuote(s)
    s = tostring(s or "")
    s = s:gsub('"', '""')
    return '"' .. s .. '"'
end

local function shQuote(s)
    s = tostring(s or "")
    s = s:gsub("'", "'\\''")
    return "'" .. s .. "'"
end

local function escapeAppleScriptString(s)
    s = tostring(s or "")
    s = s:gsub("\\", "\\\\")
    s = s:gsub('"', '\\"')
    return '"' .. s .. '"'
end

local function runCommand(cmd)
    local r1, r2, r3 = os.execute(cmd)
    if type(r1) == "boolean" then
        return r1
    end
    if type(r1) == "number" then
        return r1 == 0
    end
    if r2 == "exit" and type(r3) == "number" then
        return r3 == 0
    end
    return false
end

local function getRestartPath()
    local restartPath = nil
    local fs = love and love.filesystem
    if fs and fs.getExecutablePath then
        restartPath = fs.getExecutablePath()
    elseif type(arg) == "table" and type(arg[0]) == "string" then
        restartPath = arg[0]
    end
    if restartPath == "" then
        restartPath = nil
    end
    return restartPath
end

local function runWindowsUpdater(url, targetDir)
    local ok, updaterPathOrErr = ensureUpdaterOnDisk(targetDir, "update_console.ps1")
    if not ok then
        return false, updaterPathOrErr
    end

    local restartPath = getRestartPath()

    local cmd = "cmd /c start \"\" powershell -NoProfile -ExecutionPolicy Bypass -File "
        .. cmdQuote(updaterPathOrErr)
        .. " -Url " .. cmdQuote(url)
        .. " -TargetDir " .. cmdQuote(targetDir)
    if restartPath then
        cmd = cmd .. " -RestartPath " .. cmdQuote(restartPath)
    end

    os.execute(cmd)
    return true, cmd
end




local function runPosixUpdater(url, targetDir, osName)
    local ok, updaterPathOrErr = ensureUpdaterOnDisk(targetDir, "update_console.sh")
    if not ok then
        return false, updaterPathOrErr
    end

    runCommand("chmod +x " .. shQuote(updaterPathOrErr))

    local restartPath = getRestartPath()
    local scriptCmd = shQuote(updaterPathOrErr)
        .. " --url " .. shQuote(url)
        .. " --target-dir " .. shQuote(targetDir)
    if restartPath then
        scriptCmd = scriptCmd .. " --restart-path " .. shQuote(restartPath)
    end

    if osName == "OS X" then
        local appleDo = 'tell application "Terminal" to do script ' .. escapeAppleScriptString(scriptCmd)
        local appleActivate = 'tell application "Terminal" to activate'
        local cmd = "osascript -e " .. shQuote(appleDo) .. " -e " .. shQuote(appleActivate)
        if runCommand(cmd) then
            return true, cmd
        end
        local fallback = "sh -c " .. shQuote("nohup " .. scriptCmd .. " >/dev/null 2>&1 &")
        runCommand(fallback)
        return true, fallback
    end

    local scriptCmdQuoted = shQuote(scriptCmd)
    local launch = "if command -v x-terminal-emulator >/dev/null 2>&1; then "
        .. "x-terminal-emulator -e sh -c " .. scriptCmdQuoted .. "; "
        .. "elif command -v gnome-terminal >/dev/null 2>&1; then "
        .. "gnome-terminal -- sh -c " .. scriptCmdQuoted .. "; "
        .. "elif command -v konsole >/dev/null 2>&1; then "
        .. "konsole -e sh -c " .. scriptCmdQuoted .. "; "
        .. "elif command -v xterm >/dev/null 2>&1; then "
        .. "xterm -e sh -c " .. scriptCmdQuoted .. "; "
        .. "else nohup sh -c " .. scriptCmdQuoted .. " >/dev/null 2>&1 & fi"

    local cmd = "sh -c " .. shQuote(launch)
    runCommand(cmd)
    return true, cmd
end

local function runExternalUpdater(url, targetDir)
    local osName = "Windows"
    if love.system and love.system.getOS then
        osName = love.system.getOS()
    end

    if osName == "Windows" then
        return runWindowsUpdater(url, targetDir)
    end

    return runPosixUpdater(url, targetDir, osName)
end
local function compareVersion(v1, v2)
    local function split(v)
        local t = {}
        for num in v:gmatch("%d+") do
            table.insert(t, tonumber(num))
        end
        return t
    end

    local a = split(v1)
    local b = split(v2)

    local len = math.max(#a, #b)
    for i = 1, len do
        local x = a[i] or 0
        local y = b[i] or 0
        if x > y then return 1 end
        if x < y then return -1 end
    end
    return 0
end

local function trimUpdateValue(value)
    if value == nil then
        return nil
    end

    local text = tostring(value)
    text = text:gsub("^%z+", "")
    text = text:gsub("^\239\187\191", "")
    text = text:gsub("\r", "")
    text = text:match("^%s*(.-)%s*$") or ""

    local unquoted = text:match('^"(.*)"$') or text:match("^'(.*)'$")
    if unquoted then
        text = unquoted:match("^%s*(.-)%s*$") or ""
    end

    if text == "" then
        return nil
    end

    if text:lower() == "nil" then
        return nil
    end

    return text
end

local function parseUpdateManifest(remote)
    if type(remote) ~= "string" or remote == "" then
        return {}
    end

    local manifest = {}
    for rawLine in remote:gmatch("[^\n]+") do
        local line = rawLine:gsub("\r", "")
        line = line:gsub("^\239\187\191", "")
        local key, value = line:match("^%s*([%w_]+)%s*[:=]%s*(.-)%s*$")
        if key and value ~= nil then
            manifest[key:lower()] = trimUpdateValue(value)
        end
    end

    return manifest
end

function openingloader.load()

    --アップデート関連
    updatechack()





    --ロゴ表示関連
    logo = love.graphics.newImage("img/logo.png")
    logox = logo:getWidth()
    logoy = logo:getHeight()



    --LODING文字
    lodingfont = ui.newFont("lib/data/fonts/NotoSansJP-ExtraLight.ttf", 40)
    verfont = ui.newFont("lib/data/fonts/NotoSansJP-ExtraLight.ttf", 20)






    --sfb作成関連
    log.info("== Music data load start ==")
    local collections = sfbcheck()
    log.info("sfbcheck() completed")

    if collections then
        log.info("Collections loaded successfully")
    else
        log.warn("Collections is nil!")
        collections = {audio = {}, charts = {}, images = {}}
    end

    local preloadedAudioCount, totalAudioCount = audiocache.preloadCollectionAudio(collections)
    log.info(string.format("Preloaded audio at startup: %d/%d", preloadedAudioCount, totalAudioCount))

    if play.preloadCommonAudio then
        play.preloadCommonAudio()
    end

    if musicselect.setStartupAssets then
        musicselect.setStartupAssets(collections, {})
        log.info("musicselect startup assets were initialized by openingloader")
    end
    
    if play.setCollections then
        play.setCollections(collections)
    end
    log.info("== Music data load end ==")



    --Gamejolt関連
    gamejolt.load()
    endsaccess=endsaccess+30





end





function sfbcheck()
    log.info("== Direct Song Load Started ==")

    local collections = nil
    if createsfb and createsfb.load then
        collections = createsfb.load({forceRebuildAll = false})
    end
    log.info("== Direct Song Load Completed ==")
    
    endsaccess = endsaccess + 30
    return collections
end






function updatechack()
    local remote, code = http.request("https://raw.githubusercontent.com/cloudoamp/ShiftLine/refs/heads/main/update.txt")
    if not remote then
        log.warn("Update server connection failed")
        return
    end
    if tonumber(code) and tonumber(code) ~= 200 then
        log.warn("Update server returned status: " .. tostring(code))
        return
    end
    nowappversion = remote:match('version%s*[:=]%s*([^\n]+)')
    local manifest = parseUpdateManifest(remote)
    nowappversion = manifest.version or trimUpdateValue(nowappversion)
    local osName = love.system.getOS()

    if osName == "Windows" then
        nowappdownloadurl = remote:match('winfileurl%s*[:=]%s*([^\n]+)')
    elseif osName == "OS X" then
        nowappdownloadurl = remote:match('macfileurl%s*[:=]%s*([^\n]+)')
    elseif osName == "Linux" then
        nowappdownloadurl = remote:match('linuxfileurl%s*[:=]%s*([^\n]+)')
    end
    if nowappdownloadurl == "nil" then
        nowappdownloadurl = nil
    end
    if osName == "Windows" then
        nowappdownloadurl = manifest.winfileurl
    elseif osName == "OS X" then
        nowappdownloadurl = manifest.macfileurl
    elseif osName == "Linux" then
        nowappdownloadurl = manifest.linuxfileurl
    end
    nowappdownloadurl = trimUpdateValue(nowappdownloadurl)
    log.debug(remote)
    log.debug("Parsed update version: " .. tostring(nowappversion))
    log.debug("Parsed update url: " .. tostring(nowappdownloadurl))

    if nowappversion and compareVersion(nowappversion, appversion) == 1 then
        log.info("There is an update.")
        log.info("Current version:" .. appversion)
        if not nowappdownloadurl or nowappdownloadurl == "" then
            log.error("Update URL not found.")
            return
        end

        local targetDir = getInstallDir()
        if not targetDir or targetDir == "" then
            log.error("Failed to retrieve the installation path.")
            return
        end

        local ok, info = runExternalUpdater(nowappdownloadurl, targetDir)
        if ok then
            log.info("The update console has been launched. The application will now close.")
            love.event.quit()
        else
            log.error("Failed to launch the update console:" .. tostring(info))
        end

    elseif nowappversion == appversion then
        log.info("The current version is the latest.")
    else
        log.warn("Version information parsing failed.")
    end
end







function openingloader.update(dt)
    -- フェードイン
    if fadingIn then
        logotransparency = math.min(logotransparency + dt, 1)
        endsaccess = math.min(endsaccess + dt * 30, 100)
        if endsaccess >= 100 then
            fadingIn = false
            timer = 0
        end
    -- 待機
    elseif not fadingOut then
        timer = timer + dt
        if timer >= 1 then
            fadingOut = true
            timer = 0
        end
    -- フェードアウト
    elseif fadingOut then
        logotransparency = math.max(logotransparency - dt, 0)
        if logotransparency <= 0 then
            openingloader.endprocess = true
        end
    end
end






function openingloader.draw()
    --ロゴ関連
    displayx = love.graphics.getWidth()
    displayy = love.graphics.getHeight()
    love.graphics.setFont(lodingfont)
    local percentText = endsaccess .. "%"
    local percentHalfWidth = lodingfont:getWidth(percentText) / 2
    --LODING%表示
    love.graphics.setColor(1,1,1,logotransparency)
    love.graphics.print(percentText, displayx/10*8.5+100, displayy/10*9-40, 0, 1, 1, percentHalfWidth, lodingfont:getHeight()/2)
    love.graphics.rectangle("line",displayx/10*8.5, displayy/10*9, 200, 20)
    love.graphics.setFont(verfont)
    love.graphics.rectangle("fill",displayx/10*8.5, displayy/10*9, endsaccess*2, 20)
    love.graphics.print(i18n.t("appVersion")..appversion,10,displayy/10*9)
end










return openingloader
