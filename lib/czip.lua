--very simple file packing tool <3 Devl0rd
czip = {}

local makeFileTable = function (path)
    --recursively get everyfile in folder
    local files = {}
    local folders = {}
    if fs.isDir(path) then
        local function getFiles(path)
            for i, file in pairs(fs.list(path)) do
                if fs.isDir(path .. "/" .. file) then
                    getFiles(path .. "/" .. file)
                else
                    table.insert(files, path .. "/" .. file)
                end
            end
            if #files > 0 then
                return table.insert(folders, path)
            end
        end
        getFiles(path)
    else
        table.insert(files, path)
    end
    local fileTable = {}
    for i, filePath in pairs(files) do
        local file = fs.open(filePath, "r")
        local fileData = file.readAll()
        file.close()
        fileTable[filePath] = {
            isDir = false,
            data = fileData
        }
    end
    for i, folder in pairs(folders) do
        fileTable[folder] = {
            isDir = true
        }
    end
    return fileTable
end

czip.compress = function (path, outputFile)
    local fileTable = makeFileTable(path)
    local archiveData = textutils.serialize(fileTable)
    local file = fs.open(outputFile, "w")
    file.write(archiveData)
    file.close()
end

czip.add = function (path, outputFile)
    local fileTable = makeFileTable(path)
    local file = fs.open(outputFile, "r")
    local archiveData = file.readAll()
    file.close()
    archiveData = textutils.unserialize(archiveData)
    for fPath, fileData in pairs(fileTable) do
        archiveData[fPath] = fileData
    end
    archiveData = textutils.serialize(archiveData)
    local file = fs.open(outputFile, "w")
    file.write(archiveData)
    file.close()
end

czip.decompress = function (path, inputFile)
    local file = fs.open(inputFile, "r")
    local archiveData = file.readAll()
    file.close()
    archiveData = textutils.unserialize(archiveData)
    for fPath, fileData in pairs(archiveData) do
        if fileData.isDir then
            if not fs.exists(path .. "/" .. fPath) then
                fs.makeDir(path .. "/" .. fPath)
            end
        else
            local file = fs.open(path .. "/" .. fPath, "w")
            file.write(fileData.data)
            file.close()
        end
    end
end
return czip