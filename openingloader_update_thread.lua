-- Thread: perform a simple HTTP GET for the update manifest and push result to channel
local http = require("socket.http")
local channel = love.thread.getChannel("openingloader_update_channel")
local ok, res = pcall(http.request, http, "https://raw.githubusercontent.com/cloudoamp/ShiftLine/refs/heads/main/update.txt")
channel:push({ok = ok, body = (type(res) == "string") and res or nil, err = (ok and nil) or tostring(res)})
