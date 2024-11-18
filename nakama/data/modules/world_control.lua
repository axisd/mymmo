local world_control = {}

function world_control.match_init(context, params)
	local state = {
		presences = {}
	}
	local tick_rate = 10
	local label = "Game world"
	
	return state, tick_rate, label
end

function world_control.match_join_attempt(context, dispatcher, tick, state, presence, metadata)
	if state.presences[presence.user_id] ~= nil then
		return state, false, "User already logged in"
	end
	return state, true
end

function world_control.match_join(context, dispatcher, tick, state, presences)
	for _, presence in ipairs(presences) do
		state.presences[presence.user_id] = presence
	end
	return state
end

function world_control.match_leave(context, dispatcher, tick, state, presences)
	for _, presence in ipairs(presences) do
		state.presences[presence.user_id] = nil
	end
	return state
end

function world_control.match_loop(context, dispatcher, tick, state, messages)
	return state
end

function world_control.match_loop(context, dispatcher, tick, state, grace_seconds)
	return state
end

-- Server is shutting down. Save positions of all existing characters to storage.
function world_control.match_terminate(_, _, _, state, _)
    return state
end

-- Called when the match handler receives a runtime signal.
function world_control.match_signal(_, _, _, state, data)
	return state, data
end

return world_control