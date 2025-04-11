local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

--------------------------------------------------
-- Helper: Case-insensitive check in a table.
--------------------------------------------------
local function containsIgnoreCase(tbl, name)
    name = name:lower()
    for _, v in ipairs(tbl) do
        if v:lower() == name then
            return true
        end
    end
    return false
end

--------------------------------------------------
-- Fetch lifetime users (OG Buyers) from remote JSON - LOAD SYNCHRONOUSLY
--------------------------------------------------
local LifetimeUsers = {}
local function loadLifetimeUsers()
    local success, result = pcall(function()
        local response = request({
            Method = "GET",
            Url = "https://raw.githubusercontent.com/JejcoTwiUmYQXhBpKMDl/deinemudda/refs/heads/main/lifetimeUsers.json"
        })
        return HttpService:JSONDecode(response)
    end)
    if success then
        LifetimeUsers = result
        print("Lifetime users loaded successfully.") -- Confirmation message
    else
        warn("Failed to load lifetime users:", result)
    end
end
loadLifetimeUsers() -- Load synchronously - wait for this to complete

--------------------------------------------------
-- Helper: Check if a player is an OG buyer (ignoring case)
--------------------------------------------------
local function isLifetimeUser(player)
    for _, username in pairs(LifetimeUsers) do
        if username and player.Name:lower() == username:lower() then
            return true
        end
    end
    return false
end

--------------------------------------------------
-- Helper: Remove spaces from a string.
--------------------------------------------------
local function modifyString(randomText)
    local modified = ""
    for char in randomText:gmatch(".") do
        if char ~= " " then
            modified = modified .. char
        end
    end
    return modified
end

--------------------------------------------------
-- Chat message for spam.
--------------------------------------------------
local message = "AK ADMIN ABCDEFGH()"
local modifiedMessage = modifyString(message)

-- Removed Chat Spam Functionality
spawn(function()
    -- Removed spam functionality as per previous instructions
end)

--------------------------------------------------
-- Chat-Based Whitelisting:
-- When a player chats the above message, they get the "AK USER" tag.
--------------------------------------------------
local ChatWhitelist = {}  -- Keys are stored as player.Name:lower()

--------------------------------------------------
-- Configuration and Rank Colors
--------------------------------------------------
local CONFIG = {
    TAG_SIZE = UDim2.new(0, 100, 0, 35),
    TAG_OFFSET = Vector3.new(0, 2.4, 0),
    MAX_DISTANCE = 1000000,
    SCALE_DISTANCE = 150,
    WHITELIST_UPDATE_INTERVAL = 5,
    MAX_RETRY_ATTEMPTS = 10,
    RETRY_DELAY = 3,
    TELEPORT_DISTANCE = 5,
    TELEPORT_HEIGHT = 0.5,
    DISTANCE_THRESHOLD = 50 -- studs at which tag minimizes
}

local RankColors = {
    ["AK KING"] = {
        primary = Color3.fromRGB(20, 20, 20),
        accent = Color3.fromRGB(255, 215, 0)
    },
    ["AK CO OWNER"] = {
        primary = Color3.fromRGB(20, 20, 20),
        accent = Color3.fromRGB(138, 43, 226)
    },
    ["AK DADDY"] = {
        primary = Color3.fromRGB(20, 20, 20),
        accent = Color3.fromRGB(0, 191, 255)
    },
    ["AK STAFF"] = {
        primary = Color3.fromRGB(20, 20, 20),
        accent = Color3.fromRGB(255, 252, 132)
    },
    ["AK ADVERTISER"] = {
        primary = Color3.fromRGB(20, 20, 20),
        accent = Color3.fromRGB(255, 69, 0)
    },
    ["AK HELPER"] = {
        primary = Color3.fromRGB(20, 20, 20),
        accent = Color3.fromRGB(169, 169, 169)
    },
    ["AK USER"] = {
        primary = Color3.fromRGB(20, 20, 20),
        accent = Color3.fromRGB(114, 47, 55)
    },
    ["OG BUYER"] = {
        primary = Color3.fromRGB(20, 20, 20),
        accent = Color3.fromRGB(255, 105, 180)
    },
    ["AK LUCKYGOD"] = { -- Added AK LUCKYGOD tag
        primary = Color3.fromRGB(20, 20, 20),
        accent = Color3.fromRGB(124, 252, 0)
    }
}

--------------------------------------------------
-- Notification UI (for local player's prompt)
--------------------------------------------------
local hasShownNotification = false -- Track if notification is shown

local function createNotificationUI()
    if hasShownNotification then return end
    hasShownNotification = true

    local gui = Instance.new("ScreenGui")
    gui.Name = "TagNotification"
    gui.ResetOnSpawn = false

    local frame = Instance.new("Frame")
    frame.Name = "Frame"
    frame.Size = UDim2.new(0, 280, 0, 140)
    frame.Position = UDim2.new(0.5, -140, 0.5, -70)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BackgroundTransparency = 0
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local blur = Instance.new("BlurEffect")
    blur.Size = 10
    blur.Parent = Lighting

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.8
    stroke.Thickness = 1
    stroke.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 35)
    title.Position = UDim2.new(0, 0, 0, 10)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextSize = 16
    title.Text = "Tag Visibility Settings"
    title.TextTransparency = 0
    title.Parent = frame

    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(0.9, 0, 0, 40)
    messageLabel.Position = UDim2.new(0.05, 0, 0.35, 0)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.TextColor3 = Color3.new(0.9, 0.9, 0.9)
    messageLabel.TextSize = 14
    messageLabel.TextWrapped = true
    messageLabel.Text = "Would you like to display your rank tag above your character?"
    messageLabel.TextTransparency = 0
    messageLabel.Parent = frame

    local function createButton(text, position, color)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0.35, 0, 0, 30)
        button.Position = position
        button.BackgroundColor3 = color
        button.BorderSizePixel = 0
        button.Font = Enum.Font.GothamBold
        button.TextColor3 = Color3.new(1, 1, 1)
        button.TextSize = 14
        button.Text = text
        button.AutoButtonColor = true
        button.BackgroundTransparency = 0
        button.TextTransparency = 0
        button.Parent = frame

        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 6)
        buttonCorner.Parent = button

        return button
    end

    local yesButton = createButton("Yes", UDim2.new(0.1, 0, 0.7, 0), Color3.fromRGB(46, 204, 113))
    local noButton = createButton("No", UDim2.new(0.55, 0, 0.7, 0), Color3.fromRGB(231, 76, 60))

    return gui, yesButton, noButton, blur
end

--------------------------------------------------
-- Teleport Function
--------------------------------------------------
local function teleportToPlayer(targetPlayer)
    -- Teleport function remains the same
    local localPlayer = Players.LocalPlayer
    local character = localPlayer.Character
    local targetCharacter = targetPlayer.Character
    if not (character and targetCharacter) then return end

    local humanoid = character:FindFirstChild("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local targetHRP = targetCharacter:FindFirstChild("HumanoidRootPart")
    if not (humanoid and hrp and targetHRP) then return end

    local targetCFrame = targetHRP.CFrame
    local teleportPosition = targetCFrame.Position - (targetCFrame.LookVector * CONFIG.TELEPORT_DISTANCE)
    teleportPosition = teleportPosition + Vector3.new(0, CONFIG.TELEPORT_HEIGHT, 0)

    local particlepart = Instance.new("Part", workspace)
    particlepart.Transparency = 1
    particlepart.Anchored = true
    particlepart.CanCollide = false
    particlepart.Position = hrp.Position

    local transmitter1 = Instance.new("ParticleEmitter")
    transmitter1.Texture = "http://www.roblox.com/asset/?id=89296104222585"
    transmitter1.Size = NumberSequence.new(4)
    transmitter1.Lifetime = NumberRange.new(0.15, 0.15)
    transmitter1.Rate = 100
    transmitter1.TimeScale = 0.25
    transmitter1.VelocityInheritance = 1
    transmitter1.Drag = 5
    transmitter1.Parent = particlepart

    local particlepart2 = Instance.new("Part", workspace)
    particlepart2.Transparency = 1
    particlepart2.Anchored = true
    particlepart2.CanCollide = false
    particlepart2.Position = teleportPosition

    local transmitter2 = Instance.new("ParticleEmitter")
    transmitter2.Texture = "http://www.roblox.com/asset/?id=89296104222585"
    transmitter2.Size = NumberSequence.new(4)
    transmitter2.Lifetime = NumberRange.new(0.15, 0.15)
    transmitter2.Rate = 100
    transmitter2.TimeScale = 0.25
    transmitter2.VelocityInheritance = 1
    transmitter2.Drag = 5
    transmitter2.Parent = particlepart2

    local fadeTime = 0.1
    local tweenInfo = TweenInfo.new(fadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local meshParts = {}
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("MeshPart") then
            table.insert(meshParts, part)
        end
    end

    for _, part in ipairs(meshParts) do
        local tween = TweenService:Create(part, tweenInfo, {Transparency = 1})
        tween:Play()
    end
    task.wait(fadeTime)

    hrp.CFrame = CFrame.new(teleportPosition, targetHRP.Position)

    local teleportSound = Instance.new("Sound")
    teleportSound.SoundId = "rbxassetid://5066021887"
    local head = character:FindFirstChild("Head")
    if head then
        teleportSound.Parent = head
    else
        teleportSound.Parent = hrp
    end
    teleportSound.Volume = 0.5
    teleportSound:Play()

    for _, part in ipairs(meshParts) do
        local tween = TweenService:Create(part, tweenInfo, {Transparency = 0})
        tween:Play()
    end

    task.wait(1)
    particlepart:Destroy()
    particlepart2:Destroy()
end

--------------------------------------------------
-- Helper function to brighten colors.
-- Uses Lerp to blend the given color with white.
--------------------------------------------------
local function brightenColor(color, factor)
    return color:Lerp(Color3.new(1, 1, 1), factor)
end

--------------------------------------------------
-- Main Tag Attachment Function (for roles)
--------------------------------------------------
local function attachTagToHead(character, player, rankText)
    local head = character:WaitForChild("Head", 5)
    if not head then return end

    local existingTag = head:FindFirstChild("RankTag")
    if existingTag then existingTag:Destroy() end

    local tag = Instance.new("BillboardGui")
    tag.Adornee = head
    tag.Active = true
    tag.Name = "RankTag"
    tag.Size = CONFIG.TAG_SIZE
    tag.StudsOffset = CONFIG.TAG_OFFSET
    tag.AlwaysOnTop = true
    tag.MaxDistance = CONFIG.MAX_DISTANCE

    -- Container: modern, dark background with smooth rounded corners.
    local container = Instance.new("TextButton")
    container.Name = "TagContainer"
    container.Size = UDim2.new(1, 0, 1, 0)
    -- Even darker background and transparency
    container.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    container.BackgroundTransparency = 0.7
    container.BorderSizePixel = 0
    container.Text = ""
    container.AutoButtonColor = false
    container.ZIndex = 2
    container.Parent = tag
    container.ClipsDescendants = true

    local outerTrace = Instance.new("UIStroke")
    outerTrace.Color = RankColors[rankText].accent
    outerTrace.Thickness = 2
    outerTrace.Transparency = 0.5
    outerTrace.Parent = container

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.2, 8)
    corner.Parent = container

    -- Emoji container (always visible).
    local emojiContainer = Instance.new("Frame")
    emojiContainer.Size = UDim2.new(0.25, 0, 0.9, 0)
    emojiContainer.Position = UDim2.new(0.02, 0, 0.05, 0)
    emojiContainer.BackgroundTransparency = 1
    emojiContainer.Parent = container

    local emoji = Instance.new("TextLabel")
    emoji.Size = UDim2.new(1, 0, 1, 0)
    emoji.BackgroundTransparency = 1
    emoji.TextSize = 24 -- Increased emoji size
    -- Use pure white for emoji for maximum visibility
    emoji.TextColor3 = Color3.new(1, 1, 1) -- Pure white emoji
    emoji.Font = Enum.Font.GothamBold

    local emojiMap = {
        ["AK KING"] = "👑",
        ["AK CO OWNER"] = "⚡",
        ["AK DADDY"] = "💎",
        ["AK STAFF"] = "🔰",
        ["AK ADVERTISER"] = "📢",
        ["AK HELPER"] = "📢",
        ["AK USER"] = "♦️",
        ["OG BUYER"] = "∞",
        ["AK LUCKYGOD"] = "🍀"
    }
    emoji.Text = emojiMap[rankText] or "⭐"
    emoji.Parent = emojiContainer

    -- Rank frame for text and accent.
    local rankFrame = Instance.new("Frame")
    rankFrame.Name = "RankFrame"
    rankFrame.Size = UDim2.new(0.68, 0, 0.45, 0)
    rankFrame.Position = UDim2.new(0.28, 0, 0.1, 0)
    rankFrame.BackgroundColor3 = RankColors[rankText].accent
    rankFrame.BackgroundTransparency = 0.8
    rankFrame.Parent = container

    local rankCorner = Instance.new("UICorner")
    rankCorner.CornerRadius = UDim.new(0.5, 0)
    rankCorner.Parent = rankFrame

    local rankLabel = Instance.new("TextLabel")
    rankLabel.Name = "RankLabel"
    rankLabel.Size = UDim2.new(1, 0, 1, 0)
    rankLabel.BackgroundTransparency = 1
    rankLabel.Text = rankText
    rankLabel.TextColor3 = Color3.new(1, 1, 1) -- White text
    rankLabel.TextSize = 16 -- Increased text size
    rankLabel.Font = Enum.Font.GothamBold
    rankLabel.TextXAlignment = Enum.TextXAlignment.Center
    rankLabel.TextScaled = true
    rankLabel.Parent = rankFrame

    -- Username label.
    local userLabel = Instance.new("TextLabel")
    userLabel.Name = "UserLabel"
    userLabel.Size = UDim2.new(0.58, 0, 0.3, 0)
    userLabel.Position = UDim2.new(0.38, 0, 0.6, 0)
    userLabel.BackgroundTransparency = 1
    userLabel.Text = "@" .. player.Name
    -- Use pure white for username for maximum visibility
    userLabel.TextColor3 = Color3.new(1, 1, 1) -- Pure white username
    userLabel.TextScaled = true
    userLabel.Font = Enum.Font.GothamMedium
    userLabel.TextXAlignment = Enum.TextXAlignment.Left
    userLabel.Parent = container
    local border2 = Instance.new("UIStroke")
    border2.Color = RankColors[rankText].accent
    border2.Thickness = 0.1
    border2.Transparency = 0
    border2.Parent = userLabel

    -- Mouse hover animations.
    container.MouseEnter:Connect(function()
        TweenService:Create(container, TweenInfo.new(0.3), {BackgroundTransparency = 0.5}):Play()
        TweenService:Create(outerTrace, TweenInfo.new(0.3), {Transparency = 0.3}):Play()
        TweenService:Create(rankFrame, TweenInfo.new(0.3), {BackgroundTransparency = 0.6}):Play()
    end)
    container.MouseLeave:Connect(function()
        TweenService:Create(container, TweenInfo.new(0.3), {BackgroundTransparency = 0.7}):Play() -- Revert to the slightly less transparent background
        TweenService:Create(outerTrace, TweenInfo.new(0.3), {Transparency = 0.5}):Play()
        TweenService:Create(rankFrame, TweenInfo.new(0.3), {BackgroundTransparency = 0.8}):Play()
    end)

    -- Distance-based minimization animation:
    local isMinimized = false
    local FULL_SIZE = CONFIG.TAG_SIZE
    local MINI_SIZE = UDim2.new(0, 35, 0, 35) -- Emoji-only view.
    local heartbeatConnection
    heartbeatConnection = RunService.Heartbeat:Connect(function()
        if not (character and character:FindFirstChild("Head") and Players.LocalPlayer.Character) then return end
        local localHead = Players.LocalPlayer.Character:FindFirstChild("Head")
        if not localHead then return end
        local distance = (head.Position - localHead.Position).Magnitude

        if distance > CONFIG.DISTANCE_THRESHOLD and not isMinimized then
            isMinimized = true
            TweenService:Create(container, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {Size = MINI_SIZE}):Play()
            TweenService:Create(rankFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
            TweenService:Create(rankLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {TextTransparency = 1}):Play()
            -- Hide the username completely.
            userLabel.Visible = false
            TweenService:Create(emojiContainer, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0, 0, 0, 0)
            }):Play()
            TweenService:Create(tag, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {StudsOffset = Vector3.new(0, 1, 0)}):Play()
        elseif distance <= CONFIG.DISTANCE_THRESHOLD and isMinimized then
            isMinimized = false
            TweenService:Create(container, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {Size = FULL_SIZE}):Play()
            TweenService:Create(rankFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.8}):Play()
            TweenService:Create(rankLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {TextTransparency = 0}):Play()
            -- Show the username again.
            userLabel.Visible = true
            TweenService:Create(emojiContainer, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
                Size = UDim2.new(0.25, 0, 0.9, 0),
                Position = UDim2.new(0.02, 0, 0.05, 0)
            }):Play()
            TweenService:Create(tag, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {StudsOffset = CONFIG.TAG_OFFSET}):Play()
        end
    end)

    tag.Parent = game.CoreGui

    tag.AncestryChanged:Connect(function(_, parent)
        if not parent and heartbeatConnection then
            heartbeatConnection:Disconnect()
        end
    end)

    container.MouseButton1Click:Connect(function()
        if player ~= Players.LocalPlayer then
            teleportToPlayer(player)
        end
    end)
end

--------------------------------------------------
-- Tag Creation Function for roles
--------------------------------------------------
local function createTag(player, rankText, showPrompt)
    if showPrompt and player == Players.LocalPlayer then
        if localTagChoice ~= nil then
            if localTagChoice == false then
                return
            else
                if player.Character then
                    attachTagToHead(player.Character, player, rankText)
                end
                player.CharacterAdded:Connect(function(character)
                    attachTagToHead(character, player, rankText)
                end)
                return
            end
        end

        local gui, yesButton, noButton, blur = createNotificationUI()
        if not gui then
            return
        end
        local playerGui = player:WaitForChild("PlayerGui", 5)
        if not playerGui then
            return
        end
        gui.Parent = playerGui

        local function cleanup()
            TweenService:Create(gui.Frame, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
            blur:Destroy()
            task.wait(0.5)
            gui:Destroy()
        end

        yesButton.MouseButton1Click:Connect(function()
            cleanup()
            localTagChoice = true
            if player.Character then
                attachTagToHead(player.Character, player, rankText)
            end
            player.CharacterAdded:Connect(function(character)
                attachTagToHead(character, player, rankText)
            end)
        end)

        noButton.MouseButton1Click:Connect(function()
            cleanup()
            localTagChoice = false
        end)
    else
        if player.Character then
            attachTagToHead(player.Character, player, rankText)
        end
        player.CharacterAdded:Connect(function(character)
            attachTagToHead(character, player, rankText)
        end)
    end
end

--------------------------------------------------
-- Local variable to store the local player's prompt choice
--------------------------------------------------
local localTagChoice = nil

--------------------------------------------------
-- Custom Player Role Lists (case-insensitive)
--------------------------------------------------
local Advertisers = {"Vlafz195", "6736_45", "goekaycool", "goekayball", "goekayball2"}
local Helper = {"newbornfromthedark", "FadedSkyPlay"}
local Scripters = {"GYATT_DAMN1", "328ml", "29Kyooo", "BloxiAstra", "", "iLoveScriptsMiniG"}
local Owners = {"Dxan_PlayS", "Xeni_he07", "AliKhammas1234", "AliKhammas", "I_LOVEYOU12210", "AK_ADMEN1", "YournothimbuddyXD", "AK_ADMEN2", "Akksosdmdokdkddmkd"}
local Supporter = {"Robloxian74630436", "MyLittlePonySEDE", "IBimsDerBimbo44"}
local AKStaff = {"goekaycool", "goetemp_1", "hallloweenss", "24ksm1le5"}
local LuckyGods = {"lIIluckyIIII", "TheSadMan198", "XxLuckyXx187", "XxRaportXX", "FellFlower2"}

--------------------------------------------------
-- Apply the Appropriate Tag to a Player (including OG buyer)
--------------------------------------------------
local function applyPlayerTag(player)
    local showPrompt = player == Players.LocalPlayer
    local assignedTag = nil

    if containsIgnoreCase(Owners, player.Name) then
        assignedTag = "AK KING"
    elseif containsIgnoreCase(Scripters, player.Name) then
        assignedTag = "AK CO OWNER"
    elseif containsIgnoreCase(Supporter, player.Name) then
        assignedTag = "AK DADDY"
    elseif containsIgnoreCase(AKStaff, player.Name) then
        assignedTag = "AK STAFF"
    elseif containsIgnoreCase(Advertisers, player.Name) then
        assignedTag = "AK ADVERTISER"
    elseif containsIgnoreCase(Helper, player.Name) then
        assignedTag = "AK HELPER"
    elseif isLifetimeUser(player) then
        assignedTag = "OG BUYER"
    elseif containsIgnoreCase(LuckyGods, player.Name) then
        assignedTag = "AK LUCKYGOD"
    elseif ChatWhitelist[player.Name:lower()] then
        assignedTag = "AK USER"
    end

    if assignedTag then
        createTag(player, assignedTag, showPrompt)
    end
end

--------------------------------------------------
-- Setup Chat Listener for Each Player
--------------------------------------------------
local function setupChatListener(player)
    player.Chatted:Connect(function(msg)
        if modifyString(msg) == modifiedMessage then
            if containsIgnoreCase(Owners, player.Name)
            or containsIgnoreCase(Scripters, player.Name)
            or containsIgnoreCase(Supporter, player.Name)
            or containsIgnoreCase(AKStaff, player.Name)
            or containsIgnoreCase(Advertisers, player.Name)
            or containsIgnoreCase(Helper, player.Name)
            or isLifetimeUser(player)
            or containsIgnoreCase(LuckyGods, player.Name) then
                return
            end

            if ChatWhitelist[player.Name:lower()] then return end
            ChatWhitelist[player.Name:lower()] = true
            createTag(player, "AK USER", true)
        end
    end)
end

-- Continuously check for missing tags
spawn(function()
    while true do
        for _, gui in ipairs(game.CoreGui:GetChildren()) do
            if gui:IsA("BillboardGui") and gui.Name == "RankTag" then
                if not gui.Adornee or not gui.Adornee:IsDescendantOf(game) then
                    gui:Destroy()
                end
            end
        end

        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character and player.Character:FindFirstChild("Head") then
                local tagFound = false
                for _, gui in ipairs(game.CoreGui:GetChildren()) do
                    if gui:IsA("BillboardGui") and gui.Name == "RankTag" and gui.Adornee == player.Character.Head then
                        tagFound = true
                        break
                    end
                end

                if not tagFound then
                    applyPlayerTag(player)
                end
            end
        end
        wait(0)
    end
end)

-- Initialize tag system immediately for existing players.
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(function()
        applyPlayerTag(player)
    end)
end

-- Set up for players joining later.
Players.PlayerAdded:Connect(function(player)
    setupChatListener(player)
    task.spawn(function()
        applyPlayerTag(player)
    end)
end)

-- Setup Chat Listeners for existing players.
for _, player in ipairs(Players:GetPlayers()) do
    setupChatListener(player)
end

--------------------------------------------------
-- Return API (Optional)
--------------------------------------------------
return {
    refreshTags = function()
        for _, player in pairs(Players:GetPlayers()) do
            task.spawn(function()
                applyPlayerTag(player)
            end)
        end
    end,
    forceTag = function(player, rankType)
        if RankColors[rankType] then
            createTag(player, rankType, player == Players.LocalPlayer)
            return true
        end
        return false
    end,
    teleportTo = function(player)
        if player ~= Players.LocalPlayer then
            teleportToPlayer(player)
        end
    end
}
