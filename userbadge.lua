local userbadge = {}

local gamejolt = require "gamejolt"
local gamejoltuser = require "gamejoltuser"
local settings = require "settings"
local ui = require("lib.ui")
local okHttp, http = pcall(require, "socket.http")
if not okHttp then http = nil end

local avatarImg = nil
local avatarScale = 1
local avatarUrlLoaded = nil
local avatarUrlAttempted = nil
local badgeFont = nil

local function ensureFont()
    if badgeFont then
        return badgeFont
    end

    local okFont, fontOrErr = pcall(ui.newFont, "lib/data/fonts/NotoSansJP-Light.ttf", 20)
    if okFont and fontOrErr then
        badgeFont = fontOrErr
        return badgeFont
    end

    badgeFont = love.graphics.getFont()
    return badgeFont
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

function userbadge.update(dt)
    if gamejolt.status and gamejolt.status.authenticated then
        local url = gamejolt.status.avatarUrl
        if type(url) == "string" and url ~= "" and url ~= avatarUrlLoaded and url ~= avatarUrlAttempted then
            avatarUrlAttempted = url
            avatarImg = fetchAvatarImage(url)
            if avatarImg then
                avatarScale = 40 / math.max(1, math.max(avatarImg:getWidth(), avatarImg:getHeight()))
                avatarUrlLoaded = url
            end
        end
    else
        avatarImg = nil
        avatarScale = 1
        avatarUrlLoaded = nil
        avatarUrlAttempted = nil
    end
end

function userbadge.draw()
    if not (gamejolt.status and gamejolt.status.authenticated) then return end

    local username = gamejolt.status.username
    if type(username) ~= "string" or username == "" then
        username = gamejoltuser.userid or ""
    end
    if type(username) ~= "string" or username == "" then return end

    local ratingText = ""
<<<<<<< Updated upstream
    if settings and type(settings.settingsdata) == "table" then
        local stats = settings.settingsdata.stats
        if type(stats) == "table" then
            local rating = tonumber(stats.ratingAverage) or tonumber(stats.lastRating)
            if type(rating) == "number" and rating > 0 then
                ratingText = "  " .. string.format("%.2f", rating)
            end
=======
    local ratingValue = nil

    if gamejolt and gamejolt.memory and type(gamejolt.memory) == "table" then
        local cachedRating = gamejolt.memory.resultRating
        if cachedRating ~= nil then
            ratingValue = tonumber(cachedRating)
>>>>>>> Stashed changes
        end
    end

    if type(ratingValue) ~= "number" and settings and type(settings.settingsdata) == "table" then
        local stats = settings.settingsdata.stats
        if type(stats) == "table" then
            ratingValue = tonumber(stats.ratingAverage) or tonumber(stats.lastRating)
        end
    end

    if type(ratingValue) == "number" and ratingValue > 0 then
        ratingText = "  " .. string.format("%.2f", ratingValue)
    end

    local font = ensureFont()

    local prevFont = love.graphics.getFont()
    local r, g, b, a = love.graphics.getColor()
    if font and type(font.getWidth) == "function" and type(font.getHeight) == "function" then
        love.graphics.setFont(font)
    else
        love.graphics.setFont(prevFont)
    end

    local iconSize = 40
    local pad = 10
    local x = 10
    local y = 10

    local nameText = username
    local nameW = 0
    local nameH = 20
    local ratingW = 0
    local ratingH = 20
    local totalTextW = 0

    if font and type(font.getWidth) == "function" and type(font.getHeight) == "function" then
        nameW = font:getWidth(nameText)
        nameH = font:getHeight()
        ratingW = font:getWidth(ratingText)
        ratingH = font:getHeight()
    elseif prevFont and type(prevFont.getWidth) == "function" and type(prevFont.getHeight) == "function" then
        nameW = prevFont:getWidth(nameText)
        nameH = prevFont:getHeight()
        ratingW = prevFont:getWidth(ratingText)
        ratingH = prevFont:getHeight()
    end

    totalTextW = nameW + (ratingText ~= "" and (pad + ratingW) or 0)
    local bgW = iconSize + pad + totalTextW + pad
    local bgH = iconSize

    love.graphics.setColor(0, 0, 0, 0.45)
    love.graphics.rectangle("fill", x - 4, y - 4, bgW + 8, bgH + 8, 6, 6)

    if avatarImg then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(avatarImg, x, y, 0, avatarScale, avatarScale)
    else
        love.graphics.setColor(0, 0, 0, 0.25)
        love.graphics.rectangle("fill", x, y, iconSize, iconSize)
        love.graphics.setColor(1, 1, 1, 0.7)
        love.graphics.rectangle("line", x, y, iconSize, iconSize)
    end

    love.graphics.setColor(1, 1, 1, 1)
<<<<<<< Updated upstream
    love.graphics.print(displayName, x + iconSize + pad, y + math.floor((iconSize - textH) / 2 + 0.5))
=======
    local textY = y + math.floor((iconSize - math.max(nameH, ratingH)) / 2 + 0.5)
    love.graphics.print(nameText, x + iconSize + pad, textY)
    if ratingText ~= "" then
        love.graphics.print(ratingText, x + iconSize + pad + nameW + pad, textY)
    end
>>>>>>> Stashed changes

    love.graphics.setFont(prevFont)
    love.graphics.setColor(r, g, b, a)
end

return userbadge
