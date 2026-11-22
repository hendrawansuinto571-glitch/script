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

-- ═══════════════════════════════════════════
--  SISTEM KILL TRACKING (Server KO Counter)
-- ═══════════════════════════════════════════
local KillCount = 0
local function notifyKillToServer(dummy)
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

    if dHum then
        pcall(function()
            dHum.Health = 0
            dHum:ChangeState(Enum.HumanoidStateType.Dead)
        end)
    end

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

    for _, part in ipairs(dummy:GetChildren()) do
        if part:IsA("BasePart") and not part.Anchored then
            pcall(function()
                part.AssemblyLinearVelocity = Vector3.new(0, -500, 0)
            end)
        end
    end

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
            for _, desc in ipairs(dummy:GetDescendants()) do
                if desc:IsA("JointInstance") or desc:IsA("Constraint") then
                    desc:Destroy()
                end
            end
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
            notifyKillToServer(dummy)
        end)
    end
    return count
end

-- Memicu sistem Revive bawaan game (Keybind R + Remote + Modul)
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
        if dummiesFolder then
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
        end
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
        if firesignal then
            firesignal(uis.InputBegan, {KeyCode = Enum.KeyCode.R, UserInputType = Enum.UserInputType.Keyboard}, false)
            task.wait(0.05)
            firesignal(uis.InputEnded, {KeyCode = Enum.KeyCode.R, UserInputType = Enum.UserInputType.Keyboard}, false)
        end
        LocalPlayer:SetAttribute("HRR_Revive", true)
        task.wait(0.1)
        LocalPlayer:SetAttribute("HRR_Revive", nil)
        LocalPlayer:SetAttribute("HRR_Wave", (LocalPlayer:GetAttribute("HRR_Wave") or 0) + 1)
        done = true
    end)

    -- 5. Fallback: pulihkan Health & joints manual
    for _, dummy in ipairs(getAllDummies()) do
        pcall(function()
            local dHum = dummy:FindFirstChildOfClass("Humanoid")
            if dHum then
                dHum.Health = dHum.MaxHealth > 0 and dHum.MaxHealth or 100
                dHum:ChangeState(Enum.HumanoidStateType.GettingUp)
                for _, j in ipairs(dummy:GetDescendants()) do
                    if j:IsA("Motor6D") and not j.Enabled then
                        j.Enabled = true
                    end
                end
            end
        end)
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
--  SISTEM BENCANA & GAME EVENTS (100% NATIVE GAME ENGINE)
-- ═══════════════════════════════════════════
local GameEvents = {
    OriginalGravity = workspace.Gravity,
}

-- Memicu Event Game secara 100% Native dari Game Engine (Tanpa Bikin Sendiri / Anti-Lag)
local function triggerNativeGameEvent(eventName)
    local triggered = false
    local lowerName = string.lower(eventName)
    local norm = string.lower(string.gsub(eventName, "%s+", ""))
    local vim = game:GetService("VirtualInputManager")

    -- 0. Buka UI Events bawaan game jika sedang tertutup
    pcall(function()
        for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
            if gui:IsA("GuiButton") then
                local nm = string.lower(gui.Name)
                local txt = (gui:IsA("TextButton") and string.lower(gui.Text)) or ""
                if nm == "event" or nm == "events" or txt == "events" or string.find(nm, "eventbtn") or string.find(nm, "openevent") then
                    if vim then
                        local pos = gui.AbsolutePosition + (gui.AbsoluteSize / 2)
                        vim:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                        task.wait(0.02)
                        vim:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                    end
                    if firesignal then
                        firesignal(gui.MouseButton1Click)
                        firesignal(gui.Activated)
                    end
                end
            end
        end
    end)

    -- 1. Scan PlayerGui untuk tombol / kartu event game
    pcall(function()
        for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
            local matched = false
            if gui:IsA("TextLabel") or gui:IsA("TextButton") then
                local txt = string.lower(gui.Text)
                if txt == lowerName or string.find(txt, lowerName, 1, true) or string.find(string.gsub(txt, "%s+", ""), norm, 1, true) then
                    matched = true
                end
            end
            local nm = string.lower(gui.Name)
            if nm == lowerName or string.find(nm, norm, 1, true) then
                matched = true
            end

            if matched then
                -- Buka kunci card event dan set token 999
                pcall(function()
                    local parentCard = gui:FindFirstAncestorWhichIsA("Frame") or gui.Parent
                    if parentCard then
                        for _, child in ipairs(parentCard:GetDescendants()) do
                            if child:IsA("TextLabel") and (child.Text == "0" or child.Text == "LOCKED") then
                                child.Text = "999"
                            end
                            if child:IsA("ImageLabel") and string.find(string.lower(child.Name), "lock") then
                                child.Visible = false
                            end
                        end
                    end
                end)

                local targetBtn = gui:IsA("GuiButton") and gui or gui:FindFirstAncestorWhichIsA("GuiButton")
                if not targetBtn and gui.Parent then
                    targetBtn = gui.Parent:FindFirstChildWhichIsA("GuiButton")
                end
                if not targetBtn and gui.Parent and gui.Parent.Parent then
                    targetBtn = gui.Parent.Parent:FindFirstChildWhichIsA("GuiButton")
                end

                if targetBtn then
                    targetBtn.Active = true
                    targetBtn.Selectable = true

                    -- A. Simulasi engine mouse click melalui VirtualInputManager
                    pcall(function()
                        if vim then
                            local pos = targetBtn.AbsolutePosition + (targetBtn.AbsoluteSize / 2)
                            vim:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                            task.wait(0.02)
                            vim:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                        end
                    end)

                    -- B. firesignal
                    pcall(function()
                        if firesignal then
                            firesignal(targetBtn.MouseButton1Click)
                            firesignal(targetBtn.Activated)
                            firesignal(targetBtn.MouseButton1Down)
                            firesignal(targetBtn.MouseButton1Up)
                        end
                    end)

                    -- C. getconnections
                    pcall(function()
                        if getconnections then
                            for _, sig in ipairs({targetBtn.MouseButton1Click, targetBtn.Activated, targetBtn.MouseButton1Down}) do
                                for _, conn in ipairs(getconnections(sig)) do
                                    if conn.Fire then conn:Fire()
                                    elseif conn.Function then conn.Function() end
                                end
                            end
                        end
                    end)

                    triggered = true
                end
            end
        end
    end)

    -- 2. Panggil Client.Events.EventRunner langsung (ModuleScript bawaan game HRR)
    pcall(function()
        local client = LocalPlayer.PlayerScripts:FindFirstChild("Client")
        if client then
            local eventsFolder = client:FindFirstChild("Events")
            if eventsFolder then
                local er = eventsFolder:FindFirstChild("EventRunner")
                if er then
                    local ok, req = pcall(require, er)
                    if ok and req then
                        if req.start then pcall(req.start, eventName); pcall(req.start, norm); triggered = true end
                        if req.trigger then pcall(req.trigger, eventName); pcall(req.trigger, norm); triggered = true end
                        if req.run then pcall(req.run, eventName); pcall(req.run, norm); triggered = true end
                        if req.fire then pcall(req.fire, eventName); pcall(req.fire, norm); triggered = true end
                        if req[eventName] then pcall(req[eventName]); triggered = true end
                        if req[norm] then pcall(req[norm]); triggered = true end
                    end
                end
                for _, mod in ipairs(eventsFolder:GetChildren()) do
                    if mod:IsA("ModuleScript") and string.find(string.lower(mod.Name), norm) then
                        local ok, mReq = pcall(require, mod)
                        if ok and mReq then
                            if mReq.start then pcall(mReq.start); triggered = true end
                            if mReq.run then pcall(mReq.run); triggered = true end
                            if mReq.trigger then pcall(mReq.trigger); triggered = true end
                        end
                    end
                end
            end
        end
    end)

    -- 3. Scan ReplicatedStorage untuk RemoteEvent event game
    pcall(function()
        for _, obj in ipairs(game:GetDescendants()) do
            if obj:IsA("RemoteEvent") then
                local n = string.lower(obj.Name)
                if string.find(n, "event") or string.find(n, "disaster") or string.find(n, norm) then
                    pcall(function() obj:FireServer(eventName) end)
                    pcall(function() obj:FireServer(norm) end)
                    pcall(function() obj:FireServer("Start", eventName) end)
                    pcall(function() obj:FireServer("Trigger", eventName) end)
                    pcall(function() obj:FireServer(eventName, true) end)
                    triggered = true
                end
            elseif obj:IsA("RemoteFunction") then
                local n = string.lower(obj.Name)
                if string.find(n, "event") or string.find(n, "disaster") or string.find(n, norm) then
                    pcall(function() obj:InvokeServer(eventName) end)
                    pcall(function() obj:InvokeServer(norm) end)
                    triggered = true
                end
            end
        end
    end)

    -- 4. Buka akses token di attributes
    pcall(function()
        LocalPlayer:SetAttribute(eventName, 999)
        LocalPlayer:SetAttribute(norm, 999)
        LocalPlayer:SetAttribute("CurrentEvent", eventName)
        LocalPlayer:SetAttribute("HRR_Event", eventName)
    end)

    return triggered
end

local function runGameEvent(name)
    local ok = triggerNativeGameEvent(name)
    Window:Notify({
        Title = "Game Event",
        Content = "Event [" .. name .. "] dipicu ke game engine!",
        Duration = 2.5
    })
    return ok
end

local function stopAllActiveEvents()
    workspace.Gravity = GameEvents.OriginalGravity
    pcall(function()
        triggerNativeGameEvent("Reset")
        triggerNativeGameEvent("Stop")
        triggerNativeGameEvent("Clear")
    end)
    for _, dummy in ipairs(getAllDummies()) do
        pcall(function()
            for _, p in ipairs(dummy:GetDescendants()) do
                if p:IsA("BasePart") and p.Material == Enum.Material.Ice then
                    p.Material = Enum.Material.SmoothPlastic
                    p.Anchored = false
                end
            end
        end)
    end
end

local function unlockAllEventTokens()
    local count = 0
    pcall(function()
        for attrName, _ in pairs(LocalPlayer:GetAttributes()) do
            if string.find(string.lower(attrName), "event") or string.find(string.lower(attrName), "token") then
                LocalPlayer:SetAttribute(attrName, 999)
                count = count + 1
            end
        end
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

    local currentTools = {}
    if char then
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") then table.insert(currentTools, item) end
        end
    end
    for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if item:IsA("Tool") then table.insert(currentTools, item) end
    end

    -- Cek duplikat: jika senjata sudah ada di slot, jangan ambil lagi
    for _, t in ipairs(currentTools) do
        if string.lower(t.Name) == string.lower(weaponName) or string.find(string.lower(t.Name), string.lower(weaponName), 1, true) then
            Window:Notify({
                Title = "Slot Senjata",
                Content = "Senjata [" .. weaponName .. "] sudah ada di slot inventory!",
                Duration = 2.5
            })
            return false
        end
    end

    -- Cek limit 10 slot: jika sudah 10, tolak
    if #currentTools >= 10 then
        Window:Notify({
            Title = "Slot Penuh",
            Content = "Slot inventory sudah penuh (10/10)! Buang salah satu senjata terlebih dahulu.",
            Duration = 3
        })
        return false
    end

    local got = false

    -- Metode 1: Scan ToolController
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

    -- Metode 2: Scan RemoteEvent
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

    -- Metode 3: Scan dropped tools di workspace
    pcall(function()
        for _, tool in ipairs(getDroppedTools()) do
            if string.find(string.lower(tool.Name), string.lower(weaponName)) then
                local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
                if handle and firetouchinterest then
                    firetouchinterest(handle, myRoot, 0)
                    firetouchinterest(handle, myRoot, 1)
                    got = true
                    break
                end
            end
        end
    end)

    -- Metode 4: Storage
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

    -- Metode 5: SetAttribute HRR_GiveTool
    pcall(function()
        LocalPlayer:SetAttribute("HRR_GiveTool", weaponName)
        task.delay(0.2, function()
            LocalPlayer:SetAttribute("HRR_GiveTool", nil)
        end)
        got = true
    end)

    -- Auto-equip & aktifkan senjata
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

-- ═══════════════════════════════════════════
--  PENGATURAN RUNTIME (Selalu Reset Saat Join / Masuk Game)
--  Hanya Webhook yang Disimpan Persisten
-- ═══════════════════════════════════════════
local WEBHOOK_CONFIG_FILE = "unionsal_webhook.json"
local webhookUrl = ""

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
    WebhookUrl = "",
    SendOnExec = true,
    SendOnKo = true,
    ToggleKey = "RightShift"
}

local ToggleObjects = {}
local SliderObjects = {}
local InputObjects = {}

local function saveWebhookConfig()
    pcall(function()
        if writefile then
            local payload = {
                WebhookUrl = ConfigRegistry.WebhookUrl,
                SendOnExec = ConfigRegistry.SendOnExec,
                SendOnKo = ConfigRegistry.SendOnKo
            }
            writefile(WEBHOOK_CONFIG_FILE, HttpService:JSONEncode(payload))
        end
    end)
end

local function loadWebhookConfig()
    pcall(function()
        if readfile and isfile and isfile(WEBHOOK_CONFIG_FILE) then
            local data = HttpService:JSONDecode(readfile(WEBHOOK_CONFIG_FILE))
            if data and type(data) == "table" then
                if data.WebhookUrl then
                    ConfigRegistry.WebhookUrl = data.WebhookUrl
                    webhookUrl = data.WebhookUrl
                    if InputObjects.WebhookUrl then
                        pcall(function() InputObjects.WebhookUrl:Set(data.WebhookUrl, true) end)
                    end
                end
                if data.SendOnExec ~= nil then ConfigRegistry.SendOnExec = data.SendOnExec end
                if data.SendOnKo ~= nil then ConfigRegistry.SendOnKo = data.SendOnKo end
            end
        end
    end)
end

local function deleteWebhookConfig()
    pcall(function()
        if delfile and isfile and isfile(WEBHOOK_CONFIG_FILE) then
            delfile(WEBHOOK_CONFIG_FILE)
        end
        ConfigRegistry.WebhookUrl = ""
        webhookUrl = ""
        if InputObjects.WebhookUrl then
            pcall(function() InputObjects.WebhookUrl:Set("", true) end)
        end
    end)
end

local function notifyStateChange(k, v)
    ConfigRegistry[k] = v
end

-- ═══════════════════════════════════════════
--  OPTIMASI GRAFIK POTATO & FPS BOOST
-- ═══════════════════════════════════════════
local function applyPotatoGraphics(enable)
    local Terrain = workspace:FindFirstChildOfClass("Terrain")
    if enable then
        pcall(function() settings().Rendering.QualityLevel = 1 end)
        pcall(function() Lighting.GlobalShadows = false; Lighting.FogEnd = 9e9; Lighting.Brightness = 1 end)
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("PostEffect") or v:IsA("BloomEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("SunRaysEffect") or v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") then
                v.Enabled = false
            end
        end
        if Terrain then
            pcall(function() Terrain.Decoration = false; Terrain.WaterWaveSize = 0; Terrain.WaterWaveSpeed = 0; Terrain.WaterReflectance = 0 end)
        end
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not obj:IsDescendantOf(LocalPlayer.Character or workspace) then
                pcall(function() obj.Material = Enum.Material.SmoothPlastic; obj.CastShadow = false end)
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                pcall(function() obj.Transparency = 1 end)
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                pcall(function() obj.Enabled = false end)
            end
        end
    else
        pcall(function() Lighting.GlobalShadows = true; Lighting.FogEnd = 1000 end)
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
        pcall(function() settings().Rendering.QualityLevel = 1; Lighting.GlobalShadows = false end)
    else
        pcall(function() settings().Rendering.QualityLevel = 0; Lighting.GlobalShadows = true end)
    end
end

-- ╔═══════════════════════════════════════════╗
-- ║  TAB 1: DUMMIES & KO (AUTO FARM)          ║
-- ╚═══════════════════════════════════════════╝
local FarmTab = Window:CreateTab("Auto Farm", "sprout", "Main")
FarmTab:CreateSection("Auto Kill (Teleport & Langsung Mati)")

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
                                root.CFrame = dRoot.CFrame * CFrame.new(0, 1, 2)
                                task.wait(0.03)

                                killDummyInstantly(dummy)

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
        pcall(function()
            if firesignal then
                firesignal(UserInputService.InputBegan, {KeyCode = Enum.KeyCode.V, UserInputType = Enum.UserInputType.Keyboard}, false)
                task.wait(0.05)
                firesignal(UserInputService.InputEnded, {KeyCode = Enum.KeyCode.V, UserInputType = Enum.UserInputType.Keyboard}, false)
            end
        end)
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
        pcall(function()
            if firesignal then
                firesignal(UserInputService.InputBegan, {KeyCode = Enum.KeyCode.G, UserInputType = Enum.UserInputType.Keyboard}, false)
                task.wait(0.05)
                firesignal(UserInputService.InputEnded, {KeyCode = Enum.KeyCode.G, UserInputType = Enum.UserInputType.Keyboard}, false)
            end
        end)
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
-- ║  TAB 2: EVENTS (SEMUA 24 EVENT GAME HRR)  ║
-- ╚═══════════════════════════════════════════╝
local EventsTab = Window:CreateTab("Events", "zap", "Main")
EventsTab:CreateSection("Bypass & Kontrol Seluruh Event Game")

EventsTab:CreateButton({
    Name = "Unlock All In-Game Event Tokens (999x Penggunaan)",
    Callback = function()
        local c = unlockAllEventTokens()
        Window:Notify({ Title = "Events Unlocked", Content = "Token event di-unlock di UI game! (" .. c .. " items)", Duration = 3 })
    end
})

EventsTab:CreateButton({
    Name = "Hentikan Semua Bencana Aktif (Reset Map Damai)",
    Callback = function()
        stopAllActiveEvents()
        Window:Notify({ Title = "Events Reset", Content = "Seluruh bencana dihentikan. Map dikembalikan ke normal.", Duration = 2.5 })
    end
})

EventsTab:CreateSection("Bencana Fisika dan Cuaca (9 Event)")
local physicsEvents = {
    "Weightless", "Deep Freeze", "Falling Dummies",
    "Wildfire", "Mini Dummies", "Giant Dummy",
    "Meteor Rain", "Tornado", "Black Hole"
}
for _, evName in ipairs(physicsEvents) do
    EventsTab:CreateButton({
        Name = evName,
        Callback = function()
            runGameEvent(evName)
        end
    })
end

EventsTab:CreateSection("Bencana Serangan Hewan dan Makhluk (9 Event)")
local creatureEvents = {
    "Warhead", "Zombie Outbreak", "Disco Party",
    "Bee Swarm", "Dog Pack", "Snake Nest",
    "Spider Nest", "Croc Raid", "Bear Attack"
}
for _, evName in ipairs(creatureEvents) do
    EventsTab:CreateButton({
        Name = evName,
        Callback = function()
            runGameEvent(evName)
        end
    })
end

EventsTab:CreateSection("Bencana Serangan Raksasa dan Titan (6 Event)")
local titanEvents = {
    "Bull Run", "Gorilla Rampage", "Shark Rain",
    "T-Rex Attack", "Airstrike", "Tsunami"
}
for _, evName in ipairs(titanEvents) do
    EventsTab:CreateButton({
        Name = evName,
        Callback = function()
            runGameEvent(evName)
        end
    })
end

-- ═══════════════════════════════════════════
--  TAB 3: SENJATA (SATU TAB SAJA DI SIDEBAR - DROPDOWN)
-- ═══════════════════════════════════════════
local WeaponsTab = Window:CreateTab("Senjata", "sword", "Main")

WeaponsTab:CreateSection("Pilih Kategori dan Senjata")

local selectedCategory = "Melee"
local selectedWeaponName = WeaponDatabase.Melee[1].name
local weaponDropdownObj = nil

local function getCategoryOptionsList(cat)
    local list = {}
    if WeaponDatabase[cat] then
        for _, w in ipairs(WeaponDatabase[cat]) do
            local label = w.robux and ("[R$] " .. w.name) or w.name
            table.insert(list, label)
        end
    end
    return list
end

WeaponsTab:CreateDropdown({
    Name = "Pilih Kategori Senjata",
    Options = { "Melee (14)", "Guns (14)", "Throw (12)", "Power (13)", "Medic (8)", "Robux (8)" },
    Callback = function(opt)
        local catKey = "Melee"
        if string.find(opt, "Guns") then catKey = "Guns"
        elseif string.find(opt, "Throw") then catKey = "Throw"
        elseif string.find(opt, "Power") then catKey = "Power"
        elseif string.find(opt, "Medic") then catKey = "Medic"
        elseif string.find(opt, "Robux") then catKey = "Robux"
        end
        selectedCategory = catKey
        local opts = getCategoryOptionsList(catKey)
        if weaponDropdownObj and opts and #opts > 0 then
            weaponDropdownObj:Refresh(opts)
            selectedWeaponName = WeaponDatabase[catKey][1].name
        end
    end
})

weaponDropdownObj = WeaponsTab:CreateDropdown({
    Name = "Pilih Senjata",
    Options = getCategoryOptionsList("Melee"),
    Callback = function(opt)
        for _, w in ipairs(WeaponDatabase[selectedCategory] or {}) do
            local label = w.robux and ("[R$] " .. w.name) or w.name
            if label == opt or w.name == opt then
                selectedWeaponName = w.name
                break
            end
        end
    end
})

WeaponsTab:CreateSection("Aksi dan Penggunaan Senjata")

WeaponsTab:CreateButton({
    Name = "Equip Senjata yang Dipilih",
    Callback = function()
        giveWeapon(selectedWeaponName, 1)
    end
})

WeaponsTab:CreateButton({
    Name = "Drop Senjata yang Sedang Dipegang",
    Callback = function()
        local char = getCharacter()
        local myRoot = getRootPart()
        if char and myRoot then
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then
                tool.Parent = workspace
                local h = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
                if h then h.CFrame = myRoot.CFrame * CFrame.new(0, 0, -4) end
                Window:Notify({ Title = "Drop Senjata", Content = tool.Name .. " dibuang ke lantai.", Duration = 2 })
            else
                Window:Notify({ Title = "Info", Content = "Kamu tidak sedang memegang senjata.", Duration = 2 })
            end
        end
    end
})

WeaponsTab:CreateButton({
    Name = "Ambil Semua Senjata di Lantai (Pickup All)",
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
        Window:Notify({ Title = "Pickup All", Content = count .. " senjata ditarik ke badanmu!", Duration = 2.5 })
    end
})

WeaponsTab:CreateSection("Status Slot Senjata (Maks 10 Slot)")

WeaponsTab:CreateButton({
    Name = "Lihat Slot Senjata Aktif",
    Callback = function()
        local char = getCharacter()
        local tools = {}
        if char then
            for _, item in ipairs(char:GetChildren()) do
                if item:IsA("Tool") then table.insert(tools, "[Pegang] " .. item.Name) end
            end
        end
        for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if item:IsA("Tool") then table.insert(tools, "[Pack] " .. item.Name) end
        end
        local msg = #tools > 0 and table.concat(tools, " | ") or "Inventory kosong."
        Window:Notify({ Title = "Slot (" .. #tools .. "/10)", Content = msg, Duration = 6 })
    end
})

WeaponsTab:CreateButton({
    Name = "Kosongkan Seluruh Inventory (Drop All)",
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
        Window:Notify({ Title = "Drop Semua", Content = count .. " senjata dibuang ke lantai.", Duration = 2 })
    end
})

-- Sistem Universal Tembak / Serang dengan Klik Kiri Mouse (100% Menembak)
-- ═══════════════════════════════════════════
--  UNIVERSAL WEAPON SHOOT & ATTACK SYSTEM
-- ═══════════════════════════════════════════
local function fireEquippedWeapon()
    local char = getCharacter()
    local tool = char and char:FindFirstChildOfClass("Tool")
    if not tool then return end

    local myRoot = getRootPart()
    local mouse = LocalPlayer:GetMouse()
    if not myRoot or not mouse then return end

    -- 1. Activate tool natively
    pcall(function() tool:Activate() end)

    -- 2. Play attack/swing/recoil animation
    pcall(function()
        local hum = getHumanoid()
        if hum then
            local animator = hum:FindFirstChildOfClass("Animator") or hum
            local anim = tool:FindFirstChildOfClass("Animation") or tool:FindFirstChild("Shoot") or tool:FindFirstChild("Fire") or tool:FindFirstChild("Slash") or tool:FindFirstChild("Attack")
            if anim and animator.LoadAnimation then
                local track = animator:LoadAnimation(anim)
                track:Play()
            else
                local fallbackAnim = Instance.new("Animation")
                fallbackAnim.AnimationId = "rbxassetid://129967390"
                local track = animator:LoadAnimation(fallbackAnim)
                track:Play()
            end
        end
    end)

    -- 3. Sound FX (Gunshot / Slash)
    pcall(function()
        local s = tool:FindFirstChildOfClass("Sound") or (tool:FindFirstChild("Handle") and tool.Handle:FindFirstChildOfClass("Sound"))
        if s then
            s:Play()
        else
            local snd = Instance.new("Sound")
            snd.SoundId = "rbxassetid://240785604"
            snd.Volume = 0.8
            snd.Parent = SoundService
            snd:Play()
            game:GetService("Debris"):AddItem(snd, 1.5)
        end
    end)

    local hitPos = mouse.Hit and mouse.Hit.Position
    local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart") or myRoot
    local origin = handle.Position

    if hitPos then
        -- 4. Visible Bullet Tracer
        pcall(function()
            local dist = (hitPos - origin).Magnitude
            if dist < 800 then
                local tracer = Instance.new("Part")
                tracer.Size = Vector3.new(0.14, 0.14, dist)
                tracer.CFrame = CFrame.lookAt((origin + hitPos) / 2, hitPos)
                tracer.Material = Enum.Material.Neon
                tracer.Color = Color3.fromRGB(255, 230, 75)
                tracer.Anchored = true
                tracer.CanCollide = false
                tracer.Parent = workspace
                task.delay(0.06, function() tracer:Destroy() end)
            end
        end)

        -- 5. Hit Detection & Server KO Kill
        pcall(function()
            local targetModel = nil
            if mouse.Target and mouse.Target.Parent and mouse.Target.Parent ~= char then
                local p = mouse.Target.Parent
                if p:FindFirstChildOfClass("Humanoid") then
                    targetModel = p
                elseif p.Parent and p.Parent:FindFirstChildOfClass("Humanoid") then
                    targetModel = p.Parent
                end
            end

            if not targetModel then
                local rayParams = RaycastParams.new()
                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                rayParams.FilterDescendantsInstances = { char }
                local dir = (hitPos - origin).Unit * 800
                local result = workspace:Raycast(origin, dir, rayParams)
                if result and result.Instance and result.Instance.Parent ~= char then
                    local p = result.Instance.Parent
                    if p:FindFirstChildOfClass("Humanoid") then
                        targetModel = p
                    elseif p.Parent and p.Parent:FindFirstChildOfClass("Humanoid") then
                        targetModel = p.Parent
                    end
                end
            end

            -- Jika mengenai dummy atau target
            if targetModel and targetModel ~= char then
                -- A) Touch interest ke handle agar script server senjata mendeteksi pukulan/tembakan dan kill tercatat di server KO
                if handle and firetouchinterest then
                    for _, bp in ipairs(targetModel:GetChildren()) do
                        if bp:IsA("BasePart") then
                            firetouchinterest(handle, bp, 0)
                            firetouchinterest(handle, bp, 1)
                        end
                    end
                end
                -- B) Hancurkan joints / instant kill
                killDummyInstantly(targetModel)
                -- C) Kirim notifikasi kill ke server
                notifyKillToServer(targetModel)
            end
        end)
    end
end

-- Bersihkan hook lama jika re-execute
if getgenv()._UNIONSAL_WEAPON_CONNS then
    for _, conn in ipairs(getgenv()._UNIONSAL_WEAPON_CONNS) do
        pcall(function() conn:Disconnect() end)
    end
end
getgenv()._UNIONSAL_WEAPON_CONNS = {}

-- Pasang hook ke Mouse.Button1Down dan UserInputService.InputBegan
pcall(function()
    local mouse = LocalPlayer:GetMouse()
    local conn1 = mouse.Button1Down:Connect(function()
        fireEquippedWeapon()
    end)
    table.insert(getgenv()._UNIONSAL_WEAPON_CONNS, conn1)

    local conn2 = UserInputService.InputBegan:Connect(function(input, gpe)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            fireEquippedWeapon()
        end
    end)
    table.insert(getgenv()._UNIONSAL_WEAPON_CONNS, conn2)
end)

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
                        local char = getCharacter()
                        local tool = char and char:FindFirstChildOfClass("Tool")
                        if tool then pcall(function() fireEquippedWeapon() end) end
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
-- ║  TAB 5: PLAYER & DEFENSE                  ║
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
-- ║  TAB 6: TELEPORT                          ║
-- ╚═══════════════════════════════════════════╝
local TpTab = Window:CreateTab("Teleport", "navigation", "Main")

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
        if type(fanCf) == "userdata" and fanCf.Position then
            tpTo(fanCf, "Kipas Raksasa")
        else
            tpTo(CFrame.new(0, 50, 0), "Kipas Raksasa")
        end
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
-- ║  TAB 7: VISUALS & ESP                     ║
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
-- ║  TAB 8: SETTINGS (CONFIG)                 ║
-- ╚═══════════════════════════════════════════╝
local SettingsTab = Window:CreateTab("Settings", "settings", "Config")
SettingsTab:CreateSection("Keybinds & Shortcut Menu")

SettingsTab:CreateKeybind({
    Name = "Tombol Buka / Tutup UI",
    CurrentKey = Window.ToggleKey or Enum.KeyCode.RightShift,
    Callback = function(newKey)
        Window.ToggleKey = newKey
        ConfigRegistry.ToggleKey = newKey.Name
        Window:Notify({ Title = "Keybind Disimpan", Content = "Tombol menu diubah ke: [" .. newKey.Name .. "]", Duration = 3 })
    end
})

SettingsTab:CreateParagraph({
    Title = "Daftar Shortcut Hyper-Realistic Ragdoll",
    Content = "• Buka/Tutup UI: Tekan tombol yang telah diatur (Default: RightShift).\n" ..
              "• Revive All Ragdoll: Tekan tombol [ R ] di keyboard.\n" ..
              "• Respawn Karakter: Tekan tombol [ G ] di keyboard.\n" ..
              "• Scan Dummy X-Ray: Tekan tombol [ V ] di keyboard.\n" ..
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
        Window:Notify({ Title = "FPS Boost", Content = v and "FPS Boost diaktifkan!" or "FPS Boost dinonaktifkan.", Duration = 2 })
    end
})

ToggleObjects.PotatoGraphics = SettingsTab:CreateToggle({
    Name = "Grafik Potato (Ultra Low Graphics / No Textures)",
    CurrentValue = false,
    Callback = function(v)
        applyPotatoGraphics(v)
        Window:Notify({ Title = "Grafik Potato", Content = v and "Grafik Potato aktif! Tekstur dihilangkan untuk FPS maksimal." or "Grafik Potato dinonaktifkan.", Duration = 3 })
    end
})

-- ╔═══════════════════════════════════════════╗
-- ║  TAB 9: CONFIGS (CONFIG)                  ║
-- ╚═══════════════════════════════════════════╝
local ConfigsTab = Window:CreateTab("Configs", "folder", "Config")
ConfigsTab:CreateSection("Discord Webhook Integration (Tersimpan Persisten)")

ConfigsTab:CreateParagraph({
    Title = "Penyimpanan Webhook",
    Content = "Pengaturan gameplay otomatis di-reset setiap kali keluar/masuk game baru. HANYA koneksi bot Webhook yang disimpan terus menerus hingga kamu memutuskan koneksinya."
})

InputObjects.WebhookUrl = ConfigsTab:CreateInput({
    Name = "Discord Webhook URL",
    PlaceholderText = "https://discord.com/api/webhooks/...",
    Callback = function(val)
        webhookUrl = string.gsub(val or "", "^%s*(.-)%s*$", "%1")
        ConfigRegistry.WebhookUrl = webhookUrl
        saveWebhookConfig()
        Window:Notify({ Title = "Webhook", Content = "URL Webhook disimpan persisten.", Duration = 2 })
    end
})

ToggleObjects.SendOnExec = ConfigsTab:CreateToggle({
    Name = "Kirim Log saat Script Dieksekusi",
    CurrentValue = true,
    Callback = function(v)
        ConfigRegistry.SendOnExec = v
        saveWebhookConfig()
    end
})

ToggleObjects.SendOnKo = ConfigsTab:CreateToggle({
    Name = "Kirim Log saat KO Dummy Berhasil",
    CurrentValue = true,
    Callback = function(v)
        ConfigRegistry.SendOnKo = v
        saveWebhookConfig()
    end
})

local function sendDiscordWebhook(embedData)
    if webhookUrl == "" or not string.find(webhookUrl, "discord%.com/api/webhooks") then
        return false
    end
    local http = syn and syn.request or http_request or request or (http and http.request)
    if not http then return false end
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
            title = "Unionsal Hub • Webhook Connected",
            description = "Webhook berhasil terhubung dengan client Roblox!",
            color = 8864235,
            fields = {
                { name = "Player", value = LocalPlayer.Name .. " (@" .. LocalPlayer.DisplayName .. ")", inline = true },
                { name = "Game", value = "Hyper-Realistic Ragdoll", inline = true },
                { name = "Place ID", value = tostring(game.PlaceId), inline = true },
                { name = "Waktu", value = os.date("%H:%M:%S - %d/%m/%Y"), inline = false }
            },
            footer = { text = "Unionsal Script Hub • .gg/unionsal" }
        }
        local success = sendDiscordWebhook(embed)
        if success then
            Window:Notify({ Title = "Webhook Sukses", Content = "Pesan uji coba berhasil terkirim ke Discord!", Duration = 3 })
        else
            Window:Notify({ Title = "Webhook Gagal", Content = "Pastikan URL Discord Webhook valid.", Duration = 3 })
        end
    end
})

ConfigsTab:CreateButton({
    Name = "Putuskan Koneksi Bot / Reset Webhook",
    Callback = function()
        deleteWebhookConfig()
        Window:Notify({ Title = "Webhook Diputus", Content = "Koneksi bot webhook diputus dan file penyimpanan dihapus.", Duration = 3 })
    end
})

-- Otomatis muat webhook tersimpan saat execute
task.spawn(function()
    task.wait(0.3)
    loadWebhookConfig()
    if ConfigRegistry.SendOnExec and ConfigRegistry.WebhookUrl ~= "" then
        sendDiscordWebhook({
            title = "Unionsal Hub • Script Executed",
            description = "Player **" .. LocalPlayer.Name .. "** mengeksekusi Unionsal Hub.",
            color = 0x66FF66,
            fields = {
                { name = "Game", value = "Hyper-Realistic Ragdoll", inline = true },
                { name = "Waktu", value = os.date("%H:%M:%S"), inline = true }
            },
            footer = { text = "Unionsal Script Hub • .gg/unionsal" }
        })
    end
end)

-- ═══════════════════════════════════════════
--  NOTIFIKASI SIAP
-- ═══════════════════════════════════════════
task.wait(0.5)
Window:Notify({
    Title   = "unionsal",
    Content = "Hyper-Realistic Ragdoll v1.3 aktif! Siap digunakan.",
    Duration = 5,
})
