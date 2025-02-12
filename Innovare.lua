--[[
    Innovare.lua
    Advanced Plugin Management System for Roblox
    Author: LxckStxp
    Version: 1.0.0
--]]

-- Services
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-- Constants
local DEPENDENCIES = {
    Oratio = {
        url = "https://raw.githubusercontent.com/LxckStxp/Oratio/main/Oratio.lua",
        required = true
    },
    Censura = {
        url = "https://raw.githubusercontent.com/LxckStxp/Censura/main/Censura.lua",
        required = true
    }
}

-- Check for existing instance with enhanced cleanup
if _G.Innovare then
    print(string.rep("\n", 30))
    print("Innovare Detected. Cleaning up previous instance...")
    
    if _G.Innovare.System.Cleanup then
        pcall(function()
            _G.Innovare.System.Cleanup()
        end)
    end
    
    _G.Innovare = nil
end

-- Establish Global Innovare Table with meta methods for better control
_G.Innovare = setmetatable({
    Version = "1.0.0",
    Git = "https://raw.githubusercontent.com/LxckStxp/Innovare/main/",
    System = {
        Dependencies = {},  -- Store loaded dependencies
        Status = {         -- System status tracking
            Initialized = false,
            DependenciesLoaded = false,
            PluginsLoaded = false
        }
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
}, {
    __index = function(t, k)
        if k == "Ready" then
            return t.System.Status.Initialized
        end
        return rawget(t, k)
    end
})

local Inn = _G.Innovare
local Sys = Inn.System

-- Enhanced HTTP handling
Sys.HttpGet = function(url)
    local success, result = pcall(function()
        return game:HttpGet(url, true)
    end)
    
    if not success then
        error(string.format("HTTP GET failed: %s", tostring(result)))
    end
    
    return result
end

-- Enhanced dependency loader
Sys.LoadDependency = function(name, info)
    if Sys.Dependencies[name] then
        return Sys.Dependencies[name]
    end
    
    local success, result = pcall(function()
        local content = Sys.HttpGet(info.url)
        return loadstring(content)()
    end)
    
    if not success then
        if info.required then
            error(string.format("Failed to load required dependency %s: %s", name, tostring(result)))
        else
            warn(string.format("Failed to load optional dependency %s: %s", name, tostring(result)))
            return nil
        end
    end
    
    Sys.Dependencies[name] = result
    return result
end

-- Initialize all dependencies
Sys.InitializeDependencies = function()
    -- Load Oratio first for logging
    local oratio = Sys.LoadDependency("Oratio", DEPENDENCIES.Oratio)
    if not oratio then return false end
    
    Sys.Oratio = oratio
    Ora = Sys.Oratio.Logger.new({
        moduleName = "Innovare"
    })
    
    -- Load Censura and store its elements properly
    local censura = Sys.LoadDependency("Censura", DEPENDENCIES.Censura)
    if not censura then return false end
    
    -- Store Censura components properly
    Sys.Censura = {
        Elements = censura.Elements,
        Modules = censura.Modules,
        GUI = censura.GUI
    }
    
    if not Sys.Censura.Elements then
        Ora:Error("Censura Elements not available after loading")
        return false
    end
    
    Sys.Status.DependenciesLoaded = true
    return true
end

-- Enhanced module loader
Sys.LoadModule = function(module)
    if Inn.Modules[module] then
        return Inn.Modules[module]
    end
    
    local url = Inn.Git .. module .. ".lua"
    local success, result = pcall(function()
        local content = Sys.HttpGet(url)
        return loadstring(content)()
    end)
    
    if not success then
        Ora:Error(string.format("Failed to load module %s: %s", module, tostring(result)))
        return nil
    end
    
    Inn.Modules[module] = result
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
        Ora:Warn("Using PlayerGui fallback")
    end
    
    return true
end

-- Enhanced cleanup system
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
    
    -- Remove GUI
    if Inn.GUI then
        Inn.GUI:Destroy()
    end
    
    -- Clear tables
    table.clear(Inn.Plugins)
    table.clear(Inn.Modules)
    table.clear(Sys.Dependencies)
    
    Sys.Status.Initialized = false
    Sys.Status.DependenciesLoaded = false
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
    
    -- Initialize dependencies
    if not Sys.InitializeDependencies() then
        Ora:Error("Failed to initialize dependencies")
        return false
    end
    
    -- Setup GUI
    if not Sys.SetupGUI() then
        Ora:Error("Failed to setup GUI")
        return false
    end
    
    -- Load Plugin Manager
    Inn.Modules.PluginManager = Sys.LoadModule("Core/PluginManager")
    if not Inn.Modules.PluginManager then
        Ora:Error("Failed to load PluginManager")
        return false
    end
    
    -- Create main window
    local window = Sys.Censura.Elements.Window.new({
        title = "Innovare",
        size = UDim2.new(0, 400, 0, 500)
    })
    
    -- Initialize Plugin Manager
    if not Inn.Modules.PluginManager.Init(window) then
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
local success, result = pcall(Sys.Init)
if not success then
    warn("Innovare initialization failed:", result)
end

return Inn
