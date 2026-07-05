local audiocache = {}

local function ensureAudioCache(collections)
    if type(collections) ~= "table" then
        return nil
    end

    local cache = rawget(collections, "_runtimeAudioCache")
    if type(cache) ~= "table" then
        cache = {}
        collections._runtimeAudioCache = cache
    end
    return cache
end

local function getEntryPath(entry)
    if type(entry) == "table" then
        if type(entry.sourcePath) == "string" and entry.sourcePath ~= "" then
            return entry.sourcePath
        end
        if type(entry.name) == "string" and entry.name ~= "" and type(entry.data) ~= "string" then
            return entry.name
        end
        return nil
    end

    if type(entry) == "string" and entry ~= "" then
        return entry
    end

    return nil
end

function audiocache.getEntryKey(entry)
    if type(entry) == "table" then
        local cachedKey = rawget(entry, "_audioCacheKey")
        if type(cachedKey) == "string" and cachedKey ~= "" then
            return cachedKey
        end

        local key = nil
        local archive = tostring(entry.archive or "")
        if type(entry.data) == "string" then
            key = table.concat({
                "blob",
                archive,
                tostring(entry.name or "audio"),
                tostring(#entry.data)
            }, ":")
        else
            local path = getEntryPath(entry)
            if path then
                key = "path:" .. path
            elseif archive ~= "" or tostring(entry.name or "") ~= "" then
                key = "meta:" .. archive .. ":" .. tostring(entry.name or "")
            end
        end

        if key then
            entry._audioCacheKey = key
        end
        return key
    end

    local path = getEntryPath(entry)
    if path then
        return "path:" .. path
    end

    return nil
end

local function decodeEntryToSoundData(entry)
    if not love or not love.sound then
        return nil
    end

    if type(entry) == "table" and type(entry.data) == "string" then
        local fileName = entry.name or "audio"
        local okFileData, fileData = pcall(love.filesystem.newFileData, entry.data, fileName)
        if okFileData and fileData then
            local okSoundData, soundData = pcall(love.sound.newSoundData, fileData)
            if okSoundData and soundData then
                return soundData
            end
        end
        return nil
    end

    local path = getEntryPath(entry)
    if path then
        local okSoundData, soundData = pcall(love.sound.newSoundData, path)
        if okSoundData and soundData then
            return soundData
        end
    end

    return nil
end

function audiocache.preloadEntry(collections, entry)
    local cache = ensureAudioCache(collections)
    local key = audiocache.getEntryKey(entry)

    if cache and key and cache[key] ~= nil then
        return cache[key]
    end

    local record = {
        key = key,
        soundData = decodeEntryToSoundData(entry)
    }

    if cache and key then
        cache[key] = record
    end

    if type(entry) == "table" then
        entry._audioCacheKey = key or entry._audioCacheKey
    end

    return record
end

function audiocache.getPreloadedSoundData(collections, entry)
    local cache = ensureAudioCache(collections)
    local key = audiocache.getEntryKey(entry)
    local record = (cache and key and cache[key]) or nil

    if not record then
        record = audiocache.preloadEntry(collections, entry)
    end

    if record then
        return record.soundData
    end

    return nil
end

function audiocache.preloadCollectionAudio(collections)
    local audioEntries = type(collections) == "table" and collections.audio or nil
    local loaded = 0
    local total = 0

    for _, entry in ipairs(audioEntries or {}) do
        total = total + 1
        local record = audiocache.preloadEntry(collections, entry)
        if record and record.soundData then
            loaded = loaded + 1
        end
    end

    return loaded, total
end

return audiocache
