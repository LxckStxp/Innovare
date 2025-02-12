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

-- Load Core Dependencies First
local function loadCoreDependencies()
    local success, oratio = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/Oratio/main/Oratio.lua"))()
    end)
    
    if not success then
        warn("Failed to load Oratio:", oratio)
        return
    end
    
    local success2, censura = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/Censura/main/Censura.lua"))()
    end)
    
    if not success2 then
        warn("Failed to load Censura:", censura)
        return
    end
    
    return oratio, censura
end

-- Load dependencies before establishing Innovare
local Oratio, Censura = loadCoreDependencies()
if not Oratio or not Censura then
    error("Failed to load core dependencies")
    return
end

-- Establish Global Innovare Table
_G.Innovare = {
    Version = "1.0.0",
    Git = "https://raw.githubusercontent.com/LxckStxp/Innovare/main/",
    System = {
        Oratio = Oratio,    -- Store Oratio reference
        Censura = Censura,  -- Store Censura reference
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
    
    -- Try to parent to CoreGui, fallback to PlayerGui
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
    
    -- Verify Censura is loaded and available
    if not Sys.Censura then
        Ora:Error("Censura not found in System")
        return false
    end
    
    if not Sys.Censura.Elements then
        Ora:Error("Censura Elements not available")
        return false
    end
    
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

-- Example usage demonstration
local function demonstrateUsage()
    -- Create a custom plugin
    local TestPlugin = {
        Name = "TestPlugin",
        Init = function(tab)
            local section = Sys.Censura.Elements.Section.new({
                title = "Test Section"
            })
            section.Parent = tab
            
            Sys.Censura.Elements.Button.new({
                text = "Test Button",
                onClick = function()
                    Sys.Censura.Elements.Notification.Success("Button clicked!")
                end
            }).Parent = section
        end,
        Cleanup = function()
            print("Test plugin cleanup")
        end
    }
    
    -- Load the test plugin
    Inn.Modules.PluginManager.LoadPlugin(TestPlugin)
end

-- Run Initialization
local success = Sys.Init()

if success then
    Ora:Info("Innovare loaded successfully!")
    -- demonstrateUsage() -- Uncomment to run the demonstration
else
    Ora:Error("Failed to initialize Innovare")
end

return Inn
