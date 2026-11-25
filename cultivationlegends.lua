-- ╔══════════════════════════════════════════════════════════════╗
-- ║      UNIONSAL SCRIPT HUB — Cultivation Legends (Obitel)      ║
-- ║   Runtime Shared/Client Discovery • Bagua Circle Cultivation ║
-- ║   Heartbeat Sword Flight • Auto Herb/Cauldron • Fast Talent  ║
-- ║   1-Click Dynamic Island & Map Teleport • Festival Charm     ║
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

local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local GuiService         = game:GetService("GuiService")
local HttpService        = game:GetService("HttpService")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local VirtualUser        = game:GetService("VirtualUser")

local VirtualInputManager = nil
pcall(function() VirtualInputManager = game:GetService("VirtualInputManager") end)

local LocalPlayer = Players.LocalPlayer

-- ═══════════════════════════════════════════
--  KARAKTER & UTILITY HELPERS
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

local function isPlayerCharacterDescendant(obj)
    if not obj then return false end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character and obj:IsDescendantOf(plr.Character) then
            return true
        end
    end
    return false
end

local function clamp(n, lo, hi)
    if n < lo then return lo end
    if n > hi then return hi end
    return n
end

local function flat(v)
    return Vector3.new(v.X, 0, v.Z)
end

local function normalizeStr(s)
    return string.lower(tostring(s or "")):gsub("[%s_%-%.,'\"!%?:]+", "")
end

local function partOf(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Attachment") then
        local p = obj.Parent
        return (p and p:IsA("BasePart")) and p or nil
    end
    if obj:IsA("Model") then
        if obj.PrimaryPart then return obj.PrimaryPart end
        local hrp = obj:FindFirstChild("HumanoidRootPart")
        if hrp and hrp:IsA("BasePart") then return hrp end
    end
    return obj:FindFirstChildWhichIsA("BasePart", true)
end

local function posOf(obj)
    if not obj then return nil end
    if obj:IsA("Attachment") then return obj.WorldPosition end
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Model") then
        local p = partOf(obj)
        if p then return p.Position end
        local ok, piv = pcall(function() return obj:GetPivot().Position end)
        if ok and typeof(piv) == "Vector3" then return piv end
    end
    local p = partOf(obj)
    return p and p.Position or nil
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
    QiThreshold        = 99.5,
    RebirthMaxRealm    = 0,

    -- Movement / Sword Flight
    UseSwordFlight     = true,
    FlySpeed           = 150,
    NaturalHeight      = 24,
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
    TeleportMode       = "Smooth Fly (Sword)",
    TeleportSearch     = "",

    -- Runtime Status
    LoopRunning        = false,
    LoopGacha          = false,
    LoopLantern        = false,
    LoopShop           = false,
    Step               = "Siap",
    Realm              = "Memuat...",
    RealmIndex         = 1,
    Qi                 = 0,
    Locked             = false,
    LastRequirementMsg = "",
}

local LogBuffer = {}

local function log(msg)
    msg = tostring(msg)
    print("[CultivationLegends] " .. msg)
    table.insert(LogBuffer, 1, "• " .. msg)
    while #LogBuffer > 10 do
        table.remove(LogBuffer)
    end
    if State.LogLabel then
        pcall(function()
            State.LogLabel.Text = table.concat(LogBuffer, "\n")
        end)
    end
end

-- ═══════════════════════════════════════════
--  REMOTES, SHARED MODULES & CLIENT MODULES
-- ═══════════════════════════════════════════
local RemoteFolder = ReplicatedStorage:FindFirstChild("Remotes")
local SharedFolder = ReplicatedStorage:FindFirstChild("Shared")

local Remotes = {
    Action       = RemoteFolder and RemoteFolder:FindFirstChild("Action"),
    Fx           = RemoteFolder and RemoteFolder:FindFirstChild("Fx"),
    Meditate     = ReplicatedStorage:FindFirstChild("MeditateEvent"),
    SwordMode    = ReplicatedStorage:FindFirstChild("SwordModeEvent"),
    AuraSelect   = ReplicatedStorage:FindFirstChild("AuraSelectEvent"),
    FeedbackRead = RemoteFolder and RemoteFolder:FindFirstChild("FeedbackRead"),
}

local SharedCache = {}
local ClientCache = {}

local function safeReqShared(name)
    if SharedCache[name] ~= nil then
        return SharedCache[name] ~= false and SharedCache[name] or nil
    end
    local folder = SharedFolder or ReplicatedStorage:FindFirstChild("Shared")
    local mod = folder and folder:FindFirstChild(name)
    if not mod or not mod:IsA("ModuleScript") then
        SharedCache[name] = false
        return nil
    end
    local ok, res = pcall(require, mod)
    if ok and type(res) == "table" then
        SharedCache[name] = res
        return res
    end
    SharedCache[name] = false
    return nil
end

local function safeReqClient(relPath)
    if ClientCache[relPath] ~= nil then
        return ClientCache[relPath] ~= false and ClientCache[relPath] or nil
    end
    local ps = LocalPlayer:FindFirstChild("PlayerScripts")
    local node = ps and ps:FindFirstChild("Client")
    if not node then
        ClientCache[relPath] = false
        return nil
    end
    for seg in string.gmatch(relPath, "[^%.]+") do
        node = node:FindFirstChild(seg)
        if not node then
            ClientCache[relPath] = false
            return nil
        end
    end
    if not node:IsA("ModuleScript") then
        ClientCache[relPath] = false
        return nil
    end
    local ok, res = pcall(require, node)
    if ok and res ~= nil then
        ClientCache[relPath] = res
        return res
    end
    ClientCache[relPath] = false
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
        local ok, res = pcall(function()
            return remote:InvokeServer(unpackFn(args, 1, n))
        end)
        return ok, res
    end
    return false
end

local function fireAction(...)
    if not Remotes.Action then
        local rf = ReplicatedStorage:FindFirstChild("Remotes")
        Remotes.Action = rf and rf:FindFirstChild("Action")
    end
    return fireRaw(Remotes.Action, ...)
end

-- ═══════════════════════════════════════════
--  RUNTIME CONSTANT & REMOTE DISCOVERY ENGINE
-- ═══════════════════════════════════════════
local Discovered = {
    ActionStrings = {},   -- semua string literal yg ditemukan di client scripts
    SpyHistory    = {},   -- panggilan Action:FireServer asli yang tertangkap
    Learned       = {     -- pemetaan aksi yang berhasil dipelajari
        RollTalent   = {},
        Meditate     = {},
        Breakthrough = {},
        Cauldron     = {},
        ShopBuy      = {},
        Harvest      = {},
    },
}

local function recordSpyCall(remoteName, args)
    local summary = remoteName .. "("
    local parts = {}
    for i = 1, math.min(#args, 4) do
        local v = args[i]
        if type(v) == "table" then
            local kv = {}
            for tk, tv in pairs(v) do
                table.insert(kv, tostring(tk) .. "=" .. tostring(tv))
            end
            table.insert(parts, "{" .. table.concat(kv, ",") .. "}")
        else
            table.insert(parts, typeof and typeof(v) == "Instance" and v:GetFullName() or tostring(v))
        end
    end
    summary = summary .. table.concat(parts, ", ") .. ")"
    table.insert(Discovered.SpyHistory, 1, summary)
    while #Discovered.SpyHistory > 25 do
        table.remove(Discovered.SpyHistory)
    end

    -- Auto-classify jika Action remote dipanggil
    local firstStr = type(args[1]) == "string" and args[1] or nil
    if remoteName == "Action" and firstStr then
        local low = string.lower(firstStr)
        if string.find(low, "talent", 1, true) or string.find(low, "roll", 1, true) or string.find(low, "spin", 1, true) then
            Discovered.Learned.RollTalent[firstStr] = args
        elseif string.find(low, "break", 1, true) or string.find(low, "rebirth", 1, true) or string.find(low, "ascend", 1, true) then
            Discovered.Learned.Breakthrough[firstStr] = args
        elseif string.find(low, "brew", 1, true) or string.find(low, "cauldron", 1, true) or string.find(low, "craft", 1, true) or string.find(low, "alch", 1, true) then
            Discovered.Learned.Cauldron[firstStr] = args
        elseif string.find(low, "shop", 1, true) or string.find(low, "buy", 1, true) or string.find(low, "fest", 1, true) then
            Discovered.Learned.ShopBuy[firstStr] = args
        elseif string.find(low, "herb", 1, true) or string.find(low, "harvest", 1, true) or string.find(low, "pick", 1, true) or string.find(low, "lantern", 1, true) then
            Discovered.Learned.Harvest[firstStr] = args
        elseif string.find(low, "medit", 1, true) then
            Discovered.Learned.Meditate[firstStr] = args
        end
    end
end

-- Pasang passive namecall spy agar saat user atau tombol UI memicu remote, skrip langsung belajar
local function installPassiveSpy()
    if getgenv()._CL_SPY_INSTALLED then return end
    if type(hookmetamethod) ~= "function" or type(getnamecallmethod) ~= "function" then return end
    getgenv()._CL_SPY_INSTALLED = true

    pcall(function()
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if not checkcaller() and (method == "FireServer" or method == "InvokeServer") then
                if typeof(self) == "Instance" and (self == Remotes.Action or self == Remotes.Meditate or self == Remotes.SwordMode or string.find(self.Name, "Event", 1, true) or (self.Parent and self.Parent.Name == "Remotes")) then
                    local args = { ... }
                    task.defer(function()
                        pcall(recordSpyCall, self.Name, args)
                    end)
                end
            end
            return oldNamecall(self, ...)
        end)
    end)
end

-- Ekstrak konstanta string dari ModuleScript client via debug.getconstants / getgc
local function extractConstantsFromClient()
    local getConst = (type(debug) == "table" and debug.getconstants) or getconstants
    local getProt = (type(debug) == "table" and debug.getprotos) or getprotos
    if type(getConst) ~= "function" then return end

    local visited = {}
    local targetModNames = {
        TalentWindow = true, Cauldron = true, ElderTalk = true, ShopWindow = true,
        Meditation = true, Herbs = true, Lotus = true, Hud = true, MapView = true,
        EventPanel = true, SwordFlight = true, State = true,
    }

    local function scanFunc(fn, ownerName, depth)
        if type(fn) ~= "function" or visited[fn] or depth > 3 then return end
        visited[fn] = true
        local okC, consts = pcall(getConst, fn)
        if okC and type(consts) == "table" then
            local hasFire = false
            for _, c in pairs(consts) do
                if c == "FireServer" or c == "InvokeServer" or c == "Action" then
                    hasFire = true
                    break
                end
            end
            for _, c in pairs(consts) do
                if type(c) == "string" and #c >= 3 and #c <= 42 and not string.find(c, "%s") then
                    Discovered.ActionStrings[ownerName] = Discovered.ActionStrings[ownerName] or {}
                    if hasFire or string.match(c, "^[%a_][%w_%.:%-]*$") then
                        Discovered.ActionStrings[ownerName][c] = hasFire and "FIRE" or "STR"
                    end
                end
            end
        end
        if type(getProt) == "function" then
            local okP, protos = pcall(getProt, fn)
            if okP and type(protos) == "table" then
                for _, pf in ipairs(protos) do
                    scanFunc(pf, ownerName, depth + 1)
                end
            end
        end
    end

    -- Scan functions returned by required Client modules
    for _, rel in ipairs({
        "UI.TalentWindow", "UI.Cauldron", "UI.ElderTalk", "UI.ShopWindow",
        "UI.Hud", "UI.EventPanel", "UI.MapView", "Meditation", "Herbs", "Lotus"
    }) do
        local mod = safeReqClient(rel)
        if type(mod) == "table" then
            for _, v in pairs(mod) do
                if type(v) == "function" then
                    scanFunc(v, rel, 0)
                end
            end
        elseif type(mod) == "function" then
            scanFunc(mod, rel, 0)
        end
    end

    -- Scan getgc functions whose script matches known client scripts
    if type(getgc) == "function" and type(getfenv) == "function" then
        local okGc, gc = pcall(getgc)
        if okGc and type(gc) == "table" then
            for _, obj in ipairs(gc) do
                if type(obj) == "function" then
                    local okEnv, env = pcall(getfenv, obj)
                    local scr = okEnv and type(env) == "table" and env.script
                    if scr and typeof(scr) == "Instance" and targetModNames[scr.Name] then
                        scanFunc(obj, scr.Name, 0)
                    end
                end
            end
        end
    end
end

-- ═══════════════════════════════════════════
--  PROPER GUI CLICKER & KEYBOARD PRESSER
-- ═══════════════════════════════════════════
local OurGui = nil

local function isActuallyVisible(obj)
    if not obj or not obj.Parent then return false end
    local cur = obj
    while cur and cur ~= game do
        if cur:IsA("ScreenGui") then
            return cur.Enabled == true
        elseif cur:IsA("GuiObject") then
            if cur.Visible == false then return false end
        end
        cur = cur.Parent
    end
    return false
end

local function triggerButton(btn)
    if not btn or not (btn:IsA("TextButton") or btn:IsA("ImageButton")) then return false end
    local fired = false

    -- 1. firesignal (executor native)
    if type(firesignal) == "function" then
        for _, sigName in ipairs({ "MouseButton1Click", "Activated", "MouseButton1Down", "MouseButton1Up" }) do
            local ok = pcall(function() firesignal(btn[sigName]) end)
            if ok then fired = true end
        end
    end

    -- 2. getconnections fallback
    if type(getconnections) == "function" then
        for _, sigName in ipairs({ "MouseButton1Click", "Activated", "MouseButton1Down" }) do
            local okC, conns = pcall(getconnections, btn[sigName])
            if okC and type(conns) == "table" then
                for _, conn in ipairs(conns) do
                    pcall(function()
                        if conn.Fire then conn:Fire() else conn.Function() end
                        fired = true
                    end)
                end
            end
        end
    end

    -- 3. Activate()
    pcall(function() btn:Activate() end)

    -- 4. VirtualInputManager click WITH GuiInset if visible on screen
    if VirtualInputManager and isActuallyVisible(btn) then
        pcall(function()
            local inset = Vector2.zero
            pcall(function() inset = GuiService:GetGuiInset() end)
            local pos = btn.AbsolutePosition + (btn.AbsoluteSize * 0.5) + inset
            if pos.X > 0 and pos.Y > 0 then
                VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                task.wait(0.03)
                VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                fired = true
            end
        end)
    end

    return fired
end

local function pressKey(keyCode)
    if not VirtualInputManager or not keyCode then return false end
    local ok = pcall(function()
        VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
        task.wait(0.06)
        VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
    end)
    return ok
end

local function labelOfButton(btn)
    if btn:IsA("TextButton") and btn.Text and btn.Text ~= "" then
        return btn.Text
    end
    local parts = {}
    for _, d in ipairs(btn:GetDescendants()) do
        if d:IsA("TextLabel") and d.Text and d.Text ~= "" then
            table.insert(parts, d.Text)
        end
    end
    return table.concat(parts, " ")
end

-- Cari dan klik tombol yang BENAR-BENAR TERLIHAT di layar (atau dalam container tertentu)
local function findVisibleButtons(keywords, container, excludeWords)
    local pg = container or getPlayerGui()
    if not pg then return {} end
    excludeWords = excludeWords or { "close", "exit", "cancel", "tutup" }
    local matches = {}

    for _, obj in ipairs(pg:GetDescendants()) do
        if (obj:IsA("TextButton") or obj:IsA("ImageButton")) and isActuallyVisible(obj) then
            if not (OurGui and obj:IsDescendantOf(OurGui)) and obj.AbsoluteSize.X >= 8 and obj.AbsoluteSize.Y >= 8 then
                local lbl = labelOfButton(obj)
                local combined = string.lower(obj.Name .. " " .. lbl)
                local excluded = false
                for _, ex in ipairs(excludeWords) do
                    if string.find(combined, ex, 1, true) then
                        excluded = true
                        break
                    end
                end
                if not excluded then
                    for _, kw in ipairs(keywords) do
                        if string.find(combined, string.lower(kw), 1, true) then
                            table.insert(matches, { Button = obj, Label = lbl ~= "" and lbl or obj.Name })
                            break
                        end
                    end
                end
            end
        end
    end
    return matches
end

local function clickVisibleGui(keywords, container, excludeWords)
    local list = findVisibleButtons(keywords, container, excludeWords)
    if #list > 0 then
        triggerButton(list[1].Button)
        return true, list[1].Label, list[1].Button
    end
    return false, nil, nil
end

local function usePrompt(prompt)
    if not prompt or not prompt.Parent then return false end
    local ok = false
    if type(fireproximityprompt) == "function" then
        ok = pcall(fireproximityprompt, prompt)
    elseif type(fireProximityPrompt) == "function" then
        ok = pcall(fireProximityPrompt, prompt)
    end
    if not ok then
        ok = pcall(function()
            prompt:InputHoldBegin()
            task.wait(math.min((prompt.HoldDuration or 0.1) + 0.06, 1.2))
            prompt:InputHoldEnd()
        end)
    end
    return ok
end

local function touchPart(part)
    local root = getRootPart()
    if not root or not part then return end
    if type(firetouchinterest) == "function" then
        pcall(function()
            firetouchinterest(root, part, 0)
            task.wait(0.05)
            firetouchinterest(root, part, 1)
        end)
    end
end

local function findPromptNear(pos, radius)
    local best, bestDist = nil, radius or 28
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            local p = posOf(obj.Parent)
            if p then
                local d = (p - pos).Magnitude
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
--  DATA PARSER: SHARED.REALMS, ALCHEMY, ITEMS, WORLD, LOTUS
-- ═══════════════════════════════════════════
local RealmList = {}
local RealmByName = {}
local ItemCatalog = {}   -- id/key -> display name
local Recipes = {}       -- list of { Key, Name, Result, Ingredients = { {Name, Count} } }

local function buildItemCatalog()
    ItemCatalog = {}
    local items = safeReqShared("Items")
    if not items then return end

    local function walkItems(tbl, depth)
        if type(tbl) ~= "table" or depth > 3 then return end
        for k, v in pairs(tbl) do
            if type(v) == "table" then
                local name = v.Name or v.DisplayName or v.Title or (type(k) == "string" and k or nil)
                if type(name) == "string" then
                    ItemCatalog[tostring(k)] = name
                    ItemCatalog[normalizeStr(k)] = name
                    ItemCatalog[normalizeStr(name)] = name
                end
                if not name or depth < 2 then
                    walkItems(v, depth + 1)
                end
            elseif type(v) == "string" and type(k) == "string" then
                ItemCatalog[k] = v
            end
        end
    end
    walkItems(items, 0)
end

local function resolveItemDisplay(idOrName)
    local s = tostring(idOrName or "")
    return ItemCatalog[s] or ItemCatalog[normalizeStr(s)] or s
end

local function buildRealmList()
    RealmList = {}
    RealmByName = {}
    local data = safeReqShared("Realms")
    if not data then return end

    local entries = {}
    local function extractReqPill(tbl)
        if type(tbl) ~= "table" then return nil end
        for _, k in ipairs({ "Pill", "BreakthroughPill", "Elixir", "RequiredPill", "RequiredItem", "Item", "BreakthroughItem", "CostItem", "Recipe" }) do
            local val = tbl[k]
            if type(val) == "string" and val ~= "" then return val end
            if type(val) == "table" and (val.Name or val.Item or val.Id) then
                return val.Name or val.Item or val.Id
            end
        end
        return nil
    end

    local function extractReqMaterials(tbl)
        local mats = {}
        if type(tbl) ~= "table" then return mats end
        for _, k in ipairs({ "Materials", "Ingredients", "Herbs", "Items", "Cost", "Requirements", "Reagents" }) do
            local m = tbl[k]
            if type(m) == "table" then
                for mk, mv in pairs(m) do
                    if type(mk) == "string" and type(mv) == "number" then
                        table.insert(mats, { Name = resolveItemDisplay(mk), RawId = mk, Count = mv })
                    elseif type(mv) == "table" then
                        local n = mv.Name or mv.Item or mv.Id or tostring(mk)
                        local c = tonumber(mv.Count or mv.Amount or mv.Qty) or 1
                        table.insert(mats, { Name = resolveItemDisplay(n), RawId = n, Count = c })
                    elseif type(mv) == "string" then
                        table.insert(mats, { Name = resolveItemDisplay(mv), RawId = mv, Count = 1 })
                    end
                end
            end
        end
        return mats
    end

    if #data > 0 then
        for i, v in ipairs(data) do
            if type(v) == "string" then
                table.insert(entries, { Name = v, Order = i, MaxQi = nil, Mats = {} })
            elseif type(v) == "table" then
                table.insert(entries, {
                    Name = v.Name or v.Title or v.DisplayName or ("Realm " .. i),
                    Order = v.Order or v.Index or v.Level or v.Tier or i,
                    MaxQi = v.Qi or v.MaxQi or v.RequiredQi or v.QiRequired or v.Exp,
                    Spot = v.Spot or v.Court or v.Location or v.Map or v.Area or v.Bagua,
                    Pill = extractReqPill(v),
                    Mats = extractReqMaterials(v),
                })
            end
        end
    else
        for k, v in pairs(data) do
            if type(v) == "table" then
                table.insert(entries, {
                    Name = v.Name or v.Title or tostring(k),
                    Order = v.Order or v.Index or v.Level or v.Tier or 0,
                    MaxQi = v.Qi or v.MaxQi or v.RequiredQi or v.QiRequired,
                    Spot = v.Spot or v.Court or v.Location or v.Map or v.Area,
                    Pill = extractReqPill(v),
                    Mats = extractReqMaterials(v),
                })
            end
        end
    end

    table.sort(entries, function(a, b) return (tonumber(a.Order) or 0) < (tonumber(b.Order) or 0) end)
    for i, e in ipairs(entries) do
        e.Index = i
        RealmList[i] = e
        RealmByName[normalizeStr(e.Name)] = i
    end
end

local function buildRecipes()
    Recipes = {}
    local alch = safeReqShared("Alchemy")
    if not alch then return end

    local function walkAlch(tbl, depth)
        if type(tbl) ~= "table" or depth > 2 then return end
        for k, v in pairs(tbl) do
            if type(v) == "table" then
                local ings = {}
                for _, key in ipairs({ "Ingredients", "Items", "Materials", "Recipe", "Reagents", "Cost", "Herbs" }) do
                    local raw = v[key]
                    if type(raw) == "table" then
                        for ik, iv in pairs(raw) do
                            if type(ik) == "string" and type(iv) == "number" then
                                table.insert(ings, { Name = resolveItemDisplay(ik), RawId = ik, Count = iv })
                            elseif type(iv) == "table" then
                                local n = iv.Name or iv.Item or iv.Id or tostring(ik)
                                local c = tonumber(iv.Count or iv.Amount or iv.Qty) or 1
                                table.insert(ings, { Name = resolveItemDisplay(n), RawId = n, Count = c })
                            elseif type(iv) == "string" then
                                table.insert(ings, { Name = resolveItemDisplay(iv), RawId = iv, Count = 1 })
                            end
                        end
                    end
                end
                if #ings > 0 then
                    table.insert(Recipes, {
                        Key = tostring(k),
                        Name = v.Name or v.DisplayName or v.Result or tostring(k),
                        RealmReq = v.Realm or v.RealmIndex or v.MinRealm or v.Stage,
                        Ingredients = ings,
                    })
                elseif depth < 2 then
                    walkAlch(v, depth + 1)
                end
            end
        end
    end
    walkAlch(alch, 0)
end

-- ═══════════════════════════════════════════
--  PLAYER STATE READER (Client.UI.State + HUD + Attributes)
-- ═══════════════════════════════════════════
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

local function readStateModuleField(keys)
    local st = safeReqClient("UI.State")
    if type(st) ~= "table" then return nil end
    local pools = { st }
    for _, sub in pairs(st) do
        if type(sub) == "table" then table.insert(pools, sub) end
    end
    for _, pool in ipairs(pools) do
        for _, k in ipairs(keys) do
            if pool[k] ~= nil then return pool[k] end
        end
    end
    return nil
end

-- Scan HUD tepatnya untuk banner "Breakthrough • 92% [B]" atau label Qi
local function scanHudBreakthroughQi()
    local pg = getPlayerGui()
    if not pg then return nil end
    local best, bestScore = nil, -1
    for _, d in ipairs(pg:GetDescendants()) do
        if d:IsA("TextLabel") and isActuallyVisible(d) and not (OurGui and d:IsDescendantOf(OurGui)) then
            local txt = d.Text or ""
            local num = tonumber(string.match(txt, "(%d+%.?%d*)%s*%%"))
            if num then
                local low = string.lower(txt)
                local score = 0
                if string.find(low, "breakthrough", 1, true) or string.find(low, "qi", 1, true) or string.find(low, "[b]", 1, true) then
                    score = score + 10
                end
                local pName = d.Parent and string.lower(d.Parent.Name) or ""
                if string.find(pName, "break", 1, true) or string.find(pName, "qi", 1, true) or string.find(pName, "hud", 1, true) then
                    score = score + 5
                end
                if score > bestScore then
                    bestScore = score
                    best = num
                end
            end
        end
    end
    return best
end

local function refreshPlayerState()
    -- 1. Cek Client.UI.State terlebih dahulu
    local stRealm = readStateModuleField({ "Realm", "realm", "RealmName", "RealmIndex", "Stage", "CultivationRealm" })
    local realmVal = stRealm or attrOf({ "Realm", "RealmName", "CultivationRealm", "Rank", "Stage", "RealmIndex" })

    if type(realmVal) == "string" and realmVal ~= "" then
        State.Realm = realmVal
        local idx = RealmByName[normalizeStr(realmVal)]
        if idx then State.RealmIndex = idx end
    elseif type(realmVal) == "number" then
        State.RealmIndex = clamp(math.floor(realmVal), 1, math.max(#RealmList, 1))
        State.Realm = RealmList[State.RealmIndex] and RealmList[State.RealmIndex].Name or ("Realm " .. State.RealmIndex)
    elseif #RealmList > 0 then
        State.Realm = RealmList[State.RealmIndex] and RealmList[State.RealmIndex].Name or State.Realm
    end

    -- 2. Baca persentase Qi / Breakthrough
    local hudQi = scanHudBreakthroughQi()
    if hudQi ~= nil then
        State.Qi = clamp(hudQi, 0, 100)
    else
        local rawQi = readStateModuleField({ "QiProgress", "QiPercent", "BreakthroughPercent", "Qi", "Cultivation" })
            or attrOf({ "QiProgress", "CultivationProgress", "Qi", "Progress", "Cultivation" })
        if type(rawQi) == "number" then
            local maxQi = RealmList[State.RealmIndex] and RealmList[State.RealmIndex].MaxQi
            if rawQi > 0 and rawQi <= 1 then
                State.Qi = clamp(rawQi * 100, 0, 100)
            elseif maxQi and maxQi > 0 and rawQi > 100 then
                State.Qi = clamp((rawQi / maxQi) * 100, 0, 100)
            else
                State.Qi = clamp(rawQi, 0, 100)
            end
        end
    end

    return State.Realm, State.Qi
end

local function countItemInBag(itemName)
    if not itemName or itemName == "" then return 0 end
    local target = normalizeStr(itemName)
    local count = 0

    -- Cek Client.UI.State inventory table
    local inv = readStateModuleField({ "Inventory", "inventory", "Items", "Bag", "Herbs", "Pills" })
    if type(inv) == "table" then
        for k, v in pairs(inv) do
            if type(k) == "string" and string.find(normalizeStr(k), target, 1, true) and type(v) == "number" then
                count = math.max(count, v)
            elseif type(v) == "table" then
                local vn = v.Name or v.Id or v.Item or ""
                if string.find(normalizeStr(vn), target, 1, true) then
                    count = math.max(count, tonumber(v.Count or v.Amount or v.Qty) or 1)
                end
            end
        end
    end

    -- Cek Backpack & Character
    for _, c in ipairs({ LocalPlayer:FindFirstChild("Backpack"), LocalPlayer.Character }) do
        if c then
            for _, obj in ipairs(c:GetChildren()) do
                if string.find(normalizeStr(obj.Name), target, 1, true) then
                    local amt = obj:GetAttribute("Count") or obj:GetAttribute("Amount") or 1
                    count = count + (tonumber(amt) or 1)
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
    return countItemInBag("Pill") + countItemInBag("Elixir") + countItemInBag("Breakthrough")
end

-- ═══════════════════════════════════════════
--  PEMINDAIAN LOKASI: BAGUA CIRCLES, SHARED.WORLD, PULAU
-- ═══════════════════════════════════════════
local WorldSpots = {}    -- spots dari Shared.World / Shared.Lotus / Shared.DungeonData
local BaguaSpots = {}    -- spots Bagua Circle / Qi Gathering di Workspace & PlayerGui
local IslandSpots = {}   -- semua pulau pemain di Workspace.Obitel.Islands

local function extractVec3FromTable(v)
    if typeof(v) == "Vector3" then return v end
    if typeof(v) == "CFrame" then return v.Position end
    if type(v) ~= "table" then return nil end
    if type(v.X) == "number" and type(v.Y) == "number" and type(v.Z) == "number" then
        return Vector3.new(v.X, v.Y, v.Z)
    end
    if type(v[1]) == "number" and type(v[2]) == "number" and type(v[3]) == "number" then
        return Vector3.new(v[1], v[2], v[3])
    end
    for _, key in ipairs({ "Position", "Pos", "CFrame", "Spot", "Spawn", "Location", "Point", "Center", "Teleport", "Coords" }) do
        local sub = v[key]
        if typeof(sub) == "Vector3" then return sub end
        if typeof(sub) == "CFrame" then return sub.Position end
        if type(sub) == "table" then
            local rec = extractVec3FromTable(sub)
            if rec then return rec end
        end
    end
    return nil
end

local function scanSharedLocations()
    WorldSpots = {}
    local seen = {}

    local function walk(tbl, prefix, source, depth)
        if type(tbl) ~= "table" or depth > 4 then return end
        for k, v in pairs(tbl) do
            if type(v) == "table" then
                local label = v.Name or v.DisplayName or v.Title or tostring(k)
                local pos = extractVec3FromTable(v)
                if pos then
                    local full = (prefix ~= "" and (prefix .. " - " .. label) or label)
                    if not seen[full] then
                        seen[full] = true
                        table.insert(WorldSpots, {
                            Name = full,
                            Position = pos,
                            Source = source,
                            Multiplier = tonumber(v.Multiplier or v.QiMultiplier or v.Boost or v.Rate) or 1,
                            RealmReq = tonumber(v.RealmIndex or v.MinRealm or v.RequiredRealm or v.Level or v.Tier) or 1,
                        })
                    end
                else
                    local nextPref = (type(k) == "string" and k ~= "Position" and k ~= "CFrame") and (prefix ~= "" and (prefix .. " / " .. k) or k) or prefix
                    walk(v, nextPref, source, depth + 1)
                end
            elseif typeof(v) == "Vector3" or typeof(v) == "CFrame" then
                local pos = typeof(v) == "CFrame" and v.Position or v
                local full = (prefix ~= "" and (prefix .. " - " .. tostring(k)) or tostring(k))
                if not seen[full] then
                    seen[full] = true
                    table.insert(WorldSpots, { Name = full, Position = pos, Source = source, Multiplier = 1, RealmReq = 1 })
                end
            end
        end
    end

    local w = safeReqShared("World")
    if w then walk(w, "", "World", 0) end
    local l = safeReqShared("Lotus")
    if l then walk(l, "Lotus", "Lotus", 0) end
    local d = safeReqShared("DungeonData")
    if d then walk(d, "Dungeon", "Dungeon", 0) end
end

-- ═══════════════════════════════════════════
--  DATA LOKASI KULTIVASI REAL (dari Workspace scan langsung in-game)
--  Source: Workspace.Map.Formations.*, Workspace.Map.Village.*, dst.
--  Realm order: Body Tempering(1) → Qi Gathering(2) → Foundation Est.(3)
--               → Golden Core(4) → Nascent Soul(5) → Heavenly Being(6)
--               → Great Heavenly Being(7) → Heavenly Lord(8) → Immortal(9)
-- ═══════════════════════════════════════════
local CULTIVATION_SPOTS_HARDCODED = {
    -- { name, workspacePath, center, standOffset, multiplier, realmIndex }
    -- realmIndex: 1=BodyTemp, 2=QiGath, 3=FoundEst, 4=GoldCore,
    --              5=NascentSoul, 6=HeavenlyBeing, 7=GreatHeavenly, 8=HeavenlyLord, 9=Immortal
    {
        Name       = "Stone of First Breath",
        Path       = {"Map","Village","FirstBreathStone"},
        Center     = Vector3.new(-1.8, 6.3, 304.0),
        Multiplier = 1.5,
        RealmIndex = 1,   -- Body Tempering
    },
    {
        Name       = "Outer Court Bagua Circle",
        Path       = {"Map","Formations","plaza"},
        Center     = Vector3.new(0.0, 67.2, 30.0),
        Multiplier = 3,
        RealmIndex = 2,   -- Qi Gathering
    },
    {
        Name       = "Contemplation Cliff",
        Path       = {"Map","Formations","cliff"},
        Center     = Vector3.new(-196.0, 66.0, -24.0),
        Multiplier = 5,
        RealmIndex = 2,   -- Qi Gathering (Layer 3+)
    },
    {
        Name       = "Jade Formation",
        Path       = {"Map","Islands","JadePeak"},
        Center     = Vector3.new(482.0, 126.3, -120.4),
        Multiplier = 10,
        RealmIndex = 3,   -- Foundation Establishment
    },
    {
        Name       = "Golden Formation",
        Path       = {"Map","Islands","GoldTerrace"},
        Center     = Vector3.new(697.6, 291.3, -448.8),
        Multiplier = 22,
        RealmIndex = 4,   -- Golden Core
    },
    {
        Name       = "Cloud Formation",
        Path       = {"Map","HeavenCity","Plaza"},
        Center     = Vector3.new(520.0, 509.9, -780.0),
        Multiplier = 50,
        RealmIndex = 6,   -- Heavenly Being (skip 5=Nascent if no spot)
    },
    {
        Name       = "Heaven's Threshold",
        Path       = {"Map","HeavenCity","GreatHeavenSummit"},
        Center     = Vector3.new(449.1, 535.7, -902.9),
        Multiplier = 110,
        RealmIndex = 7,   -- Great Heavenly Being
    },
    {
        Name       = "Lord's Peak",
        Path       = {"Map","HeavenCity","LordPeak"},
        Center     = Vector3.new(532.1, 597.4, -939.1),
        Multiplier = 250,
        RealmIndex = 8,   -- Heavenly Lord
    },
    {
        Name       = "Penglai, Isle of Immortals",
        Path       = {"Map","ImmortalIsle"},
        Center     = Vector3.new(-215.3, 502.7, -709.7),
        Multiplier = 550,
        RealmIndex = 9,   -- Immortal
    },
}

-- Ambil posisi live dari Workspace jika model masih ada, fallback ke hardcoded
local function getLivePosForSpot(spot)
    local ok, pos = pcall(function()
        local cur = workspace
        for _, p in ipairs(spot.Path) do
            cur = cur:FindFirstChild(p)
            if not cur then return nil end
        end
        if cur:IsA("BasePart") then return cur.Position end
        if cur:IsA("Model") then return cur:GetPivot().Position end
        local part = cur:FindFirstChildWhichIsA("BasePart", true)
        return part and part.Position or nil
    end)
    return (ok and pos) and pos or spot.Center
end

local function scanBaguaCircles()
    BaguaSpots = {}
    local seenPos = {}

    local function addCircle(name, rawPos, mult, reqRealm, locked)
        if not rawPos then return end
        for _, sp in ipairs(seenPos) do
            if (sp - rawPos).Magnitude < 12 then return end
        end
        table.insert(seenPos, rawPos)
        -- Berdiri 5 studs di depan spot agar tidak stuck di dalam objek
        local standPos = rawPos + Vector3.new(0, 1, 5.5)
        table.insert(BaguaSpots, {
            Name       = name,
            CenterPos  = rawPos,
            Position   = standPos,
            Multiplier = mult or 1,
            RealmReq   = reqRealm or 1,
            Locked     = locked or false,
        })
    end

    -- 1. HARDCODED DATA REAL dari scan in-game (paling reliable!)
    for _, spot in ipairs(CULTIVATION_SPOTS_HARDCODED) do
        local livePos = getLivePosForSpot(spot)
        addCircle(
            spot.Name,
            livePos,
            spot.Multiplier,
            spot.RealmIndex,
            false
        )
    end

    -- 2. Scan tambahan dari BillboardGui / SurfaceGui (kalau ada spot baru/event)
    local containers = { workspace }
    local pg = getPlayerGui()
    if pg then table.insert(containers, pg) end

    for _, rootContainer in ipairs(containers) do
        for _, gui in ipairs(rootContainer:GetDescendants()) do
            if gui:IsA("BillboardGui") or gui:IsA("SurfaceGui") then
                local host = gui.Adornee or gui.Parent
                if host and not isPlayerCharacterDescendant(host) and not (OurGui and gui:IsDescendantOf(OurGui)) then
                    local texts = {}
                    for _, lbl in ipairs(gui:GetDescendants()) do
                        if lbl:IsA("TextLabel") and lbl.Text ~= "" then
                            table.insert(texts, lbl.Text)
                        end
                    end
                    local joined = table.concat(texts, " | ")
                    local low = string.lower(joined)
                    if string.find(low, "bagua", 1, true)
                        or string.find(low, "qi gathering", 1, true)
                        or string.find(low, "formation", 1, true)
                        or string.find(low, "outer court", 1, true)
                        or string.find(low, "contemplation", 1, true)
                        or string.find(low, "penglai", 1, true) then
                        local p = posOf(host)
                        if p then
                            local title = texts[1] or host.Name
                            local mult = tonumber(string.match(low, "×(%d+)%s*qi"))
                                or tonumber(string.match(low, "x(%d+)%s*qi"))
                                or 3
                            addCircle(title, p, mult, 1, false)
                        end
                    end
                end
            end
        end
    end

    -- 3. Spot dari Shared.World / Shared.Lotus (jika berhasil ter-require)
    for _, ws in ipairs(WorldSpots) do
        local low = string.lower(ws.Name)
        if string.find(low, "bagua", 1, true) or string.find(low, "formation", 1, true)
            or string.find(low, "court", 1, true) or string.find(low, "penglai", 1, true) then
            addCircle(ws.Name, ws.Position, ws.Multiplier, ws.RealmReq, false)
        end
    end

    -- Urutkan: multiplier terbesar dulu (spot terkuat duluan)
    table.sort(BaguaSpots, function(a, b)
        if a.Multiplier == b.Multiplier then
            return a.RealmReq < b.RealmReq
        end
        return a.Multiplier > b.Multiplier
    end)

    return BaguaSpots
end

local function findElderYun()
    local obitel = workspace:FindFirstChild("Obitel")
    local ey = obitel and obitel:FindFirstChild("ElderYun")
    if ey then
        local p = posOf(ey)
        if p then return p, ey end
    end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if (obj:IsA("Model") or obj:IsA("BasePart")) and not isPlayerCharacterDescendant(obj) then
            local norm = normalizeStr(obj.Name)
            if string.find(norm, "elderyun", 1, true) then
                local p = posOf(obj)
                if p then return p, obj end
            end
        end
    end
    return nil, nil
end

local function findCauldron()
    local obitel = workspace:FindFirstChild("Obitel")
    local islands = obitel and obitel:FindFirstChild("Islands")
    local myIs = islands and islands:FindFirstChild("Island_" .. tostring(LocalPlayer.UserId))

    for _, area in ipairs({ myIs, obitel, workspace }) do
        if area then
            for _, obj in ipairs(area:GetDescendants()) do
                if (obj:IsA("Model") or obj:IsA("BasePart")) and not isPlayerCharacterDescendant(obj) then
                    local low = string.lower(obj.Name)
                    if string.find(low, "cauldron", 1, true) or string.find(low, "alchemy", 1, true) then
                        local p = posOf(obj)
                        if p then return p, obj end
                    end
                end
            end
        end
    end
    return nil, nil
end

local function scanIslands()
    IslandSpots = {}
    local obitel = workspace:FindFirstChild("Obitel")
    local islands = obitel and obitel:FindFirstChild("Islands")
    if not islands then return IslandSpots end

    for _, island in ipairs(islands:GetChildren()) do
        local p = posOf(island)
        if p then
            local pid = tonumber(string.match(island.Name, "%d+"))
            local isMine = (pid == LocalPlayer.UserId)
            local plr = pid and Players:GetPlayerByUserId(pid)
            local label
            if isMine then
                label = "Pulau Saya (" .. LocalPlayer.DisplayName .. ")"
            elseif plr then
                label = "Pulau " .. plr.DisplayName .. " (@" .. plr.Name .. ")"
            else
                label = "Pulau " .. island.Name
            end
            table.insert(IslandSpots, {
                Name = label,
                RawName = island.Name,
                Position = p + Vector3.new(0, 4, 0),
                IsMine = isMine,
            })
        end
    end

    table.sort(IslandSpots, function(a, b)
        if a.IsMine ~= b.IsMine then return a.IsMine end
        return a.Name < b.Name
    end)
    return IslandSpots
end

-- Pilih spot kultivasi terbaik sesuai ranah kultivasi user
-- Realm name → index mapping (berdasarkan head label scan dari game)
local REALM_NAME_TO_INDEX = {
    ["body tempering"]        = 1,
    ["bodytemper"]            = 1,
    ["qi gathering"]          = 2,
    ["qigathering"]           = 2,
    ["foundation establishment"] = 3,
    ["foundationestablishment"] = 3,
    ["foundation"]            = 3,
    ["golden core"]           = 4,
    ["goldencore"]            = 4,
    ["nascent soul"]          = 5,
    ["nascentsoul"]           = 5,
    ["heavenly being"]        = 6,
    ["heavenlybeing"]         = 6,
    ["great heavenly being"]  = 7,
    ["greatheavenly"]         = 7,
    ["heavenly lord"]         = 8,
    ["heavenlylord"]          = 8,
    ["immortal"]              = 9,
}

local function getRealmIndex()
    -- Coba baca dari State (sudah di-set oleh reader)
    if State.RealmIndex and State.RealmIndex > 0 then
        return State.RealmIndex
    end
    -- Fallback: baca dari head label karakter
    local char = getCharacter()
    if char then
        local head = char:FindFirstChild("Head")
        if head then
            for _, gui in ipairs(head:GetChildren()) do
                if gui:IsA("BillboardGui") or gui:IsA("SurfaceGui") then
                    for _, lbl in ipairs(gui:GetDescendants()) do
                        if lbl:IsA("TextLabel") and lbl.Text ~= "" then
                            local low = string.lower(lbl.Text)
                            for name, idx in pairs(REALM_NAME_TO_INDEX) do
                                if string.find(low, name, 1, true) then
                                    State.RealmIndex = idx
                                    return idx
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    -- Fallback: leaderstats
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    if ls then
        local realm = ls:FindFirstChild("Realm") or ls:FindFirstChild("Stage") or ls:FindFirstChild("Cultivation")
        if realm then
            local low = string.lower(tostring(realm.Value or ""))
            for name, idx in pairs(REALM_NAME_TO_INDEX) do
                if string.find(low, name, 1, true) then
                    State.RealmIndex = idx
                    return idx
                end
            end
        end
    end
    return State.RealmIndex or 1
end

local function getBestCultivationSpot()
    scanBaguaCircles()
    local realmIdx = getRealmIndex()

    if #BaguaSpots > 0 then
        -- Cari spot terkuat yang masih sesuai realm (RealmReq <= realmIdx)
        local bestSpot = nil
        for _, spot in ipairs(BaguaSpots) do
            -- BaguaSpots sudah diurutkan Multiplier terbesar dulu
            -- Ambil yang realmnya <= realm kita (bisa masuk ke sana)
            if not spot.Locked and (spot.RealmReq or 1) <= realmIdx then
                bestSpot = spot
                break
            end
        end
        if bestSpot then
            return bestSpot.Position, bestSpot.Name .. " (×" .. tostring(bestSpot.Multiplier) .. " Qi)"
        end
        -- Fallback: spot pertama (terendah realmnya = paling mudah diakses)
        local fallback = BaguaSpots[#BaguaSpots]
        if fallback then
            return fallback.Position, fallback.Name
        end
    end

    -- Fallback ke Pulau Saya
    scanIslands()
    for _, isl in ipairs(IslandSpots) do
        if isl.IsMine then
            return isl.Position, isl.Name
        end
    end
    return nil, nil
end

-- ═══════════════════════════════════════════
--  SAFE HEARTBEAT SWORD FLIGHT (ANTI-STUCK!)
-- ═══════════════════════════════════════════
local Travel = {
    Active    = false,
    Cancelled = false,
}

-- Raycast dimulai hanya 10 studs di atas titik target agar tidak menabrak atap / awan!
local function safeGroundY(pos)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local excl = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then table.insert(excl, p.Character) end
    end
    params.FilterDescendantsInstances = excl

    local result = workspace:Raycast(pos + Vector3.new(0, 12, 0), Vector3.new(0, -60, 0), params)
    if result then
        return result.Position.Y
    end
    return pos.Y
end

local function clearLeftoverMovers()
    local root = getRootPart()
    if root then
        for _, child in ipairs(root:GetChildren()) do
            if child.Name == "CL_FlightVelocity" or child.Name == "CL_FlightGyro" then
                pcall(function() child:Destroy() end)
            end
        end
        pcall(function()
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
    end
    local hum = getHumanoid()
    if hum then
        pcall(function()
            hum.PlatformStand = false
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end)
    end
end

local function setGameSwordMode(on)
    if Remotes.SwordMode then
        fireRaw(Remotes.SwordMode, on)
    end
    local ps = LocalPlayer:FindFirstChild("PlayerScripts")
    local sf = ps and ps:FindFirstChild("Client") and ps.Client:FindFirstChild("SwordFlight")
    local st = sf and sf:FindFirstChild("SwordToggle")
    if st and st:IsA("BindableEvent") then
        pcall(function() st:Fire(on) end)
    end
    if on then
        local bp = LocalPlayer:FindFirstChild("Backpack")
        local ch = getCharacter()
        if bp and ch then
            for _, t in ipairs(bp:GetChildren()) do
                if t:IsA("Tool") and string.find(string.lower(t.Name), "sword", 1, true) then
                    pcall(function() t.Parent = ch end)
                    break
                end
            end
        end
    end
end

-- Gerakan terbang mulus berbasis Heartbeat CFrame (tidak pernah bentrok dengan physics/BodyMover dan TIDAK PERNAH stuck!)
local function glideTo(targetPos, arriveDist)
    arriveDist = arriveDist or 5
    local root = getRootPart()
    local hum = getHumanoid()
    if not root or not hum then return false end

    Travel.Active = true
    Travel.Cancelled = false

    if State.UseSwordFlight then
        setGameSwordMode(true)
        task.wait(0.1)
    end

    root = getRootPart()
    hum = getHumanoid()
    if not root or not hum then return false end

    local startPos = root.Position
    local landY = safeGroundY(targetPos) + 3.2
    local finalPos = Vector3.new(targetPos.X, landY, targetPos.Z)
    local totalDist = (finalPos - startPos).Magnitude

    if totalDist <= arriveDist then
        return true
    end

    local speed = clamp(State.FlySpeed or 150, 45, 450)
    local cruiseY = math.max(startPos.Y, finalPos.Y) + (State.NaturalHeight or 24)
    local waypoints = {
        Vector3.new(startPos.X, cruiseY, startPos.Z),
        Vector3.new(finalPos.X, cruiseY, finalPos.Z),
        finalPos,
    }
    if totalDist < 35 then
        waypoints = { finalPos }
    end

    local okMove, errMove = pcall(function()
        hum.PlatformStand = true
        for _, wp in ipairs(waypoints) do
            if Travel.Cancelled then break end
            local segStart = os.clock()
            while not Travel.Cancelled do
                local dt = RunService.Heartbeat:Wait()
                root = getRootPart()
                if not root then break end

                local pos = root.Position
                local delta = wp - pos
                local dist = delta.Magnitude
                if dist <= 3.0 then
                    root.CFrame = CFrame.new(wp) * (root.CFrame - root.CFrame.Position)
                    break
                end
                if os.clock() - segStart > math.max(6, (dist / speed) * 3 + 3) then
                    break
                end

                local step = math.min(dist, speed * clamp(dt, 0.005, 0.06))
                local nextPos = pos + (delta / dist) * step
                local flatDir = flat(delta)
                if flatDir.Magnitude > 0.2 then
                    root.CFrame = CFrame.lookAt(nextPos, nextPos + flatDir)
                else
                    root.CFrame = CFrame.new(nextPos) * (root.CFrame - root.CFrame.Position)
                end
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end)

    if not okMove then
        log("Glide warning: " .. tostring(errMove))
    end
    return okMove and not Travel.Cancelled
end

local function walkTo(targetPos, arriveDist)
    arriveDist = arriveDist or 6
    local hum, root = getHumanoid(), getRootPart()
    if not hum or not root then return false end

    hum.WalkSpeed = State.WalkSpeed or 32
    local path = PathfindingService:CreatePath({ AgentRadius = 2.5, AgentHeight = 5, AgentCanJump = true })
    local ok = pcall(function() path:ComputeAsync(root.Position, targetPos) end)
    local wps = (ok and path.Status == Enum.PathStatus.Success) and path:GetWaypoints() or { { Position = targetPos } }

    for _, wp in ipairs(wps) do
        if Travel.Cancelled then break end
        root = getRootPart()
        if not root then break end
        if wp.Action == Enum.PathWaypointAction.Jump then
            pcall(function() hum.Jump = true end)
        end
        pcall(function() hum:MoveTo(wp.Position) end)
        local t0 = os.clock()
        while not Travel.Cancelled and os.clock() - t0 < 5 do
            root = getRootPart()
            if not root or (root.Position - wp.Position).Magnitude <= 4.5 then break end
            task.wait(0.1)
        end
    end
    return true
end

local function travelTo(targetPos, label, arriveDist)
    if typeof(targetPos) ~= "Vector3" then return false end
    State.Locked = true
    local prevStep = State.Step
    State.Step = "Menuju " .. tostring(label or "tujuan")
    log("Terbang/Jalan ke: " .. tostring(label))

    local okResult = false
    local okCall, err = pcall(function()
        local root = getRootPart()
        if not root then return end
        local dist = (root.Position - targetPos).Magnitude
        if State.UseSwordFlight or dist > 20 then
            okResult = glideTo(targetPos, arriveDist or 5)
        else
            okResult = walkTo(targetPos, arriveDist or 5)
        end
    end)

    -- GUARANTEED CLEANUP — karakter tidak mungkin pernah stuck di udara!
    Travel.Active = false
    pcall(setGameSwordMode, false)
    pcall(clearLeftoverMovers)
    State.Locked = false
    State.Step = prevStep or "Siap"

    if not okCall then
        log("Travel error: " .. tostring(err))
    end
    return okResult
end

local function instantTeleport(targetPos)
    if typeof(targetPos) ~= "Vector3" then return false end
    Travel.Cancelled = true
    Travel.Active = false
    pcall(setGameSwordMode, false)
    pcall(clearLeftoverMovers)

    local root = getRootPart()
    if not root then return false end
    local gy = safeGroundY(targetPos)
    root.CFrame = CFrame.new(Vector3.new(targetPos.X, gy + 3.5, targetPos.Z))
    root.AssemblyLinearVelocity = Vector3.zero
    task.wait(0.25)
    return true
end

-- ═══════════════════════════════════════════
--  MEDITASI
-- ═══════════════════════════════════════════
local function isCurrentlyMeditating()
    local attr = attrOf({ "Meditating", "IsMeditating", "InMeditation" })
    if attr == true then return true end

    local stVal = readStateModuleField({ "Meditating", "IsMeditating", "InMeditation" })
    if stVal == true then return true end

    local root = getRootPart()
    if root then
        local humSound = root:FindFirstChild("AuraHum")
        if humSound and humSound:IsA("Sound") and humSound.IsPlaying then
            return true
        end
    end

    local hum = getHumanoid()
    if hum and hum.Sit then return true end

    -- Cek tombol HUD apakah bertuliskan Stop Meditate / Meditating
    local stopBtns = findVisibleButtons({ "stop medit", "meditating", "berhenti" })
    if #stopBtns > 0 then return true end

    return false
end

local function startMeditatingAt(spotPos)
    if isCurrentlyMeditating() then return true end

    -- 1. Coba panggil method dari Client.Meditation bila ada
    local medMod = safeReqClient("Meditation")
    if type(medMod) == "table" then
        for _, fnName in ipairs({ "Start", "Begin", "Meditate", "Set", "Toggle" }) do
            if type(medMod[fnName]) == "function" then
                pcall(medMod[fnName], true)
                task.wait(0.2)
                if isCurrentlyMeditating() then return true end
            end
        end
    end

    -- 2. Trigger ProximityPrompt di Bagua Circle jika ada
    if spotPos then
        local prompt = findPromptNear(spotPos, 24)
        if prompt then
            local pLow = string.lower(tostring(prompt.ActionText or "") .. " " .. tostring(prompt.ObjectText or ""))
            if string.find(pLow, "medit", 1, true) or string.find(pLow, "cultiv", 1, true) or string.find(pLow, "sit", 1, true) or string.find(pLow, "gather", 1, true) then
                usePrompt(prompt)
                task.wait(0.25)
                if isCurrentlyMeditating() then return true end
            end
        end
    end

    -- 3. Klik tombol Meditate di HUD yang terlihat
    local clicked = clickVisibleGui({ "meditate", "meditasi" }, nil, { "stop", "close" })
    if clicked then
        task.wait(0.25)
        if isCurrentlyMeditating() then return true end
    end

    -- 4. Coba remote MeditateEvent & Action yang ditemukan/bawaan
    if Remotes.Meditate then
        fireRaw(Remotes.Meditate, true)
        task.wait(0.25)
        if not isCurrentlyMeditating() then
            fireRaw(Remotes.Meditate)
            task.wait(0.25)
        end
    end

    if not isCurrentlyMeditating() then
        for actName, _ in pairs(Discovered.Learned.Meditate) do
            fireAction(actName, true)
        end
        fireAction("Meditate", true)
        -- Beberapa game menggunakan tombol C atau M untuk meditasi
        pressKey(Enum.KeyCode.C)
    end

    return isCurrentlyMeditating()
end

local function stopMeditating()
    if not isCurrentlyMeditating() then return end
    local clicked = clickVisibleGui({ "stop medit", "meditating", "meditate" })
    if not clicked then
        if Remotes.Meditate then fireRaw(Remotes.Meditate, false) end
        fireAction("StopMeditate")
        fireAction("Meditate", false)
    end
end

-- ═══════════════════════════════════════════
--  HERBAL, CAULDRON & REBIRTH REQUIREMENTS
-- ═══════════════════════════════════════════
local function findHerbsInWorld(preferredNames)
    local herbs = {}
    local root = getRootPart()
    local origin = root and root.Position or Vector3.zero
    local prefSet = {}
    for _, pn in ipairs(preferredNames or {}) do
        prefSet[normalizeStr(pn)] = true
    end

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            local p = obj.Parent
            if p and not isPlayerCharacterDescendant(p) then
                local pos = posOf(p)
                if pos then
                    local combined = normalizeStr(p.Name .. " " .. tostring(obj.ActionText or "") .. " " .. tostring(obj.ObjectText or ""))
                    local isMatch = false
                    local priority = 0

                    for prefNorm in pairs(prefSet) do
                        if prefNorm ~= "" and string.find(combined, prefNorm, 1, true) then
                            isMatch = true
                            priority = 10
                            break
                        end
                    end

                    if not isMatch then
                        for _, kw in ipairs({ "herb", "ginseng", "lotus", "flower", "mushroom", "root", "leaf", "plant", "harvest", "pick", "bloom", "spiritgrass" }) do
                            if string.find(combined, kw, 1, true) then
                                isMatch = true
                                break
                            end
                        end
                    end

                    if isMatch then
                        table.insert(herbs, {
                            Part = partOf(p) or p,
                            Position = pos,
                            Prompt = obj,
                            Name = p.Name,
                            Dist = (pos - origin).Magnitude,
                            Priority = priority,
                        })
                    end
                end
            end
        end
    end

    table.sort(herbs, function(a, b)
        if a.Priority ~= b.Priority then return a.Priority > b.Priority end
        return a.Dist < b.Dist
    end)
    return herbs
end

-- Cari tahu bahan & pil apa yang dibutuhkan saat Rebirth gagal
local function detectNeededMaterials()
    local needed = {}
    local neededNames = {}

    -- 1. Cek dari Shared.Realms untuk realm saat ini atau realm berikutnya
    for _, idx in ipairs({ State.RealmIndex, State.RealmIndex + 1 }) do
        local r = RealmList[idx]
        if r then
            if r.Pill then
                table.insert(neededNames, r.Pill)
                for _, rec in ipairs(Recipes) do
                    if string.find(normalizeStr(rec.Name), normalizeStr(r.Pill), 1, true) then
                        for _, ing in ipairs(rec.Ingredients) do
                            table.insert(needed, ing)
                        end
                    end
                end
            end
            for _, m in ipairs(r.Mats or {}) do
                table.insert(needed, m)
            end
        end
    end

    -- 2. Scan Toast / Modal / ElderTalk UI teks di PlayerGui yang menyebut "Need" / "Require" / nama herbal
    local pg = getPlayerGui()
    if pg then
        for _, lbl in ipairs(pg:GetDescendants()) do
            if lbl:IsA("TextLabel") and isActuallyVisible(lbl) and not (OurGui and lbl:IsDescendantOf(OurGui)) then
                local low = string.lower(lbl.Text or "")
                if string.find(low, "need", 1, true) or string.find(low, "require", 1, true) or string.find(low, "missing", 1, true) or string.find(low, "butuh", 1, true) then
                    State.LastRequirementMsg = lbl.Text
                    for _, rec in ipairs(Recipes) do
                        if string.find(normalizeStr(low), normalizeStr(rec.Name), 1, true) then
                            for _, ing in ipairs(rec.Ingredients) do
                                table.insert(needed, ing)
                            end
                        end
                    end
                    for _, dispName in pairs(ItemCatalog) do
                        if string.find(normalizeStr(low), normalizeStr(dispName), 1, true) then
                            table.insert(needed, { Name = dispName, Count = 1 })
                        end
                    end
                end
            end
        end
    end

    -- 3. Fallback ke resep yang sesuai indeks realm bila Recipes tidak kosong
    if #needed == 0 and #Recipes > 0 then
        local rec = Recipes[((State.RealmIndex - 1) % #Recipes) + 1]
        if rec then
            for _, ing in ipairs(rec.Ingredients) do
                table.insert(needed, ing)
            end
        end
    end

    return needed, neededNames
end

local function brewAtCauldron()
    local cauldronPos = findCauldron()
    if not cauldronPos then
        log("Cauldron tidak ditemukan di pulau/map.")
        return false
    end

    travelTo(cauldronPos, "Cauldron (Kuali Ramuan)", 6)
    task.wait(0.25)

    local prompt = findPromptNear(cauldronPos, 24)
    if prompt then
        usePrompt(prompt)
        task.wait(0.4)
    end

    -- Klik tombol di Cauldron UI jika terbuka
    clickVisibleGui({ "brew", "craft", "make", "racik", "synthesize", "refine" }, nil, { "close", "exit" })
    task.wait(0.3)
    clickVisibleGui({ "confirm", "yes", "craft", "brew" }, nil, { "close", "cancel" })

    -- Coba fire Action remote untuk cauldron
    for actName, _ in pairs(Discovered.Learned.Cauldron) do
        fireAction(actName)
    end
    for actName, _ in pairs(Discovered.ActionStrings["UI.Cauldron"] or {}) do
        fireAction(actName)
    end
    fireAction("Brew")
    fireAction("CraftPill")
    log("Proses Cauldron dijalankan.")
    return true
end

local function gatherAndBrewForRebirth()
    local needed, pillNames = detectNeededMaterials()
    local missingList = {}
    local targetHerbNames = {}

    for _, item in ipairs(needed) do
        local have = countItemInBag(item.Name)
        if have < (item.Count or 1) then
            table.insert(missingList, { Name = item.Name, Need = (item.Count or 1) - have })
            table.insert(targetHerbNames, item.Name)
        end
    end

    if #missingList > 0 and State.AutoHerbFarm then
        log("Butuh bahan untuk Rebirth: " .. missingList[1].Name .. " (" .. missingList[1].Need .. "x)")
        local herbs = findHerbsInWorld(targetHerbNames)
        if #herbs == 0 then
            log("Tidak ada tanaman herbal terdeteksi di map saat ini.")
        else
            for i = 1, math.min(#herbs, 5) do
                if not State.AutoRebirth then break end
                local h = herbs[i]
                travelTo(h.Position, "Herbal: " .. h.Name, 5)
                task.wait(0.15)
                touchPart(h.Part)
                usePrompt(h.Prompt)
                for actName, _ in pairs(Discovered.Learned.Harvest) do
                    fireAction(actName, h.Part)
                end
                fireAction("Harvest", h.Name)
                task.wait(0.25)
            end
        end
    end

    if State.AutoCauldron then
        brewAtCauldron()
        task.wait(0.6)
    end
end

-- ═══════════════════════════════════════════
--  BREAKTHROUGH / REBIRTH EXECUTION
-- ═══════════════════════════════════════════
local function isTribulating()
    if attrOf({ "Tribulation", "InTribulation", "IsTribulating", "Tribulating" }) == true then
        return true
    end
    for _, n in ipairs({ "Tribulation", "TribulationCloud", "HeavenlyTribulation" }) do
        if workspace:FindFirstChild(n) then return true end
    end
    return false
end

local function attemptBreakthrough()
    local beforeIdx = State.RealmIndex
    local beforeName = State.Realm

    -- 1. Coba tombol HUD Breakthrough [B] (yang terlihat di tengah bawah foto: "Breakthrough • 92% [B]")
    pressKey(Enum.KeyCode.B)
    clickVisibleGui({ "breakthrough", "terobosan", "ascend", "rebirth" }, nil, { "close", "cancel" })
    task.wait(0.4)

    -- 2. Coba action remote dari konstanta ElderTalk / Hud atau Spy
    for actName, _ in pairs(Discovered.Learned.Breakthrough) do
        fireAction(actName)
    end
    for actName, _ in pairs(Discovered.ActionStrings["UI.ElderTalk"] or {}) do
        fireAction(actName)
    end
    fireAction("Breakthrough")
    fireAction("Rebirth")
    task.wait(0.6)

    refreshPlayerState()
    if State.RealmIndex > beforeIdx or State.Realm ~= beforeName then
        log("Breakthrough HUD berhasil! Realm: " .. State.Realm)
        return true
    end

    -- 3. Terbang menuju Elder Yun bila Breakthrough HUD butuh NPC Elder Yun
    local elderPos = findElderYun()
    if elderPos then
        travelTo(elderPos, "Elder Yun (Rebirth NPC)", 6)
        task.wait(0.25)
        local prompt = findPromptNear(elderPos, 24)
        if prompt then
            usePrompt(prompt)
            task.wait(0.5)
        end
        clickVisibleGui({ "breakthrough", "rebirth", "terobosan", "ascend", "yes", "confirm" }, nil, { "close", "cancel" })
        pressKey(Enum.KeyCode.B)
        fireAction("Breakthrough")
        fireAction("Rebirth")
    end

    -- Pantau hasil & Tribulation selama 10 detik
    local t0 = os.clock()
    while os.clock() - t0 < 10 do
        if not State.AutoRebirth then break end
        if isTribulating() and State.AutoDefend then
            log("Heavenly Tribulation aktif! Meditasi & Bertahan...")
            fireAction("Defend")
            startMeditatingAt(nil)
        end
        refreshPlayerState()
        if State.RealmIndex > beforeIdx or State.Realm ~= beforeName then
            log("Breakthrough sukses ke: " .. State.Realm)
            return true
        end
        task.wait(0.6)
    end

    return false
end

-- ═══════════════════════════════════════════
--  MAIN AUTO REBIRTH & MEDITATION LOOP
-- ═══════════════════════════════════════════
local function autoRebirthLoop()
    if State.LoopRunning then return end
    State.LoopRunning = true

    while State.AutoRebirth do
        local ok, err = pcall(function()
            refreshPlayerState()
            if State.Locked then return end

            if State.RebirthMaxRealm > 0 and State.RealmIndex >= State.RebirthMaxRealm then
                log("Target Realm tercapai! Loop berhenti.")
                State.AutoRebirth = false
                return
            end

            local qi = State.Qi or 0
            if qi >= State.QiThreshold then
                State.Step = "Terobosan / Breakthrough"
                stopMeditating()

                local success = attemptBreakthrough()
                if not success then
                    log("Rebirth gagal/tertahan — cek kebutuhan herbal & Cauldron...")
                    State.Step = "Cari Herbal & Racik Pil"
                    gatherAndBrewForRebirth()
                    State.Step = "Ulangi Breakthrough"
                    attemptBreakthrough()
                end
                task.wait(2.0)
            else
                State.Step = string.format("Kultivasi (Qi %.1f%%)", qi)
                local spotPos, spotName = getBestCultivationSpot()
                if spotPos then
                    local root = getRootPart()
                    if root and (root.Position - spotPos).Magnitude > 14 then
                        travelTo(spotPos, spotName or "Bagua Circle", 5)
                    end
                end

                if not isCurrentlyMeditating() then
                    startMeditatingAt(spotPos)
                end
                task.wait(1.5)
            end
        end)

        if not ok then
            log("AutoRebirth Error: " .. tostring(err))
            task.wait(2)
        end
        task.wait(0.4)
    end

    State.LoopRunning = false
    State.Step = "Siap"
    stopMeditating()
    pcall(setGameSwordMode, false)
    pcall(clearLeftoverMovers)
    log("Auto Rebirth berhenti.")
end

-- ═══════════════════════════════════════════
--  TALENT GACHA FAST ROLL
-- ═══════════════════════════════════════════
local function isTalentWindowOpen()
    local pg = getPlayerGui()
    if not pg then return false, nil end
    for _, obj in ipairs(pg:GetDescendants()) do
        if (obj:IsA("Frame") or obj:IsA("CanvasGroup") or obj:IsA("ScrollingFrame")) and isActuallyVisible(obj) then
            if not (OurGui and obj:IsDescendantOf(OurGui)) and obj.AbsoluteSize.X > 180 and obj.AbsoluteSize.Y > 140 then
                local low = string.lower(obj.Name)
                if string.find(low, "talent", 1, true) then
                    return true, obj
                end
                for _, child in ipairs(obj:GetChildren()) do
                    if child:IsA("TextLabel") and child.Visible then
                        local tl = string.lower(child.Text or "")
                        if string.find(tl, "talent", 1, true) or string.find(tl, "reroll", 1, true) then
                            return true, obj
                        end
                    end
                end
            end
        end
    end
    -- Jika tombol Roll/Reroll sudah terlihat di layar, window pasti sudah terbuka
    local rollBtns = findVisibleButtons({ "reroll", "roll talent", "spin", "roll" }, nil, { "close", "exit", "auto", "lock", "scroll" })
    if #rollBtns > 0 then
        return true, nil
    end
    return false, nil
end

local function readCurrentTalentFromWindow(winObj)
    local scope = winObj or getPlayerGui()
    if not scope then return nil end
    local foundText = nil
    for _, lbl in ipairs(scope:GetDescendants()) do
        if lbl:IsA("TextLabel") and isActuallyVisible(lbl) and not (OurGui and lbl:IsDescendantOf(OurGui)) then
            local txt = lbl.Text or ""
            local low = string.lower(txt)
            if State.TargetTalent ~= "" and string.find(low, string.lower(State.TargetTalent), 1, true) then
                return txt, true
            end
            if State.TalentTier ~= "" and string.find(low, string.lower(State.TalentTier), 1, true) then
                return txt, true
            end
            if string.find(low, "talent", 1, true) and #txt > 3 then
                foundText = txt
            end
        end
    end
    return foundText, false
end

local function rollTalentOnce()
    -- 1. Pastikan window talent terbuka
    local isOpen, winFrame = isTalentWindowOpen()
    if not isOpen then
        clickVisibleGui({ "talent", "bakat" }, nil, { "close", "auto" })
        task.wait(0.35)
        isOpen, winFrame = isTalentWindowOpen()
    end

    -- 2. Cari & klik tombol Roll / Reroll / Spin KHUSUS di dalam Talent window (atau layar)
    local rolledUi = false
    if winFrame then
        rolledUi = clickVisibleGui({ "roll", "reroll", "spin", "gacha", "draw", "awak", "acak" }, winFrame, { "close", "exit", "auto", "lock" })
    end
    if not rolledUi then
        rolledUi = clickVisibleGui({ "reroll", "roll talent", "spin", "gacha", "roll" }, nil, { "close", "exit", "auto", "lock" })
    end

    -- 3. Panggil modul TalentWindow langsung jika menyediakan fungsi roll
    local twMod = safeReqClient("UI.TalentWindow")
    if type(twMod) == "table" then
        for _, fnName in ipairs({ "Roll", "Reroll", "Spin", "RequestRoll", "DoRoll" }) do
            if type(twMod[fnName]) == "function" then
                pcall(twMod[fnName])
            end
        end
    end

    -- 4. Tembak semua aksi yang dipelajari dari Spy / konstanta TalentWindow
    for actName, args in pairs(Discovered.Learned.RollTalent) do
        fireAction(unpackFn(args))
    end
    for actName, kind in pairs(Discovered.ActionStrings["UI.TalentWindow"] or {}) do
        if kind == "FIRE" or string.find(string.lower(actName), "roll", 1, true) or string.find(string.lower(actName), "talent", 1, true) then
            fireAction(actName)
        end
    end

    -- 5. Fallback nama standar
    if not rolledUi then
        fireAction("RollTalent")
        fireAction("TalentRoll")
        fireAction("RerollTalent")
    end

    local talentTxt, matched = readCurrentTalentFromWindow(winFrame)
    return matched, talentTxt
end

local function talentGachaLoop()
    if State.LoopGacha then return end
    State.LoopGacha = true
    local count = 0

    while State.AutoGacha do
        local shouldStop = false
        pcall(function()
            local matched, talentName = rollTalentOnce()
            count = count + 1
            if matched then
                log("Target Talent Didapat (" .. count .. "x roll): " .. tostring(talentName))
                State.AutoGacha = false
                shouldStop = true
            end
        end)
        if shouldStop then break end
        task.wait(State.RollDelay or 0.35)
    end
    State.LoopGacha = false
end

-- ═══════════════════════════════════════════
--  FESTIVAL & SKY LANTERN
-- ═══════════════════════════════════════════
local function collectSkyLanterns()
    local root = getRootPart()
    local origin = root and root.Position or Vector3.zero
    local lanterns = {}

    for _, obj in ipairs(workspace:GetDescendants()) do
        if (obj:IsA("BasePart") or obj:IsA("Model")) and not isPlayerCharacterDescendant(obj) then
            local low = string.lower(obj.Name)
            if string.find(low, "skylantern", 1, true) or string.find(low, "lantern", 1, true) or string.find(low, "lentera", 1, true) then
                local p = posOf(obj)
                if p and p.Y > -50 then
                    table.insert(lanterns, { Part = partOf(obj), Position = p, Name = obj.Name, Dist = (p - origin).Magnitude })
                end
            end
        end
    end
    table.sort(lanterns, function(a, b) return a.Dist < b.Dist end)

    local got = 0
    for i = 1, math.min(#lanterns, 8) do
        local l = lanterns[i]
        if l.Part and l.Part.Parent then
            travelTo(l.Position, "Sky Lantern", 7)
            task.wait(0.15)
            touchPart(l.Part)
            local prompt = findPromptNear(l.Position, 16)
            if prompt then usePrompt(prompt) end
            fireAction("CollectLantern", l.Name)
            got = got + 1
            task.wait(0.2)
        end
    end
    return got
end

local function buyFestivalItem(itemName)
    itemName = (itemName and itemName ~= "") and itemName or "Sky Lantern Charm"
    log("Membeli item: " .. itemName)

    clickVisibleGui({ "festival", "event", "shop", "toko" }, nil, { "close" })
    task.wait(0.35)
    clickVisibleGui({ itemName, "sky lantern charm", "charm" }, nil, { "close" })
    task.wait(0.2)
    clickVisibleGui({ "buy", "purchase", "beli", "exchange", "confirm" }, nil, { "close", "cancel" })

    for actName, _ in pairs(Discovered.Learned.ShopBuy) do
        fireAction(actName, itemName)
    end
    fireAction("BuyFestivalItem", itemName)
    fireAction("Buy", itemName)
end

-- ═══════════════════════════════════════════
--  INITIALIZE DISCOVERY & DATA
-- ═══════════════════════════════════════════
installPassiveSpy()
task.spawn(extractConstantsFromClient)

buildItemCatalog()
buildRealmList()
buildRecipes()
scanSharedLocations()
scanBaguaCircles()
scanIslands()

-- ═══════════════════════════════════════════
--  BUILD UI (UNIONSAL GLASS BENTO)
-- ═══════════════════════════════════════════
local Window = Unionsal:CreateWindow({
    Name       = "unionsal",
    Subtitle   = ".gg/unionsal",
    GameName   = "Cultivation Legends",
    ScriptName = "cultivationlegends.lua",
    Version    = "v2.5",
})

OurGui = Window.ScreenGui

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
    card.Size = UDim2.new(1, 0, 0, height or 46)
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
    label.TextColor3 = Color3.fromRGB(175, 110, 255)
    label.Text = ""
    label.Parent = card
    return label
end

-- ═══════════════════════════════════════════
--  TAB 1: CULTIVATION & REBIRTH
-- ═══════════════════════════════════════════
local CultTab = Window:CreateTab("Cultivation", "sprout", "Main")
CultTab:CreateSection("Status Kultivasi Real-time")
State.StatusLabel = createInfoCard(CultTab, 48)
State.StatusLabel.Text = "Membaca Realm & Qi..."

CultTab:CreateSection("Auto Rebirth & Meditasi (Bagua Circle)")
CultTab:CreateToggle({
    Name = "Auto Rebirth (Bagua Circle → Herbal/Cauldron → Breakthrough)",
    CurrentValue = false,
    Callback = function(v)
        State.AutoRebirth = v
        if v then
            notify("Auto Rebirth", "Aktif! Menuju spot Bagua Circle terbaik sesuai ranah Anda.")
            task.spawn(autoRebirthLoop)
        else
            Travel.Cancelled = true
            notify("Auto Rebirth", "Dihentikan.")
        end
    end,
})

CultTab:CreateToggle({
    Name = "Auto Meditate (Terbang ke Bagua Circle & Meditasi)",
    CurrentValue = false,
    Callback = function(v)
        State.AutoMeditate = v
        if v then
            task.spawn(function()
                local spotPos, spotName = getBestCultivationSpot()
                if spotPos then
                    travelTo(spotPos, spotName or "Bagua Circle", 5)
                end
                startMeditatingAt(spotPos)
            end)
        else
            stopMeditating()
        end
        notify("Auto Meditate", v and "Aktif." or "Nonaktif.")
    end,
})

CultTab:CreateSlider({
    Name = "Batas Qi untuk Breakthrough (%)",
    Range = { 50, 100 },
    Increment = 0.5,
    Suffix = "%",
    CurrentValue = 99.5,
    Callback = function(v)
        State.QiThreshold = v
    end,
})

CultTab:CreateToggle({
    Name = "Auto Cari Herbal & Racik Cauldron Jika Rebirth Gagal",
    CurrentValue = true,
    Callback = function(v)
        State.AutoHerbFarm = v
        State.AutoCauldron = v
    end,
})

CultTab:CreateToggle({
    Name = "Auto Bertahan saat Heavenly Tribulation",
    CurrentValue = true,
    Callback = function(v)
        State.AutoDefend = v
    end,
})

CultTab:CreateSection("Tombol Aksi Cepat")
CultTab:CreateButton({
    Name = "Terbang ke Bagua Circle (Sesuai Ranah) & Meditasi",
    Callback = safeRun(function()
        task.spawn(function()
            local spotPos, spotName = getBestCultivationSpot()
            if spotPos then
                travelTo(spotPos, spotName or "Bagua Circle", 5)
                local okM = startMeditatingAt(spotPos)
                notify("Bagua Circle", okM and ("Meditasi dimulai di " .. tostring(spotName)) or "Tiba di Bagua Circle.")
            else
                notify("Bagua Circle", "Spot belum terdeteksi.")
            end
        end)
    end),
})

CultTab:CreateButton({
    Name = "Eksekusi Breakthrough [B] / Elder Yun Sekarang",
    Callback = safeRun(function()
        task.spawn(function()
            attemptBreakthrough()
        end)
    end),
})

CultTab:CreateButton({
    Name = "Reset / Lepas Karakter (Jika Terasa Nyangkut)",
    Callback = function()
        State.AutoRebirth = false
        State.AutoMeditate = false
        Travel.Cancelled = true
        Travel.Active = false
        State.Locked = false
        stopMeditating()
        setGameSwordMode(false)
        clearLeftoverMovers()
        notify("Unstuck", "Semua flight mover & lock dibersihkan.")
    end,
})

-- ═══════════════════════════════════════════
--  TAB 2: MOVEMENT & SWORD FLIGHT
-- ═══════════════════════════════════════════
local MoveTab = Window:CreateTab("Movement", "rocket", "Main")
MoveTab:CreateSection("Pengaturan Terbang Pakai Pedang")

MoveTab:CreateToggle({
    Name = "Otomatis Terbang Pakai Sword Saat Pindah Lokasi",
    CurrentValue = true,
    Callback = function(v)
        State.UseSwordFlight = v
    end,
})

MoveTab:CreateSlider({
    Name = "Kecepatan Terbang",
    Range = { 50, 400 },
    Increment = 5,
    Suffix = " studs/s",
    CurrentValue = 150,
    Callback = function(v)
        State.FlySpeed = v
    end,
})

MoveTab:CreateSlider({
    Name = "Ketinggian Terbang Natural",
    Range = { 10, 80 },
    Increment = 2,
    Suffix = " studs",
    CurrentValue = 24,
    Callback = function(v)
        State.NaturalHeight = v
    end,
})

MoveTab:CreateSlider({
    Name = "WalkSpeed (Jalan Kaki)",
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
    Name = "Aktifkan Mode Sword / Terbang Game",
    Callback = safeRun(function()
        setGameSwordMode(true)
        notify("Sword", "Sinyal mode pedang dikirim.")
    end),
})

MoveTab:CreateButton({
    Name = "Matikan Mode Sword & Turun",
    Callback = safeRun(function()
        Travel.Cancelled = true
        setGameSwordMode(false)
        clearLeftoverMovers()
        notify("Sword", "Mode terbang dimatikan.")
    end),
})

-- ═══════════════════════════════════════════
--  TAB 3: TALENT GACHA FAST ROLL
-- ═══════════════════════════════════════════
local TalentTab = Window:CreateTab("Talent Gacha", "gem", "Main")
TalentTab:CreateSection("Auto Roll Talent (Fast Gacha)")

TalentTab:CreateDropdown({
    Name = "Tier / Rarity Target",
    Options = { "Mythic", "Legendary", "Divine", "Immortal", "Godly", "Celestial" },
    CurrentValue = "Mythic",
    Callback = function(v)
        State.TalentTier = v
    end,
})

TalentTab:CreateInput({
    Name = "Nama Talent Spesifik (Opsional)",
    PlaceholderText = "Kosongkan jika pakai Tier",
    Callback = function(text)
        State.TargetTalent = text
    end,
})

TalentTab:CreateSlider({
    Name = "Jeda Antar Roll (Detik)",
    Range = { 0.1, 1.5 },
    Increment = 0.05,
    Suffix = " s",
    CurrentValue = 0.35,
    Callback = function(v)
        State.RollDelay = v
    end,
})

TalentTab:CreateToggle({
    Name = "Auto Roll Talent (Otomatis Buka UI & Roll)",
    CurrentValue = false,
    Callback = function(v)
        State.AutoGacha = v
        if v then
            notify("Talent", "Fast Roll aktif! Memicu tombol Roll di TalentWindow.")
            task.spawn(talentGachaLoop)
        else
            notify("Talent", "Fast Roll berhenti.")
        end
    end,
})

TalentTab:CreateButton({
    Name = "Roll 1x Sekarang",
    Callback = safeRun(function()
        task.spawn(function()
            local matched, name = rollTalentOnce()
            notify("Talent Roll", matched and ("Target didapat: " .. tostring(name)) or "Roll dikirim.")
        end)
    end),
})

-- ═══════════════════════════════════════════
--  TAB 4: EVENT & FESTIVAL (SKY LANTERN CHARM)
-- ═══════════════════════════════════════════
local EventTab = Window:CreateTab("Event Festival", "zap", "Main")
EventTab:CreateSection("Sky Lantern Hunter")

EventTab:CreateToggle({
    Name = "Auto Kumpulkan Sky Lantern",
    CurrentValue = false,
    Callback = function(v)
        State.AutoLantern = v
        if v then
            notify("Lantern", "Berburu Sky Lantern aktif.")
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
    Name = "Ambil Semua Sky Lantern Sekali Jalan",
    Callback = safeRun(function()
        task.spawn(function()
            local n = collectSkyLanterns()
            notify("Lantern", n .. " Sky Lantern diambil.")
        end)
    end),
})

EventTab:CreateSection("Festival Shop (Otomatis Pilih Item)")
EventTab:CreateDropdown({
    Name = "Item Festival Shop",
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
            buyFestivalItem("Sky Lantern Charm")
            notify("Shop", "Pembelian Sky Lantern Charm dikirim.")
        end)
    end),
})

EventTab:CreateToggle({
    Name = "Auto Beli Item Terpilih",
    CurrentValue = false,
    Callback = function(v)
        State.AutoShop = v
        if v then
            task.spawn(function()
                while State.AutoShop do
                    buyFestivalItem(State.ShopItem)
                    task.wait(6.0)
                end
            end)
        end
    end,
})

-- ═══════════════════════════════════════════
--  TAB 5: TELEPORT & DAFTAR PULAU 1-KLIK
-- ═══════════════════════════════════════════
local TpTab = Window:CreateTab("Teleport", "navigation", "Main")
TpTab:CreateSection("Mode Perjalanan Teleport")

TpTab:CreateDropdown({
    Name = "Pilih Mode",
    Options = { "Smooth Fly (Sword)", "Instant CFrame" },
    CurrentValue = "Smooth Fly (Sword)",
    Callback = function(v)
        State.TeleportMode = v
    end,
})

local function executeTeleport(pos, label)
    if not pos then
        notify("Teleport", "Koordinat tidak ditemukan.")
        return
    end
    task.spawn(function()
        if State.TeleportMode == "Instant CFrame" then
            instantTeleport(pos)
            notify("Teleport", "Instan tiba di " .. tostring(label))
        else
            travelTo(pos, label, 5)
            notify("Teleport", "Tiba di " .. tostring(label))
        end
    end)
end

-- Container dinamis untuk tombol 1-klik daftar pulau, Bagua Circle, dan Shared.World!
TpTab:CreateSection("Cari & Klik Langsung Pulau / Map")
local DynamicListContainer = Instance.new("Frame")
DynamicListContainer.Name = "DynamicTpList"
DynamicListContainer.Size = UDim2.new(1, 0, 0, 10)
DynamicListContainer.AutomaticSize = Enum.AutomaticSize.Y
DynamicListContainer.BackgroundTransparency = 1
DynamicListContainer.Parent = TpTab.Page

local dlcLayout = Instance.new("UIListLayout")
dlcLayout.SortOrder = Enum.SortOrder.LayoutOrder
dlcLayout.Padding = UDim.new(0, 6)
dlcLayout.Parent = DynamicListContainer

local function createDynamicTpBtn(title, subInfo, targetPos)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3 = Color3.fromRGB(22, 17, 34)
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Text = ""
    btn.Parent = DynamicListContainer

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = btn

    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(44, 36, 62)
    s.Thickness = 1
    s.Parent = btn

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -24, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = title .. (subInfo and ("  •  " .. subInfo) or "")
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 12
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextTruncate = Enum.TextTruncate.AtEnd
    lbl.Parent = btn

    btn.MouseEnter:Connect(function()
        s.Color = Color3.fromRGB(135, 65, 235)
        btn.BackgroundColor3 = Color3.fromRGB(28, 22, 42)
    end)
    btn.MouseLeave:Connect(function()
        s.Color = Color3.fromRGB(44, 36, 62)
        btn.BackgroundColor3 = Color3.fromRGB(22, 17, 34)
    end)
    btn.MouseButton1Click:Connect(function()
        executeTeleport(targetPos, title)
    end)
end

local function rebuildDynamicTpList()
    for _, ch in ipairs(DynamicListContainer:GetChildren()) do
        if ch:IsA("TextButton") or ch:IsA("TextLabel") then
            ch:Destroy()
        end
    end

    scanSharedLocations()
    scanBaguaCircles()
    scanIslands()

    local filter = string.lower(State.TeleportSearch or "")
    local entries = {}

    -- 1. Bagua Circles (Cultivation Spots)
    for _, b in ipairs(BaguaSpots) do
        table.insert(entries, { Name = b.Name, Tag = "x" .. tostring(b.Multiplier) .. " Qi", Pos = b.Position })
    end

    -- 2. Pulau Pemain di Server
    for _, isl in ipairs(IslandSpots) do
        table.insert(entries, { Name = isl.Name, Tag = isl.RawName, Pos = isl.Position })
    end

    -- 3. Lokasi Penting
    local elderPos = findElderYun()
    if elderPos then table.insert(entries, { Name = "Elder Yun (Rebirth NPC)", Tag = "NPC", Pos = elderPos }) end
    local cauldronPos = findCauldron()
    if cauldronPos then table.insert(entries, { Name = "Cauldron (Kuali Ramuan)", Tag = "Craft", Pos = cauldronPos }) end

    -- 4. Shared.World / Shared.DungeonData
    for _, ws in ipairs(WorldSpots) do
        table.insert(entries, { Name = ws.Name, Tag = ws.Source, Pos = ws.Position })
    end

    local shown = 0
    for _, e in ipairs(entries) do
        if filter == "" or string.find(string.lower(e.Name .. " " .. (e.Tag or "")), filter, 1, true) then
            createDynamicTpBtn(e.Name, e.Tag, e.Pos)
            shown = shown + 1
            if shown >= 45 then break end
        end
    end

    if shown == 0 then
        local emptyLbl = Instance.new("TextLabel")
        emptyLbl.Size = UDim2.new(1, 0, 0, 32)
        emptyLbl.BackgroundTransparency = 1
        emptyLbl.Text = "Tidak ada lokasi ditemukan (klik Refresh)."
        emptyLbl.Font = Enum.Font.Gotham
        emptyLbl.TextSize = 11
        emptyLbl.TextColor3 = Color3.fromRGB(165, 155, 185)
        emptyLbl.Parent = DynamicListContainer
    end
end

TpTab:CreateInput({
    Name = "Filter / Cari Nama Pulau atau Map",
    PlaceholderText = "Ketik untuk memfilter daftar di atas...",
    Callback = function(text)
        State.TeleportSearch = text
        rebuildDynamicTpList()
    end,
})

TpTab:CreateButton({
    Name = "Refresh Semua Pulau, Bagua & Map",
    Callback = safeRun(function()
        rebuildDynamicTpList()
        notify("Teleport", "Daftar lokasi diperbarui (" .. #IslandSpots .. " pulau, " .. #BaguaSpots .. " bagua, " .. #WorldSpots .. " world).")
    end),
})

rebuildDynamicTpList()

-- ═══════════════════════════════════════════
--  TAB 6: DIAGNOSTIK & DATA INSPECTOR
-- ═══════════════════════════════════════════
local DiagTab = Window:CreateTab("Diagnostik", "activity", "Config")
DiagTab:CreateSection("Log Aktivitas Real-time")
State.LogLabel = createInfoCard(DiagTab, 140)
State.LogLabel.Text = "Menunggu aktivitas..."

DiagTab:CreateSection("Inspeksi & Remote Spy")
DiagTab:CreateButton({
    Name = "Scan Data Game (Shared, Bagua, Islands, Konstanta)",
    Callback = safeRun(function()
        extractConstantsFromClient()
        buildItemCatalog()
        buildRealmList()
        buildRecipes()
        scanSharedLocations()
        scanBaguaCircles()
        scanIslands()

        log("Realms: " .. #RealmList .. " | Recipes: " .. #Recipes .. " | World: " .. #WorldSpots)
        log("Bagua Circle: " .. #BaguaSpots .. " | Islands: " .. #IslandSpots)
        if #BaguaSpots > 0 then
            log("Bagua #1: " .. BaguaSpots[1].Name .. " (x" .. BaguaSpots[1].Multiplier .. " Qi)")
        end
        log("Spy recorded: " .. #Discovered.SpyHistory .. " calls")
    end),
})

DiagTab:CreateButton({
    Name = "Dump Struktur Lengkap ke cultivation_dump.txt",
    Callback = safeRun(function()
        local out = {}
        local function addLine(s) table.insert(out, tostring(s)) end

        local function dumpTable(tbl, indent, depth)
            if type(tbl) ~= "table" or depth > 3 then
                addLine(indent .. tostring(tbl))
                return
            end
            local count = 0
            for k, v in pairs(tbl) do
                count = count + 1
                if count > 40 then addLine(indent .. "... (truncated)"); break end
                if type(v) == "table" then
                    addLine(indent .. "[" .. tostring(k) .. "] = {")
                    dumpTable(v, indent .. "  ", depth + 1)
                    addLine(indent .. "}")
                else
                    addLine(indent .. "[" .. tostring(k) .. "] = " .. tostring(v))
                end
            end
        end

        for _, mName in ipairs({ "Realms", "World", "Lotus", "Alchemy", "Items", "FlyingSword", "SkyLantern", "Config" }) do
            addLine("=== Shared." .. mName .. " ===")
            local t = safeReqShared(mName)
            if t then dumpTable(t, "  ", 0) else addLine("  (nil)") end
        end

        addLine("=== Client.UI.State ===")
        local st = safeReqClient("UI.State")
        if type(st) == "table" then dumpTable(st, "  ", 0) else addLine("  (nil)") end

        addLine("=== Spy History ===")
        for _, s in ipairs(Discovered.SpyHistory) do addLine("  " .. s) end

        addLine("=== Extracted Action Strings ===")
        for owner, dict in pairs(Discovered.ActionStrings) do
            local keys = {}
            for k, tag in pairs(dict) do table.insert(keys, k .. "(" .. tag .. ")") end
            addLine("  " .. owner .. ": " .. table.concat(keys, ", "))
        end

        local content = table.concat(out, "\n")
        if type(writefile) == "function" then
            writefile("cultivation_dump.txt", content)
            notify("Dump Sukses", "Tersimpan di workspace executor: cultivation_dump.txt")
            log("Saved cultivation_dump.txt (" .. #out .. " baris).")
        else
            print(content)
            notify("Dump Console", "Executor tidak punya writefile — cek F9 Console.")
        end
    end),
})

-- ═══════════════════════════════════════════
--  STATUS LOOP & STARTUP
-- ═══════════════════════════════════════════
task.spawn(function()
    while true do
        pcall(function()
            refreshPlayerState()
            local hum = getHumanoid()
            if hum and not Travel.Active then
                hum.WalkSpeed = State.WalkSpeed
            end
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

-- Anti-AFK
task.spawn(function()
    while true do
        pcall(function()
            local hum = getHumanoid()
            if hum and not isCurrentlyMeditating() and not State.Locked and hum.MoveDirection.Magnitude < 0.1 then
                pcall(function() VirtualUser:CaptureController() end)
                hum.Jump = true
                task.wait(0.1)
                hum.Jump = false
            end
        end)
        task.wait(110)
    end
end)

task.spawn(function()
    task.wait(0.6)
    refreshPlayerState()
    log("Siap! Realm: " .. tostring(State.Realm) .. " | Qi: " .. string.format("%.1f", State.Qi) .. "%")
    log("Terdeteksi: " .. #BaguaSpots .. " Bagua Circle, " .. #IslandSpots .. " Pulau, " .. #WorldSpots .. " World Spot.")
    Window:Notify({
        Title = "Unionsal Hub",
        Content = "Cultivation Legends v2.5 siap! Cek Tab Teleport untuk tombol 1-klik semua pulau & Bagua.",
        Duration = 5,
    })
    task.wait(2.5)
    pcall(rebuildDynamicTpList)
end)
