-- nodeos Core Process Management
-- Handles process creation, selection, and lifecycle management

local module = {}

function module.init(nodeos, native, termWidth, termHeight)
    -- ===============================
    -- Process Management
    -- ===============================
    nodeos.processes = {}
    nodeos.processes_sorted = {}
    nodeos.lastProcID = 0
    nodeos.selectedProcessID = 0
    nodeos.selectedProcess = nil
    nodeos.titlebarID = 1

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
            nodeos.selectedProcessID = pid
            nodeos.selectedProcess = nodeos.processes[pid]

            if not nodeos.selectedProcess.minimized then
                nodeos.selectedProcess.window.setVisible(true)
                nodeos.drawProcess(nodeos.selectedProcess)

                -- Update processes_sorted list
                -- Remove the process from its current position if it exists in the list
                for i, v in ipairs(nodeos.processes_sorted) do
                    if v == pid then
                        table.remove(nodeos.processes_sorted, i)
                        break
                    end
                end

                -- Add the process to the top of the list
                table.insert(nodeos.processes_sorted, 1, pid)
            end

            os.queueEvent("titlebar_paint")
        end
    end

    nodeos.selectProcessAfter = function(pid, time)
        sleep(time)
        nodeos.selectProcess(pid)
    end

    nodeos.minimizeProcess = function(pid)
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
        nodeos.processes[pid].minimized = false

        -- Add to the top of processes_sorted when unminimized
        -- First check if it's already in the list (shouldn't be, but just in case)
        local found = false
        for i, v in ipairs(nodeos.processes_sorted) do
            if v == pid then
                found = true
                break
            end
        end

        -- Add to top of list if not found
        if not found then
            table.insert(nodeos.processes_sorted, 1, pid)
        end

        nodeos.selectProcess(pid)
    end

    nodeos.endProcess = function(pid)
        local proc = nodeos.processes[pid]
        if not proc then return end

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

        -- Configure process settings
        nodeos.configureProcessSettings(newProc, path)

        -- Create window and coroutine
        newProc.window = window.create(native, newProc.x, newProc.y, newProc.width, newProc.height)
        term.redirect(newProc.window)
        newProc.coroutine = coroutine.create(nodeos.createProcessRunFunction(path))

        -- Start process
        coroutine.resume(newProc.coroutine)
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

    nodeos.createProcessRunFunction = function(path)
        local newTable = table
        newTable["contains"] = nodeos.contains

        if type(path) == "string" then
            return function()
                _G.id = nodeos.lastProcID
                _G.table = newTable

                local nargs = nil
                if path:find(" ") then
                    path, nargs = path:match("(.+)%s+(.+)")
                end

                os.run({
                    _G = _G,
                    package = package
                }, path, nargs)

                nodeos.endProcess(_G.id)
            end
        elseif type(path) == "function" then
            return function()
                local nodeos = nodeos
                local id = nodeos.lastProcID
                local table = newTable
                path()
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
end

return module
