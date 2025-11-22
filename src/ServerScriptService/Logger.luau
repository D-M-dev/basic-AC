-- ServerScriptService/AntiCheatSystem/Logger
local Logger = {}
local HttpService = game:GetService("HttpService")
local DataStoreService = game:GetService("DataStoreService")
local Config = require(script.Parent.Config)

local LogDataStore = DataStoreService:GetDataStore("AntiCheatLogs")

-- Log suspicious activity
function Logger.LogSuspiciousActivity(player, reason, data)
	local logEntry = {
		UserId = player and player.UserId or "Unknown",
		Username = player and player.Name or "Unknown",
		Reason = reason,
		Data = data,
		Timestamp = os.time(),
		DateTime = os.date("%Y-%m-%d %H:%M:%S")
	}

	-- Print to console
	warn("[ANTI-CHEAT]", player and player.Name or "Unknown", "-", reason)

	-- Save to DataStore
	if Config.LOG_TO_DATASTORE then
		pcall(function()
			local key = "Log_" .. os.time() .. "_" .. math.random(1000, 9999)
			LogDataStore:SetAsync(key, logEntry)
		end)
	end

	-- Send to Discord webhook
	if Config.LOG_TO_WEBHOOK and Config.WEBHOOK_URL ~= "" then
		Logger.SendToDiscord(logEntry)
	end
end

-- Log punishment
function Logger.LogPunishment(player, punishmentType, reason)
	local logEntry = {
		UserId = player.UserId,
		Username = player.Name,
		PunishmentType = punishmentType,
		Reason = reason,
		Timestamp = os.time(),
		DateTime = os.date("%Y-%m-%d %H:%M:%S")
	}

	warn("[ANTI-CHEAT] PUNISHMENT:", punishmentType, "-", player.Name, "-", reason)

	if Config.LOG_TO_DATASTORE then
		pcall(function()
			local key = "Punishment_" .. player.UserId .. "_" .. os.time()
			LogDataStore:SetAsync(key, logEntry)
		end)
	end

	if Config.LOG_TO_WEBHOOK and Config.WEBHOOK_URL ~= "" then
		Logger.SendToDiscord(logEntry, true)
	end
end

-- Send log to Discord
function Logger.SendToDiscord(logEntry, isPunishment)
	spawn(function()
		local success, result = pcall(function()
			local embed = {
				title = isPunishment and "🔨 Anti-Cheat Punishment" or "⚠️ Suspicious Activity",
				color = isPunishment and 16711680 or 16776960, -- Red for punishment, Yellow for suspicious
				fields = {
					{
						name = "Player",
						value = logEntry.Username .. " (" .. logEntry.UserId .. ")",
						inline = true
					},
					{
						name = "Reason",
						value = logEntry.Reason or "N/A",
						inline = true
					},
					{
						name = "Time",
						value = logEntry.DateTime,
						inline = true
					}
				},
				footer = {
					text = "Anti-Cheat System"
				}
			}

			-- Add additional data
			if logEntry.Data then
				local dataString = HttpService:JSONEncode(logEntry.Data)
				table.insert(embed.fields, {
					name = "Additional Data",
					value = "```json\n" .. dataString .. "```",
					inline = false
				})
			end

			local payload = HttpService:JSONEncode({
				embeds = {embed}
			})

			HttpService:PostAsync(Config.WEBHOOK_URL, payload, Enum.HttpContentType.ApplicationJson)
		end)

		if not success then
			warn("[Logger] Failed to send to Discord:", result)
		end
	end)
end

-- General logging
function Logger.LogActivity(player, activity, data)
	print("[ANTI-CHEAT]", player.Name, "-", activity, data and HttpService:JSONEncode(data) or "")
end

-- Error logging
function Logger.LogError(player, errorMsg, context)
	warn("[ANTI-CHEAT ERROR]", player and player.Name or "System", "-", errorMsg, "-", context or "")
end

return Logger