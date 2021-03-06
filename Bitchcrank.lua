class "Bitchcrank" 
local NextSpellCast = Game.Timer()
local forcedTarget
local loaded = false

if myHero.charName ~= "Blitzcrank" then print("This Script is only compatible with Bitchcrank") return end

Callback.Add("Load", function() Bitchcrank() end)

function Bitchcrank:__init()

	--Load from common folder OR let us use it if its already activated as its own script
	if FileExist(COMMON_PATH .. "HPred.lua") then
		require 'HPred'
	else
		HPred()
	end	
	Callback.Add("Draw", function() self:Draw() end)
end

function Bitchcrank:TryLoad()
	if Game.Timer() < 30 then return end
	self.loaded = true	
	self:LoadSpells()
	self:CreateMenu()
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("WndMsg",function(Msg, Key) self:WndMsg(Msg, Key) end)
end


function Bitchcrank:CreateMenu()
	Menu = MenuElement({type = MENU, id = myHero.charName, name = "[Bitchcrank]"})	
	Menu:MenuElement({id = "General", name = "General", type = MENU})
	Menu.General:MenuElement({id = "DrawQ", name = "Draw Q Range", value = true})
	Menu.General:MenuElement({id = "DrawQAim", name = "Draw Q Aim", value = true})
	Menu.General:MenuElement({id = "DrawR", name = "Draw R Range", value = true})
	Menu.General:MenuElement({id = "ReactionTime", name = "Reaction Time", value = .23, min = .1, max = 1, step = .1})
	
	Menu:MenuElement({id = "Skills", name = "Skills", type = MENU})
	Menu.Skills:MenuElement({id = "Combo", name = "Combo Key",value = false,  key = string.byte(" ") })
	
	Menu.Skills:MenuElement({id = "Q", name = "[Q] Rocket Grab", type = MENU})
	Menu.Skills.Q:MenuElement({id = "Targets", name = "Targets", type = MENU})	
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.isEnemy then
			Menu.Skills.Q.Targets:MenuElement({id = hero.charName, name = hero.charName, value = true })
		end
	end
	Menu.Skills.Q:MenuElement({id = "Immobile", name = "Auto Hook Immobile", value = true})
	Menu.Skills.Q:MenuElement({id = "Range", name = "Minimum Auto Hook Range", value = 300, min = 900, max = 100, step = 50})
	Menu.Skills.Q:MenuElement({id = "Accuracy", name = "Combo Accuracy", value = 3, min = 1, max = 5, step = 1})
	Menu.Skills.Q:MenuElement({id = "Mana", name = "Mana Limit", value = 15, min = 5, max = 100, step = 5 })
		
	Menu.Skills:MenuElement({id = "E", name = "[E] Power Fist", type = MENU})
	Menu.Skills.E:MenuElement({id = "Mana", name = "Mana Limit", value = 15, min = 5, max = 100, step = 5 })
	
	Menu.Skills:MenuElement({id = "R", name = "[R] Static Field", type = MENU})
	Menu.Skills.R:MenuElement({id = "KS", name = "Secure Kills", value = true})
	Menu.Skills.R:MenuElement({id = "Count", name = "Target Count", value = 3, min = 1, max = 5, step = 1})
	Menu.Skills.R:MenuElement({id = "Mana", name = "Mana Limit", value = 15, min = 5, max = 100, step = 5 })
end

function Bitchcrank:LoadSpells()
	Q = {Range = 925, Width = 120,Delay = 0.25, Speed = 1750,  Collision = true}
	R = {Range = 600 ,Delay = 0.25, Speed = math.huge}
end

function Bitchcrank:Draw()	
	if not self.loaded then
		Draw.Text("Script will load 30 seconds into the match", 25, 250, 250)
		self:TryLoad()
		return
	end	
	
	
	if KnowsSpell(_Q) and Menu.General.DrawQ:Value() then
		Draw.Circle(myHero.pos, Q.Range, Draw.Color(150, 255, 0,0))
	end	
	
	if KnowsSpell(_R) and Menu.General.DrawR:Value() then
		Draw.Circle(myHero.pos, R.Range, Draw.Color(150, 0, 255,255))
	end
	
	if KnowsSpell(_Q) and Ready(_Q) and Menu.General.DrawQAim:Value() and self.forcedTarget and self.forcedTarget.alive and self.forcedTarget.visible then	
		local targetOrigin = HPred:PredictUnitPosition(self.forcedTarget, Q.Delay)
		local interceptTime = HPred:GetSpellInterceptTime(myHero.pos, targetOrigin, Q.Delay, Q.Speed)			
		local origin, radius = HPred:UnitMovementBounds(self.forcedTarget, interceptTime, Menu.General.ReactionTime:Value())		
						
		if radius < 25 then
			radius = 25
		end
		
		if self:GetDistance(myHero.pos, origin) > Q.Range then
			Draw.Circle(origin, 25,10, Draw.Color(150, 255, 0,0))
		else
			Draw.Circle(origin, 25,10, Draw.Color(150, 0, 255,0))
			Draw.Circle(origin, radius,1, Draw.Color(150, 255, 255,255))	
		end
	end	
end

function Bitchcrank:Tick()
	if IsRecalling() then return end	
	if NextSpellCast > Game.Timer() then return end
	
	--TODO: Only update whitelist every second
	
	if Ready(_Q) then
		if Menu.Skills.Q.Immobile:Value() then
			local target, aimPosition = HPred:GetReliableTarget(myHero.pos, Q.Range, Q.Delay, Q.Speed,Q.Width, Menu.General.ReactionTime:Value(), Q.Collision)
			if target and self:GetDistance(myHero.pos, aimPosition) >= Menu.Skills.Q.Range:Value() then
				self:CastSpell(HK_Q, aimPosition)
			end
		end
		
		if Menu.Skills.Combo:Value() and CurrentPctMana(myHero) >= Menu.Skills.Q.Mana:Value() then
			local _whiteList = {}
			for i  = 1,Game.HeroCount(i) do
				local enemy = Game.Hero(i)
				if Menu.Skills.Q.Targets[enemy.charName] and Menu.Skills.Q.Targets[enemy.charName]:Value() then
					_whiteList[enemy.charName] = true
				end
			end
			local hitRate, aimPosition = HPred:GetUnreliableTarget(myHero.pos, Q.Range, Q.Delay, Q.Speed, Q.Width, Q.Collision, Menu.Skills.Q.Accuracy:Value(),_whiteList)	
			if hitRate then
				self:CastSpell(HK_Q, aimPosition)
			end
		end
	end	
	
	if Ready(_E) and CurrentPctMana(myHero) >= Menu.Skills.E.Mana:Value() then
		self:AutoE()
	end
	if Ready(_R) and CurrentPctMana(myHero) >= Menu.Skills.R.Mana:Value() then
	
		
		local target, aimPosition =HPred:GetChannelingTarget(myHero.pos, R.Range, R.Delay, R.Speed, Menu.General.ReactionTime:Value(), R.Collision, R.Width)
			if target and aimPosition then
			Control.CastSpell(HK_R)
		end
		
		local targetCount = self:REnemyCount()
		if targetCount >= Menu.Skills.R.Count:Value() or (Menu.Skills.R.KS:Value() and self:CanRKillsteal())then
			Control.CastSpell(HK_R)
		NextSpellCast = .35 + Game.Timer()
		end
	end
end

function Bitchcrank:AutoE()
	--check if we are middle of an auto attack
	if myHero.attackData and myHero.attackData.target and myHero.attackData.state == STATE_WINDUP then
		local target = HPred:GetEnemyHeroByHandle(myHero.attackData.target)
		if target and target.isEnemy then		
			local windupRemaining = myHero.attackData.endTime - Game.Timer() - myHero.attackData.windDownTime
			if windupRemaining < .15 then
				DelayAction(function()Control.CastSpell(HK_E) end,.10)
			end
		end
	end
end
function Bitchcrank:CastSpell(key, pos)
	if NextSpellCast > Game.Timer() then return end
	Control.SetCursorPos(pos)
	Control.KeyDown(key)
	Control.KeyUp(key)
	NextSpellCast = .35 + Game.Timer()
end

function Bitchcrank:REnemyCount()
	local count = 0
	for i  = 1,Game.HeroCount(i) do
		local enemy = Game.Hero(i)
		if enemy.alive and enemy.isEnemy and enemy.visible and enemy.isTargetable and self:GetDistance(myHero.pos, enemy.pos) <= R.Range then
			count = count + 1
		end			
	end
	return count
end

function Bitchcrank:WndMsg(msg,key)
	if msg == 513 then
		local starget = nil
		for i  = 1,Game.HeroCount(i) do
			local enemy = Game.Hero(i)
			if enemy.alive and enemy.isEnemy and self:GetDistance(mousePos, enemy.pos) < 250 then
				starget = enemy
				break
			end
		end
		if starget then
			self.forcedTarget = starget
		else
			self.forcedTarget = nil
		end
	end	
end

function Bitchcrank:CanRKillsteal()
	local rDamage= 250 + (myHero:GetSpellData(_R).level -1) * 125 + myHero.ap 
	for i  = 1,Game.HeroCount(i) do
		local enemy = Game.Hero(i)
		if enemy.alive and enemy.isEnemy and enemy.visible and enemy.isTargetable and self:GetDistance(myHero.pos, enemy.pos) <= R.Range then
			local damage = self:CalculateMagicDamage(enemy, rDamage)
			if damage >= enemy.health then
				return true
			end
		end
	end
end

function Bitchcrank:CalculateMagicDamage(target, damage)			
	local targetMR = target.magicResist * myHero.magicPenPercent - myHero.magicPen
	local damageReduction = 100 / ( 100 + targetMR)
	if targetMR < 0 then
		damageReduction = 2 - (100 / (100 - targetMR))
	end		
	damage = damage * damageReduction
	
	return damage
end

function Bitchcrank:GetDistanceSqr(p1, p2)	
	return (p1.x - p2.x) ^ 2 + ((p1.z or p1.y) - (p2.z or p2.y)) ^ 2
end

function Bitchcrank:GetDistance(p1, p2)
	return math.sqrt(self:GetDistanceSqr(p1, p2))
end

function Ready(spellSlot)
	return Game.CanUseSpell(spellSlot) == 0
end

function IsRecalling()
	for K, Buff in pairs(GetBuffs(myHero)) do
		if Buff.name == "recall" and Buff.duration > 0 then
			return true
		end
	end
	return false
end

function KnowsSpell(spell)
	local spellInfo = myHero:GetSpellData(spell)
	if spellInfo and spellInfo.level > 0 then
		return true
	end
	return false
end

function CurrentPctLife(entity)
	local pctLife =  entity.health/entity.maxHealth  * 100
	return pctLife
end

function CurrentPctMana(entity)
	local pctMana =  entity.mana/entity.maxMana * 100
	return pctMana
end


---HPred Embed---




class "HPred"

Callback.Add("Tick", function() HPred:Tick() end)

local _reviveQueryFrequency = .2
local _lastReviveQuery = Game.Timer()
local _reviveLookupTable = 
	{ 
		["LifeAura.troy"] = 4, 
		["ZileanBase_R_Buf.troy"] = 3,
		["Aatrox_Base_Passive_Death_Activate"] = 3
	}

--Stores a collection of spells that will cause a character to blink
	--Ground targeted spells go towards mouse castPos with a maximum range
	--Hero/Minion targeted spells have a direction type to determine where we will land relative to our target (in front of, behind, etc)
	
--Key = Spell name
--Value = range a spell can travel, OR a targeted end position type, OR a list of particles the spell can teleport to	
local _blinkSpellLookupTable = 
	{ 
		["EzrealArcaneShift"] = 475, 
		["RiftWalk"] = 500,
		
		--Ekko and other similar blinks end up between their start pos and target pos (in front of their target relatively speaking)
		["EkkoEAttack"] = 0,
		["AlphaStrike"] = 0,
		
		--Katarina E ends on the side of her target closest to where her mouse was... 
		["KatarinaE"] = -255,
		
		--Katarina can target a dagger to teleport directly to it: Each skin has a different particle name. This should cover all of them.
		["KatarinaEDagger"] = { "Katarina_Base_Dagger_Ground_Indicator","Katarina_Skin01_Dagger_Ground_Indicator","Katarina_Skin02_Dagger_Ground_Indicator","Katarina_Skin03_Dagger_Ground_Indicator","Katarina_Skin04_Dagger_Ground_Indicator","Katarina_Skin05_Dagger_Ground_Indicator","Katarina_Skin06_Dagger_Ground_Indicator","Katarina_Skin07_Dagger_Ground_Indicator" ,"Katarina_Skin08_Dagger_Ground_Indicator","Katarina_Skin09_Dagger_Ground_Indicator"  }, 
	}

local _blinkLookupTable = 
	{ 
		"global_ss_flash_02.troy",
		"Lissandra_Base_E_Arrival.troy",
		"LeBlanc_Base_W_return_activation.troy"
		--TODO: Check if liss/leblanc have diff skill versions. MOST likely dont but worth checking for completion sake
		
		--Zed uses 'switch shadows'... It will require some special checks to choose the shadow he's going TO not from...
		--Shaco deceive no longer has any particles where you jump to so it cant be tracked (no spell data or particles showing path)
		
	}

local _cachedRevives = {}

local _movementHistory = {}

function HPred:Tick()
	--Check for revives and record them	
	if Game.Timer() - _lastReviveQuery < _reviveQueryFrequency then return end
	_lastReviveQuery=Game.Timer()
	
	--Remove old cached revives
	for _, revive in pairs(_cachedRevives) do
		if Game.Timer() > revive.expireTime + .5 then
			_cachedRevives[_] = nil
		end
	end
	
	--Cache new revives
	for i = 1, Game.ParticleCount() do 
		local particle = Game.Particle(i)
		if not _cachedRevives[particle.networkID] and  _reviveLookupTable[particle.name] then
			_cachedRevives[particle.networkID] = {}
			_cachedRevives[particle.networkID]["expireTime"] = Game.Timer() + _reviveLookupTable[particle.name]			
			local nearestDistance = 500
			for i = 1, Game.HeroCount() do
				local t = Game.Hero(i)
				local tDistance = self:GetDistance(particle.pos, t.pos)
				if tDistance < nearestDistance then
					nearestDistance = nearestDistance
					_cachedRevives[particle.networkID]["owner"] = t.charName
					_cachedRevives[particle.networkID]["pos"] = t.pos
					_cachedRevives[particle.networkID]["isEnemy"] = t.isEnemy					
				end
			end
		end
	end
end

function HPred:GetEnemyNexusPosition()
	--This is slightly wrong. It represents fountain not the nexus. Fix later.
	if myHero.team == 100 then return Vector(14340, 171.977722167969, 14390); else return Vector(396,182.132507324219,462); end
end


function HPred:GetReliableTarget(source, range, delay, speed, radius, timingAccuracy, checkCollision, midDash, hitTime)

	--TODO: Target whitelist. This will target anyone which is definitely not what we want
	--For now we can handle in the champ script. That will cause issues with multiple people in range who are goood targets though.
	
	
	--Get stunned enemies
	local target, aimPosition =self:GetImmobileTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	if target and aimPosition then
		return target, aimPosition
	end
	
	--Get hourglass enemies
	target, aimPosition =self:GetHourglassTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	if target and aimPosition then
		return target, aimPosition
	end
	
	--Get reviving target
	target, aimPosition =self:GetRevivingTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	if target and aimPosition then
		return target, aimPosition
	end
	
	--Get channeling enemies
	target, aimPosition =self:GetChannelingTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
		if target and aimPosition then
		return target, aimPosition
	end
	
	--Get teleporting enemies
	target, aimPosition =self:GetTeleportingTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)	
	if target and aimPosition then
		return target, aimPosition
	end
	
	--Get instant dash enemies
	target, aimPosition =self:GetInstantDashTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	if target and aimPosition then
		return target, aimPosition
	end	
	
	--Get dashing enemies
	target, aimPosition =self:GetDashingTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius, midDash)
	if target and aimPosition then
		return target, aimPosition
	end

	--Get blink targets
	target, aimPosition =self:GetBlinkTarget(source, range, speed, delay, checkCollision, radius)
	if target and aimPosition then
		return target, aimPosition
	end	
end

--Will return the valid target who has the highest hit chance and meets all conditions (minHitChance, whitelist check, etc)
function HPred:GetUnreliableTarget(source, range, delay, speed, radius, checkCollision, minimumHitChance, whitelist)

	local _validTargets = {}
	for i = 1, Game.HeroCount() do
		local t = Game.Hero(i)
		if self:CanTarget(t) and (not whitelist or whitelist[t.charName]) then			
			local hitChance, aimPosition = self:GetHitchance(source, t, range, delay, speed, radius, checkCollision)		
			if hitChance >= minimumHitChance then
				_validTargets[t.charName] = {["hitChance"] = hitChance, ["aimPosition"] = aimPosition}
			end
		end
	end
	
	local rHitChance = 0
	local rAimPosition
	for targetName, targetData in pairs(_validTargets) do
		if targetData.hitChance > rHitChance then
			rHitChance = targetData.hitChance
			rAimPosition = targetData.aimPosition
		end		
	end
	
	if rHitChance >= minimumHitChance then
		return rHitChance, rAimPosition
	end	
end

function HPred:GetHitchance(source, target, range, delay, speed, radius, checkCollision)
	self:UpdateMovementHistory(target)
	
	local hitChance = 1	
	
	local aimPosition = self:PredictUnitPosition(target, delay + self:GetDistance(source, target.pos) / speed)	
	local interceptTime = self:GetSpellInterceptTime(source, aimPosition, delay, speed)
	local reactionTime = self:PredictReactionTime(target, .1)
	local origin,movementRadius = self:UnitMovementBounds(target, interceptTime, reactionTime)
	
	--If they just now changed their path then assume they will keep it for at least a short while... slightly higher chance
	if _movementHistory and _movementHistory[target.charName] and Game.Timer() - _movementHistory[target.charName]["ChangedAt"] < .25 then
		hitChance = 2
	end

	--If they are standing still give a higher accuracy because they have to take actions to react to it
	if not target.pathing or not target.pathing.hasMovePath then
		hitChance = 2
	end	
	
	
	--Our spell is so wide or the target so slow or their reaction time is such that the spell will be nearly impossible to avoid
	if movementRadius - target.boundingRadius <= radius /2 then
		hitChance = 3
	end	
	
	--If they are casting a spell then the accuracy will be fairly high. if the windup is longer than our delay then it's quite likely to hit. 
	--Ideally we would predict where they will go AFTER the spell finishes but that's beyond the scope of this prediction
	if target.activeSpell and target.activeSpell.valid then
		if target.activeSpell.startTime + target.activeSpell.windup - Game.Timer() >= delay then
			hitChance = 4
		else			
			hitChance = 3
		end
	end
	
	--Check for out of range
	if self:GetDistance(myHero.pos, aimPosition) >= range then
		hitChance = -1
	end
	
	--Check minion block
	if hitChance > 0 and checkCollision then	
		if self:CheckMinionCollision(source, aimPosition, delay, speed, radius) then
			hitChance = -1
		end
	end
	
	return hitChance, aimPosition
end

function HPred:PredictReactionTime(unit, minimumReactionTime)
	local reactionTime = minimumReactionTime
	
	--If the target is auto attacking increase their reaction time by .15s - If using a skill use the remaining windup time
	if unit.activeSpell and unit.activeSpell.valid then
		local windupRemaining = unit.activeSpell.startTime + unit.activeSpell.windup - Game.Timer()
		if windupRemaining > 0 then
			reactionTime = windupRemaining
		end
	end
	
	--If the target is recalling and has been for over .25s then increase their reaction time by .25s
	local isRecalling, recallDuration = self:GetRecallingData(unit)	
	if isRecalling and recallDuration > .25 then
		reactionTime = .25
	end
	
	return reactionTime
end

function HPred:GetDashingTarget(source, range, delay, speed, dashThreshold, checkCollision, radius, midDash)

	local target
	local aimPosition
	for i = 1, Game.HeroCount() do
		local t = Game.Hero(i)
		if t.isEnemy and t.pathing.hasMovePath and t.pathing.isDashing and t.pathing.dashSpeed>500  then
			local dashEndPosition = t:GetPath(1)
			if self:GetDistance(source, dashEndPosition) <= range then				
				--The dash ends within range of our skill. We now need to find if our spell can connect with them very close to the time their dash will end
				local dashTimeRemaining = self:GetDistance(t.pos, dashEndPosition) / t.pathing.dashSpeed
				local skillInterceptTime = self:GetSpellInterceptTime(myHero.pos, dashEndPosition, delay, speed)
				local deltaInterceptTime = math.abs(skillInterceptTime - dashTimeRemaining)
				if deltaInterceptTime < dashThreshold and (not checkCollision or not self:CheckMinionCollision(source, dashEndPosition, delay, speed, radius)) then
					target = t
					aimPosition = dashEndPosition
					return target, aimPosition
				end
			end			
		end
	end
end

function HPred:GetHourglassTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	local target
	local aimPosition
	for i = 1, Game.HeroCount() do
		local t = Game.Hero(i)
		local success, timeRemaining = self:HasBuff(t, "zhonyasringshield")
		if success and t.isEnemy then
			local spellInterceptTime = self:GetSpellInterceptTime(myHero.pos, t.pos, delay, speed)
			local deltaInterceptTime = spellInterceptTime - timeRemaining
			if spellInterceptTime > timeRemaining and deltaInterceptTime < timingAccuracy and (not checkCollision or not self:CheckMinionCollision(source, interceptPosition, delay, speed, radius)) then
				target = t
				aimPosition = t.pos
				return target, aimPosition
			end
		end
	end
end

function HPred:GetRevivingTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	local target
	local aimPosition
	for _, revive in pairs(_cachedRevives) do	
		if revive.isEnemy then
			local interceptTime = self:GetSpellInterceptTime(source, revive.pos, delay, speed)
			if interceptTime > revive.expireTime - Game.Timer() and interceptTime - revive.expireTime - Game.Timer() < timingAccuracy then
				target = self:GetEnemyByName(revive.owner)
				aimPosition = revive.pos
				return target, aimPosition
			end
		end
	end	
end

function HPred:GetInstantDashTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	local target
	local aimPosition
	for i = 1, Game.HeroCount() do
		local t = Game.Hero(i)
		if t.isEnemy and t.activeSpell and t.activeSpell.valid and _blinkSpellLookupTable[t.activeSpell.name] then
			local windupRemaining = t.activeSpell.startTime + t.activeSpell.windup - Game.Timer()
			if windupRemaining > 0 then
				local endPos
				local range = _blinkSpellLookupTable[t.activeSpell.name]
				if type(range) == "table" then
					--Find the nearest matching particle to our mouse
					local target, distance = self:GetNearestParticleByNames(t.pos, range)
					if target and distance < 250 then					
						endPos = target.pos		
					end
				elseif range > 0 then
					endPos = Vector(t.activeSpell.placementPos.x, t.activeSpell.placementPos.y, t.activeSpell.placementPos.z)					
					endPos = t.activeSpell.startPos + (endPos- t.activeSpell.startPos):Normalized() * math.min(self:GetDistance(t.activeSpell.startPos,endPos), range)
				else
					local blinkTarget = self:GetObjectByHandle(t.activeSpell.target)
					if blinkTarget then				
						local offsetDirection						
						
						--We will land in front of our target relative to our starting position
						if range == 0 then						
							offsetDirection = (blinkTarget.pos - t.pos):Normalized()
						--We will land behind our target relative to our starting position
						elseif range == -1 then						
							offsetDirection = (t.pos-blinkTarget.pos):Normalized()
						--They can choose which side of target to come out on , there is no way currently to read this data so we will only use this calculation if the spell radius is large
						elseif range == -255 then
							if radius > 250 then
									endPos = blinkTarget.pos
							end							
						end
						
						if offsetDirection then
							endPos = blinkTarget.pos - offsetDirection * 150
						end
						
					end
				end	
				
				local interceptTime = self:GetSpellInterceptTime(myHero.pos, endPos, delay,speed)
				local deltaInterceptTime = interceptTime - windupRemaining
				if  deltaInterceptTime < timingAccuracy and (not checkCollision or not self:CheckMinionCollision(source, endPos, delay, speed, radius)) then
					target = t
					aimPosition = endPos
					return target,aimPosition					
				end
			end
		end
	end
end

function HPred:GetBlinkTarget(source, range, speed, delay, checkCollision, radius)
	local target
	local aimPosition
	for i = 1, Game.ParticleCount() do 
		local particle = Game.Particle(i)
		if particle and _blinkLookupTable[particle.name] then
			local pPos = particle.pos
			for k,v in pairs(self:GetEnemyHeroes()) do
				local t = v
				if t and t.isEnemy and self:GetDistance(t.pos, pPos) < t.boundingRadius then
					if (not checkCollision or not self:CheckMinionCollision(source, pPos, delay, speed, radius)) then
						target = t
						aimPosition = pPos
						return target,aimPosition
					end
				end
			end
		end
	end
end

function HPred:GetChannelingTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	local target
	local aimPosition
	for i = 1, Game.HeroCount() do
		local t = Game.Hero(i)
		local interceptTime = self:GetSpellInterceptTime(myHero.pos, t.pos, delay, speed)
		if self:CanTarget(t) and self:GetDistance(source, t.pos) <= range and self:IsChannelling(t, interceptTime) and (not checkCollision or not self:CheckMinionCollision(source, t.pos, delay, speed, radius)) then
			target = t
			aimPosition = t.pos	
			return target, aimPosition
		end
	end
end

function HPred:GetImmobileTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	local target
	local aimPosition
	for i = 1, Game.HeroCount() do
		local t = Game.Hero(i)
		if self:CanTarget(t) and self:GetDistance(source, t.pos) <= range then
			local immobileTime = self:GetImmobileTime(t)
			
			local interceptTime = self:GetSpellInterceptTime(source, t.pos, delay, speed)
			if immobileTime - interceptTime > timingAccuracy and (not checkCollision or not self:CheckMinionCollision(source, t.pos, delay, speed, radius)) then
				target = t
				aimPosition = t.pos
				return target, aimPosition
			end
		end
	end
end

function HPred:GetTeleportingTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	local target
	local aimPosition
	--Get enemies who are teleporting to towers
	for i = 1, Game.TurretCount() do
		local turret = Game.Turret(i);
		if turret.isEnemy and self:GetDistance(source, turret.pos) <= range then
			local hasBuff, expiresAt = self:HasBuff(turret, "teleport_target")
			if hasBuff then
				local interceptPosition = self:GetTeleportOffset(turret.pos,223.31)
				local deltaInterceptTime = self:GetSpellInterceptTime(source, interceptPosition, delay, speed) - expiresAt
				if deltaInterceptTime > 0 and deltaInterceptTime < timingAccuracy and (not checkCollision or not self:CheckMinionCollision(source, interceptPosition, delay, speed, radius)) then
					target = turret
					aimPosition =interceptPosition
					return target, aimPosition
				end
			end
		end
	end	
	
	--Get enemies who are teleporting to wards
	
	for i = 1, Game.WardCount() do
		local ward = Game.Ward(i);
		if ward.isEnemy and self:GetDistance(source, ward.pos) <= range then
			local hasBuff, expiresAt = self:HasBuff(ward, "teleport_target")
			if hasBuff then
				local interceptPosition = self:GetTeleportOffset(ward.pos,100.01)
				local deltaInterceptTime = self:GetSpellInterceptTime(source, interceptPosition, delay, speed) - expiresAt
				if deltaInterceptTime > 0 and deltaInterceptTime < timingAccuracy and (not checkCollision or not self:CheckMinionCollision(source, interceptPosition, delay, speed, radius)) then
					target = ward
					aimPosition = interceptPosition
					return target, aimPosition
				end
			end
		end
	end
	
	--Get enemies who are teleporting to minions
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i);
		if minion.isEnemy and self:GetDistance(source, minion.pos) <= range then
			local hasBuff, expiresAt = self:HasBuff(minion, "teleport_target")
			if hasBuff then	
				local interceptPosition = self:GetTeleportOffset(minion.pos,143.25)
				local deltaInterceptTime = self:GetSpellInterceptTime(source, interceptPosition, delay, speed) - expiresAt
				if deltaInterceptTime > 0 and deltaInterceptTime < timingAccuracy and (not checkCollision or not self:CheckMinionCollision(source, interceptPosition, delay, speed, radius)) then
					target = minion				
					aimPosition = interceptPosition
					return target, aimPosition
				end
			end
		end
	end
end

function HPred:GetTargetMS(target)
	local ms = target.pathing.isDashing and target.pathing.dashSpeed or target.ms
	return ms
end

function HPred:Angle(A, B)
	local deltaPos = A - B
	local angle = math.atan2(deltaPos.x, deltaPos.z) *  180 / math.pi	
	if angle < 0 then angle = angle + 360 end
	return angle
end

function HPred:UpdateMovementHistory(unit)
	if not _movementHistory[unit.charName] then
		_movementHistory[unit.charName] = {}
		_movementHistory[unit.charName]["EndPos"] = unit.pathing.endPos
		_movementHistory[unit.charName]["StartPos"] = unit.pathing.endPos
		_movementHistory[unit.charName]["PreviousAngle"] = 0
		_movementHistory[unit.charName]["ChangedAt"] = Game.Timer()
	end
	
	if _movementHistory[unit.charName]["EndPos"].x ~=unit.pathing.endPos.x or _movementHistory[unit.charName]["EndPos"].y ~=unit.pathing.endPos.y or _movementHistory[unit.charName]["EndPos"].z ~=unit.pathing.endPos.z then				
		_movementHistory[unit.charName]["PreviousAngle"] = self:Angle(Vector(_movementHistory[unit.charName]["StartPos"].x, _movementHistory[unit.charName]["StartPos"].y, _movementHistory[unit.charName]["StartPos"].z), Vector(_movementHistory[unit.charName]["EndPos"].x, _movementHistory[unit.charName]["EndPos"].y, _movementHistory[unit.charName]["EndPos"].z))
		_movementHistory[unit.charName]["EndPos"] = unit.pathing.endPos
		_movementHistory[unit.charName]["StartPos"] = unit.pos
		_movementHistory[unit.charName]["ChangedAt"] = Game.Timer()
	end
	
end

--Returns where the unit will be when the delay has passed given current pathing information. This assumes the target makes NO CHANGES during the delay.
function HPred:PredictUnitPosition(unit, delay, path)
	local predictedPosition = unit.pos
	local timeRemaining = delay
	local pathNodes = self:GetPathNodes(unit)
	for i = 1, #pathNodes -1 do
		local nodeDistance = self:GetDistance(pathNodes[i], pathNodes[i +1])
		local nodeTraversalTime = nodeDistance / self:GetTargetMS(unit)
			
		if timeRemaining > nodeTraversalTime then
			--This node of the path will be completed before the delay has finished. Move on to the next node if one remains
			timeRemaining =  timeRemaining - nodeTraversalTime
			predictedPosition = pathNodes[i + 1]
		else
			local directionVector = (pathNodes[i+1] - pathNodes[i]):Normalized()
			predictedPosition = pathNodes[i] + directionVector *  self:GetTargetMS(unit) * timeRemaining
			break;
		end
	end
	return predictedPosition
end

function HPred:IsChannelling(target, interceptTime)
	if target.activeSpell and target.activeSpell.valid and target.activeSpell.isChanneling then
		return true
	end
end

function HPred:HasBuff(target, buffName, minimumDuration)
	local duration = minimumDuration
	if not minimumDuration then
		duration = 0
	end
	local durationRemaining
	for i = 1, target.buffCount do 
		local buff = target:GetBuff(i)
		if buff.duration > duration and buff.name == buffName then
			durationRemaining = buff.duration
			return true, durationRemaining
		end
	end
end

--Moves an origin towards the enemy team nexus by magnitude
function HPred:GetTeleportOffset(origin, magnitude)
	local teleportOffset = origin + (self:GetEnemyNexusPosition()- origin):Normalized() * magnitude
	return teleportOffset
end

function HPred:GetSpellInterceptTime(startPos, endPos, delay, speed)	
	local interceptTime = Game.Latency()/2000 + delay + self:GetDistance(startPos, endPos) / speed
	return interceptTime
end

--Checks if a target can be targeted by abilities or auto attacks currently.
--CanTarget(target)
	--target : gameObject we are trying to hit
function HPred:CanTarget(target)
	return target.isEnemy and target.alive and target.visible and target.isTargetable
end

--Returns a position and radius in which the target could potentially move before the delay ends. ReactionTime defines how quick we expect the target to be able to change their current path
function HPred:UnitMovementBounds(unit, delay, reactionTime)
	local startPosition = self:PredictUnitPosition(unit, delay)
	
	local radius = 0
	local deltaDelay = delay -reactionTime- self:GetImmobileTime(unit)	
	if (deltaDelay >0) then
		radius = self:GetTargetMS(unit) * deltaDelay	
	end
	return startPosition, radius	
end

--Returns how long (in seconds) the target will be unable to move from their current location
function HPred:GetImmobileTime(unit)
	local duration = 0
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i);
		if buff.count > 0 and buff.duration> duration and (buff.type == 5 or buff.type == 8 or buff.type == 21 or buff.type == 22 or buff.type == 24 or buff.type == 11 or buff.type == 29 or buff.type == 30 or buff.type == 39 ) then
			duration = buff.duration
		end
	end
	return duration		
end

--Returns how long (in seconds) the target will be slowed for
function HPred:GetSlowedTime(unit)
	local duration = 0
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i);
		if buff.count > 0 and buff.duration > duration and buff.type == 10 then
			duration = buff.duration			
			return duration
		end
	end
	return duration		
end

--Returns all existing path nodes
function HPred:GetPathNodes(unit)
	local nodes = {}
	table.insert(nodes, unit.pos)
	if unit.pathing.hasMovePath then
		for i = unit.pathing.pathIndex, unit.pathing.pathCount do
			path = unit:GetPath(i)
			table.insert(nodes, path)
		end
	end		
	return nodes
end

--Finds any game object with the correct handle to match (hero, minion, wards on either team)
function HPred:GetObjectByHandle(handle)
	local target
	for i = 1, Game.HeroCount() do
		local enemy = Game.Hero(i)
		if enemy.handle == handle then
			target = enemy
			return target
		end
	end
	
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if minion.handle == handle then
			target = minion
			return target
		end
	end
	
	for i = 1, Game.WardCount() do
		local ward = Game.Ward(i);
		if minion.ward == handle then
			target = ward
			return target
		end
	end
	
	for i = 1, Game.ParticleCount() do 
		local particle = Game.Particle(i)
		if particle.ward == handle then
			target = ward
			return target
		end
	end
end

function HPred:GetEnemyHeroByHandle(handle)	
	local target
	for i = 1, Game.HeroCount() do
		local enemy = Game.Hero(i)
		if enemy.handle == handle then
			target = enemy
			return target
		end
	end
end

--Finds the closest particle to the origin that is contained in the names array
function HPred:GetNearestParticleByNames(origin, names)
	local target
	local distance = math.max
	for i = 1, Game.ParticleCount() do 
		local particle = Game.Particle(i)
		local d = self:GetDistance(origin, particle.pos)
		if d < distance then
			distance = d
			target = particle
		end
	end
	return target, distance
end

--Returns the total distance of our current path so we can calculate how long it will take to complete
function HPred:GetPathLength(nodes)
	local result = 0
	for i = 1, #nodes -1 do
		result = result + self:GetDistance(nodes[i], nodes[i + 1])
	end
	return result
end


--I know this isn't efficient but it works accurately... Leaving it for now.
function HPred:CheckMinionCollision(origin, endPos, delay, speed, radius, frequency)
		
	if not frequency then
		frequency = radius / 2
	end
	local directionVector = (endPos - origin):Normalized()
	local checkCount = self:GetDistance(origin, endPos) / frequency
	for i = 1, checkCount do
		local checkPosition = origin + directionVector * i * frequency
		local checkDelay = delay + self:GetDistance(origin, checkPosition) / speed
		if self:IsMinionIntersection(checkPosition, radius, checkDelay) then
			return true
		end
	end
	return false
end


function HPred:IsMinionIntersection(location, radius, delay, maxDistance)
	if not maxDistance then
		maxDistance = 500
	end
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if self:CanTarget(minion) and self:GetDistance(minion.pos, location) < maxDistance then
			local predictedPosition = self:PredictUnitPosition(minion, delay)
			if self:GetDistance(location, predictedPosition) <= radius + minion.boundingRadius then
				return true
			end
		end
	end
	return false
end

function HPred:GetRecallingData(unit)
	for K, Buff in pairs(GetBuffs(unit)) do
		if Buff.name == "recall" and Buff.duration > 0 then
			return true, Game.Timer() - Buff.startTime
		end
	end
	return false
end

function HPred:GetEnemyByName(name)
	local target
	for i = 1, Game.HeroCount() do
		local enemy = Game.Hero(i)
		if enemy.isEnemy and enemy.charName == name then
			target = enemy
			return target
		end
	end
end

function HPred:GetEnemyHeroes()
	local _EnemyHeroes = {}
  	for i = 1, Game.HeroCount() do
    	local enemy = Game.Hero(i)
    	if enemy and enemy.isEnemy then
	  		table.insert(_EnemyHeroes, enemy)
  		end
  	end
  	return _EnemyHeroes
end

function HPred:GetDistanceSqr(p1, p2)	
	return (p1.x - p2.x) ^ 2 + ((p1.z or p1.y) - (p2.z or p2.y)) ^ 2
end

function HPred:GetDistance(p1, p2)
	return math.sqrt(self:GetDistanceSqr(p1, p2))
end