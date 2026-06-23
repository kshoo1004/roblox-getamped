-- 파이어크로스 악세서리
local FireCross = {
	id = "FireCross",
	name = "파이어크로스",
	description = "불꽃 투사체로 원거리 공격",

	stats = {
		attackMultiplier = 1.2,
		knockbackMultiplier = 1.3,
		speedBonus = 2,
	},

	skills = {
		-- Z: 불꽃 십자 발사
		Z = {
			name = "파이어크로스",
			cooldown = 4,
			damage = 35,
			projectileSpeed = 60,
			projectileCount = 4,  -- 4방향
			spread = 90,          -- 90도 간격
			range = 50,
		},

		-- X: 화염 돌진
		X = {
			name = "화염 돌진",
			cooldown = 6,
			damage = 50,
			dashSpeed = 80,
			dashDuration = 0.4,
			trailDamage = 15,     -- 지나치는 대상 피해
			knockback = 100,
		},

		-- C: 폭염 폭발
		C = {
			name = "폭염 폭발",
			cooldown = 12,
			damage = 80,
			radius = 15,
			knockback = 180,
			burnDuration = 3,     -- 화상 DoT
			burnDamagePerSec = 10,
		},
	},
}

return FireCross
