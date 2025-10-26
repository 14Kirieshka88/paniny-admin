-- Paniny API v1

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Workspace = workspace
local LocalPlayer = Players.LocalPlayer

-- Notify (from API side)
pcall(function()
	StarterGui:SetCore("SendNotification", {
		Title = "Made with Paniny API";
		Text = "Paniny API connected";
		Icon = "rbxassetid://106585493219199";
		Duration = 4;
	})
end)

local PaninyAPI = {}

-- Settings
PaninyAPI.Settings = {
	FlySpeed = 50,
	MinWalkSpeed = 0.1,
	MaxWalkSpeed = 300,
	AimbotSmoothness = 0,
}

-- helpers
local function findPlayers(arg)
	if not arg or arg == "" then return {LocalPlayer} end
	local low = tostring(arg):lower()
	if low == "all" then return Players:GetPlayers() end
	if low == "me" then return {LocalPlayer} end
	local found = {}
	for _,p in pairs(Players:GetPlayers()) do
		if p.Name:lower():sub(1,#low) == low or (p.DisplayName and p.DisplayName:lower():sub(1,#low) == low) then
			table.insert(found, p)
		end
	end
	return found
end

local function ensureCharacter(plr)
	if not plr then return nil end
	local char = plr.Character
	if not char then return nil end
	return char:FindFirstChildOfClass("Humanoid") and char
end

local function getRoot(plr)
	if not plr or not plr.Character then return nil end
	return plr.Character:FindFirstChild("HumanoidRootPart")
end

local function getHead(plr)
	if not plr or not plr.Character then return nil end
	return plr.Character:FindFirstChild("Head")
end

-- state containers
local flyState = {}
local speedState = {}
local godState = {}
local espHighlights = {}
local espHealthGuis = {}
local playerConnections = {}
local additState = { aimbot = { enabled = false, holdKey = nil, connection = nil } }

local function cleanupPlayer(plr)
	if not plr then return end
	local id = plr.UserId
	if espHighlights[id] then
		pcall(function() if espHighlights[id].Parent then espHighlights[id]:Destroy() end end)
		espHighlights[id] = nil
	end
	if espHealthGuis[id] then
		pcall(function() if espHealthGuis[id].Parent then espHealthGuis[id]:Destroy() end end)
		espHealthGuis[id] = nil
	end
	if playerConnections[id] then
		for _,c in pairs(playerConnections[id]) do
			if c and c.Disconnect then pcall(c.Disconnect, c) end
		end
		playerConnections[id] = nil
	end
	if flyState[id] and flyState[id].bv then
		pcall(function() if flyState[id].bv.Parent then flyState[id].bv:Destroy() end end)
		flyState[id] = nil
	end
end

Players.PlayerRemoving:Connect(function(plr) cleanupPlayer(plr) end)

-- ========== Core commands (API functions) ==========
-- NOCLIP

-- NOCLIP
local noclipState = {}

function PaninyAPI.setNoclip(plr, enable)
    plr = plr or LocalPlayer
    local char = ensureCharacter(plr)
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end

    local id = plr.UserId
    if enable then
        if noclipState[id] then return true end
        noclipState[id] = RunService.Stepped:Connect(function()
            for _, part in pairs(char:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    else
        if noclipState[id] then
            noclipState[id]:Disconnect()
            noclipState[id] = nil
        end
        for _, part in pairs(char:GetChildren()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
    return true
end



-- FLY
function PaninyAPI.enableFly(plr, enable)
	plr = plr or LocalPlayer
	local char = ensureCharacter(plr)
	if not char then return false end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	local id = plr.UserId
	if enable then
		if flyState[id] then return true end
		local bv = Instance.new("BodyVelocity")
		bv.MaxForce = Vector3.new(1e5,1e5,1e5)
		bv.Velocity = Vector3.zero
		bv.Parent = hrp
		flyState[id] = {bv = bv}
		if plr == LocalPlayer then
			playerConnections[id] = playerConnections[id] or {}
			local conn
			conn = RunService.RenderStepped:Connect(function()
				if not flyState[id] or not flyState[id].bv or not flyState[id].bv.Parent then
					if conn then conn:Disconnect() end
					return
				end
				local dir = Vector3.new()
				local cam = Workspace.CurrentCamera
				local spd = (speedState[id] and speedState[id].current) or PaninyAPI.Settings.FlySpeed
				if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
				if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.new(0,1,0) end
				if dir.Magnitude > 0 then
					dir = dir.Unit
					flyState[id].bv.Velocity = dir * spd
				else
					flyState[id].bv.Velocity = Vector3.zero
				end
			end)
			table.insert(playerConnections[id], conn)
		end
	else
		if flyState[id] and flyState[id].bv then
			pcall(function() flyState[id].bv:Destroy() end)
		end
		flyState[id] = nil
	end
	return true
end

-- SPEED
function PaninyAPI.setSpeed(plr, on, value)
	plr = plr or LocalPlayer
	local char = ensureCharacter(plr)
	if not char then return false end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return false end
	local id = plr.UserId
	if on then
		local val = tonumber(value) or PaninyAPI.Settings.FlySpeed
		if val < PaninyAPI.Settings.MinWalkSpeed then val = PaninyAPI.Settings.MinWalkSpeed end
		if val > PaninyAPI.Settings.MaxWalkSpeed then val = PaninyAPI.Settings.MaxWalkSpeed end
		if not speedState[id] then speedState[id] = {original = hum.WalkSpeed, current = val}
		else speedState[id].current = val end
		hum.WalkSpeed = val
	else
		if speedState[id] and speedState[id].original then
			hum.WalkSpeed = speedState[id].original
		else
			hum.WalkSpeed = 16
		end
		speedState[id] = nil
	end
	return true
end

-- TP smart
function PaninyAPI.tpSmart(parts)
	local function waitForRoot(plr, timeout)
		timeout = timeout or 2
		local t0 = tick()
		while tick() - t0 < timeout do
			local r = getRoot(plr)
			if r then return r end
			task.wait(0.05)
		end
		return nil
	end

	if #parts >= 4 and tonumber(parts[2]) and tonumber(parts[3]) and tonumber(parts[4]) then
		local x,y,z = tonumber(parts[2]), tonumber(parts[3]), tonumber(parts[4])
		local root = waitForRoot(LocalPlayer)
		if root then root.CFrame = CFrame.new(x,y,z) return true end
		return false
	end

	if parts[2] and parts[2]:lower() == "all" and parts[3] and parts[3]:lower() == "me" then
		local myRoot = waitForRoot(LocalPlayer)
		if not myRoot then return false end
		for _,pl in pairs(Players:GetPlayers()) do
			local r = waitForRoot(pl, 1)
			if r and pl ~= LocalPlayer then
				pcall(function() r.CFrame = myRoot.CFrame + Vector3.new(0,5,0) end)
			end
		end
		return true
	end

	if parts[2] and parts[2]:lower() == "me" and parts[3] then
		local targets = findPlayers(parts[3])
		if #targets == 0 then return false end
		local rootMe = waitForRoot(LocalPlayer)
		local rootTarget = waitForRoot(targets[1], 2)
		if rootMe and rootTarget then rootMe.CFrame = rootTarget.CFrame + Vector3.new(0,3,0) return true end
		return false
	end

	if parts[2] and parts[3] then
		local p1s = findPlayers(parts[2])
		local p2s = findPlayers(parts[3])
		if #p1s == 0 or #p2s == 0 then return false end
		local destRoot = waitForRoot(p2s[1], 2)
		if not destRoot then return false end
		for _,p in pairs(p1s) do
			local r1 = waitForRoot(p, 2)
			if r1 then
				r1.CFrame = destRoot.CFrame + Vector3.new(0,3,0)
			end
		end
		return true
	end

	return false
end

-- HEAL
function PaninyAPI.healPlayer(plr)
	plr = plr or LocalPlayer
	local char = ensureCharacter(plr)
	if not char then return false end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return false end
	local id = plr.UserId
	if godState[id] and godState[id].enabled then
		local prev = godState[id].prevMax or hum.MaxHealth
		hum.MaxHealth = prev
		hum.Health = hum.MaxHealth
		task.wait(0.05)
		hum.MaxHealth = 1e9
		hum.Health = 1e9
	else
		hum.Health = hum.MaxHealth
	end
	return true
end

-- KILL
function PaninyAPI.killPlayer(plr)
	plr = plr or LocalPlayer
	local char = ensureCharacter(plr)
	if not char then return false end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return false end
	hum.Health = 0
	return true
end

-- GOD
function PaninyAPI.setGod(plr, on)
	plr = plr or LocalPlayer
	local char = ensureCharacter(plr)
	if not char then return false end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return false end
	local id = plr.UserId
	if on then
		if not godState[id] then godState[id] = {} end
		godState[id].enabled = true
		godState[id].prevMax = hum.MaxHealth or 100
		hum.MaxHealth = 1e9
		hum.Health = 1e9
	else
		if godState[id] then
			godState[id].enabled = false
			local prev = godState[id].prevMax or 100
			hum.MaxHealth = prev
			if hum.Health > hum.MaxHealth then hum.Health = hum.MaxHealth end
			godState[id] = nil
		end
	end
	return true
end

-- INVIS (store original transparencies not persisted across join in this simple API)
function PaninyAPI.setInvis(plr, on)
	plr = plr or LocalPlayer
	local char = ensureCharacter(plr)
	if not char then return false end
	if on then
		for _,v in pairs(char:GetDescendants()) do
			if (v:IsA("BasePart") or v:IsA("Decal") or v:IsA("Texture")) and v.Parent then
				v.Transparency = 1
			end
		end
	else
		for _,v in pairs(char:GetDescendants()) do
			if (v:IsA("BasePart") or v:IsA("Decal") or v:IsA("Texture")) and v.Parent then
				v.Transparency = 0
			end
		end
	end
	return true
end

-- SIT
function PaninyAPI.setSit(plr, on)
	plr = plr or LocalPlayer
	local char = ensureCharacter(plr)
	if not char then return false end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return false end
	hum.Sit = on
	return true
end

-- ESP (Highlight)
function PaninyAPI.setESP(plr, on)
	local Players = game:GetService("Players")
	local LocalPlayer = Players.LocalPlayer
	espHighlights = espHighlights or {}

	-- "all" case
	if tostring(plr):lower() == "all" then
		for _,p in pairs(Players:GetPlayers()) do
			if p ~= LocalPlayer then
				PaninyAPI.setESP(p, on)
			end
		end
		return true
	end

	if not plr then return false end
	local id = plr.UserId

	if on then
		-- если уже есть Highlight, ничего не делаем
		if espHighlights[id] and espHighlights[id].Parent then return true end
		if not plr.Character then return false end

		-- создаём Highlight
		local highlight = Instance.new("Highlight")
		highlight.Name = "PaninyESP"
		highlight.FillTransparency = 1
		highlight.OutlineColor = Color3.fromRGB(0,255,0)
		highlight.Adornee = plr.Character
		highlight.Parent = plr.Character

		espHighlights[id] = highlight
	else
		-- отключаем только если явно вызвано off
		if espHighlights[id] then
			pcall(function() 
				if espHighlights[id].Parent then 
					espHighlights[id]:Destroy() 
				end 
			end)
			espHighlights[id] = nil
		end
	end

	return true
end

-- === АВТООБНОВЛЕНИЕ ESP ===


-- Health GUI
function PaninyAPI.createHealthGuiForPlayer(plr)
	if not plr or not plr.Character then return nil end
	local id = plr.UserId
	if espHealthGuis[id] and espHealthGuis[id].Parent then return espHealthGuis[id] end
	local head = getHead(plr)
	if not head then return nil end
	local gui = Instance.new("BillboardGui")
	gui.Name = "Paniny_HealthGui"
	gui.Size = UDim2.new(0,80,0,30)
	gui.StudsOffset = Vector3.new(0,2,0)
	gui.AlwaysOnTop = true
	gui.Parent = head

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.new(1,0,1,0)
	txt.BackgroundTransparency = 1
	txt.Font = Enum.Font.SourceSansBold
	txt.TextSize = 14
	txt.Text = "HP"
	txt.Parent = gui

	local function update()
		local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
		if not hum then txt.Text = "HP: ?" return end
		local hp = math.floor(hum.Health + 0.5)
		local maxhp = math.floor(hum.MaxHealth + 0.5)
		txt.Text = ("HP: %d/%d"):format(hp, maxhp)
		local ratio = maxhp > 0 and (hp / maxhp) or 0
		if ratio > 0.7 then txt.TextColor3 = Color3.fromRGB(0,220,0)
		elseif ratio > 0.3 then txt.TextColor3 = Color3.fromRGB(220,180,0)
		else txt.TextColor3 = Color3.fromRGB(220,0,0) end
	end

	local con1 = nil
	if plr.Character then
		local hum = plr.Character:FindFirstChildOfClass("Humanoid")
		if hum then con1 = hum.HealthChanged:Connect(update) end
	end
	local con2 = plr.CharacterAdded:Connect(function(char)
		task.wait(0.1)
		if gui and gui.Parent then gui.Parent = char:FindFirstChild("Head") or gui.Parent end
		if con1 and con1.Disconnect then pcall(con1.Disconnect, con1) end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then con1 = hum.HealthChanged:Connect(update) end
		update()
	end)

	playerConnections[id] = playerConnections[id] or {}
	table.insert(playerConnections[id], con2)
	table.insert(playerConnections[id], con1)
	update()
	espHealthGuis[id] = gui
	return gui
end

function PaninyAPI.removeHealthGuiForPlayer(plr)
	if not plr then return false end
	local id = plr.UserId
	if espHealthGuis[id] then
		pcall(function() if espHealthGuis[id].Parent then espHealthGuis[id]:Destroy() end end)
		espHealthGuis[id] = nil
	end
	return true
end

-- AIMBOT (local)
local function getNearestTarget(maxDistance)
	maxDistance = maxDistance or 300
	local best, bestDist = nil, math.huge
	local cam = Workspace.CurrentCamera
	local camPos = cam and cam.CFrame.Position or Vector3.new()
	for _,p in pairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and ensureCharacter(p) then
			local head = getHead(p)
			local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
			if head and hum and hum.Health > 0 then
				local dist = (head.Position - camPos).Magnitude
				local _, onScreen = cam:WorldToViewportPoint(head.Position)
				if onScreen and dist < bestDist and dist <= maxDistance then
					best = p
					bestDist = dist
				end
			end
		end
	end
	return best
end

function PaninyAPI.startAimbot(holdKey)
	if additState.aimbot.connection then additState.aimbot.connection:Disconnect() end
	additState.aimbot.enabled = true
	additState.aimbot.holdKey = holdKey
	local conn = RunService.RenderStepped:Connect(function()
		if not additState.aimbot.enabled then return end
		if additState.aimbot.holdKey then
			local keyEnum = Enum.KeyCode[tostring(additState.aimbot.holdKey):upper()]
			if not keyEnum or not UserInputService:IsKeyDown(keyEnum) then return end
		end
		local target = getNearestTarget(1000)
		if not target then return end
		local head = getHead(target)
		if not head then return end
		local camCFrame = Workspace.CurrentCamera.CFrame
		local targetPos = head.Position
		local dir = (targetPos - camCFrame.Position)
		if dir.Magnitude < 0.1 then return end
		local newCFrame = CFrame.new(camCFrame.Position, camCFrame.Position + dir)
		Workspace.CurrentCamera.CFrame = camCFrame:Lerp(newCFrame, math.clamp(PaninyAPI.Settings.AimbotSmoothness, 0.01, 1))
	end)
	additState.aimbot.connection = conn
	return true
end

function PaninyAPI.stopAimbot()
	if additState.aimbot.connection then additState.aimbot.connection:Disconnect() end
	additState.aimbot.connection = nil
	additState.aimbot.enabled = false
	additState.aimbot.holdKey = nil
	return true
end

-- expose helpers for GUI
PaninyAPI.findPlayers = findPlayers
PaninyAPI.ensureCharacter = ensureCharacter
PaninyAPI.getRoot = getRoot
PaninyAPI.getHead = getHead

return PaninyAPI
