-- Combat system: hit detection, knockback, stun, combos
-- Handles both normal (DragonClaw) and gorilla skill sets
local Config = require(game.ReplicatedStorage.Shared.Config)
local GorillaMode = require(game.ReplicatedStorage.Shared.Accessories.GorillaMode)
local DragonClaw = require(game.ReplicatedStorage.Shared.Accessories.DragonClaw)
local Players = game:GetService("Players")

local CombatSystem = {}

local hitEvent    -- RemoteEvent from client: player used skill
local effectEvent -- RemoteEvent to all clients: show hit effects

-- Forward declaration (TransformSystem injected to avoid circular require)
local TransformSystem

-- player → { stunUntil, lastComboTime, comboCount, cooldowns }
local playerState = {}

local function getState(player)
	if not playerState[player] then
		playerState[player] = {
			stunUntil = 0,
			lastComboTime = 0,
			comboCount = 0,
			cooldowns = {},
		}
	end
	return playerState[player]
end

local function isStunned(player)
	return tick() < (getState(player).stunUntil or 0)
end

local function applyKnockback(targetCharacter, direction, force)
	local hrp = targetCharacter:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local bv = Instance.new("BodyVelocity")
	bv.Velocity = direction * force + Vector3.new(0, force * 0.28, 0)
	bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	bv.P = 1e4
	bv.Parent = hrp
	game:GetService("Debris"):AddItem(bv, 0.18)
end

local function applyHit(attacker, target, damage, knockback, stunDuration)
	local humanoid = target:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return false end

	local targetPlayer = Players:GetPlayerFromCharacter(target)
	if targetPlayer and isStunned(targetPlayer) then return false end

	humanoid:TakeDamage(damage)

	if targetPlayer then
		getState(targetPlayer).stunUntil = tick() + (stunDuration or Config.STUN_DURATION)
	end

	local attackerHRP = attacker:FindFirstChild("HumanoidRootPart")
	local targetHRP = target:FindFirstChild("HumanoidRootPart")
	if attackerHRP and targetHRP then
		local dir = (targetHRP.Position - attackerHRP.Position).Unit
		applyKnockback(target, dir, knockback)
	end

	if effectEvent and targetHRP then
		effectEvent:FireAllClients("HIT", targetHRP.Position, knockback > 130 and "heavy" or "normal")
	end
	return true
end

local function doAoeHit(attacker, center, radius, damage, knockback, stunDuration, excludePlayer)
	for _, player in ipairs(Players:GetPlayers()) do
		if player == excludePlayer then continue end
		local char = player.Character
		if not char then continue end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp and (hrp.Position - center).Magnitude <= radius then
			applyHit(attacker, char, damage, knockback, stunDuration)
		end
	end
end

local function handleSkill(attackerPlayer, skillKey)
	if isStunned(attackerPlayer) then return end

	local attacker = attackerPlayer.Character
	if not attacker then return end
	local hrp = attacker:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local isGorilla = TransformSystem and TransformSystem.IsGorilla(attackerPlayer)
	local skills = isGorilla and GorillaMode.Skills or DragonClaw.Skills
	local skill = skills[skillKey]
	if not skill then return end

	local state = getState(attackerPlayer)
	local now = tick()

	-- Cooldown check (skip for Z basic combo)
	if skillKey ~= "Z" then
		local last = state.cooldowns[skillKey] or 0
		if now - last < (skill.cooldown or 0) then return end
		state.cooldowns[skillKey] = now
	end

	if skillKey == "Z" then
		-- Combo chain
		if now - state.lastComboTime > Config.COMBO_WINDOW then
			state.comboCount = 0
		end
		state.comboCount = (state.comboCount % (skill.comboSteps or 3)) + 1
		state.lastComboTime = now

		local finalHit = state.comboCount == (skill.comboSteps or 3)
		local dmg = math.floor(skill.damage * (finalHit and 1.6 or 1.0))
		local kb = skill.knockback * (finalHit and 1.4 or 1.0)

		for _, player in ipairs(Players:GetPlayers()) do
			if player == attackerPlayer then continue end
			local char = player.Character
			if not char then continue end
			local tHRP = char:FindFirstChild("HumanoidRootPart")
			if tHRP and (tHRP.Position - hrp.Position).Magnitude <= (skill.range or 7) then
				applyHit(attacker, char, dmg, kb)
			end
		end

	elseif skillKey == "X" then
		-- Ground slam / fire dash
		if isGorilla then
			-- Ground slam AOE
			doAoeHit(attacker, hrp.Position, skill.aoeRadius or 10,
				skill.damage, skill.knockback, Config.STUN_DURATION, attackerPlayer)
			if effectEvent then
				effectEvent:FireAllClients("AOE", hrp.Position, "slam")
			end
		else
			-- Dragon Claw: fire dash
			local dashDir = hrp.CFrame.LookVector
			local bv = Instance.new("BodyVelocity")
			bv.Velocity = dashDir * (skill.dashSpeed or 80)
			bv.MaxForce = Vector3.new(1e5, 0, 1e5)
			bv.Parent = hrp
			game:GetService("Debris"):AddItem(bv, 0.25)

			task.delay(0.25, function()
				if not attacker.Parent then return end
				local newHRP = attacker:FindFirstChild("HumanoidRootPart")
				if not newHRP then return end
				for _, player in ipairs(Players:GetPlayers()) do
					if player == attackerPlayer then continue end
					local char = player.Character
					if not char then continue end
					local tHRP = char:FindFirstChild("HumanoidRootPart")
					if tHRP and (tHRP.Position - newHRP.Position).Magnitude <= 8 then
						applyHit(attacker, char, skill.damage, skill.knockback)
					end
				end
			end)
		end

	elseif skillKey == "C" then
		-- Dragon: dragon breath AOE / Gorilla: charge
		if isGorilla then
			local dashDir = hrp.CFrame.LookVector
			applyKnockback(attacker, dashDir, skill.dashSpeed or 100)
			task.delay(0.35, function()
				if not attacker.Parent then return end
				local newHRP = attacker:FindFirstChild("HumanoidRootPart")
				if not newHRP then return end
				doAoeHit(attacker, newHRP.Position, 9, skill.damage, skill.knockback,
					Config.STUN_DURATION, attackerPlayer)
			end)
		else
			-- Dragon claw explosion
			doAoeHit(attacker, hrp.Position, skill.aoeRadius or 8,
				skill.damage, skill.knockback, skill.stunDuration or 0.8, attackerPlayer)
			if effectEvent then
				effectEvent:FireAllClients("AOE", hrp.Position, "explosion")
			end
		end

	elseif skillKey == "V" and isGorilla then
		-- Gorilla roar: stun everyone nearby
		doAoeHit(attacker, hrp.Position, skill.aoeRadius or 20,
			0, skill.knockback, skill.stunDuration or 1.5, attackerPlayer)
		if effectEvent then
			effectEvent:FireAllClients("AOE", hrp.Position, "roar")
		end
	end
end

function CombatSystem.Init(events, transformSys)
	hitEvent = events.HitEvent
	effectEvent = events.EffectEvent
	TransformSystem = transformSys

	hitEvent.OnServerEvent:Connect(function(player, skillKey)
		handleSkill(player, skillKey)
	end)
end

function CombatSystem.ResetPlayer(player)
	playerState[player] = nil
end

Players.PlayerRemoving:Connect(function(player)
	playerState[player] = nil
end)

return CombatSystem
