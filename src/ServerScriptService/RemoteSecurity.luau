-- ServerScriptService/AntiCheatSystem/RemoteSecurity
local RemoteSecurity = {}
local Config = require(script.Parent.Config)
local Logger = require(script.Parent.Logger)

-- Rate limiting storage
local RemoteCallTracker = {}
local LastResetTime = {}

-- Sanitize and validate remote calls
function RemoteSecurity.ValidateRemoteCall(player, remoteName, args)
	-- Check if player is valid
	if not player or not player:IsA("Player") then
		Logger.LogSuspiciousActivity(nil, "Invalid player object in remote call", remoteName)
		return false
	end

	-- Rate limiting
	if not RemoteSecurity.CheckRateLimit(player, remoteName) then
		Logger.LogSuspiciousActivity(player, "Rate limit exceeded", remoteName)
		return false
	end

	-- Validate arguments (prevent injection attacks)
	for i, arg in ipairs(args) do
		if not RemoteSecurity.ValidateArgument(arg) then
			Logger.LogSuspiciousActivity(player, "Invalid argument detected", remoteName)
			return false
		end
	end

	return true
end

-- Rate limiting system
function RemoteSecurity.CheckRateLimit(player, remoteName)
	local userId = player.UserId
	local currentTime = tick()

	-- Initialize tracker
	if not RemoteCallTracker[userId] then
		RemoteCallTracker[userId] = {}
		LastResetTime[userId] = currentTime
	end

	if not RemoteCallTracker[userId][remoteName] then
		RemoteCallTracker[userId][remoteName] = 0
	end

	-- Reset counter every second
	if currentTime - LastResetTime[userId] >= 1 then
		RemoteCallTracker[userId] = {}
		LastResetTime[userId] = currentTime
	end

	-- Check limit
	RemoteCallTracker[userId][remoteName] = RemoteCallTracker[userId][remoteName] + 1

	if RemoteCallTracker[userId][remoteName] > Config.MAX_REMOTE_CALLS_PER_SECOND then
		return false
	end

	return true
end

-- Validate individual arguments
function RemoteSecurity.ValidateArgument(arg)
	local argType = typeof(arg)

	-- Check for dangerous types
	if argType == "Instance" then
		-- Only allow specific instance types
		local allowedClasses = {
			"Part", "MeshPart", "Tool", "Model"
		}

		local isAllowed = false
		for _, class in ipairs(allowedClasses) do
			if arg:IsA(class) then
				isAllowed = true
				break
			end
		end

		return isAllowed
	end

	-- Prevent extremely large strings (potential memory attacks)
	if argType == "string" and #arg > 10000 then
		return false
	end

	-- Prevent NaN and Inf numbers
	if argType == "number" then
		if arg ~= arg or math.abs(arg) == math.huge then
			return false
		end
	end

	return true
end

-- Secure RemoteEvent wrapper (FIXED)
function RemoteSecurity.CreateSecureRemoteEvent(name, callback)
	local remoteEvent = Instance.new("RemoteEvent")
	remoteEvent.Name = name
	remoteEvent.Parent = game.ReplicatedStorage:WaitForChild("RemoteEvents")

	remoteEvent.OnServerEvent:Connect(function(player, ...)
		-- Capture varargs into a table
		local args = {...}

		-- Validate the call
		if not RemoteSecurity.ValidateRemoteCall(player, name, args) then
			Logger.LogSuspiciousActivity(player, "Failed remote validation", name)
			return
		end

		-- Execute callback with unpacked args
		local success, errorMsg = pcall(function()
			callback(player, table.unpack(args))
		end)

		if not success then
			Logger.LogError(player, "Remote callback error: " .. tostring(errorMsg), name)
		end
	end)

	return remoteEvent
end

-- Secure RemoteFunction wrapper (FIXED)
function RemoteSecurity.CreateSecureRemoteFunction(name, callback)
	local remoteFunction = Instance.new("RemoteFunction")
	remoteFunction.Name = name
	remoteFunction.Parent = game.ReplicatedStorage:WaitForChild("RemoteFunctions")

	remoteFunction.OnServerInvoke = function(player, ...)
		-- Capture varargs into a table
		local args = {...}

		-- Validate the call
		if not RemoteSecurity.ValidateRemoteCall(player, name, args) then
			Logger.LogSuspiciousActivity(player, "Failed remote validation", name)
			return nil
		end

		-- Execute callback with unpacked args
		local success, result = pcall(function()
			return callback(player, table.unpack(args))
		end)

		if not success then
			Logger.LogError(player, "Remote callback error: " .. tostring(result), name)
			return nil
		end

		return result
	end

	return remoteFunction
end

return RemoteSecurity