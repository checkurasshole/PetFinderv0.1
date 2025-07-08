-- server-hopper.lua
-- Handles server hopping functionality

local ServerHopper = {}

-- Services
local TeleportService = game:GetService('TeleportService')
local HttpService = game:GetService('HttpService')
local Players = game:GetService('Players')

-- Constants
local PLACE_ID = game.PlaceId
local JOB_ID = game.JobId
local MAX_RETRIES = 3
local RETRY_DELAY = 2

-- State
local config = nil
local player = Players.LocalPlayer
local isTeleporting = false

function ServerHopper:init(configModule)
    config = configModule
    print('✅ ServerHopper initialized')
end

-- Private Functions
local function getServersFromAPI()
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
                    and server.playing >= config.get('minPlayers')
                    and server.playing <= config.get('maxPlayers')
                    and server.maxPlayers > server.playing

                if isValidServer then
                    server.priority = math.abs(server.playing - config.get('preferredPlayerCount'))
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

local function teleportToServer(serverId, playerCount)
    local success, errorMessage = pcall(function()
        TeleportService:TeleportToPlaceInstance(PLACE_ID, serverId, player)
    end)

    if success then
        return true
    else
        return false, errorMessage
    end
end

local function performEnhancedServerHop()
    if isTeleporting then
        return false, "Already teleporting"
    end

    isTeleporting = true
    
    local servers = getServersFromAPI()
    
    if #servers > 0 then
        local attempts = 0
        local maxServerAttempts = math.min(5, #servers)

        while attempts < maxServerAttempts do
            attempts = attempts + 1
            local selectedServer = servers[attempts]

            local success, error = teleportToServer(selectedServer.id, selectedServer.playing)

            if success then
                print(string.format('✅ Teleporting to server with %d players', selectedServer.playing))
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
        print('✅ Using fallback teleport method')
        return true
    else
        print('❌ All server hop methods failed')
        isTeleporting = false
        return false, "All server hop methods failed"
    end
end

-- Public Functions
function ServerHopper:hop()
    spawn(function()
        local success, errorMsg = pcall(performEnhancedServerHop)
        if not success then
            warn('❌ Server hop failed:', errorMsg)
        end
    end)
end

function ServerHopper:getServerInfo()
    return {
        placeId = PLACE_ID,
        jobId = JOB_ID,
        playerCount = #Players:GetPlayers(),
        maxPlayers = Players.MaxPlayers,
    }
end

function ServerHopper:findBestServers(limit)
    limit = limit or 10
    local servers = getServersFromAPI()
    local bestServers = {}
    
    for i = 1, math.min(limit, #servers) do
        table.insert(bestServers, {
            id = servers[i].id,
            players = servers[i].playing,
            maxPlayers = servers[i].maxPlayers,
            priority = servers[i].priority,
        })
    end
    
    return bestServers
end

function ServerHopper:isValidServer(serverData)
    return serverData.id ~= JOB_ID
        and serverData.playing >= config.get('minPlayers')
        and serverData.playing <= config.get('maxPlayers')
        and serverData.maxPlayers > serverData.playing
end

function ServerHopper:canHop()
    return not isTeleporting
end

-- Reset teleporting flag after some time (fallback)
spawn(function()
    while true do
        wait(30)
        if isTeleporting then
            isTeleporting = false
            print('🔄 Reset teleporting flag')
        end
    end
end)

return ServerHopper
