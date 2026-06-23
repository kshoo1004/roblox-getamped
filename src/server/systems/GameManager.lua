-- 메인 게임 루프: 로비 → 라운드 → 결과 → 반복
local Players = game:GetService("Players")
local Config          = require(game.ReplicatedStorage.shared.Config)
local CityMap         = require(script.Parent.CityMap)
local PotionSystem    = require(script.Parent.PotionSystem)
local TransformSystem = require(script.Parent.TransformSystem)
local CombatSystem    = require(script.Parent.CombatSystem)
local ArenaSystem     = require(script.Parent.ArenaSystem)
local WeaponSystem    = require(script.Parent.WeaponSystem)
local BungeeSystem    = require(script.Parent.BungeeSystem)
local MusicSystem     = require(script.Parent.MusicSystem)

local GameManager = {}

local events = {}
local state = "LOBBY"
local scores = {}
local roundTimer = 0

local statusEvent

local function broadcast(eventType, data)
	if statusEvent then statusEvent:FireAllClients(eventType, data) end
end

-- RemoteEvent 초기화 (서버 진입점에서 1회 호출)
local function setupRemotes()
	local rs = game.ReplicatedStorage
	local folder = Instance.new("Folder")
	folder.Name = "Remotes"
	folder.Parent = rs

	local function makeEvent(name)
		local e = Instance.new("RemoteEvent")
		e.Name = name
		e.Parent = folder
		return e
	end
	local function makeFunction(name)
		local f = Instance.new("RemoteFunction")
		f.Name = name
		f.Parent = folder
		return f
	end

	events.HitEvent         = makeEvent("HitEvent")
	events.EffectEvent      = makeEvent("EffectEvent")
	events.TransformEvent   = makeEvent("TransformEvent")
	events.SkillChangeEvent = makeEvent("SkillChangeEvent")
	events.WeaponPickup     = makeEvent("WeaponPickup")
	events.HUDUpdate        = makeEvent("HUDUpdate")
	events.GameState        = makeEvent("GameState")
	events.PlayBGM          = makeEvent("PlayBGM")
	events.CreateRoom       = makeEvent("CreateRoom")
	events.JoinRoom         = makeEvent("JoinRoom")
	events.LeaveRoom        = makeEvent("LeaveRoom")
	events.StartGame        = makeEvent("StartGame")
	events.RoomUpdate       = makeEvent("RoomUpdate")
	events.GetRoomList      = makeFunction("GetRoomList")
	statusEvent = events.GameState
	return events
end

local function spawnPlayer(player)
	local spawnPoints = workspace:FindFirstChild("SpawnPoints")
	local spawns = spawnPoints and spawnPoints:GetChildren() or {}
	local idx = math.random(math.max(#spawns, 1))
	local pos = spawns[idx] and spawns[idx].Position or Vector3.new(0, 5, 0)

	local character = player.Character or player.CharacterAdded:Wait()
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	if hrp then hrp.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0)) end

	local humanoid = character:WaitForChild("Humanoid", 5)
	if humanoid then
		humanoid.MaxHealth = Config.BASE_HEALTH
		humanoid.Health = Config.BASE_HEALTH
		humanoid.WalkSpeed = Config.NORMAL_SPEED
		humanoid.JumpPower = Config.NORMAL_JUMP
	end
end

-- 스코어 broadcast
local function broadcastScores()
	local list = {}
	for player, kills in pairs(scores) do
		table.insert(list, { name = player.Name, kills = kills, userId = player.UserId })
	end
	table.sort(list, function(a, b) return a.kills > b.kills end)
	for _, p in ipairs(Players:GetPlayers()) do
		events.HUDUpdate:FireClient(p, { type = "score", scores = list })
	end
end

local function startLobby()
	state = "LOBBY"
	MusicSystem.playLobbyMusic()
	broadcast("LOBBY", { countdown = Config.LOBBY_DURATION })

	local countdown = Config.LOBBY_DURATION
	while countdown > 0 do
		task.wait(1)
		countdown -= 1
		broadcast("LOBBY_TICK", { countdown = countdown })
		if #Players:GetPlayers() < Config.MIN_PLAYERS then
			countdown = Config.LOBBY_DURATION
			broadcast("LOBBY", { countdown = countdown, reason = "waiting_players" })
		end
	end
end

local function startRound()
	state = "ROUND"
	scores = {}

	-- 맵 빌드
	CityMap.Build()
	BungeeSystem.build()

	-- 스폰 포인트
	local spawnFolder = Instance.new("Folder")
	spawnFolder.Name = "SpawnPoints"
	spawnFolder.Parent = workspace
	local playerList = Players:GetPlayers()
	for i, _ in ipairs(playerList) do
		local sp = Instance.new("Part")
		sp.Anchored = true
		sp.CanCollide = false
		sp.Transparency = 1
		sp.Size = Vector3.new(4, 1, 4)
		local angle = (i / #playerList) * math.pi * 2
		sp.Position = Vector3.new(math.cos(angle) * 60, 5, math.sin(angle) * 60)
		sp.Parent = spawnFolder
	end

	-- 킬 카운터 초기화
	for _, player in ipairs(playerList) do
		scores[player] = 0
		player:LoadCharacter()
		task.delay(1, function() spawnPlayer(player) end)
	end

	-- 무기 + 물약 스폰
	WeaponSystem.spawnWeapons(Config.CITY_SIZE * 0.4)
	PotionSystem.Start(CityMap.GetPotionSpawnPoints(), function(player)
		TransformSystem.ApplyGorilla(player)
		broadcast("POTION_PICKUP", { player = player.Name })
	end)

	-- 음악
	MusicSystem.playBattleMusic()

	-- 카운트다운
	for i = 3, 1, -1 do
		broadcast("COUNTDOWN", { count = i })
		task.wait(1)
	end
	broadcast("ROUND_START", { duration = Config.ROUND_DURATION })

	-- 사망 처리
	local deathConns = {}
	for _, player in ipairs(playerList) do
		local char = player.Character
		if not char then continue end
		local hum = char:FindFirstChild("Humanoid")
		if not hum then continue end

		deathConns[player] = hum.Died:Connect(function()
			broadcast("PLAYER_DIED", { player = player.Name })
			if TransformSystem.IsGorilla(player) then
				TransformSystem.RevertGorilla(player)
			end
			task.delay(3, function()
				if state ~= "ROUND" then return end
				player:LoadCharacter()
				task.delay(0.5, function() spawnPlayer(player) end)
			end)
		end)
	end

	-- 라운드 타이머
	roundTimer = Config.ROUND_DURATION
	while roundTimer > 0 and state == "ROUND" do
		task.wait(1)
		roundTimer -= 1
		broadcast("ROUND_TICK", { remaining = roundTimer })
		for _, p in ipairs(Players:GetPlayers()) do
			events.HUDUpdate:FireClient(p, { type = "timer", remaining = roundTimer })
		end
	end

	for _, conn in pairs(deathConns) do conn:Disconnect() end
	PotionSystem.Stop()
	TransformSystem.RevertAll()
end

local function endRound()
	state = "RESULT"
	MusicSystem.stopMusic()

	local winner = nil
	local topScore = -1
	local results = {}
	for player, kills in pairs(scores) do
		table.insert(results, { name = player.Name, kills = kills })
		if kills > topScore then
			topScore = kills
			winner = player.Name
		end
	end
	table.sort(results, function(a, b) return a.kills > b.kills end)
	broadcast("ROUND_END", { winner = winner, results = results })

	task.wait(Config.RESULT_DURATION)

	-- 정리
	WeaponSystem.clearWeapons()
	BungeeSystem.clearAll()
	CityMap.Destroy()
	local sp = workspace:FindFirstChild("SpawnPoints")
	if sp then sp:Destroy() end
end

function GameManager.AddKill(killer, victim)
	if state ~= "ROUND" then return end
	if scores[killer] then
		scores[killer] += 1
		broadcast("KILL", {
			killer = killer.Name,
			victim = victim.Name,
			kills = scores[killer],
		})
		broadcastScores()
	end
end

-- 방 시스템에서 직접 라운드 시작 (RoomManager 연동)
function GameManager.startRound(playerList, mapName, roomId)
	task.spawn(function()
		state = "ROUND"
		scores = {}
		for _, p in ipairs(playerList) do scores[p] = 0 end

		CityMap.Build()
		BungeeSystem.build()

		local spawnFolder = Instance.new("Folder")
		spawnFolder.Name = "SpawnPoints"
		spawnFolder.Parent = workspace
		for i, _ in ipairs(playerList) do
			local sp = Instance.new("Part")
			sp.Anchored = true; sp.CanCollide = false; sp.Transparency = 1
			sp.Size = Vector3.new(4, 1, 4)
			local angle = (i / #playerList) * math.pi * 2
			sp.Position = Vector3.new(math.cos(angle) * 60, 5, math.sin(angle) * 60)
			sp.Parent = spawnFolder
		end

		for _, p in ipairs(playerList) do
			p:LoadCharacter()
			task.delay(1, function() spawnPlayer(p) end)
		end

		WeaponSystem.spawnWeapons(Config.CITY_SIZE * 0.4)
		PotionSystem.Start(CityMap.GetPotionSpawnPoints(), function(player)
			TransformSystem.ApplyGorilla(player)
		end)
		MusicSystem.playBattleMusic()

		for i = 3, 1, -1 do
			broadcast("COUNTDOWN", { count = i })
			task.wait(1)
		end
		broadcast("ROUND_START", { duration = Config.ROUND_DURATION })

		roundTimer = Config.ROUND_DURATION
		while roundTimer > 0 and state == "ROUND" do
			task.wait(1)
			roundTimer -= 1
		end

		PotionSystem.Stop()
		TransformSystem.RevertAll()
		MusicSystem.stopMusic()

		local results = {}
		local winner = nil; local topScore = -1
		for p, k in pairs(scores) do
			table.insert(results, { name = p.Name, kills = k })
			if k > topScore then topScore = k; winner = p.Name end
		end
		table.sort(results, function(a, b) return a.kills > b.kills end)
		broadcast("ROUND_END", { winner = winner, results = results })
		task.wait(Config.RESULT_DURATION)

		WeaponSystem.clearWeapons()
		BungeeSystem.clearAll()
		CityMap.Destroy()
		local sp = workspace:FindFirstChild("SpawnPoints")
		if sp then sp:Destroy() end

		local RoomManager = require(script.Parent.RoomManager)
		RoomManager.endRoom(roomId)
		MusicSystem.playLobbyMusic()
		broadcast("LOBBY")
		state = "LOBBY"
	end)
end

function GameManager.Start()
	setupRemotes()

	TransformSystem.Init(events)
	CombatSystem.Init(events, TransformSystem)
	ArenaSystem.Init(events, function(killer, victim)
		GameManager.AddKill(killer, victim)
	end)

	-- 로비 모드에선 RoomManager가 방 만들기/시작 담당
	local RoomManager = require(script.Parent.RoomManager)
	RoomManager.init()

	Players.PlayerAdded:Connect(function(player)
		player:LoadCharacter()
		MusicSystem.playForPlayer(player)
	end)

	-- 글로벌 로비 루프 (방 시스템 없는 단순 모드 fallback)
	if not game:GetService("RunService"):IsStudio() then
		while true do
			if #Players:GetPlayers() >= Config.MIN_PLAYERS then
				startLobby()
				startRound()
				endRound()
			else
				broadcast("WAITING", { needed = Config.MIN_PLAYERS })
				task.wait(5)
			end
		end
	end
end

return GameManager
