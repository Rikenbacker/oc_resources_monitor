-- Скачивание всех необходимых файлов для работы монитора

shell = require("shell")

shell.execute("rm monitor.lua")
shell.execute("rm ControllerConfig.lua")
shell.execute("rm ControllerData.lua")
shell.execute("rm Graphics.lua")
shell.execute("rm List_C.lua")
shell.execute("rm BatBuffersConfig.lua")
shell.execute("rm BatBuffersData.lua")
shell.execute("rm ServersConfig.lua")
shell.execute("rm ServersData.lua")
shell.execute("rm AddController.lua")

shell.execute("pastebin get 0bsyWELb monitor.lua")
shell.execute("pastebin get cYcsRv6g ControllerConfig.lua")
shell.execute("pastebin get N5AQ1kvr ControllerData.lua")
shell.execute("pastebin get 7ips3LPf Graphics.lua")
shell.execute("pastebin get UAQ6KVEs List_C.lua")
shell.execute("pastebin get 7G7Kw3Du BatBuffersConfig.lua")
shell.execute("pastebin get dFVJvdGX BatBuffersData.lua")
shell.execute("pastebin get DfYcKE0q ServersConfig.lua")
shell.execute("pastebin get wLQfgy0W ServersData.lua")
shell.execute("pastebin get U0rmaEeH AddController.lua")

shell.execute("monitor")
