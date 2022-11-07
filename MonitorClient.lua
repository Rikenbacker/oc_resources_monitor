-- Программа мониторинга состояний GT многоблоков и одноблочных батбуфферов
-- Для работы нужны следующие файлы:
 
-- controllers.cfg Описание контроллеров следующего формата:
-- f997ac1c|Clean room|true|false
-- e12ab34d|EBF|true|true
-- где первое поле - первая часть гуида контроллера, второе его наименование для отображения в случае ошибки, третье - флаг необходимости следить за включением многоблока, четвёртое - флаг необходимости выключения питания в случае если батарейка имеет ниже 10% заряда
-- Если файла controllers.cfg нет, то многоблоки не отслеживаются
 
-- servers.cfg Описание серверов формат не помню.
-- гуиды серверов которые могут слать доп.информацию о контроллерах и батарейках. Полный гуид должен быть, например ac08a71d-b851-4d46-8332-83ce1a979526
-- файл может отсутствовать если серверов нет
 
-- batbuffers.cfg Описание батбуфферов. Формат простейший: первая часть гуида для каждого батбуффера в отдельной строке
-- b86695c1
-- 12345678
 
-- Все батбуфферы и контроллеры должны быть присоеденины через адаптеры (с MFU если нужно).
-- Минимально возможный монитор второго тира.
 
batAlarmModeRed = 0
batAlarmModeYellow = 1
batAlarmModeGreen = 2
 
function getGomponent(tab, element)
    for address, componentType in tab.list() do
        if componentType == element then
            return tab.getPrimary(element)
        end
    end
 
    return nil
end
 
function reactBatAlarm(nowAlarm, newAlarm, controllers)
    if (nowAlarm == newAlarm) then
        return newAlarm
    end
 
    local controllersToSwitch = {}
 
    for i = 1, #controllers do
        if (controllers[i].disableByPower == true) then
            controllersToSwitch[#controllersToSwitch + 1] = controllers[i].key
        end
    end
 
    if (#controllersToSwitch == 0) then
        return newAlarm
    end
 
    local workMode = true
    if (newAlarm == batAlarmModeRed) then
        workMode = false
    end
    if (newAlarm == batAlarmModeGreen) then
        workMode = true
    end
    if (newAlarm == batAlarmModeYellow) then
        return newAlarm
    end
 
    for i = 1, #controllersToSwitch do
        local machine = comp.proxy(comp.get(controllersToSwitch[i]))
        machine.setWorkAllowed(workMode)
    end
 
    return newAlarm
end
 
comp = require("component")
screen = require("term")
event = require("event")
GPU1 = getGomponent(comp, "gpu")
modem = getGomponent(comp, "modem")
 
controllersFile = "config\\controllers.cfg"
batBuffersFile = "config\\batbuffers.cfg"
serversFile = "config\\servers.cfg"
 
screenWidth = 80
screenHeight = 25 --40
listenedPort = 5556
 
dofile("ServersConfig.lua")
dofile("ControllerConfig.lua")
dofile("BatBuffersConfig.lua")
dofile("ControllerData.lua")
dofile("BatBuffersData.lua")
dofile("Graphics.lua")
dofile("ServersData.lua")
 
cfg = readControllersConfig()
batCfg = readBatBuffersConfig()
srvCfg = readServersConfig()
 
battAlarm = batAlarmModeGreen
 
if modem~=nil then
    modem.open(listenedPort)
end
 
GPU1.setResolution(screenWidth, screenHeight)   
 
while (true) do
    local controllers = scanControllers(cfg)
    if srvCfg~=nil then
        controllers = scanRemoteServers(controllers, srvCfg)
    end
    local batBuffers = scanBatBuffers(batCfg)
    local tmpAlarm = getBatAlarm(batBuffers)
    battAlarm = reactBatAlarm(battAlarm, tmpAlarm, cfg)
 
    writeGUI(controllers, batBuffers, battAlarm)
 
    os.sleep(0.1)
    if event.pull(.5, "interrupted") then
        screen.clear()
        GPU1.setResolution(160, 50) 
        break
    end
end
