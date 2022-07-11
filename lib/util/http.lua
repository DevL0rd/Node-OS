local uhttp = {}

function uhttp.fetch(url)
    local file = http.get(url)
    local content = file.readAll()
    return content
end

return uhttp