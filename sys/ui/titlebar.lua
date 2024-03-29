local ok, err = pcall(function()
  local menuPID
  local hiddenNames = { "menu", "titlebar" }
  local w = term.getSize()
  local running = {}
  local procList
  local util = require("/lib/util")
  local nfte = require("/lib/nfte")
  local file = util.loadModule("file")
  local sets = require("settings").settings
  local theme = _G.pm.getTheme()
  local pm = _G.pm

  local function draw()
    procList = pm.listProcesses()
    term.setBackgroundColor(theme.titlebar.background)
    term.clear()
    local time = " " .. textutils.formatTime(os.time(), false)
    term.setTextColor(theme.titlebar.text)
    local renderX = w - string.len(time) + 1
    term.setCursorPos(renderX, 1)
    term.write(time)
    if gps.isConnected then
      term.setTextColor(colors["green"])
    else
      term.setTextColor(colors["red"])
    end
    renderX = renderX - 3
    term.setCursorPos(renderX, 1)
    term.write("GPS")
    if net.isConnected then
      term.setTextColor(colors["green"])
    else
      term.setTextColor(colors["red"])
    end
    renderX = renderX - 4
    term.setCursorPos(renderX, 1)
    term.write("NET")
    term.setTextColor(theme.menu.textSecondary)
    term.setCursorPos(1, 1)
    if menuPID and procList[menuPID] then
      term.setBackgroundColor(theme.menu.buttonBG_Selected)
      term.setTextColor(theme.menu.text)
    else
      term.setBackgroundColor(theme.menu.buttonBG)
      term.setTextColor(theme.menu.buttonText)
      menuPID = nil
    end
    term.write(" N ")
    term.setBackgroundColor(theme.titlebar.background)
    term.write(" ")
    for i, v in pairs(procList) do
      if not v.dontShowInTitlebar then
        local x, y = term.getCursorPos()
        v.startX = x
        if v == pm.getSelectedProcess() then
          term.setTextColor(theme.menu.text)
        else
          term.setTextColor(theme.menu.textSecondary)
        end
        local ins = v
        term.write(v.title .. " ")
        local x, y = term.getCursorPos()
        v.endX = x
        v.pid = i
        table.insert(running, v)
      end
    end
  end


  os.queueEvent("titlebar_paint")
  while true do
    local e = { os.pullEvent() }
    if e[1] == "mouse_click" then
      local m, x, y = e[2], e[3], e[4]
      if x >= 1 and x <= 3 and y == 1 then
        if menuPID and pm.listProcesses()[menuPID] == nil then
          menuPID = nil
        else
          if menuPID ~= nil then
            pm.endProcess(menuPID)
            menuPID = nil
          else
            menuPID = pm.createProcess("/sys/ui/menu.lua", {
              x = 1,
              y = 2,
              width = 20,
              height = 14,
              showTitlebar = false,
              dontShowInTitlebar = true
            })

            pm.selectProcess(menuPID)
          end
        end
      else
        local pid
        pid = nil -- just in case...
        for i, v in pairs(running) do
          if x >= v.startX and x <= v.endX then
            pid = v.pid
          end
        end

        if pid then
          if procList[pid].minimized then
            pm.unminimizeProcess(pid)
          end
          pm.selectProcess(pid)
        end
      end
    elseif e[1] == "pm_themeupdate" then
      theme = file.readTable("/etc/colors.cfg")
    elseif e[1] == "titlebar_paint" or e[1] == "clock_tick" then
      draw()
    end
  end
end)