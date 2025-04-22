local args = { ... }

local level = args[1]
if level == "help" then
    nodeos.graphics.print("Usage: logs <level> [name]")
    nodeos.graphics.print("Levels: INFO, WARN, ERROR, DEBUG, FATAL, ALL")
    return
end
if not level then
    level = "ALL"
end
level = level:upper()
local name = args[2]
local validLevels = {
    ["INFO"] = true,
    ["WARN"] = true,
    ["ERROR"] = true,
    ["DEBUG"] = true,
    ["FATAL"] = true,
    ["ALL"] = true
}

if not validLevels[level] then
    nodeos.graphics.print("Invalid level. Valid levels are: INFO, WARN, ERROR, DEBUG, FATAL, ALL")
    return
end

local function displayLog(log)
    local levelColors = {
        ["INFO"] = "white",
        ["WARN"] = "yellow",
        ["ERROR"] = "red",
        ["DEBUG"] = "cyan",
        ["FATAL"] = "orange"
    }

    local color = levelColors[log.level] or "white"

    -- Concat all parts into a single string with correct formatting
    local logString = "[" .. log.name .. "] [" .. log.level .. "] " .. log.msg

    -- Print the entire log in one call with the appropriate color for the log level
    nodeos.graphics.print(logString, color)
end

-- Display existing logs matching criteria
local logs = {}

if level == "ALL" then
    logs = nodeos.logging.getLogs(name)
else
    logs = nodeos.logging.getLogs(name, { level })
end

-- Display existing logs
-- nodeos.graphics.clear()
for i, log in ipairs(logs) do
    displayLog(log)
end

local newLogs = {}
-- Start listening for new logs
function listenForLogs()
    while true do
        local event, data = os.pullEvent("nodeos_logging")
        if level == "ALL" or data.level == level then
            if not name or data.name == name then
                table.insert(newLogs, data)
            end
        end
    end
end

function printNewLogs()
    while true do
        if #newLogs > 0 then
            for i, log in ipairs(newLogs) do
                displayLog(log)
            end
            newLogs = {}
        end
        nodeos.graphics.endRender()
        os.sleep(0.1) -- Sleep for a short duration to avoid busy waiting
    end
end

nodeos.waitForAll("Logs", listenForLogs, printNewLogs)
