local module = {}

function module.init(nodeos, native, termWidth, termHeight)
    if nodeos.settings.settings.consoleOnly then
        nodeos.logging.debug("Titlebar", "Console only mode, skipping titlebar module")
        return
    end
    nodeos.logging.info("Titlebar", "Initializing titlebar module")

    function menu_ui(menuID)
        nodeos.logging.debug("Titlebar", "Opening menu UI")
        local w, h = term.getSize()
        local pinned = {}

        local textbox = require("/sys/modules/util/textbox")
        local scroll = require("/sys/modules/util/scrollwindow")
        local draw = require("/sys/modules/util/draw")
        local search = textbox.new(3, h - 1, w - 7, nil, "Search", nil, nodeos.theme.userInput.background,
            nodeos.theme.userInput.text)
        local searchWindow = scroll.new(2, 2, w - 3, h - 4, {}, nodeos.theme.menu.background, false)
        local pinnedWindow = scroll.new(2, 2, w - 3, h - 4, {}, nodeos.theme.menu.background, true)
        local query
        local searchResults = {}

        local function searchSystem(query, depth)
            nodeos.logging.debug("Titlebar", "Searching system for: " .. query)
            if not depth then depth = 10 end
            local found = {}

            local function searchDir(path, query, iteration, depth)
                for _, file in pairs(fs.list(path)) do
                    if file:sub(1, 1) ~= "." then
                        if fs.isDir(fs.combine(path, file)) and iteration < depth then
                            searchDir(fs.combine(path, file), query, iteration + 1, depth)
                        else
                            if string.find(string.lower(file), string.lower(query)) then
                                table.insert(found, fs.combine(path, file))
                            end
                        end
                    end
                end
            end

            searchDir("/", query, 1, depth)
            return found
        end

        local function none() end

        local function updatePinned()
            nodeos.logging.debug("Titlebar", "Updating pinned applications")
            saveTable("/etc/menu/pinned.cfg", pinned)
        end

        local function loadPinned()
            nodeos.logging.debug("Titlebar", "Loading pinned applications")
            pinned = loadTable("/etc/menu/pinned.cfg")
            if pinned == nil then
                nodeos.logging.debug("Titlebar", "No pinned applications found, creating empty list")
                pinned = {}
            end
        end

        local function drawUI()
            term.setBackgroundColor(nodeos.theme.menu.background)
            term.clear()
            local sw = w - 3
            if not query then
                searchWindow.setVisible(false)
                pinnedWindow.setVisible(true)
                pinnedWindow.setElements({})

                local pos = 1
                pinnedWindow.addElement(scroll.createElement(1, pos, string.rep("\140", sw), colors.gray,
                    nodeos.theme.menu.background
                    , none))
                pos = pos + 1
                pinnedWindow.addElement(scroll.createElement(2, pos, "Pinned", colors.white, nodeos.theme.menu
                    .background, none))
                pos = pos + 1
                pinnedWindow.addElement(scroll.createElement(1, pos, string.rep("\140", sw), colors.gray,
                    nodeos.theme.menu.background
                    , none))
                pos = pos + 1
                for i, v in pairs(pinned) do
                    pinnedWindow.addElement(scroll.createElement(2, pos, draw.overflow(v.title, sw), colors.white,
                        nodeos.theme.menu.background, function()
                            nodeos.endProcess(nodeos.menuPID)
                            nodeos.selectProcess(nodeos.createProcess(v.path, v.insettings))
                        end))
                    pos = pos + 1
                end

                pos = pos + 1
                pinnedWindow.addElement(scroll.createElement(1, pos, string.rep("\140", sw), colors.gray,
                    nodeos.theme.menu.background
                    , none))
                pos = pos + 1
                pinnedWindow.redraw()
            else
                local pos = 1
                searchWindow.setVisible(true)
                pinnedWindow.setVisible(false)
                searchWindow.setElements({})
                if #searchResults == 0 then
                    searchWindow.addElement(scroll.createElement(
                        math.ceil(searchWindow.getWidth() / 2 - string.len("No results") / 2)
                        , pos, "No results.", colors.gray, nodeos.theme.menu.background, function() end))
                else
                    searchWindow.addElement(scroll.createElement(1, pos, "Found " .. #searchResults .. " results",
                        colors.white,
                        nodeos.theme.menu.background, none))
                    pos = pos + 1
                    searchWindow.addElement(scroll.createElement(1, pos, string.rep("\140", sw), colors.gray,
                        nodeos.theme.menu.background, none))
                    pos = pos + 1

                    for i, v in pairs(searchResults) do
                        local function addFunction()
                            nodeos.endProcess(nodeos.menuPID)
                            -- if not lua file
                            if v:sub(-4) ~= ".lua" then
                                v = "/rom/programs/edit.lua " .. v
                            end
                            nodeos.selectProcess(nodeos.createProcess(v, {
                                maximized = true
                            }))
                        end

                        searchWindow.addElement(scroll.createElement(2, pos, draw.overflow(fs.getName(v), sw),
                            colors.white,
                            nodeos.theme.menu.background, addFunction))
                        pos = pos + 1
                        local text = fs.getDir(v)
                        if fs.getDir(v) == "" then
                            text = "Root"
                        end
                        searchWindow.addElement(scroll.createElement(2, pos, draw.overflow(text, sw), colors.gray,
                            nodeos.theme.menu.background, addFunction))
                        pos = pos + 1
                        searchWindow.addElement(scroll.createElement(2, pos, "", colors.gray,
                            nodeos.theme.menu.background,
                            function() end))
                        pos = pos + 1
                    end
                    searchWindow.removeElement(#searchWindow.getElements())
                end
                searchWindow.redraw()
            end

            term.setBackgroundColor(colors.red)
            term.setTextColor(colors.white)
            term.setCursorPos(w - 2, h - 1)
            term.write("O")
            term.setCursorPos(w - 1, h - 2)
            term.setBackgroundColor(nodeos.theme.menu.background)
            draw.drawBorder(w - 2, h - 1, 1, 1, colors.red)

            term.setCursorPos(w, h - 1)
            search.redraw()
            term.setCursorPos(w - 1, h - 2)
            term.setBackgroundColor(nodeos.theme.menu.background)
            draw.drawBorder(3, h - 1, w - 7, 1, nodeos.theme.userInput.background)
        end

        loadPinned()
        drawUI()
        nodeos.logging.debug("Titlebar", "Menu UI ready")

        while true do
            local e = { os.pullEvent() }
            if e[1] == "mouse_click" then
                local m, x, y = e[2], e[3], e[4]
                if x >= 2 and x <= w - 5 and y == h - 1 then
                    query = search.select()
                    if query == "" then query = nil end
                    if query then
                        nodeos.logging.debug("Titlebar", "Searching for: " .. query)
                        searchResults = searchSystem(query)
                        nodeos.logging.debug("Titlebar", "Found " .. #searchResults .. " results")
                        drawUI()
                    end
                end
            end
            local found = searchWindow.checkEvents(e)
            pinnedWindow.checkEvents(e)
        end
    end

    function titlebar_ui()
        nodeos.logging.debug("Titlebar", "Starting titlebar UI")
        local w = term.getSize()
        local running = {}
        local procList

        local function draw()
            term.setCursorBlink(false)
            procList = nodeos.listProcesses()
            term.setBackgroundColor(nodeos.theme.titlebar.background)
            term.clear()
            local time = " " .. textutils.formatTime(os.time(), false)
            term.setTextColor(nodeos.theme.titlebar.text)
            local renderX = w - string.len(time) + 1
            term.setCursorPos(renderX, 1)
            term.write(time)
            if nodeos.gps.isConnected then
                term.setTextColor(colors["green"])
            else
                term.setTextColor(colors["red"])
            end
            renderX = renderX - 3
            term.setCursorPos(renderX, 1)
            term.write("GPS")
            if nodeos.net.isConnected then
                term.setTextColor(colors["green"])
            else
                term.setTextColor(colors["red"])
            end
            renderX = renderX - 4
            term.setCursorPos(renderX, 1)
            term.write("NET")
            term.setTextColor(nodeos.theme.menu.textSecondary)
            term.setCursorPos(1, 1)
            if nodeos.menuPID and procList[nodeos.menuPID] then
                term.setBackgroundColor(nodeos.theme.menu.buttonBG_Selected)
                term.setTextColor(nodeos.theme.menu.text)
            else
                term.setBackgroundColor(nodeos.theme.menu.buttonBG)
                term.setTextColor(nodeos.theme.menu.buttonText)
                nodeos.menuPID = nil
            end
            term.write(" N ")
            term.setBackgroundColor(nodeos.theme.titlebar.background)
            term.write(" ")
            for i, v in pairs(procList) do
                if not v.dontShowInTitlebar then
                    local x, y = term.getCursorPos()
                    v.startX = x
                    if v == nodeos.getSelectedProcess() then
                        term.setTextColor(nodeos.theme.menu.text)
                    else
                        term.setTextColor(nodeos.theme.menu.textSecondary)
                    end
                    local ins = v
                    term.write(v.title .. " ")
                    local x, y = term.getCursorPos()
                    v.endX = x
                    v.pid = i
                    table.insert(running, v)
                end
            end
        end

        os.queueEvent("titlebar_paint")
        while true do
            local e = { os.pullEvent() }
            if e[1] == "mouse_click" then
                local m, x, y = e[2], e[3], e[4]
                if x >= 1 and x <= 3 and y == 1 then
                    if nodeos.menuPID and nodeos.listProcesses()[nodeos.menuPID] == nil then
                        nodeos.menuPID = nil
                    else
                        if nodeos.menuPID ~= nil then
                            nodeos.logging.debug("Titlebar", "Closing menu")
                            nodeos.endProcess(nodeos.menuPID)
                            nodeos.menuPID = nil
                        else
                            nodeos.logging.debug("Titlebar", "Opening menu")
                            nodeos.menuPID = nodeos.createProcess(function() menu_ui(nodeos.menuPID) end, {
                                x = 1,
                                y = 2,
                                width = 20,
                                height = 14,
                                showTitlebar = false,
                                dontShowInTitlebar = true
                            })

                            nodeos.selectProcess(nodeos.menuPID)
                        end
                    end
                else
                    local pid
                    pid = nil -- just in case...
                    for i, v in pairs(running) do
                        if x >= v.startX and x <= v.endX then
                            pid = v.pid
                        end
                    end

                    if pid then
                        if procList[pid].minimized then
                            nodeos.logging.debug("Titlebar", "Unminimizing process: " .. procList[pid].title)
                            nodeos.unminimizeProcess(pid)
                        end
                        nodeos.logging.debug("Titlebar", "Selecting process: " .. procList[pid].title)
                        nodeos.selectProcess(pid)
                    end
                end
            elseif e[1] == "titlebar_paint" or e[1] == "clock_tick" then
                draw()
            end
        end
    end

    nodeos.logging.info("Titlebar", "Creating titlebar process")
    nodeos.titlebarID = nodeos.createProcess(titlebar_ui, {
        x = 1,
        y = 1,
        width = termWidth,
        height = 1,
        showTitlebar = false,
        dontShowInTitlebar = true,
        immortal = true,
    })

    function clock()
        nodeos.logging.debug("Titlebar", "Starting clock service")
        while true do
            os.queueEvent("clock_tick")
            os.sleep(1)
        end
    end

    nodeos.createProcess(clock, {
        isService = true,
    })

    nodeos.logging.info("Titlebar", "Titlebar module initialization complete")
end

return module
