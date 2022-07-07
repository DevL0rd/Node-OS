return {
    init = function (side)
        monitor = peripherals[side].peripheral
        monitor.setTextScale(0.5)
        monW, monH = monitor.getSize()
        monitor.setCursorPos(1,1)
        monitor.clear()
    end,
    unInit = function (side) 
    end 
}