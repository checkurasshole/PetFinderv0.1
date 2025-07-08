-- 👁️ ESP Module
local ESPModule = {}

-- Services
local RunService = game:GetService('RunService')
local Players = game:GetService('Players')
local player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ESP State
local espLines = {}

-- Initialize ESP
function ESPModule.initialize(brainrots)
    for _, brainrotName in pairs(brainrots) do
        espLines[brainrotName] = {}
    end
end

-- Create ESP for Instance
function ESPModule.createESPForInstance(brainrotInstance, brainrotName, index, DataModule)
    local line = Drawing.new('Line')
    line.Thickness = 2
    line.Color = Color3.fromRGB(255, 0, 255)
    line.Transparency = 1
    line.Visible = false

    local text = Drawing.new('Text')
    text.Size = 18
    text.Center = true
    text.Outline = true
    text.OutlineColor = Color3.new(0, 0, 0)
    text.Font = 2
    text.Color = Color3.fromRGB(255, 255, 255)
    text.Visible = false

    local distanceText = Drawing.new('Text')
    distanceText.Size = 14
    distanceText.Center = true
    distanceText.Outline = true
    distanceText.OutlineColor = Color3.new(0, 0, 0)
    distanceText.Font = 2
    distanceText.Color = Color3.fromRGB(255, 255, 0)
    distanceText.Visible = false

    local connection = RunService.RenderStepped:Connect(function()
        if not brainrotInstance or not brainrotInstance:IsDescendantOf(workspace) then
            line.Visible = false
            text.Visible = false
            distanceText.Visible = false
            return
        end

        local success, brainrotPos = pcall(DataModule.getBrainrotPosition, brainrotInstance)
        if not success then
            return
        end

        local screenPos, onScreen = Camera:WorldToViewportPoint(brainrotPos)
        if onScreen and screenPos.Z > 0 then
            local playerPos = player.Character and player.Character:FindFirstChild('HumanoidRootPart')
            local distance = playerPos and math.floor((playerPos.Position - brainrotPos).Magnitude) or 0

            local from = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            local to = Vector2.new(screenPos.X, screenPos.Y)

            line.From = from
            line.To = to
            line.Visible = true

            local displayName = brainrotName
            if index then
                displayName = brainrotName .. ' [' .. index .. ']'
            end

            text.Position = Vector2.new(screenPos.X, screenPos.Y - 30)
            text.Text = displayName
            text.Visible = true

            distanceText.Position = Vector2.new(screenPos.X, screenPos.Y + 20)
            distanceText.Text = distance .. 'm'
            distanceText.Visible = true
        else
            line.Visible = false
            text.Visible = false
            distanceText.Visible = false
        end
    end)

    return {
        line = line,
        text = text,
        distanceText = distanceText,
        connection = connection,
        cleanup = function()
            connection:Disconnect()
            line:Remove()
            text:Remove()
            distanceText:Remove()
        end,
    }
end

-- Clear All ESP
function ESPModule.clearAllESP()
    for brainrotName, espObjects in pairs(espLines) do
        for _, espObj in pairs(espObjects) do
            espObj.cleanup()
        end
        espLines[brainrotName] = {}
    end
end

-- Update ESP
function ESPModule.updateESP(foundPets, config, DataModule)
    ESPModule.clearAllESP()
    if not config.espEnabled then
        return
    end
    
    for brainrotName, instances in pairs(foundPets) do
        espLines[brainrotName] = {}
        for i, instance in pairs(instances) do
            local espObj = ESPModule.createESPForInstance(instance, brainrotName, #instances > 1 and i or nil, DataModule)
            table.insert(espLines[brainrotName], espObj)
        end
    end
end

-- Get ESP Lines (for external access)
function ESPModule.getESPLines()
    return espLines
end

return ESPModule
