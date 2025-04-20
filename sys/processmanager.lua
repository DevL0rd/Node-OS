local pm = {}
pm.processes = {}
pm.lastProcID = 0
pm.selectedProcessID = 0
pm.selectedProcess = nil
pm.keysDown = {}
pm.titlebarID = 1
pm.resizeStartX = nil
pm.resizeStartY = nil
pm.resizeStartW = nil
pm.resizeStartH = nil
pm.mvmtX = nil
pm.isDrawingEnabled = true
-- Double click detection variables
pm.lastClickTime = 0
pm.lastClickX = 0
pm.lastClickY = 0
pm.doubleClickThreshold = 0.3 -- 300ms threshold for double clicks
local termWidth, termHeight = term.getSize()
local native = term.current()

function pm.getTheme()
  local themePath = file.readTable("/etc/theme.cfg").currentTheme
  pm.theme = file.readTable(themePath)
  return pm.theme
end

pm.getTheme()

function pm.selectProcess(pid)
  if pm.selectedProcessID ~= pid then
    if pm.processes[pid] then
      pm.selectedProcessID = pid
      pm.selectedProcess = pm.processes[pid]
      if not pm.selectedProcess.minimized then
        pm.selectedProcess.window.setVisible(true)
        pm.drawProcess(pm.selectedProcess)
      end
      os.queueEvent("titlebar_paint")
    end
  end
end

function pm.selectProcessAfter(pid, time)
  sleep(time)
  pm.selectProcess(pid)
end

function pm.minimizeProcess(pid)
  pm.processes[pid].minimized = true
end

function pm.unminimizeProcess(pid)
  pm.processes[pid].minimized = false
  pm.selectProcess(pid)
end

function pm.listProcesses()
  return pm.processes
end

function pm.getSelectedProcess()
  return pm.selectedProcess
end

function pm.getSelectedProcessID()
  return pm.selectedProcessID
end

function pm.endProcess(pid)
  local proc = pm.processes[pid]
  if proc then
    if pid == pm.selectedProcessID then
      -- Find the foremost window to focus instead of always selecting titlebar
      local foremostPid = pm.titlebarID -- Default to titlebar if no other windows found
      local foremostProcess = nil

      -- Loop through all processes to find the foremost one
      for id, process in pairs(pm.processes) do
        if id ~= pid and id ~= pm.titlebarID
            and not process.minimized
            and not process.isService
            and not process.dontShowInTitlebar then
          -- Found a suitable process to focus
          foremostPid = id
          foremostProcess = process
          break
        end
      end

      pm.selectProcess(foremostPid)
    end
    proc.window.setVisible(false)
    pm.processes[pid] = nil
    pm.drawProcesses()
    os.queueEvent("titlebar_paint")
  end
end

function pm.getSize()
  return native.getSize()
end

function pm.changeSettings(pid, newSettings)
  local process = pm.processes[pid]
  if not process then return end

  local path = process.path

  if not newSettings.title and type(path) == "string" then
    newSettings.title = fs.getName(path)
    if newSettings.title:sub(-4) == ".lua" then
      newSettings.title = newSettings.title:sub(1, -5)
    end
  elseif type(path) ~= "string" then
    newSettings.title = "Untitled"
  end

  if newSettings.showTitlebar == nil or newSettings.showTitlebar == true then
    newSettings.showTitlebar = true
  end

  if not newSettings.width then
    newSettings.width = 20
  end
  if not newSettings.height then
    newSettings.height = 10
  end

  if not newSettings.x then
    newSettings.x = math.ceil(termWidth / 2 - (newSettings.width / 2))
  end
  if not newSettings.y then
    if (newSettings.height % 2) == 0 then
      newSettings.y = math.ceil(termHeight / 2 - (newSettings.height / 2))
    else
      newSettings.y = math.ceil(termHeight / 2 - (newSettings.height / 2)) + 1
    end
  end

  newSettings.path = process.path
  newSettings.window = process.window
  newSettings.coroutine = process.coroutine

  pm.processes[pid] = newSettings
end

function pm.createProcess(path, newProc)
  pm.lastProcID = pm.lastProcID + 1
  if not newProc.title and type(path) == "string" then
    newProc.title = fs.getName(path)
    if newProc.title:sub(-4) == ".lua" then
      newProc.title = newProc.title:sub(1, -5)
    end
  elseif type(path) ~= "string" and not newProc.title then
    newProc.title = "Untitled"
  end
  if newProc.isService == nil then
    newProc.isService = false
  end
  if newProc.showTitlebar == nil or newProc.showTitlebar == true then
    newProc.showTitlebar = true
  end
  if newProc.isService then
    newProc.showTitlebar = false
    newProc.dontShowInTitlebar = true
    newProc.disableControls = true
    newProc.minimized = true
  end

  if not newProc.width then
    newProc.width = 20
  end
  if not newProc.height then
    newProc.height = 10
  end



  if not newProc.x then
    newProc.x = math.ceil(termWidth / 2 - (newProc.width / 2))
  end
  if not newProc.y then
    if (newProc.height % 2) == 0 then
      newProc.y = math.ceil(termHeight / 2 - (newProc.height / 2))
    else
      newProc.y = math.ceil(termHeight / 2 - (newProc.height / 2)) + 1
    end
  end

  newProc.path = path

  local newTable = table
  newTable["contains"] = pm.contains

  local function run()
  end

  local req = _G.require

  if type(path) == "string" then
    run = function()
      _G.id = pm.lastProcID
      _G.table = newTable
      local nargs = nil
      if path:find(" ") then
        path, nargs = path:match("(.+)%s+(.+)")
      end

      os.run({
        _G = _G,
        package = package
      }, path, nargs)
      pm.endProcess(_G.id)
    end
  elseif type(path) == "function" then
    run = function()
      local pm = pm
      local id = pm.lastProcID
      local table = newTable
      path()
      pm.endProcess(id)
    end
  end

  newProc.window = window.create(native, newProc.x, newProc.y, newProc.width, newProc.height)
  term.redirect(newProc.window)
  newProc.coroutine = coroutine.create(run)
  coroutine.resume(newProc.coroutine)
  newProc.window.redraw()
  if pm.selectedProcess == nil then
    pm.selectedProcess = newProc
  end
  table.insert(pm.processes, pm.lastProcID, newProc)
  os.queueEvent("titlebar_paint")
  return pm.lastProcID
end

function pm.drawProcesses()
  term.redirect(native)
  term.setBackgroundColor(pm.theme.desktop.background)
  term.clear()
  term.setCursorPos(1, 5)
  if pm.selectedProcess.minimized then
    pm.selectProcess(pm.titlebarID)
  end

  for i, v in pairs(pm.processes) do
    if i ~= pm.selectedProcessID then
      if v.minimized then
        v.window.setVisible(false)
      else
        pm.drawProcess(v)
      end
    end
  end
  pm.drawProcess(pm.selectedProcess)
end

function pm.contains(tbl, elem)
  for i, v in pairs(tbl) do
    if elem == v then
      return true
    end
  end
  return false
end

function isKeyDown(id)
  for i, v in pairs(pm.keysDown) do
    if v == id then
      return i
    end
  end
end

function pm.drawProcess(proc)
  if proc.showTitlebar == false then
    term.redirect(proc.window)
    if proc.maximized then
      proc.window.reposition(1, 2, termWidth, termHeight - 1)
    else
      proc.window.reposition(proc.x, proc.y, proc.width, proc.height)
    end
    proc.window.redraw()
  else
    term.redirect(native)

    if proc.maximized then
      proc.window.reposition(1, 3, termWidth, termHeight - 2)
      if proc == pm.selectedProcess then
        paintutils.drawLine(1, 2, termWidth, 2, pm.theme.window.titlebar.backgroundSelected)
      else
        paintutils.drawLine(1, 2, termWidth, 2, pm.theme.window.titlebar.background)
      end
      term.setCursorPos(math.floor((termWidth - string.len(proc.title) / 2) / 2), 2)
      term.setTextColor(pm.theme.window.titlebar.text)
      term.write(proc.title)

      if not proc.disableControls then
        term.setCursorPos(termWidth - 2, 2)
        if proc == pm.selectedProcess then
          term.setTextColor(pm.theme.window.maximize)
        else
          term.setTextColor(pm.theme.window.titlebar.text)
        end
        term.write("\7")
        if proc == pm.selectedProcess then
          term.setTextColor(pm.theme.window.minimize)
        else
          term.setTextColor(pm.theme.window.titlebar.text)
        end
        term.write("\7")
        if proc == pm.selectedProcess then
          term.setTextColor(pm.theme.window.close)
        else
          term.setTextColor(pm.theme.window.titlebar.text)
        end
        term.write("\7")
      end
    else
      proc.window.reposition(proc.x, proc.y + 1, proc.width, proc.height)
      if proc == pm.selectedProcess then
        paintutils.drawLine(proc.x, proc.y, proc.x + proc.width - 1, proc.y, pm.theme.window.titlebar.backgroundSelected)
      else
        paintutils.drawLine(proc.x, proc.y, proc.x + proc.width - 1, proc.y, pm.theme.window.titlebar.background)
      end
      term.setCursorPos(proc.x + math.floor((proc.width - string.len(proc.title)) / 2), proc.y)
      term.setTextColor(pm.theme.window.titlebar.text)
      term.write(proc.title)

      if not proc.disableControls then
        term.setCursorPos(proc.x + proc.width - 3, proc.y)
        if proc == pm.selectedProcess then
          term.setTextColor(pm.theme.window.maximize)
        else
          term.setTextColor(pm.theme.window.titlebar.text)
        end
        term.write("\7")
        if proc == pm.selectedProcess then
          term.setTextColor(pm.theme.window.minimize)
        else
          term.setTextColor(pm.theme.window.titlebar.text)
        end
        term.write("\7")
        if proc == pm.selectedProcess then
          term.setTextColor(pm.theme.window.close)
        else
          term.setTextColor(pm.theme.window.titlebar.text)
        end
        term.write("\7")
      end
    end

    term.redirect(proc.window)
    proc.window.redraw()
  end
end

function pm.snapWindow(mouseX, mouseY)
  -- Don't snap if maximized or minimized
  if pm.selectedProcess.maximized or pm.selectedProcess.minimized then
    return false
  end

  local snapThreshold = 2 -- How close to the edge to trigger snapping
  local snapped = false

  -- Calculate half dimensions as integers to prevent shrinking
  local halfWidth = math.floor(termWidth / 2)
  local halfHeight = math.floor((termHeight - 2) / 2)

  -- Check for corner snaps using mouse position
  if mouseX <= snapThreshold and mouseY <= snapThreshold then
    -- Top-left corner
    pm.selectedProcess.x = 1
    pm.selectedProcess.y = 2
    pm.selectedProcess.width = halfWidth
    pm.selectedProcess.height = halfHeight
    snapped = true
  elseif mouseX >= termWidth - snapThreshold and mouseY <= snapThreshold then
    -- Top-right corner
    pm.selectedProcess.x = termWidth - halfWidth + 1
    pm.selectedProcess.y = 2
    pm.selectedProcess.width = halfWidth
    pm.selectedProcess.height = halfHeight
    snapped = true
  elseif mouseX <= snapThreshold and mouseY >= termHeight - snapThreshold then
    -- Bottom-left corner
    pm.selectedProcess.x = 1
    pm.selectedProcess.y = 2 + halfHeight
    pm.selectedProcess.width = halfWidth
    pm.selectedProcess.height = halfHeight
    snapped = true
  elseif mouseX >= termWidth - snapThreshold and mouseY >= termHeight - snapThreshold then
    -- Bottom-right corner
    pm.selectedProcess.x = termWidth - halfWidth + 1
    pm.selectedProcess.y = 2 + halfHeight
    pm.selectedProcess.width = halfWidth
    pm.selectedProcess.height = halfHeight
    snapped = true
    -- Edge snaps using mouse position
  elseif mouseX <= snapThreshold then
    -- Left edge
    pm.selectedProcess.x = 1
    pm.selectedProcess.y = 2
    pm.selectedProcess.width = halfWidth
    pm.selectedProcess.height = termHeight - 2
    snapped = true
  elseif mouseX >= termWidth - snapThreshold then
    -- Right edge
    pm.selectedProcess.x = termWidth - halfWidth + 1 -- Fixed right edge snapping
    pm.selectedProcess.y = 2
    pm.selectedProcess.width = halfWidth
    pm.selectedProcess.height = termHeight - 2
    snapped = true
  elseif mouseY >= termHeight - snapThreshold then
    -- Bottom edge
    pm.selectedProcess.x = 1
    pm.selectedProcess.y = 2 + halfHeight
    pm.selectedProcess.width = termWidth
    pm.selectedProcess.height = halfHeight
    snapped = true
  elseif mouseY <= snapThreshold then
    -- top edge will maximize
    pm.selectedProcess.x = 1
    pm.selectedProcess.y = 2
    pm.selectedProcess.width = termWidth
    pm.selectedProcess.height = termHeight - 2
    pm.selectedProcess.maximized = true
    pm.selectedProcess.minimized = false
    snapped = true
  end

  if snapped then
    term.redirect(pm.selectedProcess.window)
    coroutine.resume(pm.selectedProcess.coroutine, "term_resize")
  end

  return snapped
end

function pm.toggleMaximize()
  if pm.selectedProcess.minimized then
    pm.selectedProcess.minimized = false
  end

  pm.selectedProcess.maximized = not pm.selectedProcess.maximized
  term.redirect(pm.selectedProcess.window)
  coroutine.resume(pm.selectedProcess.coroutine, "term_resize")
  pm.drawProcesses()
end

function pm.eventLoop()
  while true do
    local e = { os.pullEventRaw() }
    if e[1] ~= "test" then
      if string.sub(e[1], 1, 6) == "mouse_" and not pm.selectedProcess.minimized then
        local m, x, y = e[2], e[3], e[4]

        -- Double click detection
        if e[1] == "mouse_up" then
          local currentTime = os.clock()

          if currentTime - pm.lastClickTime < pm.doubleClickThreshold and
              math.abs(x - pm.lastClickX) <= 1 and math.abs(y - pm.lastClickY) <= 1 then
            -- Handle double click on window title bar
            if pm.selectedProcess.showTitlebar and (
                  (not pm.selectedProcess.maximized and
                    x >= pm.selectedProcess.x and
                    x <= pm.selectedProcess.x + pm.selectedProcess.width - 4 and
                    y == pm.selectedProcess.y)
                  or
                  (pm.selectedProcess.maximized and y == 2 and x < termWidth - 3)
                ) then
              pm.toggleMaximize()
            end
          end

          pm.lastClickTime = currentTime
          pm.lastClickX = x
          pm.lastClickY = y
        end

        if pm.resizeStartX ~= nil and m == 2 then
          if e[1] == "mouse_up" then
            pm.resizeStartX = nil
            pm.resizeStartY = nil
            pm.resizeStartW = nil
            pm.resizeStartH = nil
            pm.drawProcesses()
          elseif e[1] == "mouse_drag" then
            pm.selectedProcess.width = (pm.resizeStartW + (x - pm.resizeStartX))
            pm.selectedProcess.height = (pm.resizeStartH + (y - pm.resizeStartY))
            term.redirect(pm.selectedProcess.window)
            coroutine.resume(pm.selectedProcess.coroutine, "term_resize")
            pm.drawProcesses()
          end
        elseif not pm.selectedProcess.minimized and not pm.selectedProcess.maximized and pm.selectedProcess.showTitlebar and
            x >= pm.selectedProcess.x and x <= pm.selectedProcess.x + pm.selectedProcess.width - 1 and y == pm.selectedProcess.y and
            e[1] == "mouse_click" and pm.mvmtX == nil then
          if not pm.selectedProcess.disableControls and x == pm.selectedProcess.x + pm.selectedProcess.width - 1 and
              e[1] == "mouse_click" then
            pm.endProcess(pm.selectedProcessID)
            pm.drawProcesses()
          elseif not pm.selectedProcess.disableControls and x == pm.selectedProcess.x + pm.selectedProcess.width - 3 and
              e[1] == "mouse_click" then
            pm.selectedProcess.minimized = true
            pm.drawProcesses()
          elseif not pm.selectedProcess.disableControls and x == pm.selectedProcess.x + pm.selectedProcess.width - 2 and
              e[1] == "mouse_click" then
            pm.selectedProcess.maximized = true
            term.redirect(pm.selectedProcess.window)
            coroutine.resume(pm.selectedProcess.coroutine, "term_resize")
            pm.drawProcesses()
          else
            pm.mvmtX = x - pm.selectedProcess.x
            pm.drawProcesses()
          end
        elseif pm.selectedProcess.maximized == true and y == 2 then
          if not pm.selectedProcess.disableControls and x == termWidth and e[1] == "mouse_click" then
            pm.endProcess(pm.selectedProcessID)
            pm.drawProcesses()
          elseif not pm.selectedProcess.disableControls and x == termWidth - 2 and e[1] == "mouse_click" then
            pm.selectedProcess.minimized = true
            pm.drawProcesses()
          elseif not pm.selectedProcess.disableControls and x == termWidth - 1 then
            pm.selectedProcess.maximized = false
            term.redirect(pm.selectedProcess.window)
            coroutine.resume(pm.selectedProcess.coroutine, "term_resize")
            pm.drawProcesses()
          else
            -- Handle dragging a maximized window by unmaximizing it first
            pm.selectedProcess.maximized = false
            -- Set window to a reasonable size
            pm.selectedProcess.width = math.floor(termWidth * 0.7)
            pm.selectedProcess.height = math.floor(termHeight * 0.7)
            -- Position the window under the cursor for dragging
            pm.selectedProcess.x = math.max(1,
              math.min(x - math.floor(pm.selectedProcess.width / 2), termWidth - pm.selectedProcess.width + 1))
            pm.selectedProcess.y = 2 -- Position right below the titlebar
            -- Start movement
            pm.mvmtX = math.floor(pm.selectedProcess.width / 2)
            term.redirect(pm.selectedProcess.window)
            coroutine.resume(pm.selectedProcess.coroutine, "term_resize")
            pm.drawProcesses()
          end
        elseif not pm.selectedProcess.maximized and pm.selectedProcess.showTitlebar and x >= pm.selectedProcess.x - 1 and
            x <= pm.selectedProcess.x + pm.selectedProcess.width - 3 and y >= pm.selectedProcess.y - 1 and y <= pm.selectedProcess.y + 1
            and e[1] == "mouse_drag" or e[1] == "mouse_up" and pm.mvmtX ~= nil then
          if e[1] == "mouse_drag" and pm.mvmtX then
            pm.selectedProcess.x = x - pm.mvmtX + 1
            pm.selectedProcess.y = y
            pm.drawProcesses()
          elseif e[1] == "mouse_up" and pm.mvmtX then
            if pm.snapWindow(x, y) then
              pm.drawProcesses()
            end
            pm.mvmtX = nil
          else
            pm.mvmtX = nil
          end
        elseif not pm.selectedProcess.disallowResizing and x == pm.selectedProcess.x + pm.selectedProcess.width - 1 and
            y == pm.selectedProcess.y + pm.selectedProcess.height and m == 2 then
          if e[1] == "mouse_click" then
            pm.resizeStartX = x
            pm.resizeStartY = y
            pm.resizeStartW = pm.selectedProcess.width
            pm.resizeStartH = pm.selectedProcess.height
          end
        elseif not pm.selectedProcess.maximized and x >= pm.selectedProcess.x and
            x <= pm.selectedProcess.x + pm.selectedProcess.width - 1 and y >= pm.selectedProcess.y and
            y <= pm.selectedProcess.y + pm.selectedProcess.height - 1 then
          term.redirect(pm.selectedProcess.window)
          local pass = {}
          if pm.selectedProcess.showTitlebar == true then
            pass = {
              e[1],
              m,
              x - pm.selectedProcess.x + 1,
              y - pm.selectedProcess.y
            }
          else
            pass = {
              e[1],
              m,
              x - pm.selectedProcess.x + 1,
              y - pm.selectedProcess.y + 1
            }
          end
          coroutine.resume(pm.selectedProcess.coroutine, table.unpack(pass))
        elseif pm.selectedProcess.maximized and y > 2 then
          term.redirect(pm.selectedProcess.window)
          local pass = {}
          if pm.selectedProcess.showTitlebar == true then
            pass = {
              e[1],
              m,
              x,
              y - 2
            }
          else
            pass = {
              e[1],
              m,
              x,
              y - 1
            }
          end
          coroutine.resume(pm.selectedProcess.coroutine, table.unpack(pass))
        elseif e[1] == "mouse_click" then
          for i, v in pairs(pm.processes) do
            if x >= v.x and x <= v.x + v.width - 1 and y >= v.y and y <= v.y + v.height - 1 then
              pm.selectProcess(i)
              local pass = {}
              if pm.selectedProcess.showTitlebar == true then
                pass = {
                  e[1],
                  m,
                  x - pm.selectedProcess.x + 1,
                  y - pm.selectedProcess.y
                }
              else
                pass = {
                  e[1],
                  m,
                  x - pm.selectedProcess.x + 1,
                  y - pm.selectedProcess.y + 1
                }
              end
              term.redirect(pm.selectedProcess.window)
              coroutine.resume(pm.selectedProcess.coroutine, table.unpack(pass))
              break
            end
          end
        end
      elseif e[1] == "char" or string.sub(e[1], 1, 3) == "key" or e[1] == "paste" then
        if e[1] == "key" then
          table.insert(pm.keysDown, e[2])
        elseif e[1] == "key_up" then
          if isKeyDown(e[2]) then
            table.remove(pm.keysDown, isKeyDown(e[2]))
          end
        end

        if isKeyDown(keys.leftCtrl) and isKeyDown(keys.leftShift) and isKeyDown(keys.delete) then
          pm.selectProcess(pm.createProcess("/sys/ui/tskmgr.lua", {
            width = 30,
            height = 15,
            title = "Task Manager"
          }))
          pm.drawProcesses()
        elseif isKeyDown(keys.leftCtrl) and isKeyDown(keys.leftShift) and isKeyDown(keys.t) then
          pm.selectProcess(pm.createProcess("/sys/shell.lua", {
            width = 40,
            height = 15,
            title = "Shell"
          }))
          pm.drawProcesses()
        end
        term.redirect(pm.selectedProcess.window)
        coroutine.resume(pm.selectedProcess.coroutine, table.unpack(e))
      elseif e[1] == "pm_fancyshutdown" then
        term.redirect(native)
        shell.run("/sys/ui/fancyshutdown.lua", e[2])
      elseif e[1] == "pm_login" then
        pm.titlebarID = pm.createProcess("/sys/ui/titlebar.lua", {
          x = 1,
          y = 1,
          width = termWidth,
          height = 1,
          showTitlebar = false,
          dontShowInTitlebar = true
        })
        pm.selectProcess(pm.titlebarID)

        pm.notifyID = pm.createProcess("/sys/ui/notifications_push.lua", {
          x = termWidth - 18,
          y = 3,
          width = 19,
          height = 5,
          showTitlebar = false,
          dontShowInTitlebar = true,
          disableControls = true
        })
        pm.selectProcess(pm.notifyID)
        files = fs.list("/home/startup")
        for i, v in pairs(files) do
          v = "/home/startup/" .. v
          if v:sub(-4) == ".lua" then
            local minimize = true
            if i == 1 then
              minimize = false
            end
            pm.createProcess(v, {
              maximized = true,
              minimized = minimize
            })
          end
        end
        notify.push("Welcome", "Welcome back!")
      elseif e[1] == "pm_paint" then
        pm.drawProcess(pm.selectedProcess)
      else
        if e[1] == "pm_themeupdate" then
          pm.theme = file.readTable("/etc/colors.cfg")
        end
        for i, v in pairs(pm.processes) do
          term.redirect(v.window)
          coroutine.resume(v.coroutine, table.unpack(e))
        end
        if e[1] ~= "rednet_message" and e[1] ~= "modem_message" and e[1] ~= "timer" then
          pm.drawProcesses()
        end
      end
    end
  end
end

return pm
