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

function pm.unminimizeProcess(pid)
  pm.processes[pid].minimized = false
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
        pm.selectProcess(pm.titlebarID)
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
    local process = pm.processes[pid]
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
        local textbox = textbox

        path(textbox)
        pm.endProcess(_G.id)
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
function pm.eventLoop()
  while true do
    local e = { os.pullEventRaw() }
    if e[1] ~= "test" then
      -- print(e[1])
      if string.sub(e[1], 1, 6) == "mouse_" and not pm.selectedProcess.minimized then
        local m, x, y = e[2], e[3], e[4]
        -- Resize checking
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
          -- Moving windows & x and max / min buttons
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
          -- Max window controls
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
          end
          -- Window movement
        elseif not pm.selectedProcess.maximized and pm.selectedProcess.showTitlebar and x >= pm.selectedProcess.x - 1 and
            x <= pm.selectedProcess.x + pm.selectedProcess.width and y >= pm.selectedProcess.y - 1 and y <= pm.selectedProcess.y + 1
            and e[1] == "mouse_drag" or e[1] == "mouse_up" and pm.mvmtX ~= nil then
          if e[1] == "mouse_drag" and pm.mvmtX then
            pm.selectedProcess.x = x - pm.mvmtX + 1
            pm.selectedProcess.y = y
            pm.drawProcesses()
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
          -- Passing events (not maximized)
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
          -- Passing events (maximized)
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
        files = fs.list("/home/startup")
        for i, v in pairs(files) do
          v = "/home/startup/" .. v
          if v:sub(-4) == ".lua" then
            pm.createProcess(v, {
              x = i + 2,
              y = i + 2,
              width = 15,
              height = 6
            })
          end
        end
      elseif e[1] == "pm_titlebardeath" then
        pm.titlebarID = pm.createProcess("/sys/ui/titlebar.lua", {
          x = 1,
          y = 1,
          width = termWidth,
          height = 1,
          showTitlebar = false,
          dontShowInTitlebar = true
        })
      elseif e[1] == "pm_paint" then
        pm.drawProcess(pm.selectedProcess) --just repaint the main focused window, is ok if other windows update over each other for performance.
      else
        if e[1] == "pm_themeupdate" then
          pm.theme = file.readTable("/etc/colors.cfg")
        end
        for i, v in pairs(pm.processes) do
          term.redirect(v.window)
          coroutine.resume(v.coroutine, table.unpack(e))
        end
        if e[1] ~= "rednet_message" and e[1] ~= "modem_message" and e[1] ~= "timer" then
          --  and e[1] ~= "timer"
          -- print(e[1])
          pm.drawProcesses()
        end
      end
    end
  end
end
return pm