-- ╔══════════════════════════════════════════════════════════════╗
-- ║      UNIONSAL SCRIPT HUB — Cultivation Legends (Obitel)      ║
-- ║   Auto Rebirth • Bagua Circle Cultivation • Smart Sword Fly  ║
-- ║   Auto Herb & Cauldron • Talent Fast Gacha • World Teleport  ║
-- ║      Design: Glass Bento Dark Purple (Unionsal Engine)        ║
-- ╚══════════════════════════════════════════════════════════════╝

getgenv()._UNIONSAL_CHILD_LOADED = true
getgenv()._NEMESIS_CHILD_LOADED = true

local SCRIPT_BASE_URL = "https://raw.githubusercontent.com/hendrawansuinto571-glitch/script/main/"

-- ═══════════════════════════════════════════
--  LOAD UI FRAMEWORK (main.lua)
-- ═══════════════════════════════════════════
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

local Players              = game:GetService("Players")
local RunService           = game:GetService("RunService")
local TweenService         = game:GetService("TweenService")
local UserInputService     = game:GetService("UserInputService")
local HttpService          = game:GetService("HttpService")
local PathfindingService   = game:GetService("PathfindingService")
local ReplicatedStorage    = game:GetService("ReplicatedStorage")
local VirtualUser          = game:GetService("VirtualUser")
local VirtualInputManager  = nil
pcall(function() VirtualInputManager = game:GetService("VirtualInputManager") end)

local LocalPlayer = Players.LocalPlayer

-- ═══════════════════════════════════════════
--  KARAKTER HELPER
-- ═══════════════════════════════════════════
local function getCharacter()
    local char = LocalPlayer.Character
    if char and char.Parent then return char end
    return nil
end

local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getRootPart()
    local char = getCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getPlayerGui()
    return LocalPlayer:FindFirstChildOfClass("PlayerGui")
end

-- ═══════════════════════════════════════════
--  STATE REGISTRY
-- ═══════════════════════════════════════════
local State = {
    -- Cultivation & Rebirth
    AutoRebirth        = false,
    AutoMeditate       = false,
    AutoHerbFarm       = true,
    AutoCauldron       = true,
    AutoDefend         = true,
    QiThreshold        = 99.0,
    RebirthMaxRealm    = 0,
    PreferredSpot      = "Auto (Bagua Circle)",

    -- Movement / Sword Flight
    UseSwordFlight     = true,
    SafeTravel         = true,
    FlySpeed           = 185,
    NaturalHeight      = 26,
    WalkSpeed          = 32,

    -- Event & Festival
    AutoLantern        = false,
    AutoShop           = false,
    ShopItem           = "Sky Lantern Charm",

    -- Talent
    AutoGacha          = false,
    TargetTalent       = "",
    TalentTier         = "Mythic",
    RollDelay          = 0.35,

    -- Teleport
    TeleportMode       = "Smooth Fly (Aman)",
    SelectedIsland     = "",
    SelectedWorldSpot  = "",
    ManualPos          = nil,

    -- Runtime Status
    LoopRunning        = false,
    Step               = "Siap",
    Realm              = "Memuat...",
    RealmIndex         = 1,
    Qi                 = 0,
    Locked             = false,
    LockDepth          = 0,
    LastBaguaPos       = nil,
    LastBaguaName      = "",
}

local LogBuffer = {}

local function log(msg)
    msg = tostring(msg)
    print("[CultivationLegends] " .. msg)
    table.insert(LogBuffer, 1, "• " .. msg)
    while #LogBuffer > 8 do
        table.remove(LogBuffer)
    end
    if State.LogLabel then
        pcall(function()
            State.LogLabel.Text = table.concat(LogBuffer, "\n")
        end)
    end
end

local function clamp(n, lo, hi)
    if n < lo then return lo end
    if n > hi then return hi end
    return n
end

local function flat(v)
    return Vector3.new(v.X, 0, v.Z)
end

-- ═══════════════════════════════════════════
--  DISCOVERY & SHARED MODULES
-- ═══════════════════════════════════════════
local RemoteFolder = ReplicatedStorage:FindFirstChild("Remotes")
local SharedFolder = ReplicatedStorage:FindFirstChild("Shared")

local Remotes = {
    Action     = RemoteFolder and RemoteFolder:FindFirstChild("Action"),
    Meditate   = ReplicatedStorage:FindFirstChild("MeditateEvent"),
    SwordMode  = ReplicatedStorage:FindFirstChild("SwordModeEvent"),
    AuraSelect = ReplicatedStorage:FindFirstChild("AuraSelectEvent"),
}

local ModuleCache = {}

local function safeReq(name)
    if ModuleCache[name] ~= nil then
        if ModuleCache[name] == false then return nil end
        return ModuleCache[name]
    end
    local mod = SharedFolder and SharedFolder:FindFirstChild(name)
    if not mod then
        ModuleCache[name] = false
        return nil
    end
    local ok, res = pcall(function()
        return require(mod)
    end)
    if ok and type(res) == "table" then
        ModuleCache[name] = res
        return res
    end
    ModuleCache[name] = false
    return nil
end

local unpackFn = table.unpack or unpack

local function fireRaw(remote, ...)
    if not remote then return false end
    local args = { ... }
    local n = select("#", ...)
    if remote:IsA("RemoteEvent") then
        local ok = pcall(function()
            remote:FireServer(unpackFn(args, 1, n))
        end)
        return ok
    elseif remote:IsA("RemoteFunction") then
        local ok = pcall(function()
            remote:InvokeServer(unpackFn(args, 1, n))
        end)
        return ok
    end
    return false
end

local function fireAction(actionName, ...)
    if not Remotes.Action then
        Remotes.Action = RemoteFolder and RemoteFolder:FindFirstChild("Action")
    end
    return fireRaw(Remotes.Action, actionName, ...)
end

-- ═══════════════════════════════════════════
--  UI CLICK & PROMPT TRIGGER
-- ═══════════════════════════════════════════
local OurGui = nil

local function usePrompt(prompt)
    if not prompt then return false end
    local ok = pcall(function()
        prompt:InputHoldBegin()
        task.wait(math.min((prompt.HoldDuration or 0.1) + 0.05, 1.0))
        prompt:InputHoldEnd()
    end)
    if not ok then
        pcall(function()
            if fireProximityPrompt then
                fireProximityPrompt(prompt, prompt.ActionText)
            end
        end)
    end
    return ok
end

local function findPromptNear(pos, radius)
    local best, bestDist = nil, radius or 25
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local p = obj.Parent
            local part = p and (p:IsA("BasePart") and p or p:FindFirstChildWhichIsA("BasePart"))
            if part then
                local d = (part.Position - pos).Magnitude
                if d < bestDist then
                    bestDist = d
                    best = obj
                end
            end
        end
    end
    return best, bestDist
end

-- Klik tombol UI game (mendukung TextButton & ImageButton berdasarkan text atau name)
local function clickGui(keywords)
    local pg = getPlayerGui()
    if not pg then return false end

    for _, obj in ipairs(pg:GetDescendants()) do
        if (obj:IsA("TextButton") or obj:IsA("ImageButton")) then
            if not (OurGui and obj:IsDescendantOf(OurGui)) then
                local label = ""
                if obj:IsA("TextButton") and obj.Text ~= "" then
                    label = obj.Text
                else
                    local sub = obj:FindFirstChildWhichIsA("TextLabel", true)
                    label = sub and sub.Text or obj.Name
                end
                local low = string.lower(label)
                local lowName = string.lower(obj.Name)

                for _, kw in ipairs(keywords) do
                    local kwLow = string.lower(kw)
                    if string.find(low, kwLow, 1, true) or string.find(lowName, kwLow, 1, true) then
                        pcall(function() obj:Activate() end)
                        if VirtualInputManager and obj.AbsolutePosition then
                            pcall(function()
                                local pos = obj.AbsolutePosition + obj.AbsoluteSize / 2
                                VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
                                task.wait(0.04)
                                VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
                            end)
                        end
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- ═══════════════════════════════════════════
--  REALM & QI SYSTEM
-- ═══════════════════════════════════════════
local RealmList = {}
local RealmByName = {}

local function buildRealmList()
    RealmList = {}
    RealmByName = {}
    local data = safeReq("Realms")
    if not data then return end

    local entries = {}
    if #data > 0 then
        for i, v in ipairs(data) do
            if type(v) == "string" then
                table.insert(entries, { name = v, order = i, maxQi = nil })
            elseif type(v) == "table" then
                table.insert(entries, {
                    name = v.Name or v.Title or ("Realm " .. i),
                    order = v.Order or v.Tier or v.Level or i,
                    maxQi = v.Qi or v.MaxQi or v.RequiredQi or v.Cost,
                })
            end
        end
    else
        for k, v in pairs(data) do
            if type(k) == "string" then
                if type(v) == "table" then
                    table.insert(entries, {
                        name = v.Name or k,
                        order = v.Order or v.Tier or v.Level or 0,
                        maxQi = v.Qi or v.MaxQi or v.RequiredQi or v.Cost,
                    })
                elseif type(v) == "number" then
                    table.insert(entries, { name = k, order = v, maxQi = v })
                end
            end
        end
    end

    table.sort(entries, function(a, b) return a.order < b.order end)
    for i, e in ipairs(entries) do
        RealmList[i] = { Name = e.name, MaxQi = e.maxQi, Index = i }
        RealmByName[string.lower(e.name)] = i
    end
end

local function attrOf(names)
    local targets = { LocalPlayer, LocalPlayer.Character }
    for _, t in ipairs(targets) do
        if t then
            for _, n in ipairs(names) do
                local ok, v = pcall(function() return t:GetAttribute(n) end)
                if ok and v ~= nil then return v end
            end
        end
    end
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    if ls then
        for _, n in ipairs(names) do
            local v = ls:FindFirstChild(n)
            if v and (v:IsA("IntValue") or v:IsA("NumberValue") or v:IsA("StringValue")) then
                return v.Value
            end
        end
    end
    return nil
end

local function scanHudQi()
    local pg = getPlayerGui()
    if not pg then return nil end
    for _, d in ipairs(pg:GetDescendants()) do
        if d:IsA("TextLabel") and d.Visible then
            local num = tonumber(string.match(d.Text, "(%d+%.?%d*)%s*%%"))
            if num then return num end
        end
    end
    return nil
end

local function readQiPercent()
    local raw = attrOf({ "QiProgress", "CultivationProgress", "Qi", "Progress", "Cultivation" })
    if type(raw) == "number" then
        if raw > 0 and raw <= 1 then return clamp(raw * 100, 0, 100) end
        if raw > 1 and raw <= 100 then return clamp(raw, 0, 100) end
        local idx = State.RealmIndex or 1
        local maxQi = RealmList[idx] and RealmList[idx].MaxQi
        if maxQi and maxQi > 0 then
            return clamp((raw / maxQi) * 100, 0, 100)
        end
    end
    local hud = scanHudQi()
    if hud then return clamp(hud, 0, 100) end
    return State.Qi or 0
end

local function refreshPlayerState()
    local realmText = attrOf({ "Realm", "RealmName", "CultivationRealm", "Rank", "Stage" })
    if type(realmText) == "string" and realmText ~= "" then
        State.Realm = realmText
        local idx = RealmByName[string.lower(realmText)]
        if idx then State.RealmIndex = idx end
    elseif type(realmText) == "number" then
        State.RealmIndex = clamp(math.floor(realmText), 1, math.max(#RealmList, 1))
        State.Realm = RealmList[State.RealmIndex] and RealmList[State.RealmIndex].Name or ("Realm " .. State.RealmIndex)
    elseif #RealmList > 0 then
        State.Realm = RealmList[State.RealmIndex] and RealmList[State.RealmIndex].Name or State.Realm
    else
        State.Realm = State.Realm ~= "Memuat..." and State.Realm or "Kultivator"
    end
    State.Qi = readQiPercent()
    return State.Realm, State.Qi
end

-- ═══════════════════════════════════════════
--  DETEKSI SPOT KULTIVASI / BAGUA CIRCLE (SESUAI FOTO)
-- ═══════════════════════════════════════════
local function partOf(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj end
    return obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
end

-- Mencari Bagua Circle / Qi Gathering spot yang persis seperti pada foto pengguna
local function findBaguaCircles()
    local spots = {}

    -- 1. Scan BillboardGui dengan teks "Qi Gathering", "Bagua", "Court", dsb.
    for _, bb in ipairs(workspace:GetDescendants()) do
        if bb:IsA("BillboardGui") then
            local textAll = ""
            for _, lbl in ipairs(bb:GetDescendants()) do
                if lbl:IsA("TextLabel") then
                    textAll = textAll .. " " .. lbl.Text
                end
            end
            local low = string.lower(textAll)
            if string.find(low, "qi gathering", 1, true) or string.find(low, "bagua", 1, true) or string.find(low, "circle", 1, true) then
                local hostPart = bb.Parent and partOf(bb.Parent)
                if hostPart then
                    local title = "Bagua Circle"
                    for _, lbl in ipairs(bb:GetDescendants()) do
                        if lbl:IsA("TextLabel") and string.find(string.lower(lbl.Text), "bagua", 1, true) then
                            title = lbl.Text
                            break
                        end
                    end
                    table.insert(spots, {
                        Name = title,
                        Position = hostPart.Position,
                        Part = hostPart,
                        Multiplier = tonumber(string.match(low, "x(%d+)%s*qi")) or 3,
                    })
                end
            end
        end
    end

    -- 2. Scan Model / BasePart yang dinamai Bagua / Circle / QiGathering / Altar
    if #spots == 0 then
        local keywords = { "bagua", "qigathering", "outer court", "inner court", "qicircle", "meditationspot" }
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") or obj:IsA("BasePart") then
                local low = string.lower(obj.Name)
                for _, kw in ipairs(keywords) do
                    if string.find(low, kw, 1, true) then
                        local p = partOf(obj)
                        if p then
                            table.insert(spots, {
                                Name = obj.Name,
                                Position = p.Position,
                                Part = p,
                                Multiplier = 3,
                            })
                            break
                        end
                    end
                end
            end
        end
    end

    return spots
end

local function getBestCultivationSpot()
    local circles = findBaguaCircles()
    if #circles > 0 then
        -- Pilih spot dengan multiplier terbaik atau terdekat
        table.sort(circles, function(a, b) return (a.Multiplier or 1) > (b.Multiplier or 1) end)
        State.LastBaguaPos = circles[1].Position
        State.LastBaguaName = circles[1].Name
        return circles[1].Position, circles[1].Name
    end

    -- Fallback ke pulau pribadi
    local obitel = workspace:FindFirstChild("Obitel")
    local islands = obitel and obitel:FindFirstChild("Islands")
    local myIs = islands and islands:FindFirstChild("Island_" .. tostring(LocalPlayer.UserId))
    if myIs then
        local p = partOf(myIs)
        if p then return p.Position, "Pulau Pribadi (Island_" .. LocalPlayer.UserId .. ")" end
    end

    return nil, nil
end

-- ═══════════════════════════════════════════
--  SMART SWORD FLIGHT & NATURAL TRAVEL
-- ═══════════════════════════════════════════
local Flight = {
    Active    = false,
    Velocity  = nil,
    Gyro      = nil,
    Cancelled = false,
}

local function groundY(pos)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local ch = LocalPlayer.Character
    params.FilterDescendantsInstances = ch and { ch } or {}
    local result = workspace:Raycast(pos + Vector3.new(0, 150, 0), Vector3.new(0, -400, 0), params)
    if result then return result.Position.Y end
    return pos.Y
end

local function activateSword()
    -- Aktifkan mode pedang lewat remote resmi game
    if Remotes.SwordMode then
        fireRaw(Remotes.SwordMode, true)
    end

    -- Trigger BindableEvent SwordToggle bila ada
    local ps = LocalPlayer:FindFirstChild("PlayerScripts")
    local clientFolder = ps and ps:FindFirstChild("Client")
    local sf = clientFolder and clientFolder:FindFirstChild("SwordFlight")
    local st = sf and sf:FindFirstChild("SwordToggle")
    if st and st:IsA("BindableEvent") then
        pcall(function() st:Fire(true) end)
    end

    -- Equip pedang dari Backpack bila berupa Tool
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local ch = LocalPlayer.Character
    if bp and ch then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") and string.find(string.lower(t.Name), "sword", 1, true) then
                pcall(function() t.Parent = ch end)
                break
            end
        end
    end
end

local function deactivateSword()
    if Remotes.SwordMode then
        fireRaw(Remotes.SwordMode, false)
    end
    local ps = LocalPlayer:FindFirstChild("PlayerScripts")
    local clientFolder = ps and ps:FindFirstChild("Client")
    local sf = clientFolder and clientFolder:FindFirstChild("SwordFlight")
    local st = sf and sf:FindFirstChild("SwordToggle")
    if st and st:IsA("BindableEvent") then
        pcall(function() st:Fire(false) end)
    end
end

local function stopFlight()
    if Flight.Velocity then
        pcall(function() Flight.Velocity:Destroy() end)
        Flight.Velocity = nil
    end
    if Flight.Gyro then
        pcall(function() Flight.Gyro:Destroy() end)
        Flight.Gyro = nil
    end
    Flight.Active = false
    deactivateSword()

    local hum = getHumanoid()
    if hum then
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Freefall) end)
    end
end

local function startFlight()
    if Flight.Active and Flight.Velocity and Flight.Gyro then return true end
    stopFlight()

    local root = getRootPart()
    local hum = getHumanoid()
    if not root or not hum then return false end

    activateSword()
    task.wait(0.15)
    root = getRootPart()
    if not root then return false end

    local bv = Instance.new("BodyVelocity")
    bv.Name = "CL_FlightVelocity"
    bv.MaxForce = Vector3.new(2e5, 2e5, 2e5)
    bv.Velocity = Vector3.zero
    bv.P = 4000
    bv.Parent = root

    local bg = Instance.new("BodyGyro")
    bg.Name = "CL_FlightGyro"
    bg.MaxTorque = Vector3.new(8e4, 8e4, 8e4)
    bg.P = 4000
    bg.D = 250
    bg.CFrame = root.CFrame
    bg.Parent = root

    Flight.Velocity = bv
    Flight.Gyro = bg
    Flight.Active = true
    return true
end

-- Terbang alami menggunakan pedang menuju koordinat target
local function flyTo(targetPos, arriveDist)
    arriveDist = arriveDist or 7
    Flight.Cancelled = false

    if not startFlight() then return false end
    local root = getRootPart()
    if not root then return false end

    local startPos = root.Position
    local totalDist = (targetPos - startPos).Magnitude
    local groundEnd = groundY(targetPos)
    local cruiseY = math.max(startPos.Y, groundEnd) + State.NaturalHeight

    local steps = clamp(math.ceil(totalDist / 90), 1, 20)
    local waypoints = {}
    for i = 1, steps do
        local t = i / (steps + 1)
        local p = startPos:Lerp(targetPos, t)
        table.insert(waypoints, Vector3.new(p.X, cruiseY, p.Z))
    end
    table.insert(waypoints, Vector3.new(targetPos.X, groundEnd + 3.5, targetPos.Z))

    local speed = clamp(State.FlySpeed, 50, 450)
    local hum = getHumanoid()

    for wIdx, wp in ipairs(waypoints) do
        if Flight.Cancelled then break end
        root = getRootPart()
        if not root then break end

        local wStart = os.clock()
        while true do
            if Flight.Cancelled then break end
            root = getRootPart()
            if not root then break end

            local pos = root.Position
            local delta = wp - pos
            local dist = delta.Magnitude
            if dist <= (wIdx == #waypoints and arriveDist or 10) then break end
            if os.clock() - wStart > math.max(5, (dist / speed) * 5) then break end

            local dir = delta.Unit
            local ramp = clamp(dist * 2.2, 30, speed)

            if Flight.Velocity and Flight.Gyro then
                Flight.Velocity.Velocity = dir * ramp
                Flight.Gyro.CFrame = CFrame.lookAt(pos, pos + flat(delta) + Vector3.new(0, delta.Y * 0.2, 0))
            else
                startFlight()
            end

            if hum then
                pcall(function() hum:ChangeState(Enum.HumanoidStateType.Freefall) end)
            end
            task.wait(0.04)
        end
    end

    if Flight.Velocity then
        Flight.Velocity.Velocity = Vector3.zero
    end
    task.wait(0.2)
    return true
end

-- Jalan kaki fallback via Pathfinding
local function walkTo(targetPos, arriveDist)
    arriveDist = arriveDist or 6
    local hum = getHumanoid()
    local root = getRootPart()
    if not hum or not root then return false end

    hum.WalkSpeed = State.WalkSpeed
    local path = PathfindingService:CreatePath({ AgentRadius = 2.5, AgentHeight = 5, AgentCanJump = true })
    local ok = pcall(function() path:ComputeAsync(root.Position, targetPos) end)
    local waypoints = (ok and path.Status == Enum.PathStatus.Success) and path:GetWaypoints() or { { Position = targetPos } }

    for _, wp in ipairs(waypoints) do
        root = getRootPart()
        if not root then break end
        pcall(function() hum:MoveTo(wp.Position) end)
        local t0 = os.clock()
        while (root.Position - wp.Position).Magnitude > 4.5 and os.clock() - t0 < 6 do
            task.wait(0.1)
            root = getRootPart()
            if not root then break end
        end
    end
    return true
end

-- Menuju lokasi (otomatis pakai Sword Flight jika diaktifkan)
local function travelTo(targetPos, label, arriveDist)
    State.Locked = true
    local prevStep = State.Step
    State.Step = "Menuju " .. (label or "tujuan")
    log("Perjalanan ke: " .. tostring(label))

    local ok = false
    local root = getRootPart()
    if root then
        local dist = (root.Position - targetPos).Magnitude
        if State.UseSwordFlight and dist > 18 then
            ok = flyTo(targetPos, arriveDist or 6)
            if not ok then ok = walkTo(targetPos, arriveDist or 6) end
        else
            ok = walkTo(targetPos, arriveDist or 6)
        end
    end

    stopFlight()
    State.Locked = false
    State.Step = prevStep or "Siap"
    return ok
end

local function instantTeleport(targetPos)
    local root = getRootPart()
    if not root then return false end
    stopFlight()
    local gy = groundY(targetPos)
    root.CFrame = CFrame.new(Vector3.new(targetPos.X, gy + 4, targetPos.Z))
    task.wait(0.3)
    return true
end

-- ═══════════════════════════════════════════
--  MEDITASI
-- ═══════════════════════════════════════════
local MeditateActive = false

local function setMeditate(on)
    if on == MeditateActive then return end
    MeditateActive = on

    if Remotes.Meditate then
        fireRaw(Remotes.Meditate, on)
    end
    fireAction("Meditate", on)

    if on then
        clickGui({ "meditate", "meditasi" })
    else
        fireAction("StopMeditate")
    end
end

-- ═══════════════════════════════════════════
--  HERBAL & CAULDRON (RAMUAN BREAKTHROUGH)
-- ═══════════════════════════════════════════
local Recipes = {}

local function buildRecipes()
    Recipes = {}
    local alch = safeReq("Alchemy")
    if not alch then return end
    for k, v in pairs(alch) do
        if type(v) == "table" then
            local ings = {}
            local rawIngs = v.Ingredients or v.Items or v.Materials or v.Recipe
            if type(rawIngs) == "table" then
                for ingName, count in pairs(rawIngs) do
                    if type(ingName) == "string" then
                        table.insert(ings, { Name = ingName, Count = tonumber(count) or 1 })
                    elseif type(count) == "table" then
                        table.insert(ings, { Name = count.Name or tostring(ingName), Count = tonumber(count.Count or count.Amount) or 1 })
                    end
                end
            end
            table.insert(Recipes, { Name = v.Name or tostring(k), Ingredients = ings })
        end
    end
end

local function countItemInBag(itemName)
    if not itemName or itemName == "" then return 0 end
    local count = 0
    local target = string.lower(itemName):gsub("%s+", "")
    local containers = { LocalPlayer:FindFirstChild("Backpack"), LocalPlayer.Character }
    for _, c in ipairs(containers) do
        if c then
            for _, obj in ipairs(c:GetChildren()) do
                if string.find(string.lower(obj.Name):gsub("%s+", ""), target, 1, true) then
                    count = count + 1
                end
            end
        end
    end
    local attr = attrOf({ itemName })
    if type(attr) == "number" then count = math.max(count, attr) end
    return count
end

local function countPill()
    local p = attrOf({ "BreakthroughPill", "Pill", "Elixir", "BreakthroughElixir" })
    if type(p) == "number" then return p end
    return countItemInBag("Pill") + countItemInBag("Breakthrough")
end

local function findHerbsInWorld()
    local herbs = {}
    local root = getRootPart()
    local origin = root and root.Position or Vector3.zero
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local p = obj.Parent
            local part = p and (p:IsA("BasePart") and p or p:FindFirstChildWhichIsA("BasePart"))
            if part and not (LocalPlayer.Character and part:IsDescendantOf(LocalPlayer.Character)) then
                local low = string.lower(p.Name .. " " .. tostring(obj.ActionText or "") .. " " .. tostring(obj.ObjectText or ""))
                if string.find(low, "herb", 1, true) or string.find(low, "lotus", 1, true) or string.find(low, "flower", 1, true) or string.find(low, "harvest", 1, true) or string.find(low, "plant", 1, true) then
                    table.insert(herbs, {
                        Part = part,
                        Prompt = obj,
                        Dist = (part.Position - origin).Magnitude,
                    })
                end
            end
        end
    end
    table.sort(herbs, function(a, b) return a.Dist < b.Dist end)
    return herbs
end

local function findCauldron()
    local obitel = workspace:FindFirstChild("Obitel")
    local islands = obitel and obitel:FindFirstChild("Islands")
    local myIs = islands and islands:FindFirstChild("Island_" .. tostring(LocalPlayer.UserId))
    local searchArea = myIs or workspace

    for _, obj in ipairs(searchArea:GetDescendants()) do
        if string.find(string.lower(obj.Name), "cauldron", 1, true) or string.find(string.lower(obj.Name), "kuali", 1, true) then
            local p = partOf(obj)
            if p then return p end
        end
    end
    return nil
end

local function brewCauldron()
    local cauldron = findCauldron()
    if not cauldron then
        log("Cauldron tidak ditemukan.")
        return false
    end

    travelTo(cauldron.Position, "Cauldron (Kuali)", 7)
    task.wait(0.3)
    local prompt = findPromptNear(cauldron.Position, 20)
    if prompt then usePrompt(prompt) end
    task.wait(0.4)

    clickGui({ "brew", "craft", "racik", "cauldron", "make" })
    fireAction("Brew")
    fireAction("CraftPill")
    task.wait(0.8)
    clickGui({ "brew", "craft", "confirm", "ya" })
    log("Selesai meracik di Cauldron.")
    return true
end

local function checkAndCraftPill()
    if countPill() > 0 then return true end
    if #Recipes == 0 then buildRecipes() end

    local currentRecipe = Recipes[((State.RealmIndex - 1) % math.max(#Recipes, 1)) + 1]
    if currentRecipe and #currentRecipe.Ingredients > 0 then
        local missing = {}
        for _, ing in ipairs(currentRecipe.Ingredients) do
            local have = countItemInBag(ing.Name)
            if have < ing.Count then
                table.insert(missing, { Name = ing.Name, Need = ing.Count - have })
            end
        end

        if #missing > 0 and State.AutoHerbFarm then
            log("Bahan kurang: " .. missing[1].Name .. " (" .. missing[1].Need .. "x). Mencari herbal...")
            local herbs = findHerbsInWorld()
            for i = 1, math.min(#herbs, 3) do
                travelTo(herbs[i].Part.Position, "Tanaman Herbal", 6)
                task.wait(0.2)
                usePrompt(herbs[i].Prompt)
                fireAction("Harvest", herbs[i].Part.Name)
                task.wait(0.3)
            end
        end
    end

    if State.AutoCauldron then
        brewCauldron()
        return countPill() > 0
    end
    return false
end

-- ═══════════════════════════════════════════
--  REBIRTH / BREAKTHROUGH & ELDER YUN
-- ═══════════════════════════════════════════
local function findElderYun()
    local obitel = workspace:FindFirstChild("Obitel")
    local elder = obitel and obitel:FindFirstChild("ElderYun")
    if elder then
        local p = partOf(elder)
        if p then return p end
    end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if string.find(string.lower(obj.Name), "elderyun", 1, true) or string.find(string.lower(obj.Name), "yun", 1, true) then
            local p = partOf(obj)
            if p then return p end
        end
    end
    return nil
end

local function isTribulating()
    local flag = attrOf({ "Tribulation", "InTribulation", "IsTribulating" })
    if flag == true then return true end
    for _, n in ipairs({ "Tribulation", "TribulationCloud", "HeavenlyTribulation" }) do
        if workspace:FindFirstChild(n) then return true end
    end
    return false
end

local function attemptRebirth()
    local elder = findElderYun()
    if elder then
        travelTo(elder.Position, "Elder Yun (Rebirth)", 7)
        task.wait(0.3)
        local prompt = findPromptNear(elder.Position, 20)
        if prompt then usePrompt(prompt) end
        task.wait(0.4)
        clickGui({ "breakthrough", "terobosan", "rebirth", "ascend", "realm" })
    end

    fireAction("Rebirth")
    fireAction("Breakthrough")
    fireAction("AttemptBreakthrough")
    log("Memicu aksi Breakthrough / Rebirth.")

    local startRealm = State.RealmIndex
    local t0 = os.clock()
    while os.clock() - t0 < 18 do
        if isTribulating() and State.AutoDefend then
            log("Heavenly Tribulation! Bertahan & Meditasi...")
            fireAction("Defend")
            setMeditate(true)
        end
        refreshPlayerState()
        if State.RealmIndex > startRealm then
            log("Berhasil naik ke Realm: " .. State.Realm)
            return true
        end
        task.wait(0.6)
    end
    return State.RealmIndex > startRealm
end

-- ═══════════════════════════════════════════
--  AUTO REBIRTH & CULTIVATION MAIN LOOP
-- ═══════════════════════════════════════════
local function autoRebirthLoop()
    if State.LoopRunning then return end
    State.LoopRunning = true

    while State.AutoRebirth do
        local ok, err = pcall(function()
            refreshPlayerState()
            if State.Locked then return end

            if State.RebirthMaxRealm > 0 and State.RealmIndex >= State.RebirthMaxRealm then
                log("Target Realm (" .. State.Realm .. ") tercapai! Loop berhenti.")
                State.AutoRebirth = false
                return
            end

            local qi = State.Qi or 0
            if qi >= State.QiThreshold then
                State.Step = "Menyiapkan Terobosan"
                setMeditate(false)

                -- Cek dan siapkan pil ramuan
                checkAndCraftPill()

                -- Eksekusi Rebirth di Elder Yun
                State.Step = "Eksekusi Rebirth (Elder Yun)"
                local okUp = attemptRebirth()
                if okUp then
                    log("Breakthrough sukses! Bersiap kultivasi tahap selanjutnya...")
                    task.wait(3.5)
                else
                    log("Breakthrough belum selesai, melanjutkan kultivasi...")
                    task.wait(2.0)
                end
            else
                State.Step = string.format("Kultivasi (Qi %.1f%%)", qi)

                -- Pergi ke Bagua Circle / Spot Kultivasi
                local spotPos, spotName = getBestCultivationSpot()
                if spotPos then
                    local root = getRootPart()
                    if root and (root.Position - spotPos).Magnitude > 16 then
                        travelTo(spotPos, spotName or "Bagua Circle", 6)
                    end
                end

                if not MeditateActive then
                    setMeditate(true)
                end
                task.wait(1.5)
            end
        end)

        if not ok then
            log("Loop error: " .. tostring(err))
            task.wait(2.0)
        end
        task.wait(0.5)
    end

    State.LoopRunning = false
    State.Step = "Siap"
    setMeditate(false)
    stopFlight()
    log("Auto Rebirth dihentikan.")
end

-- ═══════════════════════════════════════════
--  TALENT GACHA FAST ROLL
-- ═══════════════════════════════════════════
local function rollTalentFast()
    -- 1. Klik tombol UI Roll di dalam TalentWindow
    local clicked = clickGui({ "roll", "reroll", "spin", "gacha", "putar", "acak" })

    -- 2. Tembak aksi ke Remote Action
    fireAction("RollTalent")
    fireAction("TalentRoll")
    fireAction("RerollTalent")
    fireAction("Reroll")
    fireAction("Spin")

    -- 3. Cek hasil teks talent
    local pg = getPlayerGui()
    if pg then
        for _, lbl in ipairs(pg:GetDescendants()) do
            if lbl:IsA("TextLabel") and lbl.Visible then
                local low = string.lower(lbl.Text)
                if State.TargetTalent ~= "" and string.find(low, string.lower(State.TargetTalent), 1, true) then
                    return true, lbl.Text
                end
                if State.TalentTier ~= "" and string.find(low, string.lower(State.TalentTier), 1, true) then
                    return true, lbl.Text
                end
            end
        end
    end
    return false, nil
end

local function talentGachaLoop()
    if State.LoopGacha then return end
    State.LoopGacha = true

    -- Buka window talent terlebih dahulu
    clickGui({ "talent", "bakat" })
    task.wait(0.5)

    local count = 0
    while State.AutoGacha do
        local stop = false
        pcall(function()
            local gotTarget, talentName = rollTalentFast()
            count = count + 1
            if gotTarget then
                log("Target Talent Ditemukan: " .. tostring(talentName) .. " (dalam " .. count .. " roll)!")
                State.AutoGacha = false
                stop = true
            end
        end)
        if stop then break end
        task.wait(State.RollDelay or 0.35)
    end
    State.LoopGacha = false
end

-- ═══════════════════════════════════════════
--  EVENT & FESTIVAL (SKY LANTERN & SHOP)
-- ═══════════════════════════════════════════
local function collectSkyLanterns()
    local root = getRootPart()
    local origin = root and root.Position or Vector3.zero
    local lanterns = {}

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not (LocalPlayer.Character and obj:IsDescendantOf(LocalPlayer.Character)) then
            local low = string.lower(obj.Name)
            if string.find(low, "lantern", 1, true) or string.find(low, "lentera", 1, true) then
                table.insert(lanterns, { Part = obj, Dist = (obj.Position - origin).Magnitude })
            end
        end
    end
    table.sort(lanterns, function(a, b) return a.Dist < b.Dist end)

    local collected = 0
    for i = 1, math.min(#lanterns, 8) do
        local l = lanterns[i]
        if l.Part and l.Part.Parent then
            travelTo(l.Part.Position, "Sky Lantern", 8)
            task.wait(0.2)
            local prompt = findPromptNear(l.Part.Position, 16)
            if prompt then usePrompt(prompt) end
            fireAction("CollectLantern", l.Part.Name)
            fireAction("Lantern", l.Part.Name)
            collected = collected + 1
            task.wait(0.3)
        end
    end
    return collected
end

local function buyShopItem(itemName)
    itemName = itemName or State.ShopItem or "Sky Lantern Charm"
    log("Membeli item festival: " .. itemName)

    -- Buka window shop
    clickGui({ "festivalshop", "festival", "shop", "toko" })
    task.wait(0.4)

    -- Klik item target
    clickGui({ itemName, "charm", "sky lantern charm" })
    task.wait(0.2)

    -- Konfirmasi beli
    clickGui({ "buy", "beli", "purchase", "confirm" })
    fireAction("BuyFestivalItem", itemName)
    fireAction("Buy", itemName)
end

-- ═══════════════════════════════════════════
--  TELEPORT & DAFTAR PULAU REAL-TIME
-- ═══════════════════════════════════════════
local IslandTargets = {}
local IslandNames = {}

local function refreshIslands()
    IslandTargets = {}
    IslandNames = {}

    local obitel = workspace:FindFirstChild("Obitel")
    local islands = obitel and obitel:FindFirstChild("Islands")

    -- Tambah pulau pemain sendiri di urutan pertama
    local myIslandName = "Pulau Saya (Island_" .. tostring(LocalPlayer.UserId) .. ")"
    local myIs = islands and islands:FindFirstChild("Island_" .. tostring(LocalPlayer.UserId))
    if myIs then
        local p = partOf(myIs)
        if p then
            IslandTargets[myIslandName] = p.Position
            table.insert(IslandNames, myIslandName)
        end
    end

    -- Tambah pulau pemain lain di server
    if islands then
        for _, island in ipairs(islands:GetChildren()) do
            local pid = tonumber(string.match(island.Name, "%d+"))
            if pid and pid ~= LocalPlayer.UserId then
                local player = Players:GetPlayerByUserId(pid)
                local label = player and ("Pulau " .. player.DisplayName .. " (@" .. player.Name .. ")") or ("Pulau " .. island.Name)
                local p = partOf(island)
                if p then
                    IslandTargets[label] = p.Position
                    table.insert(IslandNames, label)
                end
            end
        end
    end

    -- Tambah spot penting lainnya
    local elder = findElderYun()
    if elder then
        IslandTargets["Elder Yun (Rebirth NPC)"] = elder.Position
        table.insert(IslandNames, "Elder Yun (Rebirth NPC)")
    end

    local cauldron = findCauldron()
    if cauldron then
        IslandTargets["Cauldron (Kuali Ramuan)"] = cauldron.Position
        table.insert(IslandNames, "Cauldron (Kuali Ramuan)")
    end

    local circles = findBaguaCircles()
    for _, c in ipairs(circles) do
        local label = "Bagua Circle: " .. c.Name .. " (x" .. tostring(c.Multiplier) .. " Qi)"
        IslandTargets[label] = c.Position
        table.insert(IslandNames, label)
    end
end

-- ═══════════════════════════════════════════
--  STATUS MONITOR LOOP
-- ═══════════════════════════════════════════
task.spawn(function()
    while true do
        pcall(function()
            refreshPlayerState()
            local hum = getHumanoid()
            if hum and not Flight.Active then
                hum.WalkSpeed = State.WalkSpeed
            end
            if State.StatusLabel then
                State.StatusLabel.Text = string.format(
                    "Realm: %s  |  Qi: %.1f%%  |  Pil: %d  |  Tahap: %s",
                    tostring(State.Realm), tonumber(State.Qi) or 0, countPill(), tostring(State.Step)
                )
            end
        end)
        task.wait(0.8)
    end
end)

-- Anti-AFK
task.spawn(function()
    while true do
        pcall(function()
            local hum = getHumanoid()
            if hum and not MeditateActive and not State.Locked and hum.MoveDirection.Magnitude < 0.1 then
                pcall(function() VirtualUser:CaptureController() end)
                hum.Jump = true
                task.wait(0.1)
                hum.Jump = false
            end
        end)
        task.wait(100)
    end
end)

-- ═══════════════════════════════════════════
--  BUILD UI (UNIONSAL GLASS BENTO - MAIN CATEGORY)
-- ═══════════════════════════════════════════
local Window = Unionsal:CreateWindow({
    Name       = "unionsal",
    Subtitle   = ".gg/unionsal",
    GameName   = "Cultivation Legends",
    ScriptName = "cultivationlegends.lua",
    Version    = "v2.0",
})

OurGui = Window.ScreenGui

buildRealmList()
buildRecipes()
refreshIslands()

local function notify(title, content)
    Window:Notify({ Title = title, Content = content, Duration = 3 })
end

local function safeRun(fn)
    return function(...)
        local ok, err = pcall(fn, ...)
        if not ok then
            log("Error: " .. tostring(err))
            notify("Error", tostring(err))
        end
    end
end

local function createInfoCard(tabObj, height)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, height or 44)
    card.BackgroundColor3 = Color3.fromRGB(22, 17, 34)
    card.BorderSizePixel = 0
    card.Parent = tabObj.Page

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = card

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(44, 36, 62)
    stroke.Thickness = 1
    stroke.Parent = card

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 1, -12)
    label.Position = UDim2.new(0, 10, 0, 6)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Code
    label.TextSize = 11
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.TextColor3 = Color3.fromRGB(180, 120, 255)
    label.Text = ""
    label.Parent = card
    return label
end

-- ═══════════════════════════════════════════
--  TAB 1: CULTIVATION & REBIRTH (CATEGORY: Main)
-- ═══════════════════════════════════════════
local CultTab = Window:CreateTab("Cultivation", "sprout", "Main")
CultTab:CreateSection("Status Ranah Kultivasi")
State.StatusLabel = createInfoCard(CultTab, 44)
State.StatusLabel.Text = "Membaca data kultivasi..."

CultTab:CreateSection("Auto Rebirth Pintar (Sesuai Foto Bagua Circle)")
CultTab:CreateToggle({
    Name = "Auto Rebirth (Otomatis ke Bagua Circle → Ramuan → Elder Yun)",
    CurrentValue = false,
    Callback = function(v)
        State.AutoRebirth = v
        if v then
            notify("Auto Rebirth", "Loop aktif! Karakter otomatis terbang/jalan ke Bagua Circle.")
            task.spawn(autoRebirthLoop)
        else
            notify("Auto Rebirth", "Loop dimatikan.")
        end
    end,
})

CultTab:CreateToggle({
    Name = "Auto Meditate (Meditasi di Bagua Circle / Spot)",
    CurrentValue = false,
    Callback = function(v)
        State.AutoMeditate = v
        if v then
            task.spawn(function()
                local spotPos, spotName = getBestCultivationSpot()
                if spotPos then
                    travelTo(spotPos, spotName or "Bagua Circle", 6)
                end
                setMeditate(true)
            end)
        else
            setMeditate(false)
        end
        notify("Auto Meditate", v and "Meditasi aktif." or "Meditasi nonaktif.")
    end,
})

CultTab:CreateSlider({
    Name = "Ambang Batas Qi untuk Breakthrough",
    Range = { 50, 100 },
    Increment = 1,
    Suffix = "%",
    CurrentValue = 99,
    Callback = function(v)
        State.QiThreshold = v
    end,
})

CultTab:CreateSection("Herbal & Cauldron Otomatis")
CultTab:CreateToggle({
    Name = "Auto Cari Bahan Herbal (Bila Kurang untuk Rebirth)",
    CurrentValue = true,
    Callback = function(v)
        State.AutoHerbFarm = v
    end,
})

CultTab:CreateToggle({
    Name = "Auto Cauldron (Racik Pil Terobosan Otomatis)",
    CurrentValue = true,
    Callback = function(v)
        State.AutoCauldron = v
    end,
})

CultTab:CreateToggle({
    Name = "Auto Defend / Meditasi saat Heavenly Tribulation",
    CurrentValue = true,
    Callback = function(v)
        State.AutoDefend = v
    end,
})

CultTab:CreateSection("Tombol Aksi Cepat")
CultTab:CreateButton({
    Name = "Terbang ke Bagua Circle Sekarang (Spot x3 Qi)",
    Callback = safeRun(function()
        task.spawn(function()
            local spotPos, spotName = getBestCultivationSpot()
            if spotPos then
                travelTo(spotPos, spotName or "Bagua Circle", 6)
                setMeditate(true)
                notify("Bagua Circle", "Tiba di spot kultivasi! Mulai meditasi.")
            else
                notify("Bagua Circle", "Spot tidak terdeteksi.")
            end
        end)
    end),
})

CultTab:CreateButton({
    Name = "Terbang ke Elder Yun (NPC Rebirth)",
    Callback = safeRun(function()
        task.spawn(function()
            local elder = findElderYun()
            if elder then
                travelTo(elder.Position, "Elder Yun", 7)
                notify("Elder Yun", "Tiba di Elder Yun.")
            end
        end)
    end),
})

CultTab:CreateButton({
    Name = "Hentikan Semua Aksi",
    Callback = function()
        State.AutoRebirth = false
        State.AutoMeditate = false
        State.AutoGacha = false
        State.AutoLantern = false
        State.AutoShop = false
        Flight.Cancelled = true
        setMeditate(false)
        stopFlight()
        notify("Stop", "Semua fitur dinonaktifkan.")
    end,
})

-- ═══════════════════════════════════════════
--  TAB 2: MOVEMENT & SWORD FLIGHT (CATEGORY: Main)
-- ═══════════════════════════════════════════
local MoveTab = Window:CreateTab("Movement", "rocket", "Main")
MoveTab:CreateSection("Pengaturan Pedang Terbang (Sword Flight)")

MoveTab:CreateToggle({
    Name = "Gunakan Pedang Terbang untuk Semua Perjalanan",
    CurrentValue = true,
    Callback = function(v)
        State.UseSwordFlight = v
        notify("Sword Flight", v and "Pedang terbang aktif untuk navigasi." or "Mode jalan kaki aktif.")
    end,
})

MoveTab:CreateSlider({
    Name = "Kecepatan Terbang (Studs/s)",
    Range = { 60, 450 },
    Increment = 5,
    Suffix = " studs/s",
    CurrentValue = 185,
    Callback = function(v)
        State.FlySpeed = v
    end,
})

MoveTab:CreateSlider({
    Name = "Ketinggian Terbang Natural",
    Range = { 12, 100 },
    Increment = 2,
    Suffix = " studs",
    CurrentValue = 26,
    Callback = function(v)
        State.NaturalHeight = v
    end,
})

MoveTab:CreateSlider({
    Name = "WalkSpeed (Kecepatan Jalan Kaki)",
    Range = { 16, 100 },
    Increment = 1,
    CurrentValue = 32,
    Callback = function(v)
        State.WalkSpeed = v
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = v end
    end,
})

MoveTab:CreateButton({
    Name = "Aktifkan Pedang Terbang Sekarang",
    Callback = safeRun(function()
        startFlight()
        notify("Sword", "Mode terbang pedang aktif.")
    end),
})

MoveTab:CreateButton({
    Name = "Mendarat & Matikan Pedang",
    Callback = safeRun(function()
        stopFlight()
        notify("Sword", "Mode terbang pedang dimatikan.")
    end),
})

-- ═══════════════════════════════════════════
--  TAB 3: TALENT GACHA FAST ROLL (CATEGORY: Main)
-- ═══════════════════════════════════════════
local TalentTab = Window:CreateTab("Talent Gacha", "gem", "Main")
TalentTab:CreateSection("Fast Roll Talent Otomatis")

TalentTab:CreateDropdown({
    Name = "Pilih Rarity Incaran (Berhenti Jika Dapat)",
    Options = { "Mythic", "Legendary", "Divine", "Immortal", "Godly" },
    CurrentValue = "Mythic",
    Callback = function(v)
        State.TalentTier = v
    end,
})

TalentTab:CreateInput({
    Name = "Target Nama Talent Khusus (Opsional)",
    PlaceholderText = "Contoh: Sword Saint / Immortal Body",
    Callback = function(text)
        State.TargetTalent = text
    end,
})

TalentTab:CreateSlider({
    Name = "Kecepatan Roll (Detik)",
    Range = { 0.1, 1.5 },
    Increment = 0.05,
    Suffix = " s",
    CurrentValue = 0.35,
    Callback = function(v)
        State.RollDelay = v
    end,
})

TalentTab:CreateToggle({
    Name = "Auto Roll Talent (Fast Gacha)",
    CurrentValue = false,
    Callback = function(v)
        State.AutoGacha = v
        if v then
            notify("Talent", "Fast Gacha aktif! Berhenti otomatis bila dapat target.")
            task.spawn(talentGachaLoop)
        else
            notify("Talent", "Fast Gacha dimatikan.")
        end
    end,
})

TalentTab:CreateButton({
    Name = "Roll 1x Sekarang",
    Callback = safeRun(function()
        task.spawn(function()
            local hit, name = rollTalentFast()
            notify("Talent Roll", hit and ("Dapat target: " .. tostring(name)) or "Roll selesai dikirim.")
        end)
    end),
})

-- ═══════════════════════════════════════════
--  TAB 4: EVENT & FESTIVAL (CATEGORY: Main)
-- ═══════════════════════════════════════════
local EventTab = Window:CreateTab("Event Festival", "zap", "Main")
EventTab:CreateSection("Sky Lantern Hunter (Berburu Lentera)")

EventTab:CreateToggle({
    Name = "Auto Ambil Sky Lantern (Terbang Koleksi)",
    CurrentValue = false,
    Callback = function(v)
        State.AutoLantern = v
        if v then
            notify("Lantern", "Berburu lentera aktif.")
            task.spawn(function()
                while State.AutoLantern do
                    collectSkyLanterns()
                    task.wait(3.0)
                end
            end)
        end
    end,
})

EventTab:CreateButton({
    Name = "Ambil Semua Sky Lantern di Map Sekali Jalan",
    Callback = safeRun(function()
        task.spawn(function()
            local n = collectSkyLanterns()
            notify("Lantern", "Selesai mengambil " .. n .. " Sky Lantern.")
        end)
    end),
})

EventTab:CreateSection("Festival Shop (Item Sudah Disediakan)")
EventTab:CreateDropdown({
    Name = "Pilih Item Festival untuk Dibeli",
    Options = { "Sky Lantern Charm", "Sky Lantern Aura", "Festival Token", "Lantern Fire" },
    CurrentValue = "Sky Lantern Charm",
    Callback = function(v)
        State.ShopItem = v
    end,
})

EventTab:CreateButton({
    Name = "Beli Sky Lantern Charm Sekarang",
    Callback = safeRun(function()
        task.spawn(function()
            buyShopItem("Sky Lantern Charm")
            notify("Shop", "Perintah beli Sky Lantern Charm dikirim.")
        end)
    end),
})

EventTab:CreateToggle({
    Name = "Auto Beli Item Festival Terpilih",
    CurrentValue = false,
    Callback = function(v)
        State.AutoShop = v
        if v then
            task.spawn(function()
                while State.AutoShop do
                    buyShopItem(State.ShopItem)
                    task.wait(6.0)
                end
            end)
        end
    end,
})

-- ═══════════════════════════════════════════
--  TAB 5: TELEPORT & DAFTAR PULAU (CATEGORY: Main)
-- ═══════════════════════════════════════════
local TpTab = Window:CreateTab("Teleport", "navigation", "Main")
TpTab:CreateSection("Pilihan Mode Teleport")

TpTab:CreateDropdown({
    Name = "Metode Perjalanan",
    Options = { "Smooth Fly (Aman)", "Instant CFrame" },
    CurrentValue = "Smooth Fly (Aman)",
    Callback = function(v)
        State.TeleportMode = v
    end,
})

TpTab:CreateSection("Akses Cepat Tempat Penting")
TpTab:CreateButton({
    Name = "Teleport ke Pulau Saya",
    Callback = safeRun(function()
        task.spawn(function()
            refreshIslands()
            local myIslandName = "Pulau Saya (Island_" .. tostring(LocalPlayer.UserId) .. ")"
            local pos = IslandTargets[myIslandName]
            if pos then
                if State.TeleportMode == "Instant CFrame" then
                    instantTeleport(pos)
                else
                    travelTo(pos, "Pulau Saya", 6)
                end
                notify("Teleport", "Tiba di Pulau Saya.")
            else
                notify("Teleport", "Pulau belum termuat.")
            end
        end)
    end),
})

TpTab:CreateButton({
    Name = "Teleport ke Outer Court Bagua Circle",
    Callback = safeRun(function()
        task.spawn(function()
            local spotPos, spotName = getBestCultivationSpot()
            if spotPos then
                if State.TeleportMode == "Instant CFrame" then
                    instantTeleport(spotPos)
                else
                    travelTo(spotPos, spotName or "Bagua Circle", 6)
                end
                notify("Teleport", "Tiba di Bagua Circle.")
            end
        end)
    end),
})

TpTab:CreateSection("Daftar Semua Pulau Pemain & Spot")
TpTab:CreateDropdown({
    Name = "Pilih Pulau / Lokasi",
    Options = (#IslandNames > 0 and IslandNames) or { "Memuat pulau..." },
    CurrentValue = (#IslandNames > 0 and IslandNames[1]) or "Memuat pulau...",
    Callback = function(v)
        State.SelectedIsland = v
    end,
})

TpTab:CreateButton({
    Name = "Teleport ke Pulau / Spot Terpilih",
    Callback = safeRun(function()
        local label = State.SelectedIsland
        local pos = IslandTargets[label]
        if pos then
            task.spawn(function()
                if State.TeleportMode == "Instant CFrame" then
                    instantTeleport(pos)
                else
                    travelTo(pos, label, 6)
                end
                notify("Teleport", "Tiba di " .. label)
            end)
        else
            notify("Teleport", "Pilih pulau terlebih dahulu.")
        end
    end),
})

TpTab:CreateButton({
    Name = "Refresh Daftar Pulau di Server",
    Callback = safeRun(function()
        refreshIslands()
        notify("Pulau", "Berhasil memperbarui " .. #IslandNames .. " lokasi.")
    end),
})

-- ═══════════════════════════════════════════
--  TAB 6: DIAGNOSTIK & LOG (CATEGORY: Config)
-- ═══════════════════════════════════════════
local DiagTab = Window:CreateTab("Diagnostik", "activity", "Config")
DiagTab:CreateSection("Log Aktivitas Real-time")
State.LogLabel = createInfoCard(DiagTab, 120)
State.LogLabel.Text = "Belum ada aktivitas."

DiagTab:CreateSection("Pemeriksaan Objek Game")
DiagTab:CreateButton({
    Name = "Pindai Bagua Circle & Spot Sekitar",
    Callback = safeRun(function()
        local circles = findBaguaCircles()
        log("Ditemukan " .. #circles .. " Bagua Circle di Workspace.")
        for i, c in ipairs(circles) do
            log("  #" .. i .. " " .. c.Name .. " (x" .. tostring(c.Multiplier) .. " Qi)")
        end
        local cauldron = findCauldron()
        log("Cauldron: " .. (cauldron and "Ditemukan" or "Tidak ditemukan"))
        local elder = findElderYun()
        log("Elder Yun: " .. (elder and "Ditemukan" or "Tidak ditemukan"))
        refreshIslands()
        log("Total pulau terdeteksi: " .. #IslandNames)
    end),
})

-- ═══════════════════════════════════════════
--  STARTUP NOTIFICATION
-- ═══════════════════════════════════════════
task.spawn(function()
    task.wait(0.5)
    refreshPlayerState()
    log("Inisialisasi selesai. Realm: " .. tostring(State.Realm) .. " (Qi: " .. string.format("%.1f", State.Qi) .. "%)")
    Window:Notify({
        Title = "Unionsal Hub",
        Content = "Cultivation Legends v2.0 Siap! Fitur Bagua Circle & Sword Flight Aktif.",
        Duration = 5,
    })
end)
