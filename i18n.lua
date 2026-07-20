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

local i18n = {}

local localeTexts = {
    jp = {
        clickToStart = "click to start",
        exit = "Exit",
        login = "ログイン",
        autoLogin = "ログイン情報を記憶する",
        modeSolo = "Solo",
        modeOnline = "Online",
        modeSettings = "Settings",
        modeTitle = "Title",
        play = "Play",
        result = "RESULT",
        levelPrefix = "LEVEL ",
        score = "SCORE",
        totalNotes = "TOTAL NOTES  ",
        maxCombo = "MAX COMBO",
        accuracy = "ACCURACY",
        rank = "RANK",
        perfect = "Perfect",
        good = "Good",
        bad = "Bad",
        miss = "Miss",
        retryHint = "R : RETRY",
        musicSelectHint = "ENTER / ESC : MUSIC SELECT",
        retry = "RETRY",
        musicSelect = "MUSIC SELECT",
        ratingAverage = "RATING",
        songRate = "SONG RATE",
        bestRating = "BEST",
        resume = "Resume",
        restart = "Restart",
    },
    en = {
        clickToStart = "click to start",
        exit = "Exit",
        login = "Login",
        autoLogin = "Remember me",
        modeSolo = "Solo",
        modeOnline = "Online",
        modeSettings = "Settings",
        modeTitle = "Title",
        play = "Play",
        result = "RESULT",
        levelPrefix = "LEVEL ",
        score = "SCORE",
        totalNotes = "TOTAL NOTES  ",
        maxCombo = "MAX COMBO",
        accuracy = "ACCURACY",
        rank = "RANK",
        perfect = "Perfect",
        good = "Good",
        bad = "Bad",
        miss = "Miss",
        retryHint = "R : RETRY",
        musicSelectHint = "ENTER / ESC : MUSIC SELECT",
        retry = "RETRY",
        musicSelect = "MUSIC SELECT",
        ratingAverage = "RATING",
        songRate = "SONG RATE",
        bestRating = "BEST",
        resume = "Resume",
        restart = "Restart",
    }
}

local function getLanguage()
    local settings = package.loaded["settings"]
    if not settings then
        local ok, settingsModule = pcall(require, "settings")
        if ok and type(settingsModule) == "table" then
            settings = settingsModule
        end
    end
    if type(settings) == "table" and type(settings.settingsdata) == "table" then
        local misc = settings.settingsdata.miscsettings
        if type(misc) == "table" and type(misc.language) == "string" then
            return misc.language
        end
    end
    return "jp"
end

function i18n.t(key)
    local lang = getLanguage()
    local locale = localeTexts[lang] or localeTexts.jp
    return locale[key] or localeTexts.jp[key] or key
end

function i18n.tf(key, ...)
    local text = i18n.t(key)
    if select("#", ...) == 0 then
        return text
    end
    return string_format(text, ...)
end

function i18n.getLanguage()
    return getLanguage()
end

return i18n


