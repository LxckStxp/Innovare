--[[
    Innovare.lua
    Plugin Management System for Roblox
    Author: LxckStxp
    Version: 1.0.0
    
    Features:
    - Dynamic plugin loading
    - UI management with TabSystem
    - Error handling and logging
    - Clean initialization and cleanup
--]]

-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

-- Constants
local LOAD_TIMEOUT = 5
local DEPENDENCIES = {
    Censura = "https://raw.githubusercontent.com/LxckStxp/Censura/main/Censura.lua",
    Oratio = "https://raw.githubusercontent.com/LxckStxp/Oratio/main/Oratio.lua"
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
    task.wait(0.1)
end

-- Load Dependencies
local function loadDependency(name, url)
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    
    if not success then
        error(string.format("Failed to load %s: %s", name, tostring(result)))
    end
    
    return result
end

-- Load Censura
loadDependency("Censura", DEPENDENCIES.Censura)

-- Wait for Censura initialization
local startTime = tick()
repeat
    if _G.Censura and _G.Censura.Elements and _G.Censura.Elements.Window then
        break
    end
    task.wait()
until tick() - startTime > LOAD_TIMEOUT

if not (_G.Censura and _G.Censura.Elements and _G.Censura.Elements.Window) then
    error("Censura failed to initialize within timeout period")
end

-- Load Oratio
local Oratio = loadDependency("Oratio", DEPENDENCIES.Oratio)

-- Establish Global Innovare Table
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

-- Core System Functions
Sys.LoadModule = function(module)
    if Inn.Modules[module] then
        return Inn.Modules[module]
    end
    
    -- Ensure proper path construction
    local modulePath = typeof(module) == "string" 
        and (Inn.Git .. tostring(module) .. ".lua")
        or error("Module path must be a string")
    
    local success, result = pcall(function()
        local content = game:HttpGet(modulePath, true)
        if not content then
            error("Failed to fetch module content")
        end
        
        -- Load and execute the module
        local fn, loadError = loadstring(content)
        if not fn then
            error("Failed to compile module: " .. tostring(loadError))
        end
        
        return fn()
    end)
    
    if not success then
        Ora:Error(string.format("Failed to load module '%s': %s", tostring(module), tostring(result)))
        return nil
    end
    
    Inn.Modules[module] = result
    return result
end

Sys.SetupGUI = function()
    if Inn.GUI then
        Inn.GUI:Destroy()
    end
    
    Inn.GUI = Instance.new("ScreenGui")
    Inn.GUI.Name = "InnovareGUI"
    Inn.GUI.ResetOnSpawn = false
    Inn.GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    Inn.GUI.DisplayOrder = 999
    
    local success = pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(Inn.GUI)
        end
        Inn.GUI.Parent = CoreGui
    end)
    
    if not success then
        Inn.GUI.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
        Ora:Warn("Using PlayerGui fallback")
    end
    
    return Inn.GUI
end

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
    
    -- Cleanup core modules in reverse order
    if Inn.Modules.PluginManager and Inn.Modules.PluginManager.Cleanup then
        pcall(function()
            Inn.Modules.PluginManager:Cleanup()
        end)
    end
    
    if Inn.Modules.TabSystem and Inn.Modules.TabSystem.Cleanup then
        pcall(function()
            Inn.Modules.TabSystem:Cleanup()
        end)
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
    
    -- Load Core Modules in correct order
    local coreModules = {
        TabSystem = "Core/TabSystem",
        PluginManager = "Core/PluginManager"
    }
    
    -- Load modules sequentially
    for name, path in pairs(coreModules) do
        Ora:Info("Loading " .. name .. "...")
        Inn.Modules[name] = Sys.LoadModule(path)
        
        if not Inn.Modules[name] then
            Ora:Error("Failed to load " .. name)
            return false
        end
    end
    
    -- Create main window
    local window, windowContent = Sys.Censura.Elements.Window.new({
        title = "Innovare",
        size = UDim2.new(0, 400, 0, 500),
        position = UDim2.new(0.5, -200, 0.5, -250)
    })
    
    if not window or not windowContent then
        Ora:Error("Failed to create main window")
        return false
    end
    
    -- Initialize TabSystem first
    if not Inn.Modules.TabSystem.Init(windowContent) then
        Ora:Error("Failed to initialize TabSystem")
        return false
    end
    
    -- Initialize PluginManager with TabSystem reference
    if not Inn.Modules.PluginManager.Init(window, Inn.Modules.TabSystem) then
        Ora:Error("Failed to initialize PluginManager")
        return false
    end
    
    -- Load default plugins
    local plugins = {
        "ESP"
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
