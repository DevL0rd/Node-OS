-----------------
--MISC Function--
function deepcopy(orig)
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
function getWords(str)
    local words = {}
    for word in str:gmatch("%S+") do table.insert(words, word) end
    return words
end
function listToString(list)
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
function isInt(n)
    return (type(n) == "number") and (math.floor(n) == n)
end
function isNan(n)
    return (tostring(n) == "nan")
end
function getCharOfLength(char, len)
    local nStr = ""
    while(len > 0) do
        nStr = nStr .. char
        len = len - 1
    end
    return nStr
end
function split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end