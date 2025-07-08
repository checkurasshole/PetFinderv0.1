-- 📊 Data Module
local DataModule = {}

-- Brainrot Pet Names
DataModule.brainrots = {
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

-- Utility Functions
function DataModule.getCurrentTime()
    local time = os.date('*t')
    return string.format('%02d:%02d:%02d', time.hour, time.min, time.sec)
end

function DataModule.getPlayerCount()
    local Players = game:GetService('Players')
    return #Players:GetPlayers()
end

function DataModule.getGameInstanceId()
    local success, result = pcall(function()
        return game.JobId
    end)
    return success and result or 'unknown'
end

-- Pet Detail Functions
function DataModule.getTextLabelText(overhead, name)
    local label = overhead:FindFirstChild(name)
    return label and label:IsA("TextLabel") and label.Text or "N/A"
end

function DataModule.getPetDetails()
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
                        DisplayName = DataModule.getTextLabelText(overhead, "DisplayName"),
                        Generation = DataModule.getTextLabelText(overhead, "Generation"),
                        Mutation = DataModule.getTextLabelText(overhead, "Mutation"),
                        Price = DataModule.getTextLabelText(overhead, "Price"),
                        Rarity = DataModule.getTextLabelText(overhead, "Rarity"),
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

-- Pet Finding Functions
function DataModule.findAllBrainrotInstances(brainrotName)
    local instances = {}
    for _, child in pairs(workspace:GetChildren()) do
        if child.Name == brainrotName then
            table.insert(instances, child)
        end
    end
    
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
    
    if #instances == 0 then
        for _, child in pairs(workspace:GetChildren()) do
            if child.Name:find(brainrotName) or brainrotName:find(child.Name) then
                table.insert(instances, child)
            end
        end
    end
    
    return instances
end

function DataModule.getBrainrotPosition(brainrotInstance)
    if brainrotInstance:FindFirstChild('HumanoidRootPart') then
        return brainrotInstance.HumanoidRootPart.Position
    elseif brainrotInstance:FindFirstChild('RootPart') then
        return brainrotInstance.RootPart.Position
    elseif brainrotInstance:FindFirstChild('FakeRootPart') then
        return brainrotInstance.FakeRootPart.Position
    elseif brainrotInstance:FindFirstChild('Torso') then
        return brainrotInstance.Torso.Position
    elseif brainrotInstance:FindFirstChild('Head') then
        return brainrotInstance.Head.Position
    elseif brainrotInstance.PrimaryPart then
        return brainrotInstance.PrimaryPart.Position
    else
        local cf, size = brainrotInstance:GetBoundingBox()
        return cf.Position
    end
end

return DataModule
