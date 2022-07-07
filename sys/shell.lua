shellRunning = false
isLocked = true

function shell_thread()
    --STARTUP--
    while true do
        if settings.password == "" then
            isLocked = false
        end
        newLine()
        local input = getInput()
        if isLocked then
            if settings.password == input then
                isLocked = false
                statusBarHeight = 2
                if devicesConnected["speaker"] then
                    peripherals[devicesConnected["speaker"]].peripheral.playNote("bell", speaker_settings.volume, 1)
                    sleep(0.1)
                    peripherals[devicesConnected["speaker"]].peripheral.playNote("bell", speaker_settings.volume, 4)
                end
                clear()
            end
        else
            local params = getWords(input)
            local command = table.remove(params, 1)
            if command then
                if string.sub(input, 1, 2) == "! " then
                    command = table.remove(params, 1)
                    if command then
                        command = string.lower(command)
                        local closestID = getClosestPC()
                        if closestID then
                            local res = sendCommand(closestID, command, params)
                            if res then
                                nPrint(res, "blue")
                            else
                                nPrint("No response received!", "red")
                            end
                        else
                            nPrint("PC not in range!", "red")
                        end
                    else
                        nPrint("Usage: ![pcname/id] <command>", "red")
                    end
                elseif string.sub(input, 1, 1) == "!" then
                    pcName = command:gsub('%!', '')
                    command = table.remove(params, 1)
                    if command then
                        command = string.lower(command)
                        if localComputers[tonumber(pcName)] then
                            local res = sendCommand(tonumber(pcName), command, params)
                            if res then
                                nPrint(res, "blue")
                            else
                                nPrint("No response received!", "red")
                            end
                        elseif localComputers[getComputerID(pcName)] then
                            local res = sendCommand(getComputerID(pcName), command, params)
                            if res then
                                nPrint(res, "blue")
                            else
                                nPrint("No response received!", "red")
                            end
                        else
                            nPrint("Cannot find PC!", "red")
                        end
                    else
                        nPrint("Usage: ![pcname/id] <command>", "red")
                    end
                else
                    if coms[command] then
                        if coms[command].isLocal then
                            coms[command].exec(params)
                        else
                            nPrint("This command can only be run remotely.", "red")
                        end
                    else
                        stat, err = pcall(shellRun, input)
                        if err then
                            nPrint(err, "red")
                        end
                    end
                end
            end
        end
    end
end

function shellRun(input)
    shellRunning = true
    local pathsToTry = {
        "",
        "home/bin",
        "sys/bin"
    }
    local args = split(input, " ")
    local command = table.remove(args, 1)
    for k, path in pairs(pathsToTry) do
        path = path .. "/" .. command
        if fs.exists(path) or fs.exists(path .. ".lua") then
            argsStr = ""
            for i,v in ipairs(args) do
                if i == 1 then
                    argsStr = v
                else
                    argsStr = argsStr .. " " .. v
                end
            end
            shell.run(path .. " " .. argsStr)
            return
            -- _G["..."] = argsStr
            -- shellProg = require(path)
            -- --unload it after it is done
            -- shellProg = nil
            -- package.loaded[path] = nil
            -- _G[path] = nil
            -- shellRunning = false
            -- return
        end
    end
    shell.run(input)
    shellRunning = false
end