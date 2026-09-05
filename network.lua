local socket = require("socket")
local okHttp, http = pcall(require, "socket.http")
if not okHttp then
    http = nil
end

local network = {}

network.PORT = 12345
network.mode = "offline"

network.peer = nil
network.connected = false

network.playerID = nil
network.remotePlayerID = nil
network.roomID = nil
network.partyPlayers = {}

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

local BASE64 =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ" ..
    "abcdefghijklmnopqrstuvwxyz" ..
    "0123456789+/"

-- 乱数文字列を作る
local function randomString(length)
    local result = {}

    for i = 1, length do
        local index = math.random(1, #CHARS)
        result = result .. CHARS:sub(index, index)
    end

    return table.concat(result)
end

-- イベントを発火する
local function emit(event, ...)
    local list =
        network.handlers[event]

    if not list then
        return
    end

    for _, callback in ipairs(list) do
        local ok, err =
            pcall(callback, ...)

        if not ok then
            network.lastError =
                tostring(err)
        end
    end
end

-- エラーを設定する
local function setError(message)
    network.lastError =
        tostring(message or "不明なエラー")

    networkLog("error", network.lastError)

    emit(
        "error",
        network.lastError
    )
end

local function isWouldBlockError(message)
    return message == "timeout"
        or message == "wantread"
        or message == "wantwrite"
end

local function resetPartyPlayers()
    network.partyPlayers = {}
end

local function addPartyPlayer(playerID)
    if type(playerID) == "string" and playerID ~= "" then
        network.partyPlayers[playerID] = true
    end
end

local function removePartyPlayer(playerID)
    if type(playerID) == "string" then
        network.partyPlayers[playerID] = nil
    end
end

-- イベントハンドラを登録する
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

-- プレイヤーIDを生成する
local function generatePlayerID()
    return randomString(8)
end

-- 区切り文字で分割する
local function split(str, separator)
    local result = {}

    for value in string.gmatch(str, "([^" .. separator .. "]+)") do
        result[#result + 1] = value
    end

    if separator == "" then
        result[1] = str
        return result
    end

    local start = 1

    while true do
        local position =
            str:find(
                separator,
                start,
                true
            )

        if not position then
            result[#result + 1] =
                str:sub(start)

            break
        end

        result[#result + 1] =
            str:sub(
                start,
                position - 1
            )

        start =
            position + #separator
    end

    return result
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

-- フレームを送信する
local function sendRawFrame(payload, opcode)
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

-- WebSocketハンドシェイクを行う
local function websocketHandshake()
    local key =
        websocketKey()

    networkLog(
        "info",
        "Starting WebSocket handshake",
        wsHost .. ":" .. tostring(wsPort),
        wsPath
    )

    local request =
        "GET " ..
        wsPath ..
        " HTTP/1.1\r\n" ..

        "Host: " ..
        wsHost .. "\r\n" ..

        "Upgrade: websocket\r\n" ..

        "Connection: Upgrade\r\n" ..

        "Sec-WebSocket-Key: " ..
        key .. "\r\n" ..

        "Sec-WebSocket-Version: 13\r\n" ..

        "\r\n"

    local sent, err =
        network.peer:send(request)

    if not sent then
        networkLog("error", "WebSocket handshake request failed", tostring(err))
        return false, err
    end

    networkLog("debug", "WebSocket handshake request sent", "bytes=" .. tostring(#request))

    local buffer = ""

    local start =
        socket.gettime()

    while
        socket.gettime() - start <
        network.handshakeTimeout
    do

        local data,
            receiveError,
            partial =
            network.peer:receive(4096)

        if data then

            buffer =
                buffer .. data

            networkLog("debug", "Handshake response data received", "bytes=" .. tostring(#data))

        elseif partial
            and #partial > 0 then

            buffer =
                buffer .. partial

            networkLog("debug", "Handshake response partial data received", "bytes=" .. tostring(#partial), "error=" .. tostring(receiveError))

        elseif isWouldBlockError(receiveError) then

            socket.sleep(0.01)

        else

            networkLog("error", "Handshake response receive failed", tostring(receiveError))

            return false,
                receiveError
        end

        local headerEnd =
            buffer:find(
                "\r\n\r\n",
                1,
                true
            )

        if headerEnd then
            break
        end
    end

    local headerEnd =
        buffer:find(
            "\r\n\r\n",
            1,
            true
        )

    if not headerEnd then
        networkLog("error", "WebSocket handshake timed out", "bytes=" .. tostring(#buffer))
        return false,
            "WebSocketハンドシェイクタイムアウト"
    end

    local header =
        buffer:sub(
            1,
            headerEnd + 3
        )

    local remaining =
        buffer:sub(
            headerEnd + 4
        )

    receiveBuffer =
        remaining

    local status =
        header:match(
            "^HTTP/%d%.%d%s+(%d+)"
        )

    if tonumber(status) ~= 101 then
        networkLog("error", "WebSocket handshake rejected", "status=" .. tostring(status))
        return false,
            "WebSocket接続拒否: " ..
            tostring(status)
    end

    local upgrade =
        header:match(
            "[Uu]pgrade:%s*([^\r\n]+)"
        )

    if not upgrade
        or upgrade:lower() ~= "websocket" then

        networkLog("error", "Invalid Upgrade header", tostring(upgrade))

        return false,
            "Upgradeヘッダー不正"
    end

    local connection =
        header:match(
            "[Cc]onnection:%s*([^\r\n]+)"
        )

    if not connection
        or not connection:lower():find(
            "upgrade",
            1,
            true
        ) then

        networkLog("error", "Invalid Connection header", tostring(connection))

        return false,
            "Connectionヘッダー不正"
    end

    local accept =
        header:match(
            "[Ss]ec%-[Ww]eb[Ss]ocket%-[Aa]ccept:%s*([^\r\n]+)"
        )

    if not accept then
        networkLog("error", "Missing Sec-WebSocket-Accept header")
        return false,
            "Sec-WebSocket-Acceptがありません"
    end

    local expected =
        base64Encode(
            sha1(
                key ..
                "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
            )
        )

    if accept:gsub(
        "%s+$",
        ""
    ) ~= expected then

        networkLog("error", "Invalid Sec-WebSocket-Accept header")

        return false,
            "Sec-WebSocket-Accept不正"
    end

    networkLog("info", "WebSocket handshake completed", "bufferedBytes=" .. tostring(#receiveBuffer))

    return true
end

-- TCPとTLSを接続する
local function connectWebSocket(url, roomID)
    local secure,
        host,
        port,
        path =
        parseURL(url)

    if secure == nil then
        networkLog("error", "Invalid WebSocket URL", tostring(url))
        return nil,
            "WebSocket URL不正"
    end

    networkLog(
        "info",
        "Connecting",
        (secure and "TLS" or "TCP"),
        host .. ":" .. tostring(port),
        "room=" .. tostring(roomID),
        "player=" .. tostring(network.playerID)
    )

    local start =
        socket.gettime()

    path =
        path ..
        "?room=" ..
        urlEncode(roomID) ..
        "&player=" ..
        urlEncode(network.playerID)

    local tcp =
        socket.tcp()

    if not tcp then
        networkLog("error", "TCP socket creation failed")
        return nil,
            "TCPソケット作成失敗"
    end

    tcp:settimeout(
        network.connectTimeout
    )

    local ok, err =
        tcp:connect(
            host,
            port
        )

    if not ok then
        networkLog("error", "TCP connection failed", tostring(err))
        tcp:close()
        return nil, err
    end

    networkLog("info", "TCP connection established", "elapsed=" .. tostring(socket.gettime() - start))

    if socket.gettime() - start >=
        network.connectTimeout then

        tcp:close()

        return nil,
            "TCP接続タイムアウト"
    end

    if secure then

        if not ssl then
            networkLog("error", "LuaSec unavailable", tostring(sslLoadError))
            return nil,
                "LuaSecが見つかりません。使用OS用のssl.luaとネイティブライブラリ(.dll/.so/.dylib)をLÖVEのゲームフォルダに配置してください: " .. tostring(sslLoadError)
        end

        local params = {
            mode = "client",

            protocol = "any",

            verify = "none",

            options = "all",

            server = host
        }

        local wrapped,
            wrapError =
            ssl.wrap(
                tcp,
                params
            )

        if not wrapped then
            networkLog("error", "TLS socket wrapping failed", tostring(wrapError))
            tcp:close()

            return nil,
                wrapError
        end

        tcp = wrapped

        local sniOK,
            sniError =
            pcall(function()
                tcp:sni(host)
            end)

        if not sniOK then
            networkLog("error", "TLS SNI setup failed", tostring(sniError))
            tcp:close()

            return nil,
                tostring(sniError or "SNI設定失敗")
        end

        networkLog("debug", "TLS SNI configured", host)

        tcp:settimeout(
            network.connectTimeout
        )

        local handshakeOK,
            handshakeError =
            tcp:dohandshake()

        if not handshakeOK then
            networkLog("error", "TLS handshake failed", tostring(handshakeError))
            tcp:close()

            return nil,
                handshakeError
        end

        networkLog("info", "TLS handshake completed", host)
    end

    tcp:settimeout(0)

    network.peer = tcp

    wsHost = host
    wsPort = port
    wsPath = path
    wsSecure = secure

    receiveBuffer = ""

    fragmentedOpcode = nil
    fragmentedPayload = {}

    local handshakeOK,
        handshakeError =
        websocketHandshake()

    if not handshakeOK then

        networkLog("error", "WebSocket handshake failed", tostring(handshakeError))

        pcall(function()
            tcp:close()
        end)

        network.peer = nil

        return nil,
            handshakeError
    end

    networkLog("info", "WebSocket connection ready", host .. ":" .. tostring(port))

    return true
end

-- パケットを送信する
local function sendPacket(packet)
    return sendRawFrame(
        packet,
        1
    )
end

-- ゲームパケットを送信する
function network.send(typeName, ...)
    local packet = typeName

    for _, value in ipairs({...}) do
        value = tostring(value):gsub("|", "")
        packet = packet .. "|" .. value
    end

    return sendPacket(packet)
end

-- 接続完了状態にする
local function setConnected(remotePlayerID)
    network.remotePlayerID =
        remotePlayerID

    resetPartyPlayers()
    addPartyPlayer(network.playerID)
    addPartyPlayer(remotePlayerID)

    network.connected = true

    connectionStartTime = 0
    handshakeStartTime = 0

    network.lastPingTime =
        socket.gettime()

    pendingPing = nil
    pingTimes = {}

    emit(
        "connected",
        network.remotePlayerID
    )
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

-- 完成したアプリケーションメッセージを処理する
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

    -- PING
    if typeName == "PING" then
        network.send("PONG", parts[2])
        return
    end

    -- PONG
    if typeName == "PONG" then

        local id =
            parts[2]

        local start =
            pingTimes[id]

        if start then

            network.ping =
                (socket.gettime() - network.lastPingTime) * 1000

            pingTimes[id] =
                nil

            if pendingPing == id then
                pendingPing = nil
            end

            emit(
                "ping",
                network.ping
            )
        end

        return
    end

    if typeName == "ERROR" then

        local errorCode =
            parts[2] or "UNKNOWN"

        setError(
            "サーバーエラー: " ..
            errorCode
        )

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
        emit(
            "disconnect",
            reason
        )

        network.close(false)

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

-- 受信データを処理する
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

        elseif err == "closed" then

            networkLog("warn", "Socket closed by peer")

            emit(
                "disconnect",
                "接続終了"
            )

            network.close(false)

            return

        else
            networkLog("error", "Socket receive failed", tostring(err))
            break
        end

        if not processBufferedFrames() then
            return
        end
    end
end

-- RoomIDを作成する
function network.createRoomID(int)
    return randomString(int or 10)
end

-- 外部RoomIDを作成する
function network.createExternalRoomID()
    return network.createRoomID()
end

-- RoomIDを検証する
function network.parseRoomID(roomID)
    if type(roomID) ~= "string" then
        return nil,
            nil,
            "RoomID不正"
    end

    roomID =
        roomID:match(
            "^%s*(.-)%s*$"
        )

    if roomID == "" then
        return nil,
            nil,
            "RoomID不正"
    end

    if not roomID:match(
        "^[A-Za-z0-9]+$"
    ) then
        return nil,
            nil,
            "RoomID不正"
    end

    if #roomID > 64 then
        return nil,
            nil,
            "RoomIDが長すぎます"
    end

    return roomID
end

-- ホストとして接続する
function network.host()
    networkLog("info", "Host connection requested")

    network.close(false)

    network.lastError = nil

    network.mode = "host"

    network.playerID =
        generatePlayerID()

    local roomID =
        network.createRoomID()

    connectionStartTime =
        socket.gettime()

    local ok, err =
        connectWebSocket(
            network.SERVER_URL,
            roomID
        )

    if not ok then

        networkLog("error", "Host connection failed", tostring(err))

        setError(err)

        network.mode =
            "offline"

        network.playerID =
            nil

        return false
    end

    handshakeStartTime =
        socket.gettime()

    network.roomID =
        roomID

    emit(
        "hosting",
        roomID
    )

    networkLog("info", "Host connection initialized", "room=" .. tostring(roomID))

    return true
end

-- Roomに参加する
function network.join(roomID)
    networkLog("info", "Join connection requested", "room=" .. tostring(roomID))

    network.close(false)

    local parsedRoomID,
        _,
        err =
        network.parseRoomID(
            roomID
        )

    if not parsedRoomID then
        setError(err)

        return false
    end

    network.lastError = nil

    network.mode = "client"

    network.playerID =
        generatePlayerID()

    connectionStartTime =
        socket.gettime()

    local ok,
        connectError =
        connectWebSocket(
            network.SERVER_URL,
            parsedRoomID
        )

    if not ok then

        networkLog("error", "Join connection failed", tostring(connectError))

        setError(
            connectError
        )

        network.mode =
            "offline"

        network.playerID =
            nil

        return false
    end

    handshakeStartTime =
        socket.gettime()

    network.roomID =
        parsedRoomID

    networkLog("info", "Join connection initialized", "room=" .. tostring(parsedRoomID))

    return true
end

-- ネットワークを更新する
function network.update()
    if network.peer then
        receivePackets()
    end

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

    -- Peer
    if network.peer then
        pcall(function()

            sendRawFrame(
                "DISCONNECT",
                1
            )

            sendRawFrame(
                "",
                8
            )

        end)
    end

    if network.server then
        pcall(function()
            network.peer:close()
        end)

    end

    -- リセット
    network.peer = nil
    network.server = nil
    network.connected = false

    network.remotePlayerID = nil
    pendingPing = nil
    network.mode = "offline"
end
end

-- 接続状態を取得する
function network.isConnected()
    return network.connected
end

-- Pingを取得する
function network.getPing()
    return math.floor(
        network.ping + 0.5
    )
end

-- エラーを取得する
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
