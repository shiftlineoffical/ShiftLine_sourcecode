local socket = require("socket")
local okHttp, http = pcall(require, "socket.http")
if not okHttp then
    http = nil
end

local network = {}

network.PORT = 12345
network.mode = "offline"

network.server = nil
network.peer = nil
network.connected = false

network.playerID = nil
network.remotePlayerID = nil

network.messages = {}
network.handlers = {}

network.ping = 0
network.lastPingTime = 0
network.pingInterval = 2
network.VERSION = 1

local pendingPing = nil
local externalIP = nil
local externalIPFetchTime = 0
local externalIPCacheDuration = 3600

-- HTTP library diagnostic info
network.httpAvailable = okHttp and http ~= nil

-- 文字
local CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

local function randomString(length)
    local result = ""

    for i = 1, length do
        local index = math.random(1, #CHARS)
        result = result .. CHARS:sub(index, index)
    end

    return result
end

-- 分割
local function split(str, separator)
    local result = {}

    for value in string.gmatch(str, "([^" .. separator .. "]+)") do
        result[#result + 1] = value
    end

    return result
end

-- ID生成
local function generatePlayerID()
    return randomString(8)
end

-- IP取得
function network.getLocalIP()
    local host = socket.dns.gethostname()
    return socket.dns.toip(host)
end

-- 外部IP取得
function network.getExternalIP(callback)
    if not http then
        local errorMsg = "HTTPライブラリ (socket.http) がインストールされていません。\n" ..
                        "LuaSocket ライブラリをインストールしてください。"
        if callback then
            callback(nil, errorMsg)
        end
        return nil, errorMsg
    end

    local now = socket.gettime()

    -- キャッシュがあれば返す
    if externalIP and (now - externalIPFetchTime) < externalIPCacheDuration then
        if callback then
            callback(externalIP)
        end
        return externalIP
    end

    -- 複数のAPIエンドポイント
    local endpoints = {
        "http://api.ipify.org?format=plain",
        "http://icanhazip.com",
        "http://ifconfig.me",
        "http://ident.me"
    }

    local function tryFetchIP()
        local lastError = ""

        for _, url in ipairs(endpoints) do
            local ok, body, statuscode, headers = pcall(function()
                return http.request(url)
            end)

            if ok then
                -- レスポンス取得成功
                if body and type(body) == "string" and body ~= "" then
                    local ip = body:match("^%s*(.-)%s*$")

                    if ip and ip:match("^%d+%.%d+%.%d+%.%d+$") then
                        externalIP = ip
                        externalIPFetchTime = socket.gettime()
                        return ip, nil
                    else
                        lastError = "Invalid IP format from " .. url .. ": " .. ip
                    end
                else
                    lastError = "Empty response from " .. url
                end
            else
                -- エラー発生
                lastError = "Request failed for " .. url .. ": " .. tostring(body)
            end
        end

        return nil, lastError ~= "" and lastError or "全てのエンドポイントが失敗しました"
    end

    -- 非同期フェッチ
    if callback then
        local function fetchAsync()
            local ip, err = tryFetchIP()
            callback(ip, err)
        end

        -- ここでは同期実行するが、本来はスレッドで非同期実行することを推奨
        fetchAsync()
        return nil
    else
        -- 同期フェッチ
        return tryFetchIP()
    end
end

-- RoomID作成
function network.createRoomID()
    local ip = network.getLocalIP()

    if not ip then
        return nil, "IP取得失敗"
    end

    return ip .. ":" .. network.PORT
end

-- RoomID解析
function network.parseRoomID(roomID)
    if type(roomID) ~= "string" then
        return nil, nil, "RoomIDが不正です"
    end

    local ip, port = roomID:match("^([^:]+):(%d+)$")

    if not ip then
        return nil, nil, "RoomIDが不正です"
    end

    port = tonumber(port)

    if not port or port < 1 or port > 65535 then
        return nil, nil, "ポートが不正です"
    end

    return ip, port
end

-- イベント登録
function network.on(event, callback)
    network.handlers[event] = network.handlers[event] or {}
    table.insert(network.handlers[event], callback)
end

-- イベント発火
local function emit(event, ...)
    local list = network.handlers[event]

    if not list then
        return
    end

    for _, callback in ipairs(list) do
        callback(...)
    end
end

-- 送信
local function rawSend(data)
    if not network.peer then
        return false, "未接続です"
    end

    local ok, err = network.peer:send(data .. "\n")

    if not ok then
        emit("error", err)
        return false, err
    end

    return true
end

-- パケット送信
function network.send(typeName, ...)
    local packet = typeName

    for _, value in ipairs({...}) do
        value = tostring(value):gsub("|", "")
        packet = packet .. "|" .. value
    end

    return rawSend(packet)
end

-- パケット処理
local function processPacket(packet)
    local parts = split(packet, "|")
    local typeName = parts[1]

    if not typeName then
        return
    end

    if typeName == "HELLO" then
        network.remotePlayerID = parts[2]

        network.send(
            "WELCOME",
            network.playerID,
            network.VERSION
        )

        emit("player_join", network.remotePlayerID)
        return
    end

    if typeName == "WELCOME" then
        network.remotePlayerID = parts[2]

        local version = tonumber(parts[3])

        if version ~= network.VERSION then
            emit("error", "バージョン不一致")
            return
        end

        network.connected = true

        emit(
            "connected",
            network.remotePlayerID
        )

        return
    end

    if typeName == "PING" then
        network.send("PONG", parts[2])
        return
    end

    if typeName == "PONG" then
        local id = parts[2]

        if pendingPing == id then
            network.ping =
                (socket.gettime() - network.lastPingTime) * 1000

            pendingPing = nil

            emit("ping", network.ping)
        end

        return
    end

    if typeName == "DISCONNECT" then
        emit(
            "disconnect",
            parts[2] or "切断"
        )

        network.close()
        return
    end

    emit("packet", typeName, parts)
end

-- ホスト
function network.host()
    network.close()

    network.mode = "host"
    network.playerID = generatePlayerID()

    local server, err =
        socket.bind("*", network.PORT)

    if not server then
        emit("error", err)
        return false
    end

    server:settimeout(0)

    network.server = server

    emit(
        "hosting",
        network.createRoomID()
    )

    return true
end

-- 参加
function network.join(roomID)
    network.close()

    local ip, port, err =
        network.parseRoomID(roomID)

    if not ip then
        emit("error", err)
        return false
    end

    network.mode = "client"
    network.playerID = generatePlayerID()

    local client = socket.tcp()

    client:settimeout(5)

    local ok, connectError =
        client:connect(ip, port)

    if not ok then
        client:close()
        emit("error", connectError)
        return false
    end

    client:settimeout(0)

    network.peer = client

    network.send(
        "HELLO",
        network.playerID,
        network.VERSION
    )

    return true
end

-- 接続受付
local function acceptClient()
    if not network.server or network.peer then
        return
    end

    local client = network.server:accept()

    if not client then
        return
    end

    client:settimeout(0)

    network.peer = client
end

-- 受信
local function receivePackets()
    if not network.peer then
        return
    end

    while true do
        local data, err =
            network.peer:receive("*l")

        if data then
            processPacket(data)

        elseif err == "closed" then
            emit("disconnect", "接続終了")
            network.close()
            break

        else
            break
        end
    end
end

-- 更新
function network.update()
    if network.mode == "host" then
        acceptClient()
    end

    receivePackets()

    if network.connected then
        local now = socket.gettime()

        if now - network.lastPingTime >= network.pingInterval then
            local id = randomString(8)

            pendingPing = id
            network.lastPingTime = now

            network.send("PING", id)
        end
    end
end

-- 切断
function network.close()
    if network.peer then
        pcall(function()
            network.peer:send("DISCONNECT|close\n")
        end)

        pcall(function()
            network.peer:close()
        end)
    end

    if network.server then
        pcall(function()
            network.server:close()
        end)
    end

    network.peer = nil
    network.server = nil
    network.connected = false
    network.remotePlayerID = nil
    pendingPing = nil
    network.mode = "offline"
end

-- 接続確認
function network.isConnected()
    return network.connected
end

-- Ping取得
function network.getPing()
    return math.floor(network.ping + 0.5)
end

-- エラー取得
function network.getError()
    return network.lastError
end

-- 自分のID
function network.getPlayerID()
    return network.playerID
end

-- 相手のID
function network.getRemotePlayerID()
    return network.remotePlayerID
end

return network
