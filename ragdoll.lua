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

-- ═══════════════════════════════════════════
--  SISTEM KILL TRACKING (Server KO Counter)
-- ═══════════════════════════════════════════
local KillCount = 0
local function notifyKillToServer(dummy)
    -- Coba laporkan kill ke server via berbagai RemoteEvent game HRR
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
    -- 6. Laporkan kill ke server supaya masuk KO count game
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

-- Memicu sistem Revive bawaan game (fix: pakai semua jalur HRR)
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
                -- HRR event names yang diketahui
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
        if not dummiesFolder then return end
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
        -- MapClient (World module) - handles wave/revive
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
        -- Simulate R key press (HRR uses R for Revive)
        if firesignal then
            firesignal(uis.InputBegan, {KeyCode = Enum.KeyCode.R, UserInputType = Enum.UserInputType.Keyboard}, false)
            task.wait(0.05)
            firesignal(uis.InputEnded, {KeyCode = Enum.KeyCode.R, UserInputType = Enum.UserInputType.Keyboard}, false)
        end
        LocalPlayer:SetAttribute("HRR_Revive", true)
        task.wait(0.1)
        LocalPlayer:SetAttribute("HRR_Revive", nil)
        LocalPlayer:SetAttribute("HRR_Wave", (LocalPlayer:GetAttribute("HRR_Wave") or 0) + 1)
    end)

    -- 5. Fallback: paksa revive dengan teleport posisi & Health reset manual
    if not done then
        for _, dummy in ipairs(getAllDummies()) do
            pcall(function()
                local dHum = dummy:FindFirstChildOfClass("Humanoid")
                local dRoot = dummy:FindFirstChild("HumanoidRootPart") or dummy:FindFirstChild("Torso")
                if dHum and dRoot then
                    dHum.Health = dHum.MaxHealth > 0 and dHum.MaxHealth or 100
                    dHum:ChangeState(Enum.HumanoidStateType.GettingUp)
                    -- Pasang kembali joints yang rusak
                    for _, j in ipairs(dummy:GetDescendants()) do
                        if j:IsA("Motor6D") and not j.Enabled then
                            j.Enabled = true
                        end
                    end
                end
            end)
        end
        done = true
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
                -- Scale via NumberValue (safe untuk R6 dan R15)
                for _, s in ipairs({"BodyDepthScale", "BodyHeightScale", "BodyWidthScale", "HeadScale"}) do
                    local sc = hum:FindFirstChild(s)
                    if sc and sc:IsA("NumberValue") then
                        sc.Value = 0.3
                    end
                end
                -- Coba HumanoidDescription (R15 modern)
                pcall(function()
                    local desc = hum:GetAppliedDescription()
                    desc.DepthScale = 0.3
                    desc.HeightScale = 0.3
                    desc.WidthScale = 0.3
                    desc.HeadScale = 0.4
                    hum:ApplyDescription(desc)
                end)
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
            -- Skala humanoid via NumberValue BodyScale yang benar
            local scaleNames = {"BodyDepthScale", "BodyHeightScale", "BodyWidthScale", "HeadScale"}
            for _, s in ipairs(scaleNames) do
                local sc = hum:FindFirstChild(s)
                if sc and sc:IsA("NumberValue") then
                    sc.Value = 5.5
                end
            end
            -- Juga coba via HumanoidDescription (Roblox modern)
            pcall(function()
                local desc = hum:GetAppliedDescription()
                desc.DepthScale = 5.5
                desc.HeightScale = 5.5
                desc.WidthScale = 5.5
                desc.HeadScale = 5.0
                hum:ApplyDescription(desc)
            end)
        end
        -- Scale semua BasePart relatif terhadap root
        local root = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Torso")
        if root then
            local origPos = root.CFrame
            for _, p in ipairs(target:GetChildren()) do
                if p:IsA("BasePart") then
                    local relOffset = root.CFrame:ToObjectSpace(p.CFrame)
                    p.Size = p.Size * 5.0
                    p.CFrame = origPos:ToWorldSpace(relOffset * CFrame.new(relOffset.Position * 4.5))
                end
            end
        end
        -- Highlight merah titan
        if target:FindFirstChild("GiantAura") then
            target:FindFirstChild("GiantAura"):Destroy()
        end
        local hl = Instance.new("Highlight")
        hl.Name = "GiantAura"
        hl.FillColor = Color3.fromRGB(220, 30, 30)
        hl.OutlineColor = Color3.fromRGB(255, 220, 50)
        hl.FillTransparency = 0.3
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.Occluded
        hl.Parent = target
        -- BillboardGui "TITAN" di atasnya
        local root2 = target:FindFirstChild("Head") or target:FindFirstChild("HumanoidRootPart")
        if root2 then
            local bb = Instance.new("BillboardGui")
            bb.Name = "GiantLabel"
            bb.AlwaysOnTop = true
            bb.Size = UDim2.new(0, 180, 0, 50)
            bb.StudsOffset = Vector3.new(0, 15, 0)
            bb.Adornee = root2
            bb.Parent = workspace
            local lbl = Instance.new("TextLabel")
            lbl.Text = "[TITAN]"
            lbl.TextScaled = true
            lbl.TextColor3 = Color3.fromRGB(255, 80, 20)
            lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.GothamBold
            lbl.Size = UDim2.fromScale(1, 1)
            lbl.Parent = bb
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

        -- Accretion Disk (Cincin emas menyala - pakai Part cylinder)
        local ring1 = Instance.new("Part")
        ring1.Name = "AccretionDisk"
        ring1.Shape = Enum.PartType.Cylinder
        ring1.Size = Vector3.new(2, 60, 60)
        ring1.Material = Enum.Material.Neon
        ring1.Color = Color3.fromRGB(255, 150, 0)
        ring1.Anchored = true
        ring1.CanCollide = false
        ring1.Transparency = 0.4
        ring1.CFrame = blackHoleCenter.CFrame * CFrame.Angles(0, 0, math.rad(90))
        ring1.Parent = workspace

        local ring2 = Instance.new("Part")
        ring2.Name = "AccretionDisk2"
        ring2.Shape = Enum.PartType.Cylinder
        ring2.Size = Vector3.new(1, 48, 48)
        ring2.Material = Enum.Material.Neon
        ring2.Color = Color3.fromRGB(255, 80, 0)
        ring2.Anchored = true
        ring2.CanCollide = false
        ring2.Transparency = 0.5
        ring2.CFrame = blackHoleCenter.CFrame * CFrame.Angles(math.rad(20), 0, math.rad(90))
        ring2.Parent = workspace

        -- Simpan referensi untuk dihapus saat off
        blackHoleCenter:SetAttribute("Ring1", ring1.Name)
        blackHoleCenter:SetAttribute("Ring2", ring2.Name)
        ring1:SetAttribute("BHRing", true)
        ring2:SetAttribute("BHRing", true)

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
        -- Hapus accretion disk rings
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("BasePart") and obj:GetAttribute("BHRing") then
                obj:Destroy()
            end
        end
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
    -- Hapus efek tambahan (zombie BillboardGui, aura, dll)
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("BasePart") and (obj:GetAttribute("BHRing") or obj.Name == "TornadoVortex"
           or obj.Name == "MeteorPart" or obj.Name == "AccretionDisk" or obj.Name == "AccretionDisk2"
           or obj.Name == "ZombieSpawnFx" or obj.Name == "AirstrikeBomb") then
            pcall(function() obj:Destroy() end)
        end
        if obj:IsA("BillboardGui") and (obj.Name == "GiantLabel" or obj.Name == "ZombieLabel") then
            pcall(function() obj:Destroy() end)
        end
    end
end

-- ═══════════════════════════════════════════
--  EVENT BARU: Warhead, Zombie, Disco, dll
-- ═══════════════════════════════════════════

-- EVENT 10: Warhead (Ledakan Nuklir Masif)
local function triggerWarhead()
    triggerNativeGameEvent("Warhead")
    local myRoot = getRootPart()
    local center = myRoot and myRoot.Position or Vector3.new(0, 0, 0)

    -- Tiga gelombang eksplosif besar
    for i = 1, 3 do
        task.delay(i * 0.4, function()
            local exp = Instance.new("Explosion")
            exp.Position = center + Vector3.new(math.random(-40, 40), 2, math.random(-40, 40))
            exp.BlastRadius = 60
            exp.BlastPressure = 800000
            exp.DestroyJointRadiusPercent = 0.5
            exp.Parent = workspace

            -- Efek asap jamur nuklir
            local smoke = Instance.new("Part")
            smoke.Anchored = true
            smoke.CanCollide = false
            smoke.Transparency = 1
            smoke.Position = center + Vector3.new(0, 2, 0)
            smoke.Parent = workspace
            local sm = Instance.new("Smoke")
            sm.Size = 60
            sm.RiseVelocity = 80
            sm.Color = Color3.fromRGB(80, 80, 80)
            sm.Parent = smoke
            local fire = Instance.new("Fire")
            fire.Size = 50
            fire.Heat = 50
            fire.Color = Color3.fromRGB(255, 100, 0)
            fire.SecondaryColor = Color3.fromRGB(80, 20, 0)
            fire.Parent = smoke
            task.delay(5, function() if smoke and smoke.Parent then smoke:Destroy() end end)
        end)
    end
    -- Kill semua dummy
    task.delay(0.5, function()
        for _, dummy in ipairs(getAllDummies()) do
            pcall(function()
                dummy:BreakJoints()
                local h = dummy:FindFirstChildOfClass("Humanoid")
                if h then h.Health = 0 end
                for _, p in ipairs(dummy:GetChildren()) do
                    if p:IsA("BasePart") and not p.Anchored then
                        p.AssemblyLinearVelocity = Vector3.new(math.random(-120, 120), math.random(80, 200), math.random(-120, 120))
                    end
                end
                notifyKillToServer(dummy)
            end)
        end
    end)
    return true
end

-- EVENT 11: Zombie Outbreak (Semua ragdoll jadi zombie hijau)
local function triggerZombieOutbreak()
    triggerNativeGameEvent("Zombie Outbreak")
    local count = 0
    for _, dummy in ipairs(getAllDummies()) do
        pcall(function()
            -- Ubah warna kulit zombie
            for _, p in ipairs(dummy:GetDescendants()) do
                if p:IsA("BasePart") and (p.Name == "Head" or p.Name == "Torso" or p.Name == "UpperTorso"
                   or p.Name == "LowerTorso" or p.Name == "LeftArm" or p.Name == "RightArm"
                   or p.Name == "LeftLeg" or p.Name == "RightLeg"
                   or string.find(string.lower(p.Name), "arm") or string.find(string.lower(p.Name), "leg")) then
                    p.Color = Color3.fromRGB(80, 160, 70)
                    p.Material = Enum.Material.SmoothPlastic
                end
            end
            -- Tambah efek hp regen zombie
            local hum = dummy:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = 18
                hum.MaxHealth = 300
                hum.Health = 300
            end
            -- BillboardGui zombie
            local head = dummy:FindFirstChild("Head")
            if head and not head:FindFirstChild("ZombieLabel") then
                local bb = Instance.new("BillboardGui")
                bb.Name = "ZombieLabel"
                bb.Size = UDim2.new(0, 80, 0, 25)
                bb.StudsOffset = Vector3.new(0, 3, 0)
                bb.AlwaysOnTop = false
                bb.Adornee = head
                bb.Parent = workspace
                local lbl = Instance.new("TextLabel")
                lbl.Text = "ZOMBIE"
                lbl.TextScaled = true
                lbl.TextColor3 = Color3.fromRGB(80, 220, 60)
                lbl.BackgroundTransparency = 1
                lbl.Font = Enum.Font.GothamBold
                lbl.Size = UDim2.fromScale(1, 1)
                lbl.Parent = bb
            end
            count = count + 1
        end)
    end
    return count
end

-- EVENT 12: Disco Party (Lampu disko, gravity rendah, efek warna)
local function triggerDiscoParty()
    triggerNativeGameEvent("Disco Party")
    -- Gravity ringan
    workspace.Gravity = 30
    -- Ubah warna semua dummy setiap detik
    local discoColors = {
        Color3.fromRGB(255, 0, 100),
        Color3.fromRGB(0, 200, 255),
        Color3.fromRGB(255, 200, 0),
        Color3.fromRGB(0, 255, 100),
        Color3.fromRGB(200, 0, 255),
    }
    -- Flash warna 5 kali
    for i = 1, 5 do
        task.delay(i * 0.5, function()
            local col = discoColors[(i % #discoColors) + 1]
            pcall(function()
                Lighting.Ambient = col
                Lighting.ColorShift_Top = col
            end)
            for _, dummy in ipairs(getAllDummies()) do
                pcall(function()
                    for _, p in ipairs(dummy:GetDescendants()) do
                        if p:IsA("BasePart") then
                            p.Color = discoColors[math.random(1, #discoColors)]
                        end
                    end
                end)
            end
        end)
    end
    -- Reset setelah 5 detik
    task.delay(5, function()
        workspace.Gravity = GameEvents.OriginalGravity
        Lighting.Ambient = Color3.fromRGB(0, 0, 0)
        Lighting.ColorShift_Top = Color3.fromRGB(0, 0, 0)
    end)
    return true
end

-- EVENT 13: Bee Swarm (Semua dummy diserang lebah - fire + damage)
local function triggerBeeSwarm()
    triggerNativeGameEvent("Bee Swarm")
    local count = 0
    for _, dummy in ipairs(getAllDummies()) do
        pcall(function()
            local torso = dummy:FindFirstChild("Torso") or dummy:FindFirstChild("UpperTorso") or dummy:FindFirstChild("HumanoidRootPart")
            if torso and not torso:FindFirstChild("BeeSwarmFx") then
                -- Efek lebah (partikel kuning kecil)
                local sp = Instance.new("Sparkles")
                sp.Name = "BeeSwarmFx"
                sp.SparkleColor = Color3.fromRGB(255, 200, 0)
                sp.Parent = torso
                -- Damage berkelanjutan
                local hum = dummy:FindFirstChildOfClass("Humanoid")
                if hum then
                    task.spawn(function()
                        for _ = 1, 10 do
                            if hum and hum.Health > 0 then
                                hum:TakeDamage(15)
                                task.wait(0.3)
                            end
                        end
                    end)
                end
                count = count + 1
            end
        end)
    end
    return count
end

-- EVENT 14: T-Rex Attack (T-Rex visual proper + no lag)
local function triggerTRexAttack()
    triggerNativeGameEvent("T-Rex Attack")
    local myRoot = getRootPart()
    local startPos = myRoot and (myRoot.Position + myRoot.CFrame.LookVector * 60) or Vector3.new(60, 5, 0)

    -- Buat T-Rex dari Part-Part yang di-weld (lebih nyata)
    local trexModel = Instance.new("Model")
    trexModel.Name = "HRR_TRex"
    trexModel.Parent = workspace

    local function makePart(size, color, cframeOffset, parent)
        local p = Instance.new("Part")
        p.Size = size
        p.Color = color
        p.Material = Enum.Material.SmoothPlastic
        p.Anchored = false
        p.CanCollide = false
        p.Parent = parent or trexModel
        return p
    end

    local GREEN = Color3.fromRGB(55, 110, 50)
    local DARKGREEN = Color3.fromRGB(40, 85, 38)

    -- Tubuh utama
    local body = makePart(Vector3.new(10, 12, 22), GREEN)
    body.Name = "TRexBody"
    body.Anchored = true
    body.CFrame = CFrame.new(startPos + Vector3.new(0, 7, 0))
    trexModel.PrimaryPart = body

    -- Kepala (moncong panjang)
    local head = makePart(Vector3.new(6, 7, 14), GREEN)
    head.Name = "TRexHead"
    head.CFrame = body.CFrame * CFrame.new(0, 4, -16)
    local w1 = Instance.new("WeldConstraint"); w1.Part0=body; w1.Part1=head; w1.Parent=body

    -- Rahang bawah
    local jaw = makePart(Vector3.new(5, 2, 12), DARKGREEN)
    jaw.CFrame = body.CFrame * CFrame.new(0, 0, -17)
    local wj = Instance.new("WeldConstraint"); wj.Part0=body; wj.Part1=jaw; wj.Parent=body

    -- Ekor panjang
    local tail = makePart(Vector3.new(5, 6, 20), GREEN)
    tail.CFrame = body.CFrame * CFrame.new(0, -2, 20)
    local w2 = Instance.new("WeldConstraint"); w2.Part0=body; w2.Part1=tail; w2.Parent=body

    -- Kaki depan (2)
    local legFL = makePart(Vector3.new(3, 8, 3), DARKGREEN)
    legFL.CFrame = body.CFrame * CFrame.new(-5, -8, -6)
    local wfl = Instance.new("WeldConstraint"); wfl.Part0=body; wfl.Part1=legFL; wfl.Parent=body
    local legFR = makePart(Vector3.new(3, 8, 3), DARKGREEN)
    legFR.CFrame = body.CFrame * CFrame.new(5, -8, -6)
    local wfr = Instance.new("WeldConstraint"); wfr.Part0=body; wfr.Part1=legFR; wfr.Parent=body

    -- Kaki belakang (2 - lebih besar)
    local legBL = makePart(Vector3.new(5, 14, 5), DARKGREEN)
    legBL.CFrame = body.CFrame * CFrame.new(-5, -11, 6)
    local wbl = Instance.new("WeldConstraint"); wbl.Part0=body; wbl.Part1=legBL; wbl.Parent=body
    local legBR = makePart(Vector3.new(5, 14, 5), DARKGREEN)
    legBR.CFrame = body.CFrame * CFrame.new(5, -11, 6)
    local wbr = Instance.new("WeldConstraint"); wbr.Part0=body; wbr.Part1=legBR; wbr.Parent=body

    -- Lengan kecil (T-Rex arms)
    local armL = makePart(Vector3.new(2, 5, 2), DARKGREEN)
    armL.CFrame = body.CFrame * CFrame.new(-6, 2, -6)
    local wal = Instance.new("WeldConstraint"); wal.Part0=body; wal.Part1=armL; wal.Parent=body
    local armR = makePart(Vector3.new(2, 5, 2), DARKGREEN)
    armR.CFrame = body.CFrame * CFrame.new(6, 2, -6)
    local war = Instance.new("WeldConstraint"); war.Part0=body; war.Part1=armR; war.Parent=body

    -- Mata (neon merah)
    local eyeL = makePart(Vector3.new(1.5, 1.5, 1.5), Color3.fromRGB(255, 30, 30))
    eyeL.Material = Enum.Material.Neon
    eyeL.CFrame = body.CFrame * CFrame.new(-2.5, 5, -22)
    local wel = Instance.new("WeldConstraint"); wel.Part0=body; wel.Part1=eyeL; wel.Parent=body
    local eyeR = makePart(Vector3.new(1.5, 1.5, 1.5), Color3.fromRGB(255, 30, 30))
    eyeR.Material = Enum.Material.Neon
    eyeR.CFrame = body.CFrame * CFrame.new(2.5, 5, -22)
    local wer = Instance.new("WeldConstraint"); wer.Part0=body; wer.Part1=eyeR; wer.Parent=body

    -- Suara roar
    pcall(function()
        local roar = Instance.new("Sound")
        roar.SoundId = "rbxassetid://1448044284"
        roar.Volume = 5
        roar.Parent = body
        roar:Play()
    end)

    -- Gerak T-Rex ke arah spawn (task.delay bukan loop Heartbeat = no lag)
    local stepCount = 25
    local stepDelay = 0.18
    for i = 1, stepCount do
        task.delay(i * stepDelay, function()
            if not trexModel or not trexModel.Parent or not body or not body.Parent then return end
            pcall(function()
                body.CFrame = body.CFrame * CFrame.new(0, 0, -2.5)
                -- Cek dummy di sekitar
                for _, dummy in ipairs(getAllDummies()) do
                    local dRoot = dummy:FindFirstChild("HumanoidRootPart") or dummy:FindFirstChild("Torso")
                    if dRoot and (dRoot.Position - body.Position).Magnitude < 25 then
                        pcall(function()
                            dRoot.AssemblyLinearVelocity = Vector3.new(math.random(-100,100), 80, math.random(-100,100))
                            dummy:BreakJoints()
                            local h = dummy:FindFirstChildOfClass("Humanoid")
                            if h then h.Health = 0 end
                            notifyKillToServer(dummy)
                        end)
                    end
                end
            end)
        end)
    end

    -- Hancurkan setelah selesai
    task.delay(stepCount * stepDelay + 2, function()
        if trexModel and trexModel.Parent then trexModel:Destroy() end
    end)
    return true
end

-- EVENT 15: Airstrike (Serangan udara - bom dari langit beruntun)
local function triggerAirstrike()
    triggerNativeGameEvent("Airstrike")
    local myRoot = getRootPart()
    local center = myRoot and myRoot.Position or Vector3.new(0, 0, 0)
    -- Kirim 8 bom secara beruntun
    for i = 1, 8 do
        task.delay(i * 0.4, function()
            local bombPos = center + Vector3.new(math.random(-80, 80), 200, math.random(-80, 80))
            local bomb = Instance.new("Part")
            bomb.Name = "AirstrikeBomb"
            bomb.Shape = Enum.PartType.Ball
            bomb.Size = Vector3.new(3, 3, 3)
            bomb.Material = Enum.Material.Metal
            bomb.Color = Color3.fromRGB(50, 50, 50)
            bomb.CFrame = CFrame.new(bombPos)
            bomb.CanCollide = false
            bomb.Parent = workspace
            bomb.AssemblyLinearVelocity = Vector3.new(0, -180, 0)
            bomb.Touched:Connect(function(hit)
                if hit and hit ~= bomb and not hit:IsDescendantOf(LocalPlayer.Character) then
                    local exp = Instance.new("Explosion")
                    exp.Position = bomb.Position
                    exp.BlastRadius = 30
                    exp.BlastPressure = 500000
                    exp.Parent = workspace
                    -- Kill dummy di radius
                    for _, dummy in ipairs(getAllDummies()) do
                        local dRoot = dummy:FindFirstChild("HumanoidRootPart") or dummy:FindFirstChild("Torso")
                        if dRoot and (dRoot.Position - bomb.Position).Magnitude < 35 then
                            pcall(function()
                                dummy:BreakJoints()
                                local h = dummy:FindFirstChildOfClass("Humanoid")
                                if h then h.Health = 0 end
                                dRoot.AssemblyLinearVelocity = Vector3.new(math.random(-100, 100), math.random(60, 150), math.random(-100, 100))
                                notifyKillToServer(dummy)
                            end)
                        end
                    end
                    bomb:Destroy()
                end
            end)
            task.delay(5, function() if bomb and bomb.Parent then bomb:Destroy() end end)
        end)
    end
    return true
end

-- EVENT 16: Tsunami (Gelombang air raksasa visual beneran)
local function triggerTsunami()
    triggerNativeGameEvent("Tsunami")
    local myRoot = getRootPart()
    local center = myRoot and myRoot.Position or Vector3.new(0, 0, 0)

    -- Model tsunami: 3 lapis gelombang
    local waveModel = Instance.new("Model")
    waveModel.Name = "HRR_Tsunami"
    waveModel.Parent = workspace

    local startX = center.X + 250
    local stepsTsunami = 40
    local stepDelay = 0.12

    -- Buat 3 lapis gelombang (depan, tengah, belakang)
    local waveParts = {}
    local layerOffsets = {0, 15, 30} -- Z offset
    local layerColors = {
        Color3.fromRGB(0, 80, 220),
        Color3.fromRGB(0, 110, 255),
        Color3.fromRGB(80, 160, 255),
    }
    local layerSizes = {
        Vector3.new(350, 50, 25),
        Vector3.new(350, 35, 20),
        Vector3.new(350, 20, 15),
    }
    local layerTransparency = {0.2, 0.35, 0.5}

    for i, zOff in ipairs(layerOffsets) do
        local w = Instance.new("Part")
        w.Name = "TsunamiLayer" .. i
        w.Size = layerSizes[i]
        w.Material = Enum.Material.Neon
        w.Color = layerColors[i]
        w.Transparency = layerTransparency[i]
        w.Anchored = true
        w.CanCollide = false
        w.CFrame = CFrame.new(startX, center.Y + 20, center.Z + zOff)
        w.Parent = waveModel
        table.insert(waveParts, w)

        -- Efek busa di puncak
        local foam = Instance.new("Part")
        foam.Size = Vector3.new(350, 8, 10)
        foam.Material = Enum.Material.Neon
        foam.Color = Color3.fromRGB(220, 240, 255)
        foam.Transparency = 0.1
        foam.Anchored = true
        foam.CanCollide = false
        foam.CFrame = CFrame.new(startX, center.Y + 42, center.Z + zOff - 5)
        foam.Parent = waveModel
        table.insert(waveParts, foam)
    end

    -- Gerakkan gelombang dengan task.delay (no Heartbeat lag)
    for step = 1, stepsTsunami do
        task.delay(step * stepDelay, function()
            if not waveModel or not waveModel.Parent then return end
            local newX = startX - (step * 6.5) -- bergerak ke kiri
            pcall(function()
                for _, wp in ipairs(waveParts) do
                    if wp and wp.Parent then
                        wp.CFrame = CFrame.new(newX, wp.Position.Y, wp.Position.Z)
                    end
                end
            end)
            -- Di titik tertentu, lempar semua dummy
            if step >= 5 then
                for _, dummy in ipairs(getAllDummies()) do
                    local dRoot = dummy:FindFirstChild("HumanoidRootPart") or dummy:FindFirstChild("Torso")
                    if dRoot and not dRoot.Anchored then
                        local distX = math.abs(dRoot.Position.X - newX)
                        if distX < 50 then
                            pcall(function()
                                dRoot.AssemblyLinearVelocity = Vector3.new(-80, 40, math.random(-50, 50))
                                dummy:BreakJoints()
                                local h = dummy:FindFirstChildOfClass("Humanoid")
                                if h then h.Health = 0 end
                                notifyKillToServer(dummy)
                            end)
                        end
                    end
                end
            end
        end)
    end

    -- Cleanup
    task.delay(stepsTsunami * stepDelay + 2, function()
        if waveModel and waveModel.Parent then waveModel:Destroy() end
    end)
    return true
end

-- EVENT 17: Shark Rain (Hiu proper visual berjatuhan dari langit)
local function triggerSharkRain()
    triggerNativeGameEvent("Shark Rain")
    local myRoot = getRootPart()
    local center = myRoot and myRoot.Position or Vector3.new(0, 0, 0)

    local function spawnShark(offsetX, offsetZ)
        local sharkModel = Instance.new("Model")
        sharkModel.Name = "HRR_Shark"
        sharkModel.Parent = workspace

        local GREY = Color3.fromRGB(90, 115, 135)
        local LIGHTGREY = Color3.fromRGB(200, 210, 220)
        local startPos = center + Vector3.new(offsetX, 180, offsetZ)

        -- Body utama hiu (lonjong)
        local body = Instance.new("Part")
        body.Name = "SharkBody"
        body.Size = Vector3.new(4, 3, 14)
        body.Material = Enum.Material.SmoothPlastic
        body.Color = GREY
        body.Anchored = true
        body.CanCollide = false
        body.CFrame = CFrame.new(startPos)
        body.Parent = sharkModel
        sharkModel.PrimaryPart = body

        -- Perut putih
        local belly = Instance.new("Part")
        belly.Size = Vector3.new(3.5, 1.5, 12)
        belly.Color = LIGHTGREY
        belly.Material = Enum.Material.SmoothPlastic
        belly.Anchored = true; belly.CanCollide = false
        belly.CFrame = body.CFrame * CFrame.new(0, -1.2, 0)
        belly.Parent = sharkModel
        local wb = Instance.new("WeldConstraint"); wb.Part0=body; wb.Part1=belly; wb.Parent=body

        -- Sirip atas
        local finTop = Instance.new("Part")
        finTop.Size = Vector3.new(0.5, 5, 4)
        finTop.Color = GREY
        finTop.Material = Enum.Material.SmoothPlastic
        finTop.Anchored = true; finTop.CanCollide = false
        finTop.CFrame = body.CFrame * CFrame.new(0, 3.5, -1)
        finTop.Parent = sharkModel
        local wft = Instance.new("WeldConstraint"); wft.Part0=body; wft.Part1=finTop; wft.Parent=body

        -- Sirip samping kiri
        local finL = Instance.new("Part")
        finL.Size = Vector3.new(5, 0.5, 3)
        finL.Color = GREY
        finL.Material = Enum.Material.SmoothPlastic
        finL.Anchored = true; finL.CanCollide = false
        finL.CFrame = body.CFrame * CFrame.new(-4, 0, 0)
        finL.Parent = sharkModel
        local wfL = Instance.new("WeldConstraint"); wfL.Part0=body; wfL.Part1=finL; wfL.Parent=body

        -- Sirip samping kanan
        local finR = Instance.new("Part")
        finR.Size = Vector3.new(5, 0.5, 3)
        finR.Color = GREY
        finR.Material = Enum.Material.SmoothPlastic
        finR.Anchored = true; finR.CanCollide = false
        finR.CFrame = body.CFrame * CFrame.new(4, 0, 0)
        finR.Parent = sharkModel
        local wfR = Instance.new("WeldConstraint"); wfR.Part0=body; wfR.Part1=finR; wfR.Parent=body

        -- Ekor
        local tail = Instance.new("Part")
        tail.Size = Vector3.new(0.5, 5, 5)
        tail.Color = GREY
        tail.Material = Enum.Material.SmoothPlastic
        tail.Anchored = true; tail.CanCollide = false
        tail.CFrame = body.CFrame * CFrame.new(0, 0, 8)
        tail.Parent = sharkModel
        local wt = Instance.new("WeldConstraint"); wt.Part0=body; wt.Part1=tail; wt.Parent=body

        -- Mata (hitam pekat)
        local eye = Instance.new("Part")
        eye.Size = Vector3.new(0.6, 0.6, 0.3)
        eye.Color = Color3.fromRGB(0,0,0)
        eye.Material = Enum.Material.SmoothPlastic
        eye.Anchored = true; eye.CanCollide = false
        eye.CFrame = body.CFrame * CFrame.new(-2, 0.8, -5.5)
        eye.Parent = sharkModel
        local we = Instance.new("WeldConstraint"); we.Part0=body; we.Part1=eye; we.Parent=body

        -- Jatuh dengan task.delay (no lag)
        local steps = 35
        local dropDelay = 0.08
        local hasHit = false
        for step = 1, steps do
            task.delay(step * dropDelay, function()
                if not sharkModel or not sharkModel.Parent or hasHit then return end
                pcall(function()
                    local newY = startPos.Y - (step * 5.5)
                    body.CFrame = CFrame.new(startPos.X, newY, startPos.Z)
                    -- Cek tabrakan dengan dummy
                    if newY < center.Y + 15 then
                        for _, dummy in ipairs(getAllDummies()) do
                            local dRoot = dummy:FindFirstChild("HumanoidRootPart") or dummy:FindFirstChild("Torso")
                            if dRoot then
                                local dist = (dRoot.Position - body.Position).Magnitude
                                if dist < 20 and not hasHit then
                                    hasHit = true
                                    pcall(function()
                                        dRoot.AssemblyLinearVelocity = Vector3.new(math.random(-100,100), 80, math.random(-100,100))
                                        dummy:BreakJoints()
                                        local h = dummy:FindFirstChildOfClass("Humanoid")
                                        if h then h.Health = 0 end
                                        notifyKillToServer(dummy)
                                    end)
                                end
                            end
                        end
                        -- Ledakan kecil saat mendarat
                        if newY < center.Y + 5 then
                            hasHit = true
                            local exp = Instance.new("Explosion")
                            exp.Position = body.Position
                            exp.BlastRadius = 15
                            exp.BlastPressure = 150000
                            exp.Parent = workspace
                        end
                    end
                end)
            end)
        end

        -- Cleanup
        task.delay(steps * dropDelay + 3, function()
            if sharkModel and sharkModel.Parent then sharkModel:Destroy() end
        end)
    end

    -- Spawn 5 hiu dengan interval
    for i = 1, 5 do
        task.delay(i * 0.7, function()
            spawnShark(math.random(-80, 80), math.random(-80, 80))
        end)
    end
    return true
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
        -- Simulasi V key (HRR: V = Scan Dummy)
        pcall(function()
            if firesignal then
                firesignal(UserInputService.InputBegan, {KeyCode = Enum.KeyCode.V, UserInputType = Enum.UserInputType.Keyboard}, false)
                task.wait(0.05)
                firesignal(UserInputService.InputEnded, {KeyCode = Enum.KeyCode.V, UserInputType = Enum.UserInputType.Keyboard}, false)
            end
        end)
        -- Juga coba via GUI scan button
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
        -- Simulasi G key (HRR: G = Respawn Karakter)
        pcall(function()
            if firesignal then
                firesignal(UserInputService.InputBegan, {KeyCode = Enum.KeyCode.G, UserInputType = Enum.UserInputType.Keyboard}, false)
                task.wait(0.05)
                firesignal(UserInputService.InputEnded, {KeyCode = Enum.KeyCode.G, UserInputType = Enum.UserInputType.Keyboard}, false)
            end
        end)
        -- Fallback: health = 0
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

EventsTab:CreateSection("1. Gravitasi dan Cuaca Ekstrem")

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

EventsTab:CreateSection("2. Modifikasi Ukuran dan Hujan Ragdoll")

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

EventsTab:CreateSection("3. Bencana Kosmik dan Kehancuran Massal")

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

EventsTab:CreateSection("4. Event Bencana Tambahan")

EventsTab:CreateButton({
    Name = "Warhead (Nuklir Masif - Semua Ragdoll Hancur Seketika)",
    Callback = function()
        triggerWarhead()
        Window:Notify({ Title = "WARHEAD", Content = "Hulu ledak nuklir dijatuhkan! Seluruh ragdoll musnah dalam ledakan besar!", Duration = 4 })
    end
})

EventsTab:CreateButton({
    Name = "Zombie Outbreak (Semua Ragdoll Berubah Jadi Zombie Hijau)",
    Callback = function()
        local count = triggerZombieOutbreak()
        Window:Notify({ Title = "Zombie Outbreak", Content = count .. " ragdoll telah berubah menjadi zombie hijau!", Duration = 3 })
    end
})

EventsTab:CreateButton({
    Name = "Disco Party (Pesta Lampu Disko + Gravitasi Rendah)",
    Callback = function()
        triggerDiscoParty()
        Window:Notify({ Title = "Disco Party", Content = "Pesta disko dimulai! Gravitasi ringan & semua berwarna-warni!", Duration = 3 })
    end
})

EventsTab:CreateButton({
    Name = "Bee Swarm (Serangan Lebah Masif pada Semua Ragdoll)",
    Callback = function()
        local count = triggerBeeSwarm()
        Window:Notify({ Title = "Bee Swarm", Content = count .. " ragdoll diserang gerombolan lebah!", Duration = 3 })
    end
})

EventsTab:CreateButton({
    Name = "T-Rex Attack (T-Rex Raksasa Muncul Menghancurkan Semua)",
    Callback = function()
        triggerTRexAttack()
        Window:Notify({ Title = "T-Rex Attack", Content = "T-Rex Titan berhasil dipanggil! Seluruh ragdoll diporak-porandakan!", Duration = 4 })
    end
})

EventsTab:CreateButton({
    Name = "Airstrike (8 Bom Udara Beruntun Menghujani Map)",
    Callback = function()
        triggerAirstrike()
        Window:Notify({ Title = "Airstrike", Content = "8 bom udara diluncurkan! Seluruh map dibombardir!", Duration = 3 })
    end
})

EventsTab:CreateButton({
    Name = "Tsunami (Gelombang Raksasa Menyapu Seluruh Map)",
    Callback = function()
        triggerTsunami()
        Window:Notify({ Title = "Tsunami", Content = "Gelombang tsunami masif menyapu seluruh map!", Duration = 4 })
    end
})

EventsTab:CreateButton({
    Name = "Shark Rain (Hiu Berjatuhan dari Langit)",
    Callback = function()
        triggerSharkRain()
        Window:Notify({ Title = "Shark Rain", Content = "Hiu-hiu berjatuhan dari langit menghantam semua ragdoll!", Duration = 3 })
    end
})



-- ╔═══════════════════════════════════════════╗
-- ║  TAB 3: SENJATA (WEAPON UNLOCKER)         ║
-- ╚═══════════════════════════════════════════╝
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

    -- Cek slot yang digunakan (game HRR punya 10 slot)
    local currentTools = {}
    local char = getCharacter()
    if char then
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") then
                table.insert(currentTools, item)
            end
        end
    end
    for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if item:IsA("Tool") then
            table.insert(currentTools, item)
        end
    end

    -- Cek apakah slot sudah terpakai - jika ya, drop tool di slot itu
    if slot and slot > 0 then
        local toolInSlot = currentTools[slot]
        if toolInSlot then
            -- Drop tool yang ada di slot itu
            pcall(function()
                local handle = toolInSlot:FindFirstChild("Handle") or toolInSlot:FindFirstChildWhichIsA("BasePart")
                if handle then
                    toolInSlot.Parent = workspace
                    handle.CFrame = myRoot.CFrame * CFrame.new(0, 0, -4)
                end
            end)
        end
    end

    local got = false

    -- Metode 1: Scan ToolController untuk equip tool bernama weaponName
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

    -- Metode 2: Scan RemoteEvent untuk memberi senjata
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

    -- Metode 3: Cari senjata di ServerStorage / ReplicatedStorage / workspace
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

    -- Metode 4: SetAttribute HRR_GiveTool (HRR attribute-based give)
    pcall(function()
        LocalPlayer:SetAttribute("HRR_GiveTool", weaponName)
        task.delay(0.2, function()
            LocalPlayer:SetAttribute("HRR_GiveTool", nil)
        end)
        got = true
    end)

    -- Metode 5: firetouchinterest dengan tool yang ada di tangan lain
    if not got then
        pcall(function()
            -- Ambil tool dari Backpack/Character jika ada nama mirip
            local lowerWep = string.lower(weaponName)
            for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
                if string.find(string.lower(item.Name), lowerWep) then
                    hum:EquipTool(item)
                    got = true
                    break
                end
            end
        end)
    end

    -- Pastikan tool di-equip ke tangan dan script di dalamnya aktif
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
            -- Aktifkan semua script dalam tool jika nonaktif
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

-- Listener klik mouse untuk menembak / mengayun senjata 100% aktif
local weaponClickConn = nil
if not getgenv()._UNIONSAL_WEAPON_CLICK then
    getgenv()._UNIONSAL_WEAPON_CLICK = true
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local ch = LocalPlayer.Character
            local currentTool = ch and ch:FindFirstChildOfClass("Tool")
            if currentTool then
                pcall(function() currentTool:Activate() end)
                -- Fallback damage raycast jika script bawaan senjata di-block
                task.defer(function()
                    local mouse = LocalPlayer:GetMouse()
                    local targetPart = mouse and mouse.Target
                    if targetPart and targetPart.Parent and targetPart.Parent ~= ch then
                        local dHum = targetPart.Parent:FindFirstChildOfClass("Humanoid")
                        if dHum then
                            dHum:TakeDamage(45)
                            if dHum.Health <= 0 then
                                notifyKillToServer(targetPart.Parent)
                            end
                        end
                    end
                end)
            end
        end
    end)
end

-- Buat Weapons Tab
-- ═══════════════════════════════════════════
--  SENJATA TAB (Dropdown per Kategori, Sidebar Sendiri)
-- ═══════════════════════════════════════════
-- Tab utama Senjata (sidebar: group "Senjata")
local WeaponsTab    = Window:CreateTab("Senjata",     "sword",   "Senjata")
local WeaponsMelee  = Window:CreateTab("Melee",       "sword",   "Senjata")
local WeaponsGuns   = Window:CreateTab("Guns",        "target",  "Senjata")
local WeaponsThrow  = Window:CreateTab("Lempar",      "star",    "Senjata")
local WeaponsPower  = Window:CreateTab("Power",       "zap",     "Senjata")
local WeaponsMedic  = Window:CreateTab("Medic",       "heart",   "Senjata")
local WeaponsRobux  = Window:CreateTab("Premium",     "diamond", "Senjata")

-- ── Helper: build daftar nama senjata per kategori
local function buildWeaponOptions(category)
    local opts = {}
    for _, wep in ipairs(WeaponDatabase[category]) do
        local lbl = wep.robux and ("[R$] " .. wep.name) or wep.name
        table.insert(opts, lbl)
    end
    return opts
end

local function getWeaponByLabel(category, label)
    for _, wep in ipairs(WeaponDatabase[category]) do
        local lbl = wep.robux and ("[R$] " .. wep.name) or wep.name
        if lbl == label then return wep end
    end
    return nil
end

-- ── Tab Overview Senjata
WeaponsTab:CreateSection("Status Inventory Senjata")

WeaponsTab:CreateButton({
    Name = "Lihat Slot Senjata Aktif",
    Callback = function()
        local char = getCharacter()
        local tools = {}
        if char then
            for _, item in ipairs(char:GetChildren()) do
                if item:IsA("Tool") then table.insert(tools, "[Pegang] "..item.Name) end
            end
        end
        for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if item:IsA("Tool") then table.insert(tools, "[Pack] "..item.Name) end
        end
        local msg = #tools > 0 and table.concat(tools, " | ") or "Inventory kosong."
        Window:Notify({ Title = "Slot ("..#tools.."/10)", Content = msg, Duration = 7 })
    end
})

WeaponsTab:CreateButton({
    Name = "Drop Semua Senjata (Kosongkan Inventory)",
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
        Window:Notify({ Title = "Drop Senjata", Content = count.." senjata dibuang ke lantai.", Duration = 2 })
    end
})

WeaponsTab:CreateParagraph({
    Title = "Cara Pakai Senjata",
    Content = "Pilih kategori di sidebar kiri (Melee / Guns / Lempar / Power / Medic / Premium), lalu pilih senjata dari dropdown dan klik Equip. Jika slot penuh, slot lama otomatis di-drop."
})

-- ── MELEE TAB
WeaponsMelee:CreateSection("Melee - Senjata Jarak Dekat")
local selectedMelee = WeaponDatabase.Melee[1].name
WeaponsMelee:CreateDropdown({
    Name = "Pilih Senjata Melee",
    Options = buildWeaponOptions("Melee"),
    Callback = function(opt)
        local wep = getWeaponByLabel("Melee", opt)
        if wep then selectedMelee = wep.name end
    end
})
WeaponsMelee:CreateButton({
    Name = "Equip Senjata Melee Dipilih",
    Callback = function()
        giveWeapon(selectedMelee, 1)
    end
})
WeaponsMelee:CreateParagraph({
    Title = "Daftar Melee (14 senjata)",
    Content = "Fists | Bat | Axe | Hammer | Shovel | Wrench | Crowbar | Machete | Sword | [R$] Katana | Cleaver | [R$] Chainsaw | Sledgehammer | Spear"
})

-- ── GUNS TAB
WeaponsGuns:CreateSection("Guns - Senjata Api")
local selectedGun = WeaponDatabase.Guns[1].name
WeaponsGuns:CreateDropdown({
    Name = "Pilih Senjata Api",
    Options = buildWeaponOptions("Guns"),
    Callback = function(opt)
        local wep = getWeaponByLabel("Guns", opt)
        if wep then selectedGun = wep.name end
    end
})
WeaponsGuns:CreateButton({
    Name = "Equip Senjata Api Dipilih",
    Callback = function()
        giveWeapon(selectedGun, 2)
    end
})
WeaponsGuns:CreateParagraph({
    Title = "Daftar Guns (14 senjata)",
    Content = "Pistol | Revolver | Shotgun | SMG | Rifle | Sniper | LMG | Crossbow | Flintlock | [R$] Minigun | [R$] Railgun | [R$] Flamethrower | [R$] Laser | Paintball Gun"
})

-- ── THROW TAB
WeaponsThrow:CreateSection("Lempar - Senjata Lempar")
local selectedThrow = WeaponDatabase.Throw[1].name
WeaponsThrow:CreateDropdown({
    Name = "Pilih Senjata Lempar",
    Options = buildWeaponOptions("Throw"),
    Callback = function(opt)
        local wep = getWeaponByLabel("Throw", opt)
        if wep then selectedThrow = wep.name end
    end
})
WeaponsThrow:CreateButton({
    Name = "Equip Senjata Lempar Dipilih",
    Callback = function()
        giveWeapon(selectedThrow, 3)
    end
})
WeaponsThrow:CreateParagraph({
    Title = "Daftar Lempar (12 senjata)",
    Content = "Rock | Grenade | Molotov | Flashbang | Smoke Grenade | Dynamite | Throwing Knife | Tomahawk | [R$] Shuriken | Firework | [R$] C4 | Frag Grenade"
})

-- ── POWER TAB
WeaponsPower:CreateSection("Power - Senjata Super / Special")
local selectedPower = WeaponDatabase.Power[1].name
WeaponsPower:CreateDropdown({
    Name = "Pilih Senjata Power",
    Options = buildWeaponOptions("Power"),
    Callback = function(opt)
        local wep = getWeaponByLabel("Power", opt)
        if wep then selectedPower = wep.name end
    end
})
WeaponsPower:CreateButton({
    Name = "Equip Senjata Power Dipilih",
    Callback = function()
        giveWeapon(selectedPower, 4)
    end
})
WeaponsPower:CreateParagraph({
    Title = "Daftar Power (13 senjata)",
    Content = "Gravity Gun | Freeze Ray | Lightning Rod | [R$] Black Hole Gun | [R$] Tornado Gun | [R$] Shrink Ray | [R$] Grow Ray | Magnet Gun | [R$] Portal Gun | Wind Gun | [R$] Nuke Launcher | Taser | EMP"
})

-- ── MEDIC TAB
WeaponsMedic:CreateSection("Medic - Alat Medis")
local selectedMedic = WeaponDatabase.Medic[1].name
WeaponsMedic:CreateDropdown({
    Name = "Pilih Alat Medis",
    Options = buildWeaponOptions("Medic"),
    Callback = function(opt)
        local wep = getWeaponByLabel("Medic", opt)
        if wep then selectedMedic = wep.name end
    end
})
WeaponsMedic:CreateButton({
    Name = "Equip Alat Medis Dipilih",
    Callback = function()
        giveWeapon(selectedMedic, 5)
    end
})
WeaponsMedic:CreateParagraph({
    Title = "Daftar Medic (8 alat)",
    Content = "Defibrillator | Medkit | Bandage | Syringe | Scanner | Blood Bag | AED | Splint"
})

-- ── ROBUX/PREMIUM TAB
WeaponsRobux:CreateSection("Premium - Senjata Robux (Bypass Unlock)")
WeaponsRobux:CreateParagraph({
    Title = "Info Premium",
    Content = "Senjata [R$] di game butuh Robux. Script ini bypass ToolController & RemoteEvent untuk memberi senjata tanpa beli. Pilih dari dropdown lalu klik Unlock."
})
local selectedRobux = WeaponDatabase.Robux[1].name
WeaponsRobux:CreateDropdown({
    Name = "Pilih Senjata Premium",
    Options = buildWeaponOptions("Robux"),
    Callback = function(opt)
        local wep = getWeaponByLabel("Robux", opt)
        if wep then selectedRobux = wep.name end
    end
})
WeaponsRobux:CreateButton({
    Name = "Unlock + Equip Senjata Premium",
    Callback = function()
        pcall(function()
            local attrName = "Unlocked_" .. selectedRobux:gsub("%s+", "_")
            LocalPlayer:SetAttribute(attrName, true)
            LocalPlayer:SetAttribute("HRR_Premium", true)
            LocalPlayer:SetAttribute("HRR_Robux", 999999)
        end)
        giveWeapon(selectedRobux, 1)
    end
})


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

-- (Salin Koordinat dipindah ke tab Teleport)

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

-- Helper: scan map untuk lokasi
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

-- ── Lokasi Map HRR
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
        if type(fanCf) == "userdata" then tpTo(fanCf, "Kipas Raksasa")
        else tpTo(CFrame.new(fanCf.Position), "Kipas Raksasa") end
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
            title = "Unionsal Hub v1.3 • Webhook Connected",
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
