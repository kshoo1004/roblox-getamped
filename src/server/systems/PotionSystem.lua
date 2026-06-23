-- Potion spawning, pickup detection, and respawn logic
local Config = require(game.ReplicatedStorage.Shared.Config)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local PotionSystem = {}

local potionFolder
local activePotions = {}     -- { part, spawnPoint, active }
local onPickupCallback = nil -- function(player) called when potion picked up

local function createPotionModel(position)
	local folder = Instance.new("Folder")
	folder.Name = "Potion"
	folder.Parent = potionFolder

	-- Bottle body
	local bottle = Instance.new("Part")
	bottle.Shape = Enum.PartType.Cylinder
	bottle.Size = Vector3.new(2, 1, 1)
	bottle.Position = position
	bottle.Anchored = true
	bottle.BrickColor = BrickColor.new("Bright red")
	bottle.Material = Enum.Material.Neon
	bottle.Name = "Bottle"
	bottle.Parent = folder

	-- Glow effect
	local glow = Instance.new("PointLight")
	glow.Brightness = 3
	glow.Range = 10
	glow.Color = Color3.fromRGB(255, 50, 50)
	glow.Parent = bottle

	-- Billboard label
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 80, 0, 30)
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.AlwaysOnTop = false
	billboard.Parent = bottle

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "💊 변신약"
	label.TextColor3 = Color3.fromRGB(255, 100, 100)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = billboard

	-- Float animation
	local tweenInfo = TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	TweenService:Create(bottle, tweenInfo, { Position = position + Vector3.new(0, 1, 0) }):Play()

	-- Spin
	RunService.Heartbeat:Connect(function(dt)
		if bottle and bottle.Parent then
			bottle.CFrame = bottle.CFrame * CFrame.Angles(0, dt * 2, 0)
		end
	end)

	return folder, bottle
end

local function spawnPotion(spawnPoint)
	local folder, bottle = createPotionModel(spawnPoint)

	local potionData = {
		folder = folder,
		bottle = bottle,
		spawnPoint = spawnPoint,
		active = true,
	}

	-- Touch detection
	bottle.Touched:Connect(function(hit)
		if not potionData.active then return end
		local character = hit.Parent
		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end

		-- Consume potion
		potionData.active = false
		folder:Destroy()

		if onPickupCallback then
			onPickupCallback(player)
		end

		-- Respawn after delay
		task.delay(Config.POTION_RESPAWN_TIME, function()
			if potionFolder and potionFolder.Parent then
				spawnPotion(spawnPoint)
			end
		end)
	end)

	table.insert(activePotions, potionData)
	return potionData
end

function PotionSystem.Start(spawnPoints, onPickup)
	onPickupCallback = onPickup
	activePotions = {}

	potionFolder = Instance.new("Folder")
	potionFolder.Name = "Potions"
	potionFolder.Parent = workspace

	-- Spawn initial potions at random subset of spawn points
	local shuffled = {}
	for _, pt in ipairs(spawnPoints) do
		table.insert(shuffled, pt)
	end
	-- Shuffle
	for i = #shuffled, 2, -1 do
		local j = math.random(i)
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	end

	local count = math.min(Config.POTION_COUNT, #shuffled)
	for i = 1, count do
		spawnPotion(shuffled[i])
	end

	print("[PotionSystem] Spawned " .. count .. " potions")
end

function PotionSystem.Stop()
	if potionFolder then
		potionFolder:Destroy()
		potionFolder = nil
	end
	activePotions = {}
	onPickupCallback = nil
end

return PotionSystem
