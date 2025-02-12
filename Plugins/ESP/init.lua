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
    
    -- Verify dependencies
    local Censura = _G.Innovare.System.Censura
    if not Censura or not Censura.Elements then
        error("Censura or its Elements not available")
    end
    
    -- Create section
    local section = Censura.Elements.Section.new({
        title = "ESP Settings"
    })
    
    -- Create highlight toggle
    local highlightToggle = Censura.Elements.Toggle.new({
        text = "Highlight Players",
        default = ESP.Enabled,
        onToggle = function(enabled)
            ESP.Enabled = enabled
            ESP:UpdateESP()
        end
    })
    
    -- Create info toggle
    local infoToggle = Censura.Elements.Toggle.new({
        text = "Show Player Info",
        default = ESP.ShowInfo,
        onToggle = function(enabled)
            ESP.ShowInfo = enabled
            ESP:UpdateESP()
        end
    })
    
    -- Set up hierarchy
    section.Parent = tab
    highlightToggle.Parent = section
    infoToggle.Parent = section
    
    -- Initialize ESP functionality
    ESP:SetupConnections()
    
    log("ESP initialization completed successfully")
end

-- Rest of the ESP code remains the same...

-- Test function
function ESP.Test()
    print("\n=== ESP Plugin Test ===")
    
    -- Test element creation
    local success, result = pcall(function()
        local testFrame = Instance.new("Frame")
        local Censura = _G.Innovare.System.Censura
        
        print("Testing section creation...")
        local section = Censura.Elements.Section.new({
            title = "Test Section"
        })
        section.Parent = testFrame
        print("Section created successfully")
        
        print("\nTesting toggle creation...")
        local toggle = Censura.Elements.Toggle.new({
            text = "Test Toggle",
            default = false,
            onToggle = function() end
        })
        toggle.Parent = section
        print("Toggle created successfully")
        
        return true
    end)
    
    if not success then
        print("Test failed:", result)
    else
        print("\nAll element creation tests passed")
    end
    
    print("========================\n")
end

return ESP
