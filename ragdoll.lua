-- ╔══════════════════════════════════════════════════════════════╗
-- ║      UNIONSAL SCRIPT HUB — Hyper-Realistic Ragdoll           ║
-- ║        Game  : Hyper-Realistic Ragdoll (PlaceId: 101277003916102) ║
-- ║        Module: Dummy Killer, KO Farm, Big Fan, God Physics   ║
-- ║        Design: Glass Bento dark purple (Unionsal Engine)     ║
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

local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local UserInputService= game:GetService("UserInputService")
local TweenService    = game:GetService("TweenService")
local HttpService     = game:GetService("HttpService")
local Lighting        = game:GetService("Lighting")
local LocalPlayer     = Players.LocalPlayer

-- Helper Karakter
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
--  WINDOW UTAMA (UNIONSAL GLASS BENTO)
-- ═══════════════════════════════════════════
local Window = Unionsal:CreateWindow({
    Name       = "unionsal",
    Subtitle   = ".gg/unionsal",
    GameName   = "Hyper-Realistic Ragdoll",
    ScriptName = "ragdoll.lua",
    Version    = "v1.3",
})

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
    -- Fallback titik tinggi tengah map
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

-- Otomatis gunakan / ayunkan senjata
local function swingOrShootTool()
    local char = getCharacter()
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then
        -- Ambil dari Backpack jika belum di-equip
        local bpTool = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
        if bpTool and getHumanoid() then
            getHumanoid():EquipTool(bpTool)
            task.wait(0.05)
            tool = bpTool
        end
    end
    if tool then
        pcall(function()
            tool:Activate()
        end)
    end
end

-- Eksekusi pembunuhan instan pada dummy (Lethal Decapitation & Severing)
local function killDummyInstantly(dummy)
    if not dummy or not dummy.Parent then return end

    local dHum = dummy:FindFirstChildOfClass("Humanoid")
    local dRoot = dummy:FindFirstChild("HumanoidRootPart") or dummy:FindFirstChild("Torso") or dummy:FindFirstChild("UpperTorso")

    -- 1. Matikan Humanoid seketika
    if dHum then
        pcall(function()
            dHum.Health = 0
            dHum:ChangeState(Enum.HumanoidStateType.Dead)
        end)
    end

    -- 2. Hancurkan sendi leher, kepala & torso (Decapitation / Instant Lethal)
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

    -- 3. Ayunkan senjata dengan TouchInterest langsung ke kepala & torso dummy
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

    -- 4. Berikan benturan fisika mematikan ke bawah tanah / void
    for _, part in ipairs(dummy:GetChildren()) do
        if part:IsA("BasePart") and not part.Anchored then
            pcall(function()
                part.AssemblyLinearVelocity = Vector3.new(0, -500, 0)
            end)
        end
    end

    -- 5. Panggil modul internal game jika tersedia (Client.Dummies.DummyBody / PlayerHurt)
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
            -- Hancurkan SEMUA Motor6D, Weld, Glue, BallSocketConstraint agar tubuh tercerai-berai
            for _, desc in ipairs(dummy:GetDescendants()) do
                if desc:IsA("JointInstance") or desc:IsA("Constraint") then
                    desc:Destroy()
                end
            end
            -- Beri gaya dorong eksplosif ke setiap potongan tubuh
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
        end)
    end
    return count
end

-- Memicu sistem Revive bawaan game
local function triggerGameRevive()
    local done = false
    -- 1. Scan semua tombol di PlayerGui
    pcall(function()
        for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
            if gui:IsA("TextButton") or gui:IsA("ImageButton") then
                local txt = (gui:IsA("TextButton") and string.lower(gui.Text)) or ""
                local nm = string.lower(gui.Name)
                if string.find(txt, "revive") or string.find(nm, "revive") or string.find(txt, "respawn") or string.find(nm, "respawn") then
                    if firesignal then
                        firesignal(gui.MouseButton1Click)
                        firesignal(gui.Activated)
                    end
                    done = true
                end
            end
        end
    end)
    -- 2. Scan RemoteEvent / RemoteFunction di ReplicatedStorage & game
    pcall(function()
        for _, obj in ipairs(game:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                local n = string.lower(obj.Name)
                if string.find(n, "revive") or string.find(n, "respawn") or string.find(n, "resetdummies") or string.find(n, "cleargraves") then
                    if obj:IsA("RemoteEvent") then
                        obj:FireServer()
                        done = true
                    elseif obj:IsA("RemoteFunction") then
                        obj:InvokeServer()
                        done = true
                    end
                end
            end
        end
    end)
    -- 3. Coba panggil Client Modules (Dummies.DummyManager / MapClient / EventRunner)
    pcall(function()
        local client = LocalPlayer.PlayerScripts:FindFirstChild("Client")
        if client then
            local dummiesFolder = client:FindFirstChild("Dummies")
            if dummiesFolder then
                local dm = dummiesFolder:FindFirstChild("DummyManager")
                if dm then
                    local req = require(dm)
                    if req then
                        if req.revive then req.revive(); done = true end
                        if req.respawn then req.respawn(); done = true end
                        if req.reset then req.reset(); done = true end
                        if req.spawnAll then req.spawnAll(); done = true end
                        if req.respawnAll then req.respawnAll(); done = true end
                    end
                end
            end
        end
    end)
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
--  SISTEM BENCANA & GAME EVENTS (ALL 9 EVENTS)
-- ═══════════════════════════════════════════
local GameEvents = {
    WeightlessActive    = false,
    DeepFreezeActive    = false,
    FallingDummiesLoop  = false,
    WildfireActive      = false,
    MeteorRainLoop      = false,
    TornadoActive       = false,
    BlackHoleActive     = false,
    OriginalGravity     = workspace.Gravity,
}

-- Memicu Event Game secara Native (Bypass UI & EventRunner)
local function triggerNativeGameEvent(eventName)
    local triggered = false
    local norm = string.lower(string.gsub(eventName, "%s+", ""))

    -- 1. Scan PlayerGui untuk tombol event yang sesuai gambar
    pcall(function()
        for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
            if gui:IsA("TextButton") or gui:IsA("ImageButton") then
                local txt = (gui:IsA("TextButton") and string.lower(gui.Text)) or ""
                local nm = string.lower(gui.Name)
                local pnm = (gui.Parent and string.lower(gui.Parent.Name)) or ""
                if string.find(txt, norm) or string.find(nm, norm) or string.find(pnm, norm) then
                    if firesignal then
                        firesignal(gui.MouseButton1Click)
                        firesignal(gui.Activated)
                    end
                    triggered = true
                end
            end
        end
    end)

    -- 2. Panggil Client.Events.EventRunner jika tersedia
    pcall(function()
        local client = LocalPlayer.PlayerScripts:FindFirstChild("Client")
        if client then
            local eventsFolder = client:FindFirstChild("Events")
            if eventsFolder then
                local er = eventsFolder:FindFirstChild("EventRunner")
                if er then
                    local req = require(er)
                    if req then
                        if req.start and typeof(req.start) == "function" then req.start(eventName); triggered = true end
                        if req.trigger and typeof(req.trigger) == "function" then req.trigger(eventName); triggered = true end
                        if req.run and typeof(req.run) == "function" then req.run(eventName); triggered = true end
                        if req[eventName] and typeof(req[eventName]) == "function" then req[eventName](); triggered = true end
                        if req[norm] and typeof(req[norm]) == "function" then req[norm](); triggered = true end
                    end
                end
                -- Coba modul spesifik event di dalam folder Events
                for _, mod in ipairs(eventsFolder:GetChildren()) do
                    if string.find(string.lower(mod.Name), norm) and mod:IsA("ModuleScript") then
                        local mReq = require(mod)
                        if mReq then
                            if mReq.start then mReq.start(); triggered = true end
                            if mReq.run then mReq.run(); triggered = true end
                            if mReq.trigger then mReq.trigger(); triggered = true end
                        end
                    end
                end
            end
        end
    end)

    -- 3. Scan ReplicatedStorage untuk Remote Event
    pcall(function()
        for _, obj in ipairs(game:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                local n = string.lower(obj.Name)
                if string.find(n, "event") or string.find(n, norm) then
                    if obj:IsA("RemoteEvent") then
                        obj:FireServer(eventName)
                        obj:FireServer(norm)
                        triggered = true
                    elseif obj:IsA("RemoteFunction") then
                        obj:InvokeServer(eventName)
                        triggered = true
                    end
                end
            end
        end
    end)

    return triggered
end

-- Unlock Semua Event Token / Badge secara lokal di UI
local function unlockAllEventTokens()
    local count = 0
    pcall(function()
        -- Cari atribut token pada LocalPlayer
        for attrName, _ in pairs(LocalPlayer:GetAttributes()) do
            if string.find(string.lower(attrName), "event") or string.find(string.lower(attrName), "token") then
                LocalPlayer:SetAttribute(attrName, 999)
                count = count + 1
            end
        end
        -- Cari badge/counter text di PlayerGui
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

-- EVENT 1: Weightless (Zero-G)
local function toggleWeightless(enable)
    GameEvents.WeightlessActive = enable
    if enable then
        workspace.Gravity = 10
        for _, dummy in ipairs(getAllDummies()) do
            local root = dummy:FindFirstChild("HumanoidRootPart") or dummy:FindFirstChild("Torso")
            if root and not root:FindFirstChild("AntiGravForce") then
                local bf = Instance.new("BodyForce")
                bf.Name = "AntiGravForce"
                bf.Force = Vector3.new(0, 196.2 * root:GetMass() * 0.95, 0)
                bf.Parent = root
            end
        end
    else
        workspace.Gravity = GameEvents.OriginalGravity
        for _, dummy in ipairs(getAllDummies()) do
            for _, f in ipairs(dummy:GetDescendants()) do
                if f.Name == "AntiGravForce" then f:Destroy() end
            end
        end
    end
end

-- EVENT 2: Deep Freeze
local function triggerDeepFreeze()
    triggerNativeGameEvent("Deep Freeze")
    local count = 0
    for _, dummy in ipairs(getAllDummies()) do
        pcall(function()
            for _, p in ipairs(dummy:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.Anchored = true
                    p.Material = Enum.Material.Ice
                    p.Color = Color3.fromRGB(160, 230, 255)
                    if not p:FindFirstChild("FreezeSparkle") then
                        local sp = Instance.new("Sparkles")
                        sp.Name = "FreezeSparkle"
                        sp.SparkleColor = Color3.fromRGB(200, 255, 255)
                        sp.Parent = p
                    end
                end
            end
            count = count + 1
        end)
    end
    return count
end

-- EVENT 3: Falling Dummies
local function spawnFallingDummy()
    local dummies = getAllDummies()
    if #dummies == 0 then return end
    local myRoot = getRootPart()
    local center = myRoot and myRoot.Position or Vector3.new(0, 10, 0)
    local target = dummies[math.random(1, #dummies)]
    local dRoot = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Torso")
    if dRoot and not dRoot.Anchored then
        local dropPos = center + Vector3.new(math.random(-60, 60), 220, math.random(-60, 60))
        dRoot.CFrame = CFrame.new(dropPos)
        dRoot.AssemblyLinearVelocity = Vector3.new(math.random(-20, 20), -80, math.random(-20, 20))
        dRoot.AssemblyAngularVelocity = Vector3.new(math.random(-15, 15), math.random(-15, 15), math.random(-15, 15))
    end
end

-- EVENT 4: Wildfire
local function triggerWildfire()
    triggerNativeGameEvent("Wildfire")
    local count = 0
    for _, dummy in ipairs(getAllDummies()) do
        pcall(function()
            local torso = dummy:FindFirstChild("Torso") or dummy:FindFirstChild("UpperTorso") or dummy:FindFirstChild("HumanoidRootPart")
            if torso and not torso:FindFirstChild("WildfireFx") then
                local fire = Instance.new("Fire")
                fire.Name = "WildfireFx"
                fire.Size = 8
                fire.Heat = 15
                fire.Parent = torso

                local smoke = Instance.new("Smoke")
                smoke.Name = "WildfireSmoke"
                smoke.Size = 4
                smoke.RiseVelocity = 8
                smoke.Parent = torso
                count = count + 1
            end
            local hum = dummy:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:TakeDamage(25)
            end
        end)
    end
    return count
end

-- EVENT 5: Mini Dummies
local function triggerMiniDummies()
    triggerNativeGameEvent("Mini Dummies")
    local count = 0
    for _, dummy in ipairs(getAllDummies()) do
        pcall(function()
            local hum = dummy:FindFirstChildOfClass("Humanoid")
            if hum then
                for _, s in ipairs({"BodyDepthScale", "BodyHeightScale", "BodyWidthScale", "HeadScale"}) do
                    local sc = hum:FindFirstChild(s)
                    if sc and sc:IsA("NumberValue") then
                        sc.Value = 0.35
                    end
                end
            end
            for _, p in ipairs(dummy:GetChildren()) do
                if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                    p.Size = p.Size * 0.45
                end
            end
            count = count + 1
        end)
    end
    return count
end

-- EVENT 6: Giant Dummy
local function triggerGiantDummy()
    triggerNativeGameEvent("Giant Dummy")
    local dummies = getAllDummies()
    if #dummies == 0 then return false end
    local target = dummies[math.random(1, #dummies)]
    pcall(function()
        local hum = target:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.MaxHealth = 50000
            hum.Health = 50000
            for _, s in ipairs({"BodyDepthScale", "BodyHeightScale", "BodyWidthScale", "HeadScale"}) do
                local sc = hum:FindFirstChild(s)
                if sc and sc:IsA("NumberValue") then
                    sc.Value = 6.0
                end
            end
        end
        for _, p in ipairs(target:GetChildren()) do
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                p.Size = p.Size * 4.5
            end
        end
        if not target:FindFirstChild("GiantAura") then
            local hl = Instance.new("Highlight")
            hl.Name = "GiantAura"
            hl.FillColor = Color3.fromRGB(255, 60, 60)
            hl.OutlineColor = Color3.fromRGB(255, 255, 100)
            hl.Parent = target
        end
    end)
    return true
end

-- EVENT 7: Meteor Rain
local function spawnMeteor()
    local myRoot = getRootPart()
    local center = myRoot and myRoot.Position or Vector3.new(0, 10, 0)
    local startPos = center + Vector3.new(math.random(-120, 120), 280, math.random(-120, 120))
    local targetPos = center + Vector3.new(math.random(-100, 100), 0, math.random(-100, 100))

    local meteor = Instance.new("Part")
    meteor.Name = "MeteorPart"
    meteor.Shape = Enum.PartType.Ball
    meteor.Size = Vector3.new(8, 8, 8)
    meteor.Material = Enum.Material.Basalt
    meteor.Color = Color3.fromRGB(45, 35, 30)
    meteor.CFrame = CFrame.new(startPos)
    meteor.CanCollide = false
    meteor.Parent = workspace

    local fire = Instance.new("Fire")
    fire.Size = 20
    fire.Heat = 25
    fire.Parent = meteor

    local smoke = Instance.new("Smoke")
    smoke.Size = 10
    smoke.Color = Color3.fromRGB(80, 50, 40)
    smoke.Parent = meteor

    local dir = (targetPos - startPos).Unit
    meteor.AssemblyLinearVelocity = dir * 180

    meteor.Touched:Connect(function(hit)
        if hit and not hit:IsDescendantOf(LocalPlayer.Character) and hit ~= meteor then
            local exp = Instance.new("Explosion")
            exp.Position = meteor.Position
            exp.BlastRadius = 25
            exp.BlastPressure = 350000
            exp.Parent = workspace
            meteor:Destroy()
        end
    end)

    task.delay(4, function()
        if meteor and meteor.Parent then meteor:Destroy() end
    end)
end

-- EVENT 8: Tornado
local tornadoCenter = nil
local tornadoConn = nil
local function toggleTornado(enable)
    GameEvents.TornadoActive = enable
    if enable then
        triggerNativeGameEvent("Tornado")
        local myRoot = getRootPart()
        local centerPos = (myRoot and (myRoot.Position + myRoot.CFrame.LookVector * 25)) or Vector3.new(0, 15, 0)

        tornadoCenter = Instance.new("Part")
        tornadoCenter.Name = "TornadoVortex"
        tornadoCenter.Anchored = true
        tornadoCenter.CanCollide = false
        tornadoCenter.Transparency = 0.8
        tornadoCenter.Size = Vector3.new(12, 60, 12)
        tornadoCenter.Position = centerPos
        tornadoCenter.Color = Color3.fromRGB(180, 180, 200)
        tornadoCenter.Parent = workspace

        local smoke = Instance.new("Smoke")
        smoke.Size = 25
        smoke.RiseVelocity = 35
        smoke.Opacity = 0.7
        smoke.Color = Color3.fromRGB(150, 150, 160)
        smoke.Parent = tornadoCenter

        tornadoConn = RunService.Heartbeat:Connect(function()
            if not GameEvents.TornadoActive or not tornadoCenter then return end
            for _, dummy in ipairs(getAllDummies()) do
                local dRoot = dummy:FindFirstChild("HumanoidRootPart") or dummy:FindFirstChild("Torso")
                if dRoot and not dRoot.Anchored then
                    local offset = dRoot.Position - tornadoCenter.Position
                    local dist = offset.Magnitude
                    if dist < 90 then
                        local tangent = Vector3.new(-offset.Z, 0, offset.X).Unit
                        local inward = -offset.Unit
                        local upward = Vector3.new(0, 1, 0)
                        dRoot.AssemblyLinearVelocity = (tangent * 80) + (inward * 40) + (upward * 65)
                    end
                end
            end
        end)
    else
        if tornadoConn then tornadoConn:Disconnect(); tornadoConn = nil end
        if tornadoCenter then tornadoCenter:Destroy(); tornadoCenter = nil end
    end
end

-- EVENT 9: Black Hole
local blackHoleCenter = nil
local blackHoleConn = nil
local function toggleBlackHole(enable)
    GameEvents.BlackHoleActive = enable
    if enable then
        triggerNativeGameEvent("Black Hole")
        local myRoot = getRootPart()
        local pos = (myRoot and (myRoot.Position + Vector3.new(0, 30, 0))) or Vector3.new(0, 40, 0)

        blackHoleCenter = Instance.new("Part")
        blackHoleCenter.Name = "BlackHoleSingularity"
        blackHoleCenter.Shape = Enum.PartType.Ball
        blackHoleCenter.Size = Vector3.new(16, 16, 16)
        blackHoleCenter.Material = Enum.Material.Neon
        blackHoleCenter.Color = Color3.fromRGB(0, 0, 0)
        blackHoleCenter.Anchored = true
        blackHoleCenter.CanCollide = false
        blackHoleCenter.Position = pos
        blackHoleCenter.Parent = workspace

        local ring = Instance.new("SelectionBox")
        ring.Adornee = blackHoleCenter
        ring.Color3 = Color3.fromRGB(255, 160, 40)
        ring.SurfaceTransparency = 0.3
        ring.Parent = blackHoleCenter

        blackHoleConn = RunService.Heartbeat:Connect(function()
            if not GameEvents.BlackHoleActive or not blackHoleCenter then return end
            for _, dummy in ipairs(getAllDummies()) do
                local dRoot = dummy:FindFirstChild("HumanoidRootPart") or dummy:FindFirstChild("Torso")
                if dRoot and not dRoot.Anchored then
                    local diff = blackHoleCenter.Position - dRoot.Position
                    local dist = diff.Magnitude
                    if dist < 180 then
                        local pull = diff.Unit * math.clamp(2800 / (dist + 5), 50, 350)
                        dRoot.AssemblyLinearVelocity = pull
                        if dist < 12 then
                            dummy:BreakJoints()
                        end
                    end
                end
            end
        end)
    else
        if blackHoleConn then blackHoleConn:Disconnect(); blackHoleConn = nil end
        if blackHoleCenter then blackHoleCenter:Destroy(); blackHoleCenter = nil end
    end
end

-- Hentikan Semua Bencana Aktif & Pulihkan Map
local function stopAllActiveEvents()
    toggleWeightless(false)
    toggleTornado(false)
    toggleBlackHole(false)
    GameEvents.FallingDummiesLoop = false
    GameEvents.MeteorRainLoop = false

    for _, dummy in ipairs(getAllDummies()) do
        pcall(function()
            for _, obj in ipairs(dummy:GetDescendants()) do
                if obj.Name == "WildfireFx" or obj.Name == "WildfireSmoke" or obj.Name == "FreezeSparkle" or obj.Name == "AntiGravForce" then
                    obj:Destroy()
                end
                if obj:IsA("BasePart") and obj.Material == Enum.Material.Ice then
                    obj.Material = Enum.Material.SmoothPlastic
                    obj.Anchored = false
                end
            end
        end)
    end
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
local CONFIG_FILE = "unionsal_ragdoll_device_config.json"

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
    AutoSave = true,
    WebhookUrl = "",
    SendOnExec = true,
    SendOnKo = true,
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
    local ok = pcall(function()
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

    if parsed.DeviceId == currentDeviceId then
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
            Lighting.GlobalShadows = false
        end)
    else
        pcall(function()
            settings().Rendering.QualityLevel = 0
            Lighting.GlobalShadows = true
        end)
    end
end

-- Forward-declare sendDiscordWebhook (defined fully in Configs tab below)
local sendDiscordWebhook
local webhookUrl = ""
local sendOnExec = true
local sendOnKo = true

-- ╔═══════════════════════════════════════════╗
-- ║  TAB 1: DUMMIES & KO (AUTO FARM)          ║
-- ╚═══════════════════════════════════════════╝
local FarmTab = Window:CreateTab("Auto Farm", "sprout", "Main")
FarmTab:CreateSection("Auto Kill (Teleport & Instant Kill)")

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
                                -- 1. Teleport langsung ke posisi ragdoll
                                root.CFrame = dRoot.CFrame * CFrame.new(0, 1, 2)
                                task.wait(0.03)

                                -- 2. Eksekusi INSTANT KILL langsung seketika!
                                killDummyInstantly(dummy)

                                -- 3. Notifikasi Webhook jika aktif
                                if ConfigRegistry.SendOnKo and ConfigRegistry.WebhookUrl ~= "" then
                                    sendDiscordWebhook({
                                        title = "💀 Ragdoll Eliminated",
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
    Name = "Revive All Ragdoll (Bangkitkan Seluruh Ragdoll - Fitur Game)",
    Callback = function()
        local ok = triggerGameRevive()
        Window:Notify({ Title = "Revive All", Content = ok and "Sinyal Revive game berhasil dikirim! Seluruh ragdoll dibangkitkan utuh." or "Memicu revive modul...", Duration = 3 })
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
    Name = "Respawn Karakter (Instan)",
    Callback = function()
        local hum = getHumanoid()
        if hum then
            hum.Health = 0
            Window:Notify({ Title = "Respawn", Content = "Karakter di-respawn!", Duration = 1.5 })
        end
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
-- ║  TAB 2: EVENTS & BENCANA MAP              ║
-- ╚═══════════════════════════════════════════╝
local EventsTab = Window:CreateTab("Events", "zap", "Main")
EventsTab:CreateSection("Bypass & Kontrol Seluruh Event")

EventsTab:CreateButton({
    Name = "Unlock All In-Game Event Tokens (999x Penggunaan)",
    Callback = function()
        local c = unlockAllEventTokens()
        Window:Notify({ Title = "Events Unlocked", Content = "Berhasil meng-unlock token event di UI/Client! (" .. c .. " items)", Duration = 3 })
    end
})

EventsTab:CreateButton({
    Name = "Hentikan Semua Bencana Aktif (Reset Map Damai)",
    Callback = function()
        stopAllActiveEvents()
        Window:Notify({ Title = "Events Reset", Content = "Seluruh bencana dihentikan. Map dikembalikan ke normal.", Duration = 2.5 })
    end
})

EventsTab:CreateSection("1. Gravitasi & Cuaca Ekstrem")

EventsTab:CreateToggle({
    Name = "Weightless (Gravitasi Nol / Melayang Bebas)",
    CurrentValue = false,
    Callback = function(v)
        triggerNativeGameEvent("Weightless")
        toggleWeightless(v)
        Window:Notify({ Title = "Weightless", Content = v and "Zero-G AKTIF! Semua ragdoll melayang bebas di udara." or "Gravitasi normal kembali.", Duration = 2 })
    end
})

EventsTab:CreateButton({
    Name = "Deep Freeze (Bekukan Semua Ragdoll Menjadi Es)",
    Callback = function()
        local count = triggerDeepFreeze()
        Window:Notify({ Title = "Deep Freeze", Content = count .. " ragdoll berhasil dibekukan menjadi patung es!", Duration = 3 })
    end
})

EventsTab:CreateButton({
    Name = "Wildfire (Bakar Seluruh Ragdoll dengan Api Membara)",
    Callback = function()
        local count = triggerWildfire()
        Window:Notify({ Title = "Wildfire", Content = count .. " ragdoll dilalap api kebakaran membara!", Duration = 3 })
    end
})

EventsTab:CreateSection("2. Modifikasi Ukuran & Hujan Ragdoll")

EventsTab:CreateButton({
    Name = "Falling Dummies (Jatuhkan Hujan Dummy Sekali)",
    Callback = function()
        triggerNativeGameEvent("Falling Dummies")
        for i = 1, 5 do
            spawnFallingDummy()
            task.wait(0.05)
        end
        Window:Notify({ Title = "Falling Dummies", Content = "Hujan dummy dijatuhkan dari langit!", Duration = 2 })
    end
})

local fallingDummiesLoop = false
EventsTab:CreateToggle({
    Name = "Loop Falling Dummies (Hujan Dummy Terus Menerus)",
    CurrentValue = false,
    Callback = function(v)
        fallingDummiesLoop = v
        Window:Notify({ Title = "Falling Dummies", Content = v and "Hujan dummy terus menerus AKTIF!" or "Hujan dummy dihentikan.", Duration = 2 })
        if v then
            task.spawn(function()
                while fallingDummiesLoop do
                    spawnFallingDummy()
                    task.wait(0.6)
                end
            end)
        end
    end
})

EventsTab:CreateButton({
    Name = "Mini Dummies (Ubah Semua Ragdoll Menjadi Kerdil)",
    Callback = function()
        local count = triggerMiniDummies()
        Window:Notify({ Title = "Mini Dummies", Content = count .. " ragdoll diubah menjadi ukuran kerdil/chibi!", Duration = 3 })
    end
})

EventsTab:CreateButton({
    Name = "Giant Dummy (Bangkitkan Dummy Raksasa Titan)",
    Callback = function()
        local ok = triggerGiantDummy()
        Window:Notify({ Title = "Giant Dummy", Content = ok and "Dummy Raksasa Titan berhasil dibangkitkan!" or "Tidak ada dummy di map.", Duration = 3 })
    end
})

EventsTab:CreateSection("3. Bencana Kosmik & Kehancuran Massal")

EventsTab:CreateButton({
    Name = "Meteor Rain (Panggil Hujan Meteor Sekali)",
    Callback = function()
        triggerNativeGameEvent("Meteor Rain")
        for i = 1, 4 do
            spawnMeteor()
            task.wait(0.2)
        end
        Window:Notify({ Title = "Meteor Rain", Content = "Hujan meteor berapi menghujani map!", Duration = 3 })
    end
})

local meteorRainLoop = false
EventsTab:CreateToggle({
    Name = "Loop Meteor Rain (Hujan Meteor Beruntun)",
    CurrentValue = false,
    Callback = function(v)
        meteorRainLoop = v
        Window:Notify({ Title = "Meteor Rain", Content = v and "Hujan meteor beruntun AKTIF!" or "Hujan meteor dihentikan.", Duration = 2 })
        if v then
            task.spawn(function()
                while meteorRainLoop do
                    spawnMeteor()
                    task.wait(1.2)
                end
            end)
        end
    end
})

EventsTab:CreateToggle({
    Name = "Tornado (Puting Beliung Penghisap Seluruh Objek)",
    CurrentValue = false,
    Callback = function(v)
        toggleTornado(v)
        Window:Notify({ Title = "Tornado", Content = v and "Puting Beliung AKTIF! Menghisap seluruh ragdoll & objek ke pusaran angin." or "Tornado dihentikan.", Duration = 2.5 })
    end
})

EventsTab:CreateToggle({
    Name = "Black Hole (Singularitas Kosmik Penelan Map)",
    CurrentValue = false,
    Callback = function(v)
        toggleBlackHole(v)
        Window:Notify({ Title = "Black Hole", Content = v and "BLACK HOLE AKTIF! Seluruh map & ragdoll tersedot ke singularitas gravitasi." or "Black hole dinonaktifkan.", Duration = 2.5 })
    end
})


-- ╔═══════════════════════════════════════════╗
-- ║  TAB 2: COMBAT & TOOLS                    ║
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
                        swingOrShootTool()
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
-- ║  TAB 3: PLAYER & DEFENSE                  ║
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

-- Fly Mode
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
    Name = "Salin Koordinat Posisi Saat Ini",
    Callback = function()
        local r = getRootPart()
        if r then
            local posStr = string.format("%.1f, %.1f, %.1f", r.Position.X, r.Position.Y, r.Position.Z)
            if setclipboard then setclipboard(posStr) end
            Window:Notify({ Title = "Posisi", Content = "Koordinat disalin: " .. posStr, Duration = 3 })
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
-- ║  TAB 4: TELEPORT                          ║
-- ╚═══════════════════════════════════════════╝
local TpTab = Window:CreateTab("Teleport", "navigation", "Main")
TpTab:CreateSection("Lokasi Penting Map")

TpTab:CreateButton({
    Name = "Teleport ke Kipas Raksasa (The Big Fan)",
    Callback = function()
        local root = getRootPart()
        local fanCf = findBigFan()
        if root and fanCf then
            root.CFrame = fanCf + Vector3.new(0, 10, 0)
            Window:Notify({ Title = "Teleport", Content = "Tiba di area Kipas Raksasa!", Duration = 2 })
        end
    end
})

TpTab:CreateButton({
    Name = "Teleport ke Kerumunan Dummy Terbanyak",
    Callback = function()
        local dummies = getLivingDummies()
        local root = getRootPart()
        if root and #dummies > 0 then
            local target = dummies[math.random(1, #dummies)]
            local tRoot = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Torso")
            if tRoot then
                root.CFrame = tRoot.CFrame * CFrame.new(0, 0, 4)
                Window:Notify({ Title = "Teleport", Content = "Tiba di dekat dummy!", Duration = 2 })
            end
        end
    end
})

TpTab:CreateButton({
    Name = "Teleport ke Spawn Asli",
    Callback = function()
        local root = getRootPart()
        local sp = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
        if root then
            root.CFrame = (sp and (sp.CFrame + Vector3.new(0, 4, 0))) or CFrame.new(0, 10, 0)
            Window:Notify({ Title = "Teleport", Content = "Kembali ke spawn point.", Duration = 2 })
        end
    end
})

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

-- ╔═══════════════════════════════════════════╗
-- ║  TAB 5: VISUALS & ESP                     ║
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
-- ║  TAB 6: SETTINGS (CONFIG)                 ║
-- ╚═══════════════════════════════════════════╝
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
    Title = "Daftar Shortcut Hyper-Realistic Ragdoll",
    Content = "• Buka/Tutup UI: Tekan tombol yang telah diatur (Default: RightShift).\n" ..
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
        notifyStateChange("FpsBoost", v)
        Window:Notify({ Title = "FPS Boost", Content = v and "FPS Boost diaktifkan!" or "FPS Boost dinonaktifkan.", Duration = 2 })
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

-- ╔═══════════════════════════════════════════╗
-- ║  TAB 7: CONFIGS (CONFIG)                  ║
-- ╚═══════════════════════════════════════════╝
local ConfigsTab = Window:CreateTab("Configs", "folder", "Config")
ConfigsTab:CreateSection("Discord Webhook Integration")

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
    Name = "Kirim Log saat KO Dummy Berhasil",
    CurrentValue = true,
    Callback = function(v)
        sendOnKo = v
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
            title = "⚡ Unionsal Hub v1.3 • Webhook Connected",
            description = "Webhook berhasil terhubung dengan client Roblox!",
            color = 8864235,
            fields = {
                { name = "Player", value = LocalPlayer.Name .. " (@" .. LocalPlayer.DisplayName .. ")", inline = true },
                { name = "Game", value = "Hyper-Realistic Ragdoll", inline = true },
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

-- ═══════════════════════════════════════════
--  NOTIFIKASI SIAP
-- ═══════════════════════════════════════════
task.wait(0.5)
Window:Notify({
    Title   = "unionsal",
    Content = "Hyper-Realistic Ragdoll v1.3 aktif! Kill All Dummies & Big Fan siap digunakan.",
    Duration = 5,
})
