--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║                         Aether Engine                          ║
    ║  Spinbot + Auto-Bhop + No Jump Slowdown + All Features         ║
    ╚══════════════════════════════════════════════════════════════════╝
]]

local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Qanuir/orion-ui/refs/heads/main/source.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
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
local CFrame_new = CFrame.new
local CFrame_lookAt = CFrame.lookAt

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
local SilentAimTarget = nil
local AimLockTarget = nil
local AimLockHeld = false
local lastCameraTick = tick()

-- Mobile button state
local MobileLockActive = false
local MobileGui = nil
local MobileButton = nil

-- Key mapping (EXCLUDES MouseButton1 to prevent camera blocking)
local KeyOptions = {
    "Right Mouse", "Q", "E", "Left Shift", 
    "Left Ctrl", "F", "T", "V", "X", "C", "R", "G", "Z"
}
local KeyMap = {
    ["Right Mouse"] = Enum.UserInputType.MouseButton2,
    ["Q"] = Enum.KeyCode.Q,
    ["E"] = Enum.KeyCode.E,
    ["Left Shift"] = Enum.KeyCode.LeftShift,
    ["Left Ctrl"] = Enum.KeyCode.LeftControl,
    ["F"] = Enum.KeyCode.F,
    ["T"] = Enum.KeyCode.T,
    ["V"] = Enum.KeyCode.V,
    ["X"] = Enum.KeyCode.X,
    ["C"] = Enum.KeyCode.C,
    ["R"] = Enum.KeyCode.R,
    ["G"] = Enum.KeyCode.G,
    ["Z"] = Enum.KeyCode.Z,
}
local CurrentKey = KeyMap["Left Shift"]

-- ==================== CONFIG ====================
local Config = {
    SilentAim = {
        Enabled = false,
        FOV = 100,
        AimPart = "Head",
        WallCheck = true,
        WallBang = false,
        ShowFOV = false,
        FOVColor = Theme.Accent,
    },
    AimLock = {
        AlwaysEnabled = false,
        BindEnabled = true,
        Smoothness = 0.15,
        FOV = 200,
        WallCheck = true,
        ShowFOV = true,
        FOVColor = Color3_fromRGB(255, 0, 128),
        TargetPart = "Head",
        TargetMode = "Crosshair",
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
        Enabled = true,
        Color = Color3_fromRGB(255, 255, 255),
        Transparency = 0.5,
        Thickness = 1,
        NumSides = 60,
    },
    Movement = {
        EnabledWS = false, WalkSpeed = 16,
        EnabledJP = false, JumpPower = 50,
        Bhop = false, BhopKey = Enum.KeyCode.V,
        Spinbot = false, SpinSpeed = 50,
        NoJumpSlowdown = false,
    },
    GunMods = { InfiniteAmmo = false, ReloadInterval = 1.0 },
    Hitbox = {
        Enabled = false,
        HeadSize = 2,
        HitboxColor = {R=255, G=0, B=0},
    }
}

-- ==================== NOTIFICATIONS ====================
local function SendNotification(text)
    OrionLib:MakeNotification({
        Name = "Aether",
        Content = text,
        Image = "rbxassetid://4483345998",
        Time = 3
    })
end

-- ==================== ORION UI ====================
local Window = OrionLib:MakeWindow({
    Name = "Aether",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "AetherConfig"
})

local OrionElements = {}

-- Silent Aim Tab
local SilentAimTab = Window:MakeTab({Name = "Silent Aim", Icon = "rbxassetid://4483345998"})
OrionElements.SilentAimEnabled = SilentAimTab:AddToggle({
    Name = "Enabled",
    Default = Config.SilentAim.Enabled,
    Callback = function(v) Config.SilentAim.Enabled = v end
})
OrionElements.SilentAimWallCheck = SilentAimTab:AddToggle({
    Name = "Wall Check",
    Default = Config.SilentAim.WallCheck,
    Callback = function(v) Config.SilentAim.WallCheck = v end
})
OrionElements.SilentAimWallBang = SilentAimTab:AddToggle({
    Name = "Wall Bang",
    Default = Config.SilentAim.WallBang,
    Callback = function(v) Config.SilentAim.WallBang = v end
})
OrionElements.SilentAimFOV = SilentAimTab:AddSlider({
    Name = "FOV",
    Min = 10,
    Max = 500,
    Default = Config.SilentAim.FOV,
    Increment = 1,
    ValueName = "px",
    Callback = function(v) Config.SilentAim.FOV = v end
})
OrionElements.SilentAimShowFOV = SilentAimTab:AddToggle({
    Name = "Show FOV Circle",
    Default = Config.SilentAim.ShowFOV,
    Callback = function(v) Config.SilentAim.ShowFOV = v end
})
SilentAimTab:AddDropdown({
    Name = "Aim Part",
    Default = Config.SilentAim.AimPart,
    Options = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "Torso"},
    Callback = function(v) Config.SilentAim.AimPart = v end
})

-- Aim Lock Tab
local AimLockTab = Window:MakeTab({Name = "Aim Lock", Icon = "rbxassetid://4483345998"})
OrionElements.AimLockAlways = AimLockTab:AddToggle({
    Name = "Always Enabled (Auto-Lock)",
    Default = Config.AimLock.AlwaysEnabled,
    Callback = function(v)
        Config.AimLock.AlwaysEnabled = v
        if MobileGui then
            MobileGui.Enabled = v
        end
        if not v then
            MobileLockActive = false
            if MobileButton then
                MobileButton.Text = "LOCK OFF"
                MobileButton.BackgroundColor3 = Color3.fromRGB(255, 0, 128)
            end
        end
    end
})
OrionElements.AimLockBind = AimLockTab:AddToggle({
    Name = "Bind Mode (Hold Key)",
    Default = Config.AimLock.BindEnabled,
    Callback = function(v) Config.AimLock.BindEnabled = v end
})
AimLockTab:AddDropdown({
    Name = "Hold Keybind",
    Default = "Left Shift",
    Options = KeyOptions,
    Callback = function(selected)
        CurrentKey = KeyMap[selected]
    end
})
AimLockTab:AddDropdown({
    Name = "Target Mode",
    Default = Config.AimLock.TargetMode,
    Options = {"Crosshair", "Distance"},
    Callback = function(v) Config.AimLock.TargetMode = v end
})
OrionElements.AimLockSmoothness = AimLockTab:AddSlider({
    Name = "Smoothness",
    Min = 0.01,
    Max = 1.0,
    Default = Config.AimLock.Smoothness,
    Increment = 0.01,
    ValueName = "",
    Callback = function(v) Config.AimLock.Smoothness = v end
})
OrionElements.AimLockFOV = AimLockTab:AddSlider({
    Name = "FOV",
    Min = 10,
    Max = 500,
    Default = Config.AimLock.FOV,
    Increment = 1,
    ValueName = "px",
    Callback = function(v) Config.AimLock.FOV = v end
})
OrionElements.AimLockWallCheck = AimLockTab:AddToggle({
    Name = "Wall Check",
    Default = Config.AimLock.WallCheck,
    Callback = function(v) Config.AimLock.WallCheck = v end
})
OrionElements.AimLockShowFOV = AimLockTab:AddToggle({
    Name = "Show FOV Circle",
    Default = Config.AimLock.ShowFOV,
    Callback = function(v) Config.AimLock.ShowFOV = v end
})
AimLockTab:AddDropdown({
    Name = "Target Part",
    Default = Config.AimLock.TargetPart,
    Options = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "Torso"},
    Callback = function(v) Config.AimLock.TargetPart = v end
})

-- Triggerbot Tab
local TrigTab = Window:MakeTab({Name = "Triggerbot", Icon = "rbxassetid://4483345998"})
OrionElements.TrigEnabled = TrigTab:AddToggle({
    Name = "Enabled",
    Default = Config.Triggerbot.Enabled,
    Callback = function(v) Config.Triggerbot.Enabled = v end
})
TrigTab:AddBind({
    Name = "Toggle Key",
    Default = Config.Triggerbot.Key,
    Hold = false,
    Callback = function() end
})
OrionElements.TrigDelay = TrigTab:AddSlider({
    Name = "Delay (Between Clicks)",
    Min = 0.01,
    Max = 1.0,
    Default = Config.Triggerbot.Delay,
    Increment = 0.01,
    ValueName = "s",
    Callback = function(v) Config.Triggerbot.Delay = v end
})
OrionElements.TrigRandom = TrigTab:AddSlider({
    Name = "Randomize (Legit)",
    Min = 0,
    Max = 0.2,
    Default = Config.Triggerbot.Randomization,
    Increment = 0.01,
    ValueName = "",
    Callback = function(v) Config.Triggerbot.Randomization = v end
})
OrionElements.TrigMaxDist = TrigTab:AddSlider({
    Name = "Max Distance",
    Min = 50,
    Max = 3000,
    Default = Config.Triggerbot.MaxDistance,
    Increment = 1,
    ValueName = "m",
    Callback = function(v) Config.Triggerbot.MaxDistance = v end
})

-- Visuals Tab
local VisTab = Window:MakeTab({Name = "Visuals", Icon = "rbxassetid://4483345998"})
OrionElements.VisualsEnabled = VisTab:AddToggle({
    Name = "Enabled",
    Default = Config.Visuals.Enabled,
    Callback = function(v) Config.Visuals.Enabled = v end
})
OrionElements.VisualsTeamCheck = VisTab:AddToggle({
    Name = "Team Check",
    Default = Config.Visuals.TeamCheck,
    Callback = function(v) Config.Visuals.TeamCheck = v end
})
OrionElements.VisualsBox = VisTab:AddToggle({
    Name = "Box",
    Default = Config.Visuals.Box,
    Callback = function(v) Config.Visuals.Box = v end
})
VisTab:AddColorpicker({
    Name = "Box Color",
    Default = Color3.fromRGB(Config.Visuals.BoxColor.R, Config.Visuals.BoxColor.G, Config.Visuals.BoxColor.B),
    Callback = function(Value)
        Config.Visuals.BoxColor.R = math.floor(Value.R * 255)
        Config.Visuals.BoxColor.G = math.floor(Value.G * 255)
        Config.Visuals.BoxColor.B = math.floor(Value.B * 255)
    end
})
OrionElements.VisualsNames = VisTab:AddToggle({
    Name = "Names",
    Default = Config.Visuals.Names,
    Callback = function(v) Config.Visuals.Names = v end
})
VisTab:AddColorpicker({
    Name = "Name Color",
    Default = Color3.fromRGB(Config.Visuals.NameColor.R, Config.Visuals.NameColor.G, Config.Visuals.NameColor.B),
    Callback = function(Value)
        Config.Visuals.NameColor.R = math.floor(Value.R * 255)
        Config.Visuals.NameColor.G = math.floor(Value.G * 255)
        Config.Visuals.NameColor.B = math.floor(Value.B * 255)
    end
})
OrionElements.VisualsInfo = VisTab:AddToggle({
    Name = "Info",
    Default = Config.Visuals.Info,
    Callback = function(v) Config.Visuals.Info = v end
})
VisTab:AddColorpicker({
    Name = "Info Color",
    Default = Color3.fromRGB(Config.Visuals.InfoColor.R, Config.Visuals.InfoColor.G, Config.Visuals.InfoColor.B),
    Callback = function(Value)
        Config.Visuals.InfoColor.R = math.floor(Value.R * 255)
        Config.Visuals.InfoColor.G = math.floor(Value.G * 255)
        Config.Visuals.InfoColor.B = math.floor(Value.B * 255)
    end
})
OrionElements.VisualsSkeleton = VisTab:AddToggle({
    Name = "Skeleton",
    Default = Config.Visuals.Skeleton,
    Callback = function(v) Config.Visuals.Skeleton = v end
})
VisTab:AddColorpicker({
    Name = "Skeleton Color",
    Default = Color3.fromRGB(Config.Visuals.SkeletonColor.R, Config.Visuals.SkeletonColor.G, Config.Visuals.SkeletonColor.B),
    Callback = function(Value)
        Config.Visuals.SkeletonColor.R = math.floor(Value.R * 255)
        Config.Visuals.SkeletonColor.G = math.floor(Value.G * 255)
        Config.Visuals.SkeletonColor.B = math.floor(Value.B * 255)
    end
})
OrionElements.VisualsHeadCircle = VisTab:AddToggle({
    Name = "Head Circle",
    Default = Config.Visuals.HeadCircle,
    Callback = function(v) Config.Visuals.HeadCircle = v end
})
VisTab:AddColorpicker({
    Name = "Head Circle Color",
    Default = Color3.fromRGB(Config.Visuals.HeadCircleColor.R, Config.Visuals.HeadCircleColor.G, Config.Visuals.HeadCircleColor.B),
    Callback = function(Value)
        Config.Visuals.HeadCircleColor.R = math.floor(Value.R * 255)
        Config.Visuals.HeadCircleColor.G = math.floor(Value.G * 255)
        Config.Visuals.HeadCircleColor.B = math.floor(Value.B * 255)
    end
})
OrionElements.VisualsViewLine = VisTab:AddToggle({
    Name = "View Line",
    Default = Config.Visuals.ViewLine,
    Callback = function(v) Config.Visuals.ViewLine = v end
})
VisTab:AddColorpicker({
    Name = "View Line Color",
    Default = Color3.fromRGB(Config.Visuals.ViewLineColor.R, Config.Visuals.ViewLineColor.G, Config.Visuals.ViewLineColor.B),
    Callback = function(Value)
        Config.Visuals.ViewLineColor.R = math.floor(Value.R * 255)
        Config.Visuals.ViewLineColor.G = math.floor(Value.G * 255)
        Config.Visuals.ViewLineColor.B = math.floor(Value.B * 255)
    end
})
OrionElements.VisualsSnaplines = VisTab:AddToggle({
    Name = "Snaplines",
    Default = Config.Visuals.Snaplines,
    Callback = function(v) Config.Visuals.Snaplines = v end
})
VisTab:AddColorpicker({
    Name = "Snapline Color",
    Default = Color3.fromRGB(Config.Visuals.SnaplineColor.R, Config.Visuals.SnaplineColor.G, Config.Visuals.SnaplineColor.B),
    Callback = function(Value)
        Config.Visuals.SnaplineColor.R = math.floor(Value.R * 255)
        Config.Visuals.SnaplineColor.G = math.floor(Value.G * 255)
        Config.Visuals.SnaplineColor.B = math.floor(Value.B * 255)
    end
})
OrionElements.VisualsRenderDistance = VisTab:AddSlider({
    Name = "Render Distance",
    Min = 100,
    Max = 5000,
    Default = Config.Visuals.RenderDistance,
    Increment = 1,
    ValueName = "m",
    Callback = function(v) Config.Visuals.RenderDistance = v end
})

-- Movement Tab
local MoveTab = Window:MakeTab({Name = "Movement", Icon = "rbxassetid://4483345998"})
OrionElements.MoveEnabledWS = MoveTab:AddToggle({
    Name = "Enable WalkSpeed",
    Default = Config.Movement.EnabledWS,
    Callback = function(v) Config.Movement.EnabledWS = v end
})
OrionElements.MoveWalkSpeed = MoveTab:AddSlider({
    Name = "WalkSpeed",
    Min = 16,
    Max = 500,
    Default = Config.Movement.WalkSpeed,
    Increment = 1,
    ValueName = "",
    Callback = function(v) Config.Movement.WalkSpeed = v end
})
OrionElements.MoveEnabledJP = MoveTab:AddToggle({
    Name = "Enable JumpPower",
    Default = Config.Movement.EnabledJP,
    Callback = function(v) Config.Movement.EnabledJP = v end
})
OrionElements.MoveJumpPower = MoveTab:AddSlider({
    Name = "JumpPower",
    Min = 50,
    Max = 250,
    Default = Config.Movement.JumpPower,
    Increment = 1,
    ValueName = "",
    Callback = function(v) Config.Movement.JumpPower = v end
})
OrionElements.MoveBhop = MoveTab:AddToggle({
    Name = "Auto-Bhop",
    Default = Config.Movement.Bhop,
    Callback = function(v) Config.Movement.Bhop = v end
})
MoveTab:AddBind({
    Name = "Bhop Keybind",
    Default = Config.Movement.BhopKey,
    Hold = false,
    Callback = function() end
})

-- Spinbot
OrionElements.MoveSpinbot = MoveTab:AddToggle({
    Name = "Spinbot",
    Default = Config.Movement.Spinbot,
    Callback = function(v) Config.Movement.Spinbot = v end
})
OrionElements.MoveSpinSpeed = MoveTab:AddSlider({
    Name = "Spin Speed",
    Min = 1,
    Max = 200,
    Default = Config.Movement.SpinSpeed,
    Increment = 1,
    ValueName = "",
    Callback = function(v) Config.Movement.SpinSpeed = v end
})

-- No Jump Slowdown
OrionElements.MoveNoJumpSlowdown = MoveTab:AddToggle({
    Name = "No Jump Slowdown",
    Default = Config.Movement.NoJumpSlowdown,
    Callback = function(v) Config.Movement.NoJumpSlowdown = v end
})

-- Gun Mods Tab
local GunModsTab = Window:MakeTab({Name = "Gun Mods", Icon = "rbxassetid://4483345998"})
OrionElements.InfAmmo = GunModsTab:AddToggle({
    Name = "Infinite Ammo",
    Default = Config.GunMods.InfiniteAmmo,
    Callback = function(v) Config.GunMods.InfiniteAmmo = v end
})
OrionElements.ReloadInterval = GunModsTab:AddSlider({
    Name = "Reload Interval (s)",
    Min = 0.1,
    Max = 5.0,
    Default = Config.GunMods.ReloadInterval,
    Increment = 0.1,
    ValueName = "s",
    Callback = function(v) Config.GunMods.ReloadInterval = v end
})

-- Hitbox Tab (View Hitbox removed)
local HitboxTab = Window:MakeTab({Name = "Hitbox", Icon = "rbxassetid://4483345998"})
OrionElements.HitboxEnabled = HitboxTab:AddToggle({
    Name = "Expand Hitbox",
    Default = Config.Hitbox.Enabled,
    Callback = function(v) Config.Hitbox.Enabled = v end
})
OrionElements.HitboxSize = HitboxTab:AddSlider({
    Name = "Size Multiplier",
    Min = 1,
    Max = 10,
    Default = Config.Hitbox.HeadSize,
    Increment = 0.1,
    ValueName = "x",
    Callback = function(v) Config.Hitbox.HeadSize = v end
})
HitboxTab:AddColorpicker({
    Name = "Hitbox Color",
    Default = Color3.fromRGB(Config.Hitbox.HitboxColor.R, Config.Hitbox.HitboxColor.G, Config.Hitbox.HitboxColor.B),
    Callback = function(Value)
        Config.Hitbox.HitboxColor.R = math.floor(Value.R * 255)
        Config.Hitbox.HitboxColor.G = math.floor(Value.G * 255)
        Config.Hitbox.HitboxColor.B = math.floor(Value.B * 255)
    end
})

-- Settings Tab
local SetTab = Window:MakeTab({Name = "Settings", Icon = "rbxassetid://4483345998"})
SetTab:AddButton({
    Name = "UNLOAD THE SCRIPT",
    Callback = function()
        ScriptRunning = false
        for _, conn in pairs(Connections) do conn:Disconnect() end
        table.clear(Connections)
        CleanupWalkSpeedHooks()
        CleanupHitboxHooks()
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
        if hum then hum.WalkSpeed = OriginalWalkSpeed end
        for plr, data in pairs(ESP_Store) do
            pcall(function()
                data.Box:Remove(); data.BoxOutline:Remove(); data.Name:Remove()
                data.Info:Remove(); data.HeadCircle:Remove(); data.ViewLine:Remove()
                data.Snapline:Remove()
                for _, line in pairs(data.Skeleton) do line:Remove() end
            end)
        end
        table.clear(ESP_Store)
        if SilentAimFOVCircle then SilentAimFOVCircle:Remove() end
        if AimLockFOVCircle then AimLockFOVCircle:Remove() end
        if MobileGui then MobileGui:Destroy() end
        pcall(function() RunService:UnbindFromRenderStep("AimLockCamera") end)
        OrionLib:Destroy()
    end
})

OrionLib:Init()

-- ==================== MOBILE TOGGLE BUTTON ====================
MobileGui = Instance.new("ScreenGui")
MobileGui.Name = "AimLockMobileGui"
MobileGui.ResetOnSpawn = false
MobileGui.Enabled = Config.AimLock.AlwaysEnabled
MobileGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

MobileButton = Instance.new("TextButton")
MobileButton.Name = "LockToggle"
MobileButton.Text = "LOCK OFF"
MobileButton.Size = UDim2.new(0, 110, 0, 55)
MobileButton.Position = UDim2.new(1, -130, 1, -130)
MobileButton.BackgroundColor3 = Color3.fromRGB(255, 0, 128)
MobileButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MobileButton.Font = Enum.Font.GothamBold
MobileButton.TextSize = 16
MobileButton.Parent = MobileGui
MobileButton.AutoButtonColor = false

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 10)
BtnCorner.Parent = MobileButton

local BtnStroke = Instance.new("UIStroke")
BtnStroke.Color = Color3.fromRGB(255, 255, 255)
BtnStroke.Thickness = 2
BtnStroke.Parent = MobileButton

-- Drag + Tap logic
local isDragging = false
local dragStartPos, buttonStartPos

MobileButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = false
        dragStartPos = input.Position
        buttonStartPos = MobileButton.Position
        
        local connChanged, connInputChanged
        
        connChanged = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                if not isDragging then
                    MobileLockActive = not MobileLockActive
                    MobileButton.Text = MobileLockActive and "LOCK ON" or "LOCK OFF"
                    MobileButton.BackgroundColor3 = MobileLockActive and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 0, 128)
                end
                connChanged:Disconnect()
                if connInputChanged then connInputChanged:Disconnect() end
            end
        end)
        
        connInputChanged = UserInputService.InputChanged:Connect(function(changedInput)
            if changedInput == input then
                local delta = (input.Position - dragStartPos).Magnitude
                if delta > 5 then
                    isDragging = true
                end
                if isDragging then
                    local dPos = input.Position - dragStartPos
                    MobileButton.Position = UDim2.new(
                        buttonStartPos.X.Scale, buttonStartPos.X.Offset + dPos.X,
                        buttonStartPos.Y.Scale, buttonStartPos.Y.Offset + dPos.Y
                    )
                end
            end
        end)
    end
end)

-- ==================== KEYBIND HANDLING ====================
local function InputMatches(input, key)
    if typeof(key) == "EnumItem" then
        if key.EnumType == Enum.KeyCode then
            return input.KeyCode == key
        elseif key.EnumType == Enum.UserInputType then
            return input.UserInputType == key
        end
    end
    return false
end

table.insert(Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if InputMatches(input, CurrentKey) then
        AimLockHeld = true
    end

    if input.KeyCode == Config.Triggerbot.Key then
        Config.Triggerbot.Enabled = not Config.Triggerbot.Enabled
        if Config.Triggerbot.Enabled then
            SendNotification("Triggerbot: ENABLED")
        else
            SendNotification("Triggerbot: DISABLED")
        end
    end

    if input.KeyCode == Config.Movement.BhopKey then
        Config.Movement.Bhop = not Config.Movement.Bhop
        if Config.Movement.Bhop then
            SendNotification("Auto-Bhop: ENABLED")
        else
            SendNotification("Auto-Bhop: DISABLED")
        end
    end
end))

table.insert(Connections, UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if InputMatches(input, CurrentKey) then
        AimLockHeld = false
    end
end))

-- ==================== RAYCAST PARAMS ====================
local GlobalRaycastParams = RaycastParams.new()
GlobalRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
GlobalRaycastParams.IgnoreWater = true

-- FOV circles
local SilentAimFOVCircle = Drawing.new("Circle")
SilentAimFOVCircle.Visible = Config.SilentAim.ShowFOV
SilentAimFOVCircle.Thickness = Config.FOV_Circle.Thickness
SilentAimFOVCircle.Color = Config.SilentAim.FOVColor
SilentAimFOVCircle.Transparency = Config.FOV_Circle.Transparency
SilentAimFOVCircle.Filled = false
SilentAimFOVCircle.NumSides = Config.FOV_Circle.NumSides

local AimLockFOVCircle = Drawing.new("Circle")
AimLockFOVCircle.Visible = false
AimLockFOVCircle.Thickness = Config.FOV_Circle.Thickness
AimLockFOVCircle.Color = Config.AimLock.FOVColor
AimLockFOVCircle.Transparency = Config.FOV_Circle.Transparency
AimLockFOVCircle.Filled = false
AimLockFOVCircle.NumSides = Config.FOV_Circle.NumSides

-- ==================== SILENT AIM HOOKS ====================
local function ApplySilentAimHooks()
    local rawmt = getrawmetatable and getrawmetatable(game)
    local setreadonly = setreadonly or make_writeable

    if rawmt and setreadonly then
        pcall(function()
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

-- ==================== HELPERS ====================
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

-- ==================== ESP DRAWING ====================
local function InitializeDrawing(plr)
    if ESP_Store[plr] then return end
    local Objects = {
        BoxOutline = Drawing.new("Square"), Box = Drawing.new("Square"), Name = Drawing.new("Text"),
        Info = Drawing.new("Text"), HeadCircle = Drawing.new("Circle"), ViewLine = Drawing.new("Line"),
        Snapline = Drawing.new("Line"), Skeleton = {}
    }
    Objects.BoxOutline.Visible = false; Objects.BoxOutline.Filled = false; Objects.BoxOutline.Thickness = 3; Objects.BoxOutline.Color = Color3_fromRGB(0,0,0); Objects.BoxOutline.Transparency = 0.5
    Objects.Box.Visible = false; Objects.Box.Filled = false; Objects.Box.Thickness = 1
    Objects.Name.Visible = false; Objects.Name.Center = true; Objects.Name.Outline = true; Objects.Name.Font = 2
    Objects.Info.Visible = false; Objects.Info.Center = true; Objects.Info.Outline = true; Objects.Info.Font = 2
    Objects.HeadCircle.Visible = false; Objects.HeadCircle.Filled = false; Objects.HeadCircle.Thickness = 1.5
    Objects.ViewLine.Visible = false; Objects.ViewLine.Thickness = 1
    Objects.Snapline.Visible = false; Objects.Snapline.Thickness = 1.5
    for i=1,16 do local Line = Drawing.new("Line"); Line.Visible = false; Line.Thickness = 1.5; table.insert(Objects.Skeleton, Line) end
    ESP_Store[plr] = Objects
end
local function HideAll(D)
    D.Box.Visible = false; D.BoxOutline.Visible = false; D.Name.Visible = false; D.Info.Visible = false
    D.HeadCircle.Visible = false; D.ViewLine.Visible = false; D.Snapline.Visible = false
    for _, line in ipairs(D.Skeleton) do line.Visible = false end
end
local function ClearDrawing(plr)
    if not ESP_Store[plr] then return end
    local D = ESP_Store[plr]
    pcall(function()
        D.Box:Remove(); D.BoxOutline:Remove(); D.Name:Remove(); D.Info:Remove(); D.HeadCircle:Remove()
        D.ViewLine:Remove(); D.Snapline:Remove()
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

-- ==================== TRIGGERBOT ====================
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

-- ==================== GUN MODS (FIXED - no hanging) ====================
task.spawn(function()
    while ScriptRunning do
        if Config.GunMods.InfiniteAmmo then
            pcall(function()
                local ReplicatedStorage = game:GetService("ReplicatedStorage")
                local Events = ReplicatedStorage:FindFirstChild("Events")
                if Events then
                    local Weapons = Events:FindFirstChild("Weapons")
                    if Weapons then
                        Weapons:FireServer("Reload")
                    end
                end
            end)
            task.wait(Config.GunMods.ReloadInterval)
        else
            task.wait(0.5)
        end
    end
end)

-- ==================== HITBOX (FIXED - no collision freeze) ====================
local OriginalHeadData = {} -- stores {Size, Massless, CanCollide} per head instance
local HitboxConnections = {}

local function CleanupHitboxHooks()
    for plr, conn in pairs(HitboxConnections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(HitboxConnections)
end

local function ExpandHitbox(head)
    if not head or not Config.Hitbox.Enabled then return end
    if not OriginalHeadData[head] then
        OriginalHeadData[head] = {
            Size = head.Size,
            Massless = head.Massless,
            CanCollide = head.CanCollide
        }
    end
    local targetSize = OriginalHeadData[head].Size * Config.Hitbox.HeadSize
    if head.Size ~= targetSize then
        head.Size = targetSize
    end
    if not head.Massless then
        head.Massless = true
    end
    if head.CanCollide then
        head.CanCollide = false
    end
end

local function RestoreHitbox(head)
    if not head or not OriginalHeadData[head] then return end
    local data = OriginalHeadData[head]
    pcall(function()
        head.Size = data.Size
        head.Massless = data.Massless
        head.CanCollide = data.CanCollide
    end)
    OriginalHeadData[head] = nil
end

local function SetupHitboxForPlayer(plr)
    if plr == LocalPlayer then return end
    if HitboxConnections[plr] then
        pcall(function() HitboxConnections[plr]:Disconnect() end)
        HitboxConnections[plr] = nil
    end
    
    local char = plr.Character
    if char then
        local head = char:FindFirstChild("Head")
        if head then
            ExpandHitbox(head)
        end
    end
    
    HitboxConnections[plr] = plr.CharacterAdded:Connect(function(newChar)
        task.wait(0.3)
        if not ScriptRunning then return end
        local newHead = newChar:FindFirstChild("Head")
        if newHead then
            ExpandHitbox(newHead)
        end
    end)
end

-- ==================== PLAYER LIFECYCLE ====================
local function onPlayerAdded(plr)
    if plr == LocalPlayer then return end
    local function onCharAdded(char)
        task.wait(0.5)
        SetupHitboxForPlayer(plr)
        InitializeDrawing(plr)
    end
    local function onCharRemoving(char)
        ClearDrawing(plr)
        local head = char:FindFirstChild("Head")
        if head then
            RestoreHitbox(head)
        end
    end
    plr.CharacterAdded:Connect(onCharAdded)
    plr.CharacterRemoving:Connect(onCharRemoving)
    if plr.Character then
        onCharAdded(plr.Character)
    end
end

for _, plr in ipairs(Players:GetPlayers()) do
    onPlayerAdded(plr)
end
table.insert(Connections, Players.PlayerAdded:Connect(onPlayerAdded))
table.insert(Connections, Players.PlayerRemoving:Connect(function(plr)
    ClearDrawing(plr)
    local char = plr.Character
    if char then
        local head = char:FindFirstChild("Head")
        if head then
            RestoreHitbox(head)
        end
    end
    if HitboxConnections[plr] then
        pcall(function() HitboxConnections[plr]:Disconnect() end)
        HitboxConnections[plr] = nil
    end
end))

-- ==================== WALKSPEED PROPERTY HOOK ====================
local OriginalWalkSpeed = 16
local WalkSpeedHooks = {}

local function HookWalkSpeed(hum)
    if not hum or WalkSpeedHooks[hum] then return end
    WalkSpeedHooks[hum] = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if Config.Movement.EnabledWS and hum.WalkSpeed ~= Config.Movement.WalkSpeed then
            hum.WalkSpeed = Config.Movement.WalkSpeed
        end
    end)
end

local function CleanupWalkSpeedHooks()
    for hum, conn in pairs(WalkSpeedHooks) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(WalkSpeedHooks)
end

-- Hook current humanoid if already in game
if LocalPlayer.Character then
    local hum = LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
    if hum then 
        OriginalWalkSpeed = hum.WalkSpeed
        HookWalkSpeed(hum) 
    end
end

-- Hook future humanoids after respawn
table.insert(Connections, LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 2)
    if hum then 
        OriginalWalkSpeed = hum.WalkSpeed
        HookWalkSpeed(hum) 
    end
end))

-- ==================== AIM LOCK ACTIVE CHECK ====================
local function IsLockActive()
    local mobileActive = Config.AimLock.AlwaysEnabled and MobileLockActive
    local bindActive = Config.AimLock.BindEnabled and AimLockHeld
    return mobileActive or bindActive
end

-- ==================== MAIN RENDER LOOP ====================
local function MainRender()
    if not ScriptRunning then return end

    local MouseLoc = UserInputService:GetMouseLocation()
    local ViewportSize = Camera.ViewportSize
    local ScreenBottom = Vector2_new(ViewportSize.X / 2, ViewportSize.Y)
    local ScreenCenter = Vector2_new(ViewportSize.X / 2, ViewportSize.Y / 2)

    -- Update FOV circles
    SilentAimFOVCircle.Position = MouseLoc
    SilentAimFOVCircle.Radius = Config.SilentAim.FOV
    SilentAimFOVCircle.Visible = Config.SilentAim.ShowFOV

    AimLockFOVCircle.Position = ScreenCenter
    AimLockFOVCircle.Radius = Config.AimLock.FOV
    AimLockFOVCircle.Visible = Config.AimLock.ShowFOV

    local silentBest = nil
    local silentBestDist = Config.SilentAim.FOV

    local aimLockBest = nil
    local aimLockBestDist = Config.AimLock.FOV

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

        local SilentPart = Char:FindFirstChild(Config.SilentAim.AimPart) or Head
        local LockPart = Char:FindFirstChild(Config.AimLock.TargetPart) or Head

        local HeadScreenPos, OnScreen = WTVP(Camera, Head.Position)
        local SilentScreenPos, SilentOnScreen = WTVP(Camera, SilentPart.Position)
        local LockScreenPos, LockOnScreen = WTVP(Camera, LockPart.Position)

        local baseRadius = math.max(Head.Size.X, Head.Size.Y, Head.Size.Z) / 2
        local expandedRadius = baseRadius * Config.Hitbox.HeadSize
        local screenRadius = 0
        
        if OnScreen then
            local worldRadius = Config.Hitbox.Enabled and expandedRadius or baseRadius
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
        if Config.Visuals.Enabled or Config.SilentAim.Enabled or IsLockActive() then
            IsVisible = CheckVisibility(Head, Char)
        end

        -- Silent aim target selection
        if Config.SilentAim.Enabled and SilentOnScreen then
            local magToCenter = (Vector2_new(SilentScreenPos.X, SilentScreenPos.Y) - MouseLoc).Magnitude
            local distToCircle = math.max(0, magToCenter - screenRadius)
            if distToCircle < silentBestDist then
                local passWall = true
                if Config.SilentAim.WallCheck and not Config.SilentAim.WallBang then
                    passWall = IsVisible
                end
                if passWall then
                    silentBest = SilentPart
                    silentBestDist = distToCircle
                end
            end
        end

        -- Aim Lock target selection
        if IsLockActive() and LockOnScreen then
            local magToCenter = (Vector2_new(LockScreenPos.X, LockScreenPos.Y) - ScreenCenter).Magnitude
            local distToCircle = math.max(0, magToCenter - screenRadius)
            if distToCircle < aimLockBestDist then
                local passWall = true
                if Config.AimLock.WallCheck then
                    passWall = IsVisible
                end
                if passWall then
                    aimLockBest = LockPart
                    aimLockBestDist = distToCircle
                end
            end
        end

        -- ESP drawing
        if Config.Visuals.Enabled then
            local IsR15 = (Char:FindFirstChild("UpperTorso") ~= nil)
            
            -- ==================== FIXED BOX SIZING ====================
            -- Use actual screen-projected height instead of magic 1000/Dist formula
            local topPart = Char:FindFirstChild("Head")
            local bottomPart = IsR15 and Char:FindFirstChild("LowerTorso") or Char:FindFirstChild("Torso")
            if not bottomPart then bottomPart = Root end
            
            local topPos, topVis = WTVP(Camera, topPart.Position + Vector3.new(0, 0.5, 0))
            local bottomPos, bottomVis = WTVP(Camera, bottomPart.Position - Vector3.new(0, 2, 0))
            
            local BoxSizeY, BoxSizeX, BoxPos
            if topVis and bottomVis then
                BoxSizeY = math.abs(bottomPos.Y - topPos.Y)
                BoxSizeX = BoxSizeY * 0.45 -- width is ~45% of height for humanoid proportions
                BoxPos = Vector2_new(RootPos.X - BoxSizeX / 2, topPos.Y)
            else
                -- Fallback to old method if projection fails
                local ScaleFactor = 1000 / Dist
                BoxSizeY = (IsR15 and 5.5 or 5.0) * ScaleFactor
                BoxSizeX = 3.5 * ScaleFactor
                BoxPos = Vector2_new(RootPos.X - BoxSizeX / 2, RootPos.Y - BoxSizeY / 2)
            end
            -- Clamp box size to prevent insanity on extreme FOVs
            BoxSizeX = math.clamp(BoxSizeX, 10, 400)
            BoxSizeY = math.clamp(BoxSizeY, 20, 600)
            -- ==========================================================

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
        else
            HideAll(D)
        end
    end

    SilentAimTarget = silentBest
    AimLockTarget = aimLockBest

    -- Movement (JumpPower only — WalkSpeed handled in Heartbeat)
    local Hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if Hum then
        if Config.Movement.EnabledJP then Hum.JumpPower = Config.Movement.JumpPower end
    end
end

-- ==================== WALKSPEED + BHOP + SPINBOT + HITBOX + NO JUMP SLOWDOWN HEARTBEAT ====================
table.insert(Connections, RunService.Heartbeat:Connect(function()
    if not ScriptRunning then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    local hum = char:FindFirstChildWhichIsA("Humanoid")
    if not hum then return end
    
    -- WalkSpeed (unconditional set + property hook prevents game from reverting)
    if Config.Movement.EnabledWS then
        hum.WalkSpeed = Config.Movement.WalkSpeed
    end
    
    -- No Jump Slowdown
    if Config.Movement.NoJumpSlowdown then
        if hum.FloorMaterial == Enum.Material.Air then
            local targetSpeed = Config.Movement.EnabledWS and Config.Movement.WalkSpeed or OriginalWalkSpeed
            hum.WalkSpeed = targetSpeed
        end
    end
    
    -- Auto-Bhop
    if Config.Movement.Bhop then
        if hum.FloorMaterial ~= Enum.Material.Air then
            hum.Jump = true
        end
    end
    
    -- Spinbot
    if Config.Movement.Spinbot and char:FindFirstChild("HumanoidRootPart") then
        local hrp = char.HumanoidRootPart
        local spinAmount = Config.Movement.SpinSpeed * 0.1
        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(spinAmount), 0)
    end
    
    -- ==================== HITBOX EXPANDER (COLLISION-FREE) ====================
    if Config.Hitbox.Enabled then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == LocalPlayer then continue end
            local targetChar = plr.Character
            if not targetChar then continue end
            local head = targetChar:FindFirstChild("Head")
            if not head then continue end
            
            ExpandHitbox(head)
        end
    else
        -- Restore all expanded hitboxes when disabled
        for head, _ in pairs(OriginalHeadData) do
            if typeof(head) == "Instance" and head:IsA("BasePart") then
                RestoreHitbox(head)
            end
        end
        table.clear(OriginalHeadData)
    end
end))

-- ==================== AIM LOCK CAMERA (PRIORITY 999) ====================
RunService:BindToRenderStep("AimLockCamera", 999, function()
    if not ScriptRunning then return end
    
    if IsLockActive() and AimLockTarget then
        local targetPos = AimLockTarget.Position
        local currentCF = Camera.CFrame
        local targetCF = CFrame_lookAt(currentCF.Position, targetPos)
        
        local now = tick()
        local dt = now - lastCameraTick
        lastCameraTick = now
        dt = math.clamp(dt, 0.0001, 0.1)
        
        local speed = Config.AimLock.Smoothness * 100
        local alpha = 1 - math.exp(-speed * dt)
        alpha = math.clamp(alpha, 0, 1)
        
        if Config.AimLock.Smoothness >= 0.99 then
            alpha = 1
        end
        
        Camera.CFrame = currentCF:Lerp(targetCF, alpha)
    else
        lastCameraTick = tick()
    end
end)

ApplySilentAimHooks()
table.insert(Connections, RunService.RenderStepped:Connect(MainRender))
