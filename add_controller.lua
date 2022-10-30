comp = require("component")

controllersFile = "config\\controllers.cfg"

dofile("ControllerConfig.lua")
dofile("ControllerData.lua")

local controllers = readControllersConfig()

function checkID(id)
	for i = 1, #controllers do
		if controllers[i].key == id then
			return true
		end
	end

    return false
end

function addController(id)
	print(id, " не найден в конфиге. Добавить? (Y/n)")

    local answer = io.read("*l")
    if (answer ~= "Y" and answer ~= "y") then
		return
	end

    print("Как назвать?")
	local name = io.read("*l")
	print("Нужно следить за его готовностью к работе? (Y/n)")
	answer = io.read("*l")
	local needEnabled = "true"
	if (answer ~= "Y" and answer ~= "y") then
		needEnabled = "false"
	end
	print("Вырубать если заряд хранилища питания ниже 10%? (Y/n)")
	answer = io.read("*l")
	local disableByPower = "false"
	if (answer == "Y" or answer == "y") then
		disableByPower = "true"
	end       

    local content = id .. "|" .. name .. "|" .. needEnabled .. "|" .. disableByPower .. "\n"
	local f = io.open(controllersFile, "a")
	f:write(content)
	f:close()
end

cfg = readControllersConfig()

for k, v in comp.list() do
	if v == "gt_machine" then
		local id = string.sub(k, 1, 8)
		if not checkID(id) then
			addController(id)
		end
	end
end
