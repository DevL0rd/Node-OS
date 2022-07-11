local ok, err = pcall(function()
  local menuPID
  local hiddenNames = { "menu", "titlebar" }
  local w = term.getSize()
  local running = {}
  local procList

  local util = require("/lib/util")
  local nfte = require("/lib/nfte")
  local file = util.loadModule("file")
  local theme = _G.wm.getTheme()
  local wm = _G.wm

  for i, v in pairs(_G) do
    write(i .. " ")
  end

  local function drawTime()
    local time = " " .. textutils.formatTime(os.time(), false)
    term.setTextColor(theme.menu.textSecondary)
    term.setCursorPos(w - string.len(time) + 1, 1)
    term.write(time)
  end

  local function draw()
    procList = wm.listProcesses()
    term.setBackgroundColor(theme.menu.background)
    term.clear()
    drawTime()
    term.setCursorPos(1, 1)
    if menuPID and procList[menuPID] then
      term.setBackgroundColor(theme.menu.background)
      term.setTextColor(theme.menu.text)
    else
      menuPID = nil
    end
    term.write("@ ")

    for i, v in pairs(procList) do
      if not v.dontShowInTitlebar then
        local x, y = term.getCursorPos()
        v.startX = x
        if v == wm.getSelectedProcess() then
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

  local function event()
    while true do
      local e = { os.pullEvent() }
      draw()
      if e[1] == "mouse_click" then
        local m, x, y = e[2], e[3], e[4]
        if x == 1 and y == 1 then
          if menuPID and wm.listProcesses()[menuPID] == nil then
            menuPID = nil
          else
            if menuPID ~= nil then
              wm.endProcess(menuPID)
              menuPID = nil
            else
              menuPID = wm.createProcess("/sys/ui/menu.lua", {
                x = 1,
                y = 2,
                width = 20,
                height = 14,
                showTitlebar = false,
                dontShowInTitlebar = true
              })

              wm.selectProcess(menuPID)
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
              wm.unminimizeProcess(pid)
            end
            wm.selectProcess(pid)
          end
        end
      elseif e[1] == "wm_themeupdate" then
        theme = file.readTable("/etc/colors.cfg")
      end
    end
  end

  local function time()
    while true do
      drawTime()
      sleep(1)
    end
  end

  parallel.waitForAll(time, event)
end)

if not ok then os.queueEvent("wm_titlebardeath") end