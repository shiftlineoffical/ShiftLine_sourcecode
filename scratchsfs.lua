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

local scratchsfs = {}


scratchsfs.foldname={}
scratchsfs.list={}
scratchsfs.path={}

local log = require("log")


function scratchsfs.load()
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

    local basePaths = {"lib/data/Storys"}
    local appdata = os.getenv("APPDATA") or os.getenv("HOME")
    if appdata then
        local appSongs = appdata .. "/ShiftLine/Storys"
        basePaths[#basePaths+1] = appSongs
    end

    local sflfoldname = {}
    local sflpath = {}

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
                local chartPaths = {}
                for j = 1, #items do
                    local fname = items[j]
                    local lowerName = string.lower(fname)
                    if lowerName:match("%.sfs$") then
                        chartPaths[#chartPaths + 1] = songPath .. "/" .. fname
                    end
                end

                if #chartPaths > 0 then
                    for _, chartPath in ipairs(chartPaths) do
                        sflfoldname[#sflfoldname + 1] = foldName
                        sflpath[#sflpath + 1] = chartPath
                    end
                end
            elseif string.lower(foldName):match("%.sfs$") then
                -- 直接 Storys フォルダ内に .sfs がある場合も対応
                local chartPath = base .. "/" .. foldName
                sflfoldname[#sflfoldname + 1] = foldName:gsub("%.sfs$", "")
                sflpath[#sflpath + 1] = chartPath
            end
        end
    end

    local filelist = {}
    if #sflfoldname > 0 then
        for i = 1, #sflfoldname do
            local folderPath = "lib/data/Storys/" .. sflfoldname[i]
            local items = listDir(folderPath)
            table.sort(items)
            for _, item in ipairs(items) do
                if string.sub(item, -4) == ".sfs" then
                    filelist[#filelist + 1] = item
                end
            end
        end
    end
    scratchsfs.foldname, scratchsfs.list, scratchsfs.path= sflfoldname, filelist, sflpath
    log.info('scratchsfs: found ' .. tostring(#sflfoldname) .. ' stories, ' .. tostring(#sflpath) .. ' sfs paths')
end

-- モジュールとしてテーブルを返す
return scratchsfs, scratchsfs.foldname, scratchsfs.list, scratchsfs.path


