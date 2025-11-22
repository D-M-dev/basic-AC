-- ServerScriptService/AntiCheatSystem/StatValidator
local StatValidator = {}
local Config = require(script.Parent.Config)
local Logger = require(script.Parent.Logger)

local PlayerStats = {}

-- Initialize player stats tracking
function StatValidator.InitPlayer(player)
	PlayerStats[player.UserId] = {
		Money = 0,
		Level = 1,
		Experience = 0,
		LastUpdate = tick(),
		ChangeHistory = {}
	}
end

-- Validate stat change (server-side only)
function StatValidator.ValidateStatChange(player, statName, oldValue, newValue, source)
	if Config.WHITELISTED_USERS[player.UserId] then return true end

	local userId = player.UserId
	local currentTime = tick()

	-- Calculate change rate
	local change = math.abs(newValue - oldValue)
	local timeDelta = currentTime - PlayerStats[userId].LastUpdate

	if timeDelta < 0.1 then timeDelta = 0.1 end -- Prevent division by zero

	local changeRate = change / timeDelta

	-- Check for suspicious changes
	if changeRate > Config.MAX_STAT_CHANGE_PER_SECOND then
		Logger.LogSuspiciousActivity(player, "Suspicious stat change detected", {
			Stat = statName,
			OldValue = oldValue,
			NewValue = newValue,
			ChangeRate = changeRate,
			Source = source
		})

		return false
	end

	-- Validate specific stats
	if statName == "Money" then
		-- Money can only increase through specific methods
		if newValue < oldValue and source ~= "Purchase" then
			Logger.LogSuspiciousActivity(player, "Unauthorized money decrease", {
				OldValue = oldValue,
				NewValue = newValue
			})
			return false
		end

		-- Check for money overflow
		if newValue > 1000000000 then -- 1 billion cap
			Logger.LogSuspiciousActivity(player, "Money overflow detected", {
				Value = newValue
			})
			return false
		end
	end

	-- Update tracking
	PlayerStats[userId].LastUpdate = currentTime
	table.insert(PlayerStats[userId].ChangeHistory, {
		Stat = statName,
		Change = change,
		Time = currentTime
	})

	-- Keep history limited
	if #PlayerStats[userId].ChangeHistory > 50 then
		table.remove(PlayerStats[userId].ChangeHistory, 1)
	end

	return true
end

-- Safe stat modification function
function StatValidator.ModifyStat(player, statName, amount, source)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return false end

	local stat = leaderstats:FindFirstChild(statName)
	if not stat then return false end

	local oldValue = stat.Value
	local newValue = oldValue + amount

	-- Validate before applying
	if StatValidator.ValidateStatChange(player, statName, oldValue, newValue, source) then
		stat.Value = newValue
		return true
	else
		-- Revert if invalid
		Logger.LogSuspiciousActivity(player, "Stat change rejected", {
			Stat = statName,
			AttemptedChange = amount,
			Source = source
		})
		return false
	end
end

-- Currency transaction system (secure)
function StatValidator.ProcessTransaction(player, amount, transactionType, itemName)
	if amount <= 0 then return false end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return false end

	local moneyStat = leaderstats:FindFirstChild("Money")
	if not moneyStat then return false end

	-- Validate transaction
	if transactionType == "Purchase" then
		if moneyStat.Value < amount then
			return false -- Insufficient funds
		end

		-- Deduct money
		return StatValidator.ModifyStat(player, "Money", -amount, "Purchase: " .. itemName)
	elseif transactionType == "Earn" then
		-- Add money
		return StatValidator.ModifyStat(player, "Money", amount, "Earn: " .. itemName)
	end

	return false
end

return StatValidator