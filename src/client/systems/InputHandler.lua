-- 클라이언트: 입력 처리 + 스킬 발동
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local AttackRequest = Remotes:WaitForChild("AttackRequest")
local SkillRequest = Remotes:WaitForChild("SkillRequest")
local HitConfirm = Remotes:WaitForChild("HitConfirm")

-- UI 쿨타임 표시
local function updateCooldownUI(skillKey, cooldown)
	local playerGui = player.PlayerGui
	local hud = playerGui:FindFirstChild("HUD")
	if not hud then return end
	local btn = hud:FindFirstChild("Skill_" .. skillKey)
	if not btn then return end

	local overlay = btn:FindFirstChild("CooldownOverlay")
	if overlay then
		overlay.Visible = true
		task.delay(cooldown, function()
			overlay.Visible = false
		end)
	end
end

-- 쿨타임 추적 (클라이언트 예측)
local cooldowns = {}
local function isOnCooldown(skillKey)
	local last = cooldowns[skillKey] or 0
	return tick() - last < (cooldowns[skillKey .. "_duration"] or 0)
end

local function setCooldown(skillKey, duration)
	cooldowns[skillKey] = tick()
	cooldowns[skillKey .. "_duration"] = duration
	updateCooldownUI(skillKey, duration)
end

-- 스턴 상태
local isStunned = false

-- 입력 처리
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if isStunned then return end

	local key = input.KeyCode

	-- Z: 콤보 공격
	if key == Enum.KeyCode.Z then
		AttackRequest:FireServer({})

	-- X: 스킬 1 (화염 돌진)
	elseif key == Enum.KeyCode.X then
		if not isOnCooldown("X") then
			SkillRequest:FireServer("X")
			setCooldown("X", 6)
		end

	-- C: 스킬 2 (용염 폭발)
	elseif key == Enum.KeyCode.C then
		if not isOnCooldown("C") then
			SkillRequest:FireServer("C")
			setCooldown("C", 12)
		end
	end
end)

-- 서버에서 히트 확인 수신
HitConfirm.OnClientEvent:Connect(function(data)
	if data.type == "stun" then
		isStunned = true
		task.delay(data.duration, function()
			isStunned = false
		end)

	elseif data.type == "attack" and data.target == player.Name then
		-- 피격 이펙트 (화면 빨개지기 등)
		local playerGui = player.PlayerGui
		local hud = playerGui:FindFirstChild("HUD")
		if hud then
			local hitEffect = hud:FindFirstChild("HitFlash")
			if hitEffect then
				hitEffect.Visible = true
				task.delay(0.15, function() hitEffect.Visible = false end)
			end
		end

	elseif data.type == "aoe" then
		-- AOE 폭발 이펙트 처리 (파티클 등)
	end
end)

-- 리스폰 시 재연결
player.CharacterAdded:Connect(function(newChar)
	character = newChar
	isStunned = false
	cooldowns = {}
end)
