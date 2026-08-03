local ffi = require("ffi")
<<<<<<< Updated upstream
=======
local log = require("log")
>>>>>>> Stashed changes

local discordRPC = {}

local function resolveDiscordRpcPath()
    local candidates = {}

    local sourceRoot = love and love.filesystem and love.filesystem.getSource and love.filesystem.getSource()
    if sourceRoot and sourceRoot ~= "" then
        candidates[#candidates + 1] = sourceRoot .. "/lib/plugins/DiscordRPC/Win/discord-rpc.dll"
        candidates[#candidates + 1] = sourceRoot .. "/discord-rpc.dll"
    end

    candidates[#candidates + 1] = "C:/Users/あほ/Documents/GitHub/ShiftLine_sourcecode/lib/plugins/DiscordRPC/Win/discord-rpc.dll"
    candidates[#candidates + 1] = "C:/Users/あほ/Documents/GitHub/ShiftLine_sourcecode/discord-rpc.dll"
    candidates[#candidates + 1] = "C:/discord-rpc.dll"
    candidates[#candidates + 1] = "lib/plugins/DiscordRPC/Win/discord-rpc.dll"

    for _, candidate in ipairs(candidates) do
        local f = io.open(candidate, "rb")
        if f then
            f:close()
            return candidate
        end
    end

    return nil
end

local function loadDiscordRpc()
    local path = resolveDiscordRpcPath()

    log.info("DiscordRPC: trying path " .. tostring(path or "<none>"))
    log.info("DiscordRPC: source = " .. tostring(love and love.filesystem and love.filesystem.getSource and love.filesystem.getSource() or "unknown"))

    if not path then
        log.info("DiscordRPC: DLL not found in any candidate path")
        return nil
    end

    local ok, lib = pcall(ffi.load, path)

    log.info("DiscordRPC: OK = " .. tostring(ok))
    log.info("DiscordRPC: LIB/ERR = " .. tostring(lib))

    if not ok or not lib then
        return nil
    end

    ffi.cdef([[
        ...
    ]])

    return lib
end

local lib = loadDiscordRpc()
if lib then
    discordRPC.lib = lib
end

function discordRPC.initialize(applicationId, autoRegister, optionalSteamId)
    if not discordRPC.lib then
        return false
    end

    local handlers = ffi.new("DiscordEventHandlers")
    handlers.size = ffi.sizeof("DiscordEventHandlers")
    handlers.version = nil

    discordRPC.lib.Discord_Initialize(applicationId, handlers, autoRegister and 1 or 0, optionalSteamId or nil)
    return true
end

function discordRPC.shutdown()
    if discordRPC.lib then
        discordRPC.lib.Discord_Shutdown()
    end
    return true
end

function discordRPC.runCallbacks()
    if discordRPC.lib then
        discordRPC.lib.Discord_RunCallbacks()
    end
    return true
end

function discordRPC.updatePresence(presence)
    if not discordRPC.lib or type(presence) ~= "table" then
        return false
    end

    local rp = ffi.new("DiscordRichPresence")
    rp.state = presence.state and tostring(presence.state) or nil
    rp.details = presence.details and tostring(presence.details) or nil
    rp.startTimestamp = presence.startTimestamp or 0
    rp.endTimestamp = presence.endTimestamp or 0
    rp.largeImageKey = presence.largeImageKey and tostring(presence.largeImageKey) or nil
    rp.largeImageText = presence.largeImageText and tostring(presence.largeImageText) or nil
    rp.smallImageKey = presence.smallImageKey and tostring(presence.smallImageKey) or nil
    rp.smallImageText = presence.smallImageText and tostring(presence.smallImageText) or nil
    rp.partyId = presence.partyId and tostring(presence.partyId) or nil
    rp.partySize = presence.partySize or 0
    rp.partyMax = presence.partyMax or 0
    rp.matchSecret = presence.matchSecret and tostring(presence.matchSecret) or nil
    rp.joinSecret = presence.joinSecret and tostring(presence.joinSecret) or nil
    rp.spectateSecret = presence.spectateSecret and tostring(presence.spectateSecret) or nil
    rp.instance = presence.instance and 1 or 0

    discordRPC.lib.Discord_UpdatePresence(rp)
    return true
end

function discordRPC.clearPresence()
    if discordRPC.lib then
        discordRPC.lib.Discord_ClearPresence()
    end
    return true
end

function discordRPC.respond(userId, reply)
    if discordRPC.lib then
        discordRPC.lib.Discord_Respond(userId, reply)
    end
    return true
end

return discordRPC
