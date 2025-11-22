-- ServerScriptService/AntiCheatSystem/InventoryManager
local InventoryManager = {}
local Config = require(script.Parent.Config)
local Logger = require(script.Parent.Logger)

local PlayerInventories = {}

-- Initialize player inventory
function InventoryManager.InitPlayer(player)
	PlayerInventories[player.UserId] = {
		Items = {},
		LastModification = tick(),
		ModificationCount = 0
	}
end

-- Add item (server-side only)
function InventoryManager.AddItem(player, itemId, quantity)
	local userId = player.UserId

	if not PlayerInventories[userId] then
		InventoryManager.InitPlayer(player)
	end

	-- Rate limit inventory modifications
	local currentTime = tick()
	if currentTime - PlayerInventories[userId].LastModification < 0.1 then
		PlayerInventories[userId].ModificationCount = PlayerInventories[userId].ModificationCount + 1

		if PlayerInventories[userId].ModificationCount > 10 then
			Logger.LogSuspiciousActivity(player, "Inventory spam detected", {
				ItemId = itemId,
				Count = PlayerInventories[userId].ModificationCount
			})
			return false
		end
	else
		PlayerInventories[userId].ModificationCount = 0
	end

	-- Validate item exists in game
	if not InventoryManager.ValidateItem(itemId) then
		Logger.LogSuspiciousActivity(player, "Invalid item ID", {
			ItemId = itemId
		})
		return false
	end

	-- Add item to inventory
	if not PlayerInventories[userId].Items[itemId] then
		PlayerInventories[userId].Items[itemId] = 0
	end

	PlayerInventories[userId].Items[itemId] = PlayerInventories[userId].Items[itemId] + quantity
	PlayerInventories[userId].LastModification = currentTime

	-- Log for tracking
	Logger.LogActivity(player, "Item added", {
		ItemId = itemId,
		Quantity = quantity
	})

	return true
end

-- Remove item (server-side only)
function InventoryManager.RemoveItem(player, itemId, quantity)
	local userId = player.UserId

	if not PlayerInventories[userId] or not PlayerInventories[userId].Items[itemId] then
		return false
	end

	if PlayerInventories[userId].Items[itemId] < quantity then
		Logger.LogSuspiciousActivity(player, "Insufficient item quantity", {
			ItemId = itemId,
			Has = PlayerInventories[userId].Items[itemId],
			Requested = quantity
		})
		return false
	end

	PlayerInventories[userId].Items[itemId] = PlayerInventories[userId].Items[itemId] - quantity

	if PlayerInventories[userId].Items[itemId] <= 0 then
		PlayerInventories[userId].Items[itemId] = nil
	end

	return true
end

-- Validate item exists
function InventoryManager.ValidateItem(itemId)
	-- Check against a database of valid items
	local validItems = game.ReplicatedStorage:FindFirstChild("ValidItems")
	if not validItems then return false end

	return validItems:FindFirstChild(itemId) ~= nil
end

-- Get player inventory (read-only)
function InventoryManager.GetInventory(player)
	local userId = player.UserId
	if not PlayerInventories[userId] then return {} end

	-- Return a copy to prevent tampering
	local inventoryCopy = {}
	for itemId, quantity in pairs(PlayerInventories[userId].Items) do
		inventoryCopy[itemId] = quantity
	end

	return inventoryCopy
end

return InventoryManager