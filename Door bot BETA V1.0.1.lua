--[[ 
    Roblox DOORS AI Script with Notes
    - Enemy detection (NON-FUNCTIONAL)
    - Pathfinding in development (issues with waypoint accuracy)
    - Key finding in development (BUGGED)
    - Closet hiding (NON-FUNCTIONAL)
    - Logging system implemented
    - Compatibility check for DOORS game ID implemented
--]]

-- Game ID Check
local DOORS_GAME_ID = 6839171747
if game.PlaceId ~= DOORS_GAME_ID then
    game.Players.LocalPlayer:Kick("This script only works in DOORS.")
    return
end

-- Services
local player = game.Players.LocalPlayer
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService") -- Enemy sound detection requires this service

-- Character References
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- UI Logger Function
local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "LogUI"
    screenGui.Parent = player:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0.8, 0)
    frame.Position = UDim2.new(0, 10, 0.1, 0)
    frame.BackgroundTransparency = 0.5
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.Parent = screenGui

    local uiList = Instance.new("UIListLayout")
    uiList.Parent = frame
    uiList.SortOrder = Enum.SortOrder.LayoutOrder

    return function(message, color)
        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 0, 20)
        textLabel.Text = message
        textLabel.TextColor3 = color or Color3.fromRGB(255, 255, 255)
        textLabel.BackgroundTransparency = 1
        textLabel.Parent = frame
        textLabel.TextScaled = true
    end
end

local log = createUI()

-- Enemy Detection (UNTIL TESTED, ASSUME NON-FUNCTIONAL)
local function detectEnemies()
    for _, sound in pairs(workspace:GetDescendants()) do
        if sound:IsA("Sound") and (sound.Name == "Rush" or sound.Name == "Ambush") then
            log("Enemy detected: " .. sound.Name .. "! Hiding...", Color3.fromRGB(255, 0, 0))
            return true
        end
    end
    return false
end

-- Closet Hiding (In Development: Timing and detection need testing)
local function hideInCloset()
    log("Searching for closet to hide...", Color3.fromRGB(255, 165, 0))
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name:lower():find("closet") and obj:IsA("Model") then
            local closetPart = obj:FindFirstChildWhichIsA("BasePart")
            if closetPart then
                humanoid:MoveTo(closetPart.Position)
                humanoid.MoveToFinished:Wait(5)
                log("Hiding in closet...", Color3.fromRGB(0, 255, 0))
                wait(5) -- Simulate hiding duration
                log("Enemy passed. Resuming navigation...", Color3.fromRGB(0, 255, 255))
                return
            end
        end
    end
    
    log("No closet found. Staying still...", Color3.fromRGB(255, 0, 0))
    wait(5)
end

-- Pathfinding Logic (In Development)
local function moveToPosition(targetPosition)
    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentJumpHeight = 7,
        AgentMaxSlope = 45
    })

    path:ComputeAsync(rootPart.Position, targetPosition)
    local waypoints = path:GetWaypoints()

    if #waypoints == 0 then
        log("Path not found!", Color3.fromRGB(255, 0, 0))
        return
    end

    for _, waypoint in ipairs(waypoints) do
        humanoid:MoveTo(waypoint.Position)
        local success = humanoid.MoveToFinished:Wait(2)

        if not success then
            log("Failed to reach waypoint, recalculating...", Color3.fromRGB(255, 165, 0))
            moveToPosition(targetPosition)
            return
        end
    end

    log("Successfully reached target!", Color3.fromRGB(0, 255, 0))
end

-- Key Finding Logic (In Development)
local function findKey(room)
    log("Searching for key...", Color3.fromRGB(255, 165, 0))
    for _, obj in pairs(room:GetDescendants()) do
        if obj.Name:lower():find("key") then
            log("Key found!", Color3.fromRGB(0, 255, 0))
            moveToPosition(obj.Position)
            return true
        end
    end
    log("Key not found in room.", Color3.fromRGB(255, 0, 0))
    return false
end

-- Door Interaction
local function interactWithDoor(door)
    log("Approaching door...", Color3.fromRGB(0, 255, 255))
    moveToPosition(door.PrimaryPart.Position)

    if door:FindFirstChild("Lock") then
        log("Door is locked! Searching for key...", Color3.fromRGB(255, 165, 0))
        local room = door.Parent
        if not findKey(room) then
            log("Key not found. Skipping door...", Color3.fromRGB(255, 0, 0))
            return
        end
    end

    door.ClientOpen:FireServer()
    log("Door opened!", Color3.fromRGB(0, 255, 0))
end

-- Main AI Loop
log("AI Started. Searching for doors...", Color3.fromRGB(0, 255, 255))
while true do
    for _, room in pairs(workspace.CurrentRooms:GetChildren()) do
        local door = room:FindFirstChild("Door")
        if door and not door:GetAttribute("Opened") then
            interactWithDoor(door)
            door:SetAttribute("Opened", true) -- Track opened doors
        end
    end
    wait(2)
end
