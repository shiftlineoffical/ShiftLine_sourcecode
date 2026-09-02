local socket = require("socket")

local okHttp, http = pcall(require, "socket.http")
if not okHttp then
    http = nil
end

local network = {}

-- 設定
network.PORT = 12345
network.VERSION = 1

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

network.lastError = nil

network.connectTimeout = 5
network.handshakeTimeout = 10

-- 内部
local pendingPing = nil

local externalIP = nil
local externalIPFetchTime = 0
local externalIPCacheDuration = 3600

local connectionStartTime = 0
local handshakeStartTime = 0

local closing = false

-- HTTP
network.httpAvailable = okHttp and http ~= nil

-- 文字
local CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

local function randomString(length)
    local result = {}

    for i = 1, length do
        local index = math.random(1, #CHARS)
        result[i] = CHARS:sub(index, index)
    end

    return table.concat(result)
end

-- 分割
local function split(str, separator)
    local result = {}

    if not str then
        return result
    end

    for value in string.gmatch(
        str,
        "([^" .. separator .. "]+)"
    ) do
        result[#result + 1] = value
    end

    return result
end

-- ID生成
local function generatePlayerID()
    return randomString(8)
end

-- エラー
local function setError(message)
    network.lastError = tostring(
        message or "不明なエラー"
    )

    emit("error", network.lastError)
end

-- イベント
function network.on(event, callback)
    if type(event) ~= "string" then
        return false
    end

    if type(callback) ~= "function" then
        return false
    end

    network.handlers[event] =
        network.handlers[event] or {}

    table.insert(
        network.handlers[event],
        callback
    )

    return true
end

-- 発火
local function emit(event, ...)
    local list = network.handlers[event]

    if not list then
        return
    end

    for _, callback in ipairs(list) do
        local ok, err = pcall(
            callback,
            ...
        )

        if not ok then
            network.lastError = tostring(err)
        end
    end
end

-- ローカルIP
function network.getLocalIP()
    local host = socket.dns.gethostname()

    if not host then
        return nil
    end

    return socket.dns.toip(host)
end

-- 外部IP
function network.getExternalIP(callback)
    if not http then
        local errorMsg =
            "HTTPライブラリがありません"

        if callback then
            callback(nil, errorMsg)
        end

        return nil, errorMsg
    end

    local now = socket.gettime()

    if externalIP
        and now - externalIPFetchTime
            < externalIPCacheDuration then

        if callback then
            callback(externalIP)
        end

        return externalIP
    end

    -- API
    local endpoints = {
        "https://api.ipify.org?format=plain",
        "https://icanhazip.com",
        "https://ifconfig.me/ip",
        "https://ident.me"
    }

    local function fetchIP()
        local lastError =
            "外部IP取得失敗"

        for _, url in ipairs(endpoints) do

            local ok, body = pcall(function()
                return http.request(url)
            end)

            if ok
                and body
                and type(body) == "string"
                and body ~= "" then

                local ip =
                    body:match("^%s*(.-)%s*$")

                if ip
                    and ip:match(
                        "^%d+%.%d+%.%d+%.%d+$"
                    ) then

                    externalIP = ip
                    externalIPFetchTime =
                        socket.gettime()

                    return ip
                end

                lastError = "IP形式エラー"
            else
                lastError = "HTTP通信失敗"
            end
        end

        return nil, lastError
    end

    local ip, err = fetchIP()

    if callback then
        callback(ip, err)
    end

    return ip, err
end

-- Room作成
function network.createRoomID()
    local ip = network.getLocalIP()

    if not ip then
        return nil, "IP取得失敗"
    end

    return ip .. ":" .. network.PORT
end

-- 外部Room
function network.createExternalRoomID()
    local ip, err =
        network.getExternalIP()

    if not ip then
        return nil, err
    end

    return ip .. ":" .. network.PORT
end

-- Room解析
function network.parseRoomID(roomID)
    if type(roomID) ~= "string" then
        return nil, nil, "RoomID不正"
    end

    local ip, port =
        roomID:match(
            "^([^:]+):(%d+)$"
        )

    if not ip then
        return nil, nil, "RoomID不正"
    end

    port = tonumber(port)

    if not port
        or port < 1
        or port > 65535 then

        return nil, nil, "ポート不正"
    end

    return ip, port
end

-- 送信
local function rawSend(data)
    if not network.peer then
        return false, "未接続"
    end

    local ok, err =
        network.peer:send(
            data .. "\n"
        )

    if not ok then
        network.lastError =
            tostring(err)

        emit(
            "error",
            network.lastError
        )

        return false, err
    end

    return true
end

-- パケット送信
function network.send(typeName, ...)
    if type(typeName) ~= "string"
        or typeName == "" then

        return false, "パケット不正"
    end

    local packet = typeName

    for _, value in ipairs({...}) do
        value = tostring(value)

        value = value
            :gsub("|", "")
            :gsub("[\r\n]", "")

        packet =
            packet .. "|" .. value
    end

    return rawSend(packet)
end

-- 接続設定
local function setConnected(remotePlayerID)
    network.remotePlayerID =
        remotePlayerID

    network.connected = true

    connectionStartTime = 0
    handshakeStartTime = 0

    network.lastPingTime =
        socket.gettime()

    pendingPing = nil

    emit(
        "connected",
        network.remotePlayerID
    )
end

-- パケット処理
local function processPacket(packet)
    if type(packet) ~= "string"
        or packet == "" then
        return
    end

    local parts =
        split(packet, "|")

    local typeName =
        parts[1]

    if not typeName then
        return
    end

    -- HELLO
    if typeName == "HELLO" then
        local remoteID = parts[2]
        local version =
            tonumber(parts[3])

        if not remoteID then
            setError("HELLO不正")
            network.close(false)
            return
        end

        if version ~= network.VERSION then
            network.send(
                "ERROR",
                "VERSION_MISMATCH"
            )

            setError("バージョン不一致")
            network.close(false)
            return
        end

        network.remotePlayerID =
            remoteID

        local ok, err =
            network.send(
                "WELCOME",
                network.playerID,
                network.VERSION
            )

        if not ok then
            setError(err)
            network.close(false)
            return
        end

        if not network.connected then
            setConnected(remoteID)
        end

        emit(
            "player_join",
            remoteID
        )

        return
    end

    -- WELCOME
    if typeName == "WELCOME" then
        local remoteID = parts[2]
        local version =
            tonumber(parts[3])

        if not remoteID then
            setError("WELCOME不正")
            network.close(false)
            return
        end

        if version ~= network.VERSION then
            setError("バージョン不一致")
            network.close(false)
            return
        end

        setConnected(remoteID)

        return
    end

    -- PING
    if typeName == "PING" then
        local id = parts[2]

        if id then
            network.send(
                "PONG",
                id
            )
        end

        return
    end

    -- PONG
    if typeName == "PONG" then
        local id = parts[2]

        if pendingPing == id then
            network.ping =
                (
                    socket.gettime()
                    - network.lastPingTime
                ) * 1000

            pendingPing = nil

            emit(
                "ping",
                network.ping
            )
        end

        return
    end

    -- ERROR
    if typeName == "ERROR" then
        local errorCode =
            parts[2] or "UNKNOWN"

        setError(
            "相手エラー: " ..
            errorCode
        )

        return
    end

    -- DISCONNECT
    if typeName == "DISCONNECT" then
        local reason =
            parts[2] or "切断"

        emit(
            "disconnect",
            reason
        )

        network.close(false)

        return
    end

    -- 独自
    emit(
        "packet",
        typeName,
        parts
    )
end

-- ホスト
function network.host()
    network.close(false)

    network.lastError = nil
    network.mode = "host"

    network.playerID =
        generatePlayerID()

    local server, err =
        socket.bind(
            "*",
            network.PORT
        )

    if not server then
        setError(err)

        network.mode = "offline"
        network.playerID = nil

        return false
    end

    server:settimeout(0)

    network.server = server

    handshakeStartTime =
        socket.gettime()

    local roomID =
        network.createRoomID()

    emit(
        "hosting",
        roomID
    )

    return true
end

-- 参加
function network.join(roomID)
    network.close(false)

    local ip, port, err =
        network.parseRoomID(roomID)

    if not ip then
        setError(err)
        return false
    end

    network.lastError = nil
    network.mode = "client"

    network.playerID =
        generatePlayerID()

    local client =
        socket.tcp()

    if not client then
        setError("TCP作成失敗")

        network.mode = "offline"
        return false
    end

    client:settimeout(
        network.connectTimeout
    )

    local ok, connectError =
        client:connect(
            ip,
            port
        )

    if not ok then
        client:close()

        setError(connectError)

        network.mode = "offline"
        network.playerID = nil

        return false
    end

    client:settimeout(0)

    network.peer = client

    connectionStartTime =
        socket.gettime()

    local sent, sendError =
        network.send(
            "HELLO",
            network.playerID,
            network.VERSION
        )

    if not sent then
        setError(sendError)
        network.close(false)
        return false
    end

    return true
end

-- 接続受付
local function acceptClient()
    if not network.server
        or network.peer then
        return
    end

    local client =
        network.server:accept()

    if not client then
        return
    end

    client:settimeout(0)

    network.peer = client

    handshakeStartTime =
        socket.gettime()

    emit("client_connect")
end

-- 受信
local function receivePackets()
    if not network.peer then
        return
    end

    while network.peer do
        local data, err =
            network.peer:receive("*l")

        if data then
            processPacket(data)

        elseif err == "closed" then
            emit(
                "disconnect",
                "接続終了"
            )

            network.close(false)
            break

        elseif err == "timeout" then
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

    -- 接続待ち
    if network.peer
        and not network.connected then

        local now =
            socket.gettime()

        if handshakeStartTime > 0
            and now - handshakeStartTime
                >= network.handshakeTimeout then

            setError(
                "接続タイムアウト"
            )

            emit(
                "disconnect",
                "接続タイムアウト"
            )

            network.close(false)

            return
        end
    end

    -- Ping
    if network.connected then
        local now =
            socket.gettime()

        if now - network.lastPingTime
            >= network.pingInterval then

            local id =
                randomString(8)

            pendingPing = id

            network.lastPingTime = now

            network.send(
                "PING",
                id
            )
        end
    end
end

-- 切断
function network.close(sendDisconnect)
    if sendDisconnect == nil then
        sendDisconnect = true
    end

    if closing then
        return
    end

    closing = true

    -- 通知
    if sendDisconnect
        and network.peer then

        pcall(function()
            network.peer:send(
                "DISCONNECT|close\n"
            )
        end)
    end

    -- Peer
    if network.peer then
        pcall(function()
            network.peer:close()
        end)
    end

    -- Server
    if network.server then
        pcall(function()
            network.server:close()
        end)
    end

    -- リセット
    network.peer = nil
    network.server = nil

    network.connected = false

    network.remotePlayerID = nil

    pendingPing = nil

    network.ping = 0
    network.lastPingTime = 0

    connectionStartTime = 0
    handshakeStartTime = 0

    network.mode = "offline"

    closing = false
end

-- 接続確認
function network.isConnected()
    return network.connected
end

-- Ping取得
function network.getPing()
    return math.floor(
        network.ping + 0.5
    )
end

-- エラー取得
function network.getError()
    return network.lastError
end

-- 自分ID
function network.getPlayerID()
    return network.playerID
end

-- 相手ID
function network.getRemotePlayerID()
    return network.remotePlayerID
end

-- モード取得
function network.getMode()
    return network.mode
end

return network
