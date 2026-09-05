local M = {}

M.musicCountUrl = "https://script.google.com/macros/s/AKfycbxY2r67YHH3sHB90RMLli2bTb_8uZDCYX0k97YaSwwo5yHdEkByn02Ys-dzXu9YP5eymQ/exec"

local function getOS()
    return love and love.system and love.system.getOS and love.system.getOS() or "Windows"
end

function M.isWindows()
    return getOS() == "Windows"
end

function M.getPath()
    local configuredPath = os.getenv("CURL")
    if configuredPath and configuredPath ~= "" then
        return configuredPath
    end

    local osName = getOS()
    if osName == "Windows" then
        local windir = os.getenv("WINDIR") or "C:\\Windows"
        local systemCurl = windir .. "\\System32\\curl.exe"
        local handle = io.open(systemCurl, "rb")
        if handle then
            handle:close()
            return systemCurl
        end
        return "curl.exe"
    end

    if osName == "OS X" then
        return "curl"
    end

    return "curl"
end

function M.getTempDir()
    local osName = getOS()
    if osName == "Windows" then
        return os.getenv("TEMP") or os.getenv("TMP") or "C:\\Windows\\Temp"
    end

    if osName == "OS X" then
        return os.getenv("TMPDIR") or "/tmp"
    end

    return os.getenv("TMPDIR") or "/tmp"
end

function M.joinPath(directory, filename)
    local separator = M.isWindows() and "\\" or "/"
    return directory:gsub("[\\\\/]$", "") .. separator .. filename
end

function M.quote(value)
    value = tostring(value)
    if M.isWindows() then
        return '"' .. value:gsub('"', '\\"') .. '"'
    end

    return "'" .. value:gsub("'", "'\\''") .. "'"
end

function M.nullDevice()
    return M.isWindows() and "NUL" or "/dev/null"
end

return M
