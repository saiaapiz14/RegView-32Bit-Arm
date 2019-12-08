-----------------------------------------------------------------------------------
-- Regview 1.2 (32-Bit)
-- By saiaapiz
-----------------------------------------------------------------------------------

-- Section		: Init
-- Description	: Prepare everything before executing anything else.
local __allocated, __allocatedSz = 0, 0 -- Used by allocateMem
local sf = string.format
local clock = os.clock
local toast = gg.toast
local sub = string.sub

-- Deny opcode related to PC.
denyOpcode = {
	0xEB
}

-- Section		: Function Declaration
-- Description	: This is where hand, leg, mouth, nose a.k.a Important part of the script.
function ShowChangelog() PopupBox(
[[
📜 ▫ ️Changelog
• 1.2
  - Code Improvement.
• 1.1_1
  - Cancel hook options, and abit notes.
]]
)
end
function quitErr(str)
	str = "Error: "..str
	toast(str)
	gg.alert(str)
	print(str)
	os.exit()
end
function PopupBox(Caption, Text)
	if Text == nil then Text = "" end
	gg.alert(Caption .. '\n' .. Text)
end
function isAddrValid(Address)
	if Address ~= nil and Address ~= 0 or Address then
		return true
	end
	return false
end
function tohex(Data)
	if type(Data) == 'number' then
		return sf('0x%08X', Data)
	end
	return Data:gsub(".", function(a) return string.format("%02X", (string.byte(a))) end):gsub(" ", "") 
end
function wpm(Address, ggtype, data)
	assert(Address ~= nil, "[wpm]: error, provided address is nil.")
	if gg.setValues({{address = Address, flags = ggtype, value = data}}) then 
		return true 
	else 
		return false 
	end
end
function rpm(Address, ggtype)
	assert(Address ~= nil, "[rpm]: error, provided address is nil.")
	res = gg.getValues({{address = Address, flags = ggtype}})
	if type(res) ~= "string" then
		if ggtype == gg.TYPE_BYTE then
			result = res[1].value & 0xFF
		elseif ggtype == gg.TYPE_WORD then
			result = res[1].value & 0xFFFF
		elseif ggtype == gg.TYPE_DWORD then
			result = res[1].value & 0xFFFFFFFF
		elseif ggtype == gg.TYPE_QWORD then
			result = res[1].value & 0xFFFFFFFFFFFFFFFF
		elseif ggtype == gg.TYPE_XOR then
			result = res[1].value & 0xFFFFFFFF
		else
			result = res[1].value
		end
		return result
	else
		return false
	end
end
function rwmem(Address, SizeOrBuffer)
	assert(Address ~= nil, "[rwmem]: error, provided address is nil.")
	_rw = {}
	if type(SizeOrBuffer) == "number" then
		_ = ""
		for _ = 1, SizeOrBuffer do _rw[_] = {address = (Address - 1) + _, flags = gg.TYPE_BYTE} end
		for v, __ in ipairs(gg.getValues(_rw)) do _ = _ .. string.format("%02X", __.value & 0xFF) end
		return _
	end
	Byte = {} SizeOrBuffer:gsub("..", function(x) 
		Byte[#Byte + 1] = x _rw[#Byte] = {address = (Address - 1) + #Byte, flags = gg.TYPE_BYTE, value = x .. "h"} 
	end)
	gg.setValues(_rw)
end
oldClock = os.clock() function notify(str)
  cClock = os.clock() - oldClock
  if cClock > 1 then
    posStr = (posStr and posStr < 3 and posStr + 1 or 1)
    toast(str..('...'):sub(1, posStr))
    oldClock = os.clock()
  end
end
function initMenu(Menu, prevMenu) -- UI xD
	local title, menuType, cOpt, _opt = Menu[1][1], Menu[1][2], {{},{}}
	for _ = 1, #Menu[2], 2 do
		name, func = Menu[2][_], Menu[2][_ + 1]
		cOpt[1][#cOpt[1] + 1] = (type(func) == "table" and name.." >" or name)
		cOpt[2][#cOpt[2] + 1] = func
	end
	cOpt[1][#cOpt[1] + 1] = (prevMenu and "< Back to " .. prevMenu[1][1] or "Quit Script")

	while(true) do
		if gg.isVisible() then gg.setVisible(false)
			if menuType then _opt = gg.multiChoice(cOpt[1], nil, title) else _opt = gg.choice(cOpt[1], nil, title) end
			if _opt then
				gg.setVisible(true)
				-- Sorry for messy code for menuType handler.
				if not menuType then
					-- choice Handler
					efunc = cOpt[2][_opt] if efunc then if type(efunc) ~= "table" then _curMenuName = cOpt[1][_opt] efunc() if _curMenuName ~= cOpt[1][_opt] then cOpt[1][_opt] = _curMenuName end else initMenu(efunc, Menu) end else return end
				else
					-- multiChoice Handler  
					for _ = 1, #cOpt[1] do if _opt[_] then efunc = cOpt[2][_] if efunc then if type(efunc) ~= "table" then _curMenuName = cOpt[1][_] efunc() if _curMenuName ~= cOpt[1][_] then cOpt[1][_] = _curMenuName end else gg.setVisible(true) initMenu(efunc, Menu) end else return end end end
				end
			end
		end
		gg.sleep(300)
	end
end

--= AssemblyTool (Only 32-Bit Supported.) =--
function reverseAddress(address)
	assert(address ~= nil, "\n\n>> [reverseAddress]: error, provided address is nil. <<\n\n")
	return (address & 0x000000FF) << 24 | (address & 0x0000FF00) << 8 | (address & 0x00FF0000) >> 8 | (address & 0xFF000000) >> 24
end
function setjmp(address, target) -- Will Eat 8 Byte from you !
	assert(address ~= nil, "\n\n>> [setjmp]: error, provided address is nil. <<\n\n")
	assert(address ~= nil, "\n\n>> [setjmp]: error, provided target address is nil. <<\n\n")
	local o_opsc = rwmem(address, 8)
	rwmem(address, "04F01FE5"..string.format("%08x", reverseAddress(target))) -- LDR	PC, [PC, #-4]
	return function() rwmem(address, o_opsc) end -- return: jmp restorer function.
end
function allocateMem(reqSize, armCompatibility) -- Smart way to reduce memory consumption
	assert(reqSize and not (reqSize >= 0x1000) or not (reqSize <= 0), "\n\n>> [allocateMem]: Error, Please check if reqSize is valid. <<\n\n")
	
	if armCompatibility == nil or armCompatibility == false then -- if armCompatibility is false or nil, then basic allocated mem.
		-- Reuse allocated mem from GG
		__allocatedSz = __allocatedSz + reqSize
		if __allocatedSz >= 0x1000 then -- If we used all allocated mem, then realloc our mem.
			toast("[allocateMem]: Allocated memory exhausted, realloc !")
			__allocated = 0 __allocatedSz = reqSize
		end 
		__allocated = (__allocated == 0 and gg.allocatePage(gg.PROT_READ | gg.PROT_WRITE | gg.PROT_EXEC) or __allocated)
		
		return (__allocated + __allocatedSz) - reqSize
	end

	tempMemory = 0
	for _, __ in pairs(gg.getRangesList()) do
		if __["state"] == "Xa" and __["type"] == "r-xp" then 
			tempMemory = __["start"]
		end
	end
	assert(isAddrValid(tempMemory), "\n\n>> [allocateMem]: error, failed preparing tempMemory.<<\n\n")
	local o_opsc = rwmem(tempMemory, reqSize)
	return tempMemory, function() rwmem(tempMemory, o_opsc) end -- return: allocated mem, restorer.
end
function getRegister(address)
	assert(isAddrValid(address), "\n\n>> [getRegister]: error, please provide address. <<\n\n")
	local scode = "FF5F2DE918009FE500D080E514009FE5010050E3FCFFFF1AFF5FBDE804F01FE5AAAAAAAABBBBBBBB00000000"  -- Let's shellcode handler our register thinggy !
	local _regdata = allocateMem(0x4C)
	local _amem, _amemRestore = allocateMem(scode:len() + 8, true)										-- We need to add original opcode into allocated shellcode mem, so it won't crash.
	
	gg.processPause()
	rwmem(_amem, rwmem(address, 8) .. scode)															-- Write original opcode into shellcode allocated mem.
	wpm((_amem + 8) + 0x20, 4, address + 8)																-- Write returnAddress.
	wpm((_amem + 8) + 0x24, 4, _regdata)																-- Write regData.
	local _jmpRestore = setjmp(address, _amem)															-- Hook targeted address.
	gg.processResume()
	--gg.gotoAddress(_amem) 
	
	RegisterCtl = function(newReg)																		-- Register Data Handler.
		stack = rpm(_regdata, 4)
		if stack == 0 then -- Hook not triggered yet, means stack not ready to read.
			return false 
		end
		
		reg = {}
		for r = 0, 13 do -- 13 is LR Register
			regName = (r == "13" and "LR" or "R"..r)
			if newReg ~= nil and newReg[regName] ~= nil then wpm(stack + (r * 4), 4, newReg[regName]) end	-- New register value will be written once opcode restorer function executed.
			reg[regName] = rpm(stack + (r * 4), 4)
		end
		return reg
	end
	
	return RegisterCtl, function() wpm((_amem + 8) + 0x28, 4, 1) _jmpRestore() _amemRestore() end	-- return: Register Data Handler, Opcode Restorer function.
end
function dumpAddress(address, szDump)
  cByte = 0 data = rwmem(address, szDump)
  return 'Address            Hex                       Data\n'..data:gsub('........', function(x)
      bByte = '' sByte = ''
      for _ = 1, #x, 2 do 
        bByte = bByte .. x:sub(_, _ + 1) .. ' '
        sByte = sByte .. string.char(tonumber(x:sub(_, _ + 1), 16)) .. ' '
      end
      dumpHex = string.format('0x%08X', address - cByte) .. ' : ' .. bByte .. ' | ' .. sByte .. '\n'
      cByte = cByte + 4
      return dumpHex
  end
  )
end
function insideOfLib(address)
	notify('Searching for cross-references ')
	_ = rpm(address, gg.TYPE_DWORD)
	if rpm(_, gg.TYPE_DWORD) ~= 0 then
		__ = insideOfLib(_)
		return sf('(Ptr)0x%08X %s', address, (__ ~= '' and '-> '..__ or ''))
	end
	for _, __ in pairs(gg.getRangesList()) do
		notify('Searching for cross-references ')
		if __['type'] == 'r-xp' or __['type'] == 'rwxp' then 
			if  address >= __['start'] and address <= __['end'] then
				return __['name']:match('[^/]+$') .. sf(' + 0x%X', address - __['start'])
			end
		end
	end
	return sf('0x%X', rpm(address, gg.TYPE_DWORD))
end
function getRegisterName(idx)
	return idx == 13 and 'LR' or 'R'..idx
end
function isOpAllowed(opcode)
  for i = 1, #denyOpcode do
    if reverseAddress(opcode & 0xFF000000) == denyOpcode[i] then
      return false
    end
  end
  return true
end
-------------------------------------
-----------== Main Code ==-----------
-------------------------------------

local tInfo = gg.getTargetInfo()
if tInfo == nil and gg.alert("Can't get target information, propably due to Virtual Enviroment, Continue ?", 'Yes', 'No') == 2 then
	quitErr('Cannot proceed due to an "gg.getTargetInfo" error')
elseif tInfo['x64'] then
	quitErr('Only 32-Bit Devices supported !')
end

while true do
	_inputAddress = gg.prompt({[[
▄▀▀ ▄▀▄ ▀ ▄▀▄ ▄▀▄ █▀▄ ▀ ▀▀▀▀█ 
░▀▄ █▀█ █ █▀█ █▀█ █░█ █ ░▄▀▀░
▀▀░ ▀░▀ ▀ ▀░▀ ▀░▀ █▀░ ▀ ▀▀▀▀▀ 
🔬 Regview v1.2 (32-Bit) - Telegram: @apizdev
📒 Note: Make sure 'Hide GameGuardian from the game -> 4' checkbox is off.

🔎 View Register at address (ex. 0x1000000): ]], 'Show Cross References'}, {'0x', true}, {'number', 'checkbox'})
	if _inputAddress then
		_showCf = _inputAddress[2]
		_inputAddress = tonumber(_inputAddress[1])
		if _showCf then 
			toast("By enabling 'Show Cross References', it might drop RegView performance.")
		end
		if _inputAddress and _inputAddress >= 0 then
			 _addrAlignment = _inputAddress % 4
			if _addrAlignment > 0 and gg.alert('Address not properly aligned, fix it ?', 'Yes', 'No') == 1 then
				_inputAddress = _inputAddress - _addrAlignment
			end
			if not isOpAllowed(rpm(_inputAddress, 4)) then
				quitErr('Try another address, can\'t placed hook on PC related opcode.')
			end
			_strAddress = tohex(_inputAddress)
			_registerOp = gg.choice({'Read-Only', 'Read and Write'}, 1, 'Register Operation:')
			_registerOp = (_registerOp == nil and 1 or _registerOp)
			break
		end
		PopupBox('Please try again, address not valid.')
	elseif gg.alert('Do you want to exit RegView ?', 'Yes', 'No') == 1 then
		os.exit()
	end
end

toast("Hooking " .. _inputAddress)
_getReg, _getRegRestore = getRegister(_inputAddress)

-- Hook prepared, wait for shellcode todo our work.
gg.setVisible(false)
while _getReg() == false do 
	if gg.isVisible() and gg.alert("RegView Interrupted:\n- Cancel hook on ".._strAddress.." ?", "Yes", "No") == 1 then 
		toast("Interrupted, Restoring state..") 
		return _getRegRestore()
	end
	gg.setVisible(false) 
	notify('Waiting ' .. _strAddress .. ' get called ') gg.sleep(230)
end

-- Hook triggered, saved regs then restore hook.
toast('Hook triggered, dumping register..')
savedRegs = _getReg()
if _registerOp == 2 then -- Read and Write Register !
	local _regOptText, _regOptVal, _regOptType, _newRegs = {}, {}, {}, {}
	for _regIdx = 0, 13 do
		local regName = getRegisterName(_regIdx)
		local regAddr = savedRegs[regName]
		
		_regOptText[#_regOptText + 1] = (_regIdx == 0 and 'Write New Register:\n\nR0:' or regName)
		_regOptVal[#_regOptVal + 1] = tohex(regAddr)
		_regOptType[#_regOptType + 1] = 'number'
	end
	_regOpt = gg.prompt(_regOptText, _regOptVal, _regOptType)
	for _regIdx = 0, 13 do
		_newRegs[getRegisterName(_regIdx)] = tonumber(_regOpt[_regIdx + 1])
	end
	savedRegs = _getReg(_newRegs)
	toast('New register written !')
end
_getRegRestore()

-- Save data even after quitting RegView
savedList = {}
for _, __ in pairs(savedRegs) do table.insert(savedList, {address = __, name = _, flags = gg.TYPE_DWORD}) end
cText = 'Register at ' .. _strAddress .. tostring(savedRegs)

-- All regs retrieved, now going to UI !
function regHandler(registerValue)
	_ = gg.choice({'🖨️ Dump register', '📋 Copy register', '⤴️ Jump to register'}, nil, _curMenuName .. '\n\n⛓️▫️Options')
	if _ ~= nil then
		if _ == 1 then
			__ = gg.prompt({'📟 Dump Size for '..sf('0x%08X', registerValue)}, {128}, {'number'})
			if __ == nil or tonumber(__[1]) == nil then PopupBox('Invalid dump size !') return end
			___ = tonumber(__[1])
			PopupBox(sf('0x%08X', registerValue)..' Dump: \n',dumpAddress(registerValue, ___)) 
		end
		if _ == 2 then gg.copyText(_curMenuName, false) end
		if _ == 3 then 
			toast('Hide GG to back.')
			gg.gotoAddress(registerValue) 
			while gg.isVisible() do
				gg.sleep(300) 
			end
			toast('Tap GG icon to open Regview.')
		end
	end
end

-- Generate UI !
miscOpt = {{'Miscellaneous'}, {
	"Add all register into saved list", function() gg.addListItems(savedList) end,
	"Copy to clipboard", function() gg.copyText(cText, false) end,
	"Changelog", ShowChangelog
	}
}
local regOpt = {}
for _optIdx = 0, 13 do
	local _regName = getRegisterName(_optIdx)
	regOpt[#regOpt + 1] = _regName .. '    |  ' .. sf('0x%08X : %s', savedRegs[_regName], (_showCf and insideOfLib(savedRegs[_regName]) or '?'))
	regOpt[#regOpt + 1] = function() regHandler(savedRegs[_regName]) end
end
regOpt[#regOpt + 1] = 'Miscellaneous'
regOpt[#regOpt + 1] = miscOpt

gg.setVisible(true)
initMenu({{'🔬 Regview v1.2 | '.._strAddress.." Register: ", false}, regOpt})





























