-- ╔══════════════════════════════════════════════════════════════╗
-- ║        UNIONSAL SCRIPT HUB — Blush Canyon (blush.lua)        ║
-- ║        Game  : Blush Canyon (PlaceId: 3218570640)            ║
-- ║        Module: Auto Win, Blatant Speed, Safe Fall & TP       ║
-- ║        Design: Glass Bento dark purple (matches main.lua)    ║
-- ╚══════════════════════════════════════════════════════════════╝

getgenv()._UNIONSAL_CHILD_LOADED = true
getgenv()._NEMESIS_CHILD_LOADED = true

local SCRIPT_BASE_URL = "https://raw.githubusercontent.com/hendrawansuinto571-glitch/script/main/"

-- Load Nemesis UI Library dari main.lua (Memory / File / GitHub)
local Unionsal = getgenv().UnionsalHub or getgenv().NemesisHub
if not Unionsal then
    local okLocal, resLocal = pcall(function()
        return loadstring(readfile("main.lua"))()
    end)
    if okLocal and resLocal then
        Unionsal = resLocal
    else
        local okWeb, resWeb = pcall(function()
            return loadstring(game:HttpGet(SCRIPT_BASE_URL .. "main.lua"))()
        end)
        if okWeb and resWeb then
            Unionsal = resWeb
        else
            warn("[Unionsal Hub] Gagal memuat main.lua")
            return
        end
    end
end

local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local UserInputService= game:GetService("UserInputService")
local LocalPlayer     = Players.LocalPlayer

local function getCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end
local function getHumanoid()
    local c = getCharacter()
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getRootPart()
    local c = getCharacter()
    return c and c:FindFirstChild("HumanoidRootPart")
end

-- ═══════════════════════════════════════════
--  WINDOW UTAMA (NEMESIS GLASS BENTO)
-- ═══════════════════════════════════════════
local Window = Unionsal:CreateWindow({
    Name       = "unionsal",
    Subtitle   = ".gg/unionsal",
    GameName   = "Blush Canyon",
    ScriptName = "blush.lua",
    Version    = "v1.3",
})

-- ═══════════════════════════════════════════
--  AUTO WIN & WIN LOCATOR SYSTEM
-- ═══════════════════════════════════════════
local WinSystem = {
    CustomWinCFrame    = nil,
    AutoWinRunning     = false,
    BlatantMode        = false,
    LoopDelay          = 0.3,
    SpawnCFrame        = nil,
    LastDetectedName   = "Belum terdeteksi",
}

local IGNORE_KEYWORDS = {
    "teleportpart", "spawn", "spawnlocation", "baseplate", "terrain",
    "kill", "lava", "void", "dead", "fall", "reset", "hazard", "trap", "hurt"
}

local function isIgnoredPart(name)
    local lower = string.lower(name)
    for _, ig in ipairs(IGNORE_KEYWORDS) do
        if string.find(lower, ig) then
            return true
        end
    end
    return false
end

local function getSpawnPosition()
    if WinSystem.SpawnCFrame then
        return WinSystem.SpawnCFrame.Position
    end
    local spawnObj = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
    if spawnObj then
        return spawnObj.Position
    end
    return Vector3.new(0, 5, 0)
end

local function findWinPart()
    if WinSystem.CustomWinCFrame then
        return nil, WinSystem.CustomWinCFrame, "Titik Kustom Pengguna"
    end

    local candidatePart = nil
    local candidateCFrame = nil
    local candidateName = nil

    -- 1. Scan folder stages / checkpoints
    for _, folderName in ipairs({"Checkpoints", "Stages", "Stage", "Spawns"}) do
        local f = workspace:FindFirstChild(folderName, true)
        if f then
            local highestNumber = -1
            local highestPart = nil
            for _, item in ipairs(f:GetChildren()) do
                local num = tonumber(string.match(item.Name, "%d+"))
                if num and num > highestNumber then
                    local p = (item:IsA("BasePart") and item) or item:FindFirstChildWhichIsA("BasePart")
                    if p and not isIgnoredPart(p.Name) then
                        highestNumber = num
                        highestPart = p
                    end
                end
            end
            if highestPart and highestNumber > 1 then
                candidatePart = highestPart
                candidateCFrame = highestPart.CFrame + Vector3.new(0, 4, 0)
                candidateName = folderName .. " [Stage " .. tostring(highestNumber) .. "]"
                break
            end
        end
    end

    -- 2. Scan nama part berawalan / mengandung kata kunci Win/Goal
    if not candidateCFrame then
        for _, keyword in ipairs({"winpad", "finishpad", "endpad", "winner", "trophy", "finish", "goal", "badge"}) do
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") and not isIgnoredPart(obj.Name) then
                    if string.find(string.lower(obj.Name), keyword) then
                        candidatePart = obj
                        candidateCFrame = obj.CFrame + Vector3.new(0, 4, 0)
                        candidateName = obj.Name
                        break
                    end
                end
            end
            if candidateCFrame then break end
        end
    end

    -- 3. Platform terjauh dari spawn
    if not candidateCFrame then
        local spawnPos = getSpawnPosition()
        local maxDist = 0
        local furthestPart = nil
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Anchored and not isIgnoredPart(obj.Name) then
                if obj.Size.X >= 2 and obj.Size.Z >= 2 and obj.Size.Y >= 0.2 then
                    local isCharacterPart = false
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player.Character and obj:IsDescendantOf(player.Character) then
                            isCharacterPart = true
                            break
                        end
                    end
                    if not isCharacterPart then
                        local dist = (obj.Position - spawnPos).Magnitude
                        if dist > 120 and dist > maxDist then
                            maxDist = dist
                            furthestPart = obj
                        end
                    end
                end
            end
        end
        if furthestPart then
            candidatePart = furthestPart
            candidateCFrame = furthestPart.CFrame + Vector3.new(0, 4, 0)
            candidateName = string.format("Ujung Obby: %s (%.0f studs)", furthestPart.Name, maxDist)
        end
    end

    if candidateCFrame then
        WinSystem.LastDetectedName = candidateName or "Titik Win Terdeteksi"
        return candidatePart, candidateCFrame, WinSystem.LastDetectedName
    end

    return nil, nil, "Tidak Ditemukan"
end

-- ═══════════════════════════════════════════
--  DEVICE ID RESOLVER & CONFIG MANAGER
-- ═══════════════════════════════════════════
local function getClientDeviceId()
    local hwid = ""
    pcall(function()
        hwid = game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    if not hwid or hwid == "" or hwid == "00000000-0000-0000-0000-000000000000" then
        pcall(function()
            if gethwid then hwid = gethwid() end
        end)
    end
    if not hwid or hwid == "" then
        pcall(function()
            if identifyexecutor then hwid = identifyexecutor() .. "_" .. tostring(LocalPlayer.UserId) end
        end)
    end
    if not hwid or hwid == "" then
        hwid = "DEV_" .. tostring(LocalPlayer.UserId)
    end
    return tostring(hwid)
end

local currentDeviceId = getClientDeviceId()
local CONFIG_FILE = "unionsal_device_config.json"

local ConfigRegistry = {
    AutoWin = false,
    BlatantMode = false,
    LoopDelay = 0.3,
    SafeFall = false,
    InfJump = false,
    WalkSpeed = 16,
    BlatantSpeed = false,
    Fly = false,
    FlySpeed = 50,
    NoClip = false,
    SpinBot = false,
    SpinSpeed = 30,
    Fullbright = false,
    Fov = 70,
    AntiAfk = true,
    FpsBoost = false,
    PotatoGraphics = false,
    AutoSave = true,
    WebhookUrl = "",
    SendOnExec = true,
    SendOnWin = true,
    ToggleKey = "RightShift"
}

local ToggleObjects = {}
local SliderObjects = {}
local InputObjects = {}

local function saveDeviceConfig(showNotification)
    local payload = {
        DeviceId = currentDeviceId,
        PlayerName = LocalPlayer.Name,
        UserId = LocalPlayer.UserId,
        SavedAt = os.time(),
        Settings = ConfigRegistry
    }
    local ok = pcall(function()
        if writefile then
            writefile(CONFIG_FILE, game:GetService("HttpService"):JSONEncode(payload))
            return true
        end
        return false
    end)
    if showNotification then
        if ok then
            Window:Notify({ Title = "Config Tersimpan", Content = "Pengaturan berhasil disimpan untuk device ini (" .. string.sub(currentDeviceId, 1, 8) .. "...)", Duration = 3 })
        else
            Window:Notify({ Title = "Config Error", Content = "Executor kamu tidak memiliki izin writefile.", Duration = 3 })
        end
    end
    return ok
end

local function loadDeviceConfig(showNotification)
    local ok, content = pcall(function()
        if readfile and isfile and isfile(CONFIG_FILE) then
            return readfile(CONFIG_FILE)
        end
        return nil
    end)
    if not ok or not content or content == "" then
        return false, "Belum ada file"
    end

    local parseOk, parsed = pcall(function()
        return game:GetService("HttpService"):JSONDecode(content)
    end)
    if not parseOk or not parsed or typeof(parsed) ~= "table" then
        return false, "Format tidak valid"
    end

    -- CEK APAKAH DEVICE SAMA:
    if parsed.DeviceId == currentDeviceId then
        -- DEVICE COCOK! Pulihkan seluruh konfigurasi
        if parsed.Settings and typeof(parsed.Settings) == "table" then
            for k, val in pairs(parsed.Settings) do
                ConfigRegistry[k] = val
                if ToggleObjects[k] then
                    pcall(function() ToggleObjects[k]:Set(val, true) end)
                end
                if SliderObjects[k] then
                    pcall(function() SliderObjects[k]:Set(val, true) end)
                end
                if InputObjects[k] then
                    pcall(function() InputObjects[k]:Set(val, true) end)
                end
            end
            if parsed.Settings.ToggleKey and Enum.KeyCode[parsed.Settings.ToggleKey] then
                Window.ToggleKey = Enum.KeyCode[parsed.Settings.ToggleKey]
            end
        end
        if showNotification then
            Window:Notify({ Title = "Config Dimuat", Content = "Device terverifikasi! Konfigurasi tersimpan otomatis aktif.", Duration = 4 })
        end
        return true, "Success"
    else
        -- DEVICE BERBEDA: Reset konfigurasi ke default!
        pcall(function()
            if delfile then delfile(CONFIG_FILE) end
        end)
        if showNotification then
            Window:Notify({ Title = "Device Berbeda", Content = "Device berbeda terdeteksi! Semua pengaturan di-reset ke default.", Duration = 4 })
        end
        return false, "Device Mismatch"
    end
end

local function notifyStateChange(k, v)
    ConfigRegistry[k] = v
    if ConfigRegistry.AutoSave then
        task.spawn(function()
            saveDeviceConfig(false)
        end)
    end
end

-- ═══════════════════════════════════════════
--  OPTIMASI GRAFIK POTATO & FPS BOOST
-- ═══════════════════════════════════════════
local function applyPotatoGraphics(enable)
    local Lighting = game:GetService("Lighting")
    local Terrain = workspace:FindFirstChildOfClass("Terrain")

    if enable then
        pcall(function()
            settings().Rendering.QualityLevel = 1
        end)
        pcall(function()
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            Lighting.Brightness = 1
        end)
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("PostEffect") or v:IsA("BloomEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("SunRaysEffect") or v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") then
                v.Enabled = false
            end
        end
        if Terrain then
            pcall(function()
                Terrain.Decoration = false
                Terrain.WaterWaveSize = 0
                Terrain.WaterWaveSpeed = 0
                Terrain.WaterReflectance = 0
            end)
        end
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not obj:IsDescendantOf(LocalPlayer.Character or workspace) then
                pcall(function()
                    obj.Material = Enum.Material.SmoothPlastic
                    obj.CastShadow = false
                end)
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                pcall(function() obj.Transparency = 1 end)
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                pcall(function() obj.Enabled = false end)
            end
        end
    else
        pcall(function()
            Lighting.GlobalShadows = true
            Lighting.FogEnd = 1000
        end)
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("PostEffect") then v.Enabled = true end
        end
        if Terrain then
            pcall(function() Terrain.Decoration = true end)
        end
    end
end

local function applyFpsBoost(enable)
    if enable then
        pcall(function()
            settings().Rendering.QualityLevel = 1
            game:GetService("Lighting").GlobalShadows = false
        end)
    else
        pcall(function()
            settings().Rendering.QualityLevel = 0
            game:GetService("Lighting").GlobalShadows = true
        end)
    end
end

-- ╔══════════════════════════════╗
-- ║  TAB: AUTO FARM (MAIN)       ║
-- ╚══════════════════════════════╝
local WinTab = Window:CreateTab("Auto Farm", "sprout", "Main")
WinTab:CreateSection("Auto Win Automation")

ToggleObjects.AutoWin = WinTab:CreateToggle({
    Name = "Enable Auto Win (Loop Otomatis)",
    CurrentValue = false,
    Callback = function(v)
        WinSystem.AutoWinRunning = v
        notifyStateChange("AutoWin", v)
        Window:Notify({
            Title   = "Auto Win",
            Content = v and "Auto Win aktif! Menjalankan siklus..." or "Auto Win dihentikan.",
            Duration = 2,
        })

        if v then
            task.spawn(function()
                while WinSystem.AutoWinRunning do
                    local root = getRootPart()
                    local part, winCf = findWinPart()

                    if root and winCf then
                        if root.CFrame.Y < 30 then
                            WinSystem.SpawnCFrame = root.CFrame
                        end

                        root.CFrame = winCf + Vector3.new(0, 2, 0)

                        if part and firetouchinterest then
                            pcall(function()
                                firetouchinterest(root, part, 0)
                                task.wait(0.03)
                                firetouchinterest(root, part, 1)
                            end)
                        end

                        if WinSystem.BlatantMode then
                            task.wait(WinSystem.LoopDelay)
                            if root and WinSystem.SpawnCFrame then
                                root.CFrame = WinSystem.SpawnCFrame
                            end
                            task.wait(0.05)
                        else
                            task.wait(WinSystem.LoopDelay)
                            if root and WinSystem.SpawnCFrame then
                                root.CFrame = WinSystem.SpawnCFrame
                            end
                            task.wait(0.5)
                        end
                    else
                        task.wait(1)
                    end
                end
            end)
        end
    end,
})

ToggleObjects.BlatantMode = WinTab:CreateToggle({
    Name = "Mode Blatant (Kecepatan Ekstrem)",
    CurrentValue = false,
    Callback = function(v)
        WinSystem.BlatantMode = v
        notifyStateChange("BlatantMode", v)
        Window:Notify({
            Title   = "Blatant Mode",
            Content = v and "Mode Blatant aktif! Delay minimal." or "Mode Blatant nonaktif.",
            Duration = 2,
        })
    end,
})

SliderObjects.LoopDelay = WinTab:CreateSlider({
    Name = "Auto Win Delay",
    Range = {0.05, 3},
    Increment = 0.05,
    Suffix = " detik",
    CurrentValue = 0.3,
    Callback = function(v)
        WinSystem.LoopDelay = v
        notifyStateChange("LoopDelay", v)
    end,
})

WinTab:CreateSection("Kontrol & Titik Lokasi Win")

WinTab:CreateButton({
    Name = "Teleport Langsung ke Area Win",
    Callback = function()
        local root = getRootPart()
        local part, winCf, name = findWinPart()
        if root and winCf then
            root.CFrame = winCf + Vector3.new(0, 2, 0)
            if part and firetouchinterest then
                pcall(function()
                    firetouchinterest(root, part, 0)
                    task.wait(0.03)
                    firetouchinterest(root, part, 1)
                end)
            end
            Window:Notify({
                Title   = "Teleport Berhasil",
                Content = "Tiba di titik target: " .. tostring(name),
                Duration = 3,
            })
        else
            Window:Notify({
                Title   = "Belum Terdeteksi",
                Content = "Gunakan tombol Set Manual di bawah saat berada di garis finish.",
                Duration = 4,
            })
        end
    end,
})

WinTab:CreateButton({
    Name = "Set Posisi Saat Ini Sebagai Titik Win",
    Callback = function()
        local root = getRootPart()
        if root then
            WinSystem.CustomWinCFrame = root.CFrame + Vector3.new(0, 1, 0)
            Window:Notify({
                Title   = "Titik Terkunci",
                Content = string.format("X: %.0f, Y: %.0f, Z: %.0f", root.Position.X, root.Position.Y, root.Position.Z),
                Duration = 4,
            })
        end
    end,
})

WinTab:CreateButton({
    Name = "Scan Ulang Titik Win / Ujung Obby",
    Callback = function()
        local part, winCf, name = findWinPart()
        if winCf then
            Window:Notify({
                Title   = "Hasil Scan",
                Content = "Target: " .. tostring(name),
                Duration = 4,
            })
        else
            Window:Notify({
                Title   = "Hasil Scan",
                Content = "Silakan berdiri di finish lalu klik 'Set Posisi Saat Ini'.",
                Duration = 4,
            })
        end
    end,
})

-- ╔══════════════════════════════╗
-- ║  TAB: SPEED & JUMP (MAIN)    ║
-- ╚══════════════════════════════╝
local MoveTab = Window:CreateTab("Speed & Jump", "rocket", "Main")
local safeFallActive = false
local safeFallHeartbeat = nil

MoveTab:CreateSection("Proteksi Fisika & Kebal Jatuh")

ToggleObjects.SafeFall = MoveTab:CreateToggle({
    Name = "Kebal Saat Jatuh (No Fall Damage)",
    CurrentValue = false,
    Callback = function(v)
        safeFallActive = v
        notifyStateChange("SafeFall", v)
        local hum = getHumanoid()
        if hum then
            pcall(function()
                hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, not v)
                hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, not v)
            end)
        end

        if v and not safeFallHeartbeat then
            safeFallHeartbeat = RunService.Heartbeat:Connect(function()
                if not safeFallActive then return end
                local root = getRootPart()
                if root and root.AssemblyLinearVelocity.Y < -40 then
                    root.AssemblyLinearVelocity = Vector3.new(
                        root.AssemblyLinearVelocity.X,
                        -5,
                        root.AssemblyLinearVelocity.Z
                    )
                end
            end)
        elseif not v and safeFallHeartbeat then
            safeFallHeartbeat:Disconnect()
            safeFallHeartbeat = nil
        end

        Window:Notify({
            Title   = "Anti-Fall Damage",
            Content = v and "Kebal jatuh AKTIF! Gravitasi diatur aman." or "Kebal jatuh NONAKTIF.",
            Duration = 2,
        })
    end,
})

local infiniteJump = false
UserInputService.JumpRequest:Connect(function()
    if infiniteJump then
        local hum = getHumanoid()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

ToggleObjects.InfJump = MoveTab:CreateToggle({
    Name = "Infinite Jump (Lompat Tanpa Batas)",
    CurrentValue = false,
    Callback = function(v)
        infiniteJump = v
        notifyStateChange("InfJump", v)
    end,
})

MoveTab:CreateSection("WalkSpeed & Blatant Speed")

SliderObjects.WalkSpeed = MoveTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {1, 500},
    Increment = 1,
    Suffix = " spd",
    CurrentValue = 16,
    Callback = function(v)
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = v end
        notifyStateChange("WalkSpeed", v)
    end,
})

local blatantSpeed = false
local speedMultiplier = 60
local blatantConn = nil

ToggleObjects.BlatantSpeed = MoveTab:CreateToggle({
    Name = "Blatant CFrame Speed",
    CurrentValue = false,
    Callback = function(v)
        blatantSpeed = v
        notifyStateChange("BlatantSpeed", v)
        if v and not blatantConn then
            blatantConn = RunService.RenderStepped:Connect(function(dt)
                if not blatantSpeed then return end
                local root = getRootPart()
                local hum = getHumanoid()
                if root and hum and hum.MoveDirection.Magnitude > 0 then
                    root.CFrame = root.CFrame + (hum.MoveDirection * (speedMultiplier * dt))
                end
            end)
        elseif not v and blatantConn then
            blatantConn:Disconnect()
            blatantConn = nil
        end
    end,
})

-- ╔══════════════════════════════╗
-- ║  TAB: TELEPORT (MAIN)        ║
-- ╚══════════════════════════════╝
local TpTab = Window:CreateTab("Teleport", "navigation", "Main")
TpTab:CreateSection("Teleport Lokasi Default")

TpTab:CreateButton({
    Name = "Teleport ke Spawn Asli",
    Callback = function()
        local root = getRootPart()
        if root then
            local sp = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
            if sp then
                root.CFrame = sp.CFrame + Vector3.new(0, 4, 0)
            else
                root.CFrame = CFrame.new(0, 10, 0)
            end
            Window:Notify({ Title = "Teleport", Content = "Berhasil kembali ke Spawn.", Duration = 2 })
        end
    end,
})

local function getPlayerNames()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(names, p.Name)
        end
    end
    if #names == 0 then table.insert(names, "(tidak ada player lain)") end
    return names
end

local selectedTargetPlayer = nil
TpTab:CreateDropdown({
    Name = "Pilih Target Player",
    Options = getPlayerNames(),
    Callback = function(opt) selectedTargetPlayer = opt end,
})

TpTab:CreateButton({
    Name = "Teleport ke Player Dipilih",
    Callback = function()
        local myRoot = getRootPart()
        if myRoot and selectedTargetPlayer and selectedTargetPlayer ~= "(tidak ada player lain)" then
            local tPlayer = Players:FindFirstChild(selectedTargetPlayer)
            if tPlayer and tPlayer.Character and tPlayer.Character:FindFirstChild("HumanoidRootPart") then
                myRoot.CFrame = tPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(3, 0, 0)
                Window:Notify({ Title = "Teleport", Content = "Berhasil teleport ke " .. selectedTargetPlayer, Duration = 2 })
            end
        end
    end,
})

-- ╔══════════════════════════════╗
-- ║  TAB: SHOP (MAIN)            ║
-- ╚══════════════════════════════╝
local ShopTab = Window:CreateTab("Shop", "cart", "Main")
ShopTab:CreateSection("In-Game Shop Automation")
ShopTab:CreateButton({
    Name = "Buka Toko Gravity & Speed Coil",
    Callback = function()
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        local sGui = pGui and pGui:FindFirstChild("ScreenGui")
        local sFrame = sGui and sGui:FindFirstChild("ShopFrame")
        if sFrame then
            sFrame.Visible = not sFrame.Visible
            Window:Notify({ Title = "Shop", Content = "Tampilan toko game telah di-toggle.", Duration = 2 })
        else
            Window:Notify({ Title = "Shop", Content = "ShopFrame tidak ditemukan di PlayerGui.", Duration = 2 })
        end
    end,
})

-- ╔══════════════════════════════╗
-- ║  TAB: PLAYER (MAIN)          ║
-- ╚══════════════════════════════╝
local PlayerTab = Window:CreateTab("Player", "user", "Main")
PlayerTab:CreateSection("Karakter & Fisika")

local flying = false
local flySpeed = 50
local flyBV, flyBG = nil, nil
local flyConn = nil

local function startFly()
    local root = getRootPart()
    local hum = getHumanoid()
    if not root or not hum then return end

    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    flyBV.Velocity = Vector3.zero
    flyBV.Parent = root

    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    flyBG.P = 10000
    flyBG.CFrame = root.CFrame
    flyBG.Parent = root

    flyConn = RunService.RenderStepped:Connect(function()
        if not flying or not root or not hum then return end
        local cam = workspace.CurrentCamera
        flyBG.CFrame = cam.CFrame

        local moveDir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            moveDir = moveDir - Vector3.new(0, 1, 0)
        end

        if moveDir.Magnitude > 0 then
            flyBV.Velocity = moveDir.Unit * flySpeed
        else
            flyBV.Velocity = Vector3.zero
        end
    end)
end

local function stopFly()
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyBV then flyBV:Destroy(); flyBV = nil end
    if flyBG then flyBG:Destroy(); flyBG = nil end
end

ToggleObjects.Fly = PlayerTab:CreateToggle({
    Name = "Fly Mode (Terbang WASD)",
    CurrentValue = false,
    Callback = function(v)
        flying = v
        notifyStateChange("Fly", v)
        if v then startFly() else stopFly() end
        Window:Notify({ Title = "Fly", Content = v and "Fly Mode Aktif (WASD + Space/Shift)" or "Fly Mode Nonaktif", Duration = 2 })
    end
})

SliderObjects.FlySpeed = PlayerTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 250},
    Increment = 5,
    Suffix = " spd",
    CurrentValue = 50,
    Callback = function(v)
        flySpeed = v
        notifyStateChange("FlySpeed", v)
    end
})

local noclip = false
local noclipConn = nil
ToggleObjects.NoClip = PlayerTab:CreateToggle({
    Name = "NoClip (Tembus Dinding)",
    CurrentValue = false,
    Callback = function(v)
        noclip = v
        notifyStateChange("NoClip", v)
        if v and not noclipConn then
            noclipConn = RunService.Stepped:Connect(function()
                if not noclip then return end
                local char = getCharacter()
                if char then
                    for _, p in ipairs(char:GetDescendants()) do
                        if p:IsA("BasePart") and p.CanCollide then
                            p.CanCollide = false
                        end
                    end
                end
            end)
        elseif not v and noclipConn then
            noclipConn:Disconnect()
            noclipConn = nil
        end
        Window:Notify({ Title = "NoClip", Content = v and "NoClip Aktif!" or "NoClip Nonaktif", Duration = 2 })
    end
})

local spinbot = false
local spinSpeed = 30
local spinConn = nil
ToggleObjects.SpinBot = PlayerTab:CreateToggle({
    Name = "SpinBot (Putar Cepat)",
    CurrentValue = false,
    Callback = function(v)
        spinbot = v
        notifyStateChange("SpinBot", v)
        if v and not spinConn then
            spinConn = RunService.RenderStepped:Connect(function()
                if not spinbot then return end
                local root = getRootPart()
                if root then
                    root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(spinSpeed), 0)
                end
            end)
        elseif not v and spinConn then
            spinConn:Disconnect()
            spinConn = nil
        end
    end
})

SliderObjects.SpinSpeed = PlayerTab:CreateSlider({
    Name = "SpinBot Speed",
    Range = {5, 100},
    Increment = 5,
    Suffix = " rpm",
    CurrentValue = 30,
    Callback = function(v)
        spinSpeed = v
        notifyStateChange("SpinSpeed", v)
    end
})

PlayerTab:CreateSection("Visual & Kamera")

local fullbright = false
local Lighting = game:GetService("Lighting")
local oldAmbient = Lighting.Ambient
local oldBrightness = Lighting.Brightness
local oldClock = Lighting.ClockTime
ToggleObjects.Fullbright = PlayerTab:CreateToggle({
    Name = "Fullbright (Terang Benderang / Anti Gelap)",
    CurrentValue = false,
    Callback = function(v)
        fullbright = v
        notifyStateChange("Fullbright", v)
        if v then
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
        else
            Lighting.Ambient = oldAmbient
            Lighting.Brightness = oldBrightness
            Lighting.ClockTime = oldClock
        end
        Window:Notify({ Title = "Visual", Content = v and "Fullbright Aktif!" or "Fullbright Nonaktif", Duration = 2 })
    end
})

SliderObjects.Fov = PlayerTab:CreateSlider({
    Name = "Field of View (FOV)",
    Range = {70, 120},
    Increment = 1,
    Suffix = "°",
    CurrentValue = 70,
    Callback = function(v)
        workspace.CurrentCamera.FieldOfView = v
        notifyStateChange("Fov", v)
    end
})

PlayerTab:CreateSection("Utilitas Player")

local antiAfk = false
local afkConn = nil
ToggleObjects.AntiAfk = PlayerTab:CreateToggle({
    Name = "Anti-AFK (Cegah Disconnect 20 Menit)",
    CurrentValue = true,
    Callback = function(v)
        antiAfk = v
        notifyStateChange("AntiAfk", v)
        if v and not afkConn then
            local vu = game:GetService("VirtualUser")
            afkConn = LocalPlayer.Idled:Connect(function()
                if antiAfk then
                    vu:CaptureController()
                    vu:ClickButton2(Vector2.zero)
                end
            end)
        elseif not v and afkConn then
            afkConn:Disconnect()
            afkConn = nil
        end
    end
})

PlayerTab:CreateButton({
    Name = "Salin Koordinat Posisi Saat Ini",
    Callback = function()
        local r = getRootPart()
        if r then
            local posStr = string.format("%.1f, %.1f, %.1f", r.Position.X, r.Position.Y, r.Position.Z)
            if setclipboard then setclipboard(posStr) end
            Window:Notify({ Title = "Posisi", Content = "Koordinat disalin: " .. posStr, Duration = 3 })
        end
    end
})

PlayerTab:CreateButton({
    Name = "Reset Karakter / Respawn",
    Callback = function() local h = getHumanoid(); if h then h.Health = 0 end end
})

-- ╔══════════════════════════════╗
-- ║  TAB: SETTINGS (CONFIG)      ║
-- ╚══════════════════════════════╝
local SettingsTab = Window:CreateTab("Settings", "settings", "Config")

SettingsTab:CreateSection("Keybinds & Shortcut Menu")
SettingsTab:CreateKeybind({
    Name = "Tombol Buka / Tutup UI",
    CurrentKey = Window.ToggleKey or Enum.KeyCode.RightShift,
    Callback = function(newKey)
        Window.ToggleKey = newKey
        ConfigRegistry.ToggleKey = newKey.Name
        notifyStateChange("ToggleKey", newKey.Name)
        Window:Notify({ Title = "Keybind Disimpan", Content = "Tombol menu diubah ke: [" .. newKey.Name .. "]", Duration = 3 })
    end
})

SettingsTab:CreateParagraph({
    Title = "Daftar Shortcut & Panduan Penggunaan",
    Content = "• Buka/Tutup UI: Tekan tombol yang telah diatur di atas (Default: RightShift).\\n" ..
              "• Pop-up Kotak Mini: Muncul di kiri saat tombol strip [ — ] ditekan.\\n" ..
              "• Geser Window: Drag header atas UI menggunakan mouse.\\n" ..
              "• Resize Window: Tarik grip pojok kanan bawah seperti aplikasi Windows.\\n" ..
              "• Ganti Tema: Klik ikon matahari di kanan atas untuk White/Dark mode."
})

SettingsTab:CreateSection("Optimasi Client & FPS")
ToggleObjects.FpsBoost = SettingsTab:CreateToggle({
    Name = "Reduce Graphics Lag (FPS Boost)",
    CurrentValue = false,
    Callback = function(v)
        applyFpsBoost(v)
        notifyStateChange("FpsBoost", v)
        Window:Notify({ Title = "FPS Boost", Content = v and "FPS Boost diaktifkan!" or "FPS Boost dinonaktifkan.", Duration = 2 })
    end
})

ToggleObjects.PotatoGraphics = SettingsTab:CreateToggle({
    Name = "Grafik Potato (Ultra Low Graphics / No Textures)",
    CurrentValue = false,
    Callback = function(v)
        applyPotatoGraphics(v)
        notifyStateChange("PotatoGraphics", v)
        Window:Notify({ Title = "Grafik Potato", Content = v and "Grafik Potato aktif! Tekstur dihilangkan untuk FPS maksimal." or "Grafik Potato dinonaktifkan.", Duration = 3 })
    end
})

SettingsTab:CreateSection("Opsi Penyimpanan Device")
ToggleObjects.AutoSave = SettingsTab:CreateToggle({
    Name = "Auto-Save Konfigurasi Otomatis (Per Device)",
    CurrentValue = true,
    Callback = function(v)
        ConfigRegistry.AutoSave = v
        Window:Notify({ Title = "Auto-Save", Content = v and "Auto-Save aktif! Setiap perubahan langsung tersimpan." or "Auto-Save dinonaktifkan.", Duration = 2 })
    end
})

SettingsTab:CreateButton({
    Name = "Simpan Konfigurasi Sekarang (Device Ini)",
    Callback = function()
        saveDeviceConfig(true)
    end
})

SettingsTab:CreateButton({
    Name = "Muat Ulang Konfigurasi Tersimpan",
    Callback = function()
        loadDeviceConfig(true)
    end
})

-- ╔══════════════════════════════╗
-- ║  TAB: CONFIGS (CONFIG)       ║
-- ╚══════════════════════════════╝
local ConfigsTab = Window:CreateTab("Configs", "folder", "Config")
ConfigsTab:CreateSection("Discord Webhook Integration")

local webhookUrl = ""
local sendOnExec = true
local sendOnWin = true

InputObjects.WebhookUrl = ConfigsTab:CreateInput({
    Name = "Discord Webhook URL",
    PlaceholderText = "https://discord.com/api/webhooks/...",
    Callback = function(val)
        webhookUrl = string.gsub(val or "", "^%s*(.-)%s*$", "%1")
        ConfigRegistry.WebhookUrl = webhookUrl
        notifyStateChange("WebhookUrl", webhookUrl)
        Window:Notify({ Title = "Webhook", Content = "URL Webhook disimpan.", Duration = 2 })
    end
})

ToggleObjects.SendOnExec = ConfigsTab:CreateToggle({
    Name = "Kirim Log saat Script Dieksekusi",
    CurrentValue = true,
    Callback = function(v)
        sendOnExec = v
        ConfigRegistry.SendOnExec = v
        notifyStateChange("SendOnExec", v)
    end
})

ToggleObjects.SendOnWin = ConfigsTab:CreateToggle({
    Name = "Kirim Log saat Auto Win Berhasil",
    CurrentValue = true,
    Callback = function(v)
        sendOnWin = v
        ConfigRegistry.SendOnWin = v
        notifyStateChange("SendOnWin", v)
    end
})

local function sendDiscordWebhook(embedData)
    if webhookUrl == "" or not string.find(webhookUrl, "discord%.com/api/webhooks") then
        Window:Notify({ Title = "Webhook Error", Content = "URL Webhook tidak valid! Masukkan URL Discord yang benar.", Duration = 3 })
        return false
    end
    local http = syn and syn.request or http_request or request or (http and http.request)
    if not http then
        Window:Notify({ Title = "Webhook Error", Content = "Executor kamu tidak mendukung HTTP request.", Duration = 3 })
        return false
    end
    local payload = game:GetService("HttpService"):JSONEncode({
        username = "Unionsal Hub Logger",
        avatar_url = "https://i.imgur.com/8Q9Z5bX.png",
        embeds = { embedData }
    })
    local ok = pcall(function()
        http({
            Url = webhookUrl,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = payload
        })
    end)
    return ok
end

ConfigsTab:CreateButton({
    Name = "Kirim Pesan Uji Coba (Test Webhook)",
    Callback = function()
        local embed = {
            title = "⚡ Unionsal Hub v1.3 • Webhook Connected",
            description = "Webhook berhasil terhubung dengan client Roblox!",
            color = 8864235,
            fields = {
                { name = "Player", value = LocalPlayer.Name .. " (@" .. LocalPlayer.DisplayName .. ")", inline = true },
                { name = "Game", value = "Blush Canyon", inline = true },
                { name = "Device ID", value = string.sub(currentDeviceId, 1, 12) .. "...", inline = true },
                { name = "Place ID", value = tostring(game.PlaceId), inline = true },
                { name = "Waktu", value = os.date("%H:%M:%S - %d/%m/%Y"), inline = false }
            },
            footer = { text = "Unionsal Script Hub • .gg/unionsal" }
        }
        local success = sendDiscordWebhook(embed)
        if success then
            Window:Notify({ Title = "Webhook Sukses", Content = "Pesan uji coba berhasil terkirim ke Discord!", Duration = 3 })
        end
    end
})

ConfigsTab:CreateSection("Penyimpanan Profil Konfigurasi (Device Check)")
ConfigsTab:CreateLabel("Device ID Terdeteksi: " .. string.sub(currentDeviceId, 1, 16) .. "...")

ConfigsTab:CreateButton({
    Name = "Simpan Konfigurasi (Save Config)",
    Callback = function()
        saveDeviceConfig(true)
    end
})

ConfigsTab:CreateButton({
    Name = "Muat Konfigurasi (Load Config)",
    Callback = function()
        loadDeviceConfig(true)
    end
})

ConfigsTab:CreateButton({
    Name = "Reset Konfigurasi ke Default (Reset Config)",
    Callback = function()
        pcall(function()
            if delfile and isfile and isfile(CONFIG_FILE) then
                delfile(CONFIG_FILE)
            end
        end)
        Window:Notify({ Title = "Config Reset", Content = "File konfigurasi dihapus. Pengaturan kembali ke default.", Duration = 3 })
    end
})

-- ═══════════════════════════════════════════
--  AUTO-LOAD SAAT EXECUTE (DEVICE VERIFICATION)
-- ═══════════════════════════════════════════
task.spawn(function()
    task.wait(0.5)
    loadDeviceConfig(true)
end)

task.wait(0.5)
Window:Notify({
    Title   = "unionsal",
    Content = "Blush Canyon v1.3 aktif! Auto Win & Anti-Fall Damage siap digunakan.",
    Duration = 5,
})
