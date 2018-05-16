local LocalGameTimer				= Game.Timer;
local LocalGameHeroCount 			= Game.HeroCount;
local LocalGameHero 				= Game.Hero;
local LocalGameMinionCount 			= Game.MinionCount;
local LocalGameMinion 				= Game.Minion;
local LocalGameTurretCount 			= Game.TurretCount;
local LocalGameTurret 				= Game.Turret;
local LocalGameWardCount 			= Game.WardCount;
local LocalGameWard 				= Game.Ward;
local LocalGameObjectCount 			= Game.ObjectCount;
local LocalGameObject				= Game.Object;
local LocalGameMissileCount 		= Game.MissileCount;
local LocalGameMissile				= Game.Missile;
local LocalGameParticleCount 		= Game.ParticleCount;
local LocalGameParticle				= Game.Particle;
local CastSpell 					= _G.Control.CastSpell
local LocalGameIsChatOpen			= Game.IsChatOpen;
function Ready(spellSlot)
	return Game.CanUseSpell(spellSlot) == 0
end
	
function CurrentPctLife(entity)
	local pctLife =  entity.health/entity.maxHealth  * 100
	return pctLife
end

function CurrentPctMana(entity)
	local pctMana =  entity.mana/entity.maxMana * 100
	return pctMana
end

function CanTarget(target)
	return target and target.pos and target.isEnemy and target.alive and target.health > 0 and target.visible and target.isTargetable
end

function CanTargetAlly(target)
	return target and target.pos and target.isAlly and target.alive and target.health > 0 and target.visible and target.isTargetable
end


function GetTarget(range)
	if forcedTarget and LocalGeometry:IsInRange(myHero.pos, forcedTarget.pos, range) then return forcedTarget end
	return _G.SDK.TargetSelector:GetTarget(range, _G.SDK.DAMAGE_TYPE_MAGICAL);
end

function WndMsg(msg,key)
	if msg == 513 then
		local starget = nil
		local dist = 10000
		for i  = 1,LocalGameHeroCount(i) do
			local enemy = LocalGameHero(i)
			if enemy and enemy.alive and enemy.isEnemy and LocalGeometry:GetDistanceSqr(mousePos, enemy.pos) < dist then
				starget = enemy
				dist = LocalGeometry:GetDistanceSqr(mousePos, enemy.pos)
			end
		end
		if starget then
			forcedTarget = starget
		else
			forcedTarget = nil
		end
	end	
end

function EnableOrb(bool)
    if _G.EOWLoaded then
        EOW:SetMovements(bool)
        EOW:SetAttacks(bool)
    elseif _G.SDK and _G.SDK.Orbwalker then
        _G.SDK.Orbwalker:SetMovement(bool)
        _G.SDK.Orbwalker:SetAttack(bool)
    else
        GOS.BlockMovement = not bool
        GOS.BlockAttack = not bool
    end
end

function CastSpell(key, pos, isLine)
	if not pos then Control.CastSpell(key) return end
	
	if type(pos) == "userdata" and pos.pos then
		pos = pos.pos
	end
	
	if not pos:ToScreen().onScreen and isLine then			
		pos = myHero.pos + (pos - myHero.pos):Normalized() * 250
	end
	
	if not pos:ToScreen().onScreen then
		return
	end
		
	EnableOrb(false)
	Control.CastSpell(key, pos)
	EnableOrb(true)		
end

function EnemyCount(origin, range)
	local count = 0
	for i  = 1,LocalGameHeroCount(i) do
		local enemy = LocalGameHero(i)
		if enemy and CanTarget(enemy) and LocalGeometry:IsInRange(origin, enemy.pos, range) then
			count = count + 1
		end			
	end
	return count
end

function NearestAlly(origin, range)
	local ally = nil
	local distance = range
	for i = 1,LocalGameHeroCount()  do
		local hero = LocalGameHero(i)
		if hero and hero ~= myHero and CanTargetAlly(hero) then
			local d =  LocalGeometry:GetDistanceSqr(origin, hero.pos)
			if d < range and d < distance * distance then
				distance = d
				ally = hero
			end
		end
	end
	if distance < range then
		return ally, distance
	end
end

function NearestEnemy(origin, range)
	local enemy = nil
	local distance = range
	for i = 1,LocalGameHeroCount()  do
		local hero = LocalGameHero(i)
		if hero and CanTarget(hero) then
			local d =  LocalGeometry:GetDistanceSqr(origin, hero.pos)
			if d < range and d < distance * distance then
				distance = d
				enemy = hero
			end
		end
	end
	if distance < range then
		return enemy, distance
	end
end

if FileExist(COMMON_PATH .. "Auto/Alpha.lua") then
	require 'Auto/Alpha'
else
	print("ERROR: Auto/Alpha.lua is not present in your Scripts/Common folder. Please re open loader.")
end

local remaining = 30 - Game.Timer()
print(myHero.charName .. " will load shortly")
DelayAction(function()
	LocalGeometry = _G.Alpha.Geometry
	LocalBuffManager = _G.Alpha.BuffManager
	LocalObjectManager = _G.Alpha.ObjectManager
	LocalDamageManager = _G.Alpha.DamageManager
	LocalDamageManager:InitializeCallbacks()
	Callback.Add("WndMsg",function(Msg, Key) WndMsg(Msg, Key) end)
	LoadScript()
end, remaining)