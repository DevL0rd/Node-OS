-- nodeos Drawing Functions
-- Handles rendering of windows and UI elements

local module = {}

function module.init(nodeos, native, termWidth, termHeight)
    nodeos.logging.info("Draw", "Initializing drawing module")

    -- ===============================
    -- Drawing Functions
    -- ===============================
    nodeos.drawProcesses = function()
        term.redirect(native)
        term.setBackgroundColor(nodeos.theme.desktop.background)
        term.clear()
        term.setCursorPos(1, 5)

        if nodeos.selectedProcess.minimized then
            nodeos.selectProcess(nodeos.titlebarID)
        end

        -- Draw processes from the sorted list in reverse order
        -- This ensures the most recently used process (index 1) is drawn last (on top)
        for i = #nodeos.processes_sorted, 1, -1 do
            local pid = nodeos.processes_sorted[i]
            local proc = nodeos.processes[pid]
            if proc then
                nodeos.drawProcess(proc)
            end
        end

        -- Draw the titlebar (if it's not already drawn)
        if nodeos.titlebarID ~= nodeos.selectedProcessID then
            nodeos.drawProcess(nodeos.processes[nodeos.titlebarID])
        end
    end

    nodeos.drawProcess = function(proc)
        if not proc then
            proc = nodeos.selectedProcess
        end
        term.redirect(native)

        local x, y, width, height
        local titlebarY

        -- Calculate window positioning based on state
        if proc.maximized then
            -- Maximized window positioning
            if proc.showTitlebar then
                x, y, width, height = 1, 3, termWidth, termHeight - 2
                titlebarY = 2
            else
                x, y, width, height = 1, 2, termWidth, termHeight - 1
            end
        else
            -- Normal window positioning
            if proc.showTitlebar then
                x, y, width, height = proc.x, proc.y + 1, proc.width, proc.height
                titlebarY = proc.y
            else
                x, y, width, height = proc.x, proc.y, proc.width, proc.height
            end
        end

        -- Reposition the window
        proc.window.reposition(x, y, width, height)

        -- Draw titlebar if needed
        if proc.showTitlebar then
            -- Determine titlebar width and position
            local titlebarX, titlebarWidth
            if proc.maximized then
                titlebarX, titlebarWidth = 1, termWidth
            else
                titlebarX, titlebarWidth = proc.x, proc.width
            end

            -- Draw titlebar background
            local titlebarColor = (proc == nodeos.selectedProcess)
                and nodeos.theme.window.titlebar.backgroundSelected
                or nodeos.theme.window.titlebar.background
            paintutils.drawLine(titlebarX, titlebarY, titlebarX + titlebarWidth - 1, titlebarY, titlebarColor)

            -- Draw title
            local titleX
            if proc.maximized then
                titleX = math.floor((termWidth - string.len(proc.title) / 2) / 2)
            else
                titleX = proc.x + math.floor((proc.width - string.len(proc.title)) / 2)
            end

            term.setCursorPos(titleX, titlebarY)
            term.setTextColor(nodeos.theme.window.titlebar.text)
            term.write(proc.title)

            -- Draw window controls
            if not proc.disableControls then
                local controlsX
                if proc.maximized then
                    controlsX = termWidth - 2
                else
                    controlsX = proc.x + proc.width - 3
                end

                nodeos.drawWindowControls(controlsX, titlebarY, proc == nodeos.selectedProcess)
            end
        end

        -- Redraw window content
        term.redirect(proc.window)
        proc.window.redraw()
    end

    nodeos.drawWindowControls = function(x, y, isSelected)
        term.setCursorPos(x, y)

        -- Maximize button
        term.setTextColor(isSelected and nodeos.theme.window.maximize or nodeos.theme.window.titlebar.text)
        term.write("\7")

        -- Minimize button
        term.setTextColor(isSelected and nodeos.theme.window.minimize or nodeos.theme.window.titlebar.text)
        term.write("\7")

        -- Close button
        term.setTextColor(isSelected and nodeos.theme.window.close or nodeos.theme.window.titlebar.text)
        term.write("\7")
    end

    nodeos.logging.info("Draw", "Drawing module initialization complete")
end

return module
