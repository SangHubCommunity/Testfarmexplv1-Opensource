--===[ PART 1 - GUI & TAB STATUS FIXED ]===--

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- Main ScreenGui
local MainGui = Instance.new("ScreenGui")
MainGui.Name = "SangHubGUI"
MainGui.Parent = game.CoreGui
MainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
MainGui.ResetOnSpawn = false

-- Main Frame
local MainFrame = Instance.new("Frame", MainGui)
MainFrame.Size = UDim2.new(0, 500, 0, 300)
MainFrame.Position = UDim2.new(0.5, -250, 0.5, -150)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.Visible = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

-- Tabs Holder
local TabsFrame = Instance.new("Frame", MainFrame)
TabsFrame.Size = UDim2.new(0, 120, 1, 0)
TabsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Instance.new("UICorner", TabsFrame).CornerRadius = UDim.new(0, 10)

local TabsLayout = Instance.new("UIListLayout", TabsFrame)
TabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabsLayout.Padding = UDim.new(0, 5)

-- Content Frame
local ContentFrame = Instance.new("Frame", MainFrame)
ContentFrame.Size = UDim2.new(1, -120, 1, 0)
ContentFrame.Position = UDim2.new(0, 120, 0, 0)
ContentFrame.BackgroundTransparency = 1

-- Create Tabs Table
local TabButtons = {}
local TabFrames = {}

local function CreateTab(name)
    local btn = Instance.new("TextButton", TabsFrame)
    btn.Size = UDim2.new(1, -10, 0, 40)
    btn.Text = name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local tabFrame = Instance.new("ScrollingFrame", ContentFrame)
    tabFrame.Size = UDim2.new(1, 0, 1, 0)
    tabFrame.CanvasSize = UDim2.new(0, 0, 0, 300)
    tabFrame.ScrollBarThickness = 4
    tabFrame.BackgroundTransparency = 1
    tabFrame.Visible = false

    TabButtons[name] = btn
    TabFrames[name] = tabFrame

    btn.MouseButton1Click:Connect(function()
        for _, frame in pairs(TabFrames) do
            frame.Visible = false
        end
        for _, button in pairs(TabButtons) do
            button.BackgroundColor3 = Color3.fromRGB(40,40,40)
        end
        tabFrame.Visible = true
        btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
    end)
end

-- Create Tab: STATUS
CreateTab("Status")

-- Status UI
local StatusLayout = Instance.new("UIListLayout", TabFrames["Status"])
StatusLayout.Padding = UDim.new(0, 6)

local function CreateStatusLabel(text)
    local lbl = Instance.new("TextLabel", TabFrames["Status"])
    lbl.Size = UDim2.new(1, -10, 0, 30)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 16
    lbl.TextColor3 = Color3.new(1,1,1)
    lbl.BackgroundTransparency = 1
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = text
    return lbl
end

-- Status Labels
local bossShanks = CreateStatusLabel("Shanks Boss: ❌")
local bossWhite = CreateStatusLabel("Whitebeard Boss: ❌")
local bossSaw = CreateStatusLabel("The Saw Boss: ❌")
local fruitStatus = CreateStatusLabel("Fruit Spawn / Drop: ❌")
local moonStatus = CreateStatusLabel("Moon: 🌑")
local timeStatus = CreateStatusLabel("Time in server: 0s")
local playerCount = CreateStatusLabel("Players in server: 0")

-- Variables for tracking
local startTime = tick()

-- Boss Checking
local function UpdateBossStatus()
    bossShanks.Text = "Shanks Boss: " .. (workspace:FindFirstChild("Shanks") and "✅" or "❌")
    bossWhite.Text = "Whitebeard Boss: " .. (workspace:FindFirstChild("Whitebeard") and "✅" or "❌")
    bossSaw.Text = "The Saw Boss: " .. (workspace:FindFirstChild("The Saw") and "✅" or "❌")
end

-- Fruit Checking
local function UpdateFruitStatus()
    local found = nil
    for _, obj in pairs(workspace:GetChildren()) do
        if obj:IsA("Tool") and obj:FindFirstChild("Handle") then
            found = obj.Name
            break
        end
    end
    fruitStatus.Text = "Fruit Spawn / Drop: " .. (found and found or "❌")
end

-- Moon Checking
local function UpdateMoonStatus()
    local moon = Lighting:FindFirstChild("Moon")
    if moon then
        local phase = math.floor((moon.CFrame.LookVector.X + 1) * 4) % 8
        local emoji = {"🌑","🌒","🌓","🌔","🌕","🌖","🌗","🌘"}[phase+1]
        moonStatus.Text = "Moon: " .. emoji
    end
end

-- Player Count
local function UpdatePlayerCount()
    playerCount.Text = "Players in server: " .. #Players:GetPlayers()
end

-- Time Tracking
RunService.Heartbeat:Connect(function()
    local elapsed = math.floor(tick() - startTime)
    timeStatus.Text = "Time in server: " .. elapsed .. "s"
end)

-- Update every 2 mins
task.spawn(function()
    while task.wait(120) do
        UpdateBossStatus()
        UpdateFruitStatus()
        UpdateMoonStatus()
        UpdatePlayerCount()
    end
end)

-- Initial update
UpdateBossStatus()
UpdateFruitStatus()
UpdateMoonStatus()
UpdatePlayerCount()
--===[ PART 2 - TAB GENERAL UI + SELECT WEAPON ]===--

-- Create Tab: GENERAL
CreateTab("General")

-- Scroll layout for General Tab
local genLayout = Instance.new("UIListLayout", TabFrames["General"])
genLayout.Padding = UDim.new(0, 8)
genLayout.FillDirection = Enum.FillDirection.Horizontal

-- Left Panel - Auto Farm
local LeftPanel = Instance.new("Frame", TabFrames["General"])
LeftPanel.Size = UDim2.new(0.48, 0, 1, -10)
LeftPanel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Instance.new("UICorner", LeftPanel).CornerRadius = UDim.new(0, 8)

-- Title Auto Farm
local autoTitle = Instance.new("TextLabel", LeftPanel)
autoTitle.Size = UDim2.new(1, 0, 0, 40)
autoTitle.Text = "AUTO FARM"
autoTitle.Font = Enum.Font.GothamBold
autoTitle.TextSize = 16
autoTitle.TextColor3 = Color3.new(1,1,1)
autoTitle.BackgroundTransparency = 1

-- Toggle Button Auto Farm
local autoFarmBtn = Instance.new("TextButton", LeftPanel)
autoFarmBtn.Size = UDim2.new(1, -20, 0, 40)
autoFarmBtn.Position = UDim2.new(0, 10, 0, 50)
autoFarmBtn.Text = "Level Farm"
autoFarmBtn.Font = Enum.Font.Gotham
autoFarmBtn.TextSize = 14
autoFarmBtn.TextColor3 = Color3.new(1,1,1)
autoFarmBtn.BackgroundColor3 = Color3.fromRGB(28,28,28)
Instance.new("UICorner", autoFarmBtn).CornerRadius = UDim.new(0, 8)

local checkIcon = Instance.new("ImageLabel", autoFarmBtn)
checkIcon.Size = UDim2.new(0, 20, 0, 20)
checkIcon.Position = UDim2.new(1, -30, 0.5, -10)
checkIcon.BackgroundTransparency = 1
checkIcon.Image = "rbxassetid://6031094664" -- Empty circle

getgenv().AutoFarmEnabled = false
autoFarmBtn.MouseButton1Click:Connect(function()
    getgenv().AutoFarmEnabled = not getgenv().AutoFarmEnabled
    checkIcon.Image = getgenv().AutoFarmEnabled and "rbxassetid://6031094690" or "rbxassetid://6031094664"
end)

-- Right Panel - Setting Farm
local RightPanel = Instance.new("Frame", TabFrames["General"])
RightPanel.Size = UDim2.new(0.48, 0, 1, -10)
RightPanel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Instance.new("UICorner", RightPanel).CornerRadius = UDim.new(0, 8)

-- Title Setting Farm
local settingTitle = Instance.new("TextLabel", RightPanel)
settingTitle.Size = UDim2.new(1, 0, 0, 40)
settingTitle.Text = "SETTING FARM"
settingTitle.Font = Enum.Font.GothamBold
settingTitle.TextSize = 16
settingTitle.TextColor3 = Color3.new(1,1,1)
settingTitle.BackgroundTransparency = 1

-- Time in script
local timeLabel = Instance.new("TextLabel", RightPanel)
timeLabel.Size = UDim2.new(1, -20, 0, 30)
timeLabel.Position = UDim2.new(0, 10, 0, 50)
timeLabel.Text = "Script Time: 0s"
timeLabel.Font = Enum.Font.Gotham
timeLabel.TextSize = 14
timeLabel.TextColor3 = Color3.new(1,1,1)
timeLabel.BackgroundTransparency = 1

-- Track Script Time
local scriptStart = tick()
RunService.Heartbeat:Connect(function()
    timeLabel.Text = "Script Time: " .. math.floor(tick() - scriptStart) .. "s"
end)

-- Select Weapon Dropdown
local selectBtn = Instance.new("TextButton", RightPanel)
selectBtn.Size = UDim2.new(1, -20, 0, 40)
selectBtn.Position = UDim2.new(0, 10, 0, 90)
selectBtn.Text = "Select Weapon: Nothing"
selectBtn.Font = Enum.Font.GothamBold
selectBtn.TextSize = 14
selectBtn.TextColor3 = Color3.new(1,1,1)
selectBtn.BackgroundColor3 = Color3.fromRGB(28,28,28)
Instance.new("UICorner", selectBtn).CornerRadius = UDim.new(0, 8)

-- Weapon Options Panel
local weaponFrame = Instance.new("ScrollingFrame", RightPanel)
weaponFrame.Size = UDim2.new(1, -20, 0, 100)
weaponFrame.Position = UDim2.new(0, 10, 0, 140)
weaponFrame.CanvasSize = UDim2.new(0, 0, 0, 80)
weaponFrame.ScrollBarThickness = 3
weaponFrame.Visible = false
weaponFrame.BackgroundColor3 = Color3.fromRGB(25,25,25)
Instance.new("UICorner", weaponFrame).CornerRadius = UDim.new(0, 6)

local weaponLayout = Instance.new("UIListLayout", weaponFrame)
weaponLayout.Padding = UDim.new(0, 5)

local weaponList = {"Melee", "Sword"}
local selectedWeapon = nil

for _, weapon in ipairs(weaponList) do
    local btn = Instance.new("TextButton", weaponFrame)
    btn.Size = UDim2.new(1, -10, 0, 30)
    btn.Text = weapon
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.TextColor3 = Color3.new(1,1,1)
    btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    btn.MouseButton1Click:Connect(function()
        selectedWeapon = weapon
        selectBtn.Text = "Select Weapon: " .. weapon
        weaponFrame.Visible = false
    end)
end

selectBtn.MouseButton1Click:Connect(function()
    weaponFrame.Visible = not weaponFrame.Visible
end)

-- Auto Equip when farm is on
RunService.Heartbeat:Connect(function()
    if getgenv().AutoFarmEnabled and selectedWeapon then
        local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if not tool or not tool.Name:lower():find(selectedWeapon:lower()) then
            for _, v in pairs(LocalPlayer.Backpack:GetChildren()) do
                if v:IsA("Tool") and v.Name:lower():find(selectedWeapon:lower()) then
                    LocalPlayer.Character.Humanoid:EquipTool(v)
                end
            end
        end
    end
end)
--===[ PART 3 - AUTO FARM LEVEL SYSTEM ]===--

-- Fast Attack Function
local function fastAttack()
    pcall(function()
        local vu = game:GetService("VirtualUser")
        vu:CaptureController()
        vu:Button1Down(Vector2.new(1280, 672))
    end)
end

-- Create platform to stand on
local function createPlatform()
    local part = Instance.new("Part")
    part.Size = Vector3.new(8, 1, 8)
    part.Anchored = true
    part.Transparency = 1
    part.Name = "FarmPlatform"
    part.Parent = workspace
    return part
end

-- Remove platform
local function removePlatform()
    for _, v in pairs(workspace:GetChildren()) do
        if v:IsA("Part") and v.Name == "FarmPlatform" then
            v:Destroy()
        end
    end
end

-- Increase Hitbox
local function increaseHitbox(mob)
    pcall(function()
        mob.HumanoidRootPart.Size = Vector3.new(60, 60, 60)
        mob.HumanoidRootPart.Transparency = 0.8
        mob.HumanoidRootPart.BrickColor = BrickColor.new("Bright red")
        mob.HumanoidRootPart.CanCollide = false
    end)
end

-- Get nearest mobs for current quest
local function getMobs()
    local mobs = {}
    for _, v in pairs(workspace.Enemies:GetChildren()) do
        if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
            table.insert(mobs, v)
        end
    end
    return mobs
end

-- Tween to position
local function tweenTo(pos)
    local ts = game:GetService("TweenService")
    local lp = game.Players.LocalPlayer
    local char = lp.Character or lp.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    local info = TweenInfo.new((hrp.Position - pos).Magnitude / 200, Enum.EasingStyle.Linear)
    local tween = ts:Create(hrp, info, {CFrame = CFrame.new(pos)})
    tween:Play()
    tween.Completed:Wait()
end

-- Auto Farm Loop
spawn(function()
    while task.wait() do
        if getgenv().AutoFarmEnabled and selectedWeapon then
            local mobs = getMobs()
            if #mobs > 0 then
                -- Create invisible platform
                local platform = createPlatform()
                for _, mob in ipairs(mobs) do
                    increaseHitbox(mob)
                end
                -- Pick first mob as target
                local target = mobs[1]
                if target:FindFirstChild("HumanoidRootPart") then
                    local posAbove = target.HumanoidRootPart.Position + Vector3.new(0, 8, 0)
                    tweenTo(posAbove)
                    platform.Position = target.HumanoidRootPart.Position - Vector3.new(0, 3, 0)
                    while target and target:FindFirstChild("Humanoid") and target.Humanoid.Health > 0 and getgenv().AutoFarmEnabled do
                        fastAttack()
                        -- Reposition to keep above mob
                        local newPos = target.HumanoidRootPart.Position + Vector3.new(0, 8, 0)
                        game.Players.LocalPlayer.Character:MoveTo(newPos)
                        task.wait(0.1)
                    end
                end
                removePlatform()
            end
        end
    end
end)
-- ====== PART 4: AUTO FARM SYSTEM ======

-- Auto farm loop
spawn(function()
    while task.wait() do
        if getgenv().AutoFarm then
            local data = getBestForLevel()
            if data then
                -- Step 1: Tween tới đảo mob
                tweenTo(IslandPositions[data.Mob] + Vector3.new(0, 20, 0))
                -- Step 2: Tạo block ảo
                createFloatingPlatform()
                -- Step 3: Chờ spawn
                task.wait(3)
                -- Step 4: Nhận quest
                startQuest(data.Quest)
                -- Step 5: Farm quái
                while getgenv().AutoFarm and LocalPlayer.PlayerGui.Main.Quest.Visible do
                    autoEquipSelected()
                    local mob = findNearestMobByName(data.Mob)
                    if mob and mob:FindFirstChild("HumanoidRootPart") then
                        expandHitbox(mob)
                        -- Giữ mob đứng im
                        pcall(function()
                            mob.HumanoidRootPart.Anchored = true
                        end)
                        -- Tween lên trên đầu 3 con
                        local abovePos = mob.HumanoidRootPart.CFrame * CFrame.new(0, mob.HumanoidRootPart.Size.Y * 3, 0)
                        tweenTo(abovePos)
                        -- Đánh
                        sendClick()
                        if getgenv().FastAttack then
                            task.wait(0.05)
                        else
                            task.wait(0.2)
                        end
                    else
                        break
                    end
                end
            end
        else
            removeFloatingPlatform()
        end
    end
end)

-- ====== END SCRIPT ======
print("[SangHub] Script loaded successfully! Enjoy farming.")
