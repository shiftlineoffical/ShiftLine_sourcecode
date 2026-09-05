local online_play = {}

local play = require("play")
local online_connect = require("online_connect")

local comboByPlayer = {}
local playerID = nil
local sendTimer = 0
local comboFont = nil
local labelFont = nil

local function resetComboState()
    comboByPlayer = {}
    playerID = online_connect.getPlayerID() or "local"
    comboByPlayer[playerID] = 0
    sendTimer = 0
end

local function getTeamCombo()
    local total = 0
    for _, combo in pairs(comboByPlayer) do
        total = total + math.max(0, math.floor(tonumber(combo) or 0))
    end
    return total
end

local function receivePacket(typeName, parts)
    if typeName ~= "ONLINE_COMBO" then
        return
    end

    local remoteID = parts and parts[2]
    local combo = tonumber(parts and parts[3])
    if type(remoteID) == "string" and remoteID ~= "" and combo then
        comboByPlayer[remoteID] = math.max(0, math.floor(combo))
    end
end

local function updateFonts()
    local _, height = love.graphics.getDimensions()
    comboFont = love.graphics.newFont(
        "lib/data/fonts/NotoSansJP-Regular.ttf",
        math.max(24, math.floor(height * 0.04))
    )
    labelFont = love.graphics.newFont(
        "lib/data/fonts/NotoSansJP-Light.ttf",
        math.max(16, math.floor(height * 0.022))
    )
end

function online_play.load()
    if type(play.setResultTransitionHandler) == "function" then
        play.setResultTransitionHandler(function()
            changeProgram(12)
        end)
    end
    play.load()
    updateFonts()
    resetComboState()
end

function online_play.update(dt)
    play.update(dt)

    if not online_connect.isConnected() then
        return
    end

    local currentPlayerID = playerID or "local"
    local currentCombo = 0
    if play and type(play.getCombo) == "function" then
        local ok, value = pcall(play.getCombo)
        if ok then
            currentCombo = tonumber(value) or 0
        end
    end
    comboByPlayer[currentPlayerID] = math.max(0, math.floor(currentCombo))
    sendTimer = sendTimer + (dt or 0)
    if sendTimer >= 0.1 then
        sendTimer = 0
        online_connect.send("ONLINE_COMBO", currentPlayerID, comboByPlayer[currentPlayerID])
    end
end

function online_play.draw()
    play.draw()

    local width, height = love.graphics.getDimensions()
    local teamCombo = getTeamCombo()
    local comboText = tostring(teamCombo)
    local labelText = "TEAM COMBO"
    local currentFont = comboFont or love.graphics.getFont()
    local currentLabelFont = labelFont or love.graphics.getFont()
    love.graphics.setFont(currentFont)
    local centerX = width * 0.5
    local centerY = height * 0.5
    love.graphics.setColor(0.45, 0.95, 0.9, 0.95)
    love.graphics.print(comboText, centerX - currentFont:getWidth(comboText) * 0.5, centerY - 112)
    love.graphics.setFont(currentLabelFont)
    love.graphics.setColor(0.55, 0.9, 0.86, 0.85)
    love.graphics.print(labelText, centerX - currentLabelFont:getWidth(labelText) * 0.5, centerY - 70)
    love.graphics.setColor(1, 1, 1, 1)
end

function online_play.drawOverlay()
    if play.drawOverlay then
        play.drawOverlay()
    end
end

function online_play.mousepressed(...)
    if play.mousepressed then
        play.mousepressed(...)
    end
end

function online_play.mousereleased(...)
    if play.mousereleased then
        play.mousereleased(...)
    end
end

function online_play.wheelmoved(...)
    if play.wheelmoved then
        play.wheelmoved(...)
    end
end

function online_play.keypressed(...)
    if play.keypressed then
        play.keypressed(...)
    end
end

function online_play.keyreleased(...)
    if play.keyreleased then
        play.keyreleased(...)
    end
end

function online_play.quit()
    if type(play.setResultTransitionHandler) == "function" then
        play.setResultTransitionHandler(nil)
    end
    if play.quit then
        play.quit()
    end
    comboByPlayer = {}
end

online_connect.on("packet", receivePacket)

return online_play
