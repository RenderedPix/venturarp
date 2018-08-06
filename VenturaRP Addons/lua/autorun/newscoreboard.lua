--** To use this new generic scoreboard, you need to have the player_getloading addon installed. It won't run standalone.
--** To disable it, you need to add in your server.cfg the line: pgl_newscoreboard "0"
--** It can be used correctly if your gamemode uses the standard scoreboard. It may also be usable in some gamemodes that do not use the default scoreboard, depending on the way it is displayed.
--** If you do not need this new scoreboard, you can simply delete this file.

--- Add teams in the information box.
--- Add hooks to override text and background colors for each player.
--- Add a default hook for the terrortown gamemode with standard colors. Add a hook to fake the status.
--- Add hooks to change the order.
--- Allow the order by teams, with titles or not + choice of order by status.
--- Add hooks for everything: status, team, name.
	-- http://wiki.garrysmod.com/page/team/GetName
--- Add title for statuses.
--- Add admin commands in a menu for each player (kick, ban, slay) (kick and ban will use ULX/Evolve/Assmod/FAdmin).
--- Add customizable events: left click and right click on player's nick label.
--- Add the ability for admins to hide players through chat commands. They have not to be shown at all by the functions (customizable authorizations: 0 = nobody, 1 = everybody, 2 = administrators, 3 = super administrators).
--- Allow admins to replace players' nicknames on the fly, not only on scoreboard (customizable authorizations: 0 = nobody, 1 = everybody, 2 = administrators, 3 = super administrators).
--- Change the text color for the local player. This will help to see yourself easily.
--- Bords arrondis.
--- Illuminer la photo et le drapeau pour mieux les distinguer en passant la souris par-dessus.
--- Add a button (with a ConVar parameter) to roll back to the old ScoreBoard once.
--- Put the creation of the display hook in a hook (1st player created): DarkRP, etc.
--- Ajouter une mise en surbrillance sur soi-même.


local AddNetworkedConVar
if SERVER then
	function AddNetworkedConVar( name, value, flags, helptext )
		CreateConVar( name, value, flags, helptext )
		hook.Add( "OnEntityCreated", "NetworkedConVar_"..name, function( ply ) -- delayed to get the right value for the ConVar
			if IsValid( ply ) and ply:IsPlayer() then
				SetGlobalString( name, GetConVarString( name ) )
			end
		end )
		cvars.AddChangeCallback( name, function()
			SetGlobalString( name, GetConVarString( name ) )
		end )
	end
	-- We prepare to send the parameter for the client to know if it should display the new scoreboard. It cannot be synchronized with the client when declared here, so we use a global string instead.
	AddNetworkedConVar( "pgl_newscoreboard", "1", FCVAR_ARCHIVE, "Whether to use the player_getloading scoreboard or not." )
	
	local ConVarList = nil
	local function ForceReloadConfig( ConVarToLoad )
		if not ConVarToLoad or string.len( ConVarToLoad )==0 then return end
		
		if not ConVarList then
			local configlistpart1 = ""
			configlistpart1 = file.Read("cfg/server.cfg", "MOD")
			if not configlistpart1 then
				configlistpart1 = ""
			end
			local configlistpart2 = ""
			configlistpart2 = file.Read("cfg/listenserver.cfg", "MOD")
			if not configlistpart2 then
				configlistpart2 = ""
			end
			
			local configlines = configlistpart1.."\n"..configlistpart2
			configlines = string.Replace(configlines, "\r", "\n")
			configlines = string.Replace(configlines, "\t", " ")
			configlines = string.Split(configlines, "\n")
			
			local ConVarName = ""
			local ConVarValue = ""
			ConVarList = {}
			local char = "#"
			for k,configline in ipairs( configlines ) do
				while string.sub(configline, 1, 1) == " " do -- remove any useless space
					configline = string.sub(configline, 2) -- remove the 1st character
				end
				if string.len(configline) ~= 0 and string.sub(configline, 1, 2) ~= "//" then -- not empty line and not comment line
					ConVarName = ""
					char = string.sub(configline, 1, 1)
					while char ~= " " do -- read the ConVar name
						ConVarName = ConVarName..char
						configline = string.sub(configline, 2) -- remove the 1st character
						char = string.sub(configline, 1, 1)
					end
					
					while string.sub(configline, 1, 1) == " " do -- remove any useless space
						configline = string.sub(configline, 2) -- remove the 1st character
					end
					
					char = string.sub(configline, 1, 1)
					local delim = " "
					if char == '"' then
						delim = '"'
						configline = string.sub(configline, 2) -- remove the 1st quote if any
					end
					
					ConVarValue = ""
					char = string.sub(configline, 1, 1)
					while char and char~=delim and string.len( char )~=0 do -- read the ConVar name
						ConVarValue = ConVarValue..char
						configline = string.sub( configline, 2 ) -- remove the 1st character
						char = string.sub( configline, 1, 1 )
					end
					
					if string.len( ConVarName )~=0 and string.len( ConVarValue )~=0 then
						ConVarList[ConVarName] = ConVarValue
					end
				end
			end
		end
		
		if ConVarList[ConVarToLoad] then
			MsgN(ConVarToLoad.." = "..ConVarList[ConVarToLoad])
			RunConsoleCommand(ConVarToLoad, ConVarList[ConVarToLoad])
			return ConVarList[ConVarToLoad]
		end
		return nil
	end
	
	-- We send the GroupID64 to the client so they can open easily open the group page of the server.
	local function sum_large_integers (int1, int2)
		local std_size = math.max(string.len(int1), string.len(int2))
		while string.len(int1) < std_size do
			int1 = "0"..int1
		end
		while string.len(int2) < std_size do
			int2 = "0"..int2
		end
		
		local carry=0
		local digit1
		local digit2
		local temp_result=""
		local result=""
		for k=std_size,1,-1 do -- from right digit to left ones
			digit1 = tonumber(string.GetChar(int1, k))
			digit2 = tonumber(string.GetChar(int2, k))
			temp_result = tostring(digit1+digit2+carry)
			if string.len(temp_result) > 1 then
				carry=tonumber(string.sub(temp_result, 1, string.len(temp_result)-1)) -- remove the last digit of temp_result => carry
			else
				carry=0 -- no carry
			end
			result=string.GetChar(temp_result, string.len(temp_result))..result
		end
		if carry ~= 0 then
			result=tostring(carry)..result
		end
		return result
	end
	
	-- Prepare stuff to adjust the server name link
	CreateConVar("pgl_groupurl", "", FCVAR_ARCHIVE, "URL of the link on the server name")
	local function ChangedServerLinkURL ()
		local steamgroupid = GetConVarString("sv_steamgroup")
		if string.len(steamgroupid) > 0 then
			steamgroupid = sum_large_integers("103582791429521408", steamgroupid)
		else
			steamgroupid = nil
		end
		local groupurl = GetConVarString("pgl_groupurl")
		if string.len(groupurl) > 0 then
			if string.sub(string.lower(groupurl), 1, 7) ~= "http://" and string.sub(string.lower(groupurl), 1, 8) ~= "https://" then
				groupurl = "http://"..groupurl
			end
			SetGlobalString("pgl_groupurl", groupurl)
		elseif steamgroupid and steamgroupid ~= "0" then
			SetGlobalString("pgl_groupurl", "http://steamcommunity.com/gid/"..steamgroupid)
		else
			SetGlobalString("pgl_groupurl", "")
		end
	end
	cvars.AddChangeCallback("pgl_groupurl", function ()
		ChangedServerLinkURL()
	end)
	cvars.AddChangeCallback("sv_steamgroup", function () -- does not seem to work
		ChangedServerLinkURL()
	end)
	hook.Add("OnEntityCreated", "pgl_groupurl", function (entity)
		if entity:IsPlayer() then
			ChangedServerLinkURL()
		end
	end)
	
	-- We prepare to send the full name of the gamemode.
	local GamemodeName = engine.ActiveGamemode()
	for _,Gamemode in pairs(engine.GetGamemodes()) do
		if Gamemode.name == GamemodeName then
			SetGlobalString("pgl_gamemode_title", Gamemode.title)
			break
		end
	end
	
	-- The lost packets numbers are sent every second.
	util.AddNetworkString("UpdateLostPackets")
	timer.Create( "UpdateLostPackets", 1, 0, function()
		net.Start( "UpdateLostPackets" )
		
		local List = player.GetHumans()
		net.WriteUInt( #List, 8 )
		for _, ply in ipairs( List ) do
			net.WriteUInt( ply:UserID(), 32 )
			
			local CurrentPacketLoss=0
			if not ply.PacketLossMean then
				CurrentPacketLoss = ply:PacketLoss()
			else
				for _,v in ipairs( ply.PacketLossMean ) do
					CurrentPacketLoss = CurrentPacketLoss+v
				end
				CurrentPacketLoss = CurrentPacketLoss/#ply.PacketLossMean
			end
			net.WriteFloat( CurrentPacketLoss )
		end
		
		net.Broadcast()
	end )
	
	-- Mean the packet loss on about 1 second
	local FramesPerSecond = math.floor( 1/engine.TickInterval() )
	hook.Add( "Think", "pgl_newscoreboard_1", function()
		local CurrentPacketLoss
		for _,ply in ipairs( player.GetAll() ) do
			CurrentPacketLoss = ply:PacketLoss()
			if not ply.PacketLossMean then
				ply.PacketLossMean = {}
				for k=1,FramesPerSecond do
					ply.PacketLossMean[k] = CurrentPacketLoss
				end
			else
				table.remove( ply.PacketLossMean, 1 )
				table.insert( ply.PacketLossMean, CurrentPacketLoss )
			end
		end
	end )
	
	AddNetworkedConVar("pgl_orderbystatus", "0", FCVAR_ARCHIVE, "Order for players in scoreboard: 0 = connection time, 1 = status, 2 = status with no title")
	
	-- Force to reload values if not dedicated, placed after all synchronized ConVars creations.
	if not game.IsDedicated() then
		MsgN("Forcing to load the ignored (or not) scoreboard parameters...")
		ForceReloadConfig("pgl_newscoreboard")
		ForceReloadConfig("sv_steamgroup") -- might be buggy when placed here
		ForceReloadConfig("pgl_groupurl")
		ForceReloadConfig("pgl_orderbystatus")
	end
	
	AddCSLuaFile()
	
	-- We send the country flags.
	resource.AddWorkshop("190728315")
end

if CLIENT then
	STATUS_ALIVE = 0
	STATUS_DEAD = 1
	STATUS_SPECTATOR = 2
	STATUS_LOADING = 3
	
	local language = GetConVarString("gmod_language")
	local language_translations = {}
	local function language_translate (english_string)
		for k, language_translation in pairs(language_translations) do
			if english_string == k then
				if language_translation[language] then
					return language_translation[language]
				else
					return english_string
				end
			end
		end
		return english_string
	end
	language_translations["Credits"] = {
		["fr"] = "Crédits",
		}
	language_translations["Scoreboard creator"] = {
		["fr"] = "Créateur de la planche de scores",
		}
	language_translations["Gamemode creator"] = {
		["fr"] = "Créateur du gamemode",
		}
	language_translations["Country flags"] = {
		["fr"] = "Drapeaux de pays",
		}
	language_translations["IP information database"] = {
		["fr"] = "Base de données d'informations IP",
		}
	language_translations["Server IP address getting"] = {
		["fr"] = "Obtention de l'adresse IP du serveur",
		}
	language_translations["Current map"] = {
		["fr"] = "Carte actuelle",
		}
	language_translations["You are playing on: "] = {
		["fr"] = "Vous jouez sur : ",
		}
	language_translations["Voice"] = {
		["fr"] = "Voix",
		}
	language_translations["Lost packets"] = {
		["fr"] = "Paquets perdus",
		}
	language_translations["Score"] = {
		["fr"] = "Score",
		}
	language_translations["Deaths"] = {
		["fr"] = "Décès",
		}
	language_translations["Group"] = {
		["fr"] = "Groupe",
		}
	language_translations["Status"] = {
		["fr"] = "Statut",
		}
	language_translations["Interface language"] = {
		["fr"] = "Langue de l'interface",
		}
	language_translations["Country"] = {
		["fr"] = "Pays",
		}
	language_translations["Region"] = {
		["fr"] = "Région",
		}
	language_translations["Not ready"] = {
		["fr"] = "Pas prêt",
		}
	language_translations["Player"] = {
		["fr"] = "Joueur",
		}
	language_translations["Administrator"] = {
		["fr"] = "Administrateur",
		}
	language_translations["Super Administrator"] = {
		["fr"] = "Super Administrateur",
		}
	language_translations["Alive"] = {
		["fr"] = "Vivant",
		}
	language_translations["Dead"] = {
		["fr"] = "Mort",
		}
	language_translations["Spectator"] = {
		["fr"] = "Spectateur",
		}
	language_translations["Loading"] = {
		["fr"] = "Chargement",
		}
	language_translations["Unknown"] = {
		["fr"] = "Inconnu",
		}
	
	
	-- Heights of the images, generated
	flag_height = {}
	flag_height["lo"] = 16
	flag_height["-"] = 16
	-- Automatically generated by "Get the heights.php"
	flag_height["ad"] = 11
	flag_height["ae"] = 8
	flag_height["af"] = 11
	flag_height["ag"] = 11
	flag_height["ai"] = 8
	flag_height["al"] = 11
	flag_height["am"] = 8
	flag_height["ao"] = 11
	flag_height["aq"] = 11
	flag_height["ar"] = 10
	flag_height["as"] = 8
	flag_height["at"] = 11
	flag_height["au"] = 8
	flag_height["aw"] = 11
	flag_height["ax"] = 10
	flag_height["az"] = 8
	flag_height["ba"] = 8
	flag_height["bb"] = 11
	flag_height["bd"] = 10
	flag_height["be"] = 14
	flag_height["bf"] = 11
	flag_height["bg"] = 10
	flag_height["bh"] = 10
	flag_height["bi"] = 10
	flag_height["bj"] = 11
	flag_height["bl"] = 11
	flag_height["bm"] = 8
	flag_height["bn"] = 8
	flag_height["bo"] = 11
	flag_height["bq"] = 11
	flag_height["br"] = 11
	flag_height["bs"] = 8
	flag_height["bt"] = 11
	flag_height["bv"] = 12
	flag_height["bw"] = 11
	flag_height["by"] = 8
	flag_height["bz"] = 11
	flag_height["ca"] = 8
	flag_height["cc"] = 8
	flag_height["cd"] = 12
	flag_height["cf"] = 11
	flag_height["cg"] = 11
	flag_height["ch"] = 16
	flag_height["ci"] = 11
	flag_height["ck"] = 8
	flag_height["cl"] = 11
	flag_height["cm"] = 11
	flag_height["cn"] = 11
	flag_height["co"] = 11
	flag_height["cr"] = 10
	flag_height["cu"] = 8
	flag_height["cv"] = 9
	flag_height["cw"] = 11
	flag_height["cx"] = 8
	flag_height["cy"] = 11
	flag_height["cz"] = 11
	flag_height["de"] = 10
	flag_height["dj"] = 11
	flag_height["dk"] = 12
	flag_height["dm"] = 8
	flag_height["do"] = 10
	flag_height["dz"] = 11
	flag_height["ec"] = 11
	flag_height["ee"] = 10
	flag_height["eg"] = 11
	flag_height["eh"] = 8
	flag_height["er"] = 8
	flag_height["es"] = 11
	flag_height["et"] = 8
	flag_height["fi"] = 10
	flag_height["fj"] = 8
	flag_height["fk"] = 8
	flag_height["fm"] = 8
	flag_height["fo"] = 12
	flag_height["fr"] = 11
	flag_height["ga"] = 12
	flag_height["gb"] = 8
	flag_height["gd"] = 10
	flag_height["ge"] = 11
	flag_height["gf"] = 11
	flag_height["gg"] = 11
	flag_height["gh"] = 11
	flag_height["gi"] = 8
	flag_height["gl"] = 11
	flag_height["gm"] = 11
	flag_height["gn"] = 11
	flag_height["gp"] = 8
	flag_height["gq"] = 11
	flag_height["gr"] = 11
	flag_height["gs"] = 8
	flag_height["gt"] = 10
	flag_height["gu"] = 9
	flag_height["gw"] = 8
	flag_height["gy"] = 10
	flag_height["hk"] = 11
	flag_height["hm"] = 8
	flag_height["hn"] = 8
	flag_height["hr"] = 8
	flag_height["ht"] = 10
	flag_height["hu"] = 8
	flag_height["id"] = 11
	flag_height["ie"] = 8
	flag_height["il"] = 12
	flag_height["im"] = 8
	flag_height["in"] = 11
	flag_height["io"] = 8
	flag_height["iq"] = 11
	flag_height["ir"] = 9
	flag_height["is"] = 12
	flag_height["it"] = 11
	flag_height["je"] = 10
	flag_height["jm"] = 8
	flag_height["jo"] = 8
	flag_height["jp"] = 11
	flag_height["ke"] = 11
	flag_height["kg"] = 10
	flag_height["kh"] = 10
	flag_height["ki"] = 8
	flag_height["km"] = 10
	flag_height["kn"] = 11
	flag_height["kp"] = 8
	flag_height["kr"] = 11
	flag_height["kw"] = 8
	flag_height["ky"] = 8
	flag_height["kz"] = 8
	flag_height["la"] = 11
	flag_height["lb"] = 11
	flag_height["lc"] = 8
	flag_height["li"] = 10
	flag_height["lk"] = 8
	flag_height["lr"] = 8
	flag_height["ls"] = 11
	flag_height["lt"] = 10
	flag_height["lu"] = 10
	flag_height["lv"] = 8
	flag_height["ly"] = 8
	flag_height["ma"] = 11
	flag_height["mc"] = 13
	flag_height["md"] = 8
	flag_height["me"] = 8
	flag_height["mf"] = 11
	flag_height["mg"] = 11
	flag_height["mh"] = 8
	flag_height["mk"] = 8
	flag_height["ml"] = 11
	flag_height["mm"] = 11
	flag_height["mn"] = 8
	flag_height["mo"] = 11
	flag_height["mp"] = 8
	flag_height["mq"] = 11
	flag_height["mr"] = 11
	flag_height["ms"] = 8
	flag_height["mt"] = 11
	flag_height["mu"] = 11
	flag_height["mv"] = 11
	flag_height["mw"] = 11
	flag_height["mx"] = 9
	flag_height["my"] = 8
	flag_height["mz"] = 11
	flag_height["na"] = 11
	flag_height["nc"] = 8
	flag_height["ne"] = 14
	flag_height["nf"] = 8
	flag_height["ng"] = 8
	flag_height["ni"] = 10
	flag_height["nl"] = 11
	flag_height["no"] = 12
	flag_height["np"] = 20
	flag_height["nr"] = 8
	flag_height["nu"] = 8
	flag_height["nz"] = 8
	flag_height["om"] = 8
	flag_height["pa"] = 11
	flag_height["pe"] = 11
	flag_height["pf"] = 11
	flag_height["pg"] = 12
	flag_height["ph"] = 8
	flag_height["pk"] = 11
	flag_height["pl"] = 10
	flag_height["pm"] = 11
	flag_height["pn"] = 8
	flag_height["pr"] = 11
	flag_height["ps"] = 8
	flag_height["pt"] = 11
	flag_height["pw"] = 10
	flag_height["py"] = 10
	flag_height["qa"] = 6
	flag_height["re"] = 12
	flag_height["ro"] = 11
	flag_height["rs"] = 11
	flag_height["ru"] = 11
	flag_height["rw"] = 11
	flag_height["sa"] = 11
	flag_height["sb"] = 8
	flag_height["sc"] = 8
	flag_height["sd"] = 8
	flag_height["se"] = 10
	flag_height["sg"] = 11
	flag_height["sh"] = 8
	flag_height["si"] = 8
	flag_height["sj"] = 12
	flag_height["sk"] = 11
	flag_height["sl"] = 11
	flag_height["sm"] = 12
	flag_height["sn"] = 11
	flag_height["so"] = 11
	flag_height["sr"] = 11
	flag_height["ss"] = 8
	flag_height["st"] = 8
	flag_height["sv"] = 9
	flag_height["sx"] = 11
	flag_height["sy"] = 11
	flag_height["sz"] = 11
	flag_height["tc"] = 8
	flag_height["td"] = 11
	flag_height["tf"] = 11
	flag_height["tg"] = 10
	flag_height["th"] = 11
	flag_height["tj"] = 8
	flag_height["tk"] = 8
	flag_height["tl"] = 8
	flag_height["tm"] = 11
	flag_height["tn"] = 11
	flag_height["to"] = 8
	flag_height["tr"] = 11
	flag_height["tt"] = 10
	flag_height["tv"] = 8
	flag_height["tw"] = 11
	flag_height["tz"] = 11
	flag_height["ua"] = 11
	flag_height["ug"] = 11
	flag_height["um"] = 8
	flag_height["us"] = 8
	flag_height["uy"] = 11
	flag_height["uz"] = 8
	flag_height["va"] = 16
	flag_height["vc"] = 11
	flag_height["ve"] = 11
	flag_height["vg"] = 8
	flag_height["vi"] = 11
	flag_height["vn"] = 11
	flag_height["vu"] = 10
	flag_height["wf"] = 11
	flag_height["ws"] = 8
	flag_height["ye"] = 11
	flag_height["yt"] = 11
	flag_height["za"] = 11
	flag_height["zm"] = 11
	flag_height["zw"] = 8
	
	
	-- The lost packets numbers are received every second.
	net.Receive("UpdateLostPackets", function(length, client)
		ply = LocalPlayer()
		if IsValid(ply.newscoreboard) then
			local count = net.ReadUInt( 8 )
			local UserID = 0
			local PacketLoss = 0
			ply.newscoreboard.LostPackets = {}
			if count > 0 then
				for i=1,count do
					UserID = net.ReadUInt(32)
					PacketLoss = math.Round(net.ReadFloat(), 1)
					ply.newscoreboard.LostPackets[UserID] = PacketLoss
				end
			end
		end
	end)
	
	
	-- Import ip2location.lua
	if not geoip then
		include("ip2location.lua")
	end
	
	
	local function GetPlayerStatus( data )
		local ply = data:GetPlayerEnt()
		if not IsValid( ply ) then -- loading (1)
			return STATUS_LOADING
		elseif ply:Team()==TEAM_CONNECTING then -- loading (2)
			return STATUS_LOADING
		elseif ply:Health()<=0 then -- dead
			return STATUS_DEAD
		elseif ply:Team()==TEAM_SPECTATOR then -- spectator
			return STATUS_SPECTATOR
		elseif ply:IsAdmin() then -- alive admin
			return STATUS_ALIVE
		else -- alive player
			return STATUS_ALIVE
		end
	end
	
	
	local function SortPlayersList (PlayerDataTable)
		local order = tonumber(GetGlobalString("pgl_orderbystatus", "0"))
		if order == 1 or order == 2 then
			local ClassedPlayersTable = {}
			ClassedPlayersTable["0"] = {}
			ClassedPlayersTable["1"] = {}
			ClassedPlayersTable["2"] = {}
			ClassedPlayersTable["3"] = {}
			for _,data in pairs(PlayerDataTable) do
				table.insert(ClassedPlayersTable[tostring(GetPlayerStatus(data))], data)
			end
			local OrderedPlayersTable = {}
			table.Add(OrderedPlayersTable, ClassedPlayersTable["0"])
			table.Add(OrderedPlayersTable, ClassedPlayersTable["1"])
			table.Add(OrderedPlayersTable, ClassedPlayersTable["2"])
			table.Add(OrderedPlayersTable, ClassedPlayersTable["3"])
			return OrderedPlayersTable
		else
			return PlayerDataTable
		end
	end
	
	
	local function LoadNewScoreboard ()
		local old_show_func = GAMEMODE.ScoreboardShow
		local old_hide_func = GAMEMODE.ScoreboardHide
		
		local ply = LocalPlayer()
		if IsValid(ply.newscoreboard) then
			ply.newscoreboard:Remove() -- just in case you want to modify this file without having to join again
		end
		
		local IsOldScoreboardInUse = true
		
		-- function GAMEMODE:ScoreboardShow()
		hook.Add("ScoreboardShow", "pgl_newscoreboard_show", function ()
			-- 0 must be the default for pgl_newscoreboard here because there is a risk that if it is disabled on the server then the new scoreboard can be displayed when just connected, but it may never be closed.
			if GetGlobalString("pgl_newscoreboard", "0") ~= "1" then
				IsOldScoreboardInUse = true
				-- old_show_func(self) -- Old scoreboard: show
				-- MsgN("You tried to display the old scoreboard.")
			else
				IsOldScoreboardInUse = false
				-- Show the new scoreboard
				-- MsgN("You tried to display the new scoreboard.")
				local ply = LocalPlayer()
				
				local COLOR_LOADING = Color(255, 255, 170, 128)
				local COLOR_DEAD = Color(228, 197, 197, 128)
				local COLOR_SPECTATOR = Color(228, 197, 197, 128)
				local COLOR_ALIVE_ADMIN = Color(170, 255, 170, 128)
				local COLOR_ALIVE = Color(212, 212, 212, 128)
				local function GetPlayerRowColor (ply, data)
					-- the Y component in YUV space is standardized to 200
					if not IsValid (ply) then -- loading (1)
						local NewPlayerEnt = data:GetPlayerEnt()
						if IsValid (NewPlayerEnt) then -- the player entity finally exists: has finished loading
							LocalPlayer().newscoreboard.ShouldCleanup = true
						end
						return COLOR_LOADING, STATUS_LOADING
					elseif ply:Team() == TEAM_CONNECTING then -- loading (2)
						return COLOR_LOADING, STATUS_LOADING
					elseif ply:Health()<=0 then -- dead
						return COLOR_DEAD, STATUS_DEAD
					elseif ply:Team() == TEAM_SPECTATOR then -- spectator
						return COLOR_SPECTATOR, STATUS_SPECTATOR
					elseif ply:IsAdmin() then -- alive admin
						return COLOR_ALIVE_ADMIN, STATUS_ALIVE
					else -- alive player
						return COLOR_ALIVE, STATUS_ALIVE
					end
				end
				
				if not IsValid(ply.newscoreboard) then
					local CurrentPanelWidth
					local CurrentPanelHeight
					local CurrentPanelHpos
					local CurrentPanelVpos
					
					surface.CreateFont("ScoreboardGamemodeFont",
						{
							font		= "Helvetica",
							size		= 24,
							weight		= 640
						})
					surface.CreateFont("ScoreboardServerNameFont",
						{
							font		= "Helvetica",
							size		= 20,
							weight		= 640
						})
					surface.CreateFont("ScoreboardPlayerLine32",
						{
							font		= "Helvetica",
							size		= 24,
							weight		= 640
						})
					
					ply.newscoreboard = vgui.Create("DPanel")
					ply.newscoreboard:SetSize(math.max(640, math.ceil(ScrW()-((ScrH()*2)/7))), math.ceil((ScrH()*5)/7))
					-- ply.newscoreboard:SetSize(640, math.ceil((ScrH()*5)/7)) -- Test with the lowest res available.
					-- ply.newscoreboard:SetSize(640, 640) -- Test with the lowest res available but square shape.
					ply.newscoreboard:SetBackgroundColor(Color(100, 95, 100, 192))
					ply.newscoreboard:Center()
					ply.newscoreboard.ActiveRefresh = true
					ply.newscoreboard.ShouldCleanup = true
					ply.newscoreboard.LostPackets = {}
					local ScoreboardWidth
					local ScoreboardHeight
					ScoreboardWidth, ScoreboardHeight = ply.newscoreboard:GetSize()
					
					-- The colors are set with any choice, with Y=200 in the YUV space
					
					local function display_box_credits ()
						local ply = LocalPlayer()
						if not IsValid(ply.newscoreboard.box_credits) then
							local CurrentPanelHpos
							local CurrentPanelVpos
							local CurrentPanelWidth
							local CurrentPanelHeight
							ply.newscoreboard.box_credits = vgui.Create("DFrame", ply.newscoreboard)
							ply.newscoreboard.box_credits:SetSize(75+50+50+50+32, ScoreboardHeight-66-1) -- same height as PlayerList
							local BoxHsize, BoxVsize = ply.newscoreboard.box_credits:GetSize()
							ply.newscoreboard.box_credits:SetPos(ScoreboardWidth-1-15-BoxHsize,66) -- same Vpos as PlayerList
							ply.newscoreboard.box_credits:SetDeleteOnClose(true)
							ply.newscoreboard.box_credits:SetDraggable(false)
							ply.newscoreboard.box_credits:SetSizable(false)
							ply.newscoreboard.box_credits:SetTitle(language_translate("Credits"))
							
							ply.newscoreboard.box_credits.CreatorH = vgui.Create("DLabel", ply.newscoreboard.box_credits)
							ply.newscoreboard.box_credits.CreatorH:SetDrawBackground(false)
							ply.newscoreboard.box_credits.CreatorH:SetTextColor(Color(192, 192, 192, 255))
							ply.newscoreboard.box_credits.CreatorH:SetPos(10, 30)
							ply.newscoreboard.box_credits.CreatorH:SetText(language_translate("Scoreboard creator"))
							ply.newscoreboard.box_credits.CreatorH:SizeToContents()
							CurrentPanelHpos, CurrentPanelVpos = ply.newscoreboard.box_credits.CreatorH:GetPos()
							CurrentPanelWidth, CurrentPanelHeight = ply.newscoreboard.box_credits.CreatorH:GetSize()
							
							ply.newscoreboard.box_credits.Creator = vgui.Create("DLabel", ply.newscoreboard.box_credits)
							ply.newscoreboard.box_credits.Creator:SetDrawBackground(false)
							ply.newscoreboard.box_credits.Creator:SetTextColor(Color(255, 255, 255, 255))
							ply.newscoreboard.box_credits.Creator:SetPos(25, CurrentPanelVpos+CurrentPanelHeight+2)
							ply.newscoreboard.box_credits.Creator:SetText("Mohamed RACHID")
							ply.newscoreboard.box_credits.Creator:SizeToContents()
							CurrentPanelHpos, CurrentPanelVpos = ply.newscoreboard.box_credits.Creator:GetPos()
							CurrentPanelWidth, CurrentPanelHeight = ply.newscoreboard.box_credits.Creator:GetSize()
							
							if GAMEMODE.Author then
								ply.newscoreboard.box_credits.GMCreatorH = vgui.Create("DLabel", ply.newscoreboard.box_credits)
								ply.newscoreboard.box_credits.GMCreatorH:SetDrawBackground(false)
								ply.newscoreboard.box_credits.GMCreatorH:SetTextColor(Color(192, 192, 192, 255))
								ply.newscoreboard.box_credits.GMCreatorH:SetPos(10, CurrentPanelVpos+CurrentPanelHeight+12)
								ply.newscoreboard.box_credits.GMCreatorH:SetText(language_translate("Gamemode creator"))
								ply.newscoreboard.box_credits.GMCreatorH:SizeToContents()
								CurrentPanelHpos, CurrentPanelVpos = ply.newscoreboard.box_credits.GMCreatorH:GetPos()
								CurrentPanelWidth, CurrentPanelHeight = ply.newscoreboard.box_credits.GMCreatorH:GetSize()
								
								ply.newscoreboard.box_credits.GMCreator = vgui.Create("DLabel", ply.newscoreboard.box_credits)
								ply.newscoreboard.box_credits.GMCreator:SetDrawBackground(false)
								ply.newscoreboard.box_credits.GMCreator:SetTextColor(Color(255, 255, 255, 255))
								ply.newscoreboard.box_credits.GMCreator:SetPos(25, CurrentPanelVpos+CurrentPanelHeight+2)
								ply.newscoreboard.box_credits.GMCreator:SetText(GAMEMODE.Author)
								ply.newscoreboard.box_credits.GMCreator:SizeToContents()
								CurrentPanelHpos, CurrentPanelVpos = ply.newscoreboard.box_credits.GMCreator:GetPos()
								CurrentPanelWidth, CurrentPanelHeight = ply.newscoreboard.box_credits.GMCreator:GetSize()
							end
							
							ply.newscoreboard.box_credits.MapH = vgui.Create("DLabel", ply.newscoreboard.box_credits)
							ply.newscoreboard.box_credits.MapH:SetDrawBackground(false)
							ply.newscoreboard.box_credits.MapH:SetTextColor(Color(192, 192, 192, 255))
							ply.newscoreboard.box_credits.MapH:SetPos(10, CurrentPanelVpos+CurrentPanelHeight+12)
							ply.newscoreboard.box_credits.MapH:SetText(language_translate("Current map"))
							ply.newscoreboard.box_credits.MapH:SizeToContents()
							CurrentPanelHpos, CurrentPanelVpos = ply.newscoreboard.box_credits.MapH:GetPos()
							CurrentPanelWidth, CurrentPanelHeight = ply.newscoreboard.box_credits.MapH:GetSize()
							
							ply.newscoreboard.box_credits.Map = vgui.Create("DLabel", ply.newscoreboard.box_credits)
							ply.newscoreboard.box_credits.Map:SetDrawBackground(false)
							ply.newscoreboard.box_credits.Map:SetTextColor(Color(255, 255, 255, 255))
							ply.newscoreboard.box_credits.Map:SetPos(25, CurrentPanelVpos+CurrentPanelHeight+2)
							ply.newscoreboard.box_credits.Map:SetText(game.GetMap())
							ply.newscoreboard.box_credits.Map:SizeToContents()
							CurrentPanelHpos, CurrentPanelVpos = ply.newscoreboard.box_credits.Map:GetPos()
							CurrentPanelWidth, CurrentPanelHeight = ply.newscoreboard.box_credits.Map:GetSize()
							
							ply.newscoreboard.box_credits.FlagsH = vgui.Create("DLabel", ply.newscoreboard.box_credits)
							ply.newscoreboard.box_credits.FlagsH:SetDrawBackground(false)
							ply.newscoreboard.box_credits.FlagsH:SetTextColor(Color(192, 192, 192, 255))
							ply.newscoreboard.box_credits.FlagsH:SetPos(10, CurrentPanelVpos+CurrentPanelHeight+12)
							ply.newscoreboard.box_credits.FlagsH:SetText(language_translate("Country flags"))
							ply.newscoreboard.box_credits.FlagsH:SizeToContents()
							CurrentPanelHpos, CurrentPanelVpos = ply.newscoreboard.box_credits.FlagsH:GetPos()
							CurrentPanelWidth, CurrentPanelHeight = ply.newscoreboard.box_credits.FlagsH:GetSize()
							
							ply.newscoreboard.box_credits.Flags = vgui.Create("DLabel", ply.newscoreboard.box_credits)
							ply.newscoreboard.box_credits.Flags:SetDrawBackground(false)
							ply.newscoreboard.box_credits.Flags:SetTextColor(Color(255, 255, 255, 255))
							ply.newscoreboard.box_credits.Flags:SetPos(25, CurrentPanelVpos+CurrentPanelHeight+2)
							ply.newscoreboard.box_credits.Flags:SetText("The country flag images are provided by http://www.ip2location.com")
							ply.newscoreboard.box_credits.Flags:SetSize(BoxHsize-25, 10)
							ply.newscoreboard.box_credits.Flags:SetWrap(true)
							ply.newscoreboard.box_credits.Flags:SetAutoStretchVertical(true)
							CurrentPanelHpos, CurrentPanelVpos = ply.newscoreboard.box_credits.Flags:GetPos()
							CurrentPanelVpos = CurrentPanelVpos + 16 -- buggy size with 2 lines
							CurrentPanelWidth, CurrentPanelHeight = ply.newscoreboard.box_credits.Flags:GetSize()
							
							ply.newscoreboard.box_credits.DatabaseH = vgui.Create("DLabel", ply.newscoreboard.box_credits)
							ply.newscoreboard.box_credits.DatabaseH:SetDrawBackground(false)
							ply.newscoreboard.box_credits.DatabaseH:SetTextColor(Color(192, 192, 192, 255))
							ply.newscoreboard.box_credits.DatabaseH:SetPos(10, CurrentPanelVpos+CurrentPanelHeight+12)
							ply.newscoreboard.box_credits.DatabaseH:SetText(language_translate("IP information database"))
							ply.newscoreboard.box_credits.DatabaseH:SizeToContents()
							CurrentPanelHpos, CurrentPanelVpos = ply.newscoreboard.box_credits.DatabaseH:GetPos()
							CurrentPanelWidth, CurrentPanelHeight = ply.newscoreboard.box_credits.DatabaseH:GetSize()
							
							ply.newscoreboard.box_credits.Database = vgui.Create("DLabel", ply.newscoreboard.box_credits)
							ply.newscoreboard.box_credits.Database:SetDrawBackground(false)
							ply.newscoreboard.box_credits.Database:SetTextColor(Color(255, 255, 255, 255))
							ply.newscoreboard.box_credits.Database:SetPos(25, CurrentPanelVpos+CurrentPanelHeight+2)
							ply.newscoreboard.box_credits.Database:SetText("This product includes IP2Location LITE data available from http://www.ip2location.com")
							ply.newscoreboard.box_credits.Database:SetSize(BoxHsize-25, 10)
							ply.newscoreboard.box_credits.Database:SetWrap(true)
							ply.newscoreboard.box_credits.Database:SetAutoStretchVertical(true)
							CurrentPanelHpos, CurrentPanelVpos = ply.newscoreboard.box_credits.Database:GetPos()
							CurrentPanelVpos = CurrentPanelVpos + 16 -- buggy size with 2 lines
							CurrentPanelWidth, CurrentPanelHeight = ply.newscoreboard.box_credits.Database:GetSize()
							
							ply.newscoreboard.box_credits.CheckIpH = vgui.Create("DLabel", ply.newscoreboard.box_credits)
							ply.newscoreboard.box_credits.CheckIpH:SetDrawBackground(false)
							ply.newscoreboard.box_credits.CheckIpH:SetTextColor(Color(192, 192, 192, 255))
							ply.newscoreboard.box_credits.CheckIpH:SetPos(10, CurrentPanelVpos+CurrentPanelHeight+12)
							ply.newscoreboard.box_credits.CheckIpH:SetText(language_translate("Server IP address getting"))
							ply.newscoreboard.box_credits.CheckIpH:SizeToContents()
							CurrentPanelHpos, CurrentPanelVpos = ply.newscoreboard.box_credits.CheckIpH:GetPos()
							CurrentPanelWidth, CurrentPanelHeight = ply.newscoreboard.box_credits.CheckIpH:GetSize()
							
							ply.newscoreboard.box_credits.CheckIp = vgui.Create("DLabel", ply.newscoreboard.box_credits)
							ply.newscoreboard.box_credits.CheckIp:SetDrawBackground(false)
							ply.newscoreboard.box_credits.CheckIp:SetTextColor(Color(255, 255, 255, 255))
							ply.newscoreboard.box_credits.CheckIp:SetPos(25, CurrentPanelVpos+CurrentPanelHeight+2)
							ply.newscoreboard.box_credits.CheckIp:SetText("DynDNS Current IP Check")
							ply.newscoreboard.box_credits.CheckIp:SizeToContents()
							CurrentPanelHpos, CurrentPanelVpos = ply.newscoreboard.box_credits.CheckIp:GetPos()
							CurrentPanelWidth, CurrentPanelHeight = ply.newscoreboard.box_credits.CheckIp:GetSize()
						end
					end
					ply.newscoreboard.CreditsButton = vgui.Create("DButton", ply.newscoreboard)
					ply.newscoreboard.CreditsButton:SetPos(1,1)
					ply.newscoreboard.CreditsButton:SetText(language_translate("Credits"))
					ply.newscoreboard.CreditsButton:SetDrawBackground(false)
					ply.newscoreboard.CreditsButton:SetDrawBorder(false)
					ply.newscoreboard.CreditsButton:SetTextColor(Color(224, 224, 224, 255))
					ply.newscoreboard.CreditsButton:SizeToContents()
					ply.newscoreboard.CreditsButton.DoClick = function()
						display_box_credits()
					end
					
					ply.newscoreboard.GamemodeTitle = vgui.Create("DLabel", ply.newscoreboard)
					ply.newscoreboard.GamemodeTitle:SetDrawBackground(false)
					ply.newscoreboard.GamemodeTitle:SetFont("ScoreboardGamemodeFont")
					ply.newscoreboard.GamemodeTitle:SetTextColor(Color(170, 213, 255, 255))
					ply.newscoreboard.GamemodeTitle:SetText(GetGlobalString("pgl_gamemode_title", "Garry's Mod"))
					ply.newscoreboard.GamemodeTitle:SizeToContents()
					CurrentPanelWidth, CurrentPanelHeight = ply.newscoreboard.GamemodeTitle:GetSize()
					local GamemodeTitleWidth = CurrentPanelWidth
					CurrentPanelHpos, CurrentPanelVpos = ScoreboardWidth - CurrentPanelWidth - 1, 1
					ply.newscoreboard.GamemodeTitle:SetPos(CurrentPanelHpos, CurrentPanelVpos)
					
					ply.newscoreboard.GamemodePicture = vgui.Create("DImage", ply.newscoreboard)
					ply.newscoreboard.GamemodePicture:SetSize(24, 24)
					local GamemodePicture = "gamemodes/".. engine.ActiveGamemode() .."/icon24.png"
					if not file.Exists(GamemodePicture, "GAME") then
						GamemodePicture = "gamemodes/base/icon24.png"
					end
					ply.newscoreboard.GamemodePicture:SetImage(GamemodePicture)
					CurrentPanelHpos, CurrentPanelVpos = CurrentPanelHpos - 24 - 7, 1
					ply.newscoreboard.GamemodePicture:SetPos(CurrentPanelHpos, CurrentPanelVpos)
					
					ply.newscoreboard.GamemodeLink = vgui.Create("DButton", ply.newscoreboard)
					ply.newscoreboard.GamemodeLink:SetPos(ply.newscoreboard.GamemodePicture:GetPos())
					ply.newscoreboard.GamemodeLink:SetText("")
					ply.newscoreboard.GamemodeLink:SetDrawBackground(false)
					ply.newscoreboard.GamemodeLink:SetDrawBorder(false)
					ply.newscoreboard.GamemodeLink:SetSize(GamemodeTitleWidth+24+7, 24)
					if GAMEMODE.Website and string.len( GAMEMODE.Website )~=0 then
						ply.newscoreboard.GamemodeLink.DoClick = function ()
							gui.OpenURL("http://"..GAMEMODE.Website)
						end
					end
					
					ply.newscoreboard.ServerName = vgui.Create("DButton", ply.newscoreboard)
					ply.newscoreboard.ServerName:SetDrawBackground(false)
					ply.newscoreboard.ServerName:SetDrawBorder(false)
					ply.newscoreboard.ServerName:SetFont("ScoreboardServerNameFont")
					ply.newscoreboard.ServerName:SetTextColor(Color(170, 255, 170, 255))
					ply.newscoreboard.ServerName:SetPos(1, 30)
					ply.newscoreboard.ServerName.DoClick = function ()
						local groupurl = GetGlobalString("pgl_groupurl", "")
						if string.len( groupurl )~=0 then
							gui.OpenURL(groupurl)
						end
					end
					
					ply.newscoreboard.Title = {}
					CurrentPanelHpos = ScoreboardWidth-1-1-15-32 -- the last -15 is for the scrollbar
					CurrentPanelVpos = 48
					
					ply.newscoreboard.Title.Mute = vgui.Create("DLabel", ply.newscoreboard)
					ply.newscoreboard.Title.Mute:SetDrawBackground(false)
					ply.newscoreboard.Title.Mute:SetTextColor(Color(255, 255, 255, 255))
					ply.newscoreboard.Title.Mute:SetPos(CurrentPanelHpos, CurrentPanelVpos)
					ply.newscoreboard.Title.Mute:SetSize(32, 20)
					ply.newscoreboard.Title.Mute:SetContentAlignment(8)
					ply.newscoreboard.Title.Mute:SetText(language_translate("Voice"))
					CurrentPanelHpos = CurrentPanelHpos-50
					
					ply.newscoreboard.Title.Ping = vgui.Create("DLabel", ply.newscoreboard)
					ply.newscoreboard.Title.Ping:SetDrawBackground(false)
					ply.newscoreboard.Title.Ping:SetTextColor(Color(255, 255, 255, 255))
					ply.newscoreboard.Title.Ping:SetPos(CurrentPanelHpos, CurrentPanelVpos)
					ply.newscoreboard.Title.Ping:SetSize(50, 20)
					ply.newscoreboard.Title.Ping:SetContentAlignment(8)
					ply.newscoreboard.Title.Ping:SetText("Ping")
					CurrentPanelHpos = CurrentPanelHpos-50
					
					ply.newscoreboard.Title.Deaths = vgui.Create("DLabel", ply.newscoreboard)
					ply.newscoreboard.Title.Deaths:SetDrawBackground(false)
					ply.newscoreboard.Title.Deaths:SetTextColor(Color(255, 255, 255, 255))
					ply.newscoreboard.Title.Deaths:SetPos(CurrentPanelHpos, CurrentPanelVpos)
					ply.newscoreboard.Title.Deaths:SetSize(50, 20)
					ply.newscoreboard.Title.Deaths:SetContentAlignment(8)
					ply.newscoreboard.Title.Deaths:SetText(language_translate("Deaths"))
					CurrentPanelHpos = CurrentPanelHpos-50
					
					ply.newscoreboard.Title.Score = vgui.Create("DLabel", ply.newscoreboard)
					ply.newscoreboard.Title.Score:SetDrawBackground(false)
					ply.newscoreboard.Title.Score:SetTextColor(Color(255, 255, 255, 255))
					ply.newscoreboard.Title.Score:SetPos(CurrentPanelHpos, CurrentPanelVpos)
					ply.newscoreboard.Title.Score:SetSize(50, 20)
					ply.newscoreboard.Title.Score:SetContentAlignment(8)
					ply.newscoreboard.Title.Score:SetText(language_translate("Score"))
					CurrentPanelHpos = CurrentPanelHpos-75
					
					ply.newscoreboard.Title.LostPackets = vgui.Create("DLabel", ply.newscoreboard)
					ply.newscoreboard.Title.LostPackets:SetDrawBackground(false)
					ply.newscoreboard.Title.LostPackets:SetTextColor(Color(255, 255, 255, 255))
					ply.newscoreboard.Title.LostPackets:SetPos(CurrentPanelHpos, CurrentPanelVpos)
					ply.newscoreboard.Title.LostPackets:SetSize(75, 20)
					ply.newscoreboard.Title.LostPackets:SetContentAlignment(8)
					ply.newscoreboard.Title.LostPackets:SetText(language_translate("Lost packets"))
					
					local function display_box_userinfo (data, DoNotRefreshInfo)
						local ply = LocalPlayer()
						if not IsValid(ply.newscoreboard.box_userinfo) then
							ply.newscoreboard.box_userinfo = vgui.Create("DFrame", ply.newscoreboard)
							ply.newscoreboard.box_userinfo:SetSize(75+50+50+50+32, ScoreboardHeight-66-1) -- same height as PlayerList
							local CurrentPanelHsize, CurrentPanelVsize = ply.newscoreboard.box_userinfo:GetSize()
							ply.newscoreboard.box_userinfo:SetPos(ScoreboardWidth-1-15-CurrentPanelHsize,66) -- same Vpos as PlayerList
							ply.newscoreboard.box_userinfo:SetDeleteOnClose(true)
							ply.newscoreboard.box_userinfo:SetDraggable(false)
							ply.newscoreboard.box_userinfo:SetSizable(false)
							ply.newscoreboard.box_userinfo.User = nil
							ply.newscoreboard.box_userinfo.LastUser = nil
							
							ply.newscoreboard.box_userinfo.GroupH = vgui.Create("DLabel", ply.newscoreboard.box_userinfo)
							ply.newscoreboard.box_userinfo.GroupH:SetDrawBackground(false)
							ply.newscoreboard.box_userinfo.GroupH:SetTextColor(Color(192, 192, 192, 255))
							ply.newscoreboard.box_userinfo.GroupH:SetPos(10, 30)
							ply.newscoreboard.box_userinfo.GroupH:SetSize(50, 20)
							ply.newscoreboard.box_userinfo.GroupH:SetText(language_translate("Group"))
							ply.newscoreboard.box_userinfo.GroupH:SizeToContents()
							
							ply.newscoreboard.box_userinfo.Group = vgui.Create("DLabel", ply.newscoreboard.box_userinfo)
							ply.newscoreboard.box_userinfo.Group:SetDrawBackground(false)
							ply.newscoreboard.box_userinfo.Group:SetTextColor(Color(255, 255, 255, 255))
							ply.newscoreboard.box_userinfo.Group:SetPos(25, 45)
							ply.newscoreboard.box_userinfo.Group:SetSize(50, 20)
							ply.newscoreboard.box_userinfo.Group:SetText("")
							
							ply.newscoreboard.box_userinfo.StatusH = vgui.Create("DLabel", ply.newscoreboard.box_userinfo)
							ply.newscoreboard.box_userinfo.StatusH:SetDrawBackground(false)
							ply.newscoreboard.box_userinfo.StatusH:SetTextColor(Color(192, 192, 192, 255))
							ply.newscoreboard.box_userinfo.StatusH:SetPos(10, 70)
							ply.newscoreboard.box_userinfo.StatusH:SetSize(50, 20)
							ply.newscoreboard.box_userinfo.StatusH:SetText(language_translate("Status"))
							ply.newscoreboard.box_userinfo.StatusH:SizeToContents()
							
							ply.newscoreboard.box_userinfo.Status = vgui.Create("DLabel", ply.newscoreboard.box_userinfo)
							ply.newscoreboard.box_userinfo.Status:SetDrawBackground(false)
							ply.newscoreboard.box_userinfo.Status:SetTextColor(Color(255, 255, 255, 255))
							ply.newscoreboard.box_userinfo.Status:SetPos(25, 85)
							ply.newscoreboard.box_userinfo.Status:SetSize(50, 20)
							ply.newscoreboard.box_userinfo.Status:SetText("")
							
							ply.newscoreboard.box_userinfo.LanguageH = vgui.Create("DLabel", ply.newscoreboard.box_userinfo)
							ply.newscoreboard.box_userinfo.LanguageH:SetDrawBackground(false)
							ply.newscoreboard.box_userinfo.LanguageH:SetTextColor(Color(192, 192, 192, 255))
							ply.newscoreboard.box_userinfo.LanguageH:SetPos(10, 110)
							ply.newscoreboard.box_userinfo.LanguageH:SetSize(50, 20)
							ply.newscoreboard.box_userinfo.LanguageH:SetText(language_translate("Interface language"))
							ply.newscoreboard.box_userinfo.LanguageH:SizeToContents()
							
							ply.newscoreboard.box_userinfo.Language = vgui.Create("DLabel", ply.newscoreboard.box_userinfo)
							ply.newscoreboard.box_userinfo.Language:SetDrawBackground(false)
							ply.newscoreboard.box_userinfo.Language:SetTextColor(Color(255, 255, 255, 255))
							ply.newscoreboard.box_userinfo.Language:SetPos(45, 125)
							ply.newscoreboard.box_userinfo.Language:SetSize(50, 20)
							ply.newscoreboard.box_userinfo.Language:SetText("")
							
							ply.newscoreboard.box_userinfo.LanguageFlag = vgui.Create("DImage", ply.newscoreboard.box_userinfo)
							ply.newscoreboard.box_userinfo.LanguageFlag:SetSize(16, 11)
							ply.newscoreboard.box_userinfo.LanguageFlag:SetPos(25, 127)
							
							ply.newscoreboard.box_userinfo.CountryH = vgui.Create("DLabel", ply.newscoreboard.box_userinfo)
							ply.newscoreboard.box_userinfo.CountryH:SetDrawBackground(false)
							ply.newscoreboard.box_userinfo.CountryH:SetTextColor(Color(192, 192, 192, 255))
							ply.newscoreboard.box_userinfo.CountryH:SetPos(10, 150)
							ply.newscoreboard.box_userinfo.CountryH:SetSize(50, 20)
							ply.newscoreboard.box_userinfo.CountryH:SetText(language_translate("Country"))
							ply.newscoreboard.box_userinfo.CountryH:SizeToContents()
							
							ply.newscoreboard.box_userinfo.Country = vgui.Create("DLabel", ply.newscoreboard.box_userinfo)
							ply.newscoreboard.box_userinfo.Country:SetDrawBackground(false)
							ply.newscoreboard.box_userinfo.Country:SetTextColor(Color(255, 255, 255, 255))
							ply.newscoreboard.box_userinfo.Country:SetPos(25, 165)
							ply.newscoreboard.box_userinfo.Country:SetSize(50, 20)
							ply.newscoreboard.box_userinfo.Country:SetText("")
							
							ply.newscoreboard.box_userinfo.RegionH = vgui.Create("DLabel", ply.newscoreboard.box_userinfo)
							ply.newscoreboard.box_userinfo.RegionH:SetDrawBackground(false)
							ply.newscoreboard.box_userinfo.RegionH:SetTextColor(Color(192, 192, 192, 255))
							ply.newscoreboard.box_userinfo.RegionH:SetPos(10, 190)
							ply.newscoreboard.box_userinfo.RegionH:SetSize(50, 20)
							ply.newscoreboard.box_userinfo.RegionH:SetText(language_translate("Region"))
							ply.newscoreboard.box_userinfo.RegionH:SizeToContents()
							
							ply.newscoreboard.box_userinfo.Region = vgui.Create("DLabel", ply.newscoreboard.box_userinfo)
							ply.newscoreboard.box_userinfo.Region:SetDrawBackground(false)
							ply.newscoreboard.box_userinfo.Region:SetTextColor(Color(255, 255, 255, 255))
							ply.newscoreboard.box_userinfo.Region:SetPos(25, 205)
							ply.newscoreboard.box_userinfo.Region:SetSize(50, 20)
							ply.newscoreboard.box_userinfo.Region:SetText("")
							
							local GROUP_LOADING = "Not ready"
							local GROUP_PLAYER = "Player"
							local GROUP_ADMIN = "Administrator"
							local GROUP_SUPERADMIN = "Super Administrator"
							function ply.newscoreboard.box_userinfo:Think ()
								
								local pl_state = GetPlayerStatus(data)
								local pl = self.User:GetPlayerEnt()
								
								local group = GROUP_LOADING
								if pl_state ~= STATUS_LOADING then
									if pl:IsSuperAdmin() then group = GROUP_SUPERADMIN
									elseif pl:IsAdmin() then group = GROUP_ADMIN
									else group = GROUP_PLAYER
									end
								end
								
								-- The country name is also checked because there is a bug the 1st time a loading player is displayed.
								if self.User ~= self.LastUser or group ~= self.GroupText or pl_state ~= self.StatusValue or self.User.language ~= self.LanguageText or (self.User.geoip and self.User.geoip[geoip.country_name] ~= self.CountryText) then -- refresh needed
									self:SetTitle(self.User.name)
									self.Group:SetText(language_translate(group))
									self.Group:SizeToContents()
									self.GroupText = group
									local player_state_text = ""
									if pl_state == STATUS_ALIVE then player_state_text = "Alive"
										elseif pl_state == STATUS_DEAD then player_state_text = "Dead"
										elseif pl_state == STATUS_SPECTATOR then player_state_text = "Spectator"
										elseif pl_state == STATUS_LOADING then player_state_text = "Loading"
										else player_state_text = "Unknown"
									end
									self.Status:SetText(language_translate(player_state_text))
									self.Status:SizeToContents()
									self.StatusValue = pl_state
									if self.User.language then
										-- update some labels
										self.Language:SetText(self.User.language)
										self.Language:SizeToContents()
										if string.len( self.User.language )~=0 then
											self.LanguageFlag:SetImage("resource/localization/"..self.User.language..".png")
										else
											self.LanguageFlag:SetImage("html/img/empty.png")
										end
										self.LanguageText = self.User.language
									else
										self.Language:SetText("")
										self.LanguageFlag:SetImage("html/img/empty.png")
										self.LanguageText = ""
									end
									if self.User.geoip then
										-- update some labels
										self.Country:SetText(self.User.geoip[geoip.country_name])
										self.Country:SizeToContents()
										self.CountryText = self.User.geoip[geoip.country_name]
										self.Region:SetText(self.User.geoip[geoip.region_name])
										self.Region:SizeToContents()
									else
										self.Country:SetText("")
										self.CountryText = ""
										self.Region:SetText("")
									end
									self.LastUser = self.User
								end
							end
						end
						
						if DoNotRefreshInfo ~= true then
							geoip.GetUserIDInfo(data.userid) -- ask the server for IP info
						end
						ply.newscoreboard.box_userinfo.LastUser = ply.newscoreboard.box_userinfo.User
						ply.newscoreboard.box_userinfo.User = data
					end
					
					function ply.newscoreboard:PlayerListCreate ()
						if IsValid(self.PlayerList) then
							self.PlayerList:Remove()
						end
						local ScoreboardWidth
						local ScoreboardHeight
						ScoreboardWidth, ScoreboardHeight = self:GetSize()
						
						self.PlayerList = vgui.Create("DScrollPanel", self)
						-- self.PlayerList = vgui.Create("DPanel", self) -- test
						-- self.PlayerList:SetBackgroundColor(Color(255, 0, 0, 255)) -- test
						self.PlayerList:SetPos(1,66)
						self.PlayerList.Width = ScoreboardWidth - 2
						self.PlayerList:SetSize(self.PlayerList.Width, ScoreboardHeight-66-1)
						self.PlayerList.PlayerRows = {}
						
						local ScoreBoardOrder
						function self:Think (w, h)
							if self.OrderChanged then
								self:Update(true)
								self.OrderChanged = nil
							elseif self.ActiveRefresh then
								self:Update(false)
							end
						end
					end
					
					local function GetBestNick (PlayerData, NickLabel)
						local Player = PlayerData:GetPlayerEnt()
						-- local SteamID64 = util.SteamIDTo64(PlayerData.networkid) -- will return nothing for bots and in some cases returns an incorrect result
						local Nick = nil
						local IsDirtyValue = nil
						-- if SteamID64 and PlayerData.bot == 0 then
							-- Nick = steamworks.GetPlayerName(SteamID64) -- sometimes returns "[unknown]" and might return old values if error occurs
							-- if Nick == "[unknown]" then -- workaround
								-- if IsValid(Player) then
									-- Nick = Player:Nick()
								-- else
									-- Nick = PlayerData.name
								-- end
								-- if Nick ~= "[unknown]" then
									-- IsDirtyValue = true
								-- end
							-- elseif IsValid(Player) then
								-- -- Here we compare if steamworks.GetPlayerName() returned the current value instead of an old unwanted value.
								-- local Nick31 = Player:Nick()
								-- local Nick28 = string.sub(Nick31, 1, 28) -- 31 bytes standard nickname with 3 last bytes removed (UTF-8 can contain up to 4 bytes per character and incomplete combinations may be truncated)
								-- local FullNick28 = string.sub(Nick, 1, 28)
								-- if Nick28 ~= FullNick28 then -- seems that steamworks.GetPlayerName() has not worked correctly
									-- Nick = Nick31
									-- IsDirtyValue = true
								-- end
							-- end
						-- end
						-- if not Nick or PlayerData.bot == 1 then
							-- Nick = PlayerData.name
						-- end
						
						if IsValid(NickLabel) then
							NickLabel.IsDirtyValue = IsDirtyValue
						end
						
						if PlayerData.name and string.len(PlayerData.name) > 0 then
							Nick = PlayerData.name
						elseif IsValid(Player) then
							Nick = Player:Nick()
						else
							Nick = PlayerData.name -- This should never happen, but I need a default case.
						end
						
						return Nick
					end
					
					function ply.newscoreboard:Update (cleanup)
						-- Cleanup should be false only when refreshing ping, score, etc. Here the scoreboard list is constructed.
						if cleanup or self.ShouldCleanup then
							-- Remove the boxes so they won't stay at the background.
							local box_credits_displayed = false
							if IsValid(ply.newscoreboard.box_credits) then
								box_credits_displayed = true
								ply.newscoreboard.box_credits:Remove()
							end
							local box_userinfo_data = nil
							if IsValid(ply.newscoreboard.box_userinfo) then
								box_userinfo_data = ply.newscoreboard.box_userinfo.User
								ply.newscoreboard.box_userinfo:Remove()
							end
							
							self:PlayerListCreate()
							local avatar_size = 32
							local row_height = avatar_size + 2
							local nick_Hsize
							local nick_Vsize
							local nick_Vpos
							local CurrentPanel_Hpos
							local CurrentPanel_Vpos
							local LastPanel_Hpos
							local LastPanel_Vpos
							local CurrentPanel_width
							local CurrentPanel_height
							local lower_country_code = "??"
							for k, data in ipairs(SortPlayersList(player.AllConnected)) do
								self.PlayerList.PlayerRows[k] = vgui.Create("DPanel", self.PlayerList)
								self.PlayerList.PlayerRows[k]:SetPos(0,(k-1)*(row_height+2))
								self.PlayerList.PlayerRows[k]:SetSize(self.PlayerList.Width, row_height)
								self.PlayerList.PlayerRows[k]:SetBackgroundColor(Color(255, 255, 255, 255)) -- test
								
								self.PlayerList.PlayerRows[k].Player = data:GetPlayerEnt()
								self.PlayerList.PlayerRows[k].PlayerData = data
								
								self.PlayerList.PlayerRows[k].AvatarButton = vgui.Create("DButton", self.PlayerList.PlayerRows[k])
								self.PlayerList.PlayerRows[k].AvatarButton:SetPos(1,1)
								self.PlayerList.PlayerRows[k].AvatarButton:SetSize(avatar_size, avatar_size)
								self.PlayerList.PlayerRows[k].AvatarButton.DoClick = function()
									if IsValid(self.PlayerList.PlayerRows[k].Player) then
										self.PlayerList.PlayerRows[k].Player:ShowProfile()
									elseif data.bot == 0 then
										gui.OpenURL("http://steamcommunity.com/profiles/"..util.SteamIDTo64(data.networkid).."/")
									end
								end
								
								self.PlayerList.PlayerRows[k].Avatar = vgui.Create("AvatarImage", self.PlayerList.PlayerRows[k].AvatarButton)
								self.PlayerList.PlayerRows[k].Avatar:SetPos(0,0)
								self.PlayerList.PlayerRows[k].Avatar:SetSize(avatar_size, avatar_size)
								if IsValid(self.PlayerList.PlayerRows[k].Player) then
									self.PlayerList.PlayerRows[k].Avatar:SetPlayer(self.PlayerList.PlayerRows[k].Player, avatar_size)
								end
								self.PlayerList.PlayerRows[k].Avatar:SetMouseInputEnabled(false) -- disabled click receiving so the button behind can receive clicks
								
								if data.bot == 0 then
									self.PlayerList.PlayerRows[k].Flag = vgui.Create("DImageButton", self.PlayerList.PlayerRows[k])
									if data.country and data.country ~= "-" and data.country ~= "lo" then
										lower_country_code = string.lower(data.country)
										self.PlayerList.PlayerRows[k].Flag:SetImage("materials/flags/"..lower_country_code.."_16.png")
										self.PlayerList.PlayerRows[k].Flag:SetSize(16, flag_height[lower_country_code])
									else
										self.PlayerList.PlayerRows[k].Flag:SetImage("html/img/viewonline.png")
										self.PlayerList.PlayerRows[k].Flag:SetSize(16, 16)
									end
									CurrentPanel_width, CurrentPanel_height = self.PlayerList.PlayerRows[k].Flag:GetSize()
									self.PlayerList.PlayerRows[k].Flag:SetPos(21, row_height-1-CurrentPanel_height)
									
									self.PlayerList.PlayerRows[k].Flag.DoClick = function ()
										local data = data
										display_box_userinfo(data)
									end
								end
								
								self.PlayerList.PlayerRows[k].Nick = vgui.Create("DLabel", self.PlayerList.PlayerRows[k])
								self.PlayerList.PlayerRows[k].Nick:SetFont("ScoreboardPlayerLine32")
								self.PlayerList.PlayerRows[k].Nick:SetTextColor(Color(93, 93, 93, 255))
								local Nick = GetBestNick(self.PlayerList.PlayerRows[k].PlayerData, self.PlayerList.PlayerRows[k].Nick)
								self.PlayerList.PlayerRows[k].Nick:SetText(Nick)
								self.PlayerList.PlayerRows[k].NickValue = Nick
								
								self.PlayerList.PlayerRows[k].Nick:SizeToContents()
								nick_Hsize, nick_Vsize = self.PlayerList.PlayerRows[k].Nick:GetSize()
								nick_Vpos = math.floor((row_height-nick_Vsize)/2)
								self.PlayerList.PlayerRows[k].Nick:SetPos(1+avatar_size+nick_Vpos, nick_Vpos)
								
								self.PlayerList.PlayerRows[k].Mute = vgui.Create("DImageButton", self.PlayerList.PlayerRows[k])
								self.PlayerList.PlayerRows[k].Mute:SetSize( 32, 32 )
								CurrentPanel_Hpos = self.PlayerList.Width-32-1-15 -- the last -15 is for the scrollbar
								self.PlayerList.PlayerRows[k].Mute:SetPos(CurrentPanel_Hpos, 1)
								LastPanel_Hpos = CurrentPanel_Hpos
								
								self.PlayerList.PlayerRows[k].Ping = vgui.Create("DLabel", self.PlayerList.PlayerRows[k])
								self.PlayerList.PlayerRows[k].Ping:SetWidth(50)
								self.PlayerList.PlayerRows[k].Ping:SetTextColor(Color(93, 93, 93, 255))
								self.PlayerList.PlayerRows[k].Ping:SetText("")
								self.PlayerList.PlayerRows[k].Ping:SetFont("ScoreboardPlayerLine32")
								self.PlayerList.PlayerRows[k].Ping:SetContentAlignment(8)
								CurrentPanel_Hpos = LastPanel_Hpos-50
								self.PlayerList.PlayerRows[k].Ping:SetPos(CurrentPanel_Hpos, nick_Vpos)
								LastPanel_Hpos = CurrentPanel_Hpos
								
								self.PlayerList.PlayerRows[k].Deaths = vgui.Create("DLabel", self.PlayerList.PlayerRows[k])
								self.PlayerList.PlayerRows[k].Deaths:SetWidth(50)
								self.PlayerList.PlayerRows[k].Deaths:SetTextColor(Color(93, 93, 93, 255))
								self.PlayerList.PlayerRows[k].Deaths:SetText("")
								self.PlayerList.PlayerRows[k].Deaths:SetFont("ScoreboardPlayerLine32")
								self.PlayerList.PlayerRows[k].Deaths:SetContentAlignment(8)
								CurrentPanel_Hpos = LastPanel_Hpos-50
								self.PlayerList.PlayerRows[k].Deaths:SetPos(CurrentPanel_Hpos, nick_Vpos)
								LastPanel_Hpos = CurrentPanel_Hpos
								
								self.PlayerList.PlayerRows[k].Kills = vgui.Create("DLabel", self.PlayerList.PlayerRows[k])
								self.PlayerList.PlayerRows[k].Kills:SetWidth(50)
								self.PlayerList.PlayerRows[k].Kills:SetTextColor(Color(93, 93, 93, 255))
								self.PlayerList.PlayerRows[k].Kills:SetText("")
								self.PlayerList.PlayerRows[k].Kills:SetFont("ScoreboardPlayerLine32")
								self.PlayerList.PlayerRows[k].Kills:SetContentAlignment(8)
								CurrentPanel_Hpos = LastPanel_Hpos-50
								self.PlayerList.PlayerRows[k].Kills:SetPos(CurrentPanel_Hpos, nick_Vpos)
								LastPanel_Hpos = CurrentPanel_Hpos
								
								self.PlayerList.PlayerRows[k].LostPackets = vgui.Create("DLabel", self.PlayerList.PlayerRows[k])
								self.PlayerList.PlayerRows[k].LostPackets:SetWidth(75)
								self.PlayerList.PlayerRows[k].LostPackets:SetTextColor(Color(93, 93, 93, 255))
								self.PlayerList.PlayerRows[k].LostPackets:SetText("")
								self.PlayerList.PlayerRows[k].LostPackets:SetFont("ScoreboardPlayerLine32")
								self.PlayerList.PlayerRows[k].LostPackets:SetContentAlignment(8)
								CurrentPanel_Hpos = LastPanel_Hpos-75
								self.PlayerList.PlayerRows[k].LostPackets:SetPos(CurrentPanel_Hpos, nick_Vpos)
								LastPanel_Hpos = CurrentPanel_Hpos
							end
							self.ShouldCleanup = false
							
							-- Recreate the removed boxes (at the foreground now)
							if box_credits_displayed then
								display_box_credits()
							end
							if box_userinfo_data then
								display_box_userinfo(box_userinfo_data, true)
							end
						end
						
						-- This part is executed on each refresh.
						if IsValid(self.PlayerList) then
							self.ServerName:SetText(language_translate("You are playing on: ")..GetHostName())
							self.ServerName:SizeToContents()
							
							local color
							local previous_state
							for k, PlayerRow in ipairs(self.PlayerList.PlayerRows) do
								previous_state = PlayerRow.state
								color, PlayerRow.state = GetPlayerRowColor(PlayerRow.Player, PlayerRow.PlayerData)
								if ( not PlayerRow.BgColor or PlayerRow.BgColor~=color ) then
									local ScoreBoardOrder = tonumber(GetGlobalString("pgl_orderbystatus", "0"))
									if PlayerRow.BgColor and ( ScoreBoardOrder==1 or ScoreBoardOrder==2 ) then
										self.OrderChanged = true
									end
									PlayerRow.BgColor = color
									PlayerRow:SetBackgroundColor(PlayerRow.BgColor)
								end
								
								if IsValid(PlayerRow.Player) then
									if previous_state ~= PlayerRow.state then
										-- The nick is only refreshed in some cases.
										-- local SteamID64 = PlayerRow.Player:SteamID64() -- will return nothing for bots
										-- if SteamID64 and PlayerRow.PlayerData.bot == 0 then
											-- Nick = steamworks.GetPlayerName(SteamID64)
										-- end
										-- if not Nick or PlayerRow.PlayerData.bot == 1 then
											-- Nick = PlayerRow.PlayerData.name
										-- end
										local Nick = GetBestNick(PlayerRow.PlayerData, PlayerRow.Nick)
										if previous_state == STATUS_LOADING then
											self.ShouldCleanup = true
										elseif PlayerRow.state == STATUS_DEAD then -- the player just died
											-- do nothing
										elseif PlayerRow.state == STATUS_SPECTATOR then -- the player just became spectator
											if not PlayerRow.NickValue or PlayerRow.NickValue~=Nick then
												PlayerRow.Nick:SetText(Nick)
												PlayerRow.Nick:SizeToContents()
												PlayerRow.NickValue = Nick
												-- print("Nick refreshed") -- debug
											end
										elseif PlayerRow.state == STATUS_ALIVE then -- the player just spawned
											if not PlayerRow.NickValue or PlayerRow.NickValue~=Nick then
												PlayerRow.Nick:SetText(Nick)
												PlayerRow.Nick:SizeToContents()
												PlayerRow.NickValue = Nick
												-- print("Nick refreshed") -- debug
											end
										elseif PlayerRow.Nick.IsDirtyValue then
											PlayerRow.Nick:SetText(Nick)
											PlayerRow.Nick:SizeToContents()
											PlayerRow.NickValue = Nick
											-- print("Nick refreshed (dirty value)") -- debug
										end
									end
									
									if not ply.newscoreboard.LostPackets[PlayerRow.PlayerData.userid] then
										if not PlayerRow.NumPacketLoss or PlayerRow.NumPacketLoss~=ply.newscoreboard.LostPackets[PlayerRow.PlayerData.userid] then
											PlayerRow.NumPacketLoss = ply.newscoreboard.LostPackets[PlayerRow.PlayerData.userid] or 0
											PlayerRow.LostPackets:SetText(PlayerRow.NumPacketLoss.."%")
										end
									end
									
									if ( not PlayerRow.NumKills or PlayerRow.NumKills~=PlayerRow.Player:Frags() ) then
										PlayerRow.NumKills = PlayerRow.Player:Frags()
										PlayerRow.Kills:SetText( PlayerRow.NumKills )
									end
									
									if ( not PlayerRow.NumDeaths or PlayerRow.NumDeaths~=PlayerRow.Player:Deaths() ) then
										PlayerRow.NumDeaths = PlayerRow.Player:Deaths()
										PlayerRow.Deaths:SetText( PlayerRow.NumDeaths )
									end
									
									if ( not PlayerRow.NumPing or PlayerRow.NumPing~=PlayerRow.Player:Ping() ) then
										PlayerRow.NumPing = PlayerRow.Player:Ping()
										PlayerRow.Ping:SetText( PlayerRow.NumPing )
									end
									
									if ( PlayerRow.Muted==nil or PlayerRow.Muted~=PlayerRow.Player:IsMuted() ) then
										PlayerRow.Muted = PlayerRow.Player:IsMuted()
										if ( PlayerRow.Muted ) then
											PlayerRow.Mute:SetImage( "icon32/muted.png" )
										else
											PlayerRow.Mute:SetImage( "icon32/unmuted.png" )
										end
										
										PlayerRow.Mute.DoClick = function()
											if IsValid (PlayerRow.Player) then
												PlayerRow.Player:SetMuted( not PlayerRow.Muted )
											end
										end
									end
								end
							end
						end
					end
					ply.newscoreboard:Update(true)
					
				end
				if IsValid(ply.newscoreboard) then
					ply.newscoreboard.ShouldHideCursor = (not vgui.CursorVisible())
					if ply.newscoreboard.ShouldHideCursor then
						gui.EnableScreenClicker(true)
					end
					ply.newscoreboard.ActiveRefresh = true
					ply.newscoreboard:Show()
				end
				return true
			end
		end)
		
		-- function GAMEMODE:ScoreboardHide()
		hook.Add("ScoreboardHide", "pgl_newscoreboard_hide", function ()
			if IsOldScoreboardInUse then
				-- old_hide_func(self) -- Old scoreboard: hide
			else
				local ply = LocalPlayer()
				if IsValid(ply.newscoreboard) then
					if ply.newscoreboard.ShouldHideCursor then
						gui.EnableScreenClicker(false)
						ply.newscoreboard.ShouldHideCursor = false
					end
					ply.newscoreboard.ActiveRefresh = false
					ply.newscoreboard:Hide()
				end
				return true
			end
		end)
	end
	
	if GAMEMODE then
		LoadNewScoreboard()
	else
		hook.Add("Initialize", "pgl_newscoreboard_2", function ()
			LoadNewScoreboard()
		end)
	end
end
