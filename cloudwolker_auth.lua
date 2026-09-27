local cloudwolker_auth = {}

local socket = require("socket")
local http = require("socket.http")
local ltn12 = require("ltn12")

local JSON = require("JSON")

cloudwolker_auth.BASE_URL =
    "https://shiftline-cloudwolker.cloudoam.workers.dev"

cloudwolker_auth.AUTH_URL =
    cloudwolker_auth.BASE_URL .. "/auth/discord"

cloudwolker_auth.TICKET_URL =
    cloudwolker_auth.BASE_URL .. "/auth/ticket"

cloudwolker_auth.APP_REDIRECT_URL =
    "shiftline://auth"

cloudwolker_auth.sessionToken = nil
cloudwolker_auth.user = nil

cloudwolker_auth.loading = false
cloudwolker_auth.authenticated = false
cloudwolker_auth.error = nil

local function trim(value)
    if type(value) ~= "string" then
        return ""
    end

    return value:match("^%s*(.-)%s*$") or ""
end

local function urlDecode(value)
    if type(value) ~= "string" then
        return ""
    end

    value = value:gsub("+", " ")

    value = value:gsub(
        "%%(%x%x)",
        function(hex)
            return string.char(
                tonumber(hex, 16)
            )
        end
    )

    return value
end

local function parseQuery(query)
    local result = {}

    if type(query) ~= "string" then
        return result
    end

    query = query:gsub("^%?", "")

    for pair in query:gmatch("[^&]+") do
        local key, value =
            pair:match("^([^=]*)=(.*)$")

        if key then
            result[urlDecode(key)] =
                urlDecode(value)
        else
            result[urlDecode(pair)] = ""
        end
    end

    return result
end

local function parseAuthURL(url)
    if type(url) ~= "string" then
        return nil
    end

    if not url:match("^shiftline://auth") then
        return nil
    end

    local query =
        url:match("%?(.*)$")

    if not query then
        return {}
    end

    return parseQuery(query)
end

local function httpGet(url, headers)
    local response = {}

    local result, code, responseHeaders, status =
        http.request({
            url = url,
            method = "GET",
            headers = headers or {},
            sink = ltn12.sink.table(response)
        })

    local body =
        table.concat(response)

    return result, code, responseHeaders, status, body
end

local function openBrowser(url)
    if love
        and love.system
        and type(love.system.openURL) == "function" then

        return love.system.openURL(url)
    end

    return false
end

function cloudwolker_auth.beginDiscordLogin()
    cloudwolker_auth.loading = true
    cloudwolker_auth.error = nil

    local ok =
        openBrowser(
            cloudwolker_auth.AUTH_URL
        )

    if not ok then
        cloudwolker_auth.loading = false
        cloudwolker_auth.error =
            "Discord認証ページを開けませんでした"

        return false,
            cloudwolker_auth.error
    end

    return true
end

function cloudwolker_auth.handleRedirect(url)
    local params =
        parseAuthURL(url)

    if not params then
        return false,
            "ShiftLine認証URLではありません"
    end

    local ticket =
        trim(params.ticket)

    if ticket == "" then
        local errorMessage =
            trim(params.error)

        if errorMessage == "" then
            errorMessage =
                "認証チケットがありません"
        end

        cloudwolker_auth.loading = false
        cloudwolker_auth.error =
            errorMessage

        return false,
            errorMessage
    end

    cloudwolker_auth.loading = true
    cloudwolker_auth.error = nil

    return cloudwolker_auth.exchangeTicket(
        ticket
    )
end

function cloudwolker_auth.exchangeTicket(ticket)
    ticket =
        trim(ticket)

    if ticket == "" then
        cloudwolker_auth.loading = false
        cloudwolker_auth.error =
            "チケットが空です"

        return false,
            cloudwolker_auth.error
    end

    local url =
        cloudwolker_auth.TICKET_URL ..
        "?ticket=" ..
        ticket

    local ok,
        code,
        headers,
        status,
        body =
        httpGet(url)

    if not ok then
        cloudwolker_auth.loading = false
        cloudwolker_auth.error =
            "Cloudwolkerへの接続に失敗しました"

        return false,
            cloudwolker_auth.error
    end

    if tonumber(code) ~= 200 then
        cloudwolker_auth.loading = false
        cloudwolker_auth.error =
            "認証チケット交換失敗: HTTP " ..
            tostring(code)

        return false,
            cloudwolker_auth.error
    end

    local decodedOk,
        data =
        pcall(
            JSON.decode,
            body
        )

    if not decodedOk
        or type(data) ~= "table" then

        cloudwolker_auth.loading = false
        cloudwolker_auth.error =
            "Cloudwolkerの応答を解析できませんでした"

        return false,
            cloudwolker_auth.error
    end

    if type(data.token) ~= "string"
        or data.token == "" then

        cloudwolker_auth.loading = false
        cloudwolker_auth.error =
            "セッショントークンを取得できませんでした"

        return false,
            cloudwolker_auth.error
    end

    cloudwolker_auth.sessionToken =
        data.token

    cloudwolker_auth.user =
        data.user

    cloudwolker_auth.authenticated = true
    cloudwolker_auth.loading = false
    cloudwolker_auth.error = nil

    return true,
        cloudwolker_auth.user
end

function cloudwolker_auth.isAuthenticated()
    return cloudwolker_auth.authenticated
        and type(cloudwolker_auth.sessionToken) == "string"
        and cloudwolker_auth.sessionToken ~= ""
end

function cloudwolker_auth.getToken()
    return cloudwolker_auth.sessionToken
end

function cloudwolker_auth.getUser()
    return cloudwolker_auth.user
end

function cloudwolker_auth.getError()
    return cloudwolker_auth.error
end

function cloudwolker_auth.isLoading()
    return cloudwolker_auth.loading
end

function cloudwolker_auth.logout()
    cloudwolker_auth.sessionToken = nil
    cloudwolker_auth.user = nil
    cloudwolker_auth.authenticated = false
    cloudwolker_auth.loading = false
    cloudwolker_auth.error = nil
end

return cloudwolker_auth