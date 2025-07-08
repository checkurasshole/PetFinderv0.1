-- pet-detector.lua - Pet detection and scanning module
local PetDetector = {}

-- Services
local Players = game:GetService('Players')
local workspace = game:GetService('Workspace')

-- Brainrot pet names
PetDetector.brainrots = {
    'Boneca Ambalabu',
    'Gangster Footera',
    'Chimpanzini Bananini',
    'Fluriflura',
    'Tim Cheese',
    'Tralalero Tralala',
    'Tung Tung Tung Sahur',
    'Los Tralaleritos',
    'Orangutini Ananassini',
    'Brri Brri Bicus Dicus Bombicus',
    'Talpa Di Fero',
    'Rhino Toasterino',
    'Graipuss Medussi',
    'Bambini Crostini',
    'Blueberrinni Octopusini',
    'Girafa Celestre',
    'La Grande Combinasion',
    'Glorbo Fruttodrillo',
    'Ta Ta Ta Ta Sahur',
    'Bombardiro Crocodilo',
    'Svinina Bombardino',
    'Bananita Dolphinita',
    'Bombombini Gusini',
    'Noobini Pizzanini',
    'Ballerina Cappuccina',
    'Trulimero Trulicina',
    'Brr Brr Patapim',
    'Cappuccino Assassino',
    'Trippi Troppi',
    'Lirili Larila',
    'Cocofanto Elefanto',
    'Frigo Camelo',
    'Burbaloni Loliloli',
    'La Vacca Saturno Saturnita',
    'Odin Din Din Dun',
    'Chef Crabracadabra',
}

-- Initialize the pet detector
function PetDetector:init(config)
    self.config = config
    print("✅ Pet Detector initialized")
end

-- Find all instances of a specific brainrot pet
function PetDetector:findAllBrainrotInstances(brainrotName)
    local instances = {}
    
    -- Direct name match
    for _, child in pairs(workspace:GetChildren()) do
        if child.Name == brainrotName then
            table.insert(instances, child)
        end
    end
    
    -- If no direct matches, try variations
    if #instances == 0 then
        local variations = {
            brainrotName:gsub(' ', ''),
            brainrotName:lower(),
            brainrotName:upper(),
        }
        
        for _, variation in pairs(variations) do
            for _, child in pairs(workspace:GetChildren()) do
                if child.Name == variation then
                    table.insert(instances, child)
                end
            end
        end
    end
    
    -- If still no matches, try partial matching
    if #instances == 0 then
        for _, child in pairs(workspace:GetChildren()) do
            if child.Name:find(brainrotName) or brainrotName:find(child.Name) then
                table.insert(instances, child)
            end
        end
    end
    
    return instances
end

-- Get position of a brainrot instance
function PetDetector:getBrainrotPosition(brainrotInstance)
    local possibleParts = {
        'HumanoidRootPart',
        'RootPart', 
        'FakeRootPart',
        'Torso',
        'Head'
    }
    
    for _, partName in ipairs(possibleParts) do
        local part = brainrotInstance:FindFirstChild(partName)
        if part then
            return part.Position
        end
    end
    
    -- Try PrimaryPart
    if brainrotInstance.PrimaryPart then
        return brainrotInstance.PrimaryPart.Position
    end
    
    -- Last resort: use bounding box
    local cf, size = brainrotInstance:GetBoundingBox()
    return cf.Position
end

-- Get text from a TextLabel
function PetDetector:getTextLabelText(overhead, name)
    local label = overhead:FindFirstChild(name)
    return label and label:IsA("TextLabel") and label.Text or "N/A"
end

-- Get detailed pet information from plots
function PetDetector:getPetDetails()
    local Plots = workspace:WaitForChild("Plots")
    local animals = {}

    for _, plot in ipairs(Plots:GetChildren()) do
        local plotID = plot.Name
        local podiums = plot:FindFirstChild("AnimalPodiums")

        if podiums then
            for _, podium in ipairs(podiums:GetChildren()) do
                local base = podium:FindFirstChild("Base")
                local spawn = base and base:FindFirstChild("Spawn")
                local attachment = spawn and spawn:FindFirstChild("Attachment")
                local overhead = attachment and attachment:FindFirstChild("AnimalOverhead")

                if overhead then
                    local data = {
                        DisplayName = self:getTextLabelText(overhead, "DisplayName"),
                        Generation = self:getTextLabelText(overhead, "Generation"),
                        Mutation = self:getTextLabelText(overhead, "Mutation"),
                        Price = self:getTextLabelText(overhead, "Price"),
                        Rarity = self:getTextLabelText(overhead, "Rarity"),
                        PlotID = plotID,
                        Position = spawn.Position
                    }

                    local key = data.DisplayName .. "|" .. data.Generation .. "|" .. data.Mutation .. "|" .. data.Price .. "|" .. data.Rarity

                    if animals[key] then
                        animals[key].count = animals[key].count + 1
                        table.insert(animals[key].positions, data.Position)
                        table.insert(animals[key].plotIDs, plotID)
                    else
                        animals[key] = {
                            count = 1,
                            info = data,
                            positions = {data.Position},
                            plotIDs = {plotID}
                        }
                    end
                end
            end
        end
    end

    return animals
end

-- Main scanning function
function PetDetector:scan(lastScanResults)
    local foundPets = {}
    local totalFinds = 0
    local hasNewFinds = false
    
    for _, brainrotName in pairs(self.brainrots) do
        local instances = self:findAllBrainrotInstances(brainrotName)
        
        if #instances > 0 then
            foundPets[brainrotName] = instances
            totalFinds = totalFinds + #instances
            
            -- Check if this is a new find
            local lastCount = lastScanResults[brainrotName] or 0
            if #instances > lastCount then
                hasNewFinds = true
            end
        end
    end
    
    return foundPets, totalFinds, hasNewFinds
end

-- Get current player count
function PetDetector:getPlayerCount()
    return #Players:GetPlayers()
end

-- Get current time formatted
function PetDetector:getCurrentTime()
    local time = os.date('*t')
    return string.format('%02d:%02d:%02d', time.hour, time.min, time.sec)
end

-- Get game instance ID
function PetDetector:getGameInstanceId()
    local success, result = pcall(function()
        return game.JobId
    end)
    return success and result or 'unknown'
end

-- Get place ID
function PetDetector:getPlaceId()
    return game.PlaceId
end

return PetDetector
