function scanRemoteServers(controllers, srvCfg)
    if #srvCfg == 0 then
        return controllers
    end

    local receivedData = ""
    for i = 1, #srvCfg do
        modem.send(srvCfg[i].address, listenedPort, "data")
        local _, _, _, _, _, message = event.pull(1, "modem_message")
        if message ~= nil then
            receivedData = receivedData .. message
        end
    end

    local additional = unserializeControllers(receivedData)
    for i = 1, #additional do
        controllers[#controllers + 1] = additional[i]
    end

    return controllers
end
