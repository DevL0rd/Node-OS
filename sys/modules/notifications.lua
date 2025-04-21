local module = {}

function module.init(nodeos, native, termWidth, termHeight)
    local notifications = {}
    notifications.title = "Welcome"
    notifications.message = "Welcome back!"
    notifications.showTime = 5
    notifications.show = false
    notifications.timeout = 5
    notifications.title_color = "white"
    notifications.message_color = "lightGray"
    function notifications.push(title, message, title_color, message_color)
        notifications.timeout = notifications.showTime
        notifications.title = title
        notifications.message = message
        if title_color == nil or not colors[title_color] then
            notifications.title_color = "white"
        else
            notifications.title_color = title_color
        end
        if message_color == nil or not colors[message_color] then
            notifications.message_color = "lightGray"
        else
            notifications.message_color = message_color
        end
        notifications.show = true
    end

    nodeos.notifications = notifications

    function notifications_process()
        local last_state = false
        while true do
            sleep(0.5)
            if nodeos.notifications.show ~= last_state then
                last_state = nodeos.notifications.show
                if nodeos.notifications.show then
                    nodeos.graphics.fillLine("-", 1, nodeos.notifications.title_color, "black")
                    nodeos.graphics.fillLine(" ", 2, "white", "black")
                    nodeos.graphics.fillLine(" ", 3, "white", "black")
                    nodeos.graphics.fillLine(" ", 4, "white", "black")
                    nodeos.graphics.fillLine("-", 5, nodeos.notifications.title_color, "black")
                    nodeos.graphics.centerText("[ " .. nodeos.notifications.title .. " ]", 1,
                        nodeos.notifications.title_color,
                        "black")
                    nodeos.graphics.centerText(nodeos.notifications.message, 3, nodeos.notifications.message_color,
                        "black")
                    nodeos.unminimizeProcess(nodeos.notifyID)
                else
                    nodeos.minimizeProcess(nodeos.notifyID)
                end
            end
            nodeos.notifications.timeout = nodeos.notifications.timeout - 0.5
            if nodeos.notifications.timeout <= 0 then
                nodeos.notifications.show = false
            end
        end
    end

    -- Create notification service
    nodeos.notifyID = nodeos.createProcess(notifications_process, {
        x = termWidth - 18,
        y = 3,
        width = 19,
        height = 5,
        showTitlebar = false,
        dontShowInTitlebar = true,
        disableControls = true
    })
end

return module
