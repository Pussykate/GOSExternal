Q = {Range = 1000, Width = 45,Delay = 0.25, Speed = 2850, Collision = true }
W = {Range = 900, Width = 150,Delay = 1.25, Speed = 99999 }
E = {Range = 800, Width = 300,Delay = 0.25, Speed = 2000 }

function LoadScript()
	Menu = MenuElement({type = MENU, id = myHero.networkID, name = myHero.charName})
	Menu:MenuElement({id = "Skills", name = "Skills", type = MENU})
	
	Menu.Skills:MenuElement({id = "Q", name = "[Q] Threaded Volley", type = MENU})
	Menu.Skills.Q:MenuElement({id = "Auto", name = "Auto Cast on Immobile", value = true})
	Menu.Skills.Q:MenuElement({id = "Accuracy", name = "Combo Accuracy", value = 3, min = 1, max = 6, step = 1})
	Menu.Skills.Q:MenuElement({id = "Mana", name = "Mana Limit", value = 15, min = 5, max = 100, step = 5 })
		
	Menu.Skills:MenuElement({id = "W", name = "[W] Seismic Shove", type = MENU})
	Menu.Skills.W:MenuElement({id = "Auto", name = "Auto Cast on Immobile", value = true})
	Menu.Skills.W:MenuElement({id = "PeelRange", name = "Push Range", value = 300, min = 100, max = 600, step = 50 })
	Menu.Skills.W:MenuElement({id = "Accuracy", name = "Combo Peel Accuracy", value = 3, min = 1, max = 6, step = 1})
	
	Menu.Skills:MenuElement({id = "E", name = "[E] Unraveled Earth", type = MENU})
	Menu.Skills.E:MenuElement({id = "Auto", name = "Auto Cast on Immobile", value = true})
	Menu.Skills.E:MenuElement({id = "Accuracy", name = "Combo Accuracy", value = 3, min = 1, max = 6, step = 1})
	Menu.Skills.E:MenuElement({id = "Mana", name = "Mana Limit", value = 15, min = 5, max = 100, step = 5 })		
	
	Menu.Skills:MenuElement({id = "Combo", name = "Combo Key",value = false,  key = string.byte(" ") })
	
	LocalDamageManager:OnIncomingCC(function(target, damage, ccType) OnCC(target, damage, ccType) end)
	LocalObjectManager:OnBlink(function(target) OnBlink(target) end )
	LocalObjectManager:OnSpellCast(function(spell) OnSpellCast(spell) end)
	Callback.Add("Tick", function() Tick() end)
end

local EPos = nil
local EExpiresAt = 0

function OnSpellCast(spell)
	if spell.data.name == "LuxLightStrikeKugel" then
		EPos = Vector(spell.data.placementPos.x, spell.data.placementPos.y, spell.data.placementPos.z)
		EExpiresAt = LocalGameTimer() + 5
	end
end


local NextTick = LocalGameTimer()
function Tick()
	if LocalGameIsChatOpen() then return end
	local currentTime = LocalGameTimer()
	if NextTick > currentTime then return end	
	if EPos and EExpiresAt> currentTime  then
		DetonateE()
	end
	
	if Ready(_W) and CurrentPctMana(myHero) >= Menu.Skills.W.Mana:Value() then
		for i = 1, LocalGameHeroCount() do
			local target = LocalGameHero(i)
			if CanTargetAlly(target) and  LocalGeometry:IsInRange(myHero.pos, target.pos, W.Radius) then
				local incomingDamage = LocalDamageManager:RecordedIncomingDamage(target)
				if incomingDamage > Menu.Skills.W.Damage:Value() then				
					local castPosition = LocalGeometry:PredictUnitPosition(target, W.Delay + LocalGeometry:GetDistance(myHero.pos, target.pos)/W.Speed)
					local endPosition = myHero.pos + (castPosition-myHero.pos):Normalized() * R.Range			
					local targetCount = LocalGeometry:GetLineTargetCount(myHero.pos, endPosition, W.Delay, W.Speed, W.Radius,true)
					if targetCount >= Menu.Skills.W.Count:Value() then
						NextTick = LocalGameTimer() + .25
						CastSpell(HK_W, castPosition, true)
						return
					end
				end
			end
		end
	end
	
	--Check for killsteal or target count R
	if Ready(_R) and Menu.Skills.R.Killsteal:Value() then
		local rDamage= 200 + (myHero:GetSpellData(_R).level) * 100 + myHero.ap * 0.75
		for i = 1, LocalGameHeroCount() do
			local target = LocalGameHero(i)
			if CanTarget(target) and LocalGeometry:IsInRange(myHero.pos, target.pos, R.Range) then
				
				local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, R.Range, R.Delay, R.Speed, R.Radius, R.Collision, R.IsLine)
				if castPosition and accuracy > 1  then					
					local thisRDamage = rDamage
					if LocalBuffManager:HasBuff(target, "LuxIlluminatingFraulein",R.Delay) then
						thisRDamage = thisRDamage + 20 + myHero.levelData.lvl * 10 + myHero.ap * 0.2
					end
					local extraIncoming = LocalDamageManager:RecordedIncomingDamage(target)
					local predictedHealth = target.health + target.hpRegen * R.Delay - extraIncoming			
					thisRDamage = LocalDamageManager:CalculateMagicDamage(myHero,target, thisRDamage)
					if predictedHealth > 0 and thisRDamage > predictedHealth then
						NextTick = LocalGameTimer() + .25
						CastSpell(HK_R, castPosition, true)
						return
					end
				end
			end
		end
	end
	
	if Menu.Skills.Combo:Value() then
		local target = GetTarget(Q.Range)
		if target and CanTarget(target) then
			local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, R.Range, R.Delay, R.Speed, R.Radius, R.Collision, R.IsLine)
			if castPosition and LocalGeometry:IsInRange(myHero.pos, castPosition, R.Range) then
				if accuracy > 1 then
					local endPosition = myHero.pos + (castPosition-myHero.pos):Normalized() * R.Range
					local targetCount = LocalGeometry:GetLineTargetCount(myHero.pos, endPosition, R.Delay, R.Speed, R.Radius)
					if targetCount >= Menu.Skills.R.Count:Value() then
						NextTick = LocalGameTimer() + .25
						CastSpell(HK_R, castPosition)
						return
					end
				end
			end
			local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, Q.Range, Q.Delay, Q.Speed, Q.Radius, Q.Collision, Q.IsLine)
			if castPosition and accuracy >= Menu.Skills.Q.Accuracy:Value() and LocalGeometry:IsInRange(myHero.pos, castPosition, Q.Range) then
				NextTick = LocalGameTimer() + .25
				CastSpell(HK_Q, castPosition)
				return
			end	
			local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, E.Range, E.Delay, E.Speed, E.Radius, E.Collision, E.IsLine)
			if castPosition and accuracy >= Menu.Skills.E.Accuracy:Value() and LocalGeometry:IsInRange(myHero.pos, castPosition, E.Range) then
				NextTick = LocalGameTimer() + .25
				CastSpell(HK_E, castPosition)
				return
			end	
		end
	end
	NextTick = LocalGameTimer() + .1
end


function DetonateE()
	local eData = myHero:GetSpellData(_E)
	if eData.toggleState == 2 then
		for i = 1, LocalGameHeroCount() do
			local target = LocalGameHero(i)
			if CanTarget(target) and LocalGeometry:IsInRange(EPos, target.pos, E.Radius) then
				if Menu.Skills.E.Targets[target.networkID] and Menu.Skills.E.Targets[target.networkID]:Value() then
					CastSpell(HK_E)
					EExpiresAt = 0
					break
				else
					if LocalDamageManager:PredictDamage(myHero, target, "LuxLightStrikeKugel") > target.health then
						CastSpell(HK_E)
						EExpiresAt = 0
						break
					end
					local nextPosition = LocalGeometry:PredictUnitPosition(target, .1)
					if not LocalGeometry:IsInRange(EPos, nextPosition, E.Radius) then
						CastSpell(HK_E)
						EExpiresAt = 0
						break
					end
				end
			end
		end
	end
end

function OnBlink(target)
	if target.isEnemy and CanTarget(target) and Ready(_Q) and Menu.Skills.Q.Auto:Value() and LocalGeometry:IsInRange(myHero.pos, target.pos, Q.Range) then
		local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, Q.Range, Q.Delay, Q.Speed, Q.Radius, Q.Collision)
		if accuracy > 0 then
			CastSpell(HK_Q, castPosition,true)
		end	
	end
	if target.isEnemy and CanTarget(target) and Ready(_E) and Menu.Skills.E.Auto:Value() and LocalGeometry:IsInRange(myHero.pos, target.pos, E.Range) then
		local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, E.Range, E.Delay, E.Speed, E.Radius, E.Collision)
		if accuracy > 0 then
			CastSpell(HK_E, castPosition)
		end	
	end
end

function OnCC(target, damage, ccType)
	if target.isAlly and Ready(_W) and CurrentPctMana(myHero) >= Menu.Skills.W.Mana:Value() and LocalGeometry:IsInRange(myHero.pos, target.pos, W.Range) then
		local castPosition = mousePos		
		if target ~= myHero then
			castPosition = LocalGeometry:PredictUnitPosition(target, W.Delay + LocalGeometry:GetDistance(myHero.pos, target.pos)/W.Speed)
		else
			local ally = NearestAlly(myHero.pos, W.Range)
			if ally then
				castPosition = LocalGeometry:PredictUnitPosition(ally, W.Delay + LocalGeometry:GetDistance(myHero.pos, ally.pos)/W.Speed)
			end
		end		
		CastSpell(HK_W, castPosition)
	end
	
	if target.isEnemy and CanTarget(target) and CanTarget(target) and LocalDamageManager.IMMOBILE_TYPES[ccType] then
		
		if Ready(_Q) and CurrentPctMana(myHero) >= Menu.Skills.Q.Mana:Value() and Menu.Skills.Q.Auto:Value() and LocalGeometry:IsInRange(myHero.pos, target.pos, Q.Range) then
			NextTick = LocalGameTimer() + .25
			CastSpell(HK_Q, target.pos,true)
			return
		end
		
		if Ready(_E) and CanTarget(target) and CurrentPctMana(myHero) >= Menu.Skills.E.Mana:Value() and Menu.Skills.E.Auto:Value() and LocalGeometry:IsInRange(myHero.pos, target.pos, E.Range) then
			NextTick = LocalGameTimer() +.25
			CastSpell(HK_E, target.pos)
			return
		end
	end
end