-- Gorilla transformation skill set
-- Triggered when player picks up a potion
local Config = require(game.ReplicatedStorage.Shared.Config)

local GorillaMode = {}

GorillaMode.Skills = {
	Z = {
		name = "고릴라 강타",
		cooldown = 0,           -- basic combo, no cooldown
		damage = 45,
		knockback = 120,
		range = 7,
		comboSteps = 3,
		description = "강력한 3단 주먹 콤보",
	},
	X = {
		name = "지면 강타",
		cooldown = 5,
		damage = 80,
		knockback = 200,
		range = 12,
		aoeRadius = 10,
		description = "지면을 내리쳐 주변 적을 날려보냄",
	},
	C = {
		name = "돌진",
		cooldown = 8,
		damage = 60,
		knockback = 160,
		range = 30,
		dashSpeed = 120,
		description = "빠른 속도로 돌진해 적을 치받음",
	},
	V = {
		name = "고릴라 포효",
		cooldown = 15,
		damage = 0,
		knockback = 180,
		range = 20,
		aoeRadius = 20,
		stunDuration = 1.5,
		description = "포효로 주변 적을 스턴시킴",
	},
}

-- Apply gorilla visual transformation to character
function GorillaMode.ApplyTransform(character)
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end

	-- Scale up
	humanoid.BodyDepthScale.Value = Config.GORILLA_SIZE
	humanoid.BodyHeightScale.Value = Config.GORILLA_SIZE
	humanoid.BodyWidthScale.Value = Config.GORILLA_SIZE
	humanoid.HeadScale.Value = Config.GORILLA_SIZE * 0.85

	-- Stats
	humanoid.WalkSpeed = Config.GORILLA_SPEED
	humanoid.JumpPower = Config.GORILLA_JUMP
	humanoid.MaxHealth = Config.GORILLA_HEALTH
	humanoid.Health = Config.GORILLA_HEALTH

	-- Color skin dark gray (gorilla fur)
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			if part.Name == "Head" or part.Name == "UpperTorso" or
			   part.Name == "LowerTorso" or part.Name == "LeftUpperArm" or
			   part.Name == "RightUpperArm" or part.Name == "LeftLowerArm" or
			   part.Name == "RightLowerArm" or part.Name == "LeftHand" or
			   part.Name == "RightHand" or part.Name == "LeftUpperLeg" or
			   part.Name == "RightUpperLeg" or part.Name == "LeftLowerLeg" or
			   part.Name == "RightLowerLeg" or part.Name == "LeftFoot" or
			   part.Name == "RightFoot" then
				part.BrickColor = BrickColor.new("Dark grey")
				part.Material = Enum.Material.SmoothPlastic
			end
		end
	end
end

-- Revert gorilla transformation
function GorillaMode.RevertTransform(character, originalData)
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end

	humanoid.BodyDepthScale.Value = 1
	humanoid.BodyHeightScale.Value = 1
	humanoid.BodyWidthScale.Value = 1
	humanoid.HeadScale.Value = 1

	humanoid.WalkSpeed = Config.NORMAL_SPEED
	humanoid.JumpPower = Config.NORMAL_JUMP
	humanoid.MaxHealth = Config.BASE_HEALTH
	if humanoid.Health > Config.BASE_HEALTH then
		humanoid.Health = Config.BASE_HEALTH
	end

	-- Restore original colors
	if originalData and originalData.colors then
		for partName, color in pairs(originalData.colors) do
			local part = character:FindFirstChild(partName)
			if part then
				part.BrickColor = color
			end
		end
	end
end

-- Capture current character colors before transform
function GorillaMode.CaptureOriginalData(character)
	local data = { colors = {} }
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			data.colors[part.Name] = part.BrickColor
		end
	end
	return data
end

return GorillaMode
