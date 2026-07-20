--[[
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

繧ｨ繝・ぅ繧ｿ繝｢繝ｼ繝・- 隴憺擇邱ｨ髮・畑
Play逕ｻ髱｢縺ｧE繧ｭ繝ｼ繧呈款縺吶％縺ｨ縺ｧ驕ｷ遘ｻ
- 隴憺擇縺ｯ閾ｪ蜍輔〒豬√ｌ縺ｪ縺・
- 繧ｹ繝壹・繧ｹ繧ｭ繝ｼ縺ｧ繧ｹ繧ｿ繝ｼ繝・
- F1縺ｧ繧ｪ繝ｼ繝医・繝ｬ繧､蛻・ｊ譖ｿ縺・
- Q縺ｧ縺昴・讌ｽ譖ｲSFL縺縺代ｒ蜀崎ｪｭ縺ｿ霎ｼ縺ｿ
]]

---@diagnostic disable: undefined-global
local editor = {}
local log = require "log"

-- 繧ｨ繝・ぅ繧ｿ蝗ｺ譛峨・迥ｶ諷・
local editorAutoplay = false
local editorStarted = false

local function resetEditorChartPlayback()
    chartRuntime.currentIndex = 1
    chartRuntime.nextGravityEventIndex = 1
    noteDrawQueue = {}
    noteRenderStateCache = {}
    notexy = {}
    hitEffects = {}
    clearLaneInputStates()

    for _, note in ipairs(chartRuntime.notes or {}) do
        note.judged = nil
        note.hit = nil
        note.judgeDeltaMs = nil
        note.judgedTime = nil
        note.fixedJudgeLinePos = nil
    end
end

-- 蛻晄悄蛹・
function editor.load()
    editorAutoplay = false
    editorStarted = false
    
    -- play 繝｢繧ｸ繝･繝ｼ繝ｫ縺ｮ蠢・ｦ√↑螟画焚繧貞・譛溷喧
    alpha = 0
    jacketalpha = 0
    playTimer = 0
    metaDisplayTimer = 0
    metaDisplayShown = false
    metaDisplayFinished = false
    musicload = 1  -- editor 縺ｧ縺ｯ蟶ｸ縺ｫ musicload = 1
    songStarted = false
    jacketimg = nil
    musictime = 0
    musictimer = 0
    finished = false
    resultTransitioned = false
    paused = false
    waitingResume = false
    resumeTimer = 0
    pauseMenuButtons = {}
    lanegravity = 1
    notegravity = 1
    
    -- levelColors 繧貞・譛溷喧・・lay.lua 縺ｮ levelColors 縺ｨ蜷後§・・
    levelColors = levelColors or {
        easy = {0.1, 1, 0.1},
        normal = {0.5, 0.5, 1},
        hard = {1, 1, 0},
        extra = {1, 0.1, 0.1},
        default = {0.5, 0.1, 0.5}
    }
    
    log.info("Editor initialized")
end

-- 譖ｴ譁ｰ
function editor.update(dt)
    if not bgmSource then
        return
    end

    if editorStarted then
        if not songStarted and bgmSource.isPlaying and bgmSource:isPlaying() then
            songStarted = true
        end

        local songTime = nil
        if songStarted then
            songTime = getCurrentSongTime()
        end

        if songTime then
            updateChartGravityEvents(songTime)
            updateNoteDrawQueue(songTime)
            musictime = songTime
        else
            musictime = bgmSource:tell("seconds") or musictime
        end

        musictimer = musictimer + dt
    end
end

-- 謠冗判
function editor.draw()
    -- play 縺ｨ蜷後§謠冗判繝ｭ繧ｸ繝・け
    musicdatadraw()
    
    -- 繝ｬ繝ｼ繝ｳ繝ｻ蛻､螳壹Λ繧､繝ｳ謠冗判
    notelane()
    drawJudgeline()
    drawNotes()
    drawJudgeHitEffects()
    
    -- 繧ｳ繝ｳ繝懊→繧ｹ繧ｳ繧｢陦ｨ遉ｺ
    drawComboDisplay()
    drawScoreDisplay()
    
    -- 繧ｨ繝・ぅ繧ｿ諠・ｱ陦ｨ遉ｺ
    drawEditorInfo()
end

-- 繧ｨ繝・ぅ繧ｿ諠・ｱ繧堤判髱｢縺ｫ陦ｨ遉ｺ
function drawEditorInfo()
    love.graphics.setColor(1, 1, 1, 0.8)
    local baseFont = love.graphics.getFont()
    love.graphics.setFont(baseFont)
    
    local infoText = "--- 繧ｨ繝・ぅ繧ｿ繝｢繝ｼ繝・---"
    love.graphics.print(infoText, 10, 10)
    
    local statusText = "迥ｶ諷・ "
    if editorStarted then
        if editorAutoplay then
            statusText = statusText .. "繝励Ξ繧､荳ｭ (繧ｪ繝ｼ繝医・繝ｬ繧､: ON)"
        else
            statusText = statusText .. "繝励Ξ繧､荳ｭ (繧ｪ繝ｼ繝医・繝ｬ繧､: OFF)"
        end
    else
        statusText = statusText .. "蛛懈ｭ｢荳ｭ"
    end
    love.graphics.print(statusText, 10, 30)
    
    local controlText = "[SPACE] Start/Pause [F1] Toggle autoplay [Q] Export SFL [F10] Toggle fullscreen [ESC] Back"
    love.graphics.print(controlText, 10, 50)
    
    if bgmSource then
        local timeText = string_format("Time: %.2f sec", musictime)
        love.graphics.print(timeText, 10, 70)
    end
end

-- 繧ｭ繝ｼ蜈･蜉帛・逅・
function editor.keypressed(key, scancode, isrepeat)
    if key == "escape" then
        -- 繧ｨ繝・ぅ繧ｿ繧堤ｵゆｺ・＠縺ｦ play 縺ｫ謌ｻ繧・
        if bgmSource then
            bgmSource:stop()
        end
        programnumber = 4  -- play 縺ｫ謌ｻ繧・
        program = nil
        return
    end
    
    if key == "space" then
        -- 繧ｹ繧ｿ繝ｼ繝・繧ｹ繝医ャ繝・
        if not bgmSource or musicload ~= 1 then
            return
        end
        
        if not editorStarted then
            -- 繧ｹ繧ｿ繝ｼ繝・
            editorStarted = true
            songStarted = false
            finished = false
            musictime = 0
            resetEditorChartPlayback()
            if bgmSource then
                bgmSource:stop()
                local okSeek = pcall(bgmSource.seek, bgmSource, 0, "seconds")
                if not okSeek then
                    pcall(bgmSource.seek, bgmSource, 0)
                end
                bgmSource:play()
                songStarted = true
            end
        else
            -- 蛛懈ｭ｢
            editorStarted = false
            if bgmSource then
                bgmSource:pause()
            end
        end
        return
    end
    
    if key == "f1" then
        -- 繧ｪ繝ｼ繝医・繝ｬ繧､蛻・ｊ譖ｿ縺・
        editorAutoplay = not editorAutoplay
        log.info("繧ｪ繝ｼ繝医・繝ｬ繧､: " .. (editorAutoplay and "ON" or "OFF"))
        return
    end
    
    if key == "q" then
        -- SFL 繝輔ぃ繧､繝ｫ繧貞・隱ｭ縺ｿ霎ｼ縺ｿ
        reloadCurrentChart()
        return
    end
    
    -- 驥榊鴨螟画峩繧ｭ繝ｼ・域･ｽ譖ｲ隕也せ縺ｮ蛻・ｊ譖ｿ縺茨ｼ・
    if key == "a" then
        lanegravity = 2
    elseif key == "s" then
        lanegravity = 1
    elseif key == "d" then
        lanegravity = 4
    elseif key == "w" then
        lanegravity = 3
    end
end

-- 繧ｭ繝ｼ髮｢縺怜・逅・
function editor.keyreleased(key, scancode)
    -- 繧ｨ繝・ぅ繧ｿ縺ｧ縺ｯ繧ｭ繝ｼ髮｢縺励・迚ｹ谿雁・逅・・荳崎ｦ・
end

-- 繝槭え繧ｹ蜈･蜉帛・逅・ｼ井ｸ堺ｽｿ逕ｨ・・
function editor.mousepressed(x, y, button)
    -- 繧ｨ繝・ぅ繧ｿ縺ｧ縺ｯ繝槭え繧ｹ蜈･蜉帙・荳堺ｽｿ逕ｨ
end

-- 繝槭え繧ｹ繝帙う繝ｼ繝ｫ蜃ｦ逅・- 荳蟆冗ｯ縺斐→縺ｫ騾ｲ繧/謌ｻ縺・
function editor.wheelmoved(x, y)
    if not editorStarted or not bgmSource then
        return
    end
    
    -- BPM 繧貞叙蠕暦ｼ医ョ繝輔か繝ｫ繝・120・・
    local bpm = 120
    if chartRuntime and chartRuntime.chart and chartRuntime.chart.bpm then
        bpm = tonumber(chartRuntime.chart.bpm) or 120
    end
    
    -- 荳蟆冗ｯ縺ｮ譎る俣・育ｧ抵ｼ・ (60 / BPM) * 4 = 240 / BPM
    local measureTime = 240 / math_max(1, bpm)
    
    -- 繝槭え繧ｹ繝帙う繝ｼ繝ｫ蛟､・・ > 0 縺ｪ繧我ｸ翫↓蝗槭☆ = 譎る俣騾ｲ繧・・
    local measureCount = math_floor(math.abs(y))
    local delta = (y > 0) and (measureCount * measureTime) or -(measureCount * measureTime)
    
    -- 譁ｰ縺励＞蜀咲函菴咲ｽｮ
    local newTime = math_max(0, musictime + delta)
    musictime = newTime
    
    -- bgmSource 繧呈眠縺励＞菴咲ｽｮ縺ｫ繧ｷ繝ｼ繧ｯ
    if bgmSource then
        local okSeek = pcall(bgmSource.seek, bgmSource, newTime, "seconds")
        if not okSeek then
            pcall(bgmSource.seek, bgmSource, newTime)
        end
    end
end

-- 邨ゆｺ・・逅・
function editor.quit()
    editorAutoplay = false
    editorStarted = false
    
    if bgmSource then
        bgmSource:stop()
    end
end

return editor



