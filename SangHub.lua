--===[ PHẦN 1: UI + TAB CÓ TIÊU ĐỀ ]===--

-- Anti AFK
for _,v in pairs(getconnections(game.Players.LocalPlayer.Idled)) do
    pcall(function() v:Disable() end)
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Main GUI
local Gui = Instance.new("ScreenGui", game.CoreGui)
Gui.Name = "SangHub"
Gui.ResetOnSpawn = false

-- Toggle Button
local ToggleBtn = Instance.new("ImageButton", Gui)
ToggleBtn.Size = UDim2.new(0, 44, 0, 44)
ToggleBtn.Position = UDim2.new(0, 12, 0, 12)
ToggleBtn.Image = "rbxassetid://76955883171909"
ToggleBtn.BackgroundColor3 = Color3.fromRGB(25,25,25)
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0,8)

-- Main Frame
local MainFrame = Instance.new("Frame", Gui)
MainFrame.Size = UDim2.new(0, 640, 0, 420)
MainFrame.Position = UDim2.new(0.5, -320, 0.5, -210)
MainFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
MainFrame.Active = true
MainFrame.Visible = false
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0,10)

-- Tab Bar
local TabScroll = Instance.new("ScrollingFrame", MainFrame)
TabScroll.Size = UDim2.new(1, -60, 0, 44)
TabScroll.Position = UDim2.new(0, 56, 0, 8)
TabScroll.BackgroundTransparency = 1
TabScroll.ScrollBarThickness = 6
TabScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
local TabLayout = Instance.new("UIListLayout", TabScroll)
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.Padding = UDim.new(0,6)

-- Nội dung Tab
local ContentHolder = Instance.new("Frame", MainFrame)
ContentHolder.Size = UDim2.new(1, -20, 1, -70)
ContentHolder.Position = UDim2.new(0, 10, 0, 60)
ContentHolder.BackgroundTransparency = 1

-- Danh sách Tabs
local Tabs = {"Status", "General", "Quest & Item", "Race & Gear", "Shop", "Setting", "Mic"}
local TabFrames = {}

for _, name in ipairs(Tabs) do
    local btn = Instance.new("TextButton", TabScroll)
    btn.Size = UDim2.new(0, 110, 1, 0)
    btn.Text = name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)

    local frame = Instance.new("Frame", ContentHolder)
    frame.Size = UDim2.new(1,0,1,0)
    frame.BackgroundTransparency = 1
    frame.Visible = false

    -- Tiêu đề tab
    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1,0,0,30)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.Text = name .. " Tab"

    TabFrames[name] = frame

    btn.MouseButton1Click:Connect(function()
        for _,f in pairs(TabFrames) do f.Visible = false end
        frame.Visible = true
    end)
end

TabFrames["Status"].Visible = true

-- Toggle GUI Show/Hide
ToggleBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)
--===[ PHẦN 2: STATUS TAB + GENERAL TAB ]===--

-- Status Tab
local StatusTab = TabFrames["Status"]

-- Scroll cho Status Tab
local StatusScroll = Instance.new("ScrollingFrame", StatusTab)
StatusScroll.Size = UDim2.new(1, 0, 1, -30)
StatusScroll.Position = UDim2.new(0, 0, 0, 30)
StatusScroll.CanvasSize = UDim2.new(0, 0, 0, 300)
StatusScroll.ScrollBarThickness = 4
StatusScroll.BackgroundTransparency = 1

local StatusLayout = Instance.new("UIListLayout", StatusScroll)
StatusLayout.Padding = UDim.new(0, 8)

-- Status Lines
local function createStatusLine(title)
    local txt = Instance.new("TextLabel", StatusScroll)
    txt.Size = UDim2.new(1, -10, 0, 28)
    txt.BackgroundTransparency = 1
    txt.Font = Enum.Font.GothamBold
    txt.TextSize = 14
    txt.TextColor3 = Color3.fromRGB(255,255,255)
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.Text = title
    return txt
end

local BossShanks = createStatusLine("Shanks: ❌")
local BossWhitebeard = createStatusLine("Whitebeard: ❌")
local BossSaw = createStatusLine("The Saw: ❌")
local FruitStatus = createStatusLine("Fruit Spawn / Drop: ❌")
local PlayerCount = createStatusLine("Players in Server: 0")
local ServerTime = createStatusLine("Time in Server: 0s")
local MoonStatus = createStatusLine("Moon: 🌑")

-- Auto cập nhật status
task.spawn(function()
    local startTime = tick()
    while task.wait(2) do
        -- Boss Check
        local bosses = {}
        for _,v in pairs(workspace.Enemies:GetChildren()) do
            if v:FindFirstChild("Humanoid") then
                if v.Name:find("Shanks") then bosses["Shanks"] = true end
                if v.Name:find("Whitebeard") then bosses["Whitebeard"] = true end
                if v.Name:find("The Saw") then bosses["The Saw"] = true end
            end
        end
        BossShanks.Text = "Shanks: " .. (bosses["Shanks"] and "✅" or "❌")
        BossWhitebeard.Text = "Whitebeard: " .. (bosses["Whitebeard"] and "✅" or "❌")
        BossSaw.Text = "The Saw: " .. (bosses["The Saw"] and "✅" or "❌")

        -- Fruit Check
        local fruitFound = false
        for _,v in pairs(workspace:GetChildren()) do
            if v:IsA("Tool") and v:FindFirstChild("Handle") then
                fruitFound = true
                FruitStatus.Text = "Fruit Spawn / Drop: " .. v.Name
            end
        end
        if not fruitFound then
            FruitStatus.Text = "Fruit Spawn / Drop: ❌"
        end

        -- Player Count
        PlayerCount.Text = "Players in Server: " .. #Players:GetPlayers()

        -- Time
        local elapsed = math.floor(tick() - startTime)
        ServerTime.Text = string.format("Time in Server: %ds", elapsed)

        -- Moon (giả lập)
        local moonPhases = {"🌑","🌒","🌓","🌔","🌕","🌖","🌗","🌘"}
        MoonStatus.Text = "Moon: " .. moonPhases[(math.floor(elapsed/10) % #moonPhases)+1]
    end
end)

-- General Tab
local GeneralTab = TabFrames["General"]

-- Left Panel (Auto Farm)
local LeftPanel = Instance.new("ScrollingFrame", GeneralTab)
LeftPanel.Size = UDim2.new(0.5, -5, 1, -30)
LeftPanel.Position = UDim2.new(0, 0, 0, 30)
LeftPanel.CanvasSize = UDim2.new(0, 0, 0, 200)
LeftPanel.ScrollBarThickness = 4
LeftPanel.BackgroundTransparency = 1
local LeftLayout = Instance.new("UIListLayout", LeftPanel)
LeftLayout.Padding = UDim.new(0, 8)

local leftTitle = Instance.new("TextLabel", LeftPanel)
leftTitle.Size = UDim2.new(1, -10, 0, 28)
leftTitle.BackgroundTransparency = 1
leftTitle.Font = Enum.Font.GothamBold
leftTitle.TextSize = 16
leftTitle.TextColor3 = Color3.fromRGB(255,255,255)
leftTitle.TextXAlignment = Enum.TextXAlignment.Center
leftTitle.Text = "Auto Farm"

-- Toggle Auto Farm Button
local AutoFarmToggle = Instance.new("TextButton", LeftPanel)
AutoFarmToggle.Size = UDim2.new(1, -10, 0, 36)
AutoFarmToggle.Text = "Auto Farm Level ❌"
AutoFarmToggle.Font = Enum.Font.GothamBold
AutoFarmToggle.TextSize = 14
AutoFarmToggle.BackgroundColor3 = Color3.fromRGB(40,40,40)
AutoFarmToggle.TextColor3 = Color3.fromRGB(255,255,255)
Instance.new("UICorner", AutoFarmToggle).CornerRadius = UDim.new(0,8)

local autoFarmEnabled = false
AutoFarmToggle.MouseButton1Click:Connect(function()
    autoFarmEnabled = not autoFarmEnabled
    AutoFarmToggle.Text = "Auto Farm Level " .. (autoFarmEnabled and "✅" or "❌")
    getgenv().AutoFarmEnabled = autoFarmEnabled
end)

-- Right Panel (Setting Farm)
local RightPanel = Instance.new("ScrollingFrame", GeneralTab)
RightPanel.Size = UDim2.new(0.5, -5, 1, -30)
RightPanel.Position = UDim2.new(0.5, 5, 0, 30)
RightPanel.CanvasSize = UDim2.new(0, 0, 0, 200)
RightPanel.ScrollBarThickness = 4
RightPanel.BackgroundTransparency = 1
local RightLayout = Instance.new("UIListLayout", RightPanel)
RightLayout.Padding = UDim.new(0, 8)

local rightTitle = Instance.new("TextLabel", RightPanel)
rightTitle.Size = UDim2.new(1, -10, 0, 28)
rightTitle.BackgroundTransparency = 1
rightTitle.Font = Enum.Font.GothamBold
rightTitle.TextSize = 16
rightTitle.TextColor3 = Color3.fromRGB(255,255,255)
rightTitle.TextXAlignment = Enum.TextXAlignment.Center
rightTitle.Text = "Setting Farm"

-- Select Weapon Button
local SelectWeaponBtn = Instance.new("TextButton", RightPanel)
SelectWeaponBtn.Size = UDim2.new(1, -10, 0, 36)
SelectWeaponBtn.Text = "Select Weapon: Nothing"
SelectWeaponBtn.Font = Enum.Font.GothamBold
SelectWeaponBtn.TextSize = 14
SelectWeaponBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
SelectWeaponBtn.TextColor3 = Color3.fromRGB(255,255,255)
Instance.new("UICorner", SelectWeaponBtn).CornerRadius = UDim.new(0,8)

-- Dropdown Weapon List
local WeaponDropdown = Instance.new("ScrollingFrame", SelectWeaponBtn)
WeaponDropdown.Size = UDim2.new(1, 0, 0, 100)
WeaponDropdown.Position = UDim2.new(0, 0, 1, 0)
WeaponDropdown.CanvasSize = UDim2.new(0, 0, 0, 100)
WeaponDropdown.ScrollBarThickness = 4
WeaponDropdown.Visible = false
WeaponDropdown.BackgroundColor3 = Color3.fromRGB(30,30,30)
Instance.new("UICorner", WeaponDropdown).CornerRadius = UDim.new(0,8)

local WeaponLayout = Instance.new("UIListLayout", WeaponDropdown)
WeaponLayout.Padding = UDim.new(0, 4)

local WeaponChoices = {"Melee", "Sword"}
local selectedWeapon = "Nothing"

for _, weapon in ipairs(WeaponChoices) do
    local wBtn = Instance.new("TextButton", WeaponDropdown)
    wBtn.Size = UDim2.new(1, -10, 0, 28)
    wBtn.Text = weapon
    wBtn.Font = Enum.Font.Gotham
    wBtn.TextSize = 13
    wBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    wBtn.TextColor3 = Color3.fromRGB(255,255,255)
    Instance.new("UICorner", wBtn).CornerRadius = UDim.new(0,6)

    wBtn.MouseButton1Click:Connect(function()
        selectedWeapon = weapon
        SelectWeaponBtn.Text = "Select Weapon: " .. selectedWeapon
        WeaponDropdown.Visible = false
    end)
end

SelectWeaponBtn.MouseButton1Click:Connect(function()
    WeaponDropdown.Visible = not WeaponDropdown.Visible
end)
--===[ PHẦN 3: AUTO FARM LEVEL + GOM 3 CON + AUTO EQUIP + FAST ATTACK ]===--

-- Auto Equip function
local function autoEquipWeapon()
    if selectedWeapon == "Nothing" then return end
    for _,tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if selectedWeapon == "Melee" and tool.ToolTip == "Melee" then
            LocalPlayer.Character.Humanoid:EquipTool(tool)
        elseif selectedWeapon == "Sword" and tool.ToolTip == "Sword" then
            LocalPlayer.Character.Humanoid:EquipTool(tool)
        end
    end
end

-- Fast Attack
local function fastAttack()
    pcall(function()
        local VirtualUser = game:GetService("VirtualUser")
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new())
    end)
end

-- Enlarge Hitbox
local function enlargeHitbox(target)
    if target and target:FindFirstChild("HumanoidRootPart") then
        target.HumanoidRootPart.Size = Vector3.new(60, 60, 60)
        target.HumanoidRootPart.Transparency = 1
        target.HumanoidRootPart.CanCollide = false
    end
end

-- Tween to position
local function tweenTo(pos)
    local tweenInfo = TweenInfo.new((LocalPlayer.Character.HumanoidRootPart.Position - pos).magnitude / 150, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(LocalPlayer.Character.HumanoidRootPart, tweenInfo, {CFrame = CFrame.new(pos)})
    tween:Play()
    tween.Completed:Wait()
end

-- Find quest data
local function getQuestAndEnemies()
    local questName, questPos, enemyName
    for _,data in pairs(getgenv().BF_LevelFarm) do
        if LocalPlayer.Data.Level.Value >= data[1] and LocalPlayer.Data.Level.Value <= data[2] then
            questName = data[3]
            questPos = data[4]
            enemyName = data[5]
            break
        end
    end
    return questName, questPos, enemyName
end

-- Farm loop with "gom 3 con"
task.spawn(function()
    while task.wait() do
        if autoFarmEnabled and selectedWeapon ~= "Nothing" then
            local questName, questPos, enemyName = getQuestAndEnemies()
            if not questName then continue end

            autoEquipWeapon()

            -- Take quest if not have
            if not LocalPlayer.PlayerGui.Main.Quest.Visible then
                tweenTo(questPos)
                task.wait(0.5)
                game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("StartQuest", questName, 1)
            else
                -- Farm enemies
                local collected = {}
                for _,enemy in pairs(workspace.Enemies:GetChildren()) do
                    if enemy.Name == enemyName and enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 then
                        enlargeHitbox(enemy)
                        table.insert(collected, enemy)
                        if #collected >= 3 then break end
                    end
                end

                if #collected > 0 then
                    -- Set gather point = first enemy's position
                    local gatherPos = collected[1].HumanoidRootPart.Position
                    for _,enemy in ipairs(collected) do
                        pcall(function()
                            enemy.HumanoidRootPart.CFrame = CFrame.new(gatherPos)
                        end)
                    end

                    -- Move player above gather point
                    tweenTo(gatherPos + Vector3.new(0, 30, 0))

                    -- Attack loop
                    while autoFarmEnabled and #collected > 0 do
                        autoEquipWeapon()
                        fastAttack()
                        for i=#collected,1,-1 do
                            if collected[i].Humanoid.Health <= 0 then
                                table.remove(collected, i)
                            end
                        end
                        task.wait()
                    end
                end
            end
        end
    end
end)
