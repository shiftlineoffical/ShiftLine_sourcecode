---@type any
local _G = _G

local love = love
local string = string
local table = table
local math = math

local ipairs = ipairs
local pcall = pcall
local tostring = tostring
local type = type

local string_format = string.format
local math_floor = math.floor
local math_max = math.max
local math_min = math.min

local play = require "play"
local musicselect = require "musicselect"
local log = require "log"
local i18n = require "i18n"
local audiocache = require "audiocache"
local ui = require("lib.ui")
local githubsongs = require "githubsongs"

local gamejolt = nil

do
    local ok, result = pcall(require, "gamejolt")

    if ok then
        gamejolt = result
        log.info("GameJolt module loaded")
    else
        log.warn("GameJolt module failed to load: " .. tostring(result))
    end
end

local createsfb = nil

do
    local ok, result = pcall(require, "createsfb")

    if ok then
        createsfb = result
        log.info("createsfb module loaded")
    else
        log.error("createsfb module failed to load: " .. tostring(result))
    end
end

local openingloader = {}

local displayx, displayy = love.graphics.getDimensions()

local logotransparency = 0
local lodingfont
local verfont
local statusFont

local logo
local logox
local logoy

local endsaccess = 0
local appversion = "0.4.0"

local timer = 0
local fadingIn = true
local fadingOut = false
local heavyStarted = false

local function emptyCollections()
    return {
        audio = {},
        charts = {},
        images = {}
    }
end

local function countEntries(collection, key)
    if type(collection) ~= "table" then
        return 0
    end

    local value = collection[key]

    if type(value) ~= "table" then
        return 0
    end

    return #value
end

local function cacheStartupCollections(collections)
    if type(collections) ~= "table" then
        collections = emptyCollections()
    end

    openingloader._collections = collections

    if _G.main and type(_G.main) == "table" then
        _G.main.startup = _G.main.startup or {}

        _G.main.startup.collections = collections

        if type(_G.main.startup.previewSources) ~= "table" then
            _G.main.startup.previewSources = {}
        end
    end

    return collections
end

local function filterCollectionsByCharts(collections)
    if type(collections) ~= "table" then
        return emptyCollections()
    end

    local charts =
        type(collections.charts) == "table"
        and collections.charts
        or {}

    local allowedArchives = {}
    local filteredCharts = {}

    for _, entry in ipairs(charts) do
        if type(entry) == "table" then
            filteredCharts[#filteredCharts + 1] = entry

            if type(entry.archive) == "string"
                and entry.archive ~= ""
            then
                allowedArchives[entry.archive] = true
            end
        end
    end

    local result = {
        audio = {},
        charts = filteredCharts,
        images = {}
    }

    for _, entry in ipairs(collections.audio or {}) do
        if type(entry) == "table"
            and type(entry.archive) == "string"
            and allowedArchives[entry.archive]
        then
            result.audio[#result.audio + 1] = entry
        end
    end

    for _, entry in ipairs(collections.images or {}) do
        if type(entry) == "table"
            and type(entry.archive) == "string"
            and allowedArchives[entry.archive]
        then
            result.images[#result.images + 1] = entry
        end
    end

    return result
end

local function loadLocalSongs()
    if not createsfb
        or type(createsfb.load) ~= "function"
    then
        log.error("createsfb.load is unavailable")
        return emptyCollections()
    end

    log.info("Loading local Songs")

    local ok, result = pcall(
        createsfb.load,
        createsfb,
        {
            forceRebuildAll = false
        }
    )

    if not ok then
        log.error(
            "createsfb.load failed: "
            .. tostring(result)
        )

        return emptyCollections()
    end

    if type(result) ~= "table" then
        log.error(
            "createsfb.load returned invalid result"
        )

        return emptyCollections()
    end

    log.info(
        "Local songs loaded: charts="
        .. tostring(countEntries(result, "charts"))
        .. ", audio="
        .. tostring(countEntries(result, "audio"))
        .. ", images="
        .. tostring(countEntries(result, "images"))
    )

    return result
end

local function synchronizeSongs()
    log.info("Starting GitHub song synchronization")

    local ok, result = pcall(
        githubsongs.start
    )

    if not ok then
        log.error(
            "githubsongs.start failed: "
            .. tostring(result)
        )
    elseif result == false then
        log.warn(
            "GitHub song synchronization failed"
        )
    end

    local state = nil

    if type(githubsongs.getState) == "function" then
        local stateOK, stateResult =
            pcall(githubsongs.getState)

        if stateOK
            and type(stateResult) == "table"
        then
            state = stateResult
        end
    end

    if state then
        log.info(
            "GitHub synchronization status: "
            .. tostring(state.status)
        )

        log.info(
            "GitHub synchronization result: "
            .. "downloaded="
            .. tostring(state.downloaded or 0)
            .. ", skipped="
            .. tostring(state.skipped or 0)
            .. ", failed="
            .. tostring(state.failedFiles or 0)
        )
    end

    local collections = loadLocalSongs()

    collections =
        filterCollectionsByCharts(collections)

    return collections
end

local function prepareCollections(collections)
    if type(collections) ~= "table" then
        collections = emptyCollections()
    end

    collections =
        filterCollectionsByCharts(collections)

    cacheStartupCollections(collections)

    if musicselect
        and type(musicselect.setStartupAssets) == "function"
    then
        pcall(
            musicselect.setStartupAssets,
            musicselect,
            collections,
            {}
        )
    end

    if play
        and type(play.setCollections) == "function"
    then
        pcall(
            play.setCollections,
            play,
            collections
        )
    end

    return collections
end

local function startAudioPreload(collections)
    if type(collections) ~= "table" then
        openingloader._audioPreloadState = nil
        return
    end

    local entries =
        type(collections.audio) == "table"
        and collections.audio
        or {}

    if #entries <= 0 then
        openingloader._audioPreloadState = nil
        return
    end

    openingloader._audioPreloadState = {
        entries = entries,
        idx = 1,
        loaded = 0,
        total = #entries
    }

    log.info(
        "Audio preload queued: "
        .. tostring(#entries)
        .. " entries"
    )
end

local function performHeavyLoad()
    log.info("Heavy loading started")

    local collections

    local ok, result =
        pcall(synchronizeSongs)

    if ok
        and type(result) == "table"
    then
        collections = result
    else
        log.error(
            "Song synchronization crashed: "
            .. tostring(result)
        )

        collections = loadLocalSongs()
    end

    collections =
        prepareCollections(collections)

    endsaccess =
        math_min(
            100,
            endsaccess + 35
        )

    startAudioPreload(collections)

    pcall(function()
        if play
            and type(play.preloadCommonAudio) == "function"
        then
            play.preloadCommonAudio()
        end
    end)

    pcall(function()
        if gamejolt
            and type(gamejolt.load) == "function"
        then
            gamejolt.load()
        end
    end)

    log.info(
        "Songs available: "
        .. tostring(
            countEntries(
                collections,
                "charts"
            )
        )
    )

    log.info("Heavy loading completed")
end

function openingloader.getCollections()
    return openingloader._collections
end

function openingloader.getGitHubState()
    if type(githubsongs.getState) ~= "function" then
        return nil
    end

    local ok, result =
        pcall(githubsongs.getState)

    if ok then
        return result
    end

    return nil
end

function openingloader.load()
    love.window.setTitle(
        "ShiftLine - ver" .. appversion
    )

    logo =
        love.graphics.newImage(
            "img/logo.png"
        )

    logox = logo:getWidth()
    logoy = logo:getHeight()

    lodingfont =
        ui.newFont(
            "lib/data/fonts/NotoSansJP-ExtraLight.ttf",
            40
        )

    verfont =
        ui.newFont(
            "lib/data/fonts/NotoSansJP-ExtraLight.ttf",
            20
        )

    statusFont =
        ui.newFont(
            "lib/data/fonts/NotoSansJP-ExtraLight.ttf",
            16
        )

    heavyStarted = false
    fadingIn = true
    fadingOut = false
    timer = 0
    logotransparency = 0
    endsaccess = 0

    openingloader.endprocess = false
    openingloader._deferred = true
    openingloader._collections = nil
    openingloader._audioPreloadState = nil
end

function openingloader.update(dt)
    if fadingIn then
        logotransparency =
            math_min(
                1,
                logotransparency + dt
            )

        endsaccess =
            math_min(
                100,
                endsaccess + dt * 30
            )

        if endsaccess >= 100 then
            fadingIn = false
            timer = 0
        end

        return
    end

    if openingloader._deferred
        and not heavyStarted
    then
        heavyStarted = true

        local ok, err =
            pcall(
                performHeavyLoad
            )

        if not ok then
            log.error(
                "performHeavyLoad failed: "
                .. tostring(err)
            )

            if not openingloader._collections then
                prepareCollections(
                    loadLocalSongs()
                )
            end
        end

        openingloader._deferred = false
    end

    if not fadingOut then
        timer =
            timer + dt

        if timer >= 1 then
            fadingOut = true
            timer = 0
        end

        return
    end

    if openingloader._audioPreloadState then
        local st =
            openingloader._audioPreloadState

        local batch = 3

        for i = 1, batch do
            if st.idx > st.total then
                break
            end

            local entry =
                st.entries[st.idx]

            if entry then
                local ok, rec =
                    pcall(
                        audiocache.preloadEntry,
                        openingloader._collections,
                        entry
                    )

                if ok
                    and rec
                    and rec.soundData
                then
                    st.loaded =
                        st.loaded + 1
                end
            end

            st.idx =
                st.idx + 1
        end

        if st.total > 0 then
            local progress =
                st.loaded
                / math_max(
                    1,
                    st.total
                )

            endsaccess =
                math_min(
                    98,
                    80 + progress * 18
                )
        end

        if st.idx > st.total then
            log.info(
                string_format(
                    "Preloaded audio at startup: %d/%d",
                    st.loaded,
                    st.total
                )
            )

            openingloader._audioPreloadState =
                nil

            endsaccess = 100
        end
    else
        endsaccess =
            math_max(
                endsaccess,
                100
            )
    end

    logotransparency =
        math_max(
            0,
            logotransparency - dt
        )

    if logotransparency <= 0 then
        openingloader.endprocess = true
    end
end

function openingloader.draw()
    displayx, displayy =
        love.graphics.getDimensions()

    love.graphics.setFont(
        lodingfont
    )

    local percentText =
        tostring(
            math_floor(
                endsaccess
            )
        ) .. "%"

    local percentHalfWidth =
        lodingfont:getWidth(
            percentText
        ) / 2

    love.graphics.setColor(
        1,
        1,
        1,
        logotransparency
    )

    love.graphics.print(
        percentText,
        displayx / 10 * 8.5 + 100,
        displayy / 10 * 9 - 40,
        0,
        1,
        1,
        percentHalfWidth,
        lodingfont:getHeight() / 2
    )

    love.graphics.rectangle(
        "line",
        displayx / 10 * 8.5,
        displayy / 10 * 9,
        200,
        20
    )

    love.graphics.setFont(
        verfont
    )

    love.graphics.rectangle(
        "fill",
        displayx / 10 * 8.5,
        displayy / 10 * 9,
        endsaccess * 2,
        20
    )

    pcall(function()
        love.graphics.print(
            i18n.t("Version")
                .. appversion,
            10,
            displayy / 10 * 9
        )
    end)

    local statusText = ""

    if openingloader._deferred
        and not heavyStarted
    then
        statusText =
            "Preparing..."
    elseif heavyStarted
        and not openingloader._collections
    then
        local state =
            openingloader.getGitHubState()

        if state
            and state.status == "connecting"
        then
            statusText =
                "Connecting to GitHub..."
        elseif state
            and state.status == "downloading"
        then
            statusText =
                string_format(
                    "Downloading songs... %d/%d",
                    state.completedFiles or 0,
                    state.totalFiles or 0
                )
        elseif state
            and state.status == "failed"
        then
            statusText =
                "GitHub unavailable. Loading local songs..."
        else
            statusText =
                "Loading songs..."
        end
    elseif heavyStarted
        and not openingloader.endprocess
    then
        statusText =
            "Loading assets..."
    elseif openingloader.endprocess then
        statusText =
            "Finishing..."
    end

    love.graphics.setFont(
        statusFont
    )

    love.graphics.setColor(
        1,
        1,
        1,
        logotransparency * 0.9
    )

    love.graphics.print(
        statusText,
        displayx / 10 * 8.5,
        displayy / 10 * 9 + 24
    )
end

return openingloader