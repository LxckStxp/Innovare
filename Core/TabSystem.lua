-- TabSystem.lua
-- Core tab management system for Innovare
-- Author: LxckStxp
-- Version: 1.0.0

local TabSystem = {
    _initialized = false,
    _tabs = {},
    _currentTab = nil
}

-- Services & References
local Ora = _G.Innovare.System.Oratio.Logger.new({
    moduleName = "TabSystem"
})
local Censura = _G.Innovare.System.Censura
local Utils = Censura.Modules.Utils
local Styles = Censura.Modules.Styles

-- Private Variables
local mainContainer
local tabBar
local buttonContainer
local contentArea

-- Private Functions
local function createTabButton(name)
    local button = Utils.Create("TextButton", {
        Name = "Button",
        Size = UDim2.new(0, 100, 1, -4),
        BackgroundColor3 = Styles.Colors.Controls.Button.Default,
        Text = "Button",
        TextColor3 = Styles.Colors.Text.Primary,
        Font = Styles.Text.Default.Font,
        TextSize = Styles.Text.Default.Size,
        AutoButtonColor = false,
        Parent = buttonContainer
    })
    
    Utils.ApplyCorners(button)
    Utils.ApplyHoverEffect(button)
    
    local indicator = Utils.Create("Frame", {
        Name = "SelectionIndicator",
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, -2),
        BackgroundColor3 = Styles.Colors.Primary.Main,
        BackgroundTransparency = 1,
        Parent = button
    })
    
    return button, indicator
end

local function createTabContent()
    local content = Utils.Create("ScrollingFrame", {
        Name = "TabContent",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Styles.Colors.Controls.ScrollBar.Bar,
        Visible = false,
        Parent = contentArea
    })
    
    Utils.SetupListLayout(content)
    Utils.CreatePadding(content)
    
    return content
end

local function switchTab(tab)
    if TabSystem._currentTab == tab then return end
    
    for _, t in pairs(TabSystem._tabs) do
        local isSelected = t == tab
        
        Utils.Tween(t.Button, {
            BackgroundColor3 = isSelected 
                and Styles.Colors.Controls.Button.Pressed
                or Styles.Colors.Controls.Button.Default
        })
        
        Utils.Tween(t.Indicator, {
            BackgroundTransparency = isSelected and 0 or 1
        })
        
        if t.Content then
            if isSelected then
                t.Content.Visible = true
                Utils.Tween(t.Content, {
                    Position = UDim2.new(0, 0, 0, 0),
                    BackgroundTransparency = 0
                })
            else
                Utils.Tween(t.Content, {
                    Position = UDim2.new(0.1, 0, 0, 0),
                    BackgroundTransparency = 1
                }).Completed:Connect(function()
                    t.Content.Visible = false
                end)
            end
        end
    end
    
    TabSystem._currentTab = tab
end

-- Public Functions
function TabSystem.Init(parent)
    if not parent then
        Ora:Error("Parent is required for TabSystem initialization")
        return false
    end
    
    if TabSystem._initialized then
        Ora:Warn("TabSystem already initialized")
        return false
    end
    
    Ora:Info("Initializing TabSystem...")
    
    local success, error = pcall(function()
        mainContainer = Utils.Create("Frame", {
            Name = "TabSystemContainer",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Parent = parent
        })
        
        tabBar = Utils.Create("Frame", {
            Name = "TabBar",
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundColor3 = Styles.Colors.Window.TitleBar,
            Parent = mainContainer
        })
        Utils.ApplyCorners(tabBar)
        
        buttonContainer = Utils.Create("Frame", {
            Name = "ButtonContainer",
            Size = UDim2.new(1, -10, 1, -4),
            Position = UDim2.new(0, 5, 0, 2),
            BackgroundTransparency = 1,
            Parent = tabBar
        })
        
        Utils.Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 5),
            Parent = buttonContainer
        })
        
        contentArea = Utils.Create("Frame", {
            Name = "ContentArea",
            Size = UDim2.new(1, 0, 1, -35),
            Position = UDim2.new(0, 0, 0, 35),
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            Parent = mainContainer
        })
    end)
    
    if not success then
        Ora:Error("Failed to initialize TabSystem: " .. tostring(error))
        return false
    end
    
    if not (mainContainer and tabBar and buttonContainer and contentArea) then
        Ora:Error("Failed to create all required TabSystem components")
        return false
    end
    
    TabSystem._initialized = true
    Ora:Info("TabSystem initialized successfully")
    return true
end

function TabSystem.AddTab(name)
    if not TabSystem._initialized then
        Ora:Error("TabSystem not initialized")
        return nil
    end
    
    if TabSystem._tabs[name] then
        Ora:Warn("Tab already exists: " .. tostring(name))
        return TabSystem._tabs[name].Content
    end
    
    local button, indicator = createTabButton(name)
    local content = createTabContent()
    
    local tab = {
        Name = name,
        Button = button,
        Indicator = indicator,
        Content = content
    }
    
    button.MouseButton1Click:Connect(function()
        switchTab(tab)
    end)
    
    TabSystem._tabs[name] = tab
    
    if not TabSystem._currentTab then
        switchTab(tab)
    end
    
    return content
end

function TabSystem.RemoveTab(name)
    local tab = TabSystem._tabs[name]
    if not tab then return false end
    
    tab.Button:Destroy()
    tab.Content:Destroy()
    TabSystem._tabs[name] = nil
    
    if TabSystem._currentTab == tab then
        local nextTab = next(TabSystem._tabs)
        if nextTab then
            switchTab(TabSystem._tabs[nextTab])
        else
            TabSystem._currentTab = nil
        end
    end
    
    return true
end

function TabSystem.GetTab(name)
    return TabSystem._tabs[name]
end

function TabSystem.GetCurrentTab()
    return TabSystem._currentTab and TabSystem._currentTab.Name
end

function TabSystem.SelectTab(name)
    local tab = TabSystem._tabs[name]
    if tab then
        switchTab(tab)
        return true
    end
    return false
end

function TabSystem.Cleanup()
    if not TabSystem._initialized then return end
    
    for name, _ in pairs(TabSystem._tabs) do
        TabSystem.RemoveTab(name)
    end
    
    if mainContainer then
        mainContainer:Destroy()
    end
    
    mainContainer = nil
    tabBar = nil
    buttonContainer = nil
    contentArea = nil
    TabSystem._initialized = false
    TabSystem._currentTab = nil
    
    Ora:Info("TabSystem cleaned up successfully")
end

function TabSystem.Debug()
    print("\n=== TabSystem Debug ===")
    print("Initialized:", TabSystem._initialized)
    print("Container exists:", mainContainer ~= nil)
    print("TabBar exists:", tabBar ~= nil)
    print("ButtonContainer exists:", buttonContainer ~= nil)
    print("ContentArea exists:", contentArea ~= nil)
    
    print("\nTabs:")
    for name, tab in pairs(TabSystem._tabs) do
        print(string.format("- %s (Active: %s)", name, 
            TabSystem._currentTab == tab))
    end
    
    if mainContainer then
        print("\nUI Hierarchy:")
        for _, child in ipairs(mainContainer:GetChildren()) do
            print("- " .. child.Name .. " (" .. child.ClassName .. ")")
        end
    end
    print("=====================\n")
end

return TabSystem
