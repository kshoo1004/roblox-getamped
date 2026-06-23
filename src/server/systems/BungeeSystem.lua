-- 번지점프 시스템
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Config = require(game.ReplicatedStorage.shared.Config)

local BungeeSystem = {}

local BUNGEE_POSITIONS = {
	Vector3.new(80, 0, 80),
	Vector3.new(-80, 0, 80),
	Vector3.new(80, 0, -80),
	Vector3.new(-80, 0, -80),
}

local bungeePoints = {}
local playerBungee = {}  -- userId -> { active, ropeConstraint, attachment }

local function createBungeePlatform(pos)
	-- 번지 타워 기둥
	local tower = Instance.new("Part")
	tower.Name = "BungeeTower"
	tower.Anchored = true
	tower.Size = Vector3.new(4, Config.BUNGEE_HEIGHT, 4)
	tower.Position = pos + Vector3.new(0, Config.BUNGEE_HEIGHT / 2, 0)
	tower.BrickColor = BrickColor.new("Bright red")
	tower.Material = Enum.Material.Metal
	tower.Parent = workspace

	-- 꼭대기 점프대
	local platform = Instance.new("Part")
	platform.Name = "BungeePlatform"
	platform.Anchored = true
	platform.Size = Vector3.new(8, 1, 8)
	platform.Position = pos + Vector3.new(0, Config.BUNGEE_HEIGHT + 0.5, 0)
	platform.BrickColor = BrickColor.new("Bright yellow")
	platform.Material = Enum.Material.SmoothPlastic
	platform.Parent = workspace

	-- 안내판
	local bb = Instance.new("BillboardGui", platform)
	bb.Size = UDim2.new(0, 120, 0, 40)
	bb.StudsOffset = Vector3.new(0, 3, 0)
	local lbl = Instance.new("TextLabel", bb)
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 0.3
	lbl.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
	lbl.Text = "🪂 번지점프!"
	lbl.TextColor3 = Color3.new(1, 1, 1)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 16

	-- 올라가는 계단 (나선형 발판)
	for i = 1, 12 do
		local step = Instance.new("Part")
		step.Anchored = true
		step.Size = Vector3.new(3, 0.5, 3)
		local angle = i * (math.pi * 2 / 12)
		step.Position = pos + Vector3.new(
			math.cos(angle) * 5,
			i * (Config.BUNGEE_HEIGHT / 12),
			math.sin(angle) * 5
		)
		step.BrickColor = BrickColor.new("Medium stone grey")
		step.Parent = workspace
	end

	-- 점프 트리거
	local trigger = Instance.new("Part")
	trigger.Name = "BungeeTrigger"
	trigger.Anchored = true
	trigger.CanCollide = false
	trigger.Transparency = 0.8
	trigger.Size = Vector3.new(8, 2, 8)
	trigger.Position = platform.Position + Vector3.new(0, 1, 0)
	trigger.BrickColor = BrickColor.new("Cyan")
	trigger.Parent = workspace

	return { tower = tower, platform = platform, trigger = trigger, topPos = platform.Position }
end

local function doJump(player, topPos)
	local uid = player.UserId
	if playerBungee[uid] and playerBungee[uid].active then return end

	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	playerBungee[uid] = { active = true }

	-- 텔레포트: 점프대 끝으로
	hrp.CFrame = CFrame.new(topPos + Vector3.new(0, 3, 0))
	task.wait(0.3)

	-- 번지 밧줄 시뮬레이션 (BodyPosition 이용)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then hum.PlatformStand = true end

	local bp = Instance.new("BodyPosition")
	bp.Position = topPos
	bp.MaxForce = Vector3.new(0, 1e5, 0)
	bp.D = 500
	bp.P = 8000
	bp.Parent = hrp

	-- 낙하 애니메이션
	local dropTarget = topPos - Vector3.new(0, Config.BUNGEE_HEIGHT * 0.85, 0)
	local fallTime = 0
	local bouncing = true
	local bounceCount = 0
	local direction = -1  -- -1 = 아래로, 1 = 위로

	while bouncing and playerBungee[uid] and playerBungee[uid].active do
		fallTime = fallTime + task.wait(0.05)
		local t = math.min(fallTime / 1.5, 1)

		if direction == -1 then
			bp.Position = topPos:Lerp(dropTarget, t)
			if t >= 1 then
				direction = 1
				fallTime = 0
				bounceCount = bounceCount + 1
				dropTarget = topPos - Vector3.new(0, Config.BUNGEE_HEIGHT * (0.85 - bounceCount * 0.2), 0)
			end
		else
			bp.Position = dropTarget:Lerp(topPos, t * Config.BUNGEE_ELASTICITY)
			if t >= 1 then
				if bounceCount >= 3 then
					bouncing = false
				else
					direction = -1
					fallTime = 0
				end
			end
		end
	end

	bp:Destroy()
	if hum then hum.PlatformStand = false end

	-- 착지 시 주변 플레이어 넉백
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player and other.Character then
			local otherHrp = other.Character:FindFirstChild("HumanoidRootPart")
			if otherHrp then
				local dist = (otherHrp.Position - hrp.Position).Magnitude
				if dist < 15 then
					local bv = Instance.new("BodyVelocity")
					local dir = (otherHrp.Position - hrp.Position).Unit
					bv.Velocity = (dir + Vector3.new(0, 0.5, 0)).Unit * (200 - dist * 8)
					bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
					bv.Parent = otherHrp
					game:GetService("Debris"):AddItem(bv, 0.3)
				end
			end
		end
	end

	playerBungee[uid] = { active = false }
end

function BungeeSystem.build()
	bungeePoints = {}
	for _, pos in ipairs(BUNGEE_POSITIONS) do
		local bp = createBungeePlatform(pos)
		table.insert(bungeePoints, bp)

		-- 트리거 감지
		bp.trigger.Touched:Connect(function(hit)
			local char = hit.Parent
			local player = Players:GetPlayerFromCharacter(char)
			if not player then return end
			local uid = player.UserId
			if playerBungee[uid] and playerBungee[uid].active then return end
			task.spawn(doJump, player, bp.topPos)
		end)
	end
end

function BungeeSystem.clearAll()
	for _, bp in ipairs(bungeePoints) do
		if bp.tower and bp.tower.Parent then bp.tower:Destroy() end
		if bp.platform and bp.platform.Parent then bp.platform:Destroy() end
		if bp.trigger and bp.trigger.Parent then bp.trigger:Destroy() end
	end
	bungeePoints = {}
	playerBungee = {}
end

return BungeeSystem
