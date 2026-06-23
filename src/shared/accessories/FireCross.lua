-- 파이어크로스: 불꽃 십자 투사체 + 화염 돌진 + 폭염 폭발
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local FireCross = {}
FireCross.__index = FireCross

FireCross.id = "FireCross"
FireCross.name = "파이어크로스"
FireCross.description = "불꽃 투사체로 원거리 공격"
FireCross.stats = {
	attackMultiplier = 1.2,
	knockbackMultiplier = 1.3,
	speedBonus = 2,
}
FireCross.skills = {
	Z = { name = "파이어크로스", cooldown = 4, damage = 35,
		  projectileSpeed = 60, projectileCount = 4, range = 50 },
	X = { name = "화염 돌진",   cooldown = 6, damage = 50,
		  dashSpeed = 80, dashDuration = 0.4, trailDamage = 15, knockback = 100 },
	C = { name = "폭염 폭발",   cooldown = 12, damage = 80,
		  radius = 15, knockback = 180, burnDuration = 3, burnDamagePerSec = 10 },
}

-- Z: 불꽃 십자 발사 (4방향 투사체)
function FireCross.UseSkill_Z(character, onHit)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local directions = {
		Vector3.new(1,0,0), Vector3.new(-1,0,0),
		Vector3.new(0,0,1), Vector3.new(0,0,-1)
	}

	for _, dir in ipairs(directions) do
		local proj = Instance.new("Part")
		proj.Size = Vector3.new(0.8, 0.8, 2)
		proj.BrickColor = BrickColor.new("Bright orange")
		proj.Material = Enum.Material.Neon
		proj.CFrame = root.CFrame + dir * 3
		proj.Parent = workspace
		proj.CanCollide = false

		local light = Instance.new("PointLight")
		light.Brightness = 5; light.Range = 8; light.Color = Color3.fromRGB(255,100,0)
		light.Parent = proj

		local bv = Instance.new("BodyVelocity")
		bv.Velocity = dir * FireCross.skills.Z.projectileSpeed
		bv.MaxForce = Vector3.new(1e5,1e5,1e5)
		bv.Parent = proj

		Debris:AddItem(proj, 3)

		-- 충돌 감지
		proj.Touched:Connect(function(hit)
			local victim = hit.Parent
			local hum = victim:FindFirstChild("Humanoid")
			if hum and victim ~= character then
				if onHit then onHit(victim, FireCross.skills.Z.damage) end
				proj:Destroy()
			end
		end)
	end
end

-- X: 화염 돌진
function FireCross.UseSkill_X(character, onHit)
	local root = character:FindFirstChild("HumanoidRootPart")
	local hum  = character:FindFirstChild("Humanoid")
	if not root or not hum then return end

	local sk = FireCross.skills.X
	local dir = root.CFrame.LookVector
	local bv = Instance.new("BodyVelocity")
	bv.Velocity = dir * sk.dashSpeed
	bv.MaxForce = Vector3.new(1e5, 0, 1e5)
	bv.Parent = root

	-- 돌진 중 불꽃 트레일
	local trail = Instance.new("Fire")
	trail.Size = 3; trail.Heat = 10
	trail.Parent = root

	-- 지나치는 적 데미지
	local touched = {}
	local conn = root.Touched:Connect(function(hit)
		local victim = hit.Parent
		if victim ~= character and not touched[victim] then
			local victimHum = victim:FindFirstChild("Humanoid")
			if victimHum then
				touched[victim] = true
				if onHit then onHit(victim, sk.trailDamage) end
			end
		end
	end)

	task.delay(sk.dashDuration, function()
		bv:Destroy(); trail:Destroy(); conn:Disconnect()
		-- 종료 지점 폭발 넉백
		local explode = Instance.new("Explosion")
		explode.BlastRadius = 8
		explode.BlastPressure = sk.knockback * 100
		explode.Position = root.Position
		explode.Parent = workspace
	end)
end

-- C: 폭염 폭발 + 화상 DoT
function FireCross.UseSkill_C(character, onHit)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local sk = FireCross.skills.C
	local pos = root.Position

	-- 폭발 이펙트
	local explosion = Instance.new("Explosion")
	explosion.BlastRadius = sk.radius
	explosion.BlastPressure = sk.knockback * 100
	explosion.Position = pos
	explosion.Parent = workspace

	-- 범위 내 적 화상 DoT
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if char and char ~= character then
			local r = char:FindFirstChild("HumanoidRootPart")
			local h = char:FindFirstChild("Humanoid")
			if r and h and (r.Position - pos).Magnitude <= sk.radius then
				if onHit then onHit(char, sk.damage) end
				-- 화상 DoT
				local ticks = 0
				local burnConn
				burnConn = RunService.Heartbeat:Connect(function()
					ticks += 1
					if ticks % 60 == 0 then -- 1초마다
						if onHit then onHit(char, sk.burnDamagePerSec) end
					end
					if ticks >= sk.burnDuration * 60 then
						burnConn:Disconnect()
					end
				end)
			end
		end
	end
end

return FireCross
