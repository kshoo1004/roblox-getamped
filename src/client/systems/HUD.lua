-- 인게임 HUD (체력바 / 변신타이머 / 스코어 / 무기표시)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local HUD = {}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GameHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = player.PlayerGui

-- ── 체력바 ──────────────────────────────────────
local hpBar = Instance.new("Frame", screenGui)
hpBar.Size = UDim2.new(0.25, 0, 0, 28)
hpBar.Position = UDim2.new(0.02, 0, 0.92, 0)
hpBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
hpBar.BorderSizePixel = 0
local hpCorner = Instance.new("UICorner", hpBar)
hpCorner.CornerRadius = UDim.new(0, 6)

local hpFill = Instance.new("Frame", hpBar)
hpFill.Size = UDim2.new(1, 0, 1, 0)
hpFill.BackgroundColor3 = Color3.fromRGB(80, 220, 80)
hpFill.BorderSizePixel = 0
local hpFillCorner = Instance.new("UICorner", hpFill)
hpFillCorner.CornerRadius = UDim.new(0, 6)

local hpLabel = Instance.new("TextLabel", hpBar)
hpLabel.Size = UDim2.new(1, 0, 1, 0)
hpLabel.BackgroundTransparency = 1
hpLabel.Text = "HP 150 / 150"
hpLabel.TextColor3 = Color3.new(1, 1, 1)
hpLabel.Font = Enum.Font.GothamBold
hpLabel.TextSize = 13
hpLabel.TextStrokeTransparency = 0.5

-- ── 변신 타이머 ────────────────────────────────
local transformTimer = Instance.new("Frame", screenGui)
transformTimer.Size = UDim2.new(0.18, 0, 0, 50)
transformTimer.Position = UDim2.new(0.41, 0, 0.88, 0)
transformTimer.BackgroundColor3 = Color3.fromRGB(200, 80, 20)
transformTimer.BackgroundTransparency = 0.2
transformTimer.Visible = false
transformTimer.BorderSizePixel = 0
local ttCorner = Instance.new("UICorner", transformTimer)
ttCorner.CornerRadius = UDim.new(0, 10)

local ttIcon = Instance.new("TextLabel", transformTimer)
ttIcon.Size = UDim2.new(0.3, 0, 1, 0)
ttIcon.BackgroundTransparency = 1
ttIcon.Text = "🦍"
ttIcon.TextSize = 28

local ttLabel = Instance.new("TextLabel", transformTimer)
ttLabel.Size = UDim2.new(0.7, 0, 1, 0)
ttLabel.Position = UDim2.new(0.3, 0, 0, 0)
ttLabel.BackgroundTransparency = 1
ttLabel.Text = "30s"
ttLabel.TextColor3 = Color3.new(1, 1, 1)
ttLabel.Font = Enum.Font.GothamBold
ttLabel.TextSize = 22

-- ── 스킬 쿨타임 ────────────────────────────────
local skillBar = Instance.new("Frame", screenGui)
skillBar.Size = UDim2.new(0.2, 0, 0, 60)
skillBar.Position = UDim2.new(0.4, 0, 0.8, 0)
skillBar.BackgroundTransparency = 1

local skillKeys = {"Z", "X", "C"}
local skillSlots = {}

for i, key in ipairs(skillKeys) do
	local slot = Instance.new("Frame", skillBar)
	slot.Size = UDim2.new(0, 55, 0, 55)
	slot.Position = UDim2.new(0, (i - 1) * 62, 0, 0)
	slot.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
	slot.BorderSizePixel = 0
	local slotCorner = Instance.new("UICorner", slot)
	slotCorner.CornerRadius = UDim.new(0, 8)

	local keyLabel = Instance.new("TextLabel", slot)
	keyLabel.Size = UDim2.new(1, 0, 0.4, 0)
	keyLabel.BackgroundTransparency = 1
	keyLabel.Text = key
	keyLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
	keyLabel.Font = Enum.Font.GothamBold
	keyLabel.TextSize = 14

	local coolLabel = Instance.new("TextLabel", slot)
	coolLabel.Name = "Cooldown"
	coolLabel.Size = UDim2.new(1, 0, 0.6, 0)
	coolLabel.Position = UDim2.new(0, 0, 0.4, 0)
	coolLabel.BackgroundTransparency = 1
	coolLabel.Text = "✓"
	coolLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	coolLabel.Font = Enum.Font.Gotham
	coolLabel.TextSize = 18

	-- 쿨타임 오버레이
	local overlay = Instance.new("Frame", slot)
	overlay.Name = "Overlay"
	overlay.Size = UDim2.new(1, 0, 0, 0)
	overlay.Position = UDim2.new(0, 0, 0, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.4
	overlay.BorderSizePixel = 0

	skillSlots[key] = { slot = slot, coolLabel = coolLabel, overlay = overlay }
end

-- ── 스코어보드 ─────────────────────────────────
local scoreBoard = Instance.new("Frame", screenGui)
scoreBoard.Size = UDim2.new(0.18, 0, 0.35, 0)
scoreBoard.Position = UDim2.new(0.81, 0, 0.02, 0)
scoreBoard.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
scoreBoard.BackgroundTransparency = 0.3
scoreBoard.BorderSizePixel = 0
local sbCorner = Instance.new("UICorner", scoreBoard)
sbCorner.CornerRadius = UDim.new(0, 8)

local sbTitle = Instance.new("TextLabel", scoreBoard)
sbTitle.Size = UDim2.new(1, 0, 0, 28)
sbTitle.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
sbTitle.BorderSizePixel = 0
sbTitle.Text = "🏆 스코어"
sbTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
sbTitle.Font = Enum.Font.GothamBold
sbTitle.TextSize = 14

local sbList = Instance.new("Frame", scoreBoard)
sbList.Size = UDim2.new(1, 0, 1, -28)
sbList.Position = UDim2.new(0, 0, 0, 28)
sbList.BackgroundTransparency = 1
local sbLayout = Instance.new("UIListLayout", sbList)
sbLayout.Padding = UDim.new(0, 2)

-- ── 무기 표시 ──────────────────────────────────
local weaponFrame = Instance.new("Frame", screenGui)
weaponFrame.Size = UDim2.new(0.1, 0, 0, 40)
weaponFrame.Position = UDim2.new(0.28, 0, 0.92, 0)
weaponFrame.BackgroundColor3 = Color3.fromRGB(60, 40, 20)
weaponFrame.BackgroundTransparency = 0.3
weaponFrame.Visible = false
weaponFrame.BorderSizePixel = 0
local wfCorner = Instance.new("UICorner", weaponFrame)
wfCorner.CornerRadius = UDim.new(0, 8)

local weaponLabel = Instance.new("TextLabel", weaponFrame)
weaponLabel.Size = UDim2.new(1, 0, 1, 0)
weaponLabel.BackgroundTransparency = 1
weaponLabel.Text = "🏏 야구방망이"
weaponLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
weaponLabel.Font = Enum.Font.GothamBold
weaponLabel.TextSize = 13

-- ── API ────────────────────────────────────────
function HUD.updateHP(current, max)
	local ratio = math.clamp(current / max, 0, 1)
	TweenService:Create(hpFill,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad),
		{ Size = UDim2.new(ratio, 0, 1, 0) }):Play()
	hpLabel.Text = "HP " .. math.ceil(current) .. " / " .. max
	if ratio < 0.3 then
		hpFill.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
	elseif ratio < 0.6 then
		hpFill.BackgroundColor3 = Color3.fromRGB(220, 180, 40)
	else
		hpFill.BackgroundColor3 = Color3.fromRGB(80, 220, 80)
	end
end

function HUD.showTransformTimer(seconds)
	transformTimer.Visible = seconds > 0
	if seconds > 0 then
		ttLabel.Text = tostring(math.ceil(seconds)) .. "s"
	end
end

function HUD.setCooldown(key, remaining, total)
	local slot = skillSlots[key]
	if not slot then return end
	if remaining <= 0 then
		slot.coolLabel.Text = "✓"
		slot.coolLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
		slot.overlay.Size = UDim2.new(1, 0, 0, 0)
	else
		slot.coolLabel.Text = string.format("%.1f", remaining)
		slot.coolLabel.TextColor3 = Color3.fromRGB(255, 180, 60)
		slot.overlay.Size = UDim2.new(1, 0, remaining / total, 0)
	end
end

function HUD.updateScoreBoard(scores)
	for _, child in ipairs(sbList:GetChildren()) do
		if child:IsA("TextLabel") then child:Destroy() end
	end
	table.sort(scores, function(a, b) return a.kills > b.kills end)
	for rank, entry in ipairs(scores) do
		local row = Instance.new("TextLabel", sbList)
		row.Size = UDim2.new(1, -4, 0, 22)
		row.BackgroundTransparency = 1
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.Text = string.format("  %d. %s  %d킬", rank, entry.name, entry.kills)
		row.TextColor3 = entry.name == player.Name
			and Color3.fromRGB(255, 215, 0)
			or Color3.new(1, 1, 1)
		row.Font = Enum.Font.Gotham
		row.TextSize = 12
	end
end

function HUD.showWeapon(weaponName)
	if weaponName then
		weaponFrame.Visible = true
		weaponLabel.Text = "🏏 " .. weaponName
	else
		weaponFrame.Visible = false
	end
end

-- 서버 이벤트 수신
Remotes:WaitForChild("HUDUpdate").OnClientEvent:Connect(function(data)
	if data.type == "hp" then
		HUD.updateHP(data.current, data.max)
	elseif data.type == "transform" then
		HUD.showTransformTimer(data.remaining)
	elseif data.type == "score" then
		HUD.updateScoreBoard(data.scores)
	elseif data.type == "weapon" then
		HUD.showWeapon(data.weaponName)
	elseif data.type == "cooldown" then
		HUD.setCooldown(data.key, data.remaining, data.total)
	end
end)

return HUD
