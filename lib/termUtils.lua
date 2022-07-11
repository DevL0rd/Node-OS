local termUtils = {}
function termUtils.print(text, fgColor, bgColor)
    if not fgColor or not colors[fgColor] then
        fgColor = "white"
    end
    if not bgColor or not colors[bgColor] then
        bgColor = "black"
    end
    term.setTextColor(colors[fgColor])
    term.setBackgroundColor(colors[bgColor])
    print(text)
    term.setTextColor(colors["white"])
    term.setBackgroundColor(colors["black"])

end

function termUtils.write(text, x, y, fgColor, bgColor, align)
    local tx, ty = term.getSize()
    local cx, cy = term.getCursorPos()
    if not x then
        x = cx
    end
    if not y then
        y = cy
    end
    if not fgColor or not colors[fgColor] then
        fgColor = "white"
    end
    if not bgColor or not colors[bgColor] then
        bgColor = "black"
    end
    term.setCursorPos(x, y)
    if align == "center" then
        term.setCursorPos(math.ceil((tx / 2) - (text:len() / 2)) + 1, y)
    elseif align == "right" then
        term.setCursorPos(math.ceil(tx - text:len()) + 1, y)
    end
    term.setTextColor(colors[fgColor])
    term.setBackgroundColor(colors[bgColor])
    if align == "fill" then
        write(getCharOfLength(text, tx))
    else
        write(text)
    end
    term.setTextColor(colors["white"])
    term.setBackgroundColor(colors["black"])
    term.setCursorPos(cx, cy)
end

function termUtils.newLine()
    print("")
end

function termUtils.centerText(text, line, fgColor, bgColor)
    local cx, cy = term.getCursorPos()
    if line == nil then
        line = cy
    end
    if fgColor == nil then
        fgColor = "white"
    end
    if bgColor == nil then
        bgColor = "black"
    end
    termUtils.write(text, 1, line, fgColor, bgColor, "center")
end

function termUtils.alignRight(text, line, fgColor, bgColor)
    local cx, cy = term.getCursorPos()
    if line == nil then
        line = cy
    end
    if fgColor == nil then
        fgColor = "white"
    end
    if bgColor == nil then
        bgColor = "black"
    end
    termUtils.write(text, 1, line, fgColor, bgColor, "right")
end

function termUtils.fillLine(char, line, fgColor, bgColor)
    local cx, cy = term.getCursorPos()
    if line == nil then
        line = cy
    end
    if fgColor == nil then
        fgColor = "white"
    end
    if bgColor == nil then
        bgColor = "black"
    end
    termUtils.write(char, 1, line, fgColor, bgColor, "fill")
end

function termUtils.fillLineWithBorder(bchar, line, fgColor, bgColor)
    local tx, ty = term.getSize()
    local cx, cy = term.getCursorPos()
    if line == nil then
        line = cy
    end
    if fgColor == nil then
        fgColor = term_settings.fg
    end
    if bgColor == nil then
        bgColor = term_settings.bg
    end
    termUtils.fillLine(" ", line, fgColor, bgColor)
    termUtils.write(bchar, 1, line, fgColor, bgColor)
    termUtils.write(bchar, 1, line, fgColor, bgColor, "right")
end

return termUtils