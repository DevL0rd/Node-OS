local function createElement(x, y, text, textColor, backgroundColor, clickEvent)
    return {
        x = x,
        y = y,
        text = text,
        textColor = textColor,
        backgroundColor = backgroundColor,
        clickEvent = clickEvent
    }
end

local function new(x, y, w, h, elements, backgroundColor, visible)
    if not visible then visible = true end
    local current = term.current()
    local scrollFrame = window.create(current, x, y, w, h, visible)
    scrollFrame.setBackgroundColor(backgroundColor or colors.black)
    scrollFrame.clear()

    local obj = {}
    local visibleElements = {}
    local scrollPos = 0

    obj.addElement = function(element)
        table.insert(elements, element)
    end
    obj.setElements = function(aElements)
        elements = aElements
    end
    obj.removeElement = function(id)
        table.remove(elements, id)
    end
    obj.getElements = function()
        return elements
    end
    obj.getWidth = function()
        return w
    end
    obj.resize = function(nw, nh)
        w = nw    
        h = nh
    end
    obj.scrollToTop = function()
        scrollPos = 0
    end

    obj.redraw = function()
        if visible then
            -- Load elements
            visibleElements = {}
            for id = scrollPos, scrollPos + h do
                if elements[id + 1] then
                    local e = elements[id + 1]
                    if e.x and e.y and e.text and e.textColor then
                        local newElement = elements[id + 1]
                        newElement.actualY = newElement.y - scrollPos
                        table.insert(visibleElements, elements[id + 1])
                    end
                end
            end
            local p = 1
            for i, v in pairs(visibleElements) do
                for i, v in pairs(v) do
                    p = p + 1
                end
            end
            -- Draw elements
            scrollFrame.setBackgroundColor(backgroundColor or colors.black)
            scrollFrame.clear()
            for position, elem in pairs(visibleElements) do
                if elem then
                    scrollFrame.setCursorPos(elem.x, elem.actualY)
                    scrollFrame.setTextColor(elem.textColor)
                    scrollFrame.setBackgroundColor(elem.backgroundColor or backgroundColor)
                    scrollFrame.write(elem.text)
                end
            end
        end
    end
    obj.scroll = function(direction) -- -1 is up, 1 is down
        if #elements > h then
            if scrollPos ~= 0 then
                local canScroll = true
                if elements[scrollPos + h + 1] == nil then
                    if direction == -1 then
                        canScroll = true
                    else
                        canScroll = false
                    end
                else
                    canScroll = true
                end

                if canScroll then
                    scrollPos = scrollPos + direction
                    obj.redraw()
                end
            else
                if direction == 1 then
                    scrollPos = scrollPos + direction
                    obj.redraw()
                end
            end
        end
    end
    obj.setVisible = function(isVisible)
        scrollFrame.setVisible(isVisible)
        visible = isVisible
    end
    
    obj.checkEvents = function(e)
        if visible then
            if e[1] == "mouse_scroll" then
                local dir, mx, my = e[2], e[3], e[4]
                if mx >= x and mx <= x + w - 1 and my >= y and my <= y + h - 1 then
                    obj.scroll(dir)
                end
            elseif e[1] == "mouse_click" then
                local dir, mx, my = e[2], e[3], e[4]
                for i, v in pairs(visibleElements) do
                    if mx >= v.x and mx <= v.x + string.len(v.text) - 1 and my == v.actualY + 1 and v.clickEvent ~= nil then
                        v.clickEvent()
                    end
                end
            end
        end
    end

    return obj
end

return {
    new = new,
    createElement = createElement
}