-- 🔍 Scanner Module
local ScanModule = {}

-- State Variables
local lastScanResults = {}

-- Initialize Scanner
function ScanModule.initialize(brainrots)
    for _, brainrotName in pairs(brainrots) do
        lastScanResults[brainrotName] = 0
    end
end

-- Main Scanning Function
function ScanModule.performScan(forceSend, config, sessionStats, DataModule, ESPModule, WebhookModule)
    sessionStats.scans = sessionStats.scans + 1
    local foundPets = {}
    local totalFinds = 0
    local hasNewFinds = false

    -- Get pet details
    local petDetails = DataModule.getPetDetails()

    for _, brainrotName in pairs(DataModule.brainrots) do
        local instances = DataModule.findAllBrainrotInstances(brainrotName)
        if #instances > 0 then
            foundPets[brainrotName] = instances
            totalFinds = totalFinds + #instances
            local lastCount = lastScanResults[brainrotName] or 0
            if #instances > lastCount then
                hasNewFinds = true
            end
            lastScanResults[brainrotName] = #instances
        else
            lastScanResults[brainrotName] = 0
        end
    end

    sessionStats.totalFinds = totalFinds
    ESPModule.updateESP(foundPets, config, DataModule)

    if (hasNewFinds or forceSend) and totalFinds > 0 then
        WebhookModule.sendConsolidatedWebhook(foundPets, totalFinds, petDetails, config, sessionStats, DataModule)
    end
end

-- Get Last Scan Results
function ScanModule.getLastScanResults()
    return lastScanResults
end

return ScanModule
