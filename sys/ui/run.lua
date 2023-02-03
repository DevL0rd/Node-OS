local textbox = require("/lib/textbox")
local w, h = term.getSize()
local box = textbox.new(2, 4, w - 2)
local util = require("util")
local file = util.loadModule("file")
local theme = _G.pm.getTheme()

local function draw()
    local w, h = term.getSize()
    term.setBackgroundColor(colors.white)
    term.clear()
    term.setCursorPos(2,2)
    term.setTextColor(colors.gray)
    term.write("Enter program path")
    box.redraw()
    term.setCursorPos(2,6)
    term.setBackgroundColor(colors.lightGray)
    term.setTextColor(colors.gray)
    term.write(" Run ")

    local foregroundColor = theme.window.titlebar.background

    if pm.getSelectedProcessID() == id then
        foregroundColor = theme.window.titlebar.backgroundSelected
    end

    for i = 1, h - 1 do
        term.setCursorPos(1, i)
        term.setTextColor(foregroundColor)
        term.setBackgroundColor(colors.white)
        term.write("\149")
    end
    for i = 1, h - 1 do
        term.setCursorPos(w, i)
        term.setTextColor(colors.white)
        term.setBackgroundColor(foregroundColor)
        term.write("\149")
    end
    term.setCursorPos(2, h)
    term.setTextColor(colors.white)
    term.setBackgroundColor(foregroundColor)
    term.write(string.rep("\143", w - 2))

    term.setCursorPos(1, h)
    term.setTextColor(colors.white)
    term.setBackgroundColor(foregroundColor)
    term.write("\138")
    term.setCursorPos(w, h)
    term.setTextColor(colors.white)
    term.setBackgroundColor(foregroundColor)
    term.write("\133")
end

draw()
local content = ""
while true do
    draw()
    local e = {os.pullEvent()}
    if e[1] == "mouse_click" then
        local m, x, y = e[2], e[3], e[4]
        if x >= 2 and x <= w - 2 and y == 4 then
            content = box.select()
        elseif x >= 2 and x <= 7 and y == 6 then
            pm.selectProcess(pm.createProcess(content, {
                x = 2,
                y = 3,
                width = 20,
                height = 10
            }))
            pm.endProcess(id)
            break
        end
    end
end