-- R Hub.lua — Roblox executor script (Synapse/Fluxus/Krnl-class)
-- Egg Heist module: instant grab / mutation magnet / local invis
-- Loadstring: loadstring(game:HttpGet("<your-raw-url>"))()

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer      = Players.LocalPlayer

---------------------------------------------------------------------
-- CONFIG
---------------------------------------------------------------------
local CONFIG = {
    autoGrab      = true,
    grabRadius    = 60,
    grabInterval  = 0.05,
    mutationBoost = true,
    mutationIds   = { "Gold", "Rainbow", "Shiny", "Galaxy" },
    invisEnabled  = false,
}

---------------------------------------------------------------------
-- PANEL
---------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.fromOffset(220, 170)
Frame.Position = UDim2.fromOffset(40, 40)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 8)
Corner.Parent = Frame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundTransparency = 1
Title.Text = "R HUB"
Title.TextColor3 = Color3.fromRGB(255, 210, 90)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.Parent = Frame

local function makeButton(text, y, color, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -20, 0, 32)
    b.Position = UDim2.fromOffset(10, y)
    b.BackgroundColor3 = color
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamSemibold
    b.TextSize = 13
    b.Parent = Frame
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = b
    b.MouseButton1Click:Connect(cb)
    return b
end

---------------------------------------------------------------------
-- INSTANT GRAB
---------------------------------------------------------------------
local function collectEgg(egg)
    local remote = ReplicatedStorage:FindFirstChild("CollectEgg")
        or ReplicatedStorage:FindFirstChild("EggService")
        or ReplicatedStorage:FindFirstChild("HatchEgg")
    if remote and remote:IsA("RemoteEvent") then
        pcall(function()
            remote:FireServer(egg, CONFIG.mutationIds[math.random(#CONFIG.mutationIds)])
        end)
    end
    local prompt = egg:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then
        pcall(function() fireproximityprompt(prompt) end)
    end
end

local function sweepEggs()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:lower():find("egg") then
            local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if part and (part.Position - root.Position).Magnitude <= CONFIG.grabRadius then
                collectEgg(obj)
            end
        end
    end
end

---------------------------------------------------------------------
-- MUTATION BOOST
---------------------------------------------------------------------
local function mutationHook()
    if not CONFIG.mutationBoost then return end
    for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
        if remote:IsA("RemoteEvent")
            and (remote.Name:lower():find("hatch") or remote.Name:lower():find("egg")) then
            local old
            old = hookfunction(remote.FireServer, function(self, ...)
                local args = { ... }
                table.insert(args, CONFIG.mutationIds[math.random(#CONFIG.mutationIds)])
                return old(self, table.unpack(args))
            end)
        end
    end
end

---------------------------------------------------------------------
-- INVISIBILITY
---------------------------------------------------------------------
local invisConn
local function setInvis(state)
    CONFIG.invisEnabled = state
    if invisConn then invisConn:Disconnect(); invisConn = nil end
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = state and 1 or 0
        elseif part:IsA("Decal") then
            part.Transparency = state and 1 or 0
        end
    end
    if state then
        invisConn = RunService.RenderStepped:Connect(function()
            local c = LocalPlayer.Character
            if not c then return end
            for _, part in ipairs(c:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.LocalTransparencyModifier = 1
                elseif part:IsA("Decal") then
                    part.Transparency = 1
                end
            end
        end)
    end
end

---------------------------------------------------------------------
-- BUTTONS
---------------------------------------------------------------------
makeButton("INSTANT GRAB", 40, Color3.fromRGB(60, 140, 220), function()
    CONFIG.autoGrab = not CONFIG.autoGrab
    if CONFIG.autoGrab then
        task.spawn(function()
            while CONFIG.autoGrab do
                sweepEggs()
                task.wait(CONFIG.grabInterval)
            end
        end)
    end
end)

makeButton("MUTATION MAGNET: ON", 80, Color3.fromRGB(180, 120, 40), function(self)
    CONFIG.mutationBoost = not CONFIG.mutationBoost
    self.Text = "MUTATION MAGNET: " .. (CONFIG.mutationBoost and "ON" or "OFF")
    if CONFIG.mutationBoost then mutationHook() end
end)

makeButton("INVIS: OFF", 120, Color3.fromRGB(80, 80, 90), function(self)
    setInvis(not CONFIG.invisEnabled)
    self.Text = "INVIS: " .. (CONFIG.invisEnabled and "ON" or "OFF")
end)

---------------------------------------------------------------------
-- BOOT
---------------------------------------------------------------------
task.spawn(function()
    while CONFIG.autoGrab do
        sweepEggs()
        task.wait(CONFIG.grabInterval)
    end
end)
mutationHook()
print("[R Hub] loaded — egg heist panel up")
