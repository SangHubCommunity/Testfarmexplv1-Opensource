-- SangHub - Full Auto Farm GUI Style Fix
-- [Phần 1] - Anti AFK + Config + Dữ liệu đảo / mob

-- == Anti AFK ==
for i,v in pairs(getconnections(game.Players.LocalPlayer.Idled)) do
    pcall(function() v:Disable() end)
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local VirtualInput = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

-- ====== CONFIG / STATE ======
local StartTime = tick()
getgenv().AutoFarm = false
getgenv().SelectedWeapon = "None" -- "Melee" or "Sword"
getgenv().FastAttack = false

-- ====== DATA: Island positions & level->mob mapping (Sea1 example) ======
local IslandPositions = {
    ["Bandit"] = CFrame.new(1060, 16, 1547),
    ["Monkey"] = CFrame.new(-1603, 65, 150),
    ["Gorilla"] = CFrame.new(-1337, 40, -30),
    ["Pirate"] = CFrame.new(-4870, 20, 4323),
    ["Brute"] = CFrame.new(-5020, 20, 4408),
    ["Desert Bandit"] = CFrame.new(932, 7, 4486),
    ["Desert Officer"] = CFrame.new(1572, 10, 4373),
    ["Snow Bandit"] = CFrame.new(1389, 87, -1297),
    ["Snowman"] = CFrame.new(1206, 144, -1326),
    ["Chief Petty Officer"] = CFrame.new(-4881, 20, 3914),
    ["Sky Bandit"] = CFrame.new(-4950, 295, -2886),
    ["Dark Master"] = CFrame.new(-5220, 430, -2272),
    ["Prisoner"] = CFrame.new(5100, 100, 4740),
    ["Dangerous Prisoner"] = CFrame.new(5200, 100, 4740),
    ["Toga Warrior"] = CFrame.new(-1790, 560, -2748),
    ["Gladiator"] = CFrame.new(-1295, 470, -3021),
    ["Military Soldier"] = CFrame.new(-5400, 90, 5800),
    ["Military Spy"] = CFrame.new(-5800, 90, 6000),
    ["Fishman Warrior"] = CFrame.new(60800, 20, 1500),
    ["Fishman Commando"] = CFrame.new(61000, 20, 1800),
    ["Wysper"] = CFrame.new(62000, 20, 1600),
    ["Magma Admiral"] = CFrame.new(-5000, 80, 8500),
    ["Arctic Warrior"] = CFrame.new(5600, 20, -6500),
    ["Snow Lurker"] = CFrame.new(5800, 30, -6700),
    ["Cyborg"] = CFrame.new(6200, 20, -7200)
}

local LevelToMob = {
    {LevelReq=1, Mob="Bandit", Quest="BanditQuest1"},
    {LevelReq=15, Mob="Monkey", Quest="JungleQuest"},
    {LevelReq=20, Mob="Gorilla", Quest="JungleQuest"},
    {LevelReq=30, Mob="Pirate", Quest="BuggyQuest1"},
    {LevelReq=40, Mob="Brute", Quest="BuggyQuest1"},
    {LevelReq=60, Mob="Desert Bandit", Quest="DesertQuest"},
    {LevelReq=75, Mob="Desert Officer", Quest="DesertQuest"},
    {LevelReq=90, Mob="Snow Bandit", Quest="SnowQuest"},
    {LevelReq=105, Mob="Snowman", Quest="SnowQuest"},
    {LevelReq=120, Mob="Chief Petty Officer", Quest="MarineQuest2"},
    {LevelReq=130, Mob="Sky Bandit", Quest="SkyQuest"},
    {LevelReq=145, Mob="Dark Master", Quest="SkyQuest"},
    {LevelReq=190, Mob="Prisoner", Quest="PrisonerQuest"},
    {LevelReq=210, Mob="Dangerous Prisoner", Quest="PrisonerQuest"},
    {LevelReq=250, Mob="Toga Warrior", Quest="ColosseumQuest"},
    {LevelReq=275, Mob="Gladiator", Quest="ColosseumQuest"},
    {LevelReq=300, Mob="Military Soldier", Quest="MagmaQuest"},
    {LevelReq=325, Mob="Military Spy", Quest="MagmaQuest"},
    {LevelReq=375, Mob="Fishman Warrior", Quest="FishmanQuest"},
    {LevelReq=400, Mob="Fishman Commando", Quest="FishmanQuest"},
    {LevelReq=450, Mob="Wysper", Quest="SkyExp1"},
    {LevelReq=475, Mob="Magma Admiral", Quest="SkyExp1"},
    {LevelReq=525, Mob="Arctic Warrior", Quest="FrostQuest"},
    {LevelReq=550, Mob="Snow Lurker", Quest="FrostQuest"},
    {LevelReq=625, Mob="Cyborg", Quest="CyborQuest"}
}
-- ====== UTILS ======
local function GetCurrentQuest()
    local level = LocalPlayer.Data.Level.Value
    local selected
    for i=#LevelToMob,1,-1 do
        if level >= LevelToMob[i].LevelReq then
            selected = LevelToMob[i]
            break
        end
    end
    return selected
end

local function EquipWeapon(name)
    if not name or name == "None" then return end
    for _,v in pairs(LocalPlayer.Backpack:GetChildren()) do
        if v:IsA("Tool") and v.Name == name then
            LocalPlayer.Character.Humanoid:EquipTool(v)
        end
    end
end

local function GetWeaponByType(wtype)
    for _,v in pairs(LocalPlayer.Backpack:GetChildren()) do
        if v:IsA("Tool") then
            if wtype == "Melee" and v.ToolTip == "Melee" then
                return v.Name
            elseif wtype == "Sword" and v.ToolTip == "Sword" then
                return v.Name
            end
        end
    end
    return nil
end

local function WidenHitbox(target)
    pcall(function()
        target.HumanoidRootPart.Size = Vector3.new(60, 60, 60)
        target.HumanoidRootPart.Transparency = 1
        target.HumanoidRootPart.CanCollide = false
    end)
end

local function TweenTo(cframe, speed)
    local tween = TweenService:Create(LocalPlayer.Character.HumanoidRootPart,
        TweenInfo.new((LocalPlayer.Character.HumanoidRootPart.Position - cframe.Position).Magnitude / speed, Enum.EasingStyle.Linear),
        {CFrame = cframe}
    )
    tween:Play()
    tween.Completed:Wait()
end

-- ====== FARM LOGIC ======
spawn(function()
    while task.wait() do
        if getgenv().AutoFarm and getgenv().SelectedWeapon ~= "None" then
            local questInfo = GetCurrentQuest()
            if questInfo then
                -- Tới đảo
                TweenTo(IslandPositions[questInfo.Mob] + Vector3.new(0,30,0), 250)

                -- Chờ spawn mob
                task.wait(1.5)

                -- Auto equip
                local wepName = GetWeaponByType(getgenv().SelectedWeapon)
                if wepName then
                    EquipWeapon(wepName)
                end

                -- Gom quái
                local targets = {}
                for _,mob in pairs(workspace.Enemies:GetChildren()) do
                    if mob.Name == questInfo.Mob and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                        WidenHitbox(mob)
                        table.insert(targets, mob)
                        if #targets >= 3 then break end
                    end
                end

                -- Đánh 3 con cùng lúc
                for _,mob in ipairs(targets) do
                    mob.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0,-3,0)
                    spawn(function()
                        while mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 and getgenv().AutoFarm do
                            pcall(function()
                                mob.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0,-3,0)
                                if getgenv().FastAttack then
                                    VirtualInput:SendMouseButtonEvent(0,0,0,true,game,0)
                                    VirtualInput:SendMouseButtonEvent(0,0,0,false,game,0)
                                else
                                    ReplicatedStorage.Remotes.CommF_:InvokeServer("Attack")
                                end
                            end)
                            task.wait(0.1)
                        end
                    end)
                end
            end
        end
    end
end)
-- ===== Part 3: GUI (Tabs, Status, General) =====
-- This part expects the utilities & farm logic from Part 2 to be loaded in the same environment.
-- It will read/write these global flags:
--   getgenv().AutoFarm (bool)
--   getgenv().SelectedWeapon (string) -> "Melee" / "Sword" / "None"
--   getgenv().FastAttack (bool)
-- Also expects StartTime, Players, ReplicatedStorage, TweenService, LocalPlayer to exist.

-- SAFE-GUARDS
if not game or not game:IsLoaded() then
    repeat task.wait() until game and game:IsLoaded()
end

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- create main GUI container (avoid duplicates)
if game.CoreGui:FindFirstChild("BloxFruit_TabGUI") then
    pcall(function() game.CoreGui.BloxFruit_TabGUI:Destroy() end)
end

local Gui = Instance.new("ScreenGui", game.CoreGui)
Gui.Name = "BloxFruit_TabGUI"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- toggle button (small rounded square top-left)
local ToggleBtn = Instance.new("ImageButton", Gui)
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Size = UDim2.new(0,44,0,44)
ToggleBtn.Position = UDim2.new(0,12,0,12)
ToggleBtn.Image = "rbxassetid://76955883171909" -- user provided logo id
ToggleBtn.BackgroundColor3 = Color3.fromRGB(28,28,28)
ToggleBtn.AutoButtonColor = true
local tcorner = Instance.new("UICorner", ToggleBtn); tcorner.CornerRadius = UDim.new(0,8)

-- main frame (center)
local MainFrame = Instance.new("Frame", Gui)
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0,640,0,420)
MainFrame.Position = UDim2.new(0.5,-320,0.5,-210)
MainFrame.BackgroundColor3 = Color3.fromRGB(18,18,18)
MainFrame.AnchorPoint = Vector2.new(0.5,0.5)
MainFrame.Visible = false
MainFrame.Active = true
local mcorner = Instance.new("UICorner", MainFrame); mcorner.CornerRadius = UDim.new(0,12)

-- open/close animation (scale)
MainFrame.SizeConstraint = Enum.SizeConstraint.RelativeXY
MainFrame.Size = UDim2.new(0,640,0,420)
MainFrame.LayoutOrder = 1
MainFrame.Scale = 1 -- placeholder property not used, but we'll tween Size to simulate scale

local function tweenShow(frame)
    frame.Visible = true
    frame.AnchorPoint = Vector2.new(0.5,0.5)
    frame.Position = UDim2.new(0.5,-320,0.5,-210)
    local start = UDim2.new(0,0,0,0)
    frame.Size = UDim2.new(0,20,0,13) -- tiny to start
    local tg = TweenService:Create(frame, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0,640,0,420)})
    tg:Play()
end
local function tweenHide(frame)
    local tg = TweenService:Create(frame, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0,20,0,13)})
    tg:Play()
    tg.Completed:Wait()
    frame.Visible = false
    frame.Size = UDim2.new(0,640,0,420)
end

-- header logo + title
local Logo = Instance.new("ImageLabel", MainFrame)
Logo.Size = UDim2.new(0,36,0,36)
Logo.Position = UDim2.new(0,12,0,10)
Logo.BackgroundTransparency = 1
Logo.Image = "rbxassetid://76955883171909"
local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(0,200,0,36)
Title.Position = UDim2.new(0,56,0,10)
Title.BackgroundTransparency = 1
Title.Text = "SangHub - BloxFruit"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.TextColor3 = Color3.fromRGB(220,220,220)
Title.TextXAlignment = Enum.TextXAlignment.Left

-- tab strip (scrollable)
local TabScroll = Instance.new("ScrollingFrame", MainFrame)
TabScroll.Size = UDim2.new(1,-100,0,48)
TabScroll.Position = UDim2.new(0,88,0,8)
TabScroll.BackgroundTransparency = 1
TabScroll.ScrollBarThickness = 6
TabScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
local tabLayout = Instance.new("UIListLayout", TabScroll)
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0,8)

-- content holder
local ContentHolder = Instance.new("Frame", MainFrame)
ContentHolder.Size = UDim2.new(1,-20,1,-80)
ContentHolder.Position = UDim2.new(0,10,0,64)
ContentHolder.BackgroundTransparency = 1

-- tab names (explicit)
local TabNames = {"Status","General","Quest & Item","Race & Gear","Shop","Setting","Mic"}
local TabFrames = {}

for i, name in ipairs(TabNames) do
    local btn = Instance.new("TextButton", TabScroll)
    btn.Size = UDim2.new(0,110,1,0)
    btn.Text = name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.BackgroundColor3 = Color3.fromRGB(36,36,36)
    btn.TextColor3 = Color3.fromRGB(240,240,240)
    btn.AutoButtonColor = true
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)

    local frame = Instance.new("Frame", ContentHolder)
    frame.Size = UDim2.new(1,0,1,0)
    frame.Position = UDim2.new(0,0,0,0)
    frame.BackgroundTransparency = 1
    frame.Visible = false

    TabFrames[name] = frame

    btn.MouseButton1Click:Connect(function()
        -- switch tabs (do not hide mainframe)
        for _,f in pairs(TabFrames) do f.Visible = false end
        frame.Visible = true
    end)
end

-- default
TabFrames["Status"].Visible = true

-- ----------------- STATUS TAB UI -----------------
local StatusTab = TabFrames["Status"]

-- title centered in status
local StatusTitleLabel = Instance.new("TextLabel", StatusTab)
StatusTitleLabel.Size = UDim2.new(1,0,0,36)
StatusTitleLabel.Position = UDim2.new(0,0,0,0)
StatusTitleLabel.BackgroundTransparency = 1
StatusTitleLabel.Font = Enum.Font.GothamBold
StatusTitleLabel.TextSize = 20
StatusTitleLabel.TextColor3 = Color3.fromRGB(255,255,255)
StatusTitleLabel.Text = "Status Checking"
StatusTitleLabel.TextXAlignment = Enum.TextXAlignment.Center

-- two-column scroll areas
local LeftScroll = Instance.new("ScrollingFrame", StatusTab)
LeftScroll.Size = UDim2.new(0.5,-12,1,-50)
LeftScroll.Position = UDim2.new(0,6,0,46)
LeftScroll.BackgroundTransparency = 1
LeftScroll.ScrollBarThickness = 6
local LeftList = Instance.new("UIListLayout", LeftScroll); LeftList.Padding = UDim.new(0,8)

local RightScroll = Instance.new("ScrollingFrame", StatusTab)
RightScroll.Size = UDim2.new(0.5,-12,1,-50)
RightScroll.Position = UDim2.new(0.5,6,0,46)
RightScroll.BackgroundTransparency = 1
RightScroll.ScrollBarThickness = 6
local RightList = Instance.new("UIListLayout", RightScroll); RightList.Padding = UDim.new(0,8)

-- status helper to create lines
local function makeStatusLine(parent, leftText, defaultRight)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1,-8,0,28)
    f.BackgroundTransparency = 1
    local l = Instance.new("TextLabel", f)
    l.Size = UDim2.new(0.68,0,1,0)
    l.BackgroundTransparency = 1
    l.Text = leftText
    l.Font = Enum.Font.Gotham
    l.TextSize = 14
    l.TextColor3 = Color3.fromRGB(220,220,220)
    l.TextXAlignment = Enum.TextXAlignment.Left
    local r = Instance.new("TextLabel", f)
    r.Size = UDim2.new(0.32,-6,1,0)
    r.Position = UDim2.new(0.68,6,0,0)
    r.BackgroundTransparency = 1
    r.Text = defaultRight or "—"
    r.Font = Enum.Font.GothamBold
    r.TextSize = 14
    r.TextColor3 = Color3.fromRGB(200,200,200)
    r.TextXAlignment = Enum.TextXAlignment.Right
    return l, r
end

-- Boss lines (Shank, Whitebeard, The Saw)
local _, shankStatus = makeStatusLine(LeftScroll, "Shank tóc đỏ:", "❌")
local _, whiteStatus = makeStatusLine(LeftScroll, "Râu trắng:", "❌")
local _, sawStatus   = makeStatusLine(LeftScroll, "The Saw:", "❌")

-- Right: players, fruits, uptime, moon
local _, playersStatus = makeStatusLine(RightScroll, "Players in server:", "0")
local _, fruitStatus   = makeStatusLine(RightScroll, "FRUIT SPAWN / DROP:", "❌")
local _, uptimeStatus  = makeStatusLine(RightScroll, "Script uptime:", "00:00:00")
local _, moonStatus    = makeStatusLine(RightScroll, "Moon:", "Unknown")

-- status update routine (polling)
local StartTimeLocal = tick()
spawn(function()
    while task.wait(1) do
        pcall(function()
            -- players count
            playersStatus.Text = tostring(#Players:GetPlayers())

            -- boss detection (search names heuristically)
            local foundShank, foundWhite, foundSaw = false,false,false
            for _,v in pairs(workspace:GetDescendants()) do
                if v:IsA("Model") or v:IsA("Folder") then
                    local name = v.Name:lower()
                    if not foundShank and (name:find("shank") or name:find("shank tóc") or name:find("shanks")) then foundShank = true end
                    if not foundWhite and (name:find("whitebeard") or name:find("râu trắng") or name:find("white beard")) then foundWhite = true end
                    if not foundSaw and (name:find("saw") or name:find("the saw")) then foundSaw = true end
                end
            end
            shankStatus.Text = foundShank and "✅" or "❌"
            whiteStatus.Text = foundWhite and "✅" or "❌"
            sawStatus.Text   = foundSaw   and "✅" or "❌"

            -- fruit detection
            local fruits = {}
            for _,obj in pairs(workspace:GetChildren()) do
                if obj:IsA("Tool") and obj:FindFirstChild("Handle") and obj.Name:lower():find("fruit") then
                    table.insert(fruits, obj.Name)
                end
            end
            if #fruits > 0 then
                fruitStatus.Text = table.concat(fruits, ", ")
            else
                fruitStatus.Text = "❌"
            end

            -- uptime
            local elapsed = math.floor(tick() - StartTimeLocal)
            local h = math.floor(elapsed/3600); local m = math.floor((elapsed%3600)/60); local s = elapsed%60
            uptimeStatus.Text = string.format("%02d:%02d:%02d", h, m, s)

            -- moon detection (best-effort)
            local moonObj = workspace:FindFirstChild("Moon") or ReplicatedStorage:FindFirstChild("Moon")
            if moonObj and moonObj.Name:lower():find("real") then
                moonStatus.Text = "Real 🌘🌗🌖🌕"
            elseif moonObj and moonObj.Name:lower():find("fake") then
                moonStatus.Text = "Fake 🌒🌓🌖🌑"
            else
                moonStatus.Text = "Unknown"
            end
        end)
    end
end)

-- ----------------- GENERAL TAB UI -----------------
local GeneralTab = TabFrames["General"]

-- Create two panels: Left = Auto Farm controls, Right = Setting Farming
local leftPanel = Instance.new("Frame", GeneralTab)
leftPanel.Size = UDim2.new(0.5,-12,1,0)
leftPanel.Position = UDim2.new(0,6,0,0)
leftPanel.BackgroundTransparency = 1
local leftScroll = Instance.new("ScrollingFrame", leftPanel)
leftScroll.Size = UDim2.new(1,0,1,0)
leftScroll.CanvasSize = UDim2.new(0,0,0,400)
leftScroll.ScrollBarThickness = 6
leftScroll.BackgroundTransparency = 1
local leftList = Instance.new("UIListLayout", leftScroll); leftList.Padding = UDim.new(0,10)

local rightPanel = Instance.new("Frame", GeneralTab)
rightPanel.Size = UDim2.new(0.5,-12,1,0)
rightPanel.Position = UDim2.new(0.5,6,0,0)
rightPanel.BackgroundTransparency = 1
local rightScroll = Instance.new("ScrollingFrame", rightPanel)
rightScroll.Size = UDim2.new(1,0,1,0)
rightScroll.CanvasSize = UDim2.new(0,0,0,400)
rightScroll.ScrollBarThickness = 6
rightScroll.BackgroundTransparency = 1
local rightList = Instance.new("UIListLayout", rightScroll); rightList.Padding = UDim.new(0,10)

-- RIGHT PANEL: Setting Farming (title + time)
local rightTitle = Instance.new("TextLabel", rightScroll)
rightTitle.Size = UDim2.new(1,-8,0,26)
rightTitle.BackgroundTransparency = 1
rightTitle.Text = "Setting Farming"
rightTitle.Font = Enum.Font.GothamBold
rightTitle.TextSize = 16
rightTitle.TextColor3 = Color3.fromRGB(230,230,230)
rightTitle.TextXAlignment = Enum.TextXAlignment.Left

local serverTimeLabel = Instance.new("TextLabel", rightScroll)
serverTimeLabel.Size = UDim2.new(1,-8,0,22)
serverTimeLabel.BackgroundTransparency = 1
serverTimeLabel.Text = "Local script time: 00:00:00"
serverTimeLabel.Font = Enum.Font.Gotham
serverTimeLabel.TextSize = 13
serverTimeLabel.TextColor3 = Color3.fromRGB(200,200,200)
serverTimeLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Fast attack toggle
local faFrame = Instance.new("Frame", rightScroll)
faFrame.Size = UDim2.new(1,-8,0,40)
faFrame.BackgroundTransparency = 1
local faLabel = Instance.new("TextLabel", faFrame)
faLabel.Size = UDim2.new(0.7,0,1,0); faLabel.BackgroundTransparency = 1
faLabel.Text = "Fast Attack"
faLabel.Font = Enum.Font.Gotham
faLabel.TextSize = 14
faLabel.TextColor3 = Color3.fromRGB(220,220,220)
faLabel.TextXAlignment = Enum.TextXAlignment.Left
local faCircle = Instance.new("ImageLabel", faFrame)
faCircle.Size = UDim2.new(0,34,0,34); faCircle.Position = UDim2.new(0.78,0,0.06,0)
faCircle.BackgroundTransparency = 1
faCircle.Image = "rbxassetid://6031094664" -- empty circle
local faBtn = Instance.new("TextButton", faFrame)
faBtn.Size = UDim2.new(0.2,-8,0.95,0); faBtn.Position = UDim2.new(0.78,0,0.03,0); faBtn.BackgroundTransparency = 1
faBtn.AutoButtonColor = true
local fastOn = false
faBtn.MouseButton1Click:Connect(function()
    fastOn = not fastOn
    getgenv().FastAttack = fastOn
    faCircle.Image = fastOn and "rbxassetid://6031094690" or "rbxassetid://6031094664"
end)

-- LEFT PANEL: Auto Farm controls (title + level farm toggle + select weapon scroller)
local leftTitle = Instance.new("TextLabel", leftScroll)
leftTitle.Size = UDim2.new(1,-8,0,26)
leftTitle.BackgroundTransparency = 1
leftTitle.Text = "Auto Farm"
leftTitle.Font = Enum.Font.GothamBold
leftTitle.TextSize = 16
leftTitle.TextColor3 = Color3.fromRGB(230,230,230)
leftTitle.TextXAlignment = Enum.TextXAlignment.Left

-- Level Farm section with tick-circle
local levelFrame = Instance.new("Frame", leftScroll)
levelFrame.Size = UDim2.new(1,-8,0,70)
levelFrame.BackgroundTransparency = 1
local levelLabel = Instance.new("TextLabel", levelFrame)
levelLabel.Size = UDim2.new(0.6,0,0,28)
levelLabel.Position = UDim2.new(0,6,0,6)
levelLabel.BackgroundTransparency = 1
levelLabel.Text = "Level Farm"
levelLabel.Font = Enum.Font.Gotham
levelLabel.TextSize = 16
levelLabel.TextColor3 = Color3.fromRGB(225,225,225)
levelLabel.TextXAlignment = Enum.TextXAlignment.Left

local levelCircle = Instance.new("ImageLabel", levelFrame)
levelCircle.Size = UDim2.new(0,34,0,34); levelCircle.Position = UDim2.new(0.78,0,0.18,0)
levelCircle.BackgroundTransparency = 1
levelCircle.Image = "rbxassetid://6031094664"
local levelBtn = Instance.new("TextButton", levelFrame)
levelBtn.Size = UDim2.new(0.2,-8,0.95,0); levelBtn.Position = UDim2.new(0.78,0,0.03,0); levelBtn.BackgroundTransparency = 1
levelBtn.AutoButtonColor = true
local levelOn = false
levelBtn.MouseButton1Click:Connect(function()
    levelOn = not levelOn
    getgenv().AutoFarm = levelOn
    levelCircle.Image = levelOn and "rbxassetid://6031094690" or "rbxassetid://6031094664"
end)

-- Select weapon scroller (Melee / Sword), styled as horizontal two buttons (slidable feel)
local selLabel = Instance.new("TextLabel", leftScroll)
selLabel.Size = UDim2.new(1,-8,0,20)
selLabel.BackgroundTransparency = 1
selLabel.Text = "Select Weapon: Nothing"
selLabel.Font = Enum.Font.Gotham
selLabel.TextSize = 13
selLabel.TextColor3 = Color3.fromRGB(200,200,200)
selLabel.TextXAlignment = Enum.TextXAlignment.Left

local selHolder = Instance.new("Frame", leftScroll)
selHolder.Size = UDim2.new(1,-8,0,56)
selHolder.BackgroundTransparency = 1

local selButtons = Instance.new("Frame", selHolder)
selButtons.Size = UDim2.new(1,0,0,44)
selButtons.Position = UDim2.new(0,0,0,6)
selButtons.BackgroundTransparency = 1

local meleeBtn = Instance.new("TextButton", selButtons)
meleeBtn.Size = UDim2.new(0.48,-6,1,0)
meleeBtn.Position = UDim2.new(0,0,0,0)
meleeBtn.Text = "Melee 🥋"
meleeBtn.Font = Enum.Font.GothamBold
meleeBtn.TextSize = 14
meleeBtn.BackgroundColor3 = Color3.fromRGB(28,28,28)
meleeBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", meleeBtn).CornerRadius = UDim.new(0,8)

local swordBtn = Instance.new("TextButton", selButtons)
swordBtn.Size = UDim2.new(0.48,-6,1,0)
swordBtn.Position = UDim2.new(0.52,0,0,0)
swordBtn.Text = "Sword ⚔️"
swordBtn.Font = Enum.Font.GothamBold
swordBtn.TextSize = 14
swordBtn.BackgroundColor3 = Color3.fromRGB(28,28,28)
swordBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", swordBtn).CornerRadius = UDim.new(0,8)

-- selection handling
local function setSelectedWeapon(w)
    getgenv().SelectedWeapon = w or "None"
    selLabel.Text = "Select Weapon: " .. (w or "Nothing")
    -- auto equip immediately if auto farm enabled
    if getgenv().AutoFarm and w and w ~= "None" then
        -- try to auto-equip: call autoEquipSelected() if available (from part2) else attempt a best-effort search
        pcall(function()
            if _G.autoEquipSelected then
                _G.autoEquipSelected()
            else
                -- best effort equip by type
                if w == "Melee" then
                    for _,v in pairs(LocalPlayer.Backpack:GetChildren()) do
                        if v:IsA("Tool") and (v.ToolTip == "Melee" or v.Name:lower():find("combat") or v.Name:lower():find("karate")) then
                            LocalPlayer.Character.Humanoid:EquipTool(v); break
                        end
                    end
                elseif w == "Sword" then
                    for _,v in pairs(LocalPlayer.Backpack:GetChildren()) do
                        if v:IsA("Tool") and (v.ToolTip == "Sword" or v.Name:lower():find("katana") or v.Name:lower():find("blade")) then
                            LocalPlayer.Character.Humanoid:EquipTool(v); break
                        end
                    end
                end
            end
        end)
    end
end

meleeBtn.MouseButton1Click:Connect(function()
    setSelectedWeapon("Melee")
    meleeBtn.BackgroundColor3 = Color3.fromRGB(50,120,200)
    swordBtn.BackgroundColor3 = Color3.fromRGB(28,28,28)
end)
swordBtn.MouseButton1Click:Connect(function()
    setSelectedWeapon("Sword")
    swordBtn.BackgroundColor3 = Color3.fromRGB(50,120,200)
    meleeBtn.BackgroundColor3 = Color3.fromRGB(28,28,28)
end)

-- update server/script time label
spawn(function()
    while task.wait(1) do
        pcall(function()
            local elapsed = math.floor(tick() - StartTimeLocal)
            local h = math.floor(elapsed/3600); local m = math.floor((elapsed%3600)/60); local s = elapsed%60
            serverTimeLabel.Text = "Local script time: " .. string.format("%02d:%02d:%02d",h,m,s)
        end)
    end
end)

-- Toggle button open/close
local guiOpen = false
ToggleBtn.MouseButton1Click:Connect(function()
    guiOpen = not guiOpen
    if guiOpen then
        tweenShow(MainFrame)
    else
        tweenHide(MainFrame)
    end
end)

-- make the main frame draggable on mobile (touch) and desktop
do
    local dragging = false
    local dragInput, dragStart, startPos
    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    MainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    RunService.Heartbeat:Connect(function()
        if dragging and dragInput and dragStart and startPos then
            local delta = dragInput.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- final log
print("[SangHub GUI] Part 3 (GUI) loaded. Use Toggle button (top-left) to open/close.")
