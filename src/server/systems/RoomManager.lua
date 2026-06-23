-- 방 만들기/로비 시스템
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(game.ReplicatedStorage.shared.Config)

local RoomManager = {}

local rooms = {}  -- roomId -> { host, players, status, map, maxPlayers }
local playerRoom = {}  -- userId -> roomId

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CreateRoomRE  = Remotes:WaitForChild("CreateRoom")
local JoinRoomRE    = Remotes:WaitForChild("JoinRoom")
local LeaveRoomRE   = Remotes:WaitForChild("LeaveRoom")
local StartGameRE   = Remotes:WaitForChild("StartGame")
local RoomListRF    = Remotes:WaitForChild("GetRoomList")
local RoomUpdateRE  = Remotes:WaitForChild("RoomUpdate")

local function generateRoomId()
	return tostring(math.random(1000, 9999))
end

local function broadcastRoomList()
	local list = {}
	for id, room in pairs(rooms) do
		table.insert(list, {
			id = id,
			host = room.hostName,
			playerCount = #room.players,
			maxPlayers = room.maxPlayers,
			status = room.status,
			map = room.map,
		})
	end
	RoomUpdateRE:FireAllClients(list)
end

local function removePlayerFromRoom(player)
	local userId = player.UserId
	local roomId = playerRoom[userId]
	if not roomId then return end

	local room = rooms[roomId]
	if not room then return end

	for i, pid in ipairs(room.players) do
		if pid == userId then
			table.remove(room.players, i)
			break
		end
	end
	playerRoom[userId] = nil

	if room.host == userId then
		if #room.players > 0 then
			room.host = room.players[1]
			local newHost = Players:GetPlayerByUserId(room.host)
			room.hostName = newHost and newHost.Name or "Unknown"
		else
			rooms[roomId] = nil
		end
	end

	broadcastRoomList()
end

function RoomManager.init()
	-- 방 생성
	CreateRoomRE.OnServerEvent:Connect(function(player, options)
		if playerRoom[player.UserId] then return end
		if #rooms >= Config.MAX_ROOMS then
			CreateRoomRE:FireClient(player, false, "방이 꽉 찼습니다")
			return
		end

		local roomId = generateRoomId()
		rooms[roomId] = {
			host = player.UserId,
			hostName = player.Name,
			players = { player.UserId },
			status = "waiting",
			map = options and options.map or "CityMap",
			maxPlayers = options and options.maxPlayers or 8,
		}
		playerRoom[player.UserId] = roomId
		CreateRoomRE:FireClient(player, true, roomId)
		broadcastRoomList()
	end)

	-- 방 참여
	JoinRoomRE.OnServerEvent:Connect(function(player, roomId)
		if playerRoom[player.UserId] then return end
		local room = rooms[roomId]
		if not room then
			JoinRoomRE:FireClient(player, false, "방이 없습니다")
			return
		end
		if #room.players >= room.maxPlayers then
			JoinRoomRE:FireClient(player, false, "방이 꽉 찼습니다")
			return
		end
		if room.status ~= "waiting" then
			JoinRoomRE:FireClient(player, false, "이미 게임 중")
			return
		end

		table.insert(room.players, player.UserId)
		playerRoom[player.UserId] = roomId
		JoinRoomRE:FireClient(player, true, roomId)
		broadcastRoomList()
	end)

	-- 방 나가기
	LeaveRoomRE.OnServerEvent:Connect(function(player)
		removePlayerFromRoom(player)
	end)

	-- 게임 시작 (방장만)
	StartGameRE.OnServerEvent:Connect(function(player)
		local roomId = playerRoom[player.UserId]
		if not roomId then return end
		local room = rooms[roomId]
		if not room or room.host ~= player.UserId then return end
		if #room.players < Config.MIN_PLAYERS then
			StartGameRE:FireClient(player, false, "최소 " .. Config.MIN_PLAYERS .. "명 필요")
			return
		end

		room.status = "playing"
		broadcastRoomList()

		local playerList = {}
		for _, uid in ipairs(room.players) do
			local p = Players:GetPlayerByUserId(uid)
			if p then table.insert(playerList, p) end
		end

		-- GameManager에 신호
		local GameManager = require(script.Parent.GameManager)
		GameManager.startRound(playerList, room.map, roomId)
	end)

	-- 방 목록 요청
	RoomListRF.OnServerInvoke = function(_player)
		local list = {}
		for id, room in pairs(rooms) do
			table.insert(list, {
				id = id,
				host = room.hostName,
				playerCount = #room.players,
				maxPlayers = room.maxPlayers,
				status = room.status,
				map = room.map,
			})
		end
		return list
	end

	-- 연결 끊기면 방 자동 정리
	Players.PlayerRemoving:Connect(removePlayerFromRoom)
end

function RoomManager.getRoomId(player)
	return playerRoom[player.UserId]
end

function RoomManager.endRoom(roomId)
	local room = rooms[roomId]
	if room then
		room.status = "waiting"
		broadcastRoomList()
	end
end

return RoomManager
