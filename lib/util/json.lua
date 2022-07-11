local json = require("json")
local file = require("util.file")
local ujson = {}

function ujson.readTableAsJSON(path)
    if json then
        local content = util.read(path)
        return json.decode(content)
    end
end

function ujson.writeTableAsJSON(path, tbl)
    if json then
        local content = util.write(path, json.encode(tbl))
    end
end

return ujson