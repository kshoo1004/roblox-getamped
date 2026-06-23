-- 로비 UI (방 목록 / 방 만들기 / 입장)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local CreateRoomRE = Remotes:WaitForChild("CreateRoom")
local JoinRoomRE   = Remotes:WaitForChild("JoinRoom")
local LeaveRoomRE  = Remotes:WaitForChild("LeaveRoom")
local StartGameRE  = Remotes:WaitForChild("StartGame")
local RoomListRF   = Remotes:WaitForChild("GetRoomList")
local RoomUpdateRE = Remotes:WaitForChild("RoomUpdate")

-- 메인 스크린 GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LobbyUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player.PlayerGui

-- 배경 프레임
local bg = Instance.new("Frame", screenGui)
bg.Size = UDim2.new(1, 0, 1, 0)
bg.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
bg.BackgroundTransparency = 0.1

-- 타이틀
local title = Instance.new("TextLabel", bg)
title.Size = UDim2.new(0.6, 0, 0, 60)
title.Position = UDim2.new(0.2, 0, 0, 20)
title.BackgroundTransparency = 1
title.Text = "⚡ GetAmped Roblox"
title.TextColor3 = Color3.fromRGB(255, 215, 0)
title.Font = Enum.Font.GothamBold
title.TextSize = 36

-- 방 목록 스크롤
local listFrame = Instance.new("ScrollingFrame", bg)
listFrame.Size = UDim2.new(0.65, 0, 0.65, 0)
listFrame.Position = UDim2.new(0.02, 0, 0.12, 0)
listFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
listFrame.BorderSizePixel = 0
listFrame.ScrollBarThickness = 6

local listLayout = Instance.new("UIListLayout", listFrame)
listLayout.Padding = UDim.new(0, 4)

-- 오른쪽 패널 (방 만들기 / 빠른 입장)
local rightPanel = Instance.new("Frame", bg)
rightPanel.Size = UDim2.new(0.3, 0, 0.65, 0)
rightPanel.Position = UDim2.new(0.68, 0, 0.12, 0)
rightPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
rightPanel.BorderSizePixel = 0

local function makeButton(parent, text, color, yPos)
	local btn = Instance.new("TextButton", parent)
	btn.Size = UDim2.new(0.8, 0, 0, 44)
	btn.Position = UDim2.new(0.1, 0, 0, yPos)
	btn.BackgroundColor3 = color
	btn.Text = text
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 15
	btn.BorderSizePixel = 0
	local corner = Instance.new("UICorner", btn)
	corner.CornerRadius = UDim.new(0, 8)
	return btn
end

local createBtn = makeButton(rightPanel, "🏠 방 만들기", Color3.fromRGB(60, 140, 60), 20)
local refreshBtn = makeButton(rightPanel, "🔄 새로고침", Color3.fromRGB(60, 80, 140), 80)

-- 방 목록 항목 생성
local function buildRoomList(rooms)
	for _, child in ipairs(listFrame:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	for _, room in ipairs(rooms) do
		local row = Instance.new("Frame", listFrame)
		row.Size = UDim2.new(1, -8, 0, 50)
		row.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
		row.BorderSizePixel = 0
		local corner = Instance.new("UICorner", row)
		corner.CornerRadius = UDim.new(0, 6)

		local info = Instance.new("TextLabel", row)
		info.Size = UDim2.new(0.65, 0, 1, 0)
		info.Position = UDim2.new(0.02, 0, 0, 0)
		info.BackgroundTransparency = 1
		info.TextXAlignment = Enum.TextXAlignment.Left
		info.Text = string.format("🏠 %s의 방  [%d/%d]  %s",
			room.host, room.playerCount, room.maxPlayers, room.status == "playing" and "🟡 게임 중" or "🟢 대기 중")
		info.TextColor3 = Color3.new(1, 1, 1)
		info.Font = Enum.Font.Gotham
		info.TextSize = 13

		if room.status == "waiting" then
			local joinBtn = Instance.new("TextButton", row)
			joinBtn.Size = UDim2.new(0.25, 0, 0.65, 0)
			joinBtn.Position = UDim2.new(0.72, 0, 0.17, 0)
			joinBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
			joinBtn.Text = "입장"
			joinBtn.TextColor3 = Color3.new(1, 1, 1)
			joinBtn.Font = Enum.Font.GothamBold
			joinBtn.TextSize = 13
			joinBtn.BorderSizePixel = 0
			local c2 = Instance.new("UICorner", joinBtn)
			c2.CornerRadius = UDim.new(0, 6)
			joinBtn.MouseButton1Click:Connect(function()
				JoinRoomRE:FireServer(room.id)
			end)
		end

		listFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 8)
	end
end

-- 방 만들기
createBtn.MouseButton1Click:Connect(function()
	CreateRoomRE:FireServer({ map = "CityMap", maxPlayers = 8 })
end)

-- 새로고침
refreshBtn.MouseButton1Click:Connect(function()
	local rooms = RoomListRF:InvokeServer()
	buildRoomList(rooms)
end)

-- 서버 업데이트
RoomUpdateRE.OnClientEvent:Connect(function(rooms)
	buildRoomList(rooms)
end)

-- 방 생성 응답
CreateRoomRE.OnClientEvent:Connect(function(success, msg)
	if success then
		-- 대기실 UI로 전환
		bg.Visible = false
	end
end)

-- 초기 로드
task.spawn(function()
	task.wait(1)
	local rooms = RoomListRF:InvokeServer()
	buildRoomList(rooms)
end)
