-- Core/Types.lua
local Types = {}

--[[ Plugin Type Definition
    Defines the required structure for all plugins
    @interface Plugin
    @field Name string - The name of the plugin
    @field Description string - Brief description of the plugin's functionality
    @field Version string - Plugin version number
    @field Author string - Plugin author's name
    @field Dependencies table - List of required dependencies
    @field Settings table - Plugin-specific settings
    @field Init function - Initialization function
    @field Cleanup function - Cleanup function for proper disposal
]]
Types.PluginTemplate = {
    Name = "",
    Description = "",
    Version = "1.0.0",
    Author = "",
    Dependencies = {},
    Settings = {},
    Init = function(tab) end,
    Cleanup = function() end
}

--[[ Plugin Settings Type
    Defines the structure for plugin settings
    @interface PluginSetting
    @field type string - The type of setting (e.g., "toggle", "slider", "input")
    @field default any - Default value for the setting
    @field min number? - Minimum value (for number settings)
    @field max number? - Maximum value (for number settings)
    @field options table? - Available options (for dropdown settings)
]]
Types.PluginSetting = {
    type = "string",
    default = nil,
    min = nil,
    max = nil,
    options = nil
}

-- Example Plugin Settings Schema
Types.ExampleSettings = {
    enabled = {
        type = "toggle",
        default = false
    },
    color = {
        type = "color",
        default = Color3.fromRGB(255, 0, 0)
    },
    speed = {
        type = "slider",
        default = 50,
        min = 0,
        max = 100
    },
    mode = {
        type = "dropdown",
        default = "Normal",
        options = {"Normal", "Advanced", "Expert"}
    }
}

-- Plugin Validation Function
function Types.ValidatePlugin(plugin)
    assert(type(plugin) == "table", "Plugin must be a table")
    assert(type(plugin.Name) == "string", "Plugin must have a Name (string)")
    assert(type(plugin.Description) == "string", "Plugin must have a Description (string)")
    assert(type(plugin.Version) == "string", "Plugin must have a Version (string)")
    assert(type(plugin.Author) == "string", "Plugin must have an Author (string)")
    assert(type(plugin.Dependencies) == "table", "Plugin must have Dependencies (table)")
    assert(type(plugin.Settings) == "table", "Plugin must have Settings (table)")
    assert(type(plugin.Init) == "function", "Plugin must have Init function")
    assert(type(plugin.Cleanup) == "function", "Plugin must have Cleanup function")
    
    return true
end

-- Setting Validation Functions
function Types.ValidateSettings(settings, schema)
    for key, setting in pairs(settings) do
        assert(schema[key], string.format("Invalid setting: %s", key))
        Types.ValidateSetting(setting, schema[key])
    end
    return true
end

function Types.ValidateSetting(value, schema)
    if schema.type == "toggle" then
        assert(type(value) == "boolean", "Toggle value must be boolean")
    elseif schema.type == "slider" then
        assert(type(value) == "number", "Slider value must be number")
        assert(value >= schema.min and value <= schema.max, 
            string.format("Value must be between %d and %d", schema.min, schema.max))
    elseif schema.type == "color" then
        assert(typeof(value) == "Color3", "Color value must be Color3")
    elseif schema.type == "dropdown" then
        assert(table.find(schema.options, value), 
            string.format("Value must be one of: %s", table.concat(schema.options, ", ")))
    end
    return true
end

-- Example Usage Demonstration
function Types.DemonstrateUsage()
    -- Example Plugin Definition
    local ExamplePlugin = {
        Name = "ExamplePlugin",
        Description = "An example plugin demonstrating proper structure",
        Version = "1.0.0",
        Author = "LxckStxp",
        Dependencies = {"Censura"},
        Settings = {
            enabled = false,
            color = Color3.fromRGB(255, 0, 0),
            speed = 50,
            mode = "Normal"
        },
        Init = function(tab)
            print("Plugin initialized")
        end,
        Cleanup = function()
            print("Plugin cleaned up")
        end
    }
    
    -- Validate Plugin Structure
    local success, error = pcall(function()
        return Types.ValidatePlugin(ExamplePlugin)
    end)
    
    if success then
        print("Plugin validation successful")
    else
        warn("Plugin validation failed:", error)
    end
    
    -- Validate Plugin Settings
    success, error = pcall(function()
        return Types.ValidateSettings(ExamplePlugin.Settings, Types.ExampleSettings)
    end)
    
    if success then
        print("Settings validation successful")
    else
        warn("Settings validation failed:", error)
    end
end

-- Plugin Event Types
Types.PluginEvents = {
    ON_ENABLE = "OnEnable",
    ON_DISABLE = "OnDisable",
    ON_SETTING_CHANGED = "OnSettingChanged",
    ON_TAB_FOCUS = "OnTabFocus",
    ON_TAB_BLUR = "OnTabBlur"
}

-- Plugin State Types
Types.PluginState = {
    DISABLED = "Disabled",
    ENABLED = "Enabled",
    ERROR = "Error",
    LOADING = "Loading"
}

-- Plugin Priority Levels
Types.PluginPriority = {
    HIGHEST = 1,
    HIGH = 2,
    NORMAL = 3,
    LOW = 4,
    LOWEST = 5
}

return Types
