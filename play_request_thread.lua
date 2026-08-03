local JSON = require "JSON"
local ch = love.thread.getChannel("play_song_request_channel")
local resultCh = love.thread.getChannel("play_song_request_result_channel")
local data = ch:demand()
local song = data and data.song or ""
local difficulty = data and data.difficulty or ""

local function urlEncode(str)
    if type(str) ~= "string" then
        return ""
    end
    return str:gsub("([^%w%-_.~])", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
end

local function sendRequest(song, difficulty)
    if type(song) ~= "string" or song == "" then
        return "Request count unavailable", false
    end

    local safeDifficulty = ""
    if difficulty ~= nil then
        safeDifficulty = tostring(difficulty)
    end
    local requestBody = "song=" .. urlEncode(song) .. "&difficulty=" .. urlEncode(safeDifficulty)

    local curl_path = "curl.exe"
    local windir = os.getenv("WINDIR") or "C:\\Windows"
    local system_curl = windir .. "\\System32\\curl.exe"
    local can_open = io.open(system_curl, "rb")
    if can_open then
        can_open:close()
        curl_path = system_curl
    end

    local workdir = os.getenv("TEMP") or "C:\\Windows\\Temp"
    local body_file = workdir .. "\\musiccount_body_" .. tostring(os.time()) .. ".txt"
    local body_handle = io.open(body_file, "wb")
    if body_handle then
        body_handle:write(requestBody)
        body_handle:close()
    else
        return "Request count unavailable", false
    end

    local curl_cmd = 'cd /d "' .. workdir .. '" && "' .. curl_path .. '" -sSL -L --post302 --post301 -i -X POST "' .. musicCountUrl .. '" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" -H "Content-Type: application/x-www-form-urlencoded; charset=UTF-8" -H "Accept: application/json" -H "Expect:" --data-binary @"' .. body_file .. '" -w "\n--CURL_STATUS--%{http_code}" 2>&1'

    local handle = io.popen(curl_cmd)
    local curl_output = ""
    if handle then
        curl_output = handle:read("*a") or ""
        handle:close()
    end
    pcall(os.remove, body_file)

    local status = 500
    local responseBody = ""

    if curl_output and curl_output ~= "" then
        local status_marker = curl_output:match("%-%-CURL_STATUS%-%-(%d+)")
        if status_marker then
            status = tonumber(status_marker) or 500
        else
            local last_status = nil
            for code in curl_output:gmatch("HTTP/[%d%.]+%s+(%d+)") do
                last_status = tonumber(code)
            end
            if last_status then
                status = last_status
            end
        end

        local body = curl_output:match(".*\r\n\r\n(.*)%-%-CURL_STATUS%-%-%d+") or curl_output:match(".*\n\n(.*)%-%-CURL_STATUS%-%-%d+") or curl_output:match(".*\r\n\r\n(.*)") or curl_output:match(".*\n\n(.*)")
        if body then
            responseBody = body
        else
            responseBody = curl_output
        end
    end

    if responseBody == "" or status ~= 200 then
        return "Request count unavailable", false
    end

    if responseBody:sub(1, 5) == "<html" then
        return "Request count unavailable", false
    end

    local ok, decoded = pcall(JSON.decode, JSON, responseBody)
    if not ok or type(decoded) ~= "table" then
        return "Request count unavailable", true
    end

    local success = decoded.success == true or tostring(decoded.status or ""):lower() == "ok"
    if not success then
        local countText = tostring(decoded.count or decoded.song or "?")
        if decoded.count == nil and decoded.song then
            countText = "logged"
        end
        return "Request count: " .. countText, true
    end

    local countText = tostring(decoded.count or decoded.song or "?")
    if decoded.count == nil and decoded.song then
        countText = "logged"
    end

    return "Request count: " .. countText, true
end

local countText, success = sendRequest(song, difficulty)
resultCh:push({countText = countText, ok = success})
