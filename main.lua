--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║          Universal FPS Engine — Fully Custom UI Edition          ║
    ╚══════════════════════════════════════════════════════════════════╝
]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
if not Drawing then
    warn("shitty executor detected: this script requires drawing api")
    return
end
local mouse1press = mouse1press or function() end
local mouse1release = mouse1release or function() end
local newcclosure = newcclosure or function(f) return f end
local WTVP = Camera.WorldToViewportPoint
local Vector2_new = Vector2.new
local Color3_fromRGB = Color3.fromRGB
local Math_floor = math.floor

-- Midnight Black and Blue Theme Configurations
local Theme = {
    Background = Color3_fromRGB(12, 12, 15),
    Sidebar = Color3_fromRGB(8, 8, 10),
    Topbar = Color3_fromRGB(16, 16, 20),
    Element = Color3_fromRGB(20, 20, 25),
    Accent = Color3_fromRGB(0, 128, 255),
    TextActive = Color3_fromRGB(255, 255, 255),
    TextMuted = Color3_fromRGB(150, 150, 150),
}
local ScriptRunning = true
local ESP_Store = {}
local Connections = {}
local UI_Store = {}
local SilentAimTarget = nil

local Config = {
    Global = { MenuOpen = true, Keybind = Enum.KeyCode.Insert },
    -- [Aimbot removed – only silent aim remains]
    SilentAim = {
        Enabled = false,
        FOV = 100,
        AimPart = "Head",
        WallCheck = true,
        WallBang = false,
        ShowFOV = false,
        FOVColor = Theme.Accent,
    },
    Triggerbot = {
        Enabled = false,
        Key = Enum.KeyCode.T,
        Delay = 0.1,
        Randomization = 0.05,
        MaxDistance = 1000,
    },
    Visuals = {
        Enabled = true,
        TeamCheck = true,
        Box = true,
        BoxOutline = true,
        Skeleton = true,
        HeadCircle = true,
        ViewLine = true,
        Snaplines = false,
        Names = true,
        Info = true,
        RenderDistance = 2500,
        BoxColor = {R=0,G=128,B=255},
        SkeletonColor = {R=0,G=128,B=255},
        HeadCircleColor = {R=0,G=128,B=255},
        ViewLineColor = {R=0,G=128,B=255},
        SnaplineColor = {R=0,G=128,B=255},
        NameColor = {R=255,G=255,B=255},
        InfoColor = {R=255,G=255,B=255},
    },
    FOV_Circle = {
        Enabled = true,   -- now controls silent aim FOV circle
        Color = Color3_fromRGB(255, 255, 255),
        Transparency = 0.5,
        Thickness = 1,
        NumSides = 60,
    },
    Movement = {
        EnabledWS = false, WalkSpeed = 16,
        EnabledJP = false, JumpPower = 50,
        Bhop = false, BhopKey = Enum.KeyCode.V
    },
    GunMods = { InfiniteAmmo = false, ReloadInterval = 1.0 },
    Hitbox = {
        Enabled = false,
        HeadSize = 50,
        ViewHitbox = false,
        HitboxColor = {R=255, G=0, B=0},
    }
}

local function SendNotification(text, color)
    local GUI = nil
    for _, v in pairs(UI_Store) do if v:IsA("ScreenGui") then GUI = v; break end end
    if not GUI then return end
    local NoteFrame = Instance.new("Frame")
    NoteFrame.Name = "Notification"
    NoteFrame.Size = UDim2.new(0, 200, 0, 40)
    NoteFrame.Position = UDim2.new(1, 20, 0.85, 0)
    NoteFrame.BackgroundColor3 = Theme.Topbar
    NoteFrame.BorderSizePixel = 0
    NoteFrame.Parent = GUI
    local Corner = Instance.new("UICorner"); Corner.CornerRadius = UDim.new(0, 6); Corner.Parent = NoteFrame
    local Strip = Instance.new("Frame")
    Strip.Size = UDim2.new(0, 4, 1, 0)
    Strip.BackgroundColor3 = color or Theme.Accent
    Strip.BorderSizePixel = 0
    Strip.Parent = NoteFrame
    Instance.new("UICorner", Strip).CornerRadius = UDim.new(0, 6)
    local Label = Instance.new("TextLabel")
    Label.Text = text
    Label.Size = UDim2.new(1, -15, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.TextColor3 = Theme.TextActive
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 14
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = NoteFrame
    TweenService:Create(NoteFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(1, -220, 0.85, 0)}):Play()
    task.spawn(function()
        task.wait(2)
        TweenService:Create(NoteFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Position = UDim2.new(1, 20, 0.85, 0)}):Play()
        task.wait(0.5)
        NoteFrame:Destroy()
    end)
end

local Library = {}
local MainFrameInstance = nil
function Library:CreateUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "UniversalFPSGui_" .. math.random(1000,9999)
    ScreenGui.ResetOnSpawn = false
    
    if gethui then
        ScreenGui.Parent = gethui()
    elseif CoreGui:FindFirstChild("RobloxGui") then
        ScreenGui.Parent = CoreGui
    else
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    
    table.insert(UI_Store, ScreenGui)
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 550, 0, 380)
    MainFrame.Position = UDim2.new(0.5, -275, 0.5, -190)
    MainFrame.BackgroundColor3 = Theme.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui
    
    MainFrameInstance = MainFrame
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 6)
    MainCorner.Parent = MainFrame
    
    local Dragging, DragStart, StartPos
    local function Update(input)
        local Delta = input.Position - DragStart
        MainFrame.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + Delta.X, StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y)
    end
    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            DragStart = input.Position
            StartPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then Dragging = false end
            end)
        end
    end)
    MainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if Dragging then Update(input) end
        end
    end)
    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 30)
    TopBar.BackgroundColor3 = Theme.Topbar
    TopBar.BorderSizePixel = 0
    TopBar.Parent = MainFrame
    Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 6)
    local Title = Instance.new("TextLabel")
    Title.Text = "Universal FPS Gui | By Thetrekir"
    Title.Size = UDim2.new(1, -20, 1, 0)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.BackgroundTransparency = 1
    Title.TextColor3 = Theme.TextMuted
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 14
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TopBar
    local TabContainer = Instance.new("Frame")
    TabContainer.Size = UDim2.new(0, 120, 1, -30)
    TabContainer.Position = UDim2.new(0, 0, 0, 30)
    TabContainer.BackgroundColor3 = Theme.Sidebar
    TabContainer.BorderSizePixel = 0
    TabContainer.Parent = MainFrame
    
    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabListLayout.Padding = UDim.new(0, 5)
    TabListLayout.Parent = TabContainer
    
    local TabPadding = Instance.new("UIPadding")
    TabPadding.PaddingTop = UDim.new(0, 10)
    TabPadding.Parent = TabContainer
    local PageContainer = Instance.new("Frame")
    PageContainer.Size = UDim2.new(1, -120, 1, -30)
    PageContainer.Position = UDim2.new(0, 120, 0, 30)
    PageContainer.BackgroundTransparency = 1
    PageContainer.Parent = MainFrame
    local Tabs = {}
    local FirstTab = true
    function Tabs:CreateTab(Name)
        local TabButton = Instance.new("TextButton")
        TabButton.Text = Name
        TabButton.Size = UDim2.new(1, -10, 0, 30)
        TabButton.BackgroundColor3 = Theme.Background
        TabButton.TextColor3 = Theme.TextMuted
        TabButton.Font = Enum.Font.GothamSemibold
        TabButton.TextSize = 13
        TabButton.AutoButtonColor = false
        TabButton.Parent = TabContainer
        
        local TabCorner = Instance.new("UICorner")
        TabCorner.CornerRadius = UDim.new(0, 4)
        TabCorner.Parent = TabButton
        local Page = Instance.new("ScrollingFrame")
        Page.Size = UDim2.new(1, -10, 1, -10)
        Page.Position = UDim2.new(0, 5, 0, 5)
        Page.BackgroundTransparency = 1
        Page.ScrollBarThickness = 2
        Page.ScrollBarImageColor3 = Theme.Accent
        Page.Visible = false
        Page.Parent = PageContainer
        
        local PageLayout = Instance.new("UIListLayout")
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Padding = UDim.new(0, 5)
        PageLayout.Parent = Page
        
        if FirstTab then
            FirstTab = false
            Page.Visible = true
            TabButton.TextColor3 = Theme.TextActive
            TabButton.BackgroundColor3 = Theme.Element
        end
        TabButton.MouseButton1Click:Connect(function()
            for _, v in pairs(PageContainer:GetChildren()) do if v:IsA("ScrollingFrame") then v.Visible = false end end
            for _, v in pairs(TabContainer:GetChildren()) do 
                if v:IsA("TextButton") then 
                    TweenService:Create(v, TweenInfo.new(0.2), {TextColor3 = Theme.TextMuted, BackgroundColor3 = Theme.Background}):Play()
                end 
            end
            Page.Visible = true
            TweenService:Create(TabButton, TweenInfo.new(0.2), {TextColor3 = Theme.TextActive, BackgroundColor3 = Theme.Element}):Play()
        end)
        local Elements = {}
        
        function Elements:AddToggle(Text, ConfigTable, ConfigKey)
            local ToggleFrame = Instance.new("Frame")
            ToggleFrame.Size = UDim2.new(1, 0, 0, 30)
            ToggleFrame.BackgroundColor3 = Theme.Element
            ToggleFrame.Parent = Page
            Instance.new("UICorner", ToggleFrame).CornerRadius = UDim.new(0,4)
            
            local Label = Instance.new("TextLabel")
            Label.Text = Text
            Label.Size = UDim2.new(0.7, 0, 1, 0)
            Label.Position = UDim2.new(0, 10, 0, 0)
            Label.BackgroundTransparency = 1
            Label.TextColor3 = Color3_fromRGB(220, 220, 220)
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 13
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = ToggleFrame
            
            local Button = Instance.new("TextButton")
            Button.Text = ""
            Button.Size = UDim2.new(0, 20, 0, 20)
            Button.Position = UDim2.new(1, -30, 0.5, -10)
            Button.BackgroundColor3 = ConfigTable[ConfigKey] and Theme.Accent or Color3_fromRGB(60, 60, 60)
            Button.Parent = ToggleFrame
            Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 4)
            
            Button.MouseButton1Click:Connect(function()
                ConfigTable[ConfigKey] = not ConfigTable[ConfigKey]
                TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = ConfigTable[ConfigKey] and Theme.Accent or Color3_fromRGB(60, 60, 60)}):Play()
                
                if ConfigKey == "Enabled" and ConfigTable == Config.Triggerbot then
                    if ConfigTable[ConfigKey] then
                        SendNotification("Triggerbot: ENABLED", Theme.Accent)
                    else
                        SendNotification("Triggerbot: DISABLED", Color3_fromRGB(255, 50, 50))
                    end
                end
            end)
            return Button
        end
        
        function Elements:AddSlider(Text, ConfigTable, ConfigKey, Min, Max, IsFloat)
            local SliderFrame = Instance.new("Frame")
            SliderFrame.Size = UDim2.new(1, 0, 0, 45)
            SliderFrame.BackgroundColor3 = Theme.Element
            SliderFrame.Parent = Page
            Instance.new("UICorner", SliderFrame).CornerRadius = UDim.new(0,4)
            local Label = Instance.new("TextLabel")
            Label.Text = Text
            Label.Size = UDim2.new(1, -20, 0, 20)
            Label.Position = UDim2.new(0, 10, 0, 5)
            Label.BackgroundTransparency = 1
            Label.TextColor3 = Color3_fromRGB(220, 220, 220)
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 13
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = SliderFrame
            
            local ValueLabel = Instance.new("TextLabel")
            ValueLabel.Text = tostring(ConfigTable[ConfigKey])
            ValueLabel.Size = UDim2.new(0, 50, 0, 20)
            ValueLabel.Position = UDim2.new(1, -60, 0, 5)
            ValueLabel.BackgroundTransparency = 1
            ValueLabel.TextColor3 = Theme.Accent
            ValueLabel.Font = Enum.Font.GothamBold
            ValueLabel.TextSize = 13
            ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
            ValueLabel.Parent = SliderFrame
            local SliderBar = Instance.new("Frame")
            SliderBar.Size = UDim2.new(1, -20, 0, 4)
            SliderBar.Position = UDim2.new(0, 10, 0, 30)
            SliderBar.BackgroundColor3 = Color3_fromRGB(60, 60, 60)
            SliderBar.BorderSizePixel = 0
            SliderBar.Parent = SliderFrame
            
            local Fill = Instance.new("Frame")
            Fill.BackgroundColor3 = Theme.Accent
            Fill.BorderSizePixel = 0
            Fill.Size = UDim2.new((ConfigTable[ConfigKey] - Min) / (Max - Min), 0, 1, 0)
            Fill.Parent = SliderBar
            
            local Trigger = Instance.new("TextButton")
            Trigger.BackgroundTransparency = 1
            Trigger.Text = ""
            Trigger.Size = UDim2.new(1, 0, 1, 0)
            Trigger.Parent = SliderBar
            
            local function UpdateSlider(Input)
                local SizeX = math.clamp((Input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
                local NewValue = Min + ((Max - Min) * SizeX)
                if not IsFloat then NewValue = Math_floor(NewValue) end
                
                if IsFloat then
                    NewValue = math.floor(NewValue * 100) / 100
                end
                
                ConfigTable[ConfigKey] = NewValue
                ValueLabel.Text = string.sub(tostring(NewValue), 1, 4)
                Fill.Size = UDim2.new(SizeX, 0, 1, 0)
            end
            
            local DraggingSlider = false
            Trigger.InputBegan:Connect(function(Input) if Input.UserInputType == Enum.UserInputType.MouseButton1 then DraggingSlider = true; UpdateSlider(Input) end end)
            UserInputService.InputChanged:Connect(function(Input) if DraggingSlider and Input.UserInputType == Enum.UserInputType.MouseMovement then UpdateSlider(Input) end end)
            UserInputService.InputEnded:Connect(function(Input) if Input.UserInputType == Enum.UserInputType.MouseButton1 then DraggingSlider = false end end)
        end
        
        function Elements:AddButton(Text, Callback)
            local ButtonFrame = Instance.new("Frame")
            ButtonFrame.Size = UDim2.new(1, 0, 0, 30)
            ButtonFrame.BackgroundColor3 = Theme.Element
            ButtonFrame.Parent = Page
            Instance.new("UICorner", ButtonFrame).CornerRadius = UDim.new(0,4)
            local Btn = Instance.new("TextButton")
            Btn.Text = Text
            Btn.Size = UDim2.new(1, 0, 1, 0)
            Btn.BackgroundTransparency = 1
            Btn.TextColor3 = Color3_fromRGB(255, 80, 80)
            Btn.Font = Enum.Font.GothamBold
            Btn.TextSize = 13
            Btn.Parent = ButtonFrame
            Btn.MouseButton1Click:Connect(Callback)
        end
        function Elements:AddKeybind(Text, ConfigTable, ConfigKey)
            local KeyFrame = Instance.new("Frame")
            KeyFrame.Size = UDim2.new(1, 0, 0, 30)
            KeyFrame.BackgroundColor3 = Theme.Element
            KeyFrame.Parent = Page
            Instance.new("UICorner", KeyFrame).CornerRadius = UDim.new(0,4)
            local Label = Instance.new("TextLabel")
            Label.Text = Text
            Label.Size = UDim2.new(0.6, 0, 1, 0)
            Label.Position = UDim2.new(0, 10, 0, 0)
            Label.BackgroundTransparency = 1
            Label.TextColor3 = Color3_fromRGB(220, 220, 220)
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 13
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = KeyFrame
            local KeyButton = Instance.new("TextButton")
            KeyButton.Text = ConfigTable[ConfigKey].Name
            KeyButton.Size = UDim2.new(0, 80, 0, 20)
            KeyButton.Position = UDim2.new(1, -90, 0.5, -10)
            KeyButton.BackgroundColor3 = Color3_fromRGB(60, 60, 60)
            KeyButton.TextColor3 = Theme.TextActive
            KeyButton.Font = Enum.Font.GothamBold
            KeyButton.TextSize = 12
            KeyButton.Parent = KeyFrame
            Instance.new("UICorner", KeyButton).CornerRadius = UDim.new(0, 4)
            KeyButton.MouseButton1Click:Connect(function()
                KeyButton.Text = ". . ."
                local InputConnection
                InputConnection = UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        ConfigTable[ConfigKey] = input.KeyCode
                        KeyButton.Text = input.KeyCode.Name
                        InputConnection:Disconnect()
                    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                        ConfigTable[ConfigKey] = Enum.UserInputType.MouseButton2
                        KeyButton.Text = "Mouse2"
                        InputConnection:Disconnect()
                    end
                end)
            end)
        end
        return Elements
    end
    return Tabs, ScreenGui
end

-- ==================== CREATE UI ====================
local Window, GUIInstance = Library:CreateUI()

-- Silent Aim tab (only silent aim options)
local SilentAimTab = Window:CreateTab("Silent Aim")
SilentAimTab:AddToggle("Enabled", Config.SilentAim, "Enabled")
SilentAimTab:AddToggle("Wall Check", Config.SilentAim, "WallCheck")
SilentAimTab:AddToggle("Wall Bang", Config.SilentAim, "WallBang")
SilentAimTab:AddSlider("FOV", Config.SilentAim, "FOV", 10, 500, false)
SilentAimTab:AddToggle("Show FOV Circle", Config.SilentAim, "ShowFOV")

local TrigTab = Window:CreateTab("Triggerbot")
local TrigEnabledBtn = TrigTab:AddToggle("Enabled (Toggle)", Config.Triggerbot, "Enabled")
TrigTab:AddKeybind("Toggle Key", Config.Triggerbot, "Key")
TrigTab:AddSlider("Delay (Between Clicks)", Config.Triggerbot, "Delay", 0.01, 1.0, true)
TrigTab:AddSlider("Randomize (Legit)", Config.Triggerbot, "Randomization", 0.0, 0.2, true)
TrigTab:AddSlider("Max Distance", Config.Triggerbot, "MaxDistance", 50, 3000, false)

local VisTab = Window:CreateTab("Visuals")
VisTab:AddToggle("Enabled", Config.Visuals, "Enabled")
VisTab:AddToggle("TeamCheck", Config.Visuals, "TeamCheck")
VisTab:AddToggle("Box", Config.Visuals, "Box")
VisTab:AddSlider("Box R", Config.Visuals.BoxColor, "R", 0, 255, false)
VisTab:AddSlider("Box G", Config.Visuals.BoxColor, "G", 0, 255, false)
VisTab:AddSlider("Box B", Config.Visuals.BoxColor, "B", 0, 255, false)
VisTab:AddToggle("Names", Config.Visuals, "Names")
VisTab:AddSlider("Name R", Config.Visuals.NameColor, "R", 0, 255, false)
VisTab:AddSlider("Name G", Config.Visuals.NameColor, "G", 0, 255, false)
VisTab:AddSlider("Name B", Config.Visuals.NameColor, "B", 0, 255, false)
VisTab:AddToggle("Info", Config.Visuals, "Info")
VisTab:AddSlider("Info R", Config.Visuals.InfoColor, "R", 0, 255, false)
VisTab:AddSlider("Info G", Config.Visuals.InfoColor, "G", 0, 255, false)
VisTab:AddSlider("Info B", Config.Visuals.InfoColor, "B", 0, 255, false)
VisTab:AddToggle("Skeleton", Config.Visuals, "Skeleton")
VisTab:AddSlider("Skel R", Config.Visuals.SkeletonColor, "R", 0, 255, false)
VisTab:AddSlider("Skel G", Config.Visuals.SkeletonColor, "G", 0, 255, false)
VisTab:AddSlider("Skel B", Config.Visuals.SkeletonColor, "B", 0, 255, false)
VisTab:AddToggle("Head", Config.Visuals, "HeadCircle")
VisTab:AddSlider("Head R", Config.Visuals.HeadCircleColor, "R", 0, 255, false)
VisTab:AddSlider("Head G", Config.Visuals.HeadCircleColor, "G", 0, 255, false)
VisTab:AddSlider("Head B", Config.Visuals.HeadCircleColor, "B", 0, 255, false)
VisTab:AddToggle("ViewLine", Config.Visuals, "ViewLine")
VisTab:AddSlider("ViewL R", Config.Visuals.ViewLineColor, "R", 0, 255, false)
VisTab:AddSlider("ViewL G", Config.Visuals.ViewLineColor, "G", 0, 255, false)
VisTab:AddSlider("ViewL B", Config.Visuals.ViewLineColor, "B", 0, 255, false)
VisTab:AddToggle("Snaplines", Config.Visuals, "Snaplines")
VisTab:AddSlider("Snap R", Config.Visuals.SnaplineColor, "R", 0, 255, false)
VisTab:AddSlider("Snap G", Config.Visuals.SnaplineColor, "G", 0, 255, false)
VisTab:AddSlider("Snap B", Config.Visuals.SnaplineColor, "B", 0, 255, false)
VisTab:AddSlider("Distance", Config.Visuals, "RenderDistance", 100, 5000, false)

local MoveTab = Window:CreateTab("Movement")
MoveTab:AddToggle("Enable WalkSpeed", Config.Movement, "EnabledWS")
MoveTab:AddSlider("WalkSpeed", Config.Movement, "WalkSpeed", 16, 100, false)
MoveTab:AddToggle("Enable JumpPower", Config.Movement, "EnabledJP")
MoveTab:AddSlider("JumpPower", Config.Movement, "JumpPower", 50, 250, false)
local BhopEnabledBtn = MoveTab:AddToggle("Auto-Bhop", Config.Movement, "Bhop")
MoveTab:AddKeybind("Bhop Keybind", Config.Movement, "BhopKey")

local GunModsTab = Window:CreateTab("Gun Mods")
local InfAmmoBtn = GunModsTab:AddToggle("Infinite Ammo", Config.GunMods, "InfiniteAmmo")
GunModsTab:AddSlider("Reload Interval (s)", Config.GunMods, "ReloadInterval", 0.1, 5.0, true)

local HitboxTab = Window:CreateTab("Hitbox")
HitboxTab:AddToggle("Expand Hitbox", Config.Hitbox, "Enabled")
HitboxTab:AddSlider("Head Size (studs)", Config.Hitbox, "HeadSize", 10, 200, false)
HitboxTab:AddToggle("View Hitbox", Config.Hitbox, "ViewHitbox")
HitboxTab:AddSlider("View R", Config.Hitbox.HitboxColor, "R", 0, 255, false)
HitboxTab:AddSlider("View G", Config.Hitbox.HitboxColor, "G", 0, 255, false)
HitboxTab:AddSlider("View B", Config.Hitbox.HitboxColor, "B", 0, 255, false)

local SetTab = Window:CreateTab("Settings")
SetTab:AddButton("UNLOAD THE SCRIPT", function()
    ScriptRunning = false
    for _, conn in pairs(Connections) do conn:Disconnect() end
    table.clear(Connections)
    for plr, data in pairs(ESP_Store) do
        pcall(function()
            data.Box:Remove(); data.BoxOutline:Remove(); data.Name:Remove()
            data.Info:Remove(); data.HeadCircle:Remove(); data.ViewLine:Remove()
            data.Snapline:Remove(); data.HitboxCircle:Remove()
            for _, line in pairs(data.Skeleton) do line:Remove() end
        end)
    end
    table.clear(ESP_Store)
    if SilentAimFOVCircle then SilentAimFOVCircle:Remove() end
    for _, ui in pairs(UI_Store) do ui:Destroy() end
end)

-- ==================== KEYBIND HANDLING (global) ====================
table.insert(Connections, UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Config.Global.Keybind then
        Config.Global.MenuOpen = not Config.Global.MenuOpen
        if MainFrameInstance then
            MainFrameInstance.Visible = Config.Global.MenuOpen
        end
    end
    
    if input.KeyCode == Config.Triggerbot.Key then
        Config.Triggerbot.Enabled = not Config.Triggerbot.Enabled
        local Color = Config.Triggerbot.Enabled and Theme.Accent or Color3_fromRGB(60, 60, 60)
        TweenService:Create(TrigEnabledBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color}):Play()
        if Config.Triggerbot.Enabled then
            SendNotification("Triggerbot: ENABLED", Theme.Accent)
        else
            SendNotification("Triggerbot: DISABLED", Color3_fromRGB(255, 50, 50))
        end
    end
    if input.KeyCode == Config.Movement.BhopKey then
        Config.Movement.Bhop = not Config.Movement.Bhop
        local Color = Config.Movement.Bhop and Theme.Accent or Color3_fromRGB(60, 60, 60)
        if BhopEnabledBtn then
            TweenService:Create(BhopEnabledBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color}):Play()
        end
        if Config.Movement.Bhop then
            SendNotification("Auto-Bhop: ENABLED", Theme.Accent)
        else
            SendNotification("Auto-Bhop: DISABLED", Color3_fromRGB(255, 50, 50))
        end
    end
end))

-- ==================== RAYCAST PARAMS ====================
local GlobalRaycastParams = RaycastParams.new()
GlobalRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
GlobalRaycastParams.IgnoreWater = true

-- Silent aim FOV circle (only one circle now)
local SilentAimFOVCircle = Drawing.new("Circle")
SilentAimFOVCircle.Visible = Config.SilentAim.ShowFOV
SilentAimFOVCircle.Thickness = Config.FOV_Circle.Thickness
SilentAimFOVCircle.Color = Config.SilentAim.FOVColor
SilentAimFOVCircle.Transparency = Config.FOV_Circle.Transparency
SilentAimFOVCircle.Filled = false
SilentAimFOVCircle.NumSides = Config.FOV_Circle.NumSides

-- Silent aim hooks (unchanged)
local function ApplySilentAimHooks()
    local rawmt = getrawmetatable and getrawmetatable(game)
    local setreadonly = setreadonly or make_writeable
    
    if rawmt and setreadonly then
        local Success, Error = pcall(function()
            setreadonly(rawmt, false)
            
            local old_index = rawmt.__index
            rawmt.__index = newcclosure(function(self, key)
                if not checkcaller() and Config.SilentAim.Enabled and SilentAimTarget then
                    if self == Mouse then
                        if key == "Hit" then
                            local camPos = Camera.CFrame.Position
                            local targetPos = SilentAimTarget.Position
                            local distance = (targetPos - camPos).Magnitude
                            if distance > 10000 then
                                targetPos = camPos + (targetPos - camPos).Unit * 1000
                            end
                            return CFrame.new(targetPos)
                        elseif key == "Target" then
                            return SilentAimTarget
                        end
                    elseif typeof(self) == "RaycastResult" then
                        local bypassWalls = Config.SilentAim.WallBang or not Config.SilentAim.WallCheck
                        if bypassWalls then
                            if key == "Instance" then
                                return SilentAimTarget
                            elseif key == "Position" then
                                return SilentAimTarget.Position
                            end
                        end
                    end
                end
                return old_index(self, key)
            end)
            
            local old_namecall = rawmt.__namecall
            rawmt.__namecall = newcclosure(function(self, ...)
                local method = getnamecallmethod and getnamecallmethod()
                local args = {...}
                if not checkcaller() and Config.SilentAim.Enabled and SilentAimTarget and method then
                    local bypassWalls = Config.SilentAim.WallBang or not Config.SilentAim.WallCheck
                    if method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRay" then
                        if bypassWalls then
                            return SilentAimTarget, SilentAimTarget.Position, Vector3.new(0, 1, 0), Enum.Material.SmoothPlastic
                        else
                            local origin = args[1].Origin
                            local direction = (SilentAimTarget.Position - origin).Unit * 1000
                            args[1] = Ray.new(origin, direction)
                            return old_namecall(self, table.unpack(args))
                        end
                    elseif method == "Raycast" and self == Workspace then
                        if bypassWalls then
                            local fakeResult = {
                                Instance = SilentAimTarget,
                                Position = SilentAimTarget.Position,
                                Normal = Vector3.new(0, 1, 0),
                                Material = Enum.Material.SmoothPlastic,
                                Distance = (SilentAimTarget.Position - args[1]).Magnitude
                            }
                            return fakeResult
                        else
                            local origin = args[1]
                            local direction = (SilentAimTarget.Position - origin).Unit * 1000
                            args[2] = direction
                            return old_namecall(self, table.unpack(args))
                        end
                    end
                end
                return old_namecall(self, ...)
            end)
            
            setreadonly(rawmt, true)
        end)
    end
    
    pcall(function()
        if hookmetamethod then
            local old_index
            old_index = hookmetamethod(game, "__index", newcclosure(function(self, key)
                if not checkcaller() and Config.SilentAim.Enabled and SilentAimTarget then
                    if self == Mouse then
                        if key == "Hit" then
                            local camPos = Camera.CFrame.Position
                            local targetPos = SilentAimTarget.Position
                            local distance = (targetPos - camPos).Magnitude
                            if distance > 10000 then
                                targetPos = camPos + (targetPos - camPos).Unit * 1000
                            end
                            return CFrame.new(targetPos)
                        elseif key == "Target" then
                            return SilentAimTarget
                        end
                    elseif typeof(self) == "RaycastResult" then
                        local bypassWalls = Config.SilentAim.WallBang or not Config.SilentAim.WallCheck
                        if bypassWalls then
                            if key == "Instance" then
                                return SilentAimTarget
                            elseif key == "Position" then
                                return SilentAimTarget.Position
                            end
                        end
                    end
                end
                return old_index(self, key)
            end))
            
            local old_namecall
            old_namecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
                local method = getnamecallmethod and getnamecallmethod()
                local args = {...}
                if not checkcaller() and Config.SilentAim.Enabled and SilentAimTarget and method then
                    local bypassWalls = Config.SilentAim.WallBang or not Config.SilentAim.WallCheck
                    if method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRay" then
                        if bypassWalls then
                            return SilentAimTarget, SilentAimTarget.Position, Vector3.new(0, 1, 0), Enum.Material.SmoothPlastic
                        else
                            local origin = args[1].Origin
                            local direction = (SilentAimTarget.Position - origin).Unit * 1000
                            args[1] = Ray.new(origin, direction)
                            return old_namecall(self, table.unpack(args))
                        end
                    elseif method == "Raycast" and self == Workspace then
                        if bypassWalls then
                            local fakeResult = {
                                Instance = SilentAimTarget,
                                Position = SilentAimTarget.Position,
                                Normal = Vector3.new(0, 1, 0),
                                Material = Enum.Material.SmoothPlastic,
                                Distance = (SilentAimTarget.Position - args[1]).Magnitude
                            }
                            return fakeResult
                        else
                            local origin = args[1]
                            local direction = (SilentAimTarget.Position - origin).Unit * 1000
                            args[2] = direction
                            return old_namecall(self, table.unpack(args))
                        end
                    end
                end
                return old_namecall(self, ...)
            end))
        end
    end)
end

-- Helper functions
local function GetCharacterRoot(Char)
    if not Char then return nil end
    return Char.PrimaryPart or Char:FindFirstChild("HumanoidRootPart") or Char:FindFirstChild("Torso") or Char:FindFirstChild("UpperTorso")
end
local function GetCharacterHumanoid(Char)
    if not Char then return nil end
    return Char:FindFirstChild("Humanoid") or Char:FindFirstChildWhichIsA("Humanoid")
end
local CommonAttributes = {"Team", "team", "Side", "side", "Faction", "faction", "Squad", "squad"}
local function IsEnemy(plr)
    if not Config.Visuals.TeamCheck then return true end 
    if plr == LocalPlayer then return false end 
    if plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team then return false end
    local PColor = plr.TeamColor; local LColor = LocalPlayer.TeamColor
    if PColor and LColor and PColor == LColor and PColor ~= BrickColor.new("White") and PColor ~= BrickColor.new("Medium stone grey") then return false end
    for i = 1, #CommonAttributes do
        local attr = CommonAttributes[i]
        local MyAttr = LocalPlayer:GetAttribute(attr)
        if MyAttr then
            local TheirAttr = plr:GetAttribute(attr)
            if TheirAttr and MyAttr == TheirAttr then return false end
        end
    end
    local PL = plr:FindFirstChild("leaderstats"); local LL = LocalPlayer:FindFirstChild("leaderstats")
    if PL and LL then
        local MT = LL:FindFirstChild("Team") or LL:FindFirstChild("Side")
        local TT = PL:FindFirstChild("Team") or PL:FindFirstChild("Side")
        if MT and TT and MT.Value == TT.Value then return false end
    end
    return true
end
local function CheckVisibility(targetPart, targetCharacter)
    if not targetPart then return false end
    local Origin = Camera.CFrame.Position
    local Direction = targetPart.Position - Origin
    GlobalRaycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera, Workspace:FindFirstChild("RaycastIgnore")}
    local Result = Workspace:Raycast(Origin, Direction, GlobalRaycastParams)
    if Result and Result.Instance and Result.Instance:IsDescendantOf(targetCharacter) then return true end
    return Result == nil 
end

-- ESP drawing
local function InitializeDrawing(plr)
    if ESP_Store[plr] then return end
    local Objects = {
        BoxOutline = Drawing.new("Square"), Box = Drawing.new("Square"), Name = Drawing.new("Text"),
        Info = Drawing.new("Text"), HeadCircle = Drawing.new("Circle"), ViewLine = Drawing.new("Line"),
        Snapline = Drawing.new("Line"), HitboxCircle = Drawing.new("Circle"), Skeleton = {}
    }
    Objects.BoxOutline.Visible = false; Objects.BoxOutline.Filled = false; Objects.BoxOutline.Thickness = 3; Objects.BoxOutline.Color = Color3_fromRGB(0,0,0); Objects.BoxOutline.Transparency = 0.5
    Objects.Box.Visible = false; Objects.Box.Filled = false; Objects.Box.Thickness = 1
    Objects.Name.Visible = false; Objects.Name.Center = true; Objects.Name.Outline = true; Objects.Name.Font = 2
    Objects.Info.Visible = false; Objects.Info.Center = true; Objects.Info.Outline = true; Objects.Info.Font = 2
    Objects.HeadCircle.Visible = false; Objects.HeadCircle.Filled = false; Objects.HeadCircle.Thickness = 1.5
    Objects.ViewLine.Visible = false; Objects.ViewLine.Thickness = 1
    Objects.Snapline.Visible = false; Objects.Snapline.Thickness = 1.5
    Objects.HitboxCircle.Visible = false; Objects.HitboxCircle.Filled = false; Objects.HitboxCircle.Thickness = 1.5
    for i=1,16 do local Line = Drawing.new("Line"); Line.Visible = false; Line.Thickness = 1.5; table.insert(Objects.Skeleton, Line) end
    ESP_Store[plr] = Objects
end
local function HideAll(D)
    D.Box.Visible = false; D.BoxOutline.Visible = false; D.Name.Visible = false; D.Info.Visible = false
    D.HeadCircle.Visible = false; D.ViewLine.Visible = false; D.Snapline.Visible = false; D.HitboxCircle.Visible = false
    for _, line in ipairs(D.Skeleton) do line.Visible = false end
end
local function ClearDrawing(plr)
    if not ESP_Store[plr] then return end
    local D = ESP_Store[plr]
    pcall(function()
        D.Box:Remove(); D.BoxOutline:Remove(); D.Name:Remove(); D.Info:Remove(); D.HeadCircle:Remove()
        D.ViewLine:Remove(); D.Snapline:Remove(); D.HitboxCircle:Remove()
        for _, line in pairs(D.Skeleton) do line:Remove() end
    end)
    ESP_Store[plr] = nil
end
local R15_Links = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
}
local R6_Links = {
    {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
    {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
}

-- Triggerbot
task.spawn(function()
    while ScriptRunning do
        local DidFire = false
        if Config.Triggerbot.Enabled then
            local Origin = Camera.CFrame.Position
            local Direction = Camera.CFrame.LookVector * Config.Triggerbot.MaxDistance
            GlobalRaycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera, Workspace:FindFirstChild("RaycastIgnore")}
            local Result = Workspace:Raycast(Origin, Direction, GlobalRaycastParams)
            if Result and Result.Instance then
                local HitModel = Result.Instance:FindFirstAncestorOfClass("Model")
                if HitModel then
                    local Plr = Players:GetPlayerFromCharacter(HitModel)
                    if Plr and IsEnemy(Plr) then
                        local Hum = GetCharacterHumanoid(HitModel)
                        if Hum and Hum.Health > 0 then
                            mouse1press()
                            task.wait(0.03)
                            mouse1release()
                            local ShotDelay = Config.Triggerbot.Delay + (math.random() * Config.Triggerbot.Randomization)
                            task.wait(ShotDelay)
                            DidFire = true
                        end
                    end
                end
            end
        end
        if not DidFire then task.wait(0.05) end
    end
end)

-- Gun Mods: Infinite ammo
local WeaponRemote = game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("Weapons")
task.spawn(function()
    while ScriptRunning do
        if Config.GunMods.InfiniteAmmo then
            pcall(function() WeaponRemote:FireServer("Reload") end)
            task.wait(Config.GunMods.ReloadInterval)
        else
            task.wait(0.5)
        end
    end
end)

-- ==================== MAIN RENDER LOOP (SILENT AIM ONLY) ====================
local function MainRender()
    if not ScriptRunning then return end
    
    -- Expand head hitboxes
    if Config.Hitbox.Enabled then
        for _, v in next, Players:GetPlayers() do
            if v ~= LocalPlayer and v.Character then
                pcall(function()
                    local head = v.Character:FindFirstChild("Head")
                    if head then
                        head.Size = Vector3.new(Config.Hitbox.HeadSize, Config.Hitbox.HeadSize, Config.Hitbox.HeadSize)
                        head.Transparency = 0.7
                        head.BrickColor = BrickColor.new("Really blue")
                        head.Material = "Neon"
                        head.CanCollide = false
                    end
                end)
            end
        end
    end
    
    local MouseLoc = UserInputService:GetMouseLocation()
    local ViewportSize = Camera.ViewportSize
    local ScreenBottom = Vector2_new(ViewportSize.X / 2, ViewportSize.Y)
    
    -- Update silent aim FOV circle
    SilentAimFOVCircle.Position = MouseLoc
    SilentAimFOVCircle.Radius = Config.SilentAim.FOV
    SilentAimFOVCircle.Visible = Config.SilentAim.ShowFOV
    
    local silentBest = nil
    local silentBestDist = Config.SilentAim.FOV
    
    local AllPlayers = Players:GetPlayers()
    for i = 1, #AllPlayers do
        local plr = AllPlayers[i]
        if plr == LocalPlayer then continue end
        local D = ESP_Store[plr]
        if not D then InitializeDrawing(plr); D = ESP_Store[plr] end
        
        local Char = plr.Character
        if not Char then HideAll(D); continue end
        
        local Root = GetCharacterRoot(Char)
        local Head = Char:FindFirstChild("Head")
        if not Root or not Head then HideAll(D); continue end
        
        local RootPos3D = Root.Position
        local Dist = (RootPos3D - Camera.CFrame.Position).Magnitude
        if Dist > Config.Visuals.RenderDistance then HideAll(D); continue end
        if not IsEnemy(plr) then HideAll(D); continue end
        
        local Hum = GetCharacterHumanoid(Char)
        local HP = (Hum and Hum.Health) or 100
        if Hum and Hum.Health <= 0 then HideAll(D); continue end
        
        local RootPos, RootVis = WTVP(Camera, RootPos3D)
        if not RootVis then HideAll(D); continue end
        
        -- Screen positions
        local HeadScreenPos, OnScreen = WTVP(Camera, Head.Position)
        local screenRadius = 0
        if OnScreen then
            local headSize = Head.Size
            local worldRadius = math.max(headSize.X, headSize.Y, headSize.Z) / 2
            local rightVec = Camera.CFrame.RightVector * worldRadius
            local leftEdge = Head.Position - rightVec
            local rightEdge = Head.Position + rightVec
            local leftScreen = WTVP(Camera, leftEdge)
            local rightScreen = WTVP(Camera, rightEdge)
            if leftScreen and rightScreen then
                screenRadius = (Vector2_new(rightScreen.X, rightScreen.Y) - Vector2_new(leftScreen.X, leftScreen.Y)).Magnitude / 2
            end
        end
        
        local IsVisible = false
        if Config.Visuals.Enabled or Config.SilentAim.Enabled then
            IsVisible = CheckVisibility(Head, Char)
        end
        
        -- Silent aim target selection
        if Config.SilentAim.Enabled and OnScreen then
            local magToCenter = (Vector2_new(HeadScreenPos.X, HeadScreenPos.Y) - MouseLoc).Magnitude
            local distToCircle = math.max(0, magToCenter - screenRadius)
            if distToCircle < silentBestDist then
                local passWall = true
                if Config.SilentAim.WallCheck and not Config.SilentAim.WallBang then
                    passWall = IsVisible
                end
                if passWall then
                    silentBest = Head
                    silentBestDist = distToCircle
                end
            end
        end
        
        -- ESP drawing (unchanged)
        if Config.Visuals.Enabled then
            local IsR15 = (Char:FindFirstChild("UpperTorso") ~= nil)
            local ScaleFactor = 1000 / Dist
            local BoxSizeY = (IsR15 and 5.5 or 5.0) * ScaleFactor
            local BoxSizeX = 3.5 * ScaleFactor
            local BoxPos = Vector2_new(RootPos.X - BoxSizeX/2, RootPos.Y - BoxSizeY/2)
            
            if Config.Visuals.Box then
                if Config.Visuals.BoxOutline then D.BoxOutline.Size = Vector2_new(BoxSizeX, BoxSizeY); D.BoxOutline.Position = BoxPos; D.BoxOutline.Visible = true else D.BoxOutline.Visible = false end
                D.Box.Size = Vector2_new(BoxSizeX, BoxSizeY); D.Box.Position = BoxPos
                D.Box.Color = Color3_fromRGB(Config.Visuals.BoxColor.R, Config.Visuals.BoxColor.G, Config.Visuals.BoxColor.B)
                D.Box.Visible = true
            else D.Box.Visible = false; D.BoxOutline.Visible = false end
            
            if Config.Visuals.Names then
                D.Name.Text = plr.Name
                D.Name.Position = Vector2_new(RootPos.X, BoxPos.Y - 18)
                D.Name.Color = Color3_fromRGB(Config.Visuals.NameColor.R, Config.Visuals.NameColor.G, Config.Visuals.NameColor.B)
                D.Name.Visible = true
            else D.Name.Visible = false end
            
            if Config.Visuals.Info then
                D.Info.Text = Math_floor(HP) .. " HP | " .. Math_floor(Dist) .. "m"
                D.Info.Position = Vector2_new(RootPos.X, BoxPos.Y + BoxSizeY + 4)
                D.Info.Color = Color3_fromRGB(Config.Visuals.InfoColor.R, Config.Visuals.InfoColor.G, Config.Visuals.InfoColor.B)
                D.Info.Visible = true
            else D.Info.Visible = false end
            
            if Config.Visuals.Snaplines then
                D.Snapline.From = ScreenBottom; D.Snapline.To = Vector2_new(RootPos.X, RootPos.Y)
                D.Snapline.Color = Color3_fromRGB(Config.Visuals.SnaplineColor.R, Config.Visuals.SnaplineColor.G, Config.Visuals.SnaplineColor.B)
                D.Snapline.Visible = true
            else D.Snapline.Visible = false end
            
            if Config.Visuals.HeadCircle and OnScreen then
                D.HeadCircle.Position = Vector2_new(HeadScreenPos.X, HeadScreenPos.Y)
                D.HeadCircle.Radius = screenRadius > 0 and screenRadius or (ScaleFactor * 0.8)
                D.HeadCircle.Color = Color3_fromRGB(Config.Visuals.HeadCircleColor.R, Config.Visuals.HeadCircleColor.G, Config.Visuals.HeadCircleColor.B)
                D.HeadCircle.Visible = true
            else D.HeadCircle.Visible = false end
            
            if Config.Visuals.ViewLine and OnScreen then
                local endPos = Head.Position + (Head.CFrame.LookVector * 5)
                local endScreen, endVis = WTVP(Camera, endPos)
                if endVis then
                    D.ViewLine.From = Vector2_new(HeadScreenPos.X, HeadScreenPos.Y)
                    D.ViewLine.To = Vector2_new(endScreen.X, endScreen.Y)
                    D.ViewLine.Color = Color3_fromRGB(Config.Visuals.ViewLineColor.R, Config.Visuals.ViewLineColor.G, Config.Visuals.ViewLineColor.B)
                    D.ViewLine.Visible = true
                else D.ViewLine.Visible = false end
            else D.ViewLine.Visible = false end
            
            if Config.Visuals.Skeleton then
                local Links = IsR15 and R15_Links or R6_Links
                for idx, link in ipairs(Links) do
                    local p1, p2 = Char:FindFirstChild(link[1]), Char:FindFirstChild(link[2])
                    local lObj = D.Skeleton[idx]
                    if p1 and p2 and lObj then
                        local pos1, vis1 = WTVP(Camera, p1.Position)
                        local pos2, vis2 = WTVP(Camera, p2.Position)
                        if vis1 and vis2 then
                            lObj.From = Vector2_new(pos1.X, pos1.Y); lObj.To = Vector2_new(pos2.X, pos2.Y)
                            lObj.Color = Color3_fromRGB(Config.Visuals.SkeletonColor.R, Config.Visuals.SkeletonColor.G, Config.Visuals.SkeletonColor.B)
                            lObj.Visible = true
                        else lObj.Visible = false end
                    elseif lObj then lObj.Visible = false end
                end
            else for _, line in ipairs(D.Skeleton) do line.Visible = false end end
            
            if Config.Hitbox.ViewHitbox and Config.Hitbox.Enabled and OnScreen and screenRadius > 0 then
                D.HitboxCircle.Position = Vector2_new(HeadScreenPos.X, HeadScreenPos.Y)
                D.HitboxCircle.Radius = screenRadius
                D.HitboxCircle.Color = Color3_fromRGB(Config.Hitbox.HitboxColor.R, Config.Hitbox.HitboxColor.G, Config.Hitbox.HitboxColor.B)
                D.HitboxCircle.Visible = true
            else D.HitboxCircle.Visible = false end
        else
            HideAll(D)
        end
    end
    
    SilentAimTarget = silentBest
    
    -- Movement
    local Hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if Hum then
        if Config.Movement.EnabledWS then Hum.WalkSpeed = Config.Movement.WalkSpeed end
        if Config.Movement.EnabledJP then Hum.JumpPower = Config.Movement.JumpPower end
        if Config.Movement.Bhop then
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) and Hum.FloorMaterial ~= Enum.Material.Air then
                Hum.Jump = true
            end
        end
    end
end

ApplySilentAimHooks()
table.insert(Connections, RunService.RenderStepped:Connect(MainRender))
table.insert(Connections, Players.PlayerRemoving:Connect(ClearDrawing))
