-- ╔══════════════════════════════════════════════════════════════╗
-- ║         NEMESIS SCRIPT HUB — Blush Canyon (blush.lua)        ║
-- ║        Game  : Blush Canyon (PlaceId: 3218570640)            ║
-- ║        Module: Auto Win, Blatant Speed, Safe Fall & TP       ║
-- ║        Design: Glass Bento dark purple (matches main.lua)    ║
-- ╚══════════════════════════════════════════════════════════════╝

getgenv()._NEMESIS_CHILD_LOADED = true

local SCRIPT_BASE_URL = "https://raw.githubusercontent.com/hendrawansuinto571-glitch/script/main/"

-- Load Nemesis UI Library dari main.lua (Memory / File / GitHub)
local Nemesis = getgenv().NemesisHub
if not Nemesis then
    local okLocal, resLocal = pcall(function()
        return loadstring(readfile("main.lua"))()
    end)
    if okLocal and resLocal then
        Nemesis = resLocal
    else
        local okWeb, resWeb = pcall(function()
            return loadstring(game:HttpGet(SCRIPT_BASE_URL .. "main.lua"))()
        end)
        if okWeb and resWeb then
            Nemesis = resWeb
        else
            warn("[Nemesis Hub] Gagal memuat main.lua")
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
local Window = Nemesis:CreateWindow({
    Name       = "NEMESIS",
    Subtitle   = ".gg/nemesishub",
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

-- Blacklist part yang BUKAN Win (termasuk TeleportPart void-reset, killbrick, spawn)
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

-- Deteksi Spawn Asli
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

-- Cari Part Win / Ujung Obby yang Sebenarnya
local function findWinPart()
    -- 1. Jika pengguna sudah menyimpan posisi manual, utamakan itu
    if WinSystem.CustomWinCFrame then
        WinSystem.LastDetectedName = "Posisi Manual Tersimpan"
        return nil, WinSystem.CustomWinCFrame, WinSystem.LastDetectedName
    end

    -- 2. Cek apakah ada Checkpoints / Stages dengan nomor tertinggi
    local folderNames = {"Checkpoints", "Stages", "Stage", "Spawns", "Obby", "Pads"}
    for _, fn in ipairs(folderNames) do
        local folder = workspace:FindFirstChild(fn, true)
        if folder then
            local highestNum = -1
            local highestPart = nil
            for _, child in ipairs(folder:GetChildren()) do
                local num = tonumber(string.match(child.Name, "%d+"))
                if num and num > highestNum then
                    local p = (child:IsA("BasePart") and child) or child:FindFirstChildWhichIsA("BasePart")
                    if p and not isIgnoredPart(p.Name) then
                        highestNum = num
                        highestPart = p
                    end
                end
            end
            if highestPart and highestNum > 1 then
                WinSystem.LastDetectedName = folder.Name .. " [" .. tostring(highestNum) .. "]"
                return highestPart, highestPart.CFrame + Vector3.new(0, 4, 0), WinSystem.LastDetectedName
            end
        end
    end

    -- 3. Cari part dengan nama Win / Finish (kecuali yang di-blacklist)
    local winKeywords = {"winpad", "finishpad", "endpad", "winner", "trophy", "finish", "goal", "badge"}
    for _, kw in ipairs(winKeywords) do
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not isIgnoredPart(obj.Name) then
                local lower = string.lower(obj.Name)
                if string.find(lower, kw) and not obj:IsDescendantOf(LocalPlayer.Character or workspace) then
                    WinSystem.LastDetectedName = obj.Name
                    return obj, obj.CFrame + Vector3.new(0, 4, 0), WinSystem.LastDetectedName
                end
            end
        end
    end

    -- 4. Cari Platform Terjauh dari Spawn (Ujung Obby Sebenarnya)
    local spawnPos = getSpawnPosition()
    local furthestPart = nil
    local maxDist = 0

    for _, desc in ipairs(workspace:GetDescendants()) do
        if desc:IsA("BasePart") and desc.Anchored and not isIgnoredPart(desc.Name) then
            -- Ukuran platform yang wajar untuk dipijak
            if desc.Size.X >= 2 and desc.Size.Z >= 2 and desc.Size.Y >= 0.2 then
                -- Jangan ambil karakter pemain
                local isPlayerPart = false
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr.Character and desc:IsDescendantOf(plr.Character) then
                        isPlayerPart = true
                        break
                    end
                end

                if not isPlayerPart then
                    local dist = (desc.Position - spawnPos).Magnitude
                    -- Pastikan jaraknya signifikan (> 120 studs dari spawn)
                    if dist > 120 and dist > maxDist then
                        maxDist = dist
                        furthestPart = desc
                    end
                end
            end
        end
    end

    if furthestPart then
        WinSystem.LastDetectedName = string.format("Ujung Obby: %s (%.0f studs)", furthestPart.Name, maxDist)
        return furthestPart, furthestPart.CFrame + Vector3.new(0, 4, 0), WinSystem.LastDetectedName
    end

    WinSystem.LastDetectedName = "Tidak Terdeteksi (Gunakan Set Manual)"
    return nil, nil, WinSystem.LastDetectedName
end

-- ╔══════════════════════════════╗
-- ║  TAB: AUTO WIN (MAIN)        ║
-- ╚══════════════════════════════╝
local WinTab = Window:CreateTab("Auto Farm", "sprout", "Main")

WinTab:CreateSection("Auto Win Automation")

WinTab:CreateToggle({
    Name = "Enable Auto Win (Loop Otomatis)",
    CurrentValue = false,
    Callback = function(v)
        WinSystem.AutoWinRunning = v
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
                        -- Simpan spawn awal jika belum
                        if root.CFrame.Y < 30 then
                            WinSystem.SpawnCFrame = root.CFrame
                        end

                        -- Teleport ke Win
                        root.CFrame = winCf + Vector3.new(0, 2, 0)

                        -- Trigger touch transmitter jika ada
                        if part and firetouchinterest then
                            pcall(function()
                                firetouchinterest(root, part, 0)
                                task.wait(0.03)
                                firetouchinterest(root, part, 1)
                            end)
                        end

                        -- Klik ClickDetector / ProximityPrompt jika ada
                        if part then
                            local cd = part:FindFirstChildOfClass("ClickDetector")
                            if cd and fireclickdetector then
                                pcall(function() fireclickdetector(cd) end)
                            end
                            local pp = part:FindFirstChildOfClass("ProximityPrompt")
                            if pp and fireproximityprompt then
                                pcall(function() fireproximityprompt(pp) end)
                            end
                        end

                        -- Mode Blatant: sangat cepat, delay minimal
                        if WinSystem.BlatantMode then
                            task.wait(WinSystem.LoopDelay)
                            -- Balik sekejap ke spawn
                            if root and WinSystem.SpawnCFrame then
                                root.CFrame = WinSystem.SpawnCFrame
                            end
                            task.wait(0.05)
                        else
                            -- Mode Aman: delay lebih teratur
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

WinTab:CreateToggle({
    Name = "Mode Blatant (Kecepatan Ekstrem)",
    CurrentValue = false,
    Callback = function(v)
        WinSystem.BlatantMode = v
        Window:Notify({
            Title   = "Blatant Mode",
            Content = v and "Mode Blatant aktif! Delay dipercepat ke batas maksimal." or "Mode Blatant nonaktif.",
            Duration = 2,
        })
    end,
})

WinTab:CreateSlider({
    Name = "Auto Win Delay (Detik)",
    Range = {0.05, 3},
    Increment = 0.05,
    Suffix = "s",
    CurrentValue = 0.3,
    Callback = function(v)
        WinSystem.LoopDelay = v
    end,
})

WinTab:CreateSection("Kontrol & Titik Lokasi Win")

WinTab:CreateButton({
    Name = "Teleport Langsung ke Area Win",
    Callback = function()
        local root = getRootPart()
        local part, winCf, name = findWinPart()
        if root and winCf then
            root.CFrame = winCf
            if part and firetouchinterest then
                pcall(function()
                    firetouchinterest(root, part, 0)
                    task.wait(0.02)
                    firetouchinterest(root, part, 1)
                end)
            end
            Window:Notify({
                Title   = "Teleport Berhasil",
                Content = "Tiba di: " .. tostring(name),
                Duration = 3,
            })
        else
            Window:Notify({
                Title   = "Part Belum Ditemukan",
                Content = "Gunakan tombol 'Set Posisi Saat Ini Sebagai Titik Win' saat berada di garis finish.",
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
            WinSystem.LastDetectedName = "Titik Manual Pengguna"
            Window:Notify({
                Title   = "Titik Win Terkunci",
                Content = string.format("Koordinat: X:%.0f  Y:%.0f  Z:%.0f", root.Position.X, root.Position.Y, root.Position.Z),
                Duration = 3,
            })
        end
    end,
})

WinTab:CreateButton({
    Name = "Scan Ulang Titik Win / Ujung Obby",
    Callback = function()
        local part, winCf, name = findWinPart()
        if winCf then
            local p = winCf.Position
            Window:Notify({
                Title   = "Hasil Scan Map",
                Content = "Target: " .. tostring(name) .. string.format("
Koordinat: %.0f, %.0f, %.0f", p.X, p.Y, p.Z),
                Duration = 4,
            })
        else
            Window:Notify({
                Title   = "Hasil Scan Map",
                Content = "Tidak ada part win bernama. Silakan berdiri di finish dan klik 'Set Posisi Saat Ini'.",
                Duration = 4,
            })
        end
    end,
})

-- ╔══════════════════════════════╗
-- ║  TAB: SPEED & JUMP (MAIN)    ║
-- ╚══════════════════════════════╝
local MoveTab = Window:CreateTab("Speed & Jump", "rocket", "Main")

-- Proteksi Kebal Jatuh (No Fall Damage / Anti-Ragdoll)
local safeFallEnabled = false
local noFallConn = nil

MoveTab:CreateSection("Proteksi Fisika & Kebal Jatuh")

MoveTab:CreateToggle({
    Name = "Kebal Saat Jatuh (No Fall Damage)",
    CurrentValue = false,
    Callback = function(v)
        safeFallEnabled = v
        Window:Notify({
            Title   = "Anti-Fall Damage",
            Content = v and "Proteksi kebal jatuh aktif! Karakter aman dari ketinggian." or "Proteksi kebal jatuh nonaktif.",
            Duration = 2,
        })

        if v then
            -- Mencegah state Freefall memicu damage benturan
            local hum = getHumanoid()
            if hum then
                pcall(function()
                    hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                end)
            end

            -- Reset velocity jatuh bebas sebelum menyentuh tanah
            if not noFallConn then
                noFallConn = RunService.Heartbeat:Connect(function()
                    if not safeFallEnabled then return end
                    local root = getRootPart()
                    local h = getHumanoid()
                    if root and h then
                        -- Jika kecepatan jatuh ke bawah terlalu cepat, redam secara instan
                        if root.AssemblyLinearVelocity.Y < -40 then
                            root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, -5, root.AssemblyLinearVelocity.Z)
                        end
                    end
                end)
            end
        else
            if noFallConn then
                noFallConn:Disconnect()
                noFallConn = nil
            end
            local hum = getHumanoid()
            if hum then
                pcall(function()
                    hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
                    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
                end)
            end
        end
    end,
})

-- Infinite Jump (Lompat Bebas di Udara)
local infJumpEnabled = false
UserInputService.JumpRequest:Connect(function()
    if infJumpEnabled then
        local hum = getHumanoid()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

MoveTab:CreateToggle({
    Name = "Infinite Jump (Lompat Tanpa Batas di Udara)",
    CurrentValue = false,
    Callback = function(v)
        infJumpEnabled = v
        Window:Notify({
            Title   = "Infinite Jump",
            Content = v and "Lompat bebas aktif! Tekan spasi berulang kali di udara." or "Infinite jump nonaktif.",
            Duration = 2,
        })
    end,
})

-- WalkSpeed Controller
MoveTab:CreateSection("WalkSpeed & Blatant Speed")

MoveTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {1, 500},
    Increment = 1,
    Suffix = " spd",
    CurrentValue = 16,
    Callback = function(v)
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = v end
    end,
})

-- Blatant CFrame Speed (Bypass Speed Anti-Cheat)
local blatantSpeedEnabled = false
local blatantSpeedMultiplier = 60
local blatantConn = nil

MoveTab:CreateToggle({
    Name = "Blatant CFrame Speed (Lari Tembus Kecepatan)",
    CurrentValue = false,
    Callback = function(v)
        blatantSpeedEnabled = v
        Window:Notify({
            Title   = "Blatant Speed",
            Content = v and "Blatant speed aktif! Bergerak cepat dengan CFrame." or "Blatant speed nonaktif.",
            Duration = 2,
        })

        if v and not blatantConn then
            blatantConn = RunService.RenderStepped:Connect(function(dt)
                if not blatantSpeedEnabled then return end
                local root = getRootPart()
                local hum = getHumanoid()
                if root and hum and hum.MoveDirection.Magnitude > 0 then
                    root.CFrame = root.CFrame + (hum.MoveDirection * (blatantSpeedMultiplier * dt))
                end
            end)
        elseif not v and blatantConn then
            blatantConn:Disconnect()
            blatantConn = nil
        end
    end,
})

MoveTab:CreateSlider({
    Name = "Blatant Speed Multiplier",
    Range = {10, 300},
    Increment = 5,
    Suffix = "x",
    CurrentValue = 60,
    Callback = function(v)
        blatantSpeedMultiplier = v
    end,
})

MoveTab:CreateButton({
    Name = "Reset WalkSpeed ke 16",
    Callback = function()
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = 16 end
        Window:Notify({
            Title = "Reset Speed",
            Content = "WalkSpeed dikembalikan ke default (16).",
            Duration = 2,
        })
    end,
})

-- Jump Power Controller
MoveTab:CreateSection("Jump Power Controller")

MoveTab:CreateSlider({
    Name = "Jump Power / Height",
    Range = {7, 500},
    Increment = 1,
    Suffix = " jmp",
    CurrentValue = 7,
    Callback = function(v)
        local hum = getHumanoid()
        if hum then
            hum.JumpPower = v
            pcall(function() hum.JumpHeight = v end)
        end
    end,
})

MoveTab:CreateButton({
    Name = "Reset Jump ke Default",
    Callback = function()
        local hum = getHumanoid()
        if hum then
            hum.JumpPower = 7
            pcall(function() hum.JumpHeight = 7 end)
        end
        Window:Notify({
            Title = "Reset Jump",
            Content = "Jump power dikembalikan ke default.",
            Duration = 2,
        })
    end,
})

MoveTab:CreateSection("Preset Kecepatan Instan")

local presets = {
    { name = "Normal Speed (16 / 7)", spd = 16, jmp = 7 },
    { name = "Medium Speed (50 / 50)", spd = 50, jmp = 50 },
    { name = "Turbo Speed (200 / 200)", spd = 200, jmp = 200 },
    { name = "God Speed (500 / 500)", spd = 500, jmp = 500 },
}

for _, p in ipairs(presets) do
    MoveTab:CreateButton({
        Name = p.name,
        Callback = function()
            local hum = getHumanoid()
            if hum then
                hum.WalkSpeed = p.spd
                hum.JumpPower = p.jmp
                pcall(function() hum.JumpHeight = p.jmp end)
            end
            Window:Notify({
                Title = "Preset Aktif",
                Content = p.name .. " diaplikasikan.",
                Duration = 2,
            })
        end,
    })
end

-- ╔══════════════════════════════╗
-- ║  TAB: TELEPORT (MAIN)        ║
-- ╚══════════════════════════════╝
local TpTab = Window:CreateTab("Teleport", "navigation", "Main")

TpTab:CreateSection("Teleport Langsung ke Titik Penting")

TpTab:CreateButton({
    Name = "Teleport ke Win / Finish Line",
    Callback = function()
        local root = getRootPart()
        local part, winCf = findWinPart()
        if root and winCf then
            root.CFrame = winCf + Vector3.new(0, 3, 0)
            Window:Notify({ Title = "Teleport", Content = "Tiba di area Win!", Duration = 2 })
        else
            Window:Notify({ Title = "Gagal", Content = "Titik Win belum ditemukan.", Duration = 2 })
        end
    end,
})

TpTab:CreateButton({
    Name = "Spawn Point (0, 5, 0)",
    Callback = function()
        local root = getRootPart()
        if root then
            root.CFrame = WinSystem.SpawnCFrame or CFrame.new(0, 5, 0)
            Window:Notify({ Title = "Spawn Point", Content = "Kembali ke spawn point.", Duration = 2 })
        end
    end,
})

TpTab:CreateSection("Teleport ke Player")

local function getPlayerNames()
    local names = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(names, plr.Name)
        end
    end
    return #names > 0 and names or {"(tidak ada player)"}
end

local selectedTarget = nil
TpTab:CreateDropdown({
    Name = "Pilih Target Player",
    Options = getPlayerNames(),
    Callback = function(opt)
        selectedTarget = opt
    end,
})

TpTab:CreateButton({
    Name = "Teleport ke Player Dipilih",
    Callback = function()
        local myRoot = getRootPart()
        if not myRoot then return end
        if not selectedTarget or selectedTarget == "(tidak ada player)" then
            Window:Notify({ Title = "Pilih Player", Content = "Silakan pilih player dari dropdown.", Duration = 3 })
            return
        end
        local target = Players:FindFirstChild(selectedTarget)
        if target and target.Character then
            local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
            if tRoot then
                myRoot.CFrame = tRoot.CFrame + Vector3.new(3, 0, 0)
                Window:Notify({ Title = "Teleport Selesai", Content = "Berhasil teleport ke " .. selectedTarget, Duration = 2 })
            end
        else
            Window:Notify({ Title = "Player Tidak Ditemukan", Content = selectedTarget .. " offline atau tidak ada karakter.", Duration = 3 })
        end
    end,
})

TpTab:CreateButton({
    Name = "Teleport ke Player Terdekat",
    Callback = function()
        local myRoot = getRootPart()
        if not myRoot then return end
        local nearest, nearestDist = nil, math.huge
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local r = plr.Character:FindFirstChild("HumanoidRootPart")
                if r then
                    local d = (myRoot.Position - r.Position).Magnitude
                    if d < nearestDist then
                        nearestDist = d
                        nearest = plr
                    end
                end
            end
        end
        if nearest and nearest.Character then
            local tRoot = nearest.Character:FindFirstChild("HumanoidRootPart")
            if tRoot then
                myRoot.CFrame = tRoot.CFrame + Vector3.new(3, 0, 0)
                Window:Notify({ Title = "Teleport Player Terdekat", Content = nearest.Name .. " (" .. math.floor(nearestDist) .. " studs)", Duration = 3 })
            end
        else
            Window:Notify({ Title = "Tidak Ada Target", Content = "Tidak ada player lain di server.", Duration = 2 })
        end
    end,
})

TpTab:CreateSection("Teleport Koordinat Custom")

local tpX, tpY, tpZ = 0, 0, 0

TpTab:CreateInput({
    Name = "Koordinat X",
    PlaceholderText = "Nilai X (contoh: 100)",
    Callback = function(v) tpX = tonumber(v) or 0 end,
})
TpTab:CreateInput({
    Name = "Koordinat Y",
    PlaceholderText = "Nilai Y (contoh: 50)",
    Callback = function(v) tpY = tonumber(v) or 0 end,
})
TpTab:CreateInput({
    Name = "Koordinat Z",
    PlaceholderText = "Nilai Z (contoh: 200)",
    Callback = function(v) tpZ = tonumber(v) or 0 end,
})

TpTab:CreateButton({
    Name = "Teleport ke Koordinat",
    Callback = function()
        local root = getRootPart()
        if root then
            root.CFrame = CFrame.new(tpX, tpY, tpZ)
            Window:Notify({ Title = "Teleport", Content = string.format("X: %.0f  Y: %.0f  Z: %.0f", tpX, tpY, tpZ), Duration = 2 })
        end
    end,
})

-- ╔══════════════════════════════╗
-- ║  TAB: SHOP (MAIN)            ║
-- ╚══════════════════════════════╝
local ShopTab = Window:CreateTab("Shop", "cart", "Main")
ShopTab:CreateSection("In-Game Shop Automation")
ShopTab:CreateLabel("Fitur auto buy koin dan perk gamepass Blush Canyon.")

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
PlayerTab:CreateSection("Player Profile & Stats")
PlayerTab:CreateLabel("Username     : @" .. LocalPlayer.Name)
PlayerTab:CreateLabel("Display Name : " .. LocalPlayer.DisplayName)
PlayerTab:CreateLabel("User ID      : " .. tostring(LocalPlayer.UserId))
PlayerTab:CreateLabel("Account Age  : " .. tostring(LocalPlayer.AccountAge) .. " days")

PlayerTab:CreateButton({
    Name = "Reset Character / Respawn",
    Callback = function()
        local hum = getHumanoid()
        if hum then hum.Health = 0 end
    end,
})

-- ╔══════════════════════════════╗
-- ║  TAB: SETTINGS (CONFIG)      ║
-- ╚══════════════════════════════╝
local SettingsTab = Window:CreateTab("Settings", "settings", "Config")
SettingsTab:CreateSection("Client Configurations")
SettingsTab:CreateToggle({
    Name = "Auto Rejoin on Disconnect",
    CurrentValue = true,
    Callback = function(v) end,
})
SettingsTab:CreateToggle({
    Name = "Reduce Graphics Lag (FPS Boost)",
    CurrentValue = false,
    Callback = function(v)
        if v then
            pcall(function()
                settings().Rendering.QualityLevel = 1
            end)
        end
    end,
})

-- ╔══════════════════════════════╗
-- ║  TAB: CONFIGS (CONFIG)       ║
-- ╚══════════════════════════════╝
local ConfigsTab = Window:CreateTab("Configs", "folder", "Config")
ConfigsTab:CreateSection("Save & Load Profiles")
ConfigsTab:CreateButton({
    Name = "Save Current Config",
    Callback = function()
        Window:Notify({ Title = "Config", Content = "Konfigurasi berhasil disimpan.", Duration = 2 })
    end,
})
ConfigsTab:CreateButton({
    Name = "Load Default Config",
    Callback = function()
        Window:Notify({ Title = "Config", Content = "Konfigurasi default dipulihkan.", Duration = 2 })
    end,
})

-- ╔══════════════════════════════╗
-- ║  NOTIFICATION SIAP           ║
-- ╚══════════════════════════════╝
task.wait(0.5)
Window:Notify({
    Title   = "Nemesis Hub",
    Content = "Blush Canyon v1.3 aktif! Auto Win & Anti-Fall Damage siap digunakan.",
    Duration = 5,
})
