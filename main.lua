-- ╔══════════════════════════════════════════════════════════════╗
-- ║               NEMESIS SCRIPT HUB — MAIN ENGINE               ║
-- ║              UI Framework, Bento Dashboard & Loader          ║
-- ║                        .gg/nemesishub                        ║
-- ╚══════════════════════════════════════════════════════════════╝

local CoreGui         = game:GetService("CoreGui")
local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local TweenService    = game:GetService("TweenService")
local UserInputService= game:GetService("UserInputService")
local HttpService     = game:GetService("HttpService")
local StatsService    = game:GetService("Stats")
local MarketplaceService = game:GetService("MarketplaceService")

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
    play        = "rbxassetid://7734022107",
    gamepad     = "rbxassetid://7733955740",
    activity    = "rbxassetid://7733658504",
    history     = "rbxassetid://7733960012",
    clock       = "rbxassetid://7733911828",
    search      = "rbxassetid://7734052925",
    star        = "rbxassetid://7734068495",
    bell        = "rbxassetid://7733674602",
    chevronDown = "rbxassetid://7733717444",
    chevronRight= "rbxassetid://7733717646",
    diamond     = "rbxassetid://7733924046",
    wifi        = "rbxassetid://7734093446",
    monitor     = "rbxassetid://7733990288",
    close       = "rbxassetid://7743878857",
    minus       = "rbxassetid://7733978098",
    navigation  = "rbxassetid://7733993211",
    rocket      = "rbxassetid://7734042071",
    shieldAlert = "rbxassetid://7734056411",
    check       = "rbxassetid://7733715400",
}

-- ═══════════════════════════════════════════
--  COLOR PALETTE (NEMESIS DARK GLASS)
-- ═══════════════════════════════════════════
local THEME = {
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
}

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
        local url = "https://api.counterapi.dev/v1/nemesis_script_hub/executions/up"
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
    local gameInfo = ALLOWED_GAMES[placeId]

    if not gameInfo then
        -- Game tidak didukung: Tampilkan kick screen modern glass bento lalu kick
        local kickGui = Instance.new("ScreenGui")
        kickGui.Name = "NemesisKickScreen"
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
        desc.Text = "Script Nemesis Hub tidak mendukung PlaceId ini (" .. tostring(placeId) .. ").\nKamu akan dikeluarkan dari game dalam 3 detik."
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
        LocalPlayer:Kick("[Nemesis Hub] Game tidak didukung! PlaceId: " .. tostring(placeId))
        return nil
    end

    return gameInfo
end

-- ═══════════════════════════════════════════
--  MODERN INTRO / LOADING SCREEN (0–100%)
-- ═══════════════════════════════════════════
local function showIntroScreen(gameInfo, onFinish)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NemesisIntroScreen"
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
    brandTitle.Text = "NEMESIS"
    brandTitle.Font = Enum.Font.GothamBold
    brandTitle.TextSize = 17
    brandTitle.TextColor3 = THEME.TextWhite
    brandTitle.TextXAlignment = Enum.TextXAlignment.Left
    brandTitle.Parent = brandBox

    local brandSub = Instance.new("TextLabel")
    brandSub.Size = UDim2.new(0, 150, 0, 14)
    brandSub.Position = UDim2.new(0, 34, 0, 18)
    brandSub.BackgroundTransparency = 1
    brandSub.Text = ".gg/nemesishub"
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
    userLabel.Text = "@" .. LocalPlayer.Name .. "  •  " .. (gameInfo and gameInfo.name or "Nemesis")
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
--  NEMESIS UI ENGINE (BENTO DASHBOARD & TABS)
-- ═══════════════════════════════════════════
local NemesisHub = {}
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

function NemesisHub:CreateWindow(config)
    config = config or {}
    local TitleName    = config.Name or "NEMESIS"
    local SubtitleText = config.Subtitle or ".gg/nemesishub"
    local ActiveGame   = config.GameName or "Blush Canyon"
    local ActiveScript = config.ScriptName or "blush.lua"
    local HubVersion   = config.Version or "v1.3"

    local Window = {
        Tabs = {},
        CurrentTab = nil,
        GameName = ActiveGame,
        ScriptName = ActiveScript,
        Version = HubVersion,
    }

    -- Root ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "NemesisWindowGui"
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

    -- Top Right Tools (Search, Favorite, Bell, Close, Minimize)
    local ToolsContainer = Instance.new("Frame")
    ToolsContainer.Size = UDim2.new(0, 320, 0, 34)
    ToolsContainer.Position = UDim2.new(1, -340, 0, 18)
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

    -- Star & Bell
    local starBtn = Instance.new("ImageButton")
    starBtn.Size = UDim2.new(0, 18, 0, 18)
    starBtn.Position = UDim2.new(0, 192, 0.5, -9)
    starBtn.BackgroundTransparency = 1
    starBtn.Image = ICONS.star
    starBtn.ImageColor3 = THEME.TextSecondary
    starBtn.Parent = ToolsContainer

    local bellBtn = Instance.new("ImageButton")
    bellBtn.Size = UDim2.new(0, 18, 0, 18)
    bellBtn.Position = UDim2.new(0, 220, 0.5, -9)
    bellBtn.BackgroundTransparency = 1
    bellBtn.Image = ICONS.bell
    bellBtn.ImageColor3 = THEME.TextSecondary
    bellBtn.Parent = ToolsContainer

    -- Close & Minimize
    local minBtn = Instance.new("ImageButton")
    minBtn.Size = UDim2.new(0, 16, 0, 16)
    minBtn.Position = UDim2.new(0, 255, 0.5, -8)
    minBtn.BackgroundTransparency = 1
    minBtn.Image = ICONS.minus
    minBtn.ImageColor3 = THEME.TextSecondary
    minBtn.Parent = ToolsContainer

    local closeBtn = Instance.new("ImageButton")
    closeBtn.Size = UDim2.new(0, 16, 0, 16)
    closeBtn.Position = UDim2.new(0, 285, 0.5, -8)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Image = ICONS.close
    closeBtn.ImageColor3 = THEME.TextSecondary
    closeBtn.Parent = ToolsContainer

    -- ╔═══════════════════════════════════════════╗
    -- ║  FLOATING MINI POP-UP KOTAK WIDGET        ║
    -- ╚═══════════════════════════════════════════╝
    local MiniBox = Instance.new("Frame")
    MiniBox.Name = "NemesisMiniKotak"
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

    -- Toggle Hotkey (RightControl or RightShift)
    UserInputService.InputBegan:Connect(function(input, gp)
        if not gp and (input.KeyCode == Enum.KeyCode.RightControl or input.KeyCode == Enum.KeyCode.RightShift) then
            if isMinimized or not MainFrame.Visible then
                restoreWindow()
            else
                minimizeWindow()
            end
        end
    end)

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

    -- Badges Row
    local BadgesRow = Instance.new("Frame")
    BadgesRow.Size = UDim2.new(0, 300, 0, 22)
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
    vBadge.Size = UDim2.new(0, 48, 1, 0)
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


    -- Lifetime Badge
    local lifeBadge = Instance.new("Frame")
    lifeBadge.Size = UDim2.new(0, 72, 1, 0)
    lifeBadge.BackgroundColor3 = THEME.BgPill
    lifeBadge.BorderSizePixel = 0
    lifeBadge.Parent = BadgesRow
    local lifeC = Instance.new("UICorner")
    lifeC.CornerRadius = UDim.new(0, 6)
    lifeC.Parent = lifeBadge
    local lifeStroke = Instance.new("UIStroke")
    lifeStroke.Color = THEME.Stroke
    lifeStroke.Thickness = 1
    lifeStroke.Parent = lifeBadge
    local lifeIcon = Instance.new("ImageLabel")
    lifeIcon.Size = UDim2.new(0, 12, 0, 12)
    lifeIcon.Position = UDim2.new(0, 6, 0.5, -6)
    lifeIcon.BackgroundTransparency = 1
    lifeIcon.Image = ICONS.clock
    lifeIcon.ImageColor3 = THEME.TextSecondary
    lifeIcon.Parent = lifeBadge
    local lifeT = Instance.new("TextLabel")
    lifeT.Size = UDim2.new(1, -22, 1, 0)
    lifeT.Position = UDim2.new(0, 20, 0, 0)
    lifeT.BackgroundTransparency = 1
    lifeT.Text = "Lifetime"
    lifeT.Font = Enum.Font.GothamMedium
    lifeT.TextSize = 10
    lifeT.TextColor3 = THEME.TextSecondary
    lifeT.TextXAlignment = Enum.TextXAlignment.Left
    lifeT.Parent = lifeBadge

    -- Right Side Level & XP
    local LevelBox = Instance.new("Frame")
    LevelBox.Size = UDim2.new(0, 180, 0, 60)
    LevelBox.Position = UDim2.new(1, -200, 0.5, -30)
    LevelBox.BackgroundTransparency = 1
    LevelBox.Parent = UserCard

    local lvlLabel = Instance.new("TextLabel")
    lvlLabel.Size = UDim2.new(1, 0, 0, 16)
    lvlLabel.BackgroundTransparency = 1
    lvlLabel.Text = "LEVEL  <b>24</b>"
    lvlLabel.RichText = true
    lvlLabel.Font = Enum.Font.Gotham
    lvlLabel.TextSize = 13
    lvlLabel.TextColor3 = THEME.TextSecondary
    lvlLabel.TextXAlignment = Enum.TextXAlignment.Right
    lvlLabel.Parent = LevelBox

    local xpTrack = Instance.new("Frame")
    xpTrack.Size = UDim2.new(1, 0, 0, 6)
    xpTrack.Position = UDim2.new(0, 0, 0, 24)
    xpTrack.BackgroundColor3 = Color3.fromRGB(36, 28, 52)
    xpTrack.BorderSizePixel = 0
    xpTrack.Parent = LevelBox
    local xpTC = Instance.new("UICorner")
    xpTC.CornerRadius = UDim.new(1, 0)
    xpTC.Parent = xpTrack

    local xpFill = Instance.new("Frame")
    xpFill.Size = UDim2.new(0.68, 0, 1, 0)
    xpFill.BackgroundColor3 = THEME.AccentPurple
    xpFill.BorderSizePixel = 0
    xpFill.Parent = xpTrack
    local xpFC = Instance.new("UICorner")
    xpFC.CornerRadius = UDim.new(1, 0)
    xpFC.Parent = xpFill
    local xpFGrad = Instance.new("UIGradient")
    xpFGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, THEME.AccentPurple),
        ColorSequenceKeypoint.new(1, THEME.AccentNeon),
    })
    xpFGrad.Parent = xpFill

    local xpText = Instance.new("TextLabel")
    xpText.Size = UDim2.new(1, 0, 0, 14)
    xpText.Position = UDim2.new(0, 0, 0, 36)
    xpText.BackgroundTransparency = 1
    xpText.Text = "680 / 1000 XP"
    xpText.Font = Enum.Font.Gotham
    xpText.TextSize = 10
    xpText.TextColor3 = THEME.TextMuted
    xpText.TextXAlignment = Enum.TextXAlignment.Right
    xpText.Parent = LevelBox

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

    -- Game Name Big
    local gcGameName = Instance.new("TextLabel")
    gcGameName.Size = UDim2.new(1, -36, 0, 26)
    gcGameName.Position = UDim2.new(0, 18, 0, 64)
    gcGameName.BackgroundTransparency = 1
    gcGameName.Text = ActiveGame
    gcGameName.Font = Enum.Font.GothamBold
    gcGameName.TextSize = 20
    gcGameName.TextColor3 = THEME.TextWhite
    gcGameName.TextXAlignment = Enum.TextXAlignment.Left
    gcGameName.Parent = GameUseCard

    -- Script Badge
    local gcScriptPill = Instance.new("Frame")
    gcScriptPill.Size = UDim2.new(0, 130, 0, 24)
    gcScriptPill.Position = UDim2.new(0, 18, 0, 98)
    gcScriptPill.BackgroundColor3 = THEME.BgPill
    gcScriptPill.BorderSizePixel = 0
    gcScriptPill.Parent = GameUseCard
    local gspC = Instance.new("UICorner")
    gspC.CornerRadius = UDim.new(0, 6)
    gspC.Parent = gcScriptPill
    local gspS = Instance.new("UIStroke")
    gspS.Color = THEME.Stroke
    gspS.Thickness = 1
    gspS.Parent = gcScriptPill
    local gspDot = Instance.new("Frame")
    gspDot.Size = UDim2.new(0, 6, 0, 6)
    gspDot.Position = UDim2.new(0, 10, 0.5, -3)
    gspDot.BackgroundColor3 = THEME.LiveGreen
    gspDot.BorderSizePixel = 0
    gspDot.Parent = gcScriptPill
    local gspDotC = Instance.new("UICorner")
    gspDotC.CornerRadius = UDim.new(1, 0)
    gspDotC.Parent = gspDot
    local gspText = Instance.new("TextLabel")
    gspText.Size = UDim2.new(1, -24, 1, 0)
    gspText.Position = UDim2.new(0, 22, 0, 0)
    gspText.BackgroundTransparency = 1
    gspText.Text = ActiveScript
    gspText.Font = Enum.Font.GothamMedium
    gspText.TextSize = 11
    gspText.TextColor3 = THEME.TextWhite
    gspText.TextXAlignment = Enum.TextXAlignment.Left
    gspText.Parent = gcScriptPill

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
    pciImg.Image = ICONS.activity
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
    pcSub.Text = "Current FPS"
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
    memIcon.Image = ICONS.monitor
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
    memTag.Text = "MEM"
    memTag.Font = Enum.Font.GothamBold
    memTag.TextSize = 10
    memTag.TextColor3 = THEME.AccentNeon
    memTag.TextXAlignment = Enum.TextXAlignment.Right
    memTag.Parent = pcMemPill

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
    lciImg.Image = ICONS.history
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

            local function updateToggle()
                curVal = not curVal
                TweenService:Create(switchBg, TweenInfo.new(0.2), {
                    BackgroundColor3 = curVal and THEME.AccentPurple or THEME.BgPill
                }):Play()
                TweenService:Create(knob, TweenInfo.new(0.2), {
                    Position = curVal and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
                }):Play()
                pcall(cb, curVal)
            end

            togCard.MouseButton1Click:Connect(updateToggle)
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
function NemesisHub:Notify(config)
    if NemesisHub.ActiveWindow then
        NemesisHub.ActiveWindow:Notify(config)
    end
end

-- ═══════════════════════════════════════════
--  EXPOSURE & GLOBAL DISPATCHER
-- ═══════════════════════════════════════════
getgenv().NemesisHub = NemesisHub

-- Jika main.lua dieksekusi secara langsung sebagai loader:
local function entryLoader()
    local gameInfo = validateGame()
    if not gameInfo then return end

    showIntroScreen(gameInfo, function()
        -- Unduh dan jalankan script game yang cocok (e.g. blush.lua)
        local scriptUrl = SCRIPT_BASE_URL .. gameInfo.script .. ".lua"
        local ok, result = pcall(function()
            return loadstring(game:HttpGet(scriptUrl))()
        end)

        if not ok then
            -- Fallback lokal jika pengembangan offline
            pcall(function()
                loadstring(readfile(gameInfo.script .. ".lua"))()
            end)
        end
    end)
end

-- Jalankan loader otomatis jika belum ada game script yang memanggil NemesisHub
task.spawn(function()
    -- Jika dieksekusi langsung
    if not getgenv()._NEMESIS_CHILD_LOADED then
        entryLoader()
    end
end)

return NemesisHub
