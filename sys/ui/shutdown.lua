local theme = _G.pm.getTheme()

local function centerText(text, y, offset)
    if not offset then offset = 0 end
    local w, h = term.getSize()
    term.setCursorPos(math.ceil(w / 2 - string.len(text) / 2) + offset, y)
    term.write(text)
end

local function draw()
    term.setBackgroundColor(colors.white)
    term.clear()
    local w, h = term.getSize()

    -- border
    local foregroundColor = theme.window.titlebar.background

    if pm.getSelectedProcessID() == id then
        foregroundColor = theme.window.titlebar.backgroundSelected
    end
    
    for i = 2, h - 1 do
        term.setCursorPos(1, i)
        term.setTextColor(foregroundColor)
        term.setBackgroundColor(colors.white)
        term.write("\149")
    end
    for i = 2, h - 1 do
        term.setCursorPos(w, i)
        term.setTextColor(colors.white)
        term.setBackgroundColor(foregroundColor)
        term.write("\149")
    end
    term.setCursorPos(2, h)
    term.setTextColor(colors.white)
    term.setBackgroundColor(foregroundColor)
    term.write(string.rep("\143", w - 2))
    term.setCursorPos(2, 1)
    term.setTextColor(foregroundColor)
    term.setBackgroundColor(colors.white)
    term.write(string.rep("\131", w - 2))

    term.setCursorPos(1, h)
    term.setTextColor(colors.white)
    term.setBackgroundColor(foregroundColor)
    term.write("\138")
    term.setCursorPos(w, h)
    term.write("\133")
    term.setCursorPos(w, 1)
    term.write("\148")

    term.setTextColor(foregroundColor)
    term.setBackgroundColor(colors.white)
    term.setCursorPos(1, 1)
    term.write("\151")

    term.setBackgroundColor(colors.white)
    term.setTextColor(colors.red)
    centerText("Shutdown", 2, 1)
    term.setTextColor(colors.orange)
    centerText("Reboot", 3, 1)
    term.setTextColor(colors.lightGray)
    centerText("Cancel", 5, 1) 
end

draw()

while true do 
    local e = {os.pullEvent()}
    draw()
    if e[1] == "mouse_click" then
        local m, x, y = e[2], e[3], e[4]
        if y == 2 then
            os.queueEvent("pm_fancyshutdown", "shutdown")
        elseif y == 3 then
            os.queueEvent("pm_fancyshutdown", "reboot")
        elseif y == 5 then
            pm.endProcess(id)
        end
    end
end