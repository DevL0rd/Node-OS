local function newRead(win, contents, rchar)
    local outstr = contents or ""
    local cursorPos = 0
    local function draw()
        win.setCursorBlink(true)
        win.setBackgroundColor(colors.gray)
        win.clear()
        win.setTextColor(colors.lightGray)
        win.setCursorPos(1, 1)
        local w, h = win.getSize()
        local printstr = outstr
        if string.len(printstr) > w then
            printstr = printstr:sub(string.len(printstr) - w + 2, string.len(printstr))
        end

        if rchar then
            win.write(string.rep(rchar, string.len(printstr)))
        else
            win.write(printstr)
        end
    end

    while true do
        draw()
        local e = { os.pullEvent() }
        if e[1] == "char" then
            outstr = outstr .. e[2]
        elseif e[1] == "key" then
            local key = e[2]
            if key == keys.enter then
                win.setCursorBlink(false)
                return outstr
            elseif key == keys.backspace then
                outstr = outstr:sub(1, string.len(outstr) - 1)
            elseif key == keys.tab then
                win.setCursorBlink(false)
                return outstr, true
            end
        end
    end
end

local function newTextbox(x, y, w, rchar, placeholderText, contents, bg, fg)
    if not bg then bg = colors.gray end
    if not fg then fg = colors.lightGray end
    local prevTerm = term.current()
    local win = window.create(prevTerm, x, y, w, 1)
    if not contents then contents = "" end
    local newContent

    local obj = {}

    obj.redraw = function()
        win.setBackgroundColor(bg)
        win.clear()
        win.setTextColor(fg)
        win.setCursorPos(1, 1)
        win.write(newContent or contents)
        if contents == "" and placeholderText then
            win.write(placeholderText)
        end
    end

    obj.select = function(clear)
        if clear == true then
            contents = ""
        end
        win.setCursorPos(1, 1)
        contents, goToNext = newRead(win, contents, rchar)
        win.clear()
        win.setCursorPos(1, 1)
        newContent = contents
        if rchar then
            newContent = string.rep(rchar, string.len(newContent))
        end
        if string.len(newContent) > w then
            newContent = newContent:sub(1, w - 3)
            newContent = newContent .. "..."
        end
        win.write(newContent)
        if contents == "" and placeholderText then
            win.write(placeholderText)
        end

        obj.redraw()

        return contents, goToNext
    end

    obj.getContent = function()
        return contents
    end

    obj.redraw()
    return obj
end

return {
    new = newTextbox
}
