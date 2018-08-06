--** To make this file fully working, you need to download the IP location CSV database.
	-- You can download it at http://lite.ip2location.com/database-ip-country-region-city
	-- Then extract the .CSV file in garrysmod/data/geolocation/IP2LOCATION-LITE-DB3.CSV
	-- Do not forget to update it every month!
--** You can use: ulx luarun "print(table.ToString(geoip.GetIpInfo('127.0.0.1'), 'GetIpInfo', true))" in console to test if you can get an IP address (with ULX installed).

--- Use a 512 KB cache everywhere needed (all files). Refer to Drive All Vehicles Models. Ne pas oublier les seeks et compagnie.
--- The embedded database should be written in hex format, not in dec format. It will be much smaller after that.
--- Vérifier les sauts de ligne lors de la lecture du fichier.


geoip = {}
-- Constants to index the geoip.database table without named indexes
-- If you ever want to use a CSV file with another order, modify them. For unused fields, simply omit them.
geoip.ip_from = 1
geoip.ip_to = 2
geoip.country_code = 3
geoip.country_name = 4
geoip.region_name = 5
geoip.city_name = 6
if CLIENT then
	function geoip.GetUserIDInfo( UserID )
		net.Start( "GeoGetUserIDInfo" )
			net.WriteUInt( UserID, 32 )
		net.SendToServer()
	end
	net.Receive( "GeoGetUserIDInfo", function()
		local UserID = net.ReadUInt( 32 )
		local data
		for _,v in ipairs( player.AllConnected ) do
			if v.userid==UserID then
				data = v
				break
			end
		end
		if data then
			data.geoip = {}
			data.geoip[geoip.country_code] = net.ReadString()
			data.geoip[geoip.country_name] = net.ReadString()
			data.geoip[geoip.region_name] = net.ReadString()
			data.geoip[geoip.city_name] = net.ReadString()
			if string.len( data.geoip[geoip.country_code] )==0 then
				data.geoip = nil
			end
			data.language = net.ReadString()
		end
	end )
	
	
	--++ Mise à jour de la langue
	local hl
	cvars.AddChangeCallback( "gmod_language", function( convar, oldValue, newValue )
		hl = newValue
	end, "GeoUpdateLanguage" )
	hl = GetConVar( "gmod_language" ):GetString()
	local next_send_language = 0
	hook.Add( "Tick", "GeoUpdateLanguage", function()
		if CurTime()>next_send_language then
			net.Start( "GeoUpdateLanguage" )
				net.WriteString( hl )
			net.SendToServer()
			next_send_language = CurTime()+5
		end
	end )
end
if SERVER then
	-- Table with seek references to the source CSV file
	geoip.seek_ip = {}
	-- Table with the cached IP addresses (necessary when requiring several pieces of information)
	geoip.cache = {}
	-- Source CSV file
	if not file.Exists( "geolocation", "DATA" ) then
		file.CreateDir( "geolocation" )
	end
	if file.Exists( "geolocation/IP-COUNTRY-REGION-CITY.CSV", "DATA" ) then
		geoip.CSV_source = "geolocation/IP-COUNTRY-REGION-CITY.CSV"
	elseif file.Exists( "geolocation/ip-country-region-city.csv", "DATA" ) then
		geoip.CSV_source = "geolocation/ip-country-region-city.csv"
	elseif file.Exists( "geolocation/IP2LOCATION-LITE-DB3.CSV", "DATA" ) then
		geoip.CSV_source = "geolocation/IP2LOCATION-LITE-DB3.CSV"
	elseif file.Exists( "geolocation/ip2location-lite-db3.csv", "DATA" ) then
		geoip.CSV_source = "geolocation/ip2location-lite-db3.csv"
	elseif file.Exists( "geolocation/IP-COUNTRY.CSV", "DATA" ) then
		geoip.CSV_source = "geolocation/IP-COUNTRY.CSV"
	elseif file.Exists( "geolocation/ip-country.csv", "DATA" ) then
		geoip.CSV_source = "geolocation/ip-country.csv"
	elseif file.Exists( "geolocation/IP2LOCATION-LITE-DB1.CSV", "DATA" ) then
		geoip.CSV_source = "geolocation/IP2LOCATION-LITE-DB1.CSV"
	elseif file.Exists( "geolocation/ip2location-lite-db1.csv", "DATA" ) then
		geoip.CSV_source = "geolocation/ip2location-lite-db1.csv"
	else
		geoip.CSV_source = "geolocation/internal-includeddb1.txt"
		geoip.CSV_IncludedDB1 = true
		include( "gengeolightdb.lua" )
	end
	-- Source CSV stream (stays open until LUA is shut down)
	geoip.CSV_stream = nil
	
	
	util.AddNetworkString( "GeoGetUserIDInfo" )
	local function SendUserIDInfo( UserID, ply )
		local data
		for _,v in ipairs( player.AllConnected ) do
			if v.userid==UserID then
				data = v
				break
			end
		end
		if data then
			net.Start( "GeoGetUserIDInfo" )
			local current_line_info
			current_line_info = geoip.GetIpInfo( data.address )
			net.WriteUInt( data.userid, 32 )
			if current_line_info then
				net.WriteString( current_line_info[geoip.country_code] )
				if current_line_info[geoip.country_name] then
					net.WriteString( current_line_info[geoip.country_name] )
				else
					net.WriteString( "" )
				end
				if current_line_info[geoip.region_name] then
					net.WriteString( current_line_info[geoip.region_name] )
				else
					net.WriteString( "" )
				end
				if current_line_info[geoip.city_name] then
					net.WriteString( current_line_info[geoip.city_name] )
				else
					net.WriteString( "" )
				end
			else
				net.WriteString( "" )
				net.WriteString( "" )
				net.WriteString( "" )
				net.WriteString( "" )
			end
			if data.language then
				net.WriteString( data.language )
			else
				net.WriteString( "" )
			end
			net.Send( ply )
		end
	end
	net.Receive( "GeoGetUserIDInfo", function( length, client )
		local UserID = net.ReadUInt( 32 )
		SendUserIDInfo( UserID, client )
	end )
	
	
	util.AddNetworkString( "GeoUpdateLanguage" )
	net.Receive( "GeoUpdateLanguage", function(length, client)
		local UserID = client:UserID()
		for _, data in ipairs( player.AllConnected ) do
			if data.userid==UserID then
				data.language = net.ReadString()
				break
			end
		end
	end )
	
	
	AddCSLuaFile()
	
	
	-- Set in cache the countries, the regions, and the complete database is a text file (LUA content).
	if file.Exists( geoip.CSV_source, "DATA" ) then
		MsgN( "\nLoading IP location CSV database..." )
		
		
		-- Prepare a few functions to allow manipulations in files.
		-- This is a workaround to the buggy ReadLong et WriteLong methods which fail after some usages.
		local function WriteString( stream, towrite )
			stream:Write( tostring( towrite ).."\0" )
		end
		local function ReadString( stream, StopOnNewLine )
			local readchar = stream:Read( 1 )
			local result = ""
			while readchar and readchar~="\0" and ( not StopOnNewLine or readchar~="\n" ) do
				result = result..readchar
				readchar = stream:Read( 1 )
			end
			return result
		end
		
		
		-- Try to read the cache file to find seek positions
		if file.Exists( "geolocation/seek_cache.txt", "DATA" ) then
			MsgN( "Loading seek cache for IP location CSV database..." )
			local seek_cache = file.Open( "geolocation/seek_cache.txt", "r", "DATA" )
			if seek_cache then
				local CSV_last_time = tonumber( ReadString( seek_cache ) )
				local CSV_last_size = tonumber( ReadString( seek_cache ) )
				local seek_number = tonumber( ReadString( seek_cache ) )
				if CSV_last_time and CSV_last_size and seek_number and CSV_last_time==file.Time( geoip.CSV_source, "DATA" ) and CSV_last_size==file.Size( geoip.CSV_source, "DATA" ) and seek_number>0 then
					MsgN( "There are "..seek_number.." seek values to load." )
					for i=1,seek_number do
						geoip.seek_ip[i] = {}
						geoip.seek_ip[i][1] = tonumber( ReadString( seek_cache ) )
						geoip.seek_ip[i][2] = tonumber( ReadString( seek_cache ) )
						if not geoip.seek_ip[i][1] or not geoip.seek_ip[i][2] then
							ErrorNoHalt( "An error occured at the "..i.."th cached seek.\n" )
							break
						end
					end
					MsgN( "There are "..#geoip.seek_ip.." seek values loaded." )
				end
				seek_cache:Close()
				if #geoip.seek_ip~=0 and #geoip.seek_ip==seek_number then
					MsgN( "The seek cache has been loaded." )
				else
					geoip.seek_ip = {}
					MsgN( "The seek cache needs to be updated." )
				end
			else
				MsgN( "The seek cache is invalid." )
			end
		else
			MsgN( "The seek cache does not exist yet." )
		end
		
		
		-- Try to read the CSV file to find seek positions
		if #geoip.seek_ip==0 then
			geoip.CSV_stream = file.Open( geoip.CSV_source, "r", "DATA" )
			if geoip.CSV_stream then
				local readchar = "#"
				local current_read_value = ""
				local current_field = 1
				
				local current_seek = 0
				local end_seek = geoip.CSV_stream:Size()
				local seek_ref_length = math.floor( end_seek/16384 ) -- 16384 is the approximative number of seek references (to read the file much faster, at a place close to the requested information)
				
				-- Progress bar
				local progress_bar_length = 0
				MsgN( "0%         25%         50%          75%       100%" ) -- length=50
				local function UpdateProgressBar()
					local ShouldShowLength = math.floor( ( current_seek/end_seek )*50 )
					if progress_bar_length~=ShouldShowLength then
						for i=1,ShouldShowLength-progress_bar_length do
							Msg( "#" )
						end
						progress_bar_length = ShouldShowLength
					end
				end
				
				-- If special characters are inside fields, the following stuff will fail because there's no escape treatment.
				readchar = geoip.CSV_stream:Read( 1 )
				local is_complete_line -- changes the behaviour of the new line detection
				if not geoip.CSV_IncludedDB1 then
					is_complete_line = true -- 1st line is not a comment line
				else
					is_complete_line = false -- 1st line is equal to comment line
				end
				local current_line_info = {}
				local start_line_seek=current_seek
				while readchar and string.len( readchar )~=0 do -- always do an end-of-file check based on the seek, otherwise an error will be returned!
					if readchar=='"' or readchar=="\r" then
						-- ignoring
					elseif readchar=="," then
						-- next database field
						current_line_info[current_field] = current_read_value
						
						current_read_value = ""
						current_field = current_field+1
					elseif readchar=="\n" then
						-- next database row
						if is_complete_line and current_line_info[1] and string.len( current_line_info[1] )~=0 then
							current_line_info[current_field] = current_read_value
							-- record seek info
							geoip.seek_ip[#geoip.seek_ip+1] = {tonumber( current_line_info[geoip.ip_from] ), start_line_seek}
							
							geoip.CSV_stream:Skip( seek_ref_length ) -- progress in the file by seek_ref_length bytes
							current_seek = current_seek+seek_ref_length
							
							is_complete_line = false
						else
							-- read the next line to find a complete one
							start_line_seek = current_seek
							is_complete_line = true
						end
						current_line_info = {}
						current_read_value = ""
						current_field = 1
						
						UpdateProgressBar()
					else
						-- add character
						current_read_value = current_read_value..readchar
					end
					
					readchar = geoip.CSV_stream:Read( 1 )
					current_seek = current_seek+1
				end
				Msg( "#\n" )
				
				geoip.CSV_stream:Seek( 0 )
				
				
				-- Write the seek cache
				MsgN( "Writing seek cache for IP location CSV database..." )
				local seek_cache = file.Open( "geolocation/seek_cache.txt", "w", "DATA" )
				if seek_cache then
					WriteString( seek_cache, file.Time( geoip.CSV_source, "DATA" ) ) -- signed timestamp!
					WriteString( seek_cache, file.Size( geoip.CSV_source, "DATA" ) )
					WriteString( seek_cache, #geoip.seek_ip )
					for i=1,#geoip.seek_ip do
						WriteString( seek_cache, geoip.seek_ip[i][1] )
						WriteString( seek_cache, geoip.seek_ip[i][2] )
					end
					seek_cache:Close()
					MsgN( "Writing seek cache is finished." )
				else
					ErrorNoHalt( "Unable to open the seek cache for write operation.\n" )
				end
			end
		end
		
		
		if #geoip.seek_ip>0 then
			Msg( "There are "..#geoip.seek_ip.." seek positions." )
			
			
			local function SetFieldValue( info_table, current_field, value )
				if current_field==geoip.ip_from or current_field==geoip.ip_to then
					info_table[current_field] = tonumber( value ) -- set value
				else
					info_table[current_field] = value -- set value
				end
			end
			-- Convert IP address to numeric value
			local function IpToNumber( address )
				local address = address
				if address=="loopback" or address=="none" or address=="Error!" then
					address = "127.0.0.1"
				end
				address = string.Split( address, ":" )[1] -- removes the port number
				address = string.Split( address, "." )
				if address[4] then -- certainly a valid IP address
					return address[1]*256*256*256 + address[2]*256*256 + address[3]*256 + address[4]
				else -- invalid IP address
					return nil
				end
			end
			-- Get information about an IP address
			function geoip.GetIpInfo( address ) -- If you specify a port number, it will be correctly bypassed.
				local address = IpToNumber( address )
				if not address then return nil end
				
				-- If this is a LAN or local player, use server's country flag.
				if ( address==2130706433 ) -- 127.0.0.1
				or ( address>=167772160 and address<=184549375 ) -- 10.0.0.0/8
				or ( address>=2851995648 and address<=2852061183 ) -- 169.254.0.0/16
				or ( address>=2886729728 and address<=2887778303 ) -- 172.16.0.0~172.31.255.255
				or ( address>=3232235520 and address<=3232301055 ) then -- 192.168.0.0/16
					current_ip_data = {}
					current_ip_data[geoip.ip_from] = address
					current_ip_data[geoip.ip_to] = address
					current_ip_data[geoip.country_code] = "lo"
					if geoip.country_name then current_ip_data[geoip.country_name] = "Server's local network" end
					if geoip.region_name then current_ip_data[geoip.region_name] = "" end
					if geoip.city_name then current_ip_data[geoip.city_name] = "" end
					local serverip = game.GetIPAddress()
					if serverip and string.len( serverip )~=0 then
						local serveraddress = IpToNumber( serverip )
						if not serveraddress then
							address = serveraddress -- valid server IP address
						else
							return current_ip_data
						end
					else
						return current_ip_data
					end
				end
				
				-- Try to find IP information in the cache:
				if geoip.cache[address] then
					-- found exact IP
					return geoip.cache[address]
				end
				for _,current_ip_data in pairs( geoip.cache ) do
					if address>=current_ip_data[geoip.ip_from] and address<=current_ip_data[geoip.ip_to] then
						-- found IP range
						geoip.cache[address] = current_ip_data
						return current_ip_data
					end
				end
				
				-- Try to find IP information in the CSV database.
				if file.Exists( geoip.CSV_source, "DATA" ) then
					if not geoip.CSV_stream then -- maybe if the file was closed unexpectedly this won't be nil or false
						geoip.CSV_stream = file.Open( geoip.CSV_source, "r", "DATA" )
					end
					if geoip.CSV_stream then
						geoip.CSV_stream:Seek( 0 )
						-- Look in the geoip.seek_ip table to find where to search for the IP range in the CSV database. This only works if the CSV file is sorted in ascending order.
						local index_seek_ip = 0
						for i=#geoip.seek_ip,1,-1 do
							if address>=geoip.seek_ip[i][1] then -- found entry
								index_seek_ip = geoip.seek_ip[i][2]
								break
							end
						end
						
						
						-- Look in the CSV database for the required IP range.
						-- If special characters are inside fields, the following stuff will fail because there's no escape treatment.
						local current_ip_data = {}
						local previous_ip_data = {}
						local result_ip_data = nil
						
						local readchar = "#"
						local current_read_value = ""
						local current_field = 1
						geoip.CSV_stream:Seek( index_seek_ip )
						readchar = geoip.CSV_stream:Read( 1 )
						while readchar and string.len( readchar )~=0 do -- always do an end-of-file check based on the seek, otherwise an error will be thrown!
							if readchar=='"' or readchar=="\r" then
								-- ignoring
							elseif readchar=="," then
								-- next database field
								SetFieldValue( current_ip_data, current_field, current_read_value ) -- save field
								current_read_value = ""
								current_field = current_field+1
							elseif readchar=="\n" then
								-- next database row
								SetFieldValue( current_ip_data, current_field, current_read_value ) -- save field
								current_read_value = ""
								current_field = 1
								
								-- Check if the line is the one that is required
								if current_ip_data[geoip.ip_from] and current_ip_data[geoip.ip_to]
								and address >= current_ip_data[geoip.ip_from] and address<=current_ip_data[geoip.ip_to] then -- found!
									result_ip_data = current_ip_data
									geoip.cache[address] = current_ip_data
									break
								else -- continue searching!
									previous_ip_data = current_ip_data
									current_ip_data = {}
								end
							else
								-- add character
								current_read_value = current_read_value..readchar
							end
							
							readchar = geoip.CSV_stream:Read( 1 )
						end
						-- geoip.CSV_stream:Close()
						geoip.CSV_stream:Seek( 0 )
						return result_ip_data
					else
						ErrorNoHalt( "Error while trying to read the IP location CSV database.\n" )
						return nil
					end
				else
					return nil
				end
			end
			
			
			MsgN( "\nFinished loading IP location CSV database.\n" )
		else
			function geoip.GetIpInfo()
				return nil
			end
			
			
			ErrorNoHalt( "Failed loading IP location CSV database!\n\n" )
		end
	else
		function geoip.GetIpInfo()
			return nil
		end
		
		
		ErrorNoHalt( "\nThe IP location CSV database is missing.\nYou can download it at\n\thttp://lite.ip2location.com/database-ip-country-region-city\nThen extract the .CSV file at\n\tgarrysmod/data/"..geoip.CSV_source.."\nDo not forget to update it every month!\n\n" )
	end
end