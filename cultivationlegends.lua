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
        local anchor = obj:FindFirstChild("SignAnchor", true)
            or obj:FindFirstChild("PenglaiSignAnchor", true)
            or obj:FindFirstChild("Plate", true)
            or obj:FindFirstChild("Sign", true)
            or obj:FindFirstChild("Pad", true)
            or obj:FindFirstChild("Circle", true)
        if anchor and anchor:IsA("BasePart") then return anchor end
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
        if cur:IsA("LayerCollector") or cur:IsA("ScreenGui") or cur:IsA("BillboardGui") or cur:IsA("SurfaceGui") then
            return cur.Enabled == true
        elseif cur:IsA("GuiObject") then
            if cur.Visible == false then return false end
        end
        cur = cur.Parent
    end
    return true
end

local function triggerButton(btn)
    if not btn then return false end
    if not (btn:IsA("GuiButton") or btn:IsA("GuiObject")) then return false end
    local fired = false

    -- 1. firesignal (executor native)
    if type(firesignal) == "function" and btn:IsA("GuiButton") then
        for _, sigName in ipairs({ "Activated", "MouseButton1Click", "MouseButton1Down", "MouseButton1Up" }) do
            local ok = pcall(function() firesignal(btn[sigName]) end)
            if ok then fired = true end
        end
    end

    -- 2. getconnections fallback
    if type(getconnections) == "function" and btn:IsA("GuiButton") then
        for _, sigName in ipairs({ "Activated", "MouseButton1Click", "MouseButton1Down" }) do
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
    if btn:IsA("GuiButton") then
        pcall(function() btn:Activate() end)
    end

    -- 4. VirtualInputManager click WITH and WITHOUT GuiInset
    if VirtualInputManager and btn:IsA("GuiObject") then
        pcall(function()
            local pos = btn.AbsolutePosition + (btn.AbsoluteSize * 0.5)
            if pos.X > 0 and pos.Y > 0 then
                VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                task.wait(0.03)
                VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                fired = true

                -- Juga coba dengan offset GuiInset
                local inset = Vector2.zero
                pcall(function() inset = GuiService:GetGuiInset() end)
                if inset.Y > 0 then
                    VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y + inset.Y, 0, true, game, 1)
                    task.wait(0.03)
                    VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y + inset.Y, 0, false, game, 1)
                end
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

-- ═══════════════════════════════════════════
--  GAME-SPECIFIC: Klik "Hit" button berdasarkan nama PARENT
--  Semua tombol di game ini: TextButton[Hit] Text='' Parent=NamaFrame
-- ═══════════════════════════════════════════
-- Ambil nama parent dari button untuk identifikasi
local function getHitButtonLabel(btn)
    local parentName = (btn.Parent and btn.Parent.Name) or ""
    -- Ambil juga teks dari sibling TextLabel di parent yang sama
    local siblText = ""
    if btn.Parent then
        for _, sib in ipairs(btn.Parent:GetDescendants()) do
            if sib:IsA("TextLabel") and sib.Text and sib.Text ~= "" then
                siblText = siblText .. " " .. sib.Text
            end
        end
    end
    return parentName .. " " .. siblText
end

-- Cari Hit button berdasarkan Parent.Name, mendukung pola "Hit" button kosong
local function findHitButton(parentKeywords, excludeKeywords, scopeGui)
    local scope = scopeGui or getPlayerGui()
    if not scope then return nil end
    local excl = excludeKeywords or {}

    for _, obj in ipairs(scope:GetDescendants()) do
        if (obj:IsA("TextButton") or obj:IsA("ImageButton"))
            and obj.Visible
            and obj.AbsoluteSize.X >= 8
            and not (OurGui and obj:IsDescendantOf(OurGui)) then

            -- Bangun label: nama obj sendiri + nama parent + nama grandparent
            local ownName    = string.lower(obj.Name or "")
            local parentName = string.lower(obj.Parent and obj.Parent.Name or "")
            local gpName     = string.lower(obj.Parent and obj.Parent.Parent and obj.Parent.Parent.Name or "")
            local combined   = ownName .. "|" .. parentName .. "|" .. gpName

            -- Cek exclude dulu
            local excluded = false
            for _, ex in ipairs(excl) do
                if string.find(combined, string.lower(ex), 1, true) then
                    excluded = true
                    break
                end
            end
            if not excluded then
                for _, kw in ipairs(parentKeywords) do
                    if string.find(combined, string.lower(kw), 1, true) then
                        return obj
                    end
                end
            end
        end
    end
    return nil
end

-- Klik Hit button berdasarkan parent name, return true jika berhasil
local function clickHitButton(parentKeywords, excludeKeywords, scopeGui)
    local btn = findHitButton(parentKeywords, excludeKeywords, scopeGui)
    if btn then
        triggerButton(btn)
        return true
    end
    return false
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

-- Parser angka dengan satuan K, M, B, T (misal "35.8K" → 35800, "140K" → 140000)
local function parseSuffixedNumber(str)
    if not str then return nil end
    local clean = string.gsub(str, "[,%s]", "")
    local num, suffix = string.match(string.upper(clean), "([%d%.]+)%s*([KMBT]?)")
    if not num then return nil end
    local n = tonumber(num)
    if not n then return nil end
    if suffix == "K" then n = n * 1e3
    elseif suffix == "M" then n = n * 1e6
    elseif suffix == "B" then n = n * 1e9
    elseif suffix == "T" then n = n * 1e12
    end
    return n
end

-- Scan HUD untuk persentase Qi:
-- 1. Format "35.8K / 140K qi" (format resmi Cultivation Legends di bar atas)
-- 2. Format persen "%"
-- 3. Ukuran lebar Scale X dari Frame Progress Bar di CultivationHud
local function scanHudBreakthroughQi()
    local pg = getPlayerGui()
    if not pg then return nil end
    local bestPercent, bestScore = nil, -1

    for _, d in ipairs(pg:GetDescendants()) do
        if d:IsA("TextLabel") and isActuallyVisible(d) and not (OurGui and d:IsDescendantOf(OurGui)) then
            local txt = d.Text or ""
            local low = string.lower(txt)

            -- Format 1: "35.8K / 140K qi" atau "140K / 140K"
            local curStr, maxStr = string.match(txt, "([%d%.]+%s*[KkMmBbTt]?%s*)%s*/%s*([%d%.]+%s*[KkMmBbTt]?)")
            if curStr and maxStr then
                local curVal = parseSuffixedNumber(curStr)
                local maxVal = parseSuffixedNumber(maxStr)
                if curVal and maxVal and maxVal > 0 then
                    local pct = clamp((curVal / maxVal) * 100, 0, 100)
                    local score = 25
                    if string.find(low, "qi", 1, true) then score = score + 35 end
                    local pName = d.Parent and string.lower(d.Parent.Name) or ""
                    if string.find(pName, "qi", 1, true) or string.find(pName, "hud", 1, true) or string.find(pName, "bar", 1, true) then
                        score = score + 15
                    end
                    if score > bestScore then
                        bestScore = score
                        bestPercent = pct
                    end
                end
            end

            -- Format 2: "100%" atau "92%"
            local pctNum = tonumber(string.match(txt, "(%d+%.?%d*)%s*%%"))
            if pctNum then
                local score = 10
                if string.find(low, "breakthrough", 1, true) or string.find(low, "qi", 1, true) or string.find(low, "[b]", 1, true) then
                    score = score + 25
                end
                local pName = d.Parent and string.lower(d.Parent.Name) or ""
                if string.find(pName, "break", 1, true) or string.find(pName, "qi", 1, true) or string.find(pName, "hud", 1, true) then
                    score = score + 10
                end
                if score > bestScore then
                    bestScore = score
                    bestPercent = pctNum
                end
            end
        end
    end

    -- Format 3: Ukuran Frame Bar di CultivationHud
    local hud = pg:FindFirstChild("CultivationHud")
    if hud then
        for _, obj in ipairs(hud:GetDescendants()) do
            if obj:IsA("Frame") and obj.Visible then
                local pName = obj.Parent and string.lower(obj.Parent.Name) or ""
                local oName = string.lower(obj.Name)
                if string.find(pName, "bar", 1, true) or string.find(oName, "bar", 1, true) or string.find(oName, "fill", 1, true) or string.find(oName, "progress", 1, true) then
                    local sx = obj.Size.X.Scale
                    if sx and sx > 0 and sx <= 1.02 then
                        local barPct = clamp(sx * 100, 0, 100)
                        if 15 > bestScore then
                            bestScore = 15
                            bestPercent = barPct
                        end
                    end
                end
            end
        end
    end

    return bestPercent
end

-- Peta realm name → index (berdasarkan head label scan real dari Workspace)
local REALM_TO_IDX = {
    ["body tempering"]           = 1, ["bodytemper"] = 1,
    ["qi gathering"]             = 2, ["qigathering"] = 2,
    ["foundation establishment"] = 3, ["foundationestablishment"] = 3, ["foundation"] = 3,
    ["golden core"]              = 4, ["goldencore"] = 4,
    ["nascent soul"]             = 5, ["nascentsoul"] = 5,
    ["heavenly being"]           = 6, ["heavenlybeing"] = 6,
    ["great heavenly being"]     = 7, ["greatheavenly"] = 7, ["great heavenly"] = 7,
    ["heavenly lord"]            = 8, ["heavenlylord"] = 8,
    ["immortal"]                 = 9,
}

-- Baca realm dari head label karakter LOCAL (paling akurat, langsung dari game)
local function readRealmFromHead()
    local char = getCharacter()
    if not char then return nil, nil end
    local head = char:FindFirstChild("Head")
    if not head then return nil, nil end
    for _, gui in ipairs(head:GetDescendants()) do
        if (gui:IsA("TextLabel") or gui:IsA("TextButton")) and gui.Text ~= "" then
            local raw = gui.Text
            local low = string.lower(raw)
            -- Format: "Qi Gathering · 3" atau "Golden Core · 2"
            for name, idx in pairs(REALM_TO_IDX) do
                if string.find(low, name, 1, true) then
                    return name, idx
                end
            end
        end
    end
    return nil, nil
end

local function refreshPlayerState()
    -- 1. Prioritas: baca langsung dari head label karakter (terbukti ada: "Qi Gathering · 3", "Nascent Soul · 2")
    local headName, headIdx = readRealmFromHead()
    if headName and headIdx then
        State.Realm = headName
        State.RealmIndex = headIdx
    else
        -- 2. Scan banner Realm di CultivationHud (terbukti ada di atas layar: "Foundation Establishment", dll)
        local foundHudRealm = false
        local pg = getPlayerGui()
        local hud = pg and pg:FindFirstChild("CultivationHud")
        if hud then
            for _, d in ipairs(hud:GetDescendants()) do
                if d:IsA("TextLabel") and d.Text ~= "" and isActuallyVisible(d) and not (OurGui and d:IsDescendantOf(OurGui)) then
                    local low = string.lower(d.Text)
                    for name, idx in pairs(REALM_TO_IDX) do
                        if string.find(low, name, 1, true) then
                            State.Realm = name
                            State.RealmIndex = idx
                            foundHudRealm = true
                            break
                        end
                    end
                    if foundHudRealm then break end
                end
            end
        end

        -- 3. Fallback: Cek Client.UI.State / Attribute
        if not foundHudRealm then
            local stRealm = readStateModuleField({ "Realm", "realm", "RealmName", "RealmIndex", "Stage", "CultivationRealm" })
            local realmVal = stRealm or attrOf({ "Realm", "RealmName", "CultivationRealm", "Rank", "Stage", "RealmIndex" })
            if type(realmVal) == "string" and realmVal ~= "" then
                State.Realm = realmVal
                local low = string.lower(realmVal)
                for name, idx in pairs(REALM_TO_IDX) do
                    if string.find(low, name, 1, true) then
                        State.RealmIndex = idx
                        break
                    end
                end
            elseif type(realmVal) == "number" then
                State.RealmIndex = clamp(math.floor(realmVal), 1, 9)
                State.Realm = RealmList[State.RealmIndex] and RealmList[State.RealmIndex].Name or ("Realm " .. State.RealmIndex)
            end
        end
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
    {
        Name       = "Stone of First Breath",
        Path       = {"Map","Village","FirstBreathStone","SignAnchor"},
        Center     = Vector3.new(-1.8, 6.3, 304.0),
        Multiplier = 1.5,
        RealmIndex = 1,   -- Body Tempering
    },
    {
        Name       = "Outer Court Bagua Circle",
        Path       = {"Map","Formations","plaza","SignAnchor"},
        Center     = Vector3.new(0.0, 67.2, 30.0),
        Multiplier = 3,
        RealmIndex = 2,   -- Qi Gathering
    },
    {
        Name       = "Contemplation Cliff",
        Path       = {"Map","Formations","cliff","SignAnchor"},
        Center     = Vector3.new(-196.0, 66.0, -24.0),
        Multiplier = 5,
        RealmIndex = 2,   -- Qi Gathering (Layer 3+)
    },
    {
        Name       = "Jade Formation",
        Path       = {"Map","Islands","JadePeak","SignAnchor"},
        Center     = Vector3.new(482.0, 145.0, -120.4),
        Multiplier = 10,
        RealmIndex = 3,   -- Foundation Establishment
    },
    {
        Name       = "Golden Formation",
        Path       = {"Map","Islands","GoldTerrace","SignAnchor"},
        Center     = Vector3.new(697.6, 310.0, -448.8),
        Multiplier = 22,
        RealmIndex = 4,   -- Golden Core
    },
    {
        Name       = "Cloud Formation",
        Path       = {"Map","HeavenCity","Plaza","SignAnchor"},
        Center     = Vector3.new(520.0, 520.0, -780.0),
        Multiplier = 50,
        RealmIndex = 6,   -- Heavenly Being (5=Nascent can also use Golden/Cloud)
    },
    {
        Name       = "Heaven's Threshold",
        Path       = {"Map","HeavenCity","GreatHeavenSummit","SignAnchor"},
        Center     = Vector3.new(449.1, 545.0, -902.9),
        Multiplier = 110,
        RealmIndex = 7,   -- Great Heavenly Being
    },
    {
        Name       = "Lord's Peak",
        Path       = {"Map","HeavenCity","LordPeak","SignAnchor"},
        Center     = Vector3.new(532.1, 605.0, -939.1),
        Multiplier = 250,
        RealmIndex = 8,   -- Heavenly Lord
    },
    {
        Name       = "Penglai, Isle of Immortals",
        Path       = {"Map","ImmortalIsle","PenglaiRock","SignAnchor"},
        Center     = Vector3.new(-215.3, 510.0, -709.7),
        Multiplier = 550,
        RealmIndex = 9,   -- Immortal
    },
}

-- Ambil posisi live dari Workspace jika model masih ada, fallback ke hardcoded
local function getLivePosForSpot(spot)
    local ok, pos = pcall(function()
        local cur = workspace
        for _, p in ipairs(spot.Path) do
            if cur then
                cur = cur:FindFirstChild(p)
            end
        end

        -- 1. Jika path langsung menemukan BasePart (SignAnchor)
        if cur and cur:IsA("BasePart") then
            return cur.Position
        end

        -- 2. Jika path berhenti di Model / Folder, cari SignAnchor
        local targetObj = cur
        if not targetObj then
            local parent = workspace
            for i = 1, #spot.Path - 1 do
                parent = parent:FindFirstChild(spot.Path[i])
                if not parent then break end
            end
            targetObj = parent
        end

        if targetObj then
            -- Cari anchor Billboard / Plate formasi
            local anchor = targetObj:FindFirstChild("SignAnchor", true)
                or targetObj:FindFirstChild("PenglaiSignAnchor", true)
                or targetObj:FindFirstChild("Plate", true)
                or targetObj:FindFirstChild("Sign", true)
                or targetObj:FindFirstChild("Circle", true)
                or targetObj:FindFirstChild("Pad", true)
            if anchor and anchor:IsA("BasePart") then
                return anchor.Position
            end

            -- Cari BasePart dengan posisi Y tertinggi di pulau (permukaan atas lantai/formation)
            local highestPart = nil
            local highestY = -math.huge
            for _, desc in ipairs(targetObj:GetDescendants()) do
                if desc:IsA("BasePart") and desc.Transparency < 1 and desc.Size.Magnitude > 1.5 then
                    if desc.Position.Y > highestY then
                        highestY = desc.Position.Y
                        highestPart = desc
                    end
                end
            end
            if highestPart then
                return highestPart.Position
            end

            if targetObj:IsA("Model") then
                return targetObj:GetPivot().Position
            end
        end

        return nil
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
        -- Berdiri presisi di atas spot (2.0 studs di atas SignAnchor agar pas di formation circle)
        local standPos = rawPos + Vector3.new(0, 2.0, 0)
        table.insert(BaguaSpots, {
            Name       = name,
            CenterPos  = rawPos,
            Position   = standPos,
            Multiplier = mult or 1,
            RealmReq   = reqRealm or 1,
            Locked     = locked or false,
        })
    end

    -- 1. HARDCODED DATA REAL dari scan in-game (koordinat dan realm 100% akurat)
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

    -- 2. Spot dari Shared.World / Shared.Lotus (jika berhasil ter-require)
    for _, ws in ipairs(WorldSpots) do
        local low = string.lower(ws.Name)
        if string.find(low, "bagua", 1, true) or string.find(low, "formation", 1, true)
            or string.find(low, "court", 1, true) or string.find(low, "penglai", 1, true) then
            addCircle(ws.Name, ws.Position, ws.Multiplier, ws.RealmReq, false)
        end
    end

    -- Urutkan: Multiplier terbesar dulu
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

local REALM_INDEX_TO_SPOT_NAME = {
    [1] = "Stone of First Breath",
    [2] = "Outer Court Bagua Circle",
    [3] = "Jade Formation",
    [4] = "Golden Formation",
    [5] = "Golden Formation",
    [6] = "Cloud Formation",
    [7] = "Heaven's Threshold",
    [8] = "Lord's Peak",
    [9] = "Penglai, Isle of Immortals",
}

local function getBestCultivationSpot()
    scanBaguaCircles()
    local realmIdx = getRealmIndex()
    local targetName = REALM_INDEX_TO_SPOT_NAME[realmIdx] or "Outer Court Bagua Circle"

    -- 1. Cari spot yang tepat sesuai ranah pemain
    for _, spot in ipairs(BaguaSpots) do
        if spot.Name == targetName or string.find(string.lower(spot.Name), string.lower(targetName), 1, true) then
            return spot.Position, spot.Name .. " (×" .. tostring(spot.Multiplier) .. " Qi)"
        end
    end

    -- 2. Fallback: Cari spot dengan RealmReq == realmIdx
    for _, spot in ipairs(BaguaSpots) do
        if (spot.RealmReq or 1) == realmIdx then
            return spot.Position, spot.Name .. " (×" .. tostring(spot.Multiplier) .. " Qi)"
        end
    end

    -- 3. Fallback: Spot dengan RealmReq <= realmIdx
    for _, spot in ipairs(BaguaSpots) do
        if (spot.RealmReq or 1) <= realmIdx then
            return spot.Position, spot.Name .. " (×" .. tostring(spot.Multiplier) .. " Qi)"
        end
    end

    -- 4. Default aman: Outer Court Bagua Circle
    local defaultSpot = CULTIVATION_SPOTS_HARDCODED[2]
    return defaultSpot.Center, defaultSpot.Name
end

-- ═══════════════════════════════════════════
--  SAFE HEARTBEAT SWORD FLIGHT (ANTI-STUCK!)
-- ═══════════════════════════════════════════
local Travel = {
    Active    = false,
    Cancelled = false,
}

-- Raycast mendeteksi lantai atas formasi / pulau agar selalu mendarat di atas permukaan pad
local function safeGroundY(pos)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local excl = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then table.insert(excl, p.Character) end
    end
    params.FilterDescendantsInstances = excl
    params.RespectCanCollide = true -- WAJIB: Hanya tabrak tanah/lantai fisik yang bisa diinjak!

    -- Raycast dari 35 studs di atas pos, turun ke bawah sejauh 70 studs
    -- Menjamin selalu menangkap lantai atas pulau, bukan rongga bawah/dalam mesh
    local result = workspace:Raycast(pos + Vector3.new(0, 35, 0), Vector3.new(0, -70, 0), params)
    if result then
        return result.Position.Y
    end
    return pos.Y
end

local function clearLeftoverMovers()
    local char = getCharacter()
    if char then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and (p.Name == "HumanoidRootPart" or string.find(p.Name, "Torso") or string.find(p.Name, "Leg")) then
                pcall(function() p.CanCollide = true end)
            end
        end
    end
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

    -- Pastikan sword mode game dinonaktifkan agar script game tidak mengunci physics / posisi karakter
    pcall(setGameSwordMode, false)
    pcall(clearLeftoverMovers)
    task.wait(0.05)

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

    local speed = clamp(State.FlySpeed or 160, 60, 450)
    -- Cruise altitude minimal 35 studs di atas titik tertinggi (start atau target)
    local cruiseY = math.max(startPos.Y, finalPos.Y) + math.max(State.NaturalHeight or 30, 35)
    local waypoints = {
        Vector3.new(startPos.X, cruiseY, startPos.Z),
        Vector3.new(finalPos.X, cruiseY, finalPos.Z),
        finalPos,
    }
    -- Hanya bypass waypoint jika jarak sangat dekat DAN ketinggian hampir sama
    if totalDist < 18 and math.abs(startPos.Y - finalPos.Y) < 6 then
        waypoints = { finalPos }
    end

    -- Noclip aktif selama fase terbang agar bebas menembus rintangan
    local noclipConn
    pcall(function()
        noclipConn = RunService.Stepped:Connect(function()
            local ch = getCharacter()
            if ch then
                for _, p in ipairs(ch:GetDescendants()) do
                    if p:IsA("BasePart") and p.CanCollide then
                        p.CanCollide = false
                    end
                end
            end
        end)
    end)

    local okMove, errMove = pcall(function()
        if hum and hum.Sit then hum.Sit = false end
        for _, wp in ipairs(waypoints) do
            if Travel.Cancelled then break end
            local segStart = os.clock()
            while not Travel.Cancelled do
                local dt = RunService.Heartbeat:Wait()
                root = getRootPart()
                local ch = getCharacter()
                if not root or not ch then break end

                local pos = root.Position
                local delta = wp - pos
                local dist = delta.Magnitude
                if dist <= 3.5 then
                    local targetCf = CFrame.new(wp) * (root.CFrame - root.CFrame.Position)
                    ch:PivotTo(targetCf)
                    root.CFrame = targetCf
                    break
                end
                if os.clock() - segStart > math.max(6, (dist / speed) * 3 + 3) then
                    break
                end

                local step = math.min(dist, speed * clamp(dt, 0.005, 0.06))
                local nextPos = pos + (delta / dist) * step
                local flatDir = flat(delta)
                local newCf
                if flatDir.Magnitude > 0.2 then
                    newCf = CFrame.lookAt(nextPos, nextPos + flatDir)
                else
                    newCf = CFrame.new(nextPos) * (root.CFrame - root.CFrame.Position)
                end
                ch:PivotTo(newCf)
                root.CFrame = newCf
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end)

    if noclipConn then
        pcall(function() noclipConn:Disconnect() end)
    end

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

    -- Jaminan 100%: Berdiri & lepas kuncian posisi sebelum bergerak
    if isCurrentlyMeditating() then
        stopMeditating()
        task.wait(0.25)
    end

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
    -- Jika sedang aktif bergerak/terbang, pasti tidak sedang meditasi
    if Travel.Active then return false end

    -- 1. Cek Action.Stand di CultivationHud (indikator live paling akurat dari game!)
    -- Tombol "起" (Stand) hanya muncul saat karakter sedang duduk/meditasi
    local pg = getPlayerGui()
    local hud = pg and pg:FindFirstChild("CultivationHud")
    local action = hud and hud:FindFirstChild("Action")
    if action then
        local standBtn = action:FindFirstChild("Stand")
        if standBtn and isActuallyVisible(standBtn) then
            for _, d in ipairs(standBtn:GetDescendants()) do
                if d:IsA("TextLabel") and d.Text ~= "" then
                    local t = string.lower(d.Text)
                    if string.find(t, "stand", 1, true) or string.find(d.Text, "起", 1, true) then
                        return true
                    end
                end
            end
        end
    end

    -- 2. Cek animasi Humanoid (cross-legged / meditation animation)
    local hum = getHumanoid()
    if hum then
        if hum.Sit then return true end
        local animator = hum:FindFirstChildOfClass("Animator")
        if animator then
            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                local aName = string.lower(track.Animation and track.Animation.Name or "")
                if string.find(aName, "meditat", 1, true) or string.find(aName, "cultivat", 1, true) then
                    return true
                end
            end
        end
    end

    local attr = attrOf({ "Meditating", "IsMeditating", "InMeditation" })
    if attr == true then return true end

    local stVal = readStateModuleField({ "Meditating", "IsMeditating", "InMeditation" })
    if stVal == true then return true end

    local stopBtns = findVisibleButtons({ "stop medit", "meditating", "berhenti" })
    if #stopBtns > 0 then return true end

    return false
end

local function startMeditatingAt(spotPos)
    if isCurrentlyMeditating() then return true end

    local pg = getPlayerGui()
    local hud = pg and pg:FindFirstChild("CultivationHud")
    local action = hud and hud:FindFirstChild("Action")

    -- 1. Klik Action.Stand jika saat ini bertuliskan "Sit" / "Meditate" / "坐"
    if action then
        local standBtn = action:FindFirstChild("Stand")
        if standBtn and isActuallyVisible(standBtn) then
            local isStandState = false
            for _, d in ipairs(standBtn:GetDescendants()) do
                if d:IsA("TextLabel") and d.Text ~= "" then
                    local t = string.lower(d.Text)
                    if string.find(t, "stand", 1, true) or string.find(d.Text, "起", 1, true) then
                        isStandState = true
                        break
                    end
                end
            end
            -- Jika bukan bertuliskan "Stand", berarti tombolnya adalah "Sit", klik untuk duduk!
            if not isStandState then
                local hitStand = standBtn:FindFirstChild("Hit")
                if hitStand and isActuallyVisible(hitStand) then
                    triggerButton(hitStand)
                    task.wait(0.3)
                    if isCurrentlyMeditating() then return true end
                end
            end
        end

        -- 2. Klik Action.Disk (tombol "氣" besar / Click for qi)
        local disk = action:FindFirstChild("Disk")
        local hitDisk = disk and disk:FindFirstChild("Hit")
        if hitDisk and isActuallyVisible(hitDisk) then
            triggerButton(hitDisk)
            task.wait(0.2)
            if isCurrentlyMeditating() then return true end
        end
    end

    -- 3. Coba panggil method dari Client.Meditation bila ada
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

    -- 4. Trigger ProximityPrompt di Bagua Circle jika ada
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

    -- 5. Coba remote MeditateEvent & Action yang ditemukan/bawaan
    if Remotes.Meditate then
        fireRaw(Remotes.Meditate, true)
        task.wait(0.25)
    end

    if not isCurrentlyMeditating() then
        for actName, _ in pairs(Discovered.Learned.Meditate) do
            fireAction(actName, true)
        end
        fireAction("Meditate", true)
    end

    return isCurrentlyMeditating()
end

local function stopMeditating()
    local pg = getPlayerGui()
    local hud = pg and pg:FindFirstChild("CultivationHud")
    local action = hud and hud:FindFirstChild("Action")
    if action then
        local standBtn = action:FindFirstChild("Stand")
        local hitStand = standBtn and standBtn:FindFirstChild("Hit")
        if hitStand and isActuallyVisible(hitStand) then
            local isStand = false
            for _, d in ipairs(standBtn:GetDescendants()) do
                if d:IsA("TextLabel") and (string.find(string.lower(d.Text), "stand", 1, true) or string.find(d.Text, "起", 1, true)) then
                    isStand = true
                    break
                end
            end
            if isStand then
                triggerButton(hitStand)
                task.wait(0.2)
            end
        end
    end

    local hum = getHumanoid()
    if hum and hum.Sit then
        hum.Sit = false
    end

    local clicked = clickVisibleGui({ "stand", "berdiri", "stop medit" })
    if not clicked then
        if Remotes.Meditate then fireRaw(Remotes.Meditate, false) end
        fireAction("StopMeditate")
        fireAction("Meditate", false)
    end
    pressKey(Enum.KeyCode.Space)
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

    local pg = getPlayerGui()
    local hud = pg and pg:FindFirstChild("CultivationHud")
    local action = hud and hud:FindFirstChild("Action")

    -- STEP 1: Klik tombol Rebirth & Breakthrough di Action HUD
    -- Disk = Tombol lingkaran besar emas dengan karakter "破" (Breakthrough)
    -- Rebirth = Tombol Rebirth di Action bar
    if action then
        local disk = action:FindFirstChild("Disk")
        local hitDisk = disk and disk:FindFirstChild("Hit")
        if hitDisk and isActuallyVisible(hitDisk) then
            triggerButton(hitDisk)
            log("Memicu tombol Breakthrough (Disk/破)...")
        end

        local rebirth = action:FindFirstChild("Rebirth")
        local hitRebirth = rebirth and rebirth:FindFirstChild("Hit")
        if hitRebirth and isActuallyVisible(hitRebirth) then
            triggerButton(hitRebirth)
            log("Memicu tombol Rebirth di HUD...")
        end
    end

    -- Shortcut tombol keyboard B
    pressKey(Enum.KeyCode.B)

    -- Cek juga tombol shortcut di AdminPanel jika panel admin aktif di HUD
    if hud and hud:FindFirstChild("AdminPanel") then
        local grid = hud.AdminPanel:FindFirstChild("Grid", true)
        if grid then
            local bBt = grid:FindFirstChild("B_Breakthrough")
            local hitBt = bBt and bBt:FindFirstChild("Hit")
            if hitBt and isActuallyVisible(hitBt) then triggerButton(hitBt) end

            local bRb = grid:FindFirstChild("B_Rebirth now")
            local hitRb = bRb and bRb:FindFirstChild("Hit")
            if hitRb and isActuallyVisible(hitRb) then triggerButton(hitRb) end
        end
    end

    task.wait(0.5)

    -- STEP 2: Cek apakah ada popup Modal atau Toast yang menampilkan syarat (Herbal/Ramuan/Pil)
    local modals = pg and pg:FindFirstChild("CultivationModals")
    local modalPanel = modals and modals:FindFirstChild("Modal") and modals.Modal:FindFirstChild("Panel")
    local hasRequirements = false
    local reqDetails = {}

    if modalPanel and modalPanel.Visible then
        for _, lbl in ipairs(modalPanel:GetDescendants()) do
            if lbl:IsA("TextLabel") and lbl.Visible and lbl.Text ~= "" then
                local low = string.lower(lbl.Text)
                if string.find(low, "need", 1, true)
                    or string.find(low, "require", 1, true)
                    or string.find(low, "missing", 1, true)
                    or string.find(low, "kurang", 1, true)
                    or string.find(low, "butuh", 1, true) then
                    hasRequirements = true
                    table.insert(reqDetails, lbl.Text)
                end
            end
        end
    end

    -- Scan seluruh layar untuk pesan syarat jika modal tidak tertangkap
    if not hasRequirements and pg then
        for _, lbl in ipairs(pg:GetDescendants()) do
            if lbl:IsA("TextLabel") and isActuallyVisible(lbl) and not (OurGui and lbl:IsDescendantOf(OurGui)) then
                local low = string.lower(lbl.Text or "")
                if string.find(low, "need herb", 1, true)
                    or string.find(low, "require", 1, true)
                    or string.find(low, "not enough", 1, true)
                    or string.find(low, "butuh bahan", 1, true) then
                    hasRequirements = true
                    table.insert(reqDetails, lbl.Text)
                    break
                end
            end
        end
    end

    -- STEP 3: Jika butuh herbal/ramuan, otomatis kumpulkan & racik lalu coba lagi
    if hasRequirements then
        log("Breakthrough butuh bahan: " .. (#reqDetails > 0 and table.concat(reqDetails, " | ") or "Herbal/Pil"))
        -- Tutup popup jika ada tombol Close
        if modalPanel then
            local closeBtn = modalPanel:FindFirstChild("Close") and modalPanel.Close:FindFirstChild("Hit")
            if closeBtn then triggerButton(closeBtn) end
        end
        task.wait(0.3)

        State.Step = "Cari Herbal & Racik Pil"
        gatherAndBrewForRebirth()
        task.wait(0.6)

        -- Coba tekan tombol Breakthrough kembali setelah bahan diracik
        if action then
            local disk = action:FindFirstChild("Disk")
            local hitDisk = disk and disk:FindFirstChild("Hit")
            if hitDisk and isActuallyVisible(hitDisk) then triggerButton(hitDisk) end
        end
        pressKey(Enum.KeyCode.B)
        task.wait(0.5)
    end

    -- STEP 4: Konfirmasi jika ada tombol konfirmasi (Yes / Confirm / Ok / 破 / Be Reborn)
    local rebornClicked = clickBeRebornButton and clickBeRebornButton()
    if rebornClicked then
        log("Memicu konfirmasi 'Be Reborn' di modal...")
        task.wait(0.5)
    end

    if modalPanel and modalPanel.Visible then
        for _, obj in ipairs(modalPanel:GetDescendants()) do
            if (obj:IsA("TextButton") or obj:IsA("ImageButton")) and isActuallyVisible(obj) then
                local pName = obj.Parent and string.lower(obj.Parent.Name) or ""
                local bText = string.lower(obj:IsA("TextButton") and obj.Text or "")
                if string.find(pName, "confirm", 1, true) or string.find(pName, "yes", 1, true) or string.find(pName, "ok", 1, true)
                    or string.find(pName, "break", 1, true) or string.find(pName, "claim", 1, true) or string.find(pName, "reborn", 1, true)
                    or string.find(bText, "reborn", 1, true) or string.find(bText, "confirm", 1, true) then
                    triggerButton(obj)
                end
            end
        end
    end

    -- STEP 5: Tembak action remote sebagai cadangan
    for actName, _ in pairs(Discovered.Learned.Breakthrough) do
        fireAction(actName)
    end
    fireAction("Breakthrough")
    fireAction("Rebirth")
    task.wait(0.6)

    -- STEP 6: Pantau apakah realm atau layer berhasil naik (maks 8 detik)
    local t0 = os.clock()
    while os.clock() - t0 < 8 do
        if not State.AutoRebirth then break end
        if isTribulating() then
            log("Heavenly Tribulation! Bertahan...")
            fireAction("Defend")
            task.wait(0.4)
        end
        refreshPlayerState()
        if State.RealmIndex > beforeIdx or State.Realm ~= beforeName or (State.Qi and State.Qi < 30) then
            log("✅ BREAKTHROUGH BERHASIL! Ranah: " .. tostring(State.Realm) .. " (Tier " .. State.RealmIndex .. ")")
            return true
        end
        task.wait(0.5)
    end

    -- TIDAK PERNAH PERGI KE ELDER YUN (sesuai instruksi user)
    return false
end

-- ═══════════════════════════════════════════
--  MAIN AUTO REBIRTH & MEDITATION LOOP
-- ═══════════════════════════════════════════

-- Cek apakah modal konfirmasi Rebirth ("Be Reborn") sedang terbuka di layar
local function isRebornModalOpen()
    local pg = getPlayerGui()
    if not pg then return false end
    for _, d in ipairs(pg:GetDescendants()) do
        if not (OurGui and d:IsDescendantOf(OurGui)) then
            if (d:IsA("TextLabel") or d:IsA("TextButton")) and isActuallyVisible(d) and d.Text ~= "" then
                local low = string.lower(d.Text)
                if string.find(low, "be reborn", 1, true) or (low == "reborn" and not string.find(low, "later", 1, true)) then
                    return true
                end
            end
        end
    end
    return false
end

-- Mencari dan mengklik tombol "Be Reborn" pada modal pop-up secara presisi
local function clickBeRebornButton()
    local pg = getPlayerGui()
    if not pg then return false end

    local candidates = {}
    -- 1. Scan semua TextLabel / TextButton di PlayerGui untuk teks "Be Reborn" (tanpa filter isActuallyVisible agar tidak terhalang container)
    for _, obj in ipairs(pg:GetDescendants()) do
        if not (OurGui and obj:IsDescendantOf(OurGui)) then
            if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj.Text ~= "" then
                local low = string.lower(obj.Text)
                if string.find(low, "be reborn", 1, true) or (low == "reborn" and not string.find(low, "later", 1, true)) then
                    table.insert(candidates, obj)
                end
            end
        end
    end

    -- 2. Scan khusus di CultivationModals
    local modals = pg:FindFirstChild("CultivationModals")
    if modals then
        for _, obj in ipairs(modals:GetDescendants()) do
            if not (OurGui and obj:IsDescendantOf(OurGui)) then
                local oName = string.lower(obj.Name)
                local pName = obj.Parent and string.lower(obj.Parent.Name) or ""
                if (string.find(oName, "reborn", 1, true) or string.find(pName, "reborn", 1, true)
                    or string.find(oName, "confirm", 1, true) or string.find(pName, "confirm", 1, true))
                    and not string.find(oName, "later", 1, true) and not string.find(pName, "later", 1, true) then
                    table.insert(candidates, obj)
                end
            end
        end
    end

    if #candidates == 0 then return false end

    local clicked = false
    for _, obj in ipairs(candidates) do
        print("[CultivationLegends] Tombol Reborn terdeteksi:", obj:GetFullName(), "Class:", obj.ClassName)
        log("Memicu konfirmasi 'Be Reborn': " .. obj.Name)

        -- 1. Trigger langsung jika tombol
        if obj:IsA("TextButton") or obj:IsA("ImageButton") then
            if triggerButton(obj) then clicked = true end
        end

        -- 2. Cek child Hit
        local hitChild = obj:FindFirstChild("Hit")
        if hitChild and (hitChild:IsA("TextButton") or hitChild:IsA("ImageButton")) then
            if triggerButton(hitChild) then clicked = true end
        end

        -- 3. Cek parent dan sibling
        local parent = obj.Parent
        if parent then
            local hitSibling = parent:FindFirstChild("Hit")
            if hitSibling and (hitSibling:IsA("TextButton") or hitSibling:IsA("ImageButton")) then
                if triggerButton(hitSibling) then clicked = true end
            end

            if parent:IsA("TextButton") or parent:IsA("ImageButton") then
                if triggerButton(parent) then clicked = true end
            end

            for _, ch in ipairs(parent:GetChildren()) do
                if (ch:IsA("TextButton") or ch:IsA("ImageButton")) and not string.find(string.lower(ch.Name), "later", 1, true) then
                    if triggerButton(ch) then clicked = true end
                end
            end
        end

        -- 4. VirtualInputManager click hardware pada koordinat tengah visual
        pcall(function()
            local vim = game:GetService("VirtualInputManager")
            local targetObj = (obj:IsA("GuiObject") and obj) or (parent and parent:IsA("GuiObject") and parent)
            if vim and targetObj and targetObj.AbsoluteSize.X > 0 and targetObj.AbsoluteSize.Y > 0 then
                local cx = math.floor(targetObj.AbsolutePosition.X + targetObj.AbsoluteSize.X * 0.5)
                local cy = math.floor(targetObj.AbsolutePosition.Y + targetObj.AbsoluteSize.Y * 0.5)

                vim:SendMouseButtonEvent(cx, cy, 0, true, game, 1)
                task.wait(0.04)
                vim:SendMouseButtonEvent(cx, cy, 0, false, game, 1)

                local inset = Vector2.zero
                pcall(function() inset = GuiService:GetGuiInset() end)
                if inset.Y > 0 then
                    vim:SendMouseButtonEvent(cx, cy + inset.Y, 0, true, game, 1)
                    task.wait(0.04)
                    vim:SendMouseButtonEvent(cx, cy + inset.Y, 0, false, game, 1)
                end
                clicked = true
            end
        end)
    end

    return clicked
end

-- Cek apakah tombol Rebirth ("轉") sudah aktif di Action HUD
local function getRebirthHudButton()
    local pg = getPlayerGui()
    if not pg then return nil end

    local hud = pg:FindFirstChild("CultivationHud")
    local action = hud and hud:FindFirstChild("Action")
    if action then
        -- 1. Cek langsung tombol bernama Rebirth di Action
        for _, ch in ipairs(action:GetChildren()) do
            local low = string.lower(ch.Name)
            if string.find(low, "rebirth", 1, true) or string.find(low, "reborn", 1, true) then
                local hit = ch:FindFirstChild("Hit")
                if hit and isActuallyVisible(hit) then return hit end
                if isActuallyVisible(ch) and (ch:IsA("TextButton") or ch:IsA("ImageButton")) then return ch end
            end
        end

        -- 2. Cek semua TextLabel di Action untuk karakter "轉" atau teks "Rebirth"
        for _, d in ipairs(action:GetDescendants()) do
            if d:IsA("TextLabel") and isActuallyVisible(d) and d.Text ~= "" then
                local low = string.lower(d.Text)
                if string.find(low, "rebirth", 1, true) or string.find(d.Text, "轉", 1, true) or string.find(low, "reborn", 1, true) then
                    local p = d.Parent
                    local hit = p and p:FindFirstChild("Hit")
                    if hit and isActuallyVisible(hit) then return hit end
                    if p and (p:IsA("TextButton") or p:IsA("ImageButton")) and isActuallyVisible(p) then return p end
                    if d:IsA("TextButton") or d:IsA("ImageButton") then return d end
                end
            end
        end
    end

    -- 3. Cek di seluruh PlayerGui untuk tombol Rebirth luar
    for _, btn in ipairs(pg:GetDescendants()) do
        if not (OurGui and btn:IsDescendantOf(OurGui)) then
            if btn:IsA("TextButton") or btn:IsA("ImageButton") then
                local bName = string.lower(btn.Name)
                local pName = btn.Parent and string.lower(btn.Parent.Name) or ""
                if (string.find(bName, "rebirth", 1, true) or string.find(pName, "rebirth", 1, true))
                    and not string.find(bName, "later", 1, true) and isActuallyVisible(btn) then
                    return btn
                end
            end
        end
    end

    return nil
end

-- Eksekusi Rebirth lengkap: Buka modal dari HUD jika belum terbuka, lalu klik "Be Reborn"
local function executeRebirthFlow()
    local beforeIdx = State.RealmIndex
    log("🔄 Memulai proses Rebirth...")
    print("[CultivationLegends] executeRebirthFlow dipanggil, Realm saat ini:", State.Realm, "(Tier " .. tostring(beforeIdx) .. ")")

    -- 1. Buka modal jika belum terbuka
    if not isRebornModalOpen() then
        local hudBtn = getRebirthHudButton()
        if hudBtn then
            log("Membuka modal Rebirth dari HUD (tombol '轉')...")
            print("[CultivationLegends] Mengklik tombol Rebirth di HUD:", hudBtn:GetFullName())
            triggerButton(hudBtn)
            task.wait(0.5)
        end

        -- Cadangan shortcut tombol keyboard B untuk membuka Rebirth
        pressKey(Enum.KeyCode.B)
        task.wait(0.4)

        -- Cadangan AdminPanel
        local pg = getPlayerGui()
        local hud = pg and pg:FindFirstChild("CultivationHud")
        if hud and hud:FindFirstChild("AdminPanel") then
            local bRb = hud.AdminPanel:FindFirstChild("B_Rebirth now", true)
            local hitRb = bRb and bRb:FindFirstChild("Hit")
            if hitRb then triggerButton(hitRb) end
        end
    end

    -- 2. Klik tombol "Be Reborn" di modal pop-up
    local clickedReborn = clickBeRebornButton()
    if clickedReborn then
        log("Tombol 'Be Reborn' berhasil diklik! Menunggu konfirmasi server...")
        print("[CultivationLegends] Tombol 'Be Reborn' berhasil diklik.")
    else
        log("Mencari tombol konfirmasi Rebirth...")
    end

    -- 3. Cadangan: Remote / Action Rebirth
    fireAction("Rebirth")
    fireAction("BeReborn")
    fireAction("ConfirmRebirth")
    if Remotes.Rebirth then fireRaw(Remotes.Rebirth) end

    task.wait(1.2)
    refreshPlayerState()

    local success = (State.RealmIndex < beforeIdx or State.RealmIndex == 1)
    if success then
        log("🎉 REBIRTH BERHASIL! Ranah baru: " .. tostring(State.Realm) .. " (Tier " .. tostring(State.RealmIndex) .. ")")
        print("[CultivationLegends] Rebirth sukses! State.RealmIndex =", State.RealmIndex)
    else
        print("[CultivationLegends] Rebirth sedang diproses atau menunggu konfirmasi...")
    end

    return success
end

-- Cek apakah tombol Breakthrough (Disk dengan 破) sudah aktif di HUD
local function isBreakthroughReady()
    local pg = getPlayerGui()
    local hud = pg and pg:FindFirstChild("CultivationHud")
    local action = hud and hud:FindFirstChild("Action")
    if action then
        local disk = action:FindFirstChild("Disk")
        if disk and isActuallyVisible(disk) then
            for _, d in ipairs(disk:GetDescendants()) do
                if d:IsA("TextLabel") and d.Text ~= "" then
                    if string.find(d.Text, "破", 1, true) or string.find(string.lower(d.Text), "break", 1, true) then
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- Fast Auto-Clicker untuk Qi (klik tombol "氣" Disk secara kontinu saat meditasi agar Qi terus mengalir deras!)
task.spawn(function()
    while true do
        if (State.AutoMeditate or State.AutoRebirth) and isCurrentlyMeditating() and not State.Locked then
            pcall(function()
                local pg = getPlayerGui()
                local hud = pg and pg:FindFirstChild("CultivationHud")
                local action = hud and hud:FindFirstChild("Action")
                if action then
                    local disk = action:FindFirstChild("Disk")
                    local hitDisk = disk and disk:FindFirstChild("Hit")
                    if hitDisk and isActuallyVisible(hitDisk) then
                        triggerButton(hitDisk)
                    end

                    local autoBtn = action:FindFirstChild("AutoClick")
                    local hitAuto = autoBtn and autoBtn:FindFirstChild("Hit")
                    if hitAuto and isActuallyVisible(hitAuto) and not State.InGameAutoClickChecked then
                        triggerButton(hitAuto)
                        State.InGameAutoClickChecked = true
                    end
                end
            end)
            task.wait(0.12)
        else
            State.InGameAutoClickChecked = false
            task.wait(0.4)
        end
    end
end)

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

            -- PRIORITAS 1: Cek apakah Rebirth sudah siap
            -- Syarat Rebirth game: Nascent Soul Layer 1 (RealmIndex >= 5) ATAU tombol "轉" aktif ATAU modal terbuka!
            local isRebirthEligible = (State.RealmIndex and State.RealmIndex >= 5)
            local rebornModalOpen = isRebornModalOpen()
            local hudRebirthBtn = getRebirthHudButton()

            if isRebirthEligible or rebornModalOpen or hudRebirthBtn then
                log("🌟 REBIRTH TERSEDIA (Ranah: " .. tostring(State.Realm) .. ")! Memulai proses Reinkarnasi...")
                State.Step = "Rebirth (Reinkarnasi)"
                stopMeditating()
                pcall(setGameSwordMode, false)
                pcall(clearLeftoverMovers)
                task.wait(0.3)

                local okRb = executeRebirthFlow()
                if okRb then
                    log("🎉 REBIRTH SUKSES! Ranah ter-reset dengan multiplier permanen baru!")
                    notify("Rebirth Sukses", "Karakter berhasil di-Reborn! Memulai kultivasi dari ranah awal...")
                    task.wait(1.5)
                    refreshPlayerState()
                    local spotPos, spotName = getBestCultivationSpot()
                    if spotPos then
                        travelTo(spotPos, spotName or "Stone of First Breath", 5)
                    end
                else
                    log("Sedang memproses Rebirth... Menunggu konfirmasi server.")
                end
                task.wait(1.5)
                return -- KUNCI UTAMA: Langsung return dari tick ini agar TIDAK PERNAH jatuh ke terbang/kultivasi di ranah lama!
            end

            -- PRIORITAS 2: Cek Breakthrough (Qi penuh atau tombol 破 siap)
            local qi = State.Qi or 0
            local isReady = (qi >= State.QiThreshold) or isBreakthroughReady()
            if isReady then
                State.Step = "Terobosan / Breakthrough"
                stopMeditating()

                local success = attemptBreakthrough()
                if not success then
                    log("Breakthrough butuh persiapan — cek bahan & Cauldron...")
                    State.Step = "Cari Herbal & Racik Pil"
                    gatherAndBrewForRebirth()
                    State.Step = "Ulangi Breakthrough"
                    attemptBreakthrough()
                else
                    log("Breakthrough sukses! Memeriksa spot ranah baru...")
                    refreshPlayerState()
                    local spotPos, spotName = getBestCultivationSpot()
                    if spotPos then
                        local root = getRootPart()
                        if root and (root.Position - spotPos).Magnitude > 14 then
                            log("Perpindahan otomatis ke spot ranah baru: " .. tostring(spotName))
                            State.Step = "Pindah ke " .. tostring(spotName)
                            stopMeditating()
                            pcall(setGameSwordMode, false)
                            pcall(clearLeftoverMovers)
                            task.wait(0.35)
                            travelTo(spotPos, spotName or "Bagua Circle", 5)
                            task.wait(0.2)
                        end
                    end
                end
                task.wait(1.0)
            else
                State.Step = string.format("Kultivasi (Qi %.1f%%)", qi)
                local spotPos, spotName = getBestCultivationSpot()
                if spotPos then
                    local root = getRootPart()
                    if root and (root.Position - spotPos).Magnitude > 14 then
                        log("Perpindahan ke spot ranah baru: " .. tostring(spotName) .. " — Berdiri dan bersiap terbang...")
                        State.Step = "Pindah ke " .. tostring(spotName)
                        stopMeditating()
                        pcall(setGameSwordMode, false)
                        pcall(clearLeftoverMovers)
                        task.wait(0.35)

                        travelTo(spotPos, spotName or "Bagua Circle", 5)
                        task.wait(0.2)
                    end
                end

                if not isCurrentlyMeditating() then
                    startMeditatingAt(spotPos)
                end
                task.wait(1.0)
            end
        end)

        if not ok then
            log("AutoRebirth Error: " .. tostring(err))
            task.wait(2)
        end
        task.wait(0.3)
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
--  Berdasarkan scan live Game:
--  - Buka window: CultivationHud.Side.Talent.Hit
--  - Tombol Roll: CultivationModals.Modal.Panel.Body.Bar.Roll.Hit
--  - Tombol Fast: CultivationModals.Modal.Panel.Body.Bar.Fast.Hit
--  - Tombol Auto: CultivationModals.Modal.Panel.Body.Bar.Auto.Hit
-- ═══════════════════════════════════════════
local TALENT_TIER_LABELS = { "凡", "良", "秀", "奇", "天", "雷", "混", "星",
    "Common", "Good", "Fine", "Rare", "Heavenly", "Thunder", "Chaos", "Star", "Mythic" }

-- Buka jendela Talent dari navbar Side.Talent.Hit
local function openTalentWindow()
    local pg = getPlayerGui()
    if not pg then return false end
    local hud = pg:FindFirstChild("CultivationHud")
    local side = hud and hud:FindFirstChild("Side")
    local talentNav = side and side:FindFirstChild("Talent")
    local hit = talentNav and talentNav:FindFirstChild("Hit")
    if hit and (hit:IsA("TextButton") or hit:IsA("ImageButton")) then
        triggerButton(hit)
        task.wait(0.35)
        return true
    end
    return clickHitButton({"Talent"}, {"admin","autoclick"})
end

-- Dapatkan tombol Roll langsung dari path bar modal game
local function getTalentRollButton()
    local pg = getPlayerGui()
    if not pg then return nil end
    local modals = pg:FindFirstChild("CultivationModals")
    if modals then
        local panel = modals:FindFirstChild("Panel", true)
        if panel then
            local bar = panel:FindFirstChild("Bar", true)
            local roll = bar and bar:FindFirstChild("Roll")
            local hit = roll and roll:FindFirstChild("Hit")
            if hit and (hit:IsA("TextButton") or hit:IsA("ImageButton")) then
                return hit
            end
        end
    end
    -- Fallback scan di seluruh PlayerGui untuk Parent=Roll & Grandparent=Bar
    for _, obj in ipairs(pg:GetDescendants()) do
        if (obj:IsA("TextButton") or obj:IsA("ImageButton")) and obj.Name == "Hit" then
            if obj.Parent and obj.Parent.Name == "Roll" and obj.Parent.Parent and obj.Parent.Parent.Name == "Bar" then
                return obj
            end
        end
    end
    return nil
end

local function isTalentWindowOpen()
    local btn = getTalentRollButton()
    if btn and isActuallyVisible(btn) then
        return true, btn.Parent and btn.Parent.Parent
    end
    local pg = getPlayerGui()
    local modals = pg and pg:FindFirstChild("CultivationModals")
    local modal = modals and modals:FindFirstChild("Modal")
    if modal and modal.Visible then
        return true, modal
    end
    return false, nil
end

-- Baca Talent yang sedang aktif dari Card / Drum / Right rows di Panel.Body
local function readCurrentTalentFromWindow()
    local pg = getPlayerGui()
    if not pg then return nil, false end
    local modals = pg:FindFirstChild("CultivationModals")
    local panel = modals and modals:FindFirstChild("Panel", true)
    if not panel then return nil, false end

    for _, lbl in ipairs(panel:GetDescendants()) do
        if lbl:IsA("TextLabel") and lbl.Visible and lbl.Text ~= "" then
            local txt = lbl.Text
            local low = string.lower(txt)
            -- Filter teks tombol statis
            if not string.find(low, "roll", 1, true)
                and not string.find(low, "buy", 1, true)
                and not string.find(low, "pity", 1, true)
                and not string.find(low, "cost", 1, true)
                and not string.find(low, "auto", 1, true)
                and not string.find(low, "fast", 1, true)
                and #txt >= 2 then

                if State.TargetTalent ~= "" and string.find(low, string.lower(State.TargetTalent), 1, true) then
                    return txt, true
                end
                if State.TalentTier ~= "" and string.find(low, string.lower(State.TalentTier), 1, true) then
                    return txt, true
                end
                for _, tier in ipairs(TALENT_TIER_LABELS) do
                    if string.find(txt, tier, 1, true) then
                        local matched = (State.TalentTier == "" or string.find(txt, State.TalentTier, 1, true) ~= nil)
                        return txt, matched
                    end
                end
            end
        end
    end
    return nil, false
end

local function rollTalentOnce()
    -- STEP 1: Pastikan window Talent terbuka
    local isOpen = isTalentWindowOpen()
    if not isOpen then
        openTalentWindow()
        task.wait(0.4)
    end

    -- STEP 2: Dapatkan tombol Roll (CultivationModals.Modal.Panel.Body.Bar.Roll.Hit)
    local rollBtn = getTalentRollButton()
    local rolledUi = false

    if rollBtn then
        -- Cek juga tombol Fast mode di bar yang sama agar roll lebih cepat
        local bar = rollBtn.Parent and rollBtn.Parent.Parent
        local fast = bar and bar:FindFirstChild("Fast")
        local fastHit = fast and fast:FindFirstChild("Hit")
        if fastHit and isActuallyVisible(fastHit) then
            pcall(function() triggerButton(fastHit) end)
        end

        triggerButton(rollBtn)
        rolledUi = true
    else
        -- Fallback: Tombol admin B_+5 rolls jika ada di AdminPanel
        local pg = getPlayerGui()
        local hud = pg and pg:FindFirstChild("CultivationHud")
        local grid = hud and hud:FindFirstChild("Grid", true)
        local bRoll = grid and grid:FindFirstChild("B_+5 rolls")
        local hitRoll = bRoll and bRoll:FindFirstChild("Hit")
        if hitRoll and isActuallyVisible(hitRoll) then
            triggerButton(hitRoll)
            rolledUi = true
        end
    end

    -- STEP 3: Panggil modul TalentWindow jika ada
    local twMod = safeReqClient("UI.TalentWindow")
    if type(twMod) == "table" then
        for _, fnName in ipairs({ "Roll", "Reroll", "Spin", "RequestRoll", "DoRoll" }) do
            if type(twMod[fnName]) == "function" then
                pcall(twMod[fnName])
            end
        end
    end

    -- STEP 4: Learned actions
    for actName, args in pairs(Discovered.Learned.RollTalent) do
        fireAction(unpackFn(args))
    end

    task.wait(0.1)
    local talentTxt, matched = readCurrentTalentFromWindow()
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
                log("🎯 TARGET TALENT DIDAPAT (" .. count .. "x roll): " .. tostring(talentName))
                notify("Talent Gacha", "Target didapat: " .. tostring(talentName))
                State.AutoGacha = false
                shouldStop = true
            end
            if count % 10 == 0 then
                log("Roll ke-" .. count .. " | Talent saat ini: " .. tostring(talentName))
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
pcall(installPassiveSpy)
pcall(function() task.spawn(extractConstantsFromClient) end)

pcall(buildItemCatalog)
pcall(buildRealmList)
pcall(buildRecipes)
pcall(scanSharedLocations)
pcall(scanBaguaCircles)
pcall(scanIslands)

-- Bersihkan instance GUI lama jika ada (mencegah GUI tertumpuk atau sembunyi)
pcall(function()
    local parents = {
        (gethui and gethui()),
        CoreGui,
        (LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui"))
    }
    for _, p in ipairs(parents) do
        if p then
            for _, c in ipairs(p:GetChildren()) do
                if c.Name == "UnionsalWindowGui" or c.Name == "UnionsalKickScreen" then
                    c:Destroy()
                end
            end
        end
    end
end)

print("[Unionsal Hub] Membuka menu Cultivation Legends...")

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

print("[Unionsal Hub] Window berhasil dibuat!")

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
    Name = "Lakukan Rebirth Sekarang ('Be Reborn')",
    Callback = safeRun(function()
        task.spawn(function()
            stopMeditating()
            pcall(setGameSwordMode, false)
            pcall(clearLeftoverMovers)
            task.wait(0.2)
            local ok = executeRebirthFlow()
            if ok then
                notify("Rebirth Sukses", "Karakter berhasil di-Reborn!")
            else
                notify("Rebirth", "Tombol Rebirth / modal 'Be Reborn' diproses.")
            end
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
    Options = { "星 (Cosmic / Star ×8)", "混 (Chaos ×5)", "雷 (Thunder ×3)", "天 (Heavenly ×2.2)", "奇 (Rare ×1.6)", "Mythic", "Legendary" },
    CurrentValue = "星 (Cosmic / Star ×8)",
    Callback = function(v)
        State.TalentTier = string.match(v, "^([^%s%(]+)") or v
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
    Range = { 0.05, 1.0 },
    Increment = 0.05,
    Suffix = " s",
    CurrentValue = 0.25,
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
            notify("Talent", "Fast Roll aktif! Menembak tombol Roll di Talent Window.")
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
            notify("Talent Roll", matched and ("Target didapat: " .. tostring(name)) or ("Roll dikirim: " .. tostring(name or "sukses")))
        end)
    end),
})

TalentTab:CreateButton({
    Name = "Buka / Tutup Window Talent Game",
    Callback = safeRun(function()
        openTalentWindow()
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
