local module = {}

function module.init(nodeos, native, termWidth, termHeight)
    local logging = {}

    logging.logs = {}
    function logging.log(name, msg, level)
        if not level then
            level = "INFO"
        end
        table.insert(logging.logs,
            {
                name = name,
                time = os.time(),
                level = level,
                msg = msg,
            }
        )
        if #logging.logs > 100000 then
            table.remove(logging.logs, 1)
        end
        os.queueEvent("nodeos_logging", {
            name = name,
            time = os.time(),
            level = level,
            msg = msg,
        })
    end

    function logging.saveLogs(name, path)
        local logs = logging.getLogs(name)
        local file = fs.open(path, "w")
        if file then
            for i, v in pairs(logs) do
                file.writeLine(v.time .. " [" .. v.level .. "] " .. v.name .. ": " .. v.msg)
            end
            file.close()
        else
            logging.error("Logging", "Failed to open log file for writing: " .. path)
        end
    end

    function logging.warn(name, msg)
        logging.log(name, msg, "WARN")
    end

    function logging.error(name, msg)
        logging.log(name, msg, "ERROR")
        logging.saveLogs(nil, "/tmp/log.txt")
    end

    function logging.info(name, msg)
        logging.log(name, msg, "INFO")
    end

    function logging.debug(name, msg)
        logging.log(name, msg, "DEBUG")
    end

    function logging.fatal(name, msg)
        logging.log(name, msg, "FATAL")
        logging.saveLogs(nil, "/tmp/log.txt")
    end

    function logging.getLogs(name, levels)
        local logs = {}
        for i, v in pairs(logging.logs) do
            if name and v.name == name then
                if levels then
                    for j, k in pairs(levels) do
                        if v.level == k then
                            table.insert(logs, v)
                        end
                    end
                else
                    table.insert(logs, v)
                end
            else
                if levels then
                    for j, k in pairs(levels) do
                        if v.level == k then
                            table.insert(logs, v)
                        end
                    end
                else
                    table.insert(logs, v)
                end
            end
        end
        return logs
    end

    logging.info("Logging", "Logging init.")

    nodeos.logging = logging
end

return module
