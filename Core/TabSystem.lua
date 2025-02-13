-- TabSystem.lua
-- Manages tab creation, switching, and UI management for Innovare
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
local contentArea

-- Private Functions
local function createTabButton(name)
    local button = Utils.Create("TextButton", {
        Name = name .. "Button",
        Size = UDim2.new(0, 100, 1, -4),
        BackgroundColor3 = Styles.Colors.Controls.Button.Default,
        Text = name,
        TextColor3 = Styles.Colors.Text.Primary,
        Font = Styles.Text.Default.Font,
        TextSize = Styles.Text.Default.Size,
        AutoButtonColor = false,
        Parent = tabBar
    })
    
    -- Apply styling
    Utils.ApplyCorners(button)
    Utils.ApplyHoverEffect(button)
    
    -- Create selection indicator
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
    
    -- Setup content layout
    Utils.SetupListLayout(content)
    Utils.CreatePadding(content)
    
    return content
end

local function switchTab(tab)
    if TabSystem._currentTab == tab then return end
    
    -- Update UI states
    for _, t in pairs(TabSystem._tabs) do
        local isSelected = t == tab
        
        -- Update button appearance
        Utils.Tween(t.Button, {
            BackgroundColor3 = isSelected 
                and Styles.Colors.Controls.Button.Pressed
                or Styles.Colors.Controls.Button.Default
        })
        
        -- Update indicator
        Utils.Tween(t.Indicator, {
            BackgroundTransparency = isSelected and 0 or 1
        })
        
        -- Update content visibility
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
    if TabSystem._initialized then
        Ora:Warn("TabSystem already initialized")
        return false
    end
    
    Ora:Info("Initializing TabSystem...")
    
    -- Create main container
    mainContainer = Utils.Create("Frame", {
        Name = "TabSystemContainer",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Parent = parent
    })
    
    -- Create tab bar
    tabBar = Utils.Create("Frame", {
        Name = "TabBar",
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = Styles.Colors.Window.TitleBar,
        Parent = mainContainer
    })
    Utils.ApplyCorners(tabBar)
    
    -- Create tab button container
    local buttonContainer = Utils.Create("Frame", {
        Name = "ButtonContainer",
        Size = UDim2.new(1, -10, 1, -4),
        Position = UDim2.new(0, 5, 0, 2),
        BackgroundTransparency = 1,
        Parent = tabBar
    })
    
    -- Setup button layout
    Utils.Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5),
        Parent = buttonContainer
    })
    
    -- Create content area
    contentArea = Utils.Create("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1, 0, 1, -35),
        Position = UDim2.new(0, 0, 0, 35),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = mainContainer
    })
    
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
        Ora:Warn("Tab already exists: " .. name)
        return TabSystem._tabs[name].Content
    end
    
    -- Create tab components
    local button, indicator = createTabButton(name)
    local content = createTabContent()
    
    -- Create tab data
    local tab = {
        Name = name,
        Button = button,
        Indicator = indicator,
        Content = content
    }
    
    -- Setup button handler
    button.MouseButton1Click:Connect(function()
        switchTab(tab)
    end)
    
    -- Store tab
    TabSystem._tabs[name] = tab
    
    -- Switch to first tab automatically
    if not TabSystem._currentTab then
        switchTab(tab)
    end
    
    return content
end

function TabSystem.RemoveTab(name)
    local tab = TabSystem._tabs[name]
    if not tab then return false end
    
    -- Cleanup UI elements
    tab.Button:Destroy()
    tab.Content:Destroy()
    
    -- Remove from storage
    TabSystem._tabs[name] = nil
    
    -- Switch to another tab if this was the current tab
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

-- Debug Function
function TabSystem.Debug()
    print("\n=== TabSystem Debug ===")
    print("Initialized:", TabSystem._initialized)
    print("Container exists:", mainContainer ~= nil)
    print("TabBar exists:", tabBar ~= nil)
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
