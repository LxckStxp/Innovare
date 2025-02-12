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

-- Debug function
local function debugPrint(...)
    print("[ESP Debug]", ...)
end

function ESP.Init(tab)
    debugPrint("Initializing ESP plugin...")
    
    -- Verify dependencies
    if not _G.Innovare then
        error("Innovare not found")
    end
    if not _G.Innovare.System.Censura then
        error("Censura not found")
    end
    if not _G.Innovare.System.Censura.Elements then
        error("Censura Elements not found")
    end
    
    local Censura = _G.Innovare.System.Censura
    
    -- Create main section with error handling
    local success, section = pcall(function()
        debugPrint("Creating ESP settings section...")
        local newSection = Censura.Elements.Section.new({
            title = "ESP Settings"
        })
        if not newSection then
            error("Failed to create section")
        end
        newSection.Parent = tab
        return newSection
    end)
    
    if not success then
        error("Failed to create section: " .. tostring(section))
    end
    
    -- Add toggle for highlights with error handling
    success = pcall(function()
        debugPrint("Creating highlight toggle...")
        local toggle = Censura.Elements.Toggle.new({
            text = "Highlight Players",
            default = ESP.Enabled,
            onToggle = function(enabled)
                ESP.Enabled = enabled
                ESP:UpdateESP()
            end
        })
        if not toggle then
            error("Failed to create highlight toggle")
        end
        toggle.Parent = section
    end)
    
    if not success then
        error("Failed to create highlight toggle")
    end
    
    -- Add toggle for info display with error handling
    success = pcall(function()
        debugPrint("Creating info toggle...")
        local toggle = Censura.Elements.Toggle.new({
            text = "Show Player Info",
            default = ESP.ShowInfo,
            onToggle = function(enabled)
                ESP.ShowInfo = enabled
                ESP:UpdateESP()
            end
        })
        if not toggle then
            error("Failed to create info toggle")
        end
        toggle.Parent = section
    end)
    
    if not success then
        error("Failed to create info toggle")
    end
    
    -- Initialize ESP with error handling
    success = pcall(function()
        debugPrint("Setting up ESP connections...")
        ESP:SetupConnections()
    end)
    
    if not success then
        error("Failed to setup ESP connections")
    end
    
    debugPrint("ESP plugin initialized successfully!")
end

-- Rest of the ESP code remains the same...
