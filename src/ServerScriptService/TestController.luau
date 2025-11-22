-- ServerScriptService/AntiCheatTests/TestController
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Load Anti-Cheat modules
local RemoteSecurity = require(game.ServerScriptService.AntiCheatSystem.RemoteSecurity)
local MovementCheck = require(game.ServerScriptService.AntiCheatSystem.MovementCheck)
local StatValidator = require(game.ServerScriptService.AntiCheatSystem.StatValidator)
local InventoryManager = require(game.ServerScriptService.AntiCheatSystem.InventoryManager)
local Logger = require(game.ServerScriptService.AntiCheatSystem.Logger)

local TestController = {}

-- Test 1: Legitimate Remote Call
function TestController.TestLegitimateRemote(player)
	print("\n=== TEST 1: Legitimate Remote Call ===")

	local testRemote = RemoteSecurity.CreateSecureRemoteEvent("TestLegitimate", function(plr, message)
		print("✓ Legitimate remote received:", plr.Name, "says:", message)
		return true
	end)

	-- Simulate legitimate call from client
	wait(0.5)
	testRemote:FireClient(player, "Test response")

	print("TEST 1 COMPLETED\n")
end

-- Test 2: Rate Limit Test
function TestController.TestRateLimit(player)
	print("\n=== TEST 2: Rate Limit Test ===")

	local callCount = 0
	local testRemote = RemoteSecurity.CreateSecureRemoteEvent("TestRateLimit", function(plr)
		callCount = callCount + 1
		print("✓ Call received:", callCount)
	end)

	-- Simulate rapid calls (should trigger rate limit)
	task.spawn(function()
		for i = 1, 15 do
			testRemote:FireClient(player)
			wait(0.05) -- 20 calls per second
		end

		wait(1)
		print("Total legitimate calls processed:", callCount)
		print("Rate limit should have blocked some calls")
		print("TEST 2 COMPLETED\n")
	end)
end

-- Test 3: Invalid Argument Detection
function TestController.TestInvalidArguments(player)
	print("\n=== TEST 3: Invalid Argument Test ===")

	local testRemote = RemoteSecurity.CreateSecureRemoteEvent("TestInvalidArgs", function(plr, data)
		print("✓ Valid data received:", data)
	end)

	-- Test with valid argument
	print("Testing valid argument...")
	local validData = "Hello World"
	-- This would normally come from client, simulating here

	-- Test with invalid argument (extremely long string)
	print("Testing invalid argument (should be blocked)...")
	local invalidData = string.rep("A", 20000) -- 20k characters

	print("TEST 3 COMPLETED\n")
end

-- Test 4: Speed Hack Detection
function TestController.TestSpeedHack(player)
	print("\n=== TEST 4: Speed Hack Detection ===")

	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")

	print("Normal WalkSpeed:", humanoid.WalkSpeed)

	-- Simulate speed hack
	wait(1)
	print("Simulating speed hack...")
	humanoid.WalkSpeed = 100

	wait(2)
	print("Current WalkSpeed:", humanoid.WalkSpeed)
	print("Check console for anti-cheat detection")
	print("TEST 4 COMPLETED\n")
end

-- Test 5: Teleport Detection
function TestController.TestTeleport(player)
	print("\n=== TEST 5: Teleport Detection ===")

	local character = player.Character or player.CharacterAdded:Wait()
	local rootPart = character:WaitForChild("HumanoidRootPart")

	local originalPosition = rootPart.Position
	print("Original position:", originalPosition)

	-- Simulate teleport
	wait(1)
	print("Simulating teleport...")
	rootPart.CFrame = rootPart.CFrame + Vector3.new(500, 0, 0)

	wait(2)
	print("New position:", rootPart.Position)
	print("Check console for teleport detection")
	print("TEST 5 COMPLETED\n")
end

-- Test 6: Stat Validation
function TestController.TestStatValidation(player)
	print("\n=== TEST 6: Stat Validation Test ===")

	-- Create test leaderstats
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local money = leaderstats:FindFirstChild("Money")
	if not money then
		money = Instance.new("IntValue")
		money.Name = "Money"
		money.Value = 100
		money.Parent = leaderstats
	end

	print("Initial money:", money.Value)

	-- Test legitimate change
	print("\nTest 1: Legitimate small increase")
	local success1 = StatValidator.ModifyStat(player, "Money", 50, "TestEarn")
	print("Result:", success1 and "✓ Success" or "✗ Failed")
	print("New money:", money.Value)

	-- Test suspicious rapid change
	print("\nTest 2: Suspicious rapid change")
	local success2 = StatValidator.ModifyStat(player, "Money", 999999, "TestExploit")
	print("Result:", success2 and "✓ Success" or "✗ Failed (Expected)")
	print("Money after exploit attempt:", money.Value)

	-- Test transaction system
	print("\nTest 3: Valid purchase")
	money.Value = 500
	local success3 = StatValidator.ProcessTransaction(player, 100, "Purchase", "TestItem")
	print("Result:", success3 and "✓ Success" or "✗ Failed")
	print("Money after purchase:", money.Value)

	print("TEST 6 COMPLETED\n")
end

-- Test 7: Inventory Management
function TestController.TestInventory(player)
	print("\n=== TEST 7: Inventory Management Test ===")

	-- Create valid items folder
	local validItems = ReplicatedStorage:FindFirstChild("ValidItems")
	if not validItems then
		validItems = Instance.new("Folder")
		validItems.Name = "ValidItems"
		validItems.Parent = ReplicatedStorage

		-- Add test items
		local item1 = Instance.new("StringValue")
		item1.Name = "Sword"
		item1.Parent = validItems

		local item2 = Instance.new("StringValue")
		item2.Name = "Shield"
		item2.Parent = validItems
	end

	-- Initialize player inventory
	InventoryManager.InitPlayer(player)

	-- Test adding valid item
	print("\nTest 1: Adding valid item")
	local success1 = InventoryManager.AddItem(player, "Sword", 1)
	print("Result:", success1 and "✓ Success" or "✗ Failed")

	-- Test adding invalid item
	print("\nTest 2: Adding invalid item")
	local success2 = InventoryManager.AddItem(player, "HackedItem", 1)
	print("Result:", success2 and "✓ Success" or "✗ Failed (Expected)")

	-- Test inventory spam
	print("\nTest 3: Inventory spam detection")
	for i = 1, 15 do
		InventoryManager.AddItem(player, "Shield", 1)
		wait(0.01)
	end
	print("Check console for spam detection")

	-- Get inventory
	print("\nTest 4: Get inventory")
	local inventory = InventoryManager.GetInventory(player)
	print("Player inventory:")
	for itemId, quantity in pairs(inventory) do
		print("-", itemId, "x", quantity)
	end

	print("TEST 7 COMPLETED\n")
end

-- Test 8: Jump Power Exploit
function TestController.TestJumpHack(player)
	print("\n=== TEST 8: Jump Power Exploit Test ===")

	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")

	print("Normal JumpPower:", humanoid.JumpPower)

	-- Simulate jump hack
	wait(1)
	print("Simulating jump power hack...")
	humanoid.JumpPower = 200

	wait(2)
	print("Current JumpPower:", humanoid.JumpPower)
	print("Should be reset to 50 by anti-cheat")
	print("TEST 8 COMPLETED\n")
end

-- Run all tests
function TestController.RunAllTests(player)
	print("\n" .. string.rep("=", 50))
	print("STARTING COMPREHENSIVE ANTI-CHEAT TESTS")
	print("Player:", player.Name)
	print(string.rep("=", 50))

	-- Run tests sequentially
	TestController.TestLegitimateRemote(player)
	wait(2)

	TestController.TestRateLimit(player)
	wait(3)

	TestController.TestInvalidArguments(player)
	wait(2)

	TestController.TestStatValidation(player)
	wait(2)

	TestController.TestInventory(player)
	wait(2)

	TestController.TestSpeedHack(player)
	wait(3)

	TestController.TestJumpHack(player)
	wait(3)

	TestController.TestTeleport(player)
	wait(2)

	print("\n" .. string.rep("=", 50))
	print("ALL TESTS COMPLETED")
	print(string.rep("=", 50) .. "\n")
end

-- Auto-run tests when player joins
Players.PlayerAdded:Connect(function(player)
	wait(2) -- Wait for character to load

	-- Only run tests in Studio
	if game:GetService("RunService"):IsStudio() then
		print("Detected Studio environment - Running tests for", player.Name)
		TestController.RunAllTests(player)
	end
end)

return TestController