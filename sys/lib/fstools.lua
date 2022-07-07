function save(table, filePath)
    local file = fs.open(filePath,"w")
    serializedTable = nil
    function serializeTable()
        serializedTable = textutils.serialize(table)
    end
    if pcall(serializeTable) then
        file.write(serializedTable)
    else
        -- print("Failure")
    end
    file.close()
end

function load(filePath)
    local file = fs.open(filePath,"r")
    local data = file.readAll()
    file.close()
    loadedTable = textutils.unserialize(data)
    if not loadedTable then
        loadedTable = {}
    end
    return loadedTable
end