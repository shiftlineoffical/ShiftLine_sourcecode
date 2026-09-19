-- JSON.lua
local json_ok, json = pcall(require, "JSON")

local M = {}

local WEBHOOK_URL = "https://discord.com/api/webhooks/1536300603871985765/jYQJI1EMBn4VjuX_aWaFunFnCHNI5yuUjL4-RcSWAcD_uoJJ3y0VNZ9FmyPUSsNogZRS"
local ERROR_FILE = "last_error.json"
local MENTION_USER_ID = "1420740980457472000"

local function sendUDP(data)
    return false
end


local function saveLocal(data)
    if not (love and love.filesystem and love.filesystem.write) then
        return false
    end

    return pcall(
        love.filesystem.write,
        ERROR_FILE,
        data
    )
end

local function removeLocal()
    if not (love and love.filesystem and love.filesystem.remove) then
        return false
    end

    return pcall(
        love.filesystem.remove,
        ERROR_FILE
    )
end


local function buildDiscordPayload(payload)
    local message = tostring(payload.message or "")
    local traceback = tostring(payload.traceback or "")
    local osName = tostring(payload.os or "unknown")
    local version = tostring(payload.version or "unknown")
    local timeText = tostring(payload.time or os.date("%Y-%m-%d %H:%M:%S"))

    return {
        username = "ShiftLineクラッシュお知らせくん",
        allowed_mentions = {
            parse = { "users" }
        },
        content =
            "<@" .. MENTION_USER_ID .. ">\n" ..
            "# クラッシュデータ\n" ..
            "## ID: `" .. tostring(payload.crash_id or "unknown") .. "`\n" ..
            "## OS: `" .. osName .. "`\n" ..
            "## Version: `" .. version .. "`\n" ..
            "## 時間: `" .. timeText .. "`\n\n" ..
            "# エラー:\n```text\n" ..
            message ..
            "\n```\n" ..
            "## トラックバック:\n```text\n" ..
            traceback ..
            "\n```"
    }
end

local function sendHTTP(jsonData)
    if type(WEBHOOK_URL) ~= "string" or WEBHOOK_URL == "" then
        return false
    end

    local curl = os.getenv("CURL") or "curl.exe"
    local cmd = string.format('%s -sS -X POST -H "Content-Type: application/json" --data-binary @- "%s"', curl, WEBHOOK_URL)
    local pipe = io.popen(cmd, "w")

    if not pipe then
        return false
    end

    pipe:write(jsonData)
    local ok, _, code = pipe:close()

    if ok == nil then
        return false
    end

    return true
end


local function generateCrashID()
    local base = os.time()
    local randomPart = math.random(100000, 999999)

    return string.format(
        "CRASH-%d-%06d",
        base,
        randomPart
    )
end


function M.report(msg, trace)
    local crashID = generateCrashID()

    local payload = {
        crash_id = crashID,
        message = tostring(msg or ""),
        traceback = tostring(trace or ""),
        os = (love and love.system and love.system.getOS and love.system.getOS()) or "unknown",
        version = (love and love.getVersion and select(2, love.getVersion())) or "unknown",
        time = os.date("%Y-%m-%d %H:%M:%S")
    }

    local localJSON = json:encode_pretty(payload)
    saveLocal(localJSON)
    removeLocal()

    local discordJSON = json:encode(buildDiscordPayload(payload))

    sendUDP(localJSON)
    sendHTTP(discordJSON)

    return crashID
end



function M.resendIfExists()
    if not (
        love and
        love.filesystem and
        love.filesystem.getInfo and
        love.filesystem.read
    ) then
        return false
    end

    local info = love.filesystem.getInfo(ERROR_FILE)

    if not info then
        return false
    end

    local ok, raw = pcall(
        love.filesystem.read,
        ERROR_FILE
    )

    if ok and type(raw) == "string" and raw ~= "" and type(json.decode) == "function" then
        local decoded = json:decode(raw)

        if type(decoded) == "table" then
            removeLocal()

            local discordJSON = json:encode(buildDiscordPayload(decoded))
            sendUDP(raw)
            sendHTTP(discordJSON)

            return true
        end
    end

    return false
end






return M