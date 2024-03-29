backgroundColor = 0x0D0D0D
whiteColor = 0xFFFFFF
yellowColor = 0xFFFF00
greenColor = 0x00FF00
redColor = 0xFF0000
cyanColor = 0x00FFFF
backgroubdError = 0xFF0000
backgroubdOK = 0x00FF00

local formatters = {
  s = function(value, format)
    format = (format and format or "%.2f")

    return string.format(format, value)
  end,
  si = function(value, unit, format)
    format = (format and format or "%.2f")
    local incPrefixes = {"k", "M", "G", "T", "P", "E", "Z", "Y"}
    local decPrefixes = {"m", "μ", "n", "p", "f", "a", "z", "y"}

    local prefix = ""
    local scaled = value

    if value ~= 0 then
      local degree = math.floor(math.log(math.abs(value), 10) / 3)
      scaled = value * 1000 ^ -degree
      if degree > 0 then
        prefix = incPrefixes[degree]
      elseif degree < 0 then
        prefix = decPrefixes[-degree]
      end
    end

    return string.format(format, scaled) .. " " .. prefix .. (unit and unit or "")
  end,
  t = function(secs, parts)
    parts = (parts and parts or 4)

    local units = {"d", "hr", "min", "sec"}
    local result = {}
    for i, v in ipairs({86400, 3600, 60}) do
      if secs >= v then
        result[i] = math.floor(secs / v)
        secs = secs % v
      end
    end
    result[4] = secs

    local resultString = ""
    local i = 1
    while parts ~= 0 and i ~= 5 do
      if result[i] and result[i] > 0 then
        if i > 1 then
          resultString = resultString .. " "
        end
        resultString = resultString .. result[i] .. " " .. units[i]
        parts = parts - 1
      end
      i = i + 1
    end
    return resultString
  end
}

-- Вывод боксов
function box(x, y, w, h, color, backgroundColor)
    local oldColor = GPU1.setForeground(color)
    GPU1.fill(x + 1, y, w - 1, 1, "═")
    GPU1.fill(x + 1, y + h, w - 1, 1, "═")
    GPU1.fill(x, y + 1, 1, h - 1, "║")
    GPU1.fill(x + w, y + 1, 1, h - 1, "║")
    GPU1.fill(x, y, 1, 1, "╔")
    GPU1.fill(x + w, y, 1, 1, "╗")
    GPU1.fill(x, y + h, 1, 1, "╚")
    GPU1.fill(x + w, y + h, 1, 1, "╝")


    GPU1.fill(x + 1, y + 1, w - 1, h - 1, " ")

    GPU1.setForeground(oldColor)
end
 
-- Вывод текста
function write(x, y, text, color)
    color = color or textColor
    screen.setCursor(x, y)
    oldColor = GPU1.setForeground(color)
    screen.write(text)
    GPU1.setForeground(oldColor)
end

function progressBar(x, y, w, h, percent, colorOne, colorTwo)
    local oldColor = GPU1.setBackground(colorOne)

    local dX = math.floor(w * percent)
    GPU1.fill(x, y, dX, h, " ")

    GPU1.setBackground(colorTwo)
    GPU1.fill(x + dX, y, w - dX, h, " ")

    GPU1.setBackground(oldColor)
end

function clearScreen(borderColor, backgroundColor)
    local oldColor = GPU1.setBackground(borderColor)
    GPU1.fill(1, 1, screenWidth, screenHeight, " ")
 
    GPU1.setBackground(backgroundColor)
    GPU1.fill(2, 2, screenWidth - 2, screenHeight - 2, " ")
 
    GPU1.setBackground(oldColor)
end

function writeControllers(x, y, controllers) 
    local borderColor = whiteColor

    local hasError = false
    local disableCount = 0
    local disabledNames = ""
    local maintainceCount = 0
    local maintainceNames = ""

    for i = 1, #controllers do
        if controllers[i]:hasError() then
            hasError = true
            borderColor = backgroubdError 
        end 
        if controllers[i]:hasEnabledError() then
            disableCount = disableCount + 1
            disabledNames = disabledNames .. " " .. controllers[i]:getName()
        end 
        if controllers[i]:hasMaintinceError() then
            maintainceCount = maintainceCount + 1
            maintainceNames = maintainceNames.. " " .. controllers[i]:getName()
        end 
    end

    box(x, y, 50, 4, borderColor, backgroundColor)

    write(x + 3, y, "Контроллеры", whiteColor)
    write(x + 3, y + 1, "Всего / Выкл / Сломано:    /    /   ", whiteColor)
    write(x + 27, y + 1, #controllers, whiteColor)

    if disableCount == 0 then
        write(x + 32, y + 1, 0, whiteColor)
        write(x + 2, y + 2, "OK", greenColor)
    else 
        write(x + 32, y + 1, disableCount, yellowColor)
        write(x + 1, y + 2, disabledNames, yellowColor)
    end

    if maintainceCount == 0 then
        write(x + 37, y + 1, 0, whiteColor)
        write(x + 2, y + 3, "OK", greenColor)
    else 
        write(x + 37, y + 1, maintainceCount, redColor)
        write(x + 1, y + 3, maintainceNames, redColor)
    end
end

function writeBatBuffers(x, y, batBuffers, battAlarm) 
    local borderColor = whiteColor

    local hasError = false
    local stored = 0
    local max = 0
    local averageIn = 0
    local averageOut = 0
    for i = 1, #batBuffers do
        stored = stored + batBuffers[i].stored
        max = max + batBuffers[i].max
		averageIn = averageIn + batBuffers[i].averageIn
        averageOut = averageOut + batBuffers[i].averageOut
    end

    local progressColor = cyanColor

    if (battAlarm == batAlarmModeRed) then
        hasError = true
        borderColor = redColor
        progressColor = redColor
    else
        if (battAlarm == batAlarmModeYellow) then
            progressColor = yellowColor
        end
    end

    box(x, y, 76, 4, borderColor, backgroundColor)

    write(x + 3, y, "Батарейки", whiteColor)
    progressBar(x + 1, y + 1, 74, 3, stored / max, progressColor, backgroundColor)
    local storedStr = formatters["si"](stored, "EU")
    local maxStr = formatters["si"](max, "EU")
	local averageInStr = "+ " .. formatters["si"](averageIn, "EU/t")
    local averageOutStr = "- " .. formatters["si"](averageOut, "EU/t")
    
    write(x + 3, y + 1, averageInStr, whiteColor)

    write(x + 32 - string.len(storedStr), y + 2, storedStr, yellowColor)
    write(x + 32, y + 2, " / ", whiteColor)
    write(x + 35, y + 2, maxStr, greenColor)

    write(x + 71 - string.len(averageOutStr), y + 3, averageOutStr, whiteColor)
end


function writeGUI(controllers, batBuffers, battAlarm)
    GPU1.setForeground(backgroundColor)

    local hasError = false
    for i = 1, #controllers do
        if controllers[i]:hasError() then
            hasError = true
        end 
    end

    if (battAlarm == batAlarmModeRed) then
        hasError = true
    end

    if hasError then
        clearScreen(backgroubdError, backgroundColor)
    else 
        clearScreen(backgroubdOK, backgroundColor)
    end

    writeControllers(3, 3, controllers)
    writeBatBuffers(3, screenHeight - 5, batBuffers, battAlarm)
end
