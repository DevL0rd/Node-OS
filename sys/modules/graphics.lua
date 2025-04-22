local module = {}

function module.init(nodeos, native, termWidth, termHeight)
    local graphics = {}
    function graphics.print(text, fgColor, bgColor)
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
        graphics.endRender()
    end

    function graphics.write(text, x, y, fgColor, bgColor, align)
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

    function graphics.newLine()
        print("")
    end

    function graphics.centerText(text, line, fgColor, bgColor)
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
        graphics.write(text, 1, line, fgColor, bgColor, "center")
    end

    function graphics.alignLeft(text, line, fgColor, bgColor)
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
        graphics.write(text, 1, line, fgColor, bgColor)
    end

    function graphics.alignRight(text, line, fgColor, bgColor)
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
        graphics.write(text, 1, line, fgColor, bgColor, "right")
    end

    function graphics.fillLine(char, line, fgColor, bgColor)
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
        graphics.write(char, 1, line, fgColor, bgColor, "fill")
    end

    function graphics.fillLineWithBorder(bchar, line, fgColor, bgColor)
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
        graphics.fillLine(" ", line, fgColor, bgColor)
        graphics.write(bchar, 1, line, fgColor, bgColor)
        graphics.write(bchar, 1, line, fgColor, bgColor, "right")
    end

    function graphics.drawLine(x1, y1, x2, y2, color)
        local dx = math.abs(x2 - x1)
        local dy = -math.abs(y2 - y1)
        local sx = x1 < x2 and 1 or -1
        local sy = y1 < y2 and 1 or -1
        local err = dx + dy
        local e2
        local tx, ty = term.getSize()
        while true do
            -- Check bounds before drawing

            if x1 >= 1 and x1 <= tx and y1 >= 1 and y1 <= ty then
                -- Use a character for the line, ensure background doesn't overwrite map
                graphics.write(" ", x1, y1, color, color)
            end

            if x1 == x2 and y1 == y2 then break end
            e2 = 2 * err
            if e2 >= dy then
                err = err + dy
                x1 = x1 + sx
            end
            if e2 <= dx then
                err = err + dx
                y1 = y1 + sy
            end
        end
    end

    function graphics.endRender()
        nodeos.drawProcess()
    end

    nodeos.graphics = graphics
end

return module
