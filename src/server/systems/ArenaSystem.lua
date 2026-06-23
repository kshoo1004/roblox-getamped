-- Arena system: fall detection, respawn, kill tracking
local Config = require(game.ReplicatedStorage.Shared.Config)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ArenaSystem = {}

local events = {}
local onKillCallback = nil
local fallCheckConnection = nil

-- player → last attacker (for kill credit)
local lastHitBy = {}

function ArenaSystem.RegisterHit(victim, attacker)
	lastHitBy[victim] = attacker
end

local function respawnAt(player, pos)
	task.delay(3, function()
		if not player.Character then return end
		local hrp = player.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
		end
		local humanoid = player.Character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.Health = humanoid.MaxHealth
		end
	end)
end

function ArenaSystem.Init(evts, onKill)
	events = evts
	onKillCallback = onKill

	-- Disconnect previous fall check if any
	if fallCheckConnection then
		fallCheckConnection:Disconnect()
	end

	local spawnPoints = {
		Vector3.new(-70, 2, -60), Vector3.new(50, 2, -60),
		Vector3.new(-70, 2, 60),  Vector3.new(50, 2, 60),
		Vector3.new(0, 2, -70),   Vector3.new(0, 2, 70),
	}

	fallCheckConnection = RunService.Heartbeat:Connect(function()
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			if not char then continue end
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if not hrp then continue end

			if hrp.Position.Y < Config.FALL_Y then
				-- Kill credit
				local killer = lastHitBy[player]
				if killer and killer ~= player and killer.Character then
					if onKillCallback then
						onKillCallback(killer, player)
					end
				end
				lastHitBy[player] = nil

				-- Humanoid kill
				local humanoid = char:FindFirstChild("Humanoid")
				if humanoid then humanoid.Health = 0 end

				-- Respawn
				local pos = spawnPoints[math.random(#spawnPoints)]
				respawnAt(player, pos)

				if events.StatusEvent then
					events.StatusEvent:FireAllClients("FELL", { player = player.Name })
				end
			end
		end
	end)
end

function ArenaSystem.Stop()
	if fallCheckConnection then
		fallCheckConnection:Disconnect()
		fallCheckConnection = nil
	end
	lastHitBy = {}
end

Players.PlayerRemoving:Connect(function(player)
	lastHitBy[player] = nil
end)

return ArenaSystem
