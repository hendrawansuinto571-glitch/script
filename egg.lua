-- ╔══════════════════════════════════════════════════════════════╗
-- ║        PAK WOWO SCRIPT HUB — egg.lua                         ║
-- ║        Game  : Egg Farm / Pet Adventure                      ║
-- ║        Author: Azeey | Beta                                  ║
-- ╚══════════════════════════════════════════════════════════════╝

-- Load Rayfield UI Library dengan Fallback (mencegah error redirect pada executor)
local Rayfield = nil
local okLoad, resLoad = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if okLoad and resLoad then
    Rayfield = resLoad
else
    local okRaw, resRaw = pcall(function()
        return loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua'))()
    end)
    if okRaw and resRaw then
        Rayfield = resRaw
    else
        warn("Gagal memuat Rayfield UI Library. Periksa koneksi internet atau executor kamu.")
        return
    end
end

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local LocalPlayer       = Players.LocalPlayer

-- ═══════════════════════════════════════════
--  HELPER KARAKTER
-- ═══════════════════════════════════════════
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
--  REMOTE SERVICES & HELPERS
-- ═══════════════════════════════════════════
local function getUassetRequest()
    local uasset = ReplicatedStorage:FindFirstChild("UassetCore")
    return uasset and uasset:FindFirstChild("Request")
end

local function getGameplayRemote(name)
    local gp = ReplicatedStorage:FindFirstChild("GameplayRemotes")
    return gp and gp:FindFirstChild(name)
end

local function getFeedsRemote(name)
    local feeds = ReplicatedStorage:FindFirstChild("UassetFeeds")
    return feeds and feeds:FindFirstChild(name)
end

local function getDevPanel()
    local gp = ReplicatedStorage:FindFirstChild("GameplayRemotes")
    return gp and gp:FindFirstChild("DevPanel")
end

-- Teleport helper ke part / model
local function teleportTo(cfOrInst, offset)
    local root = getRootPart()
    if not root then return false end
    offset = offset or Vector3.new(0, 3, 0)

    if typeof(cfOrInst) == "CFrame" then
        root.CFrame = cfOrInst + offset
        return true
    elseif typeof(cfOrInst) == "Vector3" then
        root.CFrame = CFrame.new(cfOrInst + offset)
        return true
    elseif typeof(cfOrInst) == "Instance" then
        if cfOrInst:IsA("BasePart") then
            root.CFrame = cfOrInst.CFrame + offset
            return true
        elseif cfOrInst:IsA("Model") then
            local pPart = cfOrInst.PrimaryPart or cfOrInst:FindFirstChildWhichIsA("BasePart", true)
            if pPart then
                root.CFrame = pPart.CFrame + offset
                return true
            end
        end
    end
    return false
end

-- Cari Plot milik pemain sendiri
local function getMyPlot()
    local runtime = workspace:FindFirstChild("GameplayRuntime")
    local plotContents = runtime and runtime:FindFirstChild("PlotContents")
    if plotContents then
        for _, plot in ipairs(plotContents:GetChildren()) do
            if plot:GetAttribute("OwnerUserId") == LocalPlayer.UserId or plot.Name == tostring(LocalPlayer.UserId) then
                return plot
            end
        end
    end

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:GetAttribute("OwnerUserId") == LocalPlayer.UserId then
            return obj
        end
    end
    return nil
end

-- ═══════════════════════════════════════════
--  WINDOW UTAMA
-- ═══════════════════════════════════════════
local Window = Rayfield:CreateWindow({
    Name = "🥚 Pak Wowo  ·  Egg Farm Hub",
    LoadingTitle  = "Wowo Script Hub",
    LoadingSubtitle = "by Azeey  ·  Beta",
    ConfigurationSaving = {
        Enabled    = true,
        FolderName = "WowoHub",
        FileName   = "EggConfig",
    },
    Discord = { Enabled = false },
    KeySystem = false,
})

-- Variabel Auto Farm Global
local autoGrabRiver    = false
local autoInstantHatch = false
local autoHatchPanel   = false
local autoStoreEgg     = false
local autoFeedPets     = false
local autoRestockFood  = false
local autoRebirth      = false
local autoOffline      = false
local autoSwingBat     = false
local autoDailyReward  = false
local autoFreeGift     = false
local autoSellEggs     = false
local grabDelay        = 0.2

-- ╔══════════════════════════════╗
-- ║  TAB 1 – INFORMASI           ║
-- ╚══════════════════════════════╝
local InfoTab = Window:CreateTab("  Info", 4483362458)

InfoTab:CreateSection("👤  Profil Player")

InfoTab:CreateButton({
    Name = "🖼️  Lihat Profil Roblox",
    Callback = function()
        Rayfield:Notify({
            Title   = "👤  " .. LocalPlayer.DisplayName,
            Content = "Username : @" .. LocalPlayer.Name
                    .. "\nUser ID  : " .. tostring(LocalPlayer.UserId)
                    .. "\nUmur Akun: " .. tostring(LocalPlayer.AccountAge) .. " hari",
            Duration = 6,
            Image    = 4483362458,
        })
    end,
})

InfoTab:CreateLabel("Username    :  " .. LocalPlayer.Name)
InfoTab:CreateLabel("Display Name:  " .. LocalPlayer.DisplayName)
InfoTab:CreateLabel("User ID     :  " .. tostring(LocalPlayer.UserId))
InfoTab:CreateLabel("Umur Akun   :  " .. tostring(LocalPlayer.AccountAge) .. " hari")

InfoTab:CreateSection("📋  Informasi Script")
InfoTab:CreateLabel("Script      :  Wowo Script Hub")
InfoTab:CreateLabel("Game        :  Egg Farm / Pet Adventure")
InfoTab:CreateLabel("Versi       :  Beta")
InfoTab:CreateLabel("Pembuat     :  Azeey")
InfoTab:CreateLabel("UI Library  :  Rayfield")

InfoTab:CreateSection("✅  Fitur Tersedia")
InfoTab:CreateLabel("🔥  MASTER AUTO FARM — 1 Toggle untuk Menjalankan Semua!")
InfoTab:CreateLabel("🌊  Auto Grab — Telur Sungai & Dropped Eggs")
InfoTab:CreateLabel("🐣  Auto Hatch — Instant Hatch, Panel Hatch & Auto Store")
InfoTab:CreateLabel("🐾  Auto Feed & Pets — Equip Best, Auto Feed Plot Pets")
InfoTab:CreateLabel("🔄  Auto Farm — Auto Rebirth, Offline Income & Bat Swing")
InfoTab:CreateLabel("🎁  Auto Claim — Daily Reward, Free Gift & Admin Abuse")
InfoTab:CreateLabel("💰  Auto Sell — Jual Telur Otomatis ke Booth")
InfoTab:CreateLabel("📍  Teleport — Plot Sendiri, Sungai, Toko & Player")
InfoTab:CreateLabel("⚡  Speed & Jump — Slider & Preset Instan")

InfoTab:CreateSection("⚠️  Disclaimer")
InfoTab:CreateLabel("Gunakan script ini dengan bijak.")
InfoTab:CreateLabel("Risiko banned ditanggung pengguna.")


-- ╔══════════════════════════════╗
-- ║  TAB 2 – EGG & HATCH         ║
-- ╚══════════════════════════════╝
local EggTab = Window:CreateTab("  Egg & Hatch", 4483362458)

-- Master Auto Farm Telur (All-in-One)
EggTab:CreateSection("🔥  Master Auto Farm Telur")

EggTab:CreateToggle({
    Name = "🔥  MASTER AUTO FARM TELUR (All-in-One)",
    CurrentValue = false,
    Flag = "Toggle_MasterAutoFarm",
    Callback = function(val)
        autoGrabRiver    = val
        autoInstantHatch = val
        autoHatchPanel   = val
        autoStoreEgg     = val
        autoFeedPets     = val
        autoSellEggs     = val
        autoRebirth      = val
        autoOffline      = val

        Rayfield:Notify({
            Title   = val and "🔥  Master Farm Aktif!" or "🛑  Master Farm Nonaktif",
            Content = val and "Grab Telur Sungai + Instant Hatch + Auto Store + Auto Feed + Auto Sell AKTIF!" or "Semua auto farm telah dinonaktifkan.",
            Duration = 3, Image = 4483362458,
        })
    end,
})

-- Auto Grab River
EggTab:CreateSection("🌊  Auto Grab Telur Sungai")

EggTab:CreateToggle({
    Name = "⚡  Auto Grab Telur di Sungai",
    CurrentValue = false,
    Flag = "Toggle_AutoGrabRiver",
    Callback = function(val)
        autoGrabRiver = val
        if val then
            Rayfield:Notify({
                Title   = "🌊  Auto Grab Aktif",
                Content = "Sedang mengambil telur yang mengalir di sungai...",
                Duration = 2, Image = 4483362458,
            })
        end
    end,
})

EggTab:CreateSlider({
    Name         = "Jeda Grab (Detik)",
    Range        = {0.1, 1},
    Increment    = 0.05,
    Suffix       = " s",
    CurrentValue = 0.2,
    Flag         = "Slider_GrabDelay",
    Callback     = function(v)
        grabDelay = v
    end,
})

-- ═══════════════════════════════════════════
--  FUNGSI AUTO FARM TELUR (GRAB + SAFE ZONE TP)
-- ═══════════════════════════════════════════

-- Pastikan Egg Grabber ter-equip di karakter
local function ensureEggGrabberEquipped()
    local char = getCharacter()
    local hum  = getHumanoid()
    if not char or not hum then return false end

    -- Sudah ada di tangan?
    if char:FindFirstChild("Egg Grabber") then return true end

    -- Coba equip dari Backpack
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        local tool = bp:FindFirstChild("Egg Grabber")
        if tool then
            pcall(function() hum:EquipTool(tool) end)
            task.wait(0.3)
            return char:FindFirstChild("Egg Grabber") ~= nil
        end
    end
    return false
end

-- Ambil 1 telur dari sungai lalu langsung TP ke plot / safe zone
local function farmSingleEgg()
    -- 1. Cek apakah sudah membawa telur
    if LocalPlayer:GetAttribute("CarriedEggId") then return end
    if LocalPlayer:GetAttribute("InSaveZone") or LocalPlayer:GetAttribute("InSafeZone") then return end

    local runtime    = workspace:FindFirstChild("GameplayRuntime")
    local activeEggs = runtime and runtime:FindFirstChild("ActiveEggs")
    local grabRemote = getGameplayRemote("Grab")
    if not activeEggs or not grabRemote then return end

    -- 2. Cari telur terdekat yang belum diklaim
    local root = getRootPart()
    if not root then return end

    local nearest, nearestPart, nearestDist = nil, nil, math.huge
    for _, egg in ipairs(activeEggs:GetChildren()) do
        if egg:IsA("Model") and not egg:GetAttribute("ClaimedBy") then
            local pp = egg.PrimaryPart or egg:FindFirstChildWhichIsA("BasePart", true)
            if pp then
                local d = (root.Position - pp.Position).Magnitude
                if d < nearestDist then
                    nearestDist = d
                    nearest     = egg
                    nearestPart = pp
                end
            end
        end
    end
    if not nearest then return end

    -- 3. Equip Egg Grabber
    if not ensureEggGrabberEquipped() then return end

    -- 4. Teleport ke dekat telur
    root.CFrame = nearestPart.CFrame + Vector3.new(0, 3, 4)
    task.wait(0.1)

    -- 5. Fire Grab remote
    local shotTag = tostring(math.random(1000, 9999)) .. "_" .. tostring(math.floor(os.clock() * 1000))
    pcall(function()
        grabRemote:FireServer(nearest, shotTag, { TargetOffset = Vector3.new(0, 0, 0) })
    end)
    task.wait(0.35)

    -- 6. Jika berhasil grab (ada CarriedEggId), langsung TP ke plot / safe zone
    if LocalPlayer:GetAttribute("CarriedEggId") then
        local plot = getMyPlot()
        if plot then
            local pp = plot.PrimaryPart or plot:FindFirstChildWhichIsA("BasePart", true)
            if pp then root.CFrame = pp.CFrame + Vector3.new(0, 4, 0) end
        else
            -- Fallback: cari SafeZone di workspace
            local safeZone = workspace:FindFirstChild("SafeZone") or workspace:FindFirstChild("SaveZone")
            if safeZone then
                local sp = safeZone:IsA("Model") and (safeZone.PrimaryPart or safeZone:FindFirstChildWhichIsA("BasePart", true))
                           or (safeZone:IsA("BasePart") and safeZone)
                if sp then root.CFrame = sp.CFrame + Vector3.new(0, 4, 0) end
            end
        end
        task.wait(0.4)

        -- 7. Store telur ke inventory
        pcall(function()
            local req = getUassetRequest()
            if req then
                req:FireServer("StoreEgg", "Back")
                task.wait(0.15)
                req:FireServer("StoreEgg", nil)
            end
        end)
        task.wait(0.3)
    end
end

task.spawn(function()
    while true do
        if autoGrabRiver then
            pcall(farmSingleEgg)
        end
        task.wait(autoGrabRiver and grabDelay or 0.5)
    end
end)

EggTab:CreateButton({
    Name = "🎯  Grab 1 Telur + TP Safe Zone (Manual)",
    Callback = function()
        local ok = false
        pcall(function()
            farmSingleEgg()
            ok = true
        end)
        Rayfield:Notify({
            Title   = "🎯  Grab Telur",
            Content = ok and "Grab telur + TP Safe Zone berhasil dijalankan!" or "Gagal grab telur (tidak ada telur / Egg Grabber tidak ditemukan).",
            Duration = 3, Image = 4483362458,
        })
    end,
})

EggTab:CreateButton({
    Name = "🧭  Teleport ke Telur Sungai Terdekat",
    Callback = function()
        local root = getRootPart()
        if not root then return end
        local nearest, nearestDist = nil, math.huge
        pcall(function()
            local runtime = workspace:FindFirstChild("GameplayRuntime")
            local activeEggs = runtime and runtime:FindFirstChild("ActiveEggs")
            if activeEggs then
                for _, egg in ipairs(activeEggs:GetChildren()) do
                    local pPart = egg:IsA("Model") and (egg.PrimaryPart or egg:FindFirstChildWhichIsA("BasePart", true))
                    if pPart and not egg:GetAttribute("ClaimedBy") then
                        local d = (root.Position - pPart.Position).Magnitude
                        if d < nearestDist then
                            nearestDist = d
                            nearest = pPart
                        end
                    end
                end
            end
        end)

        if nearest then
            root.CFrame = nearest.CFrame + Vector3.new(0, 4, 0)
            Rayfield:Notify({
                Title   = "✅  Teleport Sukses",
                Content = "Tiba di telur terdekat (Jarak: " .. math.floor(nearestDist) .. " studs)!",
                Duration = 2, Image = 4483362458,
            })
        else
            Rayfield:Notify({
                Title   = "❌  Tidak Ada Telur",
                Content = "Tidak ada telur aktif di sungai saat ini.",
                Duration = 2, Image = 4483362458,
            })
        end
    end,
})

-- Hatching & Storage
EggTab:CreateSection("🐣  Auto Hatching & Storage")

EggTab:CreateToggle({
    Name = "⚡  Auto Instant Hatch (Lewati Timer)",
    CurrentValue = false,
    Flag = "Toggle_InstantHatch",
    Callback = function(val)
        autoInstantHatch = val
    end,
})

EggTab:CreateToggle({
    Name = "🐣  Auto Hatch Telur Siap (Panel & Plot)",
    CurrentValue = false,
    Flag = "Toggle_AutoHatch",
    Callback = function(val)
        autoHatchPanel = val
    end,
})

EggTab:CreateToggle({
    Name = "📦  Auto Store Telur ke Inventory / Back",
    CurrentValue = false,
    Flag = "Toggle_AutoStore",
    Callback = function(val)
        autoStoreEgg = val
    end,
})

task.spawn(function()
    while true do
        if autoInstantHatch or autoHatchPanel then
            pcall(function()
                local req = getUassetRequest()
                if req then
                    local runtime = workspace:FindFirstChild("GameplayRuntime")
                    local plotContents = runtime and runtime:FindFirstChild("PlotContents")
                    if plotContents then
                        for _, plot in ipairs(plotContents:GetChildren()) do
                            if plot:GetAttribute("OwnerUserId") == LocalPlayer.UserId or plot.Name == tostring(LocalPlayer.UserId) then
                                for _, item in ipairs(plot:GetChildren()) do
                                    local hatchId = item:GetAttribute("HatchId")
                                    if hatchId then
                                        if autoInstantHatch then
                                            req:FireServer("InstantHatch", hatchId)
                                        end
                                        if autoHatchPanel then
                                            req:FireServer("HatchFromPanel", hatchId)
                                            req:FireServer("Hatch", hatchId)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end

        if autoStoreEgg then
            pcall(function()
                local req = getUassetRequest()
                if req then
                    req:FireServer("StoreEgg", nil)
                    req:FireServer("StoreEgg", "Back")
                end
            end)
        end

        task.wait(1.5)
    end
end)

EggTab:CreateButton({
    Name = "✨  Hatch Semua Telur Siap Sekarang",
    Callback = function()
        local count = 0
        pcall(function()
            local req = getUassetRequest()
            local runtime = workspace:FindFirstChild("GameplayRuntime")
            local plotContents = runtime and runtime:FindFirstChild("PlotContents")
            if req and plotContents then
                for _, plot in ipairs(plotContents:GetChildren()) do
                    if plot:GetAttribute("OwnerUserId") == LocalPlayer.UserId or plot.Name == tostring(LocalPlayer.UserId) then
                        for _, item in ipairs(plot:GetChildren()) do
                            local hatchId = item:GetAttribute("HatchId")
                            if hatchId then
                                count = count + 1
                                req:FireServer("InstantHatch", hatchId)
                                req:FireServer("HatchFromPanel", hatchId)
                                req:FireServer("Hatch", hatchId)
                            end
                        end
                    end
                end
            end
        end)
        Rayfield:Notify({
            Title   = "🐣  Hatch Triggered",
            Content = count > 0 and ("Memproses hatch pada " .. count .. " telur...") or "Tidak ada telur dalam plot.",
            Duration = 3, Image = 4483362458,
        })
    end,
})

EggTab:CreateButton({
    Name = "🗑️  Drop Carried Egg (Jatuhkan Telur Bawaan)",
    Callback = function()
        pcall(function()
            local carriedId = LocalPlayer:GetAttribute("CarriedEggId")
            local eggGame = ReplicatedStorage:FindFirstChild("EggGame")
            local requests = eggGame and eggGame:FindFirstChild("Requests")
            if requests and carriedId then
                requests:FireServer("DropCarriedEgg", carriedId)
            end
            local req = getUassetRequest()
            if req and carriedId then
                req:FireServer("DropEgg", carriedId)
            end
        end)
        Rayfield:Notify({
            Title   = "🗑️  Drop Egg",
            Content = "Permintaan menjatuhkan telur telah dikirim.",
            Duration = 2, Image = 4483362458,
        })
    end,
})

EggTab:CreateButton({
    Name = "🎖️  Klaim Semua Hadiah Egg Index",
    Callback = function()
        pcall(function()
            local req = getUassetRequest()
            if req then
                for stage = 1, 20 do
                    req:FireServer("ClaimIndexReward", stage)
                end
            end
        end)
        Rayfield:Notify({
            Title   = "🎖️  Index Reward",
            Content = "Semua stage reward index telah diklaim!",
            Duration = 3, Image = 4483362458,
        })
    end,
})

-- Luck Board
EggTab:CreateSection("🍀  Hatch Luck Boost")

EggTab:CreateToggle({
    Name = "🍀  Aktifkan Hatch Luck Boost",
    CurrentValue = true,
    Flag = "Toggle_LuckEnabled",
    Callback = function(val)
        pcall(function()
            local req = getUassetRequest()
            if req then
                req:FireServer("SetHatchLuckEnabled", val)
            end
        end)
    end,
})

EggTab:CreateButton({
    Name = "⬆️  Upgrade Luck Board (+1000 Level)",
    Callback = function()
        pcall(function()
            local req = getUassetRequest()
            if req then
                req:FireServer("UpgradeLuck", { Count = 1000, ExpectedLevel = 0 })
            end
        end)
        Rayfield:Notify({
            Title   = "🍀  Upgrade Luck",
            Content = "Request upgrade luck terkirim!",
            Duration = 2, Image = 4483362458,
        })
    end,
})

EggTab:CreateButton({
    Name = "✨  Klaim Free Luck 100",
    Callback = function()
        pcall(function()
            local req = getUassetRequest()
            if req then
                req:FireServer("Luck100")
            end
        end)
        Rayfield:Notify({
            Title   = "✨  Free Luck 100",
            Content = "Klaim Free Luck 100 terkirim!",
            Duration = 2, Image = 4483362458,
        })
    end,
})


-- ╔══════════════════════════════╗
-- ║  TAB 3 – PETS & FEED         ║
-- ╚══════════════════════════════╝
local PetTab = Window:CreateTab("  Pets & Feed", 4483362458)

PetTab:CreateSection("🐾  Manajemen Pet")

PetTab:CreateButton({
    Name = "🌟  Equip Best Pets (Pet Terbaik)",
    Callback = function()
        pcall(function()
            local req = getUassetRequest()
            if req then
                req:FireServer("EquipBestPets", true)
            end
        end)
        Rayfield:Notify({
            Title   = "🌟  Equip Best Pets",
            Content = "Pet terbaik telah dipasangkan!",
            Duration = 2, Image = 4483362458,
        })
    end,
})

PetTab:CreateButton({
    Name = "🚶  Unfollow Pet (Lepas Pet Ikut)",
    Callback = function()
        pcall(function()
            local req = getUassetRequest()
            if req then
                req:FireServer("UnfollowPet", nil)
            end
        end)
        Rayfield:Notify({
            Title   = "🚶  Unfollow Pet",
            Content = "Pet yang mengikuti dilepaskan.",
            Duration = 2, Image = 4483362458,
        })
    end,
})

PetTab:CreateButton({
    Name = "🐎  Dismount Pet (Turun Pet Tunggangan)",
    Callback = function()
        pcall(function()
            local petAction = getGameplayRemote("PetAction")
            if petAction then
                petAction:FireServer("Dismount")
            end
        end)
        Rayfield:Notify({
            Title   = "🐎  Dismount",
            Content = "Dismount berhasil.",
            Duration = 2, Image = 4483362458,
        })
    end,
})

PetTab:CreateButton({
    Name = "🔄  Refresh Data Pet & Plot",
    Callback = function()
        pcall(function()
            local req = getUassetRequest()
            if req then
                req:FireServer("Refresh", nil)
            end
        end)
        Rayfield:Notify({
            Title   = "🔄  Refresh",
            Content = "Status pet dan plot diperbarui.",
            Duration = 2, Image = 4483362458,
        })
    end,
})

PetTab:CreateSection("🍖  Auto Feeding (Beri Makan Pet)")

PetTab:CreateToggle({
    Name = "🍖  Auto Feed Semua Pet di Plot",
    CurrentValue = false,
    Flag = "Toggle_AutoFeed",
    Callback = function(val)
        autoFeedPets = val
    end,
})

PetTab:CreateToggle({
    Name = "🔄  Auto Restock Toko Makanan",
    CurrentValue = false,
    Flag = "Toggle_AutoRestock",
    Callback = function(val)
        autoRestockFood = val
    end,
})

task.spawn(function()
    while true do
        if autoFeedPets then
            pcall(function()
                local feedRemote = getFeedsRemote("FeedPet")
                local runtime = workspace:FindFirstChild("GameplayRuntime")
                local plotContents = runtime and runtime:FindFirstChild("PlotContents")
                if feedRemote and plotContents then
                    for _, plot in ipairs(plotContents:GetChildren()) do
                        if plot:GetAttribute("OwnerUserId") == LocalPlayer.UserId or plot.Name == tostring(LocalPlayer.UserId) then
                            for _, pet in ipairs(plot:GetChildren()) do
                                local petId = pet:GetAttribute("PetId") or pet:GetAttribute("FeedPetId")
                                if petId then
                                    feedRemote:FireServer(petId, 1)
                                end
                            end
                        end
                    end
                end
            end)
        end

        if autoRestockFood then
            pcall(function()
                local restock = getFeedsRemote("RequestFoodRestock")
                if restock then
                    restock:FireServer()
                end
            end)
        end

        task.wait(2.5)
    end
end)

PetTab:CreateButton({
    Name = "🍖  Beri Makan Pet Sekarang (Feed Once)",
    Callback = function()
        local count = 0
        pcall(function()
            local feedRemote = getFeedsRemote("FeedPet")
            local runtime = workspace:FindFirstChild("GameplayRuntime")
            local plotContents = runtime and runtime:FindFirstChild("PlotContents")
            if feedRemote and plotContents then
                for _, plot in ipairs(plotContents:GetChildren()) do
                    if plot:GetAttribute("OwnerUserId") == LocalPlayer.UserId or plot.Name == tostring(LocalPlayer.UserId) then
                        for _, pet in ipairs(plot:GetChildren()) do
                            local petId = pet:GetAttribute("PetId") or pet:GetAttribute("FeedPetId")
                            if petId then
                                count = count + 1
                                feedRemote:FireServer(petId, 1)
                            end
                        end
                    end
                end
            end
        end)
        Rayfield:Notify({
            Title   = "🍖  Feeding",
            Content = count > 0 and ("Memberi makan " .. count .. " pet...") or "Tidak ada pet di plot.",
            Duration = 2, Image = 4483362458,
        })
    end,
})

PetTab:CreateButton({
    Name = "🏪  Restock Makanan Toko Sekarang",
    Callback = function()
        pcall(function()
            local restock = getFeedsRemote("RequestFoodRestock")
            if restock then
                restock:FireServer()
            end
        end)
        Rayfield:Notify({
            Title   = "🏪  Restock",
            Content = "Permintaan restock makanan terkirim!",
            Duration = 2, Image = 4483362458,
        })
    end,
})

PetTab:CreateButton({
    Name = "🛒  Beli Slot Makanan Tambahan",
    Callback = function()
        pcall(function()
            local buySlot = getFeedsRemote("BuyFoodSlot")
            if buySlot then
                buySlot:FireServer(1, 9)
            end
        end)
        Rayfield:Notify({
            Title   = "🛒  Buy Food Slot",
            Content = "Slot makanan dibeli jika syarat terpenuhi.",
            Duration = 2, Image = 4483362458,
        })
    end,
})


-- ╔══════════════════════════════╗
-- ║  TAB 4 – AUTO FARM           ║
-- ╚══════════════════════════════╝
local FarmTab = Window:CreateTab("  Auto Farm", 4483362458)

FarmTab:CreateSection("🔄  Auto Rebirth & Income")

FarmTab:CreateToggle({
    Name = "🔄  Auto Rebirth",
    CurrentValue = false,
    Flag = "Toggle_AutoRebirth",
    Callback = function(val)
        autoRebirth = val
    end,
})

FarmTab:CreateToggle({
    Name = "💰  Auto Klaim Offline Income",
    CurrentValue = false,
    Flag = "Toggle_AutoOffline",
    Callback = function(val)
        autoOffline = val
    end,
})

task.spawn(function()
    while true do
        if autoRebirth then
            pcall(function()
                local req = getUassetRequest()
                if req then
                    req:FireServer("Rebirth", nil)
                end
            end)
        end

        if autoOffline then
            pcall(function()
                local req = getUassetRequest()
                if req then
                    req:FireServer("ResolveOfflineIncome", nil)
                end
            end)
        end

        task.wait(3)
    end
end)

FarmTab:CreateButton({
    Name = "🔄  Rebirth Sekarang (Sekali)",
    Callback = function()
        pcall(function()
            local req = getUassetRequest()
            if req then
                req:FireServer("Rebirth", nil)
            end
        end)
        Rayfield:Notify({
            Title   = "🔄  Rebirth",
            Content = "Permintaan Rebirth dikirim ke server.",
            Duration = 2, Image = 4483362458,
        })
    end,
})

FarmTab:CreateButton({
    Name = "💰  Klaim Offline Income Sekarang",
    Callback = function()
        pcall(function()
            local req = getUassetRequest()
            if req then
                req:FireServer("ResolveOfflineIncome", nil)
            end
        end)
        Rayfield:Notify({
            Title   = "💰  Offline Income",
            Content = "Offline income berhasil diklaim!",
            Duration = 2, Image = 4483362458,
        })
    end,
})

FarmTab:CreateSection("🏏  Auto Bat Swing")

FarmTab:CreateToggle({
    Name = "🏏  Auto Swing Bat (Pukul Tongkat Cepat)",
    CurrentValue = false,
    Flag = "Toggle_AutoBat",
    Callback = function(val)
        autoSwingBat = val
    end,
})

task.spawn(function()
    while true do
        if autoSwingBat then
            pcall(function()
                local bat = ReplicatedStorage:FindFirstChild("UassetBat")
                if bat then
                    bat:FireServer("Swing")
                end
            end)
            task.wait(0.15)
        else
            task.wait(0.5)
        end
    end
end)

FarmTab:CreateButton({
    Name = "🏏  Swing Bat Sekali",
    Callback = function()
        pcall(function()
            local bat = ReplicatedStorage:FindFirstChild("UassetBat")
            if bat then
                bat:FireServer("Swing")
            end
        end)
    end,
})

FarmTab:CreateSection("🎁  Auto Claim Hadiah & Event")

FarmTab:CreateToggle({
    Name = "🎁  Auto Claim Daily Reward",
    CurrentValue = false,
    Flag = "Toggle_DailyReward",
    Callback = function(val)
        autoDailyReward = val
    end,
})

FarmTab:CreateToggle({
    Name = "📦  Auto Claim Free Gift (Chest)",
    CurrentValue = false,
    Flag = "Toggle_FreeGift",
    Callback = function(val)
        autoFreeGift = val
    end,
})

task.spawn(function()
    while true do
        if autoDailyReward then
            pcall(function()
                local daily = ReplicatedStorage:FindFirstChild("DailyRewardRequest")
                if daily then
                    daily:InvokeServer("Claim")
                end
            end)
        end

        if autoFreeGift then
            pcall(function()
                local freeGift = ReplicatedStorage:FindFirstChild("FreeGiftRequest")
                if freeGift then
                    freeGift:InvokeServer("Claim")
                end
            end)
        end

        task.wait(15)
    end
end)

FarmTab:CreateButton({
    Name = "🎁  Klaim Daily Reward Sekarang",
    Callback = function()
        local res = nil
        pcall(function()
            local daily = ReplicatedStorage:FindFirstChild("DailyRewardRequest")
            if daily then
                res = daily:InvokeServer("Claim")
            end
        end)
        Rayfield:Notify({
            Title   = "🎁  Daily Reward",
            Content = res and res.Message or "Permintaan klaim hadiah harian dikirim.",
            Duration = 3, Image = 4483362458,
        })
    end,
})

FarmTab:CreateButton({
    Name = "📦  Klaim Free Gift Sekarang",
    Callback = function()
        local res = nil
        pcall(function()
            local freeGift = ReplicatedStorage:FindFirstChild("FreeGiftRequest")
            if freeGift then
                res = freeGift:InvokeServer("Claim")
            end
        end)
        Rayfield:Notify({
            Title   = "📦  Free Gift",
            Content = res and res.Message or "Permintaan klaim free gift dikirim.",
            Duration = 3, Image = 4483362458,
        })
    end,
})

FarmTab:CreateButton({
    Name = "⚡  Klaim Semua Hadiah Admin Abuse",
    Callback = function()
        pcall(function()
            local adminReq = ReplicatedStorage:FindFirstChild("AdminAbuseRequest")
            if adminReq then
                local state = adminReq:InvokeServer("State")
                if state and state.Id then
                    adminReq:InvokeServer("Claim", state.Id, 1)
                    adminReq:InvokeServer("Claim", state.Id, 2)
                    adminReq:InvokeServer("Claim", state.Id, 3)
                end
            end
        end)
        Rayfield:Notify({
            Title   = "⚡  Admin Abuse",
            Content = "Semua reward admin abuse berhasil dicoba diklaim!",
            Duration = 3, Image = 4483362458,
        })
    end,
})

FarmTab:CreateSection("🏪  Auto Sell Telur")

FarmTab:CreateToggle({
    Name = "💸  Auto Sell All Eggs (Jual Otomatis)",
    CurrentValue = false,
    Flag = "Toggle_AutoSell",
    Callback = function(val)
        autoSellEggs = val
    end,
})

task.spawn(function()
    while true do
        if autoSellEggs then
            pcall(function()
                local sellRemotes = ReplicatedStorage:FindFirstChild("UassetSellRemotes")
                local req = sellRemotes and sellRemotes:FindFirstChild("Request")
                if req then
                    req:InvokeServer("SellAllEggs")
                    req:InvokeServer("SellAll")
                end
            end)
        end
        task.wait(6)
    end
end)

FarmTab:CreateButton({
    Name = "💸  Jual Semua Telur Sekarang (Sell All)",
    Callback = function()
        pcall(function()
            local sellRemotes = ReplicatedStorage:FindFirstChild("UassetSellRemotes")
            local req = sellRemotes and sellRemotes:FindFirstChild("Request")
            if req then
                req:InvokeServer("SellAllEggs")
                req:InvokeServer("SellAll")
            end
        end)
        Rayfield:Notify({
            Title   = "💸  Sell All Eggs",
            Content = "Semua telur dijual ke Sell Booth!",
            Duration = 2, Image = 4483362458,
        })
    end,
})


-- ╔══════════════════════════════╗
-- ║  TAB 5 – SHOP & GEAR         ║
-- ╚══════════════════════════════╝
local ShopTab = Window:CreateTab("  Shop & Gear", 4483362458)

ShopTab:CreateSection("🧺  Egg Grabber Shop")

-- Toggle buka/tutup Egg Grabber Shop UI
local shopIsOpen = false
ShopTab:CreateButton({
    Name = "🛒  Buka / Tutup Egg Grabber Shop",
    Callback = function()
        pcall(function()
            local pGui   = LocalPlayer:FindFirstChild("PlayerGui")
            local shopUi = pGui and pGui:FindFirstChild("EggGrabberShopUI")
            if not shopUi then return end

            shopIsOpen = not shopIsOpen

            -- Panggil SetOpen agar animation/state di-handle game
            local styleOk, styleModule = pcall(function()
                return require(ReplicatedStorage:FindFirstChild("UassetEggGrabberShopStyle"))
            end)
            if styleOk and styleModule and styleModule.SetOpen then
                styleModule.SetOpen(shopUi, shopIsOpen)
            end

            -- MenuFx owner
            local fxOk, fxModule = pcall(function()
                return require(ReplicatedStorage:FindFirstChild("MenuFx"))
            end)
            if fxOk and fxModule and fxModule.SetOwner then
                fxModule.SetOwner(shopUi, shopIsOpen)
            end

            -- Fallback: langsung toggle Visible
            if shopUi:FindFirstChild("Overlay") then
                shopUi.Overlay.Visible = shopIsOpen
            end
            if shopUi:FindFirstChild("Panel") then
                shopUi.Panel.Visible = shopIsOpen
            end
        end)
        Rayfield:Notify({
            Title   = shopIsOpen and "🛒  Egg Grabber Shop Dibuka" or "🚪  Egg Grabber Shop Ditutup",
            Content = shopIsOpen and "UI Egg Grabber Shop terbuka!" or "UI Egg Grabber Shop ditutup.",
            Duration = 2, Image = 4483362458,
        })
    end,
})

ShopTab:CreateButton({
    Name = "⚡  Beli & Equip Grabber Terbaru",
    Callback = function()
        local bought = 0
        pcall(function()
            local grabberShop = ReplicatedStorage:FindFirstChild("UassetEggGrabberShop")
            if not grabberShop then return end

            -- WAJIB: panggil "Get" dulu agar server init state
            local owned = grabberShop:InvokeServer("Get")

            local cfg  = ReplicatedStorage:FindFirstChild("UassetEggGrabberConfig")
            local conf = cfg and pcall(function() return require(cfg) end) and require(cfg)
            local order = conf and conf.Order

            if order then
                for _, grabId in ipairs(order) do
                    -- Cek apakah sudah dimiliki
                    local alreadyOwned = false
                    if owned and type(owned) == "table" then
                        for _, ownedId in ipairs(owned) do
                            if ownedId == grabId then alreadyOwned = true; break end
                        end
                    end
                    if not alreadyOwned then
                        pcall(function() grabberShop:InvokeServer("Buy", grabId) end)
                        bought = bought + 1
                        task.wait(0.2)
                    end
                    -- Equip yang terakhir / terbaru
                    pcall(function() grabberShop:InvokeServer("Equip", grabId) end)
                    task.wait(0.1)
                end
            else
                -- Fallback tanpa config: coba beli & equip langsung
                for grabId = 1, 20 do
                    pcall(function() grabberShop:InvokeServer("Buy", grabId) end)
                    pcall(function() grabberShop:InvokeServer("Equip", grabId) end)
                    task.wait(0.1)
                end
            end
        end)
        Rayfield:Notify({
            Title   = "🧺  Egg Grabber",
            Content = "Proses beli & pasang Egg Grabber selesai! (" .. bought .. " grabber baru dibeli)",
            Duration = 3, Image = 4483362458,
        })
    end,
})

ShopTab:CreateSection("⚙️  Gear & Trap Shop")

ShopTab:CreateButton({
    Name = "🪤  Beli Golden Trap (Gunakan Coins)",
    Callback = function()
        pcall(function()
            local gearShop = ReplicatedStorage:FindFirstChild("UassetGearShop")
            if gearShop then
                -- WAJIB: panggil Snapshot dulu agar server init state
                pcall(function() gearShop:InvokeServer("Snapshot") end)
                task.wait(0.2)
                gearShop:InvokeServer("Purchase")
            end
        end)
        Rayfield:Notify({
            Title   = "⚙️  Gear Shop",
            Content = "Trap dibeli jika koin mencukupi.",
            Duration = 2, Image = 4483362458,
        })
    end,
})

ShopTab:CreateButton({
    Name = "🎟️  Beli Golden Trap (Gunakan Tokens)",
    Callback = function()
        pcall(function()
            local gearShop = ReplicatedStorage:FindFirstChild("UassetGearShop")
            if gearShop then
                -- WAJIB: panggil Snapshot dulu agar server init state
                pcall(function() gearShop:InvokeServer("Snapshot") end)
                task.wait(0.2)
                gearShop:InvokeServer("PurchaseTokens")
            end
        end)
        Rayfield:Notify({
            Title   = "⚙️  Gear Shop",
            Content = "Trap dibeli menggunakan token jika token mencukupi.",
            Duration = 2, Image = 4483362458,
        })
    end,
})

ShopTab:CreateButton({
    Name = "🛡️  Equip Trap ke Karakter",
    Callback = function()
        pcall(function()
            local req = getUassetRequest()
            if req then
                req:FireServer("EquipTrap", nil)
            end
        end)
        Rayfield:Notify({
            Title   = "🛡️  Equip Trap",
            Content = "Trap terpasang.",
            Duration = 2, Image = 4483362458,
        })
    end,
})

ShopTab:CreateSection("🛠️  Testing & Dev Bypasses (Bila Diizinkan)")

ShopTab:CreateButton({
    Name = "🔓  Bypass Semua Pembelian (Dev Free Buy)",
    Callback = function()
        local devPanel = getDevPanel()
        if devPanel then
            pcall(function()
                devPanel:InvokeServer("SetPurchaseBypass", { Enabled = true })
            end)
            Rayfield:Notify({
                Title   = "🔓  Purchase Bypass",
                Content = "Bypass pembelian gratis dikirim ke server.",
                Duration = 3, Image = 4483362458,
            })
        else
            Rayfield:Notify({
                Title   = "⚠️  DevPanel",
                Content = "DevPanel tidak tersedia di server ini.",
                Duration = 2, Image = 4483362458,
            })
        end
    end,
})

ShopTab:CreateButton({
    Name = "🌈  Bypass Trail Shop (Dev Free Trail)",
    Callback = function()
        local devPanel = getDevPanel()
        if devPanel then
            pcall(function()
                devPanel:InvokeServer("SetTrailBypass", { Enabled = true })
            end)
            Rayfield:Notify({
                Title   = "🌈  Trail Bypass",
                Content = "Bypass trail shop dikirim ke server.",
                Duration = 3, Image = 4483362458,
            })
        end
    end,
})

ShopTab:CreateButton({
    Name = "🐾  Give All Pets (Dev Bypass)",
    Callback = function()
        local devPanel = getDevPanel()
        if devPanel then
            pcall(function()
                devPanel:InvokeServer("GiveAllPets", { TargetUserId = LocalPlayer.UserId })
            end)
            Rayfield:Notify({
                Title   = "🐾  Give All Pets",
                Content = "Request Give All Pets telah dikirim!",
                Duration = 3, Image = 4483362458,
            })
        end
    end,
})

ShopTab:CreateButton({
    Name = "⚡  Ready All Eggs (Dev Bypass)",
    Callback = function()
        local devPanel = getDevPanel()
        if devPanel then
            pcall(function()
                devPanel:InvokeServer("ReadyAllEggs", { TargetUserId = LocalPlayer.UserId })
            end)
            Rayfield:Notify({
                Title   = "⚡  Ready All Eggs",
                Content = "Request percepat semua timer telur terkirim!",
                Duration = 3, Image = 4483362458,
            })
        end
    end,
})

ShopTab:CreateButton({
    Name = "☄️  Spawn Test Meteor",
    Callback = function()
        local devPanel = getDevPanel()
        if devPanel then
            pcall(function()
                devPanel:InvokeServer("SpawnTestMeteor")
            end)
            Rayfield:Notify({
                Title   = "☄️  Test Meteor",
                Content = "Request spawn meteor terkirim!",
                Duration = 2, Image = 4483362458,
            })
        end
    end,
})


-- ╔══════════════════════════════╗
-- ║  TAB 6 – TELEPORT            ║
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
                Duration = 3, Image = 4483362458,
            })
        else
            Rayfield:Notify({
                Title   = "❌  Gagal",
                Content = "Karakter tidak ditemukan!",
                Duration = 3, Image = 4483362458,
            })
        end
    end,
})

-- Teleport ke Player
TpTab:CreateSection("👥  Teleport ke Player")

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
TpTab:CreateSection("🗺️  Preset Lokasi Game")

TpTab:CreateButton({
    Name = "🏠  Plot Sendiri (My Floor Plot)",
    Callback = function()
        local plot = getMyPlot()
        if plot and teleportTo(plot, Vector3.new(0, 4, 0)) then
            Rayfield:Notify({
                Title   = "🏠  Plot Sendiri",
                Content = "Teleport ke plot kamu berhasil!",
                Duration = 2, Image = 4483362458,
            })
        else
            Rayfield:Notify({
                Title   = "⚠️  Plot Tidak Ditemukan",
                Content = "Plot belum selesai dimuat di game.",
                Duration = 2, Image = 4483362458,
            })
        end
    end,
})

TpTab:CreateButton({
    Name = "🌊  Egg River (Aliran Telur Utama)",
    Callback = function()
        local target = nil
        pcall(function()
            local runtime = workspace:FindFirstChild("GameplayRuntime")
            local activeEggs = runtime and runtime:FindFirstChild("ActiveEggs")
            if activeEggs and #activeEggs:GetChildren() > 0 then
                target = activeEggs:GetChildren()[1]
            end
            if not target then
                target = workspace:FindFirstChild("MAP") and workspace.MAP:FindFirstChild("River", true)
            end
        end)

        if target and teleportTo(target, Vector3.new(0, 5, 0)) then
            Rayfield:Notify({
                Title   = "🌊  Egg River",
                Content = "Tiba di sungai telur!",
                Duration = 2, Image = 4483362458,
            })
        else
            local root = getRootPart()
            if root then
                root.CFrame = CFrame.new(0, 15, 0)
                Rayfield:Notify({
                    Title   = "🌊  Egg River",
                    Content = "Teleport ke koordinat pusat sungai!",
                    Duration = 2, Image = 4483362458,
                })
            end
        end
    end,
})

TpTab:CreateButton({
    Name = "🧺  Egg Grabber Shop Booth",
    Callback = function()
        local booths = workspace:FindFirstChild("ShopBooths")
        local booth = booths and booths:FindFirstChild("Egg Grabber Shop")
        if booth and teleportTo(booth, Vector3.new(0, 4, 0)) then
            Rayfield:Notify({
                Title   = "🧺  Egg Grabber Shop",
                Content = "Tiba di toko Egg Grabber!",
                Duration = 2, Image = 4483362458,
            })
        else
            Rayfield:Notify({
                Title   = "❌  Gagal",
                Content = "Booth Egg Grabber tidak ditemukan.",
                Duration = 2, Image = 4483362458,
            })
        end
    end,
})

TpTab:CreateButton({
    Name = "🍖  Feed Shop Booth (Toko Makanan)",
    Callback = function()
        local booths = workspace:FindFirstChild("ShopBooths")
        local booth = booths and booths:FindFirstChild("FeedShopBooth")
        if booth and teleportTo(booth, Vector3.new(0, 4, 0)) then
            Rayfield:Notify({
                Title   = "🍖  Feed Shop",
                Content = "Tiba di toko makanan pet!",
                Duration = 2, Image = 4483362458,
            })
        else
            Rayfield:Notify({
                Title   = "❌  Gagal",
                Content = "Booth Feed Shop tidak ditemukan.",
                Duration = 2, Image = 4483362458,
            })
        end
    end,
})

TpTab:CreateButton({
    Name = "⚙️  Gear Shop Booth (Trap)",
    Callback = function()
        local booths = workspace:FindFirstChild("ShopBooths")
        local booth = booths and booths:FindFirstChild("GearShopBooth")
        if booth and teleportTo(booth, Vector3.new(0, 4, 0)) then
            Rayfield:Notify({
                Title   = "⚙️  Gear Shop",
                Content = "Tiba di toko Gear / Trap!",
                Duration = 2, Image = 4483362458,
            })
        else
            Rayfield:Notify({
                Title   = "❌  Gagal",
                Content = "Booth Gear Shop tidak ditemukan.",
                Duration = 2, Image = 4483362458,
            })
        end
    end,
})

TpTab:CreateButton({
    Name = "🏪  Sell Booth (Richard)",
    Callback = function()
        local booths = workspace:FindFirstChild("ShopBooths")
        local booth = booths and booths:FindFirstChild("SellBooth")
        if booth and teleportTo(booth, Vector3.new(0, 4, 0)) then
            Rayfield:Notify({
                Title   = "🏪  Sell Booth",
                Content = "Tiba di tempat jual telur Richard!",
                Duration = 2, Image = 4483362458,
            })
        else
            Rayfield:Notify({
                Title   = "❌  Gagal",
                Content = "Sell Booth tidak ditemukan.",
                Duration = 2, Image = 4483362458,
            })
        end
    end,
})

TpTab:CreateButton({
    Name = "🏃  Trail Shop",
    Callback = function()
        local booths = workspace:FindFirstChild("ShopBooths")
        local booth = booths and booths:FindFirstChild("Trail Shop")
        if booth and teleportTo(booth, Vector3.new(0, 4, 0)) then
            Rayfield:Notify({
                Title   = "🏃  Trail Shop",
                Content = "Tiba di toko Trail!",
                Duration = 2, Image = 4483362458,
            })
        else
            Rayfield:Notify({
                Title   = "❌  Gagal",
                Content = "Booth Trail Shop tidak ditemukan.",
                Duration = 2, Image = 4483362458,
            })
        end
    end,
})

TpTab:CreateButton({
    Name = "🏝️  Admin Abuse Island",
    Callback = function()
        local island = workspace:FindFirstChild("Admin Abuse Island")
        if island and teleportTo(island, Vector3.new(0, 5, 0)) then
            Rayfield:Notify({
                Title   = "🏝️  Admin Abuse Island",
                Content = "Tiba di Admin Abuse Island!",
                Duration = 2, Image = 4483362458,
            })
        else
            Rayfield:Notify({
                Title   = "❌  Gagal",
                Content = "Admin Abuse Island tidak ditemukan.",
                Duration = 2, Image = 4483362458,
            })
        end
    end,
})

TpTab:CreateButton({
    Name = "🏆  Leaderboard Boards",
    Callback = function()
        local target = nil
        pcall(function()
            target = workspace:FindFirstChild("MAP")
                and workspace.MAP:FindFirstChild("SegmentBase")
                and workspace.MAP.SegmentBase:FindFirstChild("BaseMarketBridge")
                and workspace.MAP.SegmentBase.BaseMarketBridge:FindFirstChild("LeaderboardBoards")
        end)
        if target and teleportTo(target, Vector3.new(0, 4, 0)) then
            Rayfield:Notify({
                Title   = "🏆  Leaderboard",
                Content = "Tiba di papan peringkat!",
                Duration = 2, Image = 4483362458,
            })
        else
            Rayfield:Notify({
                Title   = "❌  Gagal",
                Content = "Papan leaderboard tidak ditemukan.",
                Duration = 2, Image = 4483362458,
            })
        end
    end,
})

TpTab:CreateButton({
    Name = "👥  Invite Friend Pad",
    Callback = function()
        local pad = workspace:FindFirstChild("Invite Friend")
        if pad and teleportTo(pad, Vector3.new(0, 4, 0)) then
            Rayfield:Notify({
                Title   = "👥  Invite Friend",
                Content = "Tiba di area Invite Friend!",
                Duration = 2, Image = 4483362458,
            })
        else
            Rayfield:Notify({
                Title   = "❌  Gagal",
                Content = "Area Invite Friend tidak ditemukan.",
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
    Name = "🌊  Ke Pusat Map  (0, 10, 0)",
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
-- ║  TAB 7 – SPEED & JUMP        ║
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
MoveTab:CreateSection("🦘  Jump Power / Height")

MoveTab:CreateSlider({
    Name         = "Jump Power  (UseJumpPower = true)",
    Range        = {10, 500},
    Increment    = 5,
    Suffix       = " pwr",
    CurrentValue = 50,   -- default Roblox = 50
    Flag         = "Slider_JumpPower",
    Callback     = function(v)
        local hum = getHumanoid()
        if not hum then return end
        -- Hanya set JumpPower jika game menggunakan JumpPower, bukan JumpHeight
        if hum.UseJumpPower then
            hum.JumpPower = v
        else
            -- Konversi range: power 50 ≈ height 7.2
            hum.JumpHeight = v / 50 * 7.2
        end
    end,
})

MoveTab:CreateSlider({
    Name         = "Jump Height (UseJumpPower = false)",
    Range        = {1, 100},
    Increment    = 0.5,
    Suffix       = " h",
    CurrentValue = 7.2,  -- default Roblox = 7.2
    Flag         = "Slider_JumpHeight",
    Callback     = function(v)
        local hum = getHumanoid()
        if not hum then return end
        if not hum.UseJumpPower then
            pcall(function() hum.JumpHeight = v end)
        else
            -- Konversi: height 7.2 ≈ power 50
            hum.JumpPower = math.max(1, v / 7.2 * 50)
        end
    end,
})

MoveTab:CreateButton({
    Name = "🔄  Reset Jump → Default",
    Callback = function()
        local hum = getHumanoid()
        if hum then
            if hum.UseJumpPower then
                hum.JumpPower = 50
            else
                pcall(function() hum.JumpHeight = 7.2 end)
            end
        end
        Rayfield:Notify({
            Title = "🔄  Reset Jump", Content = "Jump kembali ke nilai default Roblox",
            Duration = 2, Image = 4483362458,
        })
    end,
})

-- Preset Instan
MoveTab:CreateSection("⚡  Preset Instan")

local presets = {
    { name = "🐢  Normal",  spd = 16,  jmp = 50,  jh = 7.2,  label = "Speed 16 · Jump Default" },
    { name = "🐇  Medium",  spd = 50,  jmp = 100, jh = 14,   label = "Speed 50 · Jump 100" },
    { name = "🚀  Turbo",   spd = 200, jmp = 250, jh = 36,   label = "Speed 200 · Jump 250" },
    { name = "💀  God Mode",spd = 500, jmp = 500, jh = 72,   label = "Speed 500 · Jump 500 — HATI-HATI!" },
}

for _, p in ipairs(presets) do
    MoveTab:CreateButton({
        Name = p.name,
        Callback = function()
            local hum = getHumanoid()
            if hum then
                hum.WalkSpeed = p.spd
                if hum.UseJumpPower then
                    hum.JumpPower = p.jmp
                else
                    pcall(function() hum.JumpHeight = p.jh end)
                end
            end
            Rayfield:Notify({
                Title   = p.name .. " Aktif!",
                Content = p.label,
                Duration = 2, Image = 4483362458,
            })
        end,
    })
end


-- ╔══════════════════════════════╗
-- ║  NOTIF SELAMAT DATANG        ║
-- ╚══════════════════════════════╝
task.wait(0.8)
Rayfield:Notify({
    Title   = "🥚  Wowo Hub — Egg Farm",
    Content = "Selamat datang, " .. LocalPlayer.DisplayName .. "!\nScript siap digunakan. Selamat bermain!",
    Duration = 5,
    Image    = 4483362458,
})
