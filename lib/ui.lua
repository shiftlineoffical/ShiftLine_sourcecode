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

local ui = {}

-- 逕滓・: 蟷ｳ陦悟屁霎ｺ蠖｢繝昴Μ繧ｴ繝ｳ (x1,y1) 蟾ｦ荳・(x2,y2) 蜿ｳ荳・縺ｧ蛯ｾ縺阪ｒ謖・ｮ・
function ui.parallelogramPoly(x1, x2, y1, y2, slope)
    local dx = slope * (y2 - y1)
    return {x1, y1, x1 + dx, y2, x2 + dx, y2, x2, y1}
end

-- 繝昴Μ繧ｴ繝ｳ縺ｧ蝪励ｊ縺､縺ｶ縺励∵棧縲√ユ繧ｭ繧ｹ繝医ｒ謠冗判縲ゅユ繧ｭ繧ｹ繝医・蟷・↓蜿弱∪繧九ｈ縺・ヵ繧ｩ繝ｳ繝医し繧､繧ｺ繧堤ｸｮ蟆上☆繧・
function ui.drawParallelogram(poly, text, font, opts)
    opts = opts or {}
    local mx, my = love.mouse.getPosition()
    local hover = false
    -- pointInPolygon
    do
        local inside = false
        local j = #poly - 1
        for i = 1, #poly, 2 do
            local xi, yi = poly[i], poly[i+1]
            local xj, yj = poly[j], poly[j+1]
            local intersect = ((yi > my) ~= (yj > my)) and (mx < (xj - xi) * (my - yi) / (yj - yi) + xi)
            if intersect then inside = not inside end
            j = i
        end
        hover = inside
    end

    if hover then
        love.graphics.setColor(unpack(opts.hoverColor or {0.25,0.25,0.25}))
    else
        love.graphics.setColor(unpack(opts.color or {0.1,0.1,0.1}))
    end
    love.graphics.polygon("fill", poly)

    love.graphics.setColor(unpack(opts.lineColor or {1,1,1,0.5}))
    love.graphics.polygon("line", poly)

    -- calc center
    local sx, sy, cx, cy = 0,0,0,0
    for i = 1, #poly, 2 do
        sx = sx + poly[i]
        sy = sy + poly[i+1]
    end
    cx = sx / (#poly/2)
    cy = sy / (#poly/2)

    -- fit text width
    local maxW = (opts.maxWidth or 0) -- if 0 use polygon width estimation
    if maxW == 0 then
        local minx, maxx = poly[1], poly[1]
        for i = 1, #poly, 2 do
            minx = math_min(minx, poly[i])
            maxx = math_max(maxx, poly[i])
        end
        maxW = maxx - minx - (opts.textPadding or 24)
    end

    local displayText = text or ""
    local f = font
    local scale = 1
    local textW = f:getWidth(displayText)
    if textW > maxW then
        scale = maxW / textW
    end

    love.graphics.setColor(unpack(opts.textColor or {1,1,1}))
    love.graphics.push()
    love.graphics.translate(cx, cy - (f:getHeight()*scale)/2)
    love.graphics.scale(scale, scale)
    love.graphics.print(displayText, -f:getWidth(displayText)/2, 0)
    love.graphics.pop()
end

-- 蜿励￠蜿悶▲縺溽判蜒上ｒ譛螟ｧ蟷・鬮倥＆縺ｫ蜿弱ａ繧九せ繧ｱ繝ｼ繝ｫ蛟､繧定ｿ斐☆
function ui.scaleToFit(img, maxW, maxH)
    if not img or type(img.getWidth) ~= "function" then return 1 end
    local iw = img:getWidth()
    local ih = img:getHeight()
    if iw == 0 or ih == 0 then return 1 end
    local sx = maxW / iw
    local sy = maxH / ih
    return math_min(sx, sy, 1)
end

function ui.scaleFontSize(size)
    local _, displayHeight = love.graphics.getDimensions()
    local baseHeight = 1080
    return math_max(12, math_floor(size * displayHeight / baseHeight))
end

function ui.newFont(fontPathOrSize, size)
    if type(fontPathOrSize) == "string" then
        return love.graphics.newFont(fontPathOrSize, ui.scaleFontSize(size or 16))
    end
    return love.graphics.newFont(ui.scaleFontSize(fontPathOrSize))
end

return ui


