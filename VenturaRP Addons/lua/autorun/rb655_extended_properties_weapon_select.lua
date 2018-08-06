
AddCSLuaFile()

local function GiveWeapon( ply, ent, t )
	if ( !t || !t[ 1 ] || !isstring( t[ 1 ] ) ) then return end

	local swep = list.Get( "Weapon" )[ t[ 1 ] ]
	if ( swep == nil && t[ 1 ] == "weapon_alyxgun" ) then swep = { ClassName = "weapon_alyxgun", PrintName = "#weapon_alyxgun", Category = "Half-Life 2", Author = "VALVe", Spawnable = true } end
	if ( swep == nil ) then return end

	if ( ( !swep.Spawnable && !ply:IsAdmin() ) || ( swep.AdminOnly && !ply:IsAdmin() ) ) then return end
	if ( !hook.Run( "PlayerGiveSWEP", ply, t[ 1 ], swep ) ) then return end

	ent:Give( t[1] )
	if ( SERVER ) then duplicator.StoreEntityModifier( ent, "rb655_npc_weapon", t ) end
end
duplicator.RegisterEntityModifier( "rb655_npc_weapon", GiveWeapon )

local function changeWep( it, ent, wep )
	it:MsgStart()
		net.WriteEntity( ent )
		net.WriteString( wep )
	it:MsgEnd()
end

local nowep = {
	"cycler",

	"npc_seagull", "npc_crow", "npc_piegon", "npc_rollermine", "npc_turret_floor", "npc_stalker",
	"npc_combine_camera", "npc_turret_ceiling", "npc_cscanner", "npc_clawscanner", "npc_manhack", "npc_sniper",
	"npc_combinegunship", "npc_combinedropship", "npc_helicopter", "npc_antlion_worker", "npc_headcrab_black",
	"npc_hunter", "npc_vortigaunt", "npc_antlion", "npc_antlionguard", "npc_barnacle", "npc_headcrab",
	"npc_dog", "npc_gman", "npc_antlion_grub", "npc_strider", "npc_fastzombie", "npc_fastzombie_torso",
	"npc_headcrab_poison", "npc_headcrab_fast", "npc_poisonzombie", "npc_zombie", "npc_zombie_torso", "npc_zombine",

	// HLS
	"monster_scientist", "monster_zombie", "monster_headcrab", "class C_AI_BaseNPC", "monster_tentacle",
	"monster_alien_grunt", "monster_alien_slave", "monster_human_assassin", "monster_babycrab", "monster_bullchicken",
	"monster_cockroach", "monster_alien_controller", "monster_gargantua", "monster_bigmomma", "monster_human_grunt",
	"monster_houndeye", "monster_nihilanth", "monster_barney", "monster_snark"
}

AddEntFunctionProperty( "rb655_npc_weapon_strip", "Strip Weapon", 651, function( ent )
	if ( ent:IsNPC() && IsValid( ent:GetActiveWeapon() ) && !table.HasValue( nowep, ent:GetClass() ) ) then return true end
	return false
end, function( ent )
	ent:GetActiveWeapon():Remove()
end, "icon16/gun.png" )

properties.Add( "rb655_npc_weapon", {
	MenuLabel = "Change Weapon ( Popup )",
	MenuIcon = "icon16/gun.png",
	Order = 650,
	Filter = function( self, ent, ply ) 
		if ( !IsValid( ent ) or !gamemode.Call( "CanProperty", ply, "rb655_npc_weapon", ent ) ) then return false end
		if ( ent:IsNPC() && !table.HasValue( nowep, ent:GetClass() ) ) then return true end
		return false 
	end,
	Action = function( self, ent )
		if ( !IsValid( ent ) ) then return false end
	
		local frame = vgui.Create( "DFrame" )
		frame:SetSize( ScrW() / 1.2, ScrH() / 1.2 )
		frame:SetTitle( "Change weapon of " .. language.GetPhrase( "#" .. ent:GetClass() ) .. " - WARNING! Not all NPCs can use weapons and not all weapons are usable by NPCs" )
		frame:Center()
		
		frame:MakePopup()

		frame:SetDraggable( false )
		
		function frame:Paint( w, h )
			Derma_DrawBackgroundBlur( self, self.m_fCreateTime )
			draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 200 ) )
		end
		
		local PropPanel = vgui.Create( "ContentContainer", frame )
		PropPanel:SetVisible( true )
		PropPanel:SetTriggerSpawnlistChange( false )
		PropPanel:SetPos( 5, 27 )
		PropPanel:SetSize( ScrW() / 1.2 - 10, ScrH() / 1.2 - 32 )

		local Weapons = list.Get( "Weapon" )
		local Categorised = {}
		
		Categorised[ "Half-Life 2" ] = { { PrintName = "#weapon_alyxgun", ClassName = "weapon_alyxgun" } }
		language.Add( "weapon_alyxgun", "Alyx gun" )

		for k, weapon in pairs( Weapons ) do
			if ( !weapon.Spawnable && !weapon.AdminSpawnable ) then continue end

			Categorised[ weapon.Category ] = Categorised[ weapon.Category ] or {}
			table.insert( Categorised[ weapon.Category ], weapon )
		end

		Weapons = nil

		for CategoryName, v in SortedPairs( Categorised ) do
			local Header = vgui.Create( "ContentHeader", PropPanel )
			Header:SetText( CategoryName )
			PropPanel:Add( Header )

			for k, WeaponTable in SortedPairsByMemberValue( v, "PrintName" ) do
				if ( WeaponTable.AdminOnly && !LocalPlayer():IsAdmin() ) then continue end
			
				local icon = vgui.Create( "ContentIcon", PropPanel )
				icon:SetMaterial( "entities/" .. WeaponTable.ClassName .. ".png" )
				icon:SetName( WeaponTable.PrintName or "#" .. WeaponTable.ClassName )
				icon:SetAdminOnly( WeaponTable.AdminOnly or false )

				icon.DoClick = function()
					changeWep( self, ent, WeaponTable.ClassName )
					frame:Close()
				end
				
				PropPanel:Add( icon )
			end
		end
	end,
	Receive = function( self, length, ply )
		local ent = net.ReadEntity()
		if ( !IsValid( ent ) ) then return end
		if ( !ent:IsNPC() or table.HasValue( nowep, ent:GetClass() ) ) then return end

		local wep = net.ReadString()

		GiveWeapon( ply, ent, { wep } )
	end
} )
