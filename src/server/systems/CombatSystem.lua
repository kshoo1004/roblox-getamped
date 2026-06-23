-- 서버: 전투 판정 시스템
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CombatSystem = {}

-- RemoteEvents
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local AttackRequest = Remotes:WaitForChild("AttackRequest")
local HitConfirm = Remotes:WaitForChild("HitConfirm")
local SkillRequest = Remotes:WaitForChild("SkillRequest")

-- 플레이어별 전투 상태
local playerStates = {}

local function getState(player)
	if not playerStates[player] then
		playerStates[player] = {
			combo = 0,
			lastComboTime = 0,
			cooldowns = {},
			isStunned = false,
			stunEndTime = 0,
			equippedAccessory = nil,
		}
	end
	return playerStates[player]
end

-- 히트박스 판정
local function getHitsInRange(origin, direction, range, radius, attacker)
	local hits = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player == attacker then continue end
		local char = player.Character
		if not char then continue end
		local root = char:FindFirstChild("HumanoidRootPart")
		if not root then continue end

		local toTarget = root.Position - origin
		local dist = toTarget.Magnitude

		-- 전방 범위 체크
		local dot = toTarget.Unit:Dot(direction.Unit)
		if dist <= range and (radius > 0 or dot > 0.3) then
			table.insert(hits, { player = player, char = char })
		end
	end
	return hits
end

-- 넉백 적용
local function applyKnockback(targetChar, direction, force)
	local root = targetChar:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local bv = Instance.new("BodyVelocity")
	bv.Velocity = direction * force + Vector3.new(0, force * 0.3, 0)
	bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	bv.Parent = root

	game:GetService("Debris"):AddItem(bv, 0.25)
end

-- 데미지 적용
local function applyDamage(targetChar, damage, attacker)
	local humanoid = targetChar:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return false end
	humanoid:TakeDamage(damage)
	return true
end

-- 스턴 적용
local function applyStun(targetPlayer, duration)
	local state = getState(targetPlayer)
	state.isStunned = true
	state.stunEndTime = tick() + duration
	-- 클라이언트에 스턴 알림
	HitConfirm:FireClient(targetPlayer, { type = "stun", duration = duration })
end

-- 공격 처리 (Z키 콤보)
AttackRequest.OnServerEvent:Connect(function(player, attackData)
	local state = getState(player)
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	-- 스턴 체크
	if state.isStunned and tick() < state.stunEndTime then return end

	-- 악세서리 스킬 가져오기
	local accessory = state.equippedAccessory
	if not accessory then return end
	local zSkill = accessory.Skills.Z

	-- 콤보 체인 체크
	local now = tick()
	if now - state.lastComboTime > zSkill.ComboWindow then
		state.combo = 0
	end
	state.combo = math.min(state.combo + 1, zSkill.ComboCount)
	state.lastComboTime = now

	local comboIdx = state.combo
	local damage = zSkill.Damage[comboIdx]
	local knockback = zSkill.Knockback[comboIdx]

	-- 히트 판정
	local hits = getHitsInRange(
		root.Position,
		root.CFrame.LookVector,
		zSkill.Range,
		0,
		player
	)

	for _, hit in ipairs(hits) do
		if applyDamage(hit.char, damage, player) then
			local dir = (hit.char.HumanoidRootPart.Position - root.Position).Unit
			applyKnockback(hit.char, dir, knockback)
			HitConfirm:FireAllClients({
				attacker = player.Name,
				target = hit.player.Name,
				damage = damage,
				combo = comboIdx,
				type = "attack",
			})
		end
	end
end)

-- 스킬 처리 (X, C키)
SkillRequest.OnServerEvent:Connect(function(player, skillKey)
	local state = getState(player)
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	if state.isStunned and tick() < state.stunEndTime then return end

	local accessory = state.equippedAccessory
	if not accessory then return end
	local skill = accessory.Skills[skillKey]
	if not skill then return end

	-- 쿨타임 체크
	local now = tick()
	local lastUsed = state.cooldowns[skillKey] or 0
	if now - lastUsed < skill.Cooldown then return end
	state.cooldowns[skillKey] = now

	if skillKey == "X" then
		-- 화염 돌진
		local dir = root.CFrame.LookVector
		local hits = getHitsInRange(root.Position, dir, skill.Range, 3, player)

		-- 돌진 이동
		local bv = Instance.new("BodyVelocity")
		bv.Velocity = dir * skill.DashSpeed
		bv.MaxForce = Vector3.new(1e5, 0, 1e5)
		bv.Parent = root
		game:GetService("Debris"):AddItem(bv, skill.DashDuration)

		for _, hit in ipairs(hits) do
			if applyDamage(hit.char, skill.Damage, player) then
				local knockDir = (hit.char.HumanoidRootPart.Position - root.Position).Unit
				applyKnockback(hit.char, knockDir, skill.Knockback)
			end
		end

	elseif skillKey == "C" then
		-- 용염 폭발 (범위기)
		local hits = getHitsInRange(root.Position, Vector3.new(0,0,0), skill.AoeRadius, skill.AoeRadius, player)

		for _, hit in ipairs(hits) do
			if applyDamage(hit.char, skill.Damage, player) then
				local knockDir = (hit.char.HumanoidRootPart.Position - root.Position).Unit
				applyKnockback(hit.char, knockDir, skill.Knockback)
				applyStun(hit.player, skill.StunDuration)
			end
		end

		HitConfirm:FireAllClients({
			attacker = player.Name,
			type = "aoe",
			position = root.Position,
			radius = skill.AoeRadius,
		})
	end
end)

-- 악세서리 장착
local function equipAccessory(player, accessoryDef)
	local state = getState(player)
	state.equippedAccessory = accessoryDef
	state.combo = 0
	state.cooldowns = {}
end

-- 플레이어 리스폰 처리
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		-- 기본 악세서리: 용발톱
		local DragonClaw = require(ReplicatedStorage.Accessories.DragonClaw)
		equipAccessory(player, DragonClaw)
		playerStates[player] = nil -- 상태 리셋
		getState(player).equippedAccessory = DragonClaw
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	playerStates[player] = nil
end)

return CombatSystem
