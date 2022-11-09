BatBuffersConfig = {}
 
function BatBuffersConfig:new(parseStr)
    -- свойства
    local obj= {}
        obj.key = parseStr
 
    --чистая магия!
    setmetatable(obj, self)
    self.__index = self; return obj
end
 
function readBatBuffersConfig()
    local batBuffersConfigArray = {}

   local f=io.open(batBuffersFile,"r")
   if f~=nil then 
		io.close(f) 
    else
		return batBuffersConfigArray
	end	
	
    for line in io.lines(batBuffersFile) do
        batBuffersConfigArray[#batBuffersConfigArray + 1] = BatBuffersConfig:new(line)
    end
   
    return batBuffersConfigArray
end
