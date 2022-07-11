local general = {}

function general.resetColorScheme()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
end

function general.resetCursorPos()
    term.setCursorPos(1,1)
end

function general.reset()
    util.resetColorScheme()
    term.clear()
    util.resetCursorPos()
    return true
end

function general.tableContains(tbl, elem)
    for i, e in pairs(tbl) do
        if elem == e then
            return true
        end
    end
    return false
end

-- Prints the contents of a table much like 'textutils.serialize(tab)',
-- but the output is much more readable and it has the option to toggle recursion.
function general.printTable(tab, recursive, depth)
	recursive = not (recursive == false) -- True by default.
	depth = depth or 0 -- The depth starts at 0.
	
	-- Getting the longest key, so all printed values will line up.
	local longestKey = 1
	for key, _ in pairs(tab) do
		local keyLength = #tostring(key)
		if keyLength > longestKey then
			longestKey = keyLength
		end
	end
	
	if depth == 0 then
		print()
	end
	
	-- Print the keys and values, with extra spaces so the values line up.
	for key, value in pairs(tab) do
		yield() -- Need to yield, as the next bit of code can be recursive.
		
		local spacingCount = longestKey - #tostring(key) -- How many spaces are added between the key and value.
		print(
			string.rep('    ', depth).. -- Shift tables that are deep inside the original table.
			tostring(key)..
			string.rep(' ', spacingCount)..
			', '..
			tostring(type(value) == 'table' and 'table' or value)
		)
		
		local isTable = type(value) == 'table'
		local valueIsTable = (tab == value)
		if recursive and isTable and not valueIsTable then
			printTable(value, recursive, depth + 1) -- Go into the table.
		end
	end
	
	if depth == 0 then
		print()
	end
end

-- Reverses the order of the elements in a table.
function general.reverseTable(tab)
	reversedTable = {}
	for i = #tab, 1, -1 do
		reversedTable[#reversedTable + 1] = tab[i]
	end
	return reversedTable
end

-- Removes an element from a table.
function general.tableRemove(t, e)
	for i = 1, #t do
		if t[i] == e then
			table.remove(t, i)
			break -- Breaking is necessary, because the loop's #t max iterations has changed, because t changed.
		end
	end
	return t
end

-- Prevents the program from crashing after 5 seconds.
-- Executes faster than 'sleep(0.05)'.
function general.yield()
	os.queueEvent("randomEvent")
	os.pullEvent("randomEvent")
end

-- Yields when more than t seconds have passed since the last yield. t is 4 by default.
function general.tryYield(t)
    t = t or 4
    local currentClock = os.clock()
    if currentClock - previousClock > t then
        previousClock = currentClock
        yield()
    end
end

return general