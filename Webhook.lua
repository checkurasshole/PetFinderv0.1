-- 🔗 Webhook Module
local WebhookModule = {}

-- Services
local HttpService = game:GetService('HttpService')

-- Constants
local MAX_RETRIES = 3
local RETRY_DELAY = 2
local PLACE_ID = game.PlaceId
local JOB_ID = game.JobId

-- Send Webhook with Retry
function WebhookModule.sendWebhookWithRetry(data, webhookUrl, retries)
    retries = retries or 0
    local success, response = pcall(function()
        return http_request({
            Url = webhookUrl,
            Method = 'POST',
            Headers = {
                ['Content-Type'] = 'application/json',
            },
            Body = HttpService:JSONEncode(data),
        })
    end)
    
    if success and response.StatusCode == 204 then
        return true
    elseif retries < MAX_RETRIES then
        wait(RETRY_DELAY)
        return WebhookModule.sendWebhookWithRetry(data, webhookUrl, retries + 1)
    else
        warn('Failed to send webhook after', MAX_RETRIES, 'retries')
        return false
    end
end

-- Create Discord Embed
function WebhookModule.createDiscordEmbed(foundPets, totalFinds, petDetails, sessionStats, DataModule)
    local petsFoundList = {}
    for brainrotName, instances in pairs(foundPets) do
        if #instances > 0 then
            table.insert(petsFoundList, {
                name = brainrotName,
                value = string.format('**%d found**', #instances),
                inline = true,
            })
        end
    end

    -- Add pet details if available
    local petDetailsText = ""
    if petDetails and next(petDetails) then
        local detailCount = 0
        for _, entry in pairs(petDetails) do
            if detailCount < 5 then -- Limit to first 5 unique pets
                local info = entry.info
                petDetailsText = petDetailsText .. string.format(
                    "**%s** (x%d)\n📊 Gen: %s | 🧬 Mut: %s | 💰 %s | 🎖️ %s\n\n",
                    info.DisplayName,
                    entry.count,
                    info.Generation,
                    info.Mutation,
                    info.Price,
                    info.Rarity
                )
                detailCount = detailCount + 1
            end
        end
    end

    local embed = {
        title = '🎯 **TARGET ACQUIRED!**',
        description = string.format('**%d Brainrot Pets Found!**', totalFinds),
        color = 16711935,
        fields = {
            {
                name = '📍 **Location Info**',
                value = string.format(
                    '```lua\ngame:GetService("TeleportService"):TeleportToPlaceInstance(%d, "%s")\n```\n👤 Players: %d',
                    PLACE_ID,
                    JOB_ID,
                    DataModule.getPlayerCount()
                ),
                inline = false,
            },
        },
        footer = {
            text = string.format('🔍 Session: %d scans | 📊 Total finds: %d | 🎯 Place ID: %s', sessionStats.scans, sessionStats.totalFinds, PLACE_ID),
        },
        timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
    }

    -- Add pet details field if available
    if petDetailsText ~= "" then
        table.insert(embed.fields, {
            name = '🐾 **Pet Details**',
            value = petDetailsText,
            inline = false,
        })
    end

    local maxPetFields = math.min(#petsFoundList, 15)
    for i = 1, maxPetFields do
        table.insert(embed.fields, petsFoundList[i])
    end

    if #petsFoundList > 15 then
        local remainingPets = {}
        for i = 16, #petsFoundList do
            table.insert(remainingPets, petsFoundList[i].name)
        end
        table.insert(embed.fields, {
            name = '➕ **Additional Pets**',
            value = table.concat(remainingPets, ', '),
            inline = false,
        })
    end

    return embed
end

-- Send Consolidated Webhook
function WebhookModule.sendConsolidatedWebhook(foundPets, totalFinds, petDetails, config, sessionStats, DataModule)
    if not config.webhookUrl or config.webhookUrl == '' or totalFinds == 0 then
        return
    end

    local embed = WebhookModule.createDiscordEmbed(foundPets, totalFinds, petDetails, sessionStats, DataModule)

    local data = {
        content = string.format('🚨 **Found %d pets!** 🚨', totalFinds),
        embeds = { embed },
        username = 'Brainrot Hunter v2.1',
        avatar_url = 'https://cdn.discordapp.com/emojis/1234567890123456789.png',
    }

    spawn(function()
        local success = WebhookModule.sendWebhookWithRetry(data, config.webhookUrl)
        if success then
            Rayfield:Notify({
                Title = 'Webhook Sent',
                Content = string.format('Found %d pets reported to Discord with detailed info', totalFinds),
                Duration = 3,
                Image = 4483362458,
            })
        else
            Rayfield:Notify({
                Title = 'Webhook Failed',
                Content = 'Failed to send webhook after multiple retries',
                Duration = 5,
                Image = 4483362458,
            })
        end
    end)
end

return WebhookModule
