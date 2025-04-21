_G.require = require
require("/sys/lua_extensions")
_G.nodeos = {}
-- ===============================
-- Initialization & Configuration
-- ===============================
local termWidth, termHeight = term.getSize()
local native = term.current()

-- Load modules
local moduleNames = {
  "settings",
  "graphics",
  "logging",
  "theme",
  "helpers",
  "processes",
  "window",
  "draw",
  "notifications",
  "net",
  "gps",
  "services",
  "titlebar",
  "login",
  "events",
}






function KERNEL()
  -- Helper function to load a module
  local function loadModule(name)
    local module = require("/sys/modules/" .. name)
    module.init(nodeos, native, termWidth, termHeight)
  end

  -- Load all modules
  for _, moduleName in ipairs(moduleNames) do
    loadModule(moduleName)
  end


  nodeos.drawProcesses()
  nodeos.eventLoop()
end

function start()
  local ok, err = xpcall(KERNEL, function(err)
    local function errorScreen(error)
      term.redirect(term.native())
      term.setBackgroundColor(colors.red)
      term.clear()
      term.setTextColor(colors.white)
      term.setCursorPos(2, 2)
      term.write("Kernel Panic!")
      local w, h = term.getSize()
      local errorContentWindow = window.create(term.native(), 2, 4, w - 2, h - 3)
      errorContentWindow.setBackgroundColor(colors.red)
      errorContentWindow.setTextColor(colors.white)
      errorContentWindow.clear()
      term.redirect(errorContentWindow)
      print(error)
      for i = 30, 1, -1 do
        term.setCursorPos(2, h - 1)
        term.write(("The system will restart in %d second(s)"):format(i))
        sleep(1)
      end
      logging.fatal("Kernel", "Kernel panic: " .. error)
      os.reboot()
    end

    errorScreen(err)
  end)
end

start()
