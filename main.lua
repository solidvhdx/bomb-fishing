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
local THEME = {
	background = Color3.fromRGB(6, 9, 15),
	backgroundAlt = Color3.fromRGB(10, 15, 24),
	foreground = Color3.fromRGB(244, 247, 255),
	foregroundSoft = Color3.fromRGB(226, 232, 240),
	card = Color3.fromRGB(15, 23, 36),
	cardElevated = Color3.fromRGB(19, 30, 46),
	cardHover = Color3.fromRGB(23, 36, 56),
	cardActive = Color3.fromRGB(25, 43, 68),
	mutedForeground = Color3.fromRGB(141, 158, 182),
	border = Color3.fromRGB(43, 57, 80),
	borderSoft = Color3.fromRGB(30, 41, 59),
	secondary = Color3.fromRGB(17, 24, 39),
	secondaryForeground = Color3.fromRGB(236, 242, 255),
	accent = Color3.fromRGB(96, 165, 250),
	accentSoft = Color3.fromRGB(30, 41, 59),
	accentGlow = Color3.fromRGB(59, 130, 246),
	sidebar = Color3.fromRGB(11, 18, 29),
	sidebarAccent = Color3.fromRGB(28, 43, 68),
	destructive = Color3.fromRGB(248, 113, 113),
	destructiveSurface = Color3.fromRGB(61, 21, 29),
	success = Color3.fromRGB(74, 222, 128),
	successSurface = Color3.fromRGB(18, 52, 41),
	shadow = Color3.fromRGB(2, 6, 12),
	radius = 18,
	radiusSm = 12,
	radiusXs = 8,
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

local function gradient(parent, rotation, colors, transparency)
	local g = Instance.new("UIGradient")
	g.Rotation = rotation or 0
	g.Color = colors
	if transparency then
		g.Transparency = transparency
	end
	g.Parent = parent
	return g
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
	local VirtualUser = game:GetService("VirtualUser")
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
		RoundMaxWait = 120,
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
	local no3dRender = false
	local antiAfk = false
	local antiAfkConn = nil
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
	local FOOTER_H = 44

	local Root = Instance.new("Frame")
	Root.Name = "Root"
	Root.Size = UDim2.fromOffset(452, 774)
	Root.Position = UDim2.new(0, 24, 0.04, 0)
	Root.BackgroundTransparency = 1
	Root.BorderSizePixel = 0
	Root.Active = true
	Root.ClipsDescendants = false
	Root.Parent = ScreenGui

	local RootShadow = Instance.new("Frame")
	RootShadow.Name = "RootShadow"
	RootShadow.Size = UDim2.new(1, 18, 1, 20)
	RootShadow.Position = UDim2.fromOffset(8, 10)
	RootShadow.BackgroundColor3 = THEME.shadow
	RootShadow.BackgroundTransparency = 0.3
	RootShadow.BorderSizePixel = 0
	RootShadow.ZIndex = 0
	RootShadow.Parent = Root
	corner(RootShadow, THEME.radius + 4)
	gradient(
		RootShadow,
		90,
		ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(8, 13, 20)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(2, 5, 10)),
		}),
		NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.15),
			NumberSequenceKeypoint.new(1, 0.5),
		})
	)

	local RootShell = Instance.new("Frame")
	RootShell.Name = "RootShell"
	RootShell.Size = UDim2.fromScale(1, 1)
	RootShell.BackgroundColor3 = THEME.background
	RootShell.BorderSizePixel = 0
	RootShell.ZIndex = 1
	RootShell.Parent = Root
	corner(RootShell, THEME.radius)
	stroke(RootShell, THEME.border)
	gradient(
		RootShell,
		90,
		ColorSequence.new({
			ColorSequenceKeypoint.new(0, THEME.backgroundAlt),
			ColorSequenceKeypoint.new(0.45, THEME.background),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 8, 14)),
		})
	)

	local RootHighlight = Instance.new("Frame")
	RootHighlight.Name = "RootHighlight"
	RootHighlight.Size = UDim2.new(1, -2, 0, 154)
	RootHighlight.Position = UDim2.fromOffset(1, 1)
	RootHighlight.BackgroundColor3 = THEME.accent
	RootHighlight.BackgroundTransparency = 0.82
	RootHighlight.BorderSizePixel = 0
	RootHighlight.ZIndex = 1
	RootHighlight.Parent = RootShell
	corner(RootHighlight, THEME.radius)
	gradient(
		RootHighlight,
		90,
		ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(96, 165, 250)),
			ColorSequenceKeypoint.new(0.6, Color3.fromRGB(56, 189, 248)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 23, 42)),
		}),
		NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.55),
			NumberSequenceKeypoint.new(0.6, 0.82),
			NumberSequenceKeypoint.new(1, 1),
		})
	)

	HEADER_H = 120
	local TopBar = Instance.new("Frame")
	TopBar.Name = "TopBar"
	TopBar.Size = UDim2.new(1, 0, 0, HEADER_H)
	TopBar.BackgroundTransparency = 1
	TopBar.BorderSizePixel = 0
	TopBar.ZIndex = 2
	TopBar.Parent = RootShell

	local TopBarDivider = Instance.new("Frame")
	TopBarDivider.Size = UDim2.new(1, -28, 0, 1)
	TopBarDivider.Position = UDim2.new(0, 14, 1, -1)
	TopBarDivider.BackgroundColor3 = THEME.borderSoft
	TopBarDivider.BorderSizePixel = 0
	TopBarDivider.ZIndex = 2
	TopBarDivider.Parent = TopBar

	local HeaderBadge = Instance.new("Frame")
	HeaderBadge.Name = "HeaderBadge"
	HeaderBadge.Size = UDim2.fromOffset(82, 24)
	HeaderBadge.Position = UDim2.fromOffset(18, 18)
	HeaderBadge.BackgroundColor3 = THEME.accentSoft
	HeaderBadge.BorderSizePixel = 0
	HeaderBadge.ZIndex = 3
	HeaderBadge.Parent = TopBar
	corner(HeaderBadge, THEME.radiusXs)
	stroke(HeaderBadge, THEME.border)
	gradient(
		HeaderBadge,
		0,
		ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 34, 54)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 27, 43)),
		})
	)

	local HeaderBadgeText = Instance.new("TextLabel")
	HeaderBadgeText.Size = UDim2.fromScale(1, 1)
	HeaderBadgeText.BackgroundTransparency = 1
	HeaderBadgeText.Font = Enum.Font.GothamBold
	HeaderBadgeText.TextSize = 10
	HeaderBadgeText.TextColor3 = THEME.foregroundSoft
	HeaderBadgeText.Text = "SHADCN"
	HeaderBadgeText.ZIndex = 4
	HeaderBadgeText.Parent = HeaderBadge

	local TopTitle = Instance.new("TextLabel")
	TopTitle.Size = UDim2.new(1, -88, 0, 26)
	TopTitle.Position = UDim2.fromOffset(18, 50)
	TopTitle.BackgroundTransparency = 1
	TopTitle.Font = Enum.Font.GothamBold
	TopTitle.TextSize = 22
	TopTitle.TextXAlignment = Enum.TextXAlignment.Left
	TopTitle.TextColor3 = THEME.foreground
	TopTitle.Text = "Bomb Fishing Control"
	TopTitle.ZIndex = 3
	TopTitle.Parent = TopBar

	local HeaderSubtitle = Instance.new("TextLabel")
	HeaderSubtitle.Size = UDim2.new(1, -120, 0, 34)
	HeaderSubtitle.Position = UDim2.fromOffset(18, 78)
	HeaderSubtitle.BackgroundTransparency = 1
	HeaderSubtitle.Font = Enum.Font.Gotham
	HeaderSubtitle.TextSize = 12
	HeaderSubtitle.TextWrapped = true
	HeaderSubtitle.TextXAlignment = Enum.TextXAlignment.Left
	HeaderSubtitle.TextYAlignment = Enum.TextYAlignment.Top
	HeaderSubtitle.TextColor3 = THEME.mutedForeground
	HeaderSubtitle.Text = "Every toggle keeps the same logic, remotes, and timing. Only the shell gets rebuilt."
	HeaderSubtitle.ZIndex = 3
	HeaderSubtitle.Parent = TopBar

	local HeaderStatus = Instance.new("Frame")
	HeaderStatus.Name = "HeaderStatus"
	HeaderStatus.Size = UDim2.fromOffset(106, 28)
	HeaderStatus.AnchorPoint = Vector2.new(1, 0)
	HeaderStatus.Position = UDim2.new(1, -86, 0, 18)
	HeaderStatus.BackgroundColor3 = THEME.successSurface
	HeaderStatus.BorderSizePixel = 0
	HeaderStatus.ZIndex = 3
	HeaderStatus.Parent = TopBar
	corner(HeaderStatus, THEME.radiusXs)
	stroke(HeaderStatus, Color3.fromRGB(34, 85, 62))

	local HeaderStatusDot = Instance.new("Frame")
	HeaderStatusDot.Size = UDim2.fromOffset(8, 8)
	HeaderStatusDot.Position = UDim2.fromOffset(12, 10)
	HeaderStatusDot.BackgroundColor3 = THEME.success
	HeaderStatusDot.BorderSizePixel = 0
	HeaderStatusDot.ZIndex = 4
	HeaderStatusDot.Parent = HeaderStatus
	corner(HeaderStatusDot, 99)

	local HeaderStatusText = Instance.new("TextLabel")
	HeaderStatusText.Size = UDim2.new(1, -28, 1, 0)
	HeaderStatusText.Position = UDim2.fromOffset(24, 0)
	HeaderStatusText.BackgroundTransparency = 1
	HeaderStatusText.Font = Enum.Font.GothamSemibold
	HeaderStatusText.TextSize = 11
	HeaderStatusText.TextXAlignment = Enum.TextXAlignment.Left
	HeaderStatusText.TextColor3 = THEME.success
	HeaderStatusText.Text = "Stable"
	HeaderStatusText.ZIndex = 4
	HeaderStatusText.Parent = HeaderStatus

	local CloseBtn = Instance.new("TextButton")
	CloseBtn.Size = UDim2.fromOffset(32, 32)
	CloseBtn.Position = UDim2.new(1, -44, 0, 16)
	CloseBtn.BackgroundColor3 = THEME.secondary
	CloseBtn.BorderSizePixel = 0
	CloseBtn.AutoButtonColor = false
	CloseBtn.Font = Enum.Font.GothamBold
	CloseBtn.TextSize = 13
	CloseBtn.TextColor3 = THEME.mutedForeground
	CloseBtn.Text = "X"
	CloseBtn.ZIndex = 4
	CloseBtn.Parent = TopBar
	corner(CloseBtn, THEME.radiusSm)
	stroke(CloseBtn, THEME.border)
	gradient(
		CloseBtn,
		90,
		ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 27, 42)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(13, 20, 31)),
		})
	)

	CloseBtn.MouseEnter:Connect(function()
		TweenService:Create(CloseBtn, TweenInfo.new(0.12), {
			BackgroundColor3 = THEME.cardHover,
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
	Body.BackgroundTransparency = 1
	Body.BorderSizePixel = 0
	Body.ClipsDescendants = true
	Body.ZIndex = 2
	Body.Parent = RootShell

	local ListPad = Instance.new("Frame")
	ListPad.Size = UDim2.new(1, 0, 1, 0)
	ListPad.BackgroundTransparency = 1
	ListPad.BorderSizePixel = 0
	ListPad.Parent = Body
	padding(ListPad, 12, 14, 10, 14)

	local ListLayout = Instance.new("UIListLayout")
	ListLayout.Padding = UDim.new(0, 8)
	ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	ListLayout.Parent = ListPad

	local toggleRows = {}
	local rowDescriptions = {
		["Auto Farm"] = "Loop the fishing cycle continuously.",
		["Auto Claim Money"] = "Collect cash from your base on schedule.",
		["Auto Claim Cage"] = "Claim fish from the cage bridge timer.",
		["Auto Equip Best"] = "Equip the strongest available fish setup.",
		["Auto Sell Inventory"] = "Sell inventory after each completed round.",
		["Auto Rebirth"] = "Watch rebirth progress and fire when ready.",
		["No 3D Render"] = "Disable 3D rendering for lighter runtime load.",
		["Anti AFK"] = "Prevent idle kick while the script stays active.",
	}

	local HeroCard = Instance.new("Frame")
	HeroCard.Name = "HeroCard"
	HeroCard.LayoutOrder = 1
	HeroCard.Size = UDim2.new(1, 0, 0, 80)
	HeroCard.BackgroundColor3 = THEME.cardElevated
	HeroCard.BorderSizePixel = 0
	HeroCard.Parent = ListPad
	corner(HeroCard, THEME.radiusSm)
	stroke(HeroCard, THEME.border)
	gradient(
		HeroCard,
		0,
		ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 31, 47)),
			ColorSequenceKeypoint.new(0.55, Color3.fromRGB(16, 25, 39)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 20, 31)),
		})
	)

	local HeroStripe = Instance.new("Frame")
	HeroStripe.Size = UDim2.new(0, 4, 1, -24)
	HeroStripe.Position = UDim2.fromOffset(14, 12)
	HeroStripe.BackgroundColor3 = THEME.accent
	HeroStripe.BorderSizePixel = 0
	HeroStripe.Parent = HeroCard
	corner(HeroStripe, 99)

	local HeroTitle = Instance.new("TextLabel")
	HeroTitle.Size = UDim2.new(1, -146, 0, 20)
	HeroTitle.Position = UDim2.fromOffset(28, 14)
	HeroTitle.BackgroundTransparency = 1
	HeroTitle.Font = Enum.Font.GothamSemibold
	HeroTitle.TextSize = 14
	HeroTitle.TextXAlignment = Enum.TextXAlignment.Left
	HeroTitle.TextColor3 = THEME.foreground
	HeroTitle.Text = "Automation Suite"
	HeroTitle.Parent = HeroCard

	local HeroBody = Instance.new("TextLabel")
	HeroBody.Size = UDim2.new(1, -146, 0, 34)
	HeroBody.Position = UDim2.fromOffset(28, 36)
	HeroBody.BackgroundTransparency = 1
	HeroBody.Font = Enum.Font.Gotham
	HeroBody.TextSize = 11
	HeroBody.TextWrapped = true
	HeroBody.TextXAlignment = Enum.TextXAlignment.Left
	HeroBody.TextYAlignment = Enum.TextYAlignment.Top
	HeroBody.TextColor3 = THEME.mutedForeground
	HeroBody.Text = "Cleaner hierarchy, smoother states, and zero logic changes underneath the panel."
	HeroBody.Parent = HeroCard

	local HeroPill = Instance.new("Frame")
	HeroPill.Size = UDim2.fromOffset(98, 28)
	HeroPill.AnchorPoint = Vector2.new(1, 0.5)
	HeroPill.Position = UDim2.new(1, -14, 0.5, 0)
	HeroPill.BackgroundColor3 = THEME.accentSoft
	HeroPill.BorderSizePixel = 0
	HeroPill.Parent = HeroCard
	corner(HeroPill, THEME.radiusXs)
	stroke(HeroPill, THEME.border)

	local HeroPillText = Instance.new("TextLabel")
	HeroPillText.Size = UDim2.fromScale(1, 1)
	HeroPillText.BackgroundTransparency = 1
	HeroPillText.Font = Enum.Font.GothamSemibold
	HeroPillText.TextSize = 11
	HeroPillText.TextColor3 = THEME.foregroundSoft
	HeroPillText.Text = "Live Panel"
	HeroPillText.Parent = HeroPill

	local SectionLabel = Instance.new("TextLabel")
	SectionLabel.LayoutOrder = 2
	SectionLabel.Size = UDim2.new(1, 0, 0, 18)
	SectionLabel.BackgroundTransparency = 1
	SectionLabel.Font = Enum.Font.GothamBold
	SectionLabel.TextSize = 11
	SectionLabel.TextXAlignment = Enum.TextXAlignment.Left
	SectionLabel.TextColor3 = THEME.mutedForeground
	SectionLabel.Text = "AUTOMATION"
	SectionLabel.Parent = ListPad

	local function makeToggleRow(label, order, statusWidth)
		statusWidth = statusWidth or 72

		local row = Instance.new("Frame")
		row.Name = label
		row.LayoutOrder = order
		row.Size = UDim2.new(1, 0, 0, 52)
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
		gradient(
			bg,
			0,
			ColorSequence.new({
				ColorSequenceKeypoint.new(0, THEME.cardElevated),
				ColorSequenceKeypoint.new(1, THEME.card),
			})
		)

		local accentBar = Instance.new("Frame")
		accentBar.Name = "AccentBar"
		accentBar.Size = UDim2.new(0, 4, 1, -20)
		accentBar.Position = UDim2.fromOffset(12, 10)
		accentBar.BackgroundColor3 = THEME.border
		accentBar.BorderSizePixel = 0
		accentBar.ZIndex = 2
		accentBar.Parent = bg
		corner(accentBar, 99)

		local labelLbl = Instance.new("TextLabel")
		labelLbl.Size = UDim2.new(1, -(statusWidth + 94), 0, 18)
		labelLbl.Position = UDim2.fromOffset(28, 9)
		labelLbl.BackgroundTransparency = 1
		labelLbl.Font = Enum.Font.GothamSemibold
		labelLbl.TextSize = 13
		labelLbl.TextXAlignment = Enum.TextXAlignment.Left
		labelLbl.TextYAlignment = Enum.TextYAlignment.Bottom
		labelLbl.TextTruncate = Enum.TextTruncate.AtEnd
		labelLbl.TextColor3 = THEME.foreground
		labelLbl.Text = label
		labelLbl.ZIndex = 2
		labelLbl.Active = false
		labelLbl.Parent = row
		pcall(function()
			labelLbl.Interactable = false
		end)

		local descLbl = Instance.new("TextLabel")
		descLbl.Size = UDim2.new(1, -(statusWidth + 94), 0, 16)
		descLbl.Position = UDim2.fromOffset(28, 27)
		descLbl.BackgroundTransparency = 1
		descLbl.Font = Enum.Font.Gotham
		descLbl.TextSize = 10
		descLbl.TextXAlignment = Enum.TextXAlignment.Left
		descLbl.TextYAlignment = Enum.TextYAlignment.Top
		descLbl.TextTruncate = Enum.TextTruncate.AtEnd
		descLbl.TextColor3 = THEME.mutedForeground
		descLbl.Text = rowDescriptions[label] or "Automation control"
		descLbl.ZIndex = 2
		descLbl.Active = false
		descLbl.Parent = row
		pcall(function()
			descLbl.Interactable = false
		end)

		local statusChip = Instance.new("Frame")
		statusChip.Name = "StatusChip"
		statusChip.Size = UDim2.fromOffset(statusWidth, 28)
		statusChip.AnchorPoint = Vector2.new(1, 0.5)
		statusChip.Position = UDim2.new(1, -12, 0.5, 0)
		statusChip.BackgroundColor3 = THEME.secondary
		statusChip.BorderSizePixel = 0
		statusChip.ZIndex = 2
		statusChip.Parent = row
		corner(statusChip, THEME.radiusXs)
		stroke(statusChip, THEME.borderSoft)

		local statusLbl = Instance.new("TextLabel")
		statusLbl.Size = UDim2.fromScale(1, 1)
		statusLbl.BackgroundTransparency = 1
		statusLbl.Font = Enum.Font.GothamSemibold
		statusLbl.TextSize = 11
		statusLbl.TextXAlignment = Enum.TextXAlignment.Center
		statusLbl.TextYAlignment = Enum.TextYAlignment.Center
		statusLbl.TextColor3 = THEME.mutedForeground
		statusLbl.Text = "OFF"
		statusLbl.ZIndex = 2
		statusLbl.Active = false
		statusLbl.Parent = statusChip
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
				BackgroundColor3 = THEME.cardHover,
			}):Play()
			TweenService:Create(statusChip, TweenInfo.new(0.1), {
				BackgroundColor3 = THEME.accentSoft,
			}):Play()
			TweenService:Create(accentBar, TweenInfo.new(0.1), {
				BackgroundColor3 = THEME.accent,
			}):Play()
		end)
		hit.MouseLeave:Connect(function()
			if row:GetAttribute("Active") then
				return
			end
			TweenService:Create(bg, TweenInfo.new(0.1), {
				BackgroundColor3 = THEME.card,
			}):Play()
			TweenService:Create(statusChip, TweenInfo.new(0.1), {
				BackgroundColor3 = THEME.secondary,
			}):Play()
			TweenService:Create(accentBar, TweenInfo.new(0.1), {
				BackgroundColor3 = THEME.border,
			}):Play()
		end)

		toggleRows[label] = {
			btn = bg,
			hit = hit,
			status = statusLbl,
			statusChip = statusChip,
			accentBar = accentBar,
			desc = descLbl,
			row = row,
		}
		return hit, statusLbl
	end

	local FarmBtn, BadgeText = makeToggleRow("Auto Farm", 3)
	local ClaimBtn, ClaimBadgeText = makeToggleRow("Auto Claim Money", 4)
	local CageBtn, CageBadgeText = makeToggleRow("Auto Claim Cage", 5)
	local EquipBtn, EquipBadgeText = makeToggleRow("Auto Equip Best", 6)
	local SellBtn, SellBadgeText = makeToggleRow("Auto Sell Inventory", 7)
	local RebirthBtn, RebirthBadgeText = makeToggleRow("Auto Rebirth", 8, 74)
	local No3dBtn, No3dBadgeText = makeToggleRow("No 3D Render", 9, 74)
	local AntiAfkBtn, AntiAfkBadgeText = makeToggleRow("Anti AFK", 10, 74)

	local Footer = Instance.new("Frame")
	Footer.Name = "Footer"
	Footer.Size = UDim2.new(1, 0, 0, FOOTER_H)
	Footer.Position = UDim2.new(0, 0, 1, -FOOTER_H)
	Footer.BackgroundTransparency = 1
	Footer.BorderSizePixel = 0
	Footer.ZIndex = 2
	Footer.Parent = RootShell

	local FooterBorder = Instance.new("Frame")
	FooterBorder.Size = UDim2.new(1, -28, 0, 1)
	FooterBorder.Position = UDim2.fromOffset(14, 0)
	FooterBorder.BackgroundColor3 = THEME.borderSoft
	FooterBorder.BorderSizePixel = 0
	FooterBorder.Parent = Footer

	local FooterHotkey = Instance.new("Frame")
	FooterHotkey.Size = UDim2.fromOffset(30, 24)
	FooterHotkey.Position = UDim2.fromOffset(16, 10)
	FooterHotkey.BackgroundColor3 = THEME.secondary
	FooterHotkey.BorderSizePixel = 0
	FooterHotkey.Parent = Footer
	corner(FooterHotkey, THEME.radiusXs)
	stroke(FooterHotkey, THEME.border)

	local FooterHotkeyText = Instance.new("TextLabel")
	FooterHotkeyText.Size = UDim2.fromScale(1, 1)
	FooterHotkeyText.BackgroundTransparency = 1
	FooterHotkeyText.Font = Enum.Font.GothamBold
	FooterHotkeyText.TextSize = 11
	FooterHotkeyText.TextColor3 = THEME.foreground
	FooterHotkeyText.Text = HOTKEY_LABEL
	FooterHotkeyText.Parent = FooterHotkey

	local FooterHint = Instance.new("TextLabel")
	FooterHint.Size = UDim2.new(1, -126, 1, 0)
	FooterHint.Position = UDim2.fromOffset(54, 0)
	FooterHint.BackgroundTransparency = 1
	FooterHint.Font = Enum.Font.Gotham
	FooterHint.TextSize = 11
	FooterHint.TextXAlignment = Enum.TextXAlignment.Left
	FooterHint.TextColor3 = THEME.mutedForeground
	FooterHint.Text = "Toggle panel visibility instantly"
	FooterHint.Parent = Footer

	local FooterTag = Instance.new("TextLabel")
	FooterTag.Size = UDim2.fromOffset(84, 24)
	FooterTag.AnchorPoint = Vector2.new(1, 0.5)
	FooterTag.Position = UDim2.new(1, -16, 0.5, 0)
	FooterTag.BackgroundColor3 = THEME.accentSoft
	FooterTag.BackgroundTransparency = 0.15
	FooterTag.BorderSizePixel = 0
	FooterTag.Font = Enum.Font.GothamSemibold
	FooterTag.TextSize = 10
	FooterTag.TextColor3 = THEME.foregroundSoft
	FooterTag.Text = "Premium UI"
	FooterTag.Parent = Footer
	corner(FooterTag, THEME.radiusXs)

	local ConfirmOverlay = Instance.new("Frame")
	ConfirmOverlay.Name = "ConfirmOverlay"
	ConfirmOverlay.Size = UDim2.fromScale(1, 1)
	ConfirmOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	ConfirmOverlay.BackgroundTransparency = 0.28
	ConfirmOverlay.BorderSizePixel = 0
	ConfirmOverlay.Active = false
	ConfirmOverlay.Visible = false
	ConfirmOverlay.ZIndex = 100
	ConfirmOverlay.Parent = ScreenGui

	local ConfirmShade = Instance.new("Frame")
	ConfirmShade.Size = UDim2.fromScale(1, 1)
	ConfirmShade.BackgroundColor3 = THEME.background
	ConfirmShade.BackgroundTransparency = 0.18
	ConfirmShade.BorderSizePixel = 0
	ConfirmShade.ZIndex = 100
	ConfirmShade.Parent = ConfirmOverlay
	gradient(
		ConfirmShade,
		90,
		ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(8, 13, 20)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(3, 6, 10)),
		}),
		NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.25),
			NumberSequenceKeypoint.new(1, 0.45),
		})
	)

	local ConfirmCard = Instance.new("Frame")
	ConfirmCard.Name = "ConfirmCard"
	ConfirmCard.Size = UDim2.fromOffset(372, 198)
	ConfirmCard.AnchorPoint = Vector2.new(0.5, 0.5)
	ConfirmCard.Position = UDim2.fromScale(0.5, 0.5)
	ConfirmCard.BackgroundColor3 = THEME.backgroundAlt
	ConfirmCard.BorderSizePixel = 0
	ConfirmCard.ZIndex = 101
	ConfirmCard.Parent = ConfirmOverlay
	corner(ConfirmCard, THEME.radius)
	stroke(ConfirmCard, THEME.border)
	gradient(
		ConfirmCard,
		90,
		ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(17, 24, 39)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(11, 17, 28)),
		})
	)

	padding(ConfirmCard, 18, 18, 18, 18)

	local ConfirmBadge = Instance.new("Frame")
	ConfirmBadge.Size = UDim2.fromOffset(96, 26)
	ConfirmBadge.BackgroundColor3 = THEME.destructiveSurface
	ConfirmBadge.BorderSizePixel = 0
	ConfirmBadge.ZIndex = 102
	ConfirmBadge.Parent = ConfirmCard
	corner(ConfirmBadge, THEME.radiusXs)
	stroke(ConfirmBadge, Color3.fromRGB(127, 29, 29))

	local ConfirmBadgeText = Instance.new("TextLabel")
	ConfirmBadgeText.Size = UDim2.fromScale(1, 1)
	ConfirmBadgeText.BackgroundTransparency = 1
	ConfirmBadgeText.Font = Enum.Font.GothamBold
	ConfirmBadgeText.TextSize = 10
	ConfirmBadgeText.TextColor3 = THEME.destructive
	ConfirmBadgeText.Text = "SHUTDOWN"
	ConfirmBadgeText.ZIndex = 103
	ConfirmBadgeText.Parent = ConfirmBadge

	local ConfirmTitle = Instance.new("TextLabel")
	ConfirmTitle.Size = UDim2.new(1, 0, 0, 24)
	ConfirmTitle.Position = UDim2.fromOffset(0, 34)
	ConfirmTitle.BackgroundTransparency = 1
	ConfirmTitle.Font = Enum.Font.GothamBold
	ConfirmTitle.TextSize = 20
	ConfirmTitle.TextXAlignment = Enum.TextXAlignment.Left
	ConfirmTitle.TextColor3 = THEME.foreground
	ConfirmTitle.Text = "Close script?"
	ConfirmTitle.ZIndex = 102
	ConfirmTitle.Parent = ConfirmCard

	local ConfirmBody = Instance.new("TextLabel")
	ConfirmBody.Size = UDim2.new(1, 0, 0, 58)
	ConfirmBody.Position = UDim2.fromOffset(0, 68)
	ConfirmBody.BackgroundTransparency = 1
	ConfirmBody.Font = Enum.Font.Gotham
	ConfirmBody.TextSize = 12
	ConfirmBody.TextXAlignment = Enum.TextXAlignment.Left
	ConfirmBody.TextYAlignment = Enum.TextYAlignment.Top
	ConfirmBody.TextWrapped = true
	ConfirmBody.TextColor3 = THEME.mutedForeground
	ConfirmBody.Text = "This stops every automation loop, clears the panel, and ends the active session. Re-run the script if you want to start it again."
	ConfirmBody.ZIndex = 102
	ConfirmBody.Parent = ConfirmCard

	local ConfirmActions = Instance.new("Frame")
	ConfirmActions.Size = UDim2.new(1, 0, 0, 40)
	ConfirmActions.Position = UDim2.new(0, 0, 1, -40)
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
	gradient(
		ConfirmCancel,
		90,
		ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 27, 42)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(13, 20, 31)),
		})
	)

	local ConfirmClose = Instance.new("TextButton")
	ConfirmClose.Size = UDim2.new(0.5, -6, 1, 0)
	ConfirmClose.Position = UDim2.new(0.5, 6, 0, 0)
	ConfirmClose.BackgroundColor3 = THEME.destructiveSurface
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
	gradient(
		ConfirmClose,
		90,
		ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(82, 24, 34)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(58, 18, 26)),
		})
	)

	ConfirmCancel.MouseEnter:Connect(function()
		TweenService:Create(ConfirmCancel, TweenInfo.new(0.12), {
			BackgroundColor3 = THEME.cardHover,
			TextColor3 = THEME.foreground,
		}):Play()
	end)
	ConfirmCancel.MouseLeave:Connect(function()
		TweenService:Create(ConfirmCancel, TweenInfo.new(0.12), {
			BackgroundColor3 = THEME.secondary,
			TextColor3 = THEME.secondaryForeground,
		}):Play()
	end)
	ConfirmClose.MouseEnter:Connect(function()
		TweenService:Create(ConfirmClose, TweenInfo.new(0.12), {
			BackgroundColor3 = Color3.fromRGB(92, 27, 37),
			TextColor3 = Color3.fromRGB(254, 202, 202),
		}):Play()
	end)
	ConfirmClose.MouseLeave:Connect(function()
		TweenService:Create(ConfirmClose, TweenInfo.new(0.12), {
			BackgroundColor3 = THEME.destructiveSurface,
			TextColor3 = THEME.destructive,
		}):Play()
	end)

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

	local function applyNo3dRender(enabled)
		pcall(function()
			RunService:Set3dRenderingEnabled(not enabled)
		end)
	end

	local function applyAntiAfk(enabled)
		if antiAfkConn then
			pcall(function()
				antiAfkConn:Disconnect()
			end)
			antiAfkConn = nil
		end
		if not enabled then
			return
		end
		antiAfkConn = LocalPlayer.Idled:Connect(function()
			pcall(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new())
			end)
		end)
	end

	local function shutdownScript()
		if not alive then
			return
		end
		alive = false
		farming = false
		claiming = false
		claimCage = false
		autoRebirth = false
		applyAntiAfk(false)
		pcall(function()
			RunService:Set3dRenderingEnabled(true)
		end)
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

	local function dismissConfirmBackdrop(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			hideCloseConfirm()
		end
	end

	ConfirmCancel.MouseButton1Click:Connect(hideCloseConfirm)
	ConfirmClose.MouseButton1Click:Connect(shutdownScript)
	ConfirmOverlay.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and (input.Target == ConfirmOverlay or input.Target == ConfirmShade) then
			hideCloseConfirm()
		end
	end)
	ConfirmShade.InputBegan:Connect(dismissConfirmBackdrop)

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
	local FinishedRemote = getBombRE("Finished")
	local roundFinished = false
	local finishedHookInstalled = false
	local SendTagDataRemote = getKnitRE("BaseService", "SendTagData")
	local SellInventoryRemote = getKnitRE("SellService", "SellInventory")
	local cachedBaseName = nil

	local function setLearnedBase(name)
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
		FinishedRemote = FinishedRemote or getBombRE("Finished")
		return StartRemote ~= nil and ThrowRemote ~= nil
	end

	local function installFinishedHook()
		if finishedHookInstalled then
			return
		end
		if not FinishedRemote then
			FinishedRemote = getBombRE("Finished")
		end
		if not FinishedRemote then
			return
		end
		if hookmetamethod then
			pcall(function()
				local orig
				orig = hookmetamethod(game, "__namecall", function(self, ...)
					if rawequal(self, FinishedRemote) and getnamecallmethod() == "FireServer" then
						roundFinished = true
					end
					return orig(self, ...)
				end)
				finishedHookInstalled = orig ~= nil
			end)
		elseif hookfunction then
			pcall(function()
				local orig
				orig = hookfunction(FinishedRemote.FireServer, function(self, ...)
					if rawequal(self, FinishedRemote) then
						roundFinished = true
					end
					return orig(self, ...)
				end)
				finishedHookInstalled = orig ~= nil
			end)
		end
	end

	local function waitForRoundFinished()
		installFinishedHook()
		roundFinished = false
		local deadline = os.clock() + CONFIG.RoundMaxWait
		while not roundFinished and os.clock() < deadline do
			if not alive or not farming then
				return
			end
			task.wait(0.2)
		end
		task.wait(CONFIG.PostFinishWait)
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
			if row.statusChip then
				row.statusChip.BackgroundColor3 = THEME.secondary
			end
			if row.accentBar then
				row.accentBar.BackgroundColor3 = THEME.border
			end
			if row.desc then
				row.desc.TextColor3 = THEME.mutedForeground
			end
			row.status.Text = "OFF"
			row.status.TextColor3 = THEME.mutedForeground
			return
		end

		row.row:SetAttribute("Active", true)
		row.btn.BackgroundColor3 = THEME.cardActive
		if row.statusChip then
			row.statusChip.BackgroundColor3 = THEME.accentSoft
		end
		if row.accentBar then
			row.accentBar.BackgroundColor3 = THEME.accent
		end
		if row.desc then
			row.desc.TextColor3 = THEME.foregroundSoft
		end

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
			if row.statusChip then
				row.statusChip.BackgroundColor3 = THEME.successSurface
			end
			if row.accentBar then
				row.accentBar.BackgroundColor3 = THEME.success
			end
		else
			row.status.Text = "R" .. tostring(info.rebirth)
			row.status.TextColor3 = THEME.mutedForeground
		end
	end

	local function setupRebirthSystems()
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

		waitForRoundFinished()

		if not alive or not farming then
			return
		end

		if equipBest then
			doEquipBest()
		end

		if autoSell then
			doSellInventory()
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
		row.btn.BackgroundColor3 = on and THEME.cardActive or THEME.card
		if row.statusChip then
			row.statusChip.BackgroundColor3 = on and THEME.successSurface or THEME.secondary
		end
		if row.accentBar then
			row.accentBar.BackgroundColor3 = on and THEME.success or THEME.border
		end
		if row.desc then
			row.desc.TextColor3 = on and THEME.foregroundSoft or THEME.mutedForeground
		end
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
		setRowActive("No 3D Render", no3dRender)
		setRowActive("Anti AFK", antiAfk)
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
	wireToggle("No 3D Render", function()
		no3dRender = not no3dRender
		applyNo3dRender(no3dRender)
	end)
	wireToggle("Anti AFK", function()
		antiAfk = not antiAfk
		applyAntiAfk(antiAfk)
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
