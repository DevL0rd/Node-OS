local function setColors(text, background)
    term.setTextColor(text)
    term.setBackgroundColor(background)
end

local function overflow(text, limit)
    if string.len(text) > limit then
        text = text:sub(1, limit - 4) .. "..."
        return text
    else
        return text
    end
end

local function drawBorder(x, y, w, h, borderColor)
    local background = term.getBackgroundColor()
    local function setBorderColors(inverted)
        if inverted then
            setColors(background, borderColor)
        else
            setColors(borderColor, background)
        end
    end
  
    -- CORNERS
  
    -- Top Left
    term.setCursorPos(x - 1, y - 1)
    setBorderColors(true)
    term.write("\159", w)
    -- Top Right
    term.setCursorPos(x + w, y - 1)
    setBorderColors(false)
    term.write("\144")
    -- Bottom Left
    term.setCursorPos(x - 1, y + 1)
    setBorderColors(false)
    term.write("\130")
    -- Top Right
    term.setCursorPos(x + w, y + 1)
    setBorderColors(false)
    term.write("\129")
    
    -- SIDES
  
    -- Top
    term.setCursorPos(x, y - 1)
    setBorderColors(true)
    term.write(string.rep("\143", w))
    -- Bottom
    term.setCursorPos(x, y + 1)
    setBorderColors(false)
    term.write(string.rep("\131", w))
    -- Left
    for i = 1, h do
      term.setCursorPos(x - 1, y + h - 1)
      setBorderColors(true)
      term.write("\149")
    end
    -- Right
    for i = 1, h do
      term.setCursorPos(x + w, y + h - 1)
      setBorderColors(false)
      term.write("\149")
    end
end

local function overflowWrite(text, limit)
    write(overflow(text, limit))
end
  
return {
    setColors = setColors,
    overflow = overflow,
    drawBorder = drawBorder,
    overflowWrite = overflowWrite
}