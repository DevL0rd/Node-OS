local umath = {}

-- Constrains value between min and max.
function umath.clamp(n, min, max)
    if n < min then
        return min
    elseif n > max then
        return max
    else
        return n
    end
end
 
function umath.randomFloat(min, max)
    if max then
        return min + math.random() * (max - min)
    else
        -- When only one argument is provided, min means max.
        return math.random() * min
    end
end
 
-- Pythagorean theorem.
function umath.pythagoras(a, b)
    return math.sqrt(a^2 + b^2)
end

-- Rounds a number to a specified number of decimals.
-- If the number of decimals isn't provided, it'll round to 0 decimals.
-- Written with help from Brutal_McLegend.
function umath.round(input, decimals)
	decimals = decimals or 0
	if decimals < 0 then error("cf.round(n, d) doesn't take a negative decimal count") end
	local mult = math.pow(10, decimals)
    return math.floor(input * mult + 0.5) / mult
end

-- Get the squared magnitude of a vector.
function umath.vecMagSq(vector)
	return vector.x * vector.x + vector.y * vector.y
end

-- Get the distance between two vectors.
function umath.dist(a, b)
    local dx = b.pos.x - a.pos.x
    local dy = b.pos.y - a.pos.y
    return umath.pythagoras(dx, dy)
end

  -- Re-maps a number from one range to another.
function umath.map(value, minVar, maxVar, minResult, maxResult)
	local a = (value - minVar) / (maxVar - minVar)
	return (1 - a) * minResult + a * maxResult;
end

-- Calculates a number between two numbers at a specific increment.
function umath.lerp(start, end_, amt)
    local difference = end_ - start
    local extra = amt * difference
    return start + extra
  end

return umath