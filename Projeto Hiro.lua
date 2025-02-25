local Material = loadstring(game:HttpGet("https://raw.githubusercontent.com/Kinlei/MaterialLua/master/Module.lua"))()

local X = Material.Load({
    Title = "Sunga do Poi",
    Style = 3,
    SizeX = 500,
    SizeY = 350,
    Theme = "Dark"
})

local VisualTab = X.New({ Title = "VISUAL" })
local AimTab = X.New({ Title = "MIRA" })
local PlayerTab = X.New({ Title = "JOGADOR" })
local VehicleTab = X.New({ Title = "VEICULO" })

-- VISUAL ESP --------------------------------------------------------------------------
local players = game:GetService("Players")
local localPlayer = players.LocalPlayer
local runService = game:GetService("RunService")
local espEnabled = false
local espConnections = {}

local function createESPBox(player)
    if not player.Character then
        player.CharacterAdded:Wait()
    end

    if player.Character and not player.Character:FindFirstChild(player.Name .. "_ESP") then
        local highlight = Instance.new("Highlight")
        highlight.Name = player.Name .. "_ESP"
        highlight.Adornee = player.Character
        highlight.FillTransparency = 1
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

        if player.Team then
            highlight.OutlineColor = player.Team.TeamColor.Color
        else
            highlight.OutlineColor = Color3.new(1, 1, 1)
        end

        highlight.Parent = player.Character
    end
end
local function enableESP()
    espEnabled = true

    for _, player in pairs(players:GetPlayers()) do
        if player ~= localPlayer then
            createESPBox(player)
        end
    end

    espConnections[#espConnections + 1] = players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function()
            if espEnabled then
                createESPBox(player)
            end
        end)
    end)

    espConnections[#espConnections + 1] = runService.RenderStepped:Connect(function()
        for _, player in pairs(players:GetPlayers()) do
            if player ~= localPlayer then
                createESPBox(player)
            end
        end
    end)
end
local function disableESP()
    espEnabled = false

    for _, conn in ipairs(espConnections) do
        conn:Disconnect()
    end
    espConnections = {}

    for _, player in pairs(players:GetPlayers()) do
        if player.Character then
            local esp = player.Character:FindFirstChild(player.Name .. "_ESP")
            if esp then esp:Destroy() end
        end
    end
end

VisualTab.Toggle({
    Text = "ESP",
    Callback = function(Value)
        if Value then
            enableESP()
        else
            disableESP()
        end
        print("ESP:", Value)
    end,
    Enabled = false,
    Menu = {
        Information = function(self)
            X.Banner({ Text = "Veja os jogadores atrás de qualquer objeto." })
        end
    }
})

-- VISUAL ESP LINES --------------------------------------------------------------------
local Camera = workspace.CurrentCamera
local espLinesEnabled = false
local espLines = {}
local updateConnection

local function createLine(player)
    if player ~= localPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local line = Drawing.new("Line")
        line.Thickness = 2
        line.Color = Color3.new(0, 0, 0)
        line.Transparency = 1
        line.Visible = true
        espLines[player] = line
    end
end
local function updateLines()
    for player, line in pairs(espLines) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local rootPart = player.Character.HumanoidRootPart
            local screenPosition, onScreen = Camera:WorldToViewportPoint(rootPart.Position)

            if onScreen then
                line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                line.To = Vector2.new(screenPosition.X, screenPosition.Y)
                line.Visible = true
            else
                line.Visible = false
            end
        else
            line.Visible = false
        end
    end
end
local function enableESPLines()
    espLinesEnabled = true

    for _, player in pairs(players:GetPlayers()) do
        createLine(player)
    end

    updateConnection = runService.RenderStepped:Connect(function()
        updateLines()
        task.wait(0.05)
    end)

    players.PlayerAdded:Connect(createLine)
end
local function disableESPLines()
    espLinesEnabled = false

    if updateConnection then
        updateConnection:Disconnect()
        updateConnection = nil
    end

    for _, line in pairs(espLines) do
        line:Remove()
    end

    espLines = {}
end

VisualTab.Toggle({
    Text = "ESP Line",
    Callback = function(Value)
        if Value then
            enableESPLines()
        else
            disableESPLines()
        end
        print("ESP Line:", Value)
    end,
    Enabled = false,
    Menu = {
        Information = function(self)
            X.Banner({ Text = "Linhas guiadas a todos jogadores da sessão." })
        end
    }
})

-- VISUAL ESP BOX ----------------------------------------------------------------------
local espEnabled = false
local espBoxes = {}

local function createESPBox(player)
    if player == localPlayer then return end

    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = Color3.new(0, 0, 0)
    box.Thickness = 2
    box.Filled = false

    espBoxes[player] = box
end
local function removeESPBox(player)
    if espBoxes[player] then
        espBoxes[player]:Remove()
        espBoxes[player] = nil
    end
end
local function updateESP()
    for player, box in pairs(espBoxes) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")

            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                local sizeX = 80 
                local sizeY = 120 

                local boxPosition = Vector2.new(pos.X - sizeX / 2, pos.Y - sizeY / 2)

                box.Size = Vector2.new(sizeX, sizeY)
                box.Position = boxPosition
                box.Visible = true
            else
                box.Visible = false
            end
        else
            box.Visible = false
        end
    end
end
local function enableESP()
    espEnabled = true

    for _, player in pairs(players:GetPlayers()) do
        if player ~= localPlayer then
            createESPBox(player)
        end
    end

    players.PlayerAdded:Connect(function(player)
        createESPBox(player)
    end)

    runService.RenderStepped:Connect(updateESP)
end
local function disableESP()
    espEnabled = false
    for _, box in pairs(espBoxes) do
        box:Remove()
    end
    espBoxes = {}
end

VisualTab.Toggle({
    Text = "ESP Box",
    Callback = function(Value)
        if Value then
            enableESP()
        else
            disableESP()
        end
        print("ESP Box:", Value)
    end,
    Enabled = false,
    Menu = {
        Information = function(self)
            X.Banner({ Text = "Veja jogadores através de paredes com caixas 2D." })
        end
    }
})

-- VISUAL MIRA -------------------------------------------------------------------------
VisualTab.Toggle({
    Text = "Crosshair",
    Callback = function(Value)
        local player = game:GetService("Players").LocalPlayer
        if Value then
            local screenGui = Instance.new("ScreenGui")
            screenGui.Name = "MiraScreenGui"
            screenGui.Parent = player.PlayerGui

            local cruzHorizontal = Instance.new("Frame")
            cruzHorizontal.Size = UDim2.new(0, 8, 0, 0.4)
            cruzHorizontal.Position = UDim2.new(0.513, -25, 0.472, 0)
            cruzHorizontal.AnchorPoint = Vector2.new(0.5, 0.5)
            cruzHorizontal.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            cruzHorizontal.Parent = screenGui

            local cruzVertical = Instance.new("Frame")
            cruzVertical.Size = UDim2.new(0, 0.4, 0, 8)
            cruzVertical.Position = UDim2.new(0.4999, 0, 0.496, -25)
            cruzVertical.AnchorPoint = Vector2.new(0.5, 0.5)
            cruzVertical.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            cruzVertical.Parent = screenGui
        else
            if player.PlayerGui:FindFirstChild("MiraScreenGui") then
                player.PlayerGui.MiraScreenGui:Destroy()
            end
        end
        print("Crosshair:", Value)
    end,
    Enabled = false,
    Menu = {
        Information = function(self)
            X.Banner({ Text = "Mira no centro da tela (Cruz)." })
        end
    }
})

-- MIRA AIMBOT -------------------------------------------------------------------------
local aimlockEnabled = false
local UserInputService = game:GetService("UserInputService")
local smoothness = 0.1
local aimConnection

local function findClosestPlayer()
    local localPlayer = players.LocalPlayer
    local closestPlayer = nil
    local shortestDistance = math.huge

    for _, player in ipairs(players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local head = player.Character.Head
            local distance = (localPlayer.Character.HumanoidRootPart.Position - head.Position).magnitude

            if distance < shortestDistance then
                shortestDistance = distance
                closestPlayer = player
            end
        end
    end

    return closestPlayer
end
local function enableAimbot()
    if aimConnection then aimConnection:Disconnect() end
    aimlockEnabled = true
    aimConnection = runService.RenderStepped:Connect(function()
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) and aimlockEnabled then
            local closestPlayer = findClosestPlayer()

            if closestPlayer and closestPlayer.Character and closestPlayer.Character:FindFirstChild("Head") then
                local head = closestPlayer.Character.Head
                local targetPosition = CFrame.new(Camera.CFrame.Position, head.Position)

                Camera.CFrame = Camera.CFrame:Lerp(targetPosition, smoothness)
            end
        end
    end)
end
local function disableAimbot()
    aimlockEnabled = false
    if aimConnection then
        aimConnection:Disconnect()
        aimConnection = nil
    end
end

AimTab.Toggle({
    Text = "Aimbot",
    Callback = function(Value)
        if Value then
            enableAimbot()
        else
            disableAimbot()
        end
        print("Aimbot:", Value)
    end,
    Enabled = false,
    Menu = {
        Information = function(self)
            X.Banner({ Text = "Modo Guuh." })
        end
    }
})

-- MIRA AIMBOT SMOOTH ------------------------------------------------------------------
AimTab.Slider({
    Text = "Aimbot Smooth",
    Callback = function(Value)
        smoothness = Value / 100
    end,
    Min = 1,
    Max = 20,
    Def = 8,
    Menu = {
        Information = function(self)
            X.Banner({ Text = "Suavidade do Aimbot." })
        end
    }
})

-- JOGADOR PULO INF --------------------------------------------------------------------
PlayerTab.Toggle({
    Text = "Pulo Infinito",
    Callback = function(Value)
		_G.infinjump = Value
		
		if _G.infinJumpStarted == nil then
			_G.infinJumpStarted = true
			local plr = game:GetService('Players').LocalPlayer
			local m = plr:GetMouse()

			m.KeyDown:connect(function(k)
				if _G.infinjump then 
					if k:byte() == 32 then  
						local humanoide = game:GetService('Players').LocalPlayer.Character:FindFirstChildOfClass('Humanoid')
						if humanoide then
							humanoide:ChangeState('Jumping')  
							wait() 
							humanoide:ChangeState('Seated') 
						end
					end
				end
			end)
		end
    end,
    Enabled = false,
    Menu = {
        Information = function(self)
            X.Banner({ Text = "Cancelamento de pulo desabilitado." })
        end
    }
})

-- JOGADOR FLY -------------------------------------------------------------------------
PlayerTab.Button({
    Text = "Fly",
    Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/HiruZT/SungaDoPoi/refs/heads/main/Fly-HiruZT.lua"))()
    end,
    Menu = {
        Information = function(self)
            X.Banner({ Text = "Voar voar, Subir subir..." })
        end
    }
})

-- JOGADOR SPEED -----------------------------------------------------------------------
PlayerTab.Slider({
    Text = "Velocidade",
    Callback = function(Value)
		game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = Value
    end,
    Min = 8,
    Max = 80,
    Def = 16,
    Menu = {
        Information = function(self)
            X.Banner({ Text = "Define a velocidade do personagem." })
        end
    }
})

-- JOGADOR ALTURA PULO -----------------------------------------------------------------
PlayerTab.Slider({
    Text = "Altura do Pulo",
    Callback = function(Value)
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoid = character:FindFirstChildOfClass("Humanoid")

        if humanoid then
            humanoid.UseJumpPower = true
            humanoid.JumpPower = Value
            humanoid.Jump = true
        end
    end,
    Min = 40,
    Max = 800,
    Def = 50,
    Menu = {
        Information = function(self)
            X.Banner({ Text = "Define a altura do pulo." })
        end
    }
})

-- JOGADOR GRAVITY ---------------------------------------------------------------------
PlayerTab.Slider({
    Text = "Gravidade",
    Callback = function(Value)
		game.workspace.Gravity = Value
    end,
    Min = 0,
    Max = 800,
    Def = 196,
    Menu = {
        Information = function(self)
            X.Banner({ Text = "Define a gravidade do mundo." })
        end
    }
})

-- JOGADOR TP CLICK --------------------------------------------------------------------
PlayerTab.Toggle({
    Text = "TP Click",
    Callback = function(Value)
        _G.WRDClickTeleport = Value

        local player = game:GetService("Players").LocalPlayer
        local UserInputService = game:GetService("UserInputService")
        local mouse = player:GetMouse()

        if Value then
            if not _G.WRDClickEvent then
                _G.WRDClickEvent = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed then return end

                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if _G.WRDClickTeleport and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                            local character = player.Character
                            if character and character:FindFirstChild("HumanoidRootPart") then
                                local targetPosition = mouse.Hit.p
                                character:MoveTo(Vector3.new(targetPosition.X, targetPosition.Y, targetPosition.Z))
                            end
                        end
                    end
                end)
            end
        else
            if _G.WRDClickEvent then
                _G.WRDClickEvent:Disconnect()
                _G.WRDClickEvent = nil
            end
        end
    end,
    Enabled = false,
    Menu = {
        Information = function(self)
            X.Banner({ Text = "Teletransporte a onde quiser pressionando 'Ctrl + Click'." })
        end
    }
})

-- JOGADOR TP JOGADOR ------------------------------------------------------------------
PlayerTab.Button({
    Text = "TP Jogador",
    Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/HiruZT/SungaDoPoi/refs/heads/main/TP-PLayer"))()
    end,
    Menu = {
        Information = function(self)
            X.Banner({ Text = "Teletransporte para qualquer jogador do mundo." })
        end
    }
})

-- VEICULO MENU CARRO ------------------------------------------------------------------
VehicleTab.Button({
    Text = "Car Tuning (Universal)",
    Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/HiruZT/SungaDoPoi/refs/heads/main/CarTuning.lua"))()
    end,
    Menu = {
        Information = function(self)
            X.Banner({ Text = "Aceleração, Freio, InstaBreak, FlyCar, Molas" })
        end
    }
})

-- VEICULO VELOCIMETRO -----------------------------------------------------------------
