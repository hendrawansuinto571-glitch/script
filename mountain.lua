-- ╔══════════════════════════════════════════════════════════════════╗
-- ║       UNIONSAL SCRIPT HUB — Mountain Excavator (White Summit)     ║
-- ║   Complete Automation Suite • ReplicatedStorage.Services.Library.F║
-- ║   Auto Dig (4 Modes) • Auto Explosives • Auto Vacuum & 25 Crates  ║
-- ║   Auto 18 Gems • Auto Buy Tools/Hangar • Heavy Vehicles • Climb   ║
-- ║   Full Auto Combo Mode • Command Parser (; ! /) • Anti-Kick Safety║
-- ╚══════════════════════════════════════════════════════════════════╝

getgenv()._UNIONSAL_CHILD_LOADED = true
getgenv()._NEMESIS_CHILD_LOADED = true

local SCRIPT_BASE_URL = "https://raw.githubusercontent.com/hendrawansuinto571-glitch/script/main/"

-- ══════════════════════════════════════════════════════════════════
-- 1. LOAD UI FRAMEWORK (main.lua)
-- ══════════════════════════════════════════════════════════════════
local Unionsal = getgenv().UnionsalHub or getgenv().NemesisHub
if not Unionsal or type(Unionsal.CreateWindow) ~= "function" then
    local okLocal, resLocal = pcall(function()
        return loadstring(readfile("main.lua"))()
    end)
    if okLocal and resLocal and type(resLocal.CreateWindow) == "function" then
        Unionsal = resLocal
    else
        local okWeb, resWeb = pcall(function()
            return loadstring(game:HttpGet(SCRIPT_BASE_URL .. "main.lua?v=" .. tostring(tick())))()
        end)
        if okWeb and resWeb and type(resWeb.CreateWindow) == "function" then
            Unionsal = resWeb
        else
            warn("[Unionsal Hub] Gagal memuat main.lua")
            return
        end
    end
end

-- ══════════════════════════════════════════════════════════════════
-- 2. ROBLOX CORE SERVICES
-- ══════════════════════════════════════════════════════════════════
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService= game:GetService("PathfindingService")

local LocalPlayer = Players.LocalPlayer

-- ══════════════════════════════════════════════════════════════════
-- 3. NETWORK FRAMEWORK RESOLVER (Services.Library.F)
-- ══════════════════════════════════════════════════════════════════
local FModule = nil
local RemoteRE = nil
local RemoteRF = nil

local function initNetwork()
    local services = ReplicatedStorage:FindFirstChild("Services")
    local library = services and services:FindFirstChild("Library")
    local fObj = library and library:FindFirstChild("F")
    if fObj and fObj:IsA("ModuleScript") then
        local ok, res = pcall(require, fObj)
        if ok and type(res) == "table" then
            FModule = res
        end
    end

    RemoteRE = (fObj and fObj:FindFirstChild("RE"))
        or (library and library:FindFirstChild("RE"))
        or (services and services:FindFirstChild("RE"))
        or ReplicatedStorage:FindFirstChild("RE", true)

    RemoteRF = (fObj and fObj:FindFirstChild("RF"))
        or (library and library:FindFirstChild("RF"))
        or (services and services:FindFirstChild("RF"))
        or ReplicatedStorage:FindFirstChild("RF", true)
end
pcall(initNetwork)

local function fireServerEvent(eventName, payload)
    if FModule and FModule.ClientToServer and type(FModule.ClientToServer.Fire) == "function" then
        local ok, err = pcall(function()
            FModule.ClientToServer.Fire(eventName, payload)
        end)
        if ok then return true end
    end
    if RemoteRE and RemoteRE:IsA("RemoteEvent") then
        local ok = pcall(function()
            RemoteRE:FireServer(eventName, payload)
        end)
        if ok then return true end
    end
    return false
end

local function invokeServerRPC(methodName, payload)
    if FModule and FModule.RPC and type(FModule.RPC.Invoke) == "function" then
        local ok, res = pcall(function()
            return FModule.RPC.Invoke(methodName, payload)
        end)
        if ok then return res end
    end
    if RemoteRF and RemoteRF:IsA("RemoteFunction") then
        local ok, res = pcall(function()
            return RemoteRF:InvokeServer(methodName, payload)
        end)
        if ok then return res end
    end
    return nil
end

-- ══════════════════════════════════════════════════════════════════
-- 4. CHARACTER & HELPER FUNCTIONS
-- ══════════════════════════════════════════════════════════════════
local function getCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getRootPart()
    local char = getCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function parseNumber(val)
    if type(val) == "number" then return val end
    if type(val) ~= "string" then return 0 end
    local clean = val:gsub(",", ""):gsub("%s+", "")
    local num, suffix = clean:match("^([%d%.]+)([kKmMbB]?)$")
    if not num then return 0 end
    num = tonumber(num) or 0
    if suffix == "k" or suffix == "K" then
        return num * 1000
    elseif suffix == "m" or suffix == "M" then
        return num * 1000000
    elseif suffix == "b" or suffix == "B" then
        return num * 1000000000
    end
    return num
end

local function getLeaderstat(name)
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    if not ls then return 0, "0" end
    local valObj = ls:FindFirstChild(name)
    if not valObj then return 0, "0" end
    local raw = tostring(valObj.Value)
    return parseNumber(raw), raw
end

local function getCash()
    local num, raw = getLeaderstat("Cash")
    return num, raw
end

local function getStones()
    local num, raw = getLeaderstat("Stones")
    return num, raw
end

local function safeTeleport(targetPos, offset)
    local hrp = getRootPart()
    if not hrp or typeof(targetPos) ~= "Vector3" then return false end
    offset = offset or Vector3.new(0, 3, 0)
    local cf = CFrame.new(targetPos + offset)
    hrp.CFrame = cf
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    return true
end

-- ══════════════════════════════════════════════════════════════════
-- 5. PRESETS & COORDINATES
-- ══════════════════════════════════════════════════════════════════
local Presets = {
    -- Lokasi Dasar
    base    = Vector3.new(343.7, -243.3, 1092.9),
    shop    = Vector3.new(340.4, -242.0, 1034.3),
    hangar1 = Vector3.new(477.8, -240.0, 1110.7),
    hangar2 = Vector3.new(477.8, -240.0, 1065.9),
    portal  = Vector3.new(380.5, -246.2, 1059.0),

    -- Section Gunung (Progression 1-9)
    sec1    = Vector3.new(316.1, -104.2, 951.9),
    sec2    = Vector3.new(375.0, -104.2, 917.7),
    sec3    = Vector3.new(728.2, -104.2, 474.9),
    sec4    = Vector3.new(621.1, -104.2, 871.8),
    sec5    = Vector3.new(100.3, -104.2, 1039.1),
    sec6    = Vector3.new(12.1, -104.2, 899.9),
    sec7    = Vector3.new(194.5, -104.2, 1014.1),
    sec8    = Vector3.new(268.8, 87.3, -997.8),
    sec9    = Vector3.new(401.2, 84.8, -1270.7), -- Puncak / Peak
}

local ToolProgression = {
    { Name = "Shovel",        Price = 0,           Display = "ShovelShopDisplay" },
    { Name = "Pickaxe",       Price = 400,         Display = "PickaxeShopDisplay" },
    { Name = "Jackhammer",    Price = 10000,       Display = "JackhammerShopDisplay", Aliases = {"Big Drill"} },
    { Name = "Dynamite",      Price = 150000,      Display = "DynamiteShopDisplay" },
    { Name = "Drill Rocket",  Price = 1500000,     Display = "DrillRocketShopDisplay" },
    { Name = "MountainBomb",  Price = 5000000,     Display = "MountainBombShopDisplay", Aliases = {"Rocket Bomb"} },
    { Name = "Atom Bomb",     Price = 2500000,     Display = "AtomBombShopDisplay" },
    { Name = "Fat Atom Bomb", Price = 100000000,   Display = "FatAtomBombShopDisplay" },
}

-- ══════════════════════════════════════════════════════════════════
-- 6. SYSTEM STATE REGISTRY
-- ══════════════════════════════════════════════════════════════════
local State = {
    -- Utility
    Fly             = false,
    FlySpeed        = 75,
    Noclip          = false,
    WalkSpeed       = 16,

    -- Auto Dig
    AutoDig         = false,
    DigMode         = "down",      -- "down", "forward", "wall", "scan"
    DigSpeed        = "fast",      -- "fast" (0.15s), "instant" (0.05s)
    DigHeight       = 5,           -- Hover height above target
    ActiveTool      = "Pickaxe",

    -- Auto Explosives
    AutoBomb        = false,
    BombDelay       = 0.5,

    -- Auto Vacuum & Loot
    AutoVacuum      = false,
    AutoCrates      = false,
    AutoGems        = false,
    VacuumDelay     = 0.35,

    -- Auto Buy Shop
    AutoBuy         = false,
    AutoBuyHangar   = false,
    AutoBuySpeed    = false,
    BuyPriority     = "tool",      -- "tool", "hangar", "speed"

    -- Auto Vehicle
    AutoVehicle     = false,
    VehicleType     = "excavator", -- "excavator", "rockettruck", "m79", "ufo"
    VehicleTarget   = "sec9",
    VehicleFly      = false,
    VehicleYaw      = 0,

    -- High Mountain Climb
    Climb           = false,
    ClimbSpeed      = "normal",    -- "slow", "normal", "fast"
    ClimbVehicle    = false,

    -- Combo / Full Auto Mode
    FullAuto        = false,
    SafetyPacing    = 0.2,         -- Anti-kick interval padding
}

local LogBuffer = {}
local function logMessage(msg)
    local line = string.format("[%s] %s", os.date("%H:%M:%S"), tostring(msg))
    print(line)
    table.insert(LogBuffer, 1, line)
    while #LogBuffer > 12 do
        table.remove(LogBuffer)
    end
    if State.StatusParagraph then
        pcall(function()
            State.StatusParagraph:Set({
                Title = "Console / Activity Log",
                Content = table.concat(LogBuffer, "\n")
            })
        end)
    end
end

-- ══════════════════════════════════════════════════════════════════
-- 7. CORE UTILITIES: FLY, NOCLIP, SPEED
-- ══════════════════════════════════════════════════════════════════
local FlyConnection = nil
local BodyVel = nil
local BodyGyr = nil

local function setFly(enabled)
    State.Fly = enabled
    local hrp = getRootPart()
    local hum = getHumanoid()

    if BodyVel then BodyVel:Destroy() BodyVel = nil end
    if BodyGyr then BodyGyr:Destroy() BodyGyr = nil end
    if FlyConnection then FlyConnection:Disconnect() FlyConnection = nil end

    if not enabled then
        if hum then hum.PlatformStand = false end
        logMessage("Fly dinonaktifkan.")
        return
    end

    if not hrp or not hum then return end
    hum.PlatformStand = true

    BodyVel = Instance.new("BodyVelocity")
    BodyVel.Name = "Mtn_FlyVelocity"
    BodyVel.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    BodyVel.Velocity = Vector3.zero
    BodyVel.Parent = hrp

    BodyGyr = Instance.new("BodyGyro")
    BodyGyr.Name = "Mtn_FlyGyro"
    BodyGyr.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    BodyGyr.CFrame = hrp.CFrame
    BodyGyr.Parent = hrp

    FlyConnection = RunService.RenderStepped:Connect(function()
        if not State.Fly or not hrp or not hum then return end
        local cam = workspace.CurrentCamera
        if not cam then return end

        local moveDir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end

        if moveDir.Magnitude > 0 then
            BodyVel.Velocity = moveDir.Unit * (State.FlySpeed or 75)
        else
            BodyVel.Velocity = Vector3.zero
        end
        BodyGyr.CFrame = cam.CFrame
    end)

    logMessage(string.format("Fly aktif (Speed: %d).", State.FlySpeed or 75))
end

-- Noclip loop
RunService.Stepped:Connect(function()
    if State.Noclip then
        local char = LocalPlayer.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.CanCollide = false
                end
            end
        end
    end
end)

local function setNoclip(enabled)
    State.Noclip = enabled
    logMessage("Noclip: " .. (enabled and "Aktif" or "Nonaktif"))
end

local function setWalkSpeed(val)
    State.WalkSpeed = val
    local hum = getHumanoid()
    if hum then hum.WalkSpeed = val end
    logMessage("WalkSpeed diatur ke " .. tostring(val))
end

-- ══════════════════════════════════════════════════════════════════
-- 8. BEST OWNED TOOL RESOLVER
-- ══════════════════════════════════════════════════════════════════
local function getBestOwnedTool()
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local ch = LocalPlayer.Character
    local found = {}

    local function recordTool(item)
        if item:IsA("Tool") then
            found[item.Name:lower()] = item.Name
        end
    end

    if bp then for _, t in ipairs(bp:GetChildren()) do recordTool(t) end end
    if ch then for _, t in ipairs(ch:GetChildren()) do recordTool(t) end end

    -- Scan mundur dari tool terkuat ke terlemah
    for i = #ToolProgression, 1, -1 do
        local entry = ToolProgression[i]
        local nameLower = entry.Name:lower()
        if found[nameLower] then
            return found[nameLower]
        end
        for _, alias in ipairs(entry.Aliases or {}) do
            if found[alias:lower()] then
                return found[alias:lower()]
            end
        end
    end

    return State.ActiveTool or "Pickaxe"
end

-- ══════════════════════════════════════════════════════════════════
-- 9. MODULE 1: AUTO DIG LOOP
-- ══════════════════════════════════════════════════════════════════
local function performDig(targetPos, normal)
    local toolName = getBestOwnedTool()
    targetPos = targetPos or (getRootPart() and (getRootPart().Position - Vector3.new(0, 4, 0)))
    normal = normal or Vector3.new(0, -1, 0)
    if not targetPos then return end

    fireServerEvent("Dig", {
        Tool = toolName,
        Position = targetPos,
        Normal = normal
    })
end

task.spawn(function()
    while true do
        if State.AutoDig and not State.FullAutoActiveClimb then
            local hrp = getRootPart()
            if hrp then
                local myPos = hrp.Position
                local targetPos = nil
                local normal = Vector3.new(0, -1, 0)

                if State.DigMode == "down" then
                    targetPos = myPos - Vector3.new(0, State.DigHeight or 5, 0)
                    normal = Vector3.new(0, -1, 0)
                elseif State.DigMode == "forward" then
                    targetPos = myPos + (hrp.CFrame.LookVector * 8)
                    normal = -hrp.CFrame.LookVector
                elseif State.DigMode == "wall" then
                    -- Raycast ke 4 sisi sekitar untuk mendeteksi dinding terdekat
                    local rayParams = RaycastParams.new()
                    rayParams.FilterType = Enum.RaycastFilterType.Exclude
                    rayParams.FilterDescendantsInstances = { getCharacter() }
                    local dirs = {
                        hrp.CFrame.LookVector,
                        -hrp.CFrame.LookVector,
                        hrp.CFrame.RightVector,
                        -hrp.CFrame.RightVector
                    }
                    for _, dir in ipairs(dirs) do
                        local hit = workspace:Raycast(myPos, dir * 25, rayParams)
                        if hit and hit.Position then
                            targetPos = hit.Position
                            normal = hit.Normal
                            break
                        end
                    end
                    if not targetPos then
                        targetPos = myPos - Vector3.new(0, State.DigHeight or 5, 0)
                    end
                elseif State.DigMode == "scan" then
                    -- 360-degree radial fan
                    local angle = (tick() * 4) % (math.pi * 2)
                    local dir = Vector3.new(math.cos(angle), -0.5, math.sin(angle)).Unit
                    targetPos = myPos + (dir * 12)
                    normal = -dir
                end

                performDig(targetPos, normal)
            end

            local delay = (State.DigSpeed == "instant") and 0.06 or 0.16
            task.wait(delay + (State.SafetyPacing * 0.2))
        else
            task.wait(0.3)
        end
    end
end)

-- ══════════════════════════════════════════════════════════════════
-- 10. MODULE 2: AUTO EXPLOSIVES (BOMB / DYNAMITE)
-- ══════════════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        if State.AutoBomb then
            local hrp = getRootPart()
            if hrp then
                local plantPos = hrp.Position - Vector3.new(0, 3, 0)
                local normal = Vector3.new(0, -1, 0)
                fireServerEvent("PlantCharge", { Position = plantPos, Normal = normal })
                task.wait(0.12)
                fireServerEvent("Detonate", {})
            end
            task.wait(State.BombDelay or 0.5)
        else
            task.wait(0.4)
        end
    end
end)

local function undoBomb()
    fireServerEvent("UndoCharge", {})
    logMessage("Undo charge remote terkirim.")
end

-- ══════════════════════════════════════════════════════════════════
-- 11. MODULE 3: AUTO VACUUM & LOOT (CRATES & GEMS)
-- ══════════════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        if State.AutoVacuum then
            fireServerEvent("Vacuum", {
                { Id = 1, Material = "Stone", Count = 10, Auto = true }
            })
            fireServerEvent("StonesSync", {})
            task.wait(State.VacuumDelay or 0.35)
        else
            task.wait(0.5)
        end
    end
end)

local function claimAllCrates()
    local cratesFolder = workspace:FindFirstChild("LuckyCrates")
    if not cratesFolder then
        logMessage("LuckyCrates folder tidak ditemukan.")
        return 0
    end

    local hrp = getRootPart()
    local origPos = hrp and hrp.Position
    local claimed = 0
    local crates = cratesFolder:GetChildren()
    logMessage(string.format("Memulai klaim %d Lucky Crates...", #crates))

    for idx, crate in ipairs(crates) do
        local pos = crate:IsA("Model") and crate:GetPivot().Position or (crate:IsA("BasePart") and crate.Position)
        if pos then
            safeTeleport(pos, Vector3.new(0, 2, 0))
            task.wait(0.12)
            local prompt = crate:FindFirstChild("LuckyCratePrompt", true)
            if prompt and prompt:IsA("ProximityPrompt") then
                pcall(function()
                    if fireproximityprompt then
                        fireproximityprompt(prompt, 0)
                    else
                        prompt:InputHoldBegin()
                        task.wait(0.05)
                        prompt:InputHoldEnd()
                    end
                end)
                claimed = claimed + 1
            end
            invokeServerRPC("ClaimCrate", { Crate = crate.Name })
            task.wait(0.18 + State.SafetyPacing)
        end
    end

    if origPos then
        safeTeleport(origPos)
    end
    logMessage(string.format("Selesai klaim %d Lucky Crates!", claimed))
    return claimed
end

local function claimAllGems()
    local gemsFolder = workspace:FindFirstChild("Gems")
    if not gemsFolder then
        logMessage("Gems folder tidak ditemukan.")
        return 0
    end

    local hrp = getRootPart()
    local origPos = hrp and hrp.Position
    local count = 0
    local gems = gemsFolder:GetChildren()
    logMessage(string.format("Memulai pengumpulan %d Gems...", #gems))

    for idx, gem in ipairs(gems) do
        local pos = gem:IsA("Model") and gem:GetPivot().Position or (gem:IsA("BasePart") and gem.Position)
        if pos then
            safeTeleport(pos, Vector3.new(0, 2, 0))
            task.wait(0.12)
            performDig(pos, Vector3.new(0, -1, 0))
            fireServerEvent("Vacuum", { { Id = 1, Material = "Gem", Count = 1, Auto = true } })
            count = count + 1
            task.wait(0.18 + State.SafetyPacing)
        end
    end

    if origPos then
        safeTeleport(origPos)
    end
    logMessage(string.format("Selesai mengumpulkan %d Gems!", count))
    return count
end

local function executeCollectAll()
    logMessage("Menjalankan Collect All (Vacuum + Sync + Crates + Gems)...")
    fireServerEvent("Vacuum", { { Id = 1, Material = "Stone", Count = 50, Auto = true } })
    fireServerEvent("StonesSync", {})
    claimAllCrates()
    claimAllGems()
    logMessage("Collect All selesai!")
end

task.spawn(function()
    while true do
        if State.AutoCrates then
            claimAllCrates()
            task.wait(30)
        else
            task.wait(2)
        end
    end
end)

task.spawn(function()
    while true do
        if State.AutoGems then
            claimAllGems()
            task.wait(45)
        else
            task.wait(2)
        end
    end
end)

-- ══════════════════════════════════════════════════════════════════
-- 12. MODULE 4: AUTO BUY SHOP & UPGRADES
-- ══════════════════════════════════════════════════════════════════
local function attemptBuyTool(toolEntry)
    local cash = getCash()
    if cash < toolEntry.Price then return false end

    -- Coba ProximityPrompt di ToolShopDisplays
    local displays = workspace:FindFirstChild("ToolShopDisplays")
    if displays then
        local disp = displays:FindFirstChild(toolEntry.Display)
        if disp then
            local prompt = disp:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                if fireproximityprompt then
                    fireproximityprompt(prompt, 0)
                else
                    prompt:InputHoldBegin()
                    task.wait(0.05)
                    prompt:InputHoldEnd()
                end
            end
        end
    end

    -- RPC Fallback
    invokeServerRPC("BuyTool", toolEntry.Name)
    logMessage(string.format("Membeli Tool: %s (Harga: %s)", toolEntry.Name, tostring(toolEntry.Price)))
    return true
end

local function attemptBuyHangar2()
    local cash = getCash()
    if cash < 225000 then return false end

    local hangars = workspace:FindFirstChild("HangarPrompts")
    local h2 = hangars and hangars:FindFirstChild("Hangar2")
    if h2 then
        local prompt = h2:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt then
            if fireproximityprompt then
                fireproximityprompt(prompt, 0)
            else
                prompt:InputHoldBegin()
                task.wait(0.05)
                prompt:InputHoldEnd()
            end
        end
    end

    invokeServerRPC("BuyUpgrade", "Hangar2")
    logMessage("Membeli Unlock Hangar 2 (225K Cash)!")
    return true
end

local function attemptBuySpeedMultiplier()
    local beam = workspace:FindFirstChild("SpeedMultiplierShowcase")
    local prompt = beam and beam:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then
        if fireproximityprompt then
            fireproximityprompt(prompt, 0)
        else
            prompt:InputHoldBegin()
            task.wait(0.05)
            prompt:InputHoldEnd()
        end
        logMessage("Membeli Max Speed Multiplier!")
        return true
    end
    return false
end

task.spawn(function()
    while true do
        if State.AutoBuy then
            local cash = getCash()
            if State.BuyPriority == "hangar" and State.AutoBuyHangar and cash >= 225000 then
                attemptBuyHangar2()
                task.wait(1.5)
            end

            -- Beli tool berikutnya yang belum dimiliki
            for _, entry in ipairs(ToolProgression) do
                if cash >= entry.Price and entry.Price > 0 then
                    attemptBuyTool(entry)
                    task.wait(0.6)
                end
            end

            if State.AutoBuySpeed then
                attemptBuySpeedMultiplier()
            end

            task.wait(2.5)
        else
            task.wait(1)
        end
    end
end)

-- ══════════════════════════════════════════════════════════════════
-- 13. MODULE 5: AUTO VEHICLE (EXCAVATOR, TRUCK, M79, UFO)
-- ══════════════════════════════════════════════════════════════════
local function operateVehicleFire(targetPos)
    targetPos = targetPos or Presets[State.VehicleTarget] or Presets.sec9
    local vType = State.VehicleType:lower()

    if vType == "excavator" then
        fireServerEvent("ExcavatorDig", {})
        fireServerEvent("ExcavatorRam", {})
        fireServerEvent("ExcavatorYaw", { Yaw = State.VehicleYaw or 0 })
    elseif vType == "rockettruck" then
        fireServerEvent("RocketTruckFire", { Target = targetPos })
        fireServerEvent("RocketTruckYaw", { Yaw = State.VehicleYaw or 0 })
    elseif vType == "m79" then
        fireServerEvent("M79Fire", { Target = targetPos })
    elseif vType == "ufo" then
        fireServerEvent("UFOLaser", { Target = targetPos })
    end
end

local function exitCurrentVehicle()
    fireServerEvent("ExcavatorExit", {})
    fireServerEvent("UFOExit", {})
    local hum = getHumanoid()
    if hum and hum.SeatPart then
        hum.Sit = false
    end
    logMessage("Keluar dari kendaraan.")
end

task.spawn(function()
    while true do
        if State.AutoVehicle then
            local targetPos = Presets[State.VehicleTarget] or Presets.sec9
            operateVehicleFire(targetPos)
            task.wait(1.0 + State.SafetyPacing)
        else
            task.wait(0.8)
        end
    end
end)

-- ══════════════════════════════════════════════════════════════════
-- 14. MODULE 6: HIGH MOUNTAIN CLIMB
-- ══════════════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        if State.Climb then
            local hrp = getRootPart()
            if hrp then
                local currentPos = hrp.Position
                -- Target naik menuju Peak (Section 9 di Y = 84.8, Z = -1270.7)
                local peakPos = Presets.sec9
                local dirToPeak = (Vector3.new(peakPos.X, currentPos.Y, peakPos.Z) - currentPos).Unit
                local targetStep = currentPos + (dirToPeak * 15) + Vector3.new(0, 8, 0)

                safeTeleport(targetStep)
                task.wait(0.15)

                -- Gali dan bom untuk membuka jalur
                performDig(targetStep - Vector3.new(0, 3, 0), Vector3.new(0, -1, 0))
                fireServerEvent("PlantCharge", { Position = targetStep, Normal = Vector3.new(0, -1, 0) })
                task.wait(0.1)
                fireServerEvent("Detonate", {})

                if (currentPos - peakPos).Magnitude < 40 then
                    logMessage("Selamat! Puncak Gunung (Section 9) tercapai!")
                    State.Climb = false
                end
            end

            local delay = (State.ClimbSpeed == "fast") and 0.4 or ((State.ClimbSpeed == "slow") and 1.2 or 0.7)
            task.wait(delay)
        else
            task.wait(1)
        end
    end
end)

-- ══════════════════════════════════════════════════════════════════
-- 15. MODULE 7: FULL AUTO COMBO MODE
-- ══════════════════════════════════════════════════════════════════
local function setFullAuto(enabled)
    State.FullAuto = enabled
    State.AutoVacuum = enabled
    State.AutoCrates = enabled
    State.AutoGems   = enabled
    State.AutoBuy    = enabled
    State.AutoBuyHangar = enabled
    State.AutoDig    = enabled
    State.DigMode    = "down"
    State.AutoBomb   = enabled
    State.Climb      = enabled

    if enabled then
        setFly(true)
        setNoclip(true)
        logMessage("🔥 FULL AUTO MODE AKTIF! Semua sistem bekerja otomatis berurutan.")
    else
        setFly(false)
        setNoclip(false)
        logMessage("Full Auto Mode dinonaktifkan.")
    end
end

-- Collect All berkala tiap 60 detik saat Full Auto aktif
task.spawn(function()
    while true do
        if State.FullAuto then
            task.wait(60)
            if State.FullAuto then
                executeCollectAll()
            end
        else
            task.wait(3)
        end
    end
end)

-- ══════════════════════════════════════════════════════════════════
-- 16. COMMAND INTERPRETER (; / !)
-- ══════════════════════════════════════════════════════════════════
local function executeCommand(input)
    if not input or type(input) ~= "string" or input == "" then return end
    local clean = input:gsub("^[;/!]", ""):gsub("^%s+", ""):gsub("%s+$", "")
    local parts = {}
    for word in clean:gmatch("%S+") do
        table.insert(parts, word:lower())
    end
    if #parts == 0 then return end

    local cmd = parts[1]
    local arg1 = parts[2]
    local arg2 = parts[3]

    -- 1. Fly
    if cmd == "fly" then
        if arg1 == "on" then setFly(true)
        elseif arg1 == "off" then setFly(false)
        else setFly(not State.Fly) end

    -- 2. Noclip
    elseif cmd == "noclip" then
        if arg1 == "on" then setNoclip(true)
        elseif arg1 == "off" then setNoclip(false)
        else setNoclip(not State.Noclip) end

    -- 3. Speed
    elseif cmd == "speed" then
        local spd = tonumber(arg1) or 16
        setWalkSpeed(spd)

    -- 4. Teleport (tp)
    elseif cmd == "tp" then
        local loc = arg1
        if loc and Presets[loc] then
            safeTeleport(Presets[loc])
            logMessage("Teleport ke preset: " .. loc)
        elseif loc and loc:match("^sec(%d+)$") then
            local num = loc:match("^sec(%d+)$")
            local key = "sec" .. num
            if Presets[key] then
                safeTeleport(Presets[key])
                logMessage("Teleport ke Section " .. num)
            end
        else
            logMessage("Lokasi TP tidak dikenal: " .. tostring(loc))
        end

    -- 5. Goto manual Vector3
    elseif cmd == "goto" then
        local x = tonumber(arg1)
        local y = tonumber(arg2)
        local z = tonumber(parts[4])
        if x and y and z then
            safeTeleport(Vector3.new(x, y, z))
            logMessage(string.format("Teleport ke koordinat (%.1f, %.1f, %.1f)", x, y, z))
        end

    -- 6. CollectAll
    elseif cmd == "collectall" then
        executeCollectAll()

    -- 7. AutoDig
    elseif cmd == "autodig" then
        if arg1 == "on" then State.AutoDig = true logMessage("AutoDig: Aktif")
        elseif arg1 == "off" then State.AutoDig = false logMessage("AutoDig: Nonaktif")
        elseif arg1 == "mode" and arg2 then
            State.DigMode = arg2
            logMessage("AutoDig Mode: " .. arg2)
        elseif arg1 == "speed" and arg2 then
            State.DigSpeed = arg2
            logMessage("AutoDig Speed: " .. arg2)
        elseif arg1 == "height" and tonumber(arg2) then
            State.DigHeight = tonumber(arg2)
            logMessage("AutoDig Height: " .. arg2)
        end

    -- 8. AutoBomb
    elseif cmd == "autobomb" then
        if arg1 == "on" then State.AutoBomb = true logMessage("AutoBomb: Aktif")
        elseif arg1 == "off" then State.AutoBomb = false logMessage("AutoBomb: Nonaktif")
        elseif arg1 == "undo" then undoBomb() end

    -- 9. AutoVacuum, AutoCrates, AutoGems
    elseif cmd == "autovacuum" then
        State.AutoVacuum = (arg1 == "on") or (arg1 ~= "off" and not State.AutoVacuum)
        logMessage("AutoVacuum: " .. (State.AutoVacuum and "Aktif" or "Nonaktif"))
    elseif cmd == "autocrates" then
        State.AutoCrates = (arg1 == "on") or (arg1 ~= "off" and not State.AutoCrates)
        logMessage("AutoCrates: " .. (State.AutoCrates and "Aktif" or "Nonaktif"))
    elseif cmd == "autogems" then
        State.AutoGems = (arg1 == "on") or (arg1 ~= "off" and not State.AutoGems)
        logMessage("AutoGems: " .. (State.AutoGems and "Aktif" or "Nonaktif"))

    -- 10. AutoBuy
    elseif cmd == "autobuy" then
        if arg1 == "on" then State.AutoBuy = true logMessage("AutoBuy Tools: Aktif")
        elseif arg1 == "off" then State.AutoBuy = false logMessage("AutoBuy Tools: Nonaktif")
        elseif arg1 == "hangar" then
            State.AutoBuyHangar = (arg2 == "on")
            logMessage("AutoBuy Hangar: " .. tostring(State.AutoBuyHangar))
        elseif arg1 == "speedmult" then
            State.AutoBuySpeed = (arg2 == "on")
            logMessage("AutoBuy Speed: " .. tostring(State.AutoBuySpeed))
        elseif arg1 == "priority" and arg2 then
            State.BuyPriority = arg2
            logMessage("Buy Priority: " .. arg2)
        end

    -- 11. AutoVehicle
    elseif cmd == "autovehicle" then
        if arg1 == "on" then State.AutoVehicle = true logMessage("AutoVehicle: Aktif")
        elseif arg1 == "off" then State.AutoVehicle = false logMessage("AutoVehicle: Nonaktif")
        elseif arg1 == "type" and arg2 then
            State.VehicleType = arg2
            logMessage("Vehicle Type: " .. arg2)
        elseif arg1 == "target" and arg2 then
            State.VehicleTarget = arg2
            logMessage("Vehicle Target: " .. arg2)
        elseif arg1 == "exit" then exitCurrentVehicle() end

    -- 12. Climb
    elseif cmd == "climb" then
        if arg1 == "on" then State.Climb = true logMessage("Climb: Aktif")
        elseif arg1 == "off" then State.Climb = false logMessage("Climb: Nonaktif")
        elseif arg1 == "speed" and arg2 then
            State.ClimbSpeed = arg2
            logMessage("Climb Speed: " .. arg2)
        elseif arg1 == "vehicle" then
            State.ClimbVehicle = (arg2 == "on")
        end

    -- 13. FullAuto
    elseif cmd == "fullauto" then
        setFullAuto(arg1 == "on" or (arg1 ~= "off" and not State.FullAuto))

    -- 14. Status
    elseif cmd == "status" then
        local _, cashRaw = getCash()
        local _, stoneRaw = getStones()
        logMessage(string.format("STATUS -> Cash: %s | Stones: %s | Tool: %s | AutoDig: %s | FullAuto: %s",
            cashRaw, stoneRaw, getBestOwnedTool(), tostring(State.AutoDig), tostring(State.FullAuto)))
    end
end

-- Listener Chat Roblox untuk command (; ! /)
LocalPlayer.Chatted:Connect(function(msg)
    if msg:sub(1,1) == ";" or msg:sub(1,1) == "!" or msg:sub(1,1) == "/" then
        executeCommand(msg)
    end
end)

-- ══════════════════════════════════════════════════════════════════
-- 17. GUI CREATION (UNIONSAL HUB)
-- ══════════════════════════════════════════════════════════════════
local Window = Unionsal:CreateWindow({
    Title       = "Mountain Excavator (White Summit)",
    SubTitle    = "Full Automation • F Framework • Commands Support",
    GameIcon    = "rbxassetid://10723345518",
    TabWidth    = 160,
    Size        = UDim2.fromOffset(620, 480),
})

-- ── TAB 1: DASHBOARD & STATUS ────────────────────────────────────
local DashTab = Window:CreateTab({ Name = "Dashboard & Status" })

DashTab:CreateSection("Statistik Pemain (Real-Time)")

local CashParagraph = DashTab:CreateParagraph({
    Title = "Data Saldo & Sumber Daya",
    Content = "Memuat data game..."
})

task.spawn(function()
    while true do
        local _, cRaw = getCash()
        local _, sRaw = getStones()
        local hrp = getRootPart()
        local posStr = hrp and string.format("%.1f, %.1f, %.1f", hrp.Position.X, hrp.Position.Y, hrp.Position.Z) or "-"
        pcall(function()
            CashParagraph:Set({
                Title = "Data Saldo & Sumber Daya",
                Content = string.format("💰 Cash: %s  |  🪨 Stones: %s\n📍 Posisi: %s\n🔨 Tool Aktif: %s",
                    cRaw, sRaw, posStr, getBestOwnedTool())
            })
        end)
        task.wait(1.5)
    end
end)

DashTab:CreateSection("Bar Perintah (Command Input)")

DashTab:CreateInput({
    Name = "Jalankan Command (; ! /)",
    PlaceholderText = "Contoh: autodig on, tp sec9, fullauto on",
    RemoveTextOnFocusLost = false,
    Callback = function(text)
        executeCommand(text)
    end,
})

DashTab:CreateButton({
    Name = "Tampilkan Status Lengkap (;status)",
    Callback = function()
        executeCommand("status")
    end,
})

DashTab:CreateSection("Aktivitas & Log Eksekusi")

State.StatusParagraph = DashTab:CreateParagraph({
    Title = "Console / Activity Log",
    Content = "Script siap. Ketik perintah atau aktifkan toggle di tab samping."
})

-- ── TAB 2: EXCAVATION & AUTO DIG ────────────────────────────────
local DigTab = Window:CreateTab({ Name = "Auto Dig & Bom" })

DigTab:CreateSection("Penggalian Otomatis (Auto Dig Loop)")

DigTab:CreateToggle({
    Name = "Auto Dig (Gali Otomatis)",
    CurrentValue = false,
    Callback = function(v)
        State.AutoDig = v
        logMessage("Auto Dig: " .. (v and "Aktif" or "Nonaktif"))
    end,
})

DigTab:CreateDropdown({
    Name = "Mode Arah Penggalian",
    Options = { "down (Bawah Kaki)", "forward (Ke Depan)", "wall (Scan Dinding)", "scan (360° Fan)" },
    CurrentOption = "down (Bawah Kaki)",
    Callback = function(opt)
        local m = opt:match("^(%w+)")
        State.DigMode = m or "down"
        logMessage("Arah Gali diatur ke: " .. State.DigMode)
    end,
})

DigTab:CreateDropdown({
    Name = "Kecepatan Gali",
    Options = { "fast (0.15s - Aman)", "instant (0.05s - Berisiko)" },
    CurrentOption = "fast (0.15s - Aman)",
    Callback = function(opt)
        local s = opt:match("^(%w+)")
        State.DigSpeed = s or "fast"
        logMessage("Kecepatan Gali: " .. State.DigSpeed)
    end,
})

DigTab:CreateSlider({
    Name = "Ketinggian Hover Gali (Studs)",
    Range = { 0, 20 },
    Increment = 1,
    CurrentValue = 5,
    Callback = function(v)
        State.DigHeight = v
    end,
})

DigTab:CreateSection("Peledak & Bom Otomatis (Auto Explosive)")

DigTab:CreateToggle({
    Name = "Auto Bomb (Plant + Detonate Otomatis)",
    CurrentValue = false,
    Callback = function(v)
        State.AutoBomb = v
        logMessage("Auto Bomb: " .. (v and "Aktif" or "Nonaktif"))
    end,
})

DigTab:CreateButton({
    Name = "Batalkan / Undo Peledak Terakhir",
    Callback = function()
        undoBomb()
    end,
})

-- ── TAB 3: LOOT & FARMING ───────────────────────────────────────
local LootTab = Window:CreateTab({ Name = "Loot & Farming" })

LootTab:CreateSection("Penyedot Batu Otomatis (Auto Vacuum)")

LootTab:CreateToggle({
    Name = "Auto Vacuum (Sedot Semua Batu Jarak Jauh)",
    CurrentValue = false,
    Callback = function(v)
        State.AutoVacuum = v
        logMessage("Auto Vacuum: " .. (v and "Aktif" or "Nonaktif"))
    end,
})

LootTab:CreateSection("Koleksi Peti & Permata Otomatis")

LootTab:CreateButton({
    Name = "Klaim Semua 25 Lucky Crates Sekali Klik",
    Callback = function()
        claimAllCrates()
    end,
})

LootTab:CreateToggle({
    Name = "Auto Loop Klaim 25 Lucky Crates",
    CurrentValue = false,
    Callback = function(v)
        State.AutoCrates = v
        logMessage("Auto Crates Loop: " .. (v and "Aktif" or "Nonaktif"))
    end,
})

LootTab:CreateButton({
    Name = "Ambil Semua 18 Gems di Map",
    Callback = function()
        claimAllGems()
    end,
})

LootTab:CreateToggle({
    Name = "Auto Loop Ambil 18 Gems",
    CurrentValue = false,
    Callback = function(v)
        State.AutoGems = v
        logMessage("Auto Gems Loop: " .. (v and "Aktif" or "Nonaktif"))
    end,
})

LootTab:CreateButton({
    Name = "Koleksi Semua (Collect All)",
    Callback = function()
        executeCollectAll()
    end,
})

-- ── TAB 4: SHOP & AUTO BUY ──────────────────────────────────────
local ShopTab = Window:CreateTab({ Name = "Toko & Pembelian" })

ShopTab:CreateSection("Otomatis Beli Tool & Upgrade")

ShopTab:CreateToggle({
    Name = "Auto Buy Tool (Beli Tool Baru Sesuai Saldo)",
    CurrentValue = false,
    Callback = function(v)
        State.AutoBuy = v
        logMessage("Auto Buy Tool: " .. (v and "Aktif" or "Nonaktif"))
    end,
})

ShopTab:CreateToggle({
    Name = "Auto Beli Hangar 2 (Syarat 225K Cash)",
    CurrentValue = false,
    Callback = function(v)
        State.AutoBuyHangar = v
        logMessage("Auto Buy Hangar: " .. (v and "Aktif" or "Nonaktif"))
    end,
})

ShopTab:CreateToggle({
    Name = "Auto Beli Max Speed Multiplier",
    CurrentValue = false,
    Callback = function(v)
        State.AutoBuySpeed = v
        logMessage("Auto Buy Speed Multiplier: " .. (v and "Aktif" or "Nonaktif"))
    end,
})

ShopTab:CreateDropdown({
    Name = "Prioritas Pembelian",
    Options = { "tool (Utamakan Alat Gali)", "hangar (Utamakan Hangar 2)", "speed (Utamakan Speed)" },
    CurrentOption = "tool (Utamakan Alat Gali)",
    Callback = function(opt)
        local p = opt:match("^(%w+)")
        State.BuyPriority = p or "tool"
    end,
})

ShopTab:CreateSection("Beli Manual Instan")

for _, entry in ipairs(ToolProgression) do
    if entry.Price > 0 then
        ShopTab:CreateButton({
            Name = string.format("Beli %s (%s Cash)", entry.Name, tostring(entry.Price)),
            Callback = function()
                attemptBuyTool(entry)
            end,
        })
    end
end

-- ── TAB 5: VEHICLES & HEAVY EQUIPMENT ───────────────────────────
local VehTab = Window:CreateTab({ Name = "Kendaraan Berat" })

VehTab:CreateSection("Kontrol Kendaraan Otomatis (Auto Vehicle)")

VehTab:CreateToggle({
    Name = "Auto Vehicle (Operasikan Mesin Otomatis)",
    CurrentValue = false,
    Callback = function(v)
        State.AutoVehicle = v
        logMessage("Auto Vehicle: " .. (v and "Aktif" or "Nonaktif"))
    end,
})

VehTab:CreateDropdown({
    Name = "Tipe Kendaraan",
    Options = { "excavator (Beko/Gali)", "rockettruck (Truk Roket)", "m79 (Pelontar Granat)", "ufo (Laser UFO)" },
    CurrentOption = "excavator (Beko/Gali)",
    Callback = function(opt)
        local t = opt:match("^(%w+)")
        State.VehicleType = t or "excavator"
        logMessage("Tipe Kendaraan: " .. State.VehicleType)
    end,
})

VehTab:CreateDropdown({
    Name = "Target Section Tembakan",
    Options = { "sec1", "sec2", "sec3", "sec4", "sec5", "sec6", "sec7", "sec8", "sec9 (Puncak)" },
    CurrentOption = "sec9 (Puncak)",
    Callback = function(opt)
        local s = opt:match("^(%w+)")
        State.VehicleTarget = s or "sec9"
        logMessage("Target Kendaraan: " .. State.VehicleTarget)
    end,
})

VehTab:CreateSlider({
    Name = "Rotasi / Yaw Kendaraan (°)",
    Range = { -180, 180 },
    Increment = 5,
    CurrentValue = 0,
    Callback = function(v)
        State.VehicleYaw = v
    end,
})

VehTab:CreateButton({
    Name = "Keluar dari Kendaraan (Exit)",
    Callback = function()
        exitCurrentVehicle()
    end,
})

-- ── TAB 6: MOUNTAIN CLIMB ───────────────────────────────────────
local ClimbTab = Window:CreateTab({ Name = "Pendakian Puncak" })

ClimbTab:CreateSection("Mendaki ke Puncak (High Mountain Climb)")

ClimbTab:CreateToggle({
    Name = "Climb to Peak (Naik Menembus Section ke Puncak)",
    CurrentValue = false,
    Callback = function(v)
        State.Climb = v
        logMessage("Climb: " .. (v and "Aktif" or "Nonaktif"))
    end,
})

ClimbTab:CreateDropdown({
    Name = "Kecepatan Mendaki",
    Options = { "slow (Sangat Aman)", "normal (Stabil)", "fast (Cepat)" },
    CurrentOption = "normal (Stabil)",
    Callback = function(opt)
        local s = opt:match("^(%w+)")
        State.ClimbSpeed = s or "normal"
    end,
})

ClimbTab:CreateButton({
    Name = "Teleport Langsung ke Puncak (Section 9)",
    Callback = function()
        safeTeleport(Presets.sec9)
        logMessage("Teleport langsung ke Puncak (Section 9)!")
    end,
})

-- ── TAB 7: COMBO & FULL AUTO ────────────────────────────────────
local ComboTab = Window:CreateTab({ Name = "Full Auto Mode" })

ComboTab:CreateSection("Full Auto Mode (Semua Fitur Berjalan Bersamaan)")

ComboTab:CreateToggle({
    Name = "FULL AUTO COMBO (Gali + Bom + Sedot + Beli + Naik)",
    CurrentValue = false,
    Callback = function(v)
        setFullAuto(v)
    end,
})

ComboTab:CreateParagraph({
    Title = "Urutan Otomasi Full Auto",
    Content = "1. Auto Vacuum menyedot batu tanpa henti\n2. Auto Crates & Gems diklaim berkala\n3. Auto Buy membeli tool & upgrade saat saldo cukup\n4. Auto Dig & Auto Bomb melubangi gunung\n5. Mendaki otomatis ke Puncak (Section 9)\n6. Collect All dipicu tiap 60 detik"
})

-- ── TAB 8: TELEPORT & PRESETS ───────────────────────────────────
local TpTab = Window:CreateTab({ Name = "Teleportasi Map" })

TpTab:CreateSection("Preset Lokasi Dasar")

local baseList = { "base (Lobby)", "shop (Toko Alat)", "hangar1 (Auto Drills)", "hangar2 (Hangar 2)", "portal (Portal Base)" }
TpTab:CreateDropdown({
    Name = "Pilih Lokasi Utama",
    Options = baseList,
    CurrentOption = "base (Lobby)",
    Callback = function(opt)
        local key = opt:match("^(%w+)")
        if key and Presets[key] then
            safeTeleport(Presets[key])
            logMessage("Teleport ke " .. key)
        end
    end,
})

TpTab:CreateSection("Preset Section Gunung (Progression)")

local secList = {}
for i = 1, 9 do
    table.insert(secList, "sec" .. i .. (i == 9 and " (Puncak / Peak)" or ""))
end

TpTab:CreateDropdown({
    Name = "Lompat ke Section",
    Options = secList,
    CurrentOption = "sec1",
    Callback = function(opt)
        local key = opt:match("^(sec%d+)")
        if key and Presets[key] then
            safeTeleport(Presets[key])
            logMessage("Teleport ke " .. key)
        end
    end,
})

TpTab:CreateSection("Teleport Koordinat Manual")

local manualX, manualY, manualZ = 0, 0, 0
TpTab:CreateInput({
    Name = "Input X, Y, Z",
    PlaceholderText = "Contoh: 343.7, -243.3, 1092.9",
    Callback = function(txt)
        local x, y, z = txt:match("([%d%-%.]+)%s*,%s*([%d%-%.]+)%s*,%s*([%d%-%.]+)")
        if x and y and z then
            manualX, manualY, manualZ = tonumber(x), tonumber(y), tonumber(z)
        end
    end,
})

TpTab:CreateButton({
    Name = "Teleport ke Koordinat Input",
    Callback = function()
        if manualX and manualY and manualZ then
            safeTeleport(Vector3.new(manualX, manualY, manualZ))
            logMessage(string.format("Teleport ke Vector3(%.1f, %.1f, %.1f)", manualX, manualY, manualZ))
        end
    end,
})

-- ── TAB 9: SETTINGS & UTILITIES ─────────────────────────────────
local SetTab = Window:CreateTab({ Name = "Pengaturan & Anti-Kick" })

SetTab:CreateSection("Pergerakan Karakter")

SetTab:CreateToggle({
    Name = "Fly (Terbang Bebas)",
    CurrentValue = false,
    Callback = function(v)
        setFly(v)
    end,
})

SetTab:CreateSlider({
    Name = "Kecepatan Terbang (Fly Speed)",
    Range = { 20, 250 },
    Increment = 5,
    CurrentValue = 75,
    Callback = function(v)
        State.FlySpeed = v
    end,
})

SetTab:CreateToggle({
    Name = "Noclip (Tembus Dinding Gunung)",
    CurrentValue = false,
    Callback = function(v)
        setNoclip(v)
    end,
})

SetTab:CreateSlider({
    Name = "WalkSpeed Karakter",
    Range = { 16, 200 },
    Increment = 2,
    CurrentValue = 16,
    Callback = function(v)
        setWalkSpeed(v)
    end,
})

SetTab:CreateSection("Keamanan & Anti-Kick Safeguards")

SetTab:CreateSlider({
    Name = "Delay Keamanan Jeda Remote (Detik)",
    Range = { 0.05, 0.8 },
    Increment = 0.05,
    CurrentValue = 0.2,
    Callback = function(v)
        State.SafetyPacing = v
        logMessage("Delay Keamanan diatur ke " .. tostring(v) .. "s")
    end,
})

logMessage("Mountain Excavator Script berhasil dimuat!")
