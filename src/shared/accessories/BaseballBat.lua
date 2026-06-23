-- 빠따 (야구방망이) 악세서리
local BaseballBat = {
	id = "BaseballBat",
	name = "야구방망이",
	description = "강력한 타격으로 넉백을 주는 배트",

	stats = {
		attackMultiplier = 1.4,
		knockbackMultiplier = 2.0,  -- 강한 넉백
		speedBonus = 0,
	},

	skills = {
		-- Z: 홈런 스윙 (강 넉백)
		Z = {
			name = "홈런 스윙",
			cooldown = 3,
			damage = 45,
			knockback = 200,
			range = 7,
			stunDuration = 0.8,
			execute = function(caster, hitTargets)
				for _, target in ipairs(hitTargets) do
					-- 위+뒤로 날려버림
					local dir = (target.Character.HumanoidRootPart.Position
						- caster.Character.HumanoidRootPart.Position).Unit
					local bv = Instance.new("BodyVelocity")
					bv.Velocity = (dir + Vector3.new(0, 1.5, 0)).Unit * 220
					bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
					bv.Parent = target.Character.HumanoidRootPart
					game:GetService("Debris"):AddItem(bv, 0.25)
				end
			end,
		},

		-- X: 연속 타격 (3타)
		X = {
			name = "연속 타격",
			cooldown = 5,
			hits = 3,
			damagePerHit = 20,
			knockback = 60,
			range = 6,
			interval = 0.2,
		},

		-- C: 스매시 다운 (공중에서 내리찍기)
		C = {
			name = "스매시 다운",
			cooldown = 8,
			damage = 70,
			knockback = 150,
			range = 8,
			groundSlam = true,  -- 지면 충격파
			slamRadius = 10,
		},
	},

	-- 픽업 시 외형
	model = {
		tool = true,
		meshId = "rbxasset://meshes/baseball_bat.mesh",  -- 커스텀 메시
		color = BrickColor.new("Reddish brown"),
		size = Vector3.new(0.3, 3, 0.3),
	},
}

return BaseballBat
