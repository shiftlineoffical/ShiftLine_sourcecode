--[[
変数表
sflfoldname: 曲のフォルダ名を格納するテーブル
filelist: 曲のフォルダ内のファイル名を格納するテーブル
関数表
notesetting.load(): 曲のフォルダ名を取得してテーブルに格納する
foldName: 曲のフォルダ名
songPath: 曲のフォルダのパス
sflpath: sflファイルのパス



notesetting.load()の処理の流れ
1. "lib/data/Songs"ディレクトリ内のアイテムを取得し、テーブルsongsfoldに格納する
2. songsfoldをアルファベット順にソートする
3. sflfoldnameとsflpathという空のテーブルを作成する
4. songsfoldの各アイテムについて以下の処理を行う
    a. アイテムがディレクトリであるか確認する
    b. ディレクトリ内のアイテムを取得し、テーブルsongsfoldに格納する
    c. songsfoldをアルファベット順にソートする
    d. ディレクトリ内のアイテムを順番に確認し、拡張子が.sflのファイルがあればそのパスをchartPathに格納し、ループを抜ける
    f. chartPathが見つかった場合、sflfoldnameにフォルダ名を、sflpathにchartPathを格納する
5. sflfoldnameとsflpathという空のテーブルを作成する
6. sflfoldnameの最初の要素が存在する場合、そのフォルダ内のアイテムを取得し、テーブルfilelistに格納する
7. filelistをアルファベット順にソートする
8. sflfoldnameとfilelist、sflpathを返す



sflpathの内容
sflpathは、"lib/data/Songs"ディレクトリ内の各曲のフォルダに存在する.sflファイルのパスを格納するテーブル
例えば、"lib/data/Songs/ExampleSong/ExampleSong.sfl"のようなパスが格納される



    ]]

local scratchsfl = {}


scratchsfl.foldname={}
scratchsfl.list={}
scratchsfl.path={}
scratchsfl.basePath={}  -- 各楽曲のベースパス（lib/data/SongsまたはAPPDATA/ShiftLine/Songs）

local log = require("log")


function scratchsfl.load()
    local function listDir(path)
        local ok, items = pcall(love.filesystem.getDirectoryItems, path)
        if ok and type(items) == "table" and #items > 0 then
            table.sort(items)
            return items
        end

        local okLfs, lfs = pcall(require, "lfs")
        if okLfs and lfs then
            local out = {}
            for name in lfs.dir(path) do
                if name ~= "." and name ~= ".." then
                    out[#out+1] = name
                end
            end
            table.sort(out)
            return out
        end

        local sep = package.config:sub(1,1)
        local cmd
        if sep == '\\' then
            cmd = 'dir /b "'..path..'"'
        else
            cmd = 'ls -A "'..path..'"'
        end
        local p = io.popen(cmd)
        if p then
            local out = {}
            for line in p:lines() do
                out[#out+1] = line
            end
            p:close()
            table.sort(out)
            return out
        end

        return {}
    end

    local basePaths = {"lib/data/Songs"}
    -- AppData（保存領域）はまず LÖVE のファイルシステム内の相対パスを優先して参照する
    if love and love.filesystem and love.filesystem.getSaveDirectory then
        basePaths[#basePaths+1] = "ShiftLine/Songs"
    else
        local appdata = os.getenv("APPDATA") or os.getenv("HOME")
        if appdata then
            local appSongs = appdata .. "/ShiftLine/Songs"
            basePaths[#basePaths+1] = appSongs
        end
    end

    local sflfoldname = {}
    local sflpath = {}
    local basePath = {}

    log.info('scratchsfl: scanning basePaths: '..table.concat(basePaths, ', '))
    for _, base in ipairs(basePaths) do
        local entries = listDir(base)
        for i = 1, #entries do
            local foldName = entries[i]
            local songPath = base .. "/" .. foldName
            local isDir = false

            local okInfo, info = pcall(love.filesystem.getInfo, songPath)
            if okInfo and info and info.type == "directory" then
                isDir = true
            else
                local okLfs, lfs = pcall(require, "lfs")
                if okLfs and lfs then
                    local attr = lfs.attributes(songPath)
                    if attr and attr.mode == "directory" then isDir = true end
                end
            end

            if isDir then
                local items = listDir(songPath)
                local chartPath = nil
                for j = 1, #items do
                    local fname = items[j]
                    local lowerName = string.lower(fname)
                    if lowerName:match("%.sfl$") then
                        chartPath = songPath .. "/" .. fname
                        break
                    end
                end

                if chartPath then
                    sflfoldname[#sflfoldname + 1] = foldName
                    sflpath[#sflpath + 1] = chartPath
                    basePath[#basePath + 1] = base
                end
            end
        end
    end

    local filelist = {}
    if #sflfoldname > 0 then
        for i = 1, #sflfoldname do
            local folderPath = "lib/data/Songs/" .. sflfoldname[i]
            local items = listDir(folderPath)
            table.sort(items)
            for _, item in ipairs(items) do
                if string.sub(item, -4) == ".sfb" then
                    filelist[#filelist + 1] = item
                end
            end
        end
    end
    scratchsfl.foldname, scratchsfl.list, scratchsfl.path, scratchsfl.basePath = sflfoldname, filelist, sflpath, basePath
end

-- モジュールとしてテーブルを返す
return scratchsfl, scratchsfl.foldname, scratchsfl.list, scratchsfl.path


