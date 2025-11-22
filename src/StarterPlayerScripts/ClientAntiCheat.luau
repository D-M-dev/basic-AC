-- StarterPlayer/StarterPlayerScripts/ClientAntiCheat
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local ReportRemote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("ReportSuspiciousActivity")

-- Detect common exploit characteristics
local function DetectExploits()
	-- Check for unusual GUI elements (executor GUIs)
	local function checkForSuspiciousGuis()
		local playerGui = player:WaitForChild("PlayerGui")

		for _, gui in ipairs(playerGui:GetDescendants()) do
			if gui:IsA("ScreenGui") then
				-- Check for common exploit GUI names
				local suspiciousNames = {"Executor", "Synapse", "KRNL", "Exploit", "Script"}

				for _, name in ipairs(suspiciousNames) do
					if string.find(gui.Name:lower(), name:lower()) then
						ReportRemote:FireServer("Suspicious GUI detected", gui.Name)
						return true
					end
				end
			end
		end

		return false
	end

	-- Check for modified CoreGui (exploiters often hide it)
	local function checkCoreGui()
		local success, result = pcall(function()
			return game:GetService("CoreGui"):GetChildren()
		end)

		if not success then
			ReportRemote:FireServer("CoreGui access blocked", result)
		end
	end

	-- Check for unusual script additions
	local function monitorScriptAdditions()
		player.PlayerScripts.DescendantAdded:Connect(function(descendant)
			if descendant:IsA("LocalScript") or descendant:IsA("Script") then
				-- Check if script was added by the game
				if not descendant:IsDescendantOf(game.StarterPlayer) then
					ReportRemote:FireServer("Unauthorized script detected", descendant.Name)
				end
			end
		end)
	end

	-- Run checks
	spawn(checkForSuspiciousGuis)
	spawn(checkCoreGui)
	spawn(monitorScriptAdditions)
end

-- Monitor for speed modifications
local function MonitorMovement()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")

	-- Expected values
	local NORMAL_WALKSPEED = 16
	local NORMAL_JUMPPOWER = 50

	humanoid.Changed:Connect(function(property)
		if property == "WalkSpeed" then
			if humanoid.WalkSpeed ~= NORMAL_WALKSPEED then
				ReportRemote:FireServer("WalkSpeed modified on client", {
					Old = NORMAL_WALKSPEED,
					New = humanoid.WalkSpeed
				})
			end
		elseif property == "JumpPower" then
			if humanoid.JumpPower ~= NORMAL_JUMPPOWER then
				ReportRemote:FireServer("JumpPower modified on client", {
					Old = NORMAL_JUMPPOWER,
					New = humanoid.JumpPower
				})
			end
		end
	end)
end

-- Initialize
DetectExploits()
player.CharacterAdded:Connect(MonitorMovement)
if player.Character then
	MonitorMovement()
end