--[[
    Innovare.lua
    Advanced Plugin Management System for Roblox
    Author: LxckStxp
    Version: 1.0.0
    
    Features:
    - Dynamic plugin loading system
    - UI management with Censura
    - Logging with Oratio
    - Comprehensive error handling
    - Auto-cleanup on reinstantiation
--]]

-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

-- Constants
local TIMEOUT_DURATION = 5
local DEPENDENCIES = {
    Censura = {
        url = "https://raw.githubusercontent.com/LxckStxp/Censura/main/Censura.lua",
        required = true
    },
    Oratio = {
        url = "https://raw.githubusercontent.com/LxckStxp/Oratio/main/Oratio.lua",
        required = true
    }
}

-- Cleanup existing instance
if _G.Innovare then
    print(string.rep("\n", 30))
    print("Innovare Detected. Cleaning up previous instance...")
    
    if _G.Innovare.System.Cleanup then
        pcall(function()
            _G.Innovare.System.Cleanup()
        end)
    end
    
    _G.Innovare = nil
    task.wait(0.1) -- Brief pause to ensure cleanup
end

-- Utility Functions
local function loadDependency(name, info)
    local success, result = pcall(function()
        return loadstring(game:HttpGet(info.url))()
    end)
    
    if not success and info.required then
        error(string.format("Failed to load required dependency %s: %s", name, tostring(result)))
    end
    
    return success and result or nil
end

local function waitForDependency(dependency, timeout)
    local startTime = tick()
    
    repeat
        if _G[dependency] and _G[dependency].Elements and _G[dependency].Elements.Window then
            return true
        end
        task.wait()
    until tick() - startTime > timeout
    
    return false
end

-- Load Core Dependencies
local Censura = loadDependency("Censura", DEPENDENCIES.Censura)
if not Censura then
    error("Failed to load Censura")
    return
end

if not waitForDependency("Censura", TIMEOUT_DURATION) then
    error("Censura failed to initialize within timeout period")
    return
end

local Oratio = loadDependency("Oratio", DEPENDENCIES.Oratio)
if not Oratio then
    error("Failed to load Oratio")
    return
end

-- Establish Global Innovare Table with Type Definitions
---@class Innovare
---@field Version string
---@field Git string
---@field System table
---@field Modules table
---@field Plugins table
---@field GUI ScreenGui
_G.Innovare = {
    Version = "1.0.0",
    Git = "https://raw.githubusercontent.com/LxckStxp/Innovare/main/",
    System = {
        Oratio = Oratio,
        Censura = _G.Censura,
        Status = {
            Initialized = false,
            PluginsLoaded = false
        }
    },
    Modules = {},
    Plugins = {},
    GUI = nil,
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

-- Enhanced Module Loading System
Sys.LoadModule = function(module)
    if Inn.Modules[module] then
        return Inn.Modules[module]
    end
    
    local url = Inn.Git .. module .. ".lua"
    local success, result = pcall(function()
        local content = game:HttpGet(url, true)
        return loadstring(content)()
    end)
    
    if not success then
        Ora:Error(string.format("Failed to load module %s: %s", module, tostring(result)))
        return nil
    end
    
    Inn.Modules[module] = result
    return result
end

-- Enhanced GUI Setup
Sys.SetupGUI = function()
    if Inn.GUI then
        Inn.GUI:Destroy()
    end
    
    Inn.GUI = Instance.new("ScreenGui")
    Inn.GUI.Name = "InnovareGUI"
    Inn.GUI.ResetOnSpawn = false
    Inn.GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    Inn.GUI.DisplayOrder = 999
    
    -- Try CoreGui first, fallback to PlayerGui
    local success = pcall(function()
        Inn.GUI.Parent = game:GetService("CoreGui")
    end)
    
    if not success then
        local player = Players.LocalPlayer
        if not player then
            player = Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
        end
        Inn.GUI.Parent = player:WaitForChild("PlayerGui")
        Ora:Warn("Using PlayerGui fallback")
    end
    
    return Inn.GUI
end

-- Comprehensive Cleanup System
Sys.Cleanup = function()
    Ora:Info("Starting cleanup...")
    
    -- Cleanup plugins
    for name, plugin in pairs(Inn.Plugins) do
        if plugin.Cleanup then
            pcall(function()
                plugin:Cleanup()
                Ora:Info(string.format("Cleaned up plugin: %s", name))
            end)
        end
    end
    
    -- Cleanup GUI
    if Inn.GUI then
        Inn.GUI:Destroy()
    end
    
    -- Clear tables
    table.clear(Inn.Plugins)
    table.clear(Inn.Modules)
    
    -- Reset status
    Sys.Status.Initialized = false
    Sys.Status.PluginsLoaded = false
    
    Ora:Info("Cleanup complete")
end

-- Main Initialization
Sys.Init = function()
    if Sys.Status.Initialized then
        Ora:Warn("Innovare already initialized")
        return false
    end
    
    print(string.format(Inn.Messages.Clear .. Inn.Messages.Splash .. "\n", Inn.Version))
    
    Ora:Info("Starting Innovare initialization...")
    
    -- Setup GUI
    local gui = Sys.SetupGUI()
    if not gui then
        Ora:Error("Failed to setup GUI")
        return false
    end
    
    -- Load Plugin Manager
    Inn.Modules.PluginManager = Sys.LoadModule("Core/PluginManager")
    if not Inn.Modules.PluginManager then
        Ora:Error("Failed to load PluginManager")
        return false
    end
    
    -- Create main window with Censura
    local window, windowContent = Sys.Censura.Elements.Window.new({
        title = "Innovare",
        size = UDim2.new(0, 400, 0, 500)
    })
    
    if not window or not windowContent then
        Ora:Error("Failed to create main window")
        return false
    end
    
    -- Initialize Plugin Manager
    if not Inn.Modules.PluginManager.Init(window, windowContent) then
        Ora:Error("Failed to initialize PluginManager")
        return false
    end
    
    -- Load configured plugins
    local plugins = {
        "ESP" -- Add more plugins here
    }
    
    local loadedPlugins = 0
    for _, plugin in ipairs(plugins) do
        if Inn.Modules.PluginManager.LoadPlugin(plugin) then
            loadedPlugins += 1
        end
    end
    
    Sys.Status.PluginsLoaded = loadedPlugins > 0
    Sys.Status.Initialized = true
    
    Ora:Info(string.format("Initialization Complete! Loaded %d/%d plugins", loadedPlugins, #plugins))
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
