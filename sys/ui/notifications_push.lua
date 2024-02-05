
local tw, th = term.getSize()
local termUtils = require("/lib/termUtils")
local last_state = false
while true do
    sleep(0.5)
    if notify.show ~= last_state then
        last_state = notify.show
        if notify.show then
            termUtils.fillLine("-", 1, notify.title_color, "black")
            termUtils.fillLine(" ", 2, "white", "black")
            termUtils.fillLine(" ", 3, "white", "black")
            termUtils.fillLine(" ", 4, "white", "black")
            termUtils.fillLine("-", 5, notify.title_color, "black")
            termUtils.centerText("[ " .. notify.title .. " ]", 1, notify.title_color, "black")
            termUtils.centerText(notify.message, 3, notify.message_color, "black")
            pm.unminimizeProcess(pm.notifyID)
        else
            pm.minimizeProcess(pm.notifyID)
        end
    end
    notify.timeout = notify.timeout - 0.5
    if notify.timeout <= 0 then
        notify.show = false
    end
end