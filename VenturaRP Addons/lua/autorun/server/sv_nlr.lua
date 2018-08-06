-- Serverside New Life Rule by Tyguy --
local deathpos = 0
local died = false
local playernlr = "" --don't change this!
local warnings = 0
local protection = false
--ConVars
CreateClientConVar("nlr_enabled", 1, true, false) -- will nlr work?
CreateClientConVar("nlr_wait", 500, true, false) -- amount of time to wait before nlr clears (in seconds)
CreateClientConVar("nlr_warnings", 3, true, false) --amount of warnings before ban
CreateClientConVar("nlr_spawnprotection", 1, true, false) --enable/disable the nlr spawn protection
CreateClientConVar("nlr_spawnprotection_time", 10, true, false) --if spawnprotection is enabled, set the time it stays on for
CreateClientConVar("nlr_bantime", 5, true, false) --ban time if banned
--Defines
local wait = GetConVarNumber("nlr_wait")
local warningsban = GetConVarNumber("nlr_warnings")
local spawnprotectiontime = GetConVarNumber("nlr_spawnprotection_time")
local bantime = GetConVarNumber("nlr_bantime")
--

--Network Strings
util.AddNetworkString("brokenlr") --Message when a player breaks nlr
util.AddNetworkString("startednlr") --Message when a player starts nlr
util.AddNetworkString("playerbanned") --Message when a player gets banned for nlr (to public)
util.AddNetworkString("endnlr") --Message for ending nlr
util.AddNetworkString("nlralreadyon") --Message if you die while nlr is still on

util.AddNetworkString("nlrprotectionstart") --Message for when your spawn protection for nlr begins
util.AddNetworkString("nlrprotectionend") --Message for when your spawn protection for nlr begins
--

hook.Add("PlayerInitialSpawn", "resetwarnings", function(ply)
ply.warnings = 0
ply.playernlr = ""
ply.protected = false
end )

hook.Add("PlayerDeath", "nlr", function(victim, killer)
	if GetConVarNumber("nlr_enabled") == 1 then
		if victim:IsPlayer() and killer:IsPlayer() and IsValid(killer) and IsValid(victim) then
			if !victim.died then
			victim.deathpos = victim:GetPos()
			victim.died = true
			playernlr = victim
			net.Start("startednlr")
			net.Send(victim)
			else
			net.Start("nlralreadyon")
			net.Send(victim)
			end
		end
	end
end )

hook.Add("PlayerSpawn", "nlrprotection", function(ply)
	if ply.died and GetConVarNumber("nlr_spawnprotection") == 1 and GetConVarNumber("nlr_enabled") == 1 then
	local name = playernlr
		timer.Simple(0.02, function()
		ply.protected = true
		net.Start("nlrprotectionstart")
		net.Send(ply)
			timer.Simple(spawnprotectiontime, function()
			ply.protected = false
			net.Start("nlrprotectionend")
			net.Send(ply)
			end )
		end )
 	end
end )

timer.Create("nlr_timer", 1, 0, function()
	if GetConVarNumber("nlr_enabled") == 1 then
		for k,v in pairs(player.GetAll()) do 
			if v == playernlr and !v.protected then
				if v.died then
				local mypos = v:GetPos()
					if mypos:Distance(v.deathpos) < 800 and v:Alive() then
					v:Kill()
						if v.warnings != warningsban then
						v.warnings = v.warnings + 1
						net.Start("brokenlr")
						net.WriteString(v.warnings)
						net.WriteString(warningsban)
						net.Send(v)
						else
						v:Ban(bantime, "Broke New Life Rule (Warning "..v.warnings.."/"..warningsban..")")
						v:Kick("Broke New Life Rule (Warning "..v.warnings.."/"..warningsban..")")
						net.Start("playerbanned")
						net.WriteString(v:Nick())
						net.WriteString(v.warnings)
						net.Broadcast()		
						end
					end
				end
			end
		end
	end
end )

timer.Create("reset_nlr", wait, 0, function()
	if GetConVarNumber("nlr_enabled") == 1 then
		for k,v in pairs(player.GetAll()) do
			if v.died then
			v.died = false
			v.deathpos = 0
			net.Start("endnlr")
			net.Send(v)
			end
		end
	end
end )