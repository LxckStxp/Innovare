--[[
    Innovare.lua
    Plugin Management System for Roblox
    Author: LxckStxp
    Version: 1.0.0
--]]

-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Check for existing instance
if _G.Innovare then
    print(string.rep("\n", 30))
    print("Innovare Detected. Cleaning up previous instance...")
    
    if _G.Innovare.System.Cleanup then
        _G.Innovare.System.Cleanup()
    end
    
    _G.Innovare = nil
end

-- Wait for Censura to fully initialize
local function waitForCensura()
    local startTime = tick()
    local timeout = 5 -- 5 seconds timeout
    
    repeat
        if _G.Censura and _G.Censura.Elements and _G.Censura.Elements.Window then
            return true
        end
        task.wait()
    until tick() - startTime > timeout
    
    return false
end

-- Load and initialize Censura first
local success, result = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/Censura/main/Censura.lua"))()
end)

if not success then
    error("Failed to load Censura: " .. tostring(result))
    return
end

-- Wait for Censura to initialize
if not waitForCensura() then
    error("Censura failed to initialize within timeout period")
    return
end

-- Load Oratio for logging
local Oratio = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/Oratio/main/Oratio.lua"))()

-- Establish Global Innovare Table
_G.Innovare = {
    Version = "1.0.0",
    Git = "https://raw.githubusercontent.com/LxckStxp/Innovare/main/",
    System = {
        Oratio = Oratio,
        Censura = _G.Censura, -- Store direct reference to Censura
    },
    Modules = {},     -- Core Module Storage
    Plugins = {},     -- Plugin Storage
    GUI = nil,        -- Main GUI Instance
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

-- Initialize Logger
local Ora = Sys.Oratio.Logger.new({
    moduleName = "Innovare"
})

-- Function to Load Modules
Sys.LoadModule = function(module)
    local url = Inn.Git .. module .. ".lua"
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url, true))()
    end)
    
    if not success then
        Ora:Error(string.format("Failed to load module %s: %s", module, tostring(result)))
        return nil
    end
    
    return result
end

-- Setup GUI Container
Sys.SetupGUI = function()
    Inn.GUI = Instance.new("ScreenGui")
    Inn.GUI.Name = "InnovareGUI"
    Inn.GUI.ResetOnSpawn = false
    Inn.GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    Inn.GUI.DisplayOrder = 999
    
    local success = pcall(function()
        Inn.GUI.Parent = game:GetService("CoreGui")
    end)
    
    if not success then
        Inn.GUI.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
        Ora:Warn("Parented to PlayerGui instead of CoreGui")
    end
end

-- Cleanup System
Sys.Cleanup = function()
    for name, plugin in pairs(Inn.Plugins) do
        if plugin.Cleanup then
            Ora:Info(string.format("Cleaning up plugin: %s", name))
            plugin:Cleanup()
        end
    end
    
    if Inn.GUI then
        Inn.GUI:Destroy()
    end
    
    table.clear(Inn.Plugins)
    table.clear(Inn.Modules)
end

-- Main Initialization
Sys.Init = function()
    print(string.format(Inn.Messages.Clear .. Inn.Messages.Splash .. "\n", Inn.Version))
    
    Ora:Info("Starting Innovare initialization...")
    
    -- Setup GUI Container
    Sys.SetupGUI()
    
    -- Load Core Modules
    Ora:Info("Loading core modules...")
    
    -- Load Plugin Manager
    Inn.Modules.PluginManager = Sys.LoadModule("Core/PluginManager")
    if not Inn.Modules.PluginManager then
        Ora:Error("Failed to load PluginManager. Aborting initialization.")
        return false
    end
    
    -- Create main window using Censura
    local window = Sys.Censura.Elements.Window.new({
        title = "Innovare",
        size = UDim2.new(0, 400, 0, 500)
    })
    
    -- Initialize Plugin Manager with window
    if not Inn.Modules.PluginManager.Init(window) then
        Ora:Error("Failed to initialize PluginManager")
        return false
    end
    
    -- Load configured plugins
    local plugins = {
        "ESP" -- Add more plugins here
    }
    
    for _, plugin in ipairs(plugins) do
        Ora:Info(string.format("Loading plugin: %s", plugin))
        local success = Inn.Modules.PluginManager.LoadPlugin(plugin)
        if not success then
            Ora:Warn(string.format("Failed to load plugin: %s", plugin))
        end
    end
    
    Ora:Info("Initialization Complete!")
    return true
end

-- Run Initialization
local success = Sys.Init()

if success then
    Ora:Info("Innovare loaded successfully!")
else
    Ora:Error("Failed to initialize Innovare")
end

return Inn
