-- JSON.lua
local json_ok, json = pcall(require, "JSON")
local http_ok, http = pcall(require, "socket.http")
local ltn12_ok, ltn12 = pcall(require, "ltn12")

local M = {}

local WEBHOOK_URL = os.getenv("SHIFTLINE_WEBHOOK_URL") or ""
local ERROR_FILE = "last_error.json"
local MENTION_USER_ID = os.getenv("SHIFTLINE_WEBHOOK_MENTION_ID") or ""

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

    local mention = MENTION_USER_ID ~= "" and ("<@" .. MENTION_USER_ID .. ">\n") or ""
    return {
        username = "ShiftLineクラッシュお知らせくん",
        allowed_mentions = {
            parse = { "users" }
        },
        content =
            mention ..
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

    if not http_ok or not ltn12_ok or not http or not ltn12 then
        return false
    end

    local response = {}
    local ok, code = pcall(http.request, {
        url = WEBHOOK_URL,
        method = "POST",
        headers = {
            ["Content-Type"] = "application/json",
            ["Content-Length"] = tostring(#jsonData)
        },
        source = ltn12.source.string(jsonData),
        sink = ltn12.sink.table(response)
    })
    if not ok or tonumber(code) == nil or tonumber(code) < 200 or tonumber(code) >= 300 then
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