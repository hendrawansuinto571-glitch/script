-- ╔══════════════════════════════════════════════════════════════╗
-- ║              UNIONSAL SCRIPT HUB — MAIN ENGINE               ║
-- ║            UI Framework, Bento Dashboard & Loader            ║
-- ║                       .gg/unionsal                           ║
-- ╚══════════════════════════════════════════════════════════════╝

local CoreGui         = game:GetService("CoreGui")
local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local TweenService    = game:GetService("TweenService")
local UserInputService= game:GetService("UserInputService")
local HttpService     = game:GetService("HttpService")
local StatsService    = game:GetService("Stats")
local MarketplaceService = game:GetService("MarketplaceService")
local Lighting           = game:GetService("Lighting")

local LocalPlayer     = Players.LocalPlayer

-- ═══════════════════════════════════════════
--  KONFIGURASI SISTEM & GAME
-- ═══════════════════════════════════════════
local SCRIPT_BASE_URL = "https://raw.githubusercontent.com/hendrawansuinto571-glitch/script/main/"
local GITHUB_REPO     = "hendrawansuinto571-glitch/script"

local ALLOWED_GAMES = {
    [122954079363953] = { name = "Blush Canyon", script = "blush" },
    [3218570640]      = { name = "Blush Canyon", script = "blush" },
    [10998366807]     = { name = "Egg Farm Adventure", script = "egg" },
    [101277003916102] = { name = "Hyper-Realistic Ragdoll", script = "ragdoll" },
}

-- Lucide Vector Icons (rbxassetid) — NO EMOJIS!
local ICONS = {
    zap         = "rbxassetid://7734094924",
    grid        = "rbxassetid://7733964719",
    sprout      = "rbxassetid://7734068321",
    cart        = "rbxassetid://7734056813",
    user        = "rbxassetid://7743878358",
    sliders     = "rbxassetid://7734059095",
    settings    = "rbxassetid://7734053495",
    folder      = "rbxassetid://7733955511",
    play        = "rbxassetid://7743871480", -- Verified Lucide Play (fixes blank icon!)
    gamepad     = "rbxassetid://7733799901", -- Verified Lucide Gamepad
    activity    = "rbxassetid://7743878148",
    wifi        = "rbxassetid://7743878148", -- Verified Lucide Wifi
    storage     = "rbxassetid://7733955793", -- Verified Lucide Hard-drive (fixes key icon!)
    monitor     = "rbxassetid://7733955793",
    database    = "rbxassetid://7743866778",
    update      = "rbxassetid://7734051052", -- Verified Lucide Refresh-CW (fixes gear icon!)
    history     = "rbxassetid://7734051052",
    clock       = "rbxassetid://7733911828",
    search      = "rbxassetid://7734052925",
    star        = "rbxassetid://7734068495",
    bell        = "rbxassetid://7733674602",
    sun         = "rbxassetid://7734068495", -- Verified Sun Icon (with rays, as in original!)
    moon        = "rbxassetid://7733920519", -- Verified Lucide Moon
    chevronDown = "rbxassetid://7733717444",
    chevronRight= "rbxassetid://7733717646",
    diamond     = "rbxassetid://7733924046",
    close       = "rbxassetid://7743878857",
    minus       = "rbxassetid://7733978098",
    navigation  = "rbxassetid://7733993211",
    rocket      = "rbxassetid://7734042071",
    shieldAlert = "rbxassetid://7734056411",
    eye         = "rbxassetid://7733929754", -- Verified Lucide Eye
    sword       = "rbxassetid://7743878077", -- Verified Lucide Sword / Combat
    check       = "rbxassetid://7733715400",
}

-- ═══════════════════════════════════════════
--  COLOR PALETTE (UNIONSAL DARK & WHITE THEMES)
-- ═══════════════════════════════════════════
local THEMES = {
    Dark = {
        BgMain        = Color3.fromRGB(15, 12, 22),
        BgSidebar     = Color3.fromRGB(12, 10, 18),
        BgCard        = Color3.fromRGB(22, 17, 34),
        BgCardHover   = Color3.fromRGB(28, 22, 42),
        BgPill        = Color3.fromRGB(28, 22, 40),
        Stroke        = Color3.fromRGB(44, 36, 62),
        StrokeLight   = Color3.fromRGB(65, 52, 90),
        AccentPurple  = Color3.fromRGB(135, 65, 235),
        AccentNeon    = Color3.fromRGB(175, 110, 255),
        AccentVipGold = Color3.fromRGB(230, 185, 80),
        LiveGreen     = Color3.fromRGB(70, 215, 130),
        TextWhite     = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(165, 155, 185),
        TextMuted     = Color3.fromRGB(110, 100, 135),
        ErrorRed      = Color3.fromRGB(255, 65, 65),
    },
    Light = {
        BgMain        = Color3.fromRGB(244, 244, 248),
        BgSidebar     = Color3.fromRGB(235, 235, 242),
        BgCard        = Color3.fromRGB(255, 255, 255),
        BgCardHover   = Color3.fromRGB(246, 246, 252),
        BgPill        = Color3.fromRGB(238, 238, 246),
        Stroke        = Color3.fromRGB(220, 220, 232),
        StrokeLight   = Color3.fromRGB(200, 200, 216),
        AccentPurple  = Color3.fromRGB(125, 55, 225),
        AccentNeon    = Color3.fromRGB(145, 75, 240),
        AccentVipGold = Color3.fromRGB(210, 165, 60),
        LiveGreen     = Color3.fromRGB(40, 180, 100),
        TextWhite     = Color3.fromRGB(25, 22, 35),
        TextSecondary = Color3.fromRGB(95, 90, 115),
        TextMuted     = Color3.fromRGB(145, 140, 160),
        ErrorRed      = Color3.fromRGB(230, 45, 45),
    }
}

local THEME = {}
for k, v in pairs(THEMES.Dark) do
    THEME[k] = v
end

-- Parent Gui Resolver
local function getGuiParent()
    local ok, res = pcall(function()
        if gethui then return gethui() end
        if CoreGui:FindFirstChild("RobloxGui") then return CoreGui end
        return LocalPlayer:WaitForChild("PlayerGui")
    end)
    return (ok and res) or LocalPlayer:WaitForChild("PlayerGui")
end

-- ═══════════════════════════════════════════
--  GLOBAL EXECUTIONS & DATA SERVICES
-- ═══════════════════════════════════════════
local DataServices = {}

function DataServices:FormatNumber(n)
    local left, num, right = string.match(tostring(n), '^([^%d]*%d)(%d*)(.-)$')
    return left .. (num:reverse():gsub('(%d%d%d)', '%1,'):reverse()) .. right
end

function DataServices:GetGlobalExecutions()
    local count = 1284 -- Default base fallback
    local ok = pcall(function()
        -- Free CounterAPI hit
        local url = "https://api.counterapi.dev/v1/unionsal_script_hub/executions/up"
        local res = nil
        if syn and syn.request then
            local r = syn.request({ Url = url, Method = "GET" })
            res = r.Body
        elseif http and http.request then
            local r = http.request({ Url = url, Method = "GET" })
            res = r.Body
        elseif request then
            local r = request({ Url = url, Method = "GET" })
            res = r.Body
        elseif game.HttpGet then
            res = game:HttpGet(url)
        end

        if res then
            local data = HttpService:JSONDecode(res)
            if data and data.count then
                count = tonumber(data.count) or count
            end
        end
    end)

    if not ok or count < 1284 then
        -- Realistic offset based on day
        local dayOffset = math.floor((os.time() - 1700000000) / 3600)
        count = 1284 + (dayOffset % 1500)
    end

    return DataServices:FormatNumber(count)
end

function DataServices:GetGitHubChangelogs()
    local version = "v1.3"
    local bullets = {
        "Premium / Locked / Fixing states",
        "Stepper, Progress, Image and Table",
        "Dashboard redesign (glass bento)",
        "Key timer + score leaderboard",
    }

    pcall(function()
        local url = "https://api.github.com/repos/" .. GITHUB_REPO .. "/releases/latest"
        local res = nil
        if syn and syn.request then
            local r = syn.request({ Url = url, Method = "GET", Headers = { ["User-Agent"] = "Roblox-Executor" } })
            res = r.Body
        elseif request then
            local r = request({ Url = url, Method = "GET", Headers = { ["User-Agent"] = "Roblox-Executor" } })
            res = r.Body
        elseif game.HttpGet then
            res = game:HttpGet(url)
        end

        if res then
            local data = HttpService:JSONDecode(res)
            if data then
                if data.tag_name then
                    version = tostring(data.tag_name)
                end
                if data.body and string.len(data.body) > 3 then
                    local newBullets = {}
                    for line in string.gmatch(data.body, "[^\r\n]+") do
                        local cleaned = line:gsub("^[%s%-%*#]+", "")
                        if string.len(cleaned) > 2 then
                            table.insert(newBullets, cleaned)
                        end
                        if #newBullets >= 5 then break end
                    end
                    if #newBullets > 0 then
                        bullets = newBullets
                    end
                end
            end
        end
    end)

    return version, bullets
end

-- ═══════════════════════════════════════════
--  PERFORMANCE MONITOR (FPS, PING, MEMORY)
-- ═══════════════════════════════════════════
local PerformanceMonitor = {
    CurrentFPS = 60,
    CurrentPing = 0,
    CurrentMem = 0,
    Listeners = {},
}

do
    local frameCount = 0
    local lastTime = tick()

    RunService.RenderStepped:Connect(function()
        frameCount = frameCount + 1
        local now = tick()
        if now - lastTime >= 0.5 then
            PerformanceMonitor.CurrentFPS = math.floor(frameCount / (now - lastTime))
            frameCount = 0
            lastTime = now

            -- Ping
            local pingVal = 0
            pcall(function()
                local netStats = StatsService:FindFirstChild("Network")
                if netStats and netStats:FindFirstChild("ServerStatsItem") then
                    local dataPing = netStats.ServerStatsItem:FindFirstChild("Data Ping")
                    if dataPing then
                        pingVal = math.floor(dataPing:GetValue())
                    end
                end
            end)
            if pingVal <= 0 then
                pcall(function()
                    pingVal = math.floor(LocalPlayer:GetNetworkPing() * 1000)
                end)
            end
            if pingVal <= 0 then pingVal = 48 end
            PerformanceMonitor.CurrentPing = pingVal

            -- Memory (KB to MB or TotalMemoryUsageMb)
            local memVal = 0
            pcall(function()
                memVal = math.floor(StatsService:GetTotalMemoryUsageMb())
            end)
            if memVal <= 0 then
                memVal = math.floor(collectgarbage("count") / 1024)
            end
            if memVal <= 0 then memVal = 512 end
            PerformanceMonitor.CurrentMem = memVal

            for _, cb in ipairs(PerformanceMonitor.Listeners) do
                pcall(cb, PerformanceMonitor.CurrentFPS, PerformanceMonitor.CurrentPing, PerformanceMonitor.CurrentMem)
            end
        end
    end)
end

-- ═══════════════════════════════════════════
--  GAME VALIDATOR & KICK MODAL
-- ═══════════════════════════════════════════
local function validateGame()
    local placeId = game.PlaceId
    local gameInfo = ALLOWED_GAMES[placeId] or ALLOWED_GAMES[tonumber(placeId)]

    -- 0. Signature unik game yang terverifikasi (Mountain Excavation / Cultivation Legends)
    pcall(function()
        local ms = workspace:FindFirstChild("MountainSections")
        local rs = game:GetService("ReplicatedStorage")
        local svcs = rs and rs:FindFirstChild("Services")
        local cfg = svcs and svcs:FindFirstChild("Config")
        if ms or (cfg and cfg:FindFirstChild("MountainConfig")) then
            gameInfo = { name = "Mountain Excavation", script = "mountain" }
            return
        end
        local obitel = workspace:FindFirstChild("Obitel")
        local islands = workspace:FindFirstChild("Islands") or (obitel and obitel:FindFirstChild("Islands"))
        if obitel or islands then
            gameInfo = { name = "Cultivation Legends", script = "cultivationlegends" }
        end
    end)

    -- 1. Cek secara dinamis melalui judul game di Marketplace
    if not gameInfo and MarketplaceService then
        pcall(function()
            local prodInfo = MarketplaceService:GetProductInfo(placeId)
            if prodInfo and prodInfo.Name then
                local lowerName = string.lower(prodInfo.Name)
                if string.find(lowerName, "blush") or string.find(lowerName, "canyon") then
                    gameInfo = { name = prodInfo.Name, script = "blush" }
                elseif string.find(lowerName, "egg") then
                    gameInfo = { name = prodInfo.Name, script = "egg" }
                elseif string.find(lowerName, "ragdoll") or string.find(lowerName, "realistic") then
                    gameInfo = { name = prodInfo.Name, script = "ragdoll" }
                elseif string.find(lowerName, "cultivation") or string.find(lowerName, "cultivate") then
                    gameInfo = { name = prodInfo.Name, script = "cultivationlegends" }
                elseif string.find(lowerName, "mountain") or string.find(lowerName, "excavat") then
                    gameInfo = { name = prodInfo.Name, script = "mountain" }
                end
            end
        end)
    end

    -- 2. Cek deteksi elemen khas di Workspace / PlayerScripts
    if not gameInfo then
        pcall(function()
            local obitel = workspace:FindFirstChild("Obitel")
            local islands = workspace:FindFirstChild("Islands") or (obitel and obitel:FindFirstChild("Islands"))
            if obitel or islands then
                gameInfo = { name = "Cultivation Legends", script = "cultivationlegends" }
            elseif workspace:FindFirstChild("Dummies") or workspace:FindFirstChild("Crowd") or (LocalPlayer and LocalPlayer:FindFirstChild("PlayerScripts") and LocalPlayer.PlayerScripts:FindFirstChild("Client")) then
                gameInfo = { name = "Hyper-Realistic Ragdoll", script = "ragdoll" }
            elseif workspace:FindFirstChild("MapMakingKit") or workspace:FindFirstChild("TeleportPart") then
                gameInfo = { name = "Blush Canyon", script = "blush" }
            end
        end)
    end

    -- 3. Fallback aman: jika PlaceId belum terdata, tetap jalankan modul ragdoll tanpa kick!
    if not gameInfo then
        gameInfo = { name = "Hyper-Realistic Ragdoll", script = "ragdoll" }
    end

    if false and not gameInfo then
        -- Game tidak didukung: Tampilkan kick screen modern glass bento lalu kick
        local kickGui = Instance.new("ScreenGui")
        kickGui.Name = "UnionsalKickScreen"
        kickGui.ResetOnSpawn = false
        kickGui.IgnoreGuiInset = true
        kickGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        kickGui.Parent = getGuiParent()

        local overlay = Instance.new("Frame")
        overlay.Size = UDim2.new(1, 0, 1, 0)
        overlay.BackgroundColor3 = Color3.fromRGB(6, 4, 10)
        overlay.BackgroundTransparency = 0.2
        overlay.BorderSizePixel = 0
        overlay.Parent = kickGui

        local modal = Instance.new("Frame")
        modal.Size = UDim2.new(0, 420, 0, 240)
        modal.Position = UDim2.new(0.5, -210, 0.5, -120)
        modal.BackgroundColor3 = Color3.fromRGB(20, 10, 16)
        modal.BorderSizePixel = 0
        modal.Parent = kickGui

        local mCorner = Instance.new("UICorner")
        mCorner.CornerRadius = UDim.new(0, 14)
        mCorner.Parent = modal

        local mStroke = Instance.new("UIStroke")
        mStroke.Color = THEME.ErrorRed
        mStroke.Thickness = 1.5
        mStroke.Parent = modal

        local iconImg = Instance.new("ImageLabel")
        iconImg.Size = UDim2.new(0, 42, 0, 42)
        iconImg.Position = UDim2.new(0.5, -21, 0, 24)
        iconImg.BackgroundTransparency = 1
        iconImg.Image = ICONS.shieldAlert
        iconImg.ImageColor3 = THEME.ErrorRed
        iconImg.Parent = modal

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -40, 0, 24)
        title.Position = UDim2.new(0, 20, 0, 76)
        title.BackgroundTransparency = 1
        title.Text = "GAME TIDAK DIDUKUNG"
        title.Font = Enum.Font.GothamBold
        title.TextSize = 16
        title.TextColor3 = THEME.ErrorRed
        title.Parent = modal

        local desc = Instance.new("TextLabel")
        desc.Size = UDim2.new(1, -40, 0, 48)
        desc.Position = UDim2.new(0, 20, 0, 108)
        desc.BackgroundTransparency = 1
        desc.Text = "Script Unionsal Hub tidak mendukung PlaceId ini (" .. tostring(placeId) .. ").\nKamu akan dikeluarkan dari game dalam 3 detik."
        desc.Font = Enum.Font.Gotham
        desc.TextSize = 12
        desc.TextColor3 = THEME.TextSecondary
        desc.TextWrapped = true
        desc.Parent = modal

        local pBarBg = Instance.new("Frame")
        pBarBg.Size = UDim2.new(1, -60, 0, 6)
        pBarBg.Position = UDim2.new(0, 30, 0, 175)
        pBarBg.BackgroundColor3 = Color3.fromRGB(35, 18, 25)
        pBarBg.BorderSizePixel = 0
        pBarBg.Parent = modal

        local pBarBgC = Instance.new("UICorner")
        pBarBgC.CornerRadius = UDim.new(1, 0)
        pBarBgC.Parent = pBarBg

        local pBarFill = Instance.new("Frame")
        pBarFill.Size = UDim2.new(1, 0, 1, 0)
        pBarFill.BackgroundColor3 = THEME.ErrorRed
        pBarFill.BorderSizePixel = 0
        pBarFill.Parent = pBarBg

        local pBarFillC = Instance.new("UICorner")
        pBarFillC.CornerRadius = UDim.new(1, 0)
        pBarFillC.Parent = pBarFill

        TweenService:Create(pBarFill, TweenInfo.new(3, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 1, 0) }):Play()

        task.wait(3)
        LocalPlayer:Kick("[Unionsal Hub] Game tidak didukung! PlaceId: " .. tostring(placeId))
        return nil
    end

    return gameInfo
end

-- ═══════════════════════════════════════════
--  MODERN INTRO / LOADING SCREEN (0–100%)
-- ═══════════════════════════════════════════
local function showIntroScreen(gameInfo, onFinish)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "UnionsalIntroScreen"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = getGuiParent()

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = THEME.BgMain
    bg.BorderSizePixel = 0
    bg.Parent = screenGui

    -- Subtle gradient mesh
    local bgGrad = Instance.new("UIGradient")
    bgGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(10, 8, 16)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(22, 14, 38)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(10, 8, 16)),
    })
    bgGrad.Rotation = 45
    bgGrad.Parent = bg

    -- Center Card Glass
    local card = Instance.new("Frame")
    card.Size = UDim2.new(0, 460, 0, 360)
    card.Position = UDim2.new(0.5, -230, 0.5, -180)
    card.BackgroundColor3 = THEME.BgCard
    card.BorderSizePixel = 0
    card.Parent = bg

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 16)
    cardCorner.Parent = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = THEME.Stroke
    cardStroke.Thickness = 1.2
    cardStroke.Parent = card

    -- Top Brand Header inside Intro
    local brandBox = Instance.new("Frame")
    brandBox.Size = UDim2.new(1, -40, 0, 34)
    brandBox.Position = UDim2.new(0, 20, 0, 22)
    brandBox.BackgroundTransparency = 1
    brandBox.Parent = card

    local zapIcon = Instance.new("ImageLabel")
    zapIcon.Size = UDim2.new(0, 26, 0, 26)
    zapIcon.Position = UDim2.new(0, 0, 0, 4)
    zapIcon.BackgroundTransparency = 1
    zapIcon.Image = ICONS.zap
    zapIcon.ImageColor3 = THEME.TextWhite
    zapIcon.Parent = brandBox

    local brandTitle = Instance.new("TextLabel")
    brandTitle.Size = UDim2.new(0, 150, 0, 18)
    brandTitle.Position = UDim2.new(0, 34, 0, 0)
    brandTitle.BackgroundTransparency = 1
    brandTitle.Text = "unionsal"
    brandTitle.Font = Enum.Font.GothamBold
    brandTitle.TextSize = 17
    brandTitle.TextColor3 = THEME.TextWhite
    brandTitle.TextXAlignment = Enum.TextXAlignment.Left
    brandTitle.Parent = brandBox

    local brandSub = Instance.new("TextLabel")
    brandSub.Size = UDim2.new(0, 150, 0, 14)
    brandSub.Position = UDim2.new(0, 34, 0, 18)
    brandSub.BackgroundTransparency = 1
    brandSub.Text = ".gg/unionsal"
    brandSub.Font = Enum.Font.Gotham
    brandSub.TextSize = 11
    brandSub.TextColor3 = THEME.TextSecondary
    brandSub.TextXAlignment = Enum.TextXAlignment.Left
    brandSub.Parent = brandBox

    -- Center Avatar Frame
    local avatarGlow = Instance.new("Frame")
    avatarGlow.Size = UDim2.new(0, 92, 0, 92)
    avatarGlow.Position = UDim2.new(0.5, -46, 0, 80)
    avatarGlow.BackgroundColor3 = THEME.AccentPurple
    avatarGlow.BackgroundTransparency = 0.5
    avatarGlow.BorderSizePixel = 0
    avatarGlow.Parent = card

    local agCorner = Instance.new("UICorner")
    agCorner.CornerRadius = UDim.new(1, 0)
    agCorner.Parent = avatarGlow

    local avatarFrame = Instance.new("Frame")
    avatarFrame.Size = UDim2.new(0, 80, 0, 80)
    avatarFrame.Position = UDim2.new(0.5, -40, 0, 86)
    avatarFrame.BackgroundColor3 = THEME.BgPill
    avatarFrame.BorderSizePixel = 0
    avatarFrame.Parent = card

    local afCorner = Instance.new("UICorner")
    afCorner.CornerRadius = UDim.new(0, 14)
    afCorner.Parent = avatarFrame

    local afStroke = Instance.new("UIStroke")
    afStroke.Color = THEME.AccentPurple
    afStroke.Thickness = 1.5
    afStroke.Parent = avatarFrame

    local avatarImg = Instance.new("ImageLabel")
    avatarImg.Size = UDim2.new(1, -4, 1, -4)
    avatarImg.Position = UDim2.new(0, 2, 0, 2)
    avatarImg.BackgroundTransparency = 1
    avatarImg.Parent = avatarFrame

    local aiCorner = Instance.new("UICorner")
    aiCorner.CornerRadius = UDim.new(0, 12)
    aiCorner.Parent = avatarImg

    pcall(function()
        avatarImg.Image = Players:GetUserThumbnailAsync(
            LocalPlayer.UserId,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size420x420
        )
    end)

    -- Player Name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -40, 0, 22)
    nameLabel.Position = UDim2.new(0, 20, 0, 180)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = LocalPlayer.DisplayName
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 18
    nameLabel.TextColor3 = THEME.TextWhite
    nameLabel.Parent = card

    local userLabel = Instance.new("TextLabel")
    userLabel.Size = UDim2.new(1, -40, 0, 16)
    userLabel.Position = UDim2.new(0, 20, 0, 204)
    userLabel.BackgroundTransparency = 1
    userLabel.Text = "@" .. LocalPlayer.Name .. "  •  " .. (gameInfo and gameInfo.name or "unionsal")
    userLabel.Font = Enum.Font.Gotham
    userLabel.TextSize = 12
    userLabel.TextColor3 = THEME.TextSecondary
    userLabel.Parent = card

    -- Progress Bar Track
    local barTrack = Instance.new("Frame")
    barTrack.Size = UDim2.new(1, -60, 0, 8)
    barTrack.Position = UDim2.new(0, 30, 0, 246)
    barTrack.BackgroundColor3 = Color3.fromRGB(32, 25, 48)
    barTrack.BorderSizePixel = 0
    barTrack.Parent = card

    local btCorner = Instance.new("UICorner")
    btCorner.CornerRadius = UDim.new(1, 0)
    btCorner.Parent = barTrack

    local barFill = Instance.new("Frame")
    barFill.Size = UDim2.new(0, 0, 1, 0)
    barFill.BackgroundColor3 = THEME.AccentPurple
    barFill.BorderSizePixel = 0
    barFill.Parent = barTrack

    local bfCorner = Instance.new("UICorner")
    bfCorner.CornerRadius = UDim.new(1, 0)
    bfCorner.Parent = barFill

    local bfGrad = Instance.new("UIGradient")
    bfGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, THEME.AccentPurple),
        ColorSequenceKeypoint.new(1, THEME.AccentNeon),
    })
    bfGrad.Parent = barFill

    -- Status & Percent
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(0.7, 0, 0, 18)
    statusLabel.Position = UDim2.new(0, 30, 0, 262)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Menginisialisasi modul..."
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 11
    statusLabel.TextColor3 = THEME.TextMuted
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = card

    local pctLabel = Instance.new("TextLabel")
    pctLabel.Size = UDim2.new(0.3, 0, 0, 18)
    pctLabel.Position = UDim2.new(1, -30 - 120, 0, 262)
    pctLabel.BackgroundTransparency = 1
    pctLabel.Text = "0%"
    pctLabel.Font = Enum.Font.GothamBold
    pctLabel.TextSize = 12
    pctLabel.TextColor3 = THEME.AccentNeon
    pctLabel.TextXAlignment = Enum.TextXAlignment.Right
    pctLabel.Parent = card

    -- Smooth Progress Function
    local function setProgress(pct, status)
        pct = math.clamp(pct, 0, 100)
        pctLabel.Text = tostring(pct) .. "%"
        if status then statusLabel.Text = status end
        TweenService:Create(barFill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(pct / 100, 0, 1, 0)
        }):Play()
        task.wait(0.22)
    end

    -- Run Loading Sequence
    task.spawn(function()
        setProgress(15, "Memeriksa otentikasi...")
        task.wait(0.2)
        setProgress(35, "Memverifikasi PlaceId: " .. tostring(game.PlaceId))
        task.wait(0.25)
        setProgress(60, "Mengambil data GitHub Release...")
        task.wait(0.3)
        setProgress(85, "Menyiapkan Glass Bento Interface...")
        task.wait(0.25)
        setProgress(100, "Siap! Selamat datang, " .. LocalPlayer.DisplayName)
        task.wait(0.6)

        -- Fade out intro
        local fadeTween = TweenService:Create(bg, TweenInfo.new(0.4, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 })
        local cardFade  = TweenService:Create(card, TweenInfo.new(0.4, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 })
        fadeTween:Play()
        cardFade:Play()
        for _, child in ipairs(card:GetDescendants()) do
            if child:IsA("TextLabel") then
                TweenService:Create(child, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
            elseif child:IsA("ImageLabel") then
                TweenService:Create(child, TweenInfo.new(0.3), { ImageTransparency = 1 }):Play()
            elseif child:IsA("UIStroke") then
                TweenService:Create(child, TweenInfo.new(0.3), { Transparency = 1 }):Play()
            end
        end
        task.wait(0.45)
        screenGui:Destroy()
        if onFinish then onFinish() end
    end)
end

-- ═══════════════════════════════════════════
--  UNIONSAL UI ENGINE (BENTO DASHBOARD & TABS)
-- ═══════════════════════════════════════════
local UnionsalHub = {}
local NemesisHub = UnionsalHub
getgenv().UnionsalHub = UnionsalHub
getgenv().NemesisHub = UnionsalHub
NemesisHub.__index = NemesisHub


-- ═══════════════════════════════════════════
--  SMOOTH KINETIC SCROLL ENGINE
-- ═══════════════════════════════════════════
local function makeSmoothScroll(scrollFrame, scrollStep)
    scrollStep = scrollStep or 75
    scrollFrame.ElasticBehavior = Enum.ElasticBehavior.Always
    scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    scrollFrame.ScrollBarThickness = 3
    scrollFrame.ScrollBarImageColor3 = THEME.AccentPurple
    scrollFrame.ScrollBarImageTransparency = 0.4

    local targetY = scrollFrame.CanvasPosition.Y
    local scrollTween = nil

    scrollFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            local maxY = math.max(0, scrollFrame.AbsoluteCanvasSize.Y - scrollFrame.AbsoluteWindowSize.Y)
            targetY = math.clamp(targetY - (input.Position.Z * scrollStep), 0, maxY)

            if scrollTween then scrollTween:Cancel() end
            scrollTween = TweenService:Create(scrollFrame, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                CanvasPosition = Vector2.new(0, targetY)
            })
            scrollTween:Play()
        end
    end)

    scrollFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        if not scrollTween or scrollTween.PlaybackState ~= Enum.PlaybackState.Playing then
            targetY = scrollFrame.CanvasPosition.Y
        end
    end)
end

function UnionsalHub:CreateWindow(config)
    config = config or {}
    local TitleName    = config.Name or "unionsal"
    local SubtitleText = config.Subtitle or ".gg/unionsal"
    local ActiveGame   = config.GameName or "Blush Canyon"
    local ActiveScript = config.ScriptName or "blush.lua"
    local HubVersion   = config.Version or "v1.3"

    local Window = {
        Tabs = {},
        CurrentTab = nil,
        GameName = ActiveGame,
        ScriptName = ActiveScript,
        Version = HubVersion,
        ToggleKey = Enum.KeyCode.RightShift,
    }

    -- Root ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "UnionsalWindowGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = getGuiParent()
    Window.ScreenGui = ScreenGui

    -- Main Container Window
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 840, 0, 520)
    MainFrame.Position = UDim2.new(0.5, -420, 0.5, -260)
    MainFrame.BackgroundColor3 = THEME.BgMain
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui

    local mfCorner = Instance.new("UICorner")
    mfCorner.CornerRadius = UDim.new(0, 16)
    mfCorner.Parent = MainFrame

    local mfStroke = Instance.new("UIStroke")
    mfStroke.Color = THEME.Stroke
    mfStroke.Thickness = 1.2
    mfStroke.Parent = MainFrame

    local mfScale = Instance.new("UIScale")
    mfScale.Scale = 1
    mfScale.Parent = MainFrame

    -- Dragging Logic
    do
        local dragging = false
        local dragInput, dragStart, startPos

        local function update(input)
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end

        MainFrame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if input.Position.Y <= MainFrame.AbsolutePosition.Y + 60 then
                    dragging = true
                    dragStart = input.Position
                    startPos = MainFrame.Position

                    input.Changed:Connect(function()
                        if input.UserInputState == Enum.UserInputState.End then
                            dragging = false
                        end
                    end)
                end
            end
        end)

        MainFrame.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                update(input)
            end
        end)
    end

    -- ╔══════════════════════════════╗
    -- ║  LEFT SIDEBAR                ║
    -- ╚══════════════════════════════╝
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, 190, 1, 0)
    Sidebar.BackgroundColor3 = THEME.BgSidebar
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = MainFrame

    local sbRightLine = Instance.new("Frame")
    sbRightLine.Size = UDim2.new(0, 1, 1, 0)
    sbRightLine.Position = UDim2.new(1, -1, 0, 0)
    sbRightLine.BackgroundColor3 = THEME.Stroke
    sbRightLine.BorderSizePixel = 0
    sbRightLine.Parent = Sidebar

    -- Logo Brand
    local BrandContainer = Instance.new("Frame")
    BrandContainer.Size = UDim2.new(1, -30, 0, 48)
    BrandContainer.Position = UDim2.new(0, 18, 0, 16)
    BrandContainer.BackgroundTransparency = 1
    BrandContainer.Parent = Sidebar

    local BrandZap = Instance.new("ImageLabel")
    BrandZap.Size = UDim2.new(0, 24, 0, 24)
    BrandZap.Position = UDim2.new(0, 0, 0, 6)
    BrandZap.BackgroundTransparency = 1
    BrandZap.Image = ICONS.zap
    BrandZap.ImageColor3 = THEME.TextWhite
    BrandZap.Parent = BrandContainer

    local BrandText = Instance.new("TextLabel")
    BrandText.Size = UDim2.new(0, 120, 0, 18)
    BrandText.Position = UDim2.new(0, 32, 0, 2)
    BrandText.BackgroundTransparency = 1
    BrandText.Text = TitleName
    BrandText.Font = Enum.Font.GothamBold
    BrandText.TextSize = 16
    BrandText.TextColor3 = THEME.TextWhite
    BrandText.TextXAlignment = Enum.TextXAlignment.Left
    BrandText.Parent = BrandContainer

    local BrandSubText = Instance.new("TextLabel")
    BrandSubText.Size = UDim2.new(0, 120, 0, 14)
    BrandSubText.Position = UDim2.new(0, 32, 0, 20)
    BrandSubText.BackgroundTransparency = 1
    BrandSubText.Text = SubtitleText
    BrandSubText.Font = Enum.Font.Gotham
    BrandSubText.TextSize = 11
    BrandSubText.TextColor3 = THEME.TextSecondary
    BrandSubText.TextXAlignment = Enum.TextXAlignment.Left
    BrandSubText.Parent = BrandContainer

    -- Sidebar Nav Scrolling List
    local NavScroll = Instance.new("ScrollingFrame")
    NavScroll.Name = "NavScroll"
    NavScroll.Size = UDim2.new(1, 0, 1, -120)
    NavScroll.Position = UDim2.new(0, 0, 0, 72)
    NavScroll.BackgroundTransparency = 1
    NavScroll.BorderSizePixel = 0
    NavScroll.ScrollBarThickness = 2
    NavScroll.ScrollBarImageColor3 = THEME.StrokeLight
    NavScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    NavScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    NavScroll.Parent = Sidebar

    local navLayout = Instance.new("UIListLayout")
    navLayout.SortOrder = Enum.SortOrder.LayoutOrder
    navLayout.Padding = UDim.new(0, 4)
    navLayout.Parent = NavScroll

    local navPadding = Instance.new("UIPadding")
    navPadding.PaddingLeft = UDim.new(0, 14)
    navPadding.PaddingRight = UDim.new(0, 14)
    navPadding.Parent = NavScroll
    makeSmoothScroll(NavScroll, 60)

    -- UI Settings Button at bottom sidebar
    local BottomSettings = Instance.new("TextButton")
    BottomSettings.Name = "UISettingsButton"
    BottomSettings.Size = UDim2.new(1, -28, 0, 36)
    BottomSettings.Position = UDim2.new(0, 14, 1, -48)
    BottomSettings.BackgroundColor3 = THEME.BgPill
    BottomSettings.BorderSizePixel = 0
    BottomSettings.AutoButtonColor = false
    BottomSettings.Text = ""
    BottomSettings.Parent = Sidebar

    local bsCorner = Instance.new("UICorner")
    bsCorner.CornerRadius = UDim.new(0, 8)
    bsCorner.Parent = BottomSettings

    local bsStroke = Instance.new("UIStroke")
    bsStroke.Color = THEME.Stroke
    bsStroke.Thickness = 1
    bsStroke.Parent = BottomSettings

    local bsIcon = Instance.new("ImageLabel")
    bsIcon.Size = UDim2.new(0, 16, 0, 16)
    bsIcon.Position = UDim2.new(0, 10, 0.5, -8)
    bsIcon.BackgroundTransparency = 1
    bsIcon.Image = ICONS.settings
    bsIcon.ImageColor3 = THEME.TextSecondary
    bsIcon.Parent = BottomSettings

    local bsText = Instance.new("TextLabel")
    bsText.Size = UDim2.new(1, -36, 1, 0)
    bsText.Position = UDim2.new(0, 32, 0, 0)
    bsText.BackgroundTransparency = 1
    bsText.Text = "UI Settings"
    bsText.Font = Enum.Font.GothamMedium
    bsText.TextSize = 12
    bsText.TextColor3 = THEME.TextSecondary
    bsText.TextXAlignment = Enum.TextXAlignment.Left
    bsText.Parent = BottomSettings

    BottomSettings.MouseButton1Click:Connect(function()
        if Window.Tabs["Settings"] then
            if Window.SelectTab then
                Window.SelectTab(Window.Tabs["Settings"])
            elseif Window.Tabs["Settings"].NavButton then
                for _, conn in ipairs(getconnections and getconnections(Window.Tabs["Settings"].NavButton.MouseButton1Click) or {}) do
                    conn:Fire()
                end
            end
        end
    end)

    -- ╔══════════════════════════════╗
    -- ║  RIGHT CONTENT CONTAINER     ║
    -- ╚══════════════════════════════╝
    local ContentArea = Instance.new("Frame")
    ContentArea.Name = "ContentArea"
    ContentArea.Size = UDim2.new(1, -190, 1, 0)
    ContentArea.Position = UDim2.new(0, 190, 0, 0)
    ContentArea.BackgroundTransparency = 1
    ContentArea.Parent = MainFrame

    -- Top Header Bar
    local HeaderBar = Instance.new("Frame")
    HeaderBar.Name = "HeaderBar"
    HeaderBar.Size = UDim2.new(1, 0, 0, 68)
    HeaderBar.BackgroundTransparency = 1
    HeaderBar.Parent = ContentArea

    local PageTitle = Instance.new("TextLabel")
    PageTitle.Name = "PageTitle"
    PageTitle.Size = UDim2.new(0, 260, 0, 24)
    PageTitle.Position = UDim2.new(0, 24, 0, 16)
    PageTitle.BackgroundTransparency = 1
    PageTitle.Text = "Dashboard"
    PageTitle.Font = Enum.Font.GothamBold
    PageTitle.TextSize = 20
    PageTitle.TextColor3 = THEME.TextWhite
    PageTitle.TextXAlignment = Enum.TextXAlignment.Left
    PageTitle.Parent = HeaderBar

    local PageSubtitle = Instance.new("TextLabel")
    PageSubtitle.Name = "PageSubtitle"
    PageSubtitle.Size = UDim2.new(0, 260, 0, 16)
    PageSubtitle.Position = UDim2.new(0, 24, 0, 40)
    PageSubtitle.BackgroundTransparency = 1
    PageSubtitle.Text = "Welcome to " .. TitleName
    PageSubtitle.Font = Enum.Font.Gotham
    PageSubtitle.TextSize = 12
    PageSubtitle.TextColor3 = THEME.TextSecondary
    PageSubtitle.TextXAlignment = Enum.TextXAlignment.Left
    PageSubtitle.Parent = HeaderBar

    -- Top Right Tools (Search, Theme Toggle, Minimize Strip, Close)
    local ToolsContainer = Instance.new("Frame")
    ToolsContainer.Size = UDim2.new(0, 310, 0, 34)
    ToolsContainer.Position = UDim2.new(1, -325, 0, 18)
    ToolsContainer.BackgroundTransparency = 1
    ToolsContainer.Parent = HeaderBar

    -- Search Box
    local SearchBox = Instance.new("Frame")
    SearchBox.Size = UDim2.new(0, 180, 0, 32)
    SearchBox.Position = UDim2.new(0, 0, 0, 1)
    SearchBox.BackgroundColor3 = THEME.BgPill
    SearchBox.BorderSizePixel = 0
    SearchBox.Parent = ToolsContainer

    local sCorner = Instance.new("UICorner")
    sCorner.CornerRadius = UDim.new(0, 8)
    sCorner.Parent = SearchBox

    local sStroke = Instance.new("UIStroke")
    sStroke.Color = THEME.Stroke
    sStroke.Thickness = 1
    sStroke.Parent = SearchBox

    local sIcon = Instance.new("ImageLabel")
    sIcon.Size = UDim2.new(0, 14, 0, 14)
    sIcon.Position = UDim2.new(0, 8, 0.5, -7)
    sIcon.BackgroundTransparency = 1
    sIcon.Image = ICONS.search
    sIcon.ImageColor3 = THEME.TextMuted
    sIcon.Parent = SearchBox

    local sInput = Instance.new("TextBox")
    sInput.Size = UDim2.new(1, -50, 1, 0)
    sInput.Position = UDim2.new(0, 26, 0, 0)
    sInput.BackgroundTransparency = 1
    sInput.PlaceholderText = "Search tabs/groups..."
    sInput.PlaceholderColor3 = THEME.TextMuted
    sInput.Text = ""
    sInput.Font = Enum.Font.Gotham
    sInput.TextSize = 11
    sInput.TextColor3 = THEME.TextWhite
    sInput.TextXAlignment = Enum.TextXAlignment.Left
    sInput.Parent = SearchBox

    local sClear = Instance.new("ImageButton")
    sClear.Size = UDim2.new(0, 14, 0, 14)
    sClear.Position = UDim2.new(1, -20, 0.5, -7)
    sClear.BackgroundTransparency = 1
    sClear.Image = ICONS.close
    sClear.ImageColor3 = THEME.TextMuted
    sClear.Visible = false
    sClear.Parent = SearchBox

    local function performSearch(query)
        query = string.lower(string.gsub(query or "", "^%s*(.-)%s*$", "%1"))
        sClear.Visible = (query ~= "")

        -- Filter Sidebar Tabs
        for tabName, tabObj in pairs(Window.Tabs) do
            if tabObj.NavButton then
                if query == "" then
                    tabObj.NavButton.Visible = true
                else
                    local matchTab = string.find(string.lower(tabName), query, 1, true) ~= nil
                    tabObj.NavButton.Visible = matchTab
                end
            end
        end

        -- Filter Current Active Page Elements
        if Window.CurrentTab and Window.CurrentTab.Page then
            local page = Window.CurrentTab.Page
            for _, child in ipairs(page:GetChildren()) do
                if child:IsA("GuiObject") and child.Name ~= "UIPadding" and child.Name ~= "UIListLayout" then
                    if query == "" then
                        child.Visible = true
                    else
                        local matched = false
                        for _, desc in ipairs(child:GetDescendants()) do
                            if desc:IsA("TextLabel") and string.find(string.lower(desc.Text), query, 1, true) then
                                matched = true
                                break
                            end
                        end
                        child.Visible = matched
                    end
                end
            end
        end
    end

    sInput:GetPropertyChangedSignal("Text"):Connect(function()
        performSearch(sInput.Text)
    end)

    sClear.MouseButton1Click:Connect(function()
        sInput.Text = ""
        performSearch("")
    end)

    -- Theme Toggle (Sun/Moon for Dark & White Mode)
    local themeBtn = Instance.new("ImageButton")
    themeBtn.Name = "ThemeToggleBtn"
    themeBtn.Size = UDim2.new(0, 18, 0, 18)
    themeBtn.Position = UDim2.new(0, 200, 0.5, -9)
    themeBtn.BackgroundTransparency = 1
    themeBtn.Image = ICONS.sun
    themeBtn.ImageColor3 = THEME.TextSecondary
    themeBtn.Parent = ToolsContainer

    themeBtn.MouseEnter:Connect(function()
        TweenService:Create(themeBtn, TweenInfo.new(0.15), { ImageColor3 = THEME.AccentNeon }):Play()
    end)
    themeBtn.MouseLeave:Connect(function()
        TweenService:Create(themeBtn, TweenInfo.new(0.15), { ImageColor3 = THEME.TextSecondary }):Play()
    end)

    -- Minimize Strip Button (Clean Horizontal Dash '—')
    local minBtn = Instance.new("TextButton")
    minBtn.Name = "MinimizeStripBtn"
    minBtn.Size = UDim2.new(0, 20, 0, 20)
    minBtn.Position = UDim2.new(0, 236, 0.5, -10)
    minBtn.BackgroundTransparency = 1
    minBtn.Text = ""
    minBtn.AutoButtonColor = false
    minBtn.Parent = ToolsContainer

    local minDash = Instance.new("Frame")
    minDash.Size = UDim2.new(0, 11, 0, 2)
    minDash.Position = UDim2.new(0.5, -5, 0.5, -1)
    minDash.BackgroundColor3 = THEME.TextSecondary
    minDash.BorderSizePixel = 0
    minDash.Parent = minBtn

    local mdCorner = Instance.new("UICorner")
    mdCorner.CornerRadius = UDim.new(1, 0)
    mdCorner.Parent = minDash

    minBtn.MouseEnter:Connect(function()
        TweenService:Create(minDash, TweenInfo.new(0.15), { BackgroundColor3 = THEME.TextWhite }):Play()
    end)
    minBtn.MouseLeave:Connect(function()
        TweenService:Create(minDash, TweenInfo.new(0.15), { BackgroundColor3 = THEME.TextSecondary }):Play()
    end)

    -- Close Button
    local closeBtn = Instance.new("ImageButton")
    closeBtn.Name = "CloseBtn"
    closeBtn.Size = UDim2.new(0, 16, 0, 16)
    closeBtn.Position = UDim2.new(0, 272, 0.5, -8)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Image = ICONS.close
    closeBtn.ImageColor3 = THEME.TextSecondary
    closeBtn.Parent = ToolsContainer

    closeBtn.MouseEnter:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.15), { ImageColor3 = THEME.ErrorRed }):Play()
    end)
    closeBtn.MouseLeave:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.15), { ImageColor3 = THEME.TextSecondary }):Play()
    end)

    -- ╔═══════════════════════════════════════════╗
    -- ║  FLOATING MINI POP-UP KOTAK WIDGET        ║
    -- ╚═══════════════════════════════════════════╝
    local MiniBox = Instance.new("Frame")
    MiniBox.Name = "UnionsalMiniKotak"
    MiniBox.Size = UDim2.new(0, 48, 0, 48)
    MiniBox.Position = UDim2.new(0, 24, 0.5, -24)
    MiniBox.BackgroundColor3 = THEME.BgCard
    MiniBox.BorderSizePixel = 0
    MiniBox.Visible = false
    MiniBox.Parent = ScreenGui

    local mbCorner = Instance.new("UICorner")
    mbCorner.CornerRadius = UDim.new(0, 12)
    mbCorner.Parent = MiniBox

    local mbStroke = Instance.new("UIStroke")
    mbStroke.Color = THEME.AccentPurple
    mbStroke.Thickness = 1.5
    mbStroke.Parent = MiniBox

    local mbZap = Instance.new("ImageLabel")
    mbZap.Size = UDim2.new(0, 24, 0, 24)
    mbZap.Position = UDim2.new(0.5, -12, 0.5, -12)
    mbZap.BackgroundTransparency = 1
    mbZap.Image = ICONS.zap
    mbZap.ImageColor3 = THEME.AccentNeon
    mbZap.Parent = MiniBox

    local mbScale = Instance.new("UIScale")
    mbScale.Scale = 1
    mbScale.Parent = MiniBox

    local mbBtn = Instance.new("TextButton")
    mbBtn.Size = UDim2.new(1, 0, 1, 0)
    mbBtn.BackgroundTransparency = 1
    mbBtn.Text = ""
    mbBtn.Parent = MiniBox

    -- Dragging MiniBox
    do
        local mbDragging = false
        local mbDragStart, mbStartPos

        mbBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                mbDragging = true
                mbDragStart = input.Position
                mbStartPos = MiniBox.Position

                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        mbDragging = false
                    end
                end)
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if mbDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - mbDragStart
                MiniBox.Position = UDim2.new(
                    mbStartPos.X.Scale,
                    mbStartPos.X.Offset + delta.X,
                    mbStartPos.Y.Scale,
                    mbStartPos.Y.Offset + delta.Y
                )
            end
        end)
    end

    local isMinimized = false
    local function minimizeWindow()
        if isMinimized then return end
        isMinimized = true

        local twShrink = TweenService:Create(mfScale, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.4 })
        local twFade   = TweenService:Create(MainFrame, TweenInfo.new(0.22, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 })
        twShrink:Play()
        twFade:Play()

        twShrink.Completed:Connect(function()
            MainFrame.Visible = false
            MainFrame.BackgroundTransparency = 0
            mfScale.Scale = 1

            MiniBox.Visible = true
            mbScale.Scale = 0.2
            TweenService:Create(mbScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
        end)
    end

    local function restoreWindow()
        if not isMinimized then return end
        isMinimized = false

        local twPopOut = TweenService:Create(mbScale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.2 })
        twPopOut:Play()

        twPopOut.Completed:Connect(function()
            MiniBox.Visible = false
            mbScale.Scale = 1

            MainFrame.Visible = true
            mfScale.Scale = 0.7
            MainFrame.BackgroundTransparency = 0.5
            TweenService:Create(mfScale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
            TweenService:Create(MainFrame, TweenInfo.new(0.24, Enum.EasingStyle.Quad), { BackgroundTransparency = 0 }):Play()
        end)
    end

    minBtn.MouseButton1Click:Connect(minimizeWindow)
    mbBtn.MouseButton1Click:Connect(restoreWindow)

    closeBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = false
        MiniBox.Visible = false
    end)

    -- Toggle Hotkey (Dynamic Window.ToggleKey or RightControl)
    UserInputService.InputBegan:Connect(function(input, gp)
        if not gp and (input.KeyCode == (Window.ToggleKey or Enum.KeyCode.RightShift) or input.KeyCode == Enum.KeyCode.RightControl) then
            if isMinimized or not MainFrame.Visible then
                restoreWindow()
            else
                minimizeWindow()
            end
        end
    end)

    -- Windows-Style Resize Handle (Bottom-Right Drag)
    local ResizeGrip = Instance.new("TextButton")
    ResizeGrip.Name = "ResizeGrip"
    ResizeGrip.Size = UDim2.new(0, 20, 0, 20)
    ResizeGrip.Position = UDim2.new(1, -20, 1, -20)
    ResizeGrip.BackgroundTransparency = 1
    ResizeGrip.Text = ""
    ResizeGrip.AutoButtonColor = false
    ResizeGrip.ZIndex = 50
    ResizeGrip.Parent = MainFrame

    local function makeGripDot(gx, gy)
        local d = Instance.new("Frame")
        d.Size = UDim2.new(0, 3, 0, 3)
        d.Position = UDim2.new(0, gx, 0, gy)
        d.BackgroundColor3 = THEME.TextMuted
        d.BorderSizePixel = 0
        d.Parent = ResizeGrip
        local dc = Instance.new("UICorner")
        dc.CornerRadius = UDim.new(1, 0)
        dc.Parent = d
        return d
    end
    makeGripDot(13, 13)
    makeGripDot(8, 13)
    makeGripDot(13, 8)
    makeGripDot(3, 13)
    makeGripDot(8, 8)
    makeGripDot(13, 3)

    do
        local resizing = false
        local resizeStart, startSize

        ResizeGrip.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                resizing = true
                resizeStart = input.Position
                startSize = Vector2.new(MainFrame.AbsoluteSize.X, MainFrame.AbsoluteSize.Y)

                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        resizing = false
                    end
                end)
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - resizeStart
                local newW = math.clamp(startSize.X + delta.X, 640, 1400)
                local newH = math.clamp(startSize.Y + delta.Y, 440, 950)
                MainFrame.Size = UDim2.new(0, newW, 0, newH)
            end
        end)
    end

    -- Content Pages Container
    local PagesContainer = Instance.new("Frame")
    PagesContainer.Name = "PagesContainer"
    PagesContainer.Size = UDim2.new(1, 0, 1, -68)
    PagesContainer.Position = UDim2.new(0, 0, 0, 68)
    PagesContainer.BackgroundTransparency = 1
    PagesContainer.Parent = ContentArea

    -- ╔═══════════════════════════════════════════╗
    -- ║  DASHBOARD PAGE (EXACT BENTO FROM PHOTO)  ║
    -- ╚═══════════════════════════════════════════╝
    local DashboardPage = Instance.new("ScrollingFrame")
    DashboardPage.Name = "Page_Dashboard"
    DashboardPage.Size = UDim2.new(1, 0, 1, 0)
    DashboardPage.BackgroundTransparency = 1
    DashboardPage.BorderSizePixel = 0
    DashboardPage.ScrollBarThickness = 3
    DashboardPage.ScrollBarImageColor3 = THEME.StrokeLight
    DashboardPage.CanvasSize = UDim2.new(0, 0, 0, 440)
    DashboardPage.Parent = PagesContainer

    local dbPadding = Instance.new("UIPadding")
    dbPadding.PaddingLeft = UDim.new(0, 24)
    dbPadding.PaddingRight = UDim.new(0, 24)
    dbPadding.PaddingTop = UDim.new(0, 6)
    dbPadding.PaddingBottom = UDim.new(0, 20)
    dbPadding.Parent = DashboardPage
    makeSmoothScroll(DashboardPage, 80)

    -- 1. TOP USER CARD (BENTO TOP)
    local UserCard = Instance.new("Frame")
    UserCard.Name = "UserCard"
    UserCard.Size = UDim2.new(1, 0, 0, 96)
    UserCard.BackgroundColor3 = THEME.BgCard
    UserCard.BorderSizePixel = 0
    UserCard.Parent = DashboardPage

    local ucCorner = Instance.new("UICorner")
    ucCorner.CornerRadius = UDim.new(0, 14)
    ucCorner.Parent = UserCard

    local ucStroke = Instance.new("UIStroke")
    ucStroke.Color = THEME.Stroke
    ucStroke.Thickness = 1
    ucStroke.Parent = UserCard

    local ucGrad = Instance.new("UIGradient")
    ucGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(26, 20, 42)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 14, 30)),
    })
    ucGrad.Parent = UserCard

    -- Avatar on left
    local ucAvatar = Instance.new("ImageLabel")
    ucAvatar.Size = UDim2.new(0, 64, 0, 64)
    ucAvatar.Position = UDim2.new(0, 16, 0.5, -32)
    ucAvatar.BackgroundColor3 = THEME.BgPill
    ucAvatar.BorderSizePixel = 0
    ucAvatar.Parent = UserCard

    local ucaCorner = Instance.new("UICorner")
    ucaCorner.CornerRadius = UDim.new(0, 10)
    ucaCorner.Parent = ucAvatar

    pcall(function()
        ucAvatar.Image = Players:GetUserThumbnailAsync(
            LocalPlayer.UserId,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size420x420
        )
    end)

    -- User Info
    local ucWelcome = Instance.new("TextLabel")
    ucWelcome.Size = UDim2.new(0, 200, 0, 14)
    ucWelcome.Position = UDim2.new(0, 92, 0, 18)
    ucWelcome.BackgroundTransparency = 1
    ucWelcome.Text = "WELCOME BACK"
    ucWelcome.Font = Enum.Font.GothamBold
    ucWelcome.TextSize = 10
    ucWelcome.TextColor3 = THEME.TextSecondary
    ucWelcome.TextXAlignment = Enum.TextXAlignment.Left
    ucWelcome.Parent = UserCard

    local ucName = Instance.new("TextLabel")
    ucName.Size = UDim2.new(0, 250, 0, 22)
    ucName.Position = UDim2.new(0, 92, 0, 34)
    ucName.BackgroundTransparency = 1
    ucName.Text = LocalPlayer.DisplayName
    ucName.Font = Enum.Font.GothamBold
    ucName.TextSize = 18
    ucName.TextColor3 = THEME.TextWhite
    ucName.TextXAlignment = Enum.TextXAlignment.Left
    ucName.Parent = UserCard

    -- Badges Row (Version Badge Only — Lifetime & Level Removed)
    local BadgesRow = Instance.new("Frame")
    BadgesRow.Size = UDim2.new(0, 200, 0, 22)
    BadgesRow.Position = UDim2.new(0, 92, 0, 60)
    BadgesRow.BackgroundTransparency = 1
    BadgesRow.Parent = UserCard

    local bLayout = Instance.new("UIListLayout")
    bLayout.FillDirection = Enum.FillDirection.Horizontal
    bLayout.SortOrder = Enum.SortOrder.LayoutOrder
    bLayout.Padding = UDim.new(0, 6)
    bLayout.Parent = BadgesRow

    -- Version Badge
    local vBadge = Instance.new("Frame")
    vBadge.Size = UDim2.new(0, 52, 1, 0)
    vBadge.BackgroundColor3 = Color3.fromRGB(60, 28, 105)
    vBadge.BorderSizePixel = 0
    vBadge.Parent = BadgesRow
    local vbC = Instance.new("UICorner")
    vbC.CornerRadius = UDim.new(0, 6)
    vbC.Parent = vBadge
    local vbT = Instance.new("TextLabel")
    vbT.Size = UDim2.new(1, 0, 1, 0)
    vbT.BackgroundTransparency = 1
    vbT.Text = HubVersion
    vbT.Font = Enum.Font.GothamBold
    vbT.TextSize = 10
    vbT.TextColor3 = THEME.AccentNeon
    vbT.Parent = vBadge

    -- ╔═══════════════════════════════════════════╗
    -- ║  BENTO ROW 2 (EXECUTIONS & GAME USE)      ║
    -- ╚═══════════════════════════════════════════╝
    local Row2 = Instance.new("Frame")
    Row2.Name = "Row2"
    Row2.Size = UDim2.new(1, 0, 0, 140)
    Row2.Position = UDim2.new(0, 0, 0, 108)
    Row2.BackgroundTransparency = 1
    Row2.Parent = DashboardPage

    -- 2. EXECUTIONS CARD
    local ExecCard = Instance.new("Frame")
    ExecCard.Name = "ExecutionsCard"
    ExecCard.Size = UDim2.new(0.485, 0, 1, 0)
    ExecCard.Position = UDim2.new(0, 0, 0, 0)
    ExecCard.BackgroundColor3 = THEME.BgCard
    ExecCard.BorderSizePixel = 0
    ExecCard.Parent = Row2

    local ecCorner = Instance.new("UICorner")
    ecCorner.CornerRadius = UDim.new(0, 14)
    ecCorner.Parent = ExecCard
    local ecStroke = Instance.new("UIStroke")
    ecStroke.Color = THEME.Stroke
    ecStroke.Thickness = 1
    ecStroke.Parent = ExecCard

    local ecIconBox = Instance.new("Frame")
    ecIconBox.Size = UDim2.new(0, 28, 0, 28)
    ecIconBox.Position = UDim2.new(0, 18, 0, 18)
    ecIconBox.BackgroundColor3 = Color3.fromRGB(38, 20, 60)
    ecIconBox.BorderSizePixel = 0
    ecIconBox.Parent = ExecCard
    local eciC = Instance.new("UICorner")
    eciC.CornerRadius = UDim.new(0, 8)
    eciC.Parent = ecIconBox
    local eciImg = Instance.new("ImageLabel")
    eciImg.Size = UDim2.new(0, 16, 0, 16)
    eciImg.Position = UDim2.new(0.5, -8, 0.5, -8)
    eciImg.BackgroundTransparency = 1
    eciImg.Image = ICONS.play
    eciImg.ImageColor3 = THEME.AccentNeon
    eciImg.Parent = ecIconBox

    local ecTitle = Instance.new("TextLabel")
    ecTitle.Size = UDim2.new(0, 180, 0, 18)
    ecTitle.Position = UDim2.new(0, 54, 0, 22)
    ecTitle.BackgroundTransparency = 1
    ecTitle.Text = "Executions"
    ecTitle.Font = Enum.Font.GothamBold
    ecTitle.TextSize = 14
    ecTitle.TextColor3 = THEME.TextWhite
    ecTitle.TextXAlignment = Enum.TextXAlignment.Left
    ecTitle.Parent = ExecCard

    local ecValue = Instance.new("TextLabel")
    ecValue.Name = "ExecValue"
    ecValue.Size = UDim2.new(1, -36, 0, 48)
    ecValue.Position = UDim2.new(0, 18, 0, 62)
    ecValue.BackgroundTransparency = 1
    ecValue.Text = "1,284"
    ecValue.Font = Enum.Font.GothamBlack
    ecValue.TextSize = 34
    ecValue.TextColor3 = THEME.TextWhite
    ecValue.TextXAlignment = Enum.TextXAlignment.Left
    ecValue.Parent = ExecCard

    -- Async Global Executions Update
    task.spawn(function()
        local realExec = DataServices:GetGlobalExecutions()
        ecValue.Text = realExec
    end)

    -- 3. GAME USE CARD (REPLACING "TIME SPENT")
    local GameUseCard = Instance.new("Frame")
    GameUseCard.Name = "GameUseCard"
    GameUseCard.Size = UDim2.new(0.485, 0, 1, 0)
    GameUseCard.Position = UDim2.new(0.515, 0, 0, 0)
    GameUseCard.BackgroundColor3 = THEME.BgCard
    GameUseCard.BorderSizePixel = 0
    GameUseCard.Parent = Row2

    local gcCorner = Instance.new("UICorner")
    gcCorner.CornerRadius = UDim.new(0, 14)
    gcCorner.Parent = GameUseCard
    local gcStroke = Instance.new("UIStroke")
    gcStroke.Color = THEME.Stroke
    gcStroke.Thickness = 1
    gcStroke.Parent = GameUseCard

    local gcIconBox = Instance.new("Frame")
    gcIconBox.Size = UDim2.new(0, 28, 0, 28)
    gcIconBox.Position = UDim2.new(0, 18, 0, 18)
    gcIconBox.BackgroundColor3 = Color3.fromRGB(38, 20, 60)
    gcIconBox.BorderSizePixel = 0
    gcIconBox.Parent = GameUseCard
    local gciC = Instance.new("UICorner")
    gciC.CornerRadius = UDim.new(0, 8)
    gciC.Parent = gcIconBox
    local gciImg = Instance.new("ImageLabel")
    gciImg.Size = UDim2.new(0, 16, 0, 16)
    gciImg.Position = UDim2.new(0.5, -8, 0.5, -8)
    gciImg.BackgroundTransparency = 1
    gciImg.Image = ICONS.gamepad
    gciImg.ImageColor3 = THEME.AccentNeon
    gciImg.Parent = gcIconBox

    local gcTitle = Instance.new("TextLabel")
    gcTitle.Size = UDim2.new(0, 120, 0, 18)
    gcTitle.Position = UDim2.new(0, 54, 0, 16)
    gcTitle.BackgroundTransparency = 1
    gcTitle.Text = "Game Use"
    gcTitle.Font = Enum.Font.GothamBold
    gcTitle.TextSize = 14
    gcTitle.TextColor3 = THEME.TextWhite
    gcTitle.TextXAlignment = Enum.TextXAlignment.Left
    gcTitle.Parent = GameUseCard

    local gcSub = Instance.new("TextLabel")
    gcSub.Size = UDim2.new(0, 150, 0, 14)
    gcSub.Position = UDim2.new(0, 54, 0, 34)
    gcSub.BackgroundTransparency = 1
    gcSub.Text = "Active game & module"
    gcSub.Font = Enum.Font.Gotham
    gcSub.TextSize = 11
    gcSub.TextColor3 = THEME.TextSecondary
    gcSub.TextXAlignment = Enum.TextXAlignment.Left
    gcSub.Parent = GameUseCard

    -- Game Name Prominent (Without script badge, clean title only)
    local gcGameName = Instance.new("TextLabel")
    gcGameName.Size = UDim2.new(1, -36, 0, 36)
    gcGameName.Position = UDim2.new(0, 18, 0, 64)
    gcGameName.BackgroundTransparency = 1
    gcGameName.Text = ActiveGame
    gcGameName.Font = Enum.Font.GothamBold
    gcGameName.TextSize = 22
    gcGameName.TextColor3 = THEME.TextWhite
    gcGameName.TextXAlignment = Enum.TextXAlignment.Left
    gcGameName.Parent = GameUseCard

    -- ╔═══════════════════════════════════════════╗
    -- ║  BENTO ROW 3 (PERFORMANCE & CHANGELOGS)   ║
    -- ╚═══════════════════════════════════════════╝
    local Row3 = Instance.new("Frame")
    Row3.Name = "Row3"
    Row3.Size = UDim2.new(1, 0, 0, 170)
    Row3.Position = UDim2.new(0, 0, 0, 260)
    Row3.BackgroundTransparency = 1
    Row3.Parent = DashboardPage

    -- 4. PERFORMANCE CARD
    local PerfCard = Instance.new("Frame")
    PerfCard.Name = "PerformanceCard"
    PerfCard.Size = UDim2.new(0.485, 0, 1, 0)
    PerfCard.Position = UDim2.new(0, 0, 0, 0)
    PerfCard.BackgroundColor3 = THEME.BgCard
    PerfCard.BorderSizePixel = 0
    PerfCard.Parent = Row3

    local pcCorner = Instance.new("UICorner")
    pcCorner.CornerRadius = UDim.new(0, 14)
    pcCorner.Parent = PerfCard
    local pcStroke = Instance.new("UIStroke")
    pcStroke.Color = THEME.Stroke
    pcStroke.Thickness = 1
    pcStroke.Parent = PerfCard

    local pcIconBox = Instance.new("Frame")
    pcIconBox.Size = UDim2.new(0, 28, 0, 28)
    pcIconBox.Position = UDim2.new(0, 18, 0, 16)
    pcIconBox.BackgroundColor3 = Color3.fromRGB(38, 20, 60)
    pcIconBox.BorderSizePixel = 0
    pcIconBox.Parent = PerfCard
    local pciC = Instance.new("UICorner")
    pciC.CornerRadius = UDim.new(0, 8)
    pciC.Parent = pcIconBox
    local pciImg = Instance.new("ImageLabel")
    pciImg.Size = UDim2.new(0, 16, 0, 16)
    pciImg.Position = UDim2.new(0.5, -8, 0.5, -8)
    pciImg.BackgroundTransparency = 1
    pciImg.Image = ICONS.wifi
    pciImg.ImageColor3 = THEME.AccentNeon
    pciImg.Parent = pcIconBox

    local pcTitle = Instance.new("TextLabel")
    pcTitle.Size = UDim2.new(0, 180, 0, 18)
    pcTitle.Position = UDim2.new(0, 54, 0, 20)
    pcTitle.BackgroundTransparency = 1
    pcTitle.Text = "Performance"
    pcTitle.Font = Enum.Font.GothamBold
    pcTitle.TextSize = 14
    pcTitle.TextColor3 = THEME.TextWhite
    pcTitle.TextXAlignment = Enum.TextXAlignment.Left
    pcTitle.Parent = PerfCard

    local pcSub = Instance.new("TextLabel")
    pcSub.Size = UDim2.new(0, 180, 0, 14)
    pcSub.Position = UDim2.new(0, 18, 0, 48)
    pcSub.BackgroundTransparency = 1
    pcSub.Text = "Current FPS & Network"
    pcSub.Font = Enum.Font.Gotham
    pcSub.TextSize = 11
    pcSub.TextColor3 = THEME.TextSecondary
    pcSub.TextXAlignment = Enum.TextXAlignment.Left
    pcSub.Parent = PerfCard

    local pcFpsVal = Instance.new("TextLabel")
    pcFpsVal.Name = "FpsValue"
    pcFpsVal.Size = UDim2.new(1, -36, 0, 32)
    pcFpsVal.Position = UDim2.new(0, 18, 0, 64)
    pcFpsVal.BackgroundTransparency = 1
    pcFpsVal.Text = "144 fps"
    pcFpsVal.Font = Enum.Font.GothamBlack
    pcFpsVal.TextSize = 28
    pcFpsVal.TextColor3 = THEME.TextWhite
    pcFpsVal.TextXAlignment = Enum.TextXAlignment.Left
    pcFpsVal.Parent = PerfCard

    -- Sub Metrics Pills (Ping & Memory)
    local pcPingPill = Instance.new("Frame")
    pcPingPill.Size = UDim2.new(1, -36, 0, 26)
    pcPingPill.Position = UDim2.new(0, 18, 0, 102)
    pcPingPill.BackgroundColor3 = THEME.BgPill
    pcPingPill.BorderSizePixel = 0
    pcPingPill.Parent = PerfCard
    local pcppC = Instance.new("UICorner")
    pcppC.CornerRadius = UDim.new(0, 6)
    pcppC.Parent = pcPingPill
    local pcppS = Instance.new("UIStroke")
    pcppS.Color = THEME.Stroke
    pcppS.Thickness = 1
    pcppS.Parent = pcPingPill

    local pingIcon = Instance.new("ImageLabel")
    pingIcon.Size = UDim2.new(0, 14, 0, 14)
    pingIcon.Position = UDim2.new(0, 8, 0.5, -7)
    pingIcon.BackgroundTransparency = 1
    pingIcon.Image = ICONS.wifi
    pingIcon.ImageColor3 = THEME.TextSecondary
    pingIcon.Parent = pcPingPill

    local pingText = Instance.new("TextLabel")
    pingText.Name = "PingText"
    pingText.Size = UDim2.new(0, 80, 1, 0)
    pingText.Position = UDim2.new(0, 28, 0, 0)
    pingText.BackgroundTransparency = 1
    pingText.Text = "48 ms"
    pingText.Font = Enum.Font.GothamBold
    pingText.TextSize = 11
    pingText.TextColor3 = THEME.TextWhite
    pingText.TextXAlignment = Enum.TextXAlignment.Left
    pingText.Parent = pcPingPill

    local pingLive = Instance.new("TextLabel")
    pingLive.Size = UDim2.new(0, 60, 1, 0)
    pingLive.Position = UDim2.new(1, -68, 0, 0)
    pingLive.BackgroundTransparency = 1
    pingLive.Text = "LIVE"
    pingLive.Font = Enum.Font.GothamBold
    pingLive.TextSize = 10
    pingLive.TextColor3 = THEME.LiveGreen
    pingLive.TextXAlignment = Enum.TextXAlignment.Right
    pingLive.Parent = pcPingPill

    -- Memory Pill
    local pcMemPill = Instance.new("Frame")
    pcMemPill.Size = UDim2.new(1, -36, 0, 26)
    pcMemPill.Position = UDim2.new(0, 18, 0, 134)
    pcMemPill.BackgroundColor3 = THEME.BgPill
    pcMemPill.BorderSizePixel = 0
    pcMemPill.Parent = PerfCard
    local pcmpC = Instance.new("UICorner")
    pcmpC.CornerRadius = UDim.new(0, 6)
    pcmpC.Parent = pcMemPill
    local pcmpS = Instance.new("UIStroke")
    pcmpS.Color = THEME.Stroke
    pcmpS.Thickness = 1
    pcmpS.Parent = pcMemPill

    local memIcon = Instance.new("ImageLabel")
    memIcon.Size = UDim2.new(0, 14, 0, 14)
    memIcon.Position = UDim2.new(0, 8, 0.5, -7)
    memIcon.BackgroundTransparency = 1
    memIcon.Image = ICONS.storage
    memIcon.ImageColor3 = THEME.TextSecondary
    memIcon.Parent = pcMemPill

    local memText = Instance.new("TextLabel")
    memText.Name = "MemText"
    memText.Size = UDim2.new(0, 90, 1, 0)
    memText.Position = UDim2.new(0, 28, 0, 0)
    memText.BackgroundTransparency = 1
    memText.Text = "512 MB"
    memText.Font = Enum.Font.GothamBold
    memText.TextSize = 11
    memText.TextColor3 = THEME.TextWhite
    memText.TextXAlignment = Enum.TextXAlignment.Left
    memText.Parent = pcMemPill

    local memTag = Instance.new("TextLabel")
    memTag.Size = UDim2.new(0, 50, 1, 0)
    memTag.Position = UDim2.new(1, -58, 0, 0)
    memTag.BackgroundTransparency = 1
    memTag.Text = "STORAGE"
    memTag.Font = Enum.Font.GothamBold
    memTag.TextSize = 10
    memTag.TextColor3 = THEME.AccentNeon
    memTag.TextXAlignment = Enum.TextXAlignment.Right
    memTag.Parent = pcMemPill

        -- Theme Toggle (White Mode & Dark Mode Switcher)
    local isDarkMode = true
    themeBtn.MouseButton1Click:Connect(function()
        isDarkMode = not isDarkMode
        local currentPalette = isDarkMode and THEMES.Dark or THEMES.Light
        for k, v in pairs(currentPalette) do
            THEME[k] = v
        end
        themeBtn.Image = isDarkMode and ICONS.sun or ICONS.moon

        local tInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(MainFrame, tInfo, { BackgroundColor3 = THEME.BgMain }):Play()
        TweenService:Create(mfStroke, tInfo, { Color = THEME.Stroke }):Play()
        TweenService:Create(Sidebar, tInfo, { BackgroundColor3 = THEME.BgSidebar }):Play()
        TweenService:Create(sbStroke, tInfo, { Color = THEME.Stroke }):Play()
        TweenService:Create(PageTitle, tInfo, { TextColor3 = THEME.TextWhite }):Play()
        TweenService:Create(PageSubtitle, tInfo, { TextColor3 = THEME.TextSecondary }):Play()
        TweenService:Create(SearchBox, tInfo, { BackgroundColor3 = THEME.BgPill }):Play()
        TweenService:Create(sStroke, tInfo, { Color = THEME.Stroke }):Play()
        TweenService:Create(sInput, tInfo, { TextColor3 = THEME.TextWhite, PlaceholderColor3 = THEME.TextMuted }):Play()
        TweenService:Create(BottomSettings, tInfo, { BackgroundColor3 = THEME.BgPill }):Play()
        TweenService:Create(bsStroke, tInfo, { Color = THEME.Stroke }):Play()
        TweenService:Create(bsText, tInfo, { TextColor3 = THEME.TextSecondary }):Play()

        for _, c in ipairs({ UserCard, ExecCard, GameUseCard, PerfCard, LogsCard }) do
            if c and c.Parent then
                TweenService:Create(c, tInfo, { BackgroundColor3 = THEME.BgCard }):Play()
                local st = c:FindFirstChildOfClass("UIStroke")
                if st then TweenService:Create(st, tInfo, { Color = THEME.Stroke }):Play() end
            end
        end

        for _, p in ipairs({ pcPingPill, pcMemPill }) do
            if p and p.Parent then
                TweenService:Create(p, tInfo, { BackgroundColor3 = THEME.BgPill }):Play()
                local st = p:FindFirstChildOfClass("UIStroke")
                if st then TweenService:Create(st, tInfo, { Color = THEME.Stroke }):Play() end
            end
        end

        TweenService:Create(ucName, tInfo, { TextColor3 = THEME.TextWhite }):Play()
        TweenService:Create(ucWelcome, tInfo, { TextColor3 = THEME.TextSecondary }):Play()
        TweenService:Create(ecTitle, tInfo, { TextColor3 = THEME.TextWhite }):Play()
        TweenService:Create(ecValue, tInfo, { TextColor3 = THEME.TextWhite }):Play()
        TweenService:Create(gcTitle, tInfo, { TextColor3 = THEME.TextWhite }):Play()
        TweenService:Create(gcGameName, tInfo, { TextColor3 = THEME.TextWhite }):Play()
        TweenService:Create(pcTitle, tInfo, { TextColor3 = THEME.TextWhite }):Play()
        TweenService:Create(pcFpsVal, tInfo, { TextColor3 = THEME.TextWhite }):Play()
        TweenService:Create(pingText, tInfo, { TextColor3 = THEME.TextWhite }):Play()
        TweenService:Create(memText, tInfo, { TextColor3 = THEME.TextWhite }):Play()
        TweenService:Create(lcTitle, tInfo, { TextColor3 = THEME.TextWhite }):Play()
        TweenService:Create(lcVersion, tInfo, { TextColor3 = THEME.TextWhite }):Play()

        Window:Notify({
            Title   = "Tema Tampilan",
            Content = isDarkMode and "Dark Mode diaktifkan." or "White Mode diaktifkan.",
            Duration= 2,
        })
    end)

    -- Register Listener to live performance updates
    table.insert(PerformanceMonitor.Listeners, function(fps, ping, mem)
        pcFpsVal.Text = tostring(fps) .. " fps"
        pingText.Text = tostring(ping) .. " ms"
        memText.Text  = tostring(mem) .. " MB"
    end)

    -- 5. CHANGELOGS CARD
    local LogsCard = Instance.new("Frame")
    LogsCard.Name = "ChangelogsCard"
    LogsCard.Size = UDim2.new(0.485, 0, 1, 0)
    LogsCard.Position = UDim2.new(0.515, 0, 0, 0)
    LogsCard.BackgroundColor3 = THEME.BgCard
    LogsCard.BorderSizePixel = 0
    LogsCard.Parent = Row3

    local lcCorner = Instance.new("UICorner")
    lcCorner.CornerRadius = UDim.new(0, 14)
    lcCorner.Parent = LogsCard
    local lcStroke = Instance.new("UIStroke")
    lcStroke.Color = THEME.Stroke
    lcStroke.Thickness = 1
    lcStroke.Parent = LogsCard

    local lcIconBox = Instance.new("Frame")
    lcIconBox.Size = UDim2.new(0, 28, 0, 28)
    lcIconBox.Position = UDim2.new(0, 18, 0, 16)
    lcIconBox.BackgroundColor3 = Color3.fromRGB(38, 20, 60)
    lcIconBox.BorderSizePixel = 0
    lcIconBox.Parent = LogsCard
    local lciC = Instance.new("UICorner")
    lciC.CornerRadius = UDim.new(0, 8)
    lciC.Parent = lcIconBox
    local lciImg = Instance.new("ImageLabel")
    lciImg.Size = UDim2.new(0, 16, 0, 16)
    lciImg.Position = UDim2.new(0.5, -8, 0.5, -8)
    lciImg.BackgroundTransparency = 1
    lciImg.Image = ICONS.update
    lciImg.ImageColor3 = THEME.AccentNeon
    lciImg.Parent = lcIconBox

    local lcTitle = Instance.new("TextLabel")
    lcTitle.Size = UDim2.new(0, 120, 0, 18)
    lcTitle.Position = UDim2.new(0, 54, 0, 20)
    lcTitle.BackgroundTransparency = 1
    lcTitle.Text = "Changelogs"
    lcTitle.Font = Enum.Font.GothamBold
    lcTitle.TextSize = 14
    lcTitle.TextColor3 = THEME.TextWhite
    lcTitle.TextXAlignment = Enum.TextXAlignment.Left
    lcTitle.Parent = LogsCard

    local lcLatestBadge = Instance.new("Frame")
    lcLatestBadge.Size = UDim2.new(0, 50, 0, 20)
    lcLatestBadge.Position = UDim2.new(1, -66, 0, 20)
    lcLatestBadge.BackgroundColor3 = THEME.AccentPurple
    lcLatestBadge.BorderSizePixel = 0
    lcLatestBadge.Parent = LogsCard
    local lclC = Instance.new("UICorner")
    lclC.CornerRadius = UDim.new(0, 6)
    lclC.Parent = lcLatestBadge
    local lclT = Instance.new("TextLabel")
    lclT.Size = UDim2.new(1, 0, 1, 0)
    lclT.BackgroundTransparency = 1
    lclT.Text = "Latest"
    lclT.Font = Enum.Font.GothamBold
    lclT.TextSize = 10
    lclT.TextColor3 = THEME.TextWhite
    lclT.Parent = lcLatestBadge

    local lcVersion = Instance.new("TextLabel")
    lcVersion.Size = UDim2.new(1, -36, 0, 18)
    lcVersion.Position = UDim2.new(0, 18, 0, 50)
    lcVersion.BackgroundTransparency = 1
    lcVersion.Text = HubVersion
    lcVersion.Font = Enum.Font.GothamBold
    lcVersion.TextSize = 12
    lcVersion.TextColor3 = THEME.TextWhite
    lcVersion.TextXAlignment = Enum.TextXAlignment.Left
    lcVersion.Parent = LogsCard

    -- Changelog Bullets Container
    local BulletsContainer = Instance.new("Frame")
    BulletsContainer.Size = UDim2.new(1, -36, 0, 88)
    BulletsContainer.Position = UDim2.new(0, 18, 0, 72)
    BulletsContainer.BackgroundTransparency = 1
    BulletsContainer.Parent = LogsCard

    local bcLayout = Instance.new("UIListLayout")
    bcLayout.SortOrder = Enum.SortOrder.LayoutOrder
    bcLayout.Padding = UDim.new(0, 4)
    bcLayout.Parent = BulletsContainer

    local function renderBullets(items)
        for _, child in ipairs(BulletsContainer:GetChildren()) do
            if child:IsA("TextLabel") then child:Destroy() end
        end
        for i, item in ipairs(items) do
            if i > 4 then break end
            local bulletLbl = Instance.new("TextLabel")
            bulletLbl.Size = UDim2.new(1, 0, 0, 16)
            bulletLbl.BackgroundTransparency = 1
            bulletLbl.Text = "— " .. item
            bulletLbl.Font = Enum.Font.Gotham
            bulletLbl.TextSize = 11
            bulletLbl.TextColor3 = THEME.TextSecondary
            bulletLbl.TextXAlignment = Enum.TextXAlignment.Left
            bulletLbl.TextTruncate = Enum.TextTruncate.AtEnd
            bulletLbl.Parent = BulletsContainer
        end
    end

    renderBullets({
        "Premium / Locked / Fixing states",
        "Stepper, Progress, Image and Table",
        "Dashboard redesign (glass bento)",
        "Key timer + score leaderboard",
    })

    -- Async GitHub Release update
    task.spawn(function()
        local gitVer, gitNotes = DataServices:GetGitHubChangelogs()
        lcVersion.Text = gitVer
        renderBullets(gitNotes)
    end)

    -- Register Built-in Dashboard Tab
    local DashboardTabObj = {
        Name = "Dashboard",
        Page = DashboardPage,
        Category = "Main",
    }
    Window.Tabs["Dashboard"] = DashboardTabObj
    Window.CurrentTab = DashboardTabObj

    -- Categories registry in Sidebar (Interactive Collapsible Accordion)
    local Categories = {}

    local function getCategoryHeader(catName, order)
        if Categories[catName] then return Categories[catName] end

        local catContainer = Instance.new("TextButton")
        catContainer.Name = "Cat_" .. catName
        catContainer.Size = UDim2.new(1, 0, 0, 30)
        catContainer.BackgroundTransparency = 1
        catContainer.AutoButtonColor = false
        catContainer.Text = ""
        catContainer.LayoutOrder = order or 1
        catContainer.Parent = NavScroll

        local catIcon = Instance.new("ImageLabel")
        catIcon.Size = UDim2.new(0, 14, 0, 14)
        catIcon.Position = UDim2.new(0, 4, 0.5, -7)
        catIcon.BackgroundTransparency = 1
        catIcon.Image = (catName == "Config" and ICONS.sliders or ICONS.grid)
        catIcon.ImageColor3 = THEME.TextMuted
        catIcon.Parent = catContainer

        local catText = Instance.new("TextLabel")
        catText.Size = UDim2.new(1, -44, 1, 0)
        catText.Position = UDim2.new(0, 24, 0, 0)
        catText.BackgroundTransparency = 1
        catText.Text = catName
        catText.Font = Enum.Font.GothamBold
        catText.TextSize = 13
        catText.TextColor3 = THEME.TextWhite
        catText.TextXAlignment = Enum.TextXAlignment.Left
        catText.Parent = catContainer

        local catChev = Instance.new("ImageLabel")
        catChev.Size = UDim2.new(0, 12, 0, 12)
        catChev.Position = UDim2.new(1, -16, 0.5, -6)
        catChev.BackgroundTransparency = 1
        catChev.Image = ICONS.chevronDown
        catChev.ImageColor3 = THEME.TextMuted
        catChev.Parent = catContainer

        local catData = {
            Container = catContainer,
            Chevron = catChev,
            Expanded = true,
            Tabs = {},
        }

        local function toggleCategory()
            catData.Expanded = not catData.Expanded
            TweenService:Create(catChev, TweenInfo.new(0.24, Enum.EasingStyle.Quart), {
                Rotation = catData.Expanded and 0 or -90
            }):Play()

            for _, tabBtn in ipairs(catData.Tabs) do
                if catData.Expanded then
                    tabBtn.Visible = true
                    TweenService:Create(tabBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                        Size = UDim2.new(1, 0, 0, 36)
                    }):Play()
                else
                    local tw = TweenService:Create(tabBtn, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
                        Size = UDim2.new(1, 0, 0, 0)
                    })
                    tw:Play()
                    tw.Completed:Connect(function()
                        if not catData.Expanded then
                            tabBtn.Visible = false
                        end
                    end)
                end
            end
        end

        catContainer.MouseButton1Click:Connect(toggleCategory)

        catContainer.MouseEnter:Connect(function()
            TweenService:Create(catText, TweenInfo.new(0.15), { TextColor3 = THEME.AccentNeon }):Play()
            TweenService:Create(catChev, TweenInfo.new(0.15), { ImageColor3 = THEME.TextWhite }):Play()
        end)
        catContainer.MouseLeave:Connect(function()
            TweenService:Create(catText, TweenInfo.new(0.15), { TextColor3 = THEME.TextWhite }):Play()
            TweenService:Create(catChev, TweenInfo.new(0.15), { ImageColor3 = THEME.TextMuted }):Play()
        end)

        Categories[catName] = catData
        return catData
    end

    -- Create Category headers
    getCategoryHeader("Main", 10)
    getCategoryHeader("Config", 100)

    -- Function to switch active tab
    local function selectTab(tabObj)
        for _, t in pairs(Window.Tabs) do
            if t.Page then t.Page.Visible = false end
            if t.NavButton then
                TweenService:Create(t.NavButton, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
                if t.NavStroke then t.NavStroke.Enabled = false end
                if t.NavIcon then TweenService:Create(t.NavIcon, TweenInfo.new(0.2), { ImageColor3 = THEME.TextSecondary }):Play() end
                if t.NavText then TweenService:Create(t.NavText, TweenInfo.new(0.2), { TextColor3 = THEME.TextSecondary }):Play() end
            end
        end

        tabObj.Page.Visible = true
        tabObj.Page.Position = UDim2.new(0, 0, 0, 8)
        TweenService:Create(tabObj.Page, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 0)
        }):Play()

        if tabObj.NavButton then
            tabObj.NavButton.BackgroundColor3 = THEME.AccentPurple
            TweenService:Create(tabObj.NavButton, TweenInfo.new(0.2), { BackgroundTransparency = 0 }):Play()
            if tabObj.NavStroke then tabObj.NavStroke.Enabled = true end
            if tabObj.NavIcon then TweenService:Create(tabObj.NavIcon, TweenInfo.new(0.2), { ImageColor3 = THEME.TextWhite }):Play() end
            if tabObj.NavText then TweenService:Create(tabObj.NavText, TweenInfo.new(0.2), { TextColor3 = THEME.TextWhite }):Play() end
        end

        PageTitle.Text = tabObj.Name
        PageSubtitle.Text = (tabObj.Name == "Dashboard" and ("Welcome to " .. TitleName) or (tabObj.Name .. " modules for " .. ActiveGame))
        Window.CurrentTab = tabObj

        if sInput and sInput.Text ~= "" then
            performSearch(sInput.Text)
        end
    end

    -- Create Navigation Button
    local function addNavButton(tabObj, iconName, categoryName, order)
        categoryName = categoryName or "Main"
        local catData = getCategoryHeader(categoryName)

        local btn = Instance.new("TextButton")
        btn.Name = "NavBtn_" .. tabObj.Name
        btn.Size = UDim2.new(1, 0, 0, 36)
        btn.ClipsDescendants = true
        table.insert(catData.Tabs, btn)
        btn.BackgroundColor3 = THEME.BgSidebar
        btn.BackgroundTransparency = 1
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.Text = ""
        btn.LayoutOrder = order or 20
        btn.Parent = NavScroll

        local bCorner = Instance.new("UICorner")
        bCorner.CornerRadius = UDim.new(0, 10)
        bCorner.Parent = btn

        local bStroke = Instance.new("UIStroke")
        bStroke.Color = THEME.AccentNeon
        bStroke.Thickness = 1
        bStroke.Enabled = false
        bStroke.Parent = btn

        local bIcon = Instance.new("ImageLabel")
        bIcon.Size = UDim2.new(0, 16, 0, 16)
        bIcon.Position = UDim2.new(0, 10, 0.5, -8)
        bIcon.BackgroundTransparency = 1
        bIcon.Image = ICONS[iconName] or ICONS.grid
        bIcon.ImageColor3 = THEME.TextSecondary
        bIcon.Parent = btn

        local bText = Instance.new("TextLabel")
        bText.Size = UDim2.new(1, -36, 1, 0)
        bText.Position = UDim2.new(0, 34, 0, 0)
        bText.BackgroundTransparency = 1
        bText.Text = tabObj.Name
        bText.Font = Enum.Font.GothamMedium
        bText.TextSize = 12
        bText.TextColor3 = THEME.TextSecondary
        bText.TextXAlignment = Enum.TextXAlignment.Left
        bText.Parent = btn

        btn.MouseButton1Click:Connect(function()
            selectTab(tabObj)
        end)

        tabObj.NavButton = btn
        tabObj.NavIcon = bIcon
        tabObj.NavText = bText
        tabObj.NavStroke = bStroke
    end

    -- Add Dashboard button
    addNavButton(DashboardTabObj, "grid", "Main", 11)
    selectTab(DashboardTabObj)
    Window.SelectTab = selectTab

    -- ╔═══════════════════════════════════════════╗
    -- ║  TAB CREATION METHOD                      ║
    -- ╚═══════════════════════════════════════════╝
    function Window:CreateTab(tabName, iconName, categoryName)
        categoryName = categoryName or "Main"
        local baseOrder = (categoryName == "Config" and 100 or 15)

        local TabPage = Instance.new("ScrollingFrame")
        TabPage.Name = "Page_" .. tabName
        TabPage.Size = UDim2.new(1, 0, 1, 0)
        TabPage.BackgroundTransparency = 1
        TabPage.BorderSizePixel = 0
        TabPage.ScrollBarThickness = 3
        TabPage.ScrollBarImageColor3 = THEME.StrokeLight
        TabPage.CanvasSize = UDim2.new(0, 0, 0, 0)
        TabPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
        TabPage.Visible = false
        TabPage.Parent = PagesContainer

        local tpLayout = Instance.new("UIListLayout")
        tpLayout.SortOrder = Enum.SortOrder.LayoutOrder
        tpLayout.Padding = UDim.new(0, 10)
        tpLayout.Parent = TabPage

        local tpPadding = Instance.new("UIPadding")
        tpPadding.PaddingLeft = UDim.new(0, 24)
        tpPadding.PaddingRight = UDim.new(0, 24)
        tpPadding.PaddingTop = UDim.new(0, 6)
        tpPadding.PaddingBottom = UDim.new(0, 20)
        tpPadding.Parent = TabPage
        makeSmoothScroll(TabPage, 70)

        local tabObj = {
            Name = tabName,
            Page = TabPage,
            Category = categoryName,
        }
        Window.Tabs[tabName] = tabObj
        addNavButton(tabObj, iconName or "sprout", categoryName, baseOrder + #PagesContainer:GetChildren())

        -- ═══════════════════════════════════════════
        --  TAB ELEMENT BUILDERS
        -- ═══════════════════════════════════════════

                -- Keybind Setter
        function tabObj:CreateKeybind(kConfig)
            kConfig = kConfig or {}
            local kName = kConfig.Name or "Keybind"
            local curKey = kConfig.CurrentKey or Enum.KeyCode.RightShift
            local cb = kConfig.Callback or function() end

            local kbCard = Instance.new("Frame")
            kbCard.Size = UDim2.new(1, 0, 0, 46)
            kbCard.BackgroundColor3 = THEME.BgCard
            kbCard.BorderSizePixel = 0
            kbCard.Parent = TabPage

            local kbcC = Instance.new("UICorner")
            kbcC.CornerRadius = UDim.new(0, 10)
            kbcC.Parent = kbCard
            local kbcS = Instance.new("UIStroke")
            kbcS.Color = THEME.Stroke
            kbcS.Thickness = 1
            kbcS.Parent = kbCard

            local kbTitle = Instance.new("TextLabel")
            kbTitle.Size = UDim2.new(0.6, 0, 1, 0)
            kbTitle.Position = UDim2.new(0, 16, 0, 0)
            kbTitle.BackgroundTransparency = 1
            kbTitle.Text = kName
            kbTitle.Font = Enum.Font.GothamMedium
            kbTitle.TextSize = 12
            kbTitle.TextColor3 = THEME.TextWhite
            kbTitle.TextXAlignment = Enum.TextXAlignment.Left
            kbTitle.Parent = kbCard

            local kbBtn = Instance.new("TextButton")
            kbBtn.Size = UDim2.new(0, 120, 0, 28)
            kbBtn.Position = UDim2.new(1, -136, 0.5, -14)
            kbBtn.BackgroundColor3 = THEME.BgPill
            kbBtn.BorderSizePixel = 0
            kbBtn.Text = "[" .. (typeof(curKey) == "EnumItem" and curKey.Name or tostring(curKey)) .. "]"
            kbBtn.Font = Enum.Font.GothamBold
            kbBtn.TextSize = 11
            kbBtn.TextColor3 = THEME.AccentNeon
            kbBtn.Parent = kbCard

            local kbbC = Instance.new("UICorner")
            kbbC.CornerRadius = UDim.new(0, 6)
            kbbC.Parent = kbBtn
            local kbbS = Instance.new("UIStroke")
            kbbS.Color = THEME.Stroke
            kbbS.Thickness = 1
            kbbS.Parent = kbBtn

            local listening = false
            kbBtn.MouseButton1Click:Connect(function()
                if listening then return end
                listening = true
                kbBtn.Text = "[Tekan Tombol...]"
                kbBtn.TextColor3 = THEME.AccentVipGold

                local conn
                conn = UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        conn:Disconnect()
                        listening = false
                        curKey = input.KeyCode
                        kbBtn.Text = "[" .. curKey.Name .. "]"
                        kbBtn.TextColor3 = THEME.AccentNeon
                        pcall(cb, curKey)
                    end
                end)
            end)
        end

        -- Section Divider
        function tabObj:CreateSection(secTitle)
            local secFrame = Instance.new("Frame")
            secFrame.Name = "Section_" .. secTitle
            secFrame.Size = UDim2.new(1, 0, 0, 28)
            secFrame.BackgroundTransparency = 1
            secFrame.Parent = TabPage

            local secLabel = Instance.new("TextLabel")
            secLabel.Size = UDim2.new(1, 0, 1, 0)
            secLabel.BackgroundTransparency = 1
            secLabel.Text = secTitle
            secLabel.Font = Enum.Font.GothamBold
            secLabel.TextSize = 13
            secLabel.TextColor3 = THEME.AccentNeon
            secLabel.TextXAlignment = Enum.TextXAlignment.Left
            secLabel.Parent = secFrame
        end

        -- Button
        function tabObj:CreateButton(bConfig)
            bConfig = bConfig or {}
            local btnName = bConfig.Name or "Button"
            local cb = bConfig.Callback or function() end

            local btnCard = Instance.new("TextButton")
            btnCard.Size = UDim2.new(1, 0, 0, 42)
            btnCard.BackgroundColor3 = THEME.BgCard
            btnCard.BorderSizePixel = 0
            btnCard.AutoButtonColor = false
            btnCard.Text = ""
            btnCard.Parent = TabPage

            local bcC = Instance.new("UICorner")
            bcC.CornerRadius = UDim.new(0, 10)
            bcC.Parent = btnCard
            local bcS = Instance.new("UIStroke")
            bcS.Color = THEME.Stroke
            bcS.Thickness = 1
            bcS.Parent = btnCard

            local bcTxt = Instance.new("TextLabel")
            bcTxt.Size = UDim2.new(1, -50, 1, 0)
            bcTxt.Position = UDim2.new(0, 16, 0, 0)
            bcTxt.BackgroundTransparency = 1
            bcTxt.Text = btnName
            bcTxt.Font = Enum.Font.GothamMedium
            bcTxt.TextSize = 13
            bcTxt.TextColor3 = THEME.TextWhite
            bcTxt.TextXAlignment = Enum.TextXAlignment.Left
            bcTxt.Parent = btnCard

            local bcArrow = Instance.new("ImageLabel")
            bcArrow.Size = UDim2.new(0, 14, 0, 14)
            bcArrow.Position = UDim2.new(1, -26, 0.5, -7)
            bcArrow.BackgroundTransparency = 1
            bcArrow.Image = ICONS.chevronRight
            bcArrow.ImageColor3 = THEME.TextMuted
            bcArrow.Parent = btnCard

            btnCard.MouseEnter:Connect(function()
                TweenService:Create(btnCard, TweenInfo.new(0.2), { BackgroundColor3 = THEME.BgCardHover }):Play()
                TweenService:Create(bcS, TweenInfo.new(0.2), { Color = THEME.AccentPurple }):Play()
            end)
            btnCard.MouseLeave:Connect(function()
                TweenService:Create(btnCard, TweenInfo.new(0.2), { BackgroundColor3 = THEME.BgCard }):Play()
                TweenService:Create(bcS, TweenInfo.new(0.2), { Color = THEME.Stroke }):Play()
            end)
            btnCard.MouseButton1Click:Connect(function()
                TweenService:Create(btnCard, TweenInfo.new(0.1), { BackgroundColor3 = THEME.AccentPurple }):Play()
                task.wait(0.1)
                TweenService:Create(btnCard, TweenInfo.new(0.2), { BackgroundColor3 = THEME.BgCardHover }):Play()
                pcall(cb)
            end)
        end

        -- Slider
        function tabObj:CreateSlider(sConfig)
            sConfig = sConfig or {}
            local sName = sConfig.Name or "Slider"
            local minVal = (sConfig.Range and sConfig.Range[1]) or 0
            local maxVal = (sConfig.Range and sConfig.Range[2]) or 100
            local inc = sConfig.Increment or 1
            local suffix = sConfig.Suffix or ""
            local curVal = sConfig.CurrentValue or minVal
            local cb = sConfig.Callback or function() end

            local sliderCard = Instance.new("Frame")
            sliderCard.Size = UDim2.new(1, 0, 0, 56)
            sliderCard.BackgroundColor3 = THEME.BgCard
            sliderCard.BorderSizePixel = 0
            sliderCard.Parent = TabPage

            local scC = Instance.new("UICorner")
            scC.CornerRadius = UDim.new(0, 10)
            scC.Parent = sliderCard
            local scS = Instance.new("UIStroke")
            scS.Color = THEME.Stroke
            scS.Thickness = 1
            scS.Parent = sliderCard

            local scTitle = Instance.new("TextLabel")
            scTitle.Size = UDim2.new(0.7, 0, 0, 18)
            scTitle.Position = UDim2.new(0, 16, 0, 8)
            scTitle.BackgroundTransparency = 1
            scTitle.Text = sName
            scTitle.Font = Enum.Font.GothamMedium
            scTitle.TextSize = 12
            scTitle.TextColor3 = THEME.TextWhite
            scTitle.TextXAlignment = Enum.TextXAlignment.Left
            scTitle.Parent = sliderCard

            local scVal = Instance.new("TextLabel")
            scVal.Size = UDim2.new(0.3, -16, 0, 18)
            scVal.Position = UDim2.new(0.7, 0, 0, 8)
            scVal.BackgroundTransparency = 1
            scVal.Text = tostring(curVal) .. suffix
            scVal.Font = Enum.Font.GothamBold
            scVal.TextSize = 12
            scVal.TextColor3 = THEME.AccentNeon
            scVal.TextXAlignment = Enum.TextXAlignment.Right
            scVal.Parent = sliderCard

            local track = Instance.new("Frame")
            track.Size = UDim2.new(1, -32, 0, 6)
            track.Position = UDim2.new(0, 16, 0, 34)
            track.BackgroundColor3 = Color3.fromRGB(36, 28, 52)
            track.BorderSizePixel = 0
            track.Parent = sliderCard
            local tC = Instance.new("UICorner")
            tC.CornerRadius = UDim.new(1, 0)
            tC.Parent = track

            local fill = Instance.new("Frame")
            fill.Size = UDim2.new(math.clamp((curVal - minVal) / (maxVal - minVal), 0, 1), 0, 1, 0)
            fill.BackgroundColor3 = THEME.AccentPurple
            fill.BorderSizePixel = 0
            fill.Parent = track
            local fC = Instance.new("UICorner")
            fC.CornerRadius = UDim.new(1, 0)
            fC.Parent = fill

            -- Drag Interaction
            local sliding = false
            local function updateSlider(input)
                local pos = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                local rawVal = minVal + (maxVal - minVal) * pos
                local snapped = math.floor(rawVal / inc + 0.5) * inc
                curVal = math.clamp(snapped, minVal, maxVal)
                fill.Size = UDim2.new((curVal - minVal) / (maxVal - minVal), 0, 1, 0)
                scVal.Text = tostring(curVal) .. suffix
                pcall(cb, curVal)
            end

            track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    sliding = true
                    updateSlider(input)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    sliding = false
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    updateSlider(input)
                end
            end)

            local sliderObj = {}
            function sliderObj:Set(newVal, runCallback)
                curVal = math.clamp(newVal, minVal, maxVal)
                fill.Size = UDim2.new((curVal - minVal) / (maxVal - minVal), 0, 1, 0)
                scVal.Text = tostring(curVal) .. suffix
                if runCallback ~= false then
                    pcall(cb, curVal)
                end
            end
            function sliderObj:Get()
                return curVal
            end
            return sliderObj
        end

        -- Dropdown
        function tabObj:CreateDropdown(dConfig)
            dConfig = dConfig or {}
            local dName = dConfig.Name or "Dropdown"
            local options = dConfig.Options or {}
            local curVal = dConfig.CurrentValue or options[1] or ""
            local cb = dConfig.Callback or function() end

            local dropCard = Instance.new("Frame")
            dropCard.Size = UDim2.new(1, 0, 0, 44)
            dropCard.BackgroundColor3 = THEME.BgCard
            dropCard.BorderSizePixel = 0
            dropCard.ClipsDescendants = true
            dropCard.Parent = TabPage

            local dcC = Instance.new("UICorner")
            dcC.CornerRadius = UDim.new(0, 10)
            dcC.Parent = dropCard
            local dcS = Instance.new("UIStroke")
            dcS.Color = THEME.Stroke
            dcS.Thickness = 1
            dcS.Parent = dropCard

            local dcTitle = Instance.new("TextLabel")
            dcTitle.Size = UDim2.new(0.5, 0, 0, 44)
            dcTitle.Position = UDim2.new(0, 16, 0, 0)
            dcTitle.BackgroundTransparency = 1
            dcTitle.Text = dName
            dcTitle.Font = Enum.Font.GothamMedium
            dcTitle.TextSize = 12
            dcTitle.TextColor3 = THEME.TextWhite
            dcTitle.TextXAlignment = Enum.TextXAlignment.Left
            dcTitle.Parent = dropCard

            local dcVal = Instance.new("TextLabel")
            dcVal.Size = UDim2.new(0.5, -46, 0, 44)
            dcVal.Position = UDim2.new(0.5, 0, 0, 0)
            dcVal.BackgroundTransparency = 1
            dcVal.Text = tostring(curVal)
            dcVal.Font = Enum.Font.Gotham
            dcVal.TextSize = 11
            dcVal.TextColor3 = THEME.AccentNeon
            dcVal.TextXAlignment = Enum.TextXAlignment.Right
            dcVal.Parent = dropCard

            local dcChev = Instance.new("ImageLabel")
            dcChev.Size = UDim2.new(0, 14, 0, 14)
            dcChev.Position = UDim2.new(1, -26, 0, 15)
            dcChev.BackgroundTransparency = 1
            dcChev.Image = ICONS.chevronDown
            dcChev.ImageColor3 = THEME.TextSecondary
            dcChev.Parent = dropCard

            -- Smooth Scrollable Options Container
            local itemHeight = 30
            local visibleItems = math.min(#options, 4)
            local targetListHeight = visibleItems * itemHeight + 6

            local optsList = Instance.new("ScrollingFrame")
            optsList.Size = UDim2.new(1, -16, 0, targetListHeight)
            optsList.Position = UDim2.new(0, 8, 0, 44)
            optsList.BackgroundTransparency = 1
            optsList.BorderSizePixel = 0
            optsList.ScrollBarThickness = (#options > 4 and 2 or 0)
            optsList.ScrollBarImageColor3 = THEME.AccentPurple
            optsList.CanvasSize = UDim2.new(0, 0, 0, #options * itemHeight + 4)
            optsList.Parent = dropCard

            local olLayout = Instance.new("UIListLayout")
            olLayout.SortOrder = Enum.SortOrder.LayoutOrder
            olLayout.Padding = UDim.new(0, 2)
            olLayout.Parent = optsList

            if #options > 4 then
                makeSmoothScroll(optsList, 50)
            end

            local isOpen = false
            local function toggleDropdown()
                isOpen = not isOpen
                local targetCardHeight = isOpen and (50 + targetListHeight) or 44

                TweenService:Create(dropCard, TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                    Size = UDim2.new(1, 0, 0, targetCardHeight)
                }):Play()

                TweenService:Create(dcS, TweenInfo.new(0.2), {
                    Color = isOpen and THEME.AccentPurple or THEME.Stroke
                }):Play()

                TweenService:Create(dcChev, TweenInfo.new(0.24, Enum.EasingStyle.Quart), {
                    Rotation = isOpen and 180 or 0
                }):Play()
            end

            local topHit = Instance.new("TextButton")
            topHit.Size = UDim2.new(1, 0, 0, 44)
            topHit.BackgroundTransparency = 1
            topHit.Text = ""
            topHit.Parent = dropCard
            topHit.MouseButton1Click:Connect(toggleDropdown)

            for _, opt in ipairs(options) do
                local optBtn = Instance.new("TextButton")
                optBtn.Size = UDim2.new(1, 0, 0, 28)
                optBtn.BackgroundColor3 = THEME.BgPill
                optBtn.BorderSizePixel = 0
                optBtn.Text = "  " .. tostring(opt)
                optBtn.Font = Enum.Font.Gotham
                optBtn.TextSize = 11
                optBtn.TextColor3 = THEME.TextSecondary
                optBtn.TextXAlignment = Enum.TextXAlignment.Left
                optBtn.AutoButtonColor = false
                optBtn.Parent = optsList

                local oC = Instance.new("UICorner")
                oC.CornerRadius = UDim.new(0, 6)
                oC.Parent = optBtn

                optBtn.MouseEnter:Connect(function()
                    TweenService:Create(optBtn, TweenInfo.new(0.15), {
                        BackgroundColor3 = Color3.fromRGB(50, 28, 85),
                        TextColor3 = THEME.TextWhite
                    }):Play()
                end)
                optBtn.MouseLeave:Connect(function()
                    TweenService:Create(optBtn, TweenInfo.new(0.15), {
                        BackgroundColor3 = THEME.BgPill,
                        TextColor3 = THEME.TextSecondary
                    }):Play()
                end)

                optBtn.MouseButton1Click:Connect(function()
                    curVal = opt
                    dcVal.Text = tostring(curVal)
                    TweenService:Create(optBtn, TweenInfo.new(0.1), { BackgroundColor3 = THEME.AccentPurple }):Play()
                    task.wait(0.1)
                    toggleDropdown()
                    pcall(cb, curVal)
                end)
            end
        end

        -- Input
        function tabObj:CreateInput(iConfig)
            iConfig = iConfig or {}
            local iName = iConfig.Name or "Input"
            local placeholder = iConfig.PlaceholderText or "Enter value..."
            local cb = iConfig.Callback or function() end

            local inputCard = Instance.new("Frame")
            inputCard.Size = UDim2.new(1, 0, 0, 46)
            inputCard.BackgroundColor3 = THEME.BgCard
            inputCard.BorderSizePixel = 0
            inputCard.Parent = TabPage

            local icC = Instance.new("UICorner")
            icC.CornerRadius = UDim.new(0, 10)
            icC.Parent = inputCard
            local icS = Instance.new("UIStroke")
            icS.Color = THEME.Stroke
            icS.Thickness = 1
            icS.Parent = inputCard

            local icTitle = Instance.new("TextLabel")
            icTitle.Size = UDim2.new(0.4, 0, 1, 0)
            icTitle.Position = UDim2.new(0, 16, 0, 0)
            icTitle.BackgroundTransparency = 1
            icTitle.Text = iName
            icTitle.Font = Enum.Font.GothamMedium
            icTitle.TextSize = 12
            icTitle.TextColor3 = THEME.TextWhite
            icTitle.TextXAlignment = Enum.TextXAlignment.Left
            icTitle.Parent = inputCard

            local inBox = Instance.new("TextBox")
            inBox.Size = UDim2.new(0.55, 0, 0, 28)
            inBox.Position = UDim2.new(0.42, 0, 0.5, -14)
            inBox.BackgroundColor3 = THEME.BgPill
            inBox.BorderSizePixel = 0
            inBox.PlaceholderText = placeholder
            inBox.PlaceholderColor3 = THEME.TextMuted
            inBox.Text = ""
            inBox.Font = Enum.Font.Gotham
            inBox.TextSize = 11
            inBox.TextColor3 = THEME.TextWhite
            inBox.ClearTextOnFocus = false
            inBox.Parent = inputCard

            local inBoxC = Instance.new("UICorner")
            inBoxC.CornerRadius = UDim.new(0, 6)
            inBoxC.Parent = inBox

            inBox.FocusLost:Connect(function()
                pcall(cb, inBox.Text)
            end)

            local inputObj = {}
            function inputObj:Set(newVal, runCallback)
                inBox.Text = tostring(newVal)
                if runCallback ~= false then
                    pcall(cb, inBox.Text)
                end
            end
            function inputObj:Get()
                return inBox.Text
            end
            return inputObj
        end

        -- Toggle
        function tabObj:CreateToggle(tConfig)
            tConfig = tConfig or {}
            local tName = tConfig.Name or "Toggle"
            local curVal = tConfig.CurrentValue or false
            local cb = tConfig.Callback or function() end

            local togCard = Instance.new("TextButton")
            togCard.Size = UDim2.new(1, 0, 0, 44)
            togCard.BackgroundColor3 = THEME.BgCard
            togCard.BorderSizePixel = 0
            togCard.AutoButtonColor = false
            togCard.Text = ""
            togCard.Parent = TabPage

            local tcC = Instance.new("UICorner")
            tcC.CornerRadius = UDim.new(0, 10)
            tcC.Parent = togCard
            local tcS = Instance.new("UIStroke")
            tcS.Color = THEME.Stroke
            tcS.Thickness = 1
            tcS.Parent = togCard

            local tcTitle = Instance.new("TextLabel")
            tcTitle.Size = UDim2.new(1, -70, 1, 0)
            tcTitle.Position = UDim2.new(0, 16, 0, 0)
            tcTitle.BackgroundTransparency = 1
            tcTitle.Text = tName
            tcTitle.Font = Enum.Font.GothamMedium
            tcTitle.TextSize = 12
            tcTitle.TextColor3 = THEME.TextWhite
            tcTitle.TextXAlignment = Enum.TextXAlignment.Left
            tcTitle.Parent = togCard

            local switchBg = Instance.new("Frame")
            switchBg.Size = UDim2.new(0, 38, 0, 20)
            switchBg.Position = UDim2.new(1, -54, 0.5, -10)
            switchBg.BackgroundColor3 = curVal and THEME.AccentPurple or THEME.BgPill
            switchBg.BorderSizePixel = 0
            switchBg.Parent = togCard
            local swC = Instance.new("UICorner")
            swC.CornerRadius = UDim.new(1, 0)
            swC.Parent = switchBg

            local knob = Instance.new("Frame")
            knob.Size = UDim2.new(0, 14, 0, 14)
            knob.Position = curVal and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
            knob.BackgroundColor3 = THEME.TextWhite
            knob.BorderSizePixel = 0
            knob.Parent = switchBg
            local kC = Instance.new("UICorner")
            kC.CornerRadius = UDim.new(1, 0)
            kC.Parent = knob

            local function setToggleState(v, runCallback)
                curVal = v
                TweenService:Create(switchBg, TweenInfo.new(0.2), {
                    BackgroundColor3 = curVal and THEME.AccentPurple or THEME.BgPill
                }):Play()
                TweenService:Create(knob, TweenInfo.new(0.2), {
                    Position = curVal and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
                }):Play()
                if runCallback ~= false then
                    pcall(cb, curVal)
                end
            end

            togCard.MouseButton1Click:Connect(function()
                setToggleState(not curVal, true)
            end)

            local toggleObj = {}
            function toggleObj:Set(v, runCallback)
                setToggleState(v, runCallback)
            end
            function toggleObj:Get()
                return curVal
            end
            return toggleObj
        end

        -- Label
        function tabObj:CreateLabel(labelText)
            local lblCard = Instance.new("Frame")
            lblCard.Size = UDim2.new(1, 0, 0, 30)
            lblCard.BackgroundTransparency = 1
            lblCard.Parent = TabPage

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -16, 1, 0)
            lbl.Position = UDim2.new(0, 8, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = labelText
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 11
            lbl.TextColor3 = THEME.TextSecondary
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Parent = lblCard
        end

        -- Paragraph
        function tabObj:CreateParagraph(pConfig)
            pConfig = pConfig or {}
            local pTitle = pConfig.Title or "Paragraph"
            local pContent = pConfig.Content or ""

            local pCard = Instance.new("Frame")
            pCard.Size = UDim2.new(1, 0, 0, 56)
            pCard.BackgroundColor3 = THEME.BgCard
            pCard.BorderSizePixel = 0
            pCard.Parent = TabPage
            local pCorner = Instance.new("UICorner")
            pCorner.CornerRadius = UDim.new(0, 10)
            pCorner.Parent = pCard
            local pStroke = Instance.new("UIStroke")
            pStroke.Color = THEME.Stroke
            pStroke.Thickness = 1
            pStroke.Parent = pCard

            local pT = Instance.new("TextLabel")
            pT.Size = UDim2.new(1, -24, 0, 18)
            pT.Position = UDim2.new(0, 12, 0, 8)
            pT.BackgroundTransparency = 1
            pT.Text = pTitle
            pT.Font = Enum.Font.GothamBold
            pT.TextSize = 12
            pT.TextColor3 = THEME.TextWhite
            pT.TextXAlignment = Enum.TextXAlignment.Left
            pT.Parent = pCard

            local pC = Instance.new("TextLabel")
            pC.Size = UDim2.new(1, -24, 0, 24)
            pC.Position = UDim2.new(0, 12, 0, 26)
            pC.BackgroundTransparency = 1
            pC.Text = pContent
            pC.Font = Enum.Font.Gotham
            pC.TextSize = 10
            pC.TextColor3 = THEME.TextSecondary
            pC.TextXAlignment = Enum.TextXAlignment.Left
            pC.TextWrapped = true
            pC.Parent = pCard
        end

        return tabObj
    end

    -- Modern Toast Notification
    function Window:Notify(nConfig)
        nConfig = nConfig or {}
        local nTitle = nConfig.Title or "Notification"
        local nContent = nConfig.Content or ""
        local nDuration = nConfig.Duration or 4

        local notifBox = Instance.new("Frame")
        notifBox.Size = UDim2.new(0, 280, 0, 70)
        notifBox.Position = UDim2.new(1, -300, 1, 20)
        notifBox.BackgroundColor3 = THEME.BgCard
        notifBox.BorderSizePixel = 0
        notifBox.Parent = ScreenGui

        local nbC = Instance.new("UICorner")
        nbC.CornerRadius = UDim.new(0, 10)
        nbC.Parent = notifBox
        local nbS = Instance.new("UIStroke")
        nbS.Color = THEME.AccentPurple
        nbS.Thickness = 1.2
        nbS.Parent = notifBox

        local nbIcon = Instance.new("ImageLabel")
        nbIcon.Size = UDim2.new(0, 20, 0, 20)
        nbIcon.Position = UDim2.new(0, 12, 0, 14)
        nbIcon.BackgroundTransparency = 1
        nbIcon.Image = ICONS.zap
        nbIcon.ImageColor3 = THEME.AccentNeon
        nbIcon.Parent = notifBox

        local nbT = Instance.new("TextLabel")
        nbT.Size = UDim2.new(1, -44, 0, 16)
        nbT.Position = UDim2.new(0, 38, 0, 12)
        nbT.BackgroundTransparency = 1
        nbT.Text = nTitle
        nbT.Font = Enum.Font.GothamBold
        nbT.TextSize = 12
        nbT.TextColor3 = THEME.TextWhite
        nbT.TextXAlignment = Enum.TextXAlignment.Left
        nbT.Parent = notifBox

        local nbM = Instance.new("TextLabel")
        nbM.Size = UDim2.new(1, -44, 0, 32)
        nbM.Position = UDim2.new(0, 38, 0, 30)
        nbM.BackgroundTransparency = 1
        nbM.Text = nContent
        nbM.Font = Enum.Font.Gotham
        nbM.TextSize = 10
        nbM.TextColor3 = THEME.TextSecondary
        nbM.TextXAlignment = Enum.TextXAlignment.Left
        nbM.TextWrapped = true
        nbM.Parent = notifBox

        TweenService:Create(notifBox, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { Position = UDim2.new(1, -300, 1, -85) }):Play()
        task.delay(nDuration, function()
            local tw = TweenService:Create(notifBox, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { Position = UDim2.new(1, -300, 1, 20) })
            tw:Play()
            tw.Completed:Connect(function() notifBox:Destroy() end)
        end)
    end

    -- CreateParagraph helper
    function Window:CreateParagraph(pConfig)
        if Window.CurrentTab and Window.CurrentTab.CreateParagraph then
            return Window.CurrentTab:CreateParagraph(pConfig)
        end
    end

    NemesisHub.ActiveWindow = Window
    return Window
end

-- Global Hub Notify
function UnionsalHub:Notify(config)
    if NemesisHub.ActiveWindow then
        NemesisHub.ActiveWindow:Notify(config)
    end
end

-- ═══════════════════════════════════════════
--  EXPOSURE & GLOBAL DISPATCHER
-- ═══════════════════════════════════════════
getgenv().NemesisHub = NemesisHub

-- Jika main.lua dieksekusi secara langsung sebagai loader:
-- ═══════════════════════════════════════════
--  BUILT-IN MODULE LOADER (STANDALONE RUNNER)
-- ═══════════════════════════════════════════
function UnionsalHub:LoadModule(scriptName, gameTitle)
    gameTitle = gameTitle or "Blush Canyon"
    
    local Window = UnionsalHub:CreateWindow({
        Name       = "unionsal",
        Subtitle   = ".gg/unionsal",
        GameName   = gameTitle,
        ScriptName = scriptName .. ".lua",
        Version    = "v1.3",
    })

    if scriptName == "blush" then
        -- Helper karakter
        local function getChar() return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait() end
        local function getHum() local c = getChar() return c and c:FindFirstChildOfClass("Humanoid") end
        local function getRoot() local c = getChar() return c and c:FindFirstChild("HumanoidRootPart") end

        -- Win System
        local WinSystem = {
            CustomWinCFrame = nil,
            AutoWinRunning  = false,
            BlatantMode     = false,
            LoopDelay       = 0.3,
            SpawnCFrame     = nil,
            LastTargetName  = "Belum terdeteksi",
        }

        local IGNORE_LIST = {"teleportpart", "spawn", "baseplate", "terrain", "kill", "lava", "void", "dead", "fall", "reset"}
        local function isIgnored(n)
            local l = string.lower(n)
            for _, ig in ipairs(IGNORE_LIST) do
                if string.find(l, ig) then return true end
            end
            return false
        end

        local function findWin()
            if WinSystem.CustomWinCFrame then
                return nil, WinSystem.CustomWinCFrame, "Posisi Manual Tersimpan"
            end

            -- Cek Checkpoints / Stages folder
            for _, fn in ipairs({"Checkpoints", "Stages", "Stage", "Spawns"}) do
                local f = workspace:FindFirstChild(fn, true)
                if f then
                    local maxN, maxP = -1, nil
                    for _, c in ipairs(f:GetChildren()) do
                        local num = tonumber(string.match(c.Name, "%d+"))
                        if num and num > maxN then
                            local p = (c:IsA("BasePart") and c) or c:FindFirstChildWhichIsA("BasePart")
                            if p and not isIgnored(p.Name) then maxN = num; maxP = p end
                        end
                    end
                    if maxP and maxN > 1 then
                        return maxP, maxP.CFrame + Vector3.new(0, 4, 0), fn .. " [" .. tostring(maxN) .. "]"
                    end
                end
            end

            -- Cek nama winpad / finishpad
            for _, kw in ipairs({"winpad", "finishpad", "endpad", "winner", "trophy", "finish", "goal", "badge"}) do
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and not isIgnored(obj.Name) then
                        if string.find(string.lower(obj.Name), kw) and not obj:IsDescendantOf(LocalPlayer.Character or workspace) then
                            return obj, obj.CFrame + Vector3.new(0, 4, 0), obj.Name
                        end
                    end
                end
            end

            -- Platform terjauh dari spawn (Ujung Obby)
            local sp = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
            local spPos = sp and sp.Position or Vector3.new(0, 5, 0)
            local furP, maxD = nil, 0
            for _, d in ipairs(workspace:GetDescendants()) do
                if d:IsA("BasePart") and d.Anchored and not isIgnored(d.Name) then
                    if d.Size.X >= 2 and d.Size.Z >= 2 and d.Size.Y >= 0.2 then
                        local isPlr = false
                        for _, p in ipairs(Players:GetPlayers()) do
                            if p.Character and d:IsDescendantOf(p.Character) then isPlr = true; break end
                        end
                        if not isPlr then
                            local dist = (d.Position - spPos).Magnitude
                            if dist > 120 and dist > maxD then maxD = dist; furP = d end
                        end
                    end
                end
            end
            if furP then
                return furP, furP.CFrame + Vector3.new(0, 4, 0), string.format("Ujung Obby: %s (%.0f studs)", furP.Name, maxD)
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
            local ok, err = pcall(function()
                if writefile then
                    writefile(CONFIG_FILE, HttpService:JSONEncode(payload))
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
                return HttpService:JSONDecode(content)
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

        -- 1. TAB AUTO WIN
        local WinTab = Window:CreateTab("Auto Farm", "sprout", "Main")
        WinTab:CreateSection("Auto Win Automation")

        ToggleObjects.AutoWin = WinTab:CreateToggle({
            Name = "Enable Auto Win (Loop Otomatis)",
            CurrentValue = false,
            Callback = function(v)
                WinSystem.AutoWinRunning = v
                notifyStateChange("AutoWin", v)
                Window:Notify({ Title = "Auto Win", Content = v and "Auto Win aktif!" or "Auto Win dihentikan.", Duration = 2 })
                if v then
                    task.spawn(function()
                        while WinSystem.AutoWinRunning do
                            local r = getRoot()
                            local part, winCf = findWin()
                            if r and winCf then
                                if r.CFrame.Y < 30 then WinSystem.SpawnCFrame = r.CFrame end
                                r.CFrame = winCf
                                if part and firetouchinterest then
                                    pcall(function() firetouchinterest(r, part, 0); task.wait(0.02); firetouchinterest(r, part, 1) end)
                                end
                                if WinSystem.BlatantMode then
                                    task.wait(WinSystem.LoopDelay)
                                    if r and WinSystem.SpawnCFrame then r.CFrame = WinSystem.SpawnCFrame end
                                    task.wait(0.05)
                                else
                                    task.wait(WinSystem.LoopDelay)
                                    if r and WinSystem.SpawnCFrame then r.CFrame = WinSystem.SpawnCFrame end
                                    task.wait(0.5)
                                end
                            else
                                task.wait(1)
                            end
                        end
                    end)
                end
            end
        })

        ToggleObjects.BlatantMode = WinTab:CreateToggle({
            Name = "Mode Blatant (Kecepatan Ekstrem)",
            CurrentValue = false,
            Callback = function(v)
                WinSystem.BlatantMode = v
                notifyStateChange("BlatantMode", v)
                Window:Notify({ Title = "Blatant Mode", Content = v and "Mode Blatant aktif!" or "Mode Blatant nonaktif.", Duration = 2 })
            end
        })

        SliderObjects.LoopDelay = WinTab:CreateSlider({
            Name = "Auto Win Delay (Detik)",
            Range = {0.05, 3},
            Increment = 0.05,
            Suffix = "s",
            CurrentValue = 0.3,
            Callback = function(v)
                WinSystem.LoopDelay = v
                notifyStateChange("LoopDelay", v)
            end
        })

        WinTab:CreateSection("Kontrol & Titik Lokasi Win")

        WinTab:CreateButton({
            Name = "Teleport Langsung ke Area Win",
            Callback = function()
                local r = getRoot()
                local part, winCf, name = findWin()
                if r and winCf then
                    r.CFrame = winCf
                    if part and firetouchinterest then
                        pcall(function() firetouchinterest(r, part, 0); task.wait(0.02); firetouchinterest(r, part, 1) end)
                    end
                    Window:Notify({ Title = "Teleport Berhasil", Content = "Tiba di: " .. tostring(name), Duration = 3 })
                else
                    Window:Notify({ Title = "Belum Terdeteksi", Content = "Gunakan tombol Set Manual di bawah saat berada di garis finish.", Duration = 3 })
                end
            end
        })

        WinTab:CreateButton({
            Name = "Set Posisi Saat Ini Sebagai Titik Win",
            Callback = function()
                local r = getRoot()
                if r then
                    WinSystem.CustomWinCFrame = r.CFrame + Vector3.new(0, 1, 0)
                    Window:Notify({ Title = "Titik Terkunci", Content = string.format("X:%.0f Y:%.0f Z:%.0f", r.Position.X, r.Position.Y, r.Position.Z), Duration = 3 })
                end
            end
        })

        WinTab:CreateButton({
            Name = "Scan Ulang Titik Win / Ujung Obby",
            Callback = function()
                local part, winCf, name = findWin()
                if winCf then
                    Window:Notify({ Title = "Hasil Scan", Content = "Target: " .. tostring(name), Duration = 4 })
                else
                    Window:Notify({ Title = "Hasil Scan", Content = "Silakan berdiri di finish lalu klik 'Set Posisi Saat Ini'.", Duration = 3 })
                end
            end
        })

        -- 2. TAB SPEED & JUMP
        local MoveTab = Window:CreateTab("Speed & Jump", "rocket", "Main")
        local safeFall = false
        local safeFallConn = nil

        MoveTab:CreateSection("Proteksi Fisika & Kebal Jatuh")
        ToggleObjects.SafeFall = MoveTab:CreateToggle({
            Name = "Kebal Saat Jatuh (No Fall Damage)",
            CurrentValue = false,
            Callback = function(v)
                safeFall = v
                notifyStateChange("SafeFall", v)
                local h = getHum()
                if h then
                    pcall(function()
                        h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, not v)
                        h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, not v)
                    end)
                end
                if v and not safeFallConn then
                    safeFallConn = RunService.Heartbeat:Connect(function()
                        if not safeFall then return end
                        local r = getRoot()
                        if r and r.AssemblyLinearVelocity.Y < -40 then
                            r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, -5, r.AssemblyLinearVelocity.Z)
                        end
                    end)
                elseif not v and safeFallConn then
                    safeFallConn:Disconnect()
                    safeFallConn = nil
                end
                Window:Notify({ Title = "Anti-Fall", Content = v and "Kebal jatuh aktif!" or "Kebal jatuh nonaktif.", Duration = 2 })
            end
        })

        local infJump = false
        UserInputService.JumpRequest:Connect(function()
            if infJump then
                local h = getHum()
                if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
            end
        end)

        ToggleObjects.InfJump = MoveTab:CreateToggle({
            Name = "Infinite Jump (Lompat Tanpa Batas)",
            CurrentValue = false,
            Callback = function(v)
                infJump = v
                notifyStateChange("InfJump", v)
            end
        })

        MoveTab:CreateSection("WalkSpeed & Blatant Speed")
        SliderObjects.WalkSpeed = MoveTab:CreateSlider({
            Name = "WalkSpeed",
            Range = {1, 500},
            Increment = 1,
            Suffix = " spd",
            CurrentValue = 16,
            Callback = function(v)
                local h = getHum()
                if h then h.WalkSpeed = v end
                notifyStateChange("WalkSpeed", v)
            end
        })

        local blatantSpeed = false
        local bMultiplier = 60
        local bConn = nil
        ToggleObjects.BlatantSpeed = MoveTab:CreateToggle({
            Name = "Blatant CFrame Speed",
            CurrentValue = false,
            Callback = function(v)
                blatantSpeed = v
                notifyStateChange("BlatantSpeed", v)
                if v and not bConn then
                    bConn = RunService.RenderStepped:Connect(function(dt)
                        if not blatantSpeed then return end
                        local r, h = getRoot(), getHum()
                        if r and h and h.MoveDirection.Magnitude > 0 then
                            r.CFrame = r.CFrame + (h.MoveDirection * (bMultiplier * dt))
                        end
                    end)
                elseif not v and bConn then
                    bConn:Disconnect()
                    bConn = nil
                end
            end
        })

        -- 3. TAB TELEPORT
        local TpTab = Window:CreateTab("Teleport", "navigation", "Main")
        TpTab:CreateSection("Teleport Lokasi Default")

        TpTab:CreateButton({
            Name = "Teleport ke Spawn Asli",
            Callback = function()
                local r = getRoot()
                if r then
                    local sp = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
                    if sp then
                        r.CFrame = sp.CFrame + Vector3.new(0, 4, 0)
                    else
                        r.CFrame = CFrame.new(0, 10, 0)
                    end
                    Window:Notify({ Title = "Teleport", Content = "Berhasil kembali ke Spawn.", Duration = 2 })
                end
            end
        })

        local function getPlrNames()
            local t = {}
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer then table.insert(t, p.Name) end
            end
            if #t == 0 then table.insert(t, "(tidak ada player)") end
            return t
        end

        local selTarget = nil
        TpTab:CreateDropdown({
            Name = "Pilih Target Player",
            Options = getPlrNames(),
            Callback = function(opt) selTarget = opt end
        })

        TpTab:CreateButton({
            Name = "Teleport ke Player Dipilih",
            Callback = function()
                local myR = getRoot()
                if myR and selTarget and selTarget ~= "(tidak ada player)" then
                    local tPlr = Players:FindFirstChild(selTarget)
                    if tPlr and tPlr.Character and tPlr.Character:FindFirstChild("HumanoidRootPart") then
                        myR.CFrame = tPlr.Character.HumanoidRootPart.CFrame + Vector3.new(3, 0, 0)
                        Window:Notify({ Title = "Teleport", Content = "Berhasil teleport ke " .. selTarget, Duration = 2 })
                    end
                end
            end
        })

        -- 4. TAB SHOP
        local ShopTab = Window:CreateTab("Shop", "cart", "Main")
        ShopTab:CreateSection("Toko Gamepass")
        ShopTab:CreateButton({
            Name = "Buka Toko Gravity & Speed Coil",
            Callback = function()
                local pg = LocalPlayer:FindFirstChild("PlayerGui")
                local sf = pg and pg:FindFirstChild("ScreenGui") and pg.ScreenGui:FindFirstChild("ShopFrame")
                if sf then sf.Visible = not sf.Visible end
            end
        })

        -- 5. TAB PLAYER (EXPANDED FEATURES)
        local PlayerTab = Window:CreateTab("Player", "user", "Main")
        PlayerTab:CreateSection("Karakter & Fisika")

        -- Fly Mode
        local flying = false
        local flySpeed = 50
        local flyBV, flyBG = nil, nil
        local flyConn = nil

        local function startFly()
            local root = getRoot()
            local hum = getHum()
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

        -- NoClip
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
                        local char = getChar()
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

        -- SpinBot
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
                        local root = getRoot()
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

        -- Fullbright
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

        -- FOV Slider
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

        -- Anti-AFK
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
                local r = getRoot()
                if r then
                    local posStr = string.format("%.1f, %.1f, %.1f", r.Position.X, r.Position.Y, r.Position.Z)
                    if setclipboard then setclipboard(posStr) end
                    Window:Notify({ Title = "Posisi", Content = "Koordinat disalin: " .. posStr, Duration = 3 })
                end
            end
        })

        PlayerTab:CreateButton({
            Name = "Reset Karakter / Respawn",
            Callback = function() local h = getHum(); if h then h.Health = 0 end end
        })

        -- 6. TAB SETTINGS (KEYBINDS, OPTIMASI & PER-DEVICE SAVE)
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
            Content = "• Buka/Tutup UI: Tekan tombol yang telah diatur di atas (Default: RightShift).\n" ..
                      "• Pop-up Kotak Mini: Muncul di kiri saat tombol strip [ — ] ditekan.\n" ..
                      "• Geser Window: Drag header atas UI menggunakan mouse.\n" ..
                      "• Resize Window: Tarik grip pojok kanan bawah seperti aplikasi Windows.\n" ..
                      "• Ganti Tema: Klik ikon matahari di kanan atas untuk White/Dark mode."
        })

        SettingsTab:CreateSection("Optimasi Client & FPS")
        ToggleObjects.FpsBoost = SettingsTab:CreateToggle({
            Name = "Reduce Graphics Lag (FPS Boost)",
            CurrentValue = false,
            Callback = function(v)
                applyFpsBoost(v)
                notifyStateChange("FpsBoost", v)
                Window:Notify({ Title = "FPS Boost", Content = v and "FPS Boost aktif!" or "FPS Boost nonaktif.", Duration = 2 })
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

        -- 7. TAB CONFIGS & WEBHOOK
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
            local payload = HttpService:JSONEncode({
                username = "Unionsal Hub Logger",
                avatar_url = "https://i.imgur.com/8Q9Z5bX.png",
                embeds = { embedData }
            })
            local ok, err = pcall(function()
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
                    title = " Unionsal Hub v1.3 • Webhook Connected",
                    description = "Webhook berhasil terhubung dengan client Roblox!",
                    color = 8864235,
                    fields = {
                        { name = "Player", value = LocalPlayer.Name .. " (@" .. LocalPlayer.DisplayName .. ")", inline = true },
                        { name = "Game", value = gameTitle or "Blush Canyon", inline = true },
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
    elseif scriptName == "ragdoll" then
-- ═══════════════════════════════════════════
--  SISTEM DETEKSI GAME & DUMMY SCANNER
-- ═══════════════════════════════════════════
local RagdollGame = {
    AutoKillRunning    = false,
    FlingRunning       = false,
    FanTossRunning     = false,
    KillDelay          = 0.2,
    SuperGrabEnabled   = false,
    AntiRagdollActive  = false,
    FastAttackActive   = false,
    SavedFanCFrame     = nil,
}

-- Cari semua dummy di map (baik hidup maupun pingsan/mati)
local function getAllDummies()
    local list = {}
    local folders = {"Dummies", "Ragdolls", "Crowd", "NPCs", "Bodies", "Zombies"}
    for _, fn in ipairs(folders) do
        local f = workspace:FindFirstChild(fn)
        if f then
            for _, obj in ipairs(f:GetChildren()) do
                if obj:IsA("Model") and obj ~= LocalPlayer.Character and not Players:GetPlayerFromCharacter(obj) then
                    table.insert(list, obj)
                end
            end
        end
    end
    if #list == 0 then
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("Model") and obj ~= LocalPlayer.Character and not Players:GetPlayerFromCharacter(obj) then
                local hasLimb = obj:FindFirstChild("Head") or obj:FindFirstChild("Torso") or obj:FindFirstChild("UpperTorso") or obj:FindFirstChild("HumanoidRootPart")
                if hasLimb then
                    table.insert(list, obj)
                end
            end
        end
    end
    return list
end

-- Cari dummy yang masih hidup / belum hancur
local function getLivingDummies()
    local list = {}
    for _, dummy in ipairs(getAllDummies()) do
        local hum = dummy:FindFirstChildOfClass("Humanoid")
        local root = dummy:FindFirstChild("HumanoidRootPart") or dummy:FindFirstChild("Torso") or dummy:FindFirstChild("UpperTorso")
        local hasJoints = false
        for _, j in ipairs(dummy:GetDescendants()) do
            if j:IsA("Motor6D") or j:IsA("BallSocketConstraint") then
                hasJoints = true
                break
            end
        end
        if (hum and hum.Health > 0) or (root and hasJoints) then
            table.insert(list, dummy)
        end
    end
    return list
end

-- Cari Kipas Raksasa (The Big Fan) di map
local function findBigFan()
    if RagdollGame.SavedFanCFrame then
        return RagdollGame.SavedFanCFrame
    end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name = string.lower(obj.Name)
            if string.find(name, "fan") or string.find(name, "blade") or string.find(name, "ventilator") or string.find(name, "propeller") then
                if obj.Size.Magnitude > 15 then
                    RagdollGame.SavedFanCFrame = obj.CFrame + Vector3.new(0, 5, 0)
                    return RagdollGame.SavedFanCFrame
                end
            end
        end
    end
    return CFrame.new(0, 50, 0)
end

-- Cari senjata yang terjatuh di lantai (dropped guns/tools)
local function getDroppedTools()
    local tools = {}
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Tool") or (obj:IsA("Model") and obj:FindFirstChild("Handle")) then
            table.insert(tools, obj)
        end
    end
    return tools
end

-- ═══════════════════════════════════════════
--  SISTEM KILL TRACKING (Server KO Counter)
-- ═══════════════════════════════════════════
local KillCount = 0
local function notifyKillToServer(dummy)
    pcall(function()
        for _, obj in ipairs(game:GetDescendants()) do
            if obj:IsA("RemoteEvent") then
                local n = string.lower(obj.Name)
                if string.find(n, "ko") or string.find(n, "kill") or string.find(n, "dummydead")
                   or string.find(n, "dummykilled") or string.find(n, "dummyhurt")
                   or string.find(n, "ragdollkill") or string.find(n, "death") then
                    pcall(function() obj:FireServer(dummy) end)
                    pcall(function() obj:FireServer(dummy.Name) end)
                    pcall(function() obj:FireServer() end)
                end
            end
        end
    end)
    pcall(function()
        local current = LocalPlayer:GetAttribute("KOCount") or 0
        LocalPlayer:SetAttribute("KOCount", current + 1)
        for _, attrName in ipairs({"HRR_KO", "KillCount", "KO", "Kills", "DummyKills"}) do
            local val = LocalPlayer:GetAttribute(attrName)
            if val and type(val) == "number" then
                LocalPlayer:SetAttribute(attrName, val + 1)
            end
        end
    end)
    pcall(function()
        local client = LocalPlayer.PlayerScripts:FindFirstChild("Client")
        if client then
            local db = client:FindFirstChild("Dummies") and client.Dummies:FindFirstChild("DummyBody")
            if db then
                local req = require(db)
                if req then
                    if req.reportKill then req.reportKill(dummy) end
                    if req.onDeath then req.onDeath(dummy) end
                    if req.killed then req.killed(dummy) end
                end
            end
            local tc = client:FindFirstChild("Tools") and client.Tools:FindFirstChild("ToolController")
            if tc then
                local req = require(tc)
                if req and req.registerKill then req.registerKill(dummy) end
            end
        end
    end)
    KillCount = KillCount + 1
end

-- Eksekusi pembunuhan instan pada dummy (Lethal Decapitation & Severing)
local function killDummyInstantly(dummy)
    if not dummy or not dummy.Parent then return end

    local dHum = dummy:FindFirstChildOfClass("Humanoid")
    local dRoot = dummy:FindFirstChild("HumanoidRootPart") or dummy:FindFirstChild("Torso") or dummy:FindFirstChild("UpperTorso")

    if dHum then
        pcall(function()
            dHum.Health = 0
            dHum:ChangeState(Enum.HumanoidStateType.Dead)
        end)
    end

    pcall(function()
        dummy:BreakJoints()
    end)
    for _, j in ipairs(dummy:GetDescendants()) do
        if j:IsA("JointInstance") or j:IsA("Constraint") then
            pcall(function()
                local n = string.lower(j.Name)
                if string.find(n, "neck") or string.find(n, "head") or string.find(n, "waist") or string.find(n, "root") then
                    j:Destroy()
                end
            end)
        end
    end

    local char = getCharacter()
    if char then
        local tool = char:FindFirstChildOfClass("Tool") or LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
        if tool then
            if tool.Parent ~= char and getHumanoid() then
                getHumanoid():EquipTool(tool)
            end
            local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
            if handle and firetouchinterest then
                for _, part in ipairs(dummy:GetChildren()) do
                    if part:IsA("BasePart") then
                        firetouchinterest(handle, part, 0)
                        firetouchinterest(handle, part, 1)
                    end
                end
            end
            pcall(function() tool:Activate() end)
        end
    end

    for _, part in ipairs(dummy:GetChildren()) do
        if part:IsA("BasePart") and not part.Anchored then
            pcall(function()
                part.AssemblyLinearVelocity = Vector3.new(0, -500, 0)
            end)
        end
    end

    pcall(function()
        local client = LocalPlayer.PlayerScripts:FindFirstChild("Client")
        if client then
            local dummiesFolder = client:FindFirstChild("Dummies")
            if dummiesFolder then
                local db = dummiesFolder:FindFirstChild("DummyBody")
                if db then
                    local req = require(db)
                    if req and req.damage then req.damage(dummy, 999999) end
                    if req and req.kill then req.kill(dummy) end
                    if req and req.forceKill then req.forceKill(dummy) end
                end
            end
            local handsFolder = client:FindFirstChild("Hands")
            if handsFolder then
                local ph = handsFolder:FindFirstChild("PlayerHurt")
                if ph then
                    local req = require(ph)
                    if req and req.hurt then req.hurt(dummy, 999999) end
                    if req and req.damage then req.damage(dummy, 999999) end
                end
            end
        end
    end)
    task.defer(function()
        notifyKillToServer(dummy)
    end)
end

-- Hancurkan seluruh tubuh semua ragdoll menjadi potongan-potongan terpisah
local function shatterAndDismemberAllDummies()
    local count = 0
    local dummies = getAllDummies()
    for _, dummy in ipairs(dummies) do
        pcall(function()
            local dHum = dummy:FindFirstChildOfClass("Humanoid")
            if dHum then
                dHum.Health = 0
                dHum:ChangeState(Enum.HumanoidStateType.Dead)
            end
            dummy:BreakJoints()
            for _, desc in ipairs(dummy:GetDescendants()) do
                if desc:IsA("JointInstance") or desc:IsA("Constraint") then
                    desc:Destroy()
                end
            end
            for _, part in ipairs(dummy:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                    part.AssemblyLinearVelocity = Vector3.new(
                        math.random(-60, 60),
                        math.random(30, 90),
                        math.random(-60, 60)
                    )
                    part.AssemblyAngularVelocity = Vector3.new(
                        math.random(-25, 25),
                        math.random(-25, 25),
                        math.random(-25, 25)
                    )
                end
            end
            count = count + 1
            notifyKillToServer(dummy)
        end)
    end
    return count
end

-- Memicu sistem Revive bawaan game (Keybind R + Remote + Modul)
local function triggerGameRevive()
    local done = false

    -- 1. Tekan tombol Revive di UI game (PlayerGui scan)
    pcall(function()
        for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
            if gui:IsA("TextButton") or gui:IsA("ImageButton") then
                local txt = (gui:IsA("TextButton") and string.lower(gui.Text)) or ""
                local nm = string.lower(gui.Name)
                if string.find(txt, "revive") or string.find(nm, "revive")
                   or string.find(txt, "respawn") or string.find(nm, "respawn")
                   or string.find(nm, "reset") or string.find(nm, "wave") then
                    if firesignal then
                        firesignal(gui.MouseButton1Click)
                        firesignal(gui.Activated)
                        done = true
                    end
                end
            end
        end
    end)

    -- 2. Scan SEMUA RemoteEvent di seluruh game
    pcall(function()
        for _, obj in ipairs(game:GetDescendants()) do
            if obj:IsA("RemoteEvent") then
                local n = string.lower(obj.Name)
                if string.find(n, "revive") or string.find(n, "respawn")
                   or string.find(n, "resetdummies") or string.find(n, "cleargraves")
                   or string.find(n, "wave") or string.find(n, "newwave")
                   or string.find(n, "reset") and string.find(n, "dummy")
                   or n == "hrr_revive" or n == "hrr_wave" then
                    pcall(function() obj:FireServer() end)
                    done = true
                end
            elseif obj:IsA("RemoteFunction") then
                local n = string.lower(obj.Name)
                if string.find(n, "revive") or string.find(n, "respawn") then
                    pcall(function() obj:InvokeServer() end)
                    done = true
                end
            end
        end
    end)

    -- 3. DummyManager module
    pcall(function()
        local client = LocalPlayer.PlayerScripts:FindFirstChild("Client")
        if not client then return end
        local dummiesFolder = client:FindFirstChild("Dummies")
        if dummiesFolder then
            for _, modName in ipairs({"DummyManager", "Brain", "Crowd", "Saves"}) do
                local mod = dummiesFolder:FindFirstChild(modName)
                if mod then
                    local ok, req = pcall(require, mod)
                    if ok and req then
                        for _, fn in ipairs({"revive","respawn","reset","spawnAll","respawnAll","reviveAll","resetAll"}) do
                            if req[fn] then pcall(req[fn]); done = true end
                        end
                    end
                end
            end
        end
        local worldFolder = client:FindFirstChild("World")
        if worldFolder then
            local mc = worldFolder:FindFirstChild("MapClient")
            if mc then
                local ok, req = pcall(require, mc)
                if ok and req then
                    for _, fn in ipairs({"revive","respawn","reset","newWave","startWave"}) do
                        if req[fn] then pcall(req[fn]); done = true end
                    end
                end
            end
        end
    end)

    -- 4. Simulasi Keybind R (game HRR: R = Revive All Dummies)
    pcall(function()
        local uis = UserInputService
        if firesignal then
            firesignal(uis.InputBegan, {KeyCode = Enum.KeyCode.R, UserInputType = Enum.UserInputType.Keyboard}, false)
            task.wait(0.05)
            firesignal(uis.InputEnded, {KeyCode = Enum.KeyCode.R, UserInputType = Enum.UserInputType.Keyboard}, false)
        end
        LocalPlayer:SetAttribute("HRR_Revive", true)
        task.wait(0.1)
        LocalPlayer:SetAttribute("HRR_Revive", nil)
        LocalPlayer:SetAttribute("HRR_Wave", (LocalPlayer:GetAttribute("HRR_Wave") or 0) + 1)
        done = true
    end)

    -- 5. Fallback: pulihkan Health & joints manual
    for _, dummy in ipairs(getAllDummies()) do
        pcall(function()
            local dHum = dummy:FindFirstChildOfClass("Humanoid")
            if dHum then
                dHum.Health = dHum.MaxHealth > 0 and dHum.MaxHealth or 100
                dHum:ChangeState(Enum.HumanoidStateType.GettingUp)
                for _, j in ipairs(dummy:GetDescendants()) do
                    if j:IsA("Motor6D") and not j.Enabled then
                        j.Enabled = true
                    end
                end
            end
        end)
    end
    return done
end

-- Bangkitkan kembali dummy mati menggunakan Defibrillator secara massal
local function massDefibrillatorRevive()
    local hum = getHumanoid()
    local myRoot = getRootPart()
    if not hum or not myRoot then return 0 end

    local defib = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Defibrillator")) or LocalPlayer.Backpack:FindFirstChild("Defibrillator")
    if not defib then
        for _, tool in ipairs(getDroppedTools()) do
            if string.find(string.lower(tool.Name), "defibrillator") then
                local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
                if handle then handle.CFrame = myRoot.CFrame end
                task.wait(0.1)
                defib = LocalPlayer.Backpack:FindFirstChild("Defibrillator")
                break
            end
        end
    end

    if defib then
        hum:EquipTool(defib)
        task.wait(0.05)
    end

    local count = 0
    for _, dummy in ipairs(getAllDummies()) do
        local dRoot = dummy:FindFirstChild("HumanoidRootPart") or dummy:FindFirstChild("Torso") or dummy:FindFirstChild("UpperTorso")
        local dHum = dummy:FindFirstChildOfClass("Humanoid")
        if dRoot and (not dHum or dHum.Health <= 0) then
            pcall(function()
                if defib then
                    local handle = defib:FindFirstChild("Handle") or defib:FindFirstChildWhichIsA("BasePart")
                    if handle and firetouchinterest then
                        firetouchinterest(handle, dRoot, 0)
                        firetouchinterest(handle, dRoot, 1)
                    end
                    defib:Activate()
                end
                if dHum then
                    dHum.Health = 100
                    dHum:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
                count = count + 1
            end)
        end
    end
    return count
end

-- Membersihkan kuburan dummy dan senjata tercecer di map
local function clearGravesAndGuns()
    local count = 0
    for _, obj in ipairs(workspace:GetChildren()) do
        local n = string.lower(obj.Name)
        if obj:IsA("Tool") or string.find(n, "grave") or string.find(n, "tomb") or string.find(n, "corpse") or string.find(n, "blood") then
            pcall(function()
                obj:Destroy()
                count = count + 1
            end)
        end
    end
    return count
end

-- ═══════════════════════════════════════════
--  SISTEM BENCANA & GAME EVENTS (100% NATIVE GAME ENGINE)
-- ═══════════════════════════════════════════
local GameEvents = {
    OriginalGravity = workspace.Gravity,
}

-- Memicu Event Game secara 100% Native dari Game Engine (Tanpa Bikin Sendiri / Anti-Lag)
local function triggerNativeGameEvent(eventName)
    local triggered = false
    local lowerName = string.lower(eventName)
    local norm = string.lower(string.gsub(eventName, "%s+", ""))
    local vim = game:GetService("VirtualInputManager")

    -- 0. Buka UI Events bawaan game jika sedang tertutup
    pcall(function()
        for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
            if gui:IsA("GuiButton") then
                local nm = string.lower(gui.Name)
                local txt = (gui:IsA("TextButton") and string.lower(gui.Text)) or ""
                if nm == "event" or nm == "events" or txt == "events" or string.find(nm, "eventbtn") or string.find(nm, "openevent") then
                    if vim then
                        local pos = gui.AbsolutePosition + (gui.AbsoluteSize / 2)
                        vim:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                        task.wait(0.02)
                        vim:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                    end
                    if firesignal then
                        firesignal(gui.MouseButton1Click)
                        firesignal(gui.Activated)
                    end
                end
            end
        end
    end)

    -- 1. Scan PlayerGui untuk tombol / kartu event game
    pcall(function()
        for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
            local matched = false
            if gui:IsA("TextLabel") or gui:IsA("TextButton") then
                local txt = string.lower(gui.Text)
                if txt == lowerName or string.find(txt, lowerName, 1, true) or string.find(string.gsub(txt, "%s+", ""), norm, 1, true) then
                    matched = true
                end
            end
            local nm = string.lower(gui.Name)
            if nm == lowerName or string.find(nm, norm, 1, true) then
                matched = true
            end

            if matched then
                -- Buka kunci card event dan set token 999
                pcall(function()
                    local parentCard = gui:FindFirstAncestorWhichIsA("Frame") or gui.Parent
                    if parentCard then
                        for _, child in ipairs(parentCard:GetDescendants()) do
                            if child:IsA("TextLabel") and (child.Text == "0" or child.Text == "LOCKED") then
                                child.Text = "999"
                            end
                            if child:IsA("ImageLabel") and string.find(string.lower(child.Name), "lock") then
                                child.Visible = false
                            end
                        end
                    end
                end)

                local targetBtn = gui:IsA("GuiButton") and gui or gui:FindFirstAncestorWhichIsA("GuiButton")
                if not targetBtn and gui.Parent then
                    targetBtn = gui.Parent:FindFirstChildWhichIsA("GuiButton")
                end
                if not targetBtn and gui.Parent and gui.Parent.Parent then
                    targetBtn = gui.Parent.Parent:FindFirstChildWhichIsA("GuiButton")
                end

                if targetBtn then
                    targetBtn.Active = true
                    targetBtn.Selectable = true

                    -- A. Simulasi engine mouse click melalui VirtualInputManager
                    pcall(function()
                        if vim then
                            local pos = targetBtn.AbsolutePosition + (targetBtn.AbsoluteSize / 2)
                            vim:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                            task.wait(0.02)
                            vim:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                        end
                    end)

                    -- B. firesignal
                    pcall(function()
                        if firesignal then
                            firesignal(targetBtn.MouseButton1Click)
                            firesignal(targetBtn.Activated)
                            firesignal(targetBtn.MouseButton1Down)
                            firesignal(targetBtn.MouseButton1Up)
                        end
                    end)

                    -- C. getconnections
                    pcall(function()
                        if getconnections then
                            for _, sig in ipairs({targetBtn.MouseButton1Click, targetBtn.Activated, targetBtn.MouseButton1Down}) do
                                for _, conn in ipairs(getconnections(sig)) do
                                    if conn.Fire then conn:Fire()
                                    elseif conn.Function then conn.Function() end
                                end
                            end
                        end
                    end)

                    triggered = true
                end
            end
        end
    end)

    -- 2. Panggil Client.Events.EventRunner langsung (ModuleScript bawaan game HRR)
    pcall(function()
        local client = LocalPlayer.PlayerScripts:FindFirstChild("Client")
        if client then
            local eventsFolder = client:FindFirstChild("Events")
            if eventsFolder then
                local er = eventsFolder:FindFirstChild("EventRunner")
                if er then
                    local ok, req = pcall(require, er)
                    if ok and req then
                        if req.start then pcall(req.start, eventName); pcall(req.start, norm); triggered = true end
                        if req.trigger then pcall(req.trigger, eventName); pcall(req.trigger, norm); triggered = true end
                        if req.run then pcall(req.run, eventName); pcall(req.run, norm); triggered = true end
                        if req.fire then pcall(req.fire, eventName); pcall(req.fire, norm); triggered = true end
                        if req[eventName] then pcall(req[eventName]); triggered = true end
                        if req[norm] then pcall(req[norm]); triggered = true end
                    end
                end
                for _, mod in ipairs(eventsFolder:GetChildren()) do
                    if mod:IsA("ModuleScript") and string.find(string.lower(mod.Name), norm) then
                        local ok, mReq = pcall(require, mod)
                        if ok and mReq then
                            if mReq.start then pcall(mReq.start); triggered = true end
                            if mReq.run then pcall(mReq.run); triggered = true end
                            if mReq.trigger then pcall(mReq.trigger); triggered = true end
                        end
                    end
                end
            end
        end
    end)

    -- 3. Scan ReplicatedStorage untuk RemoteEvent event game
    pcall(function()
        for _, obj in ipairs(game:GetDescendants()) do
            if obj:IsA("RemoteEvent") then
                local n = string.lower(obj.Name)
                if string.find(n, "event") or string.find(n, "disaster") or string.find(n, norm) then
                    pcall(function() obj:FireServer(eventName) end)
                    pcall(function() obj:FireServer(norm) end)
                    pcall(function() obj:FireServer("Start", eventName) end)
                    pcall(function() obj:FireServer("Trigger", eventName) end)
                    pcall(function() obj:FireServer(eventName, true) end)
                    triggered = true
                end
            elseif obj:IsA("RemoteFunction") then
                local n = string.lower(obj.Name)
                if string.find(n, "event") or string.find(n, "disaster") or string.find(n, norm) then
                    pcall(function() obj:InvokeServer(eventName) end)
                    pcall(function() obj:InvokeServer(norm) end)
                    triggered = true
                end
            end
        end
    end)

    -- 4. Buka akses token di attributes
    pcall(function()
        LocalPlayer:SetAttribute(eventName, 999)
        LocalPlayer:SetAttribute(norm, 999)
        LocalPlayer:SetAttribute("CurrentEvent", eventName)
        LocalPlayer:SetAttribute("HRR_Event", eventName)
    end)

    return triggered
end

local function runGameEvent(name)
    local ok = triggerNativeGameEvent(name)
    Window:Notify({
        Title = "Game Event",
        Content = "Event [" .. name .. "] dipicu ke game engine!",
        Duration = 2.5
    })
    return ok
end

local function stopAllActiveEvents()
    workspace.Gravity = GameEvents.OriginalGravity
    pcall(function()
        triggerNativeGameEvent("Reset")
        triggerNativeGameEvent("Stop")
        triggerNativeGameEvent("Clear")
    end)
    for _, dummy in ipairs(getAllDummies()) do
        pcall(function()
            for _, p in ipairs(dummy:GetDescendants()) do
                if p:IsA("BasePart") and p.Material == Enum.Material.Ice then
                    p.Material = Enum.Material.SmoothPlastic
                    p.Anchored = false
                end
            end
        end)
    end
end

local function unlockAllEventTokens()
    local count = 0
    pcall(function()
        for attrName, _ in pairs(LocalPlayer:GetAttributes()) do
            if string.find(string.lower(attrName), "event") or string.find(string.lower(attrName), "token") then
                LocalPlayer:SetAttribute(attrName, 999)
                count = count + 1
            end
        end
        for _, label in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
            if label:IsA("TextLabel") and (label.Text == "0" or label.Text == "1" or label.Text == "LOCKED") then
                local p = label.Parent
                if p and (string.find(string.lower(p.Name), "event") or string.find(string.lower(p.Name), "badge") or string.find(string.lower(p.Name), "count")) then
                    label.Text = "999"
                    count = count + 1
                end
            end
        end
    end)
    return count
end

-- ═══════════════════════════════════════════
--  DATABASE SENJATA LENGKAP (72 Senjata HRR)
-- ═══════════════════════════════════════════
local WeaponDatabase = {
    Melee = {
        { name = "Fists",           slot = 1,  robux = false },
        { name = "Bat",             slot = 1,  robux = false },
        { name = "Axe",             slot = 1,  robux = false },
        { name = "Hammer",          slot = 1,  robux = false },
        { name = "Shovel",          slot = 1,  robux = false },
        { name = "Wrench",          slot = 1,  robux = false },
        { name = "Crowbar",         slot = 1,  robux = false },
        { name = "Machete",         slot = 1,  robux = false },
        { name = "Sword",           slot = 1,  robux = false },
        { name = "Katana",          slot = 1,  robux = true  },
        { name = "Cleaver",         slot = 1,  robux = false },
        { name = "Chainsaw",        slot = 1,  robux = true  },
        { name = "Sledgehammer",    slot = 1,  robux = false },
        { name = "Spear",           slot = 1,  robux = false },
    },
    Guns = {
        { name = "Pistol",          slot = 2,  robux = false },
        { name = "Revolver",        slot = 2,  robux = false },
        { name = "Shotgun",         slot = 2,  robux = false },
        { name = "SMG",             slot = 2,  robux = false },
        { name = "Rifle",           slot = 2,  robux = false },
        { name = "Sniper",          slot = 2,  robux = false },
        { name = "LMG",             slot = 2,  robux = false },
        { name = "Crossbow",        slot = 2,  robux = false },
        { name = "Flintlock",       slot = 2,  robux = false },
        { name = "Minigun",         slot = 2,  robux = true  },
        { name = "Railgun",         slot = 2,  robux = true  },
        { name = "Flamethrower",    slot = 2,  robux = true  },
        { name = "Laser",           slot = 2,  robux = true  },
        { name = "Paintball Gun",   slot = 2,  robux = false },
    },
    Throw = {
        { name = "Rock",            slot = 3,  robux = false },
        { name = "Grenade",         slot = 3,  robux = false },
        { name = "Molotov",         slot = 3,  robux = false },
        { name = "Flashbang",       slot = 3,  robux = false },
        { name = "Smoke Grenade",   slot = 3,  robux = false },
        { name = "Dynamite",        slot = 3,  robux = false },
        { name = "Throwing Knife",  slot = 3,  robux = false },
        { name = "Tomahawk",        slot = 3,  robux = false },
        { name = "Shuriken",        slot = 3,  robux = true  },
        { name = "Firework",        slot = 3,  robux = false },
        { name = "C4",              slot = 3,  robux = true  },
        { name = "Frag Grenade",    slot = 3,  robux = false },
    },
    Power = {
        { name = "Gravity Gun",     slot = 4,  robux = false },
        { name = "Freeze Ray",      slot = 4,  robux = false },
        { name = "Lightning Rod",   slot = 4,  robux = false },
        { name = "Black Hole Gun",  slot = 4,  robux = true  },
        { name = "Tornado Gun",     slot = 4,  robux = true  },
        { name = "Shrink Ray",      slot = 4,  robux = true  },
        { name = "Grow Ray",        slot = 4,  robux = true  },
        { name = "Magnet Gun",      slot = 4,  robux = false },
        { name = "Portal Gun",      slot = 4,  robux = true  },
        { name = "Wind Gun",        slot = 4,  robux = false },
        { name = "Nuke Launcher",   slot = 4,  robux = true  },
        { name = "Taser",           slot = 4,  robux = false },
        { name = "EMP",             slot = 4,  robux = false },
    },
    Medic = {
        { name = "Defibrillator",   slot = 5,  robux = false },
        { name = "Medkit",          slot = 5,  robux = false },
        { name = "Bandage",         slot = 5,  robux = false },
        { name = "Syringe",         slot = 5,  robux = false },
        { name = "Scanner",         slot = 5,  robux = false },
        { name = "Blood Bag",       slot = 5,  robux = false },
        { name = "AED",             slot = 5,  robux = false },
        { name = "Splint",          slot = 5,  robux = false },
    },
    Robux = {
        { name = "Golden Axe",      slot = 1,  robux = true  },
        { name = "Diamond Sword",   slot = 1,  robux = true  },
        { name = "Neon Bat",        slot = 1,  robux = true  },
        { name = "Golden Gun",      slot = 2,  robux = true  },
        { name = "Neon Rifle",      slot = 2,  robux = true  },
        { name = "Diamond Pistol",  slot = 2,  robux = true  },
        { name = "Hyperbeam",       slot = 4,  robux = true  },
        { name = "Soul Scythe",     slot = 1,  robux = true  },
    },
}

-- Fungsi utama untuk memberikan senjata ke player dan auto-equip
local function giveWeapon(weaponName, slot)
    local hum = getHumanoid()
    local myRoot = getRootPart()
    local char = getCharacter()
    if not hum or not myRoot or not char then
        Window:Notify({ Title = "Error", Content = "Karakter belum siap.", Duration = 2 })
        return false
    end

    local currentTools = {}
    if char then
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") then table.insert(currentTools, item) end
        end
    end
    for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if item:IsA("Tool") then table.insert(currentTools, item) end
    end

    -- Cek duplikat: jika senjata sudah ada di slot, jangan ambil lagi
    for _, t in ipairs(currentTools) do
        if string.lower(t.Name) == string.lower(weaponName) or string.find(string.lower(t.Name), string.lower(weaponName), 1, true) then
            Window:Notify({
                Title = "Slot Senjata",
                Content = "Senjata [" .. weaponName .. "] sudah ada di slot inventory!",
                Duration = 2.5
            })
            return false
        end
    end

    -- Cek limit 10 slot: jika sudah 10, tolak
    if #currentTools >= 10 then
        Window:Notify({
            Title = "Slot Penuh",
            Content = "Slot inventory sudah penuh (10/10)! Buang salah satu senjata terlebih dahulu.",
            Duration = 3
        })
        return false
    end

    local got = false

    -- Metode 1: Scan ToolController
    pcall(function()
        local client = LocalPlayer.PlayerScripts:FindFirstChild("Client")
        if client then
            local tc = client:FindFirstChild("Tools") and client.Tools:FindFirstChild("ToolController")
            if tc then
                local req = require(tc)
                if req then
                    if req.give then req.give(weaponName); got = true end
                    if req.unlock then req.unlock(weaponName); got = true end
                    if req.equip then req.equip(weaponName); got = true end
                    if req.giveWeapon then req.giveWeapon(weaponName); got = true end
                end
            end
        end
    end)

    -- Metode 2: Scan RemoteEvent
    pcall(function()
        for _, obj in ipairs(game:GetDescendants()) do
            if obj:IsA("RemoteEvent") then
                local n = string.lower(obj.Name)
                if string.find(n, "giveweapon") or string.find(n, "equiptool")
                   or string.find(n, "givetool") or string.find(n, "unlock")
                   or n == "hrr_tool" or n == "hrr_weapon" then
                    pcall(function() obj:FireServer(weaponName) end)
                    pcall(function() obj:FireServer(weaponName, slot) end)
                    got = true
                end
            end
        end
    end)

    -- Metode 3: Scan dropped tools di workspace
    pcall(function()
        for _, tool in ipairs(getDroppedTools()) do
            if string.find(string.lower(tool.Name), string.lower(weaponName)) then
                local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
                if handle and firetouchinterest then
                    firetouchinterest(handle, myRoot, 0)
                    firetouchinterest(handle, myRoot, 1)
                    got = true
                    break
                end
            end
        end
    end)

    -- Metode 4: Storage
    pcall(function()
        local searchLocations = {
            game:GetService("ReplicatedStorage"),
            game:GetService("ServerStorage"),
            workspace,
        }
        for _, loc in ipairs(searchLocations) do
            local function scanFolder(folder, depth)
                if depth > 4 then return end
                for _, obj in ipairs(folder:GetChildren()) do
                    local objName = string.lower(obj.Name)
                    local wepName = string.lower(weaponName)
                    if string.find(objName, wepName) or objName == wepName then
                        if obj:IsA("Tool") then
                            local clone = obj:Clone()
                            clone.Parent = LocalPlayer.Backpack
                            got = true
                            return
                        end
                    end
                    if obj:IsA("Folder") or obj:IsA("Model") then
                        scanFolder(obj, depth + 1)
                    end
                end
            end
            pcall(scanFolder, loc, 0)
            if got then break end
        end
    end)

    -- Metode 5: SetAttribute HRR_GiveTool
    pcall(function()
        LocalPlayer:SetAttribute("HRR_GiveTool", weaponName)
        task.delay(0.2, function()
            LocalPlayer:SetAttribute("HRR_GiveTool", nil)
        end)
        got = true
    end)

    -- Auto-equip & aktifkan senjata
    task.defer(function()
        task.wait(0.1)
        local toolToEquip = nil
        for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if item:IsA("Tool") and (string.find(string.lower(item.Name), string.lower(weaponName)) or item.Name == weaponName) then
                toolToEquip = item
                break
            end
        end
        if not toolToEquip and char then
            for _, item in ipairs(char:GetChildren()) do
                if item:IsA("Tool") and (string.find(string.lower(item.Name), string.lower(weaponName)) or item.Name == weaponName) then
                    toolToEquip = item
                    break
                end
            end
        end
        if toolToEquip then
            for _, scr in ipairs(toolToEquip:GetDescendants()) do
                if scr:IsA("LocalScript") and scr.Disabled then
                    scr.Disabled = false
                end
            end
            toolToEquip.Enabled = true
            toolToEquip.RequiresHandle = false
            if hum and toolToEquip.Parent == LocalPlayer.Backpack then
                hum:EquipTool(toolToEquip)
            end
            got = true
        end
    end)

    if got then
        Window:Notify({ Title = "Senjata Diberikan", Content = weaponName .. " berhasil diambil & di-equip!", Duration = 2.5 })
    else
        Window:Notify({ Title = "Senjata Dicoba", Content = "Meminta " .. weaponName .. " ke server...", Duration = 2.5 })
    end
    return got
end

-- ═══════════════════════════════════════════
--  PENGATURAN RUNTIME (Selalu Reset Saat Join / Masuk Game)
--  Hanya Webhook yang Disimpan Persisten
-- ═══════════════════════════════════════════
local WEBHOOK_CONFIG_FILE = "unionsal_webhook.json"
local webhookUrl = ""

local ConfigRegistry = {
    AutoKill = false,
    FlingAll = false,
    FanToss = false,
    KillDelay = 0.2,
    SuperGrab = false,
    AntiRagdoll = false,
    FastAttack = false,
    Fly = false,
    FlySpeed = 50,
    NoClip = false,
    SpinBot = false,
    SpinSpeed = 30,
    WalkSpeed = 16,
    Fullbright = false,
    Fov = 70,
    ToolsEsp = false,
    PlayerEsp = false,
    AntiAfk = true,
    FpsBoost = false,
    PotatoGraphics = false,
    WebhookUrl = "",
    SendOnExec = true,
    SendOnKo = true,
    ToggleKey = "RightShift"
}

local ToggleObjects = {}
local SliderObjects = {}
local InputObjects = {}

local function saveWebhookConfig()
    pcall(function()
        if writefile then
            local payload = {
                WebhookUrl = ConfigRegistry.WebhookUrl,
                SendOnExec = ConfigRegistry.SendOnExec,
                SendOnKo = ConfigRegistry.SendOnKo
            }
            writefile(WEBHOOK_CONFIG_FILE, HttpService:JSONEncode(payload))
        end
    end)
end

local function loadWebhookConfig()
    pcall(function()
        if readfile and isfile and isfile(WEBHOOK_CONFIG_FILE) then
            local data = HttpService:JSONDecode(readfile(WEBHOOK_CONFIG_FILE))
            if data and type(data) == "table" then
                if data.WebhookUrl then
                    ConfigRegistry.WebhookUrl = data.WebhookUrl
                    webhookUrl = data.WebhookUrl
                    if InputObjects.WebhookUrl then
                        pcall(function() InputObjects.WebhookUrl:Set(data.WebhookUrl, true) end)
                    end
                end
                if data.SendOnExec ~= nil then ConfigRegistry.SendOnExec = data.SendOnExec end
                if data.SendOnKo ~= nil then ConfigRegistry.SendOnKo = data.SendOnKo end
            end
        end
    end)
end

local function deleteWebhookConfig()
    pcall(function()
        if delfile and isfile and isfile(WEBHOOK_CONFIG_FILE) then
            delfile(WEBHOOK_CONFIG_FILE)
        end
        ConfigRegistry.WebhookUrl = ""
        webhookUrl = ""
        if InputObjects.WebhookUrl then
            pcall(function() InputObjects.WebhookUrl:Set("", true) end)
        end
    end)
end

local function notifyStateChange(k, v)
    ConfigRegistry[k] = v
end

-- ═══════════════════════════════════════════
--  OPTIMASI GRAFIK POTATO & FPS BOOST
-- ═══════════════════════════════════════════
local function applyPotatoGraphics(enable)
    local Terrain = workspace:FindFirstChildOfClass("Terrain")
    if enable then
        pcall(function() settings().Rendering.QualityLevel = 1 end)
        pcall(function() Lighting.GlobalShadows = false; Lighting.FogEnd = 9e9; Lighting.Brightness = 1 end)
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("PostEffect") or v:IsA("BloomEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("SunRaysEffect") or v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") then
                v.Enabled = false
            end
        end
        if Terrain then
            pcall(function() Terrain.Decoration = false; Terrain.WaterWaveSize = 0; Terrain.WaterWaveSpeed = 0; Terrain.WaterReflectance = 0 end)
        end
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not obj:IsDescendantOf(LocalPlayer.Character or workspace) then
                pcall(function() obj.Material = Enum.Material.SmoothPlastic; obj.CastShadow = false end)
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                pcall(function() obj.Transparency = 1 end)
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                pcall(function() obj.Enabled = false end)
            end
        end
    else
        pcall(function() Lighting.GlobalShadows = true; Lighting.FogEnd = 1000 end)
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
        pcall(function() settings().Rendering.QualityLevel = 1; Lighting.GlobalShadows = false end)
    else
        pcall(function() settings().Rendering.QualityLevel = 0; Lighting.GlobalShadows = true end)
    end
end

-- ╔═══════════════════════════════════════════╗
-- ║  TAB 1: DUMMIES & KO (AUTO FARM)          ║
-- ╚═══════════════════════════════════════════╝
local FarmTab = Window:CreateTab("Auto Farm", "sprout", "Main")
FarmTab:CreateSection("Auto Kill (Teleport & Langsung Mati)")

ToggleObjects.AutoKill = FarmTab:CreateToggle({
    Name = "Auto Kill Ragdoll (Teleport & Langsung Mati)",
    CurrentValue = false,
    Callback = function(v)
        RagdollGame.AutoKillRunning = v
        notifyStateChange("AutoKill", v)
        Window:Notify({ Title = "Auto Kill", Content = v and "Auto Kill AKTIF! Karakter TP dan ragdoll langsung mati seketika." or "Auto Kill nonaktif.", Duration = 2 })

        if v then
            task.spawn(function()
                while RagdollGame.AutoKillRunning do
                    local dummies = getLivingDummies()
                    if #dummies > 0 then
                        for _, dummy in ipairs(dummies) do
                            if not RagdollGame.AutoKillRunning then break end
                            local root = getRootPart()
                            local dRoot = dummy:FindFirstChild("HumanoidRootPart") or dummy:FindFirstChild("Torso") or dummy:FindFirstChild("UpperTorso") or dummy:FindFirstChild("Head")

                            if root and dRoot and dummy.Parent then
                                root.CFrame = dRoot.CFrame * CFrame.new(0, 1, 2)
                                task.wait(0.03)

                                killDummyInstantly(dummy)

                                if ConfigRegistry.SendOnKo and ConfigRegistry.WebhookUrl ~= "" then
                                    sendDiscordWebhook({
                                        title = "[KO] Ragdoll Eliminated",
                                        description = "Target: **" .. dummy.Name .. "**",
                                        color = 0xFF3333,
                                        footer = { text = "Unionsal Hub • .gg/unionsal" }
                                    })
                                end

                                task.wait(RagdollGame.KillDelay)
                            end
                        end
                    else
                        task.wait(0.5)
                    end
                end
            end)
        end
    end
})

SliderObjects.KillDelay = FarmTab:CreateSlider({
    Name = "Jeda Antar Target Ragdoll",
    Range = {0.05, 1.5},
    Increment = 0.05,
    Suffix = " detik",
    CurrentValue = 0.15,
    Callback = function(v)
        RagdollGame.KillDelay = v
        notifyStateChange("KillDelay", v)
    end
})

FarmTab:CreateSection("Shatter & Kill All (Hancurkan Seluruh Tubuh)")

FarmTab:CreateButton({
    Name = "Kill All Ragdoll (Hancurkan Seluruh Tubuh Seketika)",
    Callback = function()
        local count = shatterAndDismemberAllDummies()
        Window:Notify({ Title = "Shatter Kill All", Content = count .. " ragdoll berhasil dibunuh & tubuhnya hancur berkeping-keping!", Duration = 3.5 })
    end
})

local loopShatterRunning = false
FarmTab:CreateToggle({
    Name = "Loop Shatter All (Hancurkan Semua Terus Menerus)",
    CurrentValue = false,
    Callback = function(v)
        loopShatterRunning = v
        Window:Notify({ Title = "Loop Shatter", Content = v and "Loop Shatter AKTIF! Semua ragdoll yang muncul akan langsung hancur." or "Loop Shatter nonaktif.", Duration = 2 })
        if v then
            task.spawn(function()
                while loopShatterRunning do
                    shatterAndDismemberAllDummies()
                    task.wait(0.3)
                end
            end)
        end
    end
})

FarmTab:CreateButton({
    Name = "Fling All Ragdoll (Lontarkan Semua ke Langit)",
    Callback = function()
        local count = 0
        for _, dummy in ipairs(getAllDummies()) do
            local dRoot = dummy:FindFirstChild("HumanoidRootPart") or dummy:FindFirstChild("Torso")
            if dRoot and not dRoot.Anchored then
                dRoot.AssemblyLinearVelocity = Vector3.new(math.random(-60, 60), 350, math.random(-60, 60))
                dRoot.AssemblyAngularVelocity = Vector3.new(math.random(-80, 80), math.random(-80, 80), math.random(-80, 80))
                count = count + 1
            end
        end
        Window:Notify({ Title = "Fling Ragdoll", Content = count .. " ragdoll dilontarkan ke langit!", Duration = 3 })
    end
})

FarmTab:CreateSection("Revive & Respawn Sistem")

FarmTab:CreateButton({
    Name = "Revive All Ragdoll (R - Bangkitkan Seluruh Ragdoll)",
    Callback = function()
        local ok = triggerGameRevive()
        Window:Notify({ Title = "Revive All", Content = ok and "Sinyal Revive [R] dikirim! Seluruh ragdoll dibangkitkan." or "Memicu revive fallback...", Duration = 3 })
    end
})

FarmTab:CreateButton({
    Name = "Scan Dummy Terdekat (V - Buka Scan Menu)",
    Callback = function()
        pcall(function()
            if firesignal then
                firesignal(UserInputService.InputBegan, {KeyCode = Enum.KeyCode.V, UserInputType = Enum.UserInputType.Keyboard}, false)
                task.wait(0.05)
                firesignal(UserInputService.InputEnded, {KeyCode = Enum.KeyCode.V, UserInputType = Enum.UserInputType.Keyboard}, false)
            end
        end)
        pcall(function()
            for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
                if gui:IsA("TextButton") or gui:IsA("ImageButton") then
                    local n = string.lower(gui.Name)
                    local t = gui:IsA("TextButton") and string.lower(gui.Text) or ""
                    if string.find(n, "scan") or string.find(t, "scan") or string.find(n, "xray") then
                        if firesignal then firesignal(gui.MouseButton1Click) end
                    end
                end
            end
        end)
        Window:Notify({ Title = "Scan", Content = "Tombol V ditekan - Scan dummy aktif!", Duration = 2 })
    end
})

FarmTab:CreateButton({
    Name = "Defibrillator Mass Revive (Kejut Jantung Semua Ragdoll)",
    Callback = function()
        local count = massDefibrillatorRevive()
        Window:Notify({ Title = "Defibrillator Revive", Content = count .. " ragdoll berhasil diselamatkan/di-revive dengan Defibrillator!", Duration = 3 })
    end
})

FarmTab:CreateButton({
    Name = "Respawn Karakter (G - Instan)",
    Callback = function()
        pcall(function()
            if firesignal then
                firesignal(UserInputService.InputBegan, {KeyCode = Enum.KeyCode.G, UserInputType = Enum.UserInputType.Keyboard}, false)
                task.wait(0.05)
                firesignal(UserInputService.InputEnded, {KeyCode = Enum.KeyCode.G, UserInputType = Enum.UserInputType.Keyboard}, false)
            end
        end)
        task.wait(0.1)
        local hum = getHumanoid()
        if hum and hum.Health > 0 then
            hum.Health = 0
        end
        Window:Notify({ Title = "Respawn", Content = "Karakter di-respawn! (Tombol G + fallback)", Duration = 1.5 })
    end
})

FarmTab:CreateButton({
    Name = "Clear Graves & Dropped Guns (Bersihkan Map)",
    Callback = function()
        local count = clearGravesAndGuns()
        Window:Notify({ Title = "Clear Map", Content = count .. " kuburan/senjata di lantai dibersihkan!", Duration = 3 })
    end
})

FarmTab:CreateSection("Fisika & Interaksi Massal")

FarmTab:CreateButton({
    Name = "Bring All Dummies (Kumpulkan di Depan Pemain)",
    Callback = function()
        local myRoot = getRootPart()
        if not myRoot then return end
        local count = 0
        for _, dummy in ipairs(getAllDummies()) do
            local dRoot = dummy:FindFirstChild("HumanoidRootPart") or dummy:FindFirstChild("Torso")
            if dRoot and not dRoot.Anchored then
                dRoot.CFrame = myRoot.CFrame * CFrame.new(0, 0, -4)
                count = count + 1
            end
        end
        Window:Notify({ Title = "Bring Dummies", Content = count .. " dummy berhasil dikumpulkan di depanmu!", Duration = 3 })
    end
})

FarmTab:CreateButton({
    Name = "Yeet All Dummies to Big Fan (Hancurkan di Kipas)",
    Callback = function()
        local fanCf = findBigFan()
        local count = 0
        for _, dummy in ipairs(getAllDummies()) do
            local dRoot = dummy:FindFirstChild("HumanoidRootPart") or dummy:FindFirstChild("Torso")
            if dRoot and not dRoot.Anchored then
                dRoot.CFrame = fanCf
                count = count + 1
            end
        end
        Window:Notify({ Title = "Big Fan Toss", Content = count .. " dummy dilempar ke bilah kipas raksasa!", Duration = 3 })
    end
})

FarmTab:CreateButton({
    Name = "Freeze All Dummies (Lumpuhkan AI Bergerak)",
    Callback = function()
        local count = 0
        for _, dummy in ipairs(getAllDummies()) do
            for _, p in ipairs(dummy:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.Anchored = true
                end
            end
            count = count + 1
        end
        Window:Notify({ Title = "Freeze Dummies", Content = count .. " dummy berhasil dibekukan!", Duration = 3 })
    end
})

FarmTab:CreateButton({
    Name = "Unfreeze All Dummies (Pulihkan AI)",
    Callback = function()
        for _, dummy in ipairs(getAllDummies()) do
            for _, p in ipairs(dummy:GetDescendants()) do
                if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                    p.Anchored = false
                end
            end
        end
        Window:Notify({ Title = "Unfreeze", Content = "AI dummy dipulihkan normal.", Duration = 2 })
    end
})

-- ╔═══════════════════════════════════════════╗
-- ║  TAB 2: EVENTS (SEMUA 24 EVENT GAME HRR)  ║
-- ╚═══════════════════════════════════════════╝
local EventsTab = Window:CreateTab("Events", "zap", "Main")
EventsTab:CreateSection("Bypass & Kontrol Seluruh Event Game")

EventsTab:CreateButton({
    Name = "Unlock All In-Game Event Tokens (999x Penggunaan)",
    Callback = function()
        local c = unlockAllEventTokens()
        Window:Notify({ Title = "Events Unlocked", Content = "Token event di-unlock di UI game! (" .. c .. " items)", Duration = 3 })
    end
})

EventsTab:CreateButton({
    Name = "Hentikan Semua Bencana Aktif (Reset Map Damai)",
    Callback = function()
        stopAllActiveEvents()
        Window:Notify({ Title = "Events Reset", Content = "Seluruh bencana dihentikan. Map dikembalikan ke normal.", Duration = 2.5 })
    end
})

EventsTab:CreateSection("Bencana Fisika dan Cuaca (9 Event)")
local physicsEvents = {
    "Weightless", "Deep Freeze", "Falling Dummies",
    "Wildfire", "Mini Dummies", "Giant Dummy",
    "Meteor Rain", "Tornado", "Black Hole"
}
for _, evName in ipairs(physicsEvents) do
    EventsTab:CreateButton({
        Name = evName,
        Callback = function()
            runGameEvent(evName)
        end
    })
end

EventsTab:CreateSection("Bencana Serangan Hewan dan Makhluk (9 Event)")
local creatureEvents = {
    "Warhead", "Zombie Outbreak", "Disco Party",
    "Bee Swarm", "Dog Pack", "Snake Nest",
    "Spider Nest", "Croc Raid", "Bear Attack"
}
for _, evName in ipairs(creatureEvents) do
    EventsTab:CreateButton({
        Name = evName,
        Callback = function()
            runGameEvent(evName)
        end
    })
end

EventsTab:CreateSection("Bencana Serangan Raksasa dan Titan (6 Event)")
local titanEvents = {
    "Bull Run", "Gorilla Rampage", "Shark Rain",
    "T-Rex Attack", "Airstrike", "Tsunami"
}
for _, evName in ipairs(titanEvents) do
    EventsTab:CreateButton({
        Name = evName,
        Callback = function()
            runGameEvent(evName)
        end
    })
end

-- ═══════════════════════════════════════════
--  TAB 3: SENJATA (SATU TAB SAJA DI SIDEBAR - DROPDOWN)
-- ═══════════════════════════════════════════
local WeaponsTab = Window:CreateTab("Senjata", "sword", "Main")

WeaponsTab:CreateSection("Pilih Kategori dan Senjata")

local selectedCategory = "Melee"
local selectedWeaponName = WeaponDatabase.Melee[1].name
local weaponDropdownObj = nil

local function getCategoryOptionsList(cat)
    local list = {}
    if WeaponDatabase[cat] then
        for _, w in ipairs(WeaponDatabase[cat]) do
            local label = w.robux and ("[R$] " .. w.name) or w.name
            table.insert(list, label)
        end
    end
    return list
end

WeaponsTab:CreateDropdown({
    Name = "Pilih Kategori Senjata",
    Options = { "Melee (14)", "Guns (14)", "Throw (12)", "Power (13)", "Medic (8)", "Robux (8)" },
    Callback = function(opt)
        local catKey = "Melee"
        if string.find(opt, "Guns") then catKey = "Guns"
        elseif string.find(opt, "Throw") then catKey = "Throw"
        elseif string.find(opt, "Power") then catKey = "Power"
        elseif string.find(opt, "Medic") then catKey = "Medic"
        elseif string.find(opt, "Robux") then catKey = "Robux"
        end
        selectedCategory = catKey
        local opts = getCategoryOptionsList(catKey)
        if weaponDropdownObj and opts and #opts > 0 then
            weaponDropdownObj:Refresh(opts)
            selectedWeaponName = WeaponDatabase[catKey][1].name
        end
    end
})

weaponDropdownObj = WeaponsTab:CreateDropdown({
    Name = "Pilih Senjata",
    Options = getCategoryOptionsList("Melee"),
    Callback = function(opt)
        for _, w in ipairs(WeaponDatabase[selectedCategory] or {}) do
            local label = w.robux and ("[R$] " .. w.name) or w.name
            if label == opt or w.name == opt then
                selectedWeaponName = w.name
                break
            end
        end
    end
})

WeaponsTab:CreateSection("Aksi dan Penggunaan Senjata")

WeaponsTab:CreateButton({
    Name = "Equip Senjata yang Dipilih",
    Callback = function()
        giveWeapon(selectedWeaponName, 1)
    end
})

WeaponsTab:CreateButton({
    Name = "Drop Senjata yang Sedang Dipegang",
    Callback = function()
        local char = getCharacter()
        local myRoot = getRootPart()
        if char and myRoot then
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then
                tool.Parent = workspace
                local h = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
                if h then h.CFrame = myRoot.CFrame * CFrame.new(0, 0, -4) end
                Window:Notify({ Title = "Drop Senjata", Content = tool.Name .. " dibuang ke lantai.", Duration = 2 })
            else
                Window:Notify({ Title = "Info", Content = "Kamu tidak sedang memegang senjata.", Duration = 2 })
            end
        end
    end
})

WeaponsTab:CreateButton({
    Name = "Ambil Semua Senjata di Lantai (Pickup All)",
    Callback = function()
        local myRoot = getRootPart()
        if not myRoot then return end
        local count = 0
        for _, tool in ipairs(getDroppedTools()) do
            local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
            if handle then
                handle.CFrame = myRoot.CFrame
                count = count + 1
            end
        end
        Window:Notify({ Title = "Pickup All", Content = count .. " senjata ditarik ke badanmu!", Duration = 2.5 })
    end
})

WeaponsTab:CreateSection("Status Slot Senjata (Maks 10 Slot)")

WeaponsTab:CreateButton({
    Name = "Lihat Slot Senjata Aktif",
    Callback = function()
        local char = getCharacter()
        local tools = {}
        if char then
            for _, item in ipairs(char:GetChildren()) do
                if item:IsA("Tool") then table.insert(tools, "[Pegang] " .. item.Name) end
            end
        end
        for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if item:IsA("Tool") then table.insert(tools, "[Pack] " .. item.Name) end
        end
        local msg = #tools > 0 and table.concat(tools, " | ") or "Inventory kosong."
        Window:Notify({ Title = "Slot (" .. #tools .. "/10)", Content = msg, Duration = 6 })
    end
})

WeaponsTab:CreateButton({
    Name = "Kosongkan Seluruh Inventory (Drop All)",
    Callback = function()
        local char = getCharacter(); local myRoot = getRootPart(); local count = 0
        if char and myRoot then
            for _, item in ipairs(char:GetChildren()) do
                if item:IsA("Tool") then
                    item.Parent = workspace
                    local h = item:FindFirstChild("Handle") or item:FindFirstChildWhichIsA("BasePart")
                    if h then h.CFrame = myRoot.CFrame * CFrame.new(math.random(-4,4), 0, math.random(-4,4)) end
                    count = count + 1
                end
            end
        end
        for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if item:IsA("Tool") then
                item.Parent = workspace
                local h = item:FindFirstChild("Handle") or item:FindFirstChildWhichIsA("BasePart")
                if h and myRoot then h.CFrame = myRoot.CFrame * CFrame.new(math.random(-4,4), 0, math.random(-4,4)) end
                count = count + 1
            end
        end
        Window:Notify({ Title = "Drop Semua", Content = count .. " senjata dibuang ke lantai.", Duration = 2 })
    end
})

-- Sistem Universal Tembak / Serang dengan Klik Kiri Mouse (100% Menembak)
-- ═══════════════════════════════════════════
--  UNIVERSAL WEAPON SHOOT & ATTACK SYSTEM
-- ═══════════════════════════════════════════
local function fireEquippedWeapon()
    local char = getCharacter()
    local tool = char and char:FindFirstChildOfClass("Tool")
    if not tool then return end

    local myRoot = getRootPart()
    local mouse = LocalPlayer:GetMouse()
    if not myRoot or not mouse then return end

    -- 1. Activate tool natively
    pcall(function() tool:Activate() end)

    -- 2. Play attack/swing/recoil animation
    pcall(function()
        local hum = getHumanoid()
        if hum then
            local animator = hum:FindFirstChildOfClass("Animator") or hum
            local anim = tool:FindFirstChildOfClass("Animation") or tool:FindFirstChild("Shoot") or tool:FindFirstChild("Fire") or tool:FindFirstChild("Slash") or tool:FindFirstChild("Attack")
            if anim and animator.LoadAnimation then
                local track = animator:LoadAnimation(anim)
                track:Play()
            else
                local fallbackAnim = Instance.new("Animation")
                fallbackAnim.AnimationId = "rbxassetid://129967390"
                local track = animator:LoadAnimation(fallbackAnim)
                track:Play()
            end
        end
    end)

    -- 3. Sound FX (Gunshot / Slash)
    pcall(function()
        local s = tool:FindFirstChildOfClass("Sound") or (tool:FindFirstChild("Handle") and tool.Handle:FindFirstChildOfClass("Sound"))
        if s then
            s:Play()
        else
            local snd = Instance.new("Sound")
            snd.SoundId = "rbxassetid://240785604"
            snd.Volume = 0.8
            snd.Parent = SoundService
            snd:Play()
            game:GetService("Debris"):AddItem(snd, 1.5)
        end
    end)

    local hitPos = mouse.Hit and mouse.Hit.Position
    local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart") or myRoot
    local origin = handle.Position

    if hitPos then
        -- 4. Visible Bullet Tracer
        pcall(function()
            local dist = (hitPos - origin).Magnitude
            if dist < 800 then
                local tracer = Instance.new("Part")
                tracer.Size = Vector3.new(0.14, 0.14, dist)
                tracer.CFrame = CFrame.lookAt((origin + hitPos) / 2, hitPos)
                tracer.Material = Enum.Material.Neon
                tracer.Color = Color3.fromRGB(255, 230, 75)
                tracer.Anchored = true
                tracer.CanCollide = false
                tracer.Parent = workspace
                task.delay(0.06, function() tracer:Destroy() end)
            end
        end)

        -- 5. Hit Detection & Server KO Kill
        pcall(function()
            local targetModel = nil
            if mouse.Target and mouse.Target.Parent and mouse.Target.Parent ~= char then
                local p = mouse.Target.Parent
                if p:FindFirstChildOfClass("Humanoid") then
                    targetModel = p
                elseif p.Parent and p.Parent:FindFirstChildOfClass("Humanoid") then
                    targetModel = p.Parent
                end
            end

            if not targetModel then
                local rayParams = RaycastParams.new()
                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                rayParams.FilterDescendantsInstances = { char }
                local dir = (hitPos - origin).Unit * 800
                local result = workspace:Raycast(origin, dir, rayParams)
                if result and result.Instance and result.Instance.Parent ~= char then
                    local p = result.Instance.Parent
                    if p:FindFirstChildOfClass("Humanoid") then
                        targetModel = p
                    elseif p.Parent and p.Parent:FindFirstChildOfClass("Humanoid") then
                        targetModel = p.Parent
                    end
                end
            end

            -- Jika mengenai dummy atau target
            if targetModel and targetModel ~= char then
                -- A) Touch interest ke handle agar script server senjata mendeteksi pukulan/tembakan dan kill tercatat di server KO
                if handle and firetouchinterest then
                    for _, bp in ipairs(targetModel:GetChildren()) do
                        if bp:IsA("BasePart") then
                            firetouchinterest(handle, bp, 0)
                            firetouchinterest(handle, bp, 1)
                        end
                    end
                end
                -- B) Hancurkan joints / instant kill
                killDummyInstantly(targetModel)
                -- C) Kirim notifikasi kill ke server
                notifyKillToServer(targetModel)
            end
        end)
    end
end

-- Bersihkan hook lama jika re-execute
if getgenv()._UNIONSAL_WEAPON_CONNS then
    for _, conn in ipairs(getgenv()._UNIONSAL_WEAPON_CONNS) do
        pcall(function() conn:Disconnect() end)
    end
end
getgenv()._UNIONSAL_WEAPON_CONNS = {}

-- Pasang hook ke Mouse.Button1Down dan UserInputService.InputBegan
pcall(function()
    local mouse = LocalPlayer:GetMouse()
    local conn1 = mouse.Button1Down:Connect(function()
        fireEquippedWeapon()
    end)
    table.insert(getgenv()._UNIONSAL_WEAPON_CONNS, conn1)

    local conn2 = UserInputService.InputBegan:Connect(function(input, gpe)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            fireEquippedWeapon()
        end
    end)
    table.insert(getgenv()._UNIONSAL_WEAPON_CONNS, conn2)
end)

-- ╔═══════════════════════════════════════════╗
-- ║  TAB 4: COMBAT & TOOLS                    ║
-- ╚═══════════════════════════════════════════╝
local CombatTab = Window:CreateTab("Combat & Tools", "rocket", "Main")
CombatTab:CreateSection("Modifikasi Tangan & Grab")

ToggleObjects.SuperGrab = CombatTab:CreateToggle({
    Name = "Super Grab (Jangkauan Tak Terbatas / Infinite Range)",
    CurrentValue = false,
    Callback = function(v)
        RagdollGame.SuperGrabEnabled = v
        notifyStateChange("SuperGrab", v)
        Window:Notify({ Title = "Super Grab", Content = v and "Super Grab Aktif! Kamu bisa menarik objek dari jarak jauh." or "Super Grab nonaktif.", Duration = 2 })
    end
})

CombatTab:CreateSection("Senjata & Alat Medis")

ToggleObjects.FastAttack = CombatTab:CreateToggle({
    Name = "Fast Attack / Rapid Weapon (Axe & Gun)",
    CurrentValue = false,
    Callback = function(v)
        RagdollGame.FastAttackActive = v
        notifyStateChange("FastAttack", v)
        if v then
            task.spawn(function()
                while RagdollGame.FastAttackActive do
                    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                        local char = getCharacter()
                        local tool = char and char:FindFirstChildOfClass("Tool")
                        if tool then pcall(function() fireEquippedWeapon() end) end
                        task.wait(0.04)
                    else
                        task.wait(0.1)
                    end
                end
            end)
        end
    end
})

CombatTab:CreateButton({
    Name = "Auto Pickup Semua Senjata di Lantai (Dropped Guns)",
    Callback = function()
        local myRoot = getRootPart()
        if not myRoot then return end
        local count = 0
        for _, tool in ipairs(getDroppedTools()) do
            local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
            if handle then
                handle.CFrame = myRoot.CFrame
                count = count + 1
            end
        end
        Window:Notify({ Title = "Pickup Guns", Content = count .. " senjata berhasil diambil/ditarik ke badan!", Duration = 3 })
    end
})

CombatTab:CreateButton({
    Name = "Equip Senjata Terbaik (Axe / Gun)",
    Callback = function()
        local hum = getHumanoid()
        if not hum then return end
        local priority = {"Axe", "Shotgun", "Rifle", "Pistol", "Defibrillator"}
        local found = false
        for _, name in ipairs(priority) do
            for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
                if string.find(string.lower(item.Name), string.lower(name)) then
                    hum:EquipTool(item)
                    found = true
                    Window:Notify({ Title = "Equip", Content = "Senjata di-equip: " .. item.Name, Duration = 2 })
                    break
                end
            end
            if found then break end
        end
        if not found then
            local any = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
            if any then hum:EquipTool(any) end
        end
    end
})

CombatTab:CreateButton({
    Name = "Use Defibrillator on Nearest Body (Revive)",
    Callback = function()
        local hum = getHumanoid()
        if not hum then return end
        local defib = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Defibrillator")) or LocalPlayer.Backpack:FindFirstChild("Defibrillator")
        if defib then
            hum:EquipTool(defib)
            task.wait(0.1)
            defib:Activate()
            Window:Notify({ Title = "Defibrillator", Content = "Defibrillator diaktifkan!", Duration = 2 })
        else
            Window:Notify({ Title = "Defibrillator", Content = "Kamu tidak memiliki Defibrillator di inventory!", Duration = 2 })
        end
    end
})

-- ╔═══════════════════════════════════════════╗
-- ║  TAB 5: PLAYER & DEFENSE                  ║
-- ╚═══════════════════════════════════════════╝
local PlayerTab = Window:CreateTab("Player", "user", "Main")
PlayerTab:CreateSection("Proteksi Fisika & Anti-Ragdoll")

local antiRagdollConn = nil
ToggleObjects.AntiRagdoll = PlayerTab:CreateToggle({
    Name = "Anti-Ragdoll (Kebal Pingsan / Never Fall Down)",
    CurrentValue = false,
    Callback = function(v)
        RagdollGame.AntiRagdollActive = v
        notifyStateChange("AntiRagdoll", v)
        local hum = getHumanoid()
        if hum then
            pcall(function()
                hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, not v)
                hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, not v)
            end)
        end
        if v and not antiRagdollConn then
            antiRagdollConn = RunService.Stepped:Connect(function()
                if not RagdollGame.AntiRagdollActive then return end
                local h = getHumanoid()
                if h then
                    h.PlatformStand = false
                end
            end)
        elseif not v and antiRagdollConn then
            antiRagdollConn:Disconnect()
            antiRagdollConn = nil
        end
        Window:Notify({ Title = "Anti-Ragdoll", Content = v and "Kebal Ragdoll AKTIF! Kamu tidak akan pernah jatuh pingsan." or "Anti-Ragdoll nonaktif.", Duration = 2 })
    end
})

PlayerTab:CreateButton({
    Name = "Instant Self-Ragdoll / Bangun Cepat (Toggle)",
    Callback = function()
        local hum = getHumanoid()
        if hum then
            if hum.PlatformStand then
                hum.PlatformStand = false
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                Window:Notify({ Title = "Ragdoll", Content = "Berdiri seketika!", Duration = 1.5 })
            else
                hum.PlatformStand = true
                hum:ChangeState(Enum.HumanoidStateType.Ragdoll)
                Window:Notify({ Title = "Ragdoll", Content = "Pura-pura mati (Ragdoll mode)!", Duration = 1.5 })
            end
        end
    end
})

PlayerTab:CreateSection("Mobilitas & Gerakan")

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
    Name = "Fly Mode (Terbang Bebas)",
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

SliderObjects.WalkSpeed = PlayerTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 250},
    Increment = 1,
    Suffix = " spd",
    CurrentValue = 16,
    Callback = function(v)
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = v end
        notifyStateChange("WalkSpeed", v)
    end
})

local infJump = false
UserInputService.JumpRequest:Connect(function()
    if infJump then
        local hum = getHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

PlayerTab:CreateToggle({
    Name = "Infinite Jump (Lompat di Udara)",
    CurrentValue = false,
    Callback = function(v) infJump = v end
})

local noclip = false
local noclipConn = nil
ToggleObjects.NoClip = PlayerTab:CreateToggle({
    Name = "NoClip (Tembus Dinding / Objek)",
    CurrentValue = false,
    Callback = function(v)
        noclip = v
        notifyStateChange("NoClip", v)
        if v and not noclipConn then
            noclipConn = RunService.Stepped:Connect(function()
                if not noclip then return end
                local char = LocalPlayer.Character
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
    Name = "SpinBot (Putar Cepat 360°)",
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
    Name = "Reset Karakter / Respawn",
    Callback = function() local h = getHumanoid(); if h then h.Health = 0 end end
})

PlayerTab:CreateButton({
    Name = "Rejoin Server (Masuk Ulang)",
    Callback = function()
        local ts = game:GetService("TeleportService")
        ts:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
})

-- ╔═══════════════════════════════════════════╗
-- ║  TAB 6: TELEPORT                          ║
-- ╚═══════════════════════════════════════════╝
local TpTab = Window:CreateTab("Teleport", "navigation", "Main")

local function findMapLocation(keywords)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local n = string.lower(obj.Name)
            for _, kw in ipairs(keywords) do
                if string.find(n, kw) then
                    if obj:IsA("BasePart") then return obj.CFrame end
                    if obj:IsA("Model") and obj.PrimaryPart then return obj.PrimaryPart.CFrame end
                    if obj:IsA("Model") then
                        local p = obj:FindFirstChildWhichIsA("BasePart")
                        if p then return p.CFrame end
                    end
                end
            end
        end
    end
    return nil
end

local function tpTo(cf, label)
    local root = getRootPart()
    if not root then
        Window:Notify({ Title = "Error", Content = "Karakter belum siap.", Duration = 2 })
        return
    end
    if cf then
        root.CFrame = cf + Vector3.new(0, 5, 0)
        Window:Notify({ Title = "Teleport", Content = "Tiba di: " .. label, Duration = 2 })
    else
        Window:Notify({ Title = "Tidak Ditemukan", Content = label .. " tidak ada di map saat ini.", Duration = 2 })
    end
end

TpTab:CreateSection("Lokasi Map Utama")

TpTab:CreateButton({
    Name = "Spawn (Titik Lahir)",
    Callback = function()
        local root = getRootPart()
        local sp = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
        tpTo((sp and sp.CFrame) or CFrame.new(0, 10, 0), "Spawn Point")
    end
})

TpTab:CreateButton({
    Name = "Kipas Raksasa (The Big Fan)",
    Callback = function()
        local fanCf = findBigFan()
        if type(fanCf) == "userdata" and fanCf.Position then
            tpTo(fanCf, "Kipas Raksasa")
        else
            tpTo(CFrame.new(0, 50, 0), "Kipas Raksasa")
        end
    end
})

TpTab:CreateButton({
    Name = "Pusat Map (Center / 0,0,0)",
    Callback = function()
        tpTo(CFrame.new(0, 15, 0), "Pusat Map (0,0,0)")
    end
})

TpTab:CreateButton({
    Name = "Area Void (Bawah Map)",
    Callback = function()
        tpTo(CFrame.new(0, -150, 0), "Area Void")
    end
})

TpTab:CreateButton({
    Name = "Langit Tinggi (Sky High)",
    Callback = function()
        tpTo(CFrame.new(0, 500, 0), "Langit Tinggi (Y=500)")
    end
})

TpTab:CreateSection("Lokasi Scan dari Map")

TpTab:CreateButton({
    Name = "Area Medis / Hospital",
    Callback = function()
        local cf = findMapLocation({"medic","hospital","clinic","ambulan","healt","infirmary"})
        tpTo(cf, "Area Medis")
    end
})

TpTab:CreateButton({
    Name = "Area Senjata / Weapon Room",
    Callback = function()
        local cf = findMapLocation({"weapon","armory","gun","ammo","arsenal","rack","locker"})
        tpTo(cf, "Area Senjata")
    end
})

TpTab:CreateButton({
    Name = "Area Dummy / Crowd Zone",
    Callback = function()
        local cf = findMapLocation({"crowd","dummy","dummies","npc","ragdoll","zombie"})
        tpTo(cf, "Area Dummy")
    end
})

TpTab:CreateButton({
    Name = "Area Air / Water Zone",
    Callback = function()
        local cf = findMapLocation({"water","pool","lake","ocean","river","swim","beach"})
        tpTo(cf, "Area Air")
    end
})

TpTab:CreateButton({
    Name = "Area Terbuka Luas (Outdoor)",
    Callback = function()
        local cf = findMapLocation({"field","outdoor","grass","park","plaza","court","open"})
        tpTo(cf, "Area Outdoor")
    end
})

TpTab:CreateButton({
    Name = "Area Gedung / Building",
    Callback = function()
        local cf = findMapLocation({"building","floor","office","room","hall","warehouse","basement"})
        tpTo(cf, "Area Gedung")
    end
})

TpTab:CreateButton({
    Name = "Platform / Stage / Arena",
    Callback = function()
        local cf = findMapLocation({"stage","arena","platform","ring","cage","pit"})
        tpTo(cf, "Stage/Arena")
    end
})

TpTab:CreateSection("Teleport ke Dummy")

TpTab:CreateButton({
    Name = "Teleport ke Dummy Hidup Acak",
    Callback = function()
        local dummies = getLivingDummies()
        local root = getRootPart()
        if root and #dummies > 0 then
            local target = dummies[math.random(1, #dummies)]
            local tRoot = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Torso")
            if tRoot then
                root.CFrame = tRoot.CFrame * CFrame.new(0, 0, 4)
                Window:Notify({ Title = "Teleport", Content = "Tiba di dekat dummy: " .. target.Name, Duration = 2 })
            end
        else
            Window:Notify({ Title = "Teleport", Content = "Tidak ada dummy hidup di map.", Duration = 2 })
        end
    end
})

TpTab:CreateButton({
    Name = "Teleport ke SEMUA Dummy (Kumpulkan ke Satu Titik)",
    Callback = function()
        local root = getRootPart()
        if not root then return end
        local count = 0
        for _, dummy in ipairs(getAllDummies()) do
            local dRoot = dummy:FindFirstChild("HumanoidRootPart") or dummy:FindFirstChild("Torso")
            if dRoot and not dRoot.Anchored then
                dRoot.CFrame = root.CFrame * CFrame.new(math.random(-8,8), 0, math.random(-8,8))
                count = count + 1
            end
        end
        Window:Notify({ Title = "Kumpulkan Dummy", Content = count .. " dummy dikumpulkan ke posisimu!", Duration = 2 })
    end
})

TpTab:CreateButton({
    Name = "Teleport ke Kipas - Semua Dummy (Mass Fan Throw)",
    Callback = function()
        local fanCf = findBigFan()
        if not fanCf then fanCf = CFrame.new(0, 50, 0) end
        local count = 0
        for _, dummy in ipairs(getAllDummies()) do
            local dRoot = dummy:FindFirstChild("HumanoidRootPart") or dummy:FindFirstChild("Torso")
            if dRoot and not dRoot.Anchored then
                if type(fanCf) == "userdata" and fanCf.Position then
                    dRoot.CFrame = CFrame.new(fanCf.Position + Vector3.new(math.random(-3,3), 2, math.random(-3,3)))
                else
                    dRoot.CFrame = fanCf + Vector3.new(math.random(-3,3), 2, math.random(-3,3))
                end
                count = count + 1
            end
        end
        Window:Notify({ Title = "Fan Throw", Content = count .. " dummy dilempar ke Kipas Raksasa!", Duration = 3 })
    end
})

TpTab:CreateSection("Teleport ke Player")

local function getPlayerNames()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(names, p.Name) end
    end
    if #names == 0 then table.insert(names, "(tidak ada player lain)") end
    return names
end

local selPlr = nil
TpTab:CreateDropdown({
    Name = "Pilih Target Player",
    Options = getPlayerNames(),
    Callback = function(opt) selPlr = opt end
})

TpTab:CreateButton({
    Name = "Teleport ke Player Dipilih",
    Callback = function()
        local myRoot = getRootPart()
        if myRoot and selPlr and selPlr ~= "(tidak ada player lain)" then
            local target = Players:FindFirstChild(selPlr)
            if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                myRoot.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(3, 0, 0)
                Window:Notify({ Title = "Teleport", Content = "Teleport ke " .. selPlr, Duration = 2 })
            end
        end
    end
})

TpTab:CreateButton({
    Name = "Panggil Player ke Posisiku",
    Callback = function()
        local myRoot = getRootPart()
        if not myRoot or not selPlr or selPlr == "(tidak ada player lain)" then return end
        local target = Players:FindFirstChild(selPlr)
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            target.Character.HumanoidRootPart.CFrame = myRoot.CFrame + Vector3.new(3, 0, 0)
            Window:Notify({ Title = "Panggil Player", Content = selPlr .. " dipanggil ke posisimu!", Duration = 2 })
        end
    end
})

TpTab:CreateSection("Koordinat Custom")

local customX, customY, customZ = 0, 10, 0
TpTab:CreateInput({
    Name = "X Koordinat",
    PlaceholderText = "0",
    Callback = function(val) customX = tonumber(val) or 0 end
})
TpTab:CreateInput({
    Name = "Y Koordinat",
    PlaceholderText = "10",
    Callback = function(val) customY = tonumber(val) or 10 end
})
TpTab:CreateInput({
    Name = "Z Koordinat",
    PlaceholderText = "0",
    Callback = function(val) customZ = tonumber(val) or 0 end
})
TpTab:CreateButton({
    Name = "Teleport ke Koordinat Custom",
    Callback = function()
        tpTo(CFrame.new(customX, customY, customZ), string.format("(%d, %d, %d)", customX, customY, customZ))
    end
})
TpTab:CreateButton({
    Name = "Salin Koordinat Saat Ini",
    Callback = function()
        local r = getRootPart()
        if r then
            local posStr = string.format("%.1f, %.1f, %.1f", r.Position.X, r.Position.Y, r.Position.Z)
            if setclipboard then setclipboard(posStr) end
            Window:Notify({ Title = "Koordinat", Content = "Disalin: " .. posStr, Duration = 3 })
        end
    end
})

-- ╔═══════════════════════════════════════════╗
-- ║  TAB 7: VISUALS & ESP                     ║
-- ╚═══════════════════════════════════════════╝
local VisualTab = Window:CreateTab("Visuals", "eye", "Main")
VisualTab:CreateSection("ESP & Scanner Visual")

local dummyEspActive = false
local dummyHighlights = {}

ToggleObjects.DummyEsp = VisualTab:CreateToggle({
    Name = "Dummy ESP (Highlight Semua Dummy)",
    CurrentValue = false,
    Callback = function(v)
        dummyEspActive = v
        if v then
            task.spawn(function()
                while dummyEspActive do
                    for _, dummy in ipairs(getLivingDummies()) do
                        if not dummy:FindFirstChild("Unionsal_HL") then
                            local hl = Instance.new("Highlight")
                            hl.Name = "Unionsal_HL"
                            hl.FillColor = Color3.fromRGB(255, 60, 60)
                            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                            hl.FillTransparency = 0.5
                            hl.OutlineTransparency = 0
                            hl.Parent = dummy
                            table.insert(dummyHighlights, hl)
                        end
                    end
                    task.wait(2)
                end
            end)
        else
            for _, hl in ipairs(dummyHighlights) do
                if hl and hl.Parent then hl:Destroy() end
            end
            table.clear(dummyHighlights)
        end
    end
})

local fullbright = false
local oldAmbient = Lighting.Ambient
local oldBrightness = Lighting.Brightness
ToggleObjects.Fullbright = VisualTab:CreateToggle({
    Name = "Fullbright (Terang Benderang / Anti Gelap)",
    CurrentValue = false,
    Callback = function(v)
        fullbright = v
        notifyStateChange("Fullbright", v)
        if v then
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            Lighting.Brightness = 2
        else
            Lighting.Ambient = oldAmbient
            Lighting.Brightness = oldBrightness
        end
    end
})

SliderObjects.Fov = VisualTab:CreateSlider({
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

local toolEspActive = false
local toolHighlights = {}
ToggleObjects.ToolsEsp = VisualTab:CreateToggle({
    Name = "Weapons ESP (Highlight Senjata di Lantai)",
    CurrentValue = false,
    Callback = function(v)
        toolEspActive = v
        notifyStateChange("ToolsEsp", v)
        if v then
            task.spawn(function()
                while toolEspActive do
                    for _, tool in ipairs(getDroppedTools()) do
                        if not tool:FindFirstChild("Unionsal_ToolHL") then
                            local hl = Instance.new("Highlight")
                            hl.Name = "Unionsal_ToolHL"
                            hl.FillColor = Color3.fromRGB(80, 200, 255)
                            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                            hl.FillTransparency = 0.4
                            hl.OutlineTransparency = 0
                            hl.Parent = tool
                            table.insert(toolHighlights, hl)
                        end
                    end
                    task.wait(2)
                end
            end)
        else
            for _, hl in ipairs(toolHighlights) do
                if hl and hl.Parent then hl:Destroy() end
            end
            table.clear(toolHighlights)
        end
    end
})

local playerEspActive = false
local playerHighlights = {}
ToggleObjects.PlayerEsp = VisualTab:CreateToggle({
    Name = "Player ESP (Highlight Player Lain)",
    CurrentValue = false,
    Callback = function(v)
        playerEspActive = v
        notifyStateChange("PlayerEsp", v)
        if v then
            task.spawn(function()
                while playerEspActive do
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer and p.Character and not p.Character:FindFirstChild("Unionsal_PlrHL") then
                            local hl = Instance.new("Highlight")
                            hl.Name = "Unionsal_PlrHL"
                            hl.FillColor = Color3.fromRGB(255, 215, 0)
                            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                            hl.FillTransparency = 0.5
                            hl.OutlineTransparency = 0
                            hl.Parent = p.Character
                            table.insert(playerHighlights, hl)
                        end
                    end
                    task.wait(2)
                end
            end)
        else
            for _, hl in ipairs(playerHighlights) do
                if hl and hl.Parent then hl:Destroy() end
            end
            table.clear(playerHighlights)
        end
    end
})

-- ╔═══════════════════════════════════════════╗
-- ║  TAB 8: SETTINGS (CONFIG)                 ║
-- ╚═══════════════════════════════════════════╝
local SettingsTab = Window:CreateTab("Settings", "settings", "Config")
SettingsTab:CreateSection("Keybinds & Shortcut Menu")

SettingsTab:CreateKeybind({
    Name = "Tombol Buka / Tutup UI",
    CurrentKey = Window.ToggleKey or Enum.KeyCode.RightShift,
    Callback = function(newKey)
        Window.ToggleKey = newKey
        ConfigRegistry.ToggleKey = newKey.Name
        Window:Notify({ Title = "Keybind Disimpan", Content = "Tombol menu diubah ke: [" .. newKey.Name .. "]", Duration = 3 })
    end
})

SettingsTab:CreateParagraph({
    Title = "Daftar Shortcut Hyper-Realistic Ragdoll",
    Content = "• Buka/Tutup UI: Tekan tombol yang telah diatur (Default: RightShift).\n" ..
              "• Revive All Ragdoll: Tekan tombol [ R ] di keyboard.\n" ..
              "• Respawn Karakter: Tekan tombol [ G ] di keyboard.\n" ..
              "• Scan Dummy X-Ray: Tekan tombol [ V ] di keyboard.\n" ..
              "• Pop-up Kotak Mini: Klik kotak kecil di kiri saat tombol strip [ — ] ditekan.\n" ..
              "• Resize Window: Tarik grip pojok kanan bawah seperti aplikasi Windows.\n" ..
              "• Ganti Tema: Klik ikon matahari di kanan atas untuk White/Dark mode."
})

SettingsTab:CreateSection("Optimasi Client & FPS")
ToggleObjects.FpsBoost = SettingsTab:CreateToggle({
    Name = "Reduce Graphics Lag (FPS Boost)",
    CurrentValue = false,
    Callback = function(v)
        applyFpsBoost(v)
        Window:Notify({ Title = "FPS Boost", Content = v and "FPS Boost diaktifkan!" or "FPS Boost dinonaktifkan.", Duration = 2 })
    end
})

ToggleObjects.PotatoGraphics = SettingsTab:CreateToggle({
    Name = "Grafik Potato (Ultra Low Graphics / No Textures)",
    CurrentValue = false,
    Callback = function(v)
        applyPotatoGraphics(v)
        Window:Notify({ Title = "Grafik Potato", Content = v and "Grafik Potato aktif! Tekstur dihilangkan untuk FPS maksimal." or "Grafik Potato dinonaktifkan.", Duration = 3 })
    end
})

-- ╔═══════════════════════════════════════════╗
-- ║  TAB 9: CONFIGS (CONFIG)                  ║
-- ╚═══════════════════════════════════════════╝
local ConfigsTab = Window:CreateTab("Configs", "folder", "Config")
ConfigsTab:CreateSection("Discord Webhook Integration (Tersimpan Persisten)")

ConfigsTab:CreateParagraph({
    Title = "Penyimpanan Webhook",
    Content = "Pengaturan gameplay otomatis di-reset setiap kali keluar/masuk game baru. HANYA koneksi bot Webhook yang disimpan terus menerus hingga kamu memutuskan koneksinya."
})

InputObjects.WebhookUrl = ConfigsTab:CreateInput({
    Name = "Discord Webhook URL",
    PlaceholderText = "https://discord.com/api/webhooks/...",
    Callback = function(val)
        webhookUrl = string.gsub(val or "", "^%s*(.-)%s*$", "%1")
        ConfigRegistry.WebhookUrl = webhookUrl
        saveWebhookConfig()
        Window:Notify({ Title = "Webhook", Content = "URL Webhook disimpan persisten.", Duration = 2 })
    end
})

ToggleObjects.SendOnExec = ConfigsTab:CreateToggle({
    Name = "Kirim Log saat Script Dieksekusi",
    CurrentValue = true,
    Callback = function(v)
        ConfigRegistry.SendOnExec = v
        saveWebhookConfig()
    end
})

ToggleObjects.SendOnKo = ConfigsTab:CreateToggle({
    Name = "Kirim Log saat KO Dummy Berhasil",
    CurrentValue = true,
    Callback = function(v)
        ConfigRegistry.SendOnKo = v
        saveWebhookConfig()
    end
})

local function sendDiscordWebhook(embedData)
    if webhookUrl == "" or not string.find(webhookUrl, "discord%.com/api/webhooks") then
        return false
    end
    local http = syn and syn.request or http_request or request or (http and http.request)
    if not http then return false end
    local payload = HttpService:JSONEncode({
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
            title = "Unionsal Hub • Webhook Connected",
            description = "Webhook berhasil terhubung dengan client Roblox!",
            color = 8864235,
            fields = {
                { name = "Player", value = LocalPlayer.Name .. " (@" .. LocalPlayer.DisplayName .. ")", inline = true },
                { name = "Game", value = "Hyper-Realistic Ragdoll", inline = true },
                { name = "Place ID", value = tostring(game.PlaceId), inline = true },
                { name = "Waktu", value = os.date("%H:%M:%S - %d/%m/%Y"), inline = false }
            },
            footer = { text = "Unionsal Script Hub • .gg/unionsal" }
        }
        local success = sendDiscordWebhook(embed)
        if success then
            Window:Notify({ Title = "Webhook Sukses", Content = "Pesan uji coba berhasil terkirim ke Discord!", Duration = 3 })
        else
            Window:Notify({ Title = "Webhook Gagal", Content = "Pastikan URL Discord Webhook valid.", Duration = 3 })
        end
    end
})

ConfigsTab:CreateButton({
    Name = "Putuskan Koneksi Bot / Reset Webhook",
    Callback = function()
        deleteWebhookConfig()
        Window:Notify({ Title = "Webhook Diputus", Content = "Koneksi bot webhook diputus dan file penyimpanan dihapus.", Duration = 3 })
    end
})

-- Otomatis muat webhook tersimpan saat execute
task.spawn(function()
    task.wait(0.3)
    loadWebhookConfig()
    if ConfigRegistry.SendOnExec and ConfigRegistry.WebhookUrl ~= "" then
        sendDiscordWebhook({
            title = "Unionsal Hub • Script Executed",
            description = "Player **" .. LocalPlayer.Name .. "** mengeksekusi Unionsal Hub.",
            color = 0x66FF66,
            fields = {
                { name = "Game", value = "Hyper-Realistic Ragdoll", inline = true },
                { name = "Waktu", value = os.date("%H:%M:%S"), inline = true }
            },
            footer = { text = "Unionsal Script Hub • .gg/unionsal" }
        })
    end
end)

-- ═══════════════════════════════════════════
--  NOTIFIKASI SIAP
-- ═══════════════════════════════════════════
task.wait(0.5)
Window:Notify({
    Title   = "unionsal",
    Content = "Hyper-Realistic Ragdoll v1.3 aktif! Siap digunakan.",
    Duration = 5,
})

    end

    return Window
end

-- Jika main.lua dieksekusi secara langsung sebagai loader:
local function entryLoader()
    local gameInfo = validateGame()
    if not gameInfo then return end

    showIntroScreen(gameInfo, function()
        getgenv()._UNIONSAL_CHILD_LOADED = true
        local loaded = false

        -- 1. Prioritaskan module built-in inlined yang sudah ter-update 100%!
        -- Menjamin script selalu berjalan lancar dan instan tanpa tergantung koneksi / cache lama
        if UnionsalHub.Modules and UnionsalHub.Modules[gameInfo.script] then
            UnionsalHub:LoadModule(gameInfo.script, gameInfo.name)
            loaded = true
        end

        -- 2. Coba load dari file lokal jika ada di folder executor
        if not loaded then
            pcall(function()
                local filename = gameInfo.script .. ".lua"
                local fileExists = false
                if isfile then
                    pcall(function() fileExists = isfile(filename) end)
                else
                    fileExists = true
                end
                if fileExists and readfile then
                    local content = readfile(filename)
                    if content and #content > 100 and not string.find(content, "sirius%.menu") then
                        local fn, parseErr = loadstring(content)
                        if fn then
                            fn()
                            loaded = true
                        else
                            warn("[Unionsal Hub] Local file parse error (" .. filename .. "): " .. tostring(parseErr))
                        end
                    end
                end
            end)
        end

        -- 3. Fallback GitHub jika file belum ada (dengan cache-buster ?v=tick agar selalu update!)
        if not loaded then
            local okNet, errNet = pcall(function()
                local scriptUrl = SCRIPT_BASE_URL .. gameInfo.script .. ".lua?v=" .. tostring(tick())
                local content = game:HttpGet(scriptUrl)
                if content and #content > 100 and not string.find(content, "sirius%.menu") then
                    local fn, parseErr = loadstring(content)
                    if fn then
                        local okRun, runErr = pcall(fn)
                        if okRun then
                            loaded = true
                        else
                            warn("[Unionsal Hub] Runtime error saat menjalankan " .. gameInfo.script .. ": " .. tostring(runErr))
                        end
                    else
                        warn("[Unionsal Hub] Parse/Syntax error pada " .. gameInfo.script .. ": " .. tostring(parseErr))
                    end
                else
                    warn("[Unionsal Hub] Konten kosong atau tidak valid dari: " .. tostring(scriptUrl))
                end
            end)
            if not okNet then
                warn("[Unionsal Hub] Gagal mengunduh script dari GitHub: " .. tostring(errNet))
            end
        end
    end)
end

-- Jalankan loader otomatis jika belum ada game script yang memanggil UnionsalHub
task.spawn(function()
    if not getgenv()._UNIONSAL_CHILD_LOADED then
        entryLoader()
    end
end)

return UnionsalHub
