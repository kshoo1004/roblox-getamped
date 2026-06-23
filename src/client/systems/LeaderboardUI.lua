local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GetLeaderboard = Remotes:WaitForChild("GetLeaderboard")
local GetMyStats     = Remotes:WaitForChild("GetMyStats")

-- 메인 GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LeaderboardUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- 패널
local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 360, 0, 480)
panel.Position = UDim2.new(1, 10, 0.5, -240) -- 처음엔 화면 밖
panel.BackgroundColor3 = Color3.fromRGB(10, 10, 25)
panel.BorderSizePixel = 0
panel.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = panel

-- 타이틀
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 45)
title.BackgroundColor3 = Color3.fromRGB(80, 0, 160)
title.Text = "🏆  글로벌 랭킹"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Parent = panel

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = title

-- 내 스탯
local myStats = Instance.new("TextLabel")
myStats.Size = UDim2.new(1, -20, 0, 30)
myStats.Position = UDim2.new(0, 10, 0, 48)
myStats.BackgroundTransparency = 1
myStats.Text = "킬: 0  |  데스: 0"
myStats.TextColor3 = Color3.fromRGB(200, 200, 255)
myStats.TextScaled = true
myStats.Font = Enum.Font.Gotham
myStats.Parent = panel

-- 랭킹 리스트
local listFrame = Instance.new("Frame")
listFrame.Size = UDim2.new(1, -20, 1, -90)
listFrame.Position = UDim2.new(0, 10, 0, 82)
listFrame.BackgroundTransparency = 1
listFrame.Parent = panel

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 4)
listLayout.Parent = listFrame

local isVisible = false

local RANK_COLORS = {
	Color3.fromRGB(255, 215, 0),   -- 1등 금
	Color3.fromRGB(192, 192, 192), -- 2등 은
	Color3.fromRGB(205, 127, 50),  -- 3등 동
}

local function refreshLeaderboard()
	-- 기존 행 제거
	for _, child in ipairs(listFrame:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	local stats = GetMyStats:InvokeServer()
	myStats.Text = "킬: " .. stats.kills .. "  |  데스: " .. stats.deaths

	local entries = GetLeaderboard:InvokeServer()
	for _, entry in ipairs(entries) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 36)
		row.BackgroundColor3 = entry.rank <= 3
			and Color3.fromRGB(40, 30, 60)
			or  Color3.fromRGB(25, 25, 40)
		row.BorderSizePixel = 0
		row.Parent = listFrame

		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 6)
		rowCorner.Parent = row

		local rankLabel = Instance.new("TextLabel")
		rankLabel.Size = UDim2.new(0, 36, 1, 0)
		rankLabel.BackgroundTransparency = 1
		rankLabel.Text = entry.rank <= 3 and ({ "🥇", "🥈", "🥉" })[entry.rank] or ("#" .. entry.rank)
		rankLabel.TextColor3 = RANK_COLORS[entry.rank] or Color3.fromRGB(200, 200, 200)
		rankLabel.TextScaled = true
		rankLabel.Font = Enum.Font.GothamBold
		rankLabel.Parent = row

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.6, 0, 1, 0)
		nameLabel.Position = UDim2.new(0, 40, 0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = entry.name
		nameLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
		nameLabel.TextScaled = true
		nameLabel.Font = Enum.Font.Gotham
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = row

		local killLabel = Instance.new("TextLabel")
		killLabel.Size = UDim2.new(0, 60, 1, 0)
		killLabel.Position = UDim2.new(1, -65, 0, 0)
		killLabel.BackgroundTransparency = 1
		killLabel.Text = "⚔️ " .. entry.kills
		killLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		killLabel.TextScaled = true
		killLabel.Font = Enum.Font.GothamBold
		killLabel.Parent = row
	end
end

local function showLeaderboard()
	isVisible = true
	refreshLeaderboard()
	TweenService:Create(panel, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
		Position = UDim2.new(1, -370, 0.5, -240)
	}):Play()
end

local function hideLeaderboard()
	isVisible = false
	TweenService:Create(panel, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
		Position = UDim2.new(1, 10, 0.5, -240)
	}):Play()
end

-- Tab 키로 토글
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.Tab then
		if isVisible then hideLeaderboard() else showLeaderboard() end
	end
end)

-- 30초마다 자동 갱신
task.spawn(function()
	while true do
		task.wait(30)
		if isVisible then refreshLeaderboard() end
	end
end)
