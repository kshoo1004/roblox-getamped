local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GetShopItems  = Remotes:WaitForChild("GetShopItems")
local PurchaseItem  = Remotes:WaitForChild("PurchaseItem")
local GetCoins      = Remotes:WaitForChild("GetCoins")
local AddCoins      = Remotes:WaitForChild("AddCoins")

-- UI 생성
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ShopUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- 배경 블러
local frame = Instance.new("Frame")
frame.Size = UDim2.new(1, 0, 1, 0)
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
frame.BackgroundTransparency = 0.5
frame.Visible = false
frame.Parent = screenGui

-- 상점 패널
local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 500, 0, 420)
panel.Position = UDim2.new(0.5, -250, 0.5, -210)
panel.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
panel.BorderSizePixel = 0
panel.Parent = frame

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = panel

-- 타이틀
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 50)
title.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
title.Text = "🛒  악세서리 상점"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Parent = panel

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = title

-- 코인 표시
local coinLabel = Instance.new("TextLabel")
coinLabel.Size = UDim2.new(1, -20, 0, 30)
coinLabel.Position = UDim2.new(0, 10, 0, 55)
coinLabel.BackgroundTransparency = 1
coinLabel.Text = "💰 코인: 로딩 중..."
coinLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
coinLabel.TextScaled = true
coinLabel.Font = Enum.Font.GothamBold
coinLabel.TextXAlignment = Enum.TextXAlignment.Left
coinLabel.Parent = panel

-- 아이템 리스트
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -20, 1, -140)
scrollFrame.Position = UDim2.new(0, 10, 0, 90)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 4
scrollFrame.Parent = panel

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.Parent = scrollFrame

-- 닫기 버튼
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 10)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = panel

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn

local function updateCoins(amount)
	if amount then
		coinLabel.Text = "💰 코인: " .. tostring(amount)
	else
		local coins = GetCoins:InvokeServer()
		coinLabel.Text = "💰 코인: " .. tostring(coins)
	end
end

local function createItemRow(item)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 60)
	row.BackgroundColor3 = item.owned and Color3.fromRGB(30, 60, 30) or Color3.fromRGB(30, 30, 50)
	row.BorderSizePixel = 0
	row.Parent = scrollFrame

	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 8)
	rowCorner.Parent = row

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.55, 0, 0.5, 0)
	nameLabel.Position = UDim2.new(0, 10, 0, 5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = item.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = row

	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(0.55, 0, 0.4, 0)
	descLabel.Position = UDim2.new(0, 10, 0.5, 2)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = item.description
	descLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	descLabel.TextScaled = true
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.Parent = row

	local buyBtn = Instance.new("TextButton")
	buyBtn.Size = UDim2.new(0, 110, 0, 36)
	buyBtn.Position = UDim2.new(1, -120, 0.5, -18)
	buyBtn.BackgroundColor3 = item.owned and Color3.fromRGB(60, 120, 60) or Color3.fromRGB(255, 140, 0)
	buyBtn.Text = item.owned and "✅ 보유 중" or ("💰 " .. item.price)
	buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	buyBtn.TextScaled = true
	buyBtn.Font = Enum.Font.GothamBold
	buyBtn.Active = not item.owned
	buyBtn.Parent = row

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = buyBtn

	if not item.owned then
		buyBtn.MouseButton1Click:Connect(function()
			buyBtn.Active = false
			buyBtn.Text = "..."
			local success, msg = PurchaseItem:InvokeServer(item.id)
			if success then
				buyBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
				buyBtn.Text = "✅ 보유 중"
				row.BackgroundColor3 = Color3.fromRGB(30, 60, 30)
				updateCoins()
			else
				buyBtn.Text = "❌ 실패"
				buyBtn.Active = true
				task.delay(1.5, function()
					buyBtn.Text = "💰 " .. item.price
				end)
			end
		end)
	end

	return row
end

local function openShop()
	frame.Visible = true
	updateCoins()

	-- 기존 아이템 행 제거
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	local items = GetShopItems:InvokeServer()
	for _, item in ipairs(items) do
		createItemRow(item)
	end
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #items * 68)

	TweenService:Create(panel, TweenInfo.new(0.2), { Position = UDim2.new(0.5, -250, 0.5, -210) }):Play()
end

local function closeShop()
	frame.Visible = false
end

closeBtn.MouseButton1Click:Connect(closeShop)
frame.MouseButton1Click = nil

-- E 키로 상점 열기
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.B then
		if frame.Visible then closeShop() else openShop() end
	end
end)

AddCoins.OnClientEvent:Connect(function(newAmount)
	updateCoins(newAmount)
end)

-- 상점 열기 Remote
local OpenShopRemote = Remotes:FindFirstChild("OpenShop")
if OpenShopRemote then
	OpenShopRemote.OnClientEvent:Connect(openShop)
end
