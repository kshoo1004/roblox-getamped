-- 돌쇠진동벨트: 범위 진동 판정 + 지속 데미지 특성
local VibrationBelt = {}

VibrationBelt.id = "VibrationBelt"
VibrationBelt.displayName = "돌쇠진동벨트"
VibrationBelt.icon = "⚡"

VibrationBelt.stats = {
	damage       = 12,
	vibeRadius   = 10,   -- 진동 범위 (스터드)
	vibeDuration = 3,    -- 지속 진동 시간 (초)
	vibeInterval = 0.3,  -- 진동 타격 간격
	knockback    = 18,
	stunTime     = 0.4,
}

VibrationBelt.skills = {
	-- Z: 진동 펀치 (근접 3타)
	Z = {
		name     = "진동 펀치",
		cooldown = 0,
		comboMax = 3,
		hits = {
			{ damage = 10, range = 5,  knockback = 10, delay = 0 },
			{ damage = 10, range = 5,  knockback = 12, delay = 0.25 },
			{ damage = 15, range = 6,  knockback = 25, delay = 0.5 },
		},
	},

	-- X: 돌쇠 진동파 — 범위 내 모든 적에게 지속 데미지
	X = {
		name        = "돌쇠 진동파",
		cooldown    = 8,
		description = "반경 10 스터드 내 모든 적 3초간 지속 진동",
		execute = function(caster, targets, config)
			-- 서버에서 처리: 0.3초마다 범위 내 타격
			local ticks = math.floor(config.vibeDuration / config.vibeInterval)
			for i = 1, ticks do
				task.delay(i * config.vibeInterval, function()
					for _, target in ipairs(targets) do
						if target and target.Parent then
							-- CombatSystem이 데미지 적용
							-- ReplicatedStorage.Remotes.ApplyDamage:Fire(caster, target, config.damage)
						end
					end
				end)
			end
		end,
	},

	-- C: 대지 진동 — 지면 충격파, 공중 적은 낙하 스턴
	C = {
		name        = "대지 진동",
		cooldown    = 15,
		description = "지면 충격파로 주변 적 날리기 + 공중 추락 스턴",
		damage      = 35,
		range       = 14,
		knockbackUp = 40,   -- 위로 날리기
		knockbackOut = 20,  -- 바깥으로 날리기
		stunTime    = 1.2,
	},
}

-- 패시브: 모든 공격에 소량 진동 추가 데미지
VibrationBelt.passive = {
	name        = "진동 증폭",
	description = "모든 공격 시 추가 진동 데미지 +3",
	bonusDamage = 3,
}

-- 악세서리 외형 정의 (Studio에서 적용)
VibrationBelt.appearance = {
	beltColor      = Color3.fromRGB(180, 120, 0),
	beltWidth      = 0.3,
	beltHeight     = 0.5,
	buckleColor    = Color3.fromRGB(220, 180, 0),
	particleColor  = ColorSequence.new(Color3.fromRGB(255, 220, 0), Color3.fromRGB(255, 100, 0)),
	particleRate   = 20, -- 진동 시 파티클 방출
}

-- 진동 VFX 설정 (클라이언트에서 사용)
VibrationBelt.vfx = {
	vibeShakeAmount = 0.3,   -- 카메라 흔들림 강도
	vibeShakeFreq   = 20,    -- 흔들림 주파수
	groundWaveColor = Color3.fromRGB(255, 200, 0),
	groundWaveSize  = 12,
	soundId         = "rbxassetid://131961136", -- 진동 사운드
}

return VibrationBelt
