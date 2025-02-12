--[[
    Innovare.lua - Simplified Plugin Management System
    Author: LxckStxp
    Version: 1.0.0
--]]

-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Constants
local DEPENDENCIES = {
    Censura = "https://raw.githubusercontent.com/LxckStxp/Censura/main/Censura.lua",
    Oratio = "https://raw.githubusercontent.com/LxckStxp/Oratio/main/Oratio.lua"
}

-- Clean up existing instance
if _G.Innovare then
    if _G.Innovare.System.Cleanup then
        _G.Innovare.System.Cleanup()
    end
    _G.Innovare = nil
    task.wait(0.1)
end

-- Load Dependencies
local function loadDependency(url)
    return loadstring(game:HttpGet(url))()
end

-- Load and initialize Censura
local success = pcall(function()
    loadDependency(DEPENDENCIES.Censura)
end)

if not success or not _G.Censura then
    error("Failed to load Censura")
    return
end

-- Wait for Censura to initialize
local startTime = tick()
repeat
    if _G.Censura.Elements and _G.Censura.Elements.Window then
        break
    end
    task.wait()
until tick() - startTime > 5

if not (_G.Censura.Elements and _G.Censura.Elements.Window) then
    error("Censura failed to initialize")
    return
end

-- Load Oratio
local Oratio = loadDependency(DEPENDENCIES.Oratio)

-- Initialize Innovare
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
    GUI = nil
}

local Inn = _G.Innovare
local Sys = Inn.System
local Ora = Sys.Oratio.Logger.new({ moduleName = "Innovare" })

-- Core Functions
Sys.LoadModule = function(module)
    if Inn.Modules[module] then return Inn.Modules[module] end
    
    local success, result = pcall(function()
        return loadstring(game:HttpGet(Inn.Git .. module .. ".lua"))()
    end)
    
    if not success then
        Ora:Error("Failed to load module: " .. module)
        return nil
    end
    
    Inn.Modules[module] = result
    return result
end

Sys.SetupGUI = function()
    Inn.GUI = Instance.new("ScreenGui")
    Inn.GUI.Name = "InnovareGUI"
    Inn.GUI.ResetOnSpawn = false
    Inn.GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    Inn.GUI.DisplayOrder = 999
    
    pcall(function()
        Inn.GUI.Parent = game:GetService("CoreGui")
    end) or (Inn.GUI.Parent = Players.LocalPlayer:WaitForChild("PlayerGui"))
end

Sys.Cleanup = function()
    -- Cleanup plugins
    for name, plugin in pairs(Inn.Plugins) do
        if plugin.Cleanup then
            pcall(function() plugin:Cleanup() end)
        end
    end
    
    -- Cleanup GUI
    if Inn.GUI then Inn.GUI:Destroy() end
    
    -- Clear tables
    table.clear(Inn.Plugins)
    table.clear(Inn.Modules)
    Sys.Status.Initialized = false
    Sys.Status.PluginsLoaded = false
end

-- Main Initialization
Sys.Init = function()
    if Sys.Status.Initialized then return false end
    
    -- Setup GUI
    Sys.SetupGUI()
    
    -- Load Plugin Manager
    Inn.Modules.PluginManager = Sys.LoadModule("Core/PluginManager")
    if not Inn.Modules.PluginManager then
        Ora:Error("Failed to load PluginManager")
        return false
    end
    
    -- Create main window
    local window, content = Sys.Censura.Elements.Window.new({
        title = "Innovare",
        size = UDim2.new(0, 400, 0, 500)
    })
    
    -- Initialize Plugin Manager
    if not Inn.Modules.PluginManager.Init(window, content) then
        Ora:Error("Failed to initialize PluginManager")
        return false
    end
    
    -- Load default plugins
    local defaultPlugins = {"ESP"}
    local loadedCount = 0
    
    for _, plugin in ipairs(defaultPlugins) do
        if Inn.Modules.PluginManager.LoadPlugin(plugin) then
            loadedCount += 1
        end
    end
    
    Sys.Status.PluginsLoaded = loadedCount > 0
    Sys.Status.Initialized = true
    
    return true
end

-- Run Initialization
if Sys.Init() then
    Ora:Info("Innovare initialized successfully!")
else
    Ora:Error("Failed to initialize Innovare")
end

return Inn
