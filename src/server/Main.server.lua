-- Main server entry point: 모든 시스템 초기화 순서 관리
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local function setupRemoteEvents()
	local events = {
		"DealDamage","PlayerDied","RespawnPlayer","UseSkill","EquipAccessory",
		"TransformGorilla","RevertTransform","PickupPotion","BuyItem",
		"UpdateLeaderboard","TriggerBungee","PlayMusic","CreateRoom","JoinRoom",
		"HitEffect","SkillEffect"
	}
	local remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
	for _, name in ipairs(events) do
		local e = Instance.new("RemoteEvent")
		e.Name = name; e.Parent = remotes
	end
	local functions = {"GetRoomList","GetLeaderboard","GetShopItems"}
	for _, name in ipairs(functions) do
		local f = Instance.new("RemoteFunction")
		f.Name = name; f.Parent = remotes
	end
end

local function loadSystems()
	local order = {
		"CityMap","MusicSystem","AccessorySystem","CombatSystem",
		"TransformSystem","PotionSystem","BungeeSystem","ShopSystem",
		"LeaderboardSystem","RoomManager","GameManager"
	}
	for _, name in ipairs(order) do
		local ok, err = pcall(function()
			local m = ServerScriptService:FindFirstChild(name, true)
			if m and m:IsA("ModuleScript") then
				require(m)
				print("[Main] ✅ " .. name)
			else
				warn("[Main] ⚠️ " .. name .. " 없음")
			end
		end)
		if not ok then warn("[Main] ❌ " .. name .. ": " .. tostring(err)) end
	end
end

local function setupPlayers()
	Players.PlayerAdded:Connect(function(player)
		local stats = Instance.new("Folder")
		stats.Name = "leaderstats"; stats.Parent = player
		for _, v in ipairs({{"킬수",0},{"코인",100},{"승리",0}}) do
			local val = Instance.new("IntValue")
			val.Name = v[1]; val.Value = v[2]; val.Parent = stats
		end
	end)
end

print("[Main] 🎮 겟앰프드 Roblox 시작...")
setupRemoteEvents()
setupPlayers()
loadSystems()
print("[Main] 🚀 초기화 완료!")
