--[[
╔══════════════════════════════════════════════════════════════════╗
║              SYNC ADMIN  v4.0  ULTRA GOD EDITION               ║
║        Botão Discreto · Categorias · Fly Corrigido             ║
║     Invis · Fling · DropKick · Follow · ESP · AntiVoid         ║
╚══════════════════════════════════════════════════════════════════╝
    Execute com qualquer executor Roblox compatível com LocalScripts.
    Testado: Synapse X, KRNL, Fluxus, Script-Ware, Electron.
--]]

-- ══════════════════════════════════════════════════════════════════
--  SERVIÇOS
-- ══════════════════════════════════════════════════════════════════
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local StarterGui       = game:GetService("StarterGui")
local Lighting         = game:GetService("Lighting")
local TeleportService  = game:GetService("TeleportService")

local Player = Players.LocalPlayer
local Mouse  = Player:GetMouse()
local Camera = workspace.CurrentCamera

-- ══════════════════════════════════════════════════════════════════
--  PALETA DE CORES
-- ══════════════════════════════════════════════════════════════════
local C = {
    Red        = Color3.fromRGB(220, 28, 28),
    RedHot     = Color3.fromRGB(255, 60, 60),
    RedDark    = Color3.fromRGB(120, 12, 12),
    Black      = Color3.fromRGB(8,   8,  8),
    Dark       = Color3.fromRGB(16, 16, 16),
    DarkMid    = Color3.fromRGB(24, 24, 24),
    DarkCard   = Color3.fromRGB(32, 32, 32),
    DarkHover  = Color3.fromRGB(42, 42, 42),
    White      = Color3.fromRGB(255,255,255),
    Gray       = Color3.fromRGB(150,150,150),
    GrayDim    = Color3.fromRGB(90, 90, 90),
    Green      = Color3.fromRGB(50, 210, 80),
    Off        = Color3.fromRGB(55, 55, 55),
    Border     = Color3.fromRGB(48, 48, 48),
}

-- ══════════════════════════════════════════════════════════════════
--  ESTADOS DOS TOGGLES
-- ══════════════════════════════════════════════════════════════════
local State = {
    Fly          = false,
    Noclip       = false,
    InfJump      = false,
    AntiVoid     = false,
    Godmode      = false,
    Invisible    = false,
    ESP          = false,
    Fling        = false,
    Follow       = false,
    ClickTP      = false,
    FullBright   = false,
    Rainbow      = false,
    AntiKick     = false,
    SpeedBoost   = false,
}

-- ══════════════════════════════════════════════════════════════════
--  CONFIGURAÇÕES
-- ══════════════════════════════════════════════════════════════════
local Cfg = {
    FlySpeed      = 80,
    WalkSpeed     = 16,
    JumpPower     = 100,
    FlingForce    = 600,     -- força direta aplicada
    DropDmg       = 50,
    FollowName    = "",
    FollowTarget  = nil,
    AntiVoidY     = -80,
}

-- ══════════════════════════════════════════════════════════════════
--  CONEXÕES (para poder desligar tudo limpo)
-- ══════════════════════════════════════════════════════════════════
local Conn = {}

-- ══════════════════════════════════════════════════════════════════
--  UTILITÁRIOS BÁSICOS
-- ══════════════════════════════════════════════════════════════════
local function getChar()
    return Player.Character
end

local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function tw(obj, props, t, sty, dir)
    return TweenService:Create(
        obj,
        TweenInfo.new(t or 0.22, sty or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
        props
    )
end

local function notify(title, msg, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title    = "[S] " .. title,
            Text     = msg,
            Duration = dur or 3,
        })
    end)
end

local function findPlayer(name)
    if name == "" then return nil end
    local low = name:lower()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player then
            if p.Name:lower():find(low, 1, true)
            or p.DisplayName:lower():find(low, 1, true) then
                return p
            end
        end
    end
    return nil
end

local function killConn(key)
    if Conn[key] then
        pcall(function() Conn[key]:Disconnect() end)
        Conn[key] = nil
    end
end

-- ══════════════════════════════════════════════════════════════════
--  ── FLY (TOTALMENTE REESCRITO) ────────────────────────────────
--  Usa BodyGyro + BodyVelocity com valores altos de força.
--  Lê a câmera em RenderStepped para direção.
-- ══════════════════════════════════════════════════════════════════
local flyBG, flyBV

local function flyStart()
    local root = getRoot()
    local hum  = getHum()
    if not root or not hum then return end

    if flyBG and flyBG.Parent then flyBG:Destroy() end
    if flyBV and flyBV.Parent then flyBV:Destroy() end

    hum.PlatformStand = true

    flyBG             = Instance.new("BodyGyro")
    flyBG.MaxTorque   = Vector3.new(4e5, 4e5, 4e5)
    flyBG.P           = 9e4
    flyBG.D           = 1e3
    flyBG.CFrame      = root.CFrame
    flyBG.Parent      = root

    flyBV             = Instance.new("BodyVelocity")
    flyBV.MaxForce    = Vector3.new(9e9, 9e9, 9e9)
    flyBV.Velocity    = Vector3.zero
    flyBV.P           = 2e4
    flyBV.Parent      = root

    killConn("Fly")
    Conn["Fly"] = RunService.RenderStepped:Connect(function()
        if not State.Fly then return end
        local r = getRoot()
        if not r then return end

        local cam  = workspace.CurrentCamera
        local cf   = cam.CFrame
        local dir  = Vector3.zero

        local UIS = UserInputService
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cf.LookVector  end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cf.LookVector  end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then
            dir = dir + Vector3.new(0, 1, 0)
        end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl)
        or UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
            dir = dir + Vector3.new(0, -1, 0)
        end

        local spd = Cfg.FlySpeed
        if UIS:IsKeyDown(Enum.KeyCode.Q) then spd = spd * 3 end

        if dir.Magnitude > 0 then
            flyBV.Velocity = dir.Unit * spd
        else
            flyBV.Velocity = Vector3.zero
        end

        flyBG.CFrame = cf
    end)

    notify("Fly", "ATIVADO  WASD mover | Space subir | Ctrl/Shift descer | Q turbo", 4)
end

local function flyStop()
    killConn("Fly")
    if flyBG and flyBG.Parent then flyBG:Destroy() end
    if flyBV and flyBV.Parent then flyBV:Destroy() end
    flyBG, flyBV = nil, nil
    local h = getHum()
    if h then h.PlatformStand = false end
    notify("Fly", "DESATIVADO", 2)
end

-- ══════════════════════════════════════════════════════════════════
--  ── NOCLIP ───────────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════
local function noclipStart()
    killConn("Noclip")
    Conn["Noclip"] = RunService.Stepped:Connect(function()
        if not State.Noclip then return end
        local c = getChar()
        if not c then return end
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end)
    notify("Noclip", "ATIVADO — atravesse qualquer coisa", 3)
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
    notify("Noclip", "DESATIVADO", 2)
end

-- ══════════════════════════════════════════════════════════════════
--  ── INFINITE JUMP ────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════
local function infJumpStart()
    killConn("InfJump")
    Conn["InfJump"] = UserInputService.JumpRequest:Connect(function()
        if not State.InfJump then return end
        local h = getHum()
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
    notify("Infinite Jump", "ATIVADO", 2)
end

local function infJumpStop()
    killConn("InfJump")
    notify("Infinite Jump", "DESATIVADO", 2)
end

-- ══════════════════════════════════════════════════════════════════
--  ── ANTI-VOID ────────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════
local avSafe = Vector3.new(0, 50, 0)

local function antiVoidStart()
    killConn("AntiVoid")
    Conn["AntiVoid"] = RunService.Heartbeat:Connect(function()
        if not State.AntiVoid then return end
        local r = getRoot()
        if not r then return end
        local pos = r.Position
        if pos.Y > 5 then
            avSafe = pos
        end
        if pos.Y < Cfg.AntiVoidY then
            r.CFrame = CFrame.new(avSafe + Vector3.new(0, 10, 0))
            notify("Anti-Void", "Salvo! Posicao restaurada.", 2)
        end
    end)
    notify("Anti-Void", "ATIVADO — proteção máxima ativa", 3)
end

local function antiVoidStop()
    killConn("AntiVoid")
    notify("Anti-Void", "DESATIVADO", 2)
end

-- ══════════════════════════════════════════════════════════════════
--  ── GODMODE ──────────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════
local function godStart()
    local h = getHum()
    if not h then return end
    h.MaxHealth = math.huge
    h.Health    = math.huge
    killConn("Godmode")
    Conn["Godmode"] = h.HealthChanged:Connect(function()
        if not State.Godmode then return end
        local hh = getHum()
        if hh then hh.Health = hh.MaxHealth end
    end)
    notify("Godmode", "ATIVADO — HP Infinito (client-side)", 3)
end

local function godStop()
    killConn("Godmode")
    local h = getHum()
    if h then h.MaxHealth = 100; h.Health = 100 end
    notify("Godmode", "DESATIVADO", 2)
end

-- ══════════════════════════════════════════════════════════════════
--  ── INVISIBILIDADE ───────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════
local invisSave = {}

local function invisStart()
    local c = getChar()
    invisSave = {}
    if c then
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") or p:IsA("Decal") then
                invisSave[p] = p.Transparency
                p.Transparency = 1
            end
        end
    end
    killConn("Invisible")
    Conn["Invisible"] = RunService.Heartbeat:Connect(function()
        if not State.Invisible then return end
        local cc = getChar()
        if not cc then return end
        for _, p in ipairs(cc:GetDescendants()) do
            if p:IsA("BasePart") or p:IsA("Decal") then
                p.Transparency = 1
            end
        end
    end)
    notify("Invisivel", "ATIVADO — você sumiu do mapa!", 3)
end

local function invisStop()
    killConn("Invisible")
    local c = getChar()
    if c then
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") or p:IsA("Decal") then
                p.Transparency = invisSave[p] or 0
            end
        end
    end
    invisSave = {}
    notify("Invisivel", "DESATIVADO — de volta ao visível", 2)
end

-- ══════════════════════════════════════════════════════════════════
--  ── ESP ──────────────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════
local function buildESP(plr)
    if plr == Player then return end
    local function apply(chr)
        if not chr then return end
        local old = chr:FindFirstChild("__SA_ESP")
        if old then old:Destroy() end

        local hl = Instance.new("Highlight")
        hl.Name                  = "__SA_ESP"
        hl.FillColor             = C.Red
        hl.OutlineColor          = Color3.new(1, 1, 1)
        hl.FillTransparency      = 0.6
        hl.OutlineTransparency   = 0
        hl.DepthMode             = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent                = chr

        local head = chr:FindFirstChild("Head")
        if head then
            local bb = Instance.new("BillboardGui")
            bb.Name         = "__SA_BB"
            bb.Size         = UDim2.new(0, 100, 0, 30)
            bb.StudsOffset  = Vector3.new(0, 3.2, 0)
            bb.AlwaysOnTop  = true
            bb.Parent       = head

            local lbl = Instance.new("TextLabel")
            lbl.Size                    = UDim2.new(1, 0, 1, 0)
            lbl.BackgroundTransparency  = 1
            lbl.Text                    = plr.Name
            lbl.TextColor3              = C.RedHot
            lbl.TextStrokeTransparency  = 0
            lbl.TextSize                = 14
            lbl.Font                    = Enum.Font.GothamBold
            lbl.Parent                  = bb
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
    notify("ESP", "ATIVADO — veja todos através das paredes", 3)
end

local function espStop()
    killConn("ESPAdded")
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then
            local hl = p.Character:FindFirstChild("__SA_ESP")
            if hl then hl:Destroy() end
            local head = p.Character:FindFirstChild("Head")
            if head then
                local bb = head:FindFirstChild("__SA_BB")
                if bb then bb:Destroy() end
            end
        end
    end
    notify("ESP", "DESATIVADO", 2)
end

-- ══════════════════════════════════════════════════════════════════
--  ── FLING ────────────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════
local function doFling(target)
    if not target or not target.Character then
        notify("Fling", "Alvo invalido!", 2); return
    end
    local tr = target.Character:FindFirstChild("HumanoidRootPart")
    local r  = getRoot()
    if not tr or not r then return end

    -- Chegar perto
    r.CFrame = tr.CFrame * CFrame.new(0, 0, 1.8)
    task.wait(0.06)

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    local camLook = workspace.CurrentCamera.CFrame.LookVector
    bv.Velocity  = (camLook + Vector3.new(0, 0.8, 0)).Unit * Cfg.FlingForce
    bv.Parent    = tr

    -- Flash visual
    local ef = Instance.new("Part")
    ef.Anchored   = true; ef.CanCollide = false
    ef.Size       = Vector3.new(0.3, 0.3, 0.3)
    ef.Shape      = Enum.PartType.Ball
    ef.Material   = Enum.Material.Neon
    ef.Color      = C.RedHot
    ef.Position   = tr.Position
    ef.Parent     = workspace
    tw(ef, {Size = Vector3.new(10, 10, 10), Transparency = 1}, 0.5):Play()

    task.delay(0.3, function() if bv and bv.Parent then bv:Destroy() end end)
    task.delay(0.5, function() if ef and ef.Parent then ef:Destroy() end end)

    notify("Fling", "Fling em " .. target.Name, 2)
end

local function flingAutoStart()
    killConn("FlingAuto")
    Conn["FlingAuto"] = RunService.Heartbeat:Connect(function()
        if not State.Fling then return end
        local r = getRoot()
        if not r then return end
        local best, bestD = nil, 25
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Player and p.Character then
                local pr = p.Character:FindFirstChild("HumanoidRootPart")
                if pr then
                    local d = (pr.Position - r.Position).Magnitude
                    if d < bestD then bestD = d; best = p end
                end
            end
        end
        if best then doFling(best) end
    end)
    notify("Fling Auto", "ATIVADO — fling em quem chegar perto", 3)
end

local function flingAutoStop()
    killConn("FlingAuto")
    notify("Fling Auto", "DESATIVADO", 2)
end

-- ══════════════════════════════════════════════════════════════════
--  ── DROP KICK ────────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════
local function doDropKick(target)
    if not target or not target.Character then
        notify("DropKick", "Alvo invalido!", 2); return
    end
    local tr = target.Character:FindFirstChild("HumanoidRootPart")
    local th = target.Character:FindFirstChildOfClass("Humanoid")
    local r  = getRoot()
    if not tr or not r then return end

    r.CFrame = tr.CFrame * CFrame.new(0, 0, 1.5)
    task.wait(0.05)

    -- Dano
    if th then th.Health = math.max(0, th.Health - Cfg.DropDmg) end

    -- Lançar
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    local camCF = workspace.CurrentCamera.CFrame
    bv.Velocity = (camCF.LookVector * 60) + Vector3.new(0, 60, 0)
    bv.Parent   = tr

    -- Efeito
    local ef = Instance.new("Part")
    ef.Anchored   = true; ef.CanCollide = false
    ef.Size       = Vector3.new(0.3, 0.3, 0.3)
    ef.Shape      = Enum.PartType.Ball
    ef.Material   = Enum.Material.Neon
    ef.Color      = C.RedHot
    ef.Position   = tr.Position + Vector3.new(0, 1, 0)
    ef.Parent     = workspace
    tw(ef, {Size = Vector3.new(8, 8, 8), Transparency = 1}, 0.4):Play()

    task.delay(0.28, function() if bv and bv.Parent then bv:Destroy() end end)
    task.delay(0.4,  function() if ef and ef.Parent then ef:Destroy() end end)

    notify("DropKick", "HIT em " .. target.Name .. "  -" .. Cfg.DropDmg .. " HP", 3)
end

-- ══════════════════════════════════════════════════════════════════
--  ── FOLLOW ───────────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════
local function followStart()
    local target
    if Cfg.FollowName ~= "" then
        target = findPlayer(Cfg.FollowName)
    else
        -- mais próximo
        local r = getRoot()
        local best, bestD = nil, math.huge
        if r then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= Player and p.Character then
                    local pr = p.Character:FindFirstChild("HumanoidRootPart")
                    if pr then
                        local d = (pr.Position - r.Position).Magnitude
                        if d < bestD then bestD = d; best = p end
                    end
                end
            end
        end
        target = best
    end

    if not target then
        notify("Follow", "Jogador nao encontrado!", 2)
        State.Follow = false
        return false
    end

    Cfg.FollowTarget = target
    killConn("Follow")
    Conn["Follow"] = RunService.Heartbeat:Connect(function()
        if not State.Follow then return end
        local t = Cfg.FollowTarget
        if not t or not t.Character then return end
        local tr = t.Character:FindFirstChild("HumanoidRootPart")
        local r  = getRoot()
        if not tr or not r then return end
        if (tr.Position - r.Position).Magnitude > 4 then
            local h = getHum()
            if h then h:MoveTo(tr.Position) end
        end
    end)

    notify("Follow", "Seguindo: " .. target.Name, 3)
    return true
end

local function followStop()
    killConn("Follow")
    Cfg.FollowTarget = nil
    notify("Follow", "DESATIVADO", 2)
end

-- ══════════════════════════════════════════════════════════════════
--  ── CLICK TP ─────────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════
local function clickTPStart()
    killConn("ClickTP")
    Conn["ClickTP"] = Mouse.Button1Down:Connect(function()
        if not State.ClickTP then return end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            local r = getRoot()
            if r and Mouse.Hit then
                r.CFrame = Mouse.Hit + Vector3.new(0, 3, 0)
            end
        end
    end)
    notify("Click TP", "ATIVADO — Ctrl+Click para teleportar", 3)
end

local function clickTPStop()
    killConn("ClickTP")
    notify("Click TP", "DESATIVADO", 2)
end

-- ══════════════════════════════════════════════════════════════════
--  ── FULLBRIGHT ───────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════
local fbOrig = {}

local function fullBrightStart()
    fbOrig.Ambient        = Lighting.Ambient
    fbOrig.OutdoorAmbient = Lighting.OutdoorAmbient
    fbOrig.Brightness     = Lighting.Brightness

    Lighting.Ambient        = Color3.fromRGB(255, 255, 255)
    Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    Lighting.Brightness     = 2

    for _, ef in ipairs(Lighting:GetChildren()) do
        if ef:IsA("BlurEffect") or ef:IsA("ColorCorrectionEffect")
        or ef:IsA("DepthOfFieldEffect") then
            ef.Enabled = false
        end
    end
    notify("FullBright", "ATIVADO — visao total", 3)
end

local function fullBrightStop()
    if fbOrig.Ambient        then Lighting.Ambient        = fbOrig.Ambient        end
    if fbOrig.OutdoorAmbient then Lighting.OutdoorAmbient = fbOrig.OutdoorAmbient end
    if fbOrig.Brightness     then Lighting.Brightness     = fbOrig.Brightness     end
    for _, ef in ipairs(Lighting:GetChildren()) do
        if ef:IsA("BlurEffect") or ef:IsA("ColorCorrectionEffect")
        or ef:IsA("DepthOfFieldEffect") then
            ef.Enabled = true
        end
    end
    notify("FullBright", "DESATIVADO", 2)
end

-- ══════════════════════════════════════════════════════════════════
--  ── RAINBOW ──────────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════
local function rainbowStart()
    local hue = 0
    killConn("Rainbow")
    Conn["Rainbow"] = RunService.Heartbeat:Connect(function(dt)
        if not State.Rainbow then return end
        hue = (hue + dt * 0.35) % 1
        local col = Color3.fromHSV(hue, 1, 1)
        local c = getChar()
        if c then
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                    p.Color = col
                end
            end
        end
    end)
    notify("Rainbow", "ATIVADO — ficou colorido!", 2)
end

local function rainbowStop()
    killConn("Rainbow")
    notify("Rainbow", "DESATIVADO", 2)
end

-- ══════════════════════════════════════════════════════════════════
--  ── ANTI-KICK (requer executor que suporte metamethods) ───────
-- ══════════════════════════════════════════════════════════════════
local function antiKickStart()
    pcall(function()
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        local orig = mt.__namecall
        mt.__namecall = newcclosure(function(self, ...)
            if self == Player and getnamecallmethod() == "Kick" then return end
            return orig(self, ...)
        end)
        setreadonly(mt, true)
    end)
    notify("Anti-Kick", "ATIVADO (requer executor compativel)", 3)
end

local function antiKickStop()
    notify("Anti-Kick", "DESATIVADO — reinicie o script para restaurar", 3)
end

-- ══════════════════════════════════════════════════════════════════
--  ── SPEED BOOST ──────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════
local function speedStart()
    local h = getHum()
    if h then h.WalkSpeed = Cfg.WalkSpeed end
    notify("Speed Boost", "WalkSpeed = " .. Cfg.WalkSpeed, 2)
end

local function speedStop()
    local h = getHum()
    if h then h.WalkSpeed = 16 end
    notify("Speed Boost", "WalkSpeed restaurado para 16", 2)
end

-- ══════════════════════════════════════════════════════════════════
--  ── TELEPORT PARA JOGADOR ────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════
local function tpToPlayer(target)
    if not target or not target.Character then
        notify("Teleport", "Jogador nao encontrado!", 2); return
    end
    local tr = target.Character:FindFirstChild("HumanoidRootPart")
    local r  = getRoot()
    if tr and r then
        r.CFrame = tr.CFrame * CFrame.new(0, 0, 3.5)
        notify("Teleport", "Teleportado para " .. target.Name, 2)
    end
end

-- ══════════════════════════════════════════════════════════════════
--  RECONECTAR APÓS RESPAWN
-- ══════════════════════════════════════════════════════════════════
Player.CharacterAdded:Connect(function(newChar)
    task.wait(1)
    local h = newChar:FindFirstChildOfClass("Humanoid")
    if h then
        h.WalkSpeed = Cfg.WalkSpeed
        h.JumpPower = Cfg.JumpPower
    end
    if State.AntiVoid   then antiVoidStart()    end
    if State.InfJump    then infJumpStart()     end
    if State.Godmode    then godStart()         end
    if State.Invisible  then invisStart()       end
    if State.Noclip     then noclipStart()      end
    if State.Fly        then flyStart()         end
    if State.FullBright then fullBrightStart()  end
    if State.Rainbow    then rainbowStart()     end
    if State.SpeedBoost then speedStart()       end
end)

-- ══════════════════════════════════════════════════════════════════
--  ══ INTERFACE GRÁFICA (UI) ════════════════════════════════════
-- ══════════════════════════════════════════════════════════════════
local function BuildUI()

    -- Limpar UI anterior
    local prev = Player.PlayerGui:FindFirstChild("SyncAdminUI")
    if prev then prev:Destroy() end

    -- ScreenGui
    local Screen = Instance.new("ScreenGui")
    Screen.Name           = "SyncAdminUI"
    Screen.ResetOnSpawn   = false
    Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    Screen.DisplayOrder   = 999
    Screen.Parent         = Player.PlayerGui

    -- ────────────────────────────────────────────────────────────
    --  BOTÃO FLUTUANTE DISCRETO
    -- ────────────────────────────────────────────────────────────
    local FBtn = Instance.new("TextButton")
    FBtn.Name             = "FloatBtn"
    FBtn.Size             = UDim2.new(0, 42, 0, 42)
    FBtn.Position         = UDim2.new(0, 18, 0.5, -21)
    FBtn.BackgroundColor3 = C.Red
    FBtn.BorderSizePixel  = 0
    FBtn.Text             = "S"
    FBtn.TextColor3       = C.White
    FBtn.TextSize         = 20
    FBtn.Font             = Enum.Font.GothamBlack
    FBtn.AutoButtonColor  = false
    FBtn.ZIndex           = 10
    FBtn.Parent           = Screen

    do
        local uc = Instance.new("UICorner")
        uc.CornerRadius = UDim.new(1, 0)
        uc.Parent       = FBtn

        local us = Instance.new("UIStroke")
        us.Color     = C.RedHot
        us.Thickness = 2
        us.Parent    = FBtn
    end

    -- Pulso suave no botão
    task.spawn(function()
        while FBtn and FBtn.Parent do
            tw(FBtn, {Size = UDim2.new(0, 48, 0, 48)}, 0.55, Enum.EasingStyle.Sine):Play()
            task.wait(0.6)
            tw(FBtn, {Size = UDim2.new(0, 42, 0, 42)}, 0.55, Enum.EasingStyle.Sine):Play()
            task.wait(0.6)
        end
    end)

    -- Arrastar botão flutuante
    do
        local drag, ds, sp = false, nil, nil
        FBtn.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                drag = true; ds = i.Position; sp = FBtn.Position
            end
        end)
        FBtn.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
                local d = i.Position - ds
                FBtn.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X,
                                           sp.Y.Scale, sp.Y.Offset + d.Y)
            end
        end)
    end

    -- ────────────────────────────────────────────────────────────
    --  PAINEL PRINCIPAL
    -- ────────────────────────────────────────────────────────────
    local Panel = Instance.new("Frame")
    Panel.Name             = "MainPanel"
    Panel.Size             = UDim2.new(0, 370, 0, 560)
    Panel.Position         = UDim2.new(0.5, -185, 0.5, -280)
    Panel.BackgroundColor3 = C.Dark
    Panel.BorderSizePixel  = 0
    Panel.ClipsDescendants = true
    Panel.Visible          = false
    Panel.ZIndex           = 5
    Panel.Parent           = Screen

    do
        local uc = Instance.new("UICorner")
        uc.CornerRadius = UDim.new(0, 12)
        uc.Parent       = Panel

        local us = Instance.new("UIStroke")
        us.Color     = C.Red
        us.Thickness = 2
        us.Parent    = Panel
    end

    local panelOpen = false
    local panelW    = 370
    local panelH    = 560
    local isMin     = false

    local function openPanel()
        panelOpen     = true
        Panel.Visible = true
        Panel.Size    = UDim2.new(0, 0, 0, 0)
        tw(Panel, {Size = UDim2.new(0, panelW, 0, panelH)}, 0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out):Play()
    end

    local function closePanel()
        panelOpen = false
        tw(Panel, {Size = UDim2.new(0, 0, 0, 0)}, 0.22):Play()
        task.delay(0.23, function() Panel.Visible = false end)
    end

    FBtn.MouseButton1Click:Connect(function()
        if panelOpen then closePanel() else openPanel() end
    end)

    -- ─── HEADER ─────────────────────────────────────────────────
    local Header = Instance.new("Frame")
    Header.Size             = UDim2.new(1, 0, 0, 54)
    Header.BackgroundColor3 = C.RedDark
    Header.BorderSizePixel  = 0
    Header.ZIndex           = 6
    Header.Parent           = Panel

    do
        local uc = Instance.new("UICorner")
        uc.CornerRadius = UDim.new(0, 12)
        uc.Parent       = Header

        -- Preencher canto inferior do header
        local fix = Instance.new("Frame")
        fix.Size             = UDim2.new(1, 0, 0, 12)
        fix.Position         = UDim2.new(0, 0, 1, -12)
        fix.BackgroundColor3 = C.RedDark
        fix.BorderSizePixel  = 0
        fix.ZIndex           = 6
        fix.Parent           = Header

        local grad = Instance.new("UIGradient")
        grad.Color    = ColorSequence.new({
            ColorSequenceKeypoint.new(0, C.RedHot),
            ColorSequenceKeypoint.new(1, C.RedDark),
        })
        grad.Rotation = 90
        grad.Parent   = Header
    end

    -- Logo S no header
    local LogoF = Instance.new("Frame")
    LogoF.Size             = UDim2.new(0, 36, 0, 36)
    LogoF.Position         = UDim2.new(0, 10, 0.5, -18)
    LogoF.BackgroundColor3 = C.Black
    LogoF.BorderSizePixel  = 0
    LogoF.ZIndex           = 7
    LogoF.Parent           = Header
    Instance.new("UICorner", LogoF).CornerRadius = UDim.new(0, 8)

    local LogoL = Instance.new("TextLabel")
    LogoL.Size                  = UDim2.new(1, 0, 1, 0)
    LogoL.BackgroundTransparency = 1
    LogoL.Text                  = "S"
    LogoL.TextColor3            = C.Red
    LogoL.TextSize              = 20
    LogoL.Font                  = Enum.Font.GothamBlack
    LogoL.ZIndex                = 8
    LogoL.Parent                = LogoF

    -- Título
    local TitleL = Instance.new("TextLabel")
    TitleL.Size                  = UDim2.new(0, 160, 0, 22)
    TitleL.Position              = UDim2.new(0, 54, 0, 7)
    TitleL.BackgroundTransparency = 1
    TitleL.Text                  = "SYNC ADMIN"
    TitleL.TextColor3            = C.White
    TitleL.TextSize              = 18
    TitleL.Font                  = Enum.Font.GothamBlack
    TitleL.TextXAlignment        = Enum.TextXAlignment.Left
    TitleL.ZIndex                = 7
    TitleL.Parent                = Header

    local VerL = Instance.new("TextLabel")
    VerL.Size                  = UDim2.new(0, 160, 0, 13)
    VerL.Position              = UDim2.new(0, 54, 0, 30)
    VerL.BackgroundTransparency = 1
    VerL.Text                  = "v4.0  Ultra God Edition"
    VerL.TextColor3            = Color3.fromRGB(255, 200, 200)
    VerL.TextSize              = 10
    VerL.Font                  = Enum.Font.Gotham
    VerL.TextXAlignment        = Enum.TextXAlignment.Left
    VerL.ZIndex                = 7
    VerL.Parent                = Header

    -- Botões de controle do header
    local function makeHBtn(txt, bg, ox)
        local b = Instance.new("TextButton")
        b.Size             = UDim2.new(0, 26, 0, 26)
        b.Position         = UDim2.new(1, ox, 0.5, -13)
        b.BackgroundColor3 = bg
        b.BorderSizePixel  = 0
        b.Text             = txt
        b.TextColor3       = C.White
        b.TextSize         = 12
        b.Font             = Enum.Font.GothamBold
        b.AutoButtonColor  = false
        b.ZIndex           = 8
        b.Parent           = Header
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
        return b
    end

    local MinBtn   = makeHBtn("—", Color3.fromRGB(70, 70, 70), -74)
    local CloseBtn = makeHBtn("✕", Color3.fromRGB(160, 25, 25), -44)

    CloseBtn.MouseButton1Click:Connect(closePanel)

    MinBtn.MouseButton1Click:Connect(function()
        isMin = not isMin
        if isMin then
            tw(Panel, {Size = UDim2.new(0, panelW, 0, 54)}, 0.25):Play()
            MinBtn.Text = "+"
        else
            tw(Panel, {Size = UDim2.new(0, panelW, 0, panelH)}, 0.3, Enum.EasingStyle.Back):Play()
            MinBtn.Text = "—"
        end
    end)

    -- Drag do painel
    do
        local drag, ds, sp = false, nil, nil
        Header.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                drag = true; ds = i.Position; sp = Panel.Position
            end
        end)
        Header.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
                local d = i.Position - ds
                Panel.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X,
                                            sp.Y.Scale, sp.Y.Offset + d.Y)
            end
        end)
    end

    -- ─── STATUS BAR ─────────────────────────────────────────────
    local StatusF = Instance.new("Frame")
    StatusF.Size             = UDim2.new(1, -18, 0, 24)
    StatusF.Position         = UDim2.new(0, 9, 0, 60)
    StatusF.BackgroundColor3 = C.DarkCard
    StatusF.BorderSizePixel  = 0
    StatusF.ZIndex           = 6
    StatusF.Parent           = Panel
    Instance.new("UICorner", StatusF).CornerRadius = UDim.new(0, 6)

    local StatusL = Instance.new("TextLabel")
    StatusL.Size                  = UDim2.new(1, -12, 1, 0)
    StatusL.Position              = UDim2.new(0, 6, 0, 0)
    StatusL.BackgroundTransparency = 1
    StatusL.Text                  = "[ ONLINE ]  " .. Player.Name .. "  |  God Mode Ready"
    StatusL.TextColor3            = C.Green
    StatusL.TextSize              = 10
    StatusL.Font                  = Enum.Font.GothamSemibold
    StatusL.TextXAlignment        = Enum.TextXAlignment.Left
    StatusL.ZIndex                = 7
    StatusL.Parent                = StatusF

    -- ─── TABBAR ─────────────────────────────────────────────────
    local TabBar = Instance.new("Frame")
    TabBar.Size             = UDim2.new(1, -18, 0, 30)
    TabBar.Position         = UDim2.new(0, 9, 0, 90)
    TabBar.BackgroundColor3 = C.DarkMid
    TabBar.BorderSizePixel  = 0
    TabBar.ClipsDescendants = true
    TabBar.ZIndex           = 6
    TabBar.Parent           = Panel
    Instance.new("UICorner", TabBar).CornerRadius = UDim.new(0, 8)

    local TBLayout = Instance.new("UIListLayout")
    TBLayout.FillDirection       = Enum.FillDirection.Horizontal
    TBLayout.SortOrder           = Enum.SortOrder.LayoutOrder
    TBLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    TBLayout.Padding             = UDim.new(0, 3)
    TBLayout.Parent              = TabBar

    local TBPad = Instance.new("UIPadding")
    TBPad.PaddingLeft   = UDim.new(0, 3)
    TBPad.PaddingRight  = UDim.new(0, 3)
    TBPad.PaddingTop    = UDim.new(0, 4)
    TBPad.PaddingBottom = UDim.new(0, 4)
    TBPad.Parent        = TabBar

    -- ─── SCROLL ─────────────────────────────────────────────────
    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Size                  = UDim2.new(1, -18, 1, -136)
    Scroll.Position              = UDim2.new(0, 9, 0, 128)
    Scroll.BackgroundTransparency = 1
    Scroll.BorderSizePixel       = 0
    Scroll.ScrollBarThickness    = 3
    Scroll.ScrollBarImageColor3  = C.Red
    Scroll.CanvasSize            = UDim2.new(0, 0, 0, 0)
    Scroll.AutomaticCanvasSize   = Enum.AutomaticSize.Y
    Scroll.ZIndex                = 6
    Scroll.Parent                = Panel

    local SLayout = Instance.new("UIListLayout")
    SLayout.SortOrder = Enum.SortOrder.LayoutOrder
    SLayout.Padding   = UDim.new(0, 5)
    SLayout.Parent    = Scroll

    local SPad = Instance.new("UIPadding")
    SPad.PaddingTop    = UDim.new(0, 4)
    SPad.PaddingBottom = UDim.new(0, 12)
    SPad.Parent        = Scroll

    -- ════════════════════════════════════════════════════════════
    --  HELPERS DE CRIAÇÃO DE WIDGETS
    -- ════════════════════════════════════════════════════════════

    -- Título de seção
    local function mkSection(label)
        local f = Instance.new("Frame")
        f.Size             = UDim2.new(1, 0, 0, 24)
        f.BackgroundColor3 = C.DarkMid
        f.BorderSizePixel  = 0
        f.ZIndex           = 7
        f.Parent           = Scroll
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 5)

        local bar = Instance.new("Frame")
        bar.Size             = UDim2.new(0, 3, 0.55, 0)
        bar.Position         = UDim2.new(0, 0, 0.22, 0)
        bar.BackgroundColor3 = C.Red
        bar.BorderSizePixel  = 0
        bar.ZIndex           = 8
        bar.Parent           = f
        Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

        local lbl = Instance.new("TextLabel")
        lbl.Size                  = UDim2.new(1, -14, 1, 0)
        lbl.Position              = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text                  = label
        lbl.TextColor3            = C.Red
        lbl.TextSize              = 11
        lbl.Font                  = Enum.Font.GothamBold
        lbl.TextXAlignment        = Enum.TextXAlignment.Left
        lbl.ZIndex                = 8
        lbl.Parent                = f
        return f
    end

    -- Toggle
    local ToggleRefs = {}

    local function mkToggle(key, label, desc, onOn, onOff)
        local f = Instance.new("Frame")
        f.Size             = UDim2.new(1, 0, 0, 50)
        f.BackgroundColor3 = C.DarkCard
        f.BorderSizePixel  = 0
        f.ZIndex           = 7
        f.Parent           = Scroll
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)

        local fStroke = Instance.new("UIStroke")
        fStroke.Color        = C.Border
        fStroke.Thickness    = 1
        fStroke.Transparency = 0.5
        fStroke.Parent       = f

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size                  = UDim2.new(0.66, 0, 0, 19)
        nameLbl.Position              = UDim2.new(0, 11, 0, 7)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text                  = label
        nameLbl.TextColor3            = C.White
        nameLbl.TextSize              = 13
        nameLbl.Font                  = Enum.Font.GothamSemibold
        nameLbl.TextXAlignment        = Enum.TextXAlignment.Left
        nameLbl.ZIndex                = 8
        nameLbl.Parent                = f

        local descLbl = Instance.new("TextLabel")
        descLbl.Size                  = UDim2.new(0.66, 0, 0, 13)
        descLbl.Position              = UDim2.new(0, 11, 0, 28)
        descLbl.BackgroundTransparency = 1
        descLbl.Text                  = desc
        descLbl.TextColor3            = C.Gray
        descLbl.TextSize              = 10
        descLbl.Font                  = Enum.Font.Gotham
        descLbl.TextXAlignment        = Enum.TextXAlignment.Left
        descLbl.ZIndex                = 8
        descLbl.Parent                = f

        -- Switch track
        local track = Instance.new("Frame")
        track.Size             = UDim2.new(0, 44, 0, 22)
        track.Position         = UDim2.new(1, -56, 0.5, -11)
        track.BackgroundColor3 = C.Off
        track.BorderSizePixel  = 0
        track.ZIndex           = 8
        track.Parent           = f
        Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

        local knob = Instance.new("Frame")
        knob.Size             = UDim2.new(0, 16, 0, 16)
        knob.Position         = UDim2.new(0, 3, 0.5, -8)
        knob.BackgroundColor3 = C.White
        knob.BorderSizePixel  = 0
        knob.ZIndex           = 9
        knob.Parent           = track
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

        local enabled = false

        local function setState(val)
            enabled     = val
            State[key]  = val
            if val then
                tw(track,   {BackgroundColor3 = C.Red}, 0.18):Play()
                tw(knob,    {Position = UDim2.new(1, -19, 0.5, -8)}, 0.18):Play()
                tw(fStroke, {Color = C.Red, Transparency = 0}, 0.18):Play()
                if onOn then onOn() end
            else
                tw(track,   {BackgroundColor3 = C.Off}, 0.18):Play()
                tw(knob,    {Position = UDim2.new(0, 3, 0.5, -8)}, 0.18):Play()
                tw(fStroke, {Color = C.Border, Transparency = 0.5}, 0.18):Play()
                if onOff then onOff() end
            end
        end

        local clickBtn = Instance.new("TextButton")
        clickBtn.Size                  = UDim2.new(1, 0, 1, 0)
        clickBtn.BackgroundTransparency = 1
        clickBtn.Text                  = ""
        clickBtn.ZIndex                = 10
        clickBtn.Parent                = f

        clickBtn.MouseButton1Click:Connect(function() setState(not enabled) end)
        clickBtn.MouseEnter:Connect(function()
            tw(f, {BackgroundColor3 = C.DarkHover}, 0.1):Play()
        end)
        clickBtn.MouseLeave:Connect(function()
            tw(f, {BackgroundColor3 = C.DarkCard}, 0.1):Play()
        end)

        ToggleRefs[key] = { set = setState, get = function() return enabled end }
        return f, setState
    end

    -- Slider
    local function mkSlider(label, min, max, default, suffix, onChange)
        local f = Instance.new("Frame")
        f.Size             = UDim2.new(1, 0, 0, 60)
        f.BackgroundColor3 = C.DarkCard
        f.BorderSizePixel  = 0
        f.ZIndex           = 7
        f.Parent           = Scroll
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)

        local fStroke = Instance.new("UIStroke")
        fStroke.Color        = C.Border
        fStroke.Thickness    = 1
        fStroke.Transparency = 0.5
        fStroke.Parent       = f

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size                  = UDim2.new(0.65, 0, 0, 19)
        nameLbl.Position              = UDim2.new(0, 11, 0, 7)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text                  = label
        nameLbl.TextColor3            = C.White
        nameLbl.TextSize              = 12
        nameLbl.Font                  = Enum.Font.GothamSemibold
        nameLbl.TextXAlignment        = Enum.TextXAlignment.Left
        nameLbl.ZIndex                = 8
        nameLbl.Parent                = f

        local valLbl = Instance.new("TextLabel")
        valLbl.Size                  = UDim2.new(0.3, 0, 0, 19)
        valLbl.Position              = UDim2.new(0.7, -11, 0, 7)
        valLbl.BackgroundTransparency = 1
        valLbl.Text                  = tostring(default) .. (suffix or "")
        valLbl.TextColor3            = C.Red
        valLbl.TextSize              = 12
        valLbl.Font                  = Enum.Font.GothamBold
        valLbl.TextXAlignment        = Enum.TextXAlignment.Right
        valLbl.ZIndex                = 8
        valLbl.Parent                = f

        local track = Instance.new("Frame")
        track.Size             = UDim2.new(1, -22, 0, 7)
        track.Position         = UDim2.new(0, 11, 0, 40)
        track.BackgroundColor3 = C.DarkMid
        track.BorderSizePixel  = 0
        track.ZIndex           = 8
        track.Parent           = f
        Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

        local pct0 = (default - min) / math.max(max - min, 1)

        local fill = Instance.new("Frame")
        fill.Size             = UDim2.new(pct0, 0, 1, 0)
        fill.BackgroundColor3 = C.Red
        fill.BorderSizePixel  = 0
        fill.ZIndex           = 9
        fill.Parent           = track
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

        local fillG = Instance.new("UIGradient")
        fillG.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, C.RedHot),
            ColorSequenceKeypoint.new(1, C.RedDark),
        })
        fillG.Parent = fill

        local knob = Instance.new("Frame")
        knob.Size             = UDim2.new(0, 14, 0, 14)
        knob.Position         = UDim2.new(pct0, -7, 0.5, -7)
        knob.BackgroundColor3 = C.White
        knob.BorderSizePixel  = 0
        knob.ZIndex           = 10
        knob.Parent           = track
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

        do
            local ks = Instance.new("UIStroke")
            ks.Color     = C.Red
            ks.Thickness = 2
            ks.Parent    = knob
        end

        local dragging = false

        local function updateSlider(inp)
            local abs = track.AbsolutePosition
            local sz  = track.AbsoluteSize
            local pct = math.clamp((inp.Position.X - abs.X) / sz.X, 0, 1)
            local val = math.floor(min + (max - min) * pct + 0.5)
            tw(fill,  {Size = UDim2.new(pct, 0, 1, 0)}, 0.04):Play()
            tw(knob,  {Position = UDim2.new(pct, -7, 0.5, -7)}, 0.04):Play()
            valLbl.Text = tostring(val) .. (suffix or "")
            if onChange then onChange(val) end
        end

        track.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true; updateSlider(i)
            end
        end)
        knob.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                updateSlider(i)
            end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)

        return f
    end

    -- Botão de ação
    local function mkButton(label, desc, btnText, cb)
        local f = Instance.new("Frame")
        f.Size             = UDim2.new(1, 0, 0, 46)
        f.BackgroundColor3 = C.DarkCard
        f.BorderSizePixel  = 0
        f.ZIndex           = 7
        f.Parent           = Scroll
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)

        local fStroke = Instance.new("UIStroke")
        fStroke.Color        = C.Border
        fStroke.Thickness    = 1
        fStroke.Transparency = 0.5
        fStroke.Parent       = f

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size                  = UDim2.new(0.6, 0, 0, 17)
        nameLbl.Position              = UDim2.new(0, 11, 0, 6)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text                  = label
        nameLbl.TextColor3            = C.White
        nameLbl.TextSize              = 12
        nameLbl.Font                  = Enum.Font.GothamSemibold
        nameLbl.TextXAlignment        = Enum.TextXAlignment.Left
        nameLbl.ZIndex                = 8
        nameLbl.Parent                = f

        local descLbl = Instance.new("TextLabel")
        descLbl.Size                  = UDim2.new(0.6, 0, 0, 12)
        descLbl.Position              = UDim2.new(0, 11, 0, 25)
        descLbl.BackgroundTransparency = 1
        descLbl.Text                  = desc
        descLbl.TextColor3            = C.Gray
        descLbl.TextSize              = 10
        descLbl.Font                  = Enum.Font.Gotham
        descLbl.TextXAlignment        = Enum.TextXAlignment.Left
        descLbl.ZIndex                = 8
        descLbl.Parent                = f

        local btn = Instance.new("TextButton")
        btn.Size             = UDim2.new(0, 78, 0, 26)
        btn.Position         = UDim2.new(1, -90, 0.5, -13)
        btn.BackgroundColor3 = C.Red
        btn.BorderSizePixel  = 0
        btn.Text             = btnText or "GO"
        btn.TextColor3       = C.White
        btn.TextSize         = 11
        btn.Font             = Enum.Font.GothamBold
        btn.AutoButtonColor  = false
        btn.ZIndex           = 9
        btn.Parent           = f
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        do
            local g = Instance.new("UIGradient")
            g.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, C.RedHot),
                ColorSequenceKeypoint.new(1, C.RedDark),
            })
            g.Rotation = 90
            g.Parent   = btn
        end

        btn.MouseButton1Click:Connect(function()
            tw(btn, {Size = UDim2.new(0, 70, 0, 22)}, 0.06):Play()
            task.wait(0.07)
            tw(btn, {Size = UDim2.new(0, 78, 0, 26)}, 0.1):Play()
            if cb then cb() end
        end)
        btn.MouseEnter:Connect(function() tw(btn, {BackgroundColor3 = C.RedHot}, 0.1):Play() end)
        btn.MouseLeave:Connect(function() tw(btn, {BackgroundColor3 = C.Red},    0.1):Play() end)

        return f
    end

    -- Input de texto
    local function mkInput(placeholder, onChange)
        local f = Instance.new("Frame")
        f.Size             = UDim2.new(1, 0, 0, 34)
        f.BackgroundColor3 = C.DarkCard
        f.BorderSizePixel  = 0
        f.ZIndex           = 7
        f.Parent           = Scroll
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)

        local fStroke = Instance.new("UIStroke")
        fStroke.Color        = C.Border
        fStroke.Thickness    = 1
        fStroke.Transparency = 0.5
        fStroke.Parent       = f

        local box = Instance.new("TextBox")
        box.Size                  = UDim2.new(1, -18, 1, -8)
        box.Position              = UDim2.new(0, 9, 0, 4)
        box.BackgroundTransparency = 1
        box.PlaceholderText       = placeholder
        box.PlaceholderColor3     = C.GrayDim
        box.Text                  = ""
        box.TextColor3            = C.White
        box.TextSize              = 12
        box.Font                  = Enum.Font.Gotham
        box.TextXAlignment        = Enum.TextXAlignment.Left
        box.ClearTextOnFocus      = false
        box.ZIndex                = 8
        box.Parent                = f

        box.Focused:Connect(function()
            tw(fStroke, {Color = C.Red, Transparency = 0}, 0.15):Play()
        end)
        box.FocusLost:Connect(function()
            tw(fStroke, {Color = C.Border, Transparency = 0.5}, 0.15):Play()
            if onChange then onChange(box.Text) end
        end)
        box:GetPropertyChangedSignal("Text"):Connect(function()
            if onChange then onChange(box.Text) end
        end)

        return f, box
    end

    -- ════════════════════════════════════════════════════════════
    --  SISTEMA DE ABAS (TABS)
    -- ════════════════════════════════════════════════════════════
    local TabPages = {}
    local tabBtns  = {}
    local TAB_NAMES = {"MOVE", "COMBATE", "VISUAL", "PLAYERS", "CONFIG"}

    for i, name in ipairs(TAB_NAMES) do
        local tb = Instance.new("TextButton")
        tb.Size             = UDim2.new(0, 62, 1, -6)
        tb.BackgroundColor3 = C.DarkCard
        tb.BorderSizePixel  = 0
        tb.Text             = name
        tb.TextColor3       = C.Gray
        tb.TextSize         = 9
        tb.Font             = Enum.Font.GothamBold
        tb.AutoButtonColor  = false
        tb.LayoutOrder      = i
        tb.ZIndex           = 7
        tb.Parent           = TabBar
        Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 5)

        tabBtns[name]  = tb
        TabPages[name] = {}

        tb.MouseButton1Click:Connect(function()
            -- Esconder tudo
            for _, items in pairs(TabPages) do
                for _, item in ipairs(items) do item.Visible = false end
            end
            -- Reset tabs
            for _, b in pairs(tabBtns) do
                tw(b, {BackgroundColor3 = C.DarkCard, TextColor3 = C.Gray}, 0.15):Play()
            end
            -- Mostrar tab ativo
            for _, item in ipairs(TabPages[name]) do item.Visible = true end
            tw(tb, {BackgroundColor3 = C.Red, TextColor3 = C.White}, 0.15):Play()
        end)
    end

    local function addTab(tabName, item)
        table.insert(TabPages[tabName], item)
        item.Visible = false
    end

    -- ════════════════════════════════════════════════════════════
    --  ABA: MOVE
    -- ════════════════════════════════════════════════════════════
    do
        addTab("MOVE", mkSection("MOVIMENTO"))

        local flyT = mkToggle("Fly", "Fly Avancado",
            "WASD+Space+Ctrl/Shift | Q = Turbo 3x",
            flyStart, flyStop)
        addTab("MOVE", flyT)

        local ncT = mkToggle("Noclip", "Noclip",
            "Atravesse paredes, chao e objetos",
            noclipStart, noclipStop)
        addTab("MOVE", ncT)

        local ijT = mkToggle("InfJump", "Infinite Jump",
            "Pule infinitamente no ar",
            infJumpStart, infJumpStop)
        addTab("MOVE", ijT)

        local avT = mkToggle("AntiVoid", "Anti-Void",
            "Salvo automaticamente do void/abismo",
            antiVoidStart, antiVoidStop)
        addTab("MOVE", avT)

        local sbT = mkToggle("SpeedBoost", "Speed Boost",
            "Velocidade de corrida aumentada",
            speedStart, speedStop)
        addTab("MOVE", sbT)

        local ctpT = mkToggle("ClickTP", "Click Teleport",
            "Ctrl+Click para teleportar no cursor",
            clickTPStart, clickTPStop)
        addTab("MOVE", ctpT)

        addTab("MOVE", mkSection("AJUSTE DE VELOCIDADE"))

        addTab("MOVE", mkSlider("Velocidade de Voo", 10, 350, 80, " s/s", function(v)
            Cfg.FlySpeed = v
        end))

        addTab("MOVE", mkSlider("Walk Speed", 16, 600, 16, " s/s", function(v)
            Cfg.WalkSpeed = v
            local h = getHum()
            if h then h.WalkSpeed = v end
        end))

        addTab("MOVE", mkSlider("Jump Power", 50, 500, 100, "", function(v)
            Cfg.JumpPower = v
            local h = getHum()
            if h then h.JumpPower = v end
        end))

        addTab("MOVE", mkSection("ACOES RAPIDAS"))

        addTab("MOVE", mkButton("Reset Personagem",
            "Reinicia seu personagem agora", "RESET", function()
            local h = getHum()
            if h then h.Health = 0 end
        end))

        addTab("MOVE", mkButton("Teleport Aleatório",
            "TP para jogador aleatório no mapa", "IR", function()
            local plrs = {}
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= Player and p.Character
                and p.Character:FindFirstChild("HumanoidRootPart") then
                    table.insert(plrs, p)
                end
            end
            if #plrs == 0 then notify("Aleatorio", "Nenhum jogador disponivel!", 2); return end
            local rp = plrs[math.random(1, #plrs)]
            local r  = getRoot()
            if r then
                r.CFrame = rp.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 4)
                notify("Aleatorio", "TP para: " .. rp.Name, 2)
            end
        end))

        addTab("MOVE", mkButton("Copiar Posicao",
            "Copia suas coordenadas atuais", "COPIAR", function()
            local r = getRoot()
            if r then
                local pos = r.Position
                local str = string.format("X:%.1f Y:%.1f Z:%.1f", pos.X, pos.Y, pos.Z)
                if setclipboard then setclipboard(str) end
                notify("Posicao", str, 5)
            end
        end))

        addTab("MOVE", mkButton("Rejoin Server",
            "Reconecta ao mesmo servidor", "REJOIN", function()
            TeleportService:Teleport(game.PlaceId, Player)
        end))
    end

    -- ════════════════════════════════════════════════════════════
    --  ABA: COMBATE
    -- ════════════════════════════════════════════════════════════
    do
        addTab("COMBATE", mkSection("DEFESA PESSOAL"))

        local godT = mkToggle("Godmode", "Godmode",
            "HP infinito — nao morre (client-side)",
            godStart, godStop)
        addTab("COMBATE", godT)

        local akT = mkToggle("AntiKick", "Anti-Kick",
            "Bloqueia kicks (executor compativel)",
            antiKickStart, antiKickStop)
        addTab("COMBATE", akT)

        addTab("COMBATE", mkSection("FLING AUTO"))

        local flingT = mkToggle("Fling", "Fling Automatico",
            "Joga jogadores proximos para fora",
            flingAutoStart, flingAutoStop)
        addTab("COMBATE", flingT)

        addTab("COMBATE", mkSlider("Forca do Fling", 100, 2000, 600, "", function(v)
            Cfg.FlingForce = v
        end))

        addTab("COMBATE", mkSection("FLING MANUAL"))

        local _, fmBox = mkInput("Nome do alvo para Fling...", function(t) end)
        addTab("COMBATE", fmBox.Parent)

        addTab("COMBATE", mkButton("Fling Manual",
            "Fling no jogador digitado", "FLING!", function()
            doFling(findPlayer(fmBox.Text))
        end))

        addTab("COMBATE", mkSection("DROP KICK"))

        local _, dkBox = mkInput("Nome do alvo para DropKick...", function(t) end)
        addTab("COMBATE", dkBox.Parent)

        addTab("COMBATE", mkButton("Drop Kick",
            "Dano + lancamento forte no alvo", "KICK!", function()
            doDropKick(findPlayer(dkBox.Text))
        end))

        addTab("COMBATE", mkSlider("Dano do DropKick", 5, 200, 50, " HP", function(v)
            Cfg.DropDmg = v
        end))

        addTab("COMBATE", mkSection("ABATE"))

        local _, killBox = mkInput("Nome do alvo para Kill...", function(t) end)
        addTab("COMBATE", killBox.Parent)

        addTab("COMBATE", mkButton("Kill Player",
            "Tenta matar o alvo (client-side)", "KILL", function()
            local t = findPlayer(killBox.Text)
            if not t or not t.Character then
                notify("Kill", "Jogador nao encontrado!", 2); return
            end
            local h2 = t.Character:FindFirstChildOfClass("Humanoid")
            if h2 then h2.Health = 0; notify("Kill", "Kill em: " .. t.Name, 2) end
        end))
    end

    -- ════════════════════════════════════════════════════════════
    --  ABA: VISUAL
    -- ════════════════════════════════════════════════════════════
    do
        addTab("VISUAL", mkSection("VISAO & DETECCAO"))

        local espT = mkToggle("ESP", "ESP Wallhack",
            "Veja jogadores atraves de paredes",
            espStart, espStop)
        addTab("VISUAL", espT)

        local fbT = mkToggle("FullBright", "FullBright",
            "Iluminacao maxima, sem escuridao",
            fullBrightStart, fullBrightStop)
        addTab("VISUAL", fbT)

        addTab("VISUAL", mkSection("PERSONAGEM"))

        local invT = mkToggle("Invisible", "Invisibilidade",
            "Fica totalmente invisivel no mapa",
            invisStart, invisStop)
        addTab("VISUAL", invT)

        local rbT = mkToggle("Rainbow", "Rainbow Mode",
            "Cor do personagem muda constantemente",
            rainbowStart, rainbowStop)
        addTab("VISUAL", rbT)
    end

    -- ════════════════════════════════════════════════════════════
    --  ABA: PLAYERS
    -- ════════════════════════════════════════════════════════════
    do
        addTab("PLAYERS", mkSection("FOLLOW PLAYER"))

        local _, followBox = mkInput("Nome do jogador (vazio = mais proximo)...", function(t)
            Cfg.FollowName = t
        end)
        addTab("PLAYERS", followBox.Parent)

        local followT = mkToggle("Follow", "Follow Player",
            "Siga o jogador — fica grudado nele",
            function()
                local ok = followStart()
                if not ok then
                    local ref = ToggleRefs["Follow"]
                    if ref then ref.set(false) end
                end
            end,
            followStop)
        addTab("PLAYERS", followT)

        addTab("PLAYERS", mkSection("TELEPORT"))

        local _, tpBox = mkInput("Nome do jogador para teleportar...", function(t) end)
        addTab("PLAYERS", tpBox.Parent)

        addTab("PLAYERS", mkButton("Ir Para Jogador",
            "Teleporte instantaneo ate ele", "IR!", function()
            tpToPlayer(findPlayer(tpBox.Text))
        end))

        addTab("PLAYERS", mkSection("ACOES EM JOGADORES"))

        local _, miscBox = mkInput("Nome do alvo para acoes abaixo...", function(t) end)
        addTab("PLAYERS", miscBox.Parent)

        addTab("PLAYERS", mkButton("Trazer Jogador",
            "Teleporta o alvo ate voce", "TRAZER", function()
            local target = findPlayer(miscBox.Text)
            if not target or not target.Character then
                notify("Trazer", "Jogador nao encontrado!", 2); return
            end
            local tr = target.Character:FindFirstChild("HumanoidRootPart")
            local r  = getRoot()
            if tr and r then
                tr.CFrame = r.CFrame * CFrame.new(2.5, 0, 0)
                notify("Trazer", target.Name .. " trazido!", 2)
            end
        end))

        addTab("PLAYERS", mkButton("Listagem de Jogadores",
            "Mostra todos no servidor", "LISTAR", function()
            local names = {}
            for _, p in ipairs(Players:GetPlayers()) do
                table.insert(names, p.Name)
            end
            notify("Jogadores", table.concat(names, ", "), 6)
        end))
    end

    -- ════════════════════════════════════════════════════════════
    --  ABA: CONFIG
    -- ════════════════════════════════════════════════════════════
    do
        addTab("CONFIG", mkSection("TAMANHO DO PAINEL"))

        addTab("CONFIG", mkSlider("Largura", 280, 520, 370, "px", function(v)
            panelW = v
            local cur = Panel.Size
            Panel.Size = UDim2.new(0, v, 0, cur.Y.Offset)
        end))

        addTab("CONFIG", mkSlider("Altura", 300, 720, 560, "px", function(v)
            panelH = v
            if not isMin then
                local cur = Panel.Size
                Panel.Size = UDim2.new(0, cur.X.Offset, 0, v)
            end
        end))

        addTab("CONFIG", mkSection("ATALHOS DE TECLADO"))

        -- Info box de atalhos
        local kbF = Instance.new("Frame")
        kbF.Size             = UDim2.new(1, 0, 0, 108)
        kbF.BackgroundColor3 = C.DarkCard
        kbF.BorderSizePixel  = 0
        kbF.ZIndex           = 7
        kbF.Parent           = Scroll
        Instance.new("UICorner", kbF).CornerRadius = UDim.new(0, 8)

        do
            local us = Instance.new("UIStroke")
            us.Color        = C.Border
            us.Thickness    = 1
            us.Transparency = 0.5
            us.Parent       = kbF
        end

        local kbL = Instance.new("TextLabel")
        kbL.Size                  = UDim2.new(1, -18, 1, -12)
        kbL.Position              = UDim2.new(0, 9, 0, 6)
        kbL.BackgroundTransparency = 1
        kbL.Text = "RightShift     Abrir / Fechar painel\n" ..
                   "Alt + F        Toggle Fly\n" ..
                   "Alt + N        Toggle Noclip\n" ..
                   "Alt + E        Toggle ESP\n" ..
                   "Alt + I        Toggle Invisivel\n" ..
                   "Ctrl + Click   Teleportar (ClickTP ativo)"
        kbL.TextColor3            = C.Gray
        kbL.TextSize              = 10.5
        kbL.Font                  = Enum.Font.GothamMono
        kbL.TextXAlignment        = Enum.TextXAlignment.Left
        kbL.TextYAlignment        = Enum.TextYAlignment.Top
        kbL.ZIndex                = 8
        kbL.Parent                = kbF

        addTab("CONFIG", kbF)

        addTab("CONFIG", mkSection("SISTEMA"))

        addTab("CONFIG", mkButton("Desligar Script",
            "Remove a UI e para todas as funcoes", "OFF", function()
            for key, conn in pairs(Conn) do
                pcall(function() conn:Disconnect() end)
                Conn[key] = nil
            end
            if flyBG and flyBG.Parent then flyBG:Destroy() end
            if flyBV and flyBV.Parent then flyBV:Destroy() end
            notify("Sync Admin", "Script desligado. Reload para reativar.", 4)
            task.delay(0.3, function() Screen:Destroy() end)
        end))
    end

    -- ════════════════════════════════════════════════════════════
    --  ATIVAR PRIMEIRA ABA (MOVE)
    -- ════════════════════════════════════════════════════════════
    tabBtns["MOVE"].MouseButton1Click:Fire()

    -- ════════════════════════════════════════════════════════════
    --  KEYBINDS GLOBAIS
    -- ════════════════════════════════════════════════════════════
    UserInputService.InputBegan:Connect(function(inp, gp)
        if gp then return end

        if inp.KeyCode == Enum.KeyCode.RightShift then
            if panelOpen then closePanel() else openPanel() end
        end

        local alt = UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt)
                 or UserInputService:IsKeyDown(Enum.KeyCode.RightAlt)

        if alt then
            local hotkeys = {
                [Enum.KeyCode.F] = "Fly",
                [Enum.KeyCode.N] = "Noclip",
                [Enum.KeyCode.E] = "ESP",
                [Enum.KeyCode.I] = "Invisible",
            }
            local ref = ToggleRefs[hotkeys[inp.KeyCode]]
            if ref then ref.set(not ref.get()) end
        end
    end)

    -- Notificação de boas-vindas
    notify("SYNC ADMIN v4.0", "Carregado! Clique no S ou RightShift para abrir.", 5)

    return Screen
end

-- ══════════════════════════════════════════════════════════════════
--  INICIALIZAR
-- ══════════════════════════════════════════════════════════════════
local ok, err = pcall(BuildUI)
if not ok then
    warn("[SyncAdmin v4] Erro na UI: " .. tostring(err))
end

--[[
╔══════════════════════════════════════════════════════════════════╗
║                   SYNC ADMIN v4.0  CONTROLES                   ║
╠══════════════════════════════════════════════════════════════════╣
║  BOTAO DISCRETO:                                                ║
║  · Clique no circulo "S" flutuante para abrir/fechar            ║
║  · Arraste o botao para qualquer canto da tela                  ║
╠══════════════════════════════════════════════════════════════════╣
║  ATALHOS:                                                       ║
║  · RightShift   = Abrir/Fechar painel                           ║
║  · Alt + F      = Toggle Fly                                    ║
║  · Alt + N      = Toggle Noclip                                 ║
║  · Alt + E      = Toggle ESP                                    ║
║  · Alt + I      = Toggle Invisivel                              ║
║  · Ctrl+Click   = Teleportar (ClickTP ativo)                    ║
╠══════════════════════════════════════════════════════════════════╣
║  FLY — CONTROLES:                                               ║
║  · W/A/S/D = Mover em todas as direcoes                         ║
║  · Space   = Subir                                              ║
║  · Ctrl ou Shift = Descer                                       ║
║  · Q (segurado) = Turbo 3x de velocidade                        ║
╠══════════════════════════════════════════════════════════════════╣
║  ABAS:                                                          ║
║  · MOVE    = Fly, Noclip, InfJump, AntiVoid, Speed, ClickTP     ║
║  · COMBATE = Godmode, AntiKick, Fling, DropKick, Kill           ║
║  · VISUAL  = ESP, FullBright, Invisivel, Rainbow                ║
║  · PLAYERS = Follow, Teleport, Trazer, Listar                   ║
║  · CONFIG  = Tamanho do painel, atalhos, desligar               ║
╚══════════════════════════════════════════════════════════════════╝
--]]
