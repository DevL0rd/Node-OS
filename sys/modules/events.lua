-- nodeos Event Handling
-- Handles mouse, keyboard, and system events

local module = {}

function module.init(nodeos, native, termWidth, termHeight)
    -- ===============================
    -- Mouse Event Handling
    -- ===============================
    nodeos.handleMouseEvent = function(e, button, x, y)
        if e == "mouse_up" then
            nodeos.handleMouseUp(button, x, y)
        elseif e == "mouse_click" then
            nodeos.handleMouseClick(button, x, y)
        elseif e == "mouse_drag" then
            nodeos.handleMouseDrag(button, x, y)
        end
    end

    nodeos.handleMouseUp = function(button, x, y)
        -- Double click detection
        local currentTime = os.clock()
        local isDoubleClick = (currentTime - nodeos.clickState.lastTime < nodeos.clickState.doubleClickThreshold) and
            (math.abs(x - nodeos.clickState.lastX) <= 1) and
            (math.abs(y - nodeos.clickState.lastY) <= 1)

        -- Update click state
        nodeos.clickState.lastTime = currentTime
        nodeos.clickState.lastX = x
        nodeos.clickState.lastY = y

        -- Handle double-click on titlebar
        if isDoubleClick and nodeos.isClickOnTitleBar(x, y) then
            nodeos.toggleMaximize()
            return
        end

        -- Handle resize end
        if nodeos.resizeState.startX ~= nil and button == 2 then
            nodeos.resizeState.startX = nil
            nodeos.resizeState.startY = nil
            nodeos.resizeState.startW = nil
            nodeos.resizeState.startH = nil
            nodeos.drawProcesses()
            return
        end

        -- Handle drag end
        if nodeos.mvmtX ~= nil then
            if nodeos.snapWindow(x, y) then
                nodeos.drawProcesses()
            end
            nodeos.mvmtX = nil
        end
    end

    nodeos.handleMouseClick = function(button, x, y)
        -- Try to select another window using the same order as the drawing code
        if nodeos.selectedProcess.minimized or
            not nodeos.isPointInWindow(x, y, nodeos.selectedProcess) then
            for i, v in pairs(nodeos.processes) do
                if i ~= not v.minimized and
                    x >= v.x and x <= v.x + v.width - 1 and
                    y >= v.y and y <= v.y + v.height - 1 then
                    nodeos.selectProcess(i)
                    break
                end
            end
        end
        -- Handle resize start
        if button == 2 and not nodeos.selectedProcess.disallowResizing and
            x == nodeos.selectedProcess.x + nodeos.selectedProcess.width - 1 and
            y == nodeos.selectedProcess.y + nodeos.selectedProcess.height then
            nodeos.resizeState.startX = x
            nodeos.resizeState.startY = y
            nodeos.resizeState.startW = nodeos.selectedProcess.width
            nodeos.resizeState.startH = nodeos.selectedProcess.height
            return
        end

        -- Handle normal window titlebar clicks
        if not nodeos.selectedProcess.minimized and not nodeos.selectedProcess.maximized and
            nodeos.selectedProcess.showTitlebar and
            x >= nodeos.selectedProcess.x and x <= nodeos.selectedProcess.x + nodeos.selectedProcess.width - 1 and
            y == nodeos.selectedProcess.y and nodeos.mvmtX == nil then
            nodeos.handleTitlebarClick(x, y)
            return
        end

        -- Handle maximized window titlebar clicks
        if nodeos.selectedProcess.maximized and y == 2 then
            nodeos.handleMaximizedTitlebarClick(x, y)
            return
        end

        -- First check if the click is within the selected process (which is always on top)
        if not nodeos.selectedProcess.minimized and
            nodeos.isPointInWindow(x, y, nodeos.selectedProcess) then
            nodeos.passEventToProcess("mouse_click", button, x, y)
            return
        end
    end

    nodeos.handleTitlebarClick = function(x, y)
        -- Close button
        if not nodeos.selectedProcess.disableControls and
            x == nodeos.selectedProcess.x + nodeos.selectedProcess.width - 1 then
            nodeos.endProcess(nodeos.selectedProcessID)
            nodeos.drawProcesses()
            return
        end

        -- Minimize button
        if not nodeos.selectedProcess.disableControls and
            x == nodeos.selectedProcess.x + nodeos.selectedProcess.width - 3 then
            nodeos.selectedProcess.minimized = true
            nodeos.drawProcesses()
            return
        end

        -- Maximize button
        if not nodeos.selectedProcess.disableControls and
            x == nodeos.selectedProcess.x + nodeos.selectedProcess.width - 2 then
            nodeos.selectedProcess.maximized = true
            term.redirect(nodeos.selectedProcess.window)
            coroutine.resume(nodeos.selectedProcess.coroutine, "term_resize")
            nodeos.drawProcesses()
            return
        end

        -- Start window drag
        nodeos.mvmtX = x - nodeos.selectedProcess.x
        nodeos.drawProcesses()
    end

    nodeos.handleMaximizedTitlebarClick = function(x, y)
        -- Close button
        if not nodeos.selectedProcess.disableControls and x == termWidth then
            nodeos.endProcess(nodeos.selectedProcessID)
            nodeos.drawProcesses()
            return
        end

        -- Minimize button
        if not nodeos.selectedProcess.disableControls and x == termWidth - 2 then
            nodeos.selectedProcess.minimized = true
            nodeos.drawProcesses()
            return
        end

        -- Restore button
        if not nodeos.selectedProcess.disableControls and x == termWidth - 1 then
            nodeos.selectedProcess.maximized = false
            term.redirect(nodeos.selectedProcess.window)
            coroutine.resume(nodeos.selectedProcess.coroutine, "term_resize")
            nodeos.drawProcesses()
            return
        end

        -- Handle drag from maximized state
        nodeos.selectedProcess.maximized = false
        nodeos.selectedProcess.width = math.floor(termWidth * 0.7)
        nodeos.selectedProcess.height = math.floor(termHeight * 0.7)
        nodeos.selectedProcess.x = math.max(1, math.min(x - math.floor(nodeos.selectedProcess.width / 2),
            termWidth - nodeos.selectedProcess.width + 1))
        nodeos.selectedProcess.y = 2
        nodeos.mvmtX = math.floor(nodeos.selectedProcess.width / 2)
        term.redirect(nodeos.selectedProcess.window)
        coroutine.resume(nodeos.selectedProcess.coroutine, "term_resize")
        nodeos.drawProcesses()
    end

    nodeos.handleMouseDrag = function(button, x, y)
        -- Handle resize
        if nodeos.resizeState.startX ~= nil and button == 2 then
            nodeos.selectedProcess.width = nodeos.resizeState.startW + (x - nodeos.resizeState.startX)
            nodeos.selectedProcess.height = nodeos.resizeState.startH + (y - nodeos.resizeState.startY)
            term.redirect(nodeos.selectedProcess.window)
            coroutine.resume(nodeos.selectedProcess.coroutine, "term_resize")
            nodeos.drawProcesses()
            return
        end

        -- Handle window drag
        if not nodeos.selectedProcess.maximized and nodeos.selectedProcess.showTitlebar and
            x >= nodeos.selectedProcess.x - 1 and
            x <= nodeos.selectedProcess.x + nodeos.selectedProcess.width - 3 and
            y >= nodeos.selectedProcess.y - 1 and y <= nodeos.selectedProcess.y + 1 and
            nodeos.mvmtX then
            nodeos.selectedProcess.x = x - nodeos.mvmtX + 1
            nodeos.selectedProcess.y = y
            nodeos.drawProcesses()
            return
        end

        -- Pass event to process
        nodeos.passEventToProcess("mouse_drag", button, x, y)
    end

    -- ===============================
    -- Keyboard Event Handling
    -- ===============================
    nodeos.handleKeyboardEvent = function(e, keyCode)
        if e == "key" then
            table.insert(nodeos.keysDown, keyCode)
        elseif e == "key_up" and nodeos.isKeyDown(keyCode) then
            table.remove(nodeos.keysDown, nodeos.isKeyDown(keyCode))
        end

        -- Pass event to selected process
        term.redirect(nodeos.selectedProcess.window)
        coroutine.resume(nodeos.selectedProcess.coroutine, e, keyCode)
    end

    -- ===============================
    -- System Events
    -- ===============================
    nodeos.eventLoop = function()
        while true do
            local e = { os.pullEventRaw() }
            -- Mouse events
            if string.sub(e[1], 1, 6) == "mouse_" and not nodeos.selectedProcess.minimized then
                nodeos.handleMouseEvent(e[1], e[2], e[3], e[4])

                -- Keyboard events
            elseif e[1] == "char" or string.sub(e[1], 1, 3) == "key" or e[1] == "paste" then
                nodeos.handleKeyboardEvent(e[1], e[2])

                -- System events
            elseif e[1] == "nodeos_fancyshutdown" then
                term.redirect(native)
                shell.run("/sys/ui/fancyshutdown.lua", e[2])

                -- Login event
            elseif e[1] == "nodeos_login" then
                nodeos.handleLoginEvent()

                -- Paint event
            elseif e[1] == "nodeos_paint" then
                nodeos.drawProcess(nodeos.selectedProcess)

                -- Other events
            else
                if e[1] == "nodeos_themeupdate" then
                    nodeos.theme = loadTable("/etc/colors.cfg")
                end

                -- Pass event to all processes
                for _, v in pairs(nodeos.processes) do
                    term.redirect(v.window)
                    coroutine.resume(v.coroutine, table.unpack(e))
                end

                -- Redraw if needed
                if e[1] ~= "rednet_message" and e[1] ~= "modem_message" and e[1] ~= "timer" then
                    nodeos.drawProcesses()
                end
            end

            ::continue::
        end
    end
end

return module
