// server side apple
if CLIENT then return end
AddCSLuaFile( "cl_player.lua"  )

if file.Exists( "apple_join_disconnect_warning/indicate.txt", "DATA" ) == false then
	file.CreateDir("apple_join_disconnect_warning")
	file.Write( "apple_join_disconnect_warning/indicate.txt", "1" )
end


//Connected
function PlayerConnectAnnouncement( ply, ip )
	for k,v in pairs(player.GetAll()) do
		umsg.Start( "PlayerConnectAnnouncement", v)
			umsg.String(ply)
			umsg.String(file.Read( "apple_join_disconnect_warning/indicate.txt" ))
		umsg.End()
	end
Msg("Player " .. ply .. " has connected to the server.\n")
end
hook.Add( "PlayerConnect", "PlayerConnectAnnouncement", PlayerConnectAnnouncement )

//Spawn
function PlayerInitialSpawnAnnouncement( ply )
	timer.Simple( 3, function()
	if !ply:IsValid() then return end
	for k,v in pairs(player.GetAll()) do
		if v:IsAdmin() then
		--	if ply:IsBot() then return end
			umsg.Start( "PlayerInitialSpawnAnnouncement", v)
				umsg.String(ply:Nick())
				umsg.Short(ply:Team())
				umsg.String(ply:SteamID())
				umsg.String(file.Read( "apple_join_disconnect_warning/indicate.txt" ))
			umsg.End()
			else
			umsg.Start( "PlayerInitialSpawnAnnouncement2", v)
				umsg.String(ply:Nick())
				umsg.Short(ply:Team())
				umsg.String(file.Read( "apple_join_disconnect_warning/indicate.txt" ))
			umsg.End()
		end
	end
Msg("Player " .. ply:Nick() .. " has spawned in the server.\n")
end)
end
hook.Add( "PlayerInitialSpawn", "PlayerInitialSpawnAnnouncement", PlayerInitialSpawnAnnouncement )

 
//Disconnect
function PlayerDisconnectAnnouncement( ply )
	for k,v in pairs(player.GetAll()) do
		if v:IsAdmin() then
			if ply:IsBot() then return end
			umsg.Start( "PlayerDisconnectAnnouncement", v)
			umsg.String(ply:Nick())
			umsg.Short(ply:Team())
			umsg.String(ply:SteamID())
			umsg.String(file.Read( "apple_join_disconnect_warning/indicate.txt" ))
			umsg.End()
		else
			umsg.Start( "PlayerDisconnectAnnouncement2", v)
			umsg.String(ply:Nick())
			umsg.Short(ply:Team())
			umsg.String(file.Read( "apple_join_disconnect_warning/indicate.txt" ))
			umsg.End()
		end
	end
Msg("Player " .. ply:Nick() .. " has left the server.\n")
end
hook.Add( "PlayerDisconnected", "PlayerDisconnectAnnouncement", PlayerDisconnectAnnouncement )



concommand.Add( "jd_sounds", function(ply, cmd, args)
	if ply:IsPlayer() == false || ply:IsSuperAdmin() == false then 
		MsgC(Color(255,0,0,255),"Either console has attempted to turn sounds off, or a player is attempting to turn sounds off for apple_join_disonnect_warning addon!")
	return end
	if tostring(args[1]) == "on" then
		file.Write( "apple_join_disconnect_warning/indicate.txt", "1" )
		umsg.Start( "PlayerJDAnnouncement", ply)
			umsg.String("You have turned on sounds for: Apples_Join_Disconnect_Warning")
		umsg.End()
	elseif tostring(args[1]) == "off" then
		file.Write( "apple_join_disconnect_warning/indicate.txt", "0" )
		umsg.Start( "PlayerJDAnnouncement", ply)
			umsg.String("You have turned off sounds for: Apples_Join_Disconnect_Warning")
		umsg.End()
	else
		umsg.Start( "PlayerJDAnnouncement", ply)
			umsg.String("There are only two options, on or off. You selected '"..tostring(args[1]).."' which is not a valid option!")
		umsg.End()
	end
end)





if SERVER then
local YOUR_VERSION = "1.11"
local PLY2 = "105"
local ADDON_NAME = "join_disconnect"
local ADDON_ACTUAL_NAME = "apple_join_disconnect_warning"
local DOWNLOAD_LINK = "http://goo.gl/VitT7Z"
local MESSAGE_TO_SERVER = "APPLE'S JOIN/DISCONNECT MESSAGE"

hook.Add('PlayerInitialSpawn','PlayerInitialSpawn'..ADDON_NAME, function(ply)
http.Fetch( "https://raw.githubusercontent.com/chaos12135/gmod-development/master/branches/"..ADDON_NAME..".txt", function( body, len, headers, code )
if body == nil then return end
local body = string.Explode(" ",body)
	if tostring(body[1]) != tostring("Version") then return end
	if tonumber(body[2]) != tonumber(YOUR_VERSION) then
		if ply:GetPData(ADDON_NAME..""..PLY2) != nil || ply:GetPData(ADDON_NAME..""..PLY2) != "1" && ply:IsSuperAdmin() == true then
			umsg.Start(ADDON_NAME, ply)
				umsg.String(YOUR_VERSION)
				umsg.String(body[2])
				umsg.String(ADDON_ACTUAL_NAME)
				umsg.String(DOWNLOAD_LINK)
			umsg.End()
		end
		
		MsgC("\n",Color(255,0,0,255),"- - OUT OF DATE - -","\n")
		MsgN("~"..MESSAGE_TO_SERVER.."~")
		MsgC(Color(255,255,255,255),"Your Version: ",Color(255,0,0,255),YOUR_VERSION,"\n")
		MsgC(Color(255,255,255,255),"Online Version: ",Color(255,0,0,255),body[2])
		MsgN("We here at Apple Inc. strongly suggest that you keep this addon updated")
		MsgC(Color(255,255,255,255),"Please go here and update: ",Color(0,255,255,255),""..DOWNLOAD_LINK.."\n")
	end
end, 
function( error )
	MsgN("DOESNOT WORK")
end)
end)
net.Receive( ADDON_NAME, function( length, client )
	net.ReadEntity():SetPData(ADDON_NAME..""..PLY2,"1")
end )
util.AddNetworkString( ADDON_NAME )
end