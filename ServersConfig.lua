ServersConfig = {}
 
function ServersConfig:new(address)
    -- свойства
    local obj= {}
    obj.address = address
 
    --чистая магия!
    setmetatable(obj, self)
    self.__index = self; 
	return obj
end
 
function readServersConfig()
   local f=io.open(serversFile,"r")
   if f~=nil then 
		io.close(f) 
    else
		return nil
	end

    local serversConfigArray = {}
    for line in io.lines(serversFile) do
        serversConfigArray[#serversConfigArray + 1] = ServersConfig:new(line)
    end
   
    return serversConfigArray
end

function readServersBattConfig()
   local f=io.open(serversBattFile,"r")
   if f~=nil then 
		io.close(f) 
    else
		return nil
	end

    local serversConfigArray = {}
    for line in io.lines(serversBattFile) do
        serversConfigArray[#serversConfigArray + 1] = ServersConfig:new(line)
    end
   
    return serversConfigArray
end
