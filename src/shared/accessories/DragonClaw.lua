-- 용발톱 (Dragon Claw) Accessory Definition
local DragonClaw = {}

DragonClaw.Name = "용발톱"
DragonClaw.Description = "불꽃 발톱으로 적을 할퀴고 화염 돌진을 날린다"
DragonClaw.Icon = "rbxassetid://0" -- 나중에 교체

-- 스탯 보정
DragonClaw.Stats = {
	AttackBonus = 15,
	SpeedBonus = 5,
	DefenseBonus = 0,
}

-- 스킬 정의
DragonClaw.Skills = {
	-- Z: 발톱 할퀴기 (3단 콤보)
	Z = {
		Name = "발톱 할퀴기",
		Cooldown = 0,
		ComboCount = 3,
		Damage = { 12, 15, 25 }, -- 콤보별 데미지
		Knockback = { 20, 25, 60 },
		Range = 6,
		ComboWindow = 1.2, -- 다음 콤보 입력 허용 시간
	},
	-- X: 화염 돌진
	X = {
		Name = "화염 돌진",
		Cooldown = 6,
		Damage = 35,
		Knockback = 80,
		Range = 20,
		DashSpeed = 120,
		DashDuration = 0.35,
		FireTrail = true,
	},
	-- C: 용염 폭발 (범위기)
	C = {
		Name = "용염 폭발",
		Cooldown = 12,
		Damage = 50,
		Knockback = 100,
		Range = 10,
		AoeRadius = 8,
		StunDuration = 1.0,
	},
}

return DragonClaw
