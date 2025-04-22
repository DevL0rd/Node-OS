-- nodeos Core Process Management
-- Handles process creation, selection, and lifecycle management

local module = {}

function module.init(nodeos, native, termWidth, termHeight)
    nodeos.logging.info("Processes", "Initializing process management module")

    -- ===============================
    -- Process Management
    -- ===============================
    nodeos.processes = {}
    nodeos.processes_sorted = {}
    nodeos.lastProcID = 0
    nodeos.selectedProcessID = 0
    nodeos.selectedProcess = nil
    nodeos.titlebarID = 1

    nodeos.waitForAll = function(processName, ...)
        local funcs = { ... }
        local wrappedFuncs = {}
        local errors = {}
        local hasErrors = false

        for i, func in ipairs(funcs) do
            wrappedFuncs[i] = function()
                local ok, err = pcall(func)
                if not ok then
                    nodeos.logging.fatal(processName, err)
                    errors[i] = err
                    hasErrors = true
                    -- Still re-throw to end the coroutine
                    error(err, 0)
                end
            end
        end

        -- Call original with wrapped functions
        parallel.waitForAll(table.unpack(wrappedFuncs))

        -- Check if any errors occurred and report them
        if hasErrors then
            local errorMsg = "Error(s) occurred in " .. processName .. ": "
            for i, err in pairs(errors) do
                errorMsg = errorMsg .. "\n" .. tostring(err)
            end
            error(errorMsg, 2) -- Propagate the error to the caller
        end
    end

    nodeos.waitForAny = function(processName, ...)
        local funcs = { ... }
        local wrappedFuncs = {}
        local errors = {}
        local hasErrors = false

        for i, func in ipairs(funcs) do
            wrappedFuncs[i] = function()
                local ok, err = pcall(func)
                if not ok then
                    nodeos.logging.fatal(processName, err)
                    errors[i] = err
                    hasErrors = true
                end
            end
        end

        -- Call original with wrapped functions
        local index = parallel.waitForAny(table.unpack(wrappedFuncs))

        -- Check if any errors occurred and report them
        if hasErrors then
            local errorMsg = "Error(s) occurred in " .. processName .. ": "
            for i, err in pairs(errors) do
                errorMsg = errorMsg .. "\n" .. tostring(err)
            end
            error(errorMsg, 2) -- Propagate the error to the caller
        end

        return index
    end

    -- Window management state
    nodeos.resizeState = {
        startX = nil,
        startY = nil,
        startW = nil,
        startH = nil
    }
    nodeos.mvmtX = nil
    nodeos.isDrawingEnabled = true

    -- Input state
    nodeos.keysDown = {}

    -- Double click detection
    nodeos.clickState = {
        lastTime = 0,
        lastX = 0,
        lastY = 0,
        doubleClickThreshold = 0.3 -- 300ms
    }
    nodeos.listProcesses = function()
        return nodeos.processes
    end

    nodeos.getSelectedProcess = function()
        return nodeos.selectedProcess
    end

    nodeos.getSelectedProcessID = function()
        return nodeos.selectedProcessID
    end

    nodeos.selectProcess = function(pid)
        if nodeos.selectedProcessID ~= pid and nodeos.processes[pid] then
            nodeos.logging.debug("Processes",
                "Selecting process " .. pid .. " (" .. (nodeos.processes[pid].title or "Untitled") .. ")")
            nodeos.selectedProcessID = pid
            nodeos.selectedProcess = nodeos.processes[pid]

            if not nodeos.selectedProcess.minimized then
                nodeos.selectedProcess.window.setVisible(true)
                nodeos.drawProcess(nodeos.selectedProcess)

                -- Update processes_sorted list
                -- Remove the process from its current position if it exists in the list
            end

            -- Move selected process to top of sorted list (always on top)
            for i, v in ipairs(nodeos.processes_sorted) do
                if v == pid then
                    table.remove(nodeos.processes_sorted, i)
                    break
                end
            end
            table.insert(nodeos.processes_sorted, 1, pid)
            nodeos.drawProcesses()

            os.queueEvent("titlebar_paint")
        end
    end

    nodeos.selectProcessAfter = function(pid, time)
        sleep(time)
        nodeos.selectProcess(pid)
    end

    nodeos.minimizeProcess = function(pid)
        nodeos.logging.debug("Processes",
            "Minimizing process " .. pid .. " (" .. (nodeos.processes[pid].title or "Untitled") .. ")")
        nodeos.processes[pid].minimized = true

        -- Remove from processes_sorted list when minimized
        for i, v in ipairs(nodeos.processes_sorted) do
            if v == pid then
                table.remove(nodeos.processes_sorted, i)
                break
            end
        end
    end

    nodeos.unminimizeProcess = function(pid)
        nodeos.logging.debug("Processes",
            "Unminimizing process " .. pid .. " (" .. (nodeos.processes[pid].title or "Untitled") .. ")")
        nodeos.processes[pid].minimized = false

        -- Add to the top of processes_sorted when unminimized
        -- First check if it's already in the list (shouldn't be, but just in case)
        local found = false
        for i, v in ipairs(nodeos.processes_sorted) do
            if v == pid then
                found = true
                table.remove(nodeos.processes_sorted, i)
                break
            end
        end

        -- Add to top of list if not found
        table.insert(nodeos.processes_sorted, 1, pid)

        nodeos.selectProcess(pid)
    end

    nodeos.endProcess = function(pid)
        local proc = nodeos.processes[pid]
        if not proc then return end

        nodeos.logging.info("Processes", "Ending process " .. pid .. " (" .. (proc.title or "Untitled") .. ")")

        if pid == nodeos.selectedProcessID then
            -- Find next process to focus
            local nextPid = nodeos.titlebarID -- Default to titlebar

            -- Find visible normal window
            for id, process in pairs(nodeos.processes) do
                if id ~= pid and id ~= nodeos.titlebarID
                    and not process.minimized
                    and not process.isService then
                    nextPid = id
                    break
                end
            end

            nodeos.selectProcess(nextPid)
        end

        -- Remove from processes_sorted list when ending process
        for i, v in ipairs(nodeos.processes_sorted) do
            if v == pid then
                table.remove(nodeos.processes_sorted, i)
                break
            end
        end

        proc.window.setVisible(false)
        nodeos.processes[pid] = nil
        nodeos.drawProcesses()
        os.queueEvent("titlebar_paint")
    end

    -- ===============================
    -- Process Creation
    -- ===============================
    nodeos.createProcess = function(path, newProc)
        -- Initialize process object
        newProc = newProc or {}
        nodeos.lastProcID = nodeos.lastProcID + 1
        local pid = nodeos.lastProcID

        -- Set title
        if not newProc.title then
            if type(path) == "string" then
                newProc.title = fs.getName(path)
                if newProc.title:sub(-4) == ".lua" then
                    newProc.title = newProc.title:sub(1, -5)
                end
            else
                newProc.title = "Untitled"
            end
        end

        nodeos.logging.info("Processes", "Creating process " .. pid .. " (" .. newProc.title .. ")")

        -- Configure process settings
        nodeos.configureProcessSettings(newProc, path)

        -- Create window and coroutine
        newProc.window = window.create(native, newProc.x, newProc.y, newProc.width, newProc.height)
        term.redirect(newProc.window)
        newProc.coroutine = coroutine.create(nodeos.createProcessRunFunction(newProc.title, path))

        -- Start process
        local ok, err = coroutine.resume(newProc.coroutine)
        if not ok then
            nodeos.logging.error("Processes", "Failed to start process " .. pid .. ": " .. tostring(err))
        else
            nodeos.logging.debug("Processes", "Process " .. pid .. " started successfully")
        end

        newProc.window.redraw()

        -- Set as selected if first process
        if nodeos.selectedProcess == nil then
            nodeos.selectedProcess = newProc
        end

        -- Store and return
        table.insert(nodeos.processes, nodeos.lastProcID, newProc)

        -- Add to processes_sorted if not minimized and not a service/hidden
        if not newProc.minimized and not newProc.isService then
            table.insert(nodeos.processes_sorted, 1, nodeos.lastProcID)
        end

        os.queueEvent("titlebar_paint")
        return nodeos.lastProcID
    end

    nodeos.configureProcessSettings = function(newProc, path)
        -- Store path
        newProc.path = path

        -- Configure basic settings
        newProc.isService = newProc.isService or false
        newProc.showTitlebar = (newProc.showTitlebar == nil) or newProc.showTitlebar

        -- Configure service-specific settings
        if newProc.isService then
            newProc.showTitlebar = false
            newProc.dontShowInTitlebar = true
            newProc.disableControls = true
            newProc.minimized = true
        end

        -- Configure size
        newProc.width = newProc.width or 20
        newProc.height = newProc.height or 10

        -- Configure position
        if not newProc.x then
            newProc.x = math.ceil(termWidth / 2 - (newProc.width / 2))
        end

        if not newProc.y then
            local yOffset = (newProc.height % 2 == 0) and 0 or 1
            newProc.y = math.ceil(termHeight / 2 - (newProc.height / 2)) + yOffset
        end
    end

    nodeos.createProcessRunFunction = function(processName, path)
        local newTable = table
        newTable["contains"] = nodeos.contains

        if type(path) == "string" then
            nodeos.logging.debug("Processes", "Starting file-based process: " .. processName)
            return function()
                _G.id = nodeos.lastProcID
                _G.table = newTable

                local nargs = nil
                if path:find(" ") then
                    path, nargs = path:match("(.+)%s+(.+)")
                end

                -- Run the process with error handling
                local ok, err = xpcall(function()
                    os.run({
                        _G = _G,
                        package = package
                    }, path, nargs)
                end, function(err)
                    nodeos.logging.fatal(processName, err)
                    return err
                end)

                if not ok then
                    nodeos.logging.error("Processes", "Error in process " .. processName .. ": " .. tostring(err))
                    -- Display error message
                    local w = term.current()
                    w.setBackgroundColor(colors.red)
                    w.setTextColor(colors.white)
                    w.clear()
                    w.setCursorPos(1, 1)
                    print("Error in process: " .. processName)
                    print(err)
                    print("\nPress any key to close this window.")
                    os.pullEvent("key")
                else
                    nodeos.logging.debug("Processes", "Process " .. processName .. " completed normally")
                end

                nodeos.endProcess(_G.id)
            end
        elseif type(path) == "function" then
            nodeos.logging.debug("Processes", "Starting function-based process: " .. processName)
            return function()
                local nodeos = nodeos
                local id = nodeos.lastProcID

                -- Set up error handler
                local function errorHandler(err)
                    nodeos.logging.fatal(processName, err)
                    return err
                end

                -- Run the function with error handling
                local ok, err = xpcall(path, errorHandler)

                if not ok then
                    nodeos.logging.error("Processes", "Error in process " .. processName .. ": " .. tostring(err))
                    -- Display error message
                    local w = term.current()
                    w.setBackgroundColor(colors.red)
                    w.setTextColor(colors.white)
                    w.clear()
                    w.setCursorPos(1, 1)
                    print("Error in process: " .. processName)
                    print(err)
                    print("\nPress any key to close this window.")
                    os.pullEvent("key")
                else
                    nodeos.logging.debug("Processes", "Process " .. processName .. " completed normally")
                end

                nodeos.endProcess(id)
            end
        end

        return function() end
    end

    nodeos.changeSettings = function(pid, newSettings)
        local process = nodeos.processes[pid]
        if not process then return end

        local path = process.path

        -- Update title
        if not newSettings.title then
            if type(path) == "string" then
                newSettings.title = fs.getName(path)
                if newSettings.title:sub(-4) == ".lua" then
                    newSettings.title = newSettings.title:sub(1, -5)
                end
            else
                newSettings.title = "Untitled"
            end
        end

        -- Configure window settings
        newSettings.showTitlebar = (newSettings.showTitlebar == nil) or newSettings.showTitlebar

        -- Configure size
        newSettings.width = newSettings.width or 20
        newSettings.height = newSettings.height or 10

        -- Configure position
        if not newSettings.x then
            newSettings.x = math.ceil(termWidth / 2 - (newSettings.width / 2))
        end

        if not newSettings.y then
            local yOffset = (newSettings.height % 2 == 0) and 0 or 1
            newSettings.y = math.ceil(termHeight / 2 - (newSettings.height / 2)) + yOffset
        end

        -- Preserve critical properties
        newSettings.path = process.path
        newSettings.window = process.window
        newSettings.coroutine = process.coroutine

        -- Update process
        nodeos.processes[pid] = newSettings
    end

    nodeos.logging.info("Processes", "Process management module initialization complete")
end

return module
