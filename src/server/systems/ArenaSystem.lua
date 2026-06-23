-- 서버: 아레나 관리 (탈락 판정 + 리스폰)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FALL_Y = -50      -- 이 Y좌표 아래로 떨어지면 탈락
local RESPAWN_TIME = 3  -- 리스폰까지 대기 시간(초)
local SPAWN_POINTS = {  -- 스폰 위치 목록
	Vector3.new(0, 10, 0),
	Vector3.new(20, 10, 0),
	Vector3.new(-20, 10, 0),
	Vector3.new(0, 10, 20),
}

local scores = {}

local function getScore(player)
	if not scores[player] then
		scores[player] = { kills = 0, falls = 0 }
	end
	return scores[player]
end

local function respawnPlayer(player)
	task.wait(RESPAWN_TIME)
	if not player.Character then return end
	local spawnPos = SPAWN_POINTS[math.random(#SPAWN_POINTS)]
	local root = player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		root.CFrame = CFrame.new(spawnPos)
	end
	-- 체력 회복
	local humanoid = player.Character:FindFirstChild("Humanoid")
	if humanoid then
		humanoid.Health = humanoid.MaxHealth
	end
end

-- 탈락 감지 루프
RunService.Heartbeat:Connect(function()
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if not char then continue end
		local root = char:FindFirstChild("HumanoidRootPart")
		if not root then continue end

		if root.Position.Y < FALL_Y then
			local score = getScore(player)
			score.falls += 1

			-- 탈락 알림
			local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
			if Remotes then
				local FallEvent = Remotes:FindFirstChild("PlayerFell")
				if FallEvent then
					FallEvent:FireAllClients({ player = player.Name, falls = score.falls })
				end
			end

			-- 리스폰
			respawnPlayer(player)
		end
	end
end)

-- 처치 감지
local function onCharacterAdded(player)
	local char = player.Character or player.CharacterAdded:Wait()
	local humanoid = char:WaitForChild("Humanoid")

	humanoid.Died:Connect(function()
		-- 크레딧 태그로 처치자 확인
		local tag = humanoid:FindFirstChild("creator")
		if tag and tag.Value then
			local killer = tag.Value
			local killerScore = getScore(killer)
			killerScore.kills += 1
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	scores[player] = { kills = 0, falls = 0 }
	player.CharacterAdded:Connect(function()
		onCharacterAdded(player)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	scores[player] = nil
end)
