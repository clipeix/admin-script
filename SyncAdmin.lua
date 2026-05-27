--[[
╔═══════════════════════════════════════════════════════╗
║          SYNC ADMIN — FINAL EDITION                  ║
║   By: Sync Admin System · Mobile + PC · Delta OK     ║
╚═══════════════════════════════════════════════════════╝
  • Botao flutuante "S" discreto abre/fecha o painel
  • Painel compacto e ajustavel por botoes
  • Sem sliders arrastaveis — tudo por botoes + / -
  • Compativel com Delta Executor (Mobile)
]]

-- ============================================================
--  SERVICOS
-- ============================================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local StarterGui       = game:GetService("StarterGui")
local Lighting         = game:GetService("Lighting")
local HttpService      = game:GetService("HttpService")

local LP     = Players.LocalPlayer
local PG     = LP.PlayerGui
local Camera = workspace.CurrentCamera

-- ============================================================
--  PALETA DE CORES
-- ============================================================
local C = {
    Red       = Color3.fromRGB(220, 28,  28),
    RedHot    = Color3.fromRGB(255, 60,  60),
    RedDark   = Color3.fromRGB(110, 10,  10),
    RedGlow   = Color3.fromRGB(180, 20,  20),
    Black     = Color3.fromRGB(5,   5,   5),
    Dark      = Color3.fromRGB(12,  12,  12),
    DarkMid   = Color3.fromRGB(20,  20,  20),
    DarkCard  = Color3.fromRGB(28,  28,  28),
    DarkHov   = Color3.fromRGB(38,  38,  38),
    White     = Color3.fromRGB(255, 255, 255),
    Gray      = Color3.fromRGB(170, 170, 170),
    GrayDim   = Color3.fromRGB(90,  90,  90),
    Green     = Color3.fromRGB(50,  220, 90),
    GreenDark = Color3.fromRGB(20,  90,  40),
    Off       = Color3.fromRGB(50,  50,  50),
    Border    = Color3.fromRGB(55,  55,  55),
    Ping1     = Color3.fromRGB(50,  220, 90),
    Ping2     = Color3.fromRGB(255, 200, 50),
    Ping3     = Color3.fromRGB(220, 60,  30),
}

-- ============================================================
--  ESTADO
-- ============================================================
local State = {
    Noclip    = false,
    InfJump   = false,
    AntiVoid  = false,
    Godmode   = false,
    Invisible = false,
    ESP       = false,
    FlingAuto = false,
    Follow    = false,
    FullBright= false,
    SpeedBoost= false,
    Fling     = false,  -- fling manual girando
}

local Cfg = {
    WalkSpeed   = 16,
    JumpPower   = 50,
    FlingForce  = 700,
    DropDmg     = 60,
    AntiVoidY   = -80,
    FollowName  = "",
    FollowTgt   = nil,
    PanelW      = 300,
    PanelH      = 300,
}

-- ============================================================
--  CONEXOES & INSTANCIAS
-- ============================================================
local Conn = {}

local function killConn(key)
    if Conn[key] then
        pcall(function() Conn[key]:Disconnect() end)
        Conn[key] = nil
    end
end

local function getChar()  return LP.Character end
local function getHum()   local c=getChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function getRoot()  local c=getChar(); return c and c:FindFirstChild("HumanoidRootPart") end

local function tw(obj, props, t, sty, dir)
    return TweenService:Create(obj,
        TweenInfo.new(t or 0.18, sty or Enum.EasingStyle.Quart,
                      dir or Enum.EasingDirection.Out), props)
end

local function notify(title, msg, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "[S] "..title, Text = msg, Duration = dur or 3
        })
    end)
end

local function findPlayer(name)
    if not name or name=="" then return nil end
    local low = name:lower()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            if p.Name:lower():find(low,1,true)
            or p.DisplayName:lower():find(low,1,true) then
                return p
            end
        end
    end
end

local function nearestPlayer(maxDist)
    maxDist = maxDist or math.huge
    local r = getRoot(); if not r then return nil end
    local best, bestD = nil, maxDist
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local pr = p.Character:FindFirstChild("HumanoidRootPart")
            if pr then
                local d = (pr.Position - r.Position).Magnitude
                if d < bestD then bestD=d; best=p end
            end
        end
    end
    return best
end

local function playerInFront(maxDist)
    maxDist = maxDist or 14
    local r = getRoot(); if not r then return nil end
    local fwd = r.CFrame.LookVector
    local best, bestScore = nil, -math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local pr = p.Character:FindFirstChild("HumanoidRootPart")
            if pr then
                local diff = pr.Position - r.Position
                if diff.Magnitude <= maxDist then
                    local dot = fwd:Dot(diff.Unit)
                    if dot > 0.5 and dot > bestScore then
                        bestScore = dot; best = p
                    end
                end
            end
        end
    end
    return best
end

-- ============================================================
--  FUNCOES DE JOGO
-- ============================================================

-- NOCLIP
local function noclipStart()
    killConn("Noclip")
    Conn["Noclip"] = RunService.Stepped:Connect(function()
        if not State.Noclip then return end
        local c = getChar(); if not c then return end
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end)
    notify("Noclip","ATIVADO — atravesse tudo!",3)
end

local function noclipStop()
    killConn("Noclip")
    local c = getChar()
    if c then
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                p.CanCollide = true
            end
        end
    end
    notify("Noclip","DESATIVADO",2)
end

-- INFINITE JUMP
local function infJumpStart()
    killConn("InfJump")
    Conn["InfJump"] = UserInputService.JumpRequest:Connect(function()
        if not State.InfJump then return end
        local h = getHum()
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
    notify("Infinite Jump","ATIVADO — pule para sempre!",3)
end

local function infJumpStop()
    killConn("InfJump")
    notify("Infinite Jump","DESATIVADO",2)
end

-- ANTI-VOID
local avSafe = Vector3.new(0,50,0)

local function antiVoidStart()
    avSafe = Vector3.new(0,50,0)
    killConn("AntiVoid")
    Conn["AntiVoid"] = RunService.Heartbeat:Connect(function()
        if not State.AntiVoid then return end
        local r = getRoot(); if not r then return end
        local pos = r.Position
        if pos.Y > 8 then avSafe = pos end
        if pos.Y < Cfg.AntiVoidY then
            r.CFrame = CFrame.new(avSafe + Vector3.new(0,15,0))
            notify("Anti-Void","Queda evitada! Restaurado.",3)
        end
    end)
    notify("Anti-Void","ATIVADO — protecao maxima!",3)
end

local function antiVoidStop()
    killConn("AntiVoid")
    notify("Anti-Void","DESATIVADO",2)
end

-- GODMODE
local function godStart()
    local h = getHum(); if not h then return end
    h.MaxHealth = math.huge; h.Health = math.huge
    killConn("Godmode")
    Conn["Godmode"] = h.HealthChanged:Connect(function()
        if not State.Godmode then return end
        local hh = getHum(); if hh then hh.Health = hh.MaxHealth end
    end)
    notify("Godmode","INVENCIVEL — HP infinito!",3)
end

local function godStop()
    killConn("Godmode")
    local h = getHum()
    if h then h.MaxHealth = 100; h.Health = 100 end
    notify("Godmode","DESATIVADO",2)
end

-- WALKSPEED
local function applyWalkSpeed()
    local h = getHum()
    if h then h.WalkSpeed = Cfg.WalkSpeed end
end

-- JUMPPOWER
local function applyJumpPower()
    local h = getHum()
    if h then h.JumpPower = Cfg.JumpPower end
end

-- INVISIBILIDADE
-- Invisivel para OUTROS: muda transparencia no servidor via LocalScript
-- (client-side: o proprio jogador vê o personagem mas os outros nao)
local invisSave = {}

local function invisStart()
    invisSave = {}
    local c = getChar(); if not c then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then
            invisSave[p] = p.LocalTransparencyModifier
            p.LocalTransparencyModifier = 0  -- voce vê
        end
    end
    -- Para outros jogadores, seta Transparency (visible no server)
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then
            p.Transparency = 1
        end
    end
    killConn("Invisible")
    Conn["Invisible"] = RunService.Heartbeat:Connect(function()
        if not State.Invisible then return end
        local cc = getChar(); if not cc then return end
        for _, p in ipairs(cc:GetDescendants()) do
            if p:IsA("BasePart") then
                p.Transparency = 1
                p.LocalTransparencyModifier = 0
            end
        end
    end)
    notify("Invisivel","ATIVADO — sumiu para os outros!",3)
end

local function invisStop()
    killConn("Invisible")
    local c = getChar(); if not c then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then
            p.Transparency = 0
            p.LocalTransparencyModifier = invisSave[p] or 0
        end
    end
    invisSave = {}
    notify("Invisivel","DESATIVADO",2)
end

-- ESP
local function buildESP(plr)
    if plr == LP then return end
    local function apply(chr)
        if not chr then return end
        local old = chr:FindFirstChild("__SAESP")
        if old then old:Destroy() end
        local hl = Instance.new("Highlight")
        hl.Name = "__SAESP"
        hl.FillColor = C.Red
        hl.OutlineColor = Color3.new(1,1,1)
        hl.FillTransparency = 0.55
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = chr
        local head = chr:FindFirstChild("Head")
        if head then
            local bb = Instance.new("BillboardGui")
            bb.Name = "__SABB"
            bb.Size = UDim2.new(0,130,0,32)
            bb.StudsOffset = Vector3.new(0,3.8,0)
            bb.AlwaysOnTop = true
            bb.Parent = head
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1,0,1,0)
            lbl.BackgroundTransparency = 1
            lbl.Text = plr.Name
            lbl.TextColor3 = C.RedHot
            lbl.TextStrokeTransparency = 0
            lbl.TextSize = 13
            lbl.Font = Enum.Font.GothamBold
            lbl.Parent = bb
        end
    end
    if plr.Character then apply(plr.Character) end
    plr.CharacterAdded:Connect(function(chr)
        if State.ESP then task.wait(0.5); apply(chr) end
    end)
end

local function espStart()
    for _, p in ipairs(Players:GetPlayers()) do buildESP(p) end
    killConn("ESPAdded")
    Conn["ESPAdded"] = Players.PlayerAdded:Connect(function(p)
        if State.ESP then buildESP(p) end
    end)
    notify("ESP","ATIVADO — veja todos atraves das paredes!",3)
end

local function espStop()
    killConn("ESPAdded")
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then
            local hl = p.Character:FindFirstChild("__SAESP")
            if hl then hl:Destroy() end
            local hd = p.Character:FindFirstChild("Head")
            if hd then
                local bb = hd:FindFirstChild("__SABB")
                if bb then bb:Destroy() end
            end
        end
    end
    notify("ESP","DESATIVADO",2)
end

-- FLING MANUAL (gira no lugar rapidamente, lanca se tocar em alguem)
local flingBG, flingBV
local flingAngle = 0

local function flingManualStart()
    local root = getRoot(); if not root then return end
    if flingBG and flingBG.Parent then flingBG:Destroy() end
    if flingBV and flingBV.Parent then flingBV:Destroy() end

    flingBG = Instance.new("BodyAngularVelocity")
    flingBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    flingBG.AngularVelocity = Vector3.new(0, 80, 0) -- gira no eixo Y
    flingBG.P = 1e6
    flingBG.Parent = root

    flingBV = Instance.new("BodyVelocity")
    flingBV.MaxForce = Vector3.new(0, 0, 0) -- nao move, so gira
    flingBV.Velocity = Vector3.zero
    flingBV.P = 1000
    flingBV.Parent = root

    killConn("FlingManual")
    Conn["FlingManual"] = RunService.Heartbeat:Connect(function()
        if not State.Fling then return end
        local r = getRoot(); if not r then return end
        -- se chegar perto de alguem, lanca
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local pr = p.Character:FindFirstChild("HumanoidRootPart")
                if pr and (pr.Position - r.Position).Magnitude < 6 then
                    local bvHit = Instance.new("BodyVelocity")
                    bvHit.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                    bvHit.Velocity = (pr.Position - r.Position).Unit * Cfg.FlingForce
                                     + Vector3.new(0, Cfg.FlingForce * 0.5, 0)
                    bvHit.P = 1e6
                    bvHit.Parent = pr
                    task.delay(0.25, function()
                        if bvHit and bvHit.Parent then bvHit:Destroy() end
                    end)
                end
            end
        end
    end)
    notify("Fling","GIRANDO — chegue perto pra lancar!",3)
end

local function flingManualStop()
    killConn("FlingManual")
    if flingBG and flingBG.Parent then flingBG:Destroy() end
    if flingBV and flingBV.Parent then flingBV:Destroy() end
    flingBG = nil; flingBV = nil
    notify("Fling","DESATIVADO",2)
end

-- FLING AUTO (auto no jogador mais proximo)
local function doFlingTarget(target)
    if not target or not target.Character then return end
    local tr = target.Character:FindFirstChild("HumanoidRootPart")
    local r  = getRoot()
    if not tr or not r then return end
    local dir = (tr.Position - r.Position).Unit + Vector3.new(0, 0.8, 0)
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Velocity = dir.Unit * Cfg.FlingForce
    bv.P = 1e6
    bv.Parent = tr
    task.delay(0.3, function() if bv and bv.Parent then bv:Destroy() end end)
end

local flingAutoTimer = 0
local function flingAutoStart()
    killConn("FlingAuto")
    Conn["FlingAuto"] = RunService.Heartbeat:Connect(function(dt)
        if not State.FlingAuto then return end
        flingAutoTimer = flingAutoTimer + dt
        if flingAutoTimer < 0.35 then return end
        flingAutoTimer = 0
        local t = nearestPlayer(20)
        if t then doFlingTarget(t) end
    end)
    notify("Fling Auto","ATIVADO — auto-lanca o mais proximo!",3)
end

local function flingAutoStop()
    killConn("FlingAuto")
    flingAutoTimer = 0
    notify("Fling Auto","DESATIVADO",2)
end

-- DROP KICK — bate em quem esta na frente
local dropCooldown = false

local function doDropKick()
    if dropCooldown then notify("DropKick","Aguarde o cooldown!",2); return end
    local target = playerInFront(14)
    if not target then
        notify("DropKick","Nenhum jogador na frente!",2); return
    end
    local tr = target.Character:FindFirstChild("HumanoidRootPart")
    local th = target.Character:FindFirstChildOfClass("Humanoid")
    local r  = getRoot()
    if not tr or not r then return end

    -- Teleporta perto e aplica impulso
    r.CFrame = tr.CFrame * CFrame.new(0, 0, 1.8)
    task.wait(0.04)
    if th then th.Health = math.max(0, th.Health - Cfg.DropDmg) end

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    local cf = Camera.CFrame
    bv.Velocity = (cf.LookVector * 60) + Vector3.new(0, 60, 0)
    bv.P = 1e6
    bv.Parent = tr

    -- Efeito visual
    local ef = Instance.new("Part")
    ef.Anchored = true; ef.CanCollide = false
    ef.Size = Vector3.new(0.3,0.3,0.3)
    ef.Shape = Enum.PartType.Ball
    ef.Material = Enum.Material.Neon
    ef.Color = C.RedHot
    ef.Position = tr.Position + Vector3.new(0,1,0)
    ef.Parent = workspace
    tw(ef, {Size=Vector3.new(8,8,8), Transparency=1}, 0.45):Play()

    task.delay(0.3, function() if bv and bv.Parent then bv:Destroy() end end)
    task.delay(0.5, function() if ef and ef.Parent then ef:Destroy()  end end)

    dropCooldown = true
    task.delay(1.0, function() dropCooldown = false end)

    notify("DropKick","HIT! "..target.Name.." -"..Cfg.DropDmg.." HP",3)
end

-- FOLLOW — melhorado: CFrame direto, bem colado, offset configuravel
-- Cfg.FollowOffset = CFrame que define onde ficar em relacao ao alvo
Cfg.FollowOffset = CFrame.new(0, 0, 3.5)  -- padrao: atras do alvo

local function followStart()
    local target
    if Cfg.FollowName ~= "" then
        target = findPlayer(Cfg.FollowName)
        if not target then
            notify("Follow","Jogador '"..Cfg.FollowName.."' nao encontrado!",3)
            State.Follow = false
            return false
        end
    else
        target = nearestPlayer()
        if not target then
            notify("Follow","Nenhum jogador no servidor!",2)
            State.Follow = false
            return false
        end
    end
    Cfg.FollowTgt = target
    killConn("Follow")
    Conn["Follow"] = RunService.Heartbeat:Connect(function()
        if not State.Follow then return end
        local t = Cfg.FollowTgt
        if not t or not t.Character then return end
        local tr = t.Character:FindFirstChild("HumanoidRootPart")
        local r  = getRoot()
        if not tr or not r then return end
        local dist = (tr.Position - r.Position).Magnitude
        -- Se muito longe, teleporta de volta
        if dist > 60 then
            r.CFrame = tr.CFrame * Cfg.FollowOffset
        elseif dist > 2.5 then
            -- Move usando CFrame gradual (suave e preciso)
            local targetCF = tr.CFrame * Cfg.FollowOffset
            r.CFrame = r.CFrame:Lerp(targetCF, 0.35)
        end
    end)
    notify("Follow","Seguindo: "..target.Name,3)
    return true
end

local function followStop()
    killConn("Follow")
    Cfg.FollowTgt = nil
    notify("Follow","DESATIVADO",2)
end

-- FULLBRIGHT
local fbOrig = {}

local function fullBrightStart()
    fbOrig.Ambient        = Lighting.Ambient
    fbOrig.OutdoorAmbient = Lighting.OutdoorAmbient
    fbOrig.Brightness     = Lighting.Brightness
    Lighting.Ambient        = Color3.fromRGB(255,255,255)
    Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
    Lighting.Brightness     = 2
    for _, ef in ipairs(Lighting:GetChildren()) do
        if ef:IsA("BlurEffect") or ef:IsA("ColorCorrectionEffect")
        or ef:IsA("DepthOfFieldEffect") then ef.Enabled = false end
    end
    notify("FullBright","ATIVADO — visao noturna!",3)
end

local function fullBrightStop()
    Lighting.Ambient        = fbOrig.Ambient or Color3.fromRGB(127,127,127)
    Lighting.OutdoorAmbient = fbOrig.OutdoorAmbient or Color3.fromRGB(127,127,127)
    Lighting.Brightness     = fbOrig.Brightness or 1
    for _, ef in ipairs(Lighting:GetChildren()) do
        if ef:IsA("BlurEffect") or ef:IsA("ColorCorrectionEffect")
        or ef:IsA("DepthOfFieldEffect") then ef.Enabled = true end
    end
    notify("FullBright","DESATIVADO",2)
end

-- GOLD MODE — Deus absoluto: godmode + speedboost + infJump + antiVoid + noclip + fullbright
local State_GoldMode = false

local function goldModeStart()
    State_GoldMode = true
    -- Ativa todos os poderes
    State.Godmode = true; godStart()
    State.InfJump = true; infJumpStart()
    State.AntiVoid = true; antiVoidStart()
    State.Noclip = true; noclipStart()
    State.FullBright = true; fullBrightStart()
    -- WalkSpeed 100
    Cfg.WalkSpeed = 100; applyWalkSpeed()
    -- JumpPower 250
    Cfg.JumpPower = 250; applyJumpPower()
    -- Efeito dourado no personagem
    local c = getChar()
    if c then
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then
                p.Material = Enum.Material.Neon
                p.Color = Color3.fromRGB(255, 200, 0)
            end
        end
    end
    notify("GOLD MODE","MODO DEUS ABSOLUTO ATIVADO!",5)
end

local function goldModeStop()
    State_GoldMode = false
    State.Godmode = false; godStop()
    State.InfJump = false; infJumpStop()
    State.AntiVoid = false; antiVoidStop()
    State.Noclip = false; noclipStop()
    State.FullBright = false; fullBrightStop()
    Cfg.WalkSpeed = 16; applyWalkSpeed()
    Cfg.JumpPower = 100; applyJumpPower()
    -- Restaura aparencia
    local c = getChar()
    if c then
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then
                p.Material = Enum.Material.SmoothPlastic
                p.Color = Color3.fromRGB(163, 162, 165)
            end
        end
    end
    notify("GOLD MODE","DESATIVADO — poderes removidos",3)
end

-- SPEEDBOOST
local function speedBoostStart()
    Cfg.WalkSpeed = 80
    applyWalkSpeed()
    killConn("SpeedBoost")
    Conn["SpeedBoost"] = RunService.Heartbeat:Connect(function()
        if not State.SpeedBoost then return end
        local h = getHum()
        if h and h.WalkSpeed < 80 then h.WalkSpeed = 80 end
    end)
    notify("SpeedBoost","ATIVADO — velocidade 80!",3)
end

local function speedBoostStop()
    killConn("SpeedBoost")
    Cfg.WalkSpeed = 16
    applyWalkSpeed()
    notify("SpeedBoost","DESATIVADO",2)
end

-- RESPAWN AUTOMÁTICO ao morrer (reconectar funcoes)
LP.CharacterAdded:Connect(function()
    task.wait(0.7)
    if State.Noclip    then noclipStart()    end
    if State.InfJump   then infJumpStart()   end
    if State.AntiVoid  then antiVoidStart()  end
    if State.Godmode   then godStart()       end
    if State.Invisible then invisStart()     end
    if State.ESP       then espStart()       end
    if State.Follow    then followStart()    end
    if State.SpeedBoost then speedBoostStart() end
    if State.Fling     then flingManualStart() end
    applyWalkSpeed()
    applyJumpPower()
end)

-- ============================================================
--  UI — PAINEL SYNC ADMIN
-- ============================================================
-- Remove instancia antiga
local old = PG:FindFirstChild("SyncAdminGUI")
if old then old:Destroy() end

local sg = Instance.new("ScreenGui")
sg.Name = "SyncAdminGUI"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.DisplayOrder = 999
sg.Parent = PG

-- ============================================================
--  BOTAO FLUTUANTE "S" — discreto, arrastavel
-- ============================================================
local floatBtn = Instance.new("Frame")
floatBtn.Name = "FloatBtn"
floatBtn.Size = UDim2.new(0, 28, 0, 28)
floatBtn.Position = UDim2.new(0, 12, 0.15, 0)
floatBtn.BackgroundColor3 = C.Red
floatBtn.BorderSizePixel = 0
floatBtn.ZIndex = 50
floatBtn.BackgroundTransparency = 0.35
floatBtn.Parent = sg

local floatCorner = Instance.new("UICorner")
floatCorner.CornerRadius = UDim.new(1, 0)
floatCorner.Parent = floatBtn

local floatStroke = Instance.new("UIStroke")
floatStroke.Color = C.RedHot
floatStroke.Thickness = 1.5
floatStroke.Parent = floatBtn

local floatLabel = Instance.new("TextLabel")
floatLabel.Size = UDim2.new(1, 0, 1, 0)
floatLabel.BackgroundTransparency = 1
floatLabel.Text = "S"
floatLabel.TextColor3 = C.White
floatLabel.TextTransparency = 0.35
floatLabel.TextSize = 14
floatLabel.Font = Enum.Font.GothamBold
floatLabel.ZIndex = 51
floatLabel.Parent = floatBtn

-- Pulsar animacao no float
local function pulsarFloat()
    while floatBtn and floatBtn.Parent do
        tw(floatStroke, {Thickness = 3}, 0.7):Play()
        tw(floatBtn, {BackgroundColor3 = C.RedGlow}, 0.7):Play()
        task.wait(0.7)
        tw(floatStroke, {Thickness = 1.5}, 0.7):Play()
        tw(floatBtn, {BackgroundColor3 = C.Red}, 0.7):Play()
        task.wait(0.7)
    end
end
task.spawn(pulsarFloat)

-- ============================================================
--  PAINEL PRINCIPAL
-- ============================================================
local panelVisible = false

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.new(0, Cfg.PanelW, 0, Cfg.PanelH)
panel.Position = UDim2.new(0.5, -Cfg.PanelW/2, 0.5, -Cfg.PanelH/2)
panel.BackgroundColor3 = C.Dark
panel.BorderSizePixel = 0
panel.Visible = false
panel.ZIndex = 10
panel.ClipsDescendants = true
panel.Parent = sg

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 10)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = C.RedDark
panelStroke.Thickness = 1.5
panelStroke.Parent = panel

-- Sombra
local shadow = Instance.new("Frame")
shadow.Size = UDim2.new(1, 12, 1, 12)
shadow.Position = UDim2.new(0, -6, 0, -6)
shadow.BackgroundColor3 = Color3.fromRGB(0,0,0)
shadow.BackgroundTransparency = 0.6
shadow.BorderSizePixel = 0
shadow.ZIndex = 9
shadow.Parent = panel
Instance.new("UICorner", shadow).CornerRadius = UDim.new(0, 14)

-- ============================================================
--  HEADER
-- ============================================================
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 48)
header.BackgroundColor3 = C.RedDark
header.BorderSizePixel = 0
header.ZIndex = 11
header.Parent = panel
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 10)

-- Linha vermelha brilhante embaixo do header
local headerLine = Instance.new("Frame")
headerLine.Size = UDim2.new(1, 0, 0, 2)
headerLine.Position = UDim2.new(0, 0, 1, -2)
headerLine.BackgroundColor3 = C.RedHot
headerLine.BorderSizePixel = 0
headerLine.ZIndex = 12
headerLine.Parent = header

-- Titulo
local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(1, -80, 1, 0)
titleLbl.Position = UDim2.new(0, 14, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "⬡ SYNC ADMIN"
titleLbl.TextColor3 = C.White
titleLbl.TextSize = 16
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.ZIndex = 12
titleLbl.Parent = header

-- Versao
local verLbl = Instance.new("TextLabel")
verLbl.Size = UDim2.new(0, 60, 0, 14)
verLbl.Position = UDim2.new(0, 14, 1, -16)
verLbl.BackgroundTransparency = 1
verLbl.Text = "FINAL EDITION"
verLbl.TextColor3 = C.RedHot
verLbl.TextSize = 9
verLbl.Font = Enum.Font.GothamBold
verLbl.TextXAlignment = Enum.TextXAlignment.Left
verLbl.ZIndex = 12
verLbl.Parent = header

-- Botao fechar
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -36, 0.5, -14)
closeBtn.BackgroundColor3 = C.RedDark
closeBtn.BorderSizePixel = 0
closeBtn.Text = "✕"
closeBtn.TextColor3 = C.Gray
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.GothamBold
closeBtn.ZIndex = 13
closeBtn.Parent = header
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1, 0)

-- Botao minimizar
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 28, 0, 28)
minBtn.Position = UDim2.new(1, -68, 0.5, -14)
minBtn.BackgroundColor3 = C.DarkMid
minBtn.BorderSizePixel = 0
minBtn.Text = "—"
minBtn.TextColor3 = C.Gray
minBtn.TextSize = 14
minBtn.Font = Enum.Font.GothamBold
minBtn.ZIndex = 13
minBtn.Parent = header
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(1, 0)

-- ============================================================
--  BARRA DE INFO DO JOGADOR (PING, HP, NOME)
-- ============================================================
local infoBar = Instance.new("Frame")
infoBar.Name = "InfoBar"
infoBar.Size = UDim2.new(1, -12, 0, 42)
infoBar.Position = UDim2.new(0, 6, 0, 52)
infoBar.BackgroundColor3 = C.DarkCard
infoBar.BorderSizePixel = 0
infoBar.ZIndex = 11
infoBar.Parent = panel
Instance.new("UICorner", infoBar).CornerRadius = UDim.new(0, 7)

local infoStroke = Instance.new("UIStroke")
infoStroke.Color = C.Border
infoStroke.Thickness = 1
infoStroke.Parent = infoBar

local nameInfoLbl = Instance.new("TextLabel")
nameInfoLbl.Size = UDim2.new(0.45, 0, 1, 0)
nameInfoLbl.Position = UDim2.new(0, 10, 0, 0)
nameInfoLbl.BackgroundTransparency = 1
nameInfoLbl.Text = LP.Name
nameInfoLbl.TextColor3 = C.White
nameInfoLbl.TextSize = 11
nameInfoLbl.Font = Enum.Font.GothamBold
nameInfoLbl.TextXAlignment = Enum.TextXAlignment.Left
nameInfoLbl.ZIndex = 12
nameInfoLbl.Parent = infoBar

local pingLbl = Instance.new("TextLabel")
pingLbl.Size = UDim2.new(0.28, 0, 1, 0)
pingLbl.Position = UDim2.new(0.45, 0, 0, 0)
pingLbl.BackgroundTransparency = 1
pingLbl.Text = "Ping: ---"
pingLbl.TextColor3 = C.Ping1
pingLbl.TextSize = 11
pingLbl.Font = Enum.Font.Gotham
pingLbl.ZIndex = 12
pingLbl.Parent = infoBar

local hpLbl = Instance.new("TextLabel")
hpLbl.Size = UDim2.new(0.27, 0, 1, 0)
hpLbl.Position = UDim2.new(0.73, 0, 0, 0)
hpLbl.BackgroundTransparency = 1
hpLbl.Text = "HP: 100"
hpLbl.TextColor3 = C.Green
hpLbl.TextSize = 11
hpLbl.Font = Enum.Font.Gotham
hpLbl.ZIndex = 12
hpLbl.Parent = infoBar

-- Atualizar ping e HP a cada segundo
task.spawn(function()
    while panel and panel.Parent do
        task.wait(1)
        local stats = Players:FindFirstChild("LocalPlayer") and
                      LP:FindFirstChild("PlayerGui")
        local ok, ping = pcall(function()
            return math.floor(LP:GetNetworkPing() * 1000)
        end)
        if ok and ping then
            local col = ping < 80 and C.Ping1 or (ping < 180 and C.Ping2 or C.Ping3)
            pingLbl.TextColor3 = col
            pingLbl.Text = "Ping: "..ping.."ms"
        end
        local h = getHum()
        if h then
            local hp = math.floor(h.Health)
            local mx = math.floor(h.MaxHealth)
            if mx >= 9e14 then mx = "INF" end
            hpLbl.Text = "HP: "..(mx=="INF" and "INF" or hp.."/"..mx)
            hpLbl.TextColor3 = (type(mx)=="number" and hp < mx*0.35) and C.Ping3 or C.Green
        end
    end
end)

-- ============================================================
--  ABAS DE CATEGORIA
-- ============================================================
local tabs = {"MOVE", "COMBATE", "VISUAL", "PLAYERS", "CONFIG"}
local activeTab = "MOVE"

local tabBar = Instance.new("Frame")
tabBar.Name = "TabBar"
tabBar.Size = UDim2.new(1, 0, 0, 34)
tabBar.Position = UDim2.new(0, 0, 0, 96)
tabBar.BackgroundColor3 = C.DarkMid
tabBar.BorderSizePixel = 0
tabBar.ZIndex = 11
tabBar.Parent = panel

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Padding = UDim.new(0, 1)
tabLayout.Parent = tabBar

local tabBtns = {}
local tabFrames = {}

for i, tabName in ipairs(tabs) do
    local tb = Instance.new("TextButton")
    tb.Size = UDim2.new(1/#tabs, -1, 1, 0)
    tb.BackgroundColor3 = C.DarkMid
    tb.BorderSizePixel = 0
    tb.Text = tabName
    tb.TextColor3 = C.GrayDim
    tb.TextSize = 9
    tb.Font = Enum.Font.GothamBold
    tb.LayoutOrder = i
    tb.ZIndex = 12
    tb.Parent = tabBar
    tabBtns[tabName] = tb
end

-- ============================================================
--  SCROLL AREA DO CONTEUDO
-- ============================================================
-- Container fixo que ocupa o espaco abaixo das abas
local scrollContainer = Instance.new("Frame")
scrollContainer.Name = "ScrollContainer"
scrollContainer.Size = UDim2.new(1, 0, 1, -134)
scrollContainer.Position = UDim2.new(0, 0, 0, 130)
scrollContainer.BackgroundTransparency = 1
scrollContainer.BorderSizePixel = 0
scrollContainer.ClipsDescendants = true
scrollContainer.ZIndex = 11
scrollContainer.Parent = panel

-- ScrollingFrame dentro do container — vai crescer com o conteudo
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "Scroll"
scrollFrame.Size = UDim2.new(1, 0, 1, 0)
scrollFrame.Position = UDim2.new(0, 0, 0, 0)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 4
scrollFrame.ScrollBarImageColor3 = C.Red
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 600)
-- AutomaticCanvasSize desabilitado; canvas calculado manualmente via switchTab
scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
scrollFrame.ElasticBehavior = Enum.ElasticBehavior.Always
scrollFrame.ZIndex = 11
scrollFrame.Parent = scrollContainer

-- Padding interno do scroll (sem UIListLayout no nivel do scrollFrame,
-- pois cada aba gerencia seu proprio layout internamente)
local contentPad = Instance.new("UIPadding")
contentPad.PaddingLeft   = UDim.new(0, 7)
contentPad.PaddingRight  = UDim.new(0, 10)
contentPad.PaddingTop    = UDim.new(0, 6)
contentPad.PaddingBottom = UDim.new(0, 12)
contentPad.Parent = scrollFrame

-- Sem UIListLayout no scrollFrame: cada Tab_X ocupa posicao absoluta
-- e e gerenciado individualmente (AutomaticSize.Y) para scroll correto

-- ============================================================
--  COMPONENTES DE UI REUTILIZAVEIS
-- ============================================================

-- Cria um frame de secao com titulo
local function makeSection(parentFrame, title, order)
    local sec = Instance.new("Frame")
    sec.Name = "Section_"..title
    sec.Size = UDim2.new(1, 0, 0, 24)
    sec.AutomaticSize = Enum.AutomaticSize.Y
    sec.BackgroundTransparency = 1
    sec.BorderSizePixel = 0
    sec.LayoutOrder = order
    sec.ZIndex = 12
    sec.Parent = parentFrame

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Text = "  • "..title:upper()
    lbl.TextColor3 = C.RedHot
    lbl.TextSize = 10
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 13
    lbl.Parent = sec

    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, 0, 0, 1)
    line.Position = UDim2.new(0, 0, 0, 21)
    line.BackgroundColor3 = C.RedDark
    line.BorderSizePixel = 0
    line.ZIndex = 13
    line.Parent = sec

    local innerLayout = Instance.new("UIListLayout")
    innerLayout.SortOrder = Enum.SortOrder.LayoutOrder
    innerLayout.Padding = UDim.new(0, 4)
    innerLayout.Parent = sec

    return sec
end

-- Botao TOGGLE
local function makeToggle(parent, labelText, order, onToggle)
    local row = Instance.new("Frame")
    row.Name = "Toggle_"..labelText
    row.Size = UDim2.new(1, 0, 0, 38)
    row.BackgroundColor3 = C.DarkCard
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.ZIndex = 13
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 7)

    local stroke = Instance.new("UIStroke")
    stroke.Color = C.Border
    stroke.Thickness = 1
    stroke.Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -56, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = C.Gray
    lbl.TextSize = 12
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 14
    lbl.Parent = row

    -- Track (fundo do toggle)
    local track = Instance.new("Frame")
    track.Size = UDim2.new(0, 40, 0, 20)
    track.Position = UDim2.new(1, -48, 0.5, -10)
    track.BackgroundColor3 = C.Off
    track.BorderSizePixel = 0
    track.ZIndex = 14
    track.Parent = row
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    -- Thumb (bolinha)
    local thumb = Instance.new("Frame")
    thumb.Size = UDim2.new(0, 16, 0, 16)
    thumb.Position = UDim2.new(0, 2, 0.5, -8)
    thumb.BackgroundColor3 = C.GrayDim
    thumb.BorderSizePixel = 0
    thumb.ZIndex = 15
    thumb.Parent = track
    Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)

    local active = false

    local function setToggle(val)
        active = val
        if active then
            tw(track, {BackgroundColor3 = C.Red}, 0.2):Play()
            tw(thumb, {Position = UDim2.new(0, 22, 0.5, -8), BackgroundColor3 = C.White}, 0.2):Play()
            tw(lbl,   {TextColor3 = C.White}, 0.15):Play()
            stroke.Color = C.Red
        else
            tw(track, {BackgroundColor3 = C.Off}, 0.2):Play()
            tw(thumb, {Position = UDim2.new(0, 2, 0.5, -8), BackgroundColor3 = C.GrayDim}, 0.2):Play()
            tw(lbl,   {TextColor3 = C.Gray}, 0.15):Play()
            stroke.Color = C.Border
        end
    end

    -- Botao invisivel cobrindo a linha inteira
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 16
    btn.Parent = row

    btn.MouseButton1Click:Connect(function()
        active = not active
        setToggle(active)
        onToggle(active)
    end)

    -- Hover
    btn.MouseEnter:Connect(function()
        tw(row, {BackgroundColor3 = C.DarkHov}, 0.12):Play()
    end)
    btn.MouseLeave:Connect(function()
        tw(row, {BackgroundColor3 = C.DarkCard}, 0.12):Play()
    end)

    return row, setToggle
end

-- Botao de ACAO (unico, sem toggle)
local function makeAction(parent, labelText, order, onClick)
    local btn = Instance.new("TextButton")
    btn.Name = "Action_"..labelText
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = C.RedDark
    btn.BorderSizePixel = 0
    btn.Text = labelText
    btn.TextColor3 = C.White
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.LayoutOrder = order
    btn.ZIndex = 13
    btn.AutoButtonColor = false
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)

    local stroke = Instance.new("UIStroke")
    stroke.Color = C.Red
    stroke.Thickness = 1.2
    stroke.Parent = btn

    btn.MouseButton1Click:Connect(function()
        tw(btn, {BackgroundColor3 = C.RedHot}, 0.07):Play()
        task.wait(0.07)
        tw(btn, {BackgroundColor3 = C.RedDark}, 0.15):Play()
        onClick()
    end)
    btn.MouseEnter:Connect(function()
        tw(btn, {BackgroundColor3 = C.RedGlow}, 0.12):Play()
    end)
    btn.MouseLeave:Connect(function()
        tw(btn, {BackgroundColor3 = C.RedDark}, 0.12):Play()
    end)
    return btn
end

-- Stepper (+/-) para valores numericos
local function makeStepper(parent, labelText, order, defaultVal, minVal, maxVal, step, onChange)
    local row = Instance.new("Frame")
    row.Name = "Stepper_"..labelText
    row.Size = UDim2.new(1, 0, 0, 40)
    row.BackgroundColor3 = C.DarkCard
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.ZIndex = 13
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 7)

    local stroke = Instance.new("UIStroke")
    stroke.Color = C.Border
    stroke.Thickness = 1
    stroke.Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.42, 0, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = C.Gray
    lbl.TextSize = 11
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 14
    lbl.Parent = row

    local curVal = defaultVal

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0.2, 0, 1, 0)
    valLbl.Position = UDim2.new(0.42, 0, 0, 0)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(curVal)
    valLbl.TextColor3 = C.White
    valLbl.TextSize = 13
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextXAlignment = Enum.TextXAlignment.Center
    valLbl.ZIndex = 14
    valLbl.Parent = row

    local function makeStepBtn(symbol, xPos, delta)
        local sb = Instance.new("TextButton")
        sb.Size = UDim2.new(0, 30, 0, 26)
        sb.Position = UDim2.new(xPos, 0, 0.5, -13)
        sb.BackgroundColor3 = C.DarkMid
        sb.BorderSizePixel = 0
        sb.Text = symbol
        sb.TextColor3 = C.White
        sb.TextSize = 16
        sb.Font = Enum.Font.GothamBold
        sb.ZIndex = 15
        sb.AutoButtonColor = false
        sb.Parent = row
        Instance.new("UICorner", sb).CornerRadius = UDim.new(0, 5)

        local held = false

        local function doStep()
            curVal = math.clamp(curVal + delta, minVal, maxVal)
            valLbl.Text = tostring(curVal)
            onChange(curVal)
        end

        sb.MouseButton1Click:Connect(doStep)

        -- Segurar para acelerar
        sb.MouseButton1Down:Connect(function()
            held = true
            task.spawn(function()
                task.wait(0.5)
                local count = 0
                while held do
                    task.wait(0.07)
                    doStep()
                    count = count + 1
                end
            end)
        end)
        sb.MouseButton1Up:Connect(function() held = false end)
        sb.MouseLeave:Connect(function() held = false end)

        sb.MouseEnter:Connect(function()
            tw(sb, {BackgroundColor3 = C.Red}, 0.1):Play()
        end)
        sb.MouseLeave:Connect(function()
            tw(sb, {BackgroundColor3 = C.DarkMid}, 0.1):Play()
        end)
    end

    makeStepBtn("-", 0.63, -step)
    makeStepBtn("+", 0.82, step)

    return row
end

-- Campo de texto simples
local function makeTextField(parent, placeholderText, order, onChange)
    local row = Instance.new("Frame")
    row.Name = "TextField_"..placeholderText
    row.Size = UDim2.new(1, 0, 0, 40)
    row.BackgroundColor3 = C.DarkCard
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.ZIndex = 13
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 7)

    local stroke = Instance.new("UIStroke")
    stroke.Color = C.Border
    stroke.Thickness = 1
    stroke.Parent = row

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -16, 0.75, 0)
    box.Position = UDim2.new(0, 8, 0.5, -15)
    box.BackgroundTransparency = 1
    box.Text = ""
    box.PlaceholderText = placeholderText
    box.PlaceholderColor3 = C.GrayDim
    box.TextColor3 = C.White
    box.TextSize = 12
    box.Font = Enum.Font.Gotham
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.ClearTextOnFocus = false
    box.ZIndex = 14
    box.Parent = row

    box.FocusLost:Connect(function()
        if onChange then onChange(box.Text) end
    end)

    box.Focused:Connect(function()
        stroke.Color = C.Red
    end)
    box.FocusLost:Connect(function()
        stroke.Color = C.Border
    end)

    return row, box
end

-- ============================================================
--  CONTEUDO DAS ABAS
--  Cada aba e um frame com AutomaticSize = Y para crescer
--  e permitir rolagem correta no ScrollingFrame pai
-- ============================================================
for _, tabName in ipairs(tabs) do
    local tf = Instance.new("Frame")
    tf.Name = "Tab_"..tabName
    -- Largura total, altura automatica (cresce com filhos)
    tf.Size = UDim2.new(1, 0, 0, 0)
    tf.AutomaticSize = Enum.AutomaticSize.Y
    tf.BackgroundTransparency = 1
    tf.Visible = (tabName == activeTab)
    tf.ZIndex = 12
    tf.Parent = scrollFrame

    local tfl = Instance.new("UIListLayout")
    tfl.SortOrder = Enum.SortOrder.LayoutOrder
    tfl.Padding = UDim.new(0, 5)
    tfl.Parent = tf

    tabFrames[tabName] = tf
end

-- ============================================================
--  ABA: MOVE
-- ============================================================
do
    local tf = tabFrames["MOVE"]

    local secMove = makeSection(tf, "Movimentacao", 1)
    -- dummy spacing
    local sp = Instance.new("Frame")
    sp.Size = UDim2.new(1,0,0,4); sp.BackgroundTransparency=1
    sp.LayoutOrder=2; sp.Parent=tf

    local _, setNoclip = makeToggle(tf, "Noclip — Atravessar paredes", 3, function(v)
        State.Noclip = v
        if v then noclipStart() else noclipStop() end
    end)

    local _, setInfJump = makeToggle(tf, "Infinite Jump — Pule sempre", 4, function(v)
        State.InfJump = v
        if v then infJumpStart() else infJumpStop() end
    end)

    local _, setAntiVoid = makeToggle(tf, "Anti-Void — Protecao queda", 5, function(v)
        State.AntiVoid = v
        if v then antiVoidStart() else antiVoidStop() end
    end)

    local _, setSpeedBoost = makeToggle(tf, "Speed Boost — Vel. 80", 6, function(v)
        State.SpeedBoost = v
        if v then speedBoostStart() else speedBoostStop() end
    end)

    local secCfg = makeSection(tf, "Configurar", 7)

    makeStepper(tf, "WalkSpeed", 8, 16, 1, 250, 2, function(v)
        Cfg.WalkSpeed = v; applyWalkSpeed()
    end)

    makeStepper(tf, "JumpPower", 9, 50, 50, 500, 10, function(v)
        Cfg.JumpPower = v; applyJumpPower()
    end)

    local secAct = makeSection(tf, "Acoes rapidas", 10)

    makeAction(tf, "Teleport — Jogador mais proximo", 11, function()
        local t = nearestPlayer()
        if t and t.Character then
            local tr = t.Character:FindFirstChild("HumanoidRootPart")
            local r  = getRoot()
            if tr and r then
                r.CFrame = tr.CFrame * CFrame.new(0,0,3.5)
                notify("Teleport","Teleportado para "..t.Name,3)
            end
        else notify("Teleport","Nenhum jogador encontrado!",2) end
    end)

    makeAction(tf, "Rejoin — Reconectar servidor", 12, function()
        local TS = game:GetService("TeleportService")
        TS:Teleport(game.PlaceId, LP)
    end)

    makeAction(tf, "Reset — Resetar personagem", 13, function()
        local h = getHum()
        if h then h.Health = 0 end
        notify("Reset","Personagem resetado!",2)
    end)
end

-- ============================================================
--  ABA: COMBATE
-- ============================================================
do
    local tf = tabFrames["COMBATE"]

    local secFling = makeSection(tf, "Fling", 1)

    local _, setFling = makeToggle(tf, "Fling — Girar e lancar ao toque", 2, function(v)
        State.Fling = v
        if v then flingManualStart() else flingManualStop() end
    end)

    local _, setFlingAuto = makeToggle(tf, "Fling Auto — Atacar o mais proximo", 3, function(v)
        State.FlingAuto = v
        if v then flingAutoStart() else flingAutoStop() end
    end)

    makeStepper(tf, "Forca Fling", 4, 700, 100, 3000, 100, function(v)
        Cfg.FlingForce = v
    end)

    local secKick = makeSection(tf, "Drop Kick", 5)

    makeAction(tf, "Drop Kick — Chutar quem esta na frente", 6, function()
        doDropKick()
    end)

    makeStepper(tf, "Dano DropKick", 7, 60, 5, 500, 5, function(v)
        Cfg.DropDmg = v
    end)

    local secGod = makeSection(tf, "Deus Modo", 8)

    -- GOLD MODE: toggle especial com cor dourada
    do
        local goldRow = Instance.new("Frame")
        goldRow.Name = "GoldModeRow"
        goldRow.Size = UDim2.new(1, 0, 0, 44)
        goldRow.BackgroundColor3 = Color3.fromRGB(30, 22, 0)
        goldRow.BorderSizePixel = 0
        goldRow.LayoutOrder = 9
        goldRow.ZIndex = 13
        goldRow.Parent = tf
        Instance.new("UICorner", goldRow).CornerRadius = UDim.new(0, 7)

        local goldStroke = Instance.new("UIStroke")
        goldStroke.Color = Color3.fromRGB(180, 140, 0)
        goldStroke.Thickness = 1.5
        goldStroke.Parent = goldRow

        local goldLbl = Instance.new("TextLabel")
        goldLbl.Size = UDim2.new(1, -56, 1, 0)
        goldLbl.Position = UDim2.new(0, 12, 0, 0)
        goldLbl.BackgroundTransparency = 1
        goldLbl.Text = "GOLD MODE — Deus Absoluto"
        goldLbl.TextColor3 = Color3.fromRGB(255, 210, 0)
        goldLbl.TextSize = 12
        goldLbl.Font = Enum.Font.GothamBold
        goldLbl.TextXAlignment = Enum.TextXAlignment.Left
        goldLbl.ZIndex = 14
        goldLbl.Parent = goldRow

        local goldTrack = Instance.new("Frame")
        goldTrack.Size = UDim2.new(0, 40, 0, 20)
        goldTrack.Position = UDim2.new(1, -48, 0.5, -10)
        goldTrack.BackgroundColor3 = C.Off
        goldTrack.BorderSizePixel = 0
        goldTrack.ZIndex = 14
        goldTrack.Parent = goldRow
        Instance.new("UICorner", goldTrack).CornerRadius = UDim.new(1, 0)

        local goldThumb = Instance.new("Frame")
        goldThumb.Size = UDim2.new(0, 16, 0, 16)
        goldThumb.Position = UDim2.new(0, 2, 0.5, -8)
        goldThumb.BackgroundColor3 = C.GrayDim
        goldThumb.BorderSizePixel = 0
        goldThumb.ZIndex = 15
        goldThumb.Parent = goldTrack
        Instance.new("UICorner", goldThumb).CornerRadius = UDim.new(1, 0)

        local goldActive = false
        local goldBtn = Instance.new("TextButton")
        goldBtn.Size = UDim2.new(1, 0, 1, 0)
        goldBtn.BackgroundTransparency = 1
        goldBtn.Text = ""
        goldBtn.ZIndex = 16
        goldBtn.Parent = goldRow

        goldBtn.MouseButton1Click:Connect(function()
            goldActive = not goldActive
            if goldActive then
                tw(goldTrack, {BackgroundColor3 = Color3.fromRGB(180,140,0)}, 0.2):Play()
                tw(goldThumb, {Position = UDim2.new(0,22,0.5,-8), BackgroundColor3 = Color3.fromRGB(255,215,0)}, 0.2):Play()
                goldStroke.Color = Color3.fromRGB(255, 215, 0)
                goldModeStart()
            else
                tw(goldTrack, {BackgroundColor3 = C.Off}, 0.2):Play()
                tw(goldThumb, {Position = UDim2.new(0,2,0.5,-8), BackgroundColor3 = C.GrayDim}, 0.2):Play()
                goldStroke.Color = Color3.fromRGB(180, 140, 0)
                goldModeStop()
            end
        end)
    end

    local _, setGodmode = makeToggle(tf, "Godmode — HP Infinito", 10, function(v)
        State.Godmode = v
        if v then godStart() else godStop() end
    end)

    makeAction(tf, "Kill — Matar o mais proximo", 10, function()
        local t = nearestPlayer(20)
        if t and t.Character then
            local h = t.Character:FindFirstChildOfClass("Humanoid")
            if h then h.Health = 0; notify("Kill","Matou "..t.Name,3) end
        else notify("Kill","Nenhum jogador perto!",2) end
    end)
end

-- ============================================================
--  ABA: VISUAL
-- ============================================================
do
    local tf = tabFrames["VISUAL"]

    local secVis = makeSection(tf, "Visibilidade", 1)

    local _, setInvis = makeToggle(tf, "Invisivel — Sumam dos outros", 2, function(v)
        State.Invisible = v
        if v then invisStart() else invisStop() end
    end)

    local _, setESP = makeToggle(tf, "ESP — Ver jogadores (wallhack)", 3, function(v)
        State.ESP = v
        if v then espStart() else espStop() end
    end)

    local _, setFB = makeToggle(tf, "FullBright — Iluminacao maxima", 4, function(v)
        State.FullBright = v
        if v then fullBrightStart() else fullBrightStop() end
    end)

    local secPlayers = makeSection(tf, "Lista de Jogadores", 5)

    local playersListFrame = Instance.new("Frame")
    playersListFrame.Name = "PlayerList"
    playersListFrame.Size = UDim2.new(1, 0, 0, 10)
    playersListFrame.AutomaticSize = Enum.AutomaticSize.Y
    playersListFrame.BackgroundTransparency = 1
    playersListFrame.BorderSizePixel = 0
    playersListFrame.LayoutOrder = 6
    playersListFrame.ZIndex = 13
    playersListFrame.Parent = tf

    local pll = Instance.new("UIListLayout")
    pll.SortOrder = Enum.SortOrder.LayoutOrder
    pll.Padding = UDim.new(0, 3)
    pll.Parent = playersListFrame

    local function refreshPlayerList()
        for _, c in ipairs(playersListFrame:GetChildren()) do
            if not c:IsA("UIListLayout") then c:Destroy() end
        end
        for i, p in ipairs(Players:GetPlayers()) do
            local pf = Instance.new("Frame")
            pf.Size = UDim2.new(1,0,0,30)
            pf.BackgroundColor3 = C.DarkCard
            pf.BorderSizePixel = 0
            pf.LayoutOrder = i
            pf.ZIndex = 14
            pf.Parent = playersListFrame
            Instance.new("UICorner",pf).CornerRadius = UDim.new(0,6)

            local nl = Instance.new("TextLabel")
            nl.Size = UDim2.new(0.6,0,1,0)
            nl.Position = UDim2.new(0,8,0,0)
            nl.BackgroundTransparency = 1
            nl.Text = (p == LP and "[EU] " or "")..p.Name
            nl.TextColor3 = (p == LP) and C.RedHot or C.Gray
            nl.TextSize = 11
            nl.Font = Enum.Font.Gotham
            nl.TextXAlignment = Enum.TextXAlignment.Left
            nl.ZIndex = 15
            nl.Parent = pf

            if p ~= LP then
                local tpBtn = Instance.new("TextButton")
                tpBtn.Size = UDim2.new(0,28,0,22)
                tpBtn.Position = UDim2.new(1,-32,0.5,-11)
                tpBtn.BackgroundColor3 = C.RedDark
                tpBtn.BorderSizePixel = 0
                tpBtn.Text = "TP"
                tpBtn.TextColor3 = C.White
                tpBtn.TextSize = 9
                tpBtn.Font = Enum.Font.GothamBold
                tpBtn.ZIndex = 16
                tpBtn.Parent = pf
                Instance.new("UICorner",tpBtn).CornerRadius = UDim.new(0,4)
                tpBtn.MouseButton1Click:Connect(function()
                    if p.Character then
                        local pr = p.Character:FindFirstChild("HumanoidRootPart")
                        local r  = getRoot()
                        if pr and r then
                            r.CFrame = pr.CFrame * CFrame.new(0,0,3.5)
                            notify("TP","Teleportado para "..p.Name,2)
                        end
                    end
                end)
            end
        end
    end

    refreshPlayerList()
    Players.PlayerAdded:Connect(function() task.wait(1); refreshPlayerList() end)
    Players.PlayerRemoving:Connect(function() task.wait(0.5); refreshPlayerList() end)

    makeAction(tf, "Atualizar lista", 7, function()
        refreshPlayerList()
        notify("Lista","Lista atualizada!",2)
    end)
end

-- ============================================================
--  ABA: PLAYERS — Card de jogador + posicionamento + follow
-- ============================================================
do
    local tf = tabFrames["PLAYERS"]

    -- ── BUSCA DE JOGADOR ──────────────────────────────────────
    local secSearch = makeSection(tf, "Buscar Jogador", 1)

    -- Campo de texto nome/ID
    local _, searchBox = makeTextField(tf, "Nome ou ID do jogador", 2, nil)

    -- Card do jogador (aparece apos busca)
    local playerCard = Instance.new("Frame")
    playerCard.Name = "PlayerCard"
    playerCard.Size = UDim2.new(1, 0, 0, 72)
    playerCard.BackgroundColor3 = C.DarkCard
    playerCard.BorderSizePixel = 0
    playerCard.LayoutOrder = 3
    playerCard.ZIndex = 13
    playerCard.Visible = false
    playerCard.Parent = tf
    Instance.new("UICorner", playerCard).CornerRadius = UDim.new(0, 8)

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = C.Border
    cardStroke.Thickness = 1.2
    cardStroke.Parent = playerCard

    -- Avatar (ImageLabel)
    local avatarImg = Instance.new("ImageLabel")
    avatarImg.Size = UDim2.new(0, 56, 0, 56)
    avatarImg.Position = UDim2.new(0, 8, 0.5, -28)
    avatarImg.BackgroundColor3 = C.DarkMid
    avatarImg.BorderSizePixel = 0
    avatarImg.Image = ""
    avatarImg.ZIndex = 14
    avatarImg.Parent = playerCard
    Instance.new("UICorner", avatarImg).CornerRadius = UDim.new(1, 0)

    local cardNameLbl = Instance.new("TextLabel")
    cardNameLbl.Size = UDim2.new(1, -76, 0, 20)
    cardNameLbl.Position = UDim2.new(0, 72, 0, 8)
    cardNameLbl.BackgroundTransparency = 1
    cardNameLbl.Text = ""
    cardNameLbl.TextColor3 = C.White
    cardNameLbl.TextSize = 13
    cardNameLbl.Font = Enum.Font.GothamBold
    cardNameLbl.TextXAlignment = Enum.TextXAlignment.Left
    cardNameLbl.ZIndex = 14
    cardNameLbl.Parent = playerCard

    local cardDisplayLbl = Instance.new("TextLabel")
    cardDisplayLbl.Size = UDim2.new(1, -76, 0, 16)
    cardDisplayLbl.Position = UDim2.new(0, 72, 0, 28)
    cardDisplayLbl.BackgroundTransparency = 1
    cardDisplayLbl.Text = ""
    cardDisplayLbl.TextColor3 = C.Gray
    cardDisplayLbl.TextSize = 10
    cardDisplayLbl.Font = Enum.Font.Gotham
    cardDisplayLbl.TextXAlignment = Enum.TextXAlignment.Left
    cardDisplayLbl.ZIndex = 14
    cardDisplayLbl.Parent = playerCard

    local cardIdLbl = Instance.new("TextLabel")
    cardIdLbl.Size = UDim2.new(1, -76, 0, 14)
    cardIdLbl.Position = UDim2.new(0, 72, 0, 46)
    cardIdLbl.BackgroundTransparency = 1
    cardIdLbl.Text = ""
    cardIdLbl.TextColor3 = C.RedHot
    cardIdLbl.TextSize = 9
    cardIdLbl.Font = Enum.Font.GothamBold
    cardIdLbl.TextXAlignment = Enum.TextXAlignment.Left
    cardIdLbl.ZIndex = 14
    cardIdLbl.Parent = playerCard

    -- Jogador selecionado atualmente no card
    local selectedPlayer = nil

    local function showPlayerCard(plr)
        selectedPlayer = plr
        cardNameLbl.Text = plr.Name
        cardDisplayLbl.Text = "@ "..plr.DisplayName
        cardIdLbl.Text = "ID: "..tostring(plr.UserId)
        -- Carrega avatar via thumbnail
        local ok, thumb = pcall(function()
            return Players:GetUserThumbnailAsync(
                plr.UserId,
                Enum.ThumbnailType.HeadShot,
                Enum.ThumbnailSize.Size100x100
            )
        end)
        avatarImg.Image = ok and thumb or "rbxassetid://0"
        cardStroke.Color = C.Red
        playerCard.Visible = true
        tw(playerCard, {BackgroundColor3 = C.DarkHov}, 0.18):Play()
        task.wait(0.2)
        tw(playerCard, {BackgroundColor3 = C.DarkCard}, 0.18):Play()
        notify("Jogador","Selecionado: "..plr.Name,3)
    end

    local function hidePlayerCard()
        selectedPlayer = nil
        playerCard.Visible = false
        cardStroke.Color = C.Border
    end

    -- Botao buscar
    makeAction(tf, "Buscar Jogador", 4, function()
        local query = searchBox and searchBox.Text or ""
        local found = nil
        -- Tenta buscar por ID numerico
        if tonumber(query) then
            local uid = tonumber(query)
            for _, p in ipairs(Players:GetPlayers()) do
                if p.UserId == uid then found = p; break end
            end
        end
        -- Busca por nome/displayName
        if not found then found = findPlayer(query) end
        -- Busca mais proximo se vazio
        if not found and query == "" then found = nearestPlayer() end

        if found then
            showPlayerCard(found)
        else
            hidePlayerCard()
            notify("Busca","Jogador nao encontrado!",2)
        end
    end)

    -- ── POSICIONAMENTO ────────────────────────────────────────
    local secPos = makeSection(tf, "Posicionar em relacao ao alvo", 5)

    -- Tabela de offsets de posicao
    local posOptions = {
        { label = "Abracar — Na frente",   offset = CFrame.new(0, 0, 1.2) },
        { label = "Cabeca — Em cima",       offset = CFrame.new(0, 3.5, 0) },
        { label = "Ombro — Lado direito",   offset = CFrame.new(2, 1.5, 0) },
        { label = "Costas — Atras",         offset = CFrame.new(0, 0, -1.5) },
        { label = "Frente — Olhando",       offset = CFrame.new(0, 0, 3.5) },
        { label = "Colo — Na frente baixo", offset = CFrame.new(0, -1, 1) },
    }

    -- Cria botoes de posicao em grade 2 colunas
    local posGrid = Instance.new("Frame")
    posGrid.Name = "PosGrid"
    posGrid.Size = UDim2.new(1, 0, 0, 0)
    posGrid.AutomaticSize = Enum.AutomaticSize.Y
    posGrid.BackgroundTransparency = 1
    posGrid.BorderSizePixel = 0
    posGrid.LayoutOrder = 6
    posGrid.ZIndex = 13
    posGrid.Parent = tf

    local posGridLayout = Instance.new("UIGridLayout")
    posGridLayout.CellSize = UDim2.new(0.5, -4, 0, 34)
    posGridLayout.CellPadding = UDim2.new(0, 4, 0, 4)
    posGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    posGridLayout.Parent = posGrid

    for i, opt in ipairs(posOptions) do
        local pb = Instance.new("TextButton")
        pb.Size = UDim2.new(0, 1, 0, 34)  -- UIGridLayout controla o tamanho
        pb.BackgroundColor3 = C.DarkMid
        pb.BorderSizePixel = 0
        pb.Text = opt.label
        pb.TextColor3 = C.Gray
        pb.TextSize = 9
        pb.TextWrapped = true
        pb.Font = Enum.Font.GothamBold
        pb.LayoutOrder = i
        pb.ZIndex = 14
        pb.AutoButtonColor = false
        pb.Parent = posGrid
        Instance.new("UICorner", pb).CornerRadius = UDim.new(0, 6)
        Instance.new("UIStroke", pb).Color = C.Border

        pb.MouseButton1Click:Connect(function()
            local tgt = selectedPlayer
            if not tgt then tgt = nearestPlayer() end
            if not tgt or not tgt.Character then
                notify("Posicao","Selecione um jogador primeiro!",2); return
            end
            local tr = tgt.Character:FindFirstChild("HumanoidRootPart")
            local r  = getRoot()
            if tr and r then
                r.CFrame = tr.CFrame * opt.offset
                notify("Posicao", opt.label.." de "..tgt.Name, 2)
            end
            tw(pb, {BackgroundColor3 = C.Red}, 0.1):Play()
            task.wait(0.18)
            tw(pb, {BackgroundColor3 = C.DarkMid}, 0.15):Play()
        end)

        pb.MouseEnter:Connect(function()
            tw(pb, {BackgroundColor3 = C.DarkHov, TextColor3 = C.White}, 0.1):Play()
        end)
        pb.MouseLeave:Connect(function()
            tw(pb, {BackgroundColor3 = C.DarkMid, TextColor3 = C.Gray}, 0.1):Play()
        end)
    end

    -- ── FOLLOW MELHORADO ─────────────────────────────────────
    local secFollow = makeSection(tf, "Follow Preciso", 7)

    -- Opcoes de offset do follow
    local followOffsets = {
        { label = "Atras",    cf = CFrame.new(0, 0, 3.5)  },
        { label = "Frente",   cf = CFrame.new(0, 0, -3.5) },
        { label = "Lado",     cf = CFrame.new(3.5, 0, 0)  },
        { label = "Cabeca",   cf = CFrame.new(0, 3.5, 0)  },
    }

    local followOffsetGrid = Instance.new("Frame")
    followOffsetGrid.Name = "FollowOffsetGrid"
    followOffsetGrid.Size = UDim2.new(1, 0, 0, 0)
    followOffsetGrid.AutomaticSize = Enum.AutomaticSize.Y
    followOffsetGrid.BackgroundTransparency = 1
    followOffsetGrid.BorderSizePixel = 0
    followOffsetGrid.LayoutOrder = 8
    followOffsetGrid.ZIndex = 13
    followOffsetGrid.Parent = tf

    local fogLayout = Instance.new("UIGridLayout")
    fogLayout.CellSize = UDim2.new(0.25, -3, 0, 30)
    fogLayout.CellPadding = UDim2.new(0, 3, 0, 3)
    fogLayout.SortOrder = Enum.SortOrder.LayoutOrder
    fogLayout.Parent = followOffsetGrid

    local activeOffsetBtn = nil

    for i, opt in ipairs(followOffsets) do
        local ob = Instance.new("TextButton")
        ob.Size = UDim2.new(0, 1, 0, 30)
        ob.BackgroundColor3 = (i == 1) and C.RedDark or C.DarkMid
        ob.BorderSizePixel = 0
        ob.Text = opt.label
        ob.TextColor3 = (i == 1) and C.White or C.Gray
        ob.TextSize = 9
        ob.Font = Enum.Font.GothamBold
        ob.LayoutOrder = i
        ob.ZIndex = 14
        ob.AutoButtonColor = false
        ob.Parent = followOffsetGrid
        Instance.new("UICorner", ob).CornerRadius = UDim.new(0, 6)

        if i == 1 then activeOffsetBtn = ob end

        ob.MouseButton1Click:Connect(function()
            Cfg.FollowOffset = opt.cf
            -- Destaca este botao
            if activeOffsetBtn then
                tw(activeOffsetBtn, {BackgroundColor3 = C.DarkMid, TextColor3 = C.Gray}, 0.1):Play()
            end
            activeOffsetBtn = ob
            tw(ob, {BackgroundColor3 = C.RedDark, TextColor3 = C.White}, 0.1):Play()
            notify("Follow","Posicao: "..opt.label,2)
        end)
    end

    -- Campo follow por nome
    local _, followBox = makeTextField(tf, "Nome (vazio = mais proximo)", 9, function(v)
        Cfg.FollowName = v
    end)

    local followToggleRef = nil

    local _, setFollow = makeToggle(tf, "Follow — Colar no jogador", 10, function(v)
        State.Follow = v
        if v then
            -- Usa o selecionado no card se existir
            if selectedPlayer and selectedPlayer.Parent then
                Cfg.FollowName = selectedPlayer.Name
            end
            local ok = followStart()
            if not ok then
                State.Follow = false
                if setFollow then setFollow(false) end
            end
        else
            followStop()
        end
    end)
    followToggleRef = setFollow

    -- ── FERRAMENTAS DO JOGADOR ────────────────────────────────
    local secTools = makeSection(tf, "Ferramentas", 11)

    makeAction(tf, "Teleportar ate jogador", 12, function()
        local tgt = selectedPlayer
        if not tgt then
            local q = searchBox and searchBox.Text or ""
            tgt = q ~= "" and findPlayer(q) or nearestPlayer()
        end
        if tgt and tgt.Character then
            local tr = tgt.Character:FindFirstChild("HumanoidRootPart")
            local r  = getRoot()
            if tr and r then
                r.CFrame = tr.CFrame * CFrame.new(0,0,3.5)
                notify("TP","Teleportado para "..tgt.Name,3)
            end
        else notify("TP","Jogador nao encontrado!",2) end
    end)

    makeAction(tf, "Trazer ate voce", 13, function()
        local tgt = selectedPlayer
        if not tgt then
            local q = searchBox and searchBox.Text or ""
            tgt = q ~= "" and findPlayer(q) or nearestPlayer()
        end
        if tgt and tgt.Character then
            local tr = tgt.Character:FindFirstChild("HumanoidRootPart")
            local r  = getRoot()
            if tr and r then
                tr.CFrame = r.CFrame * CFrame.new(0,0,3.5)
                notify("Trazer","Trouxe "..tgt.Name.." pra voce!",3)
            end
        else notify("Trazer","Jogador nao encontrado!",2) end
    end)

    makeAction(tf, "Lancar (Fling)", 14, function()
        local tgt = selectedPlayer
        if not tgt then
            local q = searchBox and searchBox.Text or ""
            tgt = q ~= "" and findPlayer(q) or nearestPlayer(25)
        end
        if tgt then
            doFlingTarget(tgt)
            notify("Fling","Lancado: "..tgt.Name,2)
        else notify("Fling","Jogador nao encontrado!",2) end
    end)

    makeAction(tf, "Deselecionar jogador", 15, function()
        hidePlayerCard()
        notify("Card","Jogador desmarcado",2)
    end)
end

-- ============================================================
--  ABA: CONFIG
-- ============================================================
do
    local tf = tabFrames["CONFIG"]

    local secPanel = makeSection(tf, "Painel — Tamanho", 1)

    makeStepper(tf, "Largura", 2, Cfg.PanelW, 240, 480, 10, function(v)
        Cfg.PanelW = v
        panel.Size = UDim2.new(0, v, 0, Cfg.PanelH)
    end)

    makeStepper(tf, "Altura", 3, Cfg.PanelH, 260, 700, 10, function(v)
        Cfg.PanelH = v
        panel.Size = UDim2.new(0, Cfg.PanelW, 0, v)
    end)

    local secAntiVoidCfg = makeSection(tf, "Anti-Void — Limite Y", 4)

    makeStepper(tf, "Limite Y (queda)", 5, -80, -500, -20, 10, function(v)
        Cfg.AntiVoidY = v
    end)

    local secMisc = makeSection(tf, "Misc", 6)

    makeAction(tf, "Copiar posicao (console)", 7, function()
        local r = getRoot()
        if r then
            local p = r.Position
            notify("Posicao", string.format("X:%.1f Y:%.1f Z:%.1f", p.X, p.Y, p.Z), 5)
        end
    end)

    makeAction(tf, "Listar jogadores (console)", 8, function()
        local names = {}
        for _, p in ipairs(Players:GetPlayers()) do
            table.insert(names, p.Name)
        end
        notify("Jogadores", table.concat(names, ", "), 6)
    end)

    makeAction(tf, "Limpar todos os toggles", 9, function()
        -- Desativar tudo
        if State.Noclip    then State.Noclip    = false; noclipStop()    end
        if State.InfJump   then State.InfJump   = false; infJumpStop()   end
        if State.AntiVoid  then State.AntiVoid  = false; antiVoidStop()  end
        if State.Godmode   then State.Godmode   = false; godStop()       end
        if State.Invisible then State.Invisible = false; invisStop()     end
        if State.ESP       then State.ESP       = false; espStop()       end
        if State.FlingAuto then State.FlingAuto = false; flingAutoStop() end
        if State.Fling     then State.Fling     = false; flingManualStop() end
        if State.Follow    then State.Follow    = false; followStop()    end
        if State.SpeedBoost then State.SpeedBoost = false; speedBoostStop() end
        if State.FullBright then State.FullBright = false; fullBrightStop() end
        notify("Sync Admin","Todos os toggles desativados!",3)
    end)
end

-- ============================================================
--  LOGICA DAS ABAS (clique para trocar)
-- ============================================================
local function switchTab(tabName)
    activeTab = tabName
    for _, t in ipairs(tabs) do
        local tb = tabBtns[t]
        local tf = tabFrames[t]
        if t == tabName then
            tw(tb, {BackgroundColor3 = C.Red, TextColor3 = C.White}, 0.15):Play()
            tf.Visible = true
        else
            tw(tb, {BackgroundColor3 = C.DarkMid, TextColor3 = C.GrayDim}, 0.15):Play()
            tf.Visible = false
        end
    end
    -- Reseta rolagem ao topo ao mudar de aba
    scrollFrame.CanvasPosition = Vector2.new(0, 0)
    -- Aguarda layout ser calculado e forca recalculo do canvas
    task.defer(function()
        local tf = tabFrames[tabName]
        if tf then
            local layout = tf:FindFirstChildOfClass("UIListLayout")
            if layout then
                local h = layout.AbsoluteContentSize.Y + 20
                scrollFrame.CanvasSize = UDim2.new(0, 0, 0, h)
            end
        end
    end)
end

for _, tabName in ipairs(tabs) do
    tabBtns[tabName].MouseButton1Click:Connect(function()
        switchTab(tabName)
    end)
    -- Recalcula canvas quando o layout interno da aba muda (ex: lista de jogadores)
    local tf = tabFrames[tabName]
    if tf then
        local layout = tf:FindFirstChildOfClass("UIListLayout")
        if layout then
            layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                if activeTab == tabName then
                    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
                end
            end)
        end
    end
end
switchTab("MOVE")

-- ============================================================
--  ABRIR / FECHAR PAINEL
-- ============================================================
local panelMinimized = false
local panelFullH = Cfg.PanelH

local function openPanel()
    panelVisible = true
    panel.Visible = true
    panel.Size = UDim2.new(0, Cfg.PanelW, 0, 0)
    tw(panel, {Size = UDim2.new(0, Cfg.PanelW, 0, panelMinimized and 48 or Cfg.PanelH)}, 0.25):Play()
    tw(floatBtn, {BackgroundColor3 = C.RedDark}, 0.15):Play()
end

local function closePanel()
    panelVisible = false
    tw(panel, {Size = UDim2.new(0, Cfg.PanelW, 0, 0)}, 0.2):Play()
    task.delay(0.21, function()
        if not panelVisible then panel.Visible = false end
    end)
    tw(floatBtn, {BackgroundColor3 = C.Red}, 0.15):Play()
end

closeBtn.MouseButton1Click:Connect(closePanel)

minBtn.MouseButton1Click:Connect(function()
    panelMinimized = not panelMinimized
    if panelMinimized then
        panelFullH = Cfg.PanelH
        tw(panel, {Size = UDim2.new(0, Cfg.PanelW, 0, 48)}, 0.2):Play()
        scrollFrame.Visible = false
        tabBar.Visible = false
        infoBar.Visible = false
        minBtn.Text = "□"
    else
        Cfg.PanelH = panelFullH
        tw(panel, {Size = UDim2.new(0, Cfg.PanelW, 0, panelFullH)}, 0.22):Play()
        scrollFrame.Visible = true
        tabBar.Visible = true
        infoBar.Visible = true
        minBtn.Text = "—"
    end
end)

-- ============================================================
--  DRAG DO PAINEL (Mouse + Touch)
-- ============================================================
local draggingPanel = false
local dragStartPos, dragStartPanelPos

local function getDragPos(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        return input.Position
    end
end

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        draggingPanel = true
        dragStartPos = input.Position
        dragStartPanelPos = panel.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if draggingPanel and
       (input.UserInputType == Enum.UserInputType.MouseMovement
       or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStartPos
        local newX = dragStartPanelPos.X.Offset + delta.X
        local newY = dragStartPanelPos.Y.Offset + delta.Y
        panel.Position = UDim2.new(
            dragStartPanelPos.X.Scale, newX,
            dragStartPanelPos.Y.Scale, newY
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        draggingPanel = false
    end
end)

-- ABRIR/FECHAR AO CLICAR
floatBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if panelVisible then closePanel() else openPanel() end
    end
end)

-- ============================================================
--  NOTIFICACAO DE BOAS-VINDAS
-- ============================================================
task.spawn(function()
    task.wait(1.5)
    notify("Sync Admin","FINAL EDITION carregado! Toque no S para abrir.",5)
end)
