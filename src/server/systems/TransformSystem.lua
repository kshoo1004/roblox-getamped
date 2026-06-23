-- Gorilla transformation management (server-side)
-- Handles timing, revert, and remote event broadcasting
local Config = require(game.ReplicatedStorage.Shared.Config)
local GorillaMode = require(game.ReplicatedStorage.Shared.Accessories.GorillaMode)
local Players = game:GetService("Players")

local TransformSystem = {}

-- player → { endTime, originalData, timerThread }
local activeTransforms = {}

local transformEvent    -- RemoteEvent: server → client (start/stop/tick)
local skillChangeEvent  -- RemoteEvent: server → client (skill set)

function TransformSystem.Init(events)
	transformEvent = events.TransformEvent
	skillChangeEvent = events.SkillChangeEvent
end

function TransformSystem.IsGorilla(player)
	return activeTransforms[player] ~= nil
end

function TransformSystem.ApplyGorilla(player)
	local character = player.Character
	if not character then return end
	if activeTransforms[player] then
		-- Refresh duration if already gorilla
		activeTransforms[player].endTime = tick() + Config.POTION_TRANSFORM_DURATION
		return
	end

	-- Capture original state
	local originalData = GorillaMode.CaptureOriginalData(character)

	-- Apply transform
	GorillaMode.ApplyTransform(character)

	local endTime = tick() + Config.POTION_TRANSFORM_DURATION

	-- Notify client (for UI timer + gorilla skillset)
	if transformEvent then
		transformEvent:FireClient(player, "START", Config.POTION_TRANSFORM_DURATION)
	end
	if skillChangeEvent then
		skillChangeEvent:FireClient(player, "GORILLA")
	end

	-- Countdown timer
	local timerThread = task.spawn(function()
		while true do
			task.wait(1)
			local remaining = activeTransforms[player] and (activeTransforms[player].endTime - tick()) or 0
			if remaining <= 0 then break end
			if transformEvent then
				transformEvent:FireClient(player, "TICK", math.ceil(remaining))
			end
		end

		TransformSystem.RevertGorilla(player)
	end)

	activeTransforms[player] = {
		endTime = endTime,
		originalData = originalData,
		timerThread = timerThread,
	}

	print("[TransformSystem] " .. player.Name .. " → GORILLA for " .. Config.POTION_TRANSFORM_DURATION .. "s")
end

function TransformSystem.RevertGorilla(player)
	local data = activeTransforms[player]
	if not data then return end

	activeTransforms[player] = nil

	local character = player.Character
	if character then
		GorillaMode.RevertTransform(character, data.originalData)
	end

	-- Notify client
	if transformEvent then
		transformEvent:FireClient(player, "END", 0)
	end
	if skillChangeEvent then
		skillChangeEvent:FireClient(player, "NORMAL")
	end

	print("[TransformSystem] " .. player.Name .. " → NORMAL")
end

function TransformSystem.RevertAll()
	for player, _ in pairs(activeTransforms) do
		TransformSystem.RevertGorilla(player)
	end
end

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
	if activeTransforms[player] then
		activeTransforms[player] = nil
	end
end)

return TransformSystem
