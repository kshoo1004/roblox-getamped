local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LeaderboardStore = DataStoreService:GetOrderedDataStore("GlobalKills_v1")

local sessionStats = {} -- { userId: { kills, deaths, coins } }

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GetLeaderboard = Remotes:WaitForChild("GetLeaderboard")
local GetMyStats     = Remotes:WaitForChild("GetMyStats")

local LeaderboardSystem = {}

local function initPlayer(player)
	sessionStats[player.UserId] = { kills = 0, deaths = 0, coins = 0 }

	-- leaderstats (Roblox 기본 리더보드)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	ls.Parent = player

	local kills = Instance.new("IntValue")
	kills.Name = "킬"
	kills.Value = 0
	kills.Parent = ls

	local deaths = Instance.new("IntValue")
	deaths.Name = "데스"
	deaths.Value = 0
	deaths.Parent = ls
end

function LeaderboardSystem.addKill(player)
	local stats = sessionStats[player.UserId]
	if not stats then return end
	stats.kills += 1

	local ls = player:FindFirstChild("leaderstats")
	if ls then ls:FindFirstChild("킬").Value = stats.kills end

	-- 글로벌 랭킹 업데이트
	pcall(function()
		LeaderboardStore:IncrementAsync("player_" .. player.UserId, 1)
	end)
end

function LeaderboardSystem.addDeath(player)
	local stats = sessionStats[player.UserId]
	if not stats then return end
	stats.deaths += 1

	local ls = player:FindFirstChild("leaderstats")
	if ls then ls:FindFirstChild("데스").Value = stats.deaths end
end

function LeaderboardSystem.getSessionStats(player)
	return sessionStats[player.UserId] or { kills = 0, deaths = 0 }
end

-- 글로벌 Top 10
GetLeaderboard.OnServerInvoke = function()
	local success, pages = pcall(function()
		return LeaderboardStore:GetSortedAsync(false, 10)
	end)
	if not success then return {} end

	local result = {}
	local data = pages:GetCurrentPage()
	for rank, entry in ipairs(data) do
		local userId = tonumber(entry.key:match("%d+"))
		local name = "[알 수 없음]"
		pcall(function()
			name = Players:GetNameFromUserIdAsync(userId)
		end)
		table.insert(result, { rank = rank, name = name, kills = entry.value })
	end
	return result
end

GetMyStats.OnServerInvoke = function(player)
	return sessionStats[player.UserId] or { kills = 0, deaths = 0 }
end

Players.PlayerAdded:Connect(initPlayer)
Players.PlayerRemoving:Connect(function(player)
	sessionStats[player.UserId] = nil
end)

return LeaderboardSystem
