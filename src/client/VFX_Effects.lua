-- VFX_Effects: 히트 이펙트, 스킬 이펙트, UI 피드백
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VFX = {}

-- 히트 이펙트 (피격 시 파티클)
function VFX.HitEffect(position, hitType)
	hitType = hitType or "normal"

	local colors = {
		normal  = Color3.fromRGB(255, 200, 50),
		fire    = Color3.fromRGB(255, 80,  0),
		gorilla = Color3.fromRGB(100, 255, 100),
		vibrate = Color3.fromRGB(180, 180, 255),
	}

	local part = Instance.new("Part")
	part.Size = Vector3.new(0.5, 0.5, 0.5)
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.Neon
	part.BrickColor = BrickColor.new("Bright yellow")
	part.CFrame = CFrame.new(position)
	part.Parent = workspace

	-- 파티클 이미터
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(colors[hitType] or colors.normal)
	emitter.LightEmission = 0.8
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Speed = NumberRange.new(10, 25)
	emitter.Lifetime = NumberRange.new(0.3, 0.6)
	emitter.Rate = 0
	emitter.Enabled = false
	emitter.Parent = part
	emitter:Emit(20)

	Debris:AddItem(part, 1)
end

-- 스킬 이펙트 (스킬 사용 시 캐릭터 주변)
function VFX.SkillEffect(character, skillName)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	if skillName == "Z_DragonClaw" then
		-- 용발톱: 붉은 발톱 자국 이펙트
		for i = 1, 3 do
			task.delay(i * 0.05, function()
				local slash = Instance.new("Part")
				slash.Size = Vector3.new(0.2, 4, 0.1)
				slash.Anchored = true
				slash.CanCollide = false
				slash.Material = Enum.Material.Neon
				slash.BrickColor = BrickColor.new("Bright red")
				slash.CFrame = root.CFrame
					* CFrame.new(math.random(-2,2), 0, -2)
					* CFrame.Angles(0, 0, math.rad(i * 30))
				slash.Parent = workspace

				local tween = TweenService:Create(slash,
					TweenInfo.new(0.3, Enum.EasingStyle.Quad),
					{Transparency = 1, Size = Vector3.new(0.1, 6, 0.1)}
				)
				tween:Play()
				Debris:AddItem(slash, 0.4)
			end)
		end

	elseif skillName == "FireCross_Z" then
		-- 파이어크로스: 십자형 불꽃
		local glow = Instance.new("Part")
		glow.Size = Vector3.new(8, 0.2, 0.3)
		glow.Anchored = true
		glow.CanCollide = false
		glow.Material = Enum.Material.Neon
		glow.BrickColor = BrickColor.new("Bright orange")
		glow.CFrame = root.CFrame
		glow.Parent = workspace

		local glow2 = glow:Clone()
		glow2.CFrame = root.CFrame * CFrame.Angles(0, math.pi/2, 0)
		glow2.Parent = workspace

		local fire = Instance.new("Fire")
		fire.Size = 5; fire.Heat = 15
		fire.Parent = root

		task.delay(0.3, function()
			TweenService:Create(glow, TweenInfo.new(0.3), {Transparency=1}):Play()
			TweenService:Create(glow2, TweenInfo.new(0.3), {Transparency=1}):Play()
			Debris:AddItem(glow, 0.4)
			Debris:AddItem(glow2, 0.4)
		end)
		task.delay(1, function() fire:Destroy() end)

	elseif skillName == "Gorilla_Slam" then
		-- 고릴라 내려치기: 지진 이펙트
		local shockwave = Instance.new("Part")
		shockwave.Size = Vector3.new(1, 0.5, 1)
		shockwave.Anchored = true
		shockwave.CanCollide = false
		shockwave.Material = Enum.Material.Neon
		shockwave.BrickColor = BrickColor.new("Bright green")
		shockwave.Shape = Enum.PartType.Cylinder
		shockwave.CFrame = CFrame.new(root.Position - Vector3.new(0,2,0))
		shockwave.Parent = workspace

		TweenService:Create(shockwave,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Size = Vector3.new(20, 0.2, 20), Transparency = 1}
		):Play()
		Debris:AddItem(shockwave, 0.6)

	elseif skillName == "VibrationBelt" then
		-- 돌쇠진동벨트: 진동 링 이펙트
		for i = 1, 3 do
			task.delay(i * 0.1, function()
				local ring = Instance.new("Part")
				ring.Size = Vector3.new(i*3, 0.2, i*3)
				ring.Anchored = true
				ring.CanCollide = false
				ring.Material = Enum.Material.Neon
				ring.BrickColor = BrickColor.new("Lavender")
				ring.Shape = Enum.PartType.Cylinder
				ring.CFrame = CFrame.new(root.Position)
					* CFrame.Angles(0, 0, math.pi/2)
				ring.Parent = workspace

				TweenService:Create(ring,
					TweenInfo.new(0.4),
					{Transparency = 1, Size = Vector3.new(i*5, 0.1, i*5)}
				):Play()
				Debris:AddItem(ring, 0.5)
			end)
		end
	end
end

-- 변신 이펙트 (고릴라 변신)
function VFX.TransformEffect(character)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	-- 폭발적 녹색 빛
	local flash = Instance.new("Part")
	flash.Size = Vector3.new(5,5,5)
	flash.Anchored = true
	flash.CanCollide = false
	flash.Material = Enum.Material.Neon
	flash.BrickColor = BrickColor.new("Bright green")
	flash.Shape = Enum.PartType.Ball
	flash.CFrame = CFrame.new(root.Position)
	flash.Parent = workspace

	TweenService:Create(flash,
		TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = Vector3.new(20,20,20), Transparency = 1}
	):Play()
	Debris:AddItem(flash, 0.7)

	-- 화면 흔들림 (ScreenGui로 처리)
	local screenShake = Instance.new("ScreenGui")
	screenShake.Name = "TransformShake"
	screenShake.Parent = game.Players.LocalPlayer.PlayerGui
	task.delay(0.5, function() screenShake:Destroy() end)
end

-- 물약 픽업 이펙트
function VFX.PotionPickup(position)
	local sparkle = Instance.new("Part")
	sparkle.Size = Vector3.new(0.5,0.5,0.5)
	sparkle.Anchored = true
	sparkle.CanCollide = false
	sparkle.Material = Enum.Material.Neon
	sparkle.BrickColor = BrickColor.new("Cyan")
	sparkle.CFrame = CFrame.new(position)
	sparkle.Parent = workspace

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(Color3.fromRGB(0, 255, 200))
	emitter.LightEmission = 1
	emitter.Speed = NumberRange.new(5, 15)
	emitter.Lifetime = NumberRange.new(0.5, 1)
	emitter.Rate = 0
	emitter.Parent = sparkle
	emitter:Emit(30)

	Debris:AddItem(sparkle, 1.5)
end

-- RemoteEvent 연결 (서버에서 클라이언트로 VFX 요청)
local function setupRemoteListeners()
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
	if not remotes then return end

	local hitEvent = remotes:FindFirstChild("HitEffect")
	if hitEvent then
		hitEvent.OnClientEvent:Connect(function(position, hitType)
			VFX.HitEffect(position, hitType)
		end)
	end

	local skillEvent = remotes:FindFirstChild("SkillEffect")
	if skillEvent then
		skillEvent.OnClientEvent:Connect(function(character, skillName)
			VFX.SkillEffect(character, skillName)
		end)
	end
end

setupRemoteListeners()

return VFX