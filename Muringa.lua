local HiruZT = loadstring(game:HttpGet("https://raw.githubusercontent.com/zachisfunny/BooHub/main/Boo"))()

local UI = HiruZT.Load({
     Title = "👻 Muringa",
     Style = 0,
     SizeX = 400,
     SizeY = 340,
     Theme = "Dark"
})

local AIM = UI.New({
    Title = "AIMBOT"
})
local VISUAL = UI.New({
    Title = "VISUAL"
})
local FPS = UI.New({
	Title = "OPTIMIZER"
})

-- Suport ------------------------------------------------------------------------------
local services = setmetatable({}, {__index = function(_, k) return cloneref(game:GetService(k)) end})
local players, runService, userInputService, workspace = services.Players, services.RunService, services.UserInputService, services.Workspace
local localPlayer, camera = players.LocalPlayer, workspace.CurrentCamera


-- AIMBOT ------------------------------------------------------------------------------
local aimbotEnabled, aiming = false, false
local ignoreTeam, smoothness, fovRadius = true, 0.1, 40
local aimPart, lastTarget = "Head", nil

local function isVisible(target)
    local origin = camera.CFrame.Position
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {localPlayer.Character}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist

    local result = workspace:Raycast(origin, (target.Position - origin).Unit * 500, rayParams)
    return result == nil or result.Instance:IsDescendantOf(target.Parent)
end
local function findTargetByFOV()
    local closestTarget, shortestDist = nil, math.huge
    local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)

    for _, player in ipairs(players:GetPlayers()) do
        if player ~= localPlayer and (not ignoreTeam or player.Team ~= localPlayer.Team) and player.Character then
            if player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
                local targetPart = player.Character:FindFirstChild(aimPart) or player.Character:FindFirstChild("HumanoidRootPart")
                if targetPart then
                    local screenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen and isVisible(targetPart) then
                        local distFromCenter = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                        if distFromCenter < fovRadius and distFromCenter < shortestDist then
                            shortestDist = distFromCenter
                            closestTarget = player
                        end
                    end
                end
            end
        end
    end
    return closestTarget
end
userInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 and aimbotEnabled then
        aiming = true
        while aiming do
            local closestTarget = findTargetByFOV()
            if closestTarget and closestTarget.Character then
                local targetPart = closestTarget.Character:FindFirstChild(aimPart) or closestTarget.Character:FindFirstChild("HumanoidRootPart")
                if targetPart then
                    local randomOffset = Vector3.new(math.random(-1, 1) * 0.05, math.random(-1, 1) * 0.05, 0)
                    local targetPosition = CFrame.new(camera.CFrame.Position, targetPart.Position + randomOffset)
                    local dynamicSmoothness = smoothness + math.random(-2, 2) * 0.0025
                    camera.CFrame = camera.CFrame:Lerp(targetPosition, dynamicSmoothness)
                end
            end
            runService.RenderStepped:Wait()
        end
    end
end)
userInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aiming = false
    end
end)

AIM.Toggle({
    Text = "Aimbot",
    Callback = function(Value)
        aimbotEnabled = Value
    end,
    Enabled = false
})
AIM.Dropdown({
    Text = "Partes",
    Callback = function(value)
        if value == "Cabeça" then
            aimPart = "Head"
        elseif value == "Corpo" then
            aimPart = "HumanoidRootPart"
        elseif value == "Todas partes" then
            aimPart = "Torso"
        end
    end,
    Options = {"Cabeça", "Corpo", "Todas partes"}
})
AIM.Slider({
    Text = "Smooth do Aimbot",
    Callback = function(Value)
        smoothness = Value / 100
    end,
    Min = 1,
    Max = 40,
    Def = 4
})
AIM.Slider({
    Text = "FOV do Aimbot",
    Callback = function(Value)
        fovRadius = math.clamp(Value, 1, 320) 
    end,
    Min = 1,
    Max = 320,
    Def = fovRadius
})
AIM.Toggle({
    Text = "Aimbot ignora o time",
    Callback = function(Value)
        ignoreTeam = Value
    end,
    Enabled = true
})

-- HITBOX ------------------------------------------------------------------------------
local MuringaEnabled = false
local hitboxSize = 1  

local function modifyHitboxes()
    for _, player in pairs(players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local head = player.Character.Head
            local randomSize = hitboxSize + math.random(-2, 2) * 0.1  
            head.Size = Vector3.new(randomSize, randomSize, randomSize)
            head.Transparency = 1
            head.CanCollide = false
        end
    end
end
local function resetHitboxes()
    for _, player in pairs(players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("Head") then
            local head = player.Character.Head
            head.Size = Vector3.new(1, 1, 1)
            head.Transparency = 0
        end
    end
end
local function updateHitboxes()
    while MuringaEnabled do
        modifyHitboxes()
        task.wait(math.random(30, 100) / 1000)
    end
end
local function enableMuringa()
    if not MuringaEnabled then
        MuringaEnabled = true
        task.spawn(updateHitboxes)
    end
end
local function disableMuringa()
    MuringaEnabled = false
    resetHitboxes()
end

VISUAL.Slider({
    Text = "Hitbox Head",
	Callback = function(Value)
        hitboxSize = Value
        if Value == 1 then
            disableMuringa()
        else
            enableMuringa()
        end
    end,
    Min = 1,
    Max = 5,
    Def = hitboxSize
})


-- ESP ---------------------------------------------------------------------------------
local espEnabled, espConnections, espCache = false, {}, {}

local function createESPBox(player)
    if not player.Character then return end
    local char = player.Character
    if not char:FindFirstChild("ESP_Highlight") then
        local highlight = Instance.new("Highlight")
        highlight.Name = "ESP_Highlight"
        highlight.Adornee = char
        highlight.FillTransparency = 1
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.OutlineColor = player.Team and player.Team.TeamColor.Color or Color3.new(1, 1, 1)
        highlight.Parent = char
        espCache[player] = highlight
    end
end
local function refreshESP()
    for _, player in pairs(players:GetPlayers()) do
        if player ~= localPlayer then
            createESPBox(player)
        end
    end
end
local function enableESP()
    if espEnabled then return end
    espEnabled = true
    refreshESP()

    espConnections[#espConnections + 1] = players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function()
            if espEnabled then
                task.wait(0.1)
                createESPBox(player)
            end
        end)
    end)

    espConnections[#espConnections + 1] = runService.RenderStepped:Connect(function()
        refreshESP()
    end)
end
local function disableESP()
    espEnabled = false
    for _, conn in ipairs(espConnections) do
        pcall(function() conn:Disconnect() end)
    end
    espConnections = {}

    for player, highlight in pairs(espCache) do
        if highlight and highlight.Parent then
            pcall(function() highlight:Destroy() end)
        end
    end
    espCache = {}
end

VISUAL.Toggle({
    Text = "ESP Chams",
    Callback = function(Value)
        if Value then
            enableESP()
        else
            disableESP()
        end
    end,
    Enabled = false
})


-- FPS+ OPTIMIZER ----------------------------------------------------------------------
local setFPS = setfpscap(400)
local defaultFPS = 240
local debounceTime = 0.1
local lastChangeTime = 0

FPS.Slider({
    Text = "FPS Limite",
    Callback = function(Value)
        local currentTime = tick()

        if currentTime - lastChangeTime > debounceTime then
            pcall(function()
                setFPS(math.clamp(Value, 60, 400))
            end)
            lastChangeTime = currentTime  
        end
    end,
    Min = 60,
    Max = 400,
    Def = defaultFPS
})


FPS.Toggle({
    Text = "Desabilitar Partes Não Visíveis",
    Callback = function(Value)
        game:GetService("Workspace").DescendantAdded:Connect(function(child)
            if child:IsA("BasePart") then
                if Value then
                    child:SetAttribute("ShouldRender", false)
                else
                    child:SetAttribute("ShouldRender", true)
                end
            end
        end)
    end,
    Enabled = false
})
FPS.Toggle({
    Text = "Usar LOD (Level of Detail)",
    Callback = function(Value)
        local function updateLOD(player)
            for _, object in pairs(workspace:GetDescendants()) do
                if object:IsA("Model") then
                    local distance = (object.PrimaryPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
                    if distance > 50 then
                        if Value then
                            object:FindFirstChild("HighDetailModel"):Destroy()
                            object:FindFirstChild("LowDetailModel"):Clone().Parent = object
                        end
                    else
                        if Value then
                            object:FindFirstChild("LowDetailModel"):Destroy()
                            object:FindFirstChild("HighDetailModel"):Clone().Parent = object
                        end
                    end
                end
            end
        end
        
        game:GetService("RunService").Heartbeat:Connect(function()
            updateLOD(game.Players.LocalPlayer)
        end)
    end,
    Enabled = false
})
FPS.Toggle({
    Text = "Limitar Quantidade de Partes",
    Callback = function(Value)
        local maxParts = 500
        local partCount = 0
        
        game:GetService("RunService").Heartbeat:Connect(function()
            if Value then
                partCount = 0
                for _, object in pairs(workspace:GetDescendants()) do
                    if object:IsA("BasePart") then
                        partCount = partCount + 1
                        if partCount > maxParts then
                            object:Destroy()  
                        end
                    end
                end
            end
        end)
    end,
    Enabled = false
})
FPS.Toggle({
    Text = "Desativar Efeitos Gráficos Pesados",
    Callback = function(Value)
        if Value then
            game:GetService("Lighting").GlobalShadows = false  
            game:GetService("Lighting").Ambient = Color3.fromRGB(255, 255, 255) 
            game:GetService("Lighting").Brightness = 0.5  
        else
            game:GetService("Lighting").GlobalShadows = true 
            game:GetService("Lighting").Ambient = Color3.fromRGB(128, 128, 128) 
            game:GetService("Lighting").Brightness = 2 
        end
    end,
    Enabled = false
})
FPS.Toggle({
    Text = "Ocultar Partes Dinâmicas",
    Callback = function(Value)
        game:GetService("Workspace").DescendantAdded:Connect(function(child)
            if child:IsA("Part") then
                if Value then
                    child.Transparency = 1 
                    child.CanCollide = false 
                else
                    child.Transparency = 0 
                    child.CanCollide = true 
                end
            end
        end)
    end,
    Enabled = false
})
FPS.Toggle({
    Text = "Mover Tarefas Pesadas para Ociosidade",
    Callback = function(Value)
        if Value then
            game:GetService("RunService").Stepped:Connect(function()
            end)
        else
            game:GetService("RunService").Heartbeat:Connect(function()
            end)
        end
    end,
    Enabled = false
})
