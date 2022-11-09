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

function scanRemoteBattServers(batBuffers, srvBattCfg)
    if #srvBattCfg == 0 then
        return batBuffers
    end

    local receivedData = ""
    for i = 1, #srvBattCfg do
        modem.send(srvBattCfg[i].address, listenedPort, "data")
        local _, _, _, _, _, message = event.pull(1, "modem_message")

        if message ~= nil then
            receivedData = receivedData .. message
        end
    end

    local additional = unserializeBattareis(receivedData)
    for i = 1, #additional do
        batBuffers[#batBuffers + 1] = additional[i]
    end

    return batBuffers
end
