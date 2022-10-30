comp = require("component")
screen = require("term")
event = require("event")
GPU1 = comp.gpu

for k, v in comp.list() do
print(k, v)
end

controllersFile = "controllers.cfg"

dofile("ControllerConfig.lua")
dofile("ControllerData.lua")

cfg = readControllersConfig()

local controllers = scanControllers(cfg)

for i = 1, #controllers do
    print(controllers[i].name, "", controllers[i].needMaintaince, controllers[i].isEnabled, controllers[i].needEnabled)
end

for i = 1, #cfg do
    print(cfg[i].key)
    local machine = comp.proxy(comp.get(cfg[i].key))
    for j = 1, #machine.getSensorInformation() do
        print(machine.getSensorInformation()[j])
    end
    print(" ")
end
