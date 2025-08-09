-- SangHub - Integrated GUI + AutoFarm (Full raw .lua)
-- Paste toàn bộ file này vào executor

-- ========== ANTI-AFK ==========
pcall(function()
    for i,v in pairs(getconnections or {})(game.Players.LocalPlayer.Idled) do
        if type(v.Disable) == "function" then
            pcall(v.Disable, v)
        end
    end
end)

-- ========== SERVICES & LOCAL REFS ==========
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local VirtualInput = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

-- safety checks
if not LocalPlayer then
    return warn("No LocalPlayer found - aborting script")
end

-- ========== GLOBAL STATE ==========
local State = {
    AutoFarm = false,
    SelectedWeapon = "None", -- "Melee" or "Sword"
    FastAttack = false,
    AutoCollectFruit = false,
    StartTime = tick(),
    EnableIslandESP = false,
    UIsVisible = true
}

-- ========== DATA: SEA1 islands + level mapping ==========
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

-- ========== UTIL FUNCTIONS ==========
local function safeWait(t) task.wait(t or 0.03) end

local function getPlayerLevel()
    local lvl = 0
    pcall(function() lvl = LocalPlayer.Data.Level.Value end)
    return lvl
end

local function getBestForLevel()
    local lvl = getPlayerLevel()
    local best = nil
    for _,d in ipairs(LevelToMob) do
        if lvl >= d.LevelReq then best = d end
    end
    return best
end

local function tweenToCF(cf, speed)
    if not cf then return end
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    speed = speed or 250
    local hrp = LocalPlayer.Character.HumanoidRootPart
    local dist = (hrp.Position - cf.Position).Magnitude
    local info = TweenService:Create(hrp, TweenInfo.new(dist/math.max(speed,1), Enum.EasingStyle.Linear), {CFrame = cf})
    pcall(function() info:Play() end)
    if info then
        pcall(function() info.Completed:Wait() end)
    end
end

local function clickOnce()
    pcall(function()
        VirtualInput:SendMouseButtonEvent(0,0,0,true,game,0)
        task.wait()
        VirtualInput:SendMouseButtonEvent(0,0,0,false,game,0)
    end)
end

-- Find nearest mob by substring in name
local function findNearestMobByName(name)
    local closest, dist = nil, math.huge
    local enemies = workspace:FindFirstChild("Enemies") and workspace.Enemies:GetChildren() or {}
    for _,m in pairs(enemies) do
        if m and m:FindFirstChild("HumanoidRootPart") and m:FindFirstChild("Humanoid") and m.Humanoid.Health > 0 and string.find(m.Name, name) then
            local d = (m.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            if d < dist then dist = d; closest = m end
        end
    end
    return closest
end

local function createFloatingPlatform(name)
    local pname = name or "SangHub_FloatBlock"
    if workspace:FindFirstChild(pname) then return workspace[pname] end
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    local p = Instance.new("Part", workspace)
    p.Name = pname
    p.Anchored = true
    p.CanCollide = true
    p.Size = Vector3.new(10,1,10)
    p.Transparency = 1
    p.Position = LocalPlayer.Character.HumanoidRootPart.Position - Vector3.new(0,3.5,0)
    return p
end

local function removeFloatingPlatform(name)
    local pname = name or "SangHub_FloatBlock"
    if workspace:FindFirstChild(pname) then
        pcall(function() workspace[pname]:Destroy() end)
    end
end

local function expandHitbox(model)
    pcall(function()
        for _,part in ipairs(model:GetChildren()) do
            if part:IsA("BasePart") then
                part.Size = Vector3.new(60,60,60)
                part.Transparency = 0.7
                part.CanCollide = false
                part.Material = Enum.Material.Neon
            end
        end
    end)
end

local function autoEquipSelected()
    if not LocalPlayer.Character then return end
    if State.SelectedWeapon == "Melee" then
        -- try to equip any melee tool (ToolTip == "Melee" or name matches styles)
        for _,v in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if v:IsA("Tool") then
                local name = v.Name:lower()
                if (v.ToolTip and v.ToolTip == "Melee") or name:find("combat") or name:find("karate") or name:find("death") or name:find("dragon") or name:find("shark") then
                    pcall(function() LocalPlayer.Character.Humanoid:EquipTool(v) end)
                    return
                end
            end
        end
    elseif State.SelectedWeapon == "Sword" then
        for _,v in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if v:IsA("Tool") then
                local name = v.Name:lower()
                if (v.ToolTip and v.ToolTip == "Sword") or name:find("katana") or name:find("sword") or name:find("blade") or name:find("bisento") then
                    pcall(function() LocalPlayer.Character.Humanoid:EquipTool(v) end)
                    return
                end
            end
        end
    end
end

local function startQuest(quest)
    pcall(function()
        ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", quest, 1)
    end)
end

local function openFruitStock()
    pcall(function()
        ReplicatedStorage.Remotes.CommF_:InvokeServer("GetFruits")
    end)
end

-- Try to use CombatFramework fast attack if available (best-effort)
local FastAttackAvailable, CombatFramework, CombatController
do
    pcall(function()
        if LocalPlayer and LocalPlayer.PlayerScripts and LocalPlayer.PlayerScripts:FindFirstChild("CombatFramework") then
            CombatFramework = require(LocalPlayer.PlayerScripts:FindFirstChild("CombatFramework"))
            -- try to get controller upvalues (may fail or be obfuscated)
            pcall(function()
                local up = debug and debug.getupvalues and debug.getupvalues(CombatFramework) or nil
                if up and type(up) == "table" then
                    for _,v in ipairs(up) do
                        if type(v) == "table" and v.activeController then
                            CombatController = v
                            break
                        end
                    end
                end
            end)
        end
    end)
    FastAttackAvailable = (CombatController ~= nil)
end

local function fastAttackTick()
    -- If CombatController available, try to call its attack manipulation (best-effort).
    if FastAttackAvailable and CombatController and CombatController.activeController and CombatController.activeController.equipped then
        pcall(function()
            -- best-effort: call attack function if available
            if CombatController.activeController and CombatController.activeController.attack then
                CombatController.activeController:attack()
            end
        end)
    else
        -- fallback: virtual click
        clickOnce()
    end
end

-- ========== GUI BUILD ==========
local function CreateUI()
    -- clear old
    if game.CoreGui:FindFirstChild("BloxFruit_TabGUI") then
        pcall(function() game.CoreGui:FindFirstChild("BloxFruit_TabGUI"):Destroy() end)
    end

    local Gui = Instance.new("ScreenGui", game.CoreGui)
    Gui.Name = "BloxFruit_TabGUI"
    Gui.ResetOnSpawn = false
    Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Toggle Button (top-left)
    local ToggleBtn = Instance.new("ImageButton", Gui)
    ToggleBtn.Size = UDim2.new(0, 44, 0, 44)
    ToggleBtn.Position = UDim2.new(0, 12, 0, 12)
    ToggleBtn.Image = "rbxassetid://76955883171909"
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(25,25,25)
    ToggleBtn.AutoButtonColor = true
    ToggleBtn.Name = "SangHubToggle"
    local tCorner = Instance.new("UICorner", ToggleBtn); tCorner.CornerRadius = UDim.new(0,8)

    -- Main Frame
    local MainFrame = Instance.new("Frame", Gui)
    MainFrame.Size = UDim2.new(0, 640, 0, 420)
    MainFrame.Position = UDim2.new(0.5, -320, 0.5, -210)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
    MainFrame.Active = true
    MainFrame.Visible = false
    MainFrame.Name = "MainFrame"
    local mCorner = Instance.new("UICorner", MainFrame); mCorner.CornerRadius = UDim.new(0,10)

    -- Logo
    local Logo = Instance.new("ImageLabel", MainFrame)
    Logo.Size = UDim2.new(0, 34, 0, 34)
    Logo.Position = UDim2.new(0, 12, 0, 8)
    Logo.BackgroundTransparency = 1
    Logo.Image = "rbxassetid://76955883171909"

    -- Tab strip (scrollable)
    local TabScroll = Instance.new("ScrollingFrame", MainFrame)
    TabScroll.Size = UDim2.new(1, -60, 0, 44)
    TabScroll.Position = UDim2.new(0, 56, 0, 8)
    TabScroll.BackgroundTransparency = 1
    TabScroll.ScrollBarThickness = 6
    TabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
    local tabLayout = Instance.new("UIListLayout", TabScroll)
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0,6)

    -- Content container
    local ContentHolder = Instance.new("Frame", MainFrame)
    ContentHolder.Size = UDim2.new(1, -20, 1, -70)
    ContentHolder.Position = UDim2.new(0, 10, 0, 60)
    ContentHolder.BackgroundTransparency = 1

    local TabsNames = {"Status","General","Quest & Item","Race & Gear","Shop","Setting","Mic"}
    local TabFrames = {}

    for i, name in ipairs(TabsNames) do
        local btn = Instance.new("TextButton", TabScroll)
        btn.Size = UDim2.new(0, 110, 1, 0)
        btn.Text = name
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.AutoButtonColor = true
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)

        local frame = Instance.new("Frame", ContentHolder)
        frame.Size = UDim2.new(1,0,1,0)
        frame.Position = UDim2.new(0,0,0,0)
        frame.BackgroundTransparency = 1
        frame.Visible = false

        TabFrames[name] = frame

        btn.MouseButton1Click:Connect(function()
            for _,f in pairs(TabFrames) do f.Visible = false end
            frame.Visible = true
        end)
    end

    TabFrames["Status"].Visible = true

    -- ========== STATUS TAB ==========
    local StatusTab = TabFrames["Status"]

    local StatusTitle = Instance.new("TextLabel", StatusTab)
    StatusTitle.Size = UDim2.new(1,0,0,40)
    StatusTitle.Position = UDim2.new(0,0,0,0)
    StatusTitle.BackgroundTransparency = 1
    StatusTitle.Font = Enum.Font.GothamBold
    StatusTitle.TextSize = 20
    StatusTitle.TextColor3 = Color3.fromRGB(255,255,255)
    StatusTitle.Text = "Status Checking"
    StatusTitle.TextXAlignment = Enum.TextXAlignment.Center

    local left = Instance.new("ScrollingFrame", StatusTab)
    left.Size = UDim2.new(0.5, -10, 1, -50)
    left.Position = UDim2.new(0,5,0,45)
    left.BackgroundTransparency = 1
    left.ScrollBarThickness = 6
    local leftLayout = Instance.new("UIListLayout", left)
    leftLayout.Padding = UDim.new(0,6)

    local right = Instance.new("ScrollingFrame", StatusTab)
    right.Size = UDim2.new(0.5, -10, 1, -50)
    right.Position = UDim2.new(0.5, 5, 0, 45)
    right.BackgroundTransparency = 1
    right.ScrollBarThickness = 6
    local rightLayout = Instance.new("UIListLayout", right)
    rightLayout.Padding = UDim.new(0,6)

    local function makeStatusLine(parent, title)
        local f = Instance.new("Frame", parent)
        f.Size = UDim2.new(1, -10, 0, 28)
        f.BackgroundTransparency = 1
        local tl = Instance.new("TextLabel", f)
        tl.Size = UDim2.new(0.7, 0, 1, 0)
        tl.BackgroundTransparency = 1
        tl.Text = title
        tl.Font = Enum.Font.Gotham
        tl.TextColor3 = Color3.fromRGB(220,220,220)
        tl.TextXAlignment = Enum.TextXAlignment.Left
        local status = Instance.new("TextLabel", f)
        status.Size = UDim2.new(0.3, -6, 1, 0)
        status.Position = UDim2.new(0.7, 6, 0, 0)
        status.BackgroundTransparency = 1
        status.Font = Enum.Font.GothamBold
        status.TextSize = 14
        status.TextXAlignment = Enum.TextXAlignment.Right
        return f, tl, status
    end

    local bossShankF, bossShankL, bossShankStatus = makeStatusLine(left, "Shank tóc đỏ:")
    local bossWhiteF, bossWhiteL, bossWhiteStatus = makeStatusLine(left, "Râu trắng:")
    local bossSawF, bossSawL, bossSawStatus = makeStatusLine(left, "The Saw:")

    local playersCountF, playersCountL, playersCountStatus = makeStatusLine(right, "Players in server:")
    local fruitSpawnF, fruitSpawnL, fruitSpawnStatus = makeStatusLine(right, "FRUIT SPAWN / DROP:")
    local timeLabelF, timeLabelL, timeLabelStatus = makeStatusLine(right, "Script uptime:")
    local moonLabelF, moonLabelL, moonLabelStatus = makeStatusLine(right, "Moon:")

    local function updateStatus()
        pcall(function()
            playersCountStatus.Text = tostring(#Players:GetPlayers())
            -- boss detection
            local foundShank, foundWhite, foundSaw = false,false,false
            for _,v in pairs(workspace:GetDescendants()) do
                if v:IsA("Model") or v:IsA("Folder") then
                    local n = v.Name:lower()
                    if n:find("shank") then foundShank = true end
                    if n:find("whitebeard") or n:find("white beard") or n:find("râu trắng") then foundWhite = true end
                    if n:find("saw") and (not n:find("chainsaw") or n:find("the saw")) then foundSaw = true end
                end
            end
            bossShankStatus.Text = foundShank and "✅" or "❌"
            bossWhiteStatus.Text = foundWhite and "✅" or "❌"
            bossSawStatus.Text = foundSaw and "✅" or "❌"

            -- fruit detection
            local fruits = {}
            for _,obj in pairs(workspace:GetChildren()) do
                if obj:IsA("Tool") and obj:FindFirstChild("Handle") and string.match(obj.Name:lower(),"fruit") then
                    table.insert(fruits, obj.Name)
                end
            end
            if #fruits>0 then fruitSpawnStatus.Text = table.concat(fruits, ", ") else fruitSpawnStatus.Text = "❌" end

            -- uptime
            local elapsed = math.floor(tick() - State.StartTime)
            local hrs = math.floor(elapsed/3600); local mins = math.floor((elapsed%3600)/60); local secs = elapsed%60
            timeLabelStatus.Text = string.format("%02d:%02d:%02d", hrs, mins, secs)

            -- moon detection heuristics
            local moonObj = workspace:FindFirstChild("Moon") or ReplicatedStorage:FindFirstChild("Moon")
            if moonObj and tostring(moonObj.Name):lower():find("real") then
                moonLabelStatus.Text = "Real 🌘🌗🌖🌕"
            elseif moonObj and tostring(moonObj.Name):lower():find("fake") then
                moonLabelStatus.Text = "Fake 🌒🌓🌗🌑"
            else
                moonLabelStatus.Text = "Unknown"
            end
        end)
    end

    spawn(function()
        while task.wait(1) do
            pcall(updateStatus)
        end
    end)

    -- ========== GENERAL TAB ==========
    local GeneralTab = TabFrames["General"]

    -- Left panel = Auto Farm controls (Auto Farm)
    local LeftPanel = Instance.new("Frame", GeneralTab)
    LeftPanel.Size = UDim2.new(0.5, -10, 1, 0)
    LeftPanel.Position = UDim2.new(0, 0, 0, 0)
    LeftPanel.BackgroundTransparency = 1

    local LeftScroll = Instance.new("ScrollingFrame", LeftPanel)
    LeftScroll.Size = UDim2.new(1,1,1,0)
    LeftScroll.CanvasSize = UDim2.new(0,0,0,400)
    LeftScroll.ScrollBarThickness = 6
    LeftScroll.BackgroundTransparency = 1
    local LeftList = Instance.new("UIListLayout", LeftScroll); LeftList.Padding = UDim.new(0,8)

    -- Right panel = Settings / select weapon
    local RightPanel = Instance.new("Frame", GeneralTab)
    RightPanel.Size = UDim2.new(0.5, -10, 1, 0)
    RightPanel.Position = UDim2.new(0.5, 10, 0, 0)
    RightPanel.BackgroundTransparency = 1

    local RightScroll = Instance.new("ScrollingFrame", RightPanel)
    RightScroll.Size = UDim2.new(1,1,1,0)
    RightScroll.CanvasSize = UDim2.new(0,0,0,400)
    RightScroll.ScrollBarThickness = 6
    RightScroll.BackgroundTransparency = 1
    local RightList = Instance.new("UIListLayout", RightScroll); RightList.Padding = UDim.new(0,8)

    -- Left: Auto Farm (title + toggle + fast attack)
    local function lbl(parent, text)
        local t = Instance.new("TextLabel", parent)
        t.Size = UDim2.new(1, -12, 0, 28)
        t.BackgroundTransparency = 1
        t.Text = text
        t.Font = Enum.Font.GothamBold
        t.TextSize = 15
        t.TextColor3 = Color3.fromRGB(220,220,220)
        t.TextXAlignment = Enum.TextXAlignment.Left
        return t
    end

    lbl(LeftScroll, "Auto Farm")

    local farmFrame = Instance.new("Frame", LeftScroll)
    farmFrame.Size = UDim2.new(1, -12, 0, 60)
    farmFrame.BackgroundTransparency = 1

    local farmLabel = Instance.new("TextLabel", farmFrame)
    farmLabel.Size = UDim2.new(0.6,0,1,0)
    farmLabel.BackgroundTransparency = 1
    farmLabel.Text = "Level Farm"
    farmLabel.Font = Enum.Font.Gotham
    farmLabel.TextSize = 16
    farmLabel.TextColor3 = Color3.new(1,1,1)
    farmLabel.TextXAlignment = Enum.TextXAlignment.Left

    local tickCircle = Instance.new("ImageLabel", farmFrame)
    tickCircle.Size = UDim2.new(0,34,0,34)
    tickCircle.Position = UDim2.new(0.78,0,0.14,0)
    tickCircle.BackgroundTransparency = 1
    tickCircle.Image = "rbxassetid://6031094664" -- empty circle

    local lvlToggle = false
    local lvlBtn = Instance.new("TextButton", farmFrame)
    lvlBtn.Size = UDim2.new(0.2, -8, 0.9, 0)
    lvlBtn.Position = UDim2.new(0.78, 0, 0.05, 0)
    lvlBtn.Text = ""
    lvlBtn.BackgroundTransparency = 1
    lvlBtn.AutoButtonColor = true
    lvlBtn.MouseButton1Click:Connect(function()
        lvlToggle = not lvlToggle
        tickCircle.Image = lvlToggle and "rbxassetid://6031094690" or "rbxassetid://6031094664"
        State.AutoFarm = lvlToggle
        if State.AutoFarm then
            spawn(function()
                pcall(function() AutoFarmLoop() end)
            end)
        end
    end)

    -- Fast Attack toggle
    lbl(LeftScroll, "Fast Attack (use with caution)")
    local fastFrame = Instance.new("Frame", LeftScroll); fastFrame.Size = UDim2.new(1,-12,0,48); fastFrame.BackgroundTransparency = 1
    local fastLabel = Instance.new("TextLabel", fastFrame); fastLabel.Size=UDim2.new(0.6,0,1,0); fastLabel.BackgroundTransparency=1; fastLabel.Text="Fast Attack"; fastLabel.Font=Enum.Font.Gotham; fastLabel.TextColor3=Color3.new(1,1,1)
    local fastToggleImg = Instance.new("ImageLabel", fastFrame); fastToggleImg.Size=UDim2.new(0,34,0,34); fastToggleImg.Position=UDim2.new(0.78,0,0.14,0); fastToggleImg.BackgroundTransparency=1; fastToggleImg.Image="rbxassetid://6031094664"
    local fastBtn = Instance.new("TextButton", fastFrame); fastBtn.Size=UDim2.new(0.2,-8,0.9,0); fastBtn.Position=UDim2.new(0.78,0,0.05,0); fastBtn.BackgroundTransparency=1
    local fastState=false
    fastBtn.MouseButton1Click:Connect(function()
        fastState = not fastState
        fastToggleImg.Image = fastState and "rbxassetid://6031094690" or "rbxassetid://6031094664"
        State.FastAttack = fastState
    end)

    -- Right: Setting Farming (Select Weapon + time)
    lbl(RightScroll, "Setting Farming")
    local selFrame = Instance.new("Frame", RightScroll)
    selFrame.Size = UDim2.new(1, -12, 0, 100)
    selFrame.BackgroundTransparency = 1

    local selLabel = Instance.new("TextLabel", selFrame)
    selLabel.Size = UDim2.new(1, 0, 0, 24)
    selLabel.Position = UDim2.new(0,0,0,0)
    selLabel.BackgroundTransparency = 1
    selLabel.Text = "Select Weapon: Nothing"
    selLabel.Font = Enum.Font.Gotham
    selLabel.TextSize = 14
    selLabel.TextColor3 = Color3.new(1,1,1)
    selLabel.TextXAlignment = Enum.TextXAlignment.Left

    local selButtons = Instance.new("Frame", selFrame)
    selButtons.Size = UDim2.new(1,0,0,44)
    selButtons.Position = UDim2.new(0,0,0,28)
    selButtons.BackgroundTransparency = 1

    local meleeBtn = Instance.new("TextButton", selButtons)
    meleeBtn.Size = UDim2.new(0.48, -6, 1, 0)
    meleeBtn.Position = UDim2.new(0,0,0,0)
    meleeBtn.Text = "Melee 🥋"
    meleeBtn.Font = Enum.Font.GothamBold
    meleeBtn.TextSize = 14
    meleeBtn.BackgroundColor3 = Color3.fromRGB(28,28,28)
    meleeBtn.TextColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", meleeBtn).CornerRadius = UDim.new(0,6)

    local swordBtn = Instance.new("TextButton", selButtons)
    swordBtn.Size = UDim2.new(0.48, -6, 1, 0)
    swordBtn.Position = UDim2.new(0.52, 0, 0, 0)
    swordBtn.Text = "Sword ⚔️"
    swordBtn.Font = Enum.Font.GothamBold
    swordBtn.TextSize = 14
    swordBtn.BackgroundColor3 = Color3.fromRGB(28,28,28)
    swordBtn.TextColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", swordBtn).CornerRadius = UDim.new(0,6)

    meleeBtn.MouseButton1Click:Connect(function()
        State.SelectedWeapon = "Melee"
        selLabel.Text = "Select Weapon: Melee"
        -- auto equip immediately
        pcall(autoEquipSelected)
    end)
    swordBtn.MouseButton1Click:Connect(function()
        State.SelectedWeapon = "Sword"
        selLabel.Text = "Select Weapon: Sword"
        pcall(autoEquipSelected)
    end)

    -- Add server time label under setting
    local srvTimeLbl = Instance.new("TextLabel", RightScroll)
    srvTimeLbl.Size = UDim2.new(1, -12, 0, 28)
    srvTimeLbl.BackgroundTransparency = 1
    srvTimeLbl.Font = Enum.Font.Gotham
    srvTimeLbl.TextSize = 14
    srvTimeLbl.TextColor3 = Color3.fromRGB(200,200,200)
    srvTimeLbl.Text = "Server time: N/A"

    spawn(function()
        while task.wait(1) do
            pcall(function()
                -- try to fetch in-game time if available (some games put in workspace or ReplicatedStorage)
                local tstr = "N/A"
                if workspace:FindFirstChild("Time") and workspace.Time.Value then
                    tstr = tostring(workspace.Time.Value)
                elseif ReplicatedStorage:FindFirstChild("WorldTime") and ReplicatedStorage.WorldTime.Value then
                    tstr = tostring(ReplicatedStorage.WorldTime.Value)
                end
                srvTimeLbl.Text = "Server time: "..tstr
            end)
        end
    end)

    -- Toggle show/hide main frame with scale animation
    local visible = false
    local function tweenScaleObject(obj, start, finish, dur)
        pcall(function()
            obj.Size = start.size
            obj.Position = start.pos
            local s = TweenService:Create(obj, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = finish.size, Position = finish.pos})
            s:Play()
            s.Completed:Wait()
        end)
    end

    ToggleBtn.MouseButton1Click:Connect(function()
        visible = not visible
        if visible then
            MainFrame.Visible = true
            -- simple scale in: from small to actual
            MainFrame.Size = UDim2.new(0, 20, 0, 20)
            MainFrame.Position = UDim2.new(0.5, -10, 0.5, -10)
            local t = TweenService:Create(MainFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0,640,0,420), Position = UDim2.new(0.5,-320,0.5,-210)})
            t:Play()
        else
            local t = TweenService:Create(MainFrame, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(0.5,-10,0.5,-10)})
            t:Play()
            t.Completed:Wait()
            MainFrame.Visible = false
        end
    end)

    return {
        Gui = Gui,
        MainFrame = MainFrame,
        TabFrames = TabFrames,
        Controls = {
            LevelToggle = lvlBtn,
            TickCircle = tickCircle,
            FastToggle = fastBtn,
            FastImg = fastToggleImg,
            MeleeBtn = meleeBtn,
            SwordBtn = swordBtn,
            SelLabel = selLabel
        }
    }
end

-- Build UI
local UI = CreateUI()

-- ========== AUTO FARM LOGIC ==========
-- Helper: find mob spawn (first available matching)
local function getAnyMob(mobName)
    for _,m in pairs(workspace:FindFirstChild("Enemies") and workspace.Enemies:GetChildren() or {}) do
        if m and m:FindFirstChild("HumanoidRootPart") and m:FindFirstChild("Humanoid") and m.Humanoid.Health>0 and string.find(m.Name, mobName) then
            return m
        end
    end
    return nil
end

local function gotoIslandForMob(mobName)
    local cf = IslandPositions[mobName]
    if cf then
        -- go to island center
        tweenToCF(cf)
        task.wait(1)
        -- small upward teleport/hover so NPC can be reached: will tween to NPC later
    end
end

local function getQuestNPCPosition(questName)
    -- Best-effort: search workspace for NPC model with questName in its name or in GuideModule NPC list if available
    -- fallback: use previously stored IslandPositions mobs' CFrame
    -- We will try to find an NPC model with a Head/HumanoidRootPart and name contains questName
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Head") and v:FindFirstChild("HumanoidRootPart") then
            if string.find(v.Name, questName) or string.find(v.Name:lower(), questName:lower()) then
                return v.HumanoidRootPart.CFrame
            end
        end
    end
    return nil
end

-- Auto farm loop function (single-run)
function AutoFarmLoop()
    -- This function attempts to do: tween to island -> go to NPC -> start quest -> find mobs -> fly above + attack -> loop until stop
    while State.AutoFarm do
        pcall(function()
            local best = getBestForLevel()
            if not best then
                task.wait(2)
                return
            end

            -- Move to island
            if IslandPositions[best.Mob] then
                tweenToCF(IslandPositions[best.Mob], 250)
            end
            task.wait(2)

            -- Try to get quest from NPC (Best-effort)
            local npcCF = getQuestNPCPosition(best.Quest)
            if npcCF then
                tweenToCF(npcCF, 300)
                task.wait(1.2)
                startQuest(best.Quest)
                task.wait(1)
            else
                -- fallback: try to invoke StartQuest directly
                startQuest(best.Quest)
                task.wait(1)
            end

            -- Wait for mobs to spawn
            local timeout = tick() + 12
            local mob = nil
            while tick() < timeout and State.AutoFarm do
                mob = getAnyMob(best.Mob)
                if mob then break end
                task.wait(0.5)
            end

            if not mob then
                task.wait(2)
                return
            end

            -- Create platform and attack mobs
            createFloatingPlatform("SangHub_FloatBlock")
            -- bring mobs near player if desired: try repositioning mobs (best-effort)
            for _,m in pairs(workspace:FindFirstChild("Enemies") and workspace.Enemies:GetChildren() or {}) do
                if m and string.find(m.Name, best.Mob) and m:FindFirstChild("HumanoidRootPart") then
                    pcall(function()
                        m.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0,3,0)
                        expandHitbox(m)
                    end)
                end
            end

            -- Equip chosen weapon
            pcall(autoEquipSelected)

            -- attack loop for mobs of this quest until quest completes or AutoFarm is turned off
            repeat
                if not State.AutoFarm then break end
                local target = getAnyMob(best.Mob)
                if not target then
                    task.wait(0.6)
                    break
                end
                -- move above the mob
                tweenToCF(target.HumanoidRootPart.CFrame + Vector3.new(0, 10, 0), 450)
                -- ensure we have platform below
                createFloatingPlatform("SangHub_FloatBlock")
                -- fast attack or click spam
                local attackUntil = tick() + 30 -- safeguard
                while target and target:FindFirstChild("Humanoid") and target.Humanoid.Health > 0 and State.AutoFarm do
                    if State.FastAttack then
                        fastAttackTick()
                    else
                        clickOnce()
                    end
                    task.wait(0.08)
                    -- re-equip if lost
                    if not LocalPlayer.Character:FindFirstChildOfClass("Tool") and State.SelectedWeapon ~= "None" then
                        pcall(autoEquipSelected)
                    end
                    if tick() > attackUntil then -- break to re-evaluate mob list occasionally
                        break
                    end
                end
                task.wait(0.2)
            until not State.AutoFarm

            task.wait(1)
        end)
        safeWait(0.5)
    end
    -- clean up platform when stopping
    removeFloatingPlatform("SangHub_FloatBlock")
end

-- auto-equip keepalive: if auto-farm on and no tool, try to equip
spawn(function()
    while task.wait(1) do
        if State.AutoFarm and State.SelectedWeapon ~= "None" then
            if LocalPlayer.Character and not LocalPlayer.Character:FindFirstChildOfClass("Tool") then
                pcall(autoEquipSelected)
            end
        end
    end
end)

-- auto-collect fruit background if enabled
spawn(function()
    while task.wait(5) do
        if State.AutoCollectFruit then
            for _,obj in pairs(workspace:GetChildren()) do
                if obj:IsA("Tool") and obj:FindFirstChild("Handle") and string.match(obj.Name:lower(),"fruit") then
                    pcall(function()
                        firetouchinterest(LocalPlayer.Character.HumanoidRootPart, obj.Handle, 0)
                        task.wait(0.12)
                        firetouchinterest(LocalPlayer.Character.HumanoidRootPart, obj.Handle, 1)
                    end)
                end
            end
        end
    end
end)

-- ========== BUTTON HOOKUPS for created UI ==========
-- UI variable returned earlier
-- connect the UI controls if present
local function HookUIControls(ui)
    if not ui or not ui.Controls then return end
    local c = ui.Controls
    -- Level toggle is the UI element that toggles State.AutoFarm; we already change State when clicked
    -- But also add safety: start AutoFarmLoop when toggled on
    -- (The Level toggle already spawns AutoFarmLoop when clicked; keep idempotent)
    -- Fast toggle was set above, ensure hooking
    if c.FastToggle then
        c.FastToggle.MouseButton1Click:Connect(function()
            State.FastAttack = not State.FastAttack
            c.FastImg.Image = State.FastAttack and "rbxassetid://6031094690" or "rbxassetid://6031094664"
        end)
    end
    if c.MeleeBtn then
        c.MeleeBtn.MouseButton1Click:Connect(function()
            State.SelectedWeapon = "Melee"
            c.SelLabel.Text = "Select Weapon: Melee"
            pcall(autoEquipSelected)
        end)
    end
    if c.SwordBtn then
        c.SwordBtn.MouseButton1Click:Connect(function()
            State.SelectedWeapon = "Sword"
            c.SelLabel.Text = "Select Weapon: Sword"
            pcall(autoEquipSelected)
        end)
    end
end

-- find the ui returned earlier (CreateUI returned it into UI var)
HookUIControls(UI)

-- ========== FINAL LOG ==========
print("✅ SangHub Auto Farm (raw) loaded. UI created. Controls: AutoFarm, SelectWeapon(Melee/Sword), FastAttack toggle, AutoCollectFruit toggle.")
print("Start time:", os.date("%c", os.time()))

-- If you want to auto-start UI visible, uncomment:
-- UI.MainFrame.Visible = true

-- End of script
