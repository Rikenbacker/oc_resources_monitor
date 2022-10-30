comp = require("component")
screen = require("term")
computer = require("computer")
event = require("event")
GPU1 = comp.gpu
sides = require("sides")
rs = comp.redstone
me_interface = comp.me_interface
gtBattBuf = comp.gt_batterybuffer
gtMachine = comp.gt_machine
--Конфиг
screenWidth = 160
screenHeight = 50
borderColor = 0x1A1A1A
backgroundColor = 0x0D0D0D
progressBarColor = 0x00CC00
errorColor = 0xCC0000
workingColor = 0x00FF00
idleColor = 0xFFFF00
textColor = 0xFFFFFF
maxEUColor = 0xFFE800
currentEUColor = 0x2592E7
positiveEUColor = 0x00CC00
negativeEUColor = 0xCC0000
euUpdateInterval = 3

GPU1.setResolution(screenWidth, screenHeight)
firstRead, lastRead, counter, currentIO = 0, 0, 1, 1
readings = {}
machines = {}
fluidNames = {}
fluids = {}

--=========== Утилиты

-- Формат: Час Минута Секунда
function time(number)
    local formattedTime = {}
    formattedTime[1] = math.floor(number / 3600); formattedTime[2] = "h "
    formattedTime[3] = math.floor((number - formattedTime[1] * 3600) / 60); formattedTime[4] = "min "
    formattedTime[5] = number % 60; formattedTime[6] = "s"
    return table.concat(formattedTime, "")
end

-- Формат чисел XXX,XXX,XXX
function splitNumber(number)
    local formattedNumber = {}
    local string = tostring(math.abs(number))
    local sign = number / math.abs(number)
    for i = 1, #string do
        n = string:sub(i, i)
        formattedNumber[i] = n
        if ((#string - i) % 3 == 0) and (#string - i > 0) then
            formattedNumber[i] = formattedNumber[i] .. ","
        end
    end
    if (sign < 0) then table.insert(formattedNumber, 1, "-")
    end
    return table.concat(formattedNumber, "")
end

-- Формат: процентраж (%)
function getPercent(number)
    percent = {}
    percent[1] = math.floor(number * 1000) / 10
    percent[2] = "%"
    return table.concat(percent, " ")
end

-- Прогресс текст
function progressText(current, max)
    formattedProgress = {}
    formattedProgress[1] = current
    formattedProgress[2] = max
    return table.concat(formattedProgress, "/")
end

-- Вывод боксов
function box(x, y, w, h, color)
    local oldColor = GPU1.setBackground(color)
    GPU1.fill(x, y, w, h, " ")
    GPU1.setBackground(oldColor)
end

-- Вывод текста
function write(x, y, text, color)
    color = color or textColor
    screen.setCursor(x, y)
    oldColor = GPU1.setForeground(color)
    screen.write(text)
    GPU1.setForeground(oldColor)
end

function updateEU(pss)
    if counter == 1 then firstRead = computer.uptime()
    end
    if counter < euUpdateInterval then
        readings[counter] = pss.getEUStored(); counter = counter + 1
    end
    if counter == euUpdateInterval then
        lastRead = computer.uptime()
        ticks = math.ceil((lastRead - firstRead) * 20)
        currentIO = string.gsub(pss.getSensorInformation()[6], "([^0-9]+)", "") - string.gsub(pss.getSensorInformation()[8], "([^0-9]+)", "")
        counter = 1
    end
end

-- Регистрация Мультиблоков
function gtMachine(x, y, address, label)
    machine = comp.proxy(comp.get(address))

    maintenanceIndex = 0
    if machines[label] == nil then
        machines[label] = machine
        box(x, y, 4, 3, borderColor)
        box(x + 4, y, 19, 3, backgroundColor)
        write(x + 5, y, label, textColor)
    end

    box(x + 4, y + 1, 19, 2, backgroundColor)
    box(x + 5 + #label, y, 23 - #label - 5, 1, backgroundColor)
    for i = 1, #machine.getSensorInformation() do
        if string.match(machine.getSensorInformation()[i], "Problems") then
            maintenanceIndex = i
        end
    end
    if (machine.hasWork()) then
        GPU1.setBackground(backgroundColor)
        box(x + 1, y + 1, 2, 1, workingColor)
        box(x + 5, y + 1, math.floor(18 * (machine.getWorkProgress() / machine.getWorkMaxProgress())), 1, progressBarColor)
        local progressString = progressText(math.floor(machine.getWorkProgress() / 20), math.floor(machine.getWorkMaxProgress() / 20)) .. "s"
        write(x + 23 - #progressString, y, progressString)
    else
        box(x + 1, y + 1, 2, 1, idleColor)
    end
    GPU1.setBackground(backgroundColor)
    if (maintenanceIndex == 0 or string.match(machine.getSensorInformation()[maintenanceIndex], "c0")) and machine.isWorkAllowed() then
        --Do nothing
    else
        if (machine.isWorkAllowed()) then
            box(x + 1, y + 1, 2, 1, idleColor)
            write(x + 5, y + 2, "Needs maintenance!", errorColor)
        else
            box(x + 1, y + 1, 2, 1, errorColor)
            write(x + 5, y + 2, "Machine disabled!", errorColor)
        end
    end
end

--Регистрация БатБуферов
function substation(x, y, width, heigth)
    local pss = gtBattBuf
    updateEU(pss)
    width = width or screenWidth - 2 * x; heigth = heigth or 4
    GPU1.setBackground(0x000000)
    local currentEU = string.gsub(pss.getSensorInformation()[3], "([^0-9]+)", "")
    local maxEU = string.gsub(pss.getSensorInformation()[4], "([^0-9]+)", "")
    local progress = (width - 2) * (currentEU / maxEU)
    box(x, y, width, heigth, borderColor)
    box(x + 1 + progress, y + 1, width - 1 - progress, heigth - 2, backgroundColor)
    box(x + 1, y + 1, progress, heigth - 2, progressBarColor)
    write(x, y - 1, splitNumber(currentEU), currentEUColor); screen.write(" EU")
    write(x + width - #splitNumber(maxEU) - 3, y - 1, splitNumber(maxEU), maxEUColor); screen.write(" EU")
    box(x + width / 2 - 3, y - 1, 8, 1, 0x000000)
    local percentString = getPercent(progress / (width - 2))
    write(x + width / 2 - #percentString / 2, y - 1, percentString)
    box(x, y + heigth, width, 1, 0x000000)
    if currentIO >= 0 then
        local EUString = "+" .. splitNumber(currentIO)
        write(x + width / 2 - #EUString / 2 - 2, y + heigth, EUString, positiveEUColor); screen.write(" EU/t")
    else
        local EUString = splitNumber(currentIO)
        write(x + width / 2 - #EUString / 2 - 2, y + heigth, EUString, negativeEUColor); screen.write(" EU/t")
    end
    write(x + 18, y + heigth, string.gsub(pss.getSensorInformation()[6], "([^0-9]+)", ""), positiveEUColor); screen.write(" EU/t")
    write(x, y + heigth, "Total Generation:");
    write(x, y + heigth + 1, "Total Cost:");
    write(x + 12, y + heigth + 1, string.gsub(pss.getSensorInformation()[8], "([^0-9]+)", ""), negativeEUColor); screen.write(" EU/t")
    if currentIO > 0 then
        fillTime = math.floor((maxEU - currentEU) / (currentIO * 20))
        fillTimeString = time(math.abs(fillTime))
        write(x + width - #fillTimeString - 6, y + heigth, "Full: " .. fillTimeString)
    elseif currentIO == 0 then
        if currentEU == maxEU then
            write(x + width - 13, y + heigth, "Stable charge")
        else
            write(x + width - 11, y + heigth, "Need charge")
        end
    else
        fillTime = math.floor((currentEU) / (currentIO * 20))
        fillTimeString = time(math.abs(fillTime))
        write(x + width - #fillTimeString - 7, y + heigth, "Empty: " .. fillTimeString)
    end
    if currentEU / maxEU <= 0.08 then
        rs.setOutput(0, 15)
        rs.setOutput(1, 15)
        rs.setOutput(2, 15)
        rs.setOutput(3, 15)
        rs.setOutput(4, 15)
        rs.setOutput(5, 15)
    else if currentEU / maxEU >= 0.98 then
        rs.setOutput(0, 0)
        rs.setOutput(1, 0)
        rs.setOutput(2, 0)
        rs.setOutput(3, 0)
        rs.setOutput(4, 0)
        rs.setOutput(5, 0)
    end
    end
    if rs.getOutput(0) == 0 then
        box(x, y + heigth - 10, 2, 1, 0xff0000)
        GPU1.set(x + 4, y + heigth - 10, "Energy Generation Disable")
    else
        box(x, y + heigth - 10, 2, 1, 0x00ff00)
        GPU1.set(x + 4, y + heigth - 10, "Energy Generation Enable ")
    end
end

local fluidList = me_interface.getFluidsInNetwork()
function fluidslistUpdate()
    fluidList = me_interface.getFluidsInNetwork()
end

-- Регистрация жидкостей
function fluid(name, color, max, x, y)
    local amountFLuid
    local amount
    local abort = true
    for number, fluid in ipairs(fluidList) do
        if fluid.label == name then
            label = fluid.label
            amountFLuid = tonumber(fluid.amount)
            abort = false
            break
        end
    end
    if abort then return end -- Пропустить если нету жижи

    amount = math.floor(amountFLuid / 1000)
    local width = 21
    old = GPU1.setBackground(borderColor)
    if (fluidNames[name] == nil) then
        fluidNames[name] = 1
        box(x, y, width + 2, 3, borderColor)
        write(x + 1, y, label, color)
        write(x + 16, y + 2, "L/1000", color)
    else
    end
    local progress = 0
    if (amount / max > 0.5) then
        progress = math.min(math.ceil((amount / max) * width), width)
    else
        progress = math.min(math.floor((amount / max) * width), width)
    end
    local fillString = tostring(amount) .. "/" .. tostring(max)
    GPU1.setBackground(color)
    if (#fillString <= progress) then
        write(x + 1, y + 1, fillString, backgroundColor)
        box(x + 1 + #fillString, y + 1, progress - #fillString, 1, color)
        box(x + 1 + progress, y + 1, width - progress, 1, backgroundColor)
    else
        write(x + 1, y + 1, fillString:sub(1, progress), backgroundColor)
        GPU1.setBackground(backgroundColor)
        write(x + 1 + progress, y + 1, fillString:sub(progress + 1, #fillString), color)
        box(x + 1 + #fillString, y + 1, width - #fillString, 1, backgroundColor)
    end
    GPU1.setBackground(old)
end

screen.clear()

--[[=================================================================================================================

    ДОБАВЛЕНИЕ СВОИХ КОМПОНЕНТОВ

    Критерии для работы:
    1) Комп тир 3
    2) Мониторы тир 3
    3) GPU тир 3
    4) CPU тир 3

]]

while (true) do

    --[[=================================================================================================================

    Многоблоки
    Как работает отображение машин? Вы подключаетесь адаптером (или адаптером с MFU, если к контролеру нельзя напрямую подключится)
    к контролеру, задаете адресс адаптера в регистрацию и комп выводит инфу


    Как правильно зарегать машины:
    gtMachine(Координата X, Координата Y, Адресс Адаптера (или Адаптера с MFU), Название для вывода)

    Важно! Расположение бокса по координатам между машин должно быть минимум 4 по координате Y

    ]]

    gtMachine(1, 4, "4823a6f2", "Пример")
    --gtMachine(1, 8, "9645a", "Пример2")

    --[[=================================================================================================================
    Батбуфер
    Как работает отображение батбуфера? Вы подключаетесь адаптером к любому батбуферу, комп ищет в сети батбуфер и выдает всю информацию
    Обязательно нужно для подключения Redstone Port (RS Port) из OC, сигнал силой 15 выдается во все стороны

    Как правильно зарегать буфер:
    substation(Координата X, Координата Y, Ширина(x = растянуть по всей ширине), Высота бара)

    ]]

    substation(31, 40, 100, 6)

    --[[=================================================================================================================
    Жижи

    Как работает отображение жидкостей? Вы подключаетесь адаптером к обычному интерфейсу (не жидкостному!), комп сканирует
    жидкости в МЕ, далее жидкость которую вы указали, он выведет на экран, если такой жидоксти нет, то ничего не выведет

    Как правильно зарегать жидкость:
    fluid(Название для вывода, Цвет по HEX, Максимальный размер(не ограничен, но я указываю обычно 256 ведер, чтобы были для вида), Координата X, Координата Y)

    Размеры бокса 21x3

    ]]
    fluidslistUpdate()
    fluid("Nitrogen Gas", 0xe517b3, 256, screenWidth - 21, 4)
    fluid("Oxygen Gas", 0x688790, 256, screenWidth - 21, 8)

    -- Выключить программу ctrl+c
    os.sleep(0.1)
    if event.pull(.5, "interrupted") then
        screen.clear()
        break
    end
end
