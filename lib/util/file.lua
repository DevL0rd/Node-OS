local ufile = {}

function ufile.read(path)
    if fs.exists(path) then
        local file = fs.open(path, "r")
        local content = file.readAll()
        file.close()
        return content
    end
end

function ufile.write(path, contents)
    local file = fs.open(path, "w")
    file.write(contents)
    file.close()
    return true
end

function ufile.writeTable(path, table)
    return ufile.write(path, textutils.serialize(table))
end

function ufile.readTable(path)
    if fs.exists(path) then
        return textutils.unserialize(ufile.read(path))
    end
end

-- Gets the number of files inside of a folder.
function ufile.getFileCount(folder)
	return #fs.list(folder)
end

return ufile