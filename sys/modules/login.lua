local module = {}

function module.init(nodeos, native, termWidth, termHeight)
    -- Add logging for module initialization
    nodeos.logging.info("Login", "Login module initializing")

    function login_ui()
        local textbox = require("/sys/modules/util/textbox")
        local sha256 = require("/lib/sha256")

        nodeos.logging.debug("Login", "Login UI started")

        local w, h = term.getSize()
        local password = textbox.new(2, 3, w - 2, "\7", "Password", nil, nodeos.theme.userInput.background,
            nodeos.theme.userInput
            .text)

        local usrRaw = ""
        local pswrdRaw = ""
        local errorText = ""

        local function draw()
            local w, h = term.getSize()
            term.setBackgroundColor(nodeos.theme.main.background)
            term.clear()
            password.redraw()
            term.setCursorPos(2, 6)
            term.setBackgroundColor(nodeos.theme.userInput.background)
            term.setTextColor(nodeos.theme.userInput.text)
            term.write(" Login ")
            term.setCursorPos(10, 6)
            term.setBackgroundColor(nodeos.theme.main.background)
            term.setTextColor(colors.red)
            term.write(errorText)

            local foregroundColor = nodeos.theme.window.titlebar.background

            if nodeos.getSelectedProcessID() == id then
                foregroundColor = nodeos.theme.window.titlebar.backgroundSelected
            end

            for i = 1, h - 1 do
                term.setCursorPos(1, i)
                term.setTextColor(foregroundColor)
                term.setBackgroundColor(nodeos.theme.main.background)
                term.write("\149")
            end
            for i = 1, h - 1 do
                term.setCursorPos(w, i)
                term.setTextColor(nodeos.theme.main.background)
                term.setBackgroundColor(foregroundColor)
                term.write("\149")
            end
            term.setCursorPos(2, h)
            term.setTextColor(nodeos.theme.main.background)
            term.setBackgroundColor(foregroundColor)
            term.write(string.rep("\143", w - 2))

            term.setCursorPos(1, h)
            term.setTextColor(nodeos.theme.main.background)
            term.setBackgroundColor(foregroundColor)
            term.write("\138")
            term.setCursorPos(w, h)
            term.setTextColor(nodeos.theme.main.background)
            term.setBackgroundColor(foregroundColor)
            term.write("\133")
            nodeos.drawProcess()
        end

        function login()
            -- Start all autostart applications
            nodeos.logging.info("Login", "Successful login - starting autostart applications")

            local files = fs.list("/home/startup")
            for i, v in pairs(files) do
                v = "/home/startup/" .. v
                if v:sub(-4) == ".lua" then
                    local minimize = (i ~= 1)
                    nodeos.logging.debug("Login", "Starting " .. v)
                    local pid = nodeos.createProcess(v, {
                        maximized = true,
                        minimized = minimize
                    })
                    if i == 1 then
                        nodeos.selectProcess(pid)
                    end
                end
            end
            if fs.exists("/home/startup.lua") then
                local minimize = (fs.list("/home/startup") ~= nil)
                nodeos.logging.debug("Login", "Starting /home/startup.lua")
                local pid = nodeos.createProcess("/home/startup.lua", {
                    maximized = true,
                    minimized = minimize
                })
                if fs.list("/home/startup") == nil then
                    nodeos.selectProcess(pid)
                end
            end
            -- Show welcome notification
            nodeos.notifications.push("Welcome", "Welcome back!")
        end

        draw()
        while true do
            draw()
            local e = { os.pullEvent() }
            if nodeos.settings.settings.password == "" or nodeos.settings.settings.consoleOnly then
                nodeos.logging.info("Login", "No password or console only mode - automatic login")
                login()
                nodeos.endProcess(nodeos.loginID)
            end
            if e[1] == "mouse_click" then
                local m, x, y = e[2], e[3], math.ceil(e[4])
                if x >= 2 and x <= w - 2 and y == 3 then
                    pswrdRaw = password.select()
                elseif x >= 2 and x <= 7 and y == 6 then
                    if sha256(pswrdRaw) == nodeos.settings.settings.password then
                        nodeos.logging.info("Login", "Password authentication successful")
                        login()
                        nodeos.endProcess(nodeos.loginID)
                    else
                        nodeos.logging.warn("Login", "Failed login attempt - incorrect password")
                        errorText = "Incorrect password"
                    end
                end
            elseif e[1] == "key" then
                if e[2] == keys.enter then
                    if sha256(pswrdRaw) == nodeos.settings.settings.password then
                        nodeos.logging.info("Login", "Password authentication successful")
                        login()
                        nodeos.endProcess(nodeos.loginID)
                    else
                        nodeos.logging.warn("Login", "Failed login attempt - incorrect password")
                        errorText = "Incorrect password"
                    end
                end
            end
        end
    end

    if nodeos.settings.settings.consoleOnly == false then
        nodeos.logging.info("Login", "Starting graphical login UI")
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
        nodeos.logging.info("Login", "Console-only mode enabled.")
        local startup = "/sys/shell.lua"
        if fs.exists("/home/startup.lua") then
            startup = "/home/startup.lua"

            -- else if this is the master pc, start logs
        elseif os.getComputerID() == nodeos.settings.settings.master then
            startup = "/bin/logs.lua"
        end

        nodeos.selectProcess(nodeos.createProcess(startup, {
            showTitlebar = false,
            dontShowInTitlebar = true,
            disableControls = true,
            title = "Shell",
            x = 1,
            y = 1,
            width = termWidth,
            height = termHeight,
        }))
    end

    nodeos.logging.info("Login", "Login module initialization complete")
end

return module
