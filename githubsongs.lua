local githubsongs = {}

local love = love
local string = string
local table = table
local math = math
local os = os
local io = io

local ipairs = ipairs
local pairs = pairs
local pcall = pcall
local tostring = tostring
local tonumber = tonumber
local type = type

local log = require("log")
local urfs = require("urfs")


local REPO_OWNER = "shiftlineoffical"
local REPO_NAME = "ShiftLine_Songs"
local REPO_BRANCH = "main"

local API_ROOT =
    "https://api.github.com/repos/"
    .. REPO_OWNER
    .. "/"
    .. REPO_NAME

local API_TREE_URL =
    API_ROOT
    .. "/git/trees/"
    .. REPO_BRANCH
    .. "?recursive=1"

local RAW_ROOT =
    "https://raw.githubusercontent.com/"
    .. REPO_OWNER
    .. "/"
    .. REPO_NAME
    .. "/"
    .. REPO_BRANCH
    .. "/"

local SONGS_DIR = "Songs"

local CURL_COMMAND = "curl"

local USER_AGENT =
    "ShiftLine/0.4.0"

local PARALLEL_COUNT = 8

local PARALLEL_BATCH_SIZE = 16


local state = {
    status = "idle",

    started = false,
    finished = false,
    failed = false,

    error = nil,

    tree = {},
    songs = {},

    songIndex = 0,
    fileIndex = 0,

    totalFiles = 0,
    completedFiles = 0,

    currentSong = "",
    currentFile = "",

    downloaded = 0,
    skipped = 0,
    failedFiles = 0,

    bytesDownloaded = 0,
    totalBytes = 0,

    writeDir = nil,

    gameDirectory = nil
}


local curlAvailable = false
local curlVersion = nil


local function isWindows()

    if package
        and package.config
    then
        return
            package.config:sub(1, 1)
            == "\\"
    end

    return false
end


local function shellQuote(value)

    value =
        tostring(value or "")

    if isWindows() then

        -- cmd.exe quoting
        value =
            value:gsub(
                '"',
                '\\"'
            )

        return
            '"'
            .. value
            .. '"'
    end

    return
        "'"
        .. value:gsub(
            "'",
            "'\\''"
        )
        .. "'"
end


local function normalizePath(path)

    if type(path) ~= "string" then
        return nil
    end

    path =
        path:gsub(
            "\\",
            "/"
        )

    path =
        path:gsub(
            "/+$",
            ""
        )

    return path
end
local ffi = nil
local bit = nil

if isWindows() then
    local ok, ffiModule = pcall(require, "ffi")

    if ok then
        ffi = ffiModule
        bit = require("bit")

        ffi.cdef[[
            typedef unsigned short WCHAR;
            typedef int BOOL;
            typedef unsigned long DWORD;
            typedef const WCHAR *LPCWSTR;
            typedef void *LPVOID;

            BOOL CreateDirectoryW(
                LPCWSTR lpPathName,
                LPVOID lpSecurityAttributes
            );

            DWORD GetLastError(void);

            DWORD GetFileAttributesW(
                LPCWSTR lpFileName
            );

            int MultiByteToWideChar(
                unsigned int CodePage,
                DWORD dwFlags,
                const char *lpMultiByteStr,
                int cbMultiByte,
                WCHAR *lpWideCharStr,
                int cchWideChar
            );
        ]]

        log.info(
            "githubsongs: Windows UTF-16 filesystem support enabled"
        )
    else
        log.warn(
            "githubsongs: LuaJIT FFI unavailable"
        )
    end
end


local function getGameDirectory()


    local executable =
        nil

    if type(arg) == "table" then

        executable =
            arg[0]
    end

    if type(executable) ~= "string"
        or executable == ""
    then

        executable = nil
    end



    if not executable
        and love
        and love.filesystem
        and love.filesystem.getSource
    then

        local ok, source =
            pcall(
                love.filesystem.getSource
            )

        if ok
            and type(source) == "string"
            and source ~= ""
        then

            executable = source
        end
    end

    if not executable then

        log.error(
            "githubsongs: cannot determine executable path"
        )

        return nil,
            "Cannot determine game executable path"
    end

    executable =
        normalizePath(
            executable
        )



    if executable:sub(1, 1) ~= "/"
        and not executable:match(
            "^%a:/"
        )
    then

        local pipe =
            io.popen(
                "cd",
                "r"
            )

        if pipe then

            local cwd =
                pipe:read("*l")

            pipe:close()

            if cwd
                and cwd ~= ""
            then

                cwd =
                    normalizePath(cwd)

                executable =
                    cwd
                    .. "/"
                    .. executable
            end
        end
    end


    if executable:sub(-1) == "/" then

        return executable
    end


    local directory =
        executable:match(
            "^(.*)/[^/]+$"
        )

    if not directory
        or directory == ""
    then

        directory = "."
    end

    return directory
end


local function checkCurl()

    if curlAvailable then
        return true
    end

    log.info(
        "githubsongs: checking curl"
    )

    local pipe, err =
        io.popen(
            CURL_COMMAND
            .. " --version",
            "r"
        )

    if not pipe then

        log.error(
            "githubsongs: curl unavailable: "
            .. tostring(err)
        )

        return false
    end

    local output =
        pipe:read("*a")

    local closeOK =
        pipe:close()

    if not closeOK then

        log.error(
            "githubsongs: curl --version failed"
        )

        return false
    end

    if not output
        or output == ""
    then

        log.error(
            "githubsongs: curl returned no version"
        )

        return false
    end

    curlAvailable = true
    curlVersion = output

    log.info(
        "githubsongs: curl available"
    )

    local firstLine =
        output:match(
            "([^\r\n]+)"
        )

    if firstLine then

        log.info(
            "githubsongs: "
            .. firstLine
        )
    end

    return true
end


local function resetState()

    state.status = "idle"

    state.started = false
    state.finished = false
    state.failed = false

    state.error = nil

    state.tree = {}
    state.songs = {}

    state.songIndex = 0
    state.fileIndex = 0

    state.totalFiles = 0
    state.completedFiles = 0

    state.currentSong = ""
    state.currentFile = ""

    state.downloaded = 0
    state.skipped = 0
    state.failedFiles = 0

    state.bytesDownloaded = 0
    state.totalBytes = 0

    state.writeDir = nil
    state.gameDirectory = nil
end


local function getWriteDirectory()

    local ok, result =
        pcall(
            urfs.getWriteDir
        )

    if not ok then

        return false,
            "urfs.getWriteDir failed: "
            .. tostring(result)
    end

    if type(result) ~= "string"
        or result == ""
    then

        return false,
            "PhysicsFS WriteDir is empty"
    end

    return true, result
end


local function utf8ToWide(value)

    if not ffi then
        return nil
    end

    if type(value) ~= "string" then
        return nil
    end


    local required =
        ffi.C.MultiByteToWideChar(
            65001,
            0,
            value,
            -1,
            nil,
            0
        )

    if required <= 0 then
        return nil
    end

    local buffer =
        ffi.new(
            "WCHAR[?]",
            required
        )

    local converted =
        ffi.C.MultiByteToWideChar(
            65001,
            0,
            value,
            -1,
            buffer,
            required
        )

    if converted <= 0 then
        return nil
    end

    return buffer
end


local function windowsDirectoryExists(path)

    if not ffi then
        return false
    end

    local wide =
        utf8ToWide(path)

    if not wide then
        return false
    end


    local ok, attributes =
        pcall(function()

            ffi.cdef[[
                DWORD GetFileAttributesW(
                    LPCWSTR lpFileName
                );
            ]]

            return
                ffi.C.GetFileAttributesW(
                    wide
                )
        end)

    if not ok then
        return false
    end


    if attributes == 0xFFFFFFFF then
        return false
    end


    return
        bit.band(
            tonumber(attributes),
            0x10
        ) ~= 0
end


local function createWindowsDirectory(path)

    if not ffi then
        return false,
            "LuaJIT FFI unavailable"
    end


    if windowsDirectoryExists(path) then
        return true
    end

    local wide =
        utf8ToWide(path)

    if not wide then

        return false,
            "UTF-8 to UTF-16 conversion failed"
    end

    local result =
        ffi.C.CreateDirectoryW(
            wide,
            nil
        )

    if result ~= 0 then
        return true
    end


    if windowsDirectoryExists(path) then
        return true
    end

    local errorCode =
        ffi.C.GetLastError()

    return false,
        "CreateDirectoryW failed, error="
        .. tostring(errorCode)
end


local function ensureDirectory(path)

    if not path
        or path == ""
    then
        return true
    end

    path =
        normalizePath(path)

    if not path
        or path == ""
    then
        return false
    end

    log.info(
        "githubsongs: creating directory "
        .. path
    )


    if isWindows() then


        local prefix = ""


        local drive =
            path:match(
                "^([A-Za-z]:)/"
            )

        if drive then

            prefix =
                drive
                .. "/"

            path =
                path:sub(
                    4
                )
        elseif path:sub(1, 1) == "/" then

            prefix = "/"

            path =
                path:sub(2)
        end

        local current =
            prefix

        for part in path:gmatch(
            "[^/]+"
        )
        do

            if current == ""
                or current == "/"
            then

                current =
                    current
                    .. part
            else

                current =
                    current
                    .. "/"
                    .. part
            end


            local isDriveRoot =
                current:match(
                    "^[A-Za-z]:/$"
                )

            if not isDriveRoot then

                local exists =
                    windowsDirectoryExists(
                        current
                    )

                if not exists then

                    local ok,
                          errorMessage =
                        createWindowsDirectory(
                            current
                        )

                    if not ok then

                        log.error(
                            "githubsongs: failed to create directory "
                            .. current
                            .. " : "
                            .. tostring(
                                errorMessage
                            )
                        )

                        return false
                    end
                end
            end
        end


        if windowsDirectoryExists(
            current
        )
        then

            log.info(
                "githubsongs: directory ready "
                .. current
            )

            return true
        end

        log.error(
            "githubsongs: directory verification failed "
            .. current
        )

        return false
    end


    local command =
        "mkdir -p "
        .. shellQuote(path)

    local result =
        os.execute(
            command
        )

    if result == true
        or result == 0
    then

        return true
    end

    return false
end


local function fileExists(path)

    if type(path) ~= "string"
        or path == ""
    then
        return false
    end

    local file =
        io.open(
            path,
            "rb"
        )

    if file then

        file:close()

        return true
    end

    return false
end


local function getFileSize(path)

    local file =
        io.open(
            path,
            "rb"
        )

    if not file then
        return 0
    end

    local current =
        file:seek()

    local size =
        file:seek(
            "end"
        )

    file:close()

    if not size then
        return 0
    end

    if current then
        return size - current
    end

    return size
end


local function normalizeURL(url)

    if type(url) ~= "string" then
        return nil
    end

    return
        url:gsub(
            "^%s+",
            ""
        ):gsub(
            "%s+$",
            ""
        )
end


local function urlEncodePath(path)

    local result = {}

    for i = 1, #path do

        local c =
            path:sub(
                i,
                i
            )

        local b =
            string.byte(c)

        if
            (b >= 48 and b <= 57)
            or (b >= 65 and b <= 90)
            or (b >= 97 and b <= 122)
            or c == "-"
            or c == "_"
            or c == "."
            or c == "~"
        then

            result[#result + 1] =
                c

        elseif c == "/" then

            result[#result + 1] =
                "/"

        else

            result[#result + 1] =
                string.format(
                    "%%%02X",
                    b
                )
        end
    end

    return
        table.concat(result)
end


local okJson, JSONModule =
    pcall(
        require,
        "JSON"
    )

if not okJson then

    JSONModule = nil

    log.warn(
        "githubsongs: JSON module unavailable"
    )
end

local JSON = JSONModule


local function decodeJSON(text)

    if not JSON then

        return nil,
            "JSON module unavailable"
    end

    if type(text) ~= "string" then

        return nil,
            "JSON input must be a string"
    end

    local ok, result =
        pcall(
            function()
                return JSON:decode(text)
            end
        )

    if not ok then

        return nil,
            tostring(result)
    end

    if type(result) ~= "table" then

        return nil,
            "JSON root is not a table"
    end

    return result
end


local function logResponsePreview(body)

    if type(body) ~= "string" then
        return
    end

    local preview =
        body:sub(
            1,
            500
        )

    preview =
        preview:gsub(
            "[\r\n]",
            " "
        )

    log.info(
        "githubsongs: response preview = "
        .. preview
    )
end


local function removeUTF8BOM(text)

    if type(text) ~= "string" then
        return text
    end

    if
        #text >= 3
        and text:byte(1) == 0xEF
        and text:byte(2) == 0xBB
        and text:byte(3) == 0xBF
    then

        return
            text:sub(4)
    end

    return text
end


local function curlGET(url, accept)

    if not checkCurl() then

        return false,
            nil,
            "curl is not available"
    end

    url =
        normalizeURL(url)

    if not url then

        return false,
            nil,
            "invalid URL"
    end

    log.info(
        "githubsongs: curl GET "
        .. url
    )

    local command =
        CURL_COMMAND
        .. " -sS"
        .. " -L"
        .. " --fail-with-body"
        .. " --max-time 60"
        .. " --retry 2"
        .. " --retry-delay 1"
        .. " -A "
        .. shellQuote(
            USER_AGENT
        )
        .. " -H "
        .. shellQuote(
            "Accept: "
            .. (
                accept
                or "application/vnd.github+json"
            )
        )
        .. " -H "
        .. shellQuote(
            "X-GitHub-Api-Version: 2022-11-28"
        )
        .. " -- "
        .. shellQuote(url)

    local pipe, err =
        io.popen(
            command,
            "r"
        )

    if not pipe then

        return false,
            nil,
            "curl execution failed: "
            .. tostring(err)
    end

    local body =
        pipe:read("*a")

    local closeOK,
          closeReason,
          closeCode =
        pipe:close()

    if not body then
        body = ""
    end

    body =
        removeUTF8BOM(body)

    if body == "" then

        return false,
            nil,
            "curl returned empty response"
    end

    if not closeOK then

        log.warn(
            "githubsongs: curl reported failure"
        )

        logResponsePreview(body)

        return false,
            body,
            "curl request failed"
    end

    return true,
        body,
        nil
end


local function getLocalPath(remotePath)

    if type(remotePath) ~= "string" then
        return nil
    end

    local path =
        remotePath

    if path:sub(1, 6)
        == "Songs/"
    then

        path =
            path:sub(7)
    end

    local folder, file =
        path:match(
            "^([^/]+)/(.+)$"
        )

    if not folder
        or not file
    then
        return nil
    end

    if not state.gameDirectory then
        return nil
    end

    return
        state.gameDirectory
        .. "/"
        .. SONGS_DIR
        .. "/"
        .. folder
        .. "/"
        .. file
end


local function isSongFile(path)

    if type(path) ~= "string" then
        return false
    end

    local lower =
        path:lower()

    return
        lower:match("%.sfl$")
        or lower:match("%.ogg$")
        or lower:match("%.wav$")
        or lower:match("%.mp3$")
        or lower:match("%.flac$")
        or lower:match("%.png$")
        or lower:match("%.jpg$")
        or lower:match("%.jpeg$")
end


local function buildSongList(tree)

    local folders = {}

    for _, entry
        in ipairs(tree)
    do

        if type(entry) == "table"
            and entry.type == "blob"
            and type(entry.path) == "string"
        then

            local path =
                entry.path

            if path:sub(1, 6)
                == "Songs/"
            then

                path =
                    path:sub(7)
            end

            local folder =
                path:match(
                    "^([^/]+)/"
                )

            if folder then

                if not folders[folder] then

                    folders[folder] = {
                        name = folder,
                        files = {}
                    }
                end

                if isSongFile(path) then

                    folders[folder].files[
                        #folders[folder].files + 1
                    ] = {

                        path = entry.path,

                        sha = entry.sha,

                        size =
                            tonumber(
                                entry.size
                            )
                            or 0
                    }
                end
            end
        end
    end

    local songs = {}

    for _, song
        in pairs(folders)
    do

        local hasSFL = false

        for _, file
            in ipairs(song.files)
        do

            if file.path
                :lower()
                :match("%.sfl$")
            then

                hasSFL = true

                break
            end
        end

        if hasSFL then

            table.sort(
                song.files,
                function(a, b)

                    return
                        a.path:lower()
                        <
                        b.path:lower()
                end
            )

            songs[
                #songs + 1
            ] = song
        end
    end

    table.sort(
        songs,
        function(a, b)

            return
                a.name:lower()
                <
                b.name:lower()
        end
    )

    return songs
end


local function fetchTree()

    log.info(
        "githubsongs: fetching repository tree"
    )

    log.info(
        "githubsongs: API = "
        .. API_TREE_URL
    )

    local ok, body, err =
        curlGET(
            API_TREE_URL,
            "application/vnd.github+json"
        )

    if not ok then

        if body
            and type(body) == "string"
            and body ~= ""
        then

            log.error(
                "githubsongs: tree HTTP body:"
            )

            logResponsePreview(body)

            local errorData =
                decodeJSON(body)

            if type(errorData) == "table"
                and errorData.message
            then

                return false,
                    "GitHub API: "
                    .. tostring(
                        errorData.message
                    )
            end
        end

        return false,
            "Tree request failed: "
            .. tostring(err)
    end

    if type(body) ~= "string"
        or body == ""
    then

        return false,
            "GitHub tree response was empty"
    end

    log.info(
        "githubsongs: tree response length = "
        .. tostring(#body)
    )

    local data, jsonError =
        decodeJSON(body)

    if type(data) ~= "table" then

        log.error(
            "githubsongs: invalid JSON response"
        )

        if jsonError then

            log.error(
                "githubsongs: JSON error = "
                .. tostring(jsonError)
            )
        end

        logResponsePreview(body)

        return false,
            "Failed to decode GitHub tree JSON"
    end

    if data.message then

        return false,
            "GitHub API: "
            .. tostring(
                data.message
            )
    end

    if data.truncated then

        return false,
            "GitHub tree is truncated"
    end

    if type(data.tree) ~= "table" then

        return false,
            "GitHub tree field is missing"
    end

    state.tree =
        data.tree

    state.songs =
        buildSongList(
            data.tree
        )

    log.info(
        "githubsongs: tree entries = "
        .. tostring(
            #data.tree
        )
    )

    log.info(
        "githubsongs: found "
        .. tostring(
            #state.songs
        )
        .. " songs"
    )

    return true
end


local function prepareDownloads()

    local pending = {}

    for songIndex, song
        in ipairs(state.songs)
    do

        state.songIndex =
            songIndex

        state.currentSong =
            song.name

        log.info(
            "githubsongs: preparing song "
            .. tostring(songIndex)
            .. "/"
            .. tostring(#state.songs)
            .. " "
            .. tostring(song.name)
        )

        for fileIndex, file
            in ipairs(song.files)
        do

            state.fileIndex =
                fileIndex

            local localPath =
                getLocalPath(
                    file.path
                )

            if not localPath then

                state.failedFiles =
                    state.failedFiles + 1

                state.completedFiles =
                    state.completedFiles + 1

                log.warn(
                    "githubsongs: invalid local path "
                    .. tostring(
                        file.path
                    )
                )

            else

                local parent =
                    localPath:match(
                        "^(.*)/[^/]+$"
                    )

                if parent
                    and not ensureDirectory(parent)
                then

                    state.failedFiles =
                        state.failedFiles + 1

                    state.completedFiles =
                        state.completedFiles + 1

                    log.warn(
                        "githubsongs: cannot create directory "
                        .. parent
                    )

                elseif fileExists(localPath) then

                    local existingSize =
                        getFileSize(
                            localPath
                        )

                    local expectedSize =
                        tonumber(file.size)
                        or 0


                    if expectedSize > 0
                        and existingSize ~= expectedSize
                    then

                        log.info(
                            "githubsongs: existing file size mismatch, "
                            .. "redownloading "
                            .. file.path
                        )

                        pending[
                            #pending + 1
                        ] = {

                            file = file,

                            localPath = localPath,

                            url =
                                RAW_ROOT
                                .. urlEncodePath(
                                    file.path
                                ),

                            expectedSize =
                                expectedSize
                        }

                    else

                        state.skipped =
                            state.skipped + 1

                        state.completedFiles =
                            state.completedFiles + 1

                        state.bytesDownloaded =
                            state.bytesDownloaded
                            + existingSize

                        log.info(
                            "githubsongs: skip existing "
                            .. localPath
                        )
                    end

                else

                    pending[
                        #pending + 1
                    ] = {

                        file = file,

                        localPath = localPath,

                        url =
                            RAW_ROOT
                            .. urlEncodePath(
                                file.path
                            ),

                        expectedSize =
                            tonumber(file.size)
                            or 0
                    }
                end
            end
        end
    end

    state.currentSong = ""
    state.currentFile = ""

    return pending
end


local function buildParallelCurlCommand(
    pending,
    firstIndex,
    lastIndex
)

    local commandParts = {}

    commandParts[
        #commandParts + 1
    ] =
        CURL_COMMAND

    commandParts[
        #commandParts + 1
    ] =
        "-sS"

    commandParts[
        #commandParts + 1
    ] =
        "-L"

    commandParts[
        #commandParts + 1
    ] =
        "--fail-with-body"

    commandParts[
        #commandParts + 1
    ] =
        "--parallel"

    commandParts[
        #commandParts + 1
    ] =
        "--parallel-max "
        .. tostring(
            PARALLEL_COUNT
        )

    commandParts[
        #commandParts + 1
    ] =
        "--retry 2"

    commandParts[
        #commandParts + 1
    ] =
        "--retry-delay 1"

    commandParts[
        #commandParts + 1
    ] =
        "--max-time 300"

    commandParts[
        #commandParts + 1
    ] =
        "-A "
        .. shellQuote(
            USER_AGENT
        )

    commandParts[
        #commandParts + 1
    ] =
        "-H "
        .. shellQuote(
            "Accept: */*"
        )


    for i = firstIndex, lastIndex do

        local item =
            pending[i]

        commandParts[
            #commandParts + 1
        ] =
            "-o "
            .. shellQuote(
                item.localPath
            )

        commandParts[
            #commandParts + 1
        ] =
            shellQuote(
                item.url
            )
    end

    return
        table.concat(
            commandParts,
            " "
        )
end


local function validateDownloadedFile(item)

    if not fileExists(
        item.localPath
    )
    then

        return false,
            "output file does not exist"
    end

    local actualSize =
        getFileSize(
            item.localPath
        )

    if actualSize <= 0 then

        return false,
            "output file is empty"
    end

    if item.expectedSize
        and item.expectedSize > 0
        and actualSize
            ~= item.expectedSize
    then

        return false,
            "size mismatch expected="
            .. tostring(
                item.expectedSize
            )
            .. " received="
            .. tostring(
                actualSize
            )
    end

    return true,
        actualSize
end


local function removeFile(path)

    if type(path) ~= "string"
        or path == ""
    then
        return
    end

    pcall(
        os.remove,
        path
    )
end


local function downloadParallelBatch(
    pending,
    firstIndex,
    lastIndex
)

    if firstIndex > lastIndex then
        return true
    end

    log.info(
        "githubsongs: parallel batch "
        .. tostring(firstIndex)
        .. "-"
        .. tostring(lastIndex)
        .. "/"
        .. tostring(#pending)
    )

    log.info(
        "githubsongs: parallel curl max="
        .. tostring(PARALLEL_COUNT)
    )


    local first =
        pending[firstIndex]

    if first
        and first.file
    then

        state.currentFile =
            first.file.path
    end


    local command =
        buildParallelCurlCommand(
            pending,
            firstIndex,
            lastIndex
        )

    log.info(
        "githubsongs: starting curl parallel process"
    )


    local pipe, err =
        io.popen(
            command,
            "r"
        )

    if not pipe then

        log.error(
            "githubsongs: parallel curl execution failed: "
            .. tostring(err)
        )

        for i = firstIndex, lastIndex do

            local item =
                pending[i]

            removeFile(
                item.localPath
            )

            state.failedFiles =
                state.failedFiles + 1

            state.completedFiles =
                state.completedFiles + 1
        end

        return false
    end


    local output =
        pipe:read("*a")

    local closeOK,
          closeReason,
          closeCode =
        pipe:close()

    if output
        and output ~= ""
    then

        log.info(
            "githubsongs: curl output = "
            .. output:sub(
                1,
                1000
            )
        )
    end

    log.info(
        "githubsongs: parallel curl close = "
        .. tostring(closeOK)
        .. " reason="
        .. tostring(closeReason)
        .. " code="
        .. tostring(closeCode)
    )


    local batchOK = true

    for i = firstIndex, lastIndex do

        local item =
            pending[i]

        state.currentFile =
            item.file.path

        local valid,
              sizeOrError =
            validateDownloadedFile(
                item
            )

        if valid then

            state.downloaded =
                state.downloaded + 1

            state.completedFiles =
                state.completedFiles + 1

            state.bytesDownloaded =
                state.bytesDownloaded
                + tonumber(
                    sizeOrError
                )

            log.info(
                "githubsongs: downloaded "
                .. item.file.path
                .. " ("
                .. tostring(
                    sizeOrError
                )
                .. " bytes)"
            )

        else

            state.failedFiles =
                state.failedFiles + 1

            state.completedFiles =
                state.completedFiles + 1

            batchOK = false

            log.warn(
                "githubsongs: download failed "
                .. item.file.path
                .. " : "
                .. tostring(
                    sizeOrError
                )
            )


            removeFile(
                item.localPath
            )
        end
    end

    state.currentFile = ""

    return batchOK
end


function githubsongs.start()

    resetState()

    state.started = true
    state.status = "connecting"

    log.info(
        "================================"
    )

    log.info(
        "githubsongs: synchronization started"
    )

    log.info(
        "githubsongs: repository = "
        .. REPO_OWNER
        .. "/"
        .. REPO_NAME
    )


    local gameDirectory,
          gameDirectoryError =
        getGameDirectory()

    if not gameDirectory then

        state.failed = true
        state.status = "failed"

        state.error =
            gameDirectoryError

        log.error(
            "githubsongs: "
            .. tostring(
                state.error
            )
        )

        return false
    end

    state.gameDirectory =
        gameDirectory

    log.info(
        "githubsongs: game directory = "
        .. tostring(
            gameDirectory
        )
    )


    local writeOK, writeDir =
        getWriteDirectory()

    if writeOK then

        state.writeDir =
            writeDir

        log.info(
            "githubsongs: PhysicsFS WriteDir = "
            .. tostring(
                writeDir
            )
        )

        log.info(
            "githubsongs: PhysicsFS WriteDir is NOT used "
            .. "for song downloads"
        )

    else

        log.warn(
            "githubsongs: could not read PhysicsFS WriteDir: "
            .. tostring(
                writeDir
            )
        )
    end


    if not checkCurl() then

        state.failed = true
        state.status = "failed"

        state.error =
            "curl is required"

        log.error(
            "githubsongs: "
            .. state.error
        )

        return false
    end


    if not JSON then

        state.failed = true
        state.status = "failed"

        state.error =
            "JSON module is required"

        log.error(
            "githubsongs: "
            .. state.error
        )

        return false
    end


    local songsDirectory =
        gameDirectory
        .. "/"
        .. SONGS_DIR

    if not ensureDirectory(
        songsDirectory
    )
    then

        state.failed = true
        state.status = "failed"

        state.error =
            "Cannot create Songs directory"

        log.error(
            "githubsongs: "
            .. state.error
        )

        return false
    end

    log.info(
        "githubsongs: output directory = "
        .. songsDirectory
    )


    local ok, err =
        fetchTree()

    if not ok then

        state.failed = true
        state.status = "failed"

        state.error =
            err

        log.error(
            "githubsongs: "
            .. tostring(err)
        )

        return false
    end


    state.totalFiles = 0
    state.totalBytes = 0

    for _, song
        in ipairs(state.songs)
    do

        state.totalFiles =
            state.totalFiles
            + #song.files

        for _, file
            in ipairs(song.files)
        do

            state.totalBytes =
                state.totalBytes
                + (
                    tonumber(
                        file.size
                    )
                    or 0
                )
        end
    end

    log.info(
        "githubsongs: songs="
        .. tostring(
            #state.songs
        )
        .. " files="
        .. tostring(
            state.totalFiles
        )
        .. " bytes="
        .. tostring(
            state.totalBytes
        )
    )


    if #state.songs == 0 then

        state.status =
            "finished"

        state.finished = true

        log.info(
            "githubsongs: no songs found"
        )

        log.info(
            "================================"
        )

        return true
    end


    state.status =
        "preparing"

    local pending =
        prepareDownloads()

    log.info(
        "githubsongs: pending downloads = "
        .. tostring(
            #pending
        )
    )


    if #pending == 0 then

        if state.failedFiles > 0 then

            state.failed = true

            state.status =
                "finished_with_errors"

        else

            state.failed = false

            state.status =
                "finished"
        end

        state.finished = true

        state.currentSong = ""
        state.currentFile = ""

        log.info(
            "githubsongs: no new files need downloading"
        )

        log.info(
            "githubsongs: downloaded="
            .. tostring(
                state.downloaded
            )
            .. " skipped="
            .. tostring(
                state.skipped
            )
            .. " failed="
            .. tostring(
                state.failedFiles
            )
        )

        log.info(
            "================================"
        )

        return
            state.failedFiles == 0
    end


    state.status =
        "downloading"

    local allOK = true

    local firstIndex = 1

    while firstIndex <= #pending do

        local lastIndex =
            math.min(
                firstIndex
                + PARALLEL_BATCH_SIZE
                - 1,
                #pending
            )

        local batchOK =
            downloadParallelBatch(
                pending,
                firstIndex,
                lastIndex
            )

        if not batchOK then
            allOK = false
        end

        firstIndex =
            lastIndex + 1
    end


    if state.failedFiles > 0
        or not allOK
    then

        state.failed = true

        state.status =
            "finished_with_errors"

        log.warn(
            "githubsongs: synchronization "
            .. "finished with errors"
        )

    else

        state.failed = false

        state.status =
            "finished"

        log.info(
            "githubsongs: synchronization finished"
        )
    end

    state.finished = true

    state.currentSong = ""
    state.currentFile = ""


    log.info(
        "githubsongs: downloaded="
        .. tostring(
            state.downloaded
        )
        .. " skipped="
        .. tostring(
            state.skipped
        )
        .. " failed="
        .. tostring(
            state.failedFiles
        )
    )

    log.info(
        "githubsongs: bytes="
        .. tostring(
            state.bytesDownloaded
        )
        .. "/"
        .. tostring(
            state.totalBytes
        )
    )

    log.info(
        "githubsongs: gameDirectory="
        .. tostring(
            state.gameDirectory
        )
    )

    log.info(
        "githubsongs: Songs="
        .. tostring(
            state.gameDirectory
            .. "/"
            .. SONGS_DIR
        )
    )

    log.info(
        "================================"
    )

    return
        state.failedFiles == 0
end


function githubsongs.update()
end


function githubsongs.isFinished()

    return
        state.finished
end

function githubsongs.hasFailed()

    return
        state.failed
end

function githubsongs.getError()

    return
        state.error
end

function githubsongs.getProgress()

    if state.totalFiles <= 0 then

        if state.finished then
            return 1
        end

        return 0
    end

    local progress =
        state.completedFiles
        / state.totalFiles

    if progress < 0 then
        return 0
    end

    if progress > 1 then
        return 1
    end

    return progress
end

function githubsongs.getState()

    return state
end

function githubsongs.getSongs()

    return state.songs
end

function githubsongs.getStatus()

    return state.status
end


function githubsongs.getSongIndex()

    return state.songIndex
end

function githubsongs.getFileIndex()

    return state.fileIndex
end

function githubsongs.getTotalFiles()

    return state.totalFiles
end

function githubsongs.getCompletedFiles()

    return state.completedFiles
end

function githubsongs.getDownloaded()

    return state.downloaded
end

function githubsongs.getSkipped()

    return state.skipped
end

function githubsongs.getFailedFiles()

    return state.failedFiles
end

function githubsongs.getBytesDownloaded()

    return state.bytesDownloaded
end

function githubsongs.getTotalBytes()

    return state.totalBytes
end

function githubsongs.getCurrentSong()

    return state.currentSong
end

function githubsongs.getCurrentFile()

    return state.currentFile
end

function githubsongs.getCurlVersion()

    return curlVersion
end

function githubsongs.getWriteDir()

    return state.writeDir
end

function githubsongs.getGameDirectory()

    return state.gameDirectory
end


return githubsongs
