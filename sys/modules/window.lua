-- nodeos Window Management
-- Handles window operations like resizing, moving, maximizing, etc.

local module = {}

function module.init(nodeos, native, termWidth, termHeight)
    nodeos.logging.info("Window", "Initializing window management module")

    -- ===============================
    -- Window Management
    -- ===============================
    nodeos.toggleMaximize = function()
        nodeos.logging.debug("Window", "Toggling maximize state for " .. (nodeos.selectedProcess.title or "Untitled"))

        if nodeos.selectedProcess.minimized then
            nodeos.logging.debug("Window", "Unminimizing process first")
            nodeos.selectedProcess.minimized = false
        end

        nodeos.selectedProcess.maximized = not nodeos.selectedProcess.maximized

        if nodeos.selectedProcess.maximized then
            nodeos.logging.debug("Window", "Process maximized: " .. (nodeos.selectedProcess.title or "Untitled"))
        else
            nodeos.logging.debug("Window", "Process restored: " .. (nodeos.selectedProcess.title or "Untitled"))
        end

        term.redirect(nodeos.selectedProcess.window)
        coroutine.resume(nodeos.selectedProcess.coroutine, "term_resize")
        nodeos.drawProcesses()
    end

    nodeos.snapWindow = function(mouseX, mouseY)
        -- Don't snap if maximized or minimized
        if nodeos.selectedProcess.maximized or nodeos.selectedProcess.minimized then
            return false
        end

        local snapThreshold = 2 -- How close to the edge to trigger snapping
        local halfWidth = math.floor(termWidth / 2)
        local halfHeight = math.floor((termHeight - 2) / 2)

        local snapped = true -- We'll set to true if any snap occurs
        local snapType = ""

        -- Corner snaps
        if mouseX <= snapThreshold and mouseY <= snapThreshold then
            -- Top-left corner
            snapType = "top-left corner"
            nodeos.setWindowBounds(1, 2, halfWidth, halfHeight)
        elseif mouseX >= termWidth - snapThreshold and mouseY <= snapThreshold then
            -- Top-right corner
            snapType = "top-right corner"
            nodeos.setWindowBounds(termWidth - halfWidth + 1, 2, halfWidth, halfHeight)
        elseif mouseX <= snapThreshold and mouseY >= termHeight - snapThreshold then
            -- Bottom-left corner
            snapType = "bottom-left corner"
            nodeos.setWindowBounds(1, 2 + halfHeight, halfWidth, halfHeight)
        elseif mouseX >= termWidth - snapThreshold and mouseY >= termHeight - snapThreshold then
            -- Bottom-right corner
            snapType = "bottom-right corner"
            nodeos.setWindowBounds(termWidth - halfWidth + 1, 2 + halfHeight, halfWidth, halfHeight)
            -- Edge snaps
        elseif mouseX <= snapThreshold then
            -- Left edge
            snapType = "left edge"
            nodeos.setWindowBounds(1, 2, halfWidth, termHeight - 2)
        elseif mouseX >= termWidth - snapThreshold then
            -- Right edge
            snapType = "right edge"
            nodeos.setWindowBounds(termWidth - halfWidth + 1, 2, halfWidth, termHeight - 2)
        elseif mouseY >= termHeight - snapThreshold then
            -- Bottom edge
            snapType = "bottom edge"
            nodeos.setWindowBounds(1, 2 + halfHeight, termWidth, halfHeight)
        elseif mouseY <= snapThreshold then
            -- Top edge (maximizes)
            snapType = "top edge (maximize)"
            nodeos.setWindowBounds(1, 2, termWidth, termHeight - 2)
            nodeos.selectedProcess.maximized = true
            nodeos.selectedProcess.minimized = false
        else
            snapped = false
        end

        if snapped then
            nodeos.logging.debug("Window", "Window snapped to " .. snapType)
            term.redirect(nodeos.selectedProcess.window)
            coroutine.resume(nodeos.selectedProcess.coroutine, "term_resize")
        end

        return snapped
    end

    nodeos.setWindowBounds = function(x, y, width, height)
        nodeos.logging.debug("Window", "Setting window bounds to x=" .. x .. ", y=" .. y ..
            ", width=" .. width .. ", height=" .. height)
        nodeos.selectedProcess.x = x
        nodeos.selectedProcess.y = y
        nodeos.selectedProcess.width = width
        nodeos.selectedProcess.height = height
    end

    nodeos.isClickOnTitleBar = function(x, y)
        local proc = nodeos.selectedProcess
        if not proc.showTitlebar then return false end

        if not proc.maximized then
            return x >= proc.x and x <= proc.x + proc.width - 4 and y == proc.y
        else
            return y == 2 and x < termWidth - 3
        end
    end

    nodeos.passEventToProcess = function(eventType, button, x, y)
        if not nodeos.selectedProcess then return end

        local passX, passY

        -- Adjust coordinates based on window state
        if not nodeos.selectedProcess.maximized then
            local adjustY = nodeos.selectedProcess.showTitlebar and 0 or 1
            passX = x - nodeos.selectedProcess.x + 1
            passY = y - nodeos.selectedProcess.y + adjustY
        else
            local adjustY = nodeos.selectedProcess.showTitlebar and 2 or 1
            passX = x
            passY = y - adjustY
        end
        term.redirect(nodeos.selectedProcess.window)
        coroutine.resume(nodeos.selectedProcess.coroutine, eventType, button, passX, passY)
    end

    nodeos.logging.info("Window", "Window management module initialization complete")
end

return module
