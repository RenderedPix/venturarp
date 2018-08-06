--** This addon has been designed by Mohamed RACHID
--** It allows to know the complete list of loading players and every player including loading ones.
--** You can use these new functions in your gamemode: player.GetAny() and player.GetLoading(). For players connected since a previous map only, the results will only be correct when the gamemode has finished starting; you can use the property player.AllConnectedLoaded to check if you can trust the result. You can use matching console commands "player_getany" (similar to the command "users") and "player_getloading" to see the results.
--** You can call the method element:GetPlayerEnt() on each element of the returned tables. If the player has finished loading it returns the player entity, else it returns nil. You can simply use an IsValid() check on the result.
--** You can hook the shared event "OnReloadAllConnected". For example, you can add a hook clientside to refresh the scoreboard.
--** The client gets the full nicknames except after a change, and receives nothing if the changes are only over the 31 first bytes. This is not a problem in the joined scoreboard.


--x Faire un hook pour OnReloadAllConnected.
--? Ne plus utiliser de service externe pour la localisation du serveur : game.GetIPAddress()
--? Faire un cache qui utilise l'adresse IP comme clé, c'est plus pertinent.
--- Indexer player.AllConnected par UserID et optimiser tout le bazar.
--- Modifier l'obtention du nom complet du joueur (ConVar "name" sans limitation à 31 octets). Vérifier pour cela si les méthodes sont bien issues du C et traiter aussi DarkRP Player:SteamName(). Vérifier que les 31 premiers octets concordent pour autoriser l'affichage.
	-- http://wiki.garrysmod.com/page/Player/GetName
	-- http://wiki.garrysmod.com/page/Player/Name
	-- http://wiki.garrysmod.com/page/Player/Nick
--- Limiter l'utilisation de la bibliothèque player à ce qui est utilisé couramment par les scripts extérieurs.
--- Modify the Player metatable to give an easy access to the Player Data.


local function MethodGetPlayerEnt( self )
	local ply = Player( self.userid )
	return IsValid( ply ) and ply or nil -- nil if player entity does not exist yet
end
local function SetMethodGetPlayerEnt( data )
	data.GetPlayerEnt = MethodGetPlayerEnt
end


function player.Nick31MatchesFullNick( Nick1, Nick2 )
	if not Nick1 or not Nick2 then
		return false
	elseif string.sub( Nick1, 1, 31 )==string.sub( Nick2, 1, 31 ) then
		return true
	else
		return false
	end
end


if SERVER then -- serverside
	if not player.AllConnected then
		player.AllConnected = {}
		player.PendingDisconnected = {}
		player.AllConnectedLoaded = false
		player.AllConnectedLastUpdate = CurTime()
		CreateConVar( "pgl_connected_list_crc", "notset", 0, "CRC of the last saved connected_list.txt. Do not touch!" )
	end
	if not player.FullNicknames then
		player.FullNicknames = {}
	end
	
	if not geoip then
		include( "ip2location.lua" )
	end
	
	
	AddCSLuaFile()
	
	
	-- We send info when people join or disconnect, but also when a player just finishes loading + every 5 seconds if a change occurred (the client sends a query).
	-- Send info to client(s)
	util.AddNetworkString( "SendAnyPlayerList" )
	function player.SendAnyPlayerList( ply )
		net.Start( "SendAnyPlayerList" )
		net.WriteUInt( #player.AllConnected, 8 )
		if #player.AllConnected>0 then
			for i=1,#player.AllConnected do
				if player.AllConnected[i].index then
					net.WriteUInt( player.AllConnected[i].index, 32 )
				else
					net.WriteUInt( 2147483647, 32 )
				end
				net.WriteUInt( player.AllConnected[i].bot, 1 )
				net.WriteString( player.AllConnected[i].networkid )
				net.WriteString( player.AllConnected[i].name )
				net.WriteUInt( player.AllConnected[i].userid, 32 )
				local ip_info = geoip.GetIpInfo( player.AllConnected[i].address )
				if ip_info and ip_info[geoip.country_code] then
					net.WriteString( ip_info[geoip.country_code] )
				else
					net.WriteString( "" )
				end
			end
		end
		net.WriteFloat( player.AllConnectedLastUpdate )
		if not ply then
			net.Broadcast()
		else
			net.Send( ply )
		end
	end
	-- Receive queries
	util.AddNetworkString( "GetAnyPlayerList" )
	net.Receive( "GetAnyPlayerList", function( length, client )
		if net.ReadFloat()<player.AllConnectedLastUpdate then -- never twice
			player.SendAnyPlayerList( client )
		end
	end )
	
	
	-- Record full nicknames (not limited to 31 bytes) by Steam ID
	hook.Add( "CheckPassword", "player_getloading_1", function( steamid64, networkid, server_password, password, name )
		player.FullNicknames[util.SteamIDFrom64( tostring( steamid64 ) )] = name
	end )
	
	
	gameevent.Listen("player_connect")
	hook.Add( "player_connect", "player_getloading_2", function(data)
		SetMethodGetPlayerEnt(data)
		
		if player.Nick31MatchesFullNick(data.name, player.FullNicknames[data.networkid]) then
			data.name = player.FullNicknames[data.networkid]
		end
		table.insert( player.AllConnected, data )
		player.AllConnectedLastUpdate = CurTime()
		player.SendAnyPlayerList()
		hook.Run( "OnReloadAllConnected" )
	end )
	
	
	gameevent.Listen( "player_disconnect" )
	hook.Add( "player_disconnect", "player_getloading_3", function(data)
		if #player.AllConnected>0 then
			for i=#player.AllConnected,1,-1 do
				if player.AllConnected[i].networkid == data.networkid then
					table.remove( player.AllConnected, i )
					player.AllConnectedLastUpdate = CurTime()
					player.SendAnyPlayerList()
					hook.Run( "OnReloadAllConnected" )
					return
				end
			end
		end
		player.PendingDisconnected[#player.PendingDisconnected+1] = data
	end )
	
	
	local function TryGetSavedList()
		if not player.AllConnectedLoaded then
			if file.Exists( "connected_list.txt", "DATA" ) then
				local connected_list_crc_str = GetConVarString( "pgl_connected_list_crc" )
				
				if connected_list_crc_str=="notset" or string.len( connected_list_crc_str )==0 then -- no CRC
					-- MsgN("The list of connected players does not exist yet or was certainly empty.")
				else
					if connected_list_crc_str=="r0" then connected_list_crc_str="0" end
					local import_string = file.Read( "connected_list.txt", "DATA" )
					local import_string_crc_str = tostring( util.CRC( import_string ) )
					if import_string_crc_str==connected_list_crc_str then -- load data from previous map
						if string.len( import_string )>0 then
							RunStringEx( import_string, "importing connected_list.txt" )
						end
						-- Now we remove pending deleted users. This has to be done because the list is loaded after the engine began to listen to quitting players. Players might trigger the player_disconnect before the saved list of connected players has been imported.
						if #player.PendingDisconnected>0 and #player.AllConnected>0 then
							local modified = false
							for i=#player.PendingDisconnected,1,-1 do
								local data = table.remove( player.PendingDisconnected, i )
								for j=#player.AllConnected,1,-1 do
									if data.networkid==player.AllConnected[j].networkid then
										table.remove( player.AllConnected, j )
										modified = true
									end
								end
							end
							if modified then
								player.AllConnectedLastUpdate = CurTime()
								player.SendAnyPlayerList()
								hook.Run( "OnReloadAllConnected" )
							end
						end
						-- Now we set again the method element:GetPlayerEnt(), which cannot be saved.
						for _,data in ipairs( player.AllConnected ) do
							SetMethodGetPlayerEnt( data )
						end
						player.AllConnectedLoaded = true
						-- MsgN("The list of connected players has been imported.")
					else -- CRC does not match with the file
						player.AllConnectedLoaded = true
						MsgN( "The list of connected players was old or invalid! (Write error?)" )
					end
				end
			else -- The file does not exist
				RunConsoleCommand( "pgl_connected_list_crc", "nofile" )
				player.AllConnectedLoaded = true
				-- Msg("The list of connected players has never been created.")
			end
		end
	end
	if not player.AllConnectedLoaded then
		timer.Simple( 0.001, function ()
			-- This has to be delayed in order to make the actual ConVar value available (instead of the default value).
			TryGetSavedList()
		end )
	end
	
	
	hook.Add( "ShutDown", "player_getloading_4", function()
		local export_res
		local export_string = ""
		
		for _,data in ipairs( player.AllConnected ) do
			if data.bot~=1 then
				data.GetPlayerEnt = nil
				export_string = export_string..table.ToString( data, "player.AllConnected[#player.AllConnected+1]", false ).."\t" -- Never use \n because when writing as text file under Windows it will read back \r\n instead, so the CRC won't be valid.
			end
		end
		
		export_res = file.Open( "connected_list.txt", "w", "DATA" )
			export_res:Write( export_string )
		export_res:Close()
		
		local export_CRC = tostring( util.CRC( export_string ) )
		if export_CRC=="0" then export_CRC = "r0" end -- this escape is needed to force the value to be seen as not default
		RunConsoleCommand( "pgl_connected_list_crc", export_CRC )
	end )
	
	
	
	hook.Add( "PlayerAuthed", "player_getloading_5", function( ply, SteamID, UniqueID )
		-- Is executed to avoid the should-never-happen case where the player_connect hook has not been triggered and the player's data have not been loaded from the saved list.
		-- This is ignored in single player mode because the data.networkid field is set to "" while the SteamID is "STEAM_0:0:0". That will cause to have a double user in the list.
		if not game.SinglePlayer() then
			if #player.AllConnected>0 then
				for i=1,#player.AllConnected do
					if player.AllConnected[i].networkid==SteamID then
						return -- The new player is already in the player.AllConnected list: okay.
					end
				end
			end
			
			-- Horrible case: the player has not been added to the player.AllConnected list. We add him.
			local IsBot = 0
			if ply:IsBot() then IsBot = 1 end
			local data = {}
			data.address = ply:IPAddress()
			data.index = nil -- unknown value; if absent you know that the engine went here
			data.bot = IsBot
			data.networkid = SteamID
			local Name = ply:GetName()
			if player.Nick31MatchesFullNick( Name, player.FullNicknames[SteamID] ) then
				data.name = player.FullNicknames[data.networkid]
			else
				data.name = Name
			end
			data.userid = ply:UserID()
			SetMethodGetPlayerEnt(data)
			player.AllConnected[#player.AllConnected+1] = data
			player.AllConnectedLastUpdate = CurTime()
			player.SendAnyPlayerList()
			hook.Run( "OnReloadAllConnected" )
		end
		
		-- The saved list is loaded a final time here (to ensure if ever the timer is not long enough, the list will be loaded anyway).
		TryGetSavedList()
	end )
	
	
	hook.Add( "Think", "player_getloading_7", function()
		local ply
		local data
		for _,data in ipairs( player.AllConnected ) do
			local ply = data:GetPlayerEnt()
			if ply then
				if not player.Nick31MatchesFullNick( ply:GetName(), data.name ) then
					data.name = ply:GetName()
				end
			end
		end
	end )
	
	
	util.AddNetworkString( "pgl_UpdateNick" )
	net.Receive( "pgl_UpdateNick", function( length, ply )
		if #player.AllConnected>0 then
			local UserID = ply:UserID()
			for _,data in ipairs( player.AllConnected ) do
				if UserID==data.userid then
					local Nick = net.ReadString()
					if string.len( Nick )>0 then
						data.name = Nick
						-- send the update to clients
						net.Start( "pgl_UpdateNick" )
							net.WriteUInt( data.userid, 32 )
							net.WriteString( data.name )
						net.Broadcast()
					end
					break
				end
			end
		end
	end )
	
	
else -- clientside
	if not player.AllConnected then
		player.AllConnected = {}
		player.AllConnectedLastUpdate = 0.0 -- this timestamp is only sent by the server to avoid time offset error
	end
	
	
	-- Send update query
	local function GetAnyPlayerList()
		net.Start( "GetAnyPlayerList" )
			net.WriteFloat( player.AllConnectedLastUpdate )
		net.SendToServer()
	end
	GetAnyPlayerList()
	timer.Create( "UpdateAnyPlayerList", 5, 0, function()
		GetAnyPlayerList()
	end )
	
	
	-- Update the player list when the server sends it
	net.Receive( "SendAnyPlayerList", function()
		local count = net.ReadUInt( 8 )
		local AllConnected = {}
		if count>0 then
			for i=1,count do
				local data = {}
				data.address = "none" -- hidden IP address
				data.index = net.ReadUInt( 32 )
				if data.index==2147483647 then
					data.index = nil -- in case of unknown index
				end
				data.bot = net.ReadUInt( 1 )
				data.networkid = net.ReadString()
				data.name = net.ReadString()
				data.userid = net.ReadUInt( 32 )
				data.country = net.ReadString() -- does not exist serverside
				if string.len( data.country )==0 then
					data.country = nil
				end
				SetMethodGetPlayerEnt( data ) -- We set again the method element:GetPlayerEnt(), which cannot be transmitted.
				AllConnected[i] = data
			end
		end
		player.AllConnected = AllConnected
		player.AllConnectedLastUpdate = net.ReadFloat()
		
		hook.Run( "OnReloadAllConnected" )
		local ply = LocalPlayer()
		if IsValid( ply.newscoreboard ) then
			ply.newscoreboard:Update( true )
		end
	end )
	
	
	-- This stuff is designed to send to the server the full nickname instead of the 31 bytes nickname (due to networked version of ConVars). Stay aware because a LUA cheaters can send undesired values.
	cvars.AddChangeCallback( "name", function( convar, oldValue, newValue )
		net.Start( "pgl_UpdateNick" )
			net.WriteString( newValue )
		net.SendToServer()
	end, "pgl_UpdateNick" )
	-- This is the next step: the client receives the updated nickname of any player.
	net.Receive( "pgl_UpdateNick", function( length, client )
		if #player.AllConnected>0 then
			local UserID = net.ReadUInt( 32 )
			for _,data in ipairs( player.AllConnected ) do
				if UserID==data.userid then
					data.name = net.ReadString()
					break
				end
			end
		end
	end )
end


function player.GetAny()
	return player.AllConnected
end
concommand.Add( "player_getany", function()
	MsgN( "Connected players:\n"..table.ToString( player.GetAny(), "player.GetAny()", true ) )
end, nil, "Displays every player including joining ones." )


function player.GetLoading()
	local loading = {}
	for _,data in ipairs( player.AllConnected ) do
		if data.bot~=1 and not data:GetPlayerEnt() then -- human with no player entity
			table.insert( loading, data )
		end
	end
	return loading
end
concommand.Add( "player_getloading", function()
	MsgN( "Players that are joining:\n"..table.ToString( player.GetLoading(), "player.GetLoading()", true ) )
end, nil, "Displays joining players." )
