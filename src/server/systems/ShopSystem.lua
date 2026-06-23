local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CoinStore = DataStoreService:GetDataStore("PlayerCoins_v1")

local SHOP_ITEMS = {
	{ id = "DragonClaw",      name = "용발톱",       price = 500,  description = "3단 콤보 + 화염 돌진" },
	{ id = "FireCross",       name = "파이어크로스", price = 600,  description = "불꽃 투사체 + 폭발" },
	{ id = "BaseballBat",     name = "빠따",         price = 300,  description = "강력한 넉백 타격" },
	{ id = "VibrationBelt",   name = "돌쇠진동벨트", price = 700,  description = "범위 진동 + 지속 판정" },
	{ id = "GorillaPotion",   name = "고릴라물약",   price = 200,  description = "30초간 고릴라 변신" },
}

local playerCoins = {}
local playerItems = {}

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GetShopItems  = Remotes:WaitForChild("GetShopItems")
local PurchaseItem  = Remotes:WaitForChild("PurchaseItem")
local GetCoins      = Remotes:WaitForChild("GetCoins")
local AddCoins      = Remotes:WaitForChild("AddCoins")

local function loadPlayerData(player)
	local success, data = pcall(function()
		return CoinStore:GetAsync("player_" .. player.UserId)
	end)
	if success and data then
		playerCoins[player.UserId] = data.coins or 0
		playerItems[player.UserId] = data.items or {}
	else
		playerCoins[player.UserId] = 100 -- 신규 유저 초기 코인
		playerItems[player.UserId] = {}
	end
end

local function savePlayerData(player)
	pcall(function()
		CoinStore:SetAsync("player_" .. player.UserId, {
			coins = playerCoins[player.UserId] or 0,
			items = playerItems[player.UserId] or {},
		})
	end)
end

local function hasItem(userId, itemId)
	local items = playerItems[userId] or {}
	for _, id in ipairs(items) do
		if id == itemId then return true end
	end
	return false
end

Players.PlayerAdded:Connect(function(player)
	loadPlayerData(player)
end)

Players.PlayerRemoving:Connect(function(player)
	savePlayerData(player)
	playerCoins[player.UserId] = nil
	playerItems[player.UserId] = nil
end)

GetShopItems.OnServerInvoke = function(player)
	local owned = playerItems[player.UserId] or {}
	local result = {}
	for _, item in ipairs(SHOP_ITEMS) do
		local entry = { table.unpack and table.unpack({}) }
		entry.id          = item.id
		entry.name        = item.name
		entry.price       = item.price
		entry.description = item.description
		entry.owned       = hasItem(player.UserId, item.id)
		table.insert(result, entry)
	end
	return result
end

PurchaseItem.OnServerInvoke = function(player, itemId)
	local coins = playerCoins[player.UserId] or 0
	local item
	for _, v in ipairs(SHOP_ITEMS) do
		if v.id == itemId then item = v break end
	end
	if not item then return false, "존재하지 않는 아이템" end
	if hasItem(player.UserId, itemId) then return false, "이미 보유 중" end
	if coins < item.price then return false, "코인 부족 (" .. coins .. "/" .. item.price .. ")" end

	playerCoins[player.UserId] = coins - item.price
	table.insert(playerItems[player.UserId], itemId)
	savePlayerData(player)

	AddCoins:FireClient(player, playerCoins[player.UserId]) -- 잔액 동기화
	return true, "구매 완료: " .. item.name
end

GetCoins.OnServerInvoke = function(player)
	return playerCoins[player.UserId] or 0
end

-- 킬 보상 (CombatSystem에서 호출)
local ShopSystem = {}
function ShopSystem.awardKillCoins(player, amount)
	amount = amount or 50
	playerCoins[player.UserId] = (playerCoins[player.UserId] or 0) + amount
	AddCoins:FireClient(player, playerCoins[player.UserId])
end

function ShopSystem.getCoins(player)
	return playerCoins[player.UserId] or 0
end

return ShopSystem
