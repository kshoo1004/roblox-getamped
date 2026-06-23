-- 배경음악 시스템
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(game.ReplicatedStorage.shared.Config)

local MusicSystem = {}

local currentTrackIndex = 1
local isPlaying = false
local sound = nil

-- 서버 → 클라이언트 BGM 동기화 Remote
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local BGMRemote = Remotes:WaitForChild("PlayBGM")

function MusicSystem.playLobbyMusic()
	BGMRemote:FireAllClients({
		action = "play",
		assetId = Config.BGM_IDS[4],  -- 로비 BGM
		volume = Config.BGM_VOLUME,
		looped = true,
	})
end

function MusicSystem.playBattleMusic()
	currentTrackIndex = math.random(1, 3)
	BGMRemote:FireAllClients({
		action = "play",
		assetId = Config.BGM_IDS[currentTrackIndex],
		volume = Config.BGM_VOLUME * 1.2,
		looped = true,
	})
end

function MusicSystem.stopMusic()
	BGMRemote:FireAllClients({ action = "stop" })
end

function MusicSystem.playForPlayer(player)
	BGMRemote:FireClient(player, {
		action = "play",
		assetId = Config.BGM_IDS[4],
		volume = Config.BGM_VOLUME,
		looped = true,
	})
end

return MusicSystem
