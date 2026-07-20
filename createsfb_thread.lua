-- Thread: load createsfb and push collections to channel
local createsfb = require("createsfb")
local ch = love.thread.getChannel("openingloader_createsfb_channel")
local ok, res = pcall(createsfb.load, createsfb, {forceRebuildAll = false})
if ok then
    ch:push({ok = true, result = res})
else
    ch:push({ok = false, err = tostring(res)})
end
