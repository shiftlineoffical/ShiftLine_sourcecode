function love.conf(t)

    -- アプリ基本情報
    t.identity = "ShiftLine"
    t.version = "11.5"
    t.console = true

    -- ウィンドウ設定（display）
    t.window.title = "ShiftLine - ver0.3.5"
    t.window.width = 1920
    t.window.height = 1080
    t.window.fullscreen = true
    t.window.fullscreentype = "desktop"
    t.window.vsync = 1
    t.window.resizable = true
    t.window.minwidth = 1920
    t.window.minheight = 1080
    -- モジュールの有効化（modules）
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
    -- その他の設定
    t.externalstorage = true
    t.accelerometerjoystick = true
    t.gammacorrect = true
end