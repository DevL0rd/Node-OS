local util = require("util")
local file = util.loadModule("file")
local theme = _G.pm.getTheme()
local sw = require("/lib/scrollwindow")
local w, h = term.getSize()
local elements = {
    sw.createElement(1, 1, "About NodeOS", theme.main.textBold),
    sw.createElement(1, 2, "Created by DevL0rd", theme.main.text),
    sw.createElement(1, 3, "Licensed under MIT", theme.main.text)
}
local scroll = sw.new(2, 2, w - 2, h - 2, elements, theme.main.background, true)

local function draw()
    local w, h = term.getSize()
    term.setCursorPos(2, 2)
    term.setBackgroundColor(theme.main.background)
    term.clear()
    scroll.resize(w - 2, h - 1)
    scroll.setElements(elements)
    scroll.scrollToTop()
    scroll.redraw()

    local foregroundColor = theme.window.titlebar.background

    if pm.getSelectedProcessID() == id then
        foregroundColor = theme.window.titlebar.backgroundSelected
    end

    for i = 1, h - 1 do
        term.setCursorPos(1, i)
        term.setTextColor(foregroundColor)
        term.setBackgroundColor(theme.main.background)
        term.write("\149")
    end
    for i = 1, h - 1 do
        term.setCursorPos(w, i)
        term.setTextColor(theme.main.background)
        term.setBackgroundColor(foregroundColor)
        term.write("\149")
    end
    term.setCursorPos(2, h)
    term.setTextColor(theme.main.background)
    term.setBackgroundColor(foregroundColor)
    term.write(string.rep("\143", w - 2))

    term.setCursorPos(1, h)
    term.setTextColor(theme.main.background)
    term.setBackgroundColor(foregroundColor)
    term.write("\138")
    term.setCursorPos(w, h)
    term.setTextColor(theme.main.background)
    term.setBackgroundColor(foregroundColor)
    term.write("\133")
end

while true do
    draw()
    local e = { os.pullEvent() }
    scroll.checkEvents(e)
end