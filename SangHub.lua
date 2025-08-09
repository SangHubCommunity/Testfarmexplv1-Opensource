--==[ SangHub Full GUI + AutoFarm (Sea1 Example) ]==--

-- Anti AFK
for _,v in pairs(getconnections(game.Players.LocalPlayer.Idled)) do
    pcall(function() v:Disable() end)
end

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local VirtualInput = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Config
getgenv().AutoFarm = false
getgenv().SelectedWeapon = "None" -- "Melee" or "Sword"
getgenv().FastAttack = false
local StartTime = tick()

-- Island positions
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

-- Level to mob mapping
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

-- Utilities
local function getBestForLevel()
    local lvl = LocalPlayer.Data.Level.Value
    local best
    for _,d in ipairs(LevelToMob) do
        if lvl >= d.LevelReq then best = d end
    end
    return best
end

local function tweenTo(cf, speed)
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    speed = speed or 250
    local hrp = LocalPlayer.Character.HumanoidRootPart
    local dist = (hrp.Position - cf.Position).Magnitude
    local t = TweenService:Create(hrp, TweenInfo.new(dist/speed, Enum.EasingStyle.Linear), {CFrame = cf})
    t:Play()
    t.Completed:Wait()
end

local function sendClick()
    VirtualInput:SendMouseButtonEvent(0,0,0,true,game,0)
    task.wait()
    VirtualInput:SendMouseButtonEvent(0,0,0,false,game,0)
end

local function findNearestMobByName(name)
    local closest, dist = nil, math.huge
    for _,m in pairs(workspace:FindFirstChild("Enemies") and workspace.Enemies:GetChildren() or {}) do
        if m:FindFirstChild("HumanoidRootPart") and m.Humanoid.Health > 0 and string.find(m.Name, name) then
            local d = (m.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            if d < dist then dist = d; closest = m end
        end
    end
    return closest
end

local function createFloatingPlatform()
    if workspace:FindFirstChild("SangHub_FloatBlock") then return end
    local p = Instance.new("Part", workspace)
    p.Name = "SangHub_FloatBlock"
    p.Anchored = true
    p.CanCollide = true
    p.Size = Vector3.new(10,1,10)
    p.Transparency = 1
    p.Position = LocalPlayer.Character.HumanoidRootPart.Position - Vector3.new(0,3.5,0)
end

local function removeFloatingPlatform()
    if workspace:FindFirstChild("SangHub_FloatBlock") then
        workspace.SangHub_FloatBlock:Destroy()
    end
end

local function expandHitbox(m)
    for _,part in ipairs(m:GetChildren()) do
        if part:IsA("BasePart") then
            part.Size = Vector3.new(60,60,60)
            part.Transparency = 0.6
            part.CanCollide = false
            part.Material = Enum.Material.Neon
        end
    end
end

local function autoEquipSelected()
    if getgenv().SelectedWeapon == "Melee" then
        for _,v in pairs(LocalPlayer.Backpack:GetChildren()) do
            if v:IsA("Tool") and (v.ToolTip == "Melee" or v.Name:lower():find("combat") or v.Name:lower():find("karate")) then
                LocalPlayer.Character.Humanoid:EquipTool(v)
                return
            end
        end
    elseif getgenv().SelectedWeapon == "Sword" then
        for _,v in pairs(LocalPlayer.Backpack:GetChildren()) do
            if v:IsA("Tool") and (v.ToolTip == "Sword" or v.Name:lower():find("sword") or v.Name:lower():find("katana")) then
                LocalPlayer.Character.Humanoid:EquipTool(v)
                return
            end
        end
    end
end
-- SangHub UI (Safe version) - raw .lua
-- GUI + Status + Select Weapon + AutoFarm (LOCAL-SIM) placeholders
-- IMPORTANT: This script intentionally DOES NOT call server Remotes or perform automated server-side attacks.
-- Use placeholders if you understand the server-side consequences and are responsible for your actions.

-- Anti afk (best-effort)
pcall(function()
    for _, conn in pairs(getconnections and getconnections(game.Players.LocalPlayer.Idled) or {}) do
        pcall(function() conn:Disable() end)
    end
end)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local VirtualInput = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- State
local StartTime = tick()
getgenv().SelectedWeapon = "None"    -- "Melee" or "Sword"
getgenv().AutoFarmEnabled = false
getgenv().FastAttack = false
getgenv().AutoCollectFruit = false

-- Helper safe-print
local function info(fmt, ...)
    local s = string.format(fmt, ...)
    if typeof(s) == "string" then
        pcall(function() print("[SangHub] "..s) end)
    end
end

-- -------------------------
-- UI Construction
-- -------------------------
local function createGui()
    -- ensure single gui
    if game.CoreGui:FindFirstChild("SangHub_UI") then
        game.CoreGui.SangHub_UI:Destroy()
        task.wait(0.05)
    end

    local Gui = Instance.new("ScreenGui")
    Gui.Name = "SangHub_UI"
    Gui.ResetOnSpawn = false
    Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    Gui.Parent = game.CoreGui

    -- Toggle button (square rounded with logo)
    local ToggleBtn = Instance.new("ImageButton", Gui)
    ToggleBtn.Name = "ToggleBtn"
    ToggleBtn.Size = UDim2.new(0, 46, 0, 46)
    ToggleBtn.Position = UDim2.new(0, 12, 0, 12)
    ToggleBtn.Image = "rbxassetid://76955883171909" -- your logo id
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(28,28,28)
    ToggleBtn.AutoButtonColor = true
    Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0,10)

    -- MainFrame
    local Main = Instance.new("Frame", Gui)
    Main.Name = "MainFrame"
    Main.Size = UDim2.new(0,640,0,420)
    Main.Position = UDim2.new(0.5, -320, 0.5, -210)
    Main.BackgroundColor3 = Color3.fromRGB(18,18,18)
    Main.Visible = false
    Main.Active = true
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0,12)

    local Logo = Instance.new("ImageLabel", Main)
    Logo.Name = "Logo"
    Logo.Size = UDim2.new(0,34,0,34)
    Logo.Position = UDim2.new(0, 12, 0, 8)
    Logo.BackgroundTransparency = 1
    Logo.Image = "rbxassetid://76955883171909"

    -- Tab strip (scrollable)
    local TabScroll = Instance.new("ScrollingFrame", Main)
    TabScroll.Name = "TabScroll"
    TabScroll.Size = UDim2.new(1, -60, 0, 44)
    TabScroll.Position = UDim2.new(0,56,0,8)
    TabScroll.BackgroundTransparency = 1
    TabScroll.ScrollBarThickness = 6
    TabScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
    local tabLayout = Instance.new("UIListLayout", TabScroll)
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0,8)

    local ContentHolder = Instance.new("Frame", Main)
    ContentHolder.Name = "ContentHolder"
    ContentHolder.Size = UDim2.new(1,-20,1,-70)
    ContentHolder.Position = UDim2.new(0,10,0,60)
    ContentHolder.BackgroundTransparency = 1

    local TabNames = {"Status","General","Quest & Item","Race & Gear","Shop","Setting","Mic"}
    local TabFrames = {}

    for i, name in ipairs(TabNames) do
        local btn = Instance.new("TextButton", TabScroll)
        btn.Size = UDim2.new(0,110,1,0)
        btn.Text = name
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.BackgroundColor3 = Color3.fromRGB(44,44,44)
        btn.TextColor3 = Color3.fromRGB(240,240,240)
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)

        local frame = Instance.new("Frame", ContentHolder)
        frame.Size = UDim2.new(1,0,1,0)
        frame.BackgroundTransparency = 1
        frame.Visible = false

        TabFrames[name] = frame

        btn.MouseButton1Click:Connect(function()
            -- don't hide mainframe on tab clicks
            for _,f in pairs(TabFrames) do f.Visible = false end
            frame.Visible = true
        end)
    end

    TabFrames["Status"].Visible = true

    -- Toggle animation (scale)
    local openTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local closeTweenInfo = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    local scaled = false
    ToggleBtn.MouseButton1Click:Connect(function()
        scaled = not scaled
        if scaled then
            Main.Size = UDim2.new(0,1,0,1) -- start tiny
            Main.Visible = true
            local t = TweenService:Create(Main, openTweenInfo, {Size = UDim2.new(0,640,0,420)})
            t:Play()
        else
            local t = TweenService:Create(Main, closeTweenInfo, {Size = UDim2.new(0,1,0,1)})
            t:Play()
            t.Completed:Wait()
            Main.Visible = false
            Main.Size = UDim2.new(0,640,0,420)
        end
    end)

    -- return references
    return {
        Gui = Gui,
        Main = Main,
        TabFrames = TabFrames,
        ToggleBtn = ToggleBtn,
        Logo = Logo
    }
end

local UI = createGui()
local TabFrames = UI.TabFrames

-- -------------------------
-- STATUS TAB: boss, fruit, uptime, moon, players
-- -------------------------
do
    local Status = TabFrames["Status"]
    local Title = Instance.new("TextLabel", Status)
    Title.Size = UDim2.new(1,0,0,40)
    Title.Position = UDim2.new(0,0,0,0)
    Title.BackgroundTransparency = 1
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 20
    Title.TextColor3 = Color3.fromRGB(255,255,255)
    Title.Text = "Status Checking"
    Title.TextXAlignment = Enum.TextXAlignment.Center

    local left = Instance.new("ScrollingFrame", Status)
    left.Size = UDim2.new(0.5, -10, 1, -50)
    left.Position = UDim2.new(0,5,0,45)
    left.BackgroundTransparency = 1
    left.ScrollBarThickness = 6
    local leftLayout = Instance.new("UIListLayout", left); leftLayout.Padding = UDim.new(0,8)

    local right = Instance.new("ScrollingFrame", Status)
    right.Size = UDim2.new(0.5, -10, 1, -50)
    right.Position = UDim2.new(0.5,5,0,45)
    right.BackgroundTransparency = 1
    right.ScrollBarThickness = 6
    local rightLayout = Instance.new("UIListLayout", right); rightLayout.Padding = UDim.new(0,8)

    local function makeLine(parent, labelText)
        local fr = Instance.new("Frame", parent)
        fr.Size = UDim2.new(1,-12,0,28); fr.BackgroundTransparency = 1
        local lbl = Instance.new("TextLabel", fr)
        lbl.Size = UDim2.new(0.7,0,1,0); lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.Gotham; lbl.TextSize = 14; lbl.TextColor3 = Color3.fromRGB(220,220,220)
        lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = labelText
        local stat = Instance.new("TextLabel", fr)
        stat.Size = UDim2.new(0.3,-6,1,0); stat.Position = UDim2.new(0.7,6,0,0)
        stat.BackgroundTransparency = 1; stat.Font = Enum.Font.GothamBold; stat.TextSize = 14
        stat.TextXAlignment = Enum.TextXAlignment.Right; stat.TextColor3 = Color3.fromRGB(200,200,200)
        return lbl, stat
    end

    local shankLbl, shankStat = makeLine(left, "Shank tóc đỏ:")
    local wbLbl, wbStat = makeLine(left, "Râu trắng:")
    local sawLbl, sawStat = makeLine(left, "The Saw:")

    local playersLbl, playersStat = makeLine(right, "Players in server:")
    local fruitLbl, fruitStat = makeLine(right, "FRUIT SPAWN / DROP:")
    local upLbl, upStat = makeLine(right, "Script uptime:")
    local moonLbl, moonStat = makeLine(right, "Moon:")

    local function detectBosses()
        -- best-effort local detection: search names in workspace descendants
        local foundShank, foundWhite, foundSaw = false,false,false
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("Model") or v:IsA("Folder") then
                local n = v.Name:lower()
                if n:find("shank") or n:find("shank tóc") then foundShank = true end
                if n:find("whitebeard") or n:find("râu trắng") or n:find("white beard") then foundWhite = true end
                if n:find("saw") or n:find("the saw") then foundSaw = true end
            end
        end
        shankStat.Text = foundShank and "✅" or "❌"
        wbStat.Text = foundWhite and "✅" or "❌"
        sawStat.Text = foundSaw and "✅" or "❌"
    end

    local function detectFruits()
        local fruitNames = {}
        for _, obj in pairs(workspace:GetChildren()) do
            if obj:IsA("Tool") and obj:FindFirstChild("Handle") and string.match(obj.Name:lower(),"fruit") then
                table.insert(fruitNames, obj.Name)
            end
        end
        if #fruitNames > 0 then fruitStat.Text = table.concat(fruitNames, ", ") else fruitStat.Text = "❌" end
    end

    local function detectMoon()
        local moonObj = workspace:FindFirstChild("Moon") or ReplicatedStorage:FindFirstChild("Moon")
        if moonObj and moonObj.Name:lower():find("real") then
            moonStat.Text = "Real 🌘🌗🌖🌕"
        elseif moonObj and moonObj.Name:lower():find("fake") then
            moonStat.Text = "Fake 🌒🌓🌖🌑"
        else
            moonStat.Text = "Unknown"
        end
    end

    spawn(function()
        while task.wait(1) do
            pcall(function()
                playersStat.Text = tostring(#Players:GetPlayers())
                upStat.Text = (function()
                    local elapsed = math.floor(tick()-StartTime)
                    local h = math.floor(elapsed/3600)
                    local m = math.floor((elapsed%3600)/60)
                    local s = elapsed%60
                    return string.format("%02d:%02d:%02d", h, m, s)
                end)()
            end)
        end
    end)

    -- heavier checks every 120s
    spawn(function()
        while task.wait(2) do
            pcall(function()
                detectBosses()
                detectFruits()
                detectMoon()
            end)
        end
    end)
end

-- -------------------------
-- GENERAL TAB: Left = AutoFarm controls, Right = Setting (Select Weapon + Time)
-- -------------------------
do
    local General = TabFrames["General"]

    -- Left Panel: Auto Farm controls
    local LeftPanel = Instance.new("Frame", General)
    LeftPanel.Size = UDim2.new(0.5,-10,1,0)
    LeftPanel.Position = UDim2.new(0,0,0,0)
    LeftPanel.BackgroundTransparency = 1

    local LeftScroll = Instance.new("ScrollingFrame", LeftPanel)
    LeftScroll.Size = UDim2.new(1,1,1,0)
    LeftScroll.BackgroundTransparency = 1
    LeftScroll.ScrollBarThickness = 6
    local leftList = Instance.new("UIListLayout", LeftScroll); leftList.Padding = UDim.new(0,8)

    local function leftTitle(txt)
        local t = Instance.new("TextLabel", LeftScroll)
        t.Size = UDim2.new(1,-12,0,26); t.BackgroundTransparency = 1
        t.Font = Enum.Font.GothamBold; t.TextSize = 16; t.TextColor3 = Color3.fromRGB(230,230,230)
        t.Text = txt; t.TextXAlignment = Enum.TextXAlignment.Left
        return t
    end

    leftTitle(LeftScroll, "Auto Farm")

    -- Level Farm rectangle with toggle circle (as requested)
    local levelFrame = Instance.new("Frame", LeftScroll)
    levelFrame.Size = UDim2.new(1,-12,0,70); levelFrame.BackgroundTransparency = 1
    local lvlLabel = Instance.new("TextLabel", levelFrame)
    lvlLabel.Size = UDim2.new(0.7,0,0,40); lvlLabel.Position = UDim2.new(0,0,0,6)
    lvlLabel.BackgroundTransparency = 1; lvlLabel.Font = Enum.Font.Gotham; lvlLabel.TextSize = 18
    lvlLabel.Text = "Level Farm"; lvlLabel.TextColor3 = Color3.fromRGB(245,245,245); lvlLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- Circle toggle
    local circle = Instance.new("ImageLabel", levelFrame)
    circle.Size = UDim2.new(0,36,0,36); circle.Position = UDim2.new(0.78,0,0.1,0)
    circle.BackgroundTransparency = 1; circle.Image = "rbxassetid://6031094664" -- empty circle
    Instance.new("UICorner", circle).CornerRadius = UDim.new(0,18)

    local lvlToggleBtn = Instance.new("TextButton", levelFrame)
    lvlToggleBtn.Size = UDim2.new(0.2,-8,0.9,0); lvlToggleBtn.Position = UDim2.new(0.78,0,0.05,0)
    lvlToggleBtn.BackgroundTransparency = 1; lvlToggleBtn.Text = ""; lvlToggleBtn.AutoButtonColor = true

    local levelState = false
    lvlToggleBtn.MouseButton1Click:Connect(function()
        levelState = not levelState
        circle.Image = levelState and "rbxassetid://6031094690" or "rbxassetid://6031094664"
        getgenv().AutoFarmEnabled = levelState
        info("AutoFarmEnabled = %s", tostring(levelState))
        -- start/stop farm loop handled below (safe local sim)
    end)

    -- fast attack toggle
    local fastFrame = Instance.new("Frame", LeftScroll)
    fastFrame.Size = UDim2.new(1,-12,0,48); fastFrame.BackgroundTransparency = 1
    local fastLbl = Instance.new("TextLabel", fastFrame)
    fastLbl.Size = UDim2.new(0.75,0,1,0); fastLbl.BackgroundTransparency = 1
    fastLbl.Text = "Fast Attack (client-sim)"; fastLbl.Font = Enum.Font.Gotham; fastLbl.TextSize = 14
    fastLbl.TextColor3 = Color3.fromRGB(230,230,230); fastLbl.TextXAlignment = Enum.TextXAlignment.Left

    local fastToggle = Instance.new("TextButton", fastFrame)
    fastToggle.Size = UDim2.new(0.22, -6, 0.9, 0); fastToggle.Position = UDim2.new(0.78,0,0.05,0)
    fastToggle.BackgroundTransparency = 1; fastToggle.Text = "Off"
    fastToggle.MouseButton1Click:Connect(function()
        getgenv().FastAttack = not getgenv().FastAttack
        fastToggle.Text = getgenv().FastAttack and "On" or "Off"
    end)

    -- Right Panel: Settings (Select Weapon + uptime)
    local RightPanel = Instance.new("Frame", General)
    RightPanel.Size = UDim2.new(0.5,-10,1,0); RightPanel.Position = UDim2.new(0.5,10,0,0); RightPanel.BackgroundTransparency = 1

    local RightScroll = Instance.new("ScrollingFrame", RightPanel)
    RightScroll.Size = UDim2.new(1,1,1,0); RightScroll.BackgroundTransparency = 1
    RightScroll.ScrollBarThickness = 6
    local rightList = Instance.new("UIListLayout", RightScroll); rightList.Padding = UDim.new(0,8)

    local settingTitle = Instance.new("TextLabel", RightScroll)
    settingTitle.Size = UDim2.new(1,-12,0,26); settingTitle.BackgroundTransparency = 1
    settingTitle.Font = Enum.Font.GothamBold; settingTitle.TextSize = 16
    settingTitle.Text = "Setting Farming"; settingTitle.TextColor3 = Color3.fromRGB(230,230,230)

    -- Select weapon display
    local selLabel = Instance.new("TextLabel", RightScroll)
    selLabel.Size = UDim2.new(1,-12,0,30); selLabel.BackgroundTransparency = 1
    selLabel.Text = "Select Weapon: Nothing"; selLabel.Font = Enum.Font.Gotham; selLabel.TextSize = 14
    selLabel.TextColor3 = Color3.fromRGB(220,220,220); selLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- select weapon area (slide buttons)
    local selFrame = Instance.new("Frame", RightScroll)
    selFrame.Size = UDim2.new(1,-12,0,52); selFrame.BackgroundTransparency = 1
    local selButtons = Instance.new("Frame", selFrame)
    selButtons.Size = UDim2.new(1,0,1,0)
    selButtons.BackgroundTransparency = 1

    local meleeBtn = Instance.new("TextButton", selButtons)
    meleeBtn.Size = UDim2.new(0.48,-6,1,0); meleeBtn.Position = UDim2.new(0,0,0,0)
    meleeBtn.Text = "Melee 🥋"; meleeBtn.Font = Enum.Font.GothamBold; meleeBtn.TextSize = 14
    meleeBtn.BackgroundColor3 = Color3.fromRGB(30,30,30); meleeBtn.TextColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", meleeBtn).CornerRadius = UDim.new(0,6)

    local swordBtn = Instance.new("TextButton", selButtons)
    swordBtn.Size = UDim2.new(0.48,-6,1,0); swordBtn.Position = UDim2.new(0.52,0,0,0)
    swordBtn.Text = "Sword ⚔️"; swordBtn.Font = Enum.Font.GothamBold; swordBtn.TextSize = 14
    swordBtn.BackgroundColor3 = Color3.fromRGB(30,30,30); swordBtn.TextColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", swordBtn).CornerRadius = UDim.new(0,6)

    meleeBtn.MouseButton1Click:Connect(function()
        getgenv().SelectedWeapon = "Melee"
        selLabel.Text = "Select Weapon: Melee"
        info("SelectedWeapon = Melee")
    end)
    swordBtn.MouseButton1Click:Connect(function()
        getgenv().SelectedWeapon = "Sword"
        selLabel.Text = "Select Weapon: Sword"
        info("SelectedWeapon = Sword")
    end)

    -- time panel (show server time / local uptime) - located under select
    local timeLabel = Instance.new("TextLabel", RightScroll)
    timeLabel.Size = UDim2.new(1,-12,0,24); timeLabel.BackgroundTransparency = 1
    timeLabel.Font = Enum.Font.Gotham; timeLabel.TextSize = 13; timeLabel.TextColor3 = Color3.fromRGB(200,200,200)
    timeLabel.TextXAlignment = Enum.TextXAlignment.Left

    spawn(function()
        while task.wait(1) do
            pcall(function()
                local elapsed = math.floor(tick() - StartTime)
                local h = math.floor(elapsed/3600); local m = math.floor((elapsed%3600)/60); local s = elapsed%60
                timeLabel.Text = "Time: " .. string.format("%02d:%02d:%02d", h, m, s)
            end)
        end
    end)
end

-- -------------------------
-- SAFE LOCAL-SIM "AutoFarm" loop (does NOT call server)
-- -------------------------
-- Purpose: show how an AutoFarm loop could behave in local sandbox.
-- It looks for test mobs in workspace.SangHub_TestMobs (you can spawn models there to test).
-- THIS LOOP WILL NEVER INVOKE ANY RemoteEvent OR RemoteFunction.

do
    local function findTestMobByName(prefix)
        local folder = workspace:FindFirstChild("SangHub_TestMobs")
        if not folder then return nil end
        local closest, dist = nil, math.huge
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return nil end
        for _, m in pairs(folder:GetChildren()) do
            if m and m:FindFirstChild("HumanoidRootPart") and m:IsA("Model") and string.find(m.Name, prefix) then
                local d = (m.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if d < dist then dist = d; closest = m end
            end
        end
        return closest
    end

    local function safeEquipSelected()
        -- equip a tool from backpack matching selection (client-only equip)
        if not LocalPlayer.Character then return end
        if getgenv().SelectedWeapon == "None" then return end
        for _, item in pairs(LocalPlayer.Backpack:GetChildren()) do
            if item:IsA("Tool") then
                local name = item.Name:lower()
                if getgenv().SelectedWeapon == "Melee" then
                    if item.ToolTip == "Melee" or name:match("combat") or name:match("karate") or name:match("melee") or name:match("death") then
                        pcall(function() LocalPlayer.Character.Humanoid:EquipTool(item) end)
                        return
                    end
                elseif getgenv().SelectedWeapon == "Sword" then
                    if item.ToolTip == "Sword" or name:match("katana") or name:match("sword") or name:match("blade") then
                        pcall(function() LocalPlayer.Character.Humanoid:EquipTool(item) end)
                        return
                    end
                end
            end
        end
    end

    local function simulateAttackOn(mob)
        -- local simulation: reduce a NumberValue "TestHealth" under mob if exists
        if not mob then return end
        local healthObj = mob:FindFirstChild("TestHealth")
        if healthObj and healthObj:IsA("NumberValue") then
            healthObj.Value = math.max(0, healthObj.Value - (getgenv().FastAttack and 10 or 2))
            info("Simulated hit %s -> health %d", mob.Name, healthObj.Value)
            if healthObj.Value <= 0 then
                info("Mob %s died (simulated)", mob.Name)
            end
        else
            -- if no TestHealth, just print a message
            info("Simulated hit on %s (no TestHealth present)", mob.Name)
        end
    end

    spawn(function()
        while task.wait(0.6) do
            if getgenv().AutoFarmEnabled then
                pcall(function()
                    -- pick best mob prefix based on level (you can implement your own mapping)
                    local myLevel = (pcall(function() return LocalPlayer.Data.Level.Value end) and LocalPlayer.Data.Level.Value) or 1
                    -- simple heuristic: use "Bandit" prefix for demonstration
                    local prefix = "Bandit"
                    -- find nearest test mob in SangHub_TestMobs
                    local mob = findTestMobByName(prefix)
                    if mob then
                        -- create floating platform under player (local)
                        if not workspace:FindFirstChild("SangHub_FloatBlock") then
                            local p = Instance.new("Part", workspace)
                            p.Name = "SangHub_FloatBlock"
                            p.Anchored = true
                            p.CanCollide = true
                            p.Size = Vector3.new(8,1,8)
                            p.Transparency = 1
                            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                p.Position = LocalPlayer.Character.HumanoidRootPart.Position - Vector3.new(0,3.5,0)
                            end
                        end

                        -- auto-equip locally
                        safeEquipSelected()

                        -- move player above mob (local)
                        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("HumanoidRootPart") then
                            local targetCFrame = mob.HumanoidRootPart.CFrame * CFrame.new(0, 6, 0)
                            pcall(function() LocalPlayer.Character.HumanoidRootPart.CFrame = targetCFrame end)
                        end

                        -- simulate attack (no server calls)
                        simulateAttackOn(mob)
                    else
                        -- no mob found in test folder
                        info("No local test mob found (SangHub_TestMobs/%s)", tostring(prefix))
                    end
                end)
            else
                -- if auto disabled, remove float block local
                if workspace:FindFirstChild("SangHub_FloatBlock") then
                    pcall(function() workspace.SangHub_FloatBlock:Destroy() end)
                end
            end
        end
    end)
end

-- -------------------------
-- NOTES / Placeholders (DO NOT UNCOMMENT unless you understand server consequences)
-- -------------------------
--[[ Example placeholders (kept commented on purpose):
    -- 1) Starting a quest on server (NOT PROVIDED):
    -- ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", questName, 1)

    -- 2) Teleport / requestEntrance (NOT PROVIDED):
    -- ReplicatedStorage.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(...))

    -- 3) Triggering server-side attack or validation (NOT PROVIDED):
    -- ReplicatedStorage.Remotes.SomeRemote:FireServer(...)

    Adding the above calls automates real server interactions and is against the "safe-by-default" rules of this helper. 
    If you understand and accept responsibility, you can add server calls in these commented places — but I won't generate them for you.
--]]

info("SangHub UI (safe) loaded. Toggle the UI with the top-left button.")
-- SangHub SAFE UI (raw .lua)
-- GUI with tabs, status read-only, select-weapon local, toggle, animations.
-- IMPORTANT: This file purposely DOES NOT include any auto-farm actions that call server remotes or auto-clicks.

-- == Services & globals ==
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local StartTime = os.time()

-- safe state (local only)
getgenv().SangHub = getgenv().SangHub or {}
local State = getgenv().SangHub
State.GuiVisible = false
State.SelectedWeapon = "Nothing" -- "Melee" or "Sword" or "Nothing"
State.AutoFarmVisual = false -- visual toggle only (no server actions)

-- === Helper utilities ===
local function createUICorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = parent
	return c
end

local function formatTimeSince(t)
	local s = os.time() - t
	local hrs = math.floor(s/3600); local mins = math.floor((s%3600)/60); local secs = s%60
	return string.format("%02d:%02d:%02d", hrs, mins, secs)
end

-- === Root GUI ===
local gui = Instance.new("ScreenGui")
gui.Name = "BloxFruit_TabGUI_Safe"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = game.CoreGui

-- Toggle button (top-left)
local ToggleBtn = Instance.new("ImageButton", gui)
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Size = UDim2.new(0, 44, 0, 44)
ToggleBtn.Position = UDim2.new(0, 12, 0, 12)
ToggleBtn.Image = "rbxassetid://76955883171909" -- your logo id
ToggleBtn.BackgroundColor3 = Color3.fromRGB(25,25,25)
ToggleBtn.AutoButtonColor = true
createUICorner(ToggleBtn, 10)

-- Main frame (center)
local MainFrame = Instance.new("Frame", gui)
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 640, 0, 420)
MainFrame.Position = UDim2.new(0.5, -320, 0.5, -210)
MainFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
MainFrame.Visible = false
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
createUICorner(MainFrame, 12)

-- Logo top-left inside frame
local Logo = Instance.new("ImageLabel", MainFrame)
Logo.Name = "Logo"
Logo.Size = UDim2.new(0, 34, 0, 34)
Logo.Position = UDim2.new(0, 12, 0, 8)
Logo.BackgroundTransparency = 1
Logo.Image = "rbxassetid://76955883171909"

-- Tab scroll
local TabScroll = Instance.new("ScrollingFrame", MainFrame)
TabScroll.Name = "TabScroll"
TabScroll.Size = UDim2.new(1, -80, 0, 44)
TabScroll.Position = UDim2.new(0, 56, 0, 8)
TabScroll.BackgroundTransparency = 1
TabScroll.ScrollBarThickness = 6
TabScroll.AutomaticCanvasSize = Enum.AutomaticSize.X

local TabLayout = Instance.new("UIListLayout", TabScroll)
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.Padding = UDim.new(0,6)

-- Content holder
local ContentHolder = Instance.new("Frame", MainFrame)
ContentHolder.Name = "ContentHolder"
ContentHolder.Size = UDim2.new(1, -20, 1, -70)
ContentHolder.Position = UDim2.new(0, 10, 0, 60)
ContentHolder.BackgroundTransparency = 1

-- Tabs list
local TabNames = {"Status","General","Quest & Item","Race & Gear","Shop","Setting","Mic"}
local TabFrames = {}

for i, name in ipairs(TabNames) do
	local btn = Instance.new("TextButton", TabScroll)
	btn.Name = "TabBtn_"..name
	btn.Size = UDim2.new(0, 110, 1, 0)
	btn.Text = name
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 13
	btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
	btn.TextColor3 = Color3.fromRGB(255,255,255)
	createUICorner(btn, 8)

	local frame = Instance.new("Frame", ContentHolder)
	frame.Name = "Frame_"..name
	frame.Size = UDim2.new(1,0,1,0)
	frame.BackgroundTransparency = 1
	frame.Visible = false

	TabFrames[name] = frame

	btn.MouseButton1Click:Connect(function()
		for k,f in pairs(TabFrames) do f.Visible = false end
		frame.Visible = true
	end)
end

TabFrames["Status"].Visible = true

-- === STATUS TAB ===
local StatusTab = TabFrames["Status"]
-- Title centered
local StatusTitle = Instance.new("TextLabel", StatusTab)
StatusTitle.Size = UDim2.new(1,0,0,40)
StatusTitle.Position = UDim2.new(0,0,0,0)
StatusTitle.BackgroundTransparency = 1
StatusTitle.Font = Enum.Font.GothamBold
StatusTitle.TextSize = 20
StatusTitle.TextColor3 = Color3.fromRGB(255,255,255)
StatusTitle.Text = "Status Checking"
StatusTitle.TextXAlignment = Enum.TextXAlignment.Center

-- Two columns (left/right) with scrolls
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

local function makeLine(parent, labelText)
	local f = Instance.new("Frame", parent)
	f.Size = UDim2.new(1, -10, 0, 28)
	f.BackgroundTransparency = 1
	local lbl = Instance.new("TextLabel", f)
	lbl.Size = UDim2.new(0.7, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = labelText
	lbl.Font = Enum.Font.Gotham
	lbl.TextColor3 = Color3.fromRGB(220,220,220)
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	local stat = Instance.new("TextLabel", f)
	stat.Size = UDim2.new(0.3, -6, 1, 0)
	stat.Position = UDim2.new(0.7, 6, 0, 0)
	stat.BackgroundTransparency = 1
	stat.Font = Enum.Font.GothamBold
	stat.TextColor3 = Color3.fromRGB(200,200,200)
	stat.TextXAlignment = Enum.TextXAlignment.Right
	return lbl, stat
end

local shankLbl, shankStat = makeLine(left, "Shank tóc đỏ:")
local whiteLbl, whiteStat = makeLine(left, "Râu trắng:")
local sawLbl, sawStat = makeLine(left, "The Saw:")

local playersLbl, playersStat = makeLine(right, "Players in server:")
local fruitLbl, fruitStat = makeLine(right, "FRUIT SPAWN / DROP:")
local uptimeLbl, uptimeStat = makeLine(right, "Script uptime:")
local moonLbl, moonStat = makeLine(right, "Moon:")

-- updater: read-only checks (no remote calls)
local function updateStatus()
	-- players count
	local pcount = #Players:GetPlayers()
	playersStat.Text = tostring(pcount)

	-- boss detection - look for model names in workspace (best-effort)
	local foundShank, foundWhite, foundSaw = false,false,false
	for _,v in pairs(Workspace:GetDescendants()) do
		if v:IsA("Model") or v:IsA("Folder") then
			local n = v.Name:lower()
			if n:find("shank") then foundShank = true end
			if n:find("whitebeard") or n:find("râu trắng") or n:find("white") then foundWhite = true end
			if n:find("saw") then foundSaw = true end
		end
	end
	shankStat.Text = foundShank and "✅" or "❌"
	whiteStat.Text = foundWhite and "✅" or "❌"
	sawStat.Text = foundSaw and "✅" or "❌"

	-- fruit detection (tools named fruit in workspace)
	local fruitNames = {}
	for _,obj in pairs(Workspace:GetChildren()) do
		if obj:IsA("Tool") and obj:FindFirstChild("Handle") and string.find(obj.Name:lower(), "fruit") then
			table.insert(fruitNames, obj.Name)
		end
	end
	fruitStat.Text = #fruitNames>0 and table.concat(fruitNames, ", ") or "❌"

	-- uptime
	uptimeStat.Text = formatTimeSince(StartTime)

	-- moon detection (best-effort: checks Workspace or ReplicatedStorage object named "Moon")
	local moonObj = Workspace:FindFirstChild("Moon") or game:GetService("ReplicatedStorage"):FindFirstChild("Moon")
	if moonObj then
		local name = moonObj.Name:lower()
		if name:find("real") then moonStat.Text = "Real 🌘🌗🌖🌕" 
		elseif name:find("fake") then moonStat.Text = "Fake 🌒🌓🌖🌑"
		else moonStat.Text = moonObj.Name
		end
	else
		moonStat.Text = "Unknown"
	end
end

-- run updater
spawn(function()
	while true do
		pcall(updateStatus)
		wait(2) -- boss check every 2s (you asked 2min reset earlier; this updates frequently; adjust as needed)
	end
end)

-- === GENERAL TAB ===
local GeneralTab = TabFrames["General"]

-- Left panel = Auto Farm (visual toggle)
local LeftPanel = Instance.new("Frame", GeneralTab)
LeftPanel.Size = UDim2.new(0.5, -10, 1, 0)
LeftPanel.Position = UDim2.new(0, 0, 0, 0)
LeftPanel.BackgroundTransparency = 1

local LeftScroll = Instance.new("ScrollingFrame", LeftPanel)
LeftScroll.Size = UDim2.new(1,1,1,0)
LeftScroll.CanvasSize = UDim2.new(0,0,0,200)
LeftScroll.ScrollBarThickness = 6
LeftScroll.BackgroundTransparency = 1
local Llayout = Instance.new("UIListLayout", LeftScroll); Llayout.Padding = UDim.new(0,8)

local function simpleTitle(parent, text)
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

simpleTitle(LeftScroll, "Auto Farm")

-- Level farm rectangle with circle toggle
local levelFrame = Instance.new("Frame", LeftScroll)
levelFrame.Size = UDim2.new(1, -12, 0, 80)
levelFrame.BackgroundTransparency = 1

local levelTitle = Instance.new("TextLabel", levelFrame)
levelTitle.Size = UDim2.new(0.6,0,0,24)
levelTitle.Position = UDim2.new(0,8,0,6)
levelTitle.BackgroundTransparency = 1
levelTitle.Text = "Level Farm"
levelTitle.Font = Enum.Font.GothamBold
levelTitle.TextSize = 16
levelTitle.TextColor3 = Color3.fromRGB(255,255,255)
levelTitle.TextXAlignment = Enum.TextXAlignment.Left

local levelTimeLabel = Instance.new("TextLabel", levelFrame)
levelTimeLabel.Size = UDim2.new(0.9,0,0,18)
levelTimeLabel.Position = UDim2.new(0,8,0,34)
levelTimeLabel.BackgroundTransparency = 1
levelTimeLabel.Text = "Uptime: 00:00:00"
levelTimeLabel.Font = Enum.Font.Gotham
levelTimeLabel.TextSize = 12
levelTimeLabel.TextColor3 = Color3.fromRGB(200,200,200)
levelTimeLabel.TextXAlignment = Enum.TextXAlignment.Left

local circleImg = Instance.new("ImageLabel", levelFrame)
circleImg.Size = UDim2.new(0,34,0,34)
circleImg.Position = UDim2.new(0.78,0,0.12,0)
circleImg.BackgroundTransparency = 1
circleImg.Image = "rbxassetid://6031094664"

local lvlToggleBtn = Instance.new("TextButton", levelFrame)
lvlToggleBtn.Size = UDim2.new(0.2, -8, 0.9, 0)
lvlToggleBtn.Position = UDim2.new(0.78, 0, 0.05, 0)
lvlToggleBtn.BackgroundTransparency = 1
lvlToggleBtn.AutoButtonColor = true
lvlToggleBtn.Text = ""

local levelOn = false
lvlToggleBtn.MouseButton1Click:Connect(function()
	levelOn = not levelOn
	circleImg.Image = levelOn and "rbxassetid://6031094690" or "rbxassetid://6031094664"
	State.AutoFarmVisual = levelOn
	-- NOTE: This only toggles local visual/state. No server actions here.
end)

-- update uptime label every second
spawn(function()
	while wait(1) do
		levelTimeLabel.Text = "Uptime: "..formatTimeSince(StartTime)
	end
end)

-- Right panel = Setting Farming (select weapon + fast attack visual)
local RightPanel = Instance.new("Frame", GeneralTab)
RightPanel.Size = UDim2.new(0.5, -10, 1, 0)
RightPanel.Position = UDim2.new(0.5, 10, 0, 0)
RightPanel.BackgroundTransparency = 1

local RightScroll = Instance.new("ScrollingFrame", RightPanel)
RightScroll.Size = UDim2.new(1,1,1,0)
RightScroll.CanvasSize = UDim2.new(0,0,0,200)
RightScroll.ScrollBarThickness = 6
RightScroll.BackgroundTransparency = 1
local Rlayout = Instance.new("UIListLayout", RightScroll); Rlayout.Padding = UDim.new(0,8)

simpleTitle(RightScroll, "Setting Farming")

-- Select weapon display
local selFrame = Instance.new("Frame", RightScroll)
selFrame.Size = UDim2.new(1, -12, 0, 90)
selFrame.BackgroundTransparency = 1

local selLabel = Instance.new("TextLabel", selFrame)
selLabel.Size = UDim2.new(1, 0, 0, 24)
selLabel.Position = UDim2.new(0, 0, 0, 0)
selLabel.BackgroundTransparency = 1
selLabel.Text = "Select Weapon: "..State.SelectedWeapon
selLabel.Font = Enum.Font.Gotham
selLabel.TextSize = 14
selLabel.TextColor3 = Color3.fromRGB(255,255,255)
selLabel.TextXAlignment = Enum.TextXAlignment.Left

local selButtons = Instance.new("Frame", selFrame)
selButtons.Size = UDim2.new(1,0,0,44)
selButtons.Position = UDim2.new(0,0,0,30)
selButtons.BackgroundTransparency = 1

-- buttons: Melee / Sword (left-right)
local meleeBtn = Instance.new("TextButton", selButtons)
meleeBtn.Size = UDim2.new(0.48, -6, 1, 0)
meleeBtn.Position = UDim2.new(0,0,0,0)
meleeBtn.Text = "Melee 🥋"
meleeBtn.Font = Enum.Font.GothamBold
meleeBtn.TextSize = 14
meleeBtn.BackgroundColor3 = Color3.fromRGB(28,28,28)
meleeBtn.TextColor3 = Color3.new(1,1,1)
createUICorner(meleeBtn, 6)

local swordBtn = Instance.new("TextButton", selButtons)
swordBtn.Size = UDim2.new(0.48, -6, 1, 0)
swordBtn.Position = UDim2.new(0.52, 0, 0, 0)
swordBtn.Text = "Sword ⚔️"
swordBtn.Font = Enum.Font.GothamBold
swordBtn.TextSize = 14
swordBtn.BackgroundColor3 = Color3.fromRGB(28,28,28)
swordBtn.TextColor3 = Color3.new(1,1,1)
createUICorner(swordBtn, 6)

local function setSelectedWeapon(name)
	State.SelectedWeapon = name
	selLabel.Text = "Select Weapon: "..name
end

meleeBtn.MouseButton1Click:Connect(function()
	setSelectedWeapon("Melee")
	-- local auto-equip attempt (client-side only; will equip tool from backpack if available)
	pcall(function()
		for _,it in pairs(LocalPlayer.Backpack:GetChildren()) do
			if it:IsA("Tool") and (it.ToolTip == "Melee" or string.find(it.Name:lower(),"combat") or string.find(it.Name:lower(),"karate")) then
				LocalPlayer.Character.Humanoid:EquipTool(it)
				break
			end
		end
	end)
end)

swordBtn.MouseButton1Click:Connect(function()
	setSelectedWeapon("Sword")
	pcall(function()
		for _,it in pairs(LocalPlayer.Backpack:GetChildren()) do
			if it:IsA("Tool") and (it.ToolTip == "Sword" or string.find(it.Name:lower(),"sword") or string.find(it.Name:lower(),"katana") or string.find(it.Name:lower(),"blade")) then
				LocalPlayer.Character.Humanoid:EquipTool(it)
				break
			end
		end
	end)
end)

-- Fast attack visual toggle (local only)
local fastFrame = Instance.new("Frame", RightScroll)
fastFrame.Size = UDim2.new(1, -12, 0, 48)
fastFrame.BackgroundTransparency = 1
local fastLabel = Instance.new("TextLabel", fastFrame)
fastLabel.Size = UDim2.new(0.7,0,1,0)
fastLabel.BackgroundTransparency = 1
fastLabel.Text = "Fast Attack (visual)"
fastLabel.Font = Enum.Font.Gotham
fastLabel.TextSize = 14
fastLabel.TextColor3 = Color3.fromRGB(255,255,255)
fastLabel.TextXAlignment = Enum.TextXAlignment.Left

local fastCircle = Instance.new("ImageLabel", fastFrame)
fastCircle.Size = UDim2.new(0,34,0,34)
fastCircle.Position = UDim2.new(0.78,0,0.12,0)
fastCircle.BackgroundTransparency = 1
fastCircle.Image = "rbxassetid://6031094664"
createUICorner(fastCircle, 18)

local fastToggleBtn = Instance.new("TextButton", fastFrame)
fastToggleBtn.Size = UDim2.new(0.2, -8, 0.9, 0)
fastToggleBtn.Position = UDim2.new(0.78, 0, 0.05, 0)
fastToggleBtn.BackgroundTransparency = 1
fastToggleBtn.AutoButtonColor = true
fastToggleBtn.Text = ""
local fastOn = false
fastToggleBtn.MouseButton1Click:Connect(function()
	fastOn = not fastOn
	fastCircle.Image = fastOn and "rbxassetid://6031094690" or "rbxassetid://6031094664"
	-- Visual only; no auto-clicking performed
end)

-- === Toggle behavior + animations ===
local function showMain()
	if MainFrame.Visible then return end
	MainFrame.Visible = true
	State.GuiVisible = true
	-- animation: small -> full
	MainFrame.Size = UDim2.new(0, 200, 0, 120)
	MainFrame.Position = UDim2.new(0.5, -100, 0.5, -60)
	local t1 = TweenService:Create(MainFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0,640,0,420), Position = UDim2.new(0.5, -320, 0.5, -210)})
	t1:Play()
end

local function hideMain()
	if not MainFrame.Visible then return end
	-- animation: full -> small -> hide
	local t1 = TweenService:Create(MainFrame, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0,200,0,120), Position = UDim2.new(0.5, -100, 0.5, -60)})
	t1:Play()
	t1.Completed:Wait()
	MainFrame.Visible = false
	State.GuiVisible = false
end

ToggleBtn.MouseButton1Click:Connect(function()
	if State.GuiVisible then hideMain() else showMain() end
end)

-- Close behavior: if click outside (optional)
gui.InputBegan:Connect(function(inp)
	if inp.UserInputType == Enum.UserInputType.MouseButton1 then
		-- nothing fancy here
	end
end)

-- Final note / placeholder functions (safe comments only)
-- If you later want to implement automation, do NOT paste server-calling code here unless you understand anti-cheat risks.
-- Placeholder (DO NOT implement remote calls here if you want to stay within rules):
-- function Unsafe_StartAutoFarm()
--    -- WARNING: server-invoking and auto-clicking code would be here (not provided)
-- end

print("✅ SangHub SAFE GUI (no auto-farm) loaded.")
