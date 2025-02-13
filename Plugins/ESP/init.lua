--[[ 
    ESP Plugin for Innovare
    Author: LxckStxp
    Version: 1.0.0
    
    Features:
    - Player highlighting
    - Player information display
    - Customizable colors and settings
    - Performance optimized
--]]

local ESP = {
    Name = "ESP",
    Enabled = false,
    ShowInfo = false,
    Settings = {
        UpdateRate = 1/30, -- 30 FPS
        HighlightColor = Color3.fromRGB(255, 0, 0),
        TextColor = Color3.fromRGB(255, 255, 255),
        MaxDistance = 1000,
        MinTextSize = 12,
        MaxTextSize = 18
    },
    _connections = {},
    _highlights = {},
    _labels = {}
}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

-- References
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Logger setup
local Ora = _G.Innovare.System.Oratio.Logger.new({
    moduleName = "ESP"
})

-- Private Functions
local function createHighlight(player)
    local highlight = Instance.new("Highlight")
    highlight.FillColor = ESP.Settings.HighlightColor
    highlight.OutlineColor = ESP.Settings.HighlightColor
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Adornee = player.Character
    highlight.Parent = CoreGui
    
    return highlight
end

local function createLabel(player)
    local label = Instance.new("BillboardGui")
    label.Size = UDim2.new(0, 200, 0, 50)
    label.AlwaysOnTop = true
    label.Parent = CoreGui
    
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.TextColor3 = ESP.Settings.TextColor
    text.TextStrokeTransparency = 0
    text.TextSize = ESP.Settings.MaxTextSize
    text.Font = Enum.Font.GothamBold
    text.Parent = label
    
    return label
end

local function updateLabel(label, player)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        label.Enabled = false
        return
    end
    
    local rootPart = player.Character.HumanoidRootPart
    local humanoid = player.Character:FindFirstChild("Humanoid")
    
    -- Update position
    label.Adornee = rootPart
    
    -- Update text
    local textLabel = label:FindFirstChildOfClass("TextLabel")
    if textLabel then
        local distance = (rootPart.Position - Camera.CFrame.Position).Magnitude
        local health = humanoid and humanoid.Health or 0
        
        textLabel.Text = string.format(
            "%s\nHealth: %d\nDistance: %d",
            player.Name,
            math.floor(health),
            math.floor(distance)
        )
        
        -- Scale text size with distance
        local scale = math.clamp(1 - (distance / ESP.Settings.MaxDistance), 0.1, 1)
        textLabel.TextSize = ESP.Settings.MinTextSize + 
            (ESP.Settings.MaxTextSize - ESP.Settings.MinTextSize) * scale
    end
    
    label.Enabled = true
end

-- Public Functions
function ESP:SetupConnections()
    -- Clear existing connections
    for _, connection in pairs(self._connections) do
        connection:Disconnect()
    end
    self._connections = {}
    
    -- Player added
    table.insert(self._connections, Players.PlayerAdded:Connect(function(player)
        if player ~= LocalPlayer then
            self:AddPlayer(player)
        end
    end))
    
    -- Player removing
    table.insert(self._connections, Players.PlayerRemoving:Connect(function(player)
        self:RemovePlayer(player)
    end))
    
    -- Update loop
    table.insert(self._connections, RunService.RenderStepped:Connect(function()
        if self.Enabled then
            self:UpdateESP()
        end
    end))
    
    -- Add existing players
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            self:AddPlayer(player)
        end
    end
    
    Ora:Info("ESP connections setup complete")
end

function ESP:AddPlayer(player)
    -- Create highlight
    self._highlights[player] = createHighlight(player)
    
    -- Create label
    self._labels[player] = createLabel(player)
    
    -- Character added/removed handling
    table.insert(self._connections, player.CharacterAdded:Connect(function(character)
        if self._highlights[player] then
            self._highlights[player].Adornee = character
        end
    end))
end

function ESP:RemovePlayer(player)
    -- Cleanup highlight
    if self._highlights[player] then
        self._highlights[player]:Destroy()
        self._highlights[player] = nil
    end
    
    -- Cleanup label
    if self._labels[player] then
        self._labels[player]:Destroy()
        self._labels[player] = nil
    end
end

function ESP:UpdateESP()
    for player, highlight in pairs(self._highlights) do
        highlight.Enabled = self.Enabled
    end
    
    for player, label in pairs(self._labels) do
        if self.Enabled and self.ShowInfo then
            updateLabel(label, player)
        else
            label.Enabled = false
        end
    end
end

function ESP:Cleanup()
    -- Disconnect all connections
    for _, connection in pairs(self._connections) do
        connection:Disconnect()
    end
    
    -- Cleanup highlights
    for player, highlight in pairs(self._highlights) do
        highlight:Destroy()
    end
    
    -- Cleanup labels
    for player, label in pairs(self._labels) do
        label:Destroy()
    end
    
    -- Clear tables
    self._connections = {}
    self._highlights = {}
    self._labels = {}
    
    Ora:Info("ESP cleanup complete")
end

function ESP.Init(tab)
    Ora:Info("Initializing ESP plugin...")
    
    -- Create UI
    local Censura = _G.Innovare.System.Censura
    local section = Censura.Elements.Section.new({
        title = "ESP Settings"
    })
    
    -- Create toggles
    local highlightToggle = Censura.Elements.Toggle.new({
        text = "Highlight Players",
        default = ESP.Enabled,
        onToggle = function(enabled)
            ESP.Enabled = enabled
            ESP:UpdateESP()
        end
    })
    
    local infoToggle = Censura.Elements.Toggle.new({
        text = "Show Player Info",
        default = ESP.ShowInfo,
        onToggle = function(enabled)
            ESP.ShowInfo = enabled
            ESP:UpdateESP()
        end
    })
    
    -- Create color picker
    local colorPicker = Censura.Elements.ColorPicker.new({
        text = "ESP Color",
        default = ESP.Settings.HighlightColor,
        onColorChanged = function(color)
            ESP.Settings.HighlightColor = color
            for _, highlight in pairs(ESP._highlights) do
                highlight.FillColor = color
                highlight.OutlineColor = color
            end
        end
    })
    
    -- Set up hierarchy
    section.Parent = tab
    highlightToggle.Parent = section
    infoToggle.Parent = section
    colorPicker.Parent = section
    
    -- Initialize ESP functionality
    ESP:SetupConnections()
    
    Ora:Info("ESP initialization complete")
end

-- Debug Function
function ESP:Debug()
    print("\n=== ESP Debug ===")
    print("Enabled:", self.Enabled)
    print("Show Info:", self.ShowInfo)
    print("\nActive Players:", #Players:GetPlayers() - 1)
    print("Highlights:", #self._highlights)
    print("Labels:", #self._labels)
    print("Connections:", #self._connections)
    print("==================\n")
end

return ESP
