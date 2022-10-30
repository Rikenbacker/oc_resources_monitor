--Скрипт для OpenComputers, сканирования карты в поисках руды и создание JourneyMap точек
--Автор программы: slprime лето 2021
local ver = "1.0.6.1" -- версия программы

-- 1. Требования к роботу
-- 1.1. У компьютера в обязательном порядке должны присутствовать компоненты: 
-- 1.1.1. Computer Case (Tier 3). Можно и Tier 2 если есть другой способ грузить чанки
-- 1.1.2. CPU (Tier 2). У первого тира не достаточно портов
-- 1.1.3. Memory (Tier 2). 2 плашки
-- 1.1.4. Hard Disk Drive (Tier 2)
-- 1.1.5. Internet Card. Если играете в single или имеете доступ к серверу, можно обойтись без этой карты, но нужно загрузить ещё и prospector.lua на комп
-- 1.1.6. Screen, Keyboard, EEPROM (Lua BIOS)
-- 1.1.7. Inventory Upgrade. Желательно 2 штуки, чтобы хватило места для динамита
-- 1.1.8. Inventory Controller Upgrade
-- 1.1.9. Hover Upgrade (Tier 2). Можно и первый тир, но нужно быть уверенным, что высота никогда не будет больше 64
-- 1.1.10. Angel Upgrade
-- 1.1.11. Chunkloader Upgrade или обеспечить загрузку чанков другим способом


-- 2. Требование к инвентарю
-- 2.1. Wrench из gregtech
-- 2.2. Yera Wrench из Ender IO
-- 2.3. Любой Pickaxe
-- 2.4. Заряженный Capacitor Bank любого тира из Ender IO. Чем выше тир тем лучше, но тут зависит от территории что сканируется
-- 2.5. Charger из OPenComputers
-- 2.6. Data Stick 1 штука
-- 2.7. Seismic Prospector любого тира
-- 2.8. TNT или Industrial TNT. Другие виды робот не понимает.

-- PS
-- Чтобы установить скрипт вызовите: `pastebin get Ck4VA093 -f scan_veins.lua`
-- Если робот не имеет Internet Card не забудьте установить ещё и prospector.lua (tkr8bayw)
-- `scan_veins <d:number>` - диаметр для сканирования. Говорит сколько раз проставит проспектор. Учтите что диаметр сканирования равна диаметру умноженное на радиус сканирования проспектором
-- Передав -g - робот будет группировать точки по жилам. Это позволяет вам скачать только нужные вам жилы. Как качать только нужные вам точки читайте в scan_veins.lua (Ck4VA093)
-- Передав -p - робот будет сохранять точки где сканировал проспектор
-- Получив -f - робот поднимется на максимально доступную ему высоту, после чего только продолжит работу
-- Робот пишет в файл scan_veins.log свою позицию относительно старта работы. Если потеряли робота можно найти этот файл на сервере или попросить тех кто имеет доступ к серверу и узнать где, предположительно робот застрял
-- Примерная скорость движения робота: 144 блока за 1 минуту
-- Высоту роботу стоит задавать максимальную чтобы ничего не попалось у него на пути
-- Ниже указан путь как ездит робот если будите его искать
-- После завершения работы робот возвращается на место старта

-- 31 30 29 28 27 26 49
-- 32 13 12 11 10 25 48
-- 33 14  3  2  9 24 47
-- 34 15  4  1  8 23 46
-- 35 16  5  6  7 22 45
-- 36 17 18 19 20 21 44
-- 37 38 39 40 41 42 42

-- PS2. Что делать после того как робот закончил работу:
-- 1. Если у вас есть доступ к папке на сервере:
-- 1.1. Зайдите в папку `.minecraft/saves/<world name>/opencomputers/<hdd guid>/home/waypoints/` и скопируйте нужные вам файлы с waypoints. Нужны только файлы, папки в структуре лишние
-- 2. Если у вас нет доступа к серверу - значит вы попали :), но решение всё же есть
-- 2.1. скачайте `pastebin get 0SLuz5zg -f zdir.lua`
-- 2.2. вызовите `zdir ./waypoints/`
-- 2.3. Если скрипт не упадёт с ошибкой - можете приступить к пункту 2.5
-- 2.4. Если скрипт упал у вас есть 2 способа решить проблему:
-- 2.4.1. попробуйте зайти в папку waypoints и заархивировать там каждую папку отдельно
-- 2.4.2. собрать компьютер помощнее. роль играет оперативная память
-- 2.5. скачайте `pastebin get Fzyd2MJy -f clbin.lua`
-- 2.6. вызовите `clbin put <tgz name>`
-- 2.7. В итоге вы получите ссылку на ресурс clbin. Введите её в браузер, после чего архив скачается. Дайте ему расширение `.tgz` и откройте архиватором, а дальше смотрите пункт 1.

local robot = require("robot")
local fs = require("filesystem")
local computer = require("computer")
local component = require("component")
local term = require("term")
local shell = require("shell")
local inventory = component.inventory_controller

local diameter = 3
local currentPosition = 1
local prospectorDiameter = nil
local chackEnergyLevel = true
local worldCoordinates = {a = nil, b = nil, c = nil}
local parking = {
    dir = 'T',
    x = 0,
    y = 0,
    z = 0
}

local filters = {
    air         = function(item) return item.name == 'air' end,
    coal        = function(item) return item.name == 'minecraft:coal' end,
    tnt         = function(item) return (item.name == 'minecraft:tnt' and item.size >= 16) or (item.name == 'IC2:blockITNT' and item.size >= 8) or (item.label ~= nil and (item.label == 'Powderbarrel' or item.label == 'gt.blockreinforced.5.name') and item.size >= 2) end,
    charger     = function(item) return item.name == 'OpenComputers:charger' end,
    battery     = function(item) return item.name == 'EnderIO:blockCapBank' and item.energy ~= 0 end,
    yeta        = function(item) return item.name == 'EnderIO:itemYetaWrench' end,
    stick       = function(item) return item.label ~= nil and (string.lower(item.label) == 'data stick' or item.label == 'gt.metaitem.01.32708.name' or item['Raw Prospection Data']) end,
    wrench      = function(item) return item.name == 'gregtech:gt.metatool.01' end, -- очень ненадёжное сравнение, но как иначе не знаю
    prospector  = function(item) return item.label ~= nil and (string.find(string.lower(item.label), 'seismic prospector') or string.find(string.lower(item.label), 'gt.blockmachines.basicmachine.seismicprospector.')) end,
    pickaxe     = function(item) return item.label ~= nil and string.find(string.lower(item.label), 'pickaxe') and item.damage ~= item.maxDamage end,
}

function getEnergyLevel()
    return math.floor(computer.energy() * 100 / computer.maxEnergy())
end

function swingDown()
    local index = 1

    while index < 15 and robot.detectDown() do

        if index > 1 then os.sleep(0.5) end

        if robot.swingDown() == false then
            return false
        end

        index = index + 1
    end

    return index < 15
end

function collectBattery()
    local pickaxe = findStackInInternalSlot(filters.pickaxe)

    robot.select(pickaxe)

    inventory.equip()

    swingDown()
    robot.down()
    swingDown()

    -- убрать кирку
    robot.select(findStackInInternalSlot(filters.air))
    inventory.equip()

end

function checkRobotEnergy()
 
    if getEnergyLevel() < 30 then
        local energyLevel = getEnergyLevel()
        logger.push("Идёт зарядка\n")

        if not findStackInInternalSlot(filters.pickaxe) then return false end

        local charger = findStackInInternalSlot(filters.charger)
        local batteryIndex, battery = findStackInInternalSlot(filters.battery)
        local yeta = findStackInInternalSlot(filters.yeta)

        if not charger then
            logger.push("Не было найдено зарядника")
            return false
        end

        if not batteryIndex then
            logger.push("Не было найдено батареи с зарядом")
            return false
        end
        
        if not yeta then
            logger.push("Не было найдено ключа yeta")
            return false
        end

        --устанавливаем батарею
        robot.select(batteryIndex)
        robot.placeDown()

        robot.up()

        -- устанавливаем зарядник
        robot.select(charger)
        robot.placeDown()

        -- включаем зарядку
        robot.select(yeta)
        inventory.equip()
        robot.useDown(2, true)

        -- убрать ключ
        robot.select(findStackInInternalSlot(filters.air))
        inventory.equip()

        while energyLevel < 95 do

            os.sleep(3)

            if getEnergyLevel() <= energyLevel then 
                collectBattery()
                return checkRobotEnergy() 
            end
 
            energyLevel = getEnergyLevel()
        end
 
        collectBattery()
    end
 
    return true
end

function worldPosition()
    local a, b, c = worldCoordinates.a, worldCoordinates.b, worldCoordinates.c
    local worldX, worldZ = nil, nil

    if a and b then

        if a.x == b.x then
            worldZ = a.z + robotXYZD.y * (a.z < b.z and 1 or -1) 
        else
            worldX = a.x + robotXYZD.y * (a.x < b.x and 1 or -1) 
        end

    end

    if b and c then

        if b.x == c.x then
            worldZ = a.z + robotXYZD.x * (b.z < c.z and -1 or 1) 
        else
            worldX = a.x + robotXYZD.x * (b.x < c.x and -1 or 1) 
        end

    end

    return {x = worldX, z = worldZ}
end

function logPosition()
    local size = math.floor(diameter * diameter)
    local file = io.open("/home/scan_veins.log", "w")

    file:write("P: "..currentPosition.." / "..size.."\n")

    local pos = worldPosition()

    if pos.x then
        file:write("World X: "..(pos.x).."\n")
    else
        file:write("World X: ?\n")
    end

    if pos.z then
        file:write("World Z: "..(pos.z).."\n")
    else
        file:write("World Z: ?\n")
    end

    file:write("X: "..robotXYZD.x.."\n")
    file:write("Y: "..robotXYZD.y.."\n")

    file:write("Time: "..calculateTime().."\n")

    file:close()

    logger.refresh()
end

function calculateTime()
    local time = (diameter * diameter + 2 - currentPosition) * (43 + (prospectorDiameter / 2.3))
    local h, m, s = 0, 0, 0
    local str = ''

    time = time - (robotXYZD.x - math.floor(robotXYZD.x / prospectorDiameter) * prospectorDiameter) / 2.3
    time = time - (robotXYZD.y - math.floor(robotXYZD.y / prospectorDiameter) * prospectorDiameter) / 2.3

    h = math.floor(time / 60 / 60)
    m = math.floor((time - h * 60 * 60) / 60)
    s = math.floor(time - h * 60 * 60 - m * 60)

    if h > 0 then
        str = h.. ' ч. '
    end
    
    if m > 0 then
        str = str..m.. ' мин. '
    end
    
    if s > 0 then
        str = str..s.. ' сек. '
    end

    return str
end 

---------------------- logger ----------------------
 
logger = {
    width = 50,
    height = 16,
    lines = {},
  
    push = function(msg)
 
        if logger.lines[logger.height - 7] ~= nil then
            local lines = {}
 
            for i = 2, logger.height - 7 do
                if logger.lines[i] ~= nil then
                    table.insert(lines, logger.lines[i])
                end
            end
 
            logger.lines = lines
        end
 
        if utf8.len(msg) >= logger.width then
            msg = string.sub(msg, 1, utf8.offset(msg, logger.width - 3) - 1) .. "..."
        end
 
        if logger.lines[#logger.lines] ~= msg then
            table.insert(logger.lines, msg)
        end
 
        logger.refresh()
    end,

    replace = function(msg)

        if utf8.len(msg) >= logger.width then
            msg = string.sub(msg, 1, utf8.offset(msg, logger.width - 3) - 1) .. "..."
        end

        logger.lines[#logger.lines] = msg
 
        logger.refresh()
    end,
 
    dump = function(o)
 
        if type(o) == 'table' then
            local s = '{ '
    
            for k, v in pairs(o) do
    
                if type(k) ~= 'number' then 
                    k = '"'..k..'"' 
                end
    
                s = s .. '['..k..'] = ' .. logger.dump(v) .. ', '
            end
    
            return s .. '} '
        else
            return tostring(o)
        end
 
    end,
 
    refresh = function()
        term.clear()
        term.write("Cканирования карты в поисках руды\n")
        term.write("Версия: "..ver.."\n")

        if prospectorDiameter then
            term.write("Prospection area: "..prospectorDiameter.."x"..prospectorDiameter.." ("..(prospectorDiameter * diameter).."x"..(prospectorDiameter * diameter)..")\n")
            term.write('Примерное время работы: '..calculateTime().."\n")
        else
            term.write("Prospection area: -\n")
            term.write("Примерное время работы: -\n")
        end

        local pos = worldPosition()

        term.write('Мировые координаты: X='..(pos.x or '?').." Z="..(pos.z or '?').."\n")

        term.write('Относительные координаты: X='..robotXYZD.x.." Y="..robotXYZD.y.."\n")

        for i = 1, #logger.lines do
            term.write("\n"..logger.lines[i])
        end
 
    end
 
}
 
logger.width, logger.height = term.getViewport()

---------------------- movements -------------------

robotXYZD = {
    dir = parking.dir, 
    x = parking.x,
    y = parking.y,
 
    XYZDFromPosition = function(pos, z)
        local r, p, m, x, y, o1, o2 = 1, nil, nil, 0, 0, nil, nil

        if pos > 1 then

            while pos > r * r do
                r = r + 2
            end
        
            o1, o2 = pos - (r - 2) * (r - 2), r - 1
        
            p = math.ceil(o1 / o2)
            m = o1 - math.floor(o1 / o2) * o2
            if m == 0 then m = o2 end
        
            if p == 1 then
                y = math.floor(r / 2)
                x = -math.floor(r / 2) + r - m - 1
            elseif p == 2 then
                y = -math.floor(r / 2) + r - m - 1
                x = -math.floor(r / 2)
            elseif p == 3 then
                x = math.floor(r / 2) - r + m + 1
                y = -math.floor(r / 2)
            else
                y = math.floor(r / 2) - r + m + 1
                x = math.floor(r / 2)
            end

        end

        return {
            x = x * prospectorDiameter,
            y = y * prospectorDiameter,
            z = z or 0
        }

    end,
 
    rotate = function(dir)
 
        if (
            (robotXYZD.dir == "T" and dir == "B") or 
            (robotXYZD.dir == "B" and dir == "T") or 
            (robotXYZD.dir == "L" and dir == "R") or 
            (robotXYZD.dir == "R" and dir == "L")
        ) then
            robot.turnAround()
        elseif (
            (robotXYZD.dir == "L" and dir == "T") or 
            (robotXYZD.dir == "T" and dir == "R") or 
            (robotXYZD.dir == "R" and dir == "B") or 
            (robotXYZD.dir == "B" and dir == "L")
        ) then
            robot.turnRight()
        elseif (
            (robotXYZD.dir == "L" and dir == "B") or 
            (robotXYZD.dir == "B" and dir == "R") or 
            (robotXYZD.dir == "R" and dir == "T") or 
            (robotXYZD.dir == "T" and dir == "L")
        ) then
            robot.turnLeft()
        end
        
        robotXYZD.dir = dir
    end,

    jumpX = function(step)
		local y = robotXYZD.y
		local x = robotXYZD.x
		local dir = robotXYZD.dir

		if not robotXYZD.moveY(y + 1) then
			robotXYZD.moveY(y - 1)
		end

		robotXYZD.moveX(x + step * 2)
		robotXYZD.moveY(y)
		robotXYZD.rotate(dir)
	end,

	jumpY = function(step)
		local y = robotXYZD.y
		local x = robotXYZD.x
		local dir = robotXYZD.dir

		if not robotXYZD.moveX(x + 1) then
			robotXYZD.moveX(x - 1)
		end

		robotXYZD.moveY(y + step * 2)
		robotXYZD.moveX(x)
		robotXYZD.rotate(dir)
	end,
 
    moveX = function(targetX)
        if robotXYZD.x == targetX then return true end
        local dir = nil
 
        if robotXYZD.x > targetX then
            robotXYZD.rotate('L')
            dir = -1
        elseif robotXYZD.x < targetX then
            robotXYZD.rotate('R')
            dir = 1
        end
 
        while robotXYZD.x ~= targetX do
            local success, err = robot.forward()
 
            if success then
                robotXYZD.x = robotXYZD.x + dir
            elseif err == 'entity' then
                logger.push("Отойдите пожалуйста!\n")
                computer.beep(1000, 0.3)
                os.sleep(1) -- останавливаем робота на 1 секунду
            elseif err == 'impossible move' then
                error("Слишком высоко. Я боюсь летать так высоко!")
            elseif err == 'already moving' then
                logger.push("Привет TPS!")
                os.sleep(0.5) -- останавливаем робота на 1 секунду
 			else
                logger.push("moveX err:"..err)
                
                if robotXYZD.x + dir ~= targetX then
                    robotXYZD.jumpX(dir)
                else
                    break
                end
            end

            logPosition()

            if chackEnergyLevel and not checkRobotEnergy() then
                chackEnergyLevel = false
                goHome()
                error('Закончилась энергия')
            end
            
        end
 
        return robotXYZD.x == targetX
    end,
 
    moveY = function(targetY)
        if robotXYZD.y == targetY then return true end
        local dir = nil
 
        if robotXYZD.y > targetY then
            robotXYZD.rotate('B')
            dir = -1
        elseif robotXYZD.y < targetY then
            robotXYZD.rotate('T')
            dir = 1
        end
 
        while robotXYZD.y ~= targetY do
            local success, err = robot.forward()
 
            if success then
                robotXYZD.y = robotXYZD.y + dir
            elseif err == 'entity' then
                logger.push("Отойдите пожалуйста!\n")
                computer.beep(1000, 0.3)
                os.sleep(1) -- останавливаем робота на 1 секунду
            elseif err == 'impossible move' then
                error("Слишком высоко. Я боюсь летать так высоко!")
            elseif err == 'already moving' then
                logger.push("Привет TPS!")
                os.sleep(0.5) -- останавливаем робота на 1 секунду
            else
                logger.push("moveY err:"..err)
                
                if robotXYZD.y + dir ~= targetY then
                    robotXYZD.jumpY(dir)
                else
                    break
                end
            end

            logPosition()

            if chackEnergyLevel and not checkRobotEnergy() then
                chackEnergyLevel = false
                goHome()
                error('Закончилась энергия')
            end

        end
 
        return robotXYZD.y == targetY
    end,

    go = function(xyzd)

		while (true) do
			local x = robotXYZD.x
			local y = robotXYZD.y

			if robotXYZD.x ~= xyzd.x then
				robotXYZD.moveX(xyzd.x)
			end
	
			if robotXYZD.y ~= xyzd.y then
				robotXYZD.moveY(xyzd.y)
			end

			if robotXYZD.x == x and robotXYZD.y == y then
				break
			end

		end

		if xyzd.dir ~= nil and robotXYZD.dir ~= xyzd.dir then
			robotXYZD.rotate(xyzd.dir)
		end
	
		return robotXYZD.x == xyzd.x and robotXYZD.y == xyzd.y
	end
 
}

if not fs.exists(shell.getWorkingDirectory().."/prospector.lua") then
    os.execute("pastebin get tkr8bayw prospector.lua")
end

function findStackInInternalSlot(filter)

    for slotIndex = 1, robot.inventorySize() do
        local item = inventory.getStackInInternalSlot(slotIndex) or ({ name = 'air', size = 0 })

        if filter(item) then
            return slotIndex, item
        end

    end
    
    return nil
end

function getTNTCount()
    local tntCount = 0

    for slotIndex = 1, robot.inventorySize() do
        local item = inventory.getStackInInternalSlot(slotIndex) or ({ name = 'air', size = 0 })

        if filters.tnt(item) then

            if item.name == 'minecraft:tnt' then
                tntCount = tntCount + math.floor(item.size / 16)
            elseif item.name == 'IC2:blockITNT' then
                tntCount = tntCount + math.floor(item.size / 8)
            else
                tntCount = tntCount + math.floor(item.size / 2)
            end

        end

    end

    return tntCount
end

local function parsePosition(value)
    local n = string.find(value, "\n")
    local x = string.find(value, "X")
    local y = string.find(value, "Y")
    local z = string.find(value, "Z")
 
    return {
        dim = tonumber(string.sub(value, 5, n)),
        x = tonumber(string.sub(value, x + 3, y - 1)),
        y = tonumber(string.sub(value, y + 3, z - 1)),
        z = tonumber(string.sub(value, z + 3)),
    }
 
end

function prospect()
    local tnt = findStackInInternalSlot(filters.tnt)
    local stick, stickItem = findStackInInternalSlot(filters.stick)
    local wrench = findStackInInternalSlot(filters.wrench)

    -- установить проспектор
    robot.select(findStackInInternalSlot(filters.prospector))
    robot.placeDown()
    os.sleep(1)

    -- применить динамит
    robot.select(tnt)

    inventory.equip()
    while robot.useDown() == false do os.sleep(1) end
    inventory.equip()

    -- прочесть данные с проспектора
    robot.select(stick)
    inventory.equip()
    os.sleep(40)

    while robot.useDown() == false do os.sleep(1) end

    inventory.equip()

    -- снять проспектор
    robot.select(wrench)

    inventory.equip()
    swingDown()

    -- убрать ключ
    robot.select(findStackInInternalSlot(filters.air))
    inventory.equip()
end

function goUp()
    local success, err = robot.up()
 
    while success do
        parking.z = parking.z + 1
        success, err = robot.up()
    end
end

function goHome()
    robotXYZD.go(parking)

    while parking.z > 1 do
        parking.z = parking.z - 1
        success, err = robot.down()
    end
end

function main(...)
    logger.refresh()

    
    logger.push("Проспектор: ")
    if findStackInInternalSlot(filters.prospector) then
        logger.replace("Проспектор: Есть")
    else
        error('Не найден проспектор')
    end

    logger.push("Gregtech Ключ: ")
    if findStackInInternalSlot(filters.wrench) then
        logger.replace("Gregtech Ключ: Есть")
    else
        error('Не найден ключ')
    end

    logger.push("Флэшка: ")
    if findStackInInternalSlot(filters.stick) then
        logger.replace("Флэшка: Есть")
    else
        error('Не найден data stick')
    end

    logger.push("Взрывчатка: ")
    if findStackInInternalSlot(filters.tnt) then
        logger.replace("Взрывчатка: Есть")
    else
        error('Не найдена взрывчатка')
    end

    logger.push("Yeta ключ: ")
    if findStackInInternalSlot(filters.yeta) then
        logger.replace("Yeta ключ: Есть")
    else
        logger.replace("Yeta ключ: Нет")
    end

    logger.push("Кирка: ")
    if findStackInInternalSlot(filters.pickaxe) then
        logger.replace("Кирка: Есть")
    else
        logger.replace("Кирка: Нет")
    end

    logger.push("Зарядник: ")
    if findStackInInternalSlot(filters.charger) then
        logger.replace("Зарядник: Есть")
    else
        logger.replace("Зарядник: Нет")
    end

    logger.push("Ender IO Батарея: ")
    if findStackInInternalSlot(filters.battery) then
        logger.replace("Ender IO Батарея: Есть")
    else
        logger.replace("Ender IO Батарея: Нет")
    end

    --------------------------------
    local args, options = shell.parse(...)
    local exec = "prospector -a"

    if options.g then exec = exec..'g' end
    if options.p then exec = exec..'p' end
     
    diameter = tonumber(args[1]) or 3

    if (diameter - math.floor(diameter / 2) * 2) == 0 then
        error('Диаметр должен быть нечётным числом')
    end
    --------------------------------

    if getTNTCount() < diameter * diameter then
        error('Слишком мало динамита')
    end

    if options.f then 
        goUp()
    end

    prospect()

    --------------------------------
    local _, stick = findStackInInternalSlot(filters.stick)

    if stick and stick["Raw Prospection Data"] then
        worldCoordinates.a = parsePosition(stick["Raw Prospection Data"].prospection_pos)
        prospectorDiameter = math.floor(stick["Raw Prospection Data"].prospection_radius * 2)
    else
        error('Не смог прочесть data stick')
    end

    --------------------------------
    if not prospectorDiameter then
        error('Не смог определить Prospection area')
    end
    --------------------------------

    logger.refresh()

    --удалить папку с точками
    os.remove(fs.concat(shell.getWorkingDirectory(), 'waypoints/'))
    os.remove(fs.concat(shell.getWorkingDirectory(), 'waypoints.tgz'))

    logPosition()

    if os.execute(exec) == false then
        goHome()
        error('Что-то произошло с проспектором!')
    end

    logger.push("Приступаем к работе:")

    --------------------------------
    for pos = 2, diameter * diameter do
        currentPosition = pos

        if not checkRobotEnergy() then
            chackEnergyLevel = false
            goHome()
            error('Закончилась энергия')
        end
        
        logger.push("Едим на точку "..pos)
        if robotXYZD.go(robotXYZD.XYZDFromPosition(pos)) then
            logger.push("Проспектим...")
            prospect()

            if pos == 2 then
                local _, stick = findStackInInternalSlot(filters.stick)

                if stick and stick["Raw Prospection Data"] then
                    worldCoordinates.b = parsePosition(stick["Raw Prospection Data"].prospection_pos)
                end

            elseif pos == 3 then
                local _, stick = findStackInInternalSlot(filters.stick)

                if stick and stick["Raw Prospection Data"] then
                    worldCoordinates.c = parsePosition(stick["Raw Prospection Data"].prospection_pos)
                end

            end

            if os.execute(exec) == false then
                goHome()
                error('Что-то произошло с проспектором!')
            end

        end

    end

    goHome()

end

local function errorFormatter(msg)
    msg = msg:gsub("^[^%:]+%:[^%:]+%: ","")
 
    return { msg, debug.traceback(msg, 3) }
end
 
local ok, msg = xpcall(main, errorFormatter, ...)
 
if not ok and msg then
    logger.push(msg[1])
 
    local file = io.open("/home/scan_veins.log", "a")
    file:write(msg[2].."\n")
    file:close()
 
    computer.beep(1000,0.3)
    computer.beep(1000,0.3)
    computer.beep(1000,0.3)
 
    os.sleep(10)
    computer.shutdown()
end
 
return ok, msg
