-- nodeos Helper Functions
-- Contains various utility functions used by the process manager

local module = {}

function module.init(nodeos, native, termWidth, termHeight)
    -- Helper Functions
    nodeos.contains = function(tbl, elem)
        for _, v in pairs(tbl) do
            if elem == v then
                return true
            end
        end
        return false
    end

    nodeos.isKeyDown = function(id)
        for i, v in pairs(nodeos.keysDown) do
            if v == id then
                return i
            end
        end
        return nil
    end

    nodeos.getSize = function()
        return native.getSize()
    end

    nodeos.isPointInWindow = function(x, y, proc)
        if proc.minimized then
            return false
        end
        if proc.maximized then
            return x >= 1 and x <= termWidth and y >= 2 and y <= termHeight - 1
        end
        return x >= proc.x and x <= proc.x + proc.width - 1 and
            y >= proc.y and y <= proc.y + proc.height - 1
    end
end

return module
