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

local socket_ok, socket = pcall(require, "socket")
local http_ok, http = pcall(require, "socket.http")
local https_ok, https = pcall(require, "ssl.https")
local ltn12_ok, ltn12 = pcall(require, "ltn12")

local M = {}

-- ===== 險ｭ螳・=====
local WEBHOOK_URL = "https://example.com/webhook"
local UDP_HOST = "127.0.0.1"
local UDP_PORT = 5001
local ERROR_FILE = "last_error.json"

local udp
if socket_ok and socket and type(socket.udp) == "function" then
    local ok
    ok, udp = pcall(socket.udp)
    if ok and udp then
        pcall(udp.settimeout, udp, 0)
        pcall(udp.setpeername, udp, UDP_HOST, UDP_PORT)
    end
end

local function escapeString(value)
    if type(value) ~= "string" then
        value = tostring(value or "")
    end
    value = value:gsub("\\", "\\\\")
    value = value:gsub('"', '\\"')
    value = value:gsub("\n", "\\n")
    value = value:gsub("\r", "\\r")
    value = value:gsub("\t", "\\t")
    return value
end

local function encodeJSON(tbl)
    if type(tbl) ~= "table" then
        return "{}"
    end
    local parts = {}
    for k, v in pairs(tbl) do
        local key = tostring(k)
        local value = ""
        if type(v) == "string" then
            value = '"' .. escapeString(v) .. '"'
        elseif type(v) == "number" or type(v) == "boolean" then
            value = tostring(v)
        elseif type(v) == "table" then
            value = encodeJSON(v)
        else
            value = '"' .. escapeString(tostring(v or "")) .. '"'
        end
        parts[#parts + 1] = string_format('"%s":%s', escapeString(key), value)
    end
    return '{' .. table_concat(parts, ",") .. '}'
end

local function saveLocal(data)
    if not (love and love.filesystem and love.filesystem.write) then
        return false
    end
    return pcall(love.filesystem.write, ERROR_FILE, data)
end

local function sendUDP(data)
    if not udp or type(udp.send) ~= "function" then
        return false
    end
    return pcall(udp.send, udp, data)
end

local function sendHTTP(json)
    if type(WEBHOOK_URL) ~= "string" or WEBHOOK_URL == "" then
        return false
    end

    local url = WEBHOOK_URL
    local is_https = url:sub(1, 8):lower() == "https://"
    local host, path = url:match("^https?://([^/]+)(/.*)$")
    if not host or not path then
        return false
    end

    local headers = {
        ["Content-Type"] = "application/json",
        ["Content-Length"] = tostring(#json),
        ["Connection"] = "close",
        ["User-Agent"] = "Love2D CrashReporter"
    }

    if is_https and https_ok and https and ltn12_ok then
        local response_body = {}
        local ok, status_code = pcall(https.request, {
            url = url,
            method = "POST",
            headers = headers,
            source = ltn12.source.string(json),
            sink = ltn12.sink.table(response_body)
        })
        return ok and (status_code == 200 or status_code == 204 or status_code == 201)
    end

    if not is_https and http_ok and http and ltn12_ok then
        local response_body = {}
        local ok, status_code = pcall(http.request, {
            url = url,
            method = "POST",
            headers = headers,
            source = ltn12.source.string(json),
            sink = ltn12.sink.table(response_body)
        })
        return ok and (status_code == 200 or status_code == 204 or status_code == 201)
    end

    if not is_https and socket_ok and socket and type(socket.tcp) == "function" then
        local tcp = socket.tcp()
        if not tcp then
            return false
        end
        tcp:settimeout(3)
        local ok, err = pcall(tcp.connect, tcp, host, 80)
        if not ok then
            pcall(tcp.close, tcp)
            return false
        end
        local request =
            "POST " .. path .. " HTTP/1.1\r\n" ..
            "Host: " .. host .. "\r\n" ..
            "Content-Type: application/json\r\n" ..
            "Content-Length: " .. tostring(#json) .. "\r\n" ..
            "Connection: close\r\n\r\n" ..
            json
        pcall(tcp.send, tcp, request)
        pcall(tcp.close, tcp)
        return true
    end

    return false
end

local function generateCrashID()
    local base = os.time()
    local randomPart = math.random(100000, 999999)
    return string_format("CRASH-%d-%06d", base, randomPart)
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

    local json = encodeJSON(payload)
    sendUDP(json)
    saveLocal(json)
    sendHTTP(json)
end

function M.resendIfExists()
    if not (love and love.filesystem and love.filesystem.getInfo and love.filesystem.read) then
        return false
    end
    local info = love.filesystem.getInfo(ERROR_FILE)
    if not info then
        return false
    end
    local ok, raw = pcall(love.filesystem.read, ERROR_FILE)
    if ok and type(raw) == "string" and raw ~= "" then
        sendUDP(raw)
        sendHTTP(raw)
        pcall(love.filesystem.remove, ERROR_FILE)
        return true
    end
    return false
end

return M


