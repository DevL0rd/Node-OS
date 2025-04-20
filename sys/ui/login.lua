local textbox = require("/lib/textbox")
local sha256 = require("/lib/sha256")

local w, h = term.getSize()
local theme = _G.pm.getTheme()
local password = textbox.new(2, 3, w - 2, "\7", "Password", nil, theme.userInput.background, theme.userInput.text)


local usrRaw = ""
local pswrdRaw = ""
local errorText = ""

local function draw()
    local w, h = term.getSize()
    term.setBackgroundColor(theme.main.background)
    term.clear()
    password.redraw()
    term.setCursorPos(2, 6)
    term.setBackgroundColor(theme.userInput.background)
    term.setTextColor(theme.userInput.text)
    term.write(" Login ")
    term.setCursorPos(10, 6)
    term.setBackgroundColor(theme.main.background)
    term.setTextColor(colors.red)
    term.write(errorText)

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
    os.queueEvent("pm_paint")
end

draw()
while true do
    draw()
    local e = { os.pullEvent() }
    if sets.settings.password == "" or sets.settings.consoleOnly then
        os.queueEvent("pm_login")
        pm.endProcess(id)
    end
    if e[1] == "mouse_click" then
        local m, x, y = e[2], e[3], math.ceil(e[4])
        if x >= 2 and x <= w - 2 and y == 3 then
            pswrdRaw = password.select()
        elseif x >= 2 and x <= 7 and y == 6 then
            if sha256(pswrdRaw) == sets.settings.password then
                os.queueEvent("pm_login")
                pm.endProcess(id)
            else
                errorText = "Incorrect password"
            end
        end
    elseif e[1] == "key" then
        if e[2] == keys.enter then
            if sha256(pswrdRaw) == sets.settings.password then
                os.queueEvent("pm_login")
                pm.endProcess(id)
            else
                errorText = "Incorrect password"
            end
        end
    end
end
