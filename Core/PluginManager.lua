-- PluginManager.lua
-- Core plugin management system for Innovare
-- Author: LxckStxp
-- Version: 1.0.0

local PluginManager = {
    _initialized = false,
    _plugins = {},
    _activePlugins = {},
    _tabs = {}
}

-- Services & References
local Ora = _G.Innovare.System.Oratio.Logger.new({
    moduleName = "PluginManager"
})
local Censura = _G.Innovare.System.Censura
local Utils = Censura.Modules.Utils

-- Private Variables
local mainWindow
local mainContent
local tabSystem

-- Private Functions
local function createTabSystem()
    Ora:Info("Creating TabSystem...")
    
    -- Create main container
    local container = Utils.Create("Frame", {
        Name = "TabSystemContainer",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Parent = mainContent
    })
    
    -- Create tab bar
    local tabBar = Utils.Create("Frame", {
        Name = "TabBar",
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = Censura.Modules.Styles.Colors.Window.TitleBar,
        Parent = container
    })
    Utils.ApplyCorners(tabBar)
    
    -- Create content area
    local contentArea = Utils.Create("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1, 0, 1, -35),
        Position = UDim2.new(0, 0, 0, 35),
        BackgroundTransparency = 1,
        Parent = container
    })
    
    -- Initialize tab data
    local tabs = {}
    local currentTab = nil
    
    -- Create tab system interface
    local tabSystemInterface = {
        AddTab = function(self, name)
            -- Create tab button
            local button = Utils.Create("TextButton", {
                Size = UDim2.new(0, 100, 1, -4),
                Position = UDim2.new(0, #tabs * 105, 0, 2),
                BackgroundColor3 = Censura.Modules.Styles.Colors.Controls.Button.Default,
                Text = name,
                TextColor3 = Censura.Modules.Styles.Colors.Text.Primary,
                Parent = tabBar
            })
            Utils.ApplyCorners(button)
            
            -- Create content frame
            local content = Utils.Create("ScrollingFrame", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                ScrollBarThickness = 4,
                Visible = #tabs == 0, -- First tab visible by default
                Parent = contentArea
            })
            
            -- Setup content layout
            Utils.SetupListLayout(content)
            Utils.CreatePadding(content)
            
            -- Create tab data
            local tab = {
                name = name,
                button = button,
                content = content
            }
            
            -- Tab button handler
            button.MouseButton1Click:Connect(function()
                -- Hide all tabs
                for _, t in ipairs(tabs) do
                    t.content.Visible = false
                    t.button.BackgroundColor3 = Censura.Modules.Styles.Colors.Controls.Button.Default
                end
                
                -- Show selected tab
                content.Visible = true
                button.BackgroundColor3 = Censura.Modules.Styles.Colors.Controls.Button.Pressed
                currentTab = tab
            end)
            
            table.insert(tabs, tab)
            return content
        end,
        
        GetCurrentTab = function()
            return currentTab and currentTab.name
        end,
        
        SelectTab = function(self, name)
            for _, tab in ipairs(tabs) do
                if tab.name == name then
                    tab.button.MouseButton1Click:Fire()
                    break
                end
            end
        end
    }
    
    -- Create initial "Settings" tab
    local settingsTab = tabSystemInterface:AddTab("Settings")
    
    -- Add settings section
    local settingsSection = Censura.Elements.Section.new({
        title = "Plugin Management"
    })
    settingsSection.Parent = settingsTab
    
    return tabSystemInterface
end

-- Public Functions
function PluginManager.Init(window, content)
    if PluginManager._initialized then
        Ora:Warn("PluginManager already initialized")
        return false
    end
    
    Ora:Info("Initializing PluginManager...")
    
    -- Store references
    mainWindow = window
    mainContent = content
    
    -- Create tab system
    local success, result = pcall(function()
        return createTabSystem()
    end)
    
    if not success then
        Ora:Error("Failed to setup TabSystem: " .. tostring(result))
        return false
    end
    
    tabSystem = result
    PluginManager._initialized = true
    
    Ora:Info("PluginManager initialized successfully")
    return true
end

function PluginManager.LoadPlugin(pluginNameOrModule)
    if not PluginManager._initialized then
        Ora:Error("PluginManager not initialized")
        return false
    end
    
    -- Handle plugin input
    local pluginName, plugin
    if type(pluginNameOrModule) == "string" then
        pluginName = pluginNameOrModule
        local success, result = pcall(function()
            return _G.Innovare.System.LoadModule("Plugins/" .. pluginNameOrModule .. "/init")
        end)
        
        if not success then
            Ora:Error("Failed to load plugin module: " .. pluginName)
            return false
        end
        plugin = result
    else
        plugin = pluginNameOrModule
        pluginName = plugin.Name or "UnnamedPlugin"
    end
    
    -- Validate plugin
    if type(plugin) ~= "table" or type(plugin.Init) ~= "function" then
        Ora:Error("Invalid plugin structure: " .. pluginName)
        return false
    end
    
    -- Create plugin tab
    local pluginTab = tabSystem:AddTab(pluginName)
    if not pluginTab then
        Ora:Error("Failed to create tab for: " .. pluginName)
        return false
    end
    
    -- Initialize plugin
    local success, error = pcall(function()
        plugin.Init(pluginTab)
    end)
    
    if not success then
        Ora:Error("Plugin initialization failed: " .. tostring(error))
        return false
    end
    
    -- Store plugin
    PluginManager._plugins[pluginName] = plugin
    PluginManager._activePlugins[pluginName] = true
    PluginManager._tabs[pluginName] = pluginTab
    _G.Innovare.Plugins[pluginName] = plugin
    
    Ora:Info("Successfully loaded plugin: " .. pluginName)
    return true
end

function PluginManager.UnloadPlugin(pluginName)
    local plugin = PluginManager._plugins[pluginName]
    if not plugin then
        Ora:Warn("Plugin not found: " .. pluginName)
        return false
    end
    
    -- Cleanup plugin
    if plugin.Cleanup then
        local success, error = pcall(function()
            plugin:Cleanup()
        end)
        
        if not success then
            Ora:Error("Failed to cleanup plugin: " .. pluginName .. " - " .. error)
        end
    end
    
    -- Remove references
    PluginManager._plugins[pluginName] = nil
    PluginManager._activePlugins[pluginName] = nil
    PluginManager._tabs[pluginName] = nil
    _G.Innovare.Plugins[pluginName] = nil
    
    Ora:Info("Successfully unloaded plugin: " .. pluginName)
    return true
end

-- Debug Functions
function PluginManager.Debug()
    print("\n=== PluginManager Debug ===")
    print("Initialized:", PluginManager._initialized)
    print("Window exists:", mainWindow ~= nil)
    print("Content exists:", mainContent ~= nil)
    print("TabSystem exists:", tabSystem ~= nil)
    
    if mainContent then
        print("\nContent Children:")
        for _, child in ipairs(mainContent:GetChildren()) do
            print("- " .. child.Name .. " (" .. child.ClassName .. ")")
        end
    end
    
    print("\nLoaded Plugins:")
    for name, plugin in pairs(PluginManager._plugins) do
        print("- " .. name .. " (Enabled: " .. tostring(PluginManager._activePlugins[name]) .. ")")
    end
    print("=========================\n")
end

return PluginManager
