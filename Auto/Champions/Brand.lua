Q = {Range = 1050, Radius = 80, Delay = 0.25, Speed = 1550, Collision = true}
W = {Range = 900, Radius = 250, Delay = 0.875, Speed = 99999}
E = {Range = 600, Delay = 0.25, Speed = 99999}
R = {Range = 750, Radius = 600, Delay = 0.25, Speed = 1700}

function LoadScript()
	Menu = MenuElement({type = MENU, id = myHero.networkID, name = myHero.charName})
	Menu:MenuElement({id = "Skills", name = "Skills", type = MENU})

	Menu.Skills:MenuElement({id = "Q", name = "[Q] Sear", type = MENU})
	Menu.Skills.Q:MenuElement({id = "Accuracy", name = "Accuracy", value = 3, min = 1, max = 6, step = 1 })
	Menu.Skills.Q:MenuElement({id = "Auto", name = "Auto Stun", value = true})
	
	Menu.Skills:MenuElement({id = "W", name = "[W] Pillar of Flame", type = MENU})
	Menu.Skills.W:MenuElement({id = "AccuracyCombo", name = "Combo Accuracy", value = 3, min = 1, max = 6, step = 1 })
	Menu.Skills.W:MenuElement({id = "AccuracyAuto", name = "Auto Cast Accuracy", value = 3, min = 1, max = 6, step = 1 })
	Menu.Skills.W:MenuElement({id = "Mana", name = "Auto Cast Mana", value = 30, min = 1, max = 100, step = 5 })
	
	Menu.Skills:MenuElement({id = "E", name = "[E] Conflagration", type = MENU})
	Menu.Skills.E:MenuElement({id = "Mana", name = "Auto Cast Mana", value = 15, min = 1, max = 100, step = 5 })
	Menu.Skills.E:MenuElement({id = "Targets", name = "Auto Harass Targets", type = MENU})
	for i = 1, LocalGameHeroCount() do
		local hero = LocalGameHero(i)
		if hero and hero.isEnemy then
			Menu.Skills.E.Targets:MenuElement({id = hero.networkID, name = hero.charName, value = true, toggle = true})
		end
	end
	
	Menu.Skills:MenuElement({id = "R", name = "[R] Pyroclasm", type = MENU})
	Menu.Skills.R:MenuElement({id = "Count", name = "Auto Cast On Enemy Count", value = 3, min = 1, max = 6, step = 1 })	
	Menu.Skills.R:MenuElement({id = "Auto", name = "Auto Cast", value = false})
	
	Menu.Skills:MenuElement({id = "Combo", name = "Combo Key",value = false,  key = string.byte(" ") })	
	
	LocalDamageManager:OnIncomingCC(function(target, damage, ccType) OnCC(target, damage, ccType) end)
	LocalObjectManager:OnBlink(function(target) OnBlink(target) end )
	LocalObjectManager:OnSpellCast(function(spell) OnSpellCast(spell) end)
	Callback.Add("Tick", function() Tick() end)
end

local WPos = nil
local WHitTime = 0

function OnSpellCast(spell)
	if spell.data.name == "BrandW" then
		WPos = Vector(spell.data.placementPos.x, spell.data.placementPos.y, spell.data.placementPos.z)
		WHitTime = LocalGameTimer() + W.Delay
	end
end


local NextTick = LocalGameTimer()
function Tick()
	if LocalGameIsChatOpen() then return end
	local currentTime = LocalGameTimer()
	if NextTick > currentTime then return end
	
	local target = GetTarget(Q.Range)
	if target and Ready(_Q) and  CanTarget(target) and (Menu.Skills.Combo:Value() or Menu.Skills.Q.Auto:Value()) then
		local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, Q.Range, Q.Delay, Q.Speed, Q.Radius, Q.Collision, Q.IsLine)
		if castPosition and accuracy >= Menu.Skills.Q.Accuracy:Value() then
			local timeToIntercept = LocalGeometry:GetSpellInterceptTime(myHero.pos, castPosition, Q.Delay, Q.Speed)
			if LocalBuffManager:HasBuff(target, "BrandAblaze", timeToIntercept) then
				NextTick = LocalGameTimer() + .25
				CastSpell(HK_Q, castPosition)
				return
			elseif WHitTime > LocalGameTimer() and LocalGameTimer() + timeToIntercept >  WHitTime and LocalGeometry:IsInRange(WPos, castPosition, W.Radius) then				
				NextTick = LocalGameTimer() + .25
				CastSpell(HK_Q, castPosition)
				return
			end
			
		end
	end
	
	local target = GetTarget(W.Range)
	if target and Ready(_W) and CanTarget(target) and (CurrentPctMana(myHero) >= Menu.Skills.W.Mana:Value() or Menu.Skills.Combo:Value()) then
		local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, W.Range, W.Delay, W.Speed, W.Radius, W.Collision, W.IsLine)
		if accuracy >= Menu.Skills.W.AccuracyAuto:Value() or (Menu.Skills.Combo:Value() and accuracy >= Menu.Skills.W.AccuracyCombo:Value()) then
			NextTick = LocalGameTimer() + .25
			CastSpell(HK_W, castPosition)
			return
		end
	end
	
	local target = GetTarget(E.Range)
	if target and Ready(_E) and Menu.Skills.E.Targets[target.networkID] and Menu.Skills.E.Targets[target.networkID]:Value() and CanTarget(target) and (CurrentPctMana(myHero) >= Menu.Skills.E.Mana:Value() or Menu.Skills.Combo:Value()) then
		NextTick = LocalGameTimer() + .25
		CastSpell(HK_E, target)
		return
	end
	local target = GetTarget(R.Range)
	if target and Ready(_R) and CanTarget(target) and EnemyCount(target.pos, R.Radius) >= Menu.Skills.R.Count:Value() and (Menu.Skills.Combo:Value() or Menu.Skills.R.Auto:Value())then
		NextTick = LocalGameTimer() + .25
		CastSpell(HK_R, target)
		return
	end
	NextTick = LocalGameTimer() + .1
end


function OnBlink(target)
	if target.isEnemy and CanTarget(target) and Ready(_W) and Menu.Skills.W.Auto:Value() and LocalGeometry:IsInRange(myHero.pos, target.pos, W.Range) then
		local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, W.Range, W.Delay, W.Speed, W.Radius, W.Collision)
		if accuracy > 0 then
			CastSpell(HK_E, castPosition)
		end
	end
end

function OnCC(target, damage, ccType)
	if target.isEnemy and CanTarget(target) and CanTarget(target) and LocalDamageManager.IMMOBILE_TYPES[ccType] then
		if target.isEnemy and CanTarget(target) and Ready(_W) and Menu.Skills.W.Auto:Value() and LocalGeometry:IsInRange(myHero.pos, target.pos, W.Range) then
			local castPosition, accuracy = LocalGeometry:GetCastPosition(myHero, target, W.Range, W.Delay, W.Speed, W.Radius, W.Collision)
			if accuracy > 0 then
				CastSpell(HK_E, target.pos)
			end
		end
	end
end