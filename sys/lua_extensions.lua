function _G.saveTable(path, table)
    local file = fs.open(path, "w")
    file.write(textutils.serialize(table))
    file.close()
end

function _G.loadTable(path)
    if fs.exists(path) then
        local file = fs.open(path, "r")
        local content = file.readAll()
        file.close()
        return textutils.unserialize(content)
    else
        return nil
    end
end

local packageDirs = loadTable("/etc/libs.cfg")
for i, v in pairs(packageDirs) do
    package.path = package.path .. ";" .. v
end
_G.package = package
_G.shell = shell

function _G.deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

function _G.getWords(str)
    local words = {}
    for word in str:gmatch("%S+") do table.insert(words, word) end
    return words
end

function _G.listToString(list)
    local str = nil
    for i, word in pairs(list) do
        if str then
            str = str .. " " .. word
        else
            str = word
        end
    end
    return str
end

function _G.isInt(n)
    return (type(n) == "number") and (math.floor(n) == n)
end

function _G.isNan(n)
    return (tostring(n) == "nan")
end

function _G.getCharOfLength(char, len)
    local nStr = ""
    while (len > 0) do
        nStr = nStr .. char
        len = len - 1
    end
    return nStr
end

function _G.split(s, delimiter)
    result = {};
    for match in (s .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, match);
    end
    return result;
end
