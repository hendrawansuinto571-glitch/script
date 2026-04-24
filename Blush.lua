-- ╔══════════════════════════════════════════════════════════════╗
-- ║        PAK WOWO SCRIPT HUB — blush.lua                       ║
-- ║        Game  : Blush Canyon (PlaceId: 3218570640)            ║
-- ║        Author: Azeey | Beta                                  ║
-- ╚══════════════════════════════════════════════════════════════╝

-- Load Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
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
--  WINDOW UTAMA
-- ═══════════════════════════════════════════
local Window = Rayfield:CreateWindow({
    Name = "🌸 Pak Wowo  ·  Blush Canyon",
    LoadingTitle  = "Wowo Script Hub",
    LoadingSubtitle = "by Azeey  ·  Beta",
    ConfigurationSaving = {
        Enabled    = true,
        FolderName = "WowoHub",
        FileName   = "BlushConfig",
    },
    Discord = { Enabled = false },
    KeySystem = false,
})

-- ╔══════════════════════════════╗
-- ║  TAB 1 – INFORMASI           ║
-- ╚══════════════════════════════╝
local InfoTab = Window:CreateTab("  Info", 4483362458)

InfoTab:CreateSection("👤  Profil Player")

local thumbUrl = ""
pcall(function()
    thumbUrl = Players:GetUserThumbnailAsync(
        LocalPlayer.UserId,
        Enum.ThumbnailType.HeadShot,
        Enum.ThumbnailSize.Size420x420
    )
end)

InfoTab:CreateButton({
    Name = "🖼️  Lihat Profil Roblox",
    Callback = function()
        Rayfield:Notify({
            Title   = "👤  " .. LocalPlayer.DisplayName,
            Content = "Username : @" .. LocalPlayer.Name
                    .. "\nUser ID  : " .. tostring(LocalPlayer.UserId)
                    .. "\nUmur Akun: " .. tostring(LocalPlayer.AccountAge) .. " hari",
            Duration = 6,
            Image    = thumbUrl,
        })
    end,
})

InfoTab:CreateLabel("Username    :  " .. LocalPlayer.Name)
InfoTab:CreateLabel("Display Name:  " .. LocalPlayer.DisplayName)
InfoTab:CreateLabel("User ID     :  " .. tostring(LocalPlayer.UserId))
InfoTab:CreateLabel("Umur Akun   :  " .. tostring(LocalPlayer.AccountAge) .. " hari")

InfoTab:CreateSection("📋  Informasi Script")
InfoTab:CreateLabel("Script      :  Wowo Script Hub")
InfoTab:CreateLabel("Game        :  Blush Canyon")
InfoTab:CreateLabel("Versi       :  Beta")
InfoTab:CreateLabel("Pembuat     :  Azeey")
InfoTab:CreateLabel("UI Library  :  Rayfield")

InfoTab:CreateSection("✅  Fitur Tersedia")
InfoTab:CreateLabel("🌍  Teleport — ke koordinat / player / preset")
InfoTab:CreateLabel("⚡  Speed & Jump — slider & preset instan")
InfoTab:CreateLabel("💾  Konfigurasi otomatis tersimpan")

InfoTab:CreateSection("⚠️  Disclaimer")
InfoTab:CreateLabel("Gunakan script ini dengan bijak.")
InfoTab:CreateLabel("Risiko banned ditanggung pengguna.")


-- ╔══════════════════════════════╗
-- ║  TAB 2 – TELEPORT            ║
-- ╚══════════════════════════════╝
local TpTab = Window:CreateTab("  Teleport", 4483362458)

-- Teleport ke Koordinat
TpTab:CreateSection("📍  Teleport Koordinat Custom")

local tpX, tpY, tpZ = 0, 0, 0

TpTab:CreateInput({
    Name             = "Koordinat X",
    PlaceholderText  = "Nilai X  (contoh: 100)",
    RemoveTextAfterFocusLost = false,
    Flag             = "TpX",
    Callback         = function(v) tpX = tonumber(v) or 0 end,
})
TpTab:CreateInput({
    Name             = "Koordinat Y",
    PlaceholderText  = "Nilai Y  (contoh: 50)",
    RemoveTextAfterFocusLost = false,
    Flag             = "TpY",
    Callback         = function(v) tpY = tonumber(v) or 0 end,
})
TpTab:CreateInput({
    Name             = "Koordinat Z",
    PlaceholderText  = "Nilai Z  (contoh: 200)",
    RemoveTextAfterFocusLost = false,
    Flag             = "TpZ",
    Callback         = function(v) tpZ = tonumber(v) or 0 end,
})

TpTab:CreateButton({
    Name = "🚀  Teleport ke Koordinat",
    Callback = function()
        local root = getRootPart()
        if root then
            root.CFrame = CFrame.new(tpX, tpY, tpZ)
            Rayfield:Notify({
                Title   = "✅  Teleport Berhasil",
                Content = "X: " .. tpX .. "   Y: " .. tpY .. "   Z: " .. tpZ,
                Duration = 3,
                Image    = 4483362458,
            })
        else
            Rayfield:Notify({
                Title   = "❌  Gagal",
                Content = "Karakter tidak ditemukan!",
                Duration = 3,
                Image    = 4483362458,
            })
        end
    end,
})

-- Teleport ke Player
TpTab:CreateSection("👥  Teleport ke Player")

-- Dropdown pilih player
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
    Name    = "Pilih Target Player",
    Options = getPlayerNames(),
    Flag    = "TargetPlayer",
    Callback = function(opt)
        selectedTarget = opt
    end,
})

TpTab:CreateButton({
    Name = "📡  Teleport ke Player Dipilih",
    Callback = function()
        local myRoot = getRootPart()
        if not myRoot then return end
        if not selectedTarget or selectedTarget == "(tidak ada player)" then
            Rayfield:Notify({
                Title   = "⚠️  Pilih Player",
                Content = "Silakan pilih player dari dropdown!",
                Duration = 3, Image = 4483362458,
            })
            return
        end
        local target = Players:FindFirstChild(selectedTarget)
        if target and target.Character then
            local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
            if tRoot then
                myRoot.CFrame = tRoot.CFrame + Vector3.new(3, 0, 0)
                Rayfield:Notify({
                    Title   = "✅  Teleport ke " .. selectedTarget,
                    Content = "Berhasil!",
                    Duration = 3, Image = 4483362458,
                })
            end
        else
            Rayfield:Notify({
                Title   = "❌  Player Tidak Ditemukan",
                Content = selectedTarget .. " sudah offline atau tidak ada karakter.",
                Duration = 3, Image = 4483362458,
            })
        end
    end,
})

TpTab:CreateButton({
    Name = "🎯  Teleport ke Player TERDEKAT",
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
                Rayfield:Notify({
                    Title   = "✅  Teleport ke " .. nearest.Name,
                    Content = "Jarak sebelumnya: " .. math.floor(nearestDist) .. " studs",
                    Duration = 3, Image = 4483362458,
                })
            end
        else
            Rayfield:Notify({
                Title   = "❌  Tidak Ada Player",
                Content = "Tidak ada player lain di server!",
                Duration = 3, Image = 4483362458,
            })
        end
    end,
})

-- Preset Teleport
TpTab:CreateSection("🗺️  Preset Lokasi Cepat")

TpTab:CreateButton({
    Name = "🏠  Spawn Point  (0, 5, 0)",
    Callback = function()
        local root = getRootPart()
        if root then
            root.CFrame = CFrame.new(0, 5, 0)
            Rayfield:Notify({
                Title   = "🏠  Spawn Point",
                Content = "Teleport ke titik spawn berhasil!",
                Duration = 2, Image = 4483362458,
            })
        end
    end,
})

TpTab:CreateButton({
    Name = "☁️  Terbang ke Atas  (Y + 500)",
    Callback = function()
        local root = getRootPart()
        if root then
            root.CFrame = root.CFrame + Vector3.new(0, 500, 0)
            Rayfield:Notify({
                Title   = "☁️  Whoosh!",
                Content = "Kamu meluncur ke langit!",
                Duration = 2, Image = 4483362458,
            })
        end
    end,
})

TpTab:CreateButton({
    Name = "🌊  Ke Pusat Map  (0, 0, 0)",
    Callback = function()
        local root = getRootPart()
        if root then
            root.CFrame = CFrame.new(0, 10, 0)
            Rayfield:Notify({
                Title   = "🌊  Pusat Map",
                Content = "Teleport ke tengah map!",
                Duration = 2, Image = 4483362458,
            })
        end
    end,
})


-- ╔══════════════════════════════╗
-- ║  TAB 3 – SPEED & JUMP        ║
-- ╚══════════════════════════════╝
local MoveTab = Window:CreateTab("  Speed & Jump", 4483362458)

-- WalkSpeed
MoveTab:CreateSection("🏃  WalkSpeed")

MoveTab:CreateSlider({
    Name         = "WalkSpeed",
    Range        = {1, 500},
    Increment    = 1,
    Suffix       = " spd",
    CurrentValue = 16,
    Flag         = "Slider_WalkSpeed",
    Callback     = function(v)
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = v end
    end,
})

MoveTab:CreateButton({
    Name = "🔄  Reset WalkSpeed → 16",
    Callback = function()
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = 16 end
        Rayfield:Notify({
            Title = "🔄  Reset Speed", Content = "WalkSpeed kembali ke 16",
            Duration = 2, Image = 4483362458,
        })
    end,
})

-- Dash Length
MoveTab:CreateSection("💨  Dash Length")

MoveTab:CreateSlider({
    Name         = "Dash Length",
    Range        = {10, 1000},
    Increment    = 10,
    Suffix       = " len",
    CurrentValue = 10,
    Flag         = "Slider_DashLength",
    Callback     = function(v)
        local char = getCharacter()
        if char then pcall(function() char:SetAttribute("DashLength", v) end) end
    end,
})

-- JumpPower
MoveTab:CreateSection("🦘  Jump Power")

MoveTab:CreateSlider({
    Name         = "Jump Height / Power",
    Range        = {7, 500},
    Increment    = 1,
    Suffix       = " jmp",
    CurrentValue = 7,
    Flag         = "Slider_JumpPower",
    Callback     = function(v)
        local hum = getHumanoid()
        if hum then
            hum.JumpPower = v
            pcall(function() hum.JumpHeight = v end)
        end
    end,
})

MoveTab:CreateButton({
    Name = "🔄  Reset Jump → 7",
    Callback = function()
        local hum = getHumanoid()
        if hum then
            hum.JumpPower = 7
            pcall(function() hum.JumpHeight = 7 end)
        end
        Rayfield:Notify({
            Title = "🔄  Reset Jump", Content = "Jump Power kembali ke default (7)",
            Duration = 2, Image = 4483362458,
        })
    end,
})

-- Preset
MoveTab:CreateSection("⚡  Preset Instan")

local presets = {
    { name = "🐢  Normal",  spd = 16,  jmp = 7,   label = "Speed 16 · Jump 7" },
    { name = "🐇  Medium",  spd = 50,  jmp = 50,  label = "Speed 50 · Jump 50" },
    { name = "🚀  Turbo",   spd = 200, jmp = 200, label = "Speed 200 · Jump 200" },
    { name = "💀  God Mode",spd = 500, jmp = 500, label = "Speed 500 · Jump 500 — HATI-HATI!" },
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
            Rayfield:Notify({
                Title   = p.name .. " Aktif!",
                Content = p.label,
                Duration = 2,
                Image    = 4483362458,
            })
        end,
    })
end


-- ╔══════════════════════════════╗
-- ║  NOTIF SELAMAT DATANG        ║
-- ╚══════════════════════════════╝
task.wait(0.8)
Rayfield:Notify({
    Title   = "🌸  Wowo Hub — Blush Canyon",
    Content = "Selamat datang, " .. LocalPlayer.DisplayName .. "!\nScript siap digunakan. Selamat bermain!",
    Duration = 5,
    Image    = thumbUrl ~= "" and thumbUrl or 4483362458,
})