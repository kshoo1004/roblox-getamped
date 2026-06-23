-- City map procedural generation
-- Creates buildings, roads, sidewalks, and potion spawn points
local Config = require(game.ReplicatedStorage.Shared.Config)

local CityMap = {}

local mapFolder
local potionSpawnPoints = {}

local function makeBlock(size, position, color, material, parent, name)
	local part = Instance.new("Part")
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.BrickColor = color or BrickColor.new("Medium stone grey")
	part.Material = material or Enum.Material.SmoothPlastic
	part.Name = name or "Block"
	part.Parent = parent or workspace
	return part
end

local function buildGround()
	-- Main ground (road color)
	makeBlock(
		Vector3.new(Config.CITY_SIZE, 2, Config.CITY_SIZE),
		Vector3.new(0, -1, 0),
		BrickColor.new("Dark grey"),
		Enum.Material.SmoothPlastic,
		mapFolder, "Ground"
	)
	-- Road markings (center yellow lines)
	for i = -80, 80, 20 do
		makeBlock(
			Vector3.new(1, 0.2, 4),
			Vector3.new(0, 0.1, i),
			BrickColor.new("Bright yellow"),
			Enum.Material.SmoothPlastic,
			mapFolder, "RoadMark"
		)
		makeBlock(
			Vector3.new(4, 0.2, 1),
			Vector3.new(i, 0.1, 0),
			BrickColor.new("Bright yellow"),
			Enum.Material.SmoothPlastic,
			mapFolder, "RoadMark"
		)
	end
end

local function buildBuilding(x, z, width, depth, height, color)
	local cx = x + width / 2
	local cz = z + depth / 2
	local cy = height / 2

	-- Main body
	local body = makeBlock(
		Vector3.new(width, height, depth),
		Vector3.new(cx, cy, cz),
		color,
		Enum.Material.SmoothPlastic,
		mapFolder, "Building"
	)

	-- Windows (decorative rows)
	local windowColor = BrickColor.new("Institutional white")
	for row = 1, math.floor(height / 6) do
		for col = 1, math.floor(width / 5) do
			makeBlock(
				Vector3.new(2, 2.5, 0.3),
				Vector3.new(x + col * 5 - 3, row * 6 - 2, cz + depth / 2 + 0.2),
				windowColor,
				Enum.Material.Neon,
				mapFolder, "Window"
			)
		end
	end

	-- Rooftop ledge
	makeBlock(
		Vector3.new(width + 1, 1, depth + 1),
		Vector3.new(cx, height + 0.5, cz),
		BrickColor.new("Dark grey"),
		Enum.Material.SmoothPlastic,
		mapFolder, "Rooftop"
	)

	-- Rooftop is a fight platform — add spawn point there
	table.insert(potionSpawnPoints, Vector3.new(cx, height + 2, cz))
end

local function buildCity()
	local buildingColors = {
		BrickColor.new("Medium stone grey"),
		BrickColor.new("Brick yellow"),
		BrickColor.new("Sand blue"),
		BrickColor.new("Reddish brown"),
		BrickColor.new("Light bluish violet"),
		BrickColor.new("Dark orange"),
	}

	-- Grid layout: 4x5 building blocks with roads between
	local gridX = { -90, -55, -15, 25, 65 }
	local gridZ = { -80, -40, 0, 40 }
	local widths  = { 25, 30, 20, 28, 22 }
	local depths  = { 20, 25, 22, 18, 24 }
	local heights = { 30, 50, 20, 40, 60, 35, 45, 25, 55, 38,
	                  42, 28, 48, 32, 52, 22, 36, 46, 26, 44 }

	local idx = 1
	for gi, gx in ipairs(gridX) do
		for gj, gz in ipairs(gridZ) do
			local w = widths[gi]
			local d = depths[gj]
			local h = heights[idx] or 30
			local color = buildingColors[((idx - 1) % #buildingColors) + 1]
			buildBuilding(gx, gz, w, d, h, color)

			-- Street-level spawn points between buildings
			table.insert(potionSpawnPoints, Vector3.new(gx + w + 4, 2, gz + d / 2))
			table.insert(potionSpawnPoints, Vector3.new(gx + w / 2, 2, gz - 4))

			idx = idx + 1
		end
	end

	-- Sidewalks
	for _, gx in ipairs(gridX) do
		makeBlock(
			Vector3.new(2, 0.5, Config.CITY_SIZE - 10),
			Vector3.new(gx - 2, 0.25, 0),
			BrickColor.new("Light grey"),
			Enum.Material.SmoothPlastic,
			mapFolder, "Sidewalk"
		)
	end

	-- Boundary walls (invisible, keep players in)
	local half = Config.CITY_SIZE / 2
	for _, data in ipairs({
		{ Vector3.new(Config.CITY_SIZE, 60, 2), Vector3.new(0, 30, half) },
		{ Vector3.new(Config.CITY_SIZE, 60, 2), Vector3.new(0, 30, -half) },
		{ Vector3.new(2, 60, Config.CITY_SIZE), Vector3.new(half, 30, 0) },
		{ Vector3.new(2, 60, Config.CITY_SIZE), Vector3.new(-half, 30, 0) },
	}) do
		local wall = makeBlock(data[1], data[2], BrickColor.new("Transparent"), nil, mapFolder, "Boundary")
		wall.Transparency = 1
		wall.CanCollide = true
	end
end

function CityMap.Build()
	-- Clean previous map
	if mapFolder then mapFolder:Destroy() end
	potionSpawnPoints = {}

	mapFolder = Instance.new("Folder")
	mapFolder.Name = "CityMap"
	mapFolder.Parent = workspace

	buildGround()
	buildCity()

	-- Ambient lighting
	game.Lighting.Ambient = Color3.fromRGB(120, 120, 140)
	game.Lighting.TimeOfDay = "18:00:00"
	game.Lighting.Brightness = 1.5

	print("[CityMap] Built with " .. #potionSpawnPoints .. " potion spawn points")
	return mapFolder
end

function CityMap.GetPotionSpawnPoints()
	return potionSpawnPoints
end

function CityMap.GetPlayerSpawnPoints()
	-- Return street-level safe spots for player spawning
	return {
		Vector3.new(-70, 2, -60),
		Vector3.new(50, 2, -60),
		Vector3.new(-70, 2, 60),
		Vector3.new(50, 2, 60),
		Vector3.new(0, 2, -70),
		Vector3.new(0, 2, 70),
		Vector3.new(-80, 2, 0),
		Vector3.new(80, 2, 0),
	}
end

function CityMap.Destroy()
	if mapFolder then
		mapFolder:Destroy()
		mapFolder = nil
	end
end

return CityMap
