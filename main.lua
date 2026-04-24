-- ╔══════════════════════════════════════════════════════╗
-- ║           PAK WOWO SCRIPT HUB - MAIN LOADER          ║
-- ║              by Azeey | Beta Version                  ║
-- ╚══════════════════════════════════════════════════════╝

local Players         = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local RunService      = game:GetService("RunService")
local LocalPlayer     = Players.LocalPlayer
local HttpService     = game:GetService("HttpService")

-- ═══════════════════════════════════════
--  KONFIGURASI GAME YANG DIIZINKAN
-- ═══════════════════════════════════════
local ALLOWED_GAMES = {
    [122954079363953] = "blush",   -- Blush Canyon → load blush.lua
}

-- Ganti URL ini sesuai tempat kamu host script
local SCRIPT_BASE_URL = "https://raw.githubusercontent.com/hendrawansuinto571-glitch/script/main/"

-- ═══════════════════════════════════════
--  LOADING SCREEN CUSTOM (0–100%)
-- ═══════════════════════════════════════
local ScreenGui     = Instance.new("ScreenGui")
ScreenGui.Name      = "WowoLoader"
ScreenGui.ResetOnSpawn  = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent    = LocalPlayer:WaitForChild("PlayerGui")

-- Background gelap
local BG = Instance.new("Frame")
BG.Size             = UDim2.new(1, 0, 1, 0)
BG.Position         = UDim2.new(0, 0, 0, 0)
BG.BackgroundColor3 = Color3.fromRGB(8, 8, 14)
BG.BorderSizePixel  = 0
BG.ZIndex           = 10
BG.Parent           = ScreenGui

-- Gradient mesh background
local UIGrad = Instance.new("UIGradient")
UIGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(8,  8,  20)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(15, 10, 35)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(8,  8,  20)),
})
UIGrad.Rotation = 45
UIGrad.Parent   = BG

-- Glow circle belakang avatar
local GlowCircle = Instance.new("Frame")
GlowCircle.Size              = UDim2.new(0, 160, 0, 160)
GlowCircle.Position          = UDim2.new(0.5, -80, 0.27, -80)
GlowCircle.BackgroundColor3  = Color3.fromRGB(130, 80, 255)
GlowCircle.BorderSizePixel   = 0
GlowCircle.ZIndex            = 11
GlowCircle.Parent            = BG
local GlowCorner = Instance.new("UICorner")
GlowCorner.CornerRadius = UDim.new(1, 0)
GlowCorner.Parent       = GlowCircle
local GlowGrad = Instance.new("UIGradient")
GlowGrad.Color    = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(160, 100, 255)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(60,  30, 140)),
})
GlowGrad.Rotation = 135
GlowGrad.Parent   = GlowCircle

-- Avatar frame (lingkaran)
local AvatarFrame = Instance.new("Frame")
AvatarFrame.Size             = UDim2.new(0, 100, 0, 100)
AvatarFrame.Position         = UDim2.new(0.5, -50, 0.27, -50)
AvatarFrame.BackgroundColor3 = Color3.fromRGB(25, 18, 50)
AvatarFrame.BorderSizePixel  = 0
AvatarFrame.ZIndex           = 12
AvatarFrame.Parent           = BG
local AvatarCorner = Instance.new("UICorner")
AvatarCorner.CornerRadius = UDim.new(1, 0)
AvatarCorner.Parent       = AvatarFrame

local AvatarImage = Instance.new("ImageLabel")
AvatarImage.Size              = UDim2.new(1, 0, 1, 0)
AvatarImage.BackgroundColor3  = Color3.fromRGB(30, 20, 60)
AvatarImage.BorderSizePixel   = 0
AvatarImage.ZIndex            = 13
AvatarImage.Parent            = AvatarFrame
local AvatarImageCorner = Instance.new("UICorner")
AvatarImageCorner.CornerRadius = UDim.new(1, 0)
AvatarImageCorner.Parent       = AvatarImage

-- Ambil foto profil
local thumbOk, thumbUrl = pcall(function()
    return Players:GetUserThumbnailAsync(
        LocalPlayer.UserId,
        Enum.ThumbnailType.HeadShot,
        Enum.ThumbnailSize.Size420x420
    )
end)
if thumbOk then
    AvatarImage.Image = thumbUrl
end

-- Nama player
local NameLabel = Instance.new("TextLabel")
NameLabel.Size               = UDim2.new(0, 300, 0, 30)
NameLabel.Position           = UDim2.new(0.5, -150, 0.27, 65)
NameLabel.BackgroundTransparency = 1
NameLabel.Text               = LocalPlayer.DisplayName
NameLabel.TextColor3         = Color3.fromRGB(255, 255, 255)
NameLabel.Font               = Enum.Font.GothamBold
NameLabel.TextSize           = 18
NameLabel.ZIndex             = 14
NameLabel.Parent             = BG

-- Username kecil
local UsernameLabel = Instance.new("TextLabel")
UsernameLabel.Size               = UDim2.new(0, 300, 0, 20)
UsernameLabel.Position           = UDim2.new(0.5, -150, 0.27, 92)
UsernameLabel.BackgroundTransparency = 1
UsernameLabel.Text               = "@" .. LocalPlayer.Name
UsernameLabel.TextColor3         = Color3.fromRGB(160, 130, 220)
UsernameLabel.Font               = Enum.Font.Gotham
UsernameLabel.TextSize           = 13
UsernameLabel.ZIndex             = 14
UsernameLabel.Parent             = BG

-- Hub title
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size               = UDim2.new(0, 400, 0, 40)
TitleLabel.Position           = UDim2.new(0.5, -200, 0.53, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text               = "PAK WOWO SCRIPT HUB"
TitleLabel.TextColor3         = Color3.fromRGB(255, 255, 255)
TitleLabel.Font               = Enum.Font.GothamBlack
TitleLabel.TextSize           = 22
TitleLabel.ZIndex             = 14
TitleLabel.Parent             = BG

-- Subtitle
local SubLabel = Instance.new("TextLabel")
SubLabel.Size               = UDim2.new(0, 400, 0, 25)
SubLabel.Position           = UDim2.new(0.5, -200, 0.53, 38)
SubLabel.BackgroundTransparency = 1
SubLabel.Text               = "by Azeey  •  Beta"
SubLabel.TextColor3         = Color3.fromRGB(150, 120, 200)
SubLabel.Font               = Enum.Font.Gotham
SubLabel.TextSize           = 13
SubLabel.ZIndex             = 14
SubLabel.Parent             = BG

-- Progress bar background
local BarBG = Instance.new("Frame")
BarBG.Size             = UDim2.new(0, 340, 0, 6)
BarBG.Position         = UDim2.new(0.5, -170, 0.72, 0)
BarBG.BackgroundColor3 = Color3.fromRGB(35, 25, 65)
BarBG.BorderSizePixel  = 0
BarBG.ZIndex           = 14
BarBG.Parent           = BG
local BarBGCorner = Instance.new("UICorner")
BarBGCorner.CornerRadius = UDim.new(1, 0)
BarBGCorner.Parent       = BarBG

-- Progress bar fill
local BarFill = Instance.new("Frame")
BarFill.Size             = UDim2.new(0, 0, 1, 0)
BarFill.BackgroundColor3 = Color3.fromRGB(140, 90, 255)
BarFill.BorderSizePixel  = 0
BarFill.ZIndex           = 15
BarFill.Parent           = BarBG
local BarFillCorner = Instance.new("UICorner")
BarFillCorner.CornerRadius = UDim.new(1, 0)
BarFillCorner.Parent       = BarFill

local BarGlow = Instance.new("UIGradient")
BarGlow.Color    = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(200, 160, 255)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(100, 50,  200)),
})
BarGlow.Parent   = BarFill

-- Persen label
local PercentLabel = Instance.new("TextLabel")
PercentLabel.Size               = UDim2.new(0, 340, 0, 25)
PercentLabel.Position           = UDim2.new(0.5, -170, 0.72, 12)
PercentLabel.BackgroundTransparency = 1
PercentLabel.Text               = "0%"
PercentLabel.TextColor3         = Color3.fromRGB(200, 170, 255)
PercentLabel.Font               = Enum.Font.GothamBold
PercentLabel.TextSize           = 14
PercentLabel.TextXAlignment     = Enum.TextXAlignment.Center
PercentLabel.ZIndex             = 16
PercentLabel.Parent             = BG

-- Status label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size               = UDim2.new(0, 340, 0, 20)
StatusLabel.Position           = UDim2.new(0.5, -170, 0.72, 36)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text               = "Menginisialisasi..."
StatusLabel.TextColor3         = Color3.fromRGB(120, 100, 160)
StatusLabel.Font               = Enum.Font.Gotham
StatusLabel.TextSize           = 11
StatusLabel.TextXAlignment     = Enum.TextXAlignment.Center
StatusLabel.ZIndex             = 16
StatusLabel.Parent             = BG

-- ═══════════════════════════════════════
--  FUNGSI UPDATE LOADING
-- ═══════════════════════════════════════
local function setProgress(pct, status)
    local clamp = math.clamp(pct, 0, 100)
    BarFill.Size    = UDim2.new(clamp / 100, 0, 1, 0)
    PercentLabel.Text   = tostring(clamp) .. "%"
    StatusLabel.Text    = status or ""
    task.wait(0.04)
end

-- ═══════════════════════════════════════
--  CEK GAME
-- ═══════════════════════════════════════
local function checkGame()
    setProgress(10, "Memeriksa game...")
    task.wait(0.3)

    local placeId = game.PlaceId
    local scriptName = ALLOWED_GAMES[placeId]

    setProgress(30, "Memvalidasi PlaceId: " .. tostring(placeId))
    task.wait(0.4)

    if not scriptName then
        -- Bukan game yang diizinkan
        setProgress(100, "❌ Game tidak didukung!")
        task.wait(0.8)

        -- Tampilkan notif merah lalu kick
        local KickFrame = Instance.new("Frame")
        KickFrame.Size              = UDim2.new(0, 380, 0, 160)
        KickFrame.Position          = UDim2.new(0.5, -190, 0.5, -80)
        KickFrame.BackgroundColor3  = Color3.fromRGB(20, 8, 8)
        KickFrame.BorderSizePixel   = 0
        KickFrame.ZIndex            = 20
        KickFrame.Parent            = ScreenGui
        local KC = Instance.new("UICorner")
        KC.CornerRadius = UDim.new(0, 12)
        KC.Parent = KickFrame
        local KStroke = Instance.new("UIStroke")
        KStroke.Color     = Color3.fromRGB(255, 60, 60)
        KStroke.Thickness = 1.5
        KStroke.Parent    = KickFrame

        local KIcon = Instance.new("TextLabel")
        KIcon.Size               = UDim2.new(1, 0, 0, 50)
        KIcon.Position           = UDim2.new(0, 0, 0, 10)
        KIcon.BackgroundTransparency = 1
        KIcon.Text               = "⛔"
        KIcon.TextSize           = 36
        KIcon.Font               = Enum.Font.GothamBlack
        KIcon.TextColor3         = Color3.fromRGB(255, 80, 80)
        KIcon.ZIndex             = 21
        KIcon.Parent             = KickFrame

        local KTitle = Instance.new("TextLabel")
        KTitle.Size               = UDim2.new(1, -20, 0, 30)
        KTitle.Position           = UDim2.new(0, 10, 0, 60)
        KTitle.BackgroundTransparency = 1
        KTitle.Text               = "GAME TIDAK DIDUKUNG"
        KTitle.TextColor3         = Color3.fromRGB(255, 80, 80)
        KTitle.Font               = Enum.Font.GothamBlack
        KTitle.TextSize           = 16
        KTitle.ZIndex             = 21
        KTitle.Parent             = KickFrame

        local KMsg = Instance.new("TextLabel")
        KMsg.Size               = UDim2.new(1, -20, 0, 50)
        KMsg.Position           = UDim2.new(0, 10, 0, 90)
        KMsg.BackgroundTransparency = 1
        KMsg.Text               = "Script ini hanya untuk Blush Canyon.\nKamu akan di-kick dalam 3 detik..."
        KMsg.TextColor3         = Color3.fromRGB(200, 150, 150)
        KMsg.Font               = Enum.Font.Gotham
        KMsg.TextSize           = 12
        KMsg.TextWrapped        = true
        KMsg.ZIndex             = 21
        KMsg.Parent             = KickFrame

        task.wait(3)
        LocalPlayer:Kick("[Wowo Hub] Game tidak didukung! Script ini hanya untuk Blush Canyon (PlaceId: 3218570640).")
        return false
    end

    setProgress(55, "Game valid! Memuat modul...")
    task.wait(0.3)

    return scriptName
end

-- ═══════════════════════════════════════
--  LOAD SCRIPT YANG SESUAI
-- ═══════════════════════════════════════
local function loadScript(name)
    setProgress(70, "Mengunduh " .. name .. ".lua...")
    task.wait(0.3)

    -- Coba load dari GITHUB (ganti URL sesuai repo kamu)
    local url = SCRIPT_BASE_URL .. name .. ".lua"
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)

    if ok then
        setProgress(100, "✅ Script berhasil dimuat!")
        task.wait(0.5)
        return true
    else
        -- Fallback: coba loadstring lokal (jika script ada di executor)
        setProgress(85, "Mencoba metode alternatif...")
        task.wait(0.3)

        -- Untuk pengembangan lokal, kamu bisa uncomment dan ganti path ini:
        -- local localOk, localErr = pcall(function()
        --     loadstring(readfile(name .. ".lua"))()
        -- end)

        setProgress(100, "⚠️ Gagal: " .. tostring(result):sub(1, 60))
        task.wait(1)
        warn("[Wowo Hub] Gagal memuat script:", result)
        return false
    end
end

-- ═══════════════════════════════════════
--  ANIMASI FADE OUT LOADING SCREEN
-- ═══════════════════════════════════════
local function fadeOut()
    for i = 1, 10 do
        BG.BackgroundTransparency = i / 10
        task.wait(0.04)
    end
    ScreenGui:Destroy()
end

-- ═══════════════════════════════════════
--  MAIN ENTRY
-- ═══════════════════════════════════════
task.spawn(function()
    setProgress(5, "Memuat Wowo Hub...")
    task.wait(0.5)

    local scriptName = checkGame()
    if not scriptName then return end

    setProgress(60, "Game: Blush Canyon ✓")
    task.wait(0.4)

    local loaded = loadScript(scriptName)
    if loaded then
        setProgress(100, "✅ Selamat datang, " .. LocalPlayer.DisplayName .. "!")
        task.wait(1)
        fadeOut()
    else
        task.wait(2)
        fadeOut()
    end
end)
