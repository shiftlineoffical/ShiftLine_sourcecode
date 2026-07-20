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

local opening = {}

local displayWidth, displayHeight = love.graphics.getDimensions()
local gamejolt = require "gamejolt"
local gamejoltuser = require "gamejoltuser"
local i18n = require "i18n"
local utf8 = require("utf8")
local ui = require("lib.ui")
local okHttp, http = pcall(require, "socket.http")
if not okHttp then http = nil end

local button = {}
local exitButton = {}
local buttonchack = false

local usernametext = ""
local tokentext = ""

local fadeOut = false
local fadeAlpha = 0
local fadeDuration = 0.6 -- seconds to fade out

local autologinChecked = false
local focusedField = nil -- "userid" | "token" | nil
local statusText = ""
local statusIsError = false

local fead = 0
local time = 0

local caretTimer = 0
local caretOn = true

local BACKSPACE_REPEAT_DELAY = 0.4
local BACKSPACE_REPEAT_INTERVAL = 0.05
local backspaceWasDown = false
local backspaceHoldTime = 0
local backspaceRepeatTimer = 0
local cachedUiRects = nil
local cachedTokenMaskSource = nil
local cachedTokenMaskValue = ""
local openingLogoScale = 0.7
local gamejoltLogoScale = 1.0
local exitButtonPaddingX = 16
local exitButtonPaddingY = 10
local clickfont = nil









local function updateDisplaySize()
    local w, h = love.graphics.getDimensions()
    if w ~= displayWidth or h ~= displayHeight then
        displayWidth, displayHeight = w, h
        cachedUiRects = nil
        return true
    end
    return false
end








local function updateOpeningLayout()
    local baseFontSize = math_max(18, math_floor(displayHeight * 0.035))
    local exitFontSize = math_max(18, math_floor(displayHeight * 0.04))
    local clickFontSize = math_max(16, math_floor(displayHeight * 0.025))

    -- Safe font creation: fall back to current default font on failure
    local ok1, f1 = pcall(function() return love.graphics.newFont("lib/data/fonts/NotoSansJP-ExtraLight.ttf", baseFontSize) end)
    if ok1 and f1 then loginfont = f1 else loginfont = love.graphics.getFont() end
    local ok2, f2 = pcall(function() return love.graphics.newFont("lib/data/fonts/NotoSansJP-ExtraLight.ttf", exitFontSize) end)
    if ok2 and f2 then exitfont = f2 else exitfont = love.graphics.getFont() end
    local ok3, f3 = pcall(function() return love.graphics.newFont("lib/data/fonts/NotoSansJP-ExtraLight.ttf", clickFontSize) end)
    if ok3 and f3 then clickfont = f3 else clickfont = love.graphics.getFont() end

    exitButtonPaddingX = math_max(10, math_floor(exitFontSize * 0.45))
    exitButtonPaddingY = math_max(6, math_floor(exitFontSize * 0.35))

    if logoimg then
        local mainLogoMaxW = displayWidth * 0.45
        local mainLogoMaxH = displayHeight * 0.34
        openingLogoScale = ui.scaleToFit(logoimg, mainLogoMaxW, mainLogoMaxH)
    end

    if gamejoltlogoimg then
        local smallMaxW = displayWidth * 0.12
        local smallMaxH = displayHeight * 0.12
        gamejoltLogoScale = ui.scaleToFit(gamejoltlogoimg, smallMaxW, smallMaxH)
        button.w = gamejoltlogoimg:getWidth() * gamejoltLogoScale
        button.h = gamejoltlogoimg:getHeight() * gamejoltLogoScale
    end
end

local function pointInRect(px, py, r)
    if type(r) ~= "table" then return false end

    local rx = r.x or r.left or 0
    local ry = r.y or r.top or 0
    local rw = r.w or r.width or r.size or 0
    local rh = r.h or r.height or r.size or 0

    return px >= rx and px <= (rx + rw) and py >= ry and py <= (ry + rh)
end

















local function getLoginUiRects()
    if cachedUiRects then
        return cachedUiRects.panel, cachedUiRects.userBox, cachedUiRects.tokenBox, cachedUiRects.checkbox, cachedUiRects.loginBtn
    end

    local panel = {
        x = displayWidth / 10 * 3,
        y = displayHeight / 10,
        w = displayWidth / 10 * 4,
        h = displayHeight / 10 * 8,
    }

    local inputX = displayWidth / 10 * 4
    local inputW = displayWidth / 10 * 2
    local inputH = displayHeight / 20

    local userBox = { x = inputX, y = displayHeight / 10 * 2, w = inputW, h = inputH }
    local tokenBox = { x = inputX, y = displayHeight / 10 * 3, w = inputW, h = inputH }

    local checkboxSize = math_floor(inputH * 0.7 + 0.5)
    local checkboxY = displayHeight / 10 * 4 + math_floor((inputH - checkboxSize) / 2 + 0.5)
    local checkbox = { x = inputX, y = checkboxY, size = checkboxSize }

    local loginBtn = { x = inputX, y = displayHeight / 10 * 5, w = inputW, h = inputH }

    cachedUiRects = {
        panel = panel,
        userBox = userBox,
        tokenBox = tokenBox,
        checkbox = checkbox,
        loginBtn = loginBtn
    }

    return panel, userBox, tokenBox, checkbox, loginBtn
end















local function setTextInputRectForFocus()
    if not buttonchack or focusedField == nil then
        love.keyboard.setTextInput(false)
        return
    end

    local _, userBox, tokenBox = getLoginUiRects()
    if focusedField == "userid" then
        love.keyboard.setTextInput(true, userBox.x, userBox.y, userBox.w, userBox.h)
    elseif focusedField == "token" then
        love.keyboard.setTextInput(true, tokenBox.x, tokenBox.y, tokenBox.w, tokenBox.h)
    else
        love.keyboard.setTextInput(true)
    end
end














local function setLoginUiOpen(open)
    if buttonchack == open then return end

    buttonchack = open
    fead = 0
    caretTimer = 0
    caretOn = true
    statusText = ""
    statusIsError = false

    if open then
        if focusedField == nil then
            if usernametext == "" then
                focusedField = "userid"
            elseif tokentext == "" then
                focusedField = "token"
            else
                focusedField = "userid"
            end
        end
        setTextInputRectForFocus()
    else
        focusedField = nil
        love.keyboard.setTextInput(false)
    end
end















local function backspaceUtf8(s)
    if s == "" then return "" end
    local byteoffset = utf8.offset(s, -1)
    if not byteoffset then return "" end
    return string.sub(s, 1, byteoffset - 1)
end













local function fitTextEnd(text, maxWidth, font)
    if maxWidth <= 0 then return "" end
    if font:getWidth(text) <= maxWidth then return text end

    local len = utf8.len(text)
    if not len or len <= 0 then
        for start = 1, #text do
            local candidate = text:sub(start)
            if font:getWidth(candidate) <= maxWidth then
                return candidate
            end
        end
        return ""
    end

    local lo, hi = 1, len
    local best = ""
    while lo <= hi do
        local mid = math_floor((lo + hi) / 2)
        local byteIndex = utf8.offset(text, mid)
        if not byteIndex then break end

        local candidate = text:sub(byteIndex)
        if font:getWidth(candidate) <= maxWidth then
            best = candidate
            hi = mid - 1
        else
            lo = mid + 1
        end
    end

    return best
end









local function getUrlExtension(url)
    if type(url) ~= "string" then return nil end
    local clean = url:gsub("#.*$", ""):gsub("%?.*$", "")
    local ext = clean:match("%.([%w]+)$")
    if not ext then return nil end
    ext = ext:lower()
    if ext == "png" or ext == "jpg" or ext == "jpeg" then
        return ext
    end
    return nil
end











local function fetchAvatarImage(url)
    if type(url) ~= "string" or url == "" then return nil end
    if not http or not http.request then return nil end

    local body, code = http.request(url)
    if code ~= 200 and code ~= "200" then return nil end
    if type(body) ~= "string" or body == "" then return nil end

    local ext = getUrlExtension(url) or "png"
    local okFile, fileData = pcall(love.filesystem.newFileData, body, "gamejolt_avatar." .. ext)
    if not okFile or not fileData then return nil end

    local okImg, imgOrErr = pcall(love.graphics.newImage, fileData)
    if not okImg then return nil end

    return imgOrErr
end

opening.fetchAvatarImage = fetchAvatarImage











local function deleteOneCharFromFocusedField()
    if focusedField == "userid" then
        usernametext = backspaceUtf8(usernametext)
    elseif focusedField == "token" then
        tokentext = backspaceUtf8(tokentext)
    end
end









local function tryAppendToFocusedField(text)
    if not buttonchack then return end
    if focusedField == "userid" then
        usernametext = usernametext .. text
    elseif focusedField == "token" then
        tokentext = tokentext .. text
    end
end

local function pushLoginToMain(authenticatedOverride)
    if type(App) ~= "table" or type(App.setLogin) ~= "function" then return end

    local status = gamejolt.status or {}
    local authenticated = authenticatedOverride
    if authenticated == nil then
        authenticated = (status.authenticated == true)
    end

    App.setLogin({
        authenticated = authenticated,
        userid = usernametext or "",
        user_token = tokentext or "",
        username = status.username or "",
        userId = status.userId or "",
        avatarUrl = status.avatarUrl or "",
    })
end















local function attemptLogin()
    statusText = ""
    statusIsError = false

    if usernametext == "" or tokentext == "" then
        statusText = "UserID 縺ｨ Token 繧貞・蜉帙＠縺ｦ縺上□縺輔＞"
        statusIsError = true
        return
    end

    local ok, authenticatedOrErr = pcall(function()
        return gamejolt.login(usernametext, tokentext)
    end)

    if not ok then
        statusText = "繝ｭ繧ｰ繧､繝ｳ縺ｫ螟ｱ謨励＠縺ｾ縺励◆: " .. tostring(authenticatedOrErr)
        statusIsError = true
        return
    end

    if authenticatedOrErr then
        statusText = "繝ｭ繧ｰ繧､繝ｳ謌仙粥"
        statusIsError = false

        if autologinChecked then
            if gamejoltuser.save then pcall(gamejoltuser.save, usernametext, tokentext, true) end
        else
            if gamejoltuser.clear then pcall(gamejoltuser.clear) end
        end

        focusedField = nil
        setTextInputRectForFocus()
        pushLoginToMain(true)
    else
        statusText = "繝ｭ繧ｰ繧､繝ｳ螟ｱ謨・(UserID/Token 繧堤｢ｺ隱阪＠縺ｦ縺上□縺輔＞)"
        statusIsError = true
        pushLoginToMain(false)
    end
end












function opening.load()
    updateDisplaySize()
    cachedUiRects = nil

    opening.endprocess = false


    logoimg = love.graphics.newImage("img/logo.png")
    -- Safe image loading
    local okLogo, logoImgOrErr = pcall(function()
        if love.filesystem and love.filesystem.getInfo and not love.filesystem.getInfo("img/logo.png") then return nil end
        return love.graphics.newImage("img/logo.png")
    end)
    if okLogo and logoImgOrErr then logoimg = logoImgOrErr end

    local okGJ, gjImgOrErr = pcall(function()
        if love.filesystem and love.filesystem.getInfo and not love.filesystem.getInfo("img/gamejoltlogo.png") then return nil end
        return love.graphics.newImage("img/gamejoltlogo.png")
    end)
    if okGJ and gjImgOrErr then gamejoltlogoimg = gjImgOrErr end

    updateOpeningLayout()

    ---@diagnostic disable: undefined-field
    ---@diagnostic disable-next-line: undefined-field
    ---@diagnostic disable: undefined-field
    ---@diagnostic disable: undefined-field
    -- Safe video creation: check file and available API
    if love.filesystem and love.filesystem.getInfo and love.filesystem.getInfo("img/OP.ogv") then
        if type(love.graphics.newVideoStream) == "function" then
            local okv, vs = pcall(function() return love.graphics.newVideoStream("img/OP.ogv") end)
            if okv and vs then
                local okv2, vobj = pcall(function() return love.graphics.newVideo(vs) end)
                if okv2 and vobj then Video = vobj end
            end
        elseif type(love.graphics.newVideo) == "function" then
            local okv, vobj = pcall(function() return love.graphics.newVideo("img/OP.ogv") end)
            if okv and vobj then Video = vobj end
        end
    end
    ---@diagnostic enable: undefined-field
    ---@diagnostic enable: undefined-field
    ---@diagnostic enable: undefined-field

    if Video and type(Video.play) == "function" then
        pcall(function() Video:play() end)
    end

    usernametext = gamejoltuser.userid or ""
    tokentext = gamejoltuser.user_token or ""
    cachedTokenMaskSource = nil
    cachedTokenMaskValue = ""
    autologinChecked = (gamejoltuser.autologin == true)

    if gamejolt.status and gamejolt.status.authenticated then
        pushLoginToMain(true)
    end

    

    buttonchack = false
    focusedField = nil
    fead = 0
    fadeOut = false
    fadeAlpha = 0
    love.keyboard.setTextInput(false)
end














function opening.update(dt)
    local resized = updateDisplaySize()
    if resized then
        updateOpeningLayout()
        if buttonchack and focusedField ~= nil then
            setTextInputRectForFocus()
        end
    end
    time = dt

    local backspaceDown = buttonchack and focusedField ~= nil and love.keyboard.isDown("backspace")
    if backspaceDown then
        if not backspaceWasDown then
            backspaceHoldTime = 0
            backspaceRepeatTimer = 0
        else
            backspaceHoldTime = backspaceHoldTime + dt
            if backspaceHoldTime >= BACKSPACE_REPEAT_DELAY then
                backspaceRepeatTimer = backspaceRepeatTimer + dt
                local deletes = 0
                while backspaceRepeatTimer >= BACKSPACE_REPEAT_INTERVAL and deletes < 64 do
                    deleteOneCharFromFocusedField()
                    backspaceRepeatTimer = backspaceRepeatTimer - BACKSPACE_REPEAT_INTERVAL
                    deletes = deletes + 1
                end
            end
        end
    else
        backspaceHoldTime = 0
        backspaceRepeatTimer = 0
    end
    backspaceWasDown = backspaceDown

    caretTimer = caretTimer + dt
    if caretTimer >= 0.5 then
        caretTimer = caretTimer - 0.5
        caretOn = not caretOn
    end

    if fadeOut then
        fadeAlpha = math_min(fadeAlpha + dt / fadeDuration, 1)
        if fadeAlpha >= 1 then
            opening.endprocess = true
        end
    end

    button.x = displayWidth - button.w - displayWidth * 0.02
    button.y = displayHeight * 0.02

    if Video and type(Video.isPlaying) == "function" then
        local ok, playing = pcall(function() return Video:isPlaying() end)
        if not ok or not playing then
            pcall(function()
                if type(Video.rewind) == "function" then Video:rewind() end
                if type(Video.play) == "function" then Video:play() end
            end)
        end
    end
end









function opening.textinput(t)
    tryAppendToFocusedField(t)
end











function opening.keypressed(key)
    if not buttonchack then return end

    if key == "escape" then
        setLoginUiOpen(false)
        return
    end

    if key == "tab" then
        if focusedField == "userid" then
            focusedField = "token"
        else
            focusedField = "userid"
        end
        setTextInputRectForFocus()
        return
    end

    if key == "return" or key == "kpenter" then
        attemptLogin()
        return
    end

    local ctrl = love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")
    if ctrl and key == "v" then
        local clip = love.system.getClipboardText() or ""
        clip = clip:gsub("[\r\n]+", "")
        if clip ~= "" then tryAppendToFocusedField(clip) end
        return
    end

    if key == "backspace" then
        deleteOneCharFromFocusedField()
        return
    end
end











function opening.mousepressed(x, y, mouseButton, istouch, presses)
    if mouseButton ~= 1 then return end

    -- Exit button click
    if pointInRect(x, y, exitButton) then
        love.event.quit()
        return
    end

    -- Toggle login UI by clicking the GameJolt icon.
    if pointInRect(x, y, button) then
        setLoginUiOpen(not buttonchack)
        return
    end

    if not buttonchack then
        if not fadeOut then
            fadeOut = true
            fadeAlpha = 0
        end
        return
    end

    local panel, userBox, tokenBox, checkbox, loginBtn = getLoginUiRects()

    -- Click outside closes the modal.
    if not pointInRect(x, y, panel) then
        setLoginUiOpen(false)
        return
    end

    -- Focus fields / toggle checkbox / press login button.
    if pointInRect(x, y, userBox) then
        focusedField = "userid"
        setTextInputRectForFocus()
        return
    end

    if pointInRect(x, y, tokenBox) then
        focusedField = "token"
        setTextInputRectForFocus()
        return
    end

    if x >= checkbox.x and x <= checkbox.x + checkbox.size
        and y >= checkbox.y and y <= checkbox.y + checkbox.size then
        autologinChecked = not autologinChecked
        if not autologinChecked and gamejoltuser.clear then
            pcall(gamejoltuser.clear)
        end
        return
    end

    if pointInRect(x, y, loginBtn) then
        attemptLogin()
        return
    end
end










local function drawLoginUi()
    if not buttonchack then return end

    local panel, userBox, tokenBox, checkbox, loginBtn = getLoginUiRects()

    -- Fade in quickly when opened.
    fead = math_min(fead + time * 6, 1)
    local a = fead

    local font = love.graphics.getFont()
    local padding = 10

    -- Backdrop.
    love.graphics.setColor(0, 0, 0, 0.7 * a)
    love.graphics.rectangle("fill", panel.x, panel.y, panel.w, panel.h)

    -- Logo.
    love.graphics.setColor(1, 1, 1, a)
    local maxLogoW = panel.w * 0.6
    local maxLogoH = panel.h * 0.18
    local logoScale = ui.scaleToFit(gamejoltlogoimg, maxLogoW, maxLogoH)
    local logoW = gamejoltlogoimg:getWidth() * logoScale
    local logoX = panel.x + (panel.w - logoW) / 2
    local logoY = panel.y + padding
    love.graphics.draw(gamejoltlogoimg, logoX, logoY, 0, logoScale, logoScale)

    -- Inputs background.
    love.graphics.setColor(0, 0, 0, a)
    love.graphics.rectangle("fill", userBox.x, userBox.y, userBox.w, userBox.h)
    love.graphics.rectangle("fill", tokenBox.x, tokenBox.y, tokenBox.w, tokenBox.h)

    -- Input outlines (highlight focus).
    love.graphics.setColor(1, 1, 1, a)
    love.graphics.rectangle("line", userBox.x, userBox.y, userBox.w, userBox.h)
    love.graphics.rectangle("line", tokenBox.x, tokenBox.y, tokenBox.w, tokenBox.h)
    if focusedField == "userid" then
        love.graphics.setColor(0.3, 0.9, 0.4, a)
        love.graphics.rectangle("line", userBox.x - 2, userBox.y - 2, userBox.w + 4, userBox.h + 4)
    elseif focusedField == "token" then
        love.graphics.setColor(0.3, 0.9, 0.4, a)
        love.graphics.rectangle("line", tokenBox.x - 2, tokenBox.y - 2, tokenBox.w + 4, tokenBox.h + 4)
    end

    -- Placeholder / values.
    love.graphics.setColor(0.75, 0.75, 0.75, a)
    local textYAdjust = math_floor((userBox.h - font:getHeight()) / 2 + 0.5)
    local maxTextWidth = userBox.w - padding * 2
    local useridDisplay
    if usernametext ~= "" then
        useridDisplay = fitTextEnd(usernametext, maxTextWidth, font)
    else
        useridDisplay = "UserID"
    end
    local tokenDisplay
    if tokentext ~= "" then
        if cachedTokenMaskSource ~= tokentext then
            local len = utf8.len(tokentext) or #tokentext
            cachedTokenMaskSource = tokentext
            cachedTokenMaskValue = string.rep("*", len)
        end
        tokenDisplay = fitTextEnd(cachedTokenMaskValue, maxTextWidth, font)
    else
        cachedTokenMaskSource = nil
        cachedTokenMaskValue = ""
        tokenDisplay = "Token"
    end
    love.graphics.print(useridDisplay, userBox.x + padding, userBox.y + textYAdjust)
    love.graphics.print(tokenDisplay, tokenBox.x + padding, tokenBox.y + textYAdjust)

    -- Caret.
    if caretOn and focusedField ~= nil then
        local caretX, caretY
        if focusedField == "userid" then
            caretX = userBox.x + padding
            if usernametext ~= "" then
                caretX = caretX + font:getWidth(useridDisplay)
            end
            caretY = userBox.y + textYAdjust
        else
            caretX = tokenBox.x + padding
            if tokentext ~= "" then
                caretX = caretX + font:getWidth(tokenDisplay)
            end
            caretY = tokenBox.y + textYAdjust
        end
        love.graphics.setColor(0.9, 0.9, 0.9, a)
        love.graphics.print("|", caretX, caretY-4)
    end

    -- Checkbox.
    local checkboxX = checkbox.x
    local checkboxY = checkbox.y
    local checkboxSize = checkbox.size
    love.graphics.setColor(1, 1, 1, a)
    love.graphics.rectangle("line", checkboxX, checkboxY, checkboxSize, checkboxSize)
    if autologinChecked then
        love.graphics.line(
            checkboxX + 3, checkboxY + checkboxSize * 0.55,
            checkboxX + checkboxSize * 0.4, checkboxY + checkboxSize - 4
        )
        love.graphics.line(
            checkboxX + checkboxSize * 0.4, checkboxY + checkboxSize - 4,
            checkboxX + checkboxSize - 3, checkboxY + 4
        )
    end
    love.graphics.setFont(loginfont)
    love.graphics.print(i18n.t("autoLogin"), checkboxX + checkboxSize + padding, checkboxY)

    -- Login button.
    love.graphics.setColor(0.15, 0.15, 0.15, a)
    love.graphics.rectangle("fill", loginBtn.x, loginBtn.y, loginBtn.w, loginBtn.h)
    love.graphics.setColor(1, 1, 1, a)
    love.graphics.rectangle("line", loginBtn.x, loginBtn.y, loginBtn.w, loginBtn.h)
    local loginLabel = i18n.t("login")
    local loginLabelX = loginBtn.x + (loginBtn.w - font:getWidth(loginLabel)) / 2
    local loginLabelY = loginBtn.y + math_floor((loginBtn.h - font:getHeight()) / 2 + 0.5)
    love.graphics.print(loginLabel, loginLabelX, loginLabelY)

    -- Status text.
    if statusText ~= "" then
        if statusIsError then
            love.graphics.setColor(1, 0.4, 0.4, a)
        else
            love.graphics.setColor(0.4, 1, 0.6, a)
        end
        love.graphics.printf(statusText, panel.x + padding, loginBtn.y + loginBtn.h + padding, panel.w - padding * 2, "left")
    end

    love.graphics.setColor(1, 1, 1, 1)
end
















function opening.draw()
    love.graphics.setColor(1, 1, 1, 0.5)
    if Video then
        love.graphics.draw(Video, 0, 0, 0, displayWidth / Video:getWidth(), displayHeight / Video:getHeight())
    end
    love.graphics.setColor(1, 1, 1)

    if logoimg then
        local logoW = logoimg:getWidth() * openingLogoScale
        local logoH = logoimg:getHeight() * openingLogoScale
        local logoX = displayWidth / 2 - logoW / 2
        local logoY = displayHeight * 0.18 - logoH / 2
        love.graphics.draw(logoimg, logoX, logoY, 0, openingLogoScale, openingLogoScale)
    end

    love.graphics.setColor(1, 1, 1)

    if clickfont then
        love.graphics.setFont(clickfont)
        local clickText = i18n.t("clickToStart")
        local clickY = displayHeight - clickfont:getHeight() - math_max(20, math_floor(displayHeight * 0.025))
        love.graphics.print(clickText, displayWidth / 2 - clickfont:getWidth(clickText) / 2, clickY)
    else
        local defaultFont = love.graphics.getFont()
        love.graphics.setFont(defaultFont)
        local clickText = i18n.t("clickToStart")
        local clickY = displayHeight - defaultFont:getHeight() - math_max(20, math_floor(displayHeight * 0.025))
        love.graphics.print(clickText, displayWidth / 2 - defaultFont:getWidth(clickText) / 2, clickY)
    end

    -- Exit button (larger, interactive)
    love.graphics.setFont(exitfont)
    local exitText = i18n.t("exit")
    local exitW = exitfont:getWidth(exitText) + exitButtonPaddingX * 2
    local exitH = exitfont:getHeight() + exitButtonPaddingY * 2
    local exitX = displayWidth - exitW - displayWidth * 0.02
    local exitY = displayHeight - exitH - displayHeight * 0.02
    exitButton.x = exitX
    exitButton.y = exitY
    exitButton.w = exitW
    exitButton.h = exitH

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", exitX, exitY, exitW, exitH)
    love.graphics.print(exitText, exitX + exitButtonPaddingX, exitY + exitButtonPaddingY)

    love.graphics.setFont(loginfont)
    if gamejoltlogoimg then
        love.graphics.draw(gamejoltlogoimg, button.x, button.y, 0, gamejoltLogoScale, gamejoltLogoScale)
    end

    drawLoginUi()

end

function opening.drawOverlay()
    if fadeOut then
        love.graphics.setColor(0, 0, 0, fadeAlpha)
        love.graphics.rectangle("fill", 0, 0, displayWidth, displayHeight)
        love.graphics.setColor(1, 1, 1, 1)
    end
end

return opening


