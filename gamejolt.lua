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

local gamejolt = {}
local gamejoltuserdata={

    userid="",
    username="",
    user_token=""
}
local gamejolt=require "lib.plugins.gamejolt.gamejolt_api"
local gamejoltuser=require "gamejoltuser"
local log = require "log"
local JSON = require "JSON"

-- 迥ｶ諷九ｒ螟夜Κ縺九ｉ蜿ら・縺ｧ縺阪ｋ繧医≧縺ｫ縺吶ｋ
gamejolt.status = {
    authenticated = false,
    message = "",
    username = "",
    userId = "",
    avatarUrl = "",
}

local userdata={}
local useravaterurl=""
local userid=""


local function updateStatus(authenticated, message)
    gamejolt.status.authenticated = authenticated
    gamejolt.status.message = message
end


local function connection(force)
    if not force and gamejoltuser.autologin ~= true then
        updateStatus(false, "auto-login disabled")
        gamejolt.status.username = ""
        gamejolt.status.userId = ""
        gamejolt.status.avatarUrl = ""
        return false
    end

    if not (gamejoltuser.userid and gamejoltuser.user_token) or gamejoltuser.userid == "" then
        updateStatus(false, "GameJoltのユーザー情報が未設定です")
        return false
    end

    gamejoltuserdata.userid = gamejoltuser.userid
    gamejoltuserdata.user_token = gamejoltuser.user_token

    -- 蠢・★2蠑墓焚縺ｧ蛻晄悄蛹・
    gamejolt:init(1053992, "d9b3bdca24c8156fe10c485bdc827a25")

    -- 隱崎ｨｼ
    local auth_success = gamejolt:users_auth(gamejoltuserdata.userid, gamejoltuserdata.user_token)

    if auth_success == "true" then
        log.info("GameJolt authentication successful.: " .. gamejoltuserdata.userid)
        updateStatus(true, "隱崎ｨｼ謌仙粥")

        -- 隱崎ｨｼ謌仙粥蠕後↓繧ｻ繝・す繝ｧ繝ｳ髢句ｧ・
        local session = gamejolt:sessions_open()
        if session and session.success == "true" then
            log.info("GameJolt connection successful")
            updateStatus(true, "GameJolt接続に成功しました")
        else
            updateStatus(true, "隱崎ｨｼ謌仙粥 (繧ｻ繝・す繝ｧ繝ｳ髢句ｧ句､ｱ謨・")
        end

        -- 繝ｦ繝ｼ繧ｶ繝ｼ諠・ｱ隱ｭ縺ｿ蜿悶ｊ (userID 蜿門ｾ・-> users_fetch_uid 縺ｧ蜀榊叙蠕・
        local okUn, userdata_uname = pcall(function() return gamejolt:users_fetch_uname(gamejoltuserdata.userid) end)
        if okUn and userdata_uname and userdata_uname.users and userdata_uname.users[1] then
            local fetched = userdata_uname.users[1]
            local fetchedId = fetched.id
            gamejolt.status.userId = fetchedId or ""

            local okUid, userdata_uid = pcall(function() return gamejolt:users_fetch_uid(fetchedId) end)
            if okUid and userdata_uid and userdata_uid.users and userdata_uid.users[1] then
                local user = userdata_uid.users[1]
                gamejolt.status.username = user.username or fetched.username or gamejoltuserdata.userid
                gamejolt.status.avatarUrl = user.avatar_url or fetched.avatar_url or ""
            else
                gamejolt.status.username = fetched.username or gamejoltuserdata.userid
                gamejolt.status.avatarUrl = fetched.avatar_url or ""
            end
        else
            gamejolt.status.username = gamejoltuserdata.userid
            gamejolt.status.userId = ""
            gamejolt.status.avatarUrl = ""
        end

    else
        log.warn("GameJolt authentication failed.")
        updateStatus(false, "GameJolt認証に失敗しました")
        gamejolt.status.username = ""
        gamejolt.status.userId = ""
        gamejolt.status.avatarUrl = ""
    end

    return gamejolt.status.authenticated
end

function gamejolt.submitScore(scoreValue, sortValue, extraData, tableId)
    if not gamejolt.status.authenticated then
        return false, "not authenticated"
    end

    local score = tostring(scoreValue or 0)
    local sort = tostring(sortValue or scoreValue or 0)
    local ok, response = pcall(function()
        return gamejolt:scores_add(score, sort, nil, extraData, tableId)
    end)

    if not ok or not response or response.success ~= "true" then
        log.warn("GameJolt score submit failed: " .. tostring(response and response.message or response or "unknown"))
        return false, response
    end

    log.info("GameJolt score submitted: " .. score)
    return true, response
end

local function saveLocalJson(filename, data)
    if not love or not love.filesystem or not love.filesystem.write then
        return false, "love.filesystem unavailable"
    end

    local okEncode, raw = pcall(function()
        return JSON:encode(data or {})
    end)
    if not okEncode or type(raw) ~= "string" then
        return false, "json encode failed"
    end

    local okWrite, wrote = pcall(love.filesystem.write, filename, raw)
    if okWrite == true and wrote ~= nil then
        return true, "local saved"
    end

    return false, "local write failed"
end

function gamejolt.saveSettings(settingsTable, key)
    if not gamejolt.status.authenticated then
        return false, "not authenticated"
    end

    local dataKey = tostring(key or "settings")
    local dataValue = JSON:encode(settingsTable or {})

    local ok, response = pcall(function()
        return gamejolt:data_store_local_set(dataKey, dataValue)
    end)

    if not ok or not response or response.success ~= "true" then
        log.warn("GameJolt settings save failed: " .. tostring(response and response.message or response or "unknown"))
        return false, response
    end

    log.info("GameJolt settings saved: " .. dataKey)
    return true, response
end

function gamejolt.savePlayerStats(statsTable, key, localFilename)
    local payload = statsTable or {}
    local filename = tostring(localFilename or "player_stats.json")

    if gamejolt.status.authenticated then
        local dataKey = tostring(key or "player_stats")
        local dataValue = JSON:encode(payload)

        local ok, response = pcall(function()
            return gamejolt:data_store_local_set(dataKey, dataValue)
        end)

        if not ok or not response or response.success ~= "true" then
            log.warn("GameJolt player stats save failed: " .. tostring(response and response.message or response or "unknown"))
            return false, response
        end

        log.info("GameJolt player stats saved: " .. dataKey)
        return true, response
    end

    local ok, err = saveLocalJson(filename, payload)
    if ok then
        log.info("Local player stats saved: " .. filename)
        return true, { success = "local", message = filename }
    end

    log.warn("Local player stats save failed: " .. tostring(err))
    return false, err
end

function gamejolt.login(username, token)
    gamejoltuser.userid = username or ""
    gamejoltuser.user_token = token or ""

    return connection(true)
end


function gamejolt.load(useravaterurl,userid)
    connection(false)
end


function session()
    -- 譌｢縺ｫ繧ｻ繝・す繝ｧ繝ｳ遒ｺ遶区ｸ医∩縺ｪ繧我ｽ輔ｂ縺励↑縺・
    if gamejolt.status.authenticated then
        return
    end
end


function gamejolt.quit()
    -- 繧ｻ繝・す繝ｧ繝ｳ縺碁幕縺・※縺・◆繧蛾哩縺倥ｋ
    if gamejolt and gamejolt.sessions_close then
        pcall(function() gamejolt:sessions_close() end)
    end
end


return gamejolt


