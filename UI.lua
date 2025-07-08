-- 🎯 Brainrot Pet Hunter v2.1 - UI Module
-- UI.lua

local UIModule = {}

-- Create UI function
function UIModule.createUI(Window, config, sessionStats, modules)
    local ScanModule = modules.ScanModule
    local ServerHopModule = modules.ServerHopModule
    local ConfigModule = modules.ConfigModule
    local ESPModule = modules.ESPModule
    local WebhookModule = modules.WebhookModule
    local DataModule = modules.DataModule

    -- Create Main Tab
    local MainTab = Window:CreateTab('Main', 4483362458)

    -- Configuration Section
    local ConfigSection = MainTab:CreateSection('Configuration')

    local WebhookInput = MainTab:CreateInput({
        Name = 'Discord Webhook URL',
        PlaceholderText = 'Enter your webhook URL here...',
        RemoveTextAfterFocusLost = false,
        Flag = 'WebhookURL',
        Callback = function(Text)
            config.webhookUrl = Text
            ConfigModule.saveConfig(config)
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Webhook Updated & Saved",
                Text = "Discord webhook URL has been updated and saved",
                Duration = 3,
            })
        end,
    })

    -- Control Section
    local ControlSection = MainTab:CreateSection('Controls')

    local AutoScanToggle = MainTab:CreateToggle({
        Name = 'Auto Scan',
        CurrentValue = config.autoScanEnabled,
        Flag = 'AutoScan',
        Callback = function(Value)
            config.autoScanEnabled = Value
            ConfigModule.saveConfig(config)
            if Value then
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "Auto Scan Enabled & Saved",
                    Text = "Automatic scanning is now active and saved",
                    Duration = 3,
                })
            else
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "Auto Scan Disabled & Saved",
                    Text = "Automatic scanning has been stopped and saved",
                    Duration = 3,
                })
            end
        end,
    })

    local AutoServerHopToggle = MainTab:CreateToggle({
        Name = 'Auto Server Hop',
        CurrentValue = config.autoServerHopEnabled,
        Flag = 'AutoServerHop',
        Callback = function(Value)
            config.autoServerHopEnabled = Value
            ConfigModule.saveConfig(config)
            if Value then
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "Auto Server Hop Enabled & Saved",
                    Text = "Automatic server hopping is now active and saved",
                    Duration = 3,
                })
            else
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "Auto Server Hop Disabled & Saved",
                    Text = "Automatic server hopping has been stopped and saved",
                    Duration = 3,
                })
            end
        end,
    })

    local ESPToggle = MainTab:CreateToggle({
        Name = 'ESP Lines',
        CurrentValue = config.espEnabled,
        Flag = 'ESP',
        Callback = function(Value)
            config.espEnabled = Value
            ConfigModule.saveConfig(config)
            if not Value then
                ESPModule.clearAllESP()
            end
        end,
    })

    local ScanIntervalSlider = MainTab:CreateSlider({
        Name = 'Scan Interval (seconds)',
        Range = { 1, 30 },
        Increment = 1,
        CurrentValue = config.scanInterval,
        Flag = 'ScanInterval',
        Callback = function(Value)
            config.scanInterval = Value
            ConfigModule.saveConfig(config)
        end,
    })

    local ServerHopIntervalSlider = MainTab:CreateSlider({
        Name = 'Server Hop Interval (seconds)',
        Range = { 10, 600 },
        Increment = 10,
        CurrentValue = config.serverHopInterval,
        Flag = 'ServerHopInterval',
        Callback = function(Value)
            config.serverHopInterval = Value
            ConfigModule.saveConfig(config)
        end,
    })

    local MinPlayersSlider = MainTab:CreateSlider({
        Name = 'Min Players for Server Hop',
        Range = { 1, 20 },
        Increment = 1,
        CurrentValue = config.minPlayers,
        Flag = 'MinPlayers',
        Callback = function(Value)
            config.minPlayers = Value
            ConfigModule.saveConfig(config)
        end,
    })

    local PreferredPlayersSlider = MainTab:CreateSlider({
        Name = 'Preferred Player Count',
        Range = { 1, 50 },
        Increment = 1,
        CurrentValue = config.preferredPlayerCount,
        Flag = 'PreferredPlayers',
        Callback = function(Value)
            config.preferredPlayerCount = Value
            ConfigModule.saveConfig(config)
        end,
    })

    -- Action Buttons
    local ManualScanButton = MainTab:CreateButton({
        Name = 'Manual Scan & Send',
        Callback = function()
            ScanModule.performScan(true, config, sessionStats, DataModule, ESPModule, WebhookModule)
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Manual Scan",
                Text = "Performing manual scan...",
                Duration = 2,
            })
        end,
    })

    local ServerHopButton = MainTab:CreateButton({
        Name = 'Server Hop',
        Callback = function()
            local success, errorMsg = pcall(function()
                ServerHopModule.performEnhancedServerHop(config)
            end)
            if not success then
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "Server Hop Failed",
                    Text = "Failed to hop servers: " .. tostring(errorMsg),
                    Duration = 5,
                })
            end
        end,
    })

    local ResetConfigButton = MainTab:CreateButton({
        Name = 'Reset to Default Settings',
        Callback = function()
            local DEFAULT_CONFIG = ConfigModule.getDefaultConfig()
            for key, value in pairs(DEFAULT_CONFIG) do
                config[key] = value
            end
            ConfigModule.saveConfig(config)
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Settings Reset",
                Text = "All settings have been reset to defaults and saved",
                Duration = 3,
            })
            
            -- Update UI elements
            WebhookInput:Set(config.webhookUrl)
            AutoScanToggle:Set(config.autoScanEnabled)
            AutoServerHopToggle:Set(config.autoServerHopEnabled)
            ESPToggle:Set(config.espEnabled)
            ScanIntervalSlider:Set(config.scanInterval)
            ServerHopIntervalSlider:Set(config.serverHopInterval)
            MinPlayersSlider:Set(config.minPlayers)
            PreferredPlayersSlider:Set(config.preferredPlayerCount)
        end,
    })

    -- Statistics Section
    local StatsSection = MainTab:CreateSection('Statistics')

    local StatsLabel = MainTab:CreateParagraph({
        Title = 'Session Statistics',
        Content = 'Loading statistics...',
    })

    -- Function to update stats display
    local function updateStatsDisplay()
        local runtime = math.floor(tick() - sessionStats.startTime)
        local hours = math.floor(runtime / 3600)
        local minutes = math.floor((runtime % 3600) / 60)
        local seconds = runtime % 60

        local statsText = string.format(
            [[
Scans Performed: %d
Total Finds: %d
Runtime: %02d:%02d:%02d
Auto Server Hop: %s
Settings Auto-Saved: ✅
]],
            sessionStats.scans,
            sessionStats.totalFinds,
            hours,
            minutes,
            seconds,
            config.autoServerHopEnabled and 'Enabled' or 'Disabled'
        )
        StatsLabel:Set({ Title = 'Session Statistics', Content = statsText })
    end

    -- Stats Update Loop
    spawn(function()
        while true do
            updateStatsDisplay()
            wait(1)
        end
    end)

    -- Set initial values from loaded config
    WebhookInput:Set(config.webhookUrl)
    AutoScanToggle:Set(config.autoScanEnabled)
    AutoServerHopToggle:Set(config.autoServerHopEnabled)
    ESPToggle:Set(config.espEnabled)
    ScanIntervalSlider:Set(config.scanInterval)
    ServerHopIntervalSlider:Set(config.serverHopInterval)
    MinPlayersSlider:Set(config.minPlayers)
    PreferredPlayersSlider:Set(config.preferredPlayerCount)

    -- Return UI elements for external access if needed
    return {
        MainTab = MainTab,
        StatsLabel = StatsLabel,
        updateStatsDisplay = updateStatsDisplay,
        WebhookInput = WebhookInput,
        AutoScanToggle = AutoScanToggle,
        AutoServerHopToggle = AutoServerHopToggle,
        ESPToggle = ESPToggle,
        ScanIntervalSlider = ScanIntervalSlider,
        ServerHopIntervalSlider = ServerHopIntervalSlider,
        MinPlayersSlider = MinPlayersSlider,
        PreferredPlayersSlider = PreferredPlayersSlider,
    }
end

return UIModule
