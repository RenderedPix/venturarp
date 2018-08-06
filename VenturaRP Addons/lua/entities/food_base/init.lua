--[[
	Food Mod Base v2
	
	Author: KoZ
	Profile: http://steamcommunity.com/id/drunkenkoz
]]--
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include( "shared.lua" )

function ENT:SpawnFunction( ply, tr, class )
	if ( !tr.Hit ) then return end
	local pos = tr.HitPos + tr.HitNormal * 4
	local ent = ents.Create( class )
	ent:SetPos( pos )
	ent:Spawn()
	ent:Activate()
	return ent
end

function ENT:Initialize()
	self:SetModel( self.foodModel )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	
	local phys = self.Entity:GetPhysicsObject()
	if phys:IsValid() then
		phys:Wake()
	end
end

function ENT:Use( activator )
	local health = activator:Health()
	activator:SetHealth( math.Clamp( ( health or 100 ) + 15, 0, 100 ) )
	
	activator:EmitSound( self.foodSound, 50, 100 )
	self:Remove()
end