local tw, th = pm.getSize()
local w, h = term.getSize()

local recent = {}
local pinned = {}

local util = require("/lib/util")
local textbox = require("/lib/textbox")
local scroll = require("/lib/scrollwindow")
local draw = require("/lib/draw")

local file = util.loadModule("file")
local theme = _G.pm.getTheme()

local search = textbox.new(3, h - 1, w - 7, nil, "Search", nil, theme.userInput.background, theme.userInput.text)
local searchWindow = scroll.new(2, 2, w - 3, h - 4, {}, theme.menu.background, false)
local pinnedWindow = scroll.new(2, 2, w - 3, h - 4, {}, theme.menu.background, true)
local pm = _G.pm
local query
local searchResults = {}

local function setColors(text, background)
  term.setTextColor(text)
  term.setBackgroundColor(background)
end

local function searchSystem(query, depth)
  if not depth then depth = 10 end
  local found = {}

  local function searchDir(path, query, iteration, depth)
    for _, file in pairs(fs.list(path)) do
      if file:sub(1, 1) ~= "." then
        if fs.isDir(fs.combine(path, file)) and iteration < depth then
          searchDir(fs.combine(path, file), query, iteration + 1, depth)
        else
          if string.find(string.lower(file), string.lower(query)) then
            table.insert(found, fs.combine(path, file))
          end
        end
      end
    end
  end

  searchDir("/", query, 1, depth)
  return found
end

local function none() end

local function updateRecent()
  file.writeTable("/etc/menu/recent.cfg", recent)
end

local function loadRecent()
  recent = file.readTable("/etc/menu/recent.cfg")
end

local function updatePinned()
  file.writeTable("/etc/menu/pinned.cfg", pinned)
end

local function loadPinned()
  pinned = file.readTable("/etc/menu/pinned.cfg")
end

local function cleanRecent(path)
  for i, v in pairs(recent) do
    if path == v.path then
      table.remove(recent, i)
    end
  end
end

local function drawUI()
  term.setBackgroundColor(theme.menu.background)
  term.clear()
  local sw = w - 3
  if not query then
    searchWindow.setVisible(false)
    pinnedWindow.setVisible(true)
    pinnedWindow.setElements({})

    local pos = 1
    pinnedWindow.addElement(scroll.createElement(1, pos, string.rep("\140", sw), colors.gray, theme.menu.background
      , none))
    pos = pos + 1
    pinnedWindow.addElement(scroll.createElement(2, pos, "Pinned", colors.white, theme.menu.background, none))
    pos = pos + 1
    pinnedWindow.addElement(scroll.createElement(1, pos, string.rep("\140", sw), colors.gray, theme.menu.background
      , none))
    pos = pos + 1
    for i, v in pairs(pinned) do
      pinnedWindow.addElement(scroll.createElement(2, pos, draw.overflow(v.title, sw), colors.white,
        theme.menu.background, function()
        pm.endProcess(id)
        pm.selectProcess(pm.createProcess(v.path, v.insettings))
        cleanRecent(v.path)
        table.insert(recent, 1, {
          name = v.insettings.title or fs.getName(v.path),
          path = v.path,
          settings = {
            width = v.insettings.width,
            height = v.insettings.height,
            title = v.insettings.title,
          }
        })
        updateRecent()
      end))
      pos = pos + 1
    end

    pos = pos + 1
    pinnedWindow.addElement(scroll.createElement(1, pos, string.rep("\140", sw), colors.gray, theme.menu.background
      , none))
    pos = pos + 1
    pinnedWindow.addElement(scroll.createElement(2, pos, "Recent", colors.white, theme.menu.background, none))
    pos = pos + 1
    pinnedWindow.addElement(scroll.createElement(1, pos, string.rep("\140", sw), colors.gray, theme.menu.background
      , none))
    pos = pos + 1
    for i, v in pairs(recent) do
      pinnedWindow.addElement(scroll.createElement(2, pos, draw.overflow(v.name, sw), colors.white, theme.menu.background
        , function()
        pm.endProcess(id)
        pm.selectProcess(pm.createProcess(v.path, {}))
        cleanRecent(v.path)
        table.insert(recent, 1, {
          name = v.name,
          path = v.path,
          settings = v.settings
        })
        updateRecent()
      end))
      pos = pos + 1
    end
    if #recent == 0 then
      pinnedWindow.addElement(scroll.createElement(2, pos, draw.overflow("No recent apps", sw), colors.white,
        theme.menu.background, none))
    end
    pinnedWindow.redraw()
  else
    local pos = 1
    local elements = {}
    searchWindow.setVisible(true)
    pinnedWindow.setVisible(false)
    searchWindow.setElements({})
    if #searchResults == 0 then
      searchWindow.addElement(scroll.createElement(math.ceil(searchWindow.getWidth() / 2 - string.len("No results") / 2)
        , pos, "No results.", colors.gray, theme.menu.background, function() end))
    else
      searchWindow.addElement(scroll.createElement(1, pos, "Found " .. #searchResults .. " results", colors.white,
        theme.menu.background, none))
      pos = pos + 1
      searchWindow.addElement(scroll.createElement(1, pos, string.rep("\140", sw), colors.gray,
        theme.menu.background, none))
      pos = pos + 1

      for i, v in pairs(searchResults) do
        local function addFunction()
          pm.endProcess(id)
          -- if not lua file
          if v:sub(-4) ~= ".lua" then
            v = "/rom/programs/edit.lua " .. v
          end
          pm.selectProcess(pm.createProcess(v, {
            maximized = true
          }))
          cleanRecent(v)
          table.insert(recent, 1, {
            name = fs.getName(v),
            path = v,
            settings = {
              maximized = true
            }
          })
          updateRecent()
        end

        searchWindow.addElement(scroll.createElement(2, pos, draw.overflow(fs.getName(v), sw), colors.white,
          theme.menu.background, addFunction))
        pos = pos + 1
        local text = fs.getDir(v)
        if fs.getDir(v) == "" then
          text = "Root"
        end
        searchWindow.addElement(scroll.createElement(2, pos, draw.overflow(text, sw), colors.gray,
          theme.menu.background, addFunction))
        pos = pos + 1
        searchWindow.addElement(scroll.createElement(2, pos, "", colors.gray, theme.menu.background, function() end))
        pos = pos + 1
      end
      searchWindow.removeElement(#searchWindow.getElements())
    end
    searchWindow.redraw()
  end

  term.setBackgroundColor(colors.red)
  term.setTextColor(colors.white)
  term.setCursorPos(w - 2, h - 1)
  term.write("O")
  term.setCursorPos(w - 1, h - 2)
  term.setBackgroundColor(theme.menu.background)
  draw.drawBorder(w - 2, h - 1, 1, 1, colors.red)

  term.setCursorPos(w, h - 1)
  search.redraw()
  term.setCursorPos(w - 1, h - 2)
  term.setBackgroundColor(theme.menu.background)
  draw.drawBorder(3, h - 1, w - 7, 1, theme.userInput.background)
end

if not fs.exists("/etc/menu/recent.cfg") then
  updateRecent()
end

loadRecent()
loadPinned()
drawUI()

while true do
  local e = { os.pullEvent() }
  if e[1] == "mouse_click" then
    local m, x, y = e[2], e[3], e[4]
    if x == w - 2 and y == h - 1 then
      pm.endProcess(id)
      pm.selectProcess(pm.createProcess("/sys/ui/shutdown.lua", {
        height = 6,
        showTitlebar = false,
        dontShowInTitlebar = true,
        title = "Power"
      }))
    elseif x >= 2 and x <= w - 5 and y == h - 1 then
      query = search.select()
      if query == "" then query = nil end
      if query then
        searchResults = searchSystem(query)
        drawUI()
      end
    end
  elseif e[1] == "pm_themeupdate" then
    theme = file.readTable("/etc/colors.cfg")
  end
  local found = searchWindow.checkEvents(e)
  pinnedWindow.checkEvents(e)
end