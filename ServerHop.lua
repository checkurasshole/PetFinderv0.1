-- 🔄 Server Hop Module
local ServerHopModule = {}

-- Services
local TeleportService = game:GetService('TeleportService')
local HttpService = game:GetService('HttpService')
local Players = game:GetService('Players')

local player = Players.LocalPlayer
local PLACE_ID = game.PlaceId
local JOB_ID = game.JobId

-- Get Servers from API
function ServerHopModule.getServersFromAPI(config)
    local servers = {}
    local cursor = ''
    local attempts = 0
    local maxAttempts = 5

    repeat
        attempts = attempts + 1
        local url = string.format(
            'https://games.roblox.com/v1/games/%d/servers/Public?limit=100&sortOrder=Asc&cursor=%s',
            PLACE_ID,
            cursor
        )

        local success, result = pcall(function()
            local response = game:HttpGet(url)
            return HttpService:JSONDecode(response)
        end)

        if success and result and result.data then
            for _, server in pairs(result.data) do
                local isValidServer = server.id ~= JOB_ID
                    and server.playing >= config.minPlayers
                    and server.playing <= config.maxPlayers
                    and server.maxPlayers > server.playing

                if isValidServer then
                    server.priority = math.abs(server.playing - config.preferredPlayerCount)
                    table.insert(servers, server)
                end
            end
            cursor = result.nextPageCursor or ''
        else
            if attempts >= maxAttempts then
                break
            end
            wait(1)
        end
    until cursor == '' or #servers >= 50 or attempts >= maxAttempts

    if #servers > 0 then
        table.sort(servers, function(a, b)
            return a.priority < b.priority
        end)
    end

    return servers
end

-- Teleport to Server
function ServerHopModule.teleportToServer(serverId, playerCount)
    local success, errorMessage = pcall(function()
        TeleportService:TeleportToPlaceInstance(PLACE_ID, serverId, player)
    end)

    if success then
        return true
    else
        return false, errorMessage
    end
end

-- Perform Enhanced Server Hop
function ServerHopModule.performEnhancedServerHop(config)
    local servers = ServerHopModule.getServersFromAPI(config)
    
    if #servers > 0 then
        local attempts = 0
        local maxServerAttempts = math.min(5, #servers)

        while attempts < maxServerAttempts do
            attempts = attempts + 1
            local selectedServer = servers[attempts]

            local success, error = ServerHopModule.teleportToServer(selectedServer.id, selectedServer.playing)

            if success then
                Rayfield:Notify({
                    Title = 'Server Hop Success',
                    Content = string.format('Teleporting to server with %d players', selectedServer.playing),
                    Duration = 3,
                    Image = 4483362458,
                })
                return true
            else
                if attempts < maxServerAttempts then
                    wait(0.5)
                end
            end
        end
    end

    -- Fallback method
    local success = pcall(function()
        TeleportService:Teleport(PLACE_ID, player)
    end)

    if success then
        Rayfield:Notify({
            Title = 'Server Hop (Fallback)',
            Content = 'Using fallback teleport method',
            Duration = 3,
            Image = 4483362458,
        })
        return true
    else
        Rayfield:Notify({
            Title = 'Server Hop Failed',
            Content = 'All server hop methods failed',
            Duration = 5,
            Image = 4483362458,
        })
        return false
    end
end

return ServerHopModule
