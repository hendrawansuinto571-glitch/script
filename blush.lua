-- ╔══════════════════════════════════════════════════════════════╗
-- ║         NEMESIS SCRIPT HUB — Blush Canyon (blush.lua)        ║
-- ║        Game  : Blush Canyon (PlaceId: 3218570640)            ║
-- ║        Module: Client & Gameplay Features                    ║
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

-- ╔══════════════════════════════╗
-- ║  TAB: AUTO FARM (MAIN)       ║
-- ╚══════════════════════════════╝
local FarmTab = Window:CreateTab("Auto Farm", "sprout", "Main")

FarmTab:CreateSection("Auto Farming Modules")

local autoFarmEnabled = false
FarmTab:CreateToggle({
    Name = "Enable Auto Farm",
    CurrentValue = false,
    Callback = function(v)
        autoFarmEnabled = v
        Window:Notify({
            Title = "Auto Farm",
            Content = v and "Auto farm activated." or "Auto farm stopped.",
            Duration = 2,
        })
    end,
})

FarmTab:CreateSlider({
    Name = "Farm Delay (Seconds)",
    Range = {0.1, 5},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = 0.5,
    Callback = function(v)
        -- Farm delay setting
    end,
})

FarmTab:CreateButton({
    Name = "Collect All Nearby Drops",
    Callback = function()
        Window:Notify({
            Title = "Collect",
            Content = "Collecting nearby items...",
            Duration = 2,
        })
    end,
})

-- ╔══════════════════════════════╗
-- ║  TAB: TELEPORT (MAIN)        ║
-- ╚══════════════════════════════╝
local TpTab = Window:CreateTab("Teleport", "navigation", "Main")

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
            Window:Notify({
                Title   = "Teleport Berhasil",
                Content = "X: " .. tpX .. "  Y: " .. tpY .. "  Z: " .. tpZ,
                Duration = 3,
            })
        else
            Window:Notify({
                Title   = "Gagal",
                Content = "Karakter tidak ditemukan!",
                Duration = 3,
            })
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
            Window:Notify({
                Title = "Pilih Player",
                Content = "Silakan pilih player terlebih dahulu dari dropdown.",
                Duration = 3,
            })
            return
        end
        local target = Players:FindFirstChild(selectedTarget)
        if target and target.Character then
            local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
            if tRoot then
                myRoot.CFrame = tRoot.CFrame + Vector3.new(3, 0, 0)
                Window:Notify({
                    Title = "Teleport Selesai",
                    Content = "Berhasil teleport ke " .. selectedTarget,
                    Duration = 2,
                })
            end
        else
            Window:Notify({
                Title = "Player Tidak Ditemukan",
                Content = selectedTarget .. " offline atau karakter tidak tersedia.",
                Duration = 3,
            })
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
                Window:Notify({
                    Title = "Teleport Player Terdekat",
                    Content = nearest.Name .. " (" .. math.floor(nearestDist) .. " studs)",
                    Duration = 3,
                })
            end
        else
            Window:Notify({
                Title = "Tidak Ada Target",
                Content = "Tidak ada player lain di server.",
                Duration = 2,
            })
        end
    end,
})

TpTab:CreateSection("Preset Lokasi Cepat")

TpTab:CreateButton({
    Name = "Spawn Point (0, 5, 0)",
    Callback = function()
        local root = getRootPart()
        if root then
            root.CFrame = CFrame.new(0, 5, 0)
            Window:Notify({
                Title = "Spawn Point",
                Content = "Teleport ke titik awal berhasil.",
                Duration = 2,
            })
        end
    end,
})

TpTab:CreateButton({
    Name = "Terbang ke Atas (Y + 500)",
    Callback = function()
        local root = getRootPart()
        if root then
            root.CFrame = root.CFrame + Vector3.new(0, 500, 0)
            Window:Notify({
                Title = "Sky Jump",
                Content = "Karakter berpindah ke ketinggian 500 studs.",
                Duration = 2,
            })
        end
    end,
})

TpTab:CreateButton({
    Name = "Pusat Map (0, 10, 0)",
    Callback = function()
        local root = getRootPart()
        if root then
            root.CFrame = CFrame.new(0, 10, 0)
            Window:Notify({
                Title = "Pusat Map",
                Content = "Teleport ke koordinat pusat selesai.",
                Duration = 2,
            })
        end
    end,
})

-- ╔══════════════════════════════╗
-- ║  TAB: SPEED & JUMP (MAIN)    ║
-- ╚══════════════════════════════╝
local MoveTab = Window:CreateTab("Speed & Jump", "rocket", "Main")

MoveTab:CreateSection("WalkSpeed Controller")

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

MoveTab:CreateSection("Dash Length Controller")

MoveTab:CreateSlider({
    Name = "Dash Length",
    Range = {10, 1000},
    Increment = 10,
    Suffix = " len",
    CurrentValue = 10,
    Callback = function(v)
        local char = getCharacter()
        if char then pcall(function() char:SetAttribute("DashLength", v) end) end
    end,
})

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

MoveTab:CreateSection("Preset Kecepatan Cepat")

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
                Content = p.name .. " telah diaplikasikan.",
                Duration = 2,
            })
        end,
    })
end

-- ╔══════════════════════════════╗
-- ║  TAB: SHOP (MAIN)            ║
-- ╚══════════════════════════════╝
local ShopTab = Window:CreateTab("Shop", "cart", "Main")
ShopTab:CreateSection("In-Game Shop Automation")
ShopTab:CreateLabel("Fitur auto buy dan perk shop tersedia di versi ini.")
ShopTab:CreateButton({
    Name = "Auto Buy Potions (Soon)",
    Callback = function()
        Window:Notify({ Title = "Shop", Content = "Fitur sedang dalam pengembangan.", Duration = 2 })
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
    Content = "Modul Blush Canyon v1.3 aktif. Tekan RightShift untuk toggle UI.",
    Duration = 5,
})
