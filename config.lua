-- 🔧 Configuration Module
local ConfigModule = {}

-- Default Configuration
ConfigModule.DEFAULT_CONFIG = {
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

-- Load Configuration
function ConfigModule.loadConfig()
    local config = table.clone(ConfigModule.DEFAULT_CONFIG)
    
    local success, savedConfig = pcall(function()
        return Rayfield:LoadConfiguration()
    end)

    if success and savedConfig then
        for key, value in pairs(savedConfig) do
            if ConfigModule.DEFAULT_CONFIG[key] ~= nil then
                config[key] = value
            end
        end
        print('Configuration loaded successfully!')
    else
        print('Using default configuration')
    end
    
    return config
end

-- Save Configuration
function ConfigModule.saveConfig(config)
    local success = pcall(function()
        Rayfield:SaveConfiguration(config)
    end)

    if success then
        print('Configuration saved successfully!')
    else
        warn('Failed to save configuration')
    end
end

-- Reset Configuration
function ConfigModule.resetConfig()
    return table.clone(ConfigModule.DEFAULT_CONFIG)
end

return ConfigModule
