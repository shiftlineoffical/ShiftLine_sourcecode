local secureloader = {}

local MAGIC = "SLP2"
local VERSION = 1


local MASTER_PASSWORD =
    "ぐらはむくんは意外と頭がよかった"


local MASTER_KEY = nil
local PACK_LOADED = false
local INSTALLED = false

local files = {}


local function sha256(data)
    return love.data.hash(
        "sha256",
        data
    )
end


local function xor_byte_string(
    data,
    value
)
    local result = {}

    for i = 1, #data do
        result[i] =
            string.char(
                bit.bxor(
                    data:byte(i),
                    value
                )
            )
    end

    return table.concat(result)
end

local function hmac_sha256(
    key,
    message
)
    local BLOCK_SIZE = 64

    if #key > BLOCK_SIZE then
        key = sha256(key)
    end

    if #key < BLOCK_SIZE then
        key =
            key ..
            string.rep(
                "\0",
                BLOCK_SIZE - #key
            )
    end

    local ipad =
        xor_byte_string(
            key,
            0x36
        )

    local opad =
        xor_byte_string(
            key,
            0x5c
        )

    local inner =
        sha256(
            ipad .. message
        )

    return sha256(
        opad .. inner
    )
end


local function create_master_key()
    MASTER_KEY =
        sha256(
            MASTER_PASSWORD
        )
end


local function u16le(value)
    local b1 =
        value % 256

    local b2 =
        math.floor(
            value / 256
        ) % 256

    return string.char(
        b1,
        b2
    )
end

local function u32le(value)
    local b1 =
        value % 256

    local b2 =
        math.floor(
            value / 256
        ) % 256

    local b3 =
        math.floor(
            value / 65536
        ) % 256

    local b4 =
        math.floor(
            value / 16777216
        ) % 256

    return string.char(
        b1,
        b2,
        b3,
        b4
    )
end

local function u64le(value)
    local low =
        value % 4294967296

    local high =
        math.floor(
            value / 4294967296
        )

    return
        u32le(low) ..
        u32le(high)
end


local function read_u8(
    data,
    position
)
    local value =
        data:byte(position)

    if not value then
        error(
            "luapackの読み込み中にEOFになりました。"
        )
    end

    return
        value,
        position + 1
end

local function read_u16le(
    data,
    position
)
    if position + 1 > #data then
        error(
            "u16の読み込みに失敗しました。"
        )
    end

    local a =
        data:byte(position)

    local b =
        data:byte(position + 1)

    return
        a + b * 256,
        position + 2
end

local function read_u32le(
    data,
    position
)
    if position + 3 > #data then
        error(
            "u32の読み込みに失敗しました。"
        )
    end

    local a =
        data:byte(position)

    local b =
        data:byte(position + 1)

    local c =
        data:byte(position + 2)

    local d =
        data:byte(position + 3)

    return
        a +
        b * 256 +
        c * 65536 +
        d * 16777216,
        position + 4
end

local function read_u64le(
    data,
    position
)
    local low

    low,
    position =
        read_u32le(
            data,
            position
        )

    local high

    high,
    position =
        read_u32le(
            data,
            position
        )

    return
        low +
        high * 4294967296,
        position
end

local function read_bytes(
    data,
    position,
    count
)
    local finish =
        position + count - 1

    if finish > #data then
        error(
            "luapackのデータが途中で終了しています。"
        )
    end

    return
        data:sub(
            position,
            finish
        ),
        finish + 1
end


local function constant_time_equal(
    a,
    b
)
    if #a ~= #b then
        return false
    end

    local result = 0

    for i = 1, #a do
        result =
            bit.bor(
                result,
                bit.bxor(
                    a:byte(i),
                    b:byte(i)
                )
            )
    end

    return result == 0
end


local function create_keystream_block(
    nonce,
    file_index,
    field_type,
    counter
)
    local message =
        "SLP2-STREAM" ..
        nonce ..
        u32le(file_index) ..
        string.char(field_type) ..
        u64le(counter)

    return
        hmac_sha256(
            MASTER_KEY,
            message
        )
end


local function crypt_field(
    data,
    nonce,
    file_index,
    field_type
)
    local result = {}

    local position = 1
    local counter = 0

    while position <= #data do

        local stream =
            create_keystream_block(
                nonce,
                file_index,
                field_type,
                counter
            )

        local remaining =
            #data - position + 1

        local count =
            math.min(
                #stream,
                remaining
            )

        local source =
            data:sub(
                position,
                position + count - 1
            )

        local output = {}

        for i = 1, count do
            output[i] =
                string.char(
                    bit.bxor(
                        source:byte(i),
                        stream:byte(i)
                    )
                )
        end

        result[#result + 1] =
            table.concat(output)

        position =
            position + count

        counter =
            counter + 1
    end

    return table.concat(result)
end

local function decrypt_field(
    data,
    nonce,
    file_index,
    field_type
)
    return crypt_field(
        data,
        nonce,
        file_index,
        field_type
    )
end

local function normalize_path(
    path
)
    path =
        path:gsub(
            "\\",
            "/"
        )

    if path == "" then
        return nil
    end

    if path:sub(1, 1) == "/" then
        return nil
    end

    if path:match(
        "^%a:/"
    ) then
        return nil
    end

    for part in path:gmatch(
        "[^/]+"
    ) do
        if part == ".." then
            return nil
        end
    end

    return path
end


local function load_pack()
    local data, size =
        love.filesystem.read(
            "ShiftLine.luapack"
        )

    if not data then
        error(
            "ShiftLine.luapackを読み込めませんでした。"
        )
    end

    if #data < 32 then
        error(
            "ShiftLine.luapackが小さすぎます。"
        )
    end

    -- 最後の32byteがHMAC
    local payload =
        data:sub(
            1,
            #data - 32
        )

    local stored_mac =
        data:sub(
            #data - 31,
            #data
        )

    -- C#と同じHMAC
    local calculated_mac =
        hmac_sha256(
            MASTER_KEY,
            payload
        )

    if not constant_time_equal(
        stored_mac,
        calculated_mac
    ) then
        error(
            "ShiftLine.luapackのHMAC検証に失敗しました。\n" ..
            "鍵が違うか、ファイルが破損しています。"
        )
    end

    local position = 1


    local magic

    magic,
    position =
        read_bytes(
            payload,
            position,
            4
        )

    if magic ~= MAGIC then
        error(
            "未知のluapack形式です。"
        )
    end


    local version

    version,
    position =
        read_u8(
            payload,
            position
        )

    if version ~= VERSION then
        error(
            "対応していないluapackバージョンです: "
            .. tostring(version)
        )
    end

    -- reserved
    position =
        position + 1

    -- flags
    local flags

    flags,
    position =
        read_u16le(
            payload,
            position
        )


    local file_count

    file_count,
    position =
        read_u32le(
            payload,
            position
        )


    local nonce

    nonce,
    position =
        read_bytes(
            payload,
            position,
            32
        )


    files = {}

    for index = 0,
        file_count - 1 do


        local encrypted_path_length

        encrypted_path_length,
        position =
            read_u32le(
                payload,
                position
            )

        if encrypted_path_length > 16777216 then
            error(
                "ファイル名が異常に大きいです。"
            )
        end

        local encrypted_path

        encrypted_path,
        position =
            read_bytes(
                payload,
                position,
                encrypted_path_length
            )

        local original_size

        original_size,
        position =
            read_u64le(
                payload,
                position
            )


        local encrypted_data_length

        encrypted_data_length,
        position =
            read_u32le(
                payload,
                position
            )

        local encrypted_data

        encrypted_data,
        position =
            read_bytes(
                payload,
                position,
                encrypted_data_length
            )


        local path_bytes =
            decrypt_field(
                encrypted_path,
                nonce,
                index,
                1
            )

        local path =
            normalize_path(
                path_bytes
            )

        if not path then
            error(
                "luapack内に不正なパスがあります。"
            )
        end

        local lua_source =
            decrypt_field(
                encrypted_data,
                nonce,
                index,
                2
            )

        if #lua_source ~= original_size then
            error(
                "Luaデータのサイズが一致しません: "
                .. path
            )
        end


        if files[path] ~= nil then
            error(
                "同じLuaファイルが複数あります: "
                .. path
            )
        end

        files[path] =
            lua_source
    end

    PACK_LOADED = true
end


local function find_file(
    name
)
    name =
        name:gsub(
            "\\",
            "/"
        )

    local source =
        files[name]

    if source then
        return source
    end

    if not name:match(
        "%.lua$"
    ) then
        source =
            files[
                name .. ".lua"
            ]

        if source then
            return source
        end
    end

    return nil
end


local function compile_source(
    source,
    filename
)
    local chunk, error_message =
        load(
            source,
            "@" .. filename,
            "t",
            _G
        )

    if not chunk then
        error(
            error_message
        )
    end

    return chunk
end


local function packed_searcher(
    module_name
)
    local path =
        module_name:gsub(
            "%.",
            "/"
        )

    local source =
        find_file(
            path
        )

    if not source then
        return nil
    end

    local chunk, error_message =
        compile_source(
            source,
            path .. ".lua"
        )

    if not chunk then
        return function()
            error(
                error_message
            )
        end
    end

    return chunk
end


function secureloader.load(
    name
)
    if not PACK_LOADED then
        error(
            "secureloader.install()が実行されていません。"
        )
    end

    local path =
        name:gsub(
            "\\",
            "/"
        )

    if not path:match(
        "%.lua$"
    ) then
        path =
            path .. ".lua"
    end

    local source =
        find_file(
            path
        )

    if not source then
        error(
            "luapack内にLuaがありません: "
            .. path
        )
    end

    local chunk =
        compile_source(
            source,
            path
        )

    return chunk()
end


function secureloader.execute_main()
    if not PACK_LOADED then
        error(
            "secureloader.install()が実行されていません。"
        )
    end

    local source =
        find_file(
            "main.lua"
        )

    if not source then
        error(
            "ShiftLine.luapack内にmain.luaがありません。"
        )
    end

    local chunk =
        compile_source(
            source,
            "main.lua"
        )


    return chunk()
end


function secureloader.install()
    if INSTALLED then
        return
    end

    create_master_key()

    load_pack()


    local searchers =
        package.searchers

    if not searchers then
        searchers =
            package.loaders
    end

    if not searchers then
        error(
            "package.searchers / package.loadersがありません。"
        )
    end

    table.insert(
        searchers,
        1,
        packed_searcher
    )

    INSTALLED = true
end


function secureloader.is_loaded()
    return PACK_LOADED
end

function secureloader.exists(
    name
)
    if not PACK_LOADED then
        return false
    end

    if files[name] then
        return true
    end

    if not name:match(
        "%.lua$"
    ) then
        return files[
            name .. ".lua"
        ] ~= nil
    end

    return false
end

return secureloader