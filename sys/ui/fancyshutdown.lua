term.setBackgroundColor(colors.cyan)
term.setPaletteColour(colors.cyan, 76 / 255, 153 / 255, 178 / 255)
term.setPaletteColour(colors.white, 1, 1, 1)
term.clear()
local args = { ... }
local w, h = term.getSize()

term.setCursorPos(w / 2 - string.len("See yah") / 2, h / 2)
term.setTextColor(colors.white)
term.write("See yah")
term.setBackgroundColor(colors.black)
sleep(1)

local startColors = { r = 76 / 255, g = 153 / 255, b = 178 / 255 }

for i = 1, 0, -0.1 do
    term.setPaletteColour(colors.cyan, startColors.r * i, startColors.g * i, startColors.b * i)
    term.setPaletteColour(colors.white, i, i, i)
    sleep()
end

if args[1] == "shutdown" then
    os.shutdown()
elseif args[1] == "reboot" then
    os.reboot()
end