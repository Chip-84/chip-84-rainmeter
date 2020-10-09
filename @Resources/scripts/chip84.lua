local bit

local opcode
local memory = {}
local V = {}
local SV = {}
local I
local pc

local stack = {}
local stackPointer

local delay_timer
local sound_timer

local keys = {}

local display = {}

local drawFlag
local extendedScreen = 0
local screen_width = 64
local screen_height = 32

local screenX, screenY

local arrayOffset = 1

local scaleMode = 0

local fontset = {
	0xF0, 0x90, 0x90, 0x90, 0xF0,
	0x20, 0x60, 0x20, 0x20, 0x70,
	0xF0, 0x10, 0xF0, 0x80, 0xF0,
	0xF0, 0x10, 0xF0, 0x10, 0xF0,
	0x90, 0x90, 0xF0, 0x10, 0x10,
	0xF0, 0x80, 0xF0, 0x10, 0xF0,
	0xF0, 0x80, 0xF0, 0x90, 0xF0,
	0xF0, 0x10, 0x20, 0x40, 0x40,
	0xF0, 0x90, 0xF0, 0x90, 0xF0,
	0xF0, 0x90, 0xF0, 0x10, 0xF0,
	0xF0, 0x90, 0xF0, 0x90, 0x90,
	0xE0, 0x90, 0xE0, 0x90, 0xE0,
	0xF0, 0x80, 0x80, 0x80, 0xF0,
	0xE0, 0x90, 0x90, 0x90, 0xE0,
	0xF0, 0x80, 0xF0, 0x80, 0xF0,
	0xF0, 0x80, 0xF0, 0x80, 0x80 
}

local fontset_hires = {
	0x7C, 0xC6, 0xCE, 0xDE, 0xD6, 0xF6, 0xE6, 0xC6, 0x7C, 0x00,
	0x10, 0x30, 0xF0, 0x30, 0x30, 0x30, 0x30, 0x30, 0xFC, 0x00,
	0x78, 0xCC, 0xCC, 0x0C, 0x18, 0x30, 0x60, 0xCC, 0xFC, 0x00,
	0x78, 0xCC, 0x0C, 0x0C, 0x38, 0x0C, 0x0C, 0xCC, 0x78, 0x00,
	0x0C, 0x1C, 0x3C, 0x6C, 0xCC, 0xFE, 0x0C, 0x0C, 0x1E, 0x00,
	0xFC, 0xC0, 0xC0, 0xC0, 0xF8, 0x0C, 0x0C, 0xCC, 0x78, 0x00,
	0x38, 0x60, 0xC0, 0xC0, 0xF8, 0xCC, 0xCC, 0xCC, 0x78, 0x00,
	0xFE, 0xC6, 0xC6, 0x06, 0x0C, 0x18, 0x30, 0x30, 0x30, 0x00,
	0x78, 0xCC, 0xCC, 0xEC, 0x78, 0xDC, 0xCC, 0xCC, 0x78, 0x00,
	0x7C, 0xC6, 0xC6, 0xC6, 0x7E, 0x0C, 0x18, 0x30, 0x70, 0x00,
	0x30, 0x78, 0xCC, 0xCC, 0xCC, 0xFC, 0xCC, 0xCC, 0xCC, 0x00,
	0xFC, 0x66, 0x66, 0x66, 0x7C, 0x66, 0x66, 0x66, 0xFC, 0x00,
	0x3C, 0x66, 0xC6, 0xC0, 0xC0, 0xC0, 0xC6, 0x66, 0x3C, 0x00,
	0xF8, 0x6C, 0x66, 0x66, 0x66, 0x66, 0x66, 0x6C, 0xF8, 0x00,
	0xFE, 0x62, 0x60, 0x64, 0x7C, 0x64, 0x60, 0x62, 0xFE, 0x00,
	0xFE, 0x66, 0x62, 0x64, 0x7C, 0x64, 0x60, 0x60, 0xF0, 0x00 
}

function init ()
	for i = 0, 4096 - arrayOffset, 1 do
		memory[i + arrayOffset] = 0
	end
	
	for i = 0, 16 - arrayOffset, 1 do
		V[i + arrayOffset] = 0
	end
	for i = 0, 8 - arrayOffset, 1 do
		SV[i + arrayOffset] = 0
	end
	for i = 0, 16 - arrayOffset, 1 do
		stack[i + arrayOffset] = 0
	end
	for i = 0, 16 - arrayOffset, 1 do
		keys[i + arrayOffset] = 0
	end
	for i = 0, 128 * 64 - arrayOffset, 1 do
		display[i + arrayOffset] = 0
	end
	I = 0x0;
	pc = 0x200;
	
	stackPointer = 0;
	
	delay_timer = 0;
	sound_timer = 0;
	
	screen_width = 64;
	screen_height = 32;
	extendedScreen = 0;
	if(scaleMode == 0) then
		SKIN:Bang("!SetOption", "MeterScreen", "W", 64)
		SKIN:Bang("!SetOption", "MeterScreen", "H", 32)
	end
	
	screenX = 0
	screenY = 0
	drawFlag = false;
	loadFontset()
end

function emulateCycle (steps)
	for step = 1, steps, 1 do
	
		if pc ~= nil then
		
		opcode = (bit.bor(bit.lshift(memory[pc + arrayOffset], 8), memory[pc + 1 + arrayOffset]));
		local x = bit.rshift(bit.band(opcode, 0x0f00), 8)
		local y = bit.rshift(bit.band(opcode, 0x00f0), 4)
		
		pc = pc + 2
		
	--0x0000
		if bit.band(opcode, 0xF000) == 0x0000 then
			if bit.band(opcode, 0x00F0) == 0x00c0 then
				local n = bit.band(opcode, 0x000f)
				for i = 0, n-1, 1 do
					for j = 1, screen_width, 1 do
						table.remove(display, screen_width * screen_height + arrayOffset)
						table.insert(display, 0 + arrayOffset, 0)
					end
				end
				drawFlag = true
			elseif bit.band(opcode, 0x00FF) == 0x00E0 then
				for i = 0, screen_width * screen_height - arrayOffset, 1 do
					display[i + arrayOffset] = 0
				end
				drawFlag = true
			elseif bit.band(opcode, 0x00FF) == 0x00EE then
				stackPointer = stackPointer - 1
				pc = stack[stackPointer + arrayOffset]
			elseif bit.band(opcode, 0x00FF) == 0x00fb then
				for i = 0, screen_height, 1 do
					for j = 1, 4, 1 do
						table.remove(display,screen_width*i+arrayOffset+screen_width)
						table.insert(display, screen_width*i+arrayOffset, 0)
					end
				end
			elseif bit.band(opcode, 0x00FF) == 0x00fc then
				for i = 0, screen_height, 1 do
					for j = 1, 4, 1 do
						table.insert(display, screen_width*i+arrayOffset+screen_width, 0)
						table.remove(display,screen_width*i+arrayOffset)
					end
				end
			elseif bit.band(opcode, 0x00FF) == 0x00fd then
				--exit
			elseif bit.band(opcode, 0x00FF) == 0x00fe then
				extendedScreen = 0;
				screen_width = 64;
				screen_height = 32;
				if(scaleMode == 0) then
					SKIN:Bang("!SetOption", "MeterScreen", "W", 64)
					SKIN:Bang("!SetOption", "MeterScreen", "H", 32)
				end
			elseif bit.band(opcode, 0x00FF) == 0x00ff then
				extendedScreen = 1;
				screen_width = 128;
				screen_height = 64;
				if(scaleMode == 0) then
					SKIN:Bang("!SetOption", "MeterScreen", "W", 128)
					SKIN:Bang("!SetOption", "MeterScreen", "H", 64)
				end
			else end
	--0x1000
		elseif bit.band(opcode, 0xF000) == 0x1000 then
			pc = bit.band(opcode, 0x0FFF)
	--0x2000
		elseif bit.band(opcode, 0xF000) == 0x2000 then
			stack[stackPointer + arrayOffset] = pc
			stackPointer = stackPointer + 1
			pc = bit.band(opcode, 0x0FFF)
	--0x3000		
		elseif bit.band(opcode, 0xF000) == 0x3000 then
			if V[x + arrayOffset] == bit.band(opcode, 0x00FF) then
				pc = pc + 2
			end
	--0x4000		
		elseif bit.band(opcode, 0xF000) == 0x4000 then
			if V[x + arrayOffset] ~= bit.band(opcode, 0x00FF) then
				pc = pc + 2
			end
	--0x5000		
		elseif bit.band(opcode, 0xF000) == 0x5000 then
			if(V[x + arrayOffset] == V[y + arrayOffset]) then
				pc = pc + 2
			end
	--0x6000		
		elseif bit.band(opcode, 0xF000) == 0x6000 then
			V[x + arrayOffset] = bit.band(opcode, 0x00FF)
	--0x7000		
		elseif bit.band(opcode, 0xF000) == 0x7000 then
			V[x + arrayOffset] = bit.band(V[x + arrayOffset] + bit.band(opcode, 0x00FF), 0xFF)
	--0x8000		
		elseif bit.band(opcode, 0xF000) == 0x8000 then
			if bit.band(opcode, 0x000F) == 0x0000 then
				V[x + arrayOffset] = V[y + arrayOffset]
			elseif bit.band(opcode, 0x000F) == 0x0001 then
				V[x + arrayOffset] = bit.band(bit.bor(V[x + arrayOffset], V[y + arrayOffset]), 0xFF)
			elseif bit.band(opcode, 0x000F) == 0x0002 then
				V[x + arrayOffset] = bit.band(V[x + arrayOffset], V[y + arrayOffset])
			elseif bit.band(opcode, 0x000F) == 0x0003 then
				V[x + arrayOffset] = bit.band(bit.bxor(V[x + arrayOffset], V[y + arrayOffset]), 0xFF)
			elseif bit.band(opcode, 0x000F) == 0x0004 then
				if V[x + arrayOffset] + V[y + arrayOffset] > 0xff then
					V[0xF + arrayOffset] = 1
				else
					V[0xF + arrayOffset] = 0
				end
				V[x + arrayOffset] = bit.band(V[x + arrayOffset] + V[y + arrayOffset], 0xFF)
			elseif bit.band(opcode, 0x000F) == 0x0005 then
				if V[x + arrayOffset] >= V[y + arrayOffset] then
					V[0xF + arrayOffset] = 1
				else
					V[0xF + arrayOffset] = 0
				end
				V[x + arrayOffset] = bit.band(V[x + arrayOffset] - V[y + arrayOffset], 0xFF)
			elseif bit.band(opcode, 0x000F) == 0x0006 then
				V[0xF + arrayOffset] = bit.band(V[x + arrayOffset], 0x1)
				V[x + arrayOffset] = bit.rshift(V[x + arrayOffset], 1)
			elseif bit.band(opcode, 0x000F) == 0x0007 then
				V[x + arrayOffset] = bit.band(V[y + arrayOffset] - V[x + arrayOffset], 0xFF)
				if V[x + arrayOffset] >= V[y + arrayOffset] then
					V[0xF + arrayOffset] = 0
				else
					V[0xF + arrayOffset] = 1
				end
			elseif bit.band(opcode, 0x000F) == 0x000E then
				V[0xF + arrayOffset] = bit.rshift(V[x + arrayOffset], 7)
				V[x + arrayOffset] = (V[x + arrayOffset] * 2) % 256
			else
				
			end
	--0x9000		
		elseif bit.band(opcode, 0xF000) == 0x9000 then
			if V[x + arrayOffset] ~= V[y + arrayOffset] then
				pc = pc + 2
			end
	--0xA000		
		elseif bit.band(opcode, 0xF000) == 0xA000 then
			I = bit.band(opcode, 0x0FFF)
	--0xB000		
		elseif bit.band(opcode, 0xF000) == 0xB000 then
			local extra = bit.band(V[0 + arrayOffset], 0xFF)
			pc = extra + bit.band(opcode, 0x0FFF)
	--0xC000		
		elseif bit.band(opcode, 0xF000) == 0xC000 then
			local nn = bit.band(opcode, 0x00ff)
			local randomNumber = bit.band(math.random(0, 255), nn)
			V[x + arrayOffset] = randomNumber
	--0xD000		
		elseif bit.band(opcode, 0xF000) == 0xD000 then
			local xd = V[x + arrayOffset]
			local yd = V[y + arrayOffset]
			local height = bit.band(opcode, 0x000F)
			
			V[0xF + arrayOffset] = 0
			
			if extendedScreen == 1 then
				local cols = 1
				local num = 0x80
				if height == 0 then
					cols = 2
					height = 16
				end
				
				for _y = 0, height - arrayOffset, 1 do
					local line = memory[I + (cols*_y) + arrayOffset]
					if cols == 2 then
						line = bit.lshift(line, 8)
						line = bit.bor(line, memory[I + bit.lshift(_y, 1) + 1 + arrayOffset])
						num = 0x8000
					end
					for _x = 0, bit.lshift(cols, 3), 1 do
						if bit.band(line, bit.rshift(num, _x)) ~= 0 then
							
							local index = ((yd + _y) % screen_height) * screen_width + ((xd + _x) % screen_width)
							
							if(display[index + arrayOffset] == 1) then
								V[0xF + arrayOffset] = 1
							end
							
							display[index + arrayOffset] = bit.bxor(display[index + arrayOffset], 1)
						end
					end
				end
			else
				for _y = 0, height - arrayOffset, 1 do
					local line = memory[I + _y + arrayOffset]
					for _x = 0, 8 - arrayOffset, 1 do
						local pixel = bit.band(line, bit.rshift(0x80, _x))
						if pixel ~= 0 then
							
							local index = ((yd + _y) % 32) * 64 + ((xd + _x) % 64)
							
							if(display[index + arrayOffset] == 1) then
								V[0xF + arrayOffset] = 1
							end
							
							display[index + arrayOffset] = bit.bxor(display[index + arrayOffset], 1)
						end
					end
				end
			end
			drawFlag = true
	--0xE000		
		elseif bit.band(opcode, 0xF000) == 0xE000 then
			if bit.band(opcode, 0x00FF) == 0x009E then
				if keys[V[x + arrayOffset] + arrayOffset] == 1 then
					pc = pc + 2
				end
			elseif bit.band(opcode, 0x00FF) == 0x00A1 then
				if keys[V[x + arrayOffset] + arrayOffset] == 0 then
					pc = pc + 2
				end
			else
				print("Opcode does not exist!")
			end
	--0xF000
		elseif bit.band(opcode, 0xF000) == 0xF000 then
			if bit.band(opcode, 0x00FF) == 0x0007 then
				V[x + arrayOffset] = delay_timer
			elseif bit.band(opcode, 0x00FF) == 0x000A then
				local storedpc = pc
				local keyPressed = false
				--repeat
					pc = storedpc - 2
					for i = 0, #keys - arrayOffset, 1 do
						if(keys[i + arrayOffset] == 1) then
							V[x + arrayOffset] = i
							pc = pc + 2
							keyPressed = true
						end
					end
				--until keyPressed == true
			elseif bit.band(opcode, 0x00FF) == 0x0015 then
				delay_timer = V[x + arrayOffset]
			elseif bit.band(opcode, 0x00FF) == 0x0018 then
				sound_timer = V[x + arrayOffset]
			elseif bit.band(opcode, 0x00FF) == 0x001E then
				I = bit.band(I + V[x + arrayOffset], 0xffff)
			elseif bit.band(opcode, 0x00FF) == 0x0029 then
				I = bit.band(V[x + arrayOffset], 0xf) * 5;
			elseif bit.band(opcode, 0x00FF) == 0x0030 then
				I = bit.band(V[x + arrayOffset], 0xf) * 10 + 80;
			elseif bit.band(opcode, 0x00FF) == 0x0033 then
				memory[I + arrayOffset] = math.floor(V[x + arrayOffset] / 100);
				memory[I+1 + arrayOffset] = math.floor(V[x + arrayOffset] / 10) % 10;
				memory[I+2 + arrayOffset] = V[x + arrayOffset] % 10;
			elseif bit.band(opcode, 0x00FF) == 0x0055 then
				for i = 0, x, 1 do
					memory[I + i + arrayOffset] = V[i + arrayOffset]
				end
			elseif bit.band(opcode, 0x00FF) == 0x0065 then
				for i = 0, x, 1 do
					V[i + arrayOffset] = memory[I + i + arrayOffset]
				end
			elseif bit.band(opcode, 0x00FF) == 0x0055 then
				if x > 7 then
					x = 7
				end
				for i = 0, x - arrayOffset, 1 do
					SV[i + arrayOffset] = V[i + arrayOffset]
				end
			elseif bit.band(opcode, 0x00FF) == 0x0065 then
				if x > 7 then
					x = 7
				end
				for i = 0, x - arrayOffset, 1 do
					V[i + arrayOffset] = SV[i + arrayOffset]
				end
			else
				print("Unsupported opcode!")
			end
		else
			print("Unsupported opcode!")
		end
		end
	end
	
	if(sound_timer > 0) then
		sound_timer = sound_timer - 1
	end
	
	if(delay_timer > 0) then
		delay_timer = delay_timer - 1
	end
end

function removeDrawFlag()
	drawFlag = false
end

function loadFontset ()
	for i = 0, #fontset - arrayOffset, 1 do
		memory[i + arrayOffset] = bit.band(fontset[i + arrayOffset], 0xFF)
	end
	for i = 0, #fontset_hires - arrayOffset, 1 do
		memory[80 + i + arrayOffset] = bit.band(fontset_hires[i + arrayOffset], 0xFF)
	end
end

function loadProgram(fileName)
	init()
	--fillKeyIds()
	
	local myFile = assert(io.open(fileName, "rb"))
	local i = 0
	repeat
		local str = myFile:read(4*1024)
		for c in (str or ''):gmatch'.' do
			memory[0x200 + i + arrayOffset] = bit.band(c:byte(), 0xFF)
			i = i + 1
		end
	until not str
	assert(myFile:close())
end

function getStringFromTable(t)
	local str = ""
	for i = 1, #t, 1 do
		str = str .. string.char(t[i])
	end
	return str
end

function generateBitmap()
	local bmp = {}
	local bitsPerPixel = 24
	local headerSize = 54
	local imageScale = 1
	bmp[0+1] = 0x42
	bmp[1+1] = 0x4d
	local tmp = (screen_width*imageScale)*(screen_height*imageScale)*math.ceil(bitsPerPixel/8)+headerSize
	--6198
	--0x1836
	local x = bit.band(tmp, 0xff)
	local y = bit.band(bit.rshift(tmp, 8), 0xff)
	local z = bit.band(bit.rshift(tmp, 16), 0xff)
	local w = bit.band(bit.rshift(tmp, 24), 0xff)
	bmp[2+1] = x
	bmp[3+1] = y
	bmp[4+1] = z
	bmp[5+1] = w
	
	bmp[6+1] = 0x00
	bmp[7+1] = 0x00
	bmp[8+1] = 0x00
	bmp[9+1] = 0x00
	bmp[10+1] = headerSize
	bmp[11+1] = 0x00
	bmp[12+1] = 0x00
	bmp[13+1] = 0x00
	bmp[14+1] = 40
	bmp[15+1] = 0x00
	bmp[16+1] = 0x00
	bmp[17+1] = 0x00
	x = bit.band(screen_width*imageScale, 0xff)
	y = bit.band(bit.rshift(screen_width*imageScale, 8), 0xff)
	z = bit.band(bit.rshift(screen_width*imageScale, 16), 0xff)
	w = bit.band(bit.rshift(screen_width*imageScale, 24), 0xff)
	bmp[18+1] = x
	bmp[19+1] = y
	bmp[20+1] = z
	bmp[21+1] = w
	x = bit.band(screen_height*imageScale, 0xff)
	y = bit.band(bit.rshift(screen_height*imageScale, 8), 0xff)
	z = bit.band(bit.rshift(screen_height*imageScale, 16), 0xff)
	w = bit.band(bit.rshift(screen_height*imageScale, 24), 0xff)
	bmp[22+1] = x
	bmp[23+1] = y
	bmp[24+1] = z
	bmp[25+1] = w

	bmp[26+1] = 0x01
	bmp[27+1] = 0x00
	bmp[28+1] = bitsPerPixel
	bmp[29+1] = 0x00
	
	bmp[30+1] = 0x00
	bmp[31+1] = 0x00
	bmp[32+1] = 0x00
	bmp[33+1] = 0x00
	
	tmp = (screen_width*imageScale)*(screen_height*imageScale)*math.ceil(bitsPerPixel/8)
	x = bit.band(tmp, 0xff)
	y = bit.band(bit.rshift(tmp, 8), 0xff)
	z = bit.band(bit.rshift(tmp, 16), 0xff)
	w = bit.band(bit.rshift(tmp, 24), 0xff)
	bmp[34+1] = x
	bmp[35+1] = y
	bmp[36+1] = z
	bmp[37+1] = w
	
	bmp[38+1] = 0x00
	bmp[39+1] = 0x00
	bmp[40+1] = 0x00
	bmp[41+1] = 0x00
	
	bmp[42+1] = 0x00
	bmp[43+1] = 0x00
	bmp[44+1] = 0x00
	bmp[45+1] = 0x00
	
	bmp[46+1] = 0x00
	bmp[47+1] = 0x00
	bmp[48+1] = 0x00
	bmp[49+1] = 0x00
	
	bmp[50+1] = 0x00
	bmp[51+1] = 0x00
	bmp[52+1] = 0x00
	bmp[53+1] = 0x00
	
	for y = 0, screen_height - arrayOffset, 1 do
		for yd = 0, imageScale-1, 1 do
			for x = 0, screen_width - arrayOffset, 1 do
				local color = 0xff
				if display[x + arrayOffset + y*screen_width] == 0 then color = 0x00 end
				for xd = 0, imageScale-1, 1 do
					table.insert(bmp, color)
					table.insert(bmp, color)
					table.insert(bmp, color)
				end
			end
		end
	end
	
	local out = io.open(SKIN:GetVariable('@').."images\\frame.bmp", "wb")
	local str = getStringFromTable(bmp)
	out:write(str)
	out:close()
end

function generateIni()
	local t = {}
	for i = 0, screen_height*screen_width - arrayOffset, 1 do
		local fillColor = "0,0,0"
		if display[i + arrayOffset] > 0 then
			fillColor = "255,255,255"
		end
		table.insert(t, "[Pixel"..i.."]\nMeter=Shape\nShape=Rectangle "..i%screen_width..","..math.floor(i/screen_width)..",1,1 | Fill Color "..fillColor.."\nDynamicVariables=1")
	end
	
	local out = io.open(SKIN:GetVariable('@').."include\\screen.inc", "wb")
	out:write(table.concat(t, "\n\n"))
	out:close()
end

function setKeyBuffer()
	keys[1+arrayOffset] = SELF:GetNumberOption("Key1Down")
	keys[2+arrayOffset] = SELF:GetNumberOption("Key2Down")
	keys[3+arrayOffset] = SELF:GetNumberOption("Key3Down")
	keys[12+arrayOffset] = SELF:GetNumberOption("Key4Down")
	keys[4+arrayOffset] = SELF:GetNumberOption("Key5Down")
	keys[5+arrayOffset] = SELF:GetNumberOption("Key6Down")
	keys[6+arrayOffset] = SELF:GetNumberOption("Key7Down")
	keys[13+arrayOffset] = SELF:GetNumberOption("Key8Down")
	keys[7+arrayOffset] = SELF:GetNumberOption("Key9Down")
	keys[8+arrayOffset] = SELF:GetNumberOption("Key10Down")
	keys[9+arrayOffset] = SELF:GetNumberOption("Key11Down")
	keys[14+arrayOffset] = SELF:GetNumberOption("Key12Down")
	keys[10+arrayOffset] = SELF:GetNumberOption("Key13Down")
	keys[0+arrayOffset] = SELF:GetNumberOption("Key14Down")
	keys[11+arrayOffset] = SELF:GetNumberOption("Key15Down")
	keys[15+arrayOffset] = SELF:GetNumberOption("Key16Down")
end

local playing = false
local fileName = ""
local romfile = ""

function Initialize()
	if(SELF:GetNumberOption("Player") == 1) then
		bit = dofile(SKIN:GetVariable('@')..'scripts\\numberlua.lua')
		romfile = SKIN:GetVariable('@').."include\\romfile.inc"
		os.remove(romfile)
		loadProgram(SKIN:GetVariable('@').."roms\\SPLASH")
		playing = true
	end
end

function Update()
	if(SELF:GetNumberOption("Player") == 1) then
		if(file_exists(romfile)) then
			local f = io.open(romfile, "rb")
			local fileName = f:read()
			f:close()
			os.remove(romfile)
			loadProgram(fileName)
			playing = true
			SKIN:Bang('!DeactivateConfig "Chip-84\\ROM Browser"')
		end
	end
	
	if(playing and SELF:GetNumberOption("MouseOver") == 0) then
		if(scaleMode ~= SKIN:GetVariable("ScaleMode")) then
			scaleMode = SKIN:GetVariable("ScaleMode")
			print(scaleMode)
			if(scaleMode == "0") then
				SKIN:Bang("!SetOption", "MeterScreen", "W", screen_width)
				SKIN:Bang("!SetOption", "MeterScreen", "H", screen_height)
			else
				SKIN:Bang("!SetOption", "MeterScreen", "W", 512)
				SKIN:Bang("!SetOption", "MeterScreen", "H", 256)
			end
		end
		setKeyBuffer()
		emulateCycle(SKIN:GetVariable("CyclesPerFrame"))
		if(drawFlag) then
			generateBitmap()
			--generateIni()
			removeDrawFlag()
			--SKIN:Bang('!Redraw')
		end
	end
end

function CheckFile()
	if(SELF:GetNumberOption("Player") == 0) then
		if(SELF:GetOption("FileName") ~= "") then
			--print(SELF:GetOption("FileName"))
			--print(is_dir(SELF:GetOption("FileName")))
			if(is_dir(SELF:GetOption("FileName"))) then
				SKIN:Bang('!CommandMeasure mIndex'..SELF:GetNumberOption("FileIndex")..'Name "FollowPath"')
			else
				fileName = SELF:GetOption("FileName")
				local out = io.open(SKIN:GetVariable('@').."include\\romfile.inc", "wb")
				out:write(fileName)
				out:close()
			end
		end
	end
end

function is_dir(path)
    local f = io.open(path, "r")
	if(f == nil) then return true end
    local ok, err, code = f:read(1)
    f:close()
    return code == 21 or f == nil
end

function file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end