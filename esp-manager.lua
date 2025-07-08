-- esp-manager.lua - ESP (Extra Sensory Perception) management module
local ESPManager = {}

-- Services
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local Camera = workspace.CurrentCamera
local player = Players.LocalPlayer

-- ESP storage
ESPManager.espLines = {}

-- Initialize ESP manager
function ESPManager:init(config)
    self.config = config
    self.espLines = {}
    print("✅ ESP Manager initialized")
end

-- Get position of a brainrot instance
function ESPManager:getBrainrotPosition(brainrotInstance)
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

-- Create ESP for a single instance
function ESPManager:createESPForInstance(brainrotInstance, brainrotName, index)
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
        if not self.config.get("espEnabled") or not brainrotInstance or not brainrotInstance:IsDescendantOf(workspace) then
            line.Visible = false
            text.Visible = false
            distanceText.Visible = false
            return
        end

        local success, brainrotPos = pcall(function()
            return self:getBrainrotPosition(brainrotInstance)
        end)
        
        if not success then
            return
        end

        local screenPos, onScreen = Camera:WorldToViewportPoint(brainrotPos)
        if onScreen and screenPos.Z > 0 then
            -- Calculate distance to player
            local playerPos = player.Character and player.Character:FindFirstChild('HumanoidRootPart')
            local distance = playerPos and math.floor((playerPos.Position - brainrotPos).Magnitude) or 0

            -- Draw line from bottom center of screen to pet
            local from = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            local to = Vector2.new(screenPos.X, screenPos.Y)

            line.From = from
            line.To = to
            line.Visible = true

            -- Display name with index if multiple instances
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

-- Clear all ESP elements
function ESPManager:clearAll()
    for brainrotName, espObjects in pairs(self.espLines) do
        for _, espObj in pairs(espObjects) do
            espObj.cleanup()
        end
        self.espLines[brainrotName] = {}
    end
end

-- Update ESP for found pets
function ESPManager:update(foundPets)
    self:clearAll()
    
    if not self.config.get("espEnabled") then
        return
    end
    
    for brainrotName, instances in pairs(foundPets) do
        self.espLines[brainrotName] = {}
        
        for i, instance in pairs(instances) do
            local espObj = self:createESPForInstance(
                instance, 
                brainrotName, 
                #instances > 1 and i or nil
            )
            table.insert(self.espLines[brainrotName], espObj)
        end
    end
end

-- Toggle ESP visibility
function ESPManager:toggle(enabled)
    if enabled then
        print("✅ ESP enabled")
    else
        self:clearAll()
        print("❌ ESP disabled")
    end
end

-- Cleanup function
function ESPManager:cleanup()
    self:clearAll()
    print("🧹 ESP Manager cleaned up")
end

return ESPManager
