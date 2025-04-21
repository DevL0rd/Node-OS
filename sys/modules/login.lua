local module = {}

function module.init(nodeos, native, termWidth, termHeight)
    function login_ui()
        local textbox = require("/sys/modules/util/textbox")
        local sha256 = require("/lib/sha256")

        local w, h = term.getSize()
        local theme = nodeos.getTheme()
        local password = textbox.new(2, 3, w - 2, "\7", "Password", nil, theme.userInput.background, theme.userInput
            .text)


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

            if nodeos.getSelectedProcessID() == id then
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
            os.queueEvent("nodeos_paint")
        end

        draw()
        while true do
            draw()
            local e = { os.pullEvent() }
            if nodeos.settings.settings.password == "" or nodeos.settings.settings.consoleOnly then
                os.queueEvent("nodeos_login")
                nodeos.endProcess(nodeos.loginID)
            end
            if e[1] == "mouse_click" then
                local m, x, y = e[2], e[3], math.ceil(e[4])
                if x >= 2 and x <= w - 2 and y == 3 then
                    pswrdRaw = password.select()
                elseif x >= 2 and x <= 7 and y == 6 then
                    if sha256(pswrdRaw) == nodeos.settings.settings.password then
                        os.queueEvent("nodeos_login")
                        nodeos.endProcess(nodeos.loginID)
                    else
                        errorText = "Incorrect password"
                    end
                end
            elseif e[1] == "key" then
                if e[2] == keys.enter then
                    if sha256(pswrdRaw) == nodeos.settings.settings.password then
                        os.queueEvent("nodeos_login")
                        nodeos.endProcess(nodeos.loginID)
                    else
                        errorText = "Incorrect password"
                    end
                end
            end
        end
    end

    nodeos.handleLoginEvent = function()
        -- Start all autostart applications
        local files = fs.list("/home/startup")
        for i, v in pairs(files) do
            v = "/home/startup/" .. v
            if v:sub(-4) == ".lua" then
                local minimize = (i ~= 1)
                local pid = nodeos.createProcess(v, {
                    maximized = true,
                    minimized = minimize
                })
                if i == 1 then
                    nodeos.selectProcess(pid)
                end
            end
        end

        -- Show welcome notification
        nodeos.notifications.push("Welcome", "Welcome back!")
    end
    if nodeos.settings.settings.consoleOnly == false then
        nodeos.loginID = nodeos.createProcess(login_ui, {
            showTitlebar = true,
            dontShowInTitlebar = true,
            disableControls = true,
            title = "Login",
            height = 7,
            y = (termHeight / 2) - 4,
        })
        nodeos.selectProcess(nodeos.loginID)
    else
        nodeos.selectProcess(nodeos.createProcess("/sys/shell.lua", {
            showTitlebar = false,
            dontShowInTitlebar = true,
            disableControls = true,
            title = "Login",
            x = 1,
            y = 1,
            width = termWidth,
            height = termHeight,
        }))
    end
end

return module
