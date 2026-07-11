



local settings = {}

local log = require("log")
local gamejolt = require("gamejolt")
local JSON = require("JSON")
local ui = require("lib.ui")

local displayWidth, displayHeight = love.graphics.getDimensions()

local function isCloudoampUser()
    return gamejolt.status and gamejolt.status.authenticated and gamejolt.status.username == "cloudoamp"
end

local categoryColors = {
    {0.5, 0.5, 0.5},
    {0.5, 0.5, 0.5},
    {0.5, 0.5, 0.5},
    {0.5, 0.5, 0.5},
    {0.5, 0.5, 0.5}
}

local linkdata = {
    shiftline = "https://shiftline.gt.tc",
    gamepage = "https://gamejolt.com/games/shiftline/1053992",
    twitter = "https://x.com/shiftline_offi"
}

--繧ｻ繝ｬ繧ｯ繝医＆繧後◆繧､繝ｳ繝・ャ繧ｯ繧ｹ
--[[
1:繝・ぅ繧ｹ繝励Ξ繧､
2:繧ｪ繝ｼ繝・ぅ繧ｪ
3:縺昴・莉・
4:繝励Ξ繧､險ｭ螳・
5:繝ｪ繝ｳ繧ｯ]]
selectedIndex = 1
selectedFieldIndex = 1

local categories = {"display", "audio", "misc", "play", "links", "keys"}

local settingFields = {
    {"displaySize", "displayMode", "vsync"},
    {"masterVolume", "musicVolume", "sfxVolume"},
    {"language", "timeout", "defaultLevel"},
    {"moveSpeed", "timing", "playLogSave", "showFPS"},
    {"website", "gamepage", "twitter"},
    {"moveup", "movedown", "moveleft", "moveright", "leftone", "lefttwo", "lefttree", "rightone", "righttwo", "righttree", "pause"}
}

local displayResolutions = {
    {800, 600},
    {1024, 768},
    {1280, 720},
    {1600, 900},
    {1920, 1080}
}

local localeTexts = {
    jp = {
        title = "設定",
        categories = {"画面設定", "音声設定", "情報設定", "プレイ設定", "サイトリンク", "キーコンフィグ"},
        displaySize = "画面サイズ",
        displayMode = "画面モード",
        vsync = "垂直同期",
        fullscreen = "フルスクリーン",
        windowed = "ウィンドウ",
        masterVolume = "全体音量",
        musicVolume = "BGM音量",
        sfxVolume = "SFX音量",
        language = "言語",
        timeout = "タイムアウト",
        defaultLevel = "デフォルトレベル",
        moveSpeed = "移動速度",
        timing = "タイミング",
        playLogSave = "ログ設定",
        showFPS = "FPS表示",
        website = "ウェブサイト",
        gamepage = "ダウンロードサイト",
        twitter = "X(Twitter)",
        moveup = "レーン・上",
        movedown = "レーン・下",
        moveleft = "レーン・左",
        moveright = "レーン・右",
        leftone = "左1",
        lefttwo = "左2",
        lefttree = "左3",
        rightone = "右1",
        righttwo = "右2",
        righttree = "右3",
        pause = "一時停止",
        helpText = "選択: Enter/上下/左右, 調整: ホイール, 保存: Enter/クリック",
        openLinkHelp = "リンクを開く",
        keyConfigHelp = "Enterを押してからキーを押す",
        booleanOn = "ON",
        booleanOff = "OFF",
        languageName = {jp = "日本語", en = "English"},
        levelName = {easy = "easy", normal = "normal", hard = "hard", extra = "extra"}
    },
    en = {
        title = "Settings",
        categories = {"Display", "Audio", "Misc", "Play", "Links", "Keys"},
        displaySize = "Display Size",
        displayMode = "Display Mode",
        vsync = "VSync",
        fullscreen = "Fullscreen",
        windowed = "Windowed",
        masterVolume = "Master Volume",
        musicVolume = "Music Volume",
        sfxVolume = "SFX Volume",
        language = "Language",
        timeout = "Timeout",
        defaultLevel = "Default Level",
        moveSpeed = "Move Speed",
        timing = "Timing",
        playLogSave = "Play Log Save",
        showFPS = "Show FPS",
        website = "Website",
        gamepage = "Gamepage",
        twitter = "Twitter",
        moveup = "Move Up",
        movedown = "Move Down",
        moveleft = "Move Left",
        moveright = "Move Right",
        leftone = "Left 1",
        lefttwo = "Left 2",
        lefttree = "Left 3",
        rightone = "Right 1",
        righttwo = "Right 2",
        righttree = "Right 3",
        pause = "Pause",
        helpText = "Click/UpDown/LeftRight to select, wheel to adjust, Enter/click to save",
        openLinkHelp = "Click to open link",
        keyConfigHelp = "Press Enter then press a key to assign",
        booleanOn = "On",
        booleanOff = "Off",
        languageName = {jp = "日本語", en = "English"},
        levelName = {easy = "Easy", normal = "Normal", hard = "Hard", extra = "Extra"}
    }
}

local keybindTarget = nil

local function clamp(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
end

local function setKeyBinding(field, key)
    if not field or not settingsdata.keysettings then
        return
    end
    settingsdata.keysettings[field] = key
    keybindTarget = nil
    settings.save()
end

local layout = {
    leftWidth = 320,
    rightX = 360,
    lineHeight = 60,
    spacing = 18,
    padding = 28
}
local slope = -0.02

local function updateLayout()
    displayWidth, displayHeight = love.graphics.getDimensions()
    layout.padding = math.max(displayWidth * 0.03, 16)
    layout.leftWidth = displayWidth * 0.24
    layout.rightX = layout.leftWidth + layout.padding
    layout.lineHeight = math.max(displayHeight * 0.075, 40)
    layout.spacing = math.max(displayHeight * 0.028, 10)
    layout.panelY = layout.padding + displayHeight * 0.05
    layout.panelH = displayHeight - layout.panelY - layout.padding
    slope = -(displayWidth / 20) / (displayHeight * 0.9)
end

local function refreshFonts()
    local titleSize = math.max(48, math.floor(displayHeight * 0.085))
    local subtitleSize = math.max(34, math.floor(displayHeight * 0.055))
    local bodySize = math.max(24, math.floor(displayHeight * 0.038))
    Titlefont = love.graphics.newFont("lib/data/fonts/NotoSansJP-Light.ttf", titleSize)
    Subtitlefont = love.graphics.newFont("lib/data/fonts/NotoSansJP-Light.ttf", subtitleSize)
    font = love.graphics.newFont("lib/data/fonts/NotoSansJP-Light.ttf", bodySize)
end

local function getLocaleText(key)
    local lang = settingsdata and settingsdata.miscsettings and settingsdata.miscsettings.language or "jp"
    local locale = localeTexts[lang] or localeTexts.jp
    return locale[key] or key
end

local function getBooleanText(value)
    if value then
        return getLocaleText("booleanOn")
    end
    return getLocaleText("booleanOff")
end

local function getDefaultLevelText(value)
    local lang = settingsdata and settingsdata.miscsettings and settingsdata.miscsettings.language or "jp"
    local locale = localeTexts[lang] or localeTexts.jp
    return locale.levelName[value] or value
end

local function findResolutionIndex(size)
    for i, res in ipairs(displayResolutions) do
        if size[1] == res[1] and size[2] == res[2] then
            return i
        end
    end
    return 1
end

local function getCurrentFieldCount()
    return #settingFields[selectedIndex]
end

local function drawMenuItem(y, label, isSelected)
    love.graphics.setColor(isSelected and {1, 0.9, 0.4} or {1, 1, 1})
    love.graphics.print(label, 40, y)
end

local function drawSettingLine(y, label, value, isSelected)
    love.graphics.setColor(isSelected and {1, 0.9, 0.4} or {1, 1, 1})
    love.graphics.print(label .. ": " .. tostring(value), displayWidth/2, y)
end

local function getSettingValue(key)
    if key == "displaySize" then
        local size = settingsdata.displaysettings.displaysize
        return tostring(size[1]) .. "x" .. tostring(size[2])
    elseif key == "displayMode" then
        return getLocaleText(settingsdata.displaysettings.displaymode)
    elseif key == "vsync" then
        return getBooleanText(settingsdata.displaysettings.vsync)
    elseif key == "masterVolume" then
        return string.format("%.1f", settingsdata.audiosettings.mastervolume)
    elseif key == "musicVolume" then
        return string.format("%.1f", settingsdata.audiosettings.musicvolume)
    elseif key == "sfxVolume" then
        return string.format("%.1f", settingsdata.audiosettings.sfxvolume)
    elseif key == "language" then
        local lang = settingsdata.miscsettings.language or "jp"
        return getLocaleText("languageName")[lang]
    elseif key == "timeout" then
        return tostring(settingsdata.miscsettings.timeout)
    elseif key == "defaultLevel" then
        return getDefaultLevelText(settingsdata.miscsettings.defoltlevel)
    elseif key == "moveSpeed" then
        return string.format("%.1f", settingsdata.playsettings.movespead)
    elseif key == "timing" then
        return tostring(settingsdata.playsettings.timing)
    elseif key == "playLogSave" then
        return getBooleanText(settingsdata.playsettings.playlogsave)
    elseif key == "showFPS" then
        return getBooleanText(settingsdata.playsettings.showfps)
    elseif key == "website" then
        return linkdata.shiftline
    elseif key == "gamepage" then
        return linkdata.gamepage
    elseif key == "twitter" then
        return linkdata.twitter
    elseif key == "moveup" or key == "movedown" or key == "moveleft" or key == "moveright" or key == "leftone" or key == "lefttwo" or key == "lefttree" or key == "rightone" or key == "righttwo" or key == "righttree" or key == "pause" then
        return settingsdata.keysettings[key]
    end
    return ""
end

local function adjustCurrentSetting(amount)
    if selectedIndex == 1 then
        if selectedFieldIndex == 1 then
            local current = findResolutionIndex(settingsdata.displaysettings.displaysize)
            current = clamp(current + amount, 1, #displayResolutions)
            settingsdata.displaysettings.displaysize = {displayResolutions[current][1], displayResolutions[current][2]}
        elseif selectedFieldIndex == 2 then
            local modes = {"fullscreen", "windowed"}
            local current = 1
            for i, v in ipairs(modes) do
                if v == settingsdata.displaysettings.displaymode then
                    current = i
                    break
                end
            end
            current = clamp(current + amount, 1, #modes)
            settingsdata.displaysettings.displaymode = modes[current]
        elseif selectedFieldIndex == 3 then
            settingsdata.displaysettings.vsync = not settingsdata.displaysettings.vsync
        end
        settings.applyDisplaySettings()
    elseif selectedIndex == 2 then
        if selectedFieldIndex == 1 then
            settingsdata.audiosettings.mastervolume = clamp(settingsdata.audiosettings.mastervolume + amount * 0.1, 0.0, 1.0)
        elseif selectedFieldIndex == 2 then
            settingsdata.audiosettings.musicvolume = clamp(settingsdata.audiosettings.musicvolume + amount * 0.1, 0.0, 1.0)
        elseif selectedFieldIndex == 3 then
            settingsdata.audiosettings.sfxvolume = clamp(settingsdata.audiosettings.sfxvolume + amount * 0.1, 0.0, 1.0)
        end
        settings.applyAudioSettings()
    elseif selectedIndex == 3 then
        if selectedFieldIndex == 1 then
            local languages = {"jp", "en"}
            local current = 1
            for i, v in ipairs(languages) do
                if v == settingsdata.miscsettings.language then
                    current = i
                    break
                end
            end
            current = clamp(current + amount, 1, #languages)
            settingsdata.miscsettings.language = languages[current]
        elseif selectedFieldIndex == 2 then
            settingsdata.miscsettings.timeout = clamp(settingsdata.miscsettings.timeout + amount * 5, 5, 120)
        elseif selectedFieldIndex == 3 then
            local levels = {"easy", "normal", "hard", "extra"}
            local current = 1
            for i, v in ipairs(levels) do
                if v == settingsdata.miscsettings.defoltlevel then
                    current = i
                    break
                end
            end
            current = clamp(current + amount, 1, #levels)
            settingsdata.miscsettings.defoltlevel = levels[current]
        end
    elseif selectedIndex == 4 then
        if selectedFieldIndex == 1 then
            settingsdata.playsettings.movespead = clamp(settingsdata.playsettings.movespead + amount * 0.1, 0.5, 2.0)
        elseif selectedFieldIndex == 2 then
            settingsdata.playsettings.timing = clamp(settingsdata.playsettings.timing + amount, -100, 100)
        elseif selectedFieldIndex == 3 then
            settingsdata.playsettings.playlogsave = not settingsdata.playsettings.playlogsave
        elseif selectedFieldIndex == 4 then
            settingsdata.playsettings.showfps = not settingsdata.playsettings.showfps
        end
    elseif selectedIndex == 6 then
        -- Key bindings are changed by pressing Enter and then selecting a new key.
    end

    settings.save()
end

--蛻晄悄蛟､
settingsdata={
    displaysettings={
    displaysize = {displayWidth, displayHeight},
    displaymode = "fullscreen",
    vsync = true,
    },


    audiosettings={
        mastervolume = 1.0,
        musicvolume = 1.0,
        sfxvolume = 1.0,
        EQsettings = {
            bass = 1,
            mid = 1,
            treble = 1
        },
    },

    keysettings={
        moveup = "w",
        movedown = "s",
        moveleft = "a",
        moveright = "d",
        leftone = "z",
        lefttwo = "x",
        lefttree = "c",
        rightone = "num3",
        righttwo = "num2",
        righttree = "num1",
        pause = "escape"

    },

    miscsettings={
        language = "jp",
        timeout = 30,
        defoltlevel = "extra"
    },
    playsettings={
        movespead = 1.0,
        timing=0,
        playlogsave = true,
        showfps = false,
    },
    stats={
        bestRating = 0,
        lastRating = 0,
        ratingAverage = 0,
        ratingHistory = {}
    }
}

function settings.applyDisplaySettings()
    if love.window then
        local width = tonumber(settingsdata.displaysettings.displaysize[1])
        local height = tonumber(settingsdata.displaysettings.displaysize[2])
        local fullscreen = settingsdata.displaysettings.displaymode == "fullscreen"
        if not width or width <= 0 or not height or height <= 0 then
            width, height = love.graphics.getDimensions()
        end
        love.window.setMode(width, height, {
            fullscreen = fullscreen,
            fullscreentype = "desktop",
            vsync = settingsdata.displaysettings.vsync == true
        })
        displayWidth, displayHeight = love.graphics.getDimensions()
    end
    -- レイアウト・フォントを即時更新
    updateLayout()
    refreshFonts()

    -- 他モジュールのフォント更新が可能なら呼び出す
    pcall(function()
        local ok, ms = pcall(require, "musicselect")
        if ok and ms and type(ms.refreshMusicselectFonts) == "function" then
            ms.refreshMusicselectFonts()
        end
    end)
end

function settings.applyAudioSettings()
    if love.audio then
        love.audio.setVolume(settingsdata.audiosettings.mastervolume)
    end
end

function settings.applySettings()
    settings.applyDisplaySettings()
    settings.applyAudioSettings()
end

function settings.openLink()
    local field = settingFields[5][selectedFieldIndex]
    local url = getSettingValue(field)
    if type(url) == "string" and url ~= "" and love.system and love.system.openURL then
        love.system.openURL(url)
    end
end

function settings.load()

    if love.filesystem.getInfo("settings.json") then

        local contents = love.filesystem.read("settings.json")

        local decoded = JSON:decode(contents)

        if decoded then
            settingsdata = decoded
        end

    else

        settings.save() -- 蛻晄悄險ｭ螳壹ｒ菫晏ｭ・

    end

    settings.applySettings()

    updateLayout()
    refreshFonts()

end

local function getFieldRowRect(index)
    local x = layout.rightX
    local statusH = layout.lineHeight * 2 + layout.spacing
    local y = layout.panelY + statusH + layout.spacing + (index - 1) * (layout.lineHeight + layout.spacing)
    local w = displayWidth - x - layout.padding
    local h = layout.lineHeight
    return x, y, w, h
end

local function isPointInRect(x, y, rx, ry, rw, rh)
    return x >= rx and y >= ry and x <= rx + rw and y <= ry + rh
end

local function getFieldIndexAtPosition(x, y)
    for i = 1, getCurrentFieldCount() do
        local rx, ry, rw, rh = getFieldRowRect(i)
        if isPointInRect(x, y, rx, ry, rw, rh) then
            return i
        end
    end
    return nil
end

local function adjustFieldAtPosition(x, y)
    local index = getFieldIndexAtPosition(x, y)
    if not index then
        return false
    end

    local rx, ry, rw, rh = getFieldRowRect(index)
    local arrowWidth = math.min(48, rw * 0.1)
    local leftArrowX = rx + rw - arrowWidth * 2 - 22
    local rightArrowX = rx + rw - arrowWidth - 14

    selectedFieldIndex = index

    if isPointInRect(x, y, leftArrowX, ry + 8, arrowWidth, rh - 16) then
        adjustCurrentSetting(-1)
        return true
    elseif isPointInRect(x, y, rightArrowX, ry + 8, arrowWidth, rh - 16) then
        adjustCurrentSetting(1)
        return true
    end

    return false
end

function settings.update(dt)
    for index = 1, 5 do
        local color = categoryColors[index]
        if index == selectedIndex then
            color[1], color[2], color[3] = 1.0, 1.0, 1.0
        else
            color[1], color[2], color[3] = 0.5, 0.5, 0.5
        end
    end
end


function settings.draw()
    updateLayout()
    love.graphics.setFont(Titlefont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(getLocaleText("title"), displayWidth/2 - Titlefont:getWidth(getLocaleText("title"))/2, layout.padding / 2)

    love.graphics.setFont(Subtitlefont)
    local panelY = layout.panelY
    local panelH = layout.panelH
    local panelW = layout.leftWidth - layout.padding / 2

    local panelPoly = ui.parallelogramPoly(layout.padding, layout.padding + panelW, panelY, panelY + panelH, slope)
    love.graphics.setColor(0.05, 0.05, 0.05, 0.98)
    love.graphics.polygon("fill", panelPoly)
    love.graphics.setColor(1,1,1,0.12)
    love.graphics.polygon("line", panelPoly)

    for i = 1, #categories do
        local bx = layout.padding + 16
        local by = panelY + (i - 1) * (layout.lineHeight + layout.spacing)
        local bw = panelW - 32
        local bh = layout.lineHeight
        local isSelected = i == selectedIndex
        local catPoly = ui.parallelogramPoly(bx, bx + bw, by, by + bh, slope)
        ui.drawParallelogram(catPoly, getLocaleText("categories")[i], Subtitlefont, {
            color = isSelected and {0.18,0.18,0.18,0.96} or {0.10,0.10,0.10,0.92},
            lineColor = isSelected and {1,1,1,0.24} or {1,1,1,0.08},
            textPadding = 20
        })
    end

    local statusX = layout.rightX
    local statusY = panelY
    local statusW = displayWidth - statusX - layout.padding
    local statusH = layout.lineHeight * 2 + layout.spacing
    local statusPoly = ui.parallelogramPoly(statusX, statusX + statusW, statusY, statusY + statusH, slope)
    love.graphics.setColor(0, 0, 0, 0.95)
    love.graphics.polygon("fill", statusPoly)
    love.graphics.setColor(1,1,1,0.16)
    love.graphics.polygon("line", statusPoly)
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1, 0.94)
    love.graphics.print(getLocaleText("categories")[selectedIndex] .. "アイテム数: " .. getCurrentFieldCount() .. " items", statusX + 20, statusY + 18)
    love.graphics.setColor(1, 1, 1, 0.8)
    local statusHelp = selectedIndex == 6 and getLocaleText("keyConfigHelp") or getLocaleText("helpText")
    love.graphics.print(statusHelp, statusX + 20, statusY + 20 + Subtitlefont:getHeight())

    love.graphics.setFont(font)
    local maxFieldY = layout.panelY + layout.panelH - layout.padding
    local visibleItemCount = 0
    
    for i, _ in ipairs(settingFields[selectedIndex]) do
        local rx, ry, rw, rh = getFieldRowRect(i)
        if ry + rh <= maxFieldY then
            visibleItemCount = i
        else
            break
        end
    end
    
    if selectedFieldIndex > visibleItemCount then
        selectedFieldIndex = math.max(1, visibleItemCount)
    end
    
    for i, field in ipairs(settingFields[selectedIndex]) do
        local rx, ry, rw, rh = getFieldRowRect(i)
        
        if ry + rh > maxFieldY then
            break
        end
        
        local isSelected = selectedFieldIndex == i
        local fieldPoly = ui.parallelogramPoly(rx, rx + rw, ry, ry + rh, slope)
        love.graphics.setColor(isSelected and {0.18, 0.18, 0.18, 0.96} or {0.08, 0.08, 0.08, 0.92})
        love.graphics.polygon("fill", fieldPoly)
        love.graphics.setColor(1,1,1,0.08)
        love.graphics.polygon("line", fieldPoly)

        love.graphics.setColor(1, 1, 1, 0.94)
        love.graphics.print(getLocaleText(field), rx + 18, ry + rh * 0.18)

        local valueText = tostring(getSettingValue(field))
        local maxValueW = rw * 0.3
        local vScale = 1
        if font:getWidth(valueText) > maxValueW then
            vScale = maxValueW / font:getWidth(valueText)
        end
        love.graphics.setColor(1, 1, 1, 0.82)
        love.graphics.push()
        love.graphics.translate(rx + rw - 140, ry + rh * 0.18)
        love.graphics.scale(vScale, vScale)
        love.graphics.printf(valueText, -font:getWidth(valueText), 0, font:getWidth(valueText), "left")
        love.graphics.pop()

        if selectedIndex ~= 5 and selectedIndex ~= 6 then
            local arrowW = math.min(48, rw * 0.1)
            local arrowH = rh - 24
            local leftArrowX = rx + rw - arrowW * 2 - 22
            local rightArrowX = rx + rw - arrowW - 14
            local leftPoly = ui.parallelogramPoly(leftArrowX, leftArrowX + arrowW, ry + 12, ry + 12 + arrowH, slope)
            local rightPoly = ui.parallelogramPoly(rightArrowX, rightArrowX + arrowW, ry + 12, ry + 12 + arrowH, slope)
            love.graphics.setColor(1, 1, 1, 0.08)
            love.graphics.polygon("fill", leftPoly)
            love.graphics.polygon("fill", rightPoly)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf("<", leftArrowX, ry + 18, arrowW, "center")
            love.graphics.printf(">", rightArrowX, ry + 18, arrowW, "center")
        elseif selectedIndex == 5 then
            love.graphics.setColor(1, 1, 1, 0.9)
            love.graphics.printf(getLocaleText("openLinkHelp"), rx + 18, ry + rh * 0.45, rw - 36, "left")
        elseif selectedIndex == 6 then
            love.graphics.setColor(1, 1, 1, 0.9)
            love.graphics.printf(getLocaleText("keyConfigHelp"), rx + 18, ry + rh * 0.45, rw - 36, "left")
        end
    end

    love.graphics.setColor(1, 1, 1, 0.78)
    love.graphics.print(getLocaleText("helpText"), layout.rightX, displayHeight - font:getHeight() * 2)
end


local function getCategoryRect(index)
    local x = layout.padding + 16
    local y = layout.panelY + (index - 1) * (layout.lineHeight + layout.spacing)
    local w = layout.leftWidth - layout.padding - 32
    local h = layout.lineHeight
    return x, y, w, h
end

function settings.mousepressed(x, y, button)
    if button ~= 1 then
        return
    end

    for i = 1, #categories do
        local rx, ry, rw, rh = getCategoryRect(i)
        if isPointInRect(x, y, rx, ry, rw, rh) then
            selectedIndex = i
            selectedFieldIndex = 1
            return
        end
    end

    if adjustFieldAtPosition(x, y) then
        return
    end

    if selectedIndex == 5 then
        local index = getFieldIndexAtPosition(x, y)
        if index then
            selectedFieldIndex = index
            settings.openLink()
        end
    end
end

function settings.wheelmoved(x, y)
    local mx, my = love.mouse.getPosition()
    local index = getFieldIndexAtPosition(mx, my)
    if not index then
        return
    end
    if selectedIndex == 5 or selectedIndex == 6 then
        return
    end
    selectedFieldIndex = index
    adjustCurrentSetting(y > 0 and 1 or -1)
end


function settings.save()

    local jsonText = JSON:encode_pretty(settingsdata)

    local success, message = love.filesystem.write("settings.json", jsonText)

    if success then
        print("settings.json saved!")
        if gamejolt and type(gamejolt.saveSettings) == "function" and gamejolt.status and gamejolt.status.authenticated then
            local ok, response = pcall(gamejolt.saveSettings, gamejolt, settingsdata)
            if ok and response and response.success == "true" then
                log.info("GameJolt settings synced")
            else
                log.warn("GameJolt settings sync failed: " .. tostring(response and response.message or response or "unknown"))
            end
        end
    else
        print("save error: " .. tostring(message))
    end
end

function settings.displaydraw()
    love.graphics.setFont(font)
    local y = displayHeight/5 - font:getHeight() * 1.5
    drawSettingLine(y, "Display Size", settingsdata.displaysettings.displaysize[1] .. "x" .. settingsdata.displaysettings.displaysize[2], selectedFieldIndex == 1)
    drawSettingLine(y + 50, "Display Mode", settingsdata.displaysettings.displaymode, selectedFieldIndex == 2)
    drawSettingLine(y + 100, "VSync", tostring(settingsdata.displaysettings.vsync), selectedFieldIndex == 3)
end

function settings.audiodraw()
    love.graphics.setFont(font)
    local y = displayHeight/5 - font:getHeight() * 1.5
    drawSettingLine(y, "Master Volume", string.format("%.1f", settingsdata.audiosettings.mastervolume), selectedFieldIndex == 1)
    drawSettingLine(y + 50, "Music Volume", string.format("%.1f", settingsdata.audiosettings.musicvolume), selectedFieldIndex == 2)
    drawSettingLine(y + 100, "SFX Volume", string.format("%.1f", settingsdata.audiosettings.sfxvolume), selectedFieldIndex == 3)
end

function settings.miscdraw()
    love.graphics.setFont(font)
    local y = displayHeight/5 - font:getHeight() * 1.5
    drawSettingLine(y, "Language", settingsdata.miscsettings.language, selectedFieldIndex == 1)
    drawSettingLine(y + 50, "Timeout", tostring(settingsdata.miscsettings.timeout), selectedFieldIndex == 2)
    drawSettingLine(y + 100, "Default Level", settingsdata.miscsettings.defoltlevel, selectedFieldIndex == 3)
end

function settings.playdraw()
    love.graphics.setFont(font)
    local y = displayHeight/5 - font:getHeight() * 1.5
    drawSettingLine(y, "Move Speed", string.format("%.1f", settingsdata.playsettings.movespead), selectedFieldIndex == 1)
    drawSettingLine(y + 50, "Timing", tostring(settingsdata.playsettings.timing), selectedFieldIndex == 2)
    drawSettingLine(y + 100, "Play Log Save", tostring(settingsdata.playsettings.playlogsave), selectedFieldIndex == 3)
end

function settings.openMenu()
    if not isCloudoampUser() then
        log.warn("Settings access denied: GameJolt login required as cloudoamp")
        return
    end

    settings.previousProgram = programnumber
    selectedIndex = 1
    selectedFieldIndex = 1
    changeProgram(5)
end

function settings.keypressed(key, scancode, isrepeat)
    if key == "escape" then
        if keybindTarget then
            keybindTarget = nil
            return
        end
        if settings.previousProgram and settings.previousProgram ~= 5 then
            changeProgram(settings.previousProgram)
        else
            changeProgram(2)
        end
        return
    end

    if keybindTarget then
        if key ~= "escape" and key ~= "return" and key ~= "kpenter" and key ~= "tab" then
            setKeyBinding(keybindTarget, key)
        end
        return
    end

    if key == "up" or key == "w" or key == "kpup" then
        selectedIndex = math.max(1, selectedIndex - 1)
        selectedFieldIndex = 1
        return
    end

    if key == "down" or key == "s" or key == "kpdown" then
        selectedIndex = math.min(#categories, selectedIndex + 1)
        selectedFieldIndex = 1
        return
    end

    if key == "tab" then
        selectedFieldIndex = selectedFieldIndex % getCurrentFieldCount() + 1
        return
    end

    if key == "left" or key == "kpleft" then
        if selectedIndex ~= 5 and selectedIndex ~= 6 then
            adjustCurrentSetting(-1)
        end
        return
    end

    if key == "right" or key == "kpright" then
        if selectedIndex ~= 5 and selectedIndex ~= 6 then
            adjustCurrentSetting(1)
        end
        return
    end

    local numericIndex = tonumber(key)
    if numericIndex and numericIndex >= 1 and numericIndex <= #categories then
        selectedIndex = numericIndex
        selectedFieldIndex = 1
        return
    end

    if key == "return" or key == "kpenter" then
        if selectedIndex == 5 then
            settings.openLink()
        elseif selectedIndex == 6 then
            keybindTarget = settingFields[selectedIndex][selectedFieldIndex]
        else
            settings.save()
        end
        return
    end
end

return settings

