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
        local file = fs.open("/tmp/logs.txt", "a")
        file.writeLine(("%s [%s][%s] %s"):format(os.date("%H:%M:%S"), name, level, msg))
        file.close()
        os.queueEvent("logging", {
            name = name,
            time = os.time(),
            level = level,
            msg = msg,
        })
    end

    function logging.warn(name, msg)
        logging.log(name, msg, "WARN")
    end

    function logging.error(name, msg)
        debug.log(name, msg, "ERROR")
    end

    function logging.info(name, msg)
        logging.log(name, msg, "INFO")
    end

    function logging.debug(name, msg)
        logging.log(name, msg, "DEBUG")
    end

    function logging.fatal(name, msg)
        logging.log(name, msg, "FATAL")
    end

    function logging.getLogs(name, levels)
        local logs = {}
        for i, v in pairs(logging.logs) do
            if v.name == name then
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

    nodeos.logging = logging
end

return module
