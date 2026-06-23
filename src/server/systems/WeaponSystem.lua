-- 무기(빠따 등) 스폰 + 픽업 시스템
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Config = require(game.ReplicatedStorage.shared.Config)

local WeaponSystem = {}

local WEAPONS = {
	{
		id = "BaseballBat",
		name = "야구방망이",
		color = BrickColor.new("Reddish brown"),
		damage = 45,
		knockback = 200,
		label = "🏏",
	},
	{
		id = "IronPipe",
		name = "쇠파이프",
		color = BrickColor.new("Medium stone grey"),
		damage = 35,
		knockback = 130,
		label = "🔧",
	},
	{
		id = "GoldenBat",
		name = "황금빠따",
		color = BrickColor.new("Bright yellow"),
		damage = 60,
		knockback = 280,
		rare = true,
		label = "⚾",
	},
}

local activeWeapons = {}

local function createWeaponPart(weapon, position)
	local part = Instance.new("Part")
	part.Name = "Weapon_" .. weapon.id
	part.BrickColor = weapon.color
	part.Size = Vector3.new(0.4, 3.2, 0.4)
	part.Position = position + Vector3.new(0, 1.6, 0)
	part.Anchored = true
	part.CastShadow = true

	local bb = Instance.new("BillboardGui", part)
	bb.Size = UDim2.new(0, 60, 0, 30)
	bb.StudsOffset = Vector3.new(0, 2.5, 0)
	local label = Instance.new("TextLabel", bb)
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = weapon.label .. " " .. weapon.name
	label.TextColor3 = weapon.rare and Color3.fromRGB(255, 215, 0) or Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBold
	label.TextSize = 13

	-- 회전 애니메이션
	local rot = 0
	game:GetService("RunService").Heartbeat:Connect(function(dt)
		if part.Parent then
			rot = rot + dt * 120
			part.CFrame = CFrame.new(part.Position) * CFrame.Angles(0, math.rad(rot), 0)
		end
	end)

	part.Parent = workspace
	return part
end

function WeaponSystem.spawnWeapons(mapBounds)
	-- 기존 무기 정리
	for _, w in ipairs(activeWeapons) do
		if w.part and w.part.Parent then w.part:Destroy() end
	end
	activeWeapons = {}

	for i = 1, Config.WEAPON_SPAWN_COUNT do
		local weaponDef = WEAPONS[math.random(1, #WEAPONS)]
		local pos = Vector3.new(
			math.random(-mapBounds, mapBounds),
			2,
			math.random(-mapBounds, mapBounds)
		)

		local part = createWeaponPart(weaponDef, pos)

		local entry = { part = part, weapon = weaponDef, active = true }
		table.insert(activeWeapons, entry)

		-- 터치 감지 → 픽업
		part.Touched:Connect(function(hit)
			if not entry.active then return end
			local character = hit.Parent
			local player = Players:GetPlayerFromCharacter(character)
			if not player then return end

			entry.active = false
			part:Destroy()

			-- 플레이어에게 무기 장착 신호
			local Remotes = ReplicatedStorage:WaitForChild("Remotes")
			Remotes.WeaponPickup:FireClient(player, weaponDef.id)

			-- 서버 스탯 적용
			local tag = Instance.new("StringValue")
			tag.Name = "EquippedWeapon"
			tag.Value = weaponDef.id
			tag.Parent = character

			-- 15초 후 리스폰
			task.delay(Config.WEAPON_RESPAWN_TIME, function()
				if workspace:FindFirstChild("Arena") then
					local newPos = Vector3.new(
						math.random(-mapBounds, mapBounds),
						2,
						math.random(-mapBounds, mapBounds)
					)
					entry.part = createWeaponPart(weaponDef, newPos)
					entry.active = true
				end
			end)
		end)
	end
end

function WeaponSystem.getWeaponStats(weaponId)
	for _, w in ipairs(WEAPONS) do
		if w.id == weaponId then return w end
	end
	return nil
end

function WeaponSystem.clearWeapons()
	for _, entry in ipairs(activeWeapons) do
		if entry.part and entry.part.Parent then
			entry.part:Destroy()
		end
	end
	activeWeapons = {}
end

return WeaponSystem
