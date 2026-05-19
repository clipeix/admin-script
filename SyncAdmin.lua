--[[
    ╔══════════════════════════════════════════════════════════════════════╗
    ║                    SYNC ADMIN  v3.0  ULTRA PRO                      ║
    ║              Ultimate Roblox Admin Panel - Full Edition              ║
    ║       Fly Fixado | Invis | Fling | DropKick | Follow por Nome       ║
    ║         Botão Discreto | Categorias | Painel Redimensionável        ║
    ╚══════════════════════════════════════════════════════════════════════╝
--]]

-- ═══════════════════════════════════════════════════════════════════════
--  SERVICES
-- ═══════════════════════════════════════════════════════════════════════
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")
local Workspace          = game:GetService("Workspace")
local StarterGui         = game:GetService("StarterGui")
local HttpService        = game:GetService("HttpService")
local Chat               = game:GetService("Chat")

-- ═══════════════════════════════════════════════════════════════════════
--  PLAYER / MOUSE
-- ═══════════════════════════════════════════════════════════════════════
local Player = Players.LocalPlayer
local Mouse  = Player:GetMouse()

-- ═══════════════════════════════════════════════════════════════════════
--  TEMA DE CORES
-- ═══════════════════════════════════════════════════════════════════════
local T = {
    Red          = Color3.fromRGB(220, 30,  30),
    RedBright    = Color3.fromRGB(255, 60,  60),
    RedDark      = Color3.fromRGB(140, 15,  15),
    Bg           = Color3.fromRGB(12,  12,  12),
    BgLight      = Color3.fromRGB(22,  22,  22),
    BgAlt        = Color3.fromRGB(32,  32,  32),
    BgAlt2       = Color3.fromRGB(42,  42,  42),
    Text         = Color3.fromRGB(255, 255, 255),
    TextDim      = Color3.fromRGB(160, 160, 160),
    TextTiny     = Color3.fromRGB(100, 100, 100),
    Green        = Color3.fromRGB(50,  210, 80),
    Yellow       = Color3.fromRGB(255, 190, 50),
    Border       = Color3.fromRGB(55,  55,  55),
    Off          = Color3.fromRGB(70,  70,  70),
    Shadow       = Color3.fromRGB(0,   0,   0),
}

-- ═══════════════════════════════════════════════════════════════════════
--  ESTADOS (TOGGLES)
-- ═══════════════════════════════════════════════════════════════════════
local States = {
    Fly           = false,
    Noclip        = false,
    InfiniteJump  = false,
    AntiVoid      = false,
    Godmode       = false,
    Invisible     = false,
    ESP           = false,
    Fling         = false,
    Follow        = false,
    ClickTP       = false,
    AntiKick      = false,
    FullBright    = false,
}

-- ═══════════════════════════════════════════════════════════════════════
--  CONFIGURAÇÕES
-- ═══════════════════════════════════════════════════════════════════════
local Cfg = {
    FlySpeed        = 80,
    WalkSpeed       = 16,
    JumpPower       = 100,
    FlingForce      = 9e8,
    DropKickDmg     = 50,
    FollowTarget    = nil,   -- Player object
    FollowName      = "",
    FollowDistance  = 3,
    AntiVoidHeight  = -70,
}

-- ═══════════════════════════════════════════════════════════════════════
--  CONEXÕES
-- ═══════════════════════════════════════════════════════════════════════
local Conn = {}

-- ═══════════════════════════════════════════════════════════════════════
--  UTILITÁRIOS
-- ═══════════════════════════════════════════════════════════════════════
local function Char()
    return Player.Character or Player.CharacterAdded:Wait()
end
local function Hum()
    local c = Char()
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function Root()
    local c = Char()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function Tween(obj, props, t, sty, dir)
    return TweenService:Create(obj,
        TweenInfo.new(t or 0.25, sty or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
        props)
end
local function Notify(title, msg, dur)
    pcall(StarterGui.SetCore, StarterGui, "SendNotification", {
        Title = "⚡ " .. title, Text = msg, Duration = dur or 3
    })
end
local function FindPlayer(name)
    name = name:lower()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():find(name, 1, true) or p.DisplayName:lower():find(name, 1, true) then
            return p
        end
    end
    return nil
end
local function Disconnect(key)
    if Conn[key] then
        pcall(function() Conn[key]:Disconnect() end)
        Conn[key] = nil
    end
end

-- ═══════════════════════════════════════════════════════════════════════
--  LÓGICA DAS FUNÇÕES
-- ═══════════════════════════════════════════════════════════════════════

-- ─── FLY (CORRIGIDO TOTALMENTE) ───────────────────────────────────────
local FlyObjects = {}

local function StartFly()
    local root = Root()
    local hum  = Hum()
    if not root or not hum then return end

    -- Limpar objetos anteriores
    for _, v in pairs(FlyObjects) do pcall(function() v:Destroy() end) end
    FlyObjects = {}

    hum.PlatformStand = true

    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    bg.P         = 1e6
    bg.D         = 500
    bg.CFrame    = root.CFrame
    bg.Parent    = root
    FlyObjects.Gyro = bg

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    bv.Velocity  = Vector3.new(0, 0, 0)
    bv.P         = 1e5
    bv.Parent    = root
    FlyObjects.Vel = bv

    Conn["Fly"] = RunService.RenderStepped:Connect(function(dt)
        if not States.Fly then return end
        local cam = Workspace.CurrentCamera
        local r   = Root()
        if not r then return end

        local dir = Vector3.new(0, 0, 0)
        local cf  = cam.CFrame

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            dir = dir + cf.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            dir = dir - cf.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            dir = dir - cf.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            dir = dir + cf.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            dir = dir + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
            or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            dir = dir + Vector3.new(0, -1, 0)
        end

        -- Velocidade boost com Q
        local speed = Cfg.FlySpeed
        if UserInputService:IsKeyDown(Enum.KeyCode.Q) then
            speed = speed * 3
        end

        bv.Velocity = dir.Magnitude > 0 and (dir.Unit * speed) or Vector3.new(0, 0, 0)
        bg.CFrame   = cf
    end)

    Notify("Fly", "ATIVADO — WASD mover | Space subir | Ctrl descer | Q turbo", 4)
end

local function StopFly()
    Disconnect("Fly")
    for _, v in pairs(FlyObjects) do pcall(function() v:Destroy() end) end
    FlyObjects = {}
    local h = Hum()
    if h then h.PlatformStand = false end
    Notify("Fly", "DESATIVADO", 2)
end

-- ─── NOCLIP ───────────────────────────────────────────────────────────
local function StartNoclip()
    Conn["Noclip"] = RunService.Stepped:Connect(function()
        if not States.Noclip then return end
        local c = Char()
        if not c then return end
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end)
    Notify("Noclip", "ATIVADO — atravesse qualquer coisa", 3)
end

local function StopNoclip()
    Disconnect("Noclip")
    local c = Char()
    if c then
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                p.CanCollide = true
            end
        end
    end
    Notify("Noclip", "DESATIVADO", 2)
end

-- ─── INFINITE JUMP ────────────────────────────────────────────────────
local function StartInfJump()
    Conn["InfJump"] = UserInputService.JumpRequest:Connect(function()
        if not States.InfiniteJump then return end
        local h = Hum()
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
    Notify("InfiniteJump", "ATIVADO", 2)
end
local function StopInfJump()
    Disconnect("InfJump")
    Notify("InfiniteJump", "DESATIVADO", 2)
end

-- ─── ANTI-VOID ────────────────────────────────────────────────────────
local AntiVoidSafePos = Vector3.new(0, 100, 0)

local function StartAntiVoid()
    Conn["AntiVoid"] = RunService.Heartbeat:Connect(function()
        if not States.AntiVoid then return end
        local r = Root()
        if r then
            if r.Position.Y > 10 then
                AntiVoidSafePos = Vector3.new(r.Position.X, r.Position.Y, r.Position.Z)
            end
            if r.Position.Y < Cfg.AntiVoidHeight then
                r.CFrame = CFrame.new(AntiVoidSafePos + Vector3.new(0, 5, 0))
                Notify("AntiVoid", "Salvo do void!", 2)
            end
        end
    end)
    Notify("AntiVoid", "ATIVADO — proteção máxima ativa", 3)
end
local function StopAntiVoid()
    Disconnect("AntiVoid")
    Notify("AntiVoid", "DESATIVADO", 2)
end

-- ─── GODMODE ──────────────────────────────────────────────────────────
local function StartGodmode()
    local h = Hum()
    if h then
        h.MaxHealth = math.huge
        h.Health    = math.huge

        Conn["Godmode"] = h.HealthChanged:Connect(function()
            if States.Godmode then
                local hh = Hum()
                if hh then hh.Health = hh.MaxHealth end
            end
        end)
    end
    Notify("Godmode", "ATIVADO — HP infinito (client-side)", 3)
end
local function StopGodmode()
    Disconnect("Godmode")
    local h = Hum()
    if h then
        h.MaxHealth = 100
        h.Health    = 100
    end
    Notify("Godmode", "DESATIVADO", 2)
end

-- ─── INVISIBILIDADE ───────────────────────────────────────────────────
local InvisBackup = {}

local function StartInvisible()
    local c = Char()
    if not c then return end
    InvisBackup = {}
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") or p:IsA("Decal") then
            InvisBackup[p] = p.Transparency
            p.Transparency = 1
        end
    end
    -- Manter invisível após respawn
    Conn["Invis"] = RunService.Heartbeat:Connect(function()
        if not States.Invisible then return end
        local cc = Char()
        if not cc then return end
        for _, p in ipairs(cc:GetDescendants()) do
            if p:IsA("BasePart") or p:IsA("Decal") then
                p.Transparency = 1
            end
        end
    end)
    Notify("Invisível", "ATIVADO — você sumiu!", 3)
end

local function StopInvisible()
    Disconnect("Invis")
    local c = Char()
    if c then
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") or p:IsA("Decal") then
                local orig = InvisBackup[p]
                p.Transparency = orig or 0
            end
        end
    end
    InvisBackup = {}
    Notify("Invisível", "DESATIVADO", 2)
end

-- ─── ESP ──────────────────────────────────────────────────────────────
local ESPObjects = {}

local function CreateESP(plr)
    if plr == Player then return end
    local function Apply(chr)
        if not chr then return end
        -- Remover antigos
        local old = chr:FindFirstChild("SyncESP_HL")
        if old then old:Destroy() end

        local hl = Instance.new("Highlight")
        hl.Name              = "SyncESP_HL"
        hl.FillColor         = T.Red
        hl.OutlineColor      = Color3.new(1, 1, 1)
        hl.FillTransparency  = 0.65
        hl.OutlineTransparency = 0
        hl.DepthMode         = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent            = chr

        local head = chr:FindFirstChild("Head")
        if head then
            local bb = Instance.new("BillboardGui")
            bb.Name           = "SyncESP_BB"
            bb.Size           = UDim2.new(0, 120, 0, 40)
            bb.StudsOffset    = Vector3.new(0, 3.5, 0)
            bb.AlwaysOnTop    = true
            bb.Parent         = head

            local lbl = Instance.new("TextLabel")
            lbl.Size                 = UDim2.new(1, 0, 1, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text                 = plr.Name
            lbl.TextColor3           = T.RedBright
            lbl.TextStrokeTransparency = 0
            lbl.TextStrokeColor3     = Color3.new(0, 0, 0)
            lbl.TextSize             = 15
            lbl.Font                 = Enum.Font.GothamBold
            lbl.Parent               = bb
        end

        ESPObjects[plr] = hl
    end

    if plr.Character then Apply(plr.Character) end
    plr.CharacterAdded:Connect(function(chr)
        if States.ESP then task.wait(0.5) Apply(chr) end
    end)
end

local function StartESP()
    for _, p in ipairs(Players:GetPlayers()) do CreateESP(p) end
    Conn["ESPAdded"] = Players.PlayerAdded:Connect(function(p)
        if States.ESP then CreateESP(p) end
    end)
    Notify("ESP", "ATIVADO — visão total pelo mapa", 3)
end

local function StopESP()
    Disconnect("ESPAdded")
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then
            local hl = p.Character:FindFirstChild("SyncESP_HL")
            if hl then hl:Destroy() end
            local head = p.Character:FindFirstChild("Head")
            if head then
                local bb = head:FindFirstChild("SyncESP_BB")
                if bb then bb:Destroy() end
            end
        end
    end
    ESPObjects = {}
    Notify("ESP", "DESATIVADO", 2)
end

-- ─── FLING ────────────────────────────────────────────────────────────
local function FlingPlayer(targetPlayer)
    if not targetPlayer then Notify("Fling", "Nenhum alvo!", 2) return end
    local targetChar = targetPlayer.Character
    if not targetChar then Notify("Fling", "Personagem não encontrado!", 2) return end

    local root = Root()
    if not root then return end

    -- Aproximar do alvo
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return end

    root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 2)
    task.wait(0.1)

    -- Criar força massiva no alvo (hack via tools/touch)
    local force = Instance.new("BodyVelocity")
    force.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    force.Velocity  = Vector3.new(
        math.random(-1, 1) * Cfg.FlingForce / 1e6,
        Cfg.FlingForce / 1e6,
        math.random(-1, 1) * Cfg.FlingForce / 1e6
    )

    -- Usar a posição da câmera para dar direção ao fling
    local cam = Workspace.CurrentCamera
    local flingDir = (cam.CFrame.LookVector + Vector3.new(0, 1.5, 0)).Unit
    force.Velocity = flingDir * (Cfg.FlingForce / 1000)
    force.Parent    = targetRoot

    task.delay(0.25, function()
        if force and force.Parent then force:Destroy() end
    end)

    Notify("Fling", "Fling em: " .. targetPlayer.Name, 2)
end

local function StartFling()
    Conn["Fling"] = RunService.Heartbeat:Connect(function()
        if not States.Fling then return end
        local r = Root()
        if not r then return end

        local closest, closestDist = nil, 30 -- só faz fling se estiver perto

        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Player and p.Character then
                local pr = p.Character:FindFirstChild("HumanoidRootPart")
                if pr then
                    local d = (pr.Position - r.Position).Magnitude
                    if d < closestDist then
                        closestDist = d
                        closest = p
                    end
                end
            end
        end

        if closest then
            FlingPlayer(closest)
        end
    end)
    Notify("Fling", "ATIVADO — fling automático em jogadores próximos", 3)
end

local function StopFling()
    Disconnect("Fling")
    Notify("Fling", "DESATIVADO", 2)
end

-- ─── FOLLOW (COM NOME) ────────────────────────────────────────────────
local function StartFollow()
    if Cfg.FollowName == "" then
        -- Seguir mais próximo
        local r = Root()
        local closest, closestDist = nil, math.huge
        if r then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= Player and p.Character then
                    local pr = p.Character:FindFirstChild("HumanoidRootPart")
                    if pr then
                        local d = (pr.Position - r.Position).Magnitude
                        if d < closestDist then
                            closestDist = d
                            closest = p
                        end
                    end
                end
            end
        end
        Cfg.FollowTarget = closest
    else
        Cfg.FollowTarget = FindPlayer(Cfg.FollowName)
    end

    if not Cfg.FollowTarget then
        Notify("Follow", "Jogador nao encontrado!", 2)
        States.Follow = false
        return false
    end

    Conn["Follow"] = RunService.Heartbeat:Connect(function()
        if not States.Follow then return end
        local t = Cfg.FollowTarget
        if not t or not t.Character then return end
        local tr = t.Character:FindFirstChild("HumanoidRootPart")
        local r  = Root()
        if not tr or not r then return end

        local dist = (tr.Position - r.Position).Magnitude
        if dist > Cfg.FollowDistance then
            local h = Hum()
            if h then h:MoveTo(tr.Position) end
        end
    end)

    Notify("Follow", "Seguindo: " .. Cfg.FollowTarget.Name, 3)
    return true
end

local function StopFollow()
    Disconnect("Follow")
    Cfg.FollowTarget = nil
    local h = Hum()
    local r = Root()
    if h and r then h:MoveTo(r.Position) end
    Notify("Follow", "DESATIVADO", 2)
end

-- ─── CLICK TP ─────────────────────────────────────────────────────────
local function StartClickTP()
    Conn["ClickTP"] = Mouse.Button1Down:Connect(function()
        if not States.ClickTP then return end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            local r = Root()
            if r and Mouse.Hit then
                r.CFrame = Mouse.Hit + Vector3.new(0, 3, 0)

                -- Efeito de teletransporte
                local ep = Instance.new("Part")
                ep.Anchored    = true
                ep.CanCollide  = false
                ep.Size        = Vector3.new(1, 1, 1)
                ep.Shape       = Enum.PartType.Ball
                ep.Material    = Enum.Material.Neon
                ep.Color       = T.RedBright
                ep.Position    = r.Position
                ep.Parent      = Workspace
                Tween(ep, {Size = Vector3.new(8, 8, 8), Transparency = 1}, 0.5):Play()
                task.delay(0.5, function() ep:Destroy() end)
            end
        end
    end)
    Notify("ClickTP", "ATIVADO — Ctrl+Click para teleportar", 3)
end
local function StopClickTP()
    Disconnect("ClickTP")
    Notify("ClickTP", "DESATIVADO", 2)
end

-- ─── ANTI-KICK ────────────────────────────────────────────────────────
local function StartAntiKick()
    -- Hook no kick (funciona em alguns executores)
    local mt = getrawmetatable and getrawmetatable(game)
    if mt then
        local oldNamecall = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if self == Player and method == "Kick" then
                return
            end
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
        Conn["AntiKick"] = { Disconnect = function() end } -- placeholder
        Notify("AntiKick", "ATIVADO — kicks bloqueados", 3)
    else
        Notify("AntiKick", "Executor nao suporta AntiKick", 3)
    end
end
local function StopAntiKick()
    Notify("AntiKick", "DESATIVADO (reinicie para restaurar)", 3)
end

-- ─── FULLBRIGHT ───────────────────────────────────────────────────────
local OrigAmbient, OrigOutAmbient, OrigBrightness

local function StartFullBright()
    local lighting = game:GetService("Lighting")
    OrigAmbient    = lighting.Ambient
    OrigOutAmbient = lighting.OutdoorAmbient
    OrigBrightness = lighting.Brightness

    lighting.Ambient        = Color3.fromRGB(255, 255, 255)
    lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    lighting.Brightness     = 2

    -- Remover efeitos escuros
    for _, ef in ipairs(lighting:GetChildren()) do
        if ef:IsA("BlurEffect") or ef:IsA("ColorCorrectionEffect") then
            ef.Enabled = false
        end
    end

    Notify("FullBright", "ATIVADO — visao total", 3)
end
local function StopFullBright()
    local lighting = game:GetService("Lighting")
    if OrigAmbient then lighting.Ambient        = OrigAmbient end
    if OrigOutAmbient then lighting.OutdoorAmbient = OrigOutAmbient end
    if OrigBrightness then lighting.Brightness   = OrigBrightness end
    for _, ef in ipairs(lighting:GetChildren()) do
        if ef:IsA("BlurEffect") or ef:IsA("ColorCorrectionEffect") then
            ef.Enabled = true
        end
    end
    Notify("FullBright", "DESATIVADO", 2)
end

-- ─── DROPKICK (DANO + LANÇAMENTO) ────────────────────────────────────
local function DropKick(targetPlayer)
    if not targetPlayer then Notify("DropKick", "Nenhum alvo especificado!", 2) return end
    local tc = targetPlayer.Character
    if not tc then Notify("DropKick", "Alvo sem personagem!", 2) return end

    local tr = tc:FindFirstChild("HumanoidRootPart")
    local th = tc:FindFirstChildOfClass("Humanoid")
    local r  = Root()

    if not tr or not th or not r then return end

    -- Chegar perto do alvo
    r.CFrame = tr.CFrame * CFrame.new(0, 0, 1.5)
    task.wait(0.05)

    -- Aplicar dano via Humanoid (funciona somente se o jogo permitir)
    th.Health = math.max(0, th.Health - Cfg.DropKickDmg)

    -- Lançar para cima e frente
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    local cam  = Workspace.CurrentCamera
    bv.Velocity = (cam.CFrame.LookVector * 80) + Vector3.new(0, 50, 0)
    bv.Parent   = tr

    -- Efeito visual
    local ef = Instance.new("Part")
    ef.Anchored   = true
    ef.CanCollide = false
    ef.Size       = Vector3.new(0.5, 0.5, 0.5)
    ef.Shape      = Enum.PartType.Ball
    ef.Material   = Enum.Material.Neon
    ef.Color      = T.RedBright
    ef.Position   = tr.Position + Vector3.new(0, 1, 0)
    ef.Parent     = Workspace
    Tween(ef, {Size = Vector3.new(6, 6, 6), Transparency = 1}, 0.4):Play()

    task.delay(0.3, function()
        if bv and bv.Parent then bv:Destroy() end
    end)
    task.delay(0.4, function()
        if ef and ef.Parent then ef:Destroy() end
    end)

    Notify("DropKick", "DropKick em " .. targetPlayer.Name .. "! -" .. Cfg.DropKickDmg .. " HP", 3)
end

-- ─── TELEPORT PARA JOGADOR ────────────────────────────────────────────
local function TeleportToPlayer(targetPlayer)
    if not targetPlayer then Notify("TeleportTo", "Jogador nao encontrado!", 2) return end
    local tc = targetPlayer.Character
    if not tc then Notify("TeleportTo", "Alvo sem personagem!", 2) return end
    local tr = tc:FindFirstChild("HumanoidRootPart")
    local r  = Root()
    if not tr or not r then return end

    r.CFrame = tr.CFrame * CFrame.new(0, 0, 3)
    Notify("TeleportTo", "Teleportado para: " .. targetPlayer.Name, 2)
end

-- ═══════════════════════════════════════════════════════════════════════
--  INTERFACE (UI)
-- ═══════════════════════════════════════════════════════════════════════
local function BuildUI()
    -- Limpar UI anterior
    local old = Player.PlayerGui:FindFirstChild("SyncAdminV3")
    if old then old:Destroy() end

    local Screen = Instance.new("ScreenGui")
    Screen.Name          = "SyncAdminV3"
    Screen.ResetOnSpawn  = false
    Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    Screen.DisplayOrder  = 999
    Screen.Parent        = Player.PlayerGui

    -- ══════════════════════════════════════════════════════════════
    --  BOTÃO DISCRETO (FLUTUANTE)
    -- ══════════════════════════════════════════════════════════════
    local FloatBtn = Instance.new("TextButton")
    FloatBtn.Name                = "FloatBtn"
    FloatBtn.Size                = UDim2.new(0, 44, 0, 44)
    FloatBtn.Position            = UDim2.new(0, 20, 0.5, -22)
    FloatBtn.BackgroundColor3    = T.Red
    FloatBtn.BorderSizePixel     = 0
    FloatBtn.Text                = "S"
    FloatBtn.TextColor3          = T.Text
    FloatBtn.TextSize            = 22
    FloatBtn.Font                = Enum.Font.GothamBlack
    FloatBtn.AutoButtonColor     = false
    FloatBtn.Parent              = Screen

    local FBCorner = Instance.new("UICorner")
    FBCorner.CornerRadius = UDim.new(1, 0)
    FBCorner.Parent       = FloatBtn

    local FBStroke = Instance.new("UIStroke")
    FBStroke.Color      = T.RedBright
    FBStroke.Thickness  = 2
    FBStroke.Parent     = FloatBtn

    -- Pulso no botão flutuante
    local function PulseFloat()
        local t1 = Tween(FloatBtn, {Size = UDim2.new(0, 50, 0, 50), Position = UDim2.new(FloatBtn.Position.X.Scale, FloatBtn.Position.X.Offset - 3, FloatBtn.Position.Y.Scale, FloatBtn.Position.Y.Offset - 3)}, 0.5)
        local t2 = Tween(FloatBtn, {Size = UDim2.new(0, 44, 0, 44), Position = UDim2.new(FloatBtn.Position.X.Scale, FloatBtn.Position.X.Offset + 3, FloatBtn.Position.Y.Scale, FloatBtn.Position.Y.Offset + 3)}, 0.5)
        t1:Play()
        t1.Completed:Connect(function() t2:Play() end)
    end
    task.spawn(function()
        while FloatBtn and FloatBtn.Parent do
            PulseFloat()
            task.wait(1.2)
        end
    end)

    -- Arrastar o botão flutuante
    do
        local dragF, dragStartF, startPosF = false, nil, nil
        FloatBtn.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                dragF     = true
                dragStartF = inp.Position
                startPosF  = FloatBtn.Position
            end
        end)
        FloatBtn.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                dragF = false
            end
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if dragF and inp.UserInputType == Enum.UserInputType.MouseMovement then
                local d = inp.Position - dragStartF
                FloatBtn.Position = UDim2.new(
                    startPosF.X.Scale, startPosF.X.Offset + d.X,
                    startPosF.Y.Scale, startPosF.Y.Offset + d.Y
                )
            end
        end)
    end

    -- ══════════════════════════════════════════════════════════════
    --  PAINEL PRINCIPAL
    -- ══════════════════════════════════════════════════════════════
    local Panel = Instance.new("Frame")
    Panel.Name              = "Panel"
    Panel.Size              = UDim2.new(0, 360, 0, 540)
    Panel.Position          = UDim2.new(0.5, -180, 0.5, -270)
    Panel.BackgroundColor3  = T.Bg
    Panel.BorderSizePixel   = 0
    Panel.ClipsDescendants  = true
    Panel.Visible           = false
    Panel.Parent            = Screen

    local PanelCorner = Instance.new("UICorner")
    PanelCorner.CornerRadius = UDim.new(0, 12)
    PanelCorner.Parent       = Panel

    local PanelStroke = Instance.new("UIStroke")
    PanelStroke.Color     = T.Red
    PanelStroke.Thickness = 2
    PanelStroke.Parent    = Panel

    -- Sombra do painel
    local Shadow = Instance.new("ImageLabel")
    Shadow.Name                 = "Shadow"
    Shadow.AnchorPoint          = Vector2.new(0.5, 0.5)
    Shadow.Size                 = UDim2.new(1, 50, 1, 50)
    Shadow.Position             = UDim2.new(0.5, 0, 0.5, 6)
    Shadow.BackgroundTransparency = 1
    Shadow.Image                = "rbxassetid://6014261993"
    Shadow.ImageColor3          = Color3.new(0, 0, 0)
    Shadow.ImageTransparency    = 0.4
    Shadow.ScaleType            = Enum.ScaleType.Slice
    Shadow.SliceCenter          = Rect.new(49, 49, 450, 450)
    Shadow.ZIndex               = -1
    Shadow.Parent               = Panel

    -- Toggle visibilidade do painel
    local panelOpen = false
    FloatBtn.MouseButton1Click:Connect(function()
        panelOpen = not panelOpen
        if panelOpen then
            Panel.Visible = true
            Panel.Size    = UDim2.new(0, 0, 0, 0)
            Tween(Panel, {Size = UDim2.new(0, 360, 0, 540)}, 0.35, Enum.EasingStyle.Back):Play()
        else
            local tw = Tween(Panel, {Size = UDim2.new(0, 0, 0, 0)}, 0.25):Play()
            task.delay(0.25, function() Panel.Visible = false end)
        end
    end)

    -- ══════════════════════════════════════════════════════════════
    --  HEADER
    -- ══════════════════════════════════════════════════════════════
    local Header = Instance.new("Frame")
    Header.Name             = "Header"
    Header.Size             = UDim2.new(1, 0, 0, 56)
    Header.BackgroundColor3 = T.RedDark
    Header.BorderSizePixel  = 0
    Header.Parent           = Panel

    local HCorner = Instance.new("UICorner")
    HCorner.CornerRadius = UDim.new(0, 12)
    HCorner.Parent       = Header

    local HFix = Instance.new("Frame")
    HFix.Size             = UDim2.new(1, 0, 0, 12)
    HFix.Position         = UDim2.new(0, 0, 1, -12)
    HFix.BackgroundColor3 = T.RedDark
    HFix.BorderSizePixel  = 0
    HFix.Parent           = Header

    local HGrad = Instance.new("UIGradient")
    HGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, T.RedBright),
        ColorSequenceKeypoint.new(1, T.RedDark),
    })
    HGrad.Rotation = 90
    HGrad.Parent   = Header

    -- Logo S
    local LogoBox = Instance.new("Frame")
    LogoBox.Size             = UDim2.new(0, 38, 0, 38)
    LogoBox.Position         = UDim2.new(0, 10, 0.5, -19)
    LogoBox.BackgroundColor3 = T.Bg
    LogoBox.BorderSizePixel  = 0
    LogoBox.Parent           = Header
    local LBCorner = Instance.new("UICorner")
    LBCorner.CornerRadius = UDim.new(0, 8)
    LBCorner.Parent       = LogoBox

    local LogoLbl = Instance.new("TextLabel")
    LogoLbl.Size                 = UDim2.new(1, 0, 1, 0)
    LogoLbl.BackgroundTransparency = 1
    LogoLbl.Text                 = "S"
    LogoLbl.TextColor3           = T.Red
    LogoLbl.TextSize             = 22
    LogoLbl.Font                 = Enum.Font.GothamBlack
    LogoLbl.Parent               = LogoBox

    -- Título
    local TitleLbl = Instance.new("TextLabel")
    TitleLbl.Size                 = UDim2.new(0, 180, 0, 22)
    TitleLbl.Position             = UDim2.new(0, 56, 0, 8)
    TitleLbl.BackgroundTransparency = 1
    TitleLbl.Text                 = "SYNC ADMIN"
    TitleLbl.TextColor3           = T.Text
    TitleLbl.TextSize             = 19
    TitleLbl.Font                 = Enum.Font.GothamBlack
    TitleLbl.TextXAlignment       = Enum.TextXAlignment.Left
    TitleLbl.Parent               = Header

    local SubLbl = Instance.new("TextLabel")
    SubLbl.Size                 = UDim2.new(0, 180, 0, 14)
    SubLbl.Position             = UDim2.new(0, 56, 0, 30)
    SubLbl.BackgroundTransparency = 1
    SubLbl.Text                 = "Ultra Pro  •  v3.0"
    SubLbl.TextColor3           = Color3.fromRGB(255, 210, 210)
    SubLbl.TextSize             = 11
    SubLbl.Font                 = Enum.Font.Gotham
    SubLbl.TextXAlignment       = Enum.TextXAlignment.Left
    SubLbl.Parent               = Header

    -- Botões header direita
    local function MakeHdrBtn(text, bgColor, xOff)
        local b = Instance.new("TextButton")
        b.Size             = UDim2.new(0, 28, 0, 28)
        b.Position         = UDim2.new(1, xOff, 0.5, -14)
        b.BackgroundColor3 = bgColor
        b.BorderSizePixel  = 0
        b.Text             = text
        b.TextColor3       = T.Text
        b.TextSize         = 13
        b.Font             = Enum.Font.GothamBold
        b.AutoButtonColor  = false
        b.Parent           = Header
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent       = b
        return b
    end

    local MinBtn   = MakeHdrBtn("—", Color3.fromRGB(80, 80, 80), -76)
    local CloseBtn = MakeHdrBtn("✕", Color3.fromRGB(180, 30, 30), -44)

    local isMin = false
    local fullH = Panel.Size

    MinBtn.MouseButton1Click:Connect(function()
        isMin = not isMin
        if isMin then
            Tween(Panel, {Size = UDim2.new(0, 360, 0, 56)}, 0.3):Play()
            MinBtn.Text = "+"
        else
            Tween(Panel, {Size = fullH}, 0.3, Enum.EasingStyle.Back):Play()
            MinBtn.Text = "—"
        end
    end)

    CloseBtn.MouseButton1Click:Connect(function()
        Tween(Panel, {Size = UDim2.new(0, 0, 0, 0)}, 0.25):Play()
        task.delay(0.25, function()
            Panel.Visible = false
            panelOpen     = false
        end)
    end)

    -- Drag do painel
    do
        local drag, ds, sp = false, nil, nil
        Header.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                drag = true
                ds   = inp.Position
                sp   = Panel.Position
            end
        end)
        Header.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if drag and inp.UserInputType == Enum.UserInputType.MouseMovement then
                local d = inp.Position - ds
                Panel.Position = UDim2.new(
                    sp.X.Scale, sp.X.Offset + d.X,
                    sp.Y.Scale, sp.Y.Offset + d.Y
                )
            end
        end)
    end

    -- ══════════════════════════════════════════════════════════════
    --  STATUS BAR
    -- ══════════════════════════════════════════════════════════════
    local StatusBar = Instance.new("Frame")
    StatusBar.Size             = UDim2.new(1, -20, 0, 26)
    StatusBar.Position         = UDim2.new(0, 10, 0, 62)
    StatusBar.BackgroundColor3 = T.BgAlt
    StatusBar.BorderSizePixel  = 0
    StatusBar.Parent           = Panel

    local SBCorner = Instance.new("UICorner")
    SBCorner.CornerRadius = UDim.new(0, 6)
    SBCorner.Parent       = StatusBar

    local StatusLbl = Instance.new("TextLabel")
    StatusLbl.Name                 = "StatusLbl"
    StatusLbl.Size                 = UDim2.new(1, -10, 1, 0)
    StatusLbl.Position             = UDim2.new(0, 8, 0, 0)
    StatusLbl.BackgroundTransparency = 1
    StatusLbl.Text                 = "[ ONLINE ]  Bem-vindo, " .. Player.Name
    StatusLbl.TextColor3           = T.Green
    StatusLbl.TextSize             = 11
    StatusLbl.Font                 = Enum.Font.GothamSemibold
    StatusLbl.TextXAlignment       = Enum.TextXAlignment.Left
    StatusLbl.Parent               = StatusBar

    -- ══════════════════════════════════════════════════════════════
    --  TABS (CATEGORIAS)
    -- ══════════════════════════════════════════════════════════════
    local TabBar = Instance.new("Frame")
    TabBar.Size             = UDim2.new(1, -20, 0, 32)
    TabBar.Position         = UDim2.new(0, 10, 0, 94)
    TabBar.BackgroundColor3 = T.BgAlt
    TabBar.BorderSizePixel  = 0
    TabBar.Parent           = Panel

    local TBCorner = Instance.new("UICorner")
    TBCorner.CornerRadius = UDim.new(0, 8)
    TBCorner.Parent       = TabBar

    local TBLayout = Instance.new("UIListLayout")
    TBLayout.FillDirection  = Enum.FillDirection.Horizontal
    TBLayout.SortOrder      = Enum.SortOrder.LayoutOrder
    TBLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    TBLayout.Padding        = UDim.new(0, 4)
    TBLayout.Parent         = TabBar

    local TBPad = Instance.new("UIPadding")
    TBPad.PaddingLeft  = UDim.new(0, 4)
    TBPad.PaddingRight = UDim.new(0, 4)
    TBPad.PaddingTop   = UDim.new(0, 4)
    TBPad.PaddingBottom = UDim.new(0, 4)
    TBPad.Parent = TabBar

    -- ══════════════════════════════════════════════════════════════
    --  SCROLL CONTENT
    -- ══════════════════════════════════════════════════════════════
    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Name                 = "Scroll"
    Scroll.Size                 = UDim2.new(1, -20, 1, -140)
    Scroll.Position             = UDim2.new(0, 10, 0, 132)
    Scroll.BackgroundTransparency = 1
    Scroll.BorderSizePixel      = 0
    Scroll.ScrollBarThickness   = 4
    Scroll.ScrollBarImageColor3 = T.Red
    Scroll.CanvasSize           = UDim2.new(0, 0, 0, 0)
    Scroll.AutomaticCanvasSize  = Enum.AutomaticSize.Y
    Scroll.Parent               = Panel

    local ScrollLayout = Instance.new("UIListLayout")
    ScrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ScrollLayout.Padding   = UDim.new(0, 6)
    ScrollLayout.Parent    = Scroll

    local ScrollPad = Instance.new("UIPadding")
    ScrollPad.PaddingTop    = UDim.new(0, 4)
    ScrollPad.PaddingBottom = UDim.new(0, 12)
    ScrollPad.Parent        = Scroll

    -- ══════════════════════════════════════════════════════════════
    --  HELPERS DE CRIAÇÃO DE WIDGETS
    -- ══════════════════════════════════════════════════════════════

    -- Separador de seção
    local function MakeSection(label)
        local f = Instance.new("Frame")
        f.Size             = UDim2.new(1, 0, 0, 26)
        f.BackgroundColor3 = T.BgLight
        f.BorderSizePixel  = 0
        f.Parent           = Scroll
        local fc = Instance.new("UICorner")
        fc.CornerRadius = UDim.new(0, 6)
        fc.Parent       = f

        local line = Instance.new("Frame")
        line.Size             = UDim2.new(0, 3, 0.6, 0)
        line.Position         = UDim2.new(0, 0, 0.2, 0)
        line.BackgroundColor3 = T.Red
        line.BorderSizePixel  = 0
        line.Parent           = f
        local lc = Instance.new("UICorner")
        lc.CornerRadius = UDim.new(1, 0)
        lc.Parent       = line

        local lbl = Instance.new("TextLabel")
        lbl.Size                 = UDim2.new(1, -14, 1, 0)
        lbl.Position             = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text                 = label
        lbl.TextColor3           = T.Red
        lbl.TextSize             = 12
        lbl.Font                 = Enum.Font.GothamBold
        lbl.TextXAlignment       = Enum.TextXAlignment.Left
        lbl.Parent               = f

        return f
    end

    -- Toggle widget
    local ToggleRefs = {}  -- key => {btn frame, setFn}

    local function MakeToggle(key, label, desc, onEnable, onDisable)
        local f = Instance.new("Frame")
        f.Size             = UDim2.new(1, 0, 0, 52)
        f.BackgroundColor3 = T.BgAlt
        f.BorderSizePixel  = 0
        f.Parent           = Scroll

        local fc = Instance.new("UICorner")
        fc.CornerRadius = UDim.new(0, 8)
        fc.Parent       = f

        local fStroke = Instance.new("UIStroke")
        fStroke.Color        = T.Border
        fStroke.Thickness    = 1
        fStroke.Transparency = 0.5
        fStroke.Parent       = f

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size                 = UDim2.new(0.65, 0, 0, 20)
        nameLbl.Position             = UDim2.new(0, 12, 0, 8)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text                 = label
        nameLbl.TextColor3           = T.Text
        nameLbl.TextSize             = 14
        nameLbl.Font                 = Enum.Font.GothamSemibold
        nameLbl.TextXAlignment       = Enum.TextXAlignment.Left
        nameLbl.Parent               = f

        local descLbl = Instance.new("TextLabel")
        descLbl.Size                 = UDim2.new(0.65, 0, 0, 14)
        descLbl.Position             = UDim2.new(0, 12, 0, 29)
        descLbl.BackgroundTransparency = 1
        descLbl.Text                 = desc
        descLbl.TextColor3           = T.TextDim
        descLbl.TextSize             = 11
        descLbl.Font                 = Enum.Font.Gotham
        descLbl.TextXAlignment       = Enum.TextXAlignment.Left
        descLbl.Parent               = f

        -- Track
        local track = Instance.new("Frame")
        track.Size             = UDim2.new(0, 48, 0, 24)
        track.Position         = UDim2.new(1, -60, 0.5, -12)
        track.BackgroundColor3 = T.Off
        track.BorderSizePixel  = 0
        track.Parent           = f
        local tc2 = Instance.new("UICorner")
        tc2.CornerRadius = UDim.new(1, 0)
        tc2.Parent       = track

        local knob = Instance.new("Frame")
        knob.Size             = UDim2.new(0, 18, 0, 18)
        knob.Position         = UDim2.new(0, 3, 0.5, -9)
        knob.BackgroundColor3 = T.Text
        knob.BorderSizePixel  = 0
        knob.Parent           = track
        local kc = Instance.new("UICorner")
        kc.CornerRadius = UDim.new(1, 0)
        kc.Parent       = knob

        local enabled = false

        local function SetState(val)
            enabled       = val
            States[key]   = val
            if val then
                Tween(track, {BackgroundColor3 = T.Red}, 0.2):Play()
                Tween(knob,  {Position = UDim2.new(1, -21, 0.5, -9)}, 0.2):Play()
                Tween(fStroke, {Color = T.Red, Transparency = 0}, 0.2):Play()
                if onEnable then onEnable() end
            else
                Tween(track, {BackgroundColor3 = T.Off}, 0.2):Play()
                Tween(knob,  {Position = UDim2.new(0, 3, 0.5, -9)}, 0.2):Play()
                Tween(fStroke, {Color = T.Border, Transparency = 0.5}, 0.2):Play()
                if onDisable then onDisable() end
            end
        end

        local clickDetector = Instance.new("TextButton")
        clickDetector.Size                 = UDim2.new(1, 0, 1, 0)
        clickDetector.BackgroundTransparency = 1
        clickDetector.Text                 = ""
        clickDetector.Parent               = f

        clickDetector.MouseButton1Click:Connect(function()
            SetState(not enabled)
        end)
        clickDetector.MouseEnter:Connect(function()
            Tween(f, {BackgroundColor3 = T.BgAlt2}, 0.12):Play()
        end)
        clickDetector.MouseLeave:Connect(function()
            Tween(f, {BackgroundColor3 = T.BgAlt}, 0.12):Play()
        end)

        ToggleRefs[key] = { frame = f, set = SetState, get = function() return enabled end }
        return f, SetState
    end

    -- Slider widget
    local function MakeSlider(label, min, max, default, suffix, onChange)
        local f = Instance.new("Frame")
        f.Size             = UDim2.new(1, 0, 0, 62)
        f.BackgroundColor3 = T.BgAlt
        f.BorderSizePixel  = 0
        f.Parent           = Scroll

        local fc = Instance.new("UICorner")
        fc.CornerRadius = UDim.new(0, 8)
        fc.Parent       = f

        local fStroke = Instance.new("UIStroke")
        fStroke.Color        = T.Border
        fStroke.Thickness    = 1
        fStroke.Transparency = 0.5
        fStroke.Parent       = f

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size                 = UDim2.new(0.68, 0, 0, 20)
        nameLbl.Position             = UDim2.new(0, 12, 0, 8)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text                 = label
        nameLbl.TextColor3           = T.Text
        nameLbl.TextSize             = 13
        nameLbl.Font                 = Enum.Font.GothamSemibold
        nameLbl.TextXAlignment       = Enum.TextXAlignment.Left
        nameLbl.Parent               = f

        local valLbl = Instance.new("TextLabel")
        valLbl.Size                 = UDim2.new(0.28, 0, 0, 20)
        valLbl.Position             = UDim2.new(0.72, -12, 0, 8)
        valLbl.BackgroundTransparency = 1
        valLbl.Text                 = tostring(default) .. (suffix or "")
        valLbl.TextColor3           = T.Red
        valLbl.TextSize             = 13
        valLbl.Font                 = Enum.Font.GothamBold
        valLbl.TextXAlignment       = Enum.TextXAlignment.Right
        valLbl.Parent               = f

        local track = Instance.new("Frame")
        track.Size             = UDim2.new(1, -24, 0, 8)
        track.Position         = UDim2.new(0, 12, 0, 40)
        track.BackgroundColor3 = T.BgLight
        track.BorderSizePixel  = 0
        track.Parent           = f
        local trkC = Instance.new("UICorner")
        trkC.CornerRadius = UDim.new(1, 0)
        trkC.Parent       = track

        local pct0 = (default - min) / (max - min)

        local fill = Instance.new("Frame")
        fill.Size             = UDim2.new(pct0, 0, 1, 0)
        fill.BackgroundColor3 = T.Red
        fill.BorderSizePixel  = 0
        fill.Parent           = track
        local fillC = Instance.new("UICorner")
        fillC.CornerRadius = UDim.new(1, 0)
        fillC.Parent       = fill

        local fillG = Instance.new("UIGradient")
        fillG.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, T.RedBright),
            ColorSequenceKeypoint.new(1, T.RedDark),
        })
        fillG.Parent = fill

        local knob = Instance.new("Frame")
        knob.Size             = UDim2.new(0, 16, 0, 16)
        knob.Position         = UDim2.new(pct0, -8, 0.5, -8)
        knob.BackgroundColor3 = T.Text
        knob.BorderSizePixel  = 0
        knob.Parent           = track
        local kc = Instance.new("UICorner")
        kc.CornerRadius = UDim.new(1, 0)
        kc.Parent       = knob

        local kStroke = Instance.new("UIStroke")
        kStroke.Color     = T.Red
        kStroke.Thickness = 2
        kStroke.Parent    = knob

        local dragging = false
        local current  = default

        local function UpdateSlider(inp)
            local tp = track.AbsolutePosition.X
            local ts = track.AbsoluteSize.X
            local pct = math.clamp((inp.Position.X - tp) / ts, 0, 1)
            current = math.floor(min + (max - min) * pct + 0.5)
            Tween(fill,  {Size = UDim2.new(pct, 0, 1, 0)}, 0.05):Play()
            Tween(knob,  {Position = UDim2.new(pct, -8, 0.5, -8)}, 0.05):Play()
            valLbl.Text = tostring(current) .. (suffix or "")
            if onChange then onChange(current) end
        end

        track.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true; UpdateSlider(inp)
            end
        end)
        knob.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                UpdateSlider(inp)
            end
        end)
        UserInputService.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)

        return f
    end

    -- Botão de ação
    local function MakeButton(label, desc, btnText, callback)
        local f = Instance.new("Frame")
        f.Size             = UDim2.new(1, 0, 0, 48)
        f.BackgroundColor3 = T.BgAlt
        f.BorderSizePixel  = 0
        f.Parent           = Scroll

        local fc = Instance.new("UICorner")
        fc.CornerRadius = UDim.new(0, 8)
        fc.Parent       = f

        local fStroke = Instance.new("UIStroke")
        fStroke.Color        = T.Border
        fStroke.Thickness    = 1
        fStroke.Transparency = 0.5
        fStroke.Parent       = f

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size                 = UDim2.new(0.6, 0, 0, 18)
        nameLbl.Position             = UDim2.new(0, 12, 0, 7)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text                 = label
        nameLbl.TextColor3           = T.Text
        nameLbl.TextSize             = 13
        nameLbl.Font                 = Enum.Font.GothamSemibold
        nameLbl.TextXAlignment       = Enum.TextXAlignment.Left
        nameLbl.Parent               = f

        local descLbl = Instance.new("TextLabel")
        descLbl.Size                 = UDim2.new(0.6, 0, 0, 13)
        descLbl.Position             = UDim2.new(0, 12, 0, 26)
        descLbl.BackgroundTransparency = 1
        descLbl.Text                 = desc
        descLbl.TextColor3           = T.TextDim
        descLbl.TextSize             = 10
        descLbl.Font                 = Enum.Font.Gotham
        descLbl.TextXAlignment       = Enum.TextXAlignment.Left
        descLbl.Parent               = f

        local btn = Instance.new("TextButton")
        btn.Size             = UDim2.new(0, 80, 0, 28)
        btn.Position         = UDim2.new(1, -92, 0.5, -14)
        btn.BackgroundColor3 = T.Red
        btn.BorderSizePixel  = 0
        btn.Text             = btnText or "EXECUTAR"
        btn.TextColor3       = T.Text
        btn.TextSize         = 11
        btn.Font             = Enum.Font.GothamBold
        btn.AutoButtonColor  = false
        btn.Parent           = f

        local bc = Instance.new("UICorner")
        bc.CornerRadius = UDim.new(0, 6)
        bc.Parent       = btn

        local bg2 = Instance.new("UIGradient")
        bg2.Color    = ColorSequence.new({
            ColorSequenceKeypoint.new(0, T.RedBright),
            ColorSequenceKeypoint.new(1, T.RedDark),
        })
        bg2.Rotation = 90
        bg2.Parent   = btn

        btn.MouseButton1Click:Connect(function()
            Tween(btn, {Size = UDim2.new(0, 74, 0, 24)}, 0.05):Play()
            task.wait(0.06)
            Tween(btn, {Size = UDim2.new(0, 80, 0, 28)}, 0.1):Play()
            if callback then callback() end
        end)
        btn.MouseEnter:Connect(function() Tween(btn, {BackgroundColor3 = T.RedBright}, 0.12):Play() end)
        btn.MouseLeave:Connect(function() Tween(btn, {BackgroundColor3 = T.Red}, 0.12):Play() end)

        return f
    end

    -- Input de texto (para digitar nome)
    local function MakeTextInput(placeholder, onChange)
        local f = Instance.new("Frame")
        f.Size             = UDim2.new(1, 0, 0, 36)
        f.BackgroundColor3 = T.BgAlt
        f.BorderSizePixel  = 0
        f.Parent           = Scroll

        local fc = Instance.new("UICorner")
        fc.CornerRadius = UDim.new(0, 8)
        fc.Parent       = f

        local fStroke = Instance.new("UIStroke")
        fStroke.Color        = T.Border
        fStroke.Thickness    = 1
        fStroke.Transparency = 0.5
        fStroke.Parent       = f

        local box = Instance.new("TextBox")
        box.Size                 = UDim2.new(1, -20, 1, -10)
        box.Position             = UDim2.new(0, 10, 0, 5)
        box.BackgroundTransparency = 1
        box.PlaceholderText      = placeholder
        box.PlaceholderColor3    = T.TextTiny
        box.Text                 = ""
        box.TextColor3           = T.Text
        box.TextSize             = 13
        box.Font                 = Enum.Font.Gotham
        box.TextXAlignment       = Enum.TextXAlignment.Left
        box.ClearTextOnFocus     = false
        box.Parent               = f

        box.FocusLost:Connect(function()
            if onChange then onChange(box.Text) end
        end)
        box.Focused:Connect(function()
            Tween(fStroke, {Color = T.Red, Transparency = 0}, 0.15):Play()
        end)
        box:GetPropertyChangedSignal("Text"):Connect(function()
            if onChange then onChange(box.Text) end
        end)

        return f, box
    end

    -- ══════════════════════════════════════════════════════════════
    --  TABS SYSTEM
    -- ══════════════════════════════════════════════════════════════
    local TabPages = {}
    local ActiveTab = nil

    local tabNames = {"MOVE", "COMBATE", "VISUAL", "PLAYERS", "CONFIG"}
    local tabBtns  = {}

    for i, name in ipairs(tabNames) do
        local tb = Instance.new("TextButton")
        tb.Size             = UDim2.new(0, 60, 1, -8)
        tb.BackgroundColor3 = T.BgLight
        tb.BorderSizePixel  = 0
        tb.Text             = name
        tb.TextColor3       = T.TextDim
        tb.TextSize         = 10
        tb.Font             = Enum.Font.GothamBold
        tb.AutoButtonColor  = false
        tb.LayoutOrder      = i
        tb.Parent           = TabBar

        local tbc = Instance.new("UICorner")
        tbc.CornerRadius = UDim.new(0, 6)
        tbc.Parent       = tb

        tabBtns[name] = tb
        TabPages[name] = {}

        tb.MouseButton1Click:Connect(function()
            -- Esconder todos os itens
            for _, items in pairs(TabPages) do
                for _, item in ipairs(items) do
                    item.Visible = false
                end
            end
            -- Resetar todos os tabs
            for _, b in pairs(tabBtns) do
                Tween(b, {BackgroundColor3 = T.BgLight, TextColor3 = T.TextDim}, 0.15):Play()
            end
            -- Mostrar tab ativo
            for _, item in ipairs(TabPages[name]) do
                item.Visible = true
            end
            Tween(tb, {BackgroundColor3 = T.Red, TextColor3 = T.Text}, 0.15):Play()
            ActiveTab = name
        end)
    end

    -- Helper para adicionar item a um tab
    local function AddToTab(tabName, item)
        table.insert(TabPages[tabName], item)
        item.Visible = false  -- começa escondido
    end

    -- ══════════════════════════════════════════════════════════════
    --  ABA: MOVE
    -- ══════════════════════════════════════════════════════════════
    do
        local sec1 = MakeSection("MOVIMENTO")
        AddToTab("MOVE", sec1)

        local flyToggle = MakeToggle("Fly", "Fly", "Voe livremente — WASD+Space+Ctrl+Q(turbo)",
            StartFly, StopFly)
        AddToTab("MOVE", flyToggle)

        local noclipToggle = MakeToggle("Noclip", "Noclip", "Atravesse paredes e objetos",
            StartNoclip, StopNoclip)
        AddToTab("MOVE", noclipToggle)

        local ijToggle = MakeToggle("InfiniteJump", "Infinite Jump", "Pule infinitamente no ar",
            StartInfJump, StopInfJump)
        AddToTab("MOVE", ijToggle)

        local avToggle = MakeToggle("AntiVoid", "Anti-Void", "Salvo automaticamente do void",
            StartAntiVoid, StopAntiVoid)
        AddToTab("MOVE", avToggle)

        local sec2 = MakeSection("VELOCIDADE E PULO")
        AddToTab("MOVE", sec2)

        local flySlider = MakeSlider("Velocidade de Voo", 10, 300, 80, " st/s", function(v)
            Cfg.FlySpeed = v
        end)
        AddToTab("MOVE", flySlider)

        local wsSlider = MakeSlider("Walk Speed", 16, 500, 16, " st/s", function(v)
            Cfg.WalkSpeed = v
            local h = Hum()
            if h then h.WalkSpeed = v end
        end)
        AddToTab("MOVE", wsSlider)

        local jpSlider = MakeSlider("Jump Power", 50, 500, 100, "", function(v)
            Cfg.JumpPower = v
            local h = Hum()
            if h then h.JumpPower = v end
        end)
        AddToTab("MOVE", jpSlider)

        local ctpToggle = MakeToggle("ClickTP", "Click Teleport", "Ctrl+Clique para teleportar",
            StartClickTP, StopClickTP)
        AddToTab("MOVE", ctpToggle)
    end

    -- ══════════════════════════════════════════════════════════════
    --  ABA: COMBATE
    -- ══════════════════════════════════════════════════════════════
    do
        local secC = MakeSection("COMBATE & ATAQUE")
        AddToTab("COMBATE", secC)

        -- Fling Toggle
        local flingToggle = MakeToggle("Fling", "Fling Auto", "Joga jogadores próximos para fora do mapa",
            StartFling, StopFling)
        AddToTab("COMBATE", flingToggle)

        -- Fling Force Slider
        local ffSlider = MakeSlider("Força do Fling", 100, 5000, 1000, "x", function(v)
            Cfg.FlingForce = v * 1000
        end)
        AddToTab("COMBATE", ffSlider)

        -- DropKick com nome
        local secDK = MakeSection("DROP KICK")
        AddToTab("COMBATE", secDK)

        local _, dkBox = MakeTextInput("Digite o nome do alvo (DropKick)...", function(t)
            -- só guarda
        end)
        AddToTab("COMBATE", dkBox.Parent)

        local dkBtn = MakeButton("DropKick", "Dano + lançamento no alvo digitado", "DROPKICK!", function()
            local target = FindPlayer(dkBox.Text)
            DropKick(target)
        end)
        AddToTab("COMBATE", dkBtn)

        local dkDmgSlider = MakeSlider("Dano do DropKick", 5, 200, 50, " hp", function(v)
            Cfg.DropKickDmg = v
        end)
        AddToTab("COMBATE", dkDmgSlider)

        -- Fling manual com nome
        local secFM = MakeSection("FLING MANUAL")
        AddToTab("COMBATE", secFM)

        local _, fmBox = MakeTextInput("Digite o nome do alvo (Fling)...", function(t) end)
        AddToTab("COMBATE", fmBox.Parent)

        local fmBtn = MakeButton("Fling Manual", "Fling no jogador digitado", "FLING!", function()
            local target = FindPlayer(fmBox.Text)
            FlingPlayer(target)
        end)
        AddToTab("COMBATE", fmBtn)

        local secDef = MakeSection("DEFESA")
        AddToTab("COMBATE", secDef)

        local godToggle = MakeToggle("Godmode", "Godmode", "HP infinito (client-side)",
            StartGodmode, StopGodmode)
        AddToTab("COMBATE", godToggle)

        local akToggle = MakeToggle("AntiKick", "Anti-Kick", "Bloqueia kicks (requer executor)",
            StartAntiKick, StopAntiKick)
        AddToTab("COMBATE", akToggle)
    end

    -- ══════════════════════════════════════════════════════════════
    --  ABA: VISUAL
    -- ══════════════════════════════════════════════════════════════
    do
        local secV = MakeSection("VISUAL & PERCEPÇÃO")
        AddToTab("VISUAL", secV)

        local espToggle = MakeToggle("ESP", "ESP (Wallhack)", "Veja jogadores através das paredes",
            StartESP, StopESP)
        AddToTab("VISUAL", espToggle)

        local fbToggle = MakeToggle("FullBright", "FullBright", "Iluminação máxima, sem escuridão",
            StartFullBright, StopFullBright)
        AddToTab("VISUAL", fbToggle)

        local invToggle = MakeToggle("Invisible", "Invisibilidade", "Fique completamente invisível",
            StartInvisible, StopInvisible)
        AddToTab("VISUAL", invToggle)

        local secFX = MakeSection("EFEITOS")
        AddToTab("VISUAL", secFX)

        local rainbowToggle = MakeToggle("Rainbow", "Rainbow Character", "Muda a cor do personagem constantemente",
            function()
                local hue = 0
                Conn["Rainbow"] = RunService.Heartbeat:Connect(function(dt)
                    if not States.Rainbow then return end
                    hue = (hue + dt * 0.4) % 1
                    local col = Color3.fromHSV(hue, 1, 1)
                    local c = Char()
                    if c then
                        for _, p in ipairs(c:GetDescendants()) do
                            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                                p.Color = col
                            end
                        end
                    end
                end)
                Notify("Rainbow", "ATIVADO", 2)
            end,
            function()
                Disconnect("Rainbow")
                Notify("Rainbow", "DESATIVADO", 2)
            end)
        States.Rainbow = false
        AddToTab("VISUAL", rainbowToggle)
    end

    -- ══════════════════════════════════════════════════════════════
    --  ABA: PLAYERS
    -- ══════════════════════════════════════════════════════════════
    do
        local secP = MakeSection("FOLLOW / TELEPORT")
        AddToTab("PLAYERS", secP)

        local _, followBox = MakeTextInput("Nome do jogador para seguir (em branco = mais próximo)...", function(t)
            Cfg.FollowName = t
        end)
        AddToTab("PLAYERS", followBox.Parent)

        local followToggle = MakeToggle("Follow", "Follow Player", "Siga o jogador especificado ou o mais próximo",
            function()
                local ok = StartFollow()
                if not ok then
                    ToggleRefs["Follow"] and ToggleRefs["Follow"].set(false)
                end
            end,
            StopFollow)
        AddToTab("PLAYERS", followToggle)

        local secTP = MakeSection("TELEPORT PARA JOGADOR")
        AddToTab("PLAYERS", secTP)

        local _, tpBox = MakeTextInput("Nome do jogador para teleportar...", function(t) end)
        AddToTab("PLAYERS", tpBox.Parent)

        local tpBtn = MakeButton("Ir Para Jogador", "Teleporte instantâneo até ele", "IR!", function()
            TeleportToPlayer(FindPlayer(tpBox.Text))
        end)
        AddToTab("PLAYERS", tpBtn)

        local secMisc = MakeSection("AÇÕES EM JOGADORES")
        AddToTab("PLAYERS", secMisc)

        local _, miscBox = MakeTextInput("Nome do alvo para ações abaixo...", function(t) end)
        AddToTab("PLAYERS", miscBox.Parent)

        local tpToBtn = MakeButton("Trazer Jogador", "TP o alvo até você", "TRAZER", function()
            local target = FindPlayer(miscBox.Text)
            if not target or not target.Character then
                Notify("Trazer", "Jogador nao encontrado!", 2) return
            end
            local tr = target.Character:FindFirstChild("HumanoidRootPart")
            local r  = Root()
            if tr and r then
                tr.CFrame = r.CFrame * CFrame.new(2, 0, 0)
                Notify("Trazer", target.Name .. " foi trazido!", 2)
            end
        end)
        AddToTab("PLAYERS", tpToBtn)

        local killBtn = MakeButton("Kill Player", "Tenta matar o alvo (client-side)", "KILL", function()
            local target = FindPlayer(miscBox.Text)
            if not target or not target.Character then
                Notify("Kill", "Jogador nao encontrado!", 2) return
            end
            local th = target.Character:FindFirstChildOfClass("Humanoid")
            if th then
                th.Health = 0
                Notify("Kill", "Kill em: " .. target.Name, 2)
            end
        end)
        AddToTab("PLAYERS", killBtn)
    end

    -- ══════════════════════════════════════════════════════════════
    --  ABA: CONFIG
    -- ══════════════════════════════════════════════════════════════
    do
        local secCfg = MakeSection("PAINEL & SISTEMA")
        AddToTab("CONFIG", secCfg)

        local resetBtn = MakeButton("Reset Character", "Reinicia seu personagem agora", "RESET", function()
            local h = Hum()
            if h then h.Health = 0 end
        end)
        AddToTab("CONFIG", resetBtn)

        local rejoinBtn = MakeButton("Rejoin Server", "Reconecta ao servidor atual", "REJOIN", function()
            local TS = game:GetService("TeleportService")
            TS:Teleport(game.PlaceId, Player)
        end)
        AddToTab("CONFIG", rejoinBtn)

        local copyPosBtn = MakeButton("Copiar Posição", "Copia suas coordenadas atuais", "COPIAR", function()
            local r = Root()
            if r then
                local p  = r.Position
                local ps = string.format("X:%.1f Y:%.1f Z:%.1f", p.X, p.Y, p.Z)
                if setclipboard then
                    setclipboard(ps)
                    Notify("Posição", "Copiado: " .. ps, 4)
                else
                    Notify("Posição", ps, 5)
                end
            end
        end)
        AddToTab("CONFIG", copyPosBtn)

        local gotoRandBtn = MakeButton("Jogador Aleatório", "Teleporta para um jogador aleatório", "IR", function()
            local plrs = Players:GetPlayers()
            local targets = {}
            for _, p in ipairs(plrs) do
                if p ~= Player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    table.insert(targets, p)
                end
            end
            if #targets == 0 then Notify("Random", "Nenhum jogador disponivel!", 2) return end
            local rp = targets[math.random(1, #targets)]
            local r  = Root()
            if r then
                r.CFrame = rp.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 4)
                Notify("Random", "Teleportado para: " .. rp.Name, 2)
            end
        end)
        AddToTab("CONFIG", gotoRandBtn)

        local secSz = MakeSection("TAMANHO DO PAINEL")
        AddToTab("CONFIG", secSz)

        local widthSlider = MakeSlider("Largura do Painel", 280, 500, 360, "px", function(v)
            local cur = Panel.Size
            Panel.Size = UDim2.new(0, v, 0, cur.Y.Offset)
            fullH      = Panel.Size
        end)
        AddToTab("CONFIG", widthSlider)

        local heightSlider = MakeSlider("Altura do Painel", 300, 700, 540, "px", function(v)
            local cur = Panel.Size
            Panel.Size = UDim2.new(0, cur.X.Offset, 0, v)
            fullH      = Panel.Size
        end)
        AddToTab("CONFIG", heightSlider)

        local secKB = MakeSection("ATALHOS DE TECLADO")
        AddToTab("CONFIG", secKB)

        local kbInfo = Instance.new("TextLabel")
        kbInfo.Size                 = UDim2.new(1, 0, 0, 90)
        kbInfo.BackgroundColor3     = T.BgAlt
        kbInfo.BorderSizePixel      = 0
        kbInfo.Text                 = "RightShift — Mostrar/Esconder painel\nAlt+F — Toggle Fly\nAlt+N — Toggle Noclip\nAlt+E — Toggle ESP\nAlt+I — Toggle Invisível\nCtrl+Click — Click TP (quando ativo)"
        kbInfo.TextColor3           = T.TextDim
        kbInfo.TextSize             = 11
        kbInfo.Font                 = Enum.Font.Gotham
        kbInfo.TextXAlignment       = Enum.TextXAlignment.Left
        kbInfo.TextYAlignment       = Enum.TextYAlignment.Top
        kbInfo.Parent               = Scroll
        AddToTab("CONFIG", kbInfo)

        local kbCorner = Instance.new("UICorner")
        kbCorner.CornerRadius = UDim.new(0, 8)
        kbCorner.Parent       = kbInfo

        local kbPad = Instance.new("UIPadding")
        kbPad.PaddingLeft  = UDim.new(0, 10)
        kbPad.PaddingTop   = UDim.new(0, 8)
        kbPad.Parent       = kbInfo
    end

    -- ══════════════════════════════════════════════════════════════
    --  ATIVAR PRIMEIRA ABA
    -- ══════════════════════════════════════════════════════════════
    tabBtns["MOVE"].MouseButton1Click:Fire()

    -- ══════════════════════════════════════════════════════════════
    --  KEYBINDS GLOBAIS
    -- ══════════════════════════════════════════════════════════════
    UserInputService.InputBegan:Connect(function(inp, gp)
        if gp then return end

        -- RightShift = mostrar/esconder
        if inp.KeyCode == Enum.KeyCode.RightShift then
            if panelOpen then
                panelOpen = false
                local tw = Tween(Panel, {Size = UDim2.new(0, 0, 0, 0)}, 0.25)
                tw:Play()
                task.delay(0.25, function() Panel.Visible = false end)
            else
                panelOpen     = true
                Panel.Visible = true
                Panel.Size    = UDim2.new(0, 0, 0, 0)
                Tween(Panel, {Size = UDim2.new(0, 360, 0, 540)}, 0.35, Enum.EasingStyle.Back):Play()
            end
        end

        local alt = UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt)
            or UserInputService:IsKeyDown(Enum.KeyCode.RightAlt)

        if alt and inp.KeyCode == Enum.KeyCode.F then
            local ref = ToggleRefs["Fly"]
            if ref then ref.set(not ref.get()) end
        end
        if alt and inp.KeyCode == Enum.KeyCode.N then
            local ref = ToggleRefs["Noclip"]
            if ref then ref.set(not ref.get()) end
        end
        if alt and inp.KeyCode == Enum.KeyCode.E then
            local ref = ToggleRefs["ESP"]
            if ref then ref.set(not ref.get()) end
        end
        if alt and inp.KeyCode == Enum.KeyCode.I then
            local ref = ToggleRefs["Invisible"]
            if ref then ref.set(not ref.get()) end
        end
    end)

    -- ══════════════════════════════════════════════════════════════
    --  RECONECTAR APÓS RESPAWN
    -- ══════════════════════════════════════════════════════════════
    Player.CharacterAdded:Connect(function(newChar)
        task.wait(0.8)
        local h = newChar:WaitForChild("Humanoid", 5)
        if h then
            h.WalkSpeed = Cfg.WalkSpeed
            h.JumpPower = Cfg.JumpPower
        end

        -- Reativar funções que estavam ON
        if States.AntiVoid    then StartAntiVoid()   end
        if States.InfiniteJump then StartInfJump()   end
        if States.Godmode     then StartGodmode()    end
        if States.Invisible   then StartInvisible()  end
        if States.Noclip      then StartNoclip()     end
        if States.Fly         then StartFly()        end
        if States.FullBright  then StartFullBright() end
    end)

    -- Animação de entrada do painel (controlada pelo float btn)
    Notify("SYNC ADMIN v3.0", "Carregado! Clique no botao S ou RightShift para abrir", 5)

    return Screen
end

-- ═══════════════════════════════════════════════════════════════════════
--  INICIALIZAÇÃO
-- ═══════════════════════════════════════════════════════════════════════
local ok, err = pcall(BuildUI)
if not ok then
    warn("[SyncAdmin v3] Erro ao carregar UI: " .. tostring(err))
end

--[[
    ═══════════════════════════════════════════════════════════════════
    SYNC ADMIN v3.0 ULTRA PRO — CONTROLES

    BOTAO DISCRETO:
    • Clique no botao "S" flutuante para abrir/fechar o painel
    • O botao pode ser arrastado para qualquer posição da tela

    ATALHOS DE TECLADO:
    • RightShift    — Mostrar/Esconder painel
    • Alt + F       — Toggle Fly
    • Alt + N       — Toggle Noclip
    • Alt + E       — Toggle ESP
    • Alt + I       — Toggle Invisível
    • Ctrl + Click  — Teleportar (quando ClickTP ativo)

    CONTROLES DE VOO (CORRIGIDO):
    • W / A / S / D — Movimento em todas as direções
    • Space          — Subir
    • Ctrl / Shift   — Descer
    • Q (segurado)   — Turbo (3x velocidade)

    CATEGORIAS:
    • MOVE    — Fly, Noclip, InfJump, AntiVoid, Velocidades, ClickTP
    • COMBATE — Fling, DropKick, Godmode, AntiKick
    • VISUAL  — ESP, FullBright, Invisível, Rainbow
    • PLAYERS — Follow com nome, TeleportTo, Trazer, Kill
    • CONFIG  — Ações rápidas, Tamanho do painel, Atalhos

    AVISO: Script para fins educacionais. Use por sua conta e risco.
    ═══════════════════════════════════════════════════════════════════
--]]
