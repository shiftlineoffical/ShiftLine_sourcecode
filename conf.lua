---@class love
---@type any
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

---@diagnostic disable-next-line: undefined-field
function love.conf(t)

    t.identity = "ShiftLine"
    t.version = "11.5"
    t.console = true

    t.window.title = "ShiftLine - ver0.3.5"
    t.window.width = 1920
    t.window.height = 1080
    t.window.fullscreen = true
    t.window.fullscreentype = "desktop"
    t.window.vsync = 1
    t.window.resizable = true
    t.window.minwidth = 1920
    t.window.minheight = 1080
    -- 繝｢繧ｸ繝･繝ｼ繝ｫ縺ｮ譛牙柑蛹厄ｼ・odules・・
    t.modules.audio = true
    t.modules.event = true
    t.modules.graphics = true
    t.modules.image = true
    t.modules.keyboard = true
    t.modules.math = true
    t.modules.mouse = true
    t.modules.physics = false
    t.modules.sound = true
    t.modules.system = true
    t.modules.timer = true
    t.modules.window = true
    -- 縺昴・莉悶・險ｭ螳・
    t.externalstorage = true
    t.accelerometerjoystick = true
    t.gammacorrect = true
end

