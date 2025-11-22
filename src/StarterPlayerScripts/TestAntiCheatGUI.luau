-- StarterGui/TestAntiCheatGUI
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AntiCheatTestGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Main frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 400)
mainFrame.Position = UDim2.new(1, -320, 0, 20)
mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- Add corner
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = mainFrame

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
title.BorderSizePixel = 0
title.Text = "Anti-Cheat Tests"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = title

-- Scroll frame for buttons
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -20, 1, -60)
scrollFrame.Position = UDim2.new(0, 10, 0, 50)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 6
scrollFrame.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 10)
listLayout.Parent = scrollFrame

-- Helper function to create buttons
local function createButton(name, callback)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 40)
	button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	button.BorderSizePixel = 0
	button.Text = name
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.Gotham
	button.TextSize = 14
	button.Parent = scrollFrame

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = button

	button.MouseButton1Click:Connect(callback)

	-- Hover effect
	button.MouseEnter:Connect(function()
		button.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	end)

	button.MouseLeave:Connect(function()
		button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	end)

	return button
end

-- Wait for RemoteEvents folder
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not remoteEvents then
	warn("RemoteEvents folder not found!")
	return
end

-- Test 1: Speed Hack
createButton("Test Speed Hack", function()
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid then
			print("CLIENT: Setting WalkSpeed to 100")
			humanoid.WalkSpeed = 100

			wait(2)
			print("CLIENT: Current WalkSpeed:", humanoid.WalkSpeed)
		end
	end
end)

-- Test 2: Jump Hack
createButton("Test Jump Hack", function()
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid then
			print("CLIENT: Setting JumpPower to 200")
			humanoid.JumpPower = 200

			wait(2)
			print("CLIENT: Current JumpPower:", humanoid.JumpPower)
		end
	end
end)

-- Test 3: Teleport
createButton("Test Teleport", function()
	local character = player.Character
	if character then
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if rootPart then
			print("CLIENT: Teleporting 500 studs")
			rootPart.CFrame = rootPart.CFrame + Vector3.new(500, 0, 0)
		end
	end
end)

-- Test 4: Remote Spam
createButton("Test Remote Spam", function()
	print("CLIENT: Spamming remote calls")

	local testRemote = remoteEvents:FindFirstChild("PurchaseItem")
	if testRemote then
		for i = 1, 20 do
			testRemote:FireServer("TestItem", 1)
			wait(0.05)
		end
		print("CLIENT: Sent 20 rapid calls")
	else
		warn("PurchaseItem remote not found")
	end
end)

-- Test 5: Invalid Arguments
createButton("Test Invalid Args", function()
	print("CLIENT: Sending invalid arguments")

	local testRemote = remoteEvents:FindFirstChild("PurchaseItem")
	if testRemote then
		-- Send invalid data
		testRemote:FireServer(string.rep("A", 20000), -1)
		testRemote:FireServer(math.huge, math.huge)
		testRemote:FireServer(0/0, nil) -- NaN

		print("CLIENT: Sent invalid arguments")
	end
end)

-- Test 6: Fly Hack (Velocity Change)
createButton("Test Fly Hack", function()
	local character = player.Character
	if character then
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if rootPart then
			print("CLIENT: Simulating fly hack")

			local bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.Velocity = Vector3.new(0, 50, 0)
			bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
			bodyVelocity.Parent = rootPart

			wait(3)
			bodyVelocity:Destroy()
			print("CLIENT: Fly hack simulation ended")
		end
	end
end)

-- Test 7: Normal Purchase (Should Work)
createButton("Test Valid Purchase", function()
	print("CLIENT: Making legitimate purchase")

	local testRemote = remoteEvents:FindFirstChild("PurchaseItem")
	if testRemote then
		testRemote:FireServer("Sword", 1)
		print("CLIENT: Purchase request sent")
	end
end)

-- Test 8: Reset Character
createButton("Reset Character", function()
	if player.Character then
		player.Character:FindFirstChild("Humanoid").Health = 0
	end
end)

-- Test 9: Report Suspicious Activity
createButton("Report Test", function()
	local reportRemote = remoteEvents:FindFirstChild("ReportSuspiciousActivity")
	if reportRemote then
		reportRemote:FireServer("Test report from client", {TestData = "Example"})
		print("CLIENT: Test report sent")
	end
end)

-- Adjust scroll frame size
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end)

print("Anti-Cheat Test GUI loaded!")