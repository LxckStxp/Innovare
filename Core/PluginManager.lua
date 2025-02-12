-- Core/PluginManager.lua
local PluginManager = {
    _initialized = false,
    _plugins = {},
    _activePlugins = {}
}

-- Get logger instance
local Ora = _G.Innovare.System.Oratio.Logger.new({
    moduleName = "PluginManager"
})

-- Private variables
local mainWindow
local mainContent
local tabSystem
local Censura = _G.Innovare.System.Censura

-- Debug function for Censura verification
local function debugCensura()
    print("\n=== Censura Debug ===")
    print("Censura exists:", Censura ~= nil)
    if Censura then
        print("Elements exists:", Censura.Elements ~= nil)
        if Censura.Elements then
            print("TabSystem exists:", Censura.Elements.TabSystem ~= nil)
            if Censura.Elements.TabSystem then
                print("TabSystem type:", type(Censura.Elements.TabSystem))
                print("TabSystem.new exists:", type(Censura.Elements.TabSystem.new) == "function")
            end
        end
    end
    print("=====================\n")
end

-- Create basic tab container
local function createBasicTabContainer()
    -- Create main container
    local container = Instance.new("Frame")
    container.Name = "TabContainer"
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Parent = mainContent
    
    -- Create tab bar
    local tabBar = Instance.new("Frame")
    tabBar.Name = "TabBar"
    tabBar.Size = UDim2.new(1, 0, 0, 30)
    tabBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    tabBar.Parent = container
    
    -- Create tab content area
    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, 0, 1, -35)
    contentArea.Position = UDim2.new(0, 0, 0, 35)
    contentArea.BackgroundTransparency = 1
    contentArea.Parent = container
    
    -- Add methods to container
    local TabSystem = {
        _tabs = {},
        _currentTab = nil
    }
    
    function TabSystem:AddTab(name)
        -- Create tab button
        local tabButton = Instance.new("TextButton")
        tabButton.Size = UDim2.new(0, 100, 1, -4)
        tabButton.Position = UDim2.new(0, #self._tabs * 105, 0, 2)
        tabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        tabButton.Text = name
        tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        tabButton.Parent = tabBar
        
        -- Create content frame
        local contentFrame = Instance.new("ScrollingFrame")
        contentFrame.Size = UDim2.new(1, 0, 1, 0)
        contentFrame.BackgroundTransparency = 1
        contentFrame.ScrollBarThickness = 4
        contentFrame.Visible = #self._tabs == 0  -- First tab visible by default
        contentFrame.Parent = contentArea
        
        -- Setup auto-sizing
        local listLayout = Instance.new("UIListLayout")
        listLayout.Padding = UDim.new(0, 5)
        listLayout.Parent = contentFrame
        
        -- Store tab data
        local tab = {
            button = tabButton,
            content = contentFrame,
            name = name
        }
        table.insert(self._tabs, tab)
        
        -- Tab button click handler
        tabButton.MouseButton1Click:Connect(function()
            -- Hide all tabs
            for _, t in ipairs(self._tabs) do
                t.content.Visible = false
                t.button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            end
            -- Show selected tab
            contentFrame.Visible = true
            tabButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            self._currentTab = tab
        end)
        
        return contentFrame
    end
    
    return TabSystem
end

-- Initialize the plugin manager
function PluginManager.Init(window, content)
    Ora:Info("Initializing PluginManager...")
    debugCensura()  -- Debug Censura state
    
    if not window or not content then
        Ora:Error("Window or content not provided")
        return false
    end
    
    mainWindow = window
    mainContent = content
    
    -- Create basic tab system
    tabSystem = createBasicTabContainer()
    if not tabSystem then
        Ora:Error("Failed to create tab system")
        return false
    end
    
    -- Create initial "Settings" tab
    local settingsTab = tabSystem:AddTab("Settings")
    if not settingsTab then
        Ora:Error("Failed to create Settings tab")
        return false
    end
    
    PluginManager._initialized = true
    Ora:Info("PluginManager initialized successfully")
    return true
end

-- Plugin loading function
function PluginManager.LoadPlugin(pluginName)
    if not PluginManager._initialized then
        Ora:Error("PluginManager not initialized")
        return false
    end
    
    Ora:Info("Loading plugin: " .. pluginName)
    
    -- Load plugin module with detailed error handling
    local success, plugin = xpcall(
        function()
            return _G.Innovare.System.LoadModule("Plugins/" .. pluginName .. "/init")
        end,
        debug.traceback
    )
    
    if not success then
        Ora:Error("Failed to load plugin module: " .. pluginName .. "\n" .. tostring(plugin))
        return false
    end
    
    -- Create plugin tab
    local pluginTab = tabSystem:AddTab(pluginName)
    if not pluginTab then
        Ora:Error("Failed to create tab for plugin: " .. pluginName)
        return false
    end
    
    -- Initialize plugin with detailed error handling
    local initSuccess, initError = xpcall(
        function()
            Ora:Info("Initializing plugin: " .. pluginName)
            -- Add debug prints
            print("Plugin tab type:", typeof(pluginTab))
            print("Plugin init type:", typeof(plugin.Init))
            plugin.Init(pluginTab)
        end,
        debug.traceback
    )
    
    if not initSuccess then
        Ora:Error("Failed to initialize plugin: " .. pluginName .. "\nError: " .. tostring(initError))
        return false
    end
    
    -- Store plugin reference
    PluginManager._plugins[pluginName] = plugin
    PluginManager._activePlugins[pluginName] = true
    _G.Innovare.Plugins[pluginName] = plugin
    
    Ora:Info("Successfully loaded plugin: " .. pluginName)
    return true
end

-- Debug function
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
    
    if tabSystem then
        print("\nTab System Info:")
        print("Number of tabs:", #tabSystem._tabs)
        for i, tab in ipairs(tabSystem._tabs) do
            print(string.format("Tab %d: %s", i, tab.name))
        end
    end
    
    print("=========================\n")
end

-- Add a test function
function PluginManager.TestESP()
    print("\n=== Testing ESP Plugin ===")
    
    -- Test Censura availability
    print("Checking Censura...")
    print("Censura available:", _G.Innovare.System.Censura ~= nil)
    print("Elements available:", _G.Innovare.System.Censura.Elements ~= nil)
    
    -- Test tab system
    print("\nChecking tab system...")
    print("TabSystem exists:", tabSystem ~= nil)
    if tabSystem then
        print("AddTab function exists:", type(tabSystem.AddTab) == "function")
    end
    
    -- Try loading ESP
    print("\nTrying to load ESP...")
    local success = PluginManager.LoadPlugin("ESP")
    print("Load result:", success)
    
    if success then
        print("\nESP Plugin state:")
        print("Enabled:", _G.Innovare.Plugins.ESP.Enabled)
        print("ShowInfo:", _G.Innovare.Plugins.ESP.ShowInfo)
        print("Connections:", #_G.Innovare.Plugins.ESP.Connections)
    end
    
    print("========================\n")
end

return PluginManager
