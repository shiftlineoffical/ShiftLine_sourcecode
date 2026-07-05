local ffi = require("ffi")

local discordRPC = {}

local function loadDiscordRpc()
    local ok, lib = pcall(ffi.load, "discord-rpc")
    if not ok or not lib then
        return nil
    end

    ffi.cdef([[
        typedef struct { const char* state; const char* details; int64_t startTimestamp; int64_t endTimestamp; const char* largeImageKey; const char* largeImageText; const char* smallImageKey; const char* smallImageText; const char* partyId; int partySize; int partyMax; const char* matchSecret; const char* joinSecret; const char* spectateSecret; const char* instance; } DiscordRichPresence;
        typedef struct { int size; const char* version; } DiscordEventHandlers;
        void Discord_Initialize(const char* applicationId, DiscordEventHandlers* handlers, int autoRegister, const char* optionalSteamId);
        void Discord_Shutdown(void);
        void Discord_RunCallbacks(void);
        void Discord_UpdatePresence(const DiscordRichPresence* presence);
        void Discord_ClearPresence(void);
        void Discord_Respond(const char* userId, const char* reply);
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
