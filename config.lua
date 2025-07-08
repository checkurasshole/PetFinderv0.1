-- config.lua - Configuration management module
local Config = {}

-- Default configuration
Config.DEFAULT_CONFIG = {
    webhookUrl = 'https://discord.com/api/webhooks/1387967088685223968/Xhp7nvhz4g8F0jKV7QB9WJdNSr47H9xTV0lKZDZusQtwjtuLbq30iGbWZVppEfyvzaQC',
    autoScanEnabled = true,
    autoServerHopEnabled = false,
    espEnabled = true,
    scanInterval = 5,
    serverHopInterval = 300,
    placeId = game.PlaceId,
    minPlayers = 1,
    maxPlayers = math.huge,
    preferredPlayerCount = 10,
}

-- Current configuration
Config.current = {}

-- Initialize configuration
function Config:init()
    self.current = self:clone(self.DEFAULT_CONFIG)
    self:load()
end

-- Deep clone table
function Config:clone(original)
    local copy = {}
    for key, value in pairs(original) do
        if type(value) == "table" then
            copy[key] = self:clone(value)
        else
            copy[key] = value
        end
    end
    return copy
end

-- Load configuration from Rayfield
function Config:load()
    local success, savedConfig = pcall(function()
        -- This will be set by the main script after Rayfield is loaded
        if _G.RayfieldInstance then
            return _G.RayfieldInstance:LoadConfiguration()
        end
        return nil
    end)

    if success and savedConfig then
        for key, value in pairs(savedConfig) do
            if self.DEFAULT_CONFIG[key] ~= nil then
                self.current[key] = value
            end
        end
        print('✅ Configuration loaded successfully!')
    else
        print('⚠️ Using default configuration')
    end
end

-- Save configuration to Rayfield
function Config:save()
    local success = pcall(function()
        if _G.RayfieldInstance then
            _G.RayfieldInstance:SaveConfiguration(self.current)
        end
    end)

    if success then
        print('✅ Configuration saved successfully!')
    else
        warn('❌ Failed to save configuration')
    end
end

-- Get configuration value
function Config:get(key)
    return self.current[key]
end

-- Set configuration value and save
function Config:set(key, value)
    if self.DEFAULT_CONFIG[key] ~= nil then
        self.current[key] = value
        self:save()
        return true
    end
    return false
end

-- Reset to default configuration
function Config:reset()
    self.current = self:clone(self.DEFAULT_CONFIG)
    self:save()
    print('✅ Configuration reset to defaults')
end

-- Get all current configuration
function Config:getAll()
    return self:clone(self.current)
end

-- Validate configuration
function Config:validate()
    local valid = true
    local errors = {}
    
    -- Validate webhook URL
    if self.current.webhookUrl and self.current.webhookUrl ~= "" then
        if not string.match(self.current.webhookUrl, "^https://discord%.com/api/webhooks/") then
            table.insert(errors, "Invalid webhook URL format")
            valid = false
        end
    end
    
    -- Validate numeric values
    local numericFields = {
        "scanInterval", "serverHopInterval", "minPlayers", 
        "maxPlayers", "preferredPlayerCount"
    }
    
    for _, field in ipairs(numericFields) do
        if type(self.current[field]) ~= "number" then
            table.insert(errors, field .. " must be a number")
            valid = false
        end
    end
    
    -- Validate ranges
    if self.current.scanInterval < 1 or self.current.scanInterval > 30 then
        table.insert(errors, "scanInterval must be between 1 and 30")
        valid = false
    end
    
    if self.current.serverHopInterval < 10 or self.current.serverHopInterval > 600 then
        table.insert(errors, "serverHopInterval must be between 10 and 600")
        valid = false
    end
    
    if self.current.minPlayers < 1 or self.current.minPlayers > 50 then
        table.insert(errors, "minPlayers must be between 1 and 50")
        valid = false
    end
    
    if self.current.preferredPlayerCount < 1 or self.current.preferredPlayerCount > 50 then
        table.insert(errors, "preferredPlayerCount must be between 1 and 50")
        valid = false
    end
    
    return valid, errors
end

-- Export methods that can be called statically
Config.get = function(key)
    return Config.current[key]
end

Config.set = function(key, value)
    if Config.DEFAULT_CONFIG[key] ~= nil then
        Config.current[key] = value
        Config:save()
        return true
    end
    return false
end

return Config
