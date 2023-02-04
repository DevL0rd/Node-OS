local selectedID = 0
local procList

local pm = _G.pm
local theme = pm.getTheme()
local native = term.current()

local previewingThemeNumber = 1
local previewingTheme = "/sys/themes/" .. fs.list("/sys/themes")[previewingThemeNumber]

local function rebootToApplyChanges()
  pm.selectProcess(pm.createProcess(function()
    local function draw()
      local theme = pm.getTheme()
      term.setBackgroundColor(theme.main.background)
      term.setTextColor(theme.main.text)
      term.setCursorPos(2, 2)
      term.clear()
      term.write("Reboot now to apply changes?")

      term.setBackgroundColor(theme.userInput.background)
      term.setTextColor(theme.userInput.text)
      term.setCursorPos(2, 4)
      term.write(" OK ")
      term.setCursorPos(7, 4)
      term.write(" Cancel ")
    end

    while true do
      draw()
      local e = { os.pullEvent() }
      if e[1] == "mouse_click" then
        local m, x, y = e[2], e[3], e[4]
        if m == 1 then
          if x >= 2 and x <= 5 then
            os.queueEvent("pm_fancyshutdown", "reboot")
          elseif x >= 8 and x <= 14 then
            pm.endProcess(_G.pm.getSelectedProcessID())
          end
        end
      end
    end
  end, {
    title = "Reboot Now?",
    width = 30,
    height = 5
  }))
end

local function drawSubmenu(title, info, y, selected, arrow)
  local function run(selected)
    local w, h = term.getSize()
    term.setBackgroundColor(theme.main.background)
    if selected then
      term.setBackgroundColor(theme.window.titlebar.backgroundSelected)
    end
    term.setTextColor(theme.main.text)
    term.setCursorPos(2, y)
    term.clearLine()
    term.write(title)
    term.setTextColor(theme.main.textBold)
    term.setCursorPos(w - 1, y)
    if arrow ~= false then
      term.write("\26")
    end
    term.setTextColor(theme.main.textSecondary)
    term.setCursorPos(2, y + 1)
    term.clearLine()
    term.write(info)
  end

  if selected then
    run(true)
    sleep(0.1)
    run(false)
    sleep(0.05)
  else
    run(false)
  end
end

local function drawThemePreview(x, y, w, h, theme)
  local preview = window.create(native, x, y, w, h)
  term.redirect(preview)
  term.setBackgroundColor(theme.desktop.background)
  term.clear()
  term.setCursorPos(1, 1)
  term.setBackgroundColor(theme.titlebar.background)
  term.clearLine()
  term.setTextColor(theme.titlebar.text)
  term.setBackgroundColor(theme.menu.buttonBG)
  term.write(" M ")
  term.setBackgroundColor(theme.titlebar.background)
  term.write(" ")
  term.setTextColor(theme.menu.text)
  term.write("Program")

  local windowSizeX, windowSizeY = 20, 10
  if h - 2 < 10 then
    windowSizeY = h - 1
  end
  if w - 1 < 20 then
    windowSizeX = w - 1
  end
  paintutils.drawFilledBox(2, 3, windowSizeX, windowSizeY, theme.main.background)
  paintutils.drawLine(2, 3, windowSizeX, 3, theme.window.titlebar.backgroundSelected)
  term.setCursorPos(windowSizeX - 2, 3)
  term.setTextColor(theme.window.maximize)
  term.write("\7")
  term.setTextColor(theme.window.minimize)
  term.write("\7")
  term.setTextColor(theme.window.close)
  term.write("\7")
  term.setTextColor(theme.window.titlebar.text)
  term.setCursorPos((windowSizeX / 2 - string.len("Program") / 2) + 2, 3)
  term.write("Program")

  term.setCursorPos(3, 4)
  if windowSizeY >= 9 then
    term.setCursorPos(3, 5)
  end
  term.setBackgroundColor(theme.main.background)
  term.setTextColor(theme.main.textBold)
  term.write("Bold text")

  term.setCursorPos(3, 5)
  if windowSizeY >= 9 then
    term.setCursorPos(3, 6)
  end
  term.setTextColor(theme.main.text)
  term.write("Normal text")

  term.setCursorPos(3, 6)
  if windowSizeY >= 9 then
    term.setCursorPos(3, 7)
  end
  term.setTextColor(theme.main.textSecondary)
  term.write("muted text (shh)")

  term.setCursorPos(3, 7)
  if windowSizeY >= 10 then
    term.setCursorPos(3, 9)
  elseif windowSizeY >= 9 then
    term.setCursorPos(3, 8)
  end
  term.setBackgroundColor(theme.userInput.background)
  term.setTextColor(theme.userInput.text)
  term.write(" Button ")

  term.redirect(native)
end

local page = "main"
local previousPage = "main"

local previousPages = {
  main = "main",
  personalization = "main",
  ["personalization/theme"] = "personalization",
  ccemux = "main"
}

local function draw()
  local w, h = term.getSize()
  term.setBackgroundColor(theme.main.background)
  term.clear()
  if page == "main" then
    term.setCursorPos(2, 2)
    term.setTextColor(theme.main.textBold)
    term.write("Settings")
    drawSubmenu("Personalization", "Change the look of NodeOS", 4)
    if ccemux then
      drawSubmenu("CCEmuX", "Access configuration, data, etc.", 7)
    end
  elseif page == "personalization" then
    term.setCursorPos(2, 2)
    term.setTextColor(theme.main.textBold)
    term.setBackgroundColor(theme.window.titlebar.background)
    term.write(" \27 ")
    term.setBackgroundColor(theme.main.background)
    term.write(" Personalization")

    drawSubmenu("Theme", "Change NodeOS's look system-wide", 4)
  elseif page == "personalization/theme" then
    term.setCursorPos(2, 2)
    term.setTextColor(theme.main.textBold)
    term.setBackgroundColor(theme.window.titlebar.background)
    term.write(" \27 ")
    term.setBackgroundColor(theme.main.background)
    term.write(" Theme")

    local currentTheme = file.readTable("/etc/theme.cfg").currentTheme

    term.setTextColor(theme.main.text)
    term.setCursorPos(2, h - 2)
    term.write("\17")
    term.setCursorPos(w - 1, h - 2)
    term.write("\16")
    local name = fs.getName(previewingTheme):sub(1, -7)
    local newName = name:sub(1, 1):upper() .. name:sub(2, string.len(name))
    local text = newName
    term.setCursorPos(w / 2 - string.len(text) / 2, h - 2)
    term.write(text)

    if previewingTheme == currentTheme then
      local text = "Selected theme"
      term.setTextColor(theme.main.textSecondary)
      term.setCursorPos(w / 2 - string.len(text) / 2, h - 1)
      term.write(text)
    else
      local text = " Select "
      term.setBackgroundColor(theme.userInput.background)
      term.setTextColor(theme.userInput.text)
      term.setCursorPos(w / 2 - string.len(text) / 2, h - 1)
      term.write(text)
    end
    drawThemePreview(2, 4, w - 2, h - 7, file.readTable(previewingTheme))
  elseif page == "ccemux" then
    term.setCursorPos(2, 2)
    term.setTextColor(theme.main.textBold)
    term.setBackgroundColor(theme.window.titlebar.background)
    term.write(" \27 ")
    term.setBackgroundColor(theme.main.background)
    term.write(" CCEmuX")

    drawSubmenu("Configuration", "Open CCEmuX Configuration", 4, nil, false)
    drawSubmenu("Data Directory", "Open this computer's data directory", 7, nil, false)
  end
end

while true do
  draw()
  local e = { os.pullEvent() }

  local w, h = term.getSize()
  if e[1] == "mouse_click" then
    local m, x, y = e[2], e[3], e[4]
    if m == 1 then
      if y >= 4 and y <= 5 and page == "main" then
        drawSubmenu("Personalization", "Change the look of NodeOS", 4, true)
        page = "personalization"
      elseif y >= 7 and y <= 8 and page == "main" then
        drawSubmenu("CCEmuX", "Access configuration, data, etc.", 7, true)
        page = "ccemux"
      elseif y >= 4 and y <= 5 and page == "personalization" then
        drawSubmenu("Theme", "Change NodeOS's look system-wide", 4, true)
        page = "personalization/theme"
      elseif y >= 4 and y <= 5 and page == "ccemux" and ccemux then
        drawSubmenu("Configuration", "Open CCEmuX Configuration", 4, true)
        ccemux.openConfig()
      elseif y >= 7 and y <= 8 and page == "ccemux" and ccemux then
        drawSubmenu("Data Directory", "Open this computer's data directory", 7, true)
        ccemux.openDataDir()
      elseif x == 2 and y == h - 2 and page == "personalization/theme" then
        if previewingThemeNumber == 1 then
          previewingThemeNumber = #fs.list("/sys/themes")
        else
          previewingThemeNumber = previewingThemeNumber - 1
        end
        previewingTheme = "/sys/themes/" .. fs.list("/sys/themes")[previewingThemeNumber]
      elseif x == w - 1 and y == h - 2 and page == "personalization/theme" then
        if previewingThemeNumber == #fs.list("/sys/themes") then
          previewingThemeNumber = 1
        else
          previewingThemeNumber = previewingThemeNumber + 1
        end
        previewingTheme = "/sys/themes/" .. fs.list("/sys/themes")[previewingThemeNumber]
      elseif y == h - 1 and page == "personalization/theme" then
        file.writeTable("/etc/theme.cfg", { currentTheme = previewingTheme })
        rebootToApplyChanges()
      elseif y == 2 and x >= 2 and x <= 5 and page ~= "main" then
        term.setTextColor(theme.main.textBold)
        term.setBackgroundColor(theme.window.titlebar.backgroundSelected)
        term.setCursorPos(2, 2)
        term.write(" \27 ")
        sleep(0.1)
        term.setBackgroundColor(theme.window.titlebar.background)
        term.setCursorPos(2, 2)
        term.write(" \27 ")
        sleep(0.05)

        page = previousPages[page]
      end
    end
  end
end