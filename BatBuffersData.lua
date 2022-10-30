BatBuffersData = {}

function BatBuffersData:new(stored, max, averageIn, averageOut)
    -- свойства
    local obj= {}
        obj.stored = stored
		obj.max = max
        obj.averageIn = averageIn
		obj.averageOut = averageOut

    --чистая магия!
    setmetatable(obj, self)
    self.__index = self; return obj
end

function scanBatBuffers(batBuffersConfigArray)
	local buffers = {}

    for i = 1, #batBuffersConfigArray do
	    local machine = comp.proxy(comp.get(batBuffersConfigArray[i].key))
		local stored = 0
		local max = 0
		local averageIn = 0
		local averageOut = 0
		
		for i = 1, #machine.getSensorInformation() do
            if string.match(machine.getSensorInformation()[i], "Stored Items:") then
                local str = string.match(machine.getSensorInformation()[i + 1], "§a([0-9,%s]+)§r")
                str, _ = string.gsub(str, ",", "")
                str, _ = string.gsub(str, " ", "")
                stored = tonumber(str)

                local str = string.match(machine.getSensorInformation()[i + 1], "§e([0-9,%s]+)§r")
                str, _ = string.gsub(str, ",", "")
                str, _ = string.gsub(str, " ", "")
                max = tonumber(str)
             end

            if string.match(machine.getSensorInformation()[i], "^Average input:") then
                local str = string.match(machine.getSensorInformation()[i + 1], "^([0-9,%s]+)")
                str, _ = string.gsub(str, ",", "")
                str, _ = string.gsub(str, " ", "")
                averageIn = tonumber(str)
             end

            if string.match(machine.getSensorInformation()[i], "^Average output:") then
                local str = string.match(machine.getSensorInformation()[i + 1], "^([0-9,%s]+)")
                str, _ = string.gsub(str, ",", "")
                str, _ = string.gsub(str, " ", "")
                averageOut = tonumber(str)
             end
        end
		
		buffers[#buffers + 1] = BatBuffersData:new(stored, max, averageIn, averageOut)
    end
	
	return buffers
end

function getBatAlarm(buffers)
    local stored = 0
    local max = 0
	local mode

    for i = 1, #buffers do
        stored = stored + buffers[i].stored
        max = max + buffers[i].max
    end
  
    if (stored < (max / 10)) then
        return batAlarmModeRed
    else
        if (stored < (max / 2)) then
            return batAlarmModeYellow
        end
    end

	return batAlarmModeGreen
end
