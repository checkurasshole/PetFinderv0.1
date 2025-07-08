-- ui-manager.lua
-- Handles all UI creation and management

local UIManager = {}

-- State
local app = nil
local Window = nil
local MainTab = nil
local StatsLabel = nil
local WebhookInput = nil
local uiElements = {}

function UIManager:init(appInstance)
    app = appInstance
    self:createWindow()
    self:setupTabs()
    self:loadSavedSettings()
    print('✅ UIManager initialized')
end

function UIManager:createWindow()
    Window = app.Rayfield:CreateWindow({
        Name = 'Brainrot Pet Hunter v2.1',
        LoadingTitle = 'Loading Enhanced Pet Hunter...',
        LoadingSubtitle = 'by YourName - Now with Pet Details!',
        ConfigurationSaving = {
            Enabled = true,
            FolderName = 'BrainrotESP',
            FileName = 'PetHunterConfig',
        },
        Discord = {
            Enabled = false,
            Invite = '',
            RememberJoins = false,
        },
        KeySystem = false,
    })
end

function UIManager:setupTabs()
    MainTab = Window:CreateTab('Main', 4483362458)
    
    -- Configuration Section
    local ConfigSection = MainTab:CreateSection('Configuration')
    
    WebhookInput = MainTab:CreateInput({
        Name = 'Discord Webhook URL',
        PlaceholderText = 'Enter your webhook URL here...',
        RemoveTextAfterFocusLost = false,
        Flag = 'WebhookURL',
        Callback = function(Text)
            app.Config.set('webhookUrl', Text)
            app.Config.save()
            app.Rayfield:Notify({
                Title = 'Webhook Updated & Saved',
                Content = 'Discord webhook URL has been updated and saved',
                Duration = 3,
                Image = 4483362458,
            })
        end,
    })
    
    -- Control Section
    local ControlSection = MainTab:CreateSection('Controls')
    
    uiElements.AutoScanToggle = MainTab:CreateToggle({
        Name = 'Auto Scan',
        CurrentValue = app.Config.get('autoScanEnabled'),
        Flag = 'AutoScan',
        Callback = function(Value)
            app.Config.set('autoScanEnabled', Value)
            app.Config.save()
            app.Rayfield:Notify({
                Title = Value and 'Auto Scan Enabled & Saved' or 'Auto Scan Disabled & Saved',
                Content = Value and 'Automatic scanning is now active and saved' or 'Automatic scanning has been stopped and saved',
                Duration = 3,
                Image = 4483362458,
            })
        end,
    })
    
    uiElements.AutoServerHopToggle = MainTab:CreateToggle({
        Name = 'Auto Server Hop',
        CurrentValue = app.Config.get('autoServerHopEnabled'),
        Flag = 'AutoServerHop',
        Callback = function(Value)
            app.Config.set('autoServerHopEnabled', Value)
            app.Config.save()
            app.Rayfield:Notify({
                Title = Value and 'Auto Server Hop Enabled & Saved' or 'Auto Server Hop Disabled & Saved',
                Content = Value and 'Automatic server hopping is now active and saved' or 'Automatic server hopping has been stopped and saved',
                Duration = 3,
                Image = 4483362458,
            })
        end,
    })
    
    uiElements.ESPToggle = MainTab:CreateToggle({
        Name = 'ESP Lines',
        CurrentValue = app.Config.get('espEnabled'),
        Flag = 'ESP',
        Callback = function(Value)
            app.Config.set('espEnabled', Value)
            app.Config.save()
            if not Value then
                app.ESPManager:clearAll()
            end
        end,
    })
    
    uiElements.ScanIntervalSlider = MainTab:CreateSlider({
        Name = 'Scan Interval (seconds)',
        Range = { 1, 30 },
        Increment = 1,
        CurrentValue = app.Config.get('scanInterval'),
        Flag = 'ScanInterval',
        Callback = function(Value)
            app.Config.set('scanInterval', Value)
            app.Config.save()
        end,
    })
    
    uiElements.ServerHopIntervalSlider = MainTab:CreateSlider({
        Name = 'Server Hop Interval (seconds)',
        Range = { 10, 600 },
        Increment = 10,
        CurrentValue = app.Config.get('serverHopInterval'),
        Flag = 'ServerHopInterval',
        Callback = function(Value)
            app.Config.set('serverHopInterval', Value)
            app.Config.save()
        end,
    })
    
    uiElements.MinPlayersSlider = MainTab:CreateSlider({
        Name = 'Min Players for Server Hop',
        Range = { 1, 20 },
        Increment = 1,
        CurrentValue = app.Config.get('minPlayers'),
        Flag = 'MinPlayers',
        Callback = function(Value)
            app.Config.set('minPlayers', Value)
            app.Config.save()
        end,
    })
    
    uiElements.PreferredPlayersSlider = MainTab:CreateSlider({
        Name = 'Preferred Player Count',
        Range = { 1, 50 },
        Increment = 1,
        CurrentValue = app.Config.get('preferredPlayerCount'),
        Flag = 'PreferredPlayers',
        Callback = function(Value)
            app.Config.set('preferredPlayerCount', Value)
            app.Config.save()
        end,
    })
    
    -- Action Buttons
    MainTab:CreateButton({
        Name = 'Manual Scan & Send',
        Callback = function()
            app:performScan(true)
            app.Rayfield:Notify({
                Title = 'Manual Scan',
                Content = 'Performing manual scan...',
                Duration = 2,
                Image = 4483362458,
            })
        end,
    })
    
    MainTab:CreateButton({
        Name = 'Server Hop',
        Callback = function()
            if app.ServerHopper:canHop() then
                app.ServerHopper:hop()
                app.Rayfield:Notify({
                    Title = 'Server Hop',
                    Content = 'Attempting to hop servers...',
                    Duration = 3,
                    Image = 4483362458,
                })
            else
                app.Rayfield:Notify({
                    Title = 'Server Hop',
                    Content = 'Already teleporting, please wait...',
                    Duration = 3,
                    Image = 4483362458,
                })
            end
        end,
    })
    
    MainTab:CreateButton({
        Name = 'Test Webhook',
        Callback = function()
            local success = app.WebhookManager:testWebhook()
            app.Rayfield:Notify({
                Title = success and 'Webhook Test Passed' or 'Webhook Test Failed',
                Content = success and 'Test message sent successfully!' or 'Failed to send test message',
                Duration = 3,
                Image = 4483362458,
            })
        end,
    })
    
    MainTab:CreateButton({
        Name = 'Reset to Default Settings',
        Callback = function()
            app.Config.resetToDefaults()
            self:loadSavedSettings()
            app.Rayfield:Notify({
                Title = 'Settings Reset',
                Content = 'All settings have been reset to defaults and saved',
                Duration = 3,
                Image = 4483362458,
            })
        end,
    })
    
    -- Statistics Section
    local StatsSection = MainTab:CreateSection('Statistics')
    
    StatsLabel = MainTab:CreateParagraph({
        Title = 'Session Statistics',
        Content = 'Loading statistics...',
    })
    
    -- Server Info Section
    local ServerSection = MainTab:CreateSection('Server Information')
    
    local serverInfo = app.ServerHopper:getServerInfo()
    MainTab:CreateParagraph({
        Title = 'Current Server',
        Content = string.format(
            'Place ID: %s\nJob ID: %s\nPlayers: %d/%d',
            serverInfo.placeId,
            serverInfo.jobId,
            serverInfo.playerCount,
            serverInfo.maxPlayers
        ),
    })
end

function UIManager:loadSavedSettings()
    if WebhookInput then
        WebhookInput:Set(app.Config.get('webhookUrl'))
    end
    
    for name, element in pairs(uiElements) do
        if name:find('Toggle') then
            local configKey = name:gsub('Toggle', ''):gsub('Auto', 'auto'):gsub('ESP', 'esp')
            if configKey == 'AutoScan' then configKey = 'autoScanEnabled' end
            if configKey == 'AutoServerHop' then configKey = 'autoServerHopEnabled' end
            if configKey == 'esp' then configKey = 'espEnabled' end
            element:Set(app.Config.get(configKey))
        elseif name:find('Slider') then
            local configKey = name:gsub('Slider', ''):gsub('([A-Z])', function(c) return c:lower() end)
            if configKey == 'scanInterval' then element:Set(app.Config.get('scanInterval')) end
            if configKey == 'serverHopInterval' then element:Set(app.Config.get('serverHopInterval')) end
            if configKey == 'minPlayers' then element:Set(app.Config.get('minPlayers')) end
            if configKey == 'preferredPlayers' then element:Set(app.Config.get('preferredPlayerCount')) end
        end
    end
end

function UIManager:updateStats(sessionStats)
    if not StatsLabel then return end
    
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
        app.Config.get('autoServerHopEnabled') and 'Enabled' or 'Disabled'
    )
    
    StatsLabel:Set({ Title = 'Session Statistics', Content = statsText })
end

function UIManager:show()
    -- Window is automatically shown when created
    print('✅ UI is now visible')
end

function UIManager:hide()
    if Window then
        Window:Destroy()
        Window = nil
    end
end

function UIManager:notify(title, content, duration, image)
    if app and app.Rayfield then
        app.Rayfield:Notify({
            Title = title,
            Content = content,
            Duration = duration or 3,
            Image = image or 4483362458,
        })
    end
end

return UIManager
