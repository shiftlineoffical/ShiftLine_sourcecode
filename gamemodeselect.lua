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

local gamemodeselect = {}

local log = require "log"
local gamejolt = require "gamejolt"

local displayWidth, displayHeight = love.graphics.getDimensions()
local slope = -(displayWidth / 20) / (displayHeight * 0.9)
local i18n = require "i18n"
local ui = require "lib.ui"

local soloPoly
local storyPoly
local settingPoly
local titlePoly

local soloButton
local storyButton
local settingButton
local titleButton

local fadeAlpha = 0
local fading = false
local fadeSpeed = 1.5

function pointInPolygon(x, y, poly)
    local inside = false
    local j = #poly - 1

    for i = 1, #poly, 2 do
        local xi = poly[i]
        local yi = poly[i + 1]
        local xj = poly[j]
        local yj = poly[j + 1]

        local intersect =
            ((yi > y) ~= (yj > y)) and
            (x < (xj - xi) * (y - yi) / (yj - yi) + xi)

        if intersect then
            inside = not inside
        end

        j = i
    end

    return inside
end

function getParallelogram(x1, x2, y1, y2)
    local dx = slope * (y2 - y1)

    return {
        x1, y1,
        x1 + dx, y2,
        x2 + dx, y2,
        x2, y1
    }
end

local function buildButton(x1, x2, y1, y2, text)
    return {
        poly = getParallelogram(x1, x2, y1, y2),
        x = (x1 + x2) / 2,
        y = (y1 + y2) / 2,
        text = text
    }
end

local function rebuildButtons()
    soloButton = buildButton(
        displayWidth / 20,
        displayWidth / 2,
        displayHeight / 20,
        displayHeight / 10 * 9.5,
        "Solo"
    )

    storyButton = buildButton(
        displayWidth / 2 + displayWidth / 40,
        displayWidth,
        displayHeight / 20,
        displayHeight / 40 * 19,
        "Story"
    )

    settingButton = buildButton(
        displayWidth / 2,
        displayWidth / 4 * 3,
        displayHeight / 2,
        displayHeight / 10 * 9.5,
        "Settings"
    )

    titleButton = buildButton(
        displayWidth / 4 * 3 + displayWidth / 40,
        displayWidth - displayWidth / 40,
        displayHeight / 2,
        displayHeight / 10 * 9.5,
        "Title"
    )

    soloPoly = soloButton.poly
    storyPoly = storyButton.poly
    settingPoly = settingButton.poly
    titlePoly = titleButton.poly
end

local function updateLayout(force)
    local w, h = love.graphics.getDimensions()
    if force or w ~= displayWidth or h ~= displayHeight then
        displayWidth, displayHeight = w, h
        slope = -(displayWidth / 20) / (displayHeight * 0.9)
        rebuildButtons()

        local baseSize = math_max(28, math_floor(displayHeight * 0.08))
        if i18n.getLanguage() == "jp" then
            baseSize = math_max(24, math_floor(displayHeight * 0.072))
        end
        local smallSize = math_max(18, math_floor(displayHeight * 0.03))
        originalfont = love.graphics.newFont("lib/data/fonts/NotoSansJP-Light.ttf", baseSize)
        accountfont = love.graphics.newFont("lib/data/fonts/NotoSansJP-Light.ttf", smallSize)
    end
end

function drawParallelogram(button, mx, my, font)
    if not button or not button.poly then return end
    local opts = {
        hoverColor = {0.25,0.25,0.25},
        color = {0.1,0.1,0.1},
        lineColor = {1,1,1,0.5},
        textColor = {1,1,1},
        textPadding = 36
    }
    -- If language is jp make text slightly smaller by leaving more padding
    if i18n.getLanguage() == "jp" then
        opts.textPadding = opts.textPadding + 20
    end
    ui.drawParallelogram(button.poly, button.text, font, opts)
end

function gamemodeselect.load()
    updateLayout(true)
    fadeAlpha = 0
    fading = false

    print("Loaded Game Mode Selection screen")

    local baseSize = math_max(28, math_floor(displayHeight * 0.08))
    if i18n.getLanguage() == "jp" then
        baseSize = math_max(24, math_floor(displayHeight * 0.072))
    end
    local smallSize = math_max(18, math_floor(displayHeight * 0.03))

    originalfont = love.graphics.newFont("lib/data/fonts/NotoSansJP-Light.ttf", baseSize)
    accountfont = love.graphics.newFont("lib/data/fonts/NotoSansJP-Light.ttf", smallSize)

    gamemodeselect.endprocess = false
    gamemodeselect.selectedmode = nil
end

function gamemodeselect.update(dt)
    if fading then
        fadeAlpha = fadeAlpha + fadeSpeed * dt

        if fadeAlpha >= 1 then
            fadeAlpha = 1
            gamemodeselect.endprocess = true
        end
    end
end

function gamemodeselect.mousepressed(x, y, button)
    updateLayout(false)

    if button ~= 1 then return end
    if fading then return end

    if soloPoly and pointInPolygon(x, y, soloPoly) then
        gamemodeselect.selectedmode = 1
        gamemodeselect.endprocess = false
        fading = true
        log.info("Go to solo mode")
        return
    end

    if storyPoly and pointInPolygon(x, y, storyPoly) then
        if not (gamejolt.status and gamejolt.status.authenticated and (gamejolt.status.username == "cloudoamp" or gamejolt.status.username == "hamu132")) then
            log.warn("Story access denied: GameJolt login required as cloudoamp or hamu132")
            return
        end
        gamemodeselect.selectedmode = 2
        gamemodeselect.endprocess = false
        fading = true
        log.info("Go to Story mode")
        return
    end

    if settingPoly and pointInPolygon(x, y, settingPoly) then
        gamemodeselect.selectedmode = 3
        gamemodeselect.endprocess = false
        fading = true
        log.info("Go to Settings")
        return
    end

    if titlePoly and pointInPolygon(x, y, titlePoly) then
        gamemodeselect.selectedmode = 0
        gamemodeselect.endprocess = false
        fading = true
        log.info("Go to Title")
        return
    end
end

function gamemodeselect.draw()
    updateLayout(false)

    love.graphics.setFont(originalfont)
    local mx, my = love.mouse.getPosition()
    drawParallelogram(soloButton, mx, my, originalfont)
    drawParallelogram(storyButton, mx, my, originalfont)
    drawParallelogram(settingButton, mx, my, originalfont)
    drawParallelogram(titleButton, mx, my, originalfont)
end

function gamemodeselect.drawOverlay()
    if fadeAlpha > 0 then
        love.graphics.setColor(0, 0, 0, fadeAlpha)
        love.graphics.rectangle("fill", 0, 0, displayWidth, displayHeight)
        love.graphics.setColor(1, 1, 1, 1)
    end
end

return gamemodeselect


