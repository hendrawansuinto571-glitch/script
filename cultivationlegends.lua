-- ╔══════════════════════════════════════════════════════════════╗
-- ║        UNIONSAL SCRIPT HUB — Cultivation Legends            ║
-- ║        Fitur:                                               ║
-- ║          • Auto Rebirth (jalan / terbang pakai sword)       ║
-- ║          • Auto Cauldron (craft ramuan)                     ║
-- ║          • Auto Meditasi                                    ║
-- ║          • Auto Festival (lantern + festival shop)          ║
-- ║          • Auto Talent Gacha (fast reroll)                  ║
-- ║          • Teleport by Map Name                             ║
-- ╚══════════════════════════════════════════════════════════════╝
-- CATATAN PENTING:
-- File cultivationlegends.txt di folder ini HANYA berisi ringkasan
-- decompile. Semua isi script-nya "api request error" / bytecode kosong,
-- jadi TIDAK ada daftar nama item, tumbuhan, atau map di dalamnya.
--
-- Karena itu script ini bekerja dengan DETEKSI OTOMATIS:
--   - Mencari objek lewat nama + CollectionService tag + ProximityPrompt
--   - Mencari map lewat folder Islands / Island_<id> / nama map
-- Kalau ada item di game yang tidak terdeteksi, tinggal tambahkan
-- kata kuncinya di tabel KEYWORDS di bawah (tidak perlu ubah logika).

getgenv()._UNIONSAL_CHILD_LOADED = true
getgenv()._NEMESIS_CHILD_LOADED = true

local SCRIPT_BASE_URL = "https://raw.githubusercontent.com/hendrawansuinto571-glitch/script/main/"

-- ═══════════════════════════════════════════
--  LOAD UI LIBRARY (main.lua)
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
            warn("[Cultivation Legends] Gagal memuat main.lua (UI Library).")
            return
        end
    end
end

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")
local PathfindingService = game:GetService("PathfindingService")
local CollectionService  = game:GetService("CollectionService")

local VirtualUser = nil
pcall(function()
    VirtualUser = game:GetService("VirtualUser")
end)

local VirtualInputManager = nil
pcall(function()
    VirtualInputManager = game:GetService("VirtualInputManager")
end)

local LocalPlayer = Players.LocalPlayer

-- ═══════════════════════════════════════════
--  CHARACTER HELPERS
-- ═══════════════════════════════════════════
local function getCharacter()
    -- Jangan pernah yield di sini: fungsi ini dipanggil dari loop status,
    -- dan menunggu CharacterAdded bisa membuat loop berhenti saat respawn.
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
--  KEYWORD DATABASE (EDIT DI SINI KALAU PERLU)
-- ═══════════════════════════════════════════
local KEYWORDS = {
    plant = {
        "herb", "plant", "flower", "grass", "root", "leaf", "leaves", "mushroom",
        "lotus", "ginseng", "spirit", "tumbuhan", "bunga", "daun", "akar",
        "jamur", "teratai", "rumput", "buah", "fruit", "berry", "crystal flower",
        "herbal", "seedling", "sprout", "harvestable", "collectible", "bush",
        "vine", "crop", "vegetation", "petik", "ambil",
    },
    lantern = {
        "lantern", "lentera", "event lantern", "festival lantern", "sky lantern",
        "wish lantern", "firefly lantern",
    },
    cauldron = {
        "cauldron", "caldron", "kuali", "alchemy", "furnace", "pill furnace",
        "brew", "ramuan", "perapian", "dandang", "alchemy table",
    },
    meditate = {
        "meditate", "meditation", "cultivat", "shrine", "altar", "training",
        "mat", "berlatih", "meditasi", "kultivasi", "sesi meditasi",
        "cultivation pad",
    },
    rebirth = {
        "rebirth", "reincarn", "breakthrough", "ascend", "reinkarnasi",
        "terobos", "naik realm", "elder", "sesepuh", "master", "ascension",
        "rebirth altar",
    },
    festivalShop = {
        "festival shop", "festival", "shop", "toko", "merchant", "pedagang",
        "event", "lantern vendor", "event shop", "lantern shop",
    },
    sword = {
        "sword", "pedang", "saber", "blade", "jian", "flying sword",
    },
    talentRoll = {
        "gacha", "roll", "spin", "draw", "summon", "tarik", "acak", "random",
        "talent",
    },
    talentKeep = {
        "equip", "keep", "confirm", "use", "pakai", "simpan", "ambil",
        "terima", "ok", "oke",
    },
    craft = {
        "craft", "brew", "make", "cook", "buat", "racik", "ramuan",
        "proses", "mix", "combine", "refine",
    },
    confirm = {
        "confirm", "yes", "ya", "ok", "oke", "apply", "lanjut", "terima",
    },
    meditateBtn = {
        "meditate", "cultivate", "meditasi", "berlatih", "latih", "absor",
        "kultivasi",
    },
    rebirthBtn = {
        "rebirth", "reincarnate", "breakthrough", "ascend", "reinkarnasi",
        "terobos", "naik realm", "kultivasi baru",
    },
    buy = {
        "buy", "beli", "purchase", "tukar", "exchange",
    },
    map = {
        "map", "island", "realm", "region", "zone", "world", "dunia",
        "pulau", "area", "teleport", "portal", "gate", "gerbang",
    },
}

-- Tag CollectionService yang sering dipakai game (opsional, membantu deteksi)
local TAG_HINTS = {
    plant = { "plant", "herb", "harvest", "tumbuhan", "gatherable" },
    lantern = { "lantern", "festival", "event" },
    cauldron = { "cauldron", "alchemy", "furnace" },
    meditate = { "meditate", "cultivation", "training" },
    rebirth = { "rebirth", "breakthrough" },
    festivalShop = { "festival", "shop", "event" },
}

-- Nama yang tidak boleh dianggap tumbuhan / lantern
local EXCLUDE = {
    "npc", "elder ", "steward", "portal", "gate", "spawn", "dummy",
    "island", "map", "cauldron", "meditate", "rebirth", "lantern shop",
    "player", "humanoid", "camera", "terrain", "baseplate",
    "beast", "monster", "enemy", "boss", "guard", "vendor",
}

-- Tambahkan map manual di sini kalau nama map tidak terdeteksi otomatis.
-- Format: "Nama Map"  ATAU  { Name = "Nama Map", Keyword = "kata kunci" }
-- ATAU  { Name = "Nama Map", Position = Vector3.new(100, 20, 300) }
local CUSTOM_MAPS = {
    -- "Azure Mountain",
    -- { Name = "Mount Hua", Keyword = "mount hua" },
    -- { Name = "Sect Base", Position = Vector3.new(0, 50, 0) },
}

-- ═══════════════════════════════════════════
--  SHARED STATE
-- ═══════════════════════════════════════════
local Window            -- di-assign setelah UI dibuat
local ToggleObjects = {}
local SliderObjects = {}
local StatusSetters = {}

local Movement = {
    UseSword    = true,
    FlyNoclip   = true,
    TriggerNative = false,
    FlySpeed    = 45,
    StopDistance = 4,
    WalkTimeout = 25,
    FlyTimeout  = 30,
    Abort       = false,
}

local Rebirth  = { Auto = false, Delay = 4, HarvestTarget = 20, UseRoute = true, Running = false }
local Meditate = { Time = 10 }
local Lantern  = { Auto = false, Radius = 1200, Delay = 1.2 }
local Talent   = { Auto = false, Fast = true, Equip = true, Delay = 0.6 }
local Festival = { AutoShop = false, BuyList = {}, Delay = 0.7, Radius = 1500 }

local HarvestCooldown = {}

local function setStatus(key, text)
    local setter = StatusSetters[key]
    if setter then
        pcall(setter, text)
    end
end

local function nameHas(name, list)
    if type(name) ~= "string" or name == "" or not list then return false end
    local lower = string.lower(name)
    for _, kw in ipairs(list) do
        if string.find(lower, string.lower(kw), 1, true) then
            return true
        end
    end
    return false
end

local function isExcluded(name)
    return nameHas(name, EXCLUDE)
end

local TagCache = setmetatable({}, { __mode = "k" })

local function getTagsCached(obj)
    local tags = TagCache[obj]
    if tags == nil then
        local ok, result = pcall(function()
            return CollectionService:GetTags(obj)
        end)
        tags = (ok and result) or false
        TagCache[obj] = tags
    end
    if tags == false then return nil end
    return tags
end

local function hasAnyTag(obj, tags)
    if not tags or #tags == 0 then return false end
    local objTags = getTagsCached(obj)
    if not objTags then return false end
    for _, tag in ipairs(objTags) do
        if nameHas(tag, tags) then return true end
    end
    return false
end

local function objectPosition(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Model") then
        local ok, cf = pcall(function()
            local box = obj:GetBoundingBox()
            return box
        end)
        if ok and cf then return cf.Position end
    end
    local part = obj:FindFirstChildWhichIsA("BasePart", true)
    return part and part.Position or nil
end

local function resolvePart(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then
        if obj.PrimaryPart then return obj.PrimaryPart end
    end
    return obj:FindFirstChildWhichIsA("BasePart", true)
end

-- ═══════════════════════════════════════════
--  WORKSPACE SNAPSHOT (biar tidak lag)
-- ═══════════════════════════════════════════
local Snapshot = { list = {}, time = 0 }
local PromptIndex = setmetatable({}, { __mode = "k" })

local function getSnapshot(force)
    if not force and tick() - Snapshot.time < 4 and #Snapshot.list > 0 then
        return Snapshot.list
    end

    local list = {}
    local myChar = LocalPlayer.Character
    local otherChars = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            table.insert(otherChars, plr.Character)
        end
    end

    PromptIndex = setmetatable({}, { __mode = "k" })
    TagCache = setmetatable({}, { __mode = "k" })

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") or obj:IsA("ClickDetector") then
            -- Index prompt/click ke semua parent-nya (maks 8 tingkat),
            -- supaya findTargets tidak perlu pencarian rekursif per objek.
            local ancestor = obj.Parent
            local steps = 0
            while ancestor and ancestor ~= workspace and steps < 8 do
                local entry = PromptIndex[ancestor]
                if not entry then
                    entry = {}
                    PromptIndex[ancestor] = entry
                end
                if obj:IsA("ProximityPrompt") then
                    entry.Prompt = entry.Prompt or obj
                else
                    entry.Click = entry.Click or obj
                end
                ancestor = ancestor.Parent
                steps = steps + 1
            end
        elseif obj:IsA("Model") or obj:IsA("BasePart") or obj:IsA("Folder") then
            local skip = false
            if myChar and obj:IsDescendantOf(myChar) then
                skip = true
            elseif myChar and obj == myChar then
                skip = true
            else
                for _, char in ipairs(otherChars) do
                    if obj:IsDescendantOf(char) then
                        skip = true
                        break
                    end
                end
            end
            if not skip then
                table.insert(list, obj)
            end
        end
    end

    Snapshot.list = list
    Snapshot.time = tick()
    return list
end

-- ═══════════════════════════════════════════
--  TARGET SCANNER
-- ═══════════════════════════════════════════
local ScanCache = {}

local function findTargets(kind, radius, force)
    radius = radius or 5000
    local cacheKey = tostring(kind) .. ":" .. tostring(math.floor(radius))
    local cached = ScanCache[cacheKey]
    if not force and cached and tick() - cached.time < 2 then
        return cached.list
    end

    local kws = KEYWORDS[kind] or {}
    local tags = TAG_HINTS[kind] or {}
    local root = getRootPart()
    local origin = root and root.Position or Vector3.zero
    local list = {}
    local seen = {}

    local function consider(obj)
        if seen[obj] or not obj.Parent then return end
        if obj == workspace then return end

        local entry  = PromptIndex[obj]
        local prompt = entry and entry.Prompt
        local click  = entry and entry.Click

        local matched = nameHas(obj.Name, kws) or hasAnyTag(obj, tags)

        if not matched and (kind == "meditate" or kind == "rebirth" or kind == "cauldron" or kind == "festivalShop") then
            if prompt then
                local txt = tostring(prompt.ObjectText or "") .. " " .. tostring(prompt.ActionText or "")
                matched = nameHas(txt, kws)
            end
        end

        if not matched then return end
        if (kind == "plant" or kind == "lantern") then
            if obj:IsA("Folder") or isExcluded(obj.Name) then return end
        end

        local needsInteraction = not (kind == "plant" or kind == "lantern" or kind == "map")
        if needsInteraction and not (prompt or click) then return end

        local pos = objectPosition(obj)
        if not pos then return end
        local dist = (pos - origin).Magnitude
        if dist > radius then return end

        seen[obj] = true
        table.insert(list, {
            Object   = obj,
            Position = pos,
            Distance = dist,
            Prompt   = prompt,
            Click    = click,
        })
    end

    for _, obj in ipairs(getSnapshot(force)) do
        consider(obj)
    end

    table.sort(list, function(a, b)
        return a.Distance < b.Distance
    end)

    ScanCache[cacheKey] = { list = list, time = tick() }
    return list
end
-- ═══════════════════════════════════════════
--  INTERACTION ENGINE
-- ═══════════════════════════════════════════
local function facePosition(pos)
    local root = getRootPart()
    if not root or not pos then return end
    local flat = Vector3.new(pos.X, root.Position.Y, pos.Z)
    if (flat - root.Position).Magnitude < 0.15 then return end
    pcall(function()
        root.CFrame = CFrame.lookAt(root.Position, flat)
    end)
end

local function clickScreenAt(worldPos)
    local cam = workspace.CurrentCamera
    if not cam then return false end
    local screenPos, onScreen = cam:WorldToViewportPoint(worldPos)
    if not onScreen then return false end
    local vim = VirtualInputManager
    if not vim then return false end
    local ok = pcall(function()
        vim:SendMouseButtonEvent(screenPos.X, screenPos.Y, 0, true, game, 0)
        task.wait(0.06)
        vim:SendMouseButtonEvent(screenPos.X, screenPos.Y, 0, false, game, 0)
    end)
    return ok
end

local function interactWith(obj, extraWait)
    if not obj or not obj.Parent then return false end

    local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
    local click  = obj:FindFirstChildWhichIsA("ClickDetector", true)
    local root   = getRootPart()

    if prompt then
        pcall(function()
            prompt.MaxActivationDistance = math.max(prompt.MaxActivationDistance, 25)
            prompt.Enabled = true
        end)

        local fired = false
        if fireproximityprompt then
            fired = pcall(fireproximityprompt, prompt)
        end

        if not fired then
            fired = pcall(function()
                prompt:InputHoldBegin()
                task.wait(math.max(0.15, (prompt.HoldDuration or 0.1) + 0.1))
                prompt:InputHoldEnd()
            end)
        else
            task.wait(0.12)
        end

        task.wait(extraWait or 0.25)
        return fired
    end

    if click then
        pcall(function()
            click.MaxActivationDistance = math.max(click.MaxActivationDistance, 40)
        end)

        local fired = false
        if fireclickdetector then
            fired = pcall(fireclickdetector, click)
        end
        if not fired then
            local part = resolvePart(obj)
            if part then
                facePosition(part.Position)
                fired = clickScreenAt(part.Position)
            end
        end

        task.wait(extraWait or 0.25)
        return fired
    end

    -- Fallback terakhir: sentuh part-nya (banyak game harvest pakai Touched)
    local part = resolvePart(obj)
    if root and part and firetouchinterest then
        pcall(function()
            firetouchinterest(root, part, 0)
            task.wait(0.06)
            firetouchinterest(root, part, 1)
        end)
        task.wait(extraWait or 0.2)
        return true
    end

    return false
end

-- ═══════════════════════════════════════════
--  GUI AUTOMATION
-- ═══════════════════════════════════════════
local function isGuiVisible(obj)
    local current = obj
    while current and current ~= game do
        if current:IsA("GuiObject") and not current.Visible then return false end
        if current:IsA("LayerCollector") and not current.Enabled then return false end
        current = current.Parent
    end
    return true
end

local function clickGuiButton(btn)
    if not btn or not btn.Parent then return false end

    local firedAny = false
    if getconnections then
        local ok, conns = pcall(getconnections, btn.MouseButton1Click)
        if ok and conns then
            for _, conn in ipairs(conns) do
                local fired = pcall(function() conn:Fire() end)
                if fired then firedAny = true end
            end
        end
    end
    if firedAny then return true end

    if btn.AbsoluteSize.Magnitude <= 0 then return false end
    local vim = VirtualInputManager
    if not vim then return false end
    local center = btn.AbsolutePosition + (btn.AbsoluteSize / 2)
    local ok = pcall(function()
        vim:SendMouseButtonEvent(center.X, center.Y, 0, true, game, 0)
        task.wait(0.05)
        vim:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 0)
    end)
    return ok
end

local function findGuiButtons(keywords, visibleOnly)
    local found = {}
    local pg = getPlayerGui()
    if not pg then return found end

    for _, obj in ipairs(pg:GetDescendants()) do
        if obj:IsA("GuiButton") then
            local visible = (not visibleOnly) or isGuiVisible(obj)
            if visible then
                local label = obj.Name
                if obj:IsA("TextButton") then
                    label = label .. " " .. tostring(obj.Text)
                end
                if nameHas(label, keywords) then
                    table.insert(found, obj)
                end
            end
        end
    end
    return found
end

local function clickFirstGui(keywords, waitTime)
    local btns = findGuiButtons(keywords, true)
    if #btns == 0 then return false end
    clickGuiButton(btns[1])
    task.wait(waitTime or 0.25)
    return true
end

-- ═══════════════════════════════════════════
--  SWORD & MOVEMENT
-- ═══════════════════════════════════════════
local function getSwordTool()
    local char = getCharacter()
    if char then
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") and nameHas(tool.Name, KEYWORDS.sword) then
                return tool
            end
        end
    end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and nameHas(tool.Name, KEYWORDS.sword) then
                return tool
            end
        end
    end
    return nil
end

local function equipSword()
    local tool = getSwordTool()
    if not tool then return nil end
    local char = getCharacter()
    local hum = getHumanoid()
    if char and hum and tool.Parent ~= char then
        pcall(function() hum:EquipTool(tool) end)
        task.wait(0.25)
    end
    return tool
end

local function setCharacterCollision(state, saved)
    local char = getCharacter()
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            if state == false then
                saved[part] = part.CanCollide
                pcall(function() part.CanCollide = false end)
            else
                local original = saved[part]
                if original ~= nil and part.Parent then
                    pcall(function() part.CanCollide = original end)
                end
            end
        end
    end
end

local function flyTo(targetPos, timeout)
    timeout = timeout or Movement.FlyTimeout
    local root = getRootPart()
    local hum = getHumanoid()
    if not root or not hum or not targetPos then return false end

    local sword = equipSword()
    if sword and Movement.TriggerNative then
        -- Eksperimental: coba picu flight bawaan game (kalau ada SwordFlight)
        pcall(function() sword:Activate() end)
        task.wait(0.15)
    end

    root = getRootPart()
    if not root then return false end

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    bv.Velocity = Vector3.zero
    bv.Parent = root

    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    bg.P = 5000
    bg.D = 500
    bg.CFrame = root.CFrame
    bg.Parent = root

    local savedCollide = {}
    if Movement.FlyNoclip then
        setCharacterCollision(false, savedCollide)
    end

    local start = tick()
    local reached = false

    while tick() - start < timeout and not Movement.Abort do
        root = getRootPart()
        if not root then break end

        local delta = targetPos - root.Position
        local dist = delta.Magnitude
        if dist <= Movement.StopDistance then
            reached = true
            break
        end

        local speed = Movement.FlySpeed
        if dist < 15 then
            speed = math.max(8, speed * (dist / 15))
        end

        bv.Velocity = delta.Unit * speed
        bg.CFrame = CFrame.lookAt(root.Position, root.Position + delta.Unit)
        task.wait(0.04)
    end

    if bv then bv:Destroy() end
    if bg then bg:Destroy() end
    setCharacterCollision(true, savedCollide)

    task.wait(0.12)
    return reached
end

local function walkTo(targetPos, timeout)
    timeout = timeout or Movement.WalkTimeout
    local hum = getHumanoid()
    local root = getRootPart()
    if not hum or not root or not targetPos then return false end

    local start = tick()
    local path = PathfindingService:CreatePath({
        AgentRadius = 2.5,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentCanClimb = false,
        WaypointSpacing = 6,
    })

    local computeOk = pcall(function()
        path:ComputeAsync(root.Position, targetPos)
    end)

    if computeOk and path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        for i = 2, #waypoints do
            if Movement.Abort or tick() - start > timeout then break end
            local wp = waypoints[i]
            if wp.Action == Enum.PathWaypointAction.Jump then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
            hum:MoveTo(wp.Position)

            local segStart = tick()
            while tick() - segStart < 5 do
                local r = getRootPart()
                if not r then return false end
                if (r.Position - wp.Position).Magnitude < 4.5 then break end
                task.wait(0.1)
            end
        end
    end

    hum = getHumanoid()
    root = getRootPart()
    if not hum or not root then return false end

    hum:MoveTo(targetPos)
    local lastJump = tick()

    while tick() - start < timeout and not Movement.Abort do
        root = getRootPart()
        if not root then return false end
        if (root.Position - targetPos).Magnitude <= Movement.StopDistance then
            pcall(function() hum:MoveTo(root.Position) end)
            return true
        end
        if root.AssemblyLinearVelocity.Magnitude < 1.5 and tick() - lastJump > 1.2 then
            pcall(function() hum.Jump = true end)
            lastJump = tick()
        end
        task.wait(0.1)
    end

    pcall(function() hum:MoveTo(root.Position) end)
    local finalRoot = getRootPart()
    return finalRoot ~= nil and (finalRoot.Position - targetPos).Magnitude <= Movement.StopDistance + 5
end

local function travelTo(pos, label)
    if not pos then return false end
    local root = getRootPart()
    if not root then return false end

    local dist = (root.Position - pos).Magnitude
    if dist <= Movement.StopDistance then return true end

    local sword = getSwordTool()
    if Movement.UseSword and sword then
        setStatus("move", string.format("Terbang ke %s (%.0f studs) pakai %s", label or "target", dist, sword.Name))
        if flyTo(pos) then return true end
    end

    setStatus("move", string.format("Berjalan ke %s (%.0f studs)", label or "target", dist))
    return walkTo(pos)
end

-- ═══════════════════════════════════════════
--  HARVEST (TUMBUHAN & LANTERN)
-- ═══════════════════════════════════════════
local function collectOnce(kind, radius, maxCount, statusKey, label)
    radius = radius or 1200
    maxCount = maxCount or 4
    local list = findTargets(kind, radius, true)
    local collected = 0
    local attempts = 0

    for _, target in ipairs(list) do
        if Movement.Abort or collected >= maxCount or attempts >= 10 then break end

        local last = HarvestCooldown[target.Object]
        if not last or tick() - last > 6 then
            attempts = attempts + 1
            local reached = travelTo(target.Position, target.Object.Name)
            if not reached then
                local root = getRootPart()
                reached = root ~= nil and (root.Position - target.Position).Magnitude <= 25
            end
            if reached then
                facePosition(target.Position)
                local ok = interactWith(target.Object)
                HarvestCooldown[target.Object] = tick()
                if ok then
                    collected = collected + 1
                    setStatus(statusKey, string.format("%s: %s (%d/%d)", label, target.Object.Name, collected, maxCount))
                end
                task.wait(0.3)
            end
        end
    end

    return collected
end

local function harvestOnce(radius)
    return collectOnce("plant", radius or 2000, 4, "harvest", "Mengambil")
end

local function collectLanternsOnce(radius)
    return collectOnce("lantern", radius or 1000, 4, "lantern", "Lantern")
end

local function harvestUntil(targetCount, timeout)
    local start = tick()
    local got = 0
    local idle = 0

    while got < targetCount and (tick() - start) < timeout and not Movement.Abort do
        local okCall, n = pcall(harvestOnce, 2000)
        if not okCall or type(n) ~= "number" then n = 0 end
        got = got + n
        if n == 0 then
            idle = idle + 1
            task.wait(2)
            if idle >= 5 then break end
        else
            idle = 0
        end
    end
    return got
end

-- ═══════════════════════════════════════════
--  CAULDRON, MEDITASI, REBIRTH
-- ═══════════════════════════════════════════
local function useCauldron()
    setStatus("cauldron", "Mencari cauldron...")

    local target = findTargets("cauldron", 4000, true)[1]
    if target then
        travelTo(target.Position, target.Object.Name)
        facePosition(target.Position)
        interactWith(target.Object)
        task.wait(0.8)
    else
        -- Mungkin UI cauldron sudah terbuka, coba klik tombolnya
        clickFirstGui(KEYWORDS.cauldron, 0.3)
        task.wait(0.5)
    end

    local crafts = 0
    for _ = 1, 6 do
        if Movement.Abort then break end
        local clicked = false
        if clickFirstGui(KEYWORDS.craft, 0.45) then
            clicked = true
        elseif clickFirstGui(KEYWORDS.confirm, 0.35) then
            clicked = true
        end
        if not clicked then break end
        crafts = crafts + 1
    end

    setStatus("cauldron", crafts > 0
        and string.format("Ramuan diproses: %dx", crafts)
        or "Tombol craft tidak ditemukan (buka cauldron manual dulu).")
    return crafts > 0
end

local function meditateOnce()
    setStatus("meditate", "Mencari tempat meditasi...")

    local target = findTargets("meditate", 4000, true)[1]
    if target then
        travelTo(target.Position, target.Object.Name)
        facePosition(target.Position)
        interactWith(target.Object)
        task.wait(0.6)
    end

    clickFirstGui(KEYWORDS.meditateBtn, 0.4)

    local duration = Meditate.Time or 10
    setStatus("meditate", string.format("Meditasi %d detik...", duration))
    local waited = 0
    while waited < duration and not Movement.Abort do
        task.wait(0.5)
        waited = waited + 0.5
    end

    setStatus("meditate", "Meditasi selesai.")
    return true
end

local function rebirthOnce()
    setStatus("rebirthAction", "Mencari rebirth / breakthrough...")

    local target = findTargets("rebirth", 4000, true)[1]
    if target then
        travelTo(target.Position, target.Object.Name)
        facePosition(target.Position)
        interactWith(target.Object)
        task.wait(0.8)
    end

    local clicked = clickFirstGui(KEYWORDS.rebirthBtn, 0.6)
    task.wait(0.4)
    clickFirstGui(KEYWORDS.confirm, 0.4)

    setStatus("rebirthAction", clicked
        and "Rebirth diklik."
        or "Tombol rebirth tidak ditemukan (buka menu rebirth manual).")
    return clicked
end
-- ═══════════════════════════════════════════
--  ROUTE / JALAN KULTIVASI
--  (titik-titik yang dijalani karakter, urut)
-- ═══════════════════════════════════════════
local Route = {}
local RouteRunning = false
local ROUTE_FILE = "cultivation_route.json"

local function addWaypoint(wpType, customName)
    local root = getRootPart()
    if not root then return false, "Karakter belum siap." end

    local pos = root.Position
    local name = customName or "Posisi Saya"

    if wpType ~= "custom" then
        local targets = findTargets(wpType, 4000, true)
        if targets[1] then
            pos = targets[1].Position
            name = targets[1].Object.Name
        else
            return false, string.format("Tidak ada %s terdeteksi. Tambah titik manual dulu.", wpType)
        end
    end

    table.insert(Route, { Type = wpType, Name = name, Position = pos })
    return true, string.format("%s ditambahkan (total %d titik)", name, #Route)
end

local function removeLastWaypoint()
    if #Route == 0 then return false, "Route masih kosong." end
    table.remove(Route)
    return true, string.format("Titik terakhir dihapus (sisa %d titik)", #Route)
end

local function clearRoute()
    Route = {}
    return true, "Route dikosongkan."
end

local function saveRoute()
    if not writefile then return false, "Executor tidak mendukung writefile." end
    local data = {}
    for i, wp in ipairs(Route) do
        data[i] = {
            Type = wp.Type,
            Name = wp.Name,
            X = wp.Position.X,
            Y = wp.Position.Y,
            Z = wp.Position.Z,
        }
    end
    local ok = pcall(function()
        writefile(ROUTE_FILE, HttpService:JSONEncode(data))
    end)
    return ok, ok and string.format("Route tersimpan (%d titik)", #Route) or "Gagal menyimpan route."
end

local function loadRoute()
    if not (readfile and isfile) then return false, "Executor tidak mendukung readfile." end
    local ok, content = pcall(function()
        if isfile(ROUTE_FILE) then return readfile(ROUTE_FILE) end
        return nil
    end)
    if not ok or not content or content == "" then return false, "Belum ada route tersimpan." end

    local parseOk, data = pcall(function()
        return HttpService:JSONDecode(content)
    end)
    if not parseOk or type(data) ~= "table" then return false, "File route tidak valid." end

    local newRoute = {}
    for _, wp in ipairs(data) do
        if wp and wp.X and wp.Y and wp.Z then
            table.insert(newRoute, {
                Type = wp.Type or "custom",
                Name = wp.Name or "Titik",
                Position = Vector3.new(wp.X, wp.Y, wp.Z),
            })
        end
    end
    Route = newRoute
    return true, string.format("Route dimuat (%d titik)", #Route)
end

local function runRoute()
    if #Route == 0 then
        Window:Notify({ Title = "Route Kosong", Content = "Tambahkan titik dulu di tab Rebirth.", Duration = 3 })
        return false
    end
    if RouteRunning then return false end

    RouteRunning = true
    Movement.Abort = false

    for i, wp in ipairs(Route) do
        if Movement.Abort then break end
        setStatus("route", string.format("Titik %d/%d: %s (%s)", i, #Route, wp.Name, wp.Type))
        travelTo(wp.Position, wp.Name)

        if wp.Type == "plant" then
            harvestOnce(150)
        elseif wp.Type == "lantern" then
            collectLanternsOnce(180)
        elseif wp.Type == "cauldron" then
            useCauldron()
        elseif wp.Type == "meditate" then
            meditateOnce()
        elseif wp.Type == "rebirth" then
            rebirthOnce()
        end
        task.wait(0.3)
    end

    RouteRunning = false
    setStatus("route", "Route selesai.")
    return true
end

-- Susun route otomatis: beberapa tumbuhan -> cauldron -> meditasi -> rebirth
local function buildAutoRoute()
    Route = {}

    local plants = findTargets("plant", 4000, true)
    for i = 1, math.min(#plants, 3) do
        table.insert(Route, {
            Type = "plant",
            Name = plants[i].Object.Name,
            Position = plants[i].Position,
        })
    end

    local found = { plant = #Route > 0 }

    local function addNearest(kind)
        local target = findTargets(kind, 4000, true)[1]
        if target then
            table.insert(Route, {
                Type = kind,
                Name = target.Object.Name,
                Position = target.Position,
            })
            found[kind] = true
            return true
        end
        return false
    end

    addNearest("cauldron")
    addNearest("meditate")
    addNearest("rebirth")

    return #Route, found
end

-- ═══════════════════════════════════════════
--  AUTO REBIRTH LOOP
-- ═══════════════════════════════════════════
local function runRebirthCycle()
    if Rebirth.Running then return end
    Rebirth.Running = true

    local ok, err = pcall(function()
        setStatus("rebirth", "Memulai siklus rebirth...")

        if Rebirth.UseRoute and #Route > 0 then
            runRoute()
            return
        end

        setStatus("rebirth", "Mencari bahan / tumbuhan...")
        local got = harvestUntil(Rebirth.HarvestTarget, 90)
        setStatus("harvest", string.format("Bahan terkumpul: %d", got))
        if Movement.Abort then return end

        setStatus("rebirth", "Menuju cauldron & membuat ramuan...")
        useCauldron()
        if Movement.Abort then return end

        setStatus("rebirth", "Menuju tempat meditasi...")
        meditateOnce()
        if Movement.Abort then return end

        setStatus("rebirth", "Proses rebirth...")
        rebirthOnce()
        setStatus("rebirth", "Siklus rebirth selesai.")
    end)

    Rebirth.Running = false
    if not ok then
        warn("[Cultivation Legends] Rebirth cycle error: " .. tostring(err))
    end
end

local AutoRebirthGeneration = 0

local function startAutoRebirth()
    AutoRebirthGeneration = AutoRebirthGeneration + 1
    local generation = AutoRebirthGeneration
    task.spawn(function()
        while Rebirth.Auto and generation == AutoRebirthGeneration do
            runRebirthCycle()
            local waited = 0
            while Rebirth.Auto and generation == AutoRebirthGeneration and waited < Rebirth.Delay do
                task.wait(0.25)
                waited = waited + 0.25
            end
        end
    end)
end

-- ═══════════════════════════════════════════
--  AUTO LANTERN (EVENT FESTIVAL)
-- ═══════════════════════════════════════════
local AutoLanternGeneration = 0

local function startAutoLantern()
    AutoLanternGeneration = AutoLanternGeneration + 1
    local generation = AutoLanternGeneration
    task.spawn(function()
        while Lantern.Auto and generation == AutoLanternGeneration do
            local okCall, got = pcall(collectLanternsOnce, Lantern.Radius)
            if not okCall or type(got) ~= "number" then got = 0 end
            if got == 0 then
                setStatus("lantern", "Menunggu lantern event muncul...")
                task.wait(3)
            else
                setStatus("lantern", string.format("Lantern diambil: %d", got))
                task.wait(Lantern.Delay)
            end
        end
        setStatus("lantern", "Auto lantern berhenti.")
    end)
end

-- ═══════════════════════════════════════════
--  AUTO TALENT GACHA
-- ═══════════════════════════════════════════
local function talentRollOnce()
    local specific = { "gacha", "roll", "spin", "draw", "summon", "tarik", "acak", "random" }
    local btns = findGuiButtons(specific, true)
    if #btns == 0 then
        btns = findGuiButtons(KEYWORDS.talentRoll, true)
    end
    local btn = btns[1]
    if not btn then return false end

    clickGuiButton(btn)
    task.wait(Talent.Fast and 0.25 or Talent.Delay)

    if Talent.Equip then
        -- Tunggu hasil gacha muncul, lalu klik equip / keep / confirm.
        local keep
        for _ = 1, 10 do
            keep = findGuiButtons(KEYWORDS.talentKeep, true)[1]
            if keep then break end
            task.wait(0.2)
        end
        if keep then
            clickGuiButton(keep)
            task.wait(0.2)
        end
    end
    return true
end

local AutoTalentGeneration = 0

local function startAutoTalent()
    AutoTalentGeneration = AutoTalentGeneration + 1
    local generation = AutoTalentGeneration
    task.spawn(function()
        while Talent.Auto and generation == AutoTalentGeneration do
            local okCall, rolled = pcall(talentRollOnce)
            if not okCall then rolled = false end
            if rolled then
                setStatus("talent", string.format("Gacha talent... (%s)", Talent.Fast and "fast" or "normal"))
                task.wait(Talent.Fast and 0.1 or Talent.Delay)
            else
                setStatus("talent", "Tombol gacha talent belum terbuka. Buka menu talent dulu.")
                task.wait(2)
            end
        end
        setStatus("talent", "Auto talent berhenti.")
    end)
end

-- ═══════════════════════════════════════════
--  FESTIVAL SHOP
-- ═══════════════════════════════════════════
local function parseList(text)
    local list = {}
    for part in string.gmatch(text or "", "([^,]+)") do
        local clean = string.gsub(part, "^%s*(.-)%s*$", "%1")
        if clean ~= "" then
            table.insert(list, clean)
        end
    end
    return list
end

local function findBuyButtonForItem(itemName)
    local pg = getPlayerGui()
    if not pg or not itemName or itemName == "" then return nil end

    for _, obj in ipairs(pg:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Text ~= "" then
            if string.find(string.lower(obj.Text), string.lower(itemName), 1, true) then
                local container = obj.Parent
                for _ = 1, 3 do
                    if not container then break end
                    for _, d in ipairs(container:GetDescendants()) do
                        if d:IsA("GuiButton") then
                            local label = d.Name
                            if d:IsA("TextButton") then label = label .. " " .. d.Text end
                            if nameHas(label, KEYWORDS.buy) then
                                return d
                            end
                        end
                    end
                    container = container.Parent
                end
            end
        end
    end
    return nil
end

local function openFestivalShop()
    local btn = findGuiButtons(KEYWORDS.festivalShop, true)[1]
    if btn then
        clickGuiButton(btn)
        task.wait(0.7)
        return true
    end

    local target = findTargets("festivalShop", 4000, true)[1]
    if target then
        travelTo(target.Position, target.Object.Name)
        facePosition(target.Position)
        interactWith(target.Object)
        task.wait(0.8)
        return true
    end
    return false
end

local function buyFestivalItems()
    local clicked = 0

    for _, item in ipairs(Festival.BuyList) do
        local btn = findBuyButtonForItem(item)
        if btn then
            clickGuiButton(btn)
            clicked = clicked + 1
            task.wait(Festival.Delay)
        end
    end

    if clicked == 0 then
        -- Tanpa daftar item, JANGAN beli tombol acak (bisa buang currency).
        -- Hanya beli tombol yang jelas terkait festival / lantern.
        local btns = findGuiButtons(KEYWORDS.buy, true)
        for i = 1, math.min(#btns, 10) do
            local b = btns[i]
            local ctx = b.Name
            if b:IsA("TextButton") then ctx = ctx .. " " .. tostring(b.Text) end
            if b.Parent then
                for _, d in ipairs(b.Parent:GetDescendants()) do
                    if d:IsA("TextLabel") then ctx = ctx .. " " .. tostring(d.Text) end
                end
            end
            if nameHas(ctx, { "lantern", "lentera", "festival", "ticket", "event" }) then
                clickGuiButton(b)
                clicked = clicked + 1
                task.wait(Festival.Delay)
            end
        end
    end

    return clicked
end

local AutoShopGeneration = 0

local function startAutoFestivalShop()
    AutoShopGeneration = AutoShopGeneration + 1
    local generation = AutoShopGeneration
    task.spawn(function()
        while Festival.AutoShop and generation == AutoShopGeneration do
            local okBuy, bought = pcall(buyFestivalItems)
            if not okBuy or type(bought) ~= "number" then bought = 0 end
            if bought == 0 then
                setStatus("shop", "Membuka festival shop...")
                pcall(openFestivalShop)
                local okBuy2, bought2 = pcall(buyFestivalItems)
                if okBuy2 and type(bought2) == "number" then bought = bought2 end
            end

            if bought > 0 then
                setStatus("shop", string.format("Membeli item festival: %dx", bought))
            else
                setStatus("shop", "Tidak ada tombol beli yang terdeteksi.")
            end
            task.wait(2)
        end
        setStatus("shop", "Auto festival shop berhenti.")
    end)
end

-- ═══════════════════════════════════════════
--  MAP DETECTION & TELEPORT
-- ═══════════════════════════════════════════
local MapCache = { list = {}, time = 0 }

local function scanMaps(force)
    if not force and tick() - MapCache.time < 10 and #MapCache.list > 0 then
        return MapCache.list
    end

    local found = {}
    local seen = {}

    local function add(name, obj, manualPos)
        if not name or name == "" or seen[name] then return end
        local pos = manualPos or objectPosition(obj)
        if not pos then return end
        if #found >= 80 then return end
        seen[name] = true
        table.insert(found, { Name = name, Position = pos, Object = obj })
    end

    for _, obj in ipairs(getSnapshot(force)) do
        if obj:IsA("Model") or obj:IsA("BasePart") or obj:IsA("Folder") then
            local n = obj.Name
            if string.match(n, "^Island_%d+$") or nameHas(n, KEYWORDS.map) then
                add(n, obj)
            end
        end
    end

    for _, custom in ipairs(CUSTOM_MAPS) do
        if type(custom) == "string" then
            for _, obj in ipairs(getSnapshot()) do
                if obj.Name == custom then
                    add(custom, obj)
                    break
                end
            end
        elseif type(custom) == "table" and custom.Name then
            if custom.Position then
                add(custom.Name, nil, custom.Position)
            else
                for _, obj in ipairs(getSnapshot()) do
                    if nameHas(obj.Name, { custom.Keyword or custom.Name }) then
                        add(custom.Name, obj)
                        break
                    end
                end
            end
        end
    end

    table.sort(found, function(a, b)
        return a.Name < b.Name
    end)

    MapCache.list = found
    MapCache.time = tick()
    return found
end

local function findMap(query)
    if not query or query == "" then return nil end
    local lower = string.lower(query)
    local maps = scanMaps(true)

    for _, m in ipairs(maps) do
        if string.lower(m.Name) == lower then return m end
    end
    for _, m in ipairs(maps) do
        if string.find(string.lower(m.Name), lower, 1, true) then return m end
    end
    for _, obj in ipairs(getSnapshot()) do
        if string.find(string.lower(obj.Name), lower, 1, true) then
            local pos = objectPosition(obj)
            if pos then
                return { Name = obj.Name, Position = pos, Object = obj }
            end
        end
    end
    return nil
end

local function parseVector3(text)
    local x, y, z = string.match(text or "", "([%-%d%.]+)%s*,%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)")
    if x and y and z then
        local nx, ny, nz = tonumber(x), tonumber(y), tonumber(z)
        if nx and ny and nz then
            return Vector3.new(nx, ny, nz)
        end
    end
    return nil
end

local SmoothTP = false

local function teleportTo(pos)
    local root = getRootPart()
    if not root or not pos then return false end

    if SmoothTP then
        return travelTo(pos, "map tujuan")
    end

    local targetCF = CFrame.new(pos + Vector3.new(0, 6, 0))
    local char = getCharacter()
    if char and char.PivotTo then
        pcall(function() char:PivotTo(targetCF) end)
    else
        root.CFrame = targetCF
    end
    task.wait(0.2)
    return true
end
-- ═══════════════════════════════════════════
--  CONFIG MANAGER
-- ═══════════════════════════════════════════
local CONFIG_FILE = "cultivationlegends_config.json"

local ConfigRegistry = {
    UseSword      = true,
    FlyNoclip     = true,
    FlySpeed      = 45,
    HarvestTarget = 20,
    RebirthDelay  = 4,
    MeditateTime  = 10,
    TalentFast    = true,
    TalentDelay   = 0.6,
    LanternRadius = 1200,
    WalkSpeed     = 16,
    AntiAfk       = true,
    Fullbright    = false,
    AutoSave      = true,
    ToggleKey     = "RightShift",
}

local PERSIST_KEYS = {
    "UseSword", "FlyNoclip", "FlySpeed", "HarvestTarget", "RebirthDelay",
    "MeditateTime", "TalentFast", "TalentDelay", "LanternRadius", "WalkSpeed",
    "AntiAfk", "Fullbright", "AutoSave", "ToggleKey",
}

local function saveConfig(showNotify)
    local payload = { SavedAt = os.time(), Settings = {} }
    for _, key in ipairs(PERSIST_KEYS) do
        payload.Settings[key] = ConfigRegistry[key]
    end

    local ok = pcall(function()
        if not writefile then error("writefile tidak tersedia") end
        writefile(CONFIG_FILE, HttpService:JSONEncode(payload))
    end)

    if showNotify and Window then
        Window:Notify({
            Title = ok and "Config Tersimpan" or "Config Gagal",
            Content = ok and "Pengaturan berhasil disimpan." or "Executor tidak mendukung writefile.",
            Duration = 3,
        })
    end
    return ok
end

local LoadingConfig = false

local function loadConfig(showNotify)
    if not (readfile and isfile) then return false end
    local ok, content = pcall(function()
        if isfile(CONFIG_FILE) then return readfile(CONFIG_FILE) end
        return nil
    end)
    if not ok or not content or content == "" then return false end

    local parseOk, parsed = pcall(function()
        return HttpService:JSONDecode(content)
    end)
    if not parseOk or type(parsed) ~= "table" or type(parsed.Settings) ~= "table" then
        return false
    end

    LoadingConfig = true
    for _, key in ipairs(PERSIST_KEYS) do
        local val = parsed.Settings[key]
        if val ~= nil then
            ConfigRegistry[key] = val
            if ToggleObjects[key] then
                pcall(function() ToggleObjects[key]:Set(val, true) end)
            end
            if SliderObjects[key] then
                pcall(function() SliderObjects[key]:Set(val, true) end)
            end
        end
    end
    LoadingConfig = false

    if ConfigRegistry.ToggleKey and Enum.KeyCode[ConfigRegistry.ToggleKey] then
        Window.ToggleKey = Enum.KeyCode[ConfigRegistry.ToggleKey]
    end

    if showNotify and Window then
        Window:Notify({ Title = "Config Dimuat", Content = "Pengaturan tersimpan berhasil diterapkan.", Duration = 3 })
    end
    return true
end

local SaveQueued = false

local function queueSave()
    if SaveQueued then return end
    SaveQueued = true
    task.delay(1.5, function()
        SaveQueued = false
        if ConfigRegistry.AutoSave and not LoadingConfig then
            saveConfig(false)
        end
    end)
end

local function markConfig(key, value)
    ConfigRegistry[key] = value
    if ConfigRegistry.AutoSave and not LoadingConfig then
        queueSave()
    end
end

-- ═══════════════════════════════════════════
--  WINDOW UTAMA (UNIONSAL GLASS BENTO)
-- ═══════════════════════════════════════════
Window = Unionsal:CreateWindow({
    Name       = "unionsal",
    Subtitle   = ".gg/unionsal",
    GameName   = "Cultivation Legends",
    ScriptName = "cultivationlegends.lua",
    Version    = "v1.3",
})

-- ═══════════════════════════════════════════
--  KARTU STATUS DINAMIS
-- ═══════════════════════════════════════════
local function createStatusCard(tab, titleText, order)
    local page = tab.Page
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 62)
    card.BackgroundColor3 = Color3.fromRGB(22, 17, 34)
    card.BorderSizePixel = 0
    card.LayoutOrder = -20 + (order or 0)
    card.Parent = page

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = card

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(44, 36, 62)
    stroke.Thickness = 1
    stroke.Parent = card

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -24, 0, 18)
    title.Position = UDim2.new(0, 12, 0, 7)
    title.BackgroundTransparency = 1
    title.Text = titleText
    title.Font = Enum.Font.GothamBold
    title.TextSize = 12
    title.TextColor3 = Color3.fromRGB(175, 110, 255)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = card

    local body = Instance.new("TextLabel")
    body.Size = UDim2.new(1, -24, 0, 34)
    body.Position = UDim2.new(0, 12, 0, 25)
    body.BackgroundTransparency = 1
    body.Text = "Idle"
    body.Font = Enum.Font.Gotham
    body.TextSize = 10
    body.TextColor3 = Color3.fromRGB(165, 155, 185)
    body.TextXAlignment = Enum.TextXAlignment.Left
    body.TextYAlignment = Enum.TextYAlignment.Top
    body.TextWrapped = true
    body.Parent = card

    return function(text)
        body.Text = tostring(text)
    end
end

-- ═══════════════════════════════════════════
--  STOP SEMUA AUTO
-- ═══════════════════════════════════════════
local function stopAll()
    Rebirth.Auto = false
    Lantern.Auto = false
    Talent.Auto = false
    Festival.AutoShop = false
    Movement.Abort = true

    for _, key in ipairs({ "AutoRebirth", "AutoLantern", "AutoTalent", "AutoFestivalShop" }) do
        if ToggleObjects[key] then
            pcall(function() ToggleObjects[key]:Set(false, false) end)
        end
    end
    setStatus("rebirth", "Semua auto dihentikan.")
    setStatus("lantern", "Semua auto dihentikan.")
    setStatus("talent", "Semua auto dihentikan.")
    setStatus("shop", "Semua auto dihentikan.")
end

-- ═══════════════════════════════════════════
--  TAB: REBIRTH / KULTIVASI
-- ═══════════════════════════════════════════
local RebirthTab = Window:CreateTab("Rebirth", "zap", "Main")

local cultStatus = createStatusCard(RebirthTab, "Status Kultivasi", 0)
for _, key in ipairs({ "rebirth", "harvest", "cauldron", "meditate", "move", "route", "rebirthAction" }) do
    StatusSetters[key] = cultStatus
end

local detectStatus = createStatusCard(RebirthTab, "Deteksi Objek", 1)
StatusSetters.detect = detectStatus

RebirthTab:CreateSection("Auto Rebirth")

ToggleObjects.AutoRebirth = RebirthTab:CreateToggle({
    Name = "Auto Rebirth (Otomatis Penuh)",
    CurrentValue = false,
    Callback = function(v)
        Rebirth.Auto = v
        if v then
            Movement.Abort = false
            startAutoRebirth()
            Window:Notify({
                Title = "Auto Rebirth",
                Content = "Aktif! Script akan ambil bahan, craft ramuan, meditasi, lalu rebirth.",
                Duration = 4,
            })
        else
            Movement.Abort = true
            Window:Notify({ Title = "Auto Rebirth", Content = "Dihentikan.", Duration = 2 })
        end
    end,
})

ToggleObjects.UseRoute = RebirthTab:CreateToggle({
    Name = "Pakai Route Kalau Ada Titik",
    CurrentValue = true,
    Callback = function(v)
        Rebirth.UseRoute = v
    end,
})

ToggleObjects.UseSword = RebirthTab:CreateToggle({
    Name = "Terbang Pakai Sword (otomatis kalau punya)",
    CurrentValue = true,
    Callback = function(v)
        Movement.UseSword = v
        markConfig("UseSword", v)
        Window:Notify({
            Title = "Sword Flight",
            Content = v and "Auto terbang aktif (kalau sword terdeteksi)." or "Auto terbang dimatikan, karakter akan berjalan.",
            Duration = 2,
        })
    end,
})

ToggleObjects.FlyNoclip = RebirthTab:CreateToggle({
    Name = "Tembus Objek Saat Terbang",
    CurrentValue = true,
    Callback = function(v)
        Movement.FlyNoclip = v
        markConfig("FlyNoclip", v)
    end,
})

ToggleObjects.TriggerNative = RebirthTab:CreateToggle({
    Name = "Picu Flight Bawaan Game (eksperimental)",
    CurrentValue = false,
    Callback = function(v)
        Movement.TriggerNative = v
        Window:Notify({
            Title = "Native Flight",
            Content = v and "Script akan mencoba mengaktifkan flight bawaan sword." or "Hanya memakai flight internal script.",
            Duration = 2,
        })
    end,
})

SliderObjects.FlySpeed = RebirthTab:CreateSlider({
    Name = "Kecepatan Terbang",
    Range = { 15, 150 },
    Increment = 5,
    Suffix = " spd",
    CurrentValue = 45,
    Callback = function(v)
        Movement.FlySpeed = v
        markConfig("FlySpeed", v)
    end,
})

SliderObjects.HarvestTarget = RebirthTab:CreateSlider({
    Name = "Target Bahan Sebelum Craft",
    Range = { 1, 100 },
    Increment = 1,
    Suffix = " item",
    CurrentValue = 20,
    Callback = function(v)
        Rebirth.HarvestTarget = v
        markConfig("HarvestTarget", v)
    end,
})

SliderObjects.RebirthDelay = RebirthTab:CreateSlider({
    Name = "Jeda Antar Siklus Rebirth",
    Range = { 1, 30 },
    Increment = 1,
    Suffix = " detik",
    CurrentValue = 4,
    Callback = function(v)
        Rebirth.Delay = v
        markConfig("RebirthDelay", v)
    end,
})

SliderObjects.MeditateTime = RebirthTab:CreateSlider({
    Name = "Durasi Meditasi",
    Range = { 3, 120 },
    Increment = 1,
    Suffix = " detik",
    CurrentValue = 10,
    Callback = function(v)
        Meditate.Time = v
        markConfig("MeditateTime", v)
    end,
})

RebirthTab:CreateButton({
    Name = "Jalankan 1 Siklus Rebirth Sekarang",
    Callback = function()
        Movement.Abort = false
        task.spawn(runRebirthCycle)
    end,
})

RebirthTab:CreateButton({
    Name = "Stop Semua Auto",
    Callback = function()
        stopAll()
        Window:Notify({ Title = "Stop", Content = "Semua proses auto dihentikan.", Duration = 2 })
    end,
})

RebirthTab:CreateSection("Aksi Manual")

RebirthTab:CreateButton({
    Name = "Ambil Tumbuhan di Sekitar",
    Callback = function()
        Movement.Abort = false
        task.spawn(function()
            local got = harvestOnce(1200)
            Window:Notify({ Title = "Harvest", Content = got > 0 and ("Berhasil ambil " .. got .. " tumbuhan.") or "Tidak ada tumbuhan terdeteksi.", Duration = 3 })
        end)
    end,
})

RebirthTab:CreateButton({
    Name = "Buat Ramuan di Cauldron",
    Callback = function()
        Movement.Abort = false
        task.spawn(useCauldron)
    end,
})

RebirthTab:CreateButton({
    Name = "Meditasi Sekarang",
    Callback = function()
        Movement.Abort = false
        task.spawn(meditateOnce)
    end,
})

RebirthTab:CreateButton({
    Name = "Rebirth Sekarang",
    Callback = function()
        Movement.Abort = false
        task.spawn(rebirthOnce)
    end,
})

RebirthTab:CreateButton({
    Name = "Scan Ulang Objek (Debug Console)",
    Callback = function()
        local kinds = { "plant", "lantern", "cauldron", "meditate", "rebirth", "festivalShop" }
        print("[Cultivation Legends] === HASIL SCAN OBJEK ===")
        for _, kind in ipairs(kinds) do
            local targets = findTargets(kind, 5000, true)
            local names = {}
            for i = 1, math.min(#targets, 12) do
                table.insert(names, targets[i].Object.Name)
            end
            print(string.format("%s (%d): %s", kind, #targets, table.concat(names, ", ")))
        end
        local sword = getSwordTool()
        print("sword: " .. (sword and sword.Name or "tidak ada"))
        Window:Notify({ Title = "Scan Selesai", Content = "Hasil detail ada di console (F9).", Duration = 4 })
    end,
})

RebirthTab:CreateSection("Route / Jalan Kultivasi")
RebirthTab:CreateLabel("Susun titik rute sesuai jalan kultivasi. Karakter akan berjalan/terbang urut titik, lalu interaksi otomatis.")

local function routeResultNotify(ok, message)
    Window:Notify({
        Title = ok and "Route" or "Route Gagal",
        Content = message,
        Duration = 4,
    })
end

RebirthTab:CreateButton({
    Name = "Tambah Titik: Posisi Sekarang",
    Callback = function()
        local ok, msg = addWaypoint("custom")
        routeResultNotify(ok, msg)
    end,
})

RebirthTab:CreateButton({
    Name = "Tambah Titik: Tumbuhan Terdekat",
    Callback = function()
        local ok, msg = addWaypoint("plant")
        routeResultNotify(ok, msg)
    end,
})

RebirthTab:CreateButton({
    Name = "Tambah Titik: Cauldron Terdekat",
    Callback = function()
        local ok, msg = addWaypoint("cauldron")
        routeResultNotify(ok, msg)
    end,
})

RebirthTab:CreateButton({
    Name = "Tambah Titik: Meditasi Terdekat",
    Callback = function()
        local ok, msg = addWaypoint("meditate")
        routeResultNotify(ok, msg)
    end,
})

RebirthTab:CreateButton({
    Name = "Tambah Titik: Rebirth Terdekat",
    Callback = function()
        local ok, msg = addWaypoint("rebirth")
        routeResultNotify(ok, msg)
    end,
})

RebirthTab:CreateButton({
    Name = "Tambah Titik: Lantern Terdekat",
    Callback = function()
        local ok, msg = addWaypoint("lantern")
        routeResultNotify(ok, msg)
    end,
})

RebirthTab:CreateButton({
    Name = "Buat Route Otomatis (Bahan -> Cauldron -> Meditasi -> Rebirth)",
    Callback = function()
        local count, found = buildAutoRoute()
        if count == 0 then
            routeResultNotify(false, "Tidak ada objek terdeteksi. Tambah titik manual dulu.")
        else
            routeResultNotify(true, string.format(
                "Route otomatis: %d titik (cauldron:%s, meditasi:%s, rebirth:%s)",
                count,
                found.cauldron and "ya" or "tidak",
                found.meditate and "ya" or "tidak",
                found.rebirth and "ya" or "tidak"
            ))
        end
    end,
})

RebirthTab:CreateButton({
    Name = "Jalankan Route Sekarang",
    Callback = function()
        Movement.Abort = false
        task.spawn(runRoute)
    end,
})

RebirthTab:CreateButton({
    Name = "Hapus Titik Terakhir",
    Callback = function()
        local ok, msg = removeLastWaypoint()
        routeResultNotify(ok, msg)
    end,
})

RebirthTab:CreateButton({
    Name = "Kosongkan Route",
    Callback = function()
        local ok, msg = clearRoute()
        routeResultNotify(ok, msg)
    end,
})

RebirthTab:CreateButton({
    Name = "Simpan Route",
    Callback = function()
        local ok, msg = saveRoute()
        routeResultNotify(ok, msg)
    end,
})

RebirthTab:CreateButton({
    Name = "Muat Route Tersimpan",
    Callback = function()
        local ok, msg = loadRoute()
        routeResultNotify(ok, msg)
    end,
})
-- ═══════════════════════════════════════════
--  TAB: FESTIVAL
-- ═══════════════════════════════════════════
local FestivalTab = Window:CreateTab("Festival", "star", "Main")

local eventStatus = createStatusCard(FestivalTab, "Status Event Festival", 0)
StatusSetters.lantern = eventStatus
StatusSetters.shop = eventStatus

FestivalTab:CreateSection("Auto Lantern (Event)")

ToggleObjects.AutoLantern = FestivalTab:CreateToggle({
    Name = "Auto Cari & Ambil Lantern",
    CurrentValue = false,
    Callback = function(v)
        Lantern.Auto = v
        if v then
            Movement.Abort = false
            startAutoLantern()
            Window:Notify({
                Title = "Auto Lantern",
                Content = "Aktif! Script akan mencari lantern event seperti ambil tumbuhan.",
                Duration = 4,
            })
        else
            Movement.Abort = true
            Window:Notify({ Title = "Auto Lantern", Content = "Dihentikan.", Duration = 2 })
        end
    end,
})

SliderObjects.LanternRadius = FestivalTab:CreateSlider({
    Name = "Radius Pencarian Lantern",
    Range = { 100, 5000 },
    Increment = 100,
    Suffix = " studs",
    CurrentValue = 1200,
    Callback = function(v)
        Lantern.Radius = v
        markConfig("LanternRadius", v)
    end,
})

FestivalTab:CreateButton({
    Name = "Ambil Lantern Sekarang",
    Callback = function()
        Movement.Abort = false
        task.spawn(function()
            local got = collectLanternsOnce(Lantern.Radius)
            Window:Notify({
                Title = "Lantern",
                Content = got > 0 and ("Berhasil ambil " .. got .. " lantern.") or "Belum ada lantern event terdeteksi.",
                Duration = 3,
            })
        end)
    end,
})

FestivalTab:CreateSection("Festival Shop")

ToggleObjects.AutoFestivalShop = FestivalTab:CreateToggle({
    Name = "Auto Beli di Festival Shop",
    CurrentValue = false,
    Callback = function(v)
        Festival.AutoShop = v
        if v then
            Movement.Abort = false
            startAutoFestivalShop()
            Window:Notify({
                Title = "Festival Shop",
                Content = "Aktif! Script akan buka shop dan membeli item sesuai daftar.",
                Duration = 4,
            })
        else
            Window:Notify({ Title = "Festival Shop", Content = "Dihentikan.", Duration = 2 })
        end
    end,
})

FestivalTab:CreateInput({
    Name = "Nama Item (pisah koma)",
    PlaceholderText = "contoh: Lantern, Festival Ticket",
    Callback = function(text)
        Festival.BuyList = parseList(text)
    end,
})

SliderObjects.BuyDelay = FestivalTab:CreateSlider({
    Name = "Jeda Antar Pembelian",
    Range = { 0.2, 5 },
    Increment = 0.1,
    Suffix = " detik",
    CurrentValue = 0.7,
    Callback = function(v)
        Festival.Delay = v
    end,
})

FestivalTab:CreateButton({
    Name = "Buka Festival Shop",
    Callback = function()
        Movement.Abort = false
        task.spawn(function()
            local ok = openFestivalShop()
            Window:Notify({
                Title = "Festival Shop",
                Content = ok and "Shop dibuka / didekati." or "Shop festival tidak ditemukan.",
                Duration = 3,
            })
        end)
    end,
})

FestivalTab:CreateButton({
    Name = "Beli Item Sekarang",
    Callback = function()
        task.spawn(function()
            local bought = buyFestivalItems()
            Window:Notify({
                Title = "Festival Shop",
                Content = bought > 0 and ("Membeli " .. bought .. " item.") or "Tidak ada tombol beli yang cocok.",
                Duration = 3,
            })
        end)
    end,
})

FestivalTab:CreateButton({
    Name = "TP ke Festival Shop",
    Callback = function()
        local target = findTargets("festivalShop", 5000, true)[1]
        if target and teleportTo(target.Position) then
            Window:Notify({ Title = "Festival", Content = "TP ke " .. target.Object.Name, Duration = 3 })
        else
            Window:Notify({ Title = "Festival", Content = "Festival shop tidak ditemukan.", Duration = 3 })
        end
    end,
})

FestivalTab:CreateButton({
    Name = "TP ke Lantern Terdekat",
    Callback = function()
        local target = findTargets("lantern", 5000, true)[1]
        if target and teleportTo(target.Position) then
            Window:Notify({ Title = "Festival", Content = "TP ke " .. target.Object.Name, Duration = 3 })
        else
            Window:Notify({ Title = "Festival", Content = "Belum ada lantern terdeteksi.", Duration = 3 })
        end
    end,
})

FestivalTab:CreateButton({
    Name = "Stop Festival Auto",
    Callback = function()
        Lantern.Auto = false
        Festival.AutoShop = false
        Movement.Abort = true
        if ToggleObjects.AutoLantern then ToggleObjects.AutoLantern:Set(false, false) end
        if ToggleObjects.AutoFestivalShop then ToggleObjects.AutoFestivalShop:Set(false, false) end
        Window:Notify({ Title = "Festival", Content = "Auto festival dihentikan.", Duration = 2 })
    end,
})

-- ═══════════════════════════════════════════
--  TAB: TALENT
-- ═══════════════════════════════════════════
local TalentTab = Window:CreateTab("Talent", "diamond", "Main")

local talentStatus = createStatusCard(TalentTab, "Status Talent Gacha", 0)
StatusSetters.talent = talentStatus

TalentTab:CreateSection("Auto Talent Gacha")

ToggleObjects.AutoTalent = TalentTab:CreateToggle({
    Name = "Auto Talent Gacha (terus roll)",
    CurrentValue = false,
    Callback = function(v)
        Talent.Auto = v
        if v then
            startAutoTalent()
            Window:Notify({
                Title = "Auto Talent",
                Content = "Aktif! Pastikan menu talent / gacha sudah terbuka.",
                Duration = 4,
            })
        else
            Window:Notify({ Title = "Auto Talent", Content = "Dihentikan.", Duration = 2 })
        end
    end,
})

ToggleObjects.TalentFast = TalentTab:CreateToggle({
    Name = "Fast Mode (langsung gacha lagi kalau dapat)",
    CurrentValue = true,
    Callback = function(v)
        Talent.Fast = v
        markConfig("TalentFast", v)
    end,
})

ToggleObjects.TalentEquip = TalentTab:CreateToggle({
    Name = "Auto Equip / Simpan Hasil Talent",
    CurrentValue = true,
    Callback = function(v)
        Talent.Equip = v
    end,
})

SliderObjects.TalentDelay = TalentTab:CreateSlider({
    Name = "Jeda Gacha",
    Range = { 0.1, 5 },
    Increment = 0.1,
    Suffix = " detik",
    CurrentValue = 0.6,
    Callback = function(v)
        Talent.Delay = v
        markConfig("TalentDelay", v)
    end,
})

TalentTab:CreateButton({
    Name = "Gacha Talent Sekali",
    Callback = function()
        local ok = talentRollOnce()
        Window:Notify({
            Title = "Talent Gacha",
            Content = ok and "Tombol gacha diklik." or "Tombol gacha talent tidak ditemukan (buka menu talent).",
            Duration = 3,
        })
    end,
})

TalentTab:CreateButton({
    Name = "Scan Tombol Talent (Debug Console)",
    Callback = function()
        local pg = getPlayerGui()
        local count = 0
        print("[Cultivation Legends] === TOMBOL GUI TERLIHAT ===")
        if pg then
            for _, obj in ipairs(pg:GetDescendants()) do
                if obj:IsA("GuiButton") and isGuiVisible(obj) then
                    local label = obj.Name
                    if obj:IsA("TextButton") then label = label .. " | " .. obj.Text end
                    print("  " .. label)
                    count = count + 1
                    if count >= 60 then break end
                end
            end
        end
        Window:Notify({ Title = "Scan Tombol", Content = count .. " tombol terlihat. Detail di console (F9).", Duration = 4 })
    end,
})

-- ═══════════════════════════════════════════
--  TAB: TELEPORT
-- ═══════════════════════════════════════════
local TeleportTab = Window:CreateTab("Teleport", "navigation", "Main")

local initialMaps = scanMaps(true)
local mapOptions = {}
for i = 1, math.min(#initialMaps, 40) do
    table.insert(mapOptions, initialMaps[i].Name)
end
if #mapOptions == 0 then
    mapOptions = { "(belum ada map terdeteksi)" }
end

local selectedMap = mapOptions[1]

TeleportTab:CreateSection("Teleport by Map Name")

TeleportTab:CreateDropdown({
    Name = "Map Terdeteksi",
    Options = mapOptions,
    CurrentValue = selectedMap,
    Callback = function(opt)
        selectedMap = opt
    end,
})

TeleportTab:CreateButton({
    Name = "TP ke Map Dipilih",
    Callback = function()
        if selectedMap == "(belum ada map terdeteksi)" then
            Window:Notify({ Title = "Teleport", Content = "Belum ada map terdeteksi. Klik Scan Ulang Map.", Duration = 3 })
            return
        end
        local map = findMap(selectedMap)
        if map and teleportTo(map.Position) then
            Window:Notify({ Title = "Teleport", Content = "Teleport ke: " .. map.Name, Duration = 3 })
        else
            Window:Notify({ Title = "Teleport", Content = "Map tidak ditemukan.", Duration = 3 })
        end
    end,
})

TeleportTab:CreateButton({
    Name = "Scan Ulang Map (Console)",
    Callback = function()
        local maps = scanMaps(true)
        print("[Cultivation Legends] === MAP TERDETEKSI (" .. #maps .. ") ===")
        for i = 1, math.min(#maps, 60) do
            print(string.format("  %d. %s", i, maps[i].Name))
        end
        Window:Notify({
            Title = "Scan Map",
            Content = string.format("%d map terdeteksi. Map baru bisa diketik di 'Cari Nama Map'. Detail di console (F9).", #maps),
            Duration = 5,
        })
    end,
})

local mapQuery = ""

TeleportTab:CreateInput({
    Name = "Cari Nama Map",
    PlaceholderText = "contoh: Azure / Island_3966832531",
    Callback = function(text)
        mapQuery = text
    end,
})

TeleportTab:CreateButton({
    Name = "TP by Nama Map",
    Callback = function()
        local query = string.gsub(mapQuery or "", "^%s*(.-)%s*$", "%1")
        if query == "" then
            Window:Notify({ Title = "Teleport", Content = "Isi nama map dulu.", Duration = 2 })
            return
        end
        local map = findMap(query)
        if map and teleportTo(map.Position) then
            Window:Notify({ Title = "Teleport", Content = "Teleport ke: " .. map.Name, Duration = 3 })
        else
            Window:Notify({ Title = "Teleport", Content = "Map '" .. query .. "' tidak ditemukan.", Duration = 3 })
        end
    end,
})

TeleportTab:CreateSection("Koordinat, Spawn & Player")

ToggleObjects.SmoothTP = TeleportTab:CreateToggle({
    Name = "TP Halus (terbang / jalan, tidak instan)",
    CurrentValue = false,
    Callback = function(v)
        SmoothTP = v
    end,
})

local coordText = ""

TeleportTab:CreateInput({
    Name = "Koordinat (x,y,z)",
    PlaceholderText = "contoh: 100, 20, 300",
    Callback = function(text)
        coordText = text
    end,
})

TeleportTab:CreateButton({
    Name = "TP ke Koordinat",
    Callback = function()
        local pos = parseVector3(coordText)
        if pos and teleportTo(pos) then
            Window:Notify({ Title = "Teleport", Content = string.format("TP ke %.0f, %.0f, %.0f", pos.X, pos.Y, pos.Z), Duration = 3 })
        else
            Window:Notify({ Title = "Teleport", Content = "Format koordinat salah. Gunakan x,y,z", Duration = 3 })
        end
    end,
})

TeleportTab:CreateButton({
    Name = "TP ke Spawn",
    Callback = function()
        local spawnPart = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
        local pos = spawnPart and spawnPart.Position or Vector3.new(0, 10, 0)
        if teleportTo(pos) then
            Window:Notify({ Title = "Teleport", Content = "Kembali ke spawn.", Duration = 2 })
        end
    end,
})

local function getOtherPlayerNames()
    local names = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(names, plr.Name)
        end
    end
    if #names == 0 then
        names = { "(tidak ada player lain)" }
    end
    return names
end

local selectedPlayerName = getOtherPlayerNames()[1]

TeleportTab:CreateDropdown({
    Name = "Pilih Player",
    Options = getOtherPlayerNames(),
    Callback = function(opt)
        selectedPlayerName = opt
    end,
})

TeleportTab:CreateButton({
    Name = "TP ke Player",
    Callback = function()
        if not selectedPlayerName or selectedPlayerName == "(tidak ada player lain)" then
            Window:Notify({ Title = "Teleport", Content = "Tidak ada player lain.", Duration = 2 })
            return
        end
        local target = Players:FindFirstChild(selectedPlayerName)
        local targetRoot = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        if targetRoot and teleportTo(targetRoot.Position) then
            Window:Notify({ Title = "Teleport", Content = "TP ke " .. selectedPlayerName, Duration = 2 })
        else
            Window:Notify({ Title = "Teleport", Content = "Player target tidak ditemukan.", Duration = 2 })
        end
    end,
})
-- ═══════════════════════════════════════════
--  TAB: PLAYER
-- ═══════════════════════════════════════════
local PlayerTab = Window:CreateTab("Player", "user", "Main")

local noclipActive = false
local noclipConn = nil
local noclipSaved = {}

local function setNoclip(v)
    noclipActive = v
    if v and not noclipConn then
        noclipSaved = {}
        noclipConn = RunService.Stepped:Connect(function()
            if not noclipActive then return end
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        if noclipSaved[part] == nil then
                            noclipSaved[part] = part.CanCollide
                        end
                        if part.CanCollide then
                            part.CanCollide = false
                        end
                    end
                end
            end
        end)
    elseif not v and noclipConn then
        noclipConn:Disconnect()
        noclipConn = nil
        for part, state in pairs(noclipSaved) do
            if part.Parent then
                pcall(function() part.CanCollide = state end)
            end
        end
        noclipSaved = {}
    end
end

local antiAfkConn = nil

local function setAntiAfk(v)
    if v and not antiAfkConn then
        antiAfkConn = LocalPlayer.Idled:Connect(function()
            if not ConfigRegistry.AntiAfk or not VirtualUser then return end
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.zero)
            end)
        end)
    elseif not v and antiAfkConn then
        antiAfkConn:Disconnect()
        antiAfkConn = nil
    end
end

local Lighting = game:GetService("Lighting")
local savedLighting = nil

local function setFullbright(v)
    if v then
        if not savedLighting then
            savedLighting = {
                Ambient = Lighting.Ambient,
                Brightness = Lighting.Brightness,
                ClockTime = Lighting.ClockTime,
                FogEnd = Lighting.FogEnd,
            }
        end
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
    elseif savedLighting then
        Lighting.Ambient = savedLighting.Ambient
        Lighting.Brightness = savedLighting.Brightness
        Lighting.ClockTime = savedLighting.ClockTime
        Lighting.FogEnd = savedLighting.FogEnd
        savedLighting = nil
    end
end

PlayerTab:CreateSection("Karakter & Fisika")

SliderObjects.WalkSpeed = PlayerTab:CreateSlider({
    Name = "WalkSpeed",
    Range = { 1, 200 },
    Increment = 1,
    Suffix = " spd",
    CurrentValue = 16,
    Callback = function(v)
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = v end
        markConfig("WalkSpeed", v)
    end,
})

ToggleObjects.NoClip = PlayerTab:CreateToggle({
    Name = "NoClip (Tembus Dinding)",
    CurrentValue = false,
    Callback = function(v)
        setNoclip(v)
        Window:Notify({ Title = "NoClip", Content = v and "Aktif." or "Nonaktif.", Duration = 2 })
    end,
})

ToggleObjects.AntiAfk = PlayerTab:CreateToggle({
    Name = "Anti-AFK (Cegah Disconnect)",
    CurrentValue = true,
    Callback = function(v)
        markConfig("AntiAfk", v)
        setAntiAfk(v)
    end,
})

ToggleObjects.Fullbright = PlayerTab:CreateToggle({
    Name = "Fullbright (Terang Benderang)",
    CurrentValue = false,
    Callback = function(v)
        setFullbright(v)
        markConfig("Fullbright", v)
    end,
})

PlayerTab:CreateButton({
    Name = "Tes Sword Flight (Terbang ke Depan)",
    Callback = function()
        local root = getRootPart()
        local sword = getSwordTool()
        if not root then return end
        if not sword then
            Window:Notify({ Title = "Sword Flight", Content = "Sword tidak ditemukan di Backpack / karakter.", Duration = 3 })
            return
        end
        Movement.Abort = false
        task.spawn(function()
            local destination = root.Position + (root.CFrame.LookVector * 60) + Vector3.new(0, 20, 0)
            local ok = flyTo(destination)
            Window:Notify({
                Title = "Sword Flight",
                Content = ok and ("Berhasil terbang pakai " .. sword.Name) or "Gagal mencapai tujuan (cek jarak / posisi).",
                Duration = 3,
            })
        end)
    end,
})

PlayerTab:CreateButton({
    Name = "Reset Karakter / Respawn",
    Callback = function()
        local hum = getHumanoid()
        if hum then hum.Health = 0 end
    end,
})

-- ═══════════════════════════════════════════
--  TAB: SETTINGS
-- ═══════════════════════════════════════════
local SettingsTab = Window:CreateTab("Settings", "settings", "Config")

SettingsTab:CreateSection("Keybind & Panduan")

SettingsTab:CreateKeybind({
    Name = "Tombol Buka / Tutup UI",
    CurrentKey = Window.ToggleKey or Enum.KeyCode.RightShift,
    Callback = function(newKey)
        Window.ToggleKey = newKey
        markConfig("ToggleKey", newKey.Name)
        Window:Notify({ Title = "Keybind", Content = "Tombol menu diubah ke: [" .. newKey.Name .. "]", Duration = 3 })
    end,
})

SettingsTab:CreateParagraph({
    Title = "Cara Pakai Cepat",
    Content = "1. Auto Rebirth: nyalakan toggle, script cari bahan -> cauldron -> meditasi -> rebirth.\n" ..
              "2. Kalau punya sword, karakter terbang; kalau tidak ada, karakter berjalan (pathfinding).\n" ..
              "3. Route: tambah titik sesuai jalan kultivasi, lalu jalankan. Titik bisa disimpan.\n" ..
              "4. Auto Festival: lantern dicari seperti tumbuhan; shop dibeli sesuai daftar item.\n" ..
              "5. Auto Talent: buka menu talent dulu, lalu nyalakan toggle.\n" ..
              "6. TP: pilih map terdeteksi atau ketik nama map / koordinat.\n" ..
              "7. Catatan: cultivationlegends.txt isinya kosong (gagal decompile), jadi nama item/map dideteksi otomatis. Kalau ada yang meleset, tambahkan kata kuncinya di KEYWORDS / CUSTOM_MAPS bagian atas file.",
})

SettingsTab:CreateSection("Konfigurasi")

ToggleObjects.AutoSave = SettingsTab:CreateToggle({
    Name = "Auto-Save Konfigurasi",
    CurrentValue = true,
    Callback = function(v)
        ConfigRegistry.AutoSave = v
        Window:Notify({ Title = "Auto-Save", Content = v and "Aktif." or "Nonaktif.", Duration = 2 })
    end,
})

SettingsTab:CreateButton({
    Name = "Simpan Konfigurasi",
    Callback = function()
        saveConfig(true)
    end,
})

SettingsTab:CreateButton({
    Name = "Muat Konfigurasi",
    Callback = function()
        loadConfig(true)
    end,
})

SettingsTab:CreateButton({
    Name = "Reset Konfigurasi ke Default",
    Callback = function()
        pcall(function()
            if delfile and isfile and isfile(CONFIG_FILE) then
                delfile(CONFIG_FILE)
            end
        end)
        Window:Notify({ Title = "Config Reset", Content = "File konfigurasi dihapus. Restart script untuk default.", Duration = 3 })
    end,
})

SettingsTab:CreateButton({
    Name = "Stop Semua Auto",
    Callback = function()
        stopAll()
        Window:Notify({ Title = "Stop", Content = "Semua proses auto dihentikan.", Duration = 2 })
    end,
})

SettingsTab:CreateLabel("Tips: kalau ada item/map yang tidak terdeteksi, tambahkan kata kuncinya di tabel KEYWORDS / CUSTOM_MAPS di bagian atas file.")

-- ═══════════════════════════════════════════
--  DETEKSI OBJEK LIVE
-- ═══════════════════════════════════════════
task.spawn(function()
    task.wait(1)
    while true do
        local ok, err = pcall(function()
            local plantCount    = #findTargets("plant", 5000)
            local lanternCount  = #findTargets("lantern", 5000)
            local cauldronCount = #findTargets("cauldron", 5000)
            local meditateCount = #findTargets("meditate", 5000)
            local rebirthCount  = #findTargets("rebirth", 5000)
            local sword = getSwordTool()

            setStatus("detect", string.format(
                "Tumbuhan: %d | Lantern: %d | Cauldron: %d | Meditasi: %d | Rebirth: %d | Sword: %s",
                plantCount, lanternCount, cauldronCount, meditateCount, rebirthCount,
                sword and "ada" or "tidak ada"
            ))
        end)
        if not ok then
            setStatus("detect", "Gagal scan: " .. tostring(err))
        end
        task.wait(2.5)
    end
end)

-- ═══════════════════════════════════════════
--  CHARACTER RESPAWN HANDLER
-- ═══════════════════════════════════════════
LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(1)
    local hum = character and character:FindFirstChildOfClass("Humanoid")
    if hum and ConfigRegistry.WalkSpeed then
        hum.WalkSpeed = ConfigRegistry.WalkSpeed
    end
end)

-- ═══════════════════════════════════════════
--  STARTUP
-- ═══════════════════════════════════════════
task.spawn(function()
    task.wait(0.8)
    loadConfig(false)
    setAntiAfk(ConfigRegistry.AntiAfk)
    setFullbright(ConfigRegistry.Fullbright)
end)

task.spawn(function()
    task.wait(1.4)
    local ok, msg = loadRoute()
    if ok then
        print("[Cultivation Legends] " .. tostring(msg))
    end
end)

task.delay(1.8, function()
    local sword = getSwordTool()
    Window:Notify({
        Title = "Cultivation Legends",
        Content = sword
            and ("Sword terdeteksi: " .. sword.Name .. ". Auto terbang siap dipakai.")
            or "Sword tidak terdeteksi. Auto rebirth akan berjalan kaki dulu.",
        Duration = 6,
    })
end)
