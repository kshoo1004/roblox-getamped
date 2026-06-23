local Config = {
	-- Round
	ROUND_DURATION = 180,
	LOBBY_DURATION = 20,
	RESULT_DURATION = 10,
	MIN_PLAYERS = 2,
	MAX_PLAYERS = 12,

	-- Room
	MAX_ROOMS = 10,

	-- Combat
	BASE_HEALTH = 150,
	KNOCKBACK_FORCE = 80,
	STUN_DURATION = 0.4,
	COMBO_WINDOW = 0.6,

	-- Potion
	POTION_COUNT = 8,
	POTION_RESPAWN_TIME = 20,
	POTION_TRANSFORM_DURATION = 30,

	-- Gorilla
	GORILLA_HEALTH = 400,
	GORILLA_SPEED = 18,
	GORILLA_JUMP = 90,
	GORILLA_SIZE = 2.2,

	-- Normal
	NORMAL_SPEED = 16,
	NORMAL_JUMP = 50,

	-- Map
	CITY_SIZE = 300,
	BUILDING_COUNT = 30,
	STREET_WIDTH = 14,
	FALL_Y = -80,

	-- Bungee
	BUNGEE_POINTS = 4,
	BUNGEE_HEIGHT = 120,
	BUNGEE_ELASTICITY = 0.7,

	-- Weapons
	WEAPON_SPAWN_COUNT = 6,
	WEAPON_RESPAWN_TIME = 15,

	-- Music (Roblox Asset IDs)
	BGM_IDS = {
		142376088,   -- 신나는 배틀 BGM 1
		1837667609,  -- 배틀 BGM 2
		1843671375,  -- BGM 3
		142376088,   -- 로비 BGM
	},
	BGM_VOLUME = 0.4,

	-- Team colors
	TEAM_COLORS = {
		BrickColor.new("Bright red"),
		BrickColor.new("Bright blue"),
		BrickColor.new("Bright green"),
		BrickColor.new("Bright yellow"),
		BrickColor.new("Hot pink"),
		BrickColor.new("Cyan"),
	},
}

return Config
