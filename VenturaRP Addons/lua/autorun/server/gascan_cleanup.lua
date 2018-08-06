--Clean up fires parented to dead players

local function PlayerDeath( pl )
	local k, v
	
	for k, v in ipairs( ents.FindByClass( "env_fire" ) ) do
		if v:GetParent( ) == pl then
			SafeRemoveEntity( v )
		end
	end
end

hook.Add( "PlayerDeath", "Gas Can - Player Death", PlayerDeath )