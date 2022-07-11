local nfte = {}

local tchar = string.char(31)	-- for text colors
local bchar = string.char(30)	-- for background colors
local nchar = string.char(29)	-- for differentiating multiple frames in ANFT

local round = function(num)
	return math.floor(num + 0.5)
end

local deepCopy
deepCopy = function(tbl)
	local output = {}
	for k,v in pairs(tbl) do
		if type(v) == "table" then
			output[k] = deepCopy(v)
		else
			output[k] = v
		end
	end
	return output
end

local function stringWrite(str,pos,ins,exc)
	str, ins = tostring(str), tostring(ins)
	local output, fn1, fn2 = str:sub(1,pos-1)..ins..str:sub(pos+#ins)
	if exc then
		repeat
			fn1, fn2 = str:find(exc,fn2 and fn2+1 or 1)
			if fn1 then
				output = stringWrite(output,fn1,str:sub(fn1,fn2))
			end
		until not fn1
	end
	return output
end

local checkValid = function(image)
	if type(image) == "table" then
		if #image == 3 then
			return (#image[1] == #image[2] and #image[2] == #image[3])
		end
	end
	return false
end

local checkIfANFT = function(image)
	if type(image) == "table" then
		return type(image[1][1]) == "table"
	elseif type(image) == "string" then
		return image:find(nchar) and true or false
	end
end

local bl = {	-- blit
	[' '] = 0,
	['0'] = 1,
	['1'] = 2,
	['2'] = 4,
	['3'] = 8,
	['4'] = 16,
	['5'] = 32,
	['6'] = 64,
	['7'] = 128,
	['8'] = 256,
	['9'] = 512,
	['a'] = 1024,
	['b'] = 2048,
	['c'] = 4096,
	['d'] = 8192,
	['e'] = 16384,
	['f'] = 32768,
}
local lb = {} 	-- tilb
for k,v in pairs(bl) do
	lb[v] = k
end

local ldchart = {	-- converts colors into a lighter shade
	["0"] = "0",
	["1"] = "4",
	["2"] = "6",
	["3"] = "0",
	["4"] = "0",
	["5"] = "0",
	["6"] = "0",
	["7"] = "8",
	["8"] = "0",
	["9"] = "3",
	["a"] = "2",
	["b"] = "9",
	["c"] = "1",
	["d"] = "5",
	["e"] = "2",
	["f"] = "7"
}

local dlchart = {	-- converts colors into a darker shade
	["0"] = "8",
	["1"] = "c",
	["2"] = "a",
	["3"] = "9",
	["4"] = "1",
	["5"] = "d",
	["6"] = "2",
	["7"] = "f",
	["8"] = "7",
	["9"] = "b",
	["a"] = "7",
	["b"] = "7",
	["c"] = "7",
	["d"] = "7",
	["e"] = "7",
	["f"] = "f"
}

local getSizeNFP = function(image)
	local xsize = 0
	if type(image) ~= "table" then return 0,0 end
	for y = 1, #image do xsize = math.max(xsize, #image[y]) end
	return xsize, #image
end

-- returns (x, y) size of a loaded NFT image
getSize = function(image)
	assert(checkValid(image), "Invalid image.")
	local x, y = 0, #image[1]
	for y = 1, #image[1] do
		x = math.max(x, #image[1][y])
	end
	return x, y
end
nfte.getSize = getSize

-- cuts off the sides of an image
crop = function(image, x1, y1, x2, y2)
	assert(checkValid(image), "Invalid image.")
	local output = {{},{},{}}
	for y = y1, y2 do
		output[1][#output[1]+1] = image[1][y]:sub(x1,x2)
		output[2][#output[2]+1] = image[2][y]:sub(x1,x2)
		output[3][#output[3]+1] = image[3][y]:sub(x1,x2)
	end
	return output
end
nfte.crop = crop

local loadImageDataNFT = function(image, background) -- string image
	local output = {{},{},{}} -- char, text, back
	local y = 1
	background = (background or " "):sub(1,1)
	local text, back = " ", background
	local doSkip, c1, c2 = false
	local maxX = 0
	local bx
	for i = 1, #image do
		if doSkip then
			doSkip = false
		else
			output[1][y] = output[1][y] or ""
			output[2][y] = output[2][y] or ""
			output[3][y] = output[3][y] or ""
			c1, c2 = image:sub(i,i), image:sub(i+1,i+1)
			if c1 == tchar then
				text = c2
				doSkip = true
			elseif c1 == bchar then
				back = c2
				doSkip = true
			elseif c1 == "\n" then
				maxX = math.max(maxX, #output[1][y])
				y = y + 1
				text, back = " ", background
			else
				output[1][y] = output[1][y]..c1
				output[2][y] = output[2][y]..text
				output[3][y] = output[3][y]..back
			end
		end
	end
	for y = 1, #output[1] do
		output[1][y] = output[1][y] .. (" "):rep(maxX - #output[1][y])
		output[2][y] = output[2][y] .. (" "):rep(maxX - #output[2][y])
		output[3][y] = output[3][y] .. (background):rep(maxX - #output[3][y])
	end
	return output
end

local loadImageDataNFP = function(image, background)
	local output = {}
	local x, y = 1, 1
	for i = 1, #image do
		output[y] = output[y] or {}
		if bl[image:sub(i,i)] then
			output[y][x] = bl[image:sub(i,i)]
			x = x + 1
		elseif image:sub(i,i) == "\n" then
			x, y = 1, y + 1
		end
	end
	return output
end

-- takes a loaded image and returns a loaded NFT image
convertFromNFP = function(image, background)
	background = background or " "
	local output = {{},{},{}}
	if type(image) == "string" then
		image = loadImageDataNFP(image)
	end
	local imageX, imageY = getSizeNFP(image)
	local bx
	for y = 1, imageY do
		output[1][y] = ""
		output[2][y] = ""
		output[3][y] = ""
		for x = 1, imageX do
			if image[y][x] then
				bx = (x % #background) + 1
				output[1][y] = output[1][y]..lb[image[y][x] or background:sub(bx,bx)]
				output[2][y] = output[2][y]..lb[image[y][x] or background:sub(bx,bx)]
				output[3][y] = output[3][y]..lb[image[y][x] or background:sub(bx,bx)]
			end
		end
	end
	return output
end
nfte.convertFromNFP = convertFromNFP

-- loads the raw string NFT image data
loadImageData = function(image, background)
	assert(type(image) == "string", "NFT image data must be string.")
	local output = {}
	-- images can be ANFT, which means they have multiple layers
	if checkIfANFT(image) then
		local L, R = 1, 1
		while L do
			R = (image:find(nchar, L + 1) or 0)
			output[#output+1] = loadImageDataNFT(image:sub(L, R - 1), background)
			L = image:find(nchar, R + 1)
			if L then L = L + 2 end
		end
		return output, "anft"
	elseif image:find(tchar) or image:find(bchar) then
		return loadImageDataNFT(image, background), "nft"
	else
		return convertFromNFP(image), "nfp"
	end
end
nfte.loadImageData = loadImageData

-- loads an image file. will convert from NFP if necessary
loadImage = function(path, background)
	local file = io.open(path, "r")
	if file then
		io.input(file)
		local output, format = loadImageData(io.read("*all"), background)
		io.close()
		return output, format
	else
		error("No such file exists, or is directory.")
	end
end
nfte.loadImage = loadImage

local unloadImageNFT = function(image)
	assert(checkValid(image), "Invalid image.")
	local output = ""
	local text, back = " ", " "
	local c, t, b
	for y = 1, #image[1] do
		for x = 1, #image[1][y] do
			c, t, b = image[1][y]:sub(x,x), image[2][y]:sub(x,x), image[3][y]:sub(x,x)
			if (t ~= text) or (x == 1) then
				output = output..tchar..t
				text = t
			end
			if (b ~= back) or (x == 1) then
				output = output..bchar..b
				back = b
			end
			output = output..c
		end
		if y ~= #image[1] then
			output = output.."\n"
			text, back = " ", " "
		end
	end
	return output
end

-- takes a loaded NFT image and converts it back into regular NFT (or ANFT)
unloadImage = function(image)
	assert(checkValid(image), "Invalid image.")
	local output = ""
	if checkIfANFT(image) then
		for i = 1, #image do
			output = output .. unloadImageNFT(image[i])
			if i ~= #image then
				output = output .. nchar .. "\n"
			end
		end
	else
		output = unloadImageNFT(image)
	end
	return output
end
nfte.unloadImage = unloadImage

-- draws an image with the topleft corner at (x, y)
drawImage = function(image, x, y, terminal)
	assert(checkValid(image), "Invalid image.")
	assert(type(x) == "number", "x value must be number, got " .. type(x))
	assert(type(y) == "number", "y value must be number, got " .. type(y))
	terminal = terminal or term.current()
	local cx, cy = terminal.getCursorPos()
	for iy = 1, #image[1] do
		terminal.setCursorPos(x, y + (iy - 1))
		terminal.blit(image[1][iy], image[2][iy], image[3][iy])
	end
	terminal.setCursorPos(cx,cy)
end
nfte.drawImage = drawImage

-- draws an image with the topleft corner at (x, y), with transparency
drawImageTransparent = function(image, x, y, terminal)
	assert(checkValid(image), "Invalid image.")
	assert(type(x) == "number", "x value must be number, got " .. type(x))
	assert(type(y) == "number", "y value must be number, got " .. type(y))
	terminal = terminal or term.current()
	local cx, cy = terminal.getCursorPos()
	local c, t, b
	for iy = 1, #image[1] do
		for ix = 1, #image[1][iy] do
			c, t, b = image[1][iy]:sub(ix,ix), image[2][iy]:sub(ix,ix), image[3][iy]:sub(ix,ix)
			if b ~= " " or c ~= " " then
				terminal.setCursorPos(x + (ix - 1), y + (iy - 1))
				terminal.blit(c, t, b)
			end
		end
	end
	terminal.setCursorPos(cx,cy)
end
nfte.drawImageTransparent = drawImageTransparent

-- draws an image centered at (x, y) or center screen
drawImageCenter = function(image, x, y, terminal)
	terminal = terminal or term.current()
	local scr_x, scr_y = terminal.getSize()
	local imageX, imageY = getSize(image)
	return drawImage(
		image,
		round(0.5 + (x and x or (scr_x/2)) - imageX/2),
		round(0.5 + (y and y or (scr_y/2)) - imageY/2),
		terminal
	)
end
drawImageCentre = drawImageCenter
nfte.drawImageCenter = drawImageCenter
nfte.drawImageCentre = drawImageCenter

-- draws an image centered at (x, y) or center screen, with transparency
drawImageCenterTransparent = function(image, x, y, terminal)
	terminal = terminal or term.current()
	local scr_x, scr_y = terminal.getSize()
	local imageX, imageY = getSize(image)
	return drawImageTransparent(
		image,
		round(0.5 + (x and x or (scr_x/2)) - imageX/2),
		round(0.5 + (y and y or (scr_y/2)) - imageY/2),
		terminal
	)
end
drawImageCentreTransparent = drawImageCenterTransparent
nfte.drawImageCenterTransparent = drawImageCenterTransparent
nfte.drawImageCentreTransparent = drawImageCenterTransparent

-- swaps every color in an image with a different one according to a table
colorSwap = function(image, text, back)
	assert(checkValid(image), "Invalid image.")
	local output = {{},{},{}}
	for y = 1, #image[1] do
		output[1][y] = image[1][y]
		output[2][y] = image[2][y]:gsub(".", text)
		output[3][y] = image[3][y]:gsub(".", back or text)
	end
	return output
end
colourSwap = colorSwap
nfte.colorSwap = colorSwap
nfte.colourSwap = colorSwap

-- every flippable block character that doesn't need a color swap
local xflippable = {
	["\129"] = "\130",
	["\132"] = "\136",
	["\133"] = "\138",
	["\134"] = "\137",
	["\137"] = "\134",
	["\135"] = "\139",
	["\140"] = "\140",
	["\141"] = "\142",
}
-- every flippable block character that needs a color swap
local xinvertable = {
	["\144"] = "\159",
	["\145"] = "\157",
	["\146"] = "\158",
	["\147"] = "\156",
	["\148"] = "\151",
	["\152"] = "\155",
	["\149"] = "\149",
	["\150"] = "\150",
	["\153"] = "\153",
	["\154"] = "\154"
}
for k,v in pairs(xflippable) do
	xflippable[v] = k
end
for k,v in pairs(xinvertable) do
	xinvertable[v] = k
end
-- flips an image horizontally, flipping all necessary block characters
flipX = function(image)
	assert(checkValid(image), "Invalid image.")
	local output = {{},{},{}}
	for y = 1, #image[1] do
		output[1][y] = image[1][y]:gsub(".", xinvertable):gsub(".", xflippable):reverse()
		output[2][y] = ""
		output[3][y] = ""
		for x = 1, #image[1][y] do
			if xinvertable[image[1][y]:sub(x,x)] then
				output[2][y] = image[3][y]:sub(x,x) .. output[2][y]
				output[3][y] = image[2][y]:sub(x,x) .. output[3][y]
			else
				output[2][y] = image[2][y]:sub(x,x) .. output[2][y]
				output[3][y] = image[3][y]:sub(x,x) .. output[3][y]
			end
		end
	end
	return output
end
nfte.flipX = flipX

-- flips an image vertically. doesn't touch block characters
flipY = function(image)
	assert(checkValid(image), "Invalid image.")
	local output = {{},{},{}}
	for y = #image[1], 1, -1 do
		output[1][#output[1]+1] = image[1][y]
		output[2][#output[2]+1] = image[2][y]
		output[3][#output[3]+1] = image[3][y]
	end
	return output
end
nfte.flipY = flipY

-- makes a rectangular image of (width, height) and char/text/back.
makeRectangle = function(width, height, char, text, back)
	assert(type(width) == "number", "width must be number")
	assert(type(height) == "number", "height must be number")
	local output = {{},{},{}}
	for y = 1, height do
		output[1][y] = (char or " "):rep(width)
		output[2][y] = (text or " "):rep(width)
		output[3][y] = (back or " "):rep(width)
	end
	return output
end
nfte.makeRectangle = makeRectangle

-- converts an image into grayscale as best I could
grayOut = function(image)
	assert(checkValid(image), "Invalid image.")
	local output = {{},{},{}}
	local chart = {
		["0"] = "0",
		["1"] = "8",
		["2"] = "8",
		["3"] = "8",
		["4"] = "8",
		["5"] = "8",
		["6"] = "8",
		["7"] = "7",
		["8"] = "8",
		["9"] = "7",
		["a"] = "7",
		["b"] = "7",
		["c"] = "7",
		["d"] = "7",
		["e"] = "7",
		["f"] = "f"
	}
	for y = 1, #image[1] do
		output[1][y] = image[1][y]
		output[2][y] = image[2][y]:gsub(".", chart)
		output[3][y] = image[3][y]:gsub(".", chart)
	end
	return output
end
greyOut = grayOut
nfte.grayOut = grayOut
nfte.greyOut = grayOut

-- takes an image and lightens it by a certain amount
lighten = function(image, amount)
	assert(checkValid(image), "Invalid image.")
	if (amount or 1) < 0 then
		return darken(image, -amount)
	else
		local output = deepCopy(image)
		for i = 1, amount or 1 do
			for y = 1, #output[1] do
				output[1][y] = output[1][y]
				output[2][y] = output[2][y]:gsub(".",ldchart)
				output[3][y] = output[3][y]:gsub(".",ldchart)
			end
		end
		return output
	end
end
nfte.lighten = lighten

-- takes an image and darkens it by a certain amount
darken = function(image, amount)
	assert(checkValid(image), "Invalid image.")
	if (amount or 1) < 0 then
		return lighten(image, -amount)
	else
		local output = deepCopy(image)
		for i = 1, amount or 1 do
			for y = 1, #output[1] do
				output[1][y] = output[1][y]
				output[2][y] = output[2][y]:gsub(".",dlchart)
				output[3][y] = output[3][y]:gsub(".",dlchart)
			end
		end
		return output
	end
end
nfte.darken = darken

-- stretches an image so that its new height and width are (sx, sy).
-- if noRepeat, it will only draw one of each character for each pixel
--  in the original image, so as to not mess up text in images.
stretchImage = function(_image, sx, sy, noRepeat)
	assert(checkValid(_image), "Invalid image.")
	local output = {{},{},{}}
	local image = deepCopy(_image)
	if sx < 0 then image = flipX(image) end
	if sy < 0 then image = flipY(image) end
	sx, sy = math.abs(sx), math.abs(sy)
	local imageX, imageY = getSize(image)
	local tx, ty
	if sx == 0 or sy == 0 then
		for y = 1, math.max(sy, 1) do
			output[1][y] = ""
			output[2][y] = ""
			output[3][y] = ""
		end
		return output
	else
		for y = 1, sy do
			for x = 1, sx do
				tx = round((x / sx) * imageX)
				ty = math.ceil((y / sy) * imageY)
				if not noRepeat then
					output[1][y] = (output[1][y] or "")..image[1][ty]:sub(tx,tx)
				else
					output[1][y] = (output[1][y] or "").." "
				end
				output[2][y] = (output[2][y] or "")..image[2][ty]:sub(tx,tx)
				output[3][y] = (output[3][y] or "")..image[3][ty]:sub(tx,tx)
			end
		end
		if noRepeat then
			for y = 1, imageY do
				for x = 1, imageX do
					if image[1][y]:sub(x,x) ~= " " then
						tx = round(((x / imageX) * sx) - ((0.5 / imageX) * sx))
						ty = round(((y / imageY) * sy) - ((0.5 / imageY) * sx))
						output[1][ty] = stringWrite(output[1][ty], tx, image[1][y]:sub(x,x))
					end
				end
			end
		end
		return output
	end
end
nfte.stretchImage = stretchImage

-- same as stretchImage, but will not alter its aspect ratio
stretchImageKeepAspect = function(image, sx, sy, noRepeat)
	assert(checkValid(image), "Invalid image.")
	local imX, imY = nfte.getSize(image)
	local aspect = sx / sy
	local imAspect = imX / imY
	if imAspect > aspect then
		return nfte.stretchImage(image, sx, sx / imAspect, noRepeat)
	elseif imAspect < aspect then
		return nfte.stretchImage(image, sy * imAspect, sy, noRepeat)
	else
		return nfte.stretchImage(image, sx, sy, noRepeat)
	end
end
nfte.stretchImageKeepAspect = stretchImageKeepAspect

-- will stretch and unstretch an image to radically lower its resolution
pixelateImage = function(image, amntX, amntY)
	assert(checkValid(image), "Invalid image.")
	local imageX, imageY = getSize(image)
	return stretchImage(stretchImage(image,imageX/math.max(amntX,1), imageY/math.max(amntY,1)), imageX, imageY)
end
nfte.pixelateImage = pixelateImage

-- merges two or more images together at arbitrary positions
-- earlier arguments will be layered on top of later ones
merge = function(...)
	local images = {...}
	local output = {{},{},{}}
	local imageX, imageY = 0, 0
	local imSX, imSY
	for i = 1, #images do
		imageY = math.max(
			imageY,
			#images[i][1][1] + (images[i][3] == true and 0 or (images[i][3] - 1))
		)
		for y = 1, #images[i][1][1] do
			imageX = math.max(
				imageX,
				#images[i][1][1][y] + (images[i][2] == true and 0 or (images[i][2] - 1))
			)
		end
	end
	-- if either coordinate is true, center it
	for i = 1, #images do
		imSX, imSY = getSize(images[i][1])
		if images[i][2] == true then
			images[i][2] = round(1 + (imageX / 2) - (imSX / 2))
		end
		if images[i][3] == true then
			images[i][3] = round(1 + (imageY / 2) - (imSY / 2))
		end
	end

	-- will later add code to adjust X/Y positions if negative values are given

	local image, xadj, yadj
	local tx, ty
	for y = 1, imageY do
		output[1][y] = {}
		output[2][y] = {}
		output[3][y] = {}
		for x = 1, imageX do
			for i = #images, 1, -1 do
				image, xadj, yadj = images[i][1], images[i][2], images[i][3]
				tx, ty = x-(xadj-1), y-(yadj-1)
				output[1][y][x] = output[1][y][x] or " "
				output[2][y][x] = output[2][y][x] or " "
				output[3][y][x] = output[3][y][x] or " "
				if image[1][ty] then
					if (image[1][ty]:sub(tx,tx) ~= "") and (tx >= 1) then
						output[1][y][x] = (image[1][ty]:sub(tx,tx) == " " and output[1][y][x] or image[1][ty]:sub(tx,tx))
						output[2][y][x] = (image[2][ty]:sub(tx,tx) == " " and output[2][y][x] or image[2][ty]:sub(tx,tx))
						output[3][y][x] = (image[3][ty]:sub(tx,tx) == " " and output[3][y][x] or image[3][ty]:sub(tx,tx))
					end
				end
			end
		end
		output[1][y] = table.concat(output[1][y])
		output[2][y] = table.concat(output[2][y])
		output[3][y] = table.concat(output[3][y])
	end
	return output
end
nfte.merge = merge

local rotatePoint = function(x, y, angle, originX, originY)
	return
		round( (x-originX) * math.cos(angle) - (y-originY) * math.sin(angle) ) + originX,
		round( (x-originX) * math.sin(angle) + (y-originY) * math.cos(angle) ) + originY
end

-- rotates an image around (originX, originY) or its center, by angle radians
rotateImage = function(image, angle, originX, originY)
	assert(checkValid(image), "Invalid image.")
	if imageX == 0 or imageY == 0 then
		return image
	end
	local output = {{},{},{}}
	local realOutput = {{},{},{}}
	local tx, ty, corners
	local imageX, imageY = getSize(image)
	local originX, originY = originX or math.floor(imageX / 2), originY or math.floor(imageY / 2)
	corners = {
		{rotatePoint(1, 		1, 		angle, originX, originY)},
		{rotatePoint(imageX, 	1, 		angle, originX, originY)},
		{rotatePoint(1, 		imageY, angle, originX, originY)},
		{rotatePoint(imageX, 	imageY, angle, originX, originY)},
	}
	local minX = math.min(corners[1][1], corners[2][1], corners[3][1], corners[4][1])
	local maxX = math.max(corners[1][1], corners[2][1], corners[3][1], corners[4][1])
	local minY = math.min(corners[1][2], corners[2][2], corners[3][2], corners[4][2])
	local maxY = math.max(corners[1][2], corners[2][2], corners[3][2], corners[4][2])

	for y = 1, (maxY - minY) + 1 do
		output[1][y] = {}
		output[2][y] = {}
		output[3][y] = {}
		for x = 1, (maxX - minX) + 1 do
			tx, ty = rotatePoint(x + minX - 1, y + minY - 1, -angle, originX, originY)
			output[1][y][x] = " "
			output[2][y][x] = " "
			output[3][y][x] = " "
			if image[1][ty] then
				if tx >= 1 and tx <= #image[1][ty] then
					output[1][y][x] = image[1][ty]:sub(tx,tx)
					output[2][y][x] = image[2][ty]:sub(tx,tx)
					output[3][y][x] = image[3][ty]:sub(tx,tx)
				end
			end
		end
	end
	for y = 1, #output[1] do
		output[1][y] = table.concat(output[1][y])
		output[2][y] = table.concat(output[2][y])
		output[3][y] = table.concat(output[3][y])
	end
	return output, math.ceil(minX), math.ceil(minY)
end
nfte.rotateImage = rotateImage

-- returns help info for each function
help = function(input)
	local helpOut = {
		loadImageData = "Loads an NFT, ANFT, or NFP image from a string input.",
		loadImage = "Loads an NFT, ANFT, or NFP image from a file path.",
		convertFromNFP = "Loads a table NFP image into a table NFT image, same as what loadImage outputs.",
		drawImage = "Draws an image. Does not support transparency, sadly.",
		drawImageTransparent = "Draws an image. Supports transparency, but not as fast as drawImage.",
		drawImageCenter = "Draws an image centered around the inputted coordinates. Does not support transparency.",
		drawImageCentre = "Draws an image centred around the inputted coordinates. Does not support transparency.",
		drawImageCenterTransparent = "Draws an image centered around the inputted coordinates. Supports transparency, but not quite as fast as drawImageCenter.",
		drawImageCentreTransparent = "Draws an image centred around the inputted coordinates. Supports transparency, but not quite as fast as drawImageCentre.",
		flipX = "Returns the inputted image, but flipped horizontally.",
		flipY = "Returns the inputted image, but flipped vertically.",
		grayOut = "Returns the inputted image, but with the colors converted into grayscale as best I could.",
		greyOut = "Returns the inputted image, but with the colors converted into greyscale as best I could.",
		lighten = "Returns the inputted image, but with the colors lightened.",
		darken = "Returns the inputted image, but with the colors darkened.",
		stretchImage = "Returns the inputted image, but it's been stretched to the inputted size. If the fourth argument is true, it will spread non-space characters evenly in the image.",
		stretchImageKeepAspect = "Returns the inputted image, but it's been stretched to fit a box of the inputted size. Won't alter its aspect ratio. If the fourth argument is true, it will spread non-space characters evenly in the image.",
		pixelateImage = "Returns the inputted image, but pixelated to a variable degree.",
		merge = "Merges two or more images together.",
		crop = "Crops an image between points (X1, Y1) and (X2, Y2).",
		rotateImage = "Rotates an image, and also returns how much the image center's X and Y had been adjusted.",
		colorSwap = "Swaps the colors of a given image with another color, according to an inputted table.",
		colourSwap = "Swaps the colours of a given image with another colour, according to an inputted table for either/both text and background."
	}
	if nfte[input] then
		return helpOut[input] or "That function doesn't have a help text...? That's not right."
	else
		return helpOut[input] or "No such function."
	end
end
nfte.help = help

return nfte