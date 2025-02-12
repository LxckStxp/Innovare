-- Plugins/ESP/init.lua
local ESP = {
    Enabled = false,
    ShowInfo = false,
    Connections = {},
    Highlights = {},
    Labels = {}
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Debug logging function
local function log(...)
    print("[ESP]", ...)
end

function ESP.Init(tab)
    log("Starting ESP initialization")
    
    -- Verify tab parameter
    if not tab then
        error("Tab parameter is nil")
    end
    
    log("Tab parameter verified")
    
    -- Verify Censura access
    local Censura = _G.Innovare.System.Censura
    if not Censura then
        error("Censura not available")
    end
    
    log("Censura verified")
    
    -- Create section with error handling
    local section
    local success, err = pcall(function()
        section = Censura.Elements.Section.new({
            title = "ESP Settings"
        })
        
        if not section then
            error("Section creation returned nil")
        end
        
        section.Parent = tab
    end)
    
    if not success then
        error("Failed to create section: " .. tostring(err))
    end
    
    log("Section created successfully")
    
    -- Create toggles with error handling
    success, err = pcall(function()
        -- Highlight toggle
        local highlightToggle = Censura.Elements.Toggle.new({
            text = "Highlight Players",
            default = ESP.Enabled,
            onToggle = function(enabled)
                ESP.Enabled = enabled
                ESP:UpdateESP()
            end
        })
        
        if not highlightToggle then
            error("Highlight toggle creation returned nil")
        end
        
        highlightToggle.Parent = section
        
        -- Info toggle
        local infoToggle = Censura.Elements.Toggle.new({
            text = "Show Player Info",
            default = ESP.ShowInfo,
            onToggle = function(enabled)
                ESP.ShowInfo = enabled
                ESP:UpdateESP()
            end
        })
        
        if not infoToggle then
            error("Info toggle creation returned nil")
        end
        
        infoToggle.Parent = section
    end)
    
    if not success then
        error("Failed to create toggles: " .. tostring(err))
    end
    
    log("Toggles created successfully")
    
    -- Setup ESP with error handling
    success, err = pcall(function()
        ESP:SetupConnections()
    end)
    
    if not success then
        error("Failed to setup ESP connections: " .. tostring(err))
    end
    
    log("ESP initialization completed successfully")
end 

function ESP:SetupConnections()
    -- Player Added
    table.insert(ESP.Connections, Players.PlayerAdded:Connect(function(player)
        ESP:AddESP(player)
    end))
    
    -- Player Removing
    table.insert(ESP.Connections, Players.PlayerRemoving:Connect(function(player)
        ESP:RemoveESP(player)
    end))
    
    -- Add ESP to existing players
    for _, player in ipairs(Players:GetPlayers()) do
        ESP:AddESP(player)
    end
end

function ESP:AddESP(player)
    -- Create highlight
    local highlight = Instance.new("Highlight")
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.Enabled = ESP.Enabled
    ESP.Highlights[player] = highlight
    
    -- Create info label
    local label = Instance.new("BillboardGui")
    label.Size = UDim2.new(0, 200, 0, 50)
    label.AlwaysOnTop = true
    label.Enabled = ESP.ShowInfo
    
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.TextColor3 = Color3.new(1, 1, 1)
    text.TextStrokeTransparency = 0
    text.TextSize = 14
    text.Font = Enum.Font.SourceSansBold
    text.Parent = label
    
    ESP.Labels[player] = label
    
    -- Update ESP
    ESP:UpdatePlayerESP(player)
end

function ESP:RemoveESP(player)
    if ESP.Highlights[player] then
        ESP.Highlights[player]:Destroy()
        ESP.Highlights[player] = nil
    end
    
    if ESP.Labels[player] then
        ESP.Labels[player]:Destroy()
        ESP.Labels[player] = nil
    end
end

function ESP:UpdatePlayerESP(player)
    local highlight = ESP.Highlights[player]
    local label = ESP.Labels[player]
    
    if player.Character then
        -- Update highlight
        highlight.Parent = player.Character
        highlight.Enabled = ESP.Enabled
        
        -- Update label
        label.Parent = player.Character:FindFirstChild("Head")
        label.Enabled = ESP.ShowInfo
        label.TextLabel.Text = string.format(
            "%s\nHealth: %d",
            player.Name,
            player.Character:FindFirstChild("Humanoid") and 
            player.Character.Humanoid.Health or 0
        )
    end
end

function ESP:UpdateESP()
    for player, _ in pairs(ESP.Highlights) do
        ESP:UpdatePlayerESP(player)
    end
end

-- Cleanup function
function ESP:Cleanup()
    for _, connection in ipairs(ESP.Connections) do
        connection:Disconnect()
    end
    
    for player, _ in pairs(ESP.Highlights) do
        ESP:RemoveESP(player)
    end
end

return ESP
