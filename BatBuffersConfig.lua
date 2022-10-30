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
    for line in io.lines(batBuffersFile) do
        batBuffersConfigArray[#batBuffersConfigArray + 1] = BatBuffersConfig:new(line)
    end
   
    return batBuffersConfigArray
end
