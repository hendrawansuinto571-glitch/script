-- ╔══════════════════════════════════════════════════════════════╗
-- ║      UNIONSAL SCRIPT HUB — Cultivation Legends (Obitel)      ║
-- ║   Auto Rebirth • Smart Sword Flight • Auto Herb & Cauldron    ║
-- ║   Sky Lantern Hunter • Talent Fast Gacha • World Teleport     ║
-- ║      Design: Glass Bento Dark Purple (Unionsal Engine)        ║
-- ╚══════════════════════════════════════════════════════════════╝

getgenv()._UNIONSAL_CHILD_LOADED = true
getgenv()._NEMESIS_CHILD_LOADED = true

local SCRIPT_BASE_URL = "https://raw.githubusercontent.com/hendrawansuinto571-glitch/script/main/"

-- Load Unionsal UI Framework dari main.lua (Memory / File / GitHub)
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
local Lighting             = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local VirtualUser = game:GetService("VirtualUser")

-- ═══════════════════════════════════════════
--  KARAKTER HELPER
-- ═══════════════════════════════════════════
local function getCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end
local function getHumanoid()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getRootPart()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

-- ═══════════════════════════════════════════
--  STATE / CONFIG REGISTRY
-- ═══════════════════════════════════════════
local State = {
    -- Cultivation
    AutoRebirth        = false,
    AutoMeditate       = false,
    AutoCauldron       = false,
    AutoHerbFarm       = false,
    AutoDefend         = true,
    RebirthMaxRealm    = 0,      -- 0 = tanpa batas
    QiThreshold        = 99.5,
    -- Movement
    UseSwordFlight     = true,
    SafeTravel         = true,   -- tween / smooth, bukan CFrame lompat
    WalkSpeed          = 34,
    FlySpeed           = 175,
    NaturalHeight      = 28,
    -- Event
    AutoLantern        = false,
    AutoShop           = false,
    ShopItem           = "",
    -- Talent
    AutoGacha          = false,
    TargetTalent       = "",
    TalentTier         = "Mythic",
    RollDelay          = 0.45,
    -- Teleport
    TeleportMode       = "Smooth Fly",
    -- Runtime
    LoopRunning        = false,
    Step               = "idle",
    Realm              = "?",
    RealmIndex         = 1,
    Qi                 = 0,
    Locked             = false,
}

local LogBuffer = {}

-- Nama aksi remote (bisa dikalibrasi lewat tab Diagnostik bila berbeda)
local ActionNames = {
    Meditate   = "Meditate",
    StopMeditate = "StopMeditate",
    Harvest    = "Harvest",
    Brew       = "Brew",
    CraftPill  = "CraftPill",
    Rebirth    = "Rebirth",
    Breakthrough = "Breakthrough",
    Defend     = "Defend",
    CollectLantern = "CollectLantern",
    RollTalent = "RollTalent",
}

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

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function flat(v)
    -- vektor tanpa komponen Y (menghindari tabrakan vertikal saat menghitung arah)
    return Vector3.new(v.X, 0, v.Z)
end

-- ═══════════════════════════════════════════
--  DISCOVERY: REMOTES / SHARED MODULES / KARAKTER MAP
-- ═══════════════════════════════════════════
local RemoteFolder   = ReplicatedStorage:FindFirstChild("Remotes")
local SharedFolder   = ReplicatedStorage:FindFirstChild("Shared")

local Remotes = {
    Action     = RemoteFolder and RemoteFolder:FindFirstChild("Action"),
    Meditate   = ReplicatedStorage:FindFirstChild("MeditateEvent"),
    SwordMode  = ReplicatedStorage:FindFirstChild("SwordModeEvent"),
    AuraSelect = ReplicatedStorage:FindFirstChild("AuraSelectEvent"),
}

local ModuleCache = {}

local function safeReq(name)
    local cached = ModuleCache[name]
    if cached ~= nil then
        if cached == false then return nil end
        return cached
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

-- Kirim aksi ke server (RemoteEvent / RemoteFunction) dengan aman
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

local function fireAction(a, ...)
    if type(a) == "string" and ActionNames[a] and ActionNames[a] ~= "" then
        a = ActionNames[a]
    end
    return fireRaw(Remotes.Action, a, ...)
end

-- Probe berantai: coba beberapa nama aksi, berhenti saat verify() true
local function probeActions(candidates, verify, verifyDelay, totalTimeout)
    verifyDelay = verifyDelay or 1.2
    totalTimeout = totalTimeout or (#candidates * verifyDelay + 1)
    local deadline = os.clock() + totalTimeout
    for _, entry in ipairs(candidates) do
        if os.clock() > deadline then break end
        local a, b = entry[1], entry[2]
        fireAction(a, b)
        local okWatch = task.wait(verifyDelay)
        if verify and verify() then
            log("Aksi diterima: " .. tostring(a))
            return true, a
        end
        if okWatch == nil then break end
    end
    return false, nil
end

-- Klik tombol UI game berdasarkan teks (fallback ketika remote tidak diketahui)
local OurGui = nil

local function guiLabelOf(obj)
    if obj:IsA("TextButton") and obj.Text ~= "" then return obj.Text end
    local lbl = obj:FindFirstChildWhichIsA("TextLabel", true)
    return lbl and lbl.Text or ""
end

local function clickGuiButton(keywords)
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return false end
    for _, obj in ipairs(pg:GetDescendants()) do
        if (obj:IsA("TextButton") or obj:IsA("ImageButton")) and obj.Visible then
            if not (OurGui and obj:IsDescendantOf(OurGui)) then
                local label = guiLabelOf(obj)
                local low = string.lower(label)
                if low ~= "" then
                    for _, kw in ipairs(keywords) do
                        if string.find(low, kw, 1, true) then
                            pcall(function()
                                obj:Activate()
                            end)
                            pcall(function()
                                local vim = game:GetService("VirtualInputManager")
                                local pos = obj.AbsolutePosition + obj.AbsoluteSize / 2
                                vim:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
                                task.wait(0.05)
                                vim:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
                            end)
                            log("Klik UI: " .. label)
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

-- Pemicu ProximityPrompt (harvest / cauldron / NPC)
local function usePrompt(prompt)
    if not prompt then return false end
    local ok = pcall(function()
        prompt:InputHoldBegin()
        task.wait(math.min((prompt.HoldDuration or 0.1) + 0.05, 1.2))
        prompt:InputHoldEnd()
    end)
    if not ok then
        ok = pcall(function()
            fireProximityPrompt(prompt, prompt.ActionText)
        end)
    end
    return ok
end

local function findPromptNear(pos, radius)
    local best, bestDist = nil, radius or 30
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local parentPart = obj.Parent
            if parentPart and parentPart:IsA("BasePart") then
                local d = (parentPart.Position - pos).Magnitude
                if d < bestDist then
                    bestDist = d
                    best = obj
                end
            end
        end
    end
    return best, bestDist
end

-- ═══════════════════════════════════════════
--  DATA REALM (ReplicatedStorage.Shared.Realms)
-- ═══════════════════════════════════════════
local RealmList = {}
local RealmByName = {}

local function numberField(t, keys)
    if type(t) ~= "table" then return nil end
    for _, k in ipairs(keys) do
        local v = t[k]
        if type(v) == "number" then return v end
    end
    return nil
end

local function maxQiOf(t)
    return numberField(t, { "Qi", "QiMax", "MaxQi", "RequiredQi", "QiRequired", "Cost", "Threshold" })
end

local function buildRealmList()
    RealmList = {}
    RealmByName = {}
    local data = safeReq("Realms")
    if not data then return end

    local entries = {}
    if #data > 0 then
        for i, v in ipairs(data) do
            if type(v) == "string" then
                table.insert(entries, { name = v, order = i, qi = nil })
            elseif type(v) == "table" then
                table.insert(entries, {
                    name = v.Name or v.name or v.Title or ("Realm " .. i),
                    order = numberField(v, { "Order", "Index", "Level", "Tier", "Stage" }) or i,
                    qi = maxQiOf(v),
                })
            end
        end
    else
        for k, v in pairs(data) do
            if type(k) == "string" then
                if type(v) == "table" then
                    table.insert(entries, {
                        name = v.Name or k,
                        order = numberField(v, { "Order", "Index", "Level", "Tier", "Stage" }) or numberField(v, { "Qi", "QiMax" }) or 0,
                        qi = maxQiOf(v),
                    })
                elseif type(v) == "number" then
                    table.insert(entries, { name = k, order = v, qi = v })
                else
                    table.insert(entries, { name = k, order = 0, qi = nil })
                end
            end
        end
    end

    table.sort(entries, function(a, b)
        if a.order == b.order then return a.name < b.name end
        return a.order < b.order
    end)

    for i, e in ipairs(entries) do
        RealmList[i] = { Name = e.name, MaxQi = e.qi, Index = i }
        RealmByName[string.lower(e.name)] = i
    end
end

local function realmIndexFromText(text)
    if type(text) ~= "string" then return nil end
    local low = string.lower(text)
    if RealmByName[low] then return RealmByName[low] end
    for i, r in ipairs(RealmList) do
        if string.find(low, string.lower(r.Name), 1, true) then
            return i
        end
    end
    return nil
end

-- ═══════════════════════════════════════════
--  READER: REALM & QI PEMAIN
-- ═══════════════════════════════════════════
local REALM_ATTRS = { "Realm", "realm", "RealmName", "CultivationRealm", "Rank", "Stage", "RealmIndex" }
local QI_ATTRS = { "Qi", "qi", "QiProgress", "CultivationProgress", "Cultivation", "Progress", "Exp", "XP" }
local PILL_ATTRS = { "BreakthroughPill", "Pill", "Elixir", "BreakthroughElixir" }

local function attrOf(names)
    local targets = { LocalPlayer }
    local ch = LocalPlayer.Character
    if ch then table.insert(targets, ch) end
    for _, t in ipairs(targets) do
        for _, n in ipairs(names) do
            local ok, v = pcall(function()
                return t:GetAttribute(n)
            end)
            if ok and v ~= nil then return v, n end
        end
    end
    local stats = LocalPlayer:FindFirstChild("leaderstats")
    if stats then
        for _, n in ipairs(names) do
            local v = stats:FindFirstChild(n)
            if v and (v:IsA("IntValue") or v:IsA("NumberValue")) then
                return v.Value, n
            end
        end
    end
    return nil, nil
end

local function scanHudQi()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local best, bestScore = nil, 0
    for _, d in ipairs(pg:GetDescendants()) do
        if d:IsA("TextLabel") then
            local num = tonumber(string.match(d.Text, "(%d+%.?%d*)%s*%%"))
            if num then
                local score = 1
                local node = d
                for _ = 1, 4 do
                    if node.Parent then
                        local low = string.lower(node.Name)
                        if string.find(low, "qi") or string.find(low, "prog") or string.find(low, "cultiv") then
                            score = score + 3
                        end
                        node = node.Parent
                    end
                end
                if score >= bestScore then
                    bestScore = score
                    best = num
                end
            end
        end
    end
    return best
end

local function readQiPercent()
    local raw = attrOf(QI_ATTRS)
    if type(raw) == "number" then
        local idx = State.RealmIndex or 1
        local maxQi = RealmList[idx] and RealmList[idx].MaxQi
        if maxQi and maxQi > 0 then
            return clamp((raw / maxQi) * 100, 0, 100)
        end
        if raw > 0 and raw <= 1 then return clamp(raw * 100, 0, 100) end
        return clamp(raw, 0, 100)
    end
    local hud = scanHudQi()
    if hud then return clamp(hud, 0, 100) end
    return State.Qi or 0
end

local function refreshPlayerState()
    local realmText = attrOf(REALM_ATTRS)
    if type(realmText) == "number" then
        State.RealmIndex = clamp(math.floor(realmText), 1, math.max(#RealmList, 1))
        State.Realm = RealmList[State.RealmIndex] and RealmList[State.RealmIndex].Name or tostring(realmText)
    elseif type(realmText) == "string" then
        local idx = realmIndexFromText(realmText)
        State.RealmIndex = idx or State.RealmIndex
        State.Realm = realmText
    elseif #RealmList > 0 then
        State.Realm = RealmList[State.RealmIndex] and RealmList[State.RealmIndex].Name or State.Realm
    else
        State.Realm = State.Realm ~= "?" and State.Realm or "Tidak terbaca"
    end
    State.Qi = readQiPercent()
    return State.Realm, State.Qi
end

-- ═══════════════════════════════════════════
--  READER: INVENTORY / RESEP / PIL
-- ═══════════════════════════════════════════
local function normalizeName(n)
    return string.lower(tostring(n)):gsub("%s+", "")
end

local function countItem(itemName)
    if not itemName or itemName == "" then return 0 end
    local target = normalizeName(itemName)
    local total = 0
    local containers = { LocalPlayer:FindFirstChild("Backpack"), LocalPlayer.Character }
    for _, c in ipairs(containers) do
        if c then
            for _, obj in ipairs(c:GetChildren()) do
                if obj:IsA("Tool") and string.find(normalizeName(obj.Name), target, 1, true) then
                    total = total + 1
                end
            end
        end
    end
    local attr, _ = attrOf({ itemName })
    if type(attr) == "number" then total = math.max(total, attr) end
    return total
end

local function countPill()
    for _, n in ipairs(PILL_ATTRS) do
        local v = attrOf({ n })
        if type(v) == "number" then return v end
    end
    for _, candidate in ipairs({ "Breakthrough Pill", "Breakthrough Elixir", "Terobosan", "Pil Terobosan" }) do
        local c = countItem(candidate)
        if c > 0 then return c end
    end
    return 0
end

local Recipes = {}

local function buildRecipes()
    Recipes = {}
    local alch = safeReq("Alchemy")
    if not alch then return end
    local function collectIngredients(entry)
        local list = {}
        for _, key in ipairs({ "Ingredients", "Items", "Reagents", "Materials", "Recipe", "Ingredient" }) do
            local v = entry[key]
            if type(v) == "table" then
                for k, val in pairs(v) do
                    if type(k) == "string" then
                        table.insert(list, { Name = k, Count = type(val) == "number" and val or 1 })
                    elseif type(val) == "string" then
                        table.insert(list, { Name = val, Count = 1 })
                    elseif type(val) == "table" then
                        table.insert(list, { Name = val.Name or val.name or val.Item or "?", Count = tonumber(val.Count or val.Amount) or 1 })
                    end
                end
            end
        end
        return list
    end
    for k, v in pairs(alch) do
        if type(v) == "table" then
            local ings = collectIngredients(v)
            if #ings > 0 then
                table.insert(Recipes, { Name = v.Name or v.Pill or tostring(k), Ingredients = ings, Result = v.Result or v.Output or v.Name })
            end
        end
    end
end

local function recipeForRealm(index)
    if #Recipes == 0 then return nil end
    return Recipes[((index - 1) % #Recipes) + 1]
end

local function ingredientsReady(recipe)
    if not recipe then return false end
    for _, ing in ipairs(recipe.Ingredients) do
        if countItem(ing.Name) < ing.Count then return false end
    end
    return true
end

-- ═══════════════════════════════════════════
--  WORLD LOOKUP (pulau, NPC, cauldron, lotus, herbal)
-- ═══════════════════════════════════════════
local function isValidPart(p)
    return p and p:IsA("BasePart")
end

local function partOf(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj end
    return obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
end

local function findFirstByNames(names, parent, deep)
    parent = parent or workspace
    local lowSet = {}
    for _, n in ipairs(names) do
        lowSet[string.lower(n)] = true
    end
    local list = deep and parent:GetDescendants() or parent:GetChildren()
    local function matches(low)
        if lowSet[low] then return true end
        for key in pairs(lowSet) do
            if string.find(low, key, 1, true) then return true end
        end
        return false
    end
    for _, obj in ipairs(list) do
        if matches(string.lower(obj.Name)) then
            local p = partOf(obj)
            if p then return obj, p end
        end
    end
    return nil, nil
end

local function findByKeyword(keywords, minSize)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local low = string.lower(obj.Name)
            for _, kw in ipairs(keywords) do
                if string.find(low, kw, 1, true) then
                    if not minSize or (obj.Size.X + obj.Size.Y + obj.Size.Z) > minSize then
                        return obj
                    end
                end
            end
        end
    end
    return nil
end

local function myIsland()
    local obitel = workspace:FindFirstChild("Obitel")
    local islands = obitel and obitel:FindFirstChild("Islands")
    if not islands then return nil end
    local target = "Island_" .. tostring(LocalPlayer.UserId)
    return islands:FindFirstChild(target)
end

local function elderYun()
    local obitel = workspace:FindFirstChild("Obitel")
    return obitel and obitel:FindFirstChild("ElderYun")
end

local function groundY(pos)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local ch = LocalPlayer.Character
    params.FilterDescendantsInstances = ch and { ch } or {}
    local result = workspace:Raycast(pos + Vector3.new(0, 200, 0), Vector3.new(0, -500, 0), params)
    if result then return result.Position.Y end
    return pos.Y
end

local function safeStandPosition(pos, height)
    return Vector3.new(pos.X, groundY(pos) + (height or 4), pos.Z)
end

-- ═══════════════════════════════════════════
--  TRAVEL: SWORD FLIGHT & PATHFINDING WALK
-- ═══════════════════════════════════════════
local Travel = {
    Flying     = false,
    Velocity   = nil,
    Gyro       = nil,
    Cancelled  = false,
    SwordOwned = false,
    SwordCheck = 0,
}

local SWORD_HINTS = { "sword", "pedang", "flying", "fly" }

local function hasFlyingSword()
    if os.clock() - Travel.SwordCheck < 5 then
        return Travel.SwordOwned
    end
    Travel.SwordCheck = os.clock()
    Travel.SwordOwned = false

    local data = safeReq("FlyingSword")
    if data then
        for k, v in pairs(data) do
            if type(k) == "string" and string.find(string.lower(k), "name") and type(v) == "string" then
                table.insert(SWORD_HINTS, string.lower(v))
            end
            if type(v) == "string" then
                table.insert(SWORD_HINTS, string.lower(v))
            end
        end
    end

    local containers = { LocalPlayer:FindFirstChild("Backpack"), LocalPlayer.Character }
    for _, c in ipairs(containers) do
        if c then
            for _, obj in ipairs(c:GetChildren()) do
                if obj:IsA("Tool") then
                    local low = string.lower(obj.Name)
                    for _, hint in ipairs(SWORD_HINTS) do
                        if string.find(low, hint, 1, true) then
                            Travel.SwordOwned = true
                            return true
                        end
                    end
                end
            end
        end
    end
    local flag = attrOf({ "HasFlyingSword", "FlyingSword", "SwordFlight" })
    if flag == true or type(flag) == "string" then
        Travel.SwordOwned = true
    end
    return Travel.SwordOwned
end

local function stopBodyMovers()
    if Travel.Velocity then
        pcall(function() Travel.Velocity:Destroy() end)
        Travel.Velocity = nil
    end
    if Travel.Gyro then
        pcall(function() Travel.Gyro:Destroy() end)
        Travel.Gyro = nil
    end
end

local function endFlight()
    if not Travel.Flying then return end
    Travel.Flying = false
    pcall(function()
        fireRaw(Remotes.SwordMode, false)
    end)
    local hum = getHumanoid()
    if hum then
        pcall(function()
            hum:ChangeState(Enum.HumanoidStateType.Freefall)
        end)
    end
    task.wait(0.15)
    stopBodyMovers()
end

local function ensureFlight()
    if Travel.Flying and Travel.Velocity and Travel.Gyro then return true end
    Travel.Flying = false
    local root, hum = getRootPart(), getHumanoid()
    if not root or not hum then return false end
    if not hasFlyingSword() then return false end

    pcall(function()
        fireRaw(Remotes.SwordMode, true)
    end)
    task.wait(0.25)
    if not getRootPart() then return false end
    root = getRootPart()

    local bv = Instance.new("BodyVelocity")
    bv.Name = "CL_FlyVelocity"
    bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bv.Velocity = Vector3.zero
    bv.P = 3000
    bv.Parent = root

    local bg = Instance.new("BodyGyro")
    bg.Name = "CL_FlyGyro"
    bg.MaxTorque = Vector3.new(4e4, 4e4, 4e4)
    bg.P = 3000
    bg.D = 200
    bg.CFrame = root.CFrame
    bg.Parent = root

    Travel.Velocity = bv
    Travel.Gyro = bg
    Travel.Flying = true
    return true
end

-- Terbang mulus mengikuti waypoint (aman & natural, tanpa lompatan CFrame)
local function flyTo(targetPos, arriveDist)
    arriveDist = arriveDist or 7
    Travel.Cancelled = false
    if not ensureFlight() then return false end

    local root = getRootPart()
    if not root then return false end

    local startPos = root.Position
    local totalDist = (targetPos - startPos).Magnitude
    local groundTarget = groundY(targetPos)
    local cruiseY = math.max(startPos.Y, groundTarget) + State.NaturalHeight
    local waypoints = {}
    local steps = clamp(math.ceil(totalDist / 110), 1, 24)

    for i = 1, steps do
        local t = i / (steps + 1)
        local p = startPos:Lerp(targetPos, t)
        local wobble = math.sin(i * 1.7) * 5 + math.random(-3, 3)
        table.insert(waypoints, Vector3.new(p.X, cruiseY + wobble, p.Z))
    end
    table.insert(waypoints, safeStandPosition(targetPos, 6))

    local speed = clamp(State.FlySpeed, 40, 600)
    local hum = getHumanoid()

    for wIndex, wp in ipairs(waypoints) do
        if Travel.Cancelled then break end
        if not getRootPart() then break end
        local wStart = os.clock()
        local lastPos = getRootPart().Position
        local stuck = 0
        while true do
            if Travel.Cancelled then break end
            root = getRootPart()
            if not root then break end
            local pos = root.Position
            local delta = wp - pos
            local dist = delta.Magnitude
            if dist <= (wIndex == #waypoints and arriveDist or 9) then break end

            if os.clock() - wStart > math.max(6, (dist / speed) * 6) then break end
            if (pos - lastPos).Magnitude < 0.4 then
                stuck = stuck + 1
                if stuck > 90 then break end
            else
                stuck = 0
            end
            lastPos = pos

            local dir = delta.Unit
            if wIndex < #waypoints then
                local minY = groundY(pos) + State.NaturalHeight * 0.55
                if pos.Y < minY then dir = (dir + Vector3.new(0, 0.9, 0)).Unit end
            end

            local ramp = clamp(dist * 2, 25, speed)
            if not Travel.Velocity or not Travel.Gyro then
                stopBodyMovers()
                if not ensureFlight() then break end
            end
            Travel.Velocity.Velocity = dir * ramp
            Travel.Gyro.CFrame = CFrame.lookAt(pos, pos + flat(delta) + Vector3.new(0, delta.Y * 0.25, 0))
            if hum then
                pcall(function()
                    hum:ChangeState(Enum.HumanoidStateType.Freefall)
                end)
            end
            task.wait(0.05)
        end
    end

    if Travel.Velocity then
        Travel.Velocity.Velocity = Vector3.zero
    end
    task.wait(0.25)
    return true
end

-- Jalan kaki natural via PathfindingService
local function walkTo(targetPos, arriveDist)
    arriveDist = arriveDist or 6
    Travel.Cancelled = false
    local hum, root = getHumanoid(), getRootPart()
    if not hum or not root then return false end

    hum.WalkSpeed = State.WalkSpeed
    local path = PathfindingService:CreatePath({
        AgentRadius = 2.5,
        AgentHeight = 5,
        AgentCanJump = true,
        WaypointSpacing = 8,
    })

    local okPath = pcall(function()
        path:ComputeAsync(root.Position, targetPos)
    end)
    local waypoints
    if okPath and path.Status == Enum.PathStatus.Success then
        waypoints = path:GetWaypoints()
    else
        waypoints = {
            { Position = targetPos, Action = Enum.PathWaypointAction.Jump },
        }
    end

    for _, wp in ipairs(waypoints) do
        if Travel.Cancelled then break end
        local r = getRootPart()
        if not r then break end
        if wp.Action == Enum.PathWaypointAction.Jump then
            pcall(function() hum.Jump = true end)
        end
        pcall(function()
            hum:MoveTo(wp.Position)
        end)
        local startT = os.clock()
        while true do
            if Travel.Cancelled then break end
            r = getRootPart()
            if not r then break end
            if (r.Position - wp.Position).Magnitude <= 4 then break end
            if os.clock() - startT > 8 then break end
            task.wait(0.12)
        end
    end

    pcall(function()
        hum:MoveTo(targetPos)
    end)
    local t0 = os.clock()
    while os.clock() - t0 < 3 do
        local r = getRootPart()
        if not r or (r.Position - targetPos).Magnitude <= arriveDist then break end
        if Travel.Cancelled then break end
        task.wait(0.15)
    end
    pcall(function() hum:MoveTo(root.Position) end)
    hum.WalkSpeed = State.WalkSpeed
    return true
end

-- Titik akhir selalu di atas permukaan tanah
local function travelTo(targetPos, opts)
    opts = opts or {}
    State.LockDepth = (State.LockDepth or 0) + 1
    State.Locked = true
    local prevStep = State.Step
    State.Step = "travel ke " .. (opts.Label or "tujuan")
    local ok = false

    local okRun, err = pcall(function()
        local root = getRootPart()
        if not root then return end
        local stand = safeStandPosition(targetPos, opts.Height or 5)
        if State.UseSwordFlight and hasFlyingSword() and (root.Position - stand).Magnitude > 22 then
            ok = flyTo(Vector3.new(targetPos.X, groundY(targetPos), targetPos.Z), opts.Arrive)
            if not ok then
                ok = walkTo(stand, opts.Arrive)
            end
        else
            ok = walkTo(stand, opts.Arrive)
        end
    end)
    if not okRun then
        log("Travel error: " .. tostring(err))
    end

    pcall(function()
        if Travel.Flying then endFlight() end
    end)
    State.LockDepth = math.max((State.LockDepth or 1) - 1, 0)
    if State.LockDepth == 0 then
        State.Locked = false
        State.Step = prevStep or "idle"
    end
    return ok
end

local function instantTeleport(targetPos)
    local root = getRootPart()
    if not root then return false end
    if Travel.Flying then endFlight() end
    local stand = safeStandPosition(targetPos, 5)
    pcall(function()
        root.CFrame = CFrame.new(stand)
    end)
    local hum = getHumanoid()
    if hum then
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Freefall) end)
    end
    task.wait(0.35)
    return true
end

-- ═══════════════════════════════════════════
--  MEDITASI
-- ═══════════════════════════════════════════
local MEDITATE_SPOTS = { "Lotus", "MeditationStone", "Meditation", "MeditateSpot", "SitSpot", "Cushion", "JadeLotus", "QiSpot" }
local MeditateActive = false

local function findMeditationSpot()
    local island = myIsland()
    if island then
        local obj, p = findFirstByNames(MEDITATE_SPOTS, island, true)
        if p then return p.Position, "pulau pribadi: " .. obj.Name end
    end
    local lotusData = safeReq("Lotus")
    if lotusData then
        for k, v in pairs(lotusData) do
            if type(v) == "table" then
                local pos = v.Position or v.CFrame or v.Spot or v.Pos
                if typeof and typeof(pos) == "Vector3" then return pos, "Shared.Lotus." .. k end
                if typeof and typeof(pos) == "CFrame" then return pos.Position, "Shared.Lotus." .. k end
            elseif typeof and typeof(v) == "Vector3" then
                return v, "Shared.Lotus." .. tostring(k)
            end
        end
    end
    local part = findByKeyword(MEDITATE_SPOTS)
    if part then return part.Position, part.Name end
    return nil, nil
end

local function setMeditate(on)
    if on == MeditateActive then return end
    MeditateActive = on
    fireRaw(Remotes.Meditate, on)
    if on then
        fireAction("Meditate", true)
        clickGuiButton({ "meditate", "meditasi" })
    else
        fireAction("StopMeditate")
        fireAction("Meditate", false)
    end
end

-- ═══════════════════════════════════════════
--  HERBAL & CAULDRON
-- ═══════════════════════════════════════════
local HERB_HINTS = { "herb", "lotus", "flower", "mushroom", "ginseng", "root", "leaf", "vine", "grass", "bloom", "petal", "seed", "spirit", "fern", "bud", "sprout", "weed" }
local HARVEST_HINTS = { "harvest", "collect", "pick", "petik", "ambil" }
local CAULDRON_NAMES = { "Cauldron", "Kuali", "Alchemy", "BrewPot", "PotionStand", "CauldronStand" }

local HerbHintCache = nil

local function herbNameList()
    if HerbHintCache then return HerbHintCache end
    local names = {}
    safeReq("Alchemy")
    for _, recipe in ipairs(Recipes) do
        for _, ing in ipairs(recipe.Ingredients) do
            table.insert(names, ing.Name)
        end
    end
    local items = safeReq("Items")
    if items then
        for k, v in pairs(items) do
            local n = type(k) == "string" and k or (type(v) == "table" and (v.Name or v.DisplayName)) or nil
            if type(n) == "string" then
                local low = string.lower(n)
                for _, hint in ipairs(HERB_HINTS) do
                    if string.find(low, hint, 1, true) then
                        table.insert(names, n)
                        break
                    end
                end
            end
        end
    end
    HerbHintCache = names
    return names
end

local function isHerbObject(obj, prompt)
    local low = string.lower(obj.Name)
    for _, hint in ipairs(HERB_HINTS) do
        if string.find(low, hint, 1, true) then return true end
    end
    for _, name in ipairs(herbNameList()) do
        if low == string.lower(name) or string.find(low, string.lower(name), 1, true) then return true end
    end
    if prompt then
        local label = string.lower(tostring(prompt.ObjectText or "") .. " " .. tostring(prompt.ActionText or ""))
        for _, hint in ipairs(HARVEST_HINTS) do
            if string.find(label, hint, 1, true) then return true end
        end
        if string.find(label, "herb", 1, true) or string.find(label, "plant", 1, true) then return true end
    end
    return false
end

local function findHerbs(limit)
    local root = getRootPart()
    local origin = root and root.Position or Vector3.zero
    local ch = LocalPlayer.Character
    local found = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local host = obj.Parent
            local p = partOf(host)
            if p and (not ch or not host:IsDescendantOf(ch)) then
                if isHerbObject(host, obj) then
                    table.insert(found, { part = p, prompt = obj, dist = (p.Position - origin).Magnitude })
                end
            end
        end
    end
    table.sort(found, function(a, b) return a.dist < b.dist end)
    if limit then
        while #found > limit do table.remove(found) end
    end
    return found
end

local function findCauldron()
    local island = myIsland()
    local obj, p = findFirstByNames(CAULDRON_NAMES, island or workspace, true)
    if p then return p end
    local part = findByKeyword({ "cauldron", "kuali" }, 4)
    return part
end

local function harvestOne(entry)
    if not entry or not entry.part then return false end
    travelTo(entry.part.Position, { Label = "tanaman herbal", Arrive = 6 })
    task.wait(math.random(2, 4) / 10)
    local prompt = entry.prompt
    if not prompt or not prompt.Parent then
        prompt = findPromptNear(entry.part.Position, 12)
    end
    usePrompt(prompt)
    fireAction("Harvest", entry.part.Name)
    task.wait(0.35)
    return true
end

local function brewAtCauldron()
    local cauldron = findCauldron()
    if not cauldron then
        log("Cauldron tidak ditemukan di map.")
        return false
    end
    travelTo(cauldron.Position, { Label = "cauldron", Arrive = 8 })
    task.wait(0.4)
    local prompt = findPromptNear(cauldron.Position, 20)
    if prompt then usePrompt(prompt) end
    task.wait(0.6)
    if not clickGuiButton({ "brew", "racik", "craft", "cauldron" }) then
        fireAction("Brew")
        task.wait(0.4)
        fireAction("CraftPill")
    end
    task.wait(0.8)
    clickGuiButton({ "brew", "racik", "craft" })
    log("Percobaan meracik pil terobosan selesai.")
    return true
end

-- ═══════════════════════════════════════════
--  REBIRTH / TRIBULATION
-- ═══════════════════════════════════════════
local TRIBULATION_ATTRS = { "Tribulation", "IsTribulating", "InTribulation", "Tribulating", "TribulationActive" }

local function isTribulating()
    local v = attrOf(TRIBULATION_ATTRS)
    if v == true then return true end
    for _, n in ipairs({ "Tribulation", "TribulationCloud", "HeavenlyTribulation", "TribulationZone" }) do
        if workspace:FindFirstChild(n) then return true end
    end
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then
        for _, d in ipairs(pg:GetDescendants()) do
            if d:IsA("TextLabel") and string.find(string.lower(d.Text), "tribulation", 1, true) then
                local p = d.Parent
                if p and p.Visible ~= false then return true end
            end
        end
    end
    return false
end

local function attemptRebirth()
    local npc = elderYun()
    local targetPos = npc and partOf(npc) and partOf(npc).Position
    if targetPos then
        travelTo(targetPos, { Label = "Elder Yun", Arrive = 8 })
        task.wait(0.4)
        local prompt = findPromptNear(targetPos, 22)
        if prompt then usePrompt(prompt) end
        task.wait(0.5)
        clickGuiButton({ "breakthrough", "rebirth", "terobosan", "ascend", "realm" })
    end
    fireAction("Rebirth")
    task.wait(0.35)
    fireAction("Breakthrough")
    log("Menembak aksi rebirth/breakthrough.")

    local before = State.RealmIndex
    local deadline = os.clock() + 22
    local defended = false
    local reprobed = false
    while os.clock() < deadline do
        if not reprobed and os.clock() > deadline - 16 then
            reprobed = true
            -- rantai probe bila nama aksi tebakan tidak diterima server
            task.spawn(function()
                probeActions({ { "AttemptBreakthrough" }, { "Ascend" }, { "RealmBreakthrough" }, { "Tribulation" } }, function()
                    return State.RealmIndex > before
                end, 1.4, 8)
            end)
        end
        if isTribulating() then
            if not defended then
                log("Heavenly Tribulation terdeteksi — bertahan & meditasi.")
                defended = true
            end
            if State.AutoDefend then
                fireAction("Defend")
                if not MeditateActive then setMeditate(true) end
            end
        end
        refreshPlayerState()
        if State.RealmIndex > before then
            log("Realm naik: " .. tostring(State.Realm))
            return true
        end
        task.wait(0.7)
    end
    return State.RealmIndex > before
end

-- ═══════════════════════════════════════════
--  SKY LANTERN & FESTIVAL SHOP
-- ═══════════════════════════════════════════
local LANTERN_HINTS = { "lantern", "lentera", "skylantern", "festival" }
local SHOP_HINTS = { "festivalshop", "festival_shop", "shopkeeper", "merchant", "vendor", "festivalvendor", "pedagang" }

local function findLanterns(limit)
    local root = getRootPart()
    local origin = root and root.Position or Vector3.zero
    local found = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj:IsDescendantOf(LocalPlayer.Character or workspace) then
            local low = string.lower(obj.Name)
            for _, hint in ipairs(LANTERN_HINTS) do
                if string.find(low, hint, 1, true) then
                    table.insert(found, { part = obj, dist = (obj.Position - origin).Magnitude })
                    break
                end
            end
        end
    end
    table.sort(found, function(a, b) return a.dist < b.dist end)
    if limit then
        while #found > limit do table.remove(found) end
    end
    return found
end

local function collectLanterns()
    local list = findLanterns(12)
    if #list == 0 then return 0 end
    local count = 0
    for _, entry in ipairs(list) do
        if entry.part.Parent then
            travelTo(entry.part.Position, { Label = "sky lantern", Arrive = 8 })
            task.wait(0.25)
            local prompt = findPromptNear(entry.part.Position, 15)
            if prompt then usePrompt(prompt) end
            fireAction("CollectLantern")
            fireAction("Lantern", entry.part.Name)
            count = count + 1
            task.wait(0.3)
        end
    end
    return count
end

local function findShop()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local low = normalizeName(obj.Name)
            for _, hint in ipairs(SHOP_HINTS) do
                if string.find(low, hint, 1, true) then
                    local p = partOf(obj)
                    if p then return p end
                end
            end
        end
    end
    return nil
end

local function shopBuy(itemName)
    if not itemName or itemName == "" then
        log("Nama item festival belum diisi.")
        return false
    end
    local shop = findShop()
    if shop then
        travelTo(shop.Position, { Label = "festival shop", Arrive = 9 })
        task.wait(0.3)
        local prompt = findPromptNear(shop.Position, 22)
        if prompt then usePrompt(prompt) end
        task.wait(0.6)
    end
    clickGuiButton({ string.lower(itemName) })
    fireAction("BuyFestivalItem", itemName)
    fireAction("FestivalBuy", itemName)
    fireAction("Buy", itemName)
    task.wait(0.3)
    clickGuiButton({ "buy", "beli", "purchase" })
    log("Percobaan pembelian: " .. itemName)
    return true
end

-- ═══════════════════════════════════════════
--  TALENT GACHA
-- ═══════════════════════════════════════════
local TALENT_TOKEN_ATTRS = { "TalentToken", "TalentTokens", "TalentRoll", "TalentRolls", "RerollToken", "TalentCoupon", "Tokens" }
local TIER_KEYWORDS = { "mythic", "legend", "legendary", "divine", "immortal", "godly", "heaven", "celestial", "supreme" }

local function talentTokens()
    for _, n in ipairs(TALENT_TOKEN_ATTRS) do
        local v = attrOf({ n })
        if type(v) == "number" then return v end
    end
    return nil
end

local function readTalentText()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local best
    for _, d in ipairs(pg:GetDescendants()) do
        if d:IsA("TextLabel") and d.Visible then
            local node, score = d, 0
            for _ = 1, 4 do
                if node.Parent then
                    local low = string.lower(node.Name)
                    if string.find(low, "talent") or string.find(low, "result") or string.find(low, "rarity") then
                        score = score + 3
                    end
                    node = node.Parent
                end
            end
            if score > 0 and string.len(d.Text) > 1 then
                best = d.Text
            end
        end
    end
    return best
end

local function talentMatches(text)
    if not text then return false end
    local low = string.lower(text)
    if State.TargetTalent ~= "" and string.find(low, string.lower(State.TargetTalent), 1, true) then
        return true
    end
    if State.TalentTier ~= "" then
        local wanted = string.lower(State.TalentTier)
        if string.find(low, wanted, 1, true) then return true end
        -- tier tinggi: cocokkan juga sinonim
        if wanted == "mythic" then
            for _, kw in ipairs({ "divine", "immortal", "godly", "supreme", "celestial" }) do
                if string.find(low, kw, 1, true) then return true end
            end
        end
    end
    return false
end

local function rollTalentOnce()
    fireAction("RollTalent")
    fireAction("TalentRoll")
    fireAction("RerollTalent")
    fireAction("Spin")
    task.wait(State.RollDelay or 0.45)
    return talentMatches(readTalentText())
end

-- ═══════════════════════════════════════════
--  TELEPORT TARGET BUILDER (Shared.World)
-- ═══════════════════════════════════════════
local TeleportTargets = {}
local TeleportLabels = {}

local function addTarget(label, pos, source)
    if typeof(pos) ~= "Vector3" then return end
    if #TeleportLabels > 250 then return end
    local key = label .. "  (" .. source .. ")"
    TeleportTargets[key] = pos
    table.insert(TeleportLabels, key)
end

local function extractPos(v)
    if type(v) ~= "table" then
        if typeof(v) == "Vector3" then return v end
        if typeof(v) == "CFrame" then return v.Position end
        return nil
    end
    local candidates = { "Position", "Pos", "CFrame", "Spawn", "Spot", "Location", "Teleport", "Point", "Origin" }
    for _, key in ipairs(candidates) do
        local val = v[key]
        if typeof(val) == "Vector3" then return val end
        if typeof(val) == "CFrame" then return val.Position end
    end
    return nil
end

local function walkWorld(tbl, prefix, depth)
    if type(tbl) ~= "table" or depth > 3 then return end
    for k, v in pairs(tbl) do
        if type(k) == "string" and k ~= "Name" then
            local pos = extractPos(v)
            if pos then
                addTarget(prefix .. k, pos, "Shared.World")
            elseif type(v) == "table" then
                walkWorld(v, prefix .. k .. " / ", depth + 1)
            end
        end
    end
end

local function buildTeleportTargets()
    TeleportTargets = {}
    TeleportLabels = {}

    local world = safeReq("World")
    if world then walkWorld(world, "", 0) end

    local obitel = workspace:FindFirstChild("Obitel")
    local islands = obitel and obitel:FindFirstChild("Islands")
    if islands then
        for _, island in ipairs(islands:GetChildren()) do
            local p = partOf(island)
            if p then
                local pid = tonumber(string.match(island.Name, "%d+"))
                local owner = pid and Players:GetPlayerByUserId(pid)
                local label = owner and ("Pulau " .. owner.DisplayName) or ("Pulau " .. island.Name)
                addTarget(label, p.Position, "Pulau")
            end
        end
    end

    local elder = elderYun()
    local elderPart = elder and partOf(elder)
    if elderPart then addTarget("Elder Yun (Rebirth NPC)", elderPart.Position, "Spot") end

    local cauldron = findCauldron()
    if cauldron then addTarget("Cauldron (Kuali Ramuan)", cauldron.Position, "Spot") end

    local lotusPos = findMeditationSpot()
    if lotusPos then addTarget("Spot Meditasi Terdekat", lotusPos, "Spot") end

    local spawn = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
    if spawn then addTarget("Spawn / Titik Awal", spawn.Position, "Spot") end

    table.sort(TeleportLabels)
end

-- ═══════════════════════════════════════════
--  LOOP UTAMA: AUTO REBIRTH / CULTIVATION
-- ═══════════════════════════════════════════
local MeditateSpot = nil
local MeditateSpotLabel = nil
local QiStallAt = nil
local QiLast = -1

local function clearMeditateSpot()
    MeditateSpot = nil
    MeditateSpotLabel = nil
end

local function goMeditate()
    if State.Locked then return end
    if not MeditateSpot then
        local pos, label = findMeditationSpot()
        if not pos then
            if os.clock() - (State.SpotWarn or 0) > 15 then
                State.SpotWarn = os.clock()
                log("Spot meditasi tidak terdeteksi — meditasi di tempat.")
            end
            setMeditate(true)
            return
        end
        MeditateSpot = pos
        MeditateSpotLabel = label
        log("Menuju spot meditasi: " .. tostring(label))
        travelTo(pos, { Label = "spot meditasi", Arrive = 6 })
    else
        local root = getRootPart()
        if root and (root.Position - MeditateSpot).Magnitude > 25 then
            travelTo(MeditateSpot, { Label = "spot meditasi", Arrive = 6 })
        end
    end
    if not MeditateActive then setMeditate(true) end
end

local function gatherForRecipe(recipe)
    if not recipe then return false end
    local missing = {}
    for _, ing in ipairs(recipe.Ingredients) do
        local have = countItem(ing.Name)
        if have < ing.Count then
            table.insert(missing, { name = ing.Name, need = ing.Count - have })
        end
    end
    if #missing == 0 then return true end

    log("Bahan kurang: " .. missing[1].name .. " (butuh " .. missing[1].need .. ")")
    local banked = 0
    local deadline = os.clock() + 180
    while os.clock() < deadline and State.AutoRebirth do
        refreshPlayerState()
        if not State.AutoHerbFarm then break end
        local herbs = findHerbs(1)
        if #herbs == 0 then
            log("Tidak ada tanaman herbal terdeteksi di map.")
            break
        end
        harvestOne(herbs[1])
        banked = banked + 1
        if ingredientsReady(recipe) then return true end
        if banked > 40 then break end
        task.wait(0.25)
    end
    return ingredientsReady(recipe)
end

local function tryPreparePill()
    local pill = countPill()
    if pill > 0 then return true end
    local recipe = recipeForRealm(State.RealmIndex)
    if not recipe then
        return false
    end
    if not ingredientsReady(recipe) then
        if not State.AutoHerbFarm then return false end
        gatherForRecipe(recipe)
    end
    if ingredientsReady(recipe) then
        if State.AutoCauldron then
            brewAtCauldron()
            task.wait(1)
            return countPill() > 0
        end
    end
    return countPill() > 0
end

local function autoRebirthLoop()
    if State.LoopRunning then return end
    State.LoopRunning = true
    local noProgressTicks = 0

    while State.AutoRebirth do
        local ok, err = pcall(function()
            refreshPlayerState()
            if State.Locked then return end
            local qi = State.Qi or 0

            if State.RebirthMaxRealm > 0 and State.RealmIndex >= State.RebirthMaxRealm then
                log("Batas realm tercapai (" .. State.Realm .. "). Loop berhenti.")
                State.AutoRebirth = false
                return
            end

            if qi >= State.QiThreshold then
                State.Step = "menyiapkan breakthrough"
                setMeditate(false)
                tryPreparePill()
                State.Step = "eksekusi rebirth"
                local success = attemptRebirth()
                if success then
                    log("Breakthrough berhasil ke " .. State.Realm .. ". Lanjut realm berikutnya...")
                    clearMeditateSpot()
                    noProgressTicks = 0
                    task.wait(math.random(4, 7))
                else
                    noProgressTicks = noProgressTicks + 1
                    log("Breakthrough belum berhasil (percobaan " .. noProgressTicks .. ").")
                    if noProgressTicks >= 5 then
                        log("5x gagal — jeda 20 detik agar server sinkron.")
                        noProgressTicks = 0
                        task.wait(20)
                    else
                        task.wait(3)
                    end
                end
            else
                if QiLast >= 0 and math.abs(qi - QiLast) < 0.05 then
                    QiStallAt = QiStallAt or os.clock()
                else
                    QiStallAt = nil
                end
                QiLast = qi

                if QiStallAt and os.clock() - QiStallAt > 25 then
                    log("Qi mandek — reset meditasi & pindah spot.")
                    setMeditate(false)
                    clearMeditateSpot()
                    QiStallAt = nil
                end

                State.Step = "meditasi (" .. string.format("%.1f", qi) .. "%)"
                goMeditate()
                task.wait(1.2)
            end
        end)
        if not ok then
            log("Loop error: " .. tostring(err))
            task.wait(2)
        end
        task.wait(0.6)
    end

    State.LoopRunning = false
    State.Step = "idle"
    setMeditate(false)
    if Travel.Flying then endFlight() end
    log("Loop auto rebirth berhenti.")
end

-- ═══════════════════════════════════════════
--  LOOP PENDUKUNG (LANTERN, SHOP, GACHA, STATUS)
-- ═══════════════════════════════════════════
local function lanternLoop()
    if State.LoopLantern then return end
    State.LoopLantern = true
    while State.AutoLantern do
        pcall(function()
            local got = collectLanterns()
            if got > 0 then log("Sky lantern diproses: " .. got) end
        end)
        task.wait(3)
    end
    State.LoopLantern = false
end

local function meditateLoop()
    if State.LoopMeditate then return end
    State.LoopMeditate = true
    while State.AutoMeditate do
        pcall(function()
            if not MeditateActive and not State.Locked then
                goMeditate()
            elseif MeditateSpot then
                local root = getRootPart()
                if root and (root.Position - MeditateSpot).Magnitude > 30 then
                    goMeditate()
                end
            end
        end)
        task.wait(2.5)
    end
    State.LoopMeditate = false
end

local function shopLoop()
    if State.LoopShop then return end
    State.LoopShop = true
    while State.AutoShop do
        pcall(function()
            if State.ShopItem ~= "" then shopBuy(State.ShopItem) end
        end)
        task.wait(6)
    end
    State.LoopShop = false
end

local function gachaLoop()
    if State.LoopGacha then return end
    State.LoopGacha = true
    clickGuiButton({ "talent" })
    task.wait(0.6)
    local rolls = 0
    while State.AutoGacha do
        local stop = false
        pcall(function()
            local tokens = talentTokens()
            if tokens ~= nil and tokens <= 0 then
                log("Token talent habis.")
                stop = true
                return
            end
            local hit = rollTalentOnce()
            rolls = rolls + 1
            if hit then
                log("Target talent didapat dalam " .. rolls .. " roll!")
                State.AutoGacha = false
                stop = true
            end
        end)
        if stop then break end
        if rolls % 15 == 0 then log("Total roll: " .. rolls) end
        task.wait(0.1)
    end
    State.LoopGacha = false
end

local function applyWalkSpeed()
    local hum = getHumanoid()
    if hum and not Travel.Flying then
        pcall(function() hum.WalkSpeed = State.WalkSpeed end)
    end
end

local function statusLoop()
    task.spawn(function()
        while true do
            pcall(function()
                refreshPlayerState()
                applyWalkSpeed()
                if State.StatusLabel then
                    State.StatusLabel.Text = string.format(
                        "Realm: %s  |  Qi: %.1f%%  |  Pil: %d  |  Tahap: %s",
                        tostring(State.Realm), tonumber(State.Qi) or 0, countPill(), tostring(State.Step)
                    )
                end
            end)
            task.wait(0.7)
        end
    end)
end

task.spawn(function()
    while true do
        pcall(function()
            local hum = getHumanoid()
            if hum and not MeditateActive and not State.Locked and hum.MoveDirection.Magnitude < 0.1 then
                pcall(function() VirtualUser:CaptureController() end)
                hum.Jump = true
                task.wait(0.1)
                if hum then hum.Jump = false end
            end
        end)
        task.wait(120)
    end
end)

-- ═══════════════════════════════════════════
--  WINDOW UTAMA (UNIONSAL GLASS BENTO)
-- ═══════════════════════════════════════════
local Window = Unionsal:CreateWindow({
    Name       = "unionsal",
    Subtitle   = ".gg/unionsal",
    GameName   = "Cultivation Legends",
    ScriptName = "cultivationlegends.lua",
    Version    = "v1.0",
})

OurGui = Window.ScreenGui

buildRealmList()
buildRecipes()
buildTeleportTargets()

local function notifyOk(title, content)
    Window:Notify({ Title = title, Content = content, Duration = 3 })
end

local function safeRun(fn)
    return function(...)
        local ok, err = pcall(fn, ...)
        if not ok then
            log("Error: " .. tostring(err))
            notifyOk("Error", tostring(err))
        end
    end
end

-- Label kustom yang bisa diperbarui (framework tidak mengembalikan objek label)
local function createInfoLabel(tabObj, height, color)
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
    label.TextColor3 = color or Color3.fromRGB(175, 110, 255)
    label.Text = ""
    label.Parent = card
    return label
end

-- ═══════════════════════════════════════════
--  TAB 1: CULTIVATION & REBIRTH
-- ═══════════════════════════════════════════
local CultTab = Window:CreateTab("Cultivation", "sprout", "Cultivation")
CultTab:CreateSection("Status Kultivasi Real-time")
State.StatusLabel = createInfoLabel(CultTab, 44)
State.StatusLabel.Text = "Membaca data realm & qi..."

CultTab:CreateSection("Auto Rebirth / Breakthrough")
CultTab:CreateToggle({
    Name = "Auto Rebirth (Meditasi → Ramuan → Terobosan)",
    CurrentValue = false,
    Callback = function(v)
        State.AutoRebirth = v
        if v then
            notifyOk("Auto Rebirth", "Loop kultivasi aktif. Pastikan Auto Meditate menyala.")
            task.spawn(autoRebirthLoop)
        else
            notifyOk("Auto Rebirth", "Loop dihentikan.")
        end
    end,
})

CultTab:CreateToggle({
    Name = "Auto Meditate (duduk di spot lotus)",
    CurrentValue = false,
    Callback = function(v)
        State.AutoMeditate = v
        if v then
            task.spawn(meditateLoop)
        else
            setMeditate(false)
        end
        notifyOk("Auto Meditate", v and "Meditasi otomatis aktif." or "Meditasi otomatis nonaktif.")
    end,
})

CultTab:CreateSlider({
    Name = "Ambang Qi untuk Breakthrough",
    Range = { 50, 100 },
    Increment = 0.5,
    Suffix = "%",
    CurrentValue = State.QiThreshold,
    Callback = function(v)
        State.QiThreshold = v
    end,
})

CultTab:CreateSlider({
    Name = "Berhenti di Realm Ke- (0 = tanpa batas)",
    Range = { 0, 40 },
    Increment = 1,
    CurrentValue = 0,
    Callback = function(v)
        State.RebirthMaxRealm = math.floor(v)
    end,
})

CultTab:CreateToggle({
    Name = "Auto Bertahan saat Tribulation",
    CurrentValue = true,
    Callback = function(v)
        State.AutoDefend = v
    end,
})

CultTab:CreateSection("Ramuan & Herbal")
CultTab:CreateToggle({
    Name = "Auto Herb Farm (petik tanaman bahan)",
    CurrentValue = false,
    Callback = function(v)
        State.AutoHerbFarm = v
        notifyOk("Auto Herb", v and "Pengumpulan herbal aktif." or "Pengumpulan herbal nonaktif.")
    end,
})

CultTab:CreateToggle({
    Name = "Auto Cauldron (racik pil terobosan)",
    CurrentValue = false,
    Callback = function(v)
        State.AutoCauldron = v
        notifyOk("Auto Cauldron", v and "Peracikan otomatis aktif." or "Peracikan otomatis nonaktif.")
    end,
})

CultTab:CreateButton({
    Name = "Meditasi Sekarang (pindah ke spot terdekat)",
    Callback = safeRun(function()
        clearMeditateSpot()
        goMeditate()
    end),
})

CultTab:CreateButton({
    Name = "Paksa Breakthrough Sekarang (Elder Yun)",
    Callback = safeRun(function()
        task.spawn(function()
            attemptRebirth()
        end)
    end),
})

CultTab:CreateButton({
    Name = "Petik 5 Tanaman Herbal Terdekat",
    Callback = safeRun(function()
        task.spawn(function()
            local list = findHerbs(5)
            for _, entry in ipairs(list) do
                harvestOne(entry)
            end
            notifyOk("Herbal", "Selesai memproses " .. #list .. " tanaman.")
        end)
    end),
})

CultTab:CreateButton({
    Name = "Racik di Cauldron Sekarang",
    Callback = safeRun(function()
        task.spawn(function()
            brewAtCauldron()
        end)
    end),
})

CultTab:CreateButton({
    Name = "Hentikan Semua Fitur Auto",
    Callback = function()
        State.AutoRebirth = false
        State.AutoMeditate = false
        State.AutoHerbFarm = false
        State.AutoCauldron = false
        State.AutoLantern = false
        State.AutoShop = false
        State.AutoGacha = false
        Travel.Cancelled = true
        setMeditate(false)
        notifyOk("Stop", "Semua fitur otomatis dimatikan.")
    end,
})

CultTab:CreateSection("Info")
CultTab:CreateParagraph({
    Title = "Cara kerja",
    Content = "Loop membaca Realm & Qi real-time. Qi < ambang → menuju lotus + meditasi. Qi penuh → siapkan pil (herbal & cauldron) lalu menemui Elder Yun. Tribulation ditahan otomatis.",
})

-- ═══════════════════════════════════════════
--  TAB 2: MOVEMENT
-- ═══════════════════════════════════════════
local MoveTab = Window:CreateTab("Movement", "rocket", "Movement")
MoveTab:CreateSection("Sword Flight Controller")

MoveTab:CreateToggle({
    Name = "Gunakan Flying Sword untuk perjalanan",
    CurrentValue = true,
    Callback = function(v)
        State.UseSwordFlight = v
    end,
})

MoveTab:CreateToggle({
    Name = "Mode Aman (smooth, anti-deteksi)",
    CurrentValue = true,
    Callback = function(v)
        State.SafeTravel = v
    end,
})

MoveTab:CreateSlider({
    Name = "Kecepatan Terbang",
    Range = { 60, 500 },
    Increment = 5,
    Suffix = " studs/s",
    CurrentValue = 175,
    Callback = function(v)
        State.FlySpeed = v
    end,
})

MoveTab:CreateSlider({
    Name = "Ketinggian Terbang Natural",
    Range = { 10, 120 },
    Increment = 2,
    CurrentValue = 28,
    Callback = function(v)
        State.NaturalHeight = v
    end,
})

MoveTab:CreateSlider({
    Name = "Walk Speed (mode jalan kaki)",
    Range = { 16, 120 },
    Increment = 1,
    CurrentValue = 34,
    Callback = function(v)
        State.WalkSpeed = v
        applyWalkSpeed()
    end,
})

MoveTab:CreateButton({
    Name = "Tes Terbang (naik 60 studs ke depan)",
    Callback = safeRun(function()
        task.spawn(function()
            local root = getRootPart()
            if not root then return end
            flyTo(root.Position + flat(root.CFrame.LookVector) * 60 + Vector3.new(0, 40, 0), 6)
            notifyOk("Tes Terbang", "Selesai.")
        end)
    end),
})

MoveTab:CreateButton({
    Name = "Mendarat / Matikan Mode Terbang",
    Callback = function()
        Travel.Cancelled = true
        endFlight()
        notifyOk("Flight", "Mode terbang dimatikan.")
    end,
})

MoveTab:CreateSection("Informasi Pedang")
MoveTab:CreateLabel("Status pedang terbang dicek otomatis saat perjalanan dimulai.")

-- ═══════════════════════════════════════════
--  TAB 3: EVENT & FESTIVAL
-- ═══════════════════════════════════════════
local EventTab = Window:CreateTab("Event & Festival", "zap", "Event")
EventTab:CreateSection("Sky Lantern Hunter")

EventTab:CreateToggle({
    Name = "Auto Sky Lantern (terbang & kumpulkan)",
    CurrentValue = false,
    Callback = function(v)
        State.AutoLantern = v
        if v then
            notifyOk("Sky Lantern", "Berburu lentera aktif.")
            task.spawn(lanternLoop)
        else
            notifyOk("Sky Lantern", "Berburu lentera nonaktif.")
        end
    end,
})

EventTab:CreateButton({
    Name = "Kumpulkan Sky Lantern Sekali Jalan",
    Callback = safeRun(function()
        task.spawn(function()
            local n = collectLanterns()
            notifyOk("Sky Lantern", n .. " lentera diproses.")
        end)
    end),
})

EventTab:CreateSection("Festival Shop")
EventTab:CreateInput({
    Name = "Nama Item",
    PlaceholderText = "Contoh: Sky Lantern Charm",
    Callback = function(text)
        State.ShopItem = text
    end,
})

EventTab:CreateToggle({
    Name = "Auto Beli Item Festival",
    CurrentValue = false,
    Callback = function(v)
        State.AutoShop = v
        if v then
            notifyOk("Festival Shop", "Pembelian otomatis aktif untuk: " .. (State.ShopItem ~= "" and State.ShopItem or "(item belum diisi)"))
            task.spawn(shopLoop)
        else
            notifyOk("Festival Shop", "Pembelian otomatis nonaktif.")
        end
    end,
})

EventTab:CreateButton({
    Name = "Beli Sekarang",
    Callback = safeRun(function()
        task.spawn(function()
            shopBuy(State.ShopItem)
        end)
    end),
})

-- ═══════════════════════════════════════════
--  TAB 4: TALENT
-- ═══════════════════════════════════════════
local TalentTab = Window:CreateTab("Talent Gacha", "diamond", "Talent")
TalentTab:CreateSection("Fast Roll")
TalentTab:CreateLabel("Token talent dibaca otomatis; loop berhenti sendiri saat token habis.")

TalentTab:CreateDropdown({
    Name = "Tier Incaran",
    Options = { "Mythic", "Legend", "Divine", "Immortal", "Godly" },
    CurrentValue = "Mythic",
    Callback = function(v)
        State.TalentTier = v
    end,
})

TalentTab:CreateInput({
    Name = "Nama Talent Spesifik (opsional)",
    PlaceholderText = "Contoh: Sword Saint",
    Callback = function(text)
        State.TargetTalent = text
    end,
})

TalentTab:CreateSlider({
    Name = "Jeda antar Roll (detik)",
    Range = { 0.1, 2 },
    Increment = 0.05,
    Suffix = " s",
    CurrentValue = 0.45,
    Callback = function(v)
        State.RollDelay = v
    end,
})

TalentTab:CreateToggle({
    Name = "Auto Gacha (fast roll sampai target)",
    CurrentValue = false,
    Callback = function(v)
        State.AutoGacha = v
        if v then
            notifyOk("Talent", "Fast roll aktif. Berhenti otomatis saat target didapat.")
            task.spawn(gachaLoop)
        else
            notifyOk("Talent", "Fast roll dihentikan.")
        end
    end,
})

TalentTab:CreateButton({
    Name = "Roll Satu Kali",
    Callback = safeRun(function()
        task.spawn(function()
            clickGuiButton({ "talent" })
            task.wait(0.4)
            local hit = rollTalentOnce()
            notifyOk("Talent", hit and "Target cocok terdeteksi!" or "Roll dikirim.")
        end)
    end),
})

TalentTab:CreateButton({
    Name = "Hentikan Fast Roll",
    Callback = function()
        State.AutoGacha = false
    end,
})

-- ═══════════════════════════════════════════
--  TAB 5: TELEPORT & WORLD
-- ═══════════════════════════════════════════
local WorldTab = Window:CreateTab("Teleport & World", "navigation", "World")
WorldTab:CreateSection("Mode Teleport")

WorldTab:CreateDropdown({
    Name = "Mode",
    Options = { "Smooth Fly (aman)", "Instant CFrame" },
    CurrentValue = "Smooth Fly (aman)",
    Callback = function(v)
        State.TeleportMode = v
    end,
})

WorldTab:CreateSection("Daftar Target (Shared.World & Pulau)")
WorldTab:CreateDropdown({
    Name = "Pilih Map / Pulau / Spot",
    Options = (#TeleportLabels > 0 and TeleportLabels) or { "Belum ada data world" },
    CurrentValue = (#TeleportLabels > 0 and TeleportLabels[1]) or "Belum ada data world",
    Callback = function(v)
        State.TeleportChoice = v
    end,
})

local function doTeleportTo(pos, label)
    if not pos then
        notifyOk("Teleport", "Target tidak ditemukan.")
        return
    end
    task.spawn(function()
        if State.TeleportMode == "Instant CFrame" or not State.SafeTravel then
            instantTeleport(pos)
            notifyOk("Teleport", "Instan ke " .. tostring(label))
        else
            log("Terbang menuju " .. tostring(label))
            local ok = travelTo(pos, { Label = tostring(label), Arrive = 6 })
            notifyOk("Teleport", (ok and "Tiba di " or "Gagal/berhenti di ") .. tostring(label))
        end
    end)
end

WorldTab:CreateButton({
    Name = "Teleport ke Target Terpilih",
    Callback = safeRun(function()
        local label = State.TeleportChoice
        doTeleportTo(label and TeleportTargets[label], label)
    end),
})

WorldTab:CreateSection("Cari Target Manual")
local searchTarget = ""

WorldTab:CreateInput({
    Name = "Cari Nama Map / Pulau",
    PlaceholderText = "Contoh: Elder / Pulau / nama map",
    Callback = function(text)
        searchTarget = text
    end,
})

WorldTab:CreateButton({
    Name = "Teleport ke Hasil Pencarian",
    Callback = safeRun(function()
        if searchTarget == "" then
            notifyOk("Cari", "Isi nama target dulu.")
            return
        end
        local needle = string.lower(searchTarget)
        for label, pos in pairs(TeleportTargets) do
            if string.find(string.lower(label), needle, 1, true) then
                doTeleportTo(pos, label)
                return
            end
        end
        notifyOk("Cari", "Tidak ada target cocok: " .. searchTarget)
    end),
})

WorldTab:CreateInput({
    Name = "Koordinat Manual (x,y,z)",
    PlaceholderText = "120, 45, -300",
    Callback = function(text)
        local x, y, z = string.match(text, "(-?%d+%.?%d*)%s*,%s*(-?%d+%.?%d*)%s*,%s*(-?%d+%.?%d*)")
        if x and y and z then
            State.ManualPos = Vector3.new(tonumber(x), tonumber(y), tonumber(z))
        end
    end,
})

WorldTab:CreateButton({
    Name = "Teleport ke Koordinat Manual",
    Callback = safeRun(function()
        if State.ManualPos then
            doTeleportTo(State.ManualPos, "koordinat manual")
        else
            notifyOk("Teleport", "Format koordinat salah.")
        end
    end),
})

WorldTab:CreateButton({
    Name = "Refresh Daftar Target",
    Callback = safeRun(function()
        buildTeleportTargets()
        notifyOk("World", #TeleportLabels .. " target terdeteksi. Gunakan pencarian untuk target baru.")
    end),
})

-- ═══════════════════════════════════════════
--  TAB 6: DIAGNOSTIK
-- ═══════════════════════════════════════════
local DiagTab = Window:CreateTab("Diagnostik", "activity", "Diagnostik")
DiagTab:CreateSection("Log Aktivitas")
State.LogLabel = createInfoLabel(DiagTab, 130)
State.LogLabel.Text = "Belum ada aktivitas."

DiagTab:CreateSection("Pemetaan Game")
DiagTab:CreateButton({
    Name = "Pindai Struktur Game (remotes & shared)",
    Callback = safeRun(function()
        local remotes = {}
        if RemoteFolder then
            for _, r in ipairs(RemoteFolder:GetChildren()) do
                table.insert(remotes, r.Name .. " [" .. r.ClassName .. "]")
            end
        end
        local modules = {}
        if SharedFolder then
            for _, m in ipairs(SharedFolder:GetChildren()) do
                table.insert(modules, m.Name)
            end
        end
        log("Remotes (" .. #remotes .. "): " .. table.concat(remotes, ", "))
        log("Shared (" .. #modules .. "): " .. table.concat(modules, ", "))
        log("Realm terbaca: " .. tostring(#RealmList) .. " entri; Qi: " .. string.format("%.1f", State.Qi))
        log("Pedang terbang: " .. tostring(hasFlyingSword()) .. "; Pil: " .. countPill())
    end),
})

DiagTab:CreateSection("Kalibrasi Nama Aksi Remote")
DiagTab:CreateParagraph({
    Title = "Kalau aksi tidak bereaksi",
    Content = "Isi nama aksi yang benar sesuai game, lalu ulangi fitur terkait. Nama default boleh dikosongkan.",
})

local OVERRIDE_FIELDS = {
    { key = "Rebirth", label = "Aksi Rebirth" },
    { key = "Breakthrough", label = "Aksi Breakthrough" },
    { key = "Meditate", label = "Aksi Meditasi" },
    { key = "Harvest", label = "Aksi Petik Herbal" },
    { key = "Brew", label = "Aksi Racik (Cauldron)" },
    { key = "RollTalent", label = "Aksi Roll Talent" },
}

for _, field in ipairs(OVERRIDE_FIELDS) do
    DiagTab:CreateInput({
        Name = field.label .. " (default: " .. ActionNames[field.key] .. ")",
        PlaceholderText = ActionNames[field.key],
        Callback = function(text)
            if text ~= "" then
                ActionNames[field.key] = text
                log("Override " .. field.key .. " = " .. text)
            end
        end,
    })
end

DiagTab:CreateButton({
    Name = "Reset Semua Nama Aksi ke Default",
    Callback = function()
        ActionNames.Rebirth = "Rebirth"
        ActionNames.Breakthrough = "Breakthrough"
        ActionNames.Meditate = "Meditate"
        ActionNames.Harvest = "Harvest"
        ActionNames.Brew = "Brew"
        ActionNames.RollTalent = "RollTalent"
        log("Nama aksi dikembalikan ke default.")
    end,
})

DiagTab:CreateSection("Kirim Aksi Manual")
local manualAction = ""
DiagTab:CreateInput({
    Name = "Nama Aksi Remote",
    PlaceholderText = "Contoh: Breakthrough",
    Callback = function(text)
        manualAction = text
    end,
})

DiagTab:CreateButton({
    Name = "Fire Aksi Manual ke Remotes.Action",
    Callback = safeRun(function()
        if manualAction == "" then return end
        local ok = fireAction(manualAction)
        log("Manual: FireServer('" .. manualAction .. "') -> " .. tostring(ok))
    end),
})

DiagTab:CreateButton({
    Name = "Pindai ProximityPrompt Terdekat",
    Callback = safeRun(function()
        local root = getRootPart()
        if not root then return end
        local prompt, dist = findPromptNear(root.Position, 60)
        if prompt then
            log("Prompt: " .. tostring(prompt.Parent and prompt.Parent.Name) .. " (" .. string.format("%.0f", dist) .. " studs) aksi=" .. tostring(prompt.ActionText))
        else
            log("Tidak ada ProximityPrompt dalam 60 studs.")
        end
    end),
})

-- ═══════════════════════════════════════════
--  STARTUP
-- ═══════════════════════════════════════════
statusLoop()

task.spawn(function()
    task.wait(0.3)
    refreshPlayerState()
    log("Realm terbaca: " .. tostring(State.Realm) .. " | Qi: " .. string.format("%.1f", State.Qi) .. "%")
    log("Shared module: Realms=" .. tostring(safeReq("Realms") ~= nil) .. " Alchemy=" .. tostring(safeReq("Alchemy") ~= nil) .. " World=" .. tostring(safeReq("World") ~= nil))
    if not Remotes.Action then
        log("PERINGATAN: ReplicatedStorage.Remotes.Action tidak ditemukan — fitur server butuh kalibrasi.")
    end
    if not hasFlyingSword() then
        log("Pedang terbang tidak terdeteksi di inventory — perjalanan memakai jalan kaki.")
    end
end)

task.wait(0.5)
Window:Notify({
    Title = "unionsal",
    Content = "Cultivation Legends v1.0 aktif. Kalibrasi remote lewat tab Diagnostik bila ada aksi yang tidak jalan.",
    Duration = 6,
})
