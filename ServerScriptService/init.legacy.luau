-- ServerScriptService/AntiCheatSystem/Init
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Load modules
local Config = require(script.Parent.Config)
local RemoteSecurity = require(script.Parent.RemoteSecurity)
local MovementCheck = require(script.Parent.MovementCheck)
local StatValidator = require(script.Parent.StatValidator)
local InventoryManager = require(script.Parent.InventoryManager)
local Logger = require(script.Parent.Logger)

-- Create RemoteEvents folder
local remoteEventsFolder = Instance.new("Folder")
remoteEventsFolder.Name = "RemoteEvents"
remoteEventsFolder.Parent = ReplicatedStorage

local remoteFunctionsFolder = Instance.new("Folder")
remoteFunctionsFolder.Name = "RemoteFunctions"
remoteFunctionsFolder.Parent = ReplicatedStorage

-- Create report remote for client-side detection
local reportRemote = Instance.new("RemoteEvent")
reportRemote.Name = "ReportSuspiciousActivity"
reportRemote.Parent = remoteEventsFolder

reportRemote.OnServerEvent:Connect(function(player, reason, data)
	Logger.LogSuspiciousActivity(player, "Client reported: " .. reason, data)
end)

-- Example: Create secure purchase remote
local purchaseRemote = RemoteSecurity.CreateSecureRemoteEvent("PurchaseItem", function(player, itemId, quantity)
	-- Validate purchase
	local itemPrice = 100 -- Get from database
	local totalCost = itemPrice * quantity

	-- Process transaction
	if StatValidator.ProcessTransaction(player, totalCost, "Purchase", itemId) then
		-- Add item to inventory
		if InventoryManager.AddItem(player, itemId, quantity) then
			print(player.Name, "purchased", quantity, "x", itemId)
			return true
		else
			-- Refund if inventory add failed
			StatValidator.ProcessTransaction(player, totalCost, "Earn", "Refund: " .. itemId)
		end
	end

	return false
end)

-- Player initialization
Players.PlayerAdded:Connect(function(player)
	print("[Anti-Cheat] Initializing security for", player.Name)

	-- Initialize all systems
	MovementCheck.InitPlayer(player)
	StatValidator.InitPlayer(player)
	InventoryManager.InitPlayer(player)

	Logger.LogActivity(player, "Player joined", {
		AccountAge = player.AccountAge,
		UserId = player.UserId
	})
end)

-- Player cleanup
Players.PlayerRemoving:Connect(function(player)
	MovementCheck.CleanupPlayer(player)
	Logger.LogActivity(player, "Player left", nil)
end)

print("[Anti-Cheat System] Initialized successfully")