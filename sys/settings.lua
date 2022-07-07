settingsPath = "config/user.dat" 

--Load system settings
settings = {
    isSetup = false,
    name = "UnNamed-PC",
    message = "This PC has not been setup yet.",
    password = "",
    pairPin = "0000",
    NodeOSMasterID = 0
}
if fs.exists(settingsPath) then
    settings = load(settingsPath)
end

if not settings.isSetup then
    centerText("SETUP",1,"purple")
    nPrint("Please type a computer name.")
    term.setTextColor(colors["purple"])
    write("PC Name")
    term.setTextColor(colors["lightGray"])
    write(">>")
    local inp = read()
    settings.name = inp
    term.setCursorPos(1, 1)
    term.clear()

    centerText("SETUP",1,"purple")
    nPrint("Please set a password.")
    term.setTextColor(colors["purple"])
    write("Password")
    term.setTextColor(colors["lightGray"])
    write(">>")
    inp = read("*")
    settings.password = inp
    term.setCursorPos(1, 1)
    term.clear()

    centerText("SETUP",1,"purple")
    nPrint("Please set a pairing pin.")
    term.setTextColor(colors["purple"])
    write("PIN")
    term.setTextColor(colors["lightGray"])
    write(">>")
    local inp = read("*")
    if inp == "" then
        inp = "0000"
    end
    settings.pairPin = inp

    settings.isSetup = true
    save(settings, settingsPath)
    nPrint("Settings saved!", "green")
    sleep(2)
    os.reboot()
end