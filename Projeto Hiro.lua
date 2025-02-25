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
local UserInputService = game:GetService("UserInputService")
local players = game:GetService("Players")
local localPlayer = players.LocalPlayer
local runService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local esphEnabled = false
local esphConnections = {}

local function createESPhBox(player)
    if not player.Character then
        player.CharacterAdded:Wait()
    end

    if player.Character and not player.Character:FindFirstChild(player.Name .. "_ESPh") then
        local highlight = Instance.new("Highlight")
        highlight.Name = player.Name .. "_ESPh"
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
local function enableESPh()
    esphEnabled = true

    for _, player in pairs(players:GetPlayers()) do
        if player ~= localPlayer then
            createESPhBox(player)
        end
    end

    esphConnections[#esphConnections + 1] = players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function()
            if esphEnabled then
                createESPhBox(player)
            end
        end)
    end)

    esphConnections[#esphConnections + 1] = runService.RenderStepped:Connect(function()
        for _, player in pairs(players:GetPlayers()) do
            if player ~= localPlayer then
                createESPhBox(player)
            end
        end
    end)
end
local function disableESPh()
    esphEnabled = false

    for _, conn in ipairs(esphConnections) do
        conn:Disconnect()
    end
    esphConnections = {}

    for _, player in pairs(players:GetPlayers()) do
        if player.Character then
            local esph = player.Character:FindFirstChild(player.Name .. "_ESPh")
            if esph then esph:Destroy() end
        end
    end
end

VisualTab.Toggle({
    Text = "ESP Chams",
    Callback = function(Value)
        if Value then
            enableESPh()
        else
            disableESPh()
        end
    end,
    Enabled = false,
    Menu = {
        Information = function(self)
            X.Banner({ Text = "Veja os jogadores atrás de qualquer objeto." })
        end
    }
})

-- VISUAL ESP LINES --------------------------------------------------------------------
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
    box.Color = Color3.new(1, 1, 1) 
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
            local hrp = player.Character.HumanoidRootPart
            local head = player.Character:FindFirstChild("Head")
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")

            if head and humanoid then
                local feetPosition = hrp.Position - Vector3.new(0, humanoid.HipHeight, 0)
                local headPosition = head.Position 

                local feetScreen, feetVisible = Camera:WorldToViewportPoint(feetPosition)
                local headScreen, headVisible = Camera:WorldToViewportPoint(headPosition)

                if feetVisible and headVisible then
                    local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
                    local scaleFactor = 1000 / distance 

                    local height = math.abs(headScreen.Y - feetScreen.Y)
                    local width = height / 2.5 

                    local boxPosition = Vector2.new(headScreen.X - width / 2, headScreen.Y)

                    box.Size = Vector2.new(width, height)
                    box.Position = boxPosition
                    box.Visible = true
                else
                    box.Visible = false
                end
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
    Text = "ESP Box (Mini)",
    Callback = function(Value)
        if Value then
            enableESP()
        else
            disableESP()
        end
    end,
    Enabled = false,
    Menu = {
        Information = function(self)
            X.Banner({ Text = "Veja jogadores através de paredes com caixas 2D." })
        end
    }
})

-- VISUAL ESP VIDA ---------------------------------------------------------------------
local espVidaEnabled = false
local espVidaConnections = {}

local function createHealthESP(player)
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        local humanoid = player.Character:FindFirstChild("Humanoid")
        local head = player.Character:FindFirstChild("Head")

        if humanoid and head then
            local billboard = head:FindFirstChild("HealthESP")

            if not billboard then
                billboard = Instance.new("BillboardGui")
                billboard.Name = "HealthESP"
                billboard.Size = UDim2.new(4, 0, 1, 0)
                billboard.StudsOffset = Vector3.new(0, 2, 0)
                billboard.AlwaysOnTop = true

                local textLabel = Instance.new("TextLabel")
                textLabel.Size = UDim2.new(1, 0, 1, 0)
                textLabel.BackgroundTransparency = 1
                textLabel.TextColor3 = Color3.new(1, 1, 1)
                textLabel.TextStrokeTransparency = 0
                textLabel.Font = Enum.Font.SourceSansBold
                textLabel.TextScaled = true
                textLabel.Parent = billboard

                billboard.Parent = head
            end
        end
    end
end
local function updateHealthESP()
    for _, player in pairs(players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            local head = player.Character:FindFirstChild("Head")
            local billboard = head and head:FindFirstChild("HealthESP")

            if humanoid and billboard then
                local textLabel = billboard:FindFirstChildOfClass("TextLabel")
                if textLabel then
                    textLabel.Text = string.format("%d%%", (humanoid.Health / humanoid.MaxHealth) * 100)
                end
            end
        end
    end
end
local function enableHealthESP()
    espVidaEnabled = true
    espVidaConnections[#espVidaConnections + 1] = runService.RenderStepped:Connect(function()
        for _, player in pairs(players:GetPlayers()) do
            if player ~= localPlayer then
                createHealthESP(player)
            end
        end
        updateHealthESP()
    end)
end
local function disableHealthESP()
    espVidaEnabled = false
    for _, conn in ipairs(espVidaConnections) do
        conn:Disconnect()
    end
    espVidaConnections = {}

    for _, player in pairs(players:GetPlayers()) do
        if player.Character then
            local head = player.Character:FindFirstChild("Head")
            if head then
                local billboard = head:FindFirstChild("HealthESP")
                if billboard then billboard:Destroy() end
            end
        end
    end
end

VisualTab.Toggle({
    Text = "ESP Vida",
    Callback = function(Value)
        if Value then
            enableHealthESP()
        else
            disableHealthESP()
        end
    end,
    Enabled = false,
    Menu = {
        Information = function(self)
            X.Banner({ Text = "Veja a vida dos jogadores da sessão." })
        end
    }
})

-- VISUAL ESP DISTANCIA ----------------------------------------------------------------
local espEnabled = false
local espDistances = {}
local espConnection

local function createESPDist(player)
    if player == localPlayer then return end

    local textLabel = Drawing.new("Text")
    textLabel.Visible = false
    textLabel.Color = Color3.new(1, 1, 1) 
    textLabel.Size = 16
    textLabel.Center = true
    textLabel.Outline = true

    espDistances[player] = textLabel
end
local function removeESPDist(player)
    if espDistances[player] then
        espDistances[player]:Remove()
        espDistances[player] = nil
    end
end
local function updateESPDist()
    if not espEnabled then return end 

    for player, textLabel in pairs(espDistances) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)

            if onScreen then
                local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
                textLabel.Text = string.format("%.2f m", distance)

                textLabel.Position = Vector2.new(pos.X, pos.Y - 40) 
                textLabel.Visible = true
            else
                textLabel.Visible = false
            end
        else
            textLabel.Visible = false
        end
    end
end
local function enableESPDist()
    espEnabled = true

    for _, player in pairs(players:GetPlayers()) do
        if player ~= localPlayer then
            createESPDist(player)
        end
    end

    players.PlayerAdded:Connect(function(player)
        createESPDist(player)
    end)

    if not espConnection then
        espConnection = runService.RenderStepped:Connect(updateESPDist)
    end
end
local function disableESPDist()
    espEnabled = false

    if espConnection then
        espConnection:Disconnect()
        espConnection = nil
    end

    for _, textLabel in pairs(espDistances) do
        textLabel:Remove()
    end
    espDistances = {}
end

VisualTab.Toggle({
    Text = "ESP Distância",
    Callback = function(Value)
        if Value then
            enableESPDist()
        else
            disableESPDist()
        end
    end,
    Enabled = false,
    Menu = {
        Information = function(self)
            X.Banner({ Text = "Veja a distância dos jogadores na sua visão." })
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
    end,
    Enabled = false,
    Menu = {
        Information = function(self)
            X.Banner({ Text = "Mira no centro da tela (Cruz)." })
        end
    }
})

-- MIRA AIMBOT -------------------------------------------------------------------------
local smoothness = 0.1
local aimConnection
local ignoreTeam = true
local fovRadius = 150 

local function isVisible(target)
    local origin = Camera.CFrame.Position
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {localPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local result = workspace:Raycast(origin, (target.Position - origin).Unit * 500, raycastParams)
    return result == nil or result.Instance:IsDescendantOf(target.Parent) 
end
local function findTargetByFOV()
    local closestTarget = nil
    local shortestDistance = math.huge
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("Head") then
            if ignoreTeam and player.Team == localPlayer.Team then
                continue
            end

            local head = player.Character.Head
            local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)

            if onScreen and isVisible(head) then
                local distanceFromCenter = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude

                if distanceFromCenter < fovRadius and distanceFromCenter < shortestDistance then
                    shortestDistance = distanceFromCenter
                    closestTarget = player
                end
            end
        end
    end

    return closestTarget
end
local function toggleAimbot(state)
    if state then
        if aimConnection then aimConnection:Disconnect() end
        aimConnection = runService.RenderStepped:Connect(function()
            if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                local closestTarget = findTargetByFOV()
                if closestTarget and closestTarget.Character and closestTarget.Character:FindFirstChild("Head") then
                    local head = closestTarget.Character.Head
                    local targetPosition = CFrame.new(Camera.CFrame.Position, head.Position)
                    Camera.CFrame = Camera.CFrame:Lerp(targetPosition, smoothness)
                end
            end
        end)
    else
        if aimConnection then
            aimConnection:Disconnect()
            aimConnection = nil
        end
    end
end

AimTab.Toggle({
    Text = "Aimbot",
    Callback = function(Value)
        toggleAimbot(Value)
    end,
    Enabled = false,
    Menu = {
        Information = function(self)
            X.Banner({ Text = "Modo Guuh." })
        end
    }
})

-- MIRA AIMBOT SILENT AIM 3 ------------------------------------------------------------
local silentAim3Enabled = false

local function modifyHitboxes()
    for _, player in pairs(players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local head = player.Character.Head
            head.Size = Vector3.new(5, 5, 5) 
            head.Transparency = 1 
            head.CanCollide = false
        end
    end
end
local function enableSilentAim3()
    silentAim3Enabled = true
    modifyHitboxes()
    players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(modifyHitboxes)
    end)
end
local function disableSilentAim3()
    silentAim3Enabled = false
    for _, player in pairs(players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("Head") then
            local head = player.Character.Head
            head.Size = Vector3.new(1, 1, 1) 
            head.Transparency = 0
        end
    end
end

AimTab.Toggle({
    Text = "Muringa (Hitbox)",
    Callback = function(Value)
        if Value then
            enableSilentAim3()
        else
            disableSilentAim3()
        end
    end,
    Enabled = false,
    Menu = {
        Information = function(self)
            X.Banner({ Text = "Cabeça dos inimigos 8x maiores." })
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

-- MIRA AIMBOT IGNORAR TIME ------------------------------------------------------------
AimTab.Toggle({
    Text = "Aimbot ignorar amigo",
    Callback = function(Value)
        ignoreTeam = Value
    end,
    Enabled = true,
    Menu = {
        Information = function(self)
            X.Banner({ Text = "Aimbot não ativa com seu próprio time." })
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
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoid = character:FindFirstChildOfClass("Humanoid")

local lastPosition = Vector3.new()
local speedTextObjects = {}

local function createSpeedText(player)
    if not player.Character then return end
    
    local head = player.Character:FindFirstChild("Head")
    if not head then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "SpeedESP"
    billboard.Adornee = head
    billboard.Size = UDim2.new(0, 100, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.TextScaled = true
    textLabel.Text = ""
    textLabel.Parent = billboard

    billboard.Parent = head
    speedTextObjects[player] = textLabel
end
local function updateSpeed()
    while wait(1) do
        if not character or not humanoid then continue end

        local seat = humanoid.SeatPart
        if seat and seat:IsA("VehicleSeat") then 
            local currentPosition = character.PrimaryPart.Position
            local speedStudsPerSecond = (currentPosition - lastPosition).Magnitude / 0.05
            --local speedKMH = math.floor(speedStudsPerSecond * 3.6)
            lastPosition = currentPosition

            local textLabel = speedTextObjects[localPlayer]
            if textLabel then
                --textLabel.Text = tostring(speedKMH) .. " km/h"
                textLabel.Text = tostring(speedStudsPerSecond) .. "%.2f km/h"
            end
        else
            local textLabel = speedTextObjects[localPlayer]
            if textLabel then
                textLabel.Text = ""
            end
        end
    end
end
local function enableSpeedESP()
    createSpeedText(localPlayer)
    task.spawn(updateSpeed)
end

VehicleTab.Toggle({
    Text = "Velocímetro",
    Callback = function(Value)
        if Value then
            enableSpeedESP()
        else
            if speedTextObjects[localPlayer] then
                speedTextObjects[localPlayer]:Destroy()
                speedTextObjects[localPlayer] = nil
            end
        end
        print("Velocímetro:", Value)
    end,
    Enabled = false,
    Menu = {
        Information = function(self)
            X.Banner({ Text = "Exibe a velocidade do seu veículo em km/h." })
        end
    }
})



repeat wait() until game:IsLoaded()
