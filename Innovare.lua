-- Innovare.lua
if _G.Innovare then
    print(string.rep("\n", 30))
    print("Innovare Detected. Removing existing instance.")
    _G.Innovare = nil
end

-- Establish Global Innovare Table
_G.Innovare = {
    Version = "1.0.0",
    Git = "https://raw.githubusercontent.com/LxckStxp/Innovare/main/",
    System = {},      -- System Functions Storage
    Modules = {},     -- Core Module Storage
    Plugins = {},     -- Plugin Storage
    Messages = {
        Clear = string.rep("\n", 30),
        Splash = [[
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
dP                                                                
88                                                                
88 88d888b. 88d888b. .d8888b. dP   .dP .d8888b. 88d888b. .d8888b. 
88 88'  `88 88'  `88 88'  `88 88   d8' 88'  `88 88'  `88 88ooood8 
88 88    88 88    88 88.  .88 88 .88'  88.  .88 88       88.  ... 
dP dP    dP dP    dP `88888P' 8888P'   `88888P8 dP       `88888P'  v%s

                                    - By LxckStxp

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
]]
    }
}

local Inn = _G.Innovare
local Sys = Inn.System

-- Load Dependencies
Sys.LoadDependency = function(url)
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url, true))()
    end)
    if not success then
        error("Failed to load dependency: " .. tostring(result))
    end
    return result
end

-- Initialize Oratio Logger
Sys.Oratio = Sys.LoadDependency("https://raw.githubusercontent.com/LxckStxp/Oratio/main/Oratio.lua")
Ora = Sys.Oratio.Logger.new({
    moduleName = "Innovare"
})

-- Initialize Censura UI Library
Sys.Censura = Sys.LoadDependency("https://raw.githubusercontent.com/LxckStxp/Censura/main/Censura.lua")

-- Function to Load Modules
Sys.LoadModule = function(module)
    local url = Inn.Git .. module .. ".lua"
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url, true))()
    end)
    if not success then
        Ora:Error("Failed to load module from " .. url .. ": " .. tostring(result))
    end
    return result
end

-- Initialize Plugin Manager
Sys.Init = function()
    print(string.format(Inn.Messages.Clear .. Inn.Messages.Splash .. "\n", Inn.Version))
    Ora:Info("Loading Core Modules\n")

    -- Load Plugin Manager
    Inn.Modules.PluginManager = Sys.LoadModule("Core/PluginManager")
    
    -- Create main window using Censura
    local window = Sys.Censura.Elements.Window.new({
        title = "Innovare",
        size = UDim2.new(0, 400, 0, 500)
    })

    -- Initialize Plugin Manager with window
    Inn.Modules.PluginManager.Init(window)
    
    -- Load configured plugins
    local plugins = {
        "ESP" -- Add more plugins here
    }
    
    for _, plugin in ipairs(plugins) do
        Inn.Modules.PluginManager.LoadPlugin(plugin)
    end
end

-- Run Initialization
Sys.Init()

return Inn
