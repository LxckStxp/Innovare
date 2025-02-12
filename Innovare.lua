--[[
    Innovare.lua
    Plugin Management System for Roblox
    Author: LxckStxp
    Version: 1.0.0
--]]

-- Services
local RunService = game:GetService("RunService")

-- Check for existing instance
if _G.Innovare then
    print(string.rep("\n", 30))
    print("Innovare Detected. Cleaning up previous instance...")
    
    if _G.Innovare.System.Cleanup then
        _G.Innovare.System.Cleanup()
    end
    
    _G.Innovare = nil
end

-- Establish Global Innovare Table
_G.Innovare = {
    Version = "1.0.0",
    Git = "https://raw.githubusercontent.com/LxckStxp/Innovare/main/",
    System = {},      -- System Functions Storage
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

-- Load Dependencies
Sys.LoadDependency = function(url)
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url, true))()
    end)
    
    if not success then
        error(string.format("Failed to load dependency: %s", tostring(result)))
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
    
    -- Try to parent to CoreGui, fallback to PlayerGui
    local success = pcall(function()
        Inn.GUI.Parent = game:GetService("CoreGui")
    end)
    
    if not success then
        Inn.GUI.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
        Ora:Warn("Parented to PlayerGui instead of CoreGui")
    end
end

-- Cleanup System
Sys.Cleanup = function()
    -- Cleanup plugins
    for name, plugin in pairs(Inn.Plugins) do
        if plugin.Cleanup then
            Ora:Info(string.format("Cleaning up plugin: %s", name))
            plugin:Cleanup()
        end
    end
    
    -- Remove GUI
    if Inn.GUI then
        Inn.GUI:Destroy()
    end
    
    -- Clear tables
    table.clear(Inn.Plugins)
    table.clear(Inn.Modules)
end

-- Main Initialization
Sys.Init = function()
    print(string.format(Inn.Messages.Clear .. Inn.Messages.Splash .. "\n", Inn.Version))
    
    Ora:Info("Starting Innovare initialization...")
    
    -- Setup GUI Container
    Sys.SetupGUI()
    
    -- Ensure Censura is loaded first
    if not Sys.Censura then
        Ora:Error("Censura not loaded! Aborting initialization.")
        return
    end
    
    -- Wait for Censura Elements to be available
    if not Sys.Censura.Elements then
        Ora:Error("Censura Elements not available! Aborting initialization.")
        return
    end
    
    -- Load Core Modules
    Ora:Info("Loading core modules...")
    
    -- Load Plugin Manager
    Inn.Modules.PluginManager = Sys.LoadModule("Core/PluginManager")
    if not Inn.Modules.PluginManager then
        Ora:Error("Failed to load PluginManager. Aborting initialization.")
        return
    end
    
    -- Create main window using Censura
    local window = Sys.Censura.Elements.Window.new({
        title = "Innovare",
        size = UDim2.new(0, 400, 0, 500)
    })
    
    -- Initialize Plugin Manager with window
    if not Inn.Modules.PluginManager.Init(window) then
        Ora:Error("Failed to initialize PluginManager. Aborting initialization.")
        return
    end
    
    -- Load configured plugins
    local plugins = {
        "ESP" -- Add more plugins here
    }
    
    for _, plugin in ipairs(plugins) do
        if not Inn.Modules.PluginManager.LoadPlugin(plugin) then
            Ora:Warn("Failed to load plugin: " .. plugin)
        end
    end
    
    Ora:Info("Initialization Complete!")
end

-- Run Initialization
Sys.Init()

return Inn
