local notify = {}
local tw, th = term.getSize()
local termUtils = require("/lib/termUtils")
notify.title = "Welcome"
notify.message = "Welcome back!"
notify.showTime = 5
notify.show = false
notify.timeout = 5
notify.title_color = "white"
notify.message_color = "lightGray"
function notify.push(title, message, title_color, message_color)
  local w, h = term.getSize()
  local notifyID
  notify.timeout = notify.showTime
  notify.title = title
  notify.message = message
  if title_color == nil or not colors[title_color] then
    notify.title_color = "white"
  else
    notify.title_color = title_color
  end
    if message_color == nil or not colors[message_color] then
        notify.message_color = "lightGray"
    else
        notify.message_color = message_color
    end
    notify.show = true
end

return notify