-- ServerScriptService/AntiCheatSystem/MovementCheck
local MovementCheck = {}
local Config = require(script.Parent.Config)
local Logger = require(script.Parent.Logger)

local PlayerData = {}

-- Initialize player tracking
function MovementCheck.InitPlayer(player)
	PlayerData[player.UserId] = {
		LastPosition = nil,
		LastCheckTime = tick(),
		VelocityHistory = {},
		Violations = 0
	}

	-- Monitor character spawning
	player.CharacterAdded:Connect(function(character)
		MovementCheck.MonitorCharacter(player, character)
	end)

	if player.Character then
		MovementCheck.MonitorCharacter(player, player.Character)
	end
end

-- Monitor character movement
function MovementCheck.MonitorCharacter(player, character)
	local humanoid = character:WaitForChild("Humanoid", 5)
	local rootPart = character:WaitForChild("HumanoidRootPart", 5)

	if not humanoid or not rootPart then return end

	-- Check speed continuously
	spawn(function()
		while character.Parent and player.Parent do
			wait(0.5) -- Check every 0.5 seconds

			if Config.WHITELISTED_USERS[player.UserId] then continue end

			-- Speed check
			local velocity = rootPart.Velocity
			local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude

			if speed > Config.MAX_SPEED then
				MovementCheck.HandleViolation(player, "Speed hack detected", {
					Speed = speed,
					MaxSpeed = Config.MAX_SPEED
				})
			end

			-- Position desync check
			if PlayerData[player.UserId].LastPosition then
				local distance = (rootPart.Position - PlayerData[player.UserId].LastPosition).Magnitude
				local timeDelta = tick() - PlayerData[player.UserId].LastCheckTime
				local calculatedSpeed = distance / timeDelta

				-- Check for teleportation
				if calculatedSpeed > Config.MAX_SPEED * 2 and timeDelta < 1 then
					MovementCheck.HandleViolation(player, "Teleport detected", {
						Distance = distance,
						TimeDelta = timeDelta
					})
				end
			end

			-- Update tracking data
			PlayerData[player.UserId].LastPosition = rootPart.Position
			PlayerData[player.UserId].LastCheckTime = tick()
		end
	end)

	-- Jump power check
	humanoid.Changed:Connect(function(property)
		if property == "JumpPower" or property == "JumpHeight" then
			if humanoid.JumpPower > 50 or humanoid.JumpHeight > Config.MAX_JUMP_HEIGHT then
				MovementCheck.HandleViolation(player, "Jump exploit detected", {
					JumpPower = humanoid.JumpPower,
					JumpHeight = humanoid.JumpHeight
				})

				-- Reset to default
				humanoid.JumpPower = 50
				humanoid.JumpHeight = 7.2
			end
		end

		if property == "WalkSpeed" then
			if humanoid.WalkSpeed > 16 then
				MovementCheck.HandleViolation(player, "WalkSpeed exploit detected", {
					WalkSpeed = humanoid.WalkSpeed
				})

				-- Reset to default
				humanoid.WalkSpeed = 16
			end
		end
	end)
end

-- Handle violation
function MovementCheck.HandleViolation(player, reason, data)
	if not PlayerData[player.UserId] then return end

	PlayerData[player.UserId].Violations = PlayerData[player.UserId].Violations + 1

	Logger.LogSuspiciousActivity(player, reason, data)

	-- Punishment system
	local violations = PlayerData[player.UserId].Violations

	if violations >= Config.KICK_THRESHOLD then
		player:Kick("Anti-Cheat: " .. reason)
		Logger.LogPunishment(player, "KICK", reason)
	end
end

-- Cleanup on player leave
function MovementCheck.CleanupPlayer(player)
	PlayerData[player.UserId] = nil
end

return MovementCheck