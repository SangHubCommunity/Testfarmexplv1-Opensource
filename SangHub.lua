--==[ SangHub AutoFarm Full v1 ]==--
-- Khai báo trạng thái
getgenv().AutoFarmEnabled = false
getgenv().SelectedWeapon = "Nothing" -- "Melee" hoặc "Sword"

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")

-- Bảng dữ liệu Level -> Mob/Quest/Island
local BF_LevelFarm = {
    {Level=1, Mob="Bandit", Quest="BanditQuest1", Island=CFrame.new(1060, 16, 1547)},
    {Level=15, Mob="Monkey", Quest="JungleQuest", Island=CFrame.new(-1603, 65, 150)},
    {Level=20, Mob="Gorilla", Quest="JungleQuest", Island=CFrame.new(-1337, 40, -30)},
    {Level=30, Mob="Pirate", Quest="BuggyQuest1", Island=CFrame.new(-4870, 20, 4323)},
    {Level=40, Mob="Brute", Quest="BuggyQuest1", Island=CFrame.new(-5020, 20, 4408)},
    {Level=60, Mob="Desert Bandit", Quest="DesertQuest", Island=CFrame.new(932, 7, 4486)},
    {Level=75, Mob="Desert Officer", Quest="DesertQuest", Island=CFrame.new(1572, 10, 4373)},
    {Level=90, Mob="Snow Bandit", Quest="SnowQuest", Island=CFrame.new(1389, 87, -1297)},
    {Level=105, Mob="Snowman", Quest="SnowQuest", Island=CFrame.new(1206, 144, -1326)},
    {Level=120, Mob="Chief Petty Officer", Quest="MarineQuest2", Island=CFrame.new(-4881, 20, 3914)},
    {Level=130, Mob="Sky Bandit", Quest="SkyQuest", Island=CFrame.new(-4950, 295, -2886)},
    {Level=145, Mob="Dark Master", Quest="SkyQuest", Island=CFrame.new(-5220, 430, -2272)},
    {Level=190, Mob="Prisoner", Quest="PrisonerQuest", Island=CFrame.new(5100, 100, 4740)},
    {Level=210, Mob="Dangerous Prisoner", Quest="PrisonerQuest", Island=CFrame.new(5200, 100, 4740)},
    {Level=250, Mob="Toga Warrior", Quest="ColosseumQuest", Island=CFrame.new(-1790, 560, -2748)},
    {Level=275, Mob="Gladiator", Quest="ColosseumQuest", Island=CFrame.new(-1295, 470, -3021)},
    {Level=300, Mob="Military Soldier", Quest="MagmaQuest", Island=CFrame.new(-5400, 90, 5800)},
    {Level=325, Mob="Military Spy", Quest="MagmaQuest", Island=CFrame.new(-5800, 90, 6000)},
    {Level=375, Mob="Fishman Warrior", Quest="FishmanQuest", Island=CFrame.new(60800, 20, 1500)},
    {Level=400, Mob="Fishman Commando", Quest="FishmanQuest", Island=CFrame.new(61000, 20, 1800)},
    {Level=450, Mob="Wysper", Quest="SkyExp1", Island=CFrame.new(62000, 20, 1600)},
    {Level=475, Mob="Magma Admiral", Quest="SkyExp1", Island=CFrame.new(-5000, 80, 8500)},
    {Level=525, Mob="Arctic Warrior", Quest="FrostQuest", Island=CFrame.new(5600, 20, -6500)},
    {Level=550, Mob="Snow Lurker", Quest="FrostQuest", Island=CFrame.new(5800, 30, -6700)},
    {Level=625, Mob="Cyborg", Quest="CyborQuest", Island=CFrame.new(6200, 20, -7200)}
}

-- Lấy mob/quest/island theo level hiện tại
local function getFarmData()
    local myLevel = LocalPlayer.Data.Level.Value
    local best = BF_LevelFarm[1]
    for _, data in ipairs(BF_LevelFarm) do
        if myLevel >= data.Level then
            best = data
        else
            break
        end
    end
    return best
end

-- Tween tới vị trí
local function tweenTo(cf)
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = LocalPlayer.Character.HumanoidRootPart
    local dist = (hrp.Position - cf.Position).Magnitude
    local t = TweenService:Create(hrp, TweenInfo.new(dist/300, Enum.EasingStyle.Linear), {CFrame = cf})
    t:Play()
    t.Completed:Wait()
end
--==[ Phần 2: Auto Equip + Platform + Fast Attack + Auto Farm Loop ]==--

-- Tạo block ảo dưới chân
local function createPlatform()
    if workspace:FindFirstChild("AutoFarmPlatform") then return end
    local part = Instance.new("Part")
    part.Name = "AutoFarmPlatform"
    part.Size = Vector3.new(10,1,10)
    part.Anchored = true
    part.Transparency = 1
    part.Parent = workspace
end

-- Xóa block ảo
local function removePlatform()
    if workspace:FindFirstChild("AutoFarmPlatform") then
        workspace.AutoFarmPlatform:Destroy()
    end
end

-- Fast Attack
local function fastAttack()
    local Tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
    if Tool then
        pcall(function()
            Tool:Activate()
        end)
    end
end

-- Auto Equip vũ khí đã chọn
local function autoEquip()
    if getgenv().SelectedWeapon == "Nothing" then return end
    for _,v in pairs(LocalPlayer.Backpack:GetChildren()) do
        if getgenv().SelectedWeapon == "Melee" and v:IsA("Tool") and (v.ToolTip == "Melee" or v.Name == "Combat") then
            LocalPlayer.Character.Humanoid:EquipTool(v)
        elseif getgenv().SelectedWeapon == "Sword" and v:IsA("Tool") and v.ToolTip == "Sword" then
            LocalPlayer.Character.Humanoid:EquipTool(v)
        end
    end
end

-- Hàm farm 1 mob
local function farmMob(mob)
    if mob and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
        -- Tạo block ảo ở trên mob
        createPlatform()
        workspace.AutoFarmPlatform.CFrame = mob.HumanoidRootPart.CFrame * CFrame.new(0, 15, 0)

        -- Tween tới trên mob
        tweenTo(mob.HumanoidRootPart.CFrame * CFrame.new(0, 15, 0))

        -- Làm mob đứng yên
        pcall(function()
            mob.HumanoidRootPart.Anchored = true
        end)

        -- Đánh liên tục
        while getgenv().AutoFarmEnabled and mob.Parent and mob.Humanoid.Health > 0 do
            autoEquip()
            fastAttack()
            task.wait(0.1)
        end

        -- Thả mob ra
        pcall(function()
            mob.HumanoidRootPart.Anchored = false
        end)
    end
end

-- Auto Farm loop
task.spawn(function()
    while task.wait() do
        if getgenv().AutoFarmEnabled then
            local data = getFarmData()

            -- Di chuyển tới đảo
            tweenTo(data.Island)
            createPlatform()
            workspace.AutoFarmPlatform.CFrame = data.Island * CFrame.new(0,5,0)
            task.wait(3) -- chờ quái spawn

            -- Tìm mob
            local mobs = {}
            for _,v in pairs(workspace.Enemies:GetChildren()) do
                if v.Name == data.Mob and v:FindFirstChild("HumanoidRootPart") then
                    table.insert(mobs, v)
                end
            end

            -- Gom 3 con nếu có
            for i, mob in ipairs(mobs) do
                if i <= 3 then
                    farmMob(mob)
                end
            end
        else
            removePlatform()
            task.wait(1)
        end
    end
end)
--==[ Phần 3: GUI Auto Farm + Setting Farm ]==--

-- Main GUI
local Gui = Instance.new("ScreenGui")
Gui.Name = "SangHub_AutoFarm"
Gui.ResetOnSpawn = false
Gui.Parent = game.CoreGui

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 400, 0, 250)
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -125)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.Parent = Gui
MainFrame.Active = true
MainFrame.Draggable = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

-- Left Panel - Auto Farm
local LeftPanel = Instance.new("Frame", MainFrame)
LeftPanel.Size = UDim2.new(0.5, -5, 1, 0)
LeftPanel.BackgroundTransparency = 1

local LeftTitle = Instance.new("TextLabel", LeftPanel)
LeftTitle.Size = UDim2.new(1, 0, 0, 30)
LeftTitle.BackgroundTransparency = 1
LeftTitle.Text = "Auto Farm"
LeftTitle.Font = Enum.Font.GothamBold
LeftTitle.TextSize = 16
LeftTitle.TextColor3 = Color3.fromRGB(255, 255, 255)

local AutoFarmBtn = Instance.new("TextButton", LeftPanel)
AutoFarmBtn.Size = UDim2.new(1, -10, 0, 40)
AutoFarmBtn.Position = UDim2.new(0, 5, 0, 40)
AutoFarmBtn.Text = "Auto Farm Level ❌"
AutoFarmBtn.Font = Enum.Font.GothamBold
AutoFarmBtn.TextSize = 14
AutoFarmBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
AutoFarmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", AutoFarmBtn).CornerRadius = UDim.new(0, 6)

AutoFarmBtn.MouseButton1Click:Connect(function()
    getgenv().AutoFarmEnabled = not getgenv().AutoFarmEnabled
    if getgenv().AutoFarmEnabled then
        AutoFarmBtn.Text = "Auto Farm Level ✅"
    else
        AutoFarmBtn.Text = "Auto Farm Level ❌"
    end
end)

-- Right Panel - Setting Farm
local RightPanel = Instance.new("Frame", MainFrame)
RightPanel.Size = UDim2.new(0.5, -5, 1, 0)
RightPanel.Position = UDim2.new(0.5, 5, 0, 0)
RightPanel.BackgroundTransparency = 1

local RightTitle = Instance.new("TextLabel", RightPanel)
RightTitle.Size = UDim2.new(1, 0, 0, 30)
RightTitle.BackgroundTransparency = 1
RightTitle.Text = "Setting Farm"
RightTitle.Font = Enum.Font.GothamBold
RightTitle.TextSize = 16
RightTitle.TextColor3 = Color3.fromRGB(255, 255, 255)

-- Time label
local TimeLabel = Instance.new("TextLabel", RightPanel)
TimeLabel.Size = UDim2.new(1, 0, 0, 20)
TimeLabel.Position = UDim2.new(0, 0, 0, 35)
TimeLabel.BackgroundTransparency = 1
TimeLabel.Font = Enum.Font.Gotham
TimeLabel.TextSize = 14
TimeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
TimeLabel.Text = "Server Time: 00:00:00"

-- Cập nhật thời gian server
task.spawn(function()
    while task.wait(1) do
        local h = os.date("!%H")
        local m = os.date("!%M")
        local s = os.date("!%S")
        TimeLabel.Text = string.format("Server Time: %02d:%02d:%02d", h, m, s)
    end
end)

-- Select Weapon
local WeaponScroll = Instance.new("ScrollingFrame", RightPanel)
WeaponScroll.Size = UDim2.new(1, -10, 0, 130)
WeaponScroll.Position = UDim2.new(0, 5, 0, 60)
WeaponScroll.ScrollBarThickness = 4
WeaponScroll.BackgroundTransparency = 1
WeaponScroll.CanvasSize = UDim2.new(0, 0, 0, 100)
local wLayout = Instance.new("UIListLayout", WeaponScroll)
wLayout.Padding = UDim.new(0, 5)

local function addWeaponButton(name)
    local btn = Instance.new("TextButton", WeaponScroll)
    btn.Size = UDim2.new(1, -5, 0, 40)
    btn.Text = name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(function()
        getgenv().SelectedWeapon = name
        for _,child in ipairs(WeaponScroll:GetChildren()) do
            if child:IsA("TextButton") then
                child.TextColor3 = Color3.fromRGB(255,255,255)
            end
        end
        btn.TextColor3 = Color3.fromRGB(0,255,0)
    end)
end

addWeaponButton("Melee")
addWeaponButton("Sword")
