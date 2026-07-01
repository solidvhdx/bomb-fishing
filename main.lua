--[[ bomb fishing farm ]]

local function protectGui(gui)
	pcall(function()
		if protect_gui then protect_gui(gui) end
	end)
	pcall(function()
		if protectgui then protectgui(gui) end
	end)
	pcall(function()
		if syn and syn.protect_gui then syn.protect_gui(gui) end
	end)
end

local function mountGui(gui, localPlayer)
	protectGui(gui)
	if gethui then
		local ok = pcall(function() gui.Parent = gethui() end)
		if ok and gui.Parent then return end
	end
	if localPlayer then
		local ok = pcall(function()
			gui.Parent = localPlayer:WaitForChild("PlayerGui", 8)
		end)
		if ok and gui.Parent then return end
	end
	pcall(function() gui.Parent = game:GetService("CoreGui") end)
end

local THROW_POWER = 1.0
local TOGGLE_KEY = Enum.KeyCode.V
local HOTKEY_LABEL = "V"
local learnedBaseName = nil

local THEME = {
	background = Color3.fromRGB(10, 10, 10),
	foreground = Color3.fromRGB(250, 250, 250),
	card = Color3.fromRGB(23, 23, 23),
	mutedForeground = Color3.fromRGB(161, 161, 170),
	border = Color3.fromRGB(38, 38, 38),
	secondary = Color3.fromRGB(38, 38, 38),
	secondaryForeground = Color3.fromRGB(250, 250, 250),
	accent = Color3.fromRGB(38, 38, 38),
	sidebar = Color3.fromRGB(23, 23, 23),
	sidebarAccent = Color3.fromRGB(38, 38, 38),
	destructive = Color3.fromRGB(248, 113, 113),
	success = Color3.fromRGB(74, 222, 128),
	radius = 10,
	radiusSm = 6,
}

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or THEME.radius)
	c.Parent = parent
	return c
end

local function stroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or THEME.border
	s.Thickness = thickness or 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function padding(parent, t, r, b, l)
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, t or 0)
	p.PaddingRight = UDim.new(0, r or t or 0)
	p.PaddingBottom = UDim.new(0, b or t or 0)
	p.PaddingLeft = UDim.new(0, l or r or t or 0)
	p.Parent = parent
	return p
end

local function destroyExistingFarmGuis(localPlayer)
	local function sweep(parent)
		if not parent then
			return
		end
		for _, child in ipairs(parent:GetChildren()) do
			if child:IsA("ScreenGui") and child.Name == "BombFishingFarm" then
				child:Destroy()
			end
		end
	end
	sweep(game:GetService("CoreGui"))
	pcall(function()
		if gethui then
			sweep(gethui())
		end
	end)
	if localPlayer then
		local playerGui = localPlayer:FindFirstChild("PlayerGui")
		if playerGui then
			sweep(playerGui)
		end
	end
end

local function run()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local UserInputService = game:GetService("UserInputService")
	local RunService = game:GetService("RunService")
	local TweenService = game:GetService("TweenService")
	local ContextActionService = game:GetService("ContextActionService")
	local CollectionService = game:GetService("CollectionService")

	local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

	if _G.__BombFishingFarmShutdown then
		pcall(_G.__BombFishingFarmShutdown)
		_G.__BombFishingFarmShutdown = nil
	end
	destroyExistingFarmGuis(LocalPlayer)

	local SCRIPT_ID = tick()
	_G.__BombFishingFarmActiveId = SCRIPT_ID
	local alive = true

	local function isActiveScript()
		return _G.__BombFishingFarmActiveId == SCRIPT_ID and alive
	end

	local CONFIG = {
		AfterStartWait = 0.5,
		RoundWait = 12,
		PostFinishWait = 0.25,
		StartArg = 0,
		ClaimDelay = 60.0,
		CageClaimDelay = 120.0,
		RebirthPollInterval = 0.5,
		PlotButtonPath = { "MainScreen", "TopScreen", "Buttons", "Plot", "Button", "Color", "Layout" },
		_lastClaim = 0,
		_lastCageClaim = 0,
	}

	local farming = false
	local claiming = false
	local claimCage = false
	local equipBest = false
	local autoSell = false
	local autoRebirth = false
	local guiVisible = true
	local farmGeneration = 0
	local farmCycleBusy = false
	local lastRebirthFire = 0
	local lastRebirthPoll = 0
	local rebirthSystemsReady = false
	local dataReplica = nil
	local RebirthServiceClient = nil
	local GameConfig = nil

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "BombFishingFarm"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.IgnoreGuiInset = true
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ScreenGui.DisplayOrder = 999999
	mountGui(ScreenGui, LocalPlayer)

	local HEADER_H = 40
	local FOOTER_H = 26

	local Root = Instance.new("Frame")
	Root.Name = "Root"
	Root.Size = UDim2.fromOffset(300, 290)
	Root.Position = UDim2.new(0, 24, 0.15, 0)
	Root.BackgroundColor3 = THEME.background
	Root.BorderSizePixel = 0
	Root.Active = true
	Root.ClipsDescendants = true
	Root.Parent = ScreenGui
	corner(Root, THEME.radius)

	local TopBar = Instance.new("Frame")
	TopBar.Name = "TopBar"
	TopBar.Size = UDim2.new(1, 0, 0, HEADER_H)
	TopBar.BackgroundColor3 = THEME.sidebar
	TopBar.BorderSizePixel = 0
	TopBar.Parent = Root

	local TopBarBorder = Instance.new("Frame")
	TopBarBorder.Size = UDim2.new(1, 0, 0, 1)
	TopBarBorder.Position = UDim2.new(0, 0, 1, -1)
	TopBarBorder.BackgroundColor3 = THEME.border
	TopBarBorder.BorderSizePixel = 0
	TopBarBorder.Parent = TopBar

	local TopTitle = Instance.new("TextLabel")
	TopTitle.Size = UDim2.new(1, -48, 1, 0)
	TopTitle.Position = UDim2.fromOffset(14, 0)
	TopTitle.BackgroundTransparency = 1
	TopTitle.Font = Enum.Font.GothamSemibold
	TopTitle.TextSize = 14
	TopTitle.TextXAlignment = Enum.TextXAlignment.Left
	TopTitle.TextColor3 = THEME.foreground
	TopTitle.Text = "Bomb Fishing"
	TopTitle.Parent = TopBar

	local CloseBtn = Instance.new("TextButton")
	CloseBtn.Size = UDim2.fromOffset(28, 28)
	CloseBtn.Position = UDim2.new(1, -36, 0.5, -14)
	CloseBtn.BackgroundColor3 = THEME.secondary
	CloseBtn.BorderSizePixel = 0
	CloseBtn.AutoButtonColor = false
	CloseBtn.Font = Enum.Font.GothamBold
	CloseBtn.TextSize = 14
	CloseBtn.TextColor3 = THEME.mutedForeground
	CloseBtn.Text = "X"
	CloseBtn.Parent = TopBar
	corner(CloseBtn, THEME.radiusSm)
	stroke(CloseBtn, THEME.border)

	CloseBtn.MouseEnter:Connect(function()
		TweenService:Create(CloseBtn, TweenInfo.new(0.12), {
			BackgroundColor3 = THEME.accent,
			TextColor3 = THEME.foreground,
		}):Play()
	end)
	CloseBtn.MouseLeave:Connect(function()
		TweenService:Create(CloseBtn, TweenInfo.new(0.12), {
			BackgroundColor3 = THEME.secondary,
			TextColor3 = THEME.mutedForeground,
		}):Play()
	end)

	local Body = Instance.new("Frame")
	Body.Name = "Body"
	Body.Size = UDim2.new(1, 0, 1, -(HEADER_H + FOOTER_H))
	Body.Position = UDim2.fromOffset(0, HEADER_H)
	Body.BackgroundColor3 = THEME.background
	Body.BorderSizePixel = 0
	Body.ClipsDescendants = true
	Body.ZIndex = 2
	Body.Parent = Root

	local ListPad = Instance.new("Frame")
	ListPad.Size = UDim2.new(1, 0, 1, 0)
	ListPad.BackgroundTransparency = 1
	ListPad.Parent = Body
	padding(ListPad, 8, 10, 8, 10)

	local ListLayout = Instance.new("UIListLayout")
	ListLayout.Padding = UDim.new(0, 4)
	ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	ListLayout.Parent = ListPad

	local toggleRows = {}

	local function makeToggleRow(label, order, statusWidth)
		statusWidth = statusWidth or 34

		local row = Instance.new("Frame")
		row.Name = label
		row.LayoutOrder = order
		row.Size = UDim2.new(1, 0, 0, 28)
		row.BackgroundTransparency = 1
		row.BorderSizePixel = 0
		row.Parent = ListPad

		local bg = Instance.new("Frame")
		bg.Name = "Bg"
		bg.Size = UDim2.fromScale(1, 1)
		bg.BackgroundColor3 = THEME.card
		bg.BorderSizePixel = 0
		bg.ZIndex = 1
		bg.Parent = row
		corner(bg, THEME.radiusSm)
		stroke(bg, THEME.border)

		local labelLbl = Instance.new("TextLabel")
		labelLbl.Size = UDim2.new(1, -(statusWidth + 6), 1, 0)
		labelLbl.Position = UDim2.fromOffset(10, 0)
		labelLbl.BackgroundTransparency = 1
		labelLbl.Font = Enum.Font.GothamSemibold
		labelLbl.TextSize = 11
		labelLbl.TextXAlignment = Enum.TextXAlignment.Left
		labelLbl.TextYAlignment = Enum.TextYAlignment.Center
		labelLbl.TextTruncate = Enum.TextTruncate.AtEnd
		labelLbl.TextColor3 = THEME.foreground
		labelLbl.Text = label
		labelLbl.ZIndex = 2
		labelLbl.Active = false
		labelLbl.Parent = row
		pcall(function()
			labelLbl.Interactable = false
		end)

		local statusLbl = Instance.new("TextLabel")
		statusLbl.Size = UDim2.fromOffset(statusWidth, 28)
		statusLbl.AnchorPoint = Vector2.new(1, 0.5)
		statusLbl.Position = UDim2.new(1, -8, 0.5, 0)
		statusLbl.BackgroundTransparency = 1
		statusLbl.Font = Enum.Font.GothamSemibold
		statusLbl.TextSize = 10
		statusLbl.TextXAlignment = Enum.TextXAlignment.Right
		statusLbl.TextYAlignment = Enum.TextYAlignment.Center
		statusLbl.TextColor3 = THEME.mutedForeground
		statusLbl.Text = "OFF"
		statusLbl.ZIndex = 2
		statusLbl.Active = false
		statusLbl.Parent = row
		pcall(function()
			statusLbl.Interactable = false
		end)

		local hit = Instance.new("TextButton")
		hit.Name = "Hit"
		hit.Size = UDim2.fromScale(1, 1)
		hit.BackgroundTransparency = 1
		hit.BorderSizePixel = 0
		hit.AutoButtonColor = false
		hit.Text = ""
		hit.ZIndex = 3
		hit.Parent = row

		hit.MouseEnter:Connect(function()
			if row:GetAttribute("Active") then
				return
			end
			TweenService:Create(bg, TweenInfo.new(0.1), {
				BackgroundColor3 = THEME.sidebarAccent,
			}):Play()
		end)
		hit.MouseLeave:Connect(function()
			if row:GetAttribute("Active") then
				return
			end
			TweenService:Create(bg, TweenInfo.new(0.1), {
				BackgroundColor3 = THEME.card,
			}):Play()
		end)

		toggleRows[label] = { btn = bg, hit = hit, status = statusLbl, row = row }
		return hit, statusLbl
	end

	local FarmBtn, BadgeText = makeToggleRow("Auto Farm", 1)
	local ClaimBtn, ClaimBadgeText = makeToggleRow("Auto Claim Money", 2)
	local CageBtn, CageBadgeText = makeToggleRow("Auto Claim Cage", 3)
	local EquipBtn, EquipBadgeText = makeToggleRow("Auto Equip Best", 4)
	local SellBtn, SellBadgeText = makeToggleRow("Auto Sell Inventory", 5)
	local RebirthBtn, RebirthBadgeText = makeToggleRow("Auto Rebirth", 6, 44)

	local Footer = Instance.new("Frame")
	Footer.Name = "Footer"
	Footer.Size = UDim2.new(1, 0, 0, FOOTER_H)
	Footer.Position = UDim2.new(0, 0, 1, -FOOTER_H)
	Footer.BackgroundColor3 = THEME.sidebar
	Footer.BorderSizePixel = 0
	Footer.ZIndex = 1
	Footer.Parent = Root

	local FooterBorder = Instance.new("Frame")
	FooterBorder.Size = UDim2.new(1, 0, 0, 1)
	FooterBorder.BackgroundColor3 = THEME.border
	FooterBorder.BorderSizePixel = 0
	FooterBorder.Parent = Footer

	local FooterHint = Instance.new("TextLabel")
	FooterHint.Size = UDim2.new(1, -16, 1, 0)
	FooterHint.Position = UDim2.fromOffset(8, 0)
	FooterHint.BackgroundTransparency = 1
	FooterHint.Font = Enum.Font.Gotham
	FooterHint.TextSize = 10
	FooterHint.TextXAlignment = Enum.TextXAlignment.Center
	FooterHint.TextColor3 = THEME.mutedForeground
	FooterHint.Text = "Press " .. HOTKEY_LABEL .. " to toggle menu"
	FooterHint.Parent = Footer

	local ConfirmOverlay = Instance.new("Frame")
	ConfirmOverlay.Name = "ConfirmOverlay"
	ConfirmOverlay.Size = UDim2.fromScale(1, 1)
	ConfirmOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	ConfirmOverlay.BackgroundTransparency = 0.45
	ConfirmOverlay.BorderSizePixel = 0
	ConfirmOverlay.Active = false
	ConfirmOverlay.Visible = false
	ConfirmOverlay.ZIndex = 100
	ConfirmOverlay.Parent = ScreenGui

	local ConfirmCard = Instance.new("Frame")
	ConfirmCard.Name = "ConfirmCard"
	ConfirmCard.Size = UDim2.fromOffset(320, 156)
	ConfirmCard.AnchorPoint = Vector2.new(0.5, 0.5)
	ConfirmCard.Position = UDim2.fromScale(0.5, 0.5)
	ConfirmCard.BackgroundColor3 = THEME.card
	ConfirmCard.BorderSizePixel = 0
	ConfirmCard.ZIndex = 101
	ConfirmCard.Parent = ConfirmOverlay
	corner(ConfirmCard, THEME.radius)
	stroke(ConfirmCard, THEME.border)

	padding(ConfirmCard, 16, 16, 16, 16)

	local ConfirmTitle = Instance.new("TextLabel")
	ConfirmTitle.Size = UDim2.new(1, 0, 0, 22)
	ConfirmTitle.BackgroundTransparency = 1
	ConfirmTitle.Font = Enum.Font.GothamSemibold
	ConfirmTitle.TextSize = 15
	ConfirmTitle.TextXAlignment = Enum.TextXAlignment.Left
	ConfirmTitle.TextColor3 = THEME.foreground
	ConfirmTitle.Text = "Close script?"
	ConfirmTitle.ZIndex = 102
	ConfirmTitle.Parent = ConfirmCard

	local ConfirmBody = Instance.new("TextLabel")
	ConfirmBody.Size = UDim2.new(1, 0, 0, 44)
	ConfirmBody.Position = UDim2.fromOffset(0, 28)
	ConfirmBody.BackgroundTransparency = 1
	ConfirmBody.Font = Enum.Font.Gotham
	ConfirmBody.TextSize = 12
	ConfirmBody.TextXAlignment = Enum.TextXAlignment.Left
	ConfirmBody.TextYAlignment = Enum.TextYAlignment.Top
	ConfirmBody.TextWrapped = true
	ConfirmBody.TextColor3 = THEME.mutedForeground
	ConfirmBody.Text = "This stops all automation. Re-run the script to use it again."
	ConfirmBody.ZIndex = 102
	ConfirmBody.Parent = ConfirmCard

	local ConfirmActions = Instance.new("Frame")
	ConfirmActions.Size = UDim2.new(1, 0, 0, 32)
	ConfirmActions.Position = UDim2.new(0, 0, 1, -32)
	ConfirmActions.BackgroundTransparency = 1
	ConfirmActions.ZIndex = 102
	ConfirmActions.Parent = ConfirmCard

	local ConfirmCancel = Instance.new("TextButton")
	ConfirmCancel.Size = UDim2.new(0.5, -6, 1, 0)
	ConfirmCancel.BackgroundColor3 = THEME.secondary
	ConfirmCancel.BorderSizePixel = 0
	ConfirmCancel.AutoButtonColor = false
	ConfirmCancel.Font = Enum.Font.GothamSemibold
	ConfirmCancel.TextSize = 12
	ConfirmCancel.TextColor3 = THEME.secondaryForeground
	ConfirmCancel.Text = "Cancel"
	ConfirmCancel.ZIndex = 103
	ConfirmCancel.Parent = ConfirmActions
	corner(ConfirmCancel, THEME.radiusSm)
	stroke(ConfirmCancel, THEME.border)

	local ConfirmClose = Instance.new("TextButton")
	ConfirmClose.Size = UDim2.new(0.5, -6, 1, 0)
	ConfirmClose.Position = UDim2.new(0.5, 6, 0, 0)
	ConfirmClose.BackgroundColor3 = Color3.fromRGB(69, 10, 10)
	ConfirmClose.BorderSizePixel = 0
	ConfirmClose.AutoButtonColor = false
	ConfirmClose.Font = Enum.Font.GothamSemibold
	ConfirmClose.TextSize = 12
	ConfirmClose.TextColor3 = THEME.destructive
	ConfirmClose.Text = "Close script"
	ConfirmClose.ZIndex = 103
	ConfirmClose.Parent = ConfirmActions
	corner(ConfirmClose, THEME.radiusSm)
	stroke(ConfirmClose, Color3.fromRGB(127, 29, 29))

	local function setGuiVisible(visible)
		guiVisible = visible
		Root.Visible = visible
	end

	local function toggleGui()
		setGuiVisible(not guiVisible)
	end

	local connections = {}
	local function track(conn)
		table.insert(connections, conn)
		return conn
	end

	local lastToggle = 0
	local function onToggleHotkey()
		if not alive then
			return
		end
		if os.clock() - lastToggle < 0.15 then
			return
		end
		lastToggle = os.clock()
		toggleGui()
	end

	local TOGGLE_ACTION = "BombFishingFarm_Toggle"
	ContextActionService:BindAction(
		TOGGLE_ACTION,
		function(_, state)
			if state == Enum.UserInputState.Begin then
				onToggleHotkey()
			end
			return Enum.ContextActionResult.Sink
		end,
		false,
		TOGGLE_KEY
	)

	local function shutdownScript()
		if not alive then
			return
		end
		alive = false
		farming = false
		claiming = false
		claimCage = false
		autoRebirth = false
		pcall(function()
			ContextActionService:UnbindAction(TOGGLE_ACTION)
		end)
		for _, conn in ipairs(connections) do
			pcall(function()
				conn:Disconnect()
			end)
		end
		table.clear(connections)
		if ScreenGui.Parent then
			ScreenGui:Destroy()
		end
		if _G.__BombFishingFarmActiveId == SCRIPT_ID then
			_G.__BombFishingFarmActiveId = nil
		end
		_G.__BombFishingFarmShutdown = nil
	end

	_G.__BombFishingFarmShutdown = shutdownScript

	local function showCloseConfirm()
		ConfirmOverlay.Active = true
		ConfirmOverlay.Visible = true
	end

	local function hideCloseConfirm()
		ConfirmOverlay.Active = false
		ConfirmOverlay.Visible = false
	end

	ConfirmCancel.MouseButton1Click:Connect(hideCloseConfirm)
	ConfirmClose.MouseButton1Click:Connect(shutdownScript)
	ConfirmOverlay.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and input.Target == ConfirmOverlay then
			hideCloseConfirm()
		end
	end)

	local function getKnitRE(serviceName, remoteName)
		local src = ReplicatedStorage:FindFirstChild("src")
		if not src then return nil end
		local re = src:FindFirstChild("Modules")
		re = re and re:FindFirstChild("KnitClient")
		re = re and re:FindFirstChild("Services")
		re = re and re:FindFirstChild(serviceName)
		re = re and re:FindFirstChild("RE")
		re = re and re:FindFirstChild(remoteName)
		if re and (re:IsA("RemoteEvent") or re:IsA("UnreliableRemoteEvent")) then
			return re
		end
		return nil
	end

	local function getBombRE(remoteName)
		return getKnitRE("BombService", remoteName)
	end

	local StartRemote = getBombRE("Start")
	local ThrowRemote = getBombRE("Throw")
	local SendTagDataRemote = getKnitRE("BaseService", "SendTagData")
	local SellInventoryRemote = getKnitRE("SellService", "SellInventory")
	local cachedBaseName = learnedBaseName

	local function setLearnedBase(name)
		learnedBaseName = name
		cachedBaseName = name
	end

	task.spawn(function()
		local src = ReplicatedStorage:WaitForChild("src", 15)
		if not src then return end
		StartRemote = StartRemote or getBombRE("Start")
		ThrowRemote = ThrowRemote or getBombRE("Throw")
		SendTagDataRemote = SendTagDataRemote or getKnitRE("BaseService", "SendTagData")
		SellInventoryRemote = SellInventoryRemote or getKnitRE("SellService", "SellInventory")

		local remote = SendTagDataRemote
		if remote and hookfunction then
			local oldFire
			pcall(function()
				oldFire = hookfunction(remote.FireServer, function(self, tag, obj, ...)
					if rawequal(self, remote) and obj and type(tag) == "string" then
						local bases = workspace:FindFirstChild("Bases")
						if bases and obj:IsDescendantOf(bases) then
							local current = obj
							while current and current.Parent ~= bases do
								current = current.Parent
							end
							if current and current.Parent == bases then
								setLearnedBase(current.Name)
							end
						end
					end
					return oldFire(self, tag, obj, ...)
				end)
			end)
		end
	end)

	local PLAYER_BASE_ATTRS = { "BaseId", "PlotId", "BaseIndex", "PlotIndex", "AssignedBase" }
	local OWNER_ATTRS = { "UserId", "OwnerUserId", "OwnerId", "PlayerUserId", "Owner", "Player" }

	local function baseMatchesPlayer(base, player)
		for _, key in ipairs(OWNER_ATTRS) do
			local val = base:GetAttribute(key)
			if val ~= nil then
				if val == player.UserId or val == player.Name or tostring(val) == tostring(player.UserId) then
					return true
				end
			end
		end
		local ownerVal = base:FindFirstChild("Owner")
		if ownerVal then
			if ownerVal:IsA("ObjectValue") and ownerVal.Value == player then
				return true
			end
			if (ownerVal:IsA("StringValue") or ownerVal:IsA("IntValue")) then
				local v = ownerVal.Value
				if v == player.UserId or v == player.Name or tostring(v) == tostring(player.UserId) then
					return true
				end
			end
		end
		return false
	end

	local function getInteractableInBase(base, name)
		local floor1 = base:FindFirstChild("Floor1")
		local interactables = floor1 and floor1:FindFirstChild("Interactables")
		return interactables and interactables:FindFirstChild(name)
	end

	local function getCollectInBase(base)
		return getInteractableInBase(base, "Collect")
	end

	local function getAquariumInBase(base)
		return getInteractableInBase(base, "Aquarium")
	end

	local function getCageBridgeInBase(base)
		return getInteractableInBase(base, "CageBridge")
	end

	local function getWorldPosition(inst)
		if not inst then return nil end
		if inst:IsA("BasePart") then
			return inst.Position
		end
		if inst:IsA("Model") then
			return inst:GetPivot().Position
		end
		local part = inst:FindFirstChildWhichIsA("BasePart", true)
		return part and part.Position
	end

	local function deepBaseMatchesPlayer(base, player)
		for _, desc in ipairs(base:GetDescendants()) do
			if desc:IsA("ObjectValue") and desc.Value == player then
				return true
			end
			for _, key in ipairs(OWNER_ATTRS) do
				local val = desc:GetAttribute(key)
				if val ~= nil then
					if val == player.UserId or val == player.Name or tostring(val) == tostring(player.UserId) then
						return true
					end
				end
			end
		end
		return false
	end

	local function findBaseByPlayerSign(bases, player)
		local names = { player.Name, player.DisplayName }
		for _, base in ipairs(bases:GetChildren()) do
			for _, desc in ipairs(base:GetDescendants()) do
				if desc:IsA("TextLabel") or desc:IsA("TextButton") then
					local text = desc.Text
					for _, name in ipairs(names) do
						if name ~= "" and (text == name or string.find(text, name, 1, true)) then
							return base
						end
					end
				end
			end
		end
		return nil
	end

	local function findBaseWhenClearlyAtHome(bases, player)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then return nil end

		local dists = {}
		for _, base in ipairs(bases:GetChildren()) do
			local collect = getCollectInBase(base)
			local pos = getWorldPosition(collect)
			if pos then
				table.insert(dists, { base = base, dist = (root.Position - pos).Magnitude })
			end
		end
		table.sort(dists, function(a, b)
			return a.dist < b.dist
		end)

		if #dists == 0 or dists[1].dist > 50 then
			return nil
		end
		if #dists >= 2 and (dists[2].dist - dists[1].dist) < 80 then
			return nil
		end
		return dists[1].base
	end

	local function getYourBasePartInBase(base)
		return getInteractableInBase(base, "YourBasePart")
	end

	local function getBaseFolderFromInstance(inst, bases)
		if not inst or not bases then return nil end
		local current = inst
		while current and current.Parent ~= bases do
			current = current.Parent
		end
		if current and current.Parent == bases then
			return current
		end
		return nil
	end

	local function getBasesFolder(waitSeconds)
		local bases = workspace:FindFirstChild("Bases")
		if bases or not waitSeconds then
			return bases
		end
		local ok, result = pcall(function()
			return workspace:WaitForChild("Bases", waitSeconds)
		end)
		return ok and result or nil
	end

	local function findKnitModule()
		local packages = ReplicatedStorage:FindFirstChild("Packages")
		if packages then
			local knit = packages:FindFirstChild("Knit")
			if knit and knit:IsA("ModuleScript") then
				return knit
			end
		end
		for _, inst in ipairs(ReplicatedStorage:GetDescendants()) do
			if inst.Name == "Knit" and inst:IsA("ModuleScript") then
				return inst
			end
		end
		return nil
	end

	local function getBaseController()
		local knitModule = findKnitModule()
		if knitModule then
			local ok, Knit = pcall(require, knitModule)
			if ok and type(Knit) == "table" and type(Knit.GetController) == "function" then
				local ok2, ctrl = pcall(function()
					return Knit:GetController("BaseController")
				end)
				if ok2 and type(ctrl) == "table" then
					return ctrl
				end
			end
		end

		local src = ReplicatedStorage:FindFirstChild("src")
		local controllers = src and src:FindFirstChild("Controllers")
		local gameFolder = controllers and controllers:FindFirstChild("Game")
		local mod = gameFolder and gameFolder:FindFirstChild("BaseController")
		if not mod then return nil end
		local ok, ctrl = pcall(require, mod)
		if ok and type(ctrl) == "table" then
			return ctrl
		end
		return nil
	end

	local function getYourBaseFn()
		local ctrl = getBaseController()
		local tagFns = ctrl and ctrl.TagFunctions
		local fn = tagFns and tagFns.YourBase
		if type(fn) == "function" then
			return fn
		end
		return nil
	end

	local function isYourBaseInstance(inst)
		local fn = getYourBaseFn()
		if not fn or not inst then return false end
		local ok, result = pcall(fn, inst)
		return ok and result == true
	end

	local function findBaseViaTagFunctions(bases)
		local yourBaseFn = getYourBaseFn()
		if not yourBaseFn then
			return nil
		end

		for _, base in ipairs(bases:GetChildren()) do
			local yourBasePart = getYourBasePartInBase(base)
			if isYourBaseInstance(yourBasePart) then
				return base
			end
			local collect = getCollectInBase(base)
			if isYourBaseInstance(collect) then
				return base
			end
		end

		for _, inst in ipairs(CollectionService:GetTagged("YourBase")) do
			if inst:IsDescendantOf(bases) and not inst:IsDescendantOf(ReplicatedStorage) then
				if isYourBaseInstance(inst) then
					local base = getBaseFolderFromInstance(inst, bases)
					if base then return base end
				end
			end
		end

		return nil
	end

	local function tryBaseControllerBase(bases)
		local ctrl = getBaseController()
		if not ctrl then return nil end

		for _, key in ipairs({ "BaseId", "baseId", "PlotId", "plotId", "AssignedBase", "MyBase", "YourBase", "Base", "base", "Index", "index" }) do
			local v = ctrl[key]
			if type(v) == "string" or type(v) == "number" then
				local base = bases:FindFirstChild(tostring(v))
				if base then return base end
			elseif typeof(v) == "Instance" and bases:IsAncestorOf(v) then
				local current = v
				while current and current.Parent ~= bases do
					current = current.Parent
				end
				if current and current.Parent == bases then
					return current
				end
			end
		end

		for _, v in pairs(ctrl) do
			if type(v) == "string" or type(v) == "number" then
				local base = bases:FindFirstChild(tostring(v))
				if base and getCollectInBase(base) then
					return base
				end
			end
		end
		return nil
	end

	local function getCachedBaseFolder(bases)
		if not cachedBaseName or not bases then
			return nil
		end
		local cached = bases:FindFirstChild(cachedBaseName)
		if cached and getCollectInBase(cached) then
			return cached
		end
		setLearnedBase(nil)
		return nil
	end

	local function resolvePlayerBase()
		local bases = getBasesFolder()
		if not bases then return nil end

		local fromCache = getCachedBaseFolder(bases)
		if fromCache then
			return fromCache
		end

		local fromTagFn = findBaseViaTagFunctions(bases)
		if fromTagFn then
			setLearnedBase(fromTagFn.Name)
			return fromTagFn
		end

		for _, key in ipairs(PLAYER_BASE_ATTRS) do
			local id = LocalPlayer:GetAttribute(key)
			if id ~= nil then
				local base = bases:FindFirstChild(tostring(id))
				if base and getCollectInBase(base) then
					setLearnedBase(base.Name)
					return base
				end
			end
		end

		for _, base in ipairs(bases:GetChildren()) do
			if baseMatchesPlayer(base, LocalPlayer) or deepBaseMatchesPlayer(base, LocalPlayer) then
				setLearnedBase(base.Name)
				return base
			end
		end

		local fromSign = findBaseByPlayerSign(bases, LocalPlayer)
		if fromSign then
			setLearnedBase(fromSign.Name)
			return fromSign
		end

		local fromController = tryBaseControllerBase(bases)
		if fromController then
			setLearnedBase(fromController.Name)
			return fromController
		end

		local fromHome = findBaseWhenClearlyAtHome(bases, LocalPlayer)
		if fromHome then
			setLearnedBase(fromHome.Name)
			return fromHome
		end

		return nil
	end

	local function resolveGuiPath(root, path)
		local current = root
		for _, name in ipairs(path) do
			current = current and current:FindFirstChild(name)
		end
		return current
	end

	local function pressGuiOnce(btn)
		if not btn or not btn:IsA("GuiButton") then
			return false
		end
		if getconnections then
			for _, conn in ipairs(getconnections(btn.MouseButton1Click)) do
				if conn.Function then
					pcall(conn.Function)
					return true
				end
			end
			if btn.Activated then
				for _, conn in ipairs(getconnections(btn.Activated)) do
					if conn.Function then
						pcall(conn.Function)
						return true
					end
				end
			end
		end
		if firesignal then
			pcall(firesignal, btn.MouseButton1Click)
			return true
		end
		return false
	end

	local function pressPlotButton()
		local pg = LocalPlayer:FindFirstChild("PlayerGui")
		local target = pg and resolveGuiPath(pg, CONFIG.PlotButtonPath)
		if not target then
			target = resolveGuiPath(game:GetService("StarterGui"), CONFIG.PlotButtonPath)
		end
		if not target then
			return false
		end

		local btn = target:IsA("GuiButton") and target or nil
		if not btn then
			local cur = target
			while cur do
				if cur:IsA("GuiButton") then
					btn = cur
					break
				end
				cur = cur.Parent
			end
		end
		if not btn then
			for _, desc in ipairs(target:GetDescendants()) do
				if desc:IsA("GuiButton") then
					btn = desc
					break
				end
			end
		end

		return btn and pressGuiOnce(btn) or false
	end

	local function ensureFarmRemotes()
		if StartRemote and ThrowRemote then
			return true
		end
		local src = ReplicatedStorage:FindFirstChild("src") or ReplicatedStorage:WaitForChild("src", 15)
		if not src then
			return false
		end
		StartRemote = StartRemote or getBombRE("Start")
		ThrowRemote = ThrowRemote or getBombRE("Throw")
		return StartRemote ~= nil and ThrowRemote ~= nil
	end

	local function doStart()
		if not ensureFarmRemotes() then
			return false
		end
		StartRemote:FireServer(CONFIG.StartArg)
		return true
	end

	local function doThrow()
		if not ensureFarmRemotes() then
			return false
		end
		ThrowRemote:FireServer(THROW_POWER)
		return true
	end

	local function doClaim()
		if not alive then
			return false
		end
		if not SendTagDataRemote then
			SendTagDataRemote = getKnitRE("BaseService", "SendTagData")
		end
		local bases = getBasesFolder()
		local base = getCachedBaseFolder(bases) or resolvePlayerBase()
		local target = base and getCollectInBase(base)
		if not SendTagDataRemote or not target then
			return false
		end
		SendTagDataRemote:FireServer("Collect", target, "collectCash")
		return true
	end

	local function runAutoClaimOnce()
		if not alive then
			return
		end
		ReplicatedStorage:WaitForChild("src", 20)
		SendTagDataRemote = SendTagDataRemote or getKnitRE("BaseService", "SendTagData")
		getBasesFolder(15)
		for _ = 1, 15 do
			if not alive then
				return
			end
			if resolvePlayerBase() then
				break
			end
			task.wait(0.5)
		end
		for _ = 1, 6 do
			if not alive then
				return
			end
			if doClaim() then
				break
			end
			resolvePlayerBase()
			task.wait(0.5)
		end
		CONFIG._lastClaim = os.clock()
	end

	local function doClaimCage()
		if not alive then
			return false
		end
		if not SendTagDataRemote then
			SendTagDataRemote = getKnitRE("BaseService", "SendTagData")
		end
		local bases = getBasesFolder()
		local base = getCachedBaseFolder(bases) or resolvePlayerBase()
		local cageBridge = base and getCageBridgeInBase(base)
		if not SendTagDataRemote or not cageBridge then
			return false
		end
		SendTagDataRemote:FireServer("CageBridge", cageBridge, "claimFishes")
		return true
	end

	local function runAutoClaimCageOnce()
		if not alive then
			return
		end
		ReplicatedStorage:WaitForChild("src", 20)
		SendTagDataRemote = SendTagDataRemote or getKnitRE("BaseService", "SendTagData")
		getBasesFolder(15)
		for _ = 1, 15 do
			if not alive or not claimCage then
				return
			end
			if resolvePlayerBase() then
				break
			end
			task.wait(0.5)
		end
		for _ = 1, 6 do
			if not alive or not claimCage then
				return
			end
			if doClaimCage() then
				break
			end
			resolvePlayerBase()
			task.wait(0.5)
		end
		CONFIG._lastCageClaim = os.clock()
	end

	local function doEquipBest()
		if not alive or not farming or not equipBest then
			return false
		end
		if not SendTagDataRemote then
			SendTagDataRemote = getKnitRE("BaseService", "SendTagData")
		end
		local bases = getBasesFolder()
		local base = getCachedBaseFolder(bases) or resolvePlayerBase()
		local aquarium = base and getAquariumInBase(base)
		if not SendTagDataRemote or not aquarium then
			return false
		end
		SendTagDataRemote:FireServer("Aquarium", aquarium, "equipBest")
		return true
	end

	local function doSellInventory()
		if not alive or not farming or not autoSell then
			return false
		end
		if not SellInventoryRemote then
			SellInventoryRemote = getKnitRE("SellService", "SellInventory")
		end
		if not SellInventoryRemote then
			return false
		end
		SellInventoryRemote:FireServer()
		return true
	end

	local function loadGameConfig()
		if GameConfig then
			return true
		end
		local configModule = ReplicatedStorage:FindFirstChild("Config")
		if not configModule then
			return false
		end
		local ok, cfg = pcall(require, configModule)
		if ok and cfg then
			GameConfig = cfg
			return true
		end
		return false
	end

	local function getRebirthInfo()
		if not dataReplica or not dataReplica.Data then
			return nil
		end
		loadGameConfig()
		if not GameConfig or not GameConfig.Rebirth then
			return nil
		end

		local rebirth = dataReplica.Data.Rebirth or 0
		local cash = dataReplica.Data.Cash or 0
		local nextTier = GameConfig.Rebirth.Rebirths[rebirth + 1]

		if not nextTier then
			return {
				rebirth = rebirth,
				cash = cash,
				maxed = true,
				canRebirth = false,
			}
		end

		local needed = nextTier.Requirements.Cash
		return {
			rebirth = rebirth,
			cash = cash,
			needed = needed,
			maxed = false,
			canRebirth = cash >= needed,
		}
	end

	local function tryAutoRebirth()
		if not isActiveScript() then
			return false
		end
		if not autoRebirth then
			return false
		end
		if farmCycleBusy then
			return false
		end
		if os.clock() - lastRebirthFire < 1 then
			return false
		end

		local info = getRebirthInfo()
		if not info or info.maxed or not info.canRebirth then
			return false
		end
		if not RebirthServiceClient or not RebirthServiceClient.Rebirth then
			return false
		end

		RebirthServiceClient.Rebirth:Fire()
		lastRebirthFire = os.clock()
		return true
	end

	local function refreshRebirthRow()
		if not isActiveScript() then
			return
		end
		local row = toggleRows["Auto Rebirth"]
		if not row then
			return
		end

		if not autoRebirth then
			row.row:SetAttribute("Active", false)
			row.btn.BackgroundColor3 = THEME.card
			row.status.Text = "OFF"
			row.status.TextColor3 = THEME.mutedForeground
			return
		end

		row.row:SetAttribute("Active", true)
		row.btn.BackgroundColor3 = THEME.sidebarAccent

		local info = getRebirthInfo()
		if not info then
			row.status.Text = "..."
			row.status.TextColor3 = THEME.mutedForeground
			return
		end
		if info.maxed then
			row.status.Text = "MAX"
			row.status.TextColor3 = THEME.mutedForeground
		elseif info.canRebirth then
			row.status.Text = "READY"
			row.status.TextColor3 = THEME.success
		else
			row.status.Text = "R" .. tostring(info.rebirth)
			row.status.TextColor3 = THEME.mutedForeground
		end
	end

	local function setupRebirthSystems()
		loadGameConfig()
		local src = ReplicatedStorage:WaitForChild("src", 30)
		loadGameConfig()
		if not src then
			return
		end

		-- Get KnitClient (already required by the game itself)
		local okKnit, KnitClient = pcall(function()
			return require(src.Modules.KnitClient)
		end)
		if not okKnit or not KnitClient then
			return
		end

		-- Poll for DataController replica
		for _ = 1, 120 do
			if not alive then
				return
			end
			local ok, result = pcall(function()
				local dc = KnitClient.GetController("DataController")
				if not dc then
					return nil
				end
				local rep = dc:getDataReplica(true)
				if rep and rep.Data then
					return rep
				end
				return nil
			end)
			if ok and result then
				dataReplica = result
				break
			end
			task.wait(0.5)
		end

		if not dataReplica then
			return
		end

		-- Get RebirthService remote
		local okSvc, svc = pcall(function()
			return KnitClient.GetService("RebirthService")
		end)
		if okSvc and svc then
			RebirthServiceClient = svc
		end

		rebirthSystemsReady = true

		-- refreshStatus is safe to call here since we're in task.spawn (main-compatible thread)
		pcall(refreshStatus)
	end

	local rebirthSetupRunning = false
	local function ensureRebirthSystems()
		if rebirthSystemsReady or rebirthSetupRunning then
			return
		end
		rebirthSetupRunning = true
		task.spawn(function()
			setupRebirthSystems()
			rebirthSetupRunning = false
		end)
	end

	local function doFarmCycle()
		if not alive or not farming then
			return
		end

		if not doStart() then
			task.wait(2)
			return
		end

		task.wait(CONFIG.AfterStartWait)
		if not alive or not farming then
			return
		end

		if not doThrow() then
			task.wait(2)
			return
		end

		task.wait(CONFIG.RoundWait)

		if not alive or not farming then
			return
		end

		if equipBest then
			doEquipBest()
		end

		if autoSell then
			doSellInventory()
		end

		if CONFIG.PostFinishWait > 0 then
			task.wait(CONFIG.PostFinishWait)
		end
	end

	local function startFarmLoop()
		if not alive or not farming then
			return
		end
		farmGeneration = farmGeneration + 1
		local generation = farmGeneration
		task.spawn(function()
			while alive and farming and farmGeneration == generation do
				farmCycleBusy = true
				local ok, err = pcall(doFarmCycle)
				farmCycleBusy = false
				if autoRebirth then
					tryAutoRebirth()
				end
				if not ok then
					warn("[Bomb Fishing] farm cycle error:", err)
					task.wait(2)
				end
			end
		end)
	end

	local function setBadge(on, badgeText)
		if on then
			badgeText.Text = "ON"
			badgeText.TextColor3 = THEME.success
		else
			badgeText.Text = "OFF"
			badgeText.TextColor3 = THEME.mutedForeground
		end
	end

	local function setRowActive(label, on)
		local row = toggleRows[label]
		if not row then return end
		setBadge(on, row.status)
		row.row:SetAttribute("Active", on)
		row.btn.BackgroundColor3 = on and THEME.sidebarAccent or THEME.card
	end

	local function refreshStatus()
		setRowActive("Auto Farm", farming)
		setRowActive("Auto Claim Money", claiming)
		setRowActive("Auto Claim Cage", claimCage)
		setRowActive("Auto Equip Best", equipBest)
		setRowActive("Auto Sell Inventory", autoSell)
		if autoRebirth then
			if rebirthSystemsReady then
				refreshRebirthRow()
			else
				setRowActive("Auto Rebirth", true)
				local row = toggleRows["Auto Rebirth"]
				if row then
					row.status.Text = "..."
					row.status.TextColor3 = THEME.mutedForeground
				end
			end
		else
			setRowActive("Auto Rebirth", false)
		end
	end

	local function toggleAutoClaim()
		claiming = not claiming
		if claiming then
			task.spawn(function()
				runAutoClaimOnce()
				refreshStatus()
			end)
		end
		refreshStatus()
	end

	local function toggleAutoClaimCage()
		claimCage = not claimCage
		if claimCage then
			task.spawn(function()
				runAutoClaimCageOnce()
				refreshStatus()
			end)
		end
		refreshStatus()
	end

	local function startupPlotAndClaim()
		if not alive then
			return
		end
		pressPlotButton()
		SendTagDataRemote = SendTagDataRemote or getKnitRE("BaseService", "SendTagData")
		resolvePlayerBase()
		doClaim()
		CONFIG._lastClaim = os.clock()
		refreshStatus()
	end

	local function wireToggle(label, handler)
		local row = toggleRows[label]
		if not row then
			return
		end
		track(row.hit.MouseButton1Click:Connect(function()
			if not isActiveScript() then
				return
			end
			handler()
			refreshStatus()
		end))
	end

	wireToggle("Auto Farm", function()
		farming = not farming
		if farming then
			startFarmLoop()
		end
	end)
	wireToggle("Auto Claim Money", function()
		claiming = not claiming
		if claiming then
			task.spawn(function()
				runAutoClaimOnce()
				refreshStatus()
			end)
		end
	end)
	wireToggle("Auto Claim Cage", function()
		claimCage = not claimCage
		if claimCage then
			task.spawn(function()
				runAutoClaimCageOnce()
				refreshStatus()
			end)
		end
	end)
	wireToggle("Auto Equip Best", function()
		equipBest = not equipBest
	end)
	wireToggle("Auto Sell Inventory", function()
		autoSell = not autoSell
	end)
	wireToggle("Auto Rebirth", function()
		autoRebirth = not autoRebirth
		if autoRebirth then
			ensureRebirthSystems()
			tryAutoRebirth()
		end
	end)

	CloseBtn.MouseButton1Click:Connect(showCloseConfirm)

	track(UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end
		if input.KeyCode == TOGGLE_KEY then
			onToggleHotkey()
		end
	end))

	track(RunService.Heartbeat:Connect(function()
		if not alive then
			return
		end
		local now = os.clock()
		if claiming and now - CONFIG._lastClaim >= CONFIG.ClaimDelay then
			CONFIG._lastClaim = now
			doClaim()
		end
		if claimCage and now - CONFIG._lastCageClaim >= CONFIG.CageClaimDelay then
			CONFIG._lastCageClaim = now
			doClaimCage()
		end
		if autoRebirth and rebirthSystemsReady and now - lastRebirthPoll >= CONFIG.RebirthPollInterval then
			lastRebirthPoll = now
			refreshRebirthRow()
			tryAutoRebirth()
		end
	end))

	track(CollectionService:GetInstanceAddedSignal("YourBase"):Connect(function(inst)
		local bases = getBasesFolder()
		if not bases or not inst:IsDescendantOf(bases) then return end
		if inst:IsDescendantOf(ReplicatedStorage) then return end
		if not isYourBaseInstance(inst) then return end
		local base = getBaseFolderFromInstance(inst, bases)
		if base then
			setLearnedBase(base.Name)
		end
	end))

	task.spawn(startupPlotAndClaim)

	refreshStatus()
end

pcall(run)
