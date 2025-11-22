-- ServerScriptService/AntiCheatSystem/Config
local Config = {
	-- Detection limits
	MAX_SPEED = 24, -- Studs per second (default 16 + buffer)
	MAX_JUMP_HEIGHT = 60,
	MAX_REMOTE_CALLS_PER_SECOND = 10,
	MAX_STAT_CHANGE_PER_SECOND = 1000,
	MAX_POSITION_DESYNC = 50, -- Studs

	-- Punishment thresholds
	KICK_THRESHOLD = 3, -- Warnings before kick
	BAN_THRESHOLD = 5, -- Kicks before ban

	-- Logging
	LOG_TO_DATASTORE = false,
	LOG_TO_WEBHOOK = false, -- Discord webhook
	WEBHOOK_URL = "YOUR_DISCORD_WEBHOOK_URL",

	-- Whitelist (for testing)
	WHITELISTED_USERS = {
		[0] = true, -- User IDs
	}
}

return Config