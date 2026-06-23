-- 클라이언트 BGM 재생기
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local bgmSound = Instance.new("Sound")
bgmSound.Name = "BGM"
bgmSound.Volume = 0.4
bgmSound.RollOffMaxDistance = 1e9
bgmSound.Parent = SoundService

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local BGMRemote = Remotes:WaitForChild("PlayBGM")

BGMRemote.OnClientEvent:Connect(function(data)
	if data.action == "play" then
		bgmSound:Stop()
		bgmSound.SoundId = "rbxassetid://" .. tostring(data.assetId)
		bgmSound.Volume = data.volume or 0.4
		bgmSound.Looped = data.looped or true
		bgmSound:Play()
	elseif data.action == "stop" then
		bgmSound:Stop()
	end
end)
