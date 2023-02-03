local w, h = term.getSize()
local s = require("/lib/settings").settings

local function loadtable(path)
  local file = fs.open(path, "r")
  local content = textutils.unserialize(file.readAll())
  file.close()
  return content
end

local packageDirs = loadtable("/etc/libs.cfg")
for i, v in pairs(packageDirs) do
  package.path = package.path .. ";" .. v
end
_G.package = package
local pm = require("/lib/processmanager")
_G.pm = pm
_G.require = require
_G.shell = shell
local sha256 = require("/lib/sha256")
local util = require("util")
local file = util.loadModule("file")

function os_thread()
  local native = term.current()
  local w, h = term.getSize()
  files = fs.list("/sys/services")
  for i, v in pairs(files) do
    v = "/sys/services/" .. v
    if v:sub(-4) == ".lua" then
      --remove the .lua
      v = v:sub(1, -5)
      require(v:gsub("/", "."))
    end
  end
  files = fs.list("/home/services")
  for i, v in pairs(files) do
    v = "/home/services/" .. v
    if v:sub(-4) == ".lua" then
      --remove the .lua
      v = v:sub(1, -5)
      require(v:gsub("/", "."))
    end
  end
  if s.consoleOnly == false then
    local loginID = pm.createProcess("/sys/ui/login.lua", {
      showTitlebar = true,
      dontShowInTitlebar = true,
      disableControls = true,
      title = "Login",
      height = 7,
      y = (h / 2) - 4,
    })
    pm.selectProcess(loginID)
  else
    files = fs.list("/home/startup")
    for i, v in pairs(files) do
      v = "/home/startup/" .. v
      if v:sub(-4) == ".lua" then
        os.run({
          _G = _G,
          package = package
        }, v)
      end
    end
    pm.selectProcess(pm.createProcess("/sys/shell.lua", {
      showTitlebar = false,
      dontShowInTitlebar = true,
      disableControls = true,
      title = "Login",
      x = 1,
      y = 1,
      width = w,
      height = h,
    }))
      -- os.run({0
      --   _G = _G,
      --   package = package
      -- }, "/sys/shell.lua")
  end
  pm.drawProcesses()
  pm.eventLoop()
end

function start()
  local ok, err = xpcall(os_thread, function(err)
    local function errorScreen(error)
      term.redirect(term.native())
      term.setBackgroundColor(colors.red)
      term.clear()
      term.setTextColor(colors.white)
      term.setCursorPos(2, 2)
      term.write("System Crash")
      local w, h = term.getSize()
      local errorContentWindow = window.create(term.native(), 2, 4, w - 2, h - 3)
      errorContentWindow.setBackgroundColor(colors.red)
      errorContentWindow.setTextColor(colors.white)
      errorContentWindow.clear()
      term.redirect(errorContentWindow)
      print(error)
      -- term.redirect(term.native())
      -- term.setCursorPos(2, h - 1)
      -- term.write("Dumping logs...")
      -- dumpLogs()
      for i = 30, 1, -1 do
        term.setCursorPos(2, h - 1)
        term.write(("The system will restart in %d second(s)"):format(i))
        sleep(1)
      end
      os.reboot()
    end

    errorScreen(err)
  end)
end

start()