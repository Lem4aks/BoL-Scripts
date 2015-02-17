if myHero.charName ~= "Gragas" then return end
function OnLoad()
	require "Prodiction"
	require "Collision"
	require "AoE_Skillshot_Position"
	Vars()
	Menu()
    Spells()
	-- Create Table structure
	for i=1, heroManager.iCount do
		local champ = heroManager:GetHero(i)
		if champ.team ~= myHero.team then
		EnemysInTable = EnemysInTable + 1
		EnemyTable[EnemysInTable] = { hero = champ, Name = champ.charName, q = 0, e = 0, r = 0, IndicatorText = "", IndicatorPos, NotReady = false, Pct = 0, PeelMe = false }
		
		end
	end
	LoadJungle()
end


function OnTick()
	Target = ts.target
	GlobalInfo()
	AutoSpells()
	Calculations()
	if GMenu.General.JungleSteal then
		JungleSteal()
	else
		Killing = nil
	end
	if GMenu.General.Combo then
		Combo()
	end
	if GMenu.General.Harass then
		if ValidTarget(Target) then
			if dashx ~= nil and qReady then
				CastSpell(_Q, dashx, dashz)
			elseif qReady and qPos then
				CastSpell(_Q, qPos.x, qPos.z)
			end
		end
	end


	if GMenu.Skills.AutoPull then
		local PeelMe = nil
		for i=1, EnemysInTable do
			if EnemyTable[i].PeelMe == true then
				PeelMe = EnemyTable[i].hero
				if GetDistance(PeelMe) < 1000 and ValidTarget(PeelMe) then
					PullWithR(PeelMe)
				end
			end
		end
	end

	if GMenu.General.ManualPull then
		if not ChannelingW and GMenu.General.MoveToMousePull then
			moveToCursor()
		end
		for _, enemy in pairs(GetEnemyHeroes()) do
			if PeelTargetManual ~= nil and GetDistance(mousePos, PeelTargetManual) > 250 then
				PeelTargetManual = nil
			end
			
			if GetDistance(mousePos, enemy) < 250 then
				if PeelTargetManual == nil then
					PeelTargetManual = enemy
					 
				end
				if PeelTargetManual ~= nil then
					PullWithR(PeelTargetManual)
				end
				
			end
			
			
		end

		if dashx ~= nil then
			CastSpell(_Q, dashx, dashz)
			if EStart < GetGameTimer() then -- Start casting E at landing pos as soon as landing pos is known
				CastSpell(_E, dashx, dashz)
				return
			end
		return
		end	
	else
		PeelTargetManual = nil
		
	end
end


function Combo()
		
		
	if GMenu.General.OrbWalk then
		OrbWalk()
	end

	if ValidTarget(Target) then

		if GetDistance(Target)<800 then 
				if dfgReady then CastSpell(dfgSlot, Target) end
		end
		CastE(Target)
		CastQ(Target)
		GlobalInfo() -- Fail safe to determine combo behaviour
		CastR(Target)
		
	end
		


end

function CastE(unit)	
	if GMenu.Skills.DontETeamfight and AreaEnemyCount(unit, 700) >= 2 then return
	else
	
		if eReady and GMenu.Skills.UseE then

		
			if dashx ~= nil then
				if EStart < GetGameTimer() then -- Start casting E at landing pos as soon as landing pos is known
					CastSpell(_E, dashx, dashz)
					return
				end
				return
			end
			
			
				if GMenu.Skills.PullKillable and THealth < TotalDamage and AllReady and GotMana and not UltiThrown then return end
			
				if qReady and qDmg > THealth then
					return
				elseif rReady and rDmg > THealth then
					return
				elseif qReady and rReady and qDmg+rDmg > THealth then
					return
				else
					if not UltiThrown then
						local eCollides = eCol:GetMinionCollision(myHero, unit)
						if not eCollides and GetDistance(ePos)<650 then
							CastSpell(_E, ePos.x, ePos.z)
						end

					end
				end
			
		end
	
	
	end

	


	
end

function CastQ(unit)

	if qReady then
	
		if dashx ~= nil then -- Start casting Q at landing pos as soon as landing pos is known
			CastSpell(_Q, dashx, dashz)
		end
		
		if not UltiThrown and qPos then
			if THealth < qDmg then
				CastSpell(_Q, qPos.x, qPos.z)
			end
			if GMenu.Skills.PullKillable and THealth < TotalDamage and AllReady and GotMana then return end
		
		
		CastSpell(_Q, qPos.x, qPos.z)
		
		end
	end	

end



function CastR(unit)



	
	if GMenu.Skills.DontUltiTeamfight and AreaEnemyCount(unit, 700) > 2 then return 
	
	elseif rReady and GMenu.Skills.MecKsR and MecPos and AreaEnemyCount(MecPos, 400, true) >= GMenu.Skills.MecAmmount then
		CastSpell(_R, MecPos.x, MecPos.z)
		
	elseif rReady and THealth < rDmg and GMenu.Skills.KsR then
		
		if THealth < qDmg or THealth < eDmg and GMenu.Skills.KsR then
			if not BarrelThrown then
				if not qReady and THealth < qDmg then
					CastSpell(_R, rPos.x, rPos.z)
				end
			return end
			if BarrelThrown and Barrel ~= nil and GetDistance(Barrel, unit) > 350 then
					CastSpell(_R, rPos.x, rPos.z)

			end
		end	
	elseif rReady then
		if TotalDamage > THealth and AllReady then
			PullWithR(unit)
		end
		if qDmg+eDmg+rDmg > THealth then
			if qReady or qCurrCd < 1.5 then
				PullWithR(unit)
			end
		end
	end	
	
		
		
				

end




function PullWithR(unit)
	
	local pos, time, hitchance =   ProR:GetPrediction(unit)	
	if pos then
		local x,y,z = (Vector(pos) - Vector(myHero)):normalized():unpack()
		posX = pos.x + (x * 300)
		posY = pos.y + (y * 300)
		posZ = pos.z + (z * 300)

		
		
		CastSpell(_R, posX, posZ)
		DashTarget = unit
	end
		
	
end

function AutoSpells()

	
	if GMenu.Skills.AutoW and wReady and AreaEnemyCount(myHero, 1000) == 0 and not Recalling and ManaPct <= GMenu.Skills.ManaPct and not BarrelThrown then
		CastSpell(_W)
	end
	if ChannelingW and AreaEnemyCount(myHero, 1000) >= 2 then
		moveToCursor()
	end
	for _, enemy in pairs(GetEnemyHeroes()) do
		if ValidTarget(enemy) then
			if Barrel ~= nil then
				if GetDistance(enemy, Barrel) < 300 then
					CastSpell(_Q)
				end
			
			
			end
			if GMenu.Skills.KsQ and qReady and enemy.health < getDmg("Q", enemy, myHero) and not UltiThrown and dashx == nil and GetDistance(enemy, myHero) < 1100 then
					local q = ProQ:GetPrediction(enemy)
					CastSpell(_Q, q.x, q.z)
			end				
	
			if iReady then
				if getDmg("IGNITE", enemy, myHero) >= enemy.health and GetDistance(enemy, myHero) < 600 then
					CastSpell(iSlot, enemy)
				end
			end
		end
	end
end

function OrbWalk()
	if ValidTarget(Target) then
		if GetDistance(Target) <= trueRange() then
			if timeToShoot() and not ChannelingW then
				myHero:Attack(Target)
			elseif heroCanMove() and not ChannelingW then
				moveToCursor()
			end
		else
			if not ChannelingW then
				moveToCursor()
			end
		end
	else
		if not ChannelingW then
			moveToCursor()
		end
	end
end

function JungleSteal()

	if Nashor ~= nil then if not Nashor.valid or Nashor.dead or Nashor.health <= 0 then Nashor = nil end end
	if Dragon ~= nil then if not Dragon.valid or Dragon.dead or Dragon.health <= 0 then Dragon = nil end end
	if Golem1 ~= nil then if not Golem1.valid or Golem1.dead or Golem1.health <= 0 then Golem1 = nil end end
	if Golem2 ~= nil then if not Golem2.valid or Golem2.dead or Golem2.health <= 0 then Golem2 = nil end end
	if Lizard1 ~= nil then if not Lizard1.valid or Lizard1.dead or Lizard1.health <= 0 then Lizard1 = nil end end
	if Lizard2 ~= nil then if not Lizard2.valid or Lizard2.dead or Lizard2.health <= 0 then Lizard2 = nil end end
	
	if Nashor ~= nil and GetDistance(Nashor) < 1300 and Nashor.visible then Kill(Nashor, true) end
	if Dragon ~= nil and GetDistance(Dragon) < 1300 and Dragon.visible then Kill(Dragon, true) end
	if Golem1 ~= nil and GetDistance(Golem1) < 1300 and Golem1.visible then Kill(Golem1) end
	if Golem2 ~= nil and GetDistance(Golem2) < 1300 and Golem2.visible then Kill(Golem2) end
	if Lizard1 ~= nil and GetDistance(Lizard1) < 1300 and Lizard1.visible then Kill(Lizard1) end
	if Lizard2 ~= nil and GetDistance(Lizard2) < 1300 and Lizard2.visible then Kill(Lizard2) end	


end

function Kill(object, static)
	if static == nil then static = false end
	DmgOnObject = 0
	if qReady then DmgOnObject = DmgOnObject + getDmg("Q", object, myHero) end
	if rReady then DmgOnObject = DmgOnObject + getDmg("R", object, myHero) end
	if object.health + 50 < DmgOnObject then
		if static == true then
			Killing = object
			local x,y,z = (Vector(object) - Vector(myHero)):normalized():unpack()
			local rPosX = object.x - (x * 400)
			local rPosY = object.y - (y * 400)
			local rPosZ = object.z - (z * 400)
			local qPosX = object.x - (x * 300)
			local qPosY = object.y - (y * 300)
			local qPosZ = object.z - (z * 300)
		
				if qReady then
				CastSpell(_Q, qPosX, qPosZ)
				end
				if rReady then
				CastSpell(_R, rPosX, rPosZ)
				end
		else
			if qReady then 
			CastSpell(_Q, object.x, object.z)
			end
			if rReady then
			CastSpell(_R, object.x, object.z)
			end
		end
	end
	if Barrel~= nil and GetDistance(Barrel, object) < 350 then
		CastSpell(_Q)
	end
end

------------------
-- 	Helpers 	--
------------------


function GlobalInfo()
	MouseScreen = WorldToScreen(D3DXVECTOR3(mousePos.x, mousePos.y, mousePos.z))
	ts:update()
	qReady = myHero:CanUseSpell(_Q) == READY and not BarrelThrown
	wReady = myHero:CanUseSpell(_W) == READY
	eReady = myHero:CanUseSpell(_E) == READY
	rReady = myHero:CanUseSpell(_R) == READY
	qMana = myHero:GetSpellData(_Q).mana
	eMana = myHero:GetSpellData(_E).mana
	rMana = myHero:GetSpellData(_R).mana
	qCurrCd = myHero:GetSpellData(_Q).currentCd
	eCurrCd = myHero:GetSpellData(_E).currentCd
	rCurrCd = myHero:GetSpellData(_R).currentCd
	

	iSlot = ((myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") and SUMMONER_1) or (myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") and SUMMONER_2) or nil)
	iReady = (iSlot ~= nil and myHero:CanUseSpell(iSlot) == READY)
	dfgSlot = GetInventorySlotItem(3128)
	dfgReady = (dfgSlot ~= nil and GetInventoryItemIsCastable(3128,myHero))
	lichSlot = GetInventorySlotItem(3100)
	lichReady = (lichSlot ~= nil and myHero:CanUseSpell(lichSlot) == READY)
	sheenSlot = GetInventorySlotItem(3057)
	sheenReady = (sheenSlot ~= nil and myHero:CanUseSpell(sheenSlot) == READY)

	MyMana = myHero.mana
	ManaPct = math.round((myHero.mana / myHero.maxMana)*100)
	if qMana + eMana + rMana <= MyMana then
		GotMana = true
	else
		GotMana = false
	end
	if wTime ~= nil and GetGameTimer()-wTime > 1.4 then 
		ChannelingW = false
		wTime = nil
	end
	
	if ValidTarget(Target) then
		MecPos = GetAoESpellPosition(400, Target)
		qPos = ProQ:GetPrediction(Target)
		ePos = ProE:GetPrediction(Target)
		rPos = ProR:GetPrediction(Target)


		qDmg = getDmg("Q", Target, myHero)
		eDmg = getDmg("E", Target, myHero)
		rDmg = getDmg("R", Target, myHero)
		iDmg = (iReady and getDmg("IGNITE", Target, myHero) or 0)
		THealth = Target.health
		sheendamage = (SHEENSlot and getDmg("SHEEN",enemy,myHero) or 0)
		lichdamage = (LICHSlot and getDmg("LICHBANE",enemy,myHero) or 0)
		TotalDamage = qDmg+eDmg+rDmg+sheendamage+lichdamage+iDmg
		if dfgReady then 
			TotalDamage = TotalDamage * 1.2
		end	
		if rReady then
			AllReady = true
			if qCurrCd > 1.5 then
				AllReady = false
			end
			if iSlot and not iReady then
				AllReady = false
			end
			if dfgSlot and not dfgReady then
				AllReady = false
			end
		else
			AllReady = false
		end
		
	end
	if myHero.dead then
	-- Fail safe shit
		UltiThrown = false
		BarrelThrown = false
		DashTarget = nil
		dashx = nil
		dashy = nil
		dashz = nil
		Recalling = false
		Barrel = nil
		GetDash = false
		DashEndTime = nil
		EStart = nil
		
	end
	
	if DashEndTime ~= nil then
		if DashEndTime < GetGameTimer() and not Reset then
			Reset = true
		end
	end
	
	if Reset == true then
		
	
			dashx = nil
			dashy = nil
			dashz = nil
			GetDash = false
			DashTarget = nil
			UltiThrown = false
			Reset = false
			DashEndTime = nil
			EStart = nil
		
	end


end


function AreaEnemyCount(Spot, Range, Killable)
	local count = 0
	if Killable == nil then Killable = false end
	
	if Killable == true then
	
		for _, enemy in pairs(GetEnemyHeroes()) do
			if enemy and not enemy.dead and GetDistance(Spot, enemy) <= Range and getDmg("R", enemy, myHero) > enemy.health then
				count = count + 1
			end
		end   
	
	
	else
		for _, enemy in pairs(GetEnemyHeroes()) do
			if enemy and not enemy.dead and GetDistance(Spot, enemy) <= Range then
				count = count + 1
			end
		end            
	end
	return count
end





------------------
-- Callbacks	--
------------------

function OnProcessSpell(object,spell)
--	gragasbarrelrolltoggle
	if object == myHero then
	
		if spell.name:find("GragasExplosive") then -- ULT casted
			UltiThrown = true
			GetDash = true
			UltTime = math.floor(GetGameTimer())
		
		end
		if spell.name:find("GragasBarrelRoll") then -- Q casted
			BarrelThrown = true
		end
		if spell.name:find("GragasDrunkenRage") then -- W casted
			ChannelingW = true
			wTime = GetGameTimer()
		end
		if spell.name:lower():find("attack") then
			lastAttack = GetTickCount() - GetLatency()/2
			lastWindUpTime = spell.windUpTime*1000
			lastAttackCD = spell.animationTime*1000
		end
	end
end

-- gragas_barrelroll
-- gragas_barrelboom
function OnCreateObj(obj)

	if obj.name:find("gragas_barrelfoam") and BarrelThrown then
		Barrel = obj
	end
	if obj ~= nil and obj.type == "obj_AI_Minion" and obj.name ~= nil then
		if obj.name == "TT_Spiderboss7.1.1" then Vilemaw = obj
		elseif obj.name == "Worm12.1.1" then Nashor = obj
		elseif obj.name == "Dragon6.1.1" then Dragon = obj
		elseif obj.name == "AncientGolem1.1.1" then Golem1 = obj
		elseif obj.name == "AncientGolem7.1.1" then Golem2 = obj
		elseif obj.name == "LizardElder4.1.1" then Lizard1 = obj
		elseif obj.name == "LizardElder10.1.1" then Lizard2 = obj end
	end
	
end

function OnDeleteObj(obj)

	if obj.name:find("gragas_caskboom") and UltiThrown then -- Ult Exploded
		UltiThrown = false
	end
	
	if obj ~= nil and obj.name ~= nil then
		if obj.name == "TT_Spiderboss7.1.1" then Vilemaw = nil
		elseif obj.name == "Worm12.1.1" then Nashor = nil
		elseif obj.name == "Dragon6.1.1" then Dragon = nil
		elseif obj.name == "AncientGolem1.1.1" then Golem1 = nil
		elseif obj.name == "AncientGolem7.1.1" then Golem2 = nil
		elseif obj.name == "LizardElder4.1.1" then Lizard1 = nil
		elseif obj.name == "LizardElder10.1.1" then Lizard2 = nil end
	end

end

function OnGainBuff(unit, buff) 
	if unit.isMe then
		
		if buff.name:find("Recall") then
		Recalling = true
		end
		if buff.name:find("drunkenrageself") then
			ChannelingW = false
		end
	end
end

function OnLoseBuff(unit, buff) 
	
	if unit.isMe then

		if buff.name:find("GragasBarrelRoll") then
			BarrelThrown = false
			Barrel = nil
		end
		if buff.name:find("Recall") then
		Recalling = false
		end
	end
end

function OnUpdateBuff(unit, buff) 
	
	if unit.isMe then
		
		if buff.name:find("drunkenrageself") then
			ChannelingW = false
		end
	end
end

function OnDash(unit, dash) 
	if DashTarget ~= nil and unit == DashTarget and GetDash then -- Get targets landing spot from ulti explosion
	
		dashend = dash.endPos
		dashstartx = unit.x
		dashstarty = unit.y
		dashx = dashend.x
		dashz = dashend.z
		dashy = dashend.y
		DashEndTime = dash.endT
		EStart = DashEndTime - 0.3
		
	end
	
end




------------------
-- Draw+Calcs	--
------------------
function OnDraw()


	if Barrel ~= nil then DrawCircle(Barrel.x, Barrel.y, Barrel.z, 300, ARGB(255,0,255,0)) end

	
	if not GMenu.Draw.DisableDraw then
	
	
	if GMenu.Draw.ScriptMenu then
		ScriptMenu()
	end
	if GMenu.Draw.DmgIndic then
	for i=1, EnemysInTable do
		local enemy = EnemyTable[i].hero
	--		enemy.barData = GetEnemyBarData()
			local barPos = WorldToScreen(D3DXVECTOR3(enemy.x, enemy.y, enemy.z))
            local PosX = barPos.x - 35
            local PosY = barPos.y - 50
	--		local barPosOffset = GetUnitHPBarOffset(enemy)
	--		local barOffset = { x = enemy.barData.PercentageOffset.x, y = enemy.barData.PercentageOffset.y }
	--		local barPosPercentageOffset = { x = enemy.barData.PercentageOffset.x, y = enemy.barData.PercentageOffset.y }
	--		local BarPosOffsetX = 171
	--		local BarPosOffsetY = 46
	--		local CorrectionY =  14.5
	--		local StartHpPos = 31

			local Text = EnemyTable[i].IndicatorText
	--		barPos.x = barPos.x + (barPosOffset.x - 0.5 + barPosPercentageOffset.x) * BarPosOffsetX + StartHpPos 
	--		barPos.y = barPos.y + (barPosOffset.y - 0.5 + barPosPercentageOffset.y) * BarPosOffsetY + CorrectionY 
			
				if EnemyTable[i].NotReady == true then
					DrawText(tostring(Text),13,PosX ,PosY ,orange)		
		--			DrawText("|",13,barPos.x+IndicatorPos ,barPos.y ,orange)
		--			DrawText("|",13,barPos.x+IndicatorPos ,barPos.y-9 ,orange)
		--			DrawText("|",13,barPos.x+IndicatorPos ,barPos.y-18 ,orange)
				else
					DrawText(tostring(Text),13,PosX ,PosY ,ARGB(255,0,255,0))	
		--			DrawText("|",13,barPos.x+IndicatorPos ,barPos.y ,ARGB(255,0,255,0))
		--			DrawText("|",13,barPos.x+IndicatorPos ,barPos.y-9 ,ARGB(255,0,255,0))
		--			DrawText("|",13,barPos.x+IndicatorPos ,barPos.y-18 ,ARGB(255,0,255,0))
				end
			
		end
	end
	end
	if PeelTargetManual ~= nil then
		DrawText("Pull target: " .. tostring(PeelTargetManual.charName),15, MouseScreen.x, MouseScreen.y-8 ,ARGB(255,0,255,0))
	end
	if GMenu.Draw.ShowQ then
		if qReady then
		DrawCircle(myHero.x, myHero.y, myHero.z, 950, ARGB(255,0,255,0))
		else
		DrawCircle(myHero.x, myHero.y, myHero.z, 950, ARGB(255,255,0,0))
		end
	end
	if GMenu.Draw.ShowE then
		if eReady then
		DrawCircle(myHero.x, myHero.y, myHero.z, 650, ARGB(255,0,255,0))
		else
		DrawCircle(myHero.x, myHero.y, myHero.z, 650, ARGB(255,255,0,0))
		end
	end
	if GMenu.Draw.ShowR then
		if rReady then
		DrawCircle(myHero.x, myHero.y, myHero.z, 1100, ARGB(255,0,255,0))
		else
		DrawCircle(myHero.x, myHero.y, myHero.z, 1100, ARGB(255,255,0,0))
		end
	end
	

end


function ScriptMenu()
	
	
	DrawRectangleOutline(MenuX+GMenu.Draw.HudPosX, MenuY+GMenu.Draw.HudPosY, 130, 300, green, 1)
	
	
-- Menu text

	DrawText("Zikkah's Gragas",15, MenuX+GMenu.Draw.HudPosX+17, MenuY+GMenu.Draw.HudPosY ,orange)
	DrawText("---Q Settings:", 15, MenuX+GMenu.Draw.HudPosX+9, MenuY+GMenu.Draw.HudPosY+11 ,orange)
	DrawText("Auto KS", 15, MenuX+GMenu.Draw.HudPosX+9, MenuY+GMenu.Draw.HudPosY+22 ,GetColor(GMenu.Skills.KsQ))
	
	DrawText("---W Settings:", 15, MenuX+GMenu.Draw.HudPosX+9, MenuY+GMenu.Draw.HudPosY+44 ,orange)
	DrawText("Auto W < " .. tostring(GMenu.Skills.ManaPct) .. "%", 15, MenuX+GMenu.Draw.HudPosX+9, MenuY+GMenu.Draw.HudPosY+55 ,GetColor(GMenu.Skills.AutoW))

	
	DrawText("---E Settings   ",15, MenuX+GMenu.Draw.HudPosX+9, MenuY+GMenu.Draw.HudPosY+77 ,orange)	
	DrawText("Use in Combo", 15, MenuX+GMenu.Draw.HudPosX+9, MenuY+GMenu.Draw.HudPosY+88 ,GetColor(GMenu.Skills.UseE))
--	DrawText("Ks R", 15, MenuX+GMenu.Draw.HudPosX+9, MenuY+GMenu.Draw.HudPosY+99 ,GetColor(GMenu.Skills.KsR))

	
	DrawText("---R Settings",15, MenuX+GMenu.Draw.HudPosX+9, MenuY+GMenu.Draw.HudPosY+110 ,orange)	
	DrawText("Pull Killable", 15, MenuX+GMenu.Draw.HudPosX+9, MenuY+GMenu.Draw.HudPosY+121 ,GetColor(GMenu.Skills.PullKillable))
	DrawText("Auto KS", 15, MenuX+GMenu.Draw.HudPosX+9, MenuY+GMenu.Draw.HudPosY+132 ,GetColor(GMenu.Skills.KsR))

	
	DrawText("---Teamfight",15, MenuX+GMenu.Draw.HudPosX+9, MenuY+GMenu.Draw.HudPosY+154 ,orange)	
	DrawText("No E in combo", 15, MenuX+GMenu.Draw.HudPosX+9, MenuY+GMenu.Draw.HudPosY+165 ,GetColor(GMenu.Skills.DontETeamfight))
	DrawText("No ulti in combo", 15, MenuX+GMenu.Draw.HudPosX+9, MenuY+GMenu.Draw.HudPosY+176 ,GetColor(GMenu.Skills.DontUltiTeamfight))
	DrawText("Auto MEC ulti Ks(" .. tostring(GMenu.Skills.MecAmmount) .. ")", 15, MenuX+GMenu.Draw.HudPosX+9, MenuY+GMenu.Draw.HudPosY+187 ,GetColor(GMenu.Skills.MecKsR))
	
	DrawText("Auto Pull:", 15, MenuX+GMenu.Draw.HudPosX+9, MenuY+GMenu.Draw.HudPosY+198 ,GetColor(GMenu.Skills.AutoPull))
	
	-- Enemy names	
	if EnemyTable[1] ~= nil then DrawText(EnemyTable[1].Name,15, MenuX+GMenu.Draw.HudPosX+50, MenuY+GMenu.Draw.HudPosY+209 ,GetColor(EnemyTable[1].PeelMe)) end
	if EnemyTable[2] ~= nil then DrawText(EnemyTable[2].Name,15, MenuX+GMenu.Draw.HudPosX+50, MenuY+GMenu.Draw.HudPosY+220 ,GetColor(EnemyTable[2].PeelMe)) end
	if EnemyTable[3] ~= nil then DrawText(EnemyTable[3].Name,15, MenuX+GMenu.Draw.HudPosX+50, MenuY+GMenu.Draw.HudPosY+231 ,GetColor(EnemyTable[3].PeelMe)) end
	if EnemyTable[4] ~= nil then DrawText(EnemyTable[4].Name,15, MenuX+GMenu.Draw.HudPosX+50, MenuY+GMenu.Draw.HudPosY+242 ,GetColor(EnemyTable[4].PeelMe)) end
	if EnemyTable[5] ~= nil then DrawText(EnemyTable[5].Name,15, MenuX+GMenu.Draw.HudPosX+50, MenuY+GMenu.Draw.HudPosY+253 ,GetColor(EnemyTable[5].PeelMe)) end

	-- Menu Controls
	if IsKeyDown(0x01) then
		if not Pressed then 
		
			-- Q Menu Controls
			if MouseScreen.x > MenuX+GMenu.Draw.HudPosX+9 and MouseScreen.x < MenuX+GMenu.Draw.HudPosX+ 100 and MouseScreen.y > MenuY+GMenu.Draw.HudPosY+ 23 and MouseScreen.y < MenuY+GMenu.Draw.HudPosY+33  then
				GMenu.Skills.KsQ = not GMenu.Skills.KsQ
			end
			
			-- W menu controls

			if MouseScreen.x > MenuX+GMenu.Draw.HudPosX+9 and MouseScreen.x < MenuX+GMenu.Draw.HudPosX+ 100 and MouseScreen.y > MenuY+GMenu.Draw.HudPosY+ 56 and MouseScreen.y < MenuY+GMenu.Draw.HudPosY+66  then
				GMenu.Skills.AutoW = not GMenu.Skills.AutoW
			end	

	
			-- E menu controls
			if MouseScreen.x > MenuX+GMenu.Draw.HudPosX+9 and MouseScreen.x < MenuX+GMenu.Draw.HudPosX+ 100 and MouseScreen.y > MenuY+GMenu.Draw.HudPosY+ 89 and MouseScreen.y < MenuY+GMenu.Draw.HudPosY+99  then
				GMenu.Skills.UseE = not GMenu.Skills.UseE
			end	
	--[[		if MouseScreen.x > MenuX+GMenu.Draw.HudPosX+9 and MouseScreen.x < MenuX+GMenu.Draw.HudPosX+ 110 and MouseScreen.y > MenuY+GMenu.Draw.HudPosY+ 100 and MouseScreen.y < MenuY+GMenu.Draw.HudPosY+110  then
				GMenu.GapcloseK = not GMenu.GapcloseK
			end	
			if MouseScreen.x > MenuX+GMenu.Draw.HudPosX+9 and MouseScreen.x < MenuX+GMenu.Draw.HudPosX+ 110 and MouseScreen.y > MenuY+GMenu.Draw.HudPosY+ 111 and MouseScreen.y < MenuY+GMenu.Draw.HudPosY+121  then
				GMenu.GapcloseP = not GMenu.GapcloseP
			end			]]

			-- r menu controls
			if MouseScreen.x > MenuX+GMenu.Draw.HudPosX+9 and MouseScreen.x < MenuX+GMenu.Draw.HudPosX+ 110 and MouseScreen.y > MenuY+GMenu.Draw.HudPosY+ 122 and MouseScreen.y < MenuY+GMenu.Draw.HudPosY+132  then
				GMenu.Skills.PullKillable = not GMenu.Skills.PullKillable
			end						
			if MouseScreen.x > MenuX+GMenu.Draw.HudPosX+9 and MouseScreen.x < MenuX+GMenu.Draw.HudPosX+ 110 and MouseScreen.y > MenuY+GMenu.Draw.HudPosY+ 133 and MouseScreen.y < MenuY+GMenu.Draw.HudPosY+143  then
				GMenu.Skills.KsR = not GMenu.Skills.KsR
			end			
			
			
			-- Teamfight menu controls
			if MouseScreen.x > MenuX+GMenu.Draw.HudPosX+9 and MouseScreen.x < MenuX+GMenu.Draw.HudPosX+ 110 and MouseScreen.y > MenuY+GMenu.Draw.HudPosY+ 166 and MouseScreen.y < MenuY+GMenu.Draw.HudPosY+176  then
				GMenu.Skills.DontETeamfight = not GMenu.Skills.DontETeamfight
			end	
			if MouseScreen.x > MenuX+GMenu.Draw.HudPosX+9 and MouseScreen.x < MenuX+GMenu.Draw.HudPosX+ 110 and MouseScreen.y > MenuY+GMenu.Draw.HudPosY+ 177 and MouseScreen.y < MenuY+GMenu.Draw.HudPosY+187  then
				GMenu.Skills.DontUltiTeamfight = not GMenu.Skills.DontUltiTeamfight
			end	
			if MouseScreen.x > MenuX+GMenu.Draw.HudPosX+9 and MouseScreen.x < MenuX+GMenu.Draw.HudPosX+ 110 and MouseScreen.y > MenuY+GMenu.Draw.HudPosY+ 188 and MouseScreen.y < MenuY+GMenu.Draw.HudPosY+198  then
				GMenu.Skills.MecKsR = not GMenu.Skills.MecKsR
			end			
			if MouseScreen.x > MenuX+GMenu.Draw.HudPosX+9 and MouseScreen.x < MenuX+GMenu.Draw.HudPosX+ 110 and MouseScreen.y > MenuY+GMenu.Draw.HudPosY+ 199 and MouseScreen.y < MenuY+GMenu.Draw.HudPosY+209  then
				GMenu.Skills.AutoPull = not GMenu.Skills.AutoPull
			end						
			
			
			if MouseScreen.x > MenuX+GMenu.Draw.HudPosX+9 and MouseScreen.x < MenuX+GMenu.Draw.HudPosX+ 110 and MouseScreen.y > MenuY+GMenu.Draw.HudPosY+ 210 and MouseScreen.y < MenuY+GMenu.Draw.HudPosY+220  then
				
				EnemyTable[1].PeelMe = not EnemyTable[1].PeelMe
				
				
			end		
			if MouseScreen.x > MenuX+GMenu.Draw.HudPosX+9 and MouseScreen.x < MenuX+GMenu.Draw.HudPosX+ 110 and MouseScreen.y > MenuY+GMenu.Draw.HudPosY+ 221 and MouseScreen.y < MenuY+GMenu.Draw.HudPosY+231  then
				EnemyTable[2].PeelMe = not EnemyTable[2].PeelMe
			end		
			if MouseScreen.x > MenuX+GMenu.Draw.HudPosX+9 and MouseScreen.x < MenuX+GMenu.Draw.HudPosX+ 110 and MouseScreen.y > MenuY+GMenu.Draw.HudPosY+ 232 and MouseScreen.y < MenuY+GMenu.Draw.HudPosY+242  then
				EnemyTable[3].PeelMe = not EnemyTable[3].PeelMe
			end		
			if MouseScreen.x > MenuX+GMenu.Draw.HudPosX+9 and MouseScreen.x < MenuX+GMenu.Draw.HudPosX+ 110 and MouseScreen.y > MenuY+GMenu.Draw.HudPosY+ 243 and MouseScreen.y < MenuY+GMenu.Draw.HudPosY+253  then
				EnemyTable[4].PeelMe = not EnemyTable[4].PeelMe
			end	
			if MouseScreen.x > MenuX+GMenu.Draw.HudPosX+9 and MouseScreen.x < MenuX+GMenu.Draw.HudPosX+ 110 and MouseScreen.y > MenuY+GMenu.Draw.HudPosY+ 254 and MouseScreen.y < MenuY+GMenu.Draw.HudPosY+264  then
				EnemyTable[5].PeelMe = not EnemyTable[5].PeelMe
			end				
		end
		Pressed = true
	end
	if not IsKeyDown(0x01) and Pressed then Pressed = false end

end

function GetColor(check)

if check == true then return green
else
	return red
end
end


function Calculations()
	
	 
	
	for i=1, EnemysInTable do
		
		local enemy = EnemyTable[i].hero
		if not enemy.dead and enemy.visible then
		cqDmg = getDmg("Q", enemy, myHero)
		ceDmg = getDmg("E", enemy, myHero)
		crDmg = getDmg("R", enemy, myHero)
		ciDmg = getDmg("IGNITE", enemy, myHero)
		csheendamage = (SHEENSlot and getDmg("SHEEN",enemy,myHero) or 0)
		clichdamage = (LICHSlot and getDmg("LICHBANE",enemy,myHero) or 0)
		cDfgDamage = 0
		cExtraDmg = 0
		cTotal = 0
	
	if iReady then
		cExtraDmg = cExtraDmg + iDmg
	end
	
	if sheenReady then
		cExtraDmg = cExtraDmg + csheenDamage
	end
	
	if lichReady then
		cExtraDmg = cExtraDmg + clichDamage
	end
	
		EnemyTable[i].q = cqDmg

	
	
	if rReady and not UltiThrown then
		EnemyTable[i].r = crDmg
	else
		EnemyTable[i].r = 0
	end
	
	
		
		EnemyTable[i].e = ceDmg
	
	
	
	if dfgReady then 
		DfgDamage = (EnemyTable[i].q + EnemyTable[i].e + EnemyTable[i].r) * 1.2
		cExtraDmg = cExtraDmg + DfgDamage
	end	
	
	-- Make combos
	if enemy.health < EnemyTable[i].q then
		EnemyTable[i].IndicatorText = "Q Kill"
		EnemyTable[i].IndicatorPos = 0
		if qMana > MyMana or not qReady then
			EnemyTable[i].NotReady = true
		else
			EnemyTable[i].NotReady = false
		end
	
	elseif enemy.health < EnemyTable[i].r then
		EnemyTable[i].IndicatorText =  "R Kill"
		EnemyTable[i].IndicatorPos = 0
		if rMana > MyMana or not qReady or not rReady then
			EnemyTable[i].NotReady = true
		else
			EnemyTable[i].NotReady = false
		end
		
	elseif enemy.health < EnemyTable[i].r then
		EnemyTable[i].IndicatorText =  "E+Q Kill"
		EnemyTable[i].IndicatorPos = 0
		if eMana+qMana > MyMana or not eReady or not qReady then
			EnemyTable[i].NotReady = true
		else
			EnemyTable[i].NotReady = false
		end	
		
	elseif enemy.health < EnemyTable[i].q + EnemyTable[i].r then
		EnemyTable[i].IndicatorText =  "Q+R Kill"
		EnemyTable[i].IndicatorPos = 0
		if qMana + rMana > MyMana or not qReady or not rReady then
			EnemyTable[i].NotReady = true
		else
			EnemyTable[i].NotReady = false
		end
	
	
	elseif enemy.health < EnemyTable[i].q + EnemyTable[i].e + EnemyTable[i].r + cExtraDmg then
		EnemyTable[i].IndicatorText = "Assasinate!"
		EnemyTable[i].IndicatorPos = 0
		if qMana + eMana + rMana > MyMana  then
			EnemyTable[i].NotReady =  true
		else
			EnemyTable[i].NotReady = false
		end
		if not qReady or not rReady or not eReady then
			EnemyTable[i].NotReady =  true
		else
			EnemyTable[i].NotReady = false
		end
		
	else
		
			cTotal = cTotal + EnemyTable[i].q
		
		
			cTotal = cTotal + EnemyTable[i].e
		
			cTotal = cTotal + EnemyTable[i].r
		
		
		HealthLeft = math.round(enemy.health - cTotal)
		PctLeft = math.round(HealthLeft / enemy.maxHealth * 100)
		BarPct = PctLeft / 103 * 100
		EnemyTable[i].Pct = PctLeft
		EnemyTable[i].IndicatorPos = BarPct
 		EnemyTable[i].IndicatorText = PctLeft .. "% Harass"
		if not qReady or not rReady or not eReady then
			EnemyTable[i].NotReady =  true
		else
			EnemyTable[i].NotReady = false
		end
				if qMana + eMana + rMana > MyMana  then
			EnemyTable[i].NotReady =  true
		else
			EnemyTable[i].NotReady = false
		end
		if not qReady or not rReady or not eReady then
			EnemyTable[i].NotReady =  true
		else
			EnemyTable[i].NotReady = false
		end
	end
	
	end

	end	

	
	
	

end






------------------
-- 	On Load		--
------------------

function Menu()

			GMenu = scriptConfig("Beasty Gragas!", "BeastyGragas")
			GMenu:addTS(ts)
			GMenu:addSubMenu("Beasty Gragas:General/Keys", "General")
			GMenu:addSubMenu("Beasty Gragas:Skills", "Skills")
			GMenu:addSubMenu("Beasty Gragas:Draw", "Draw")
	
			
			GMenu.General:addParam("sep", "----- [ General Settings ] -----", SCRIPT_PARAM_INFO, "")
			GMenu.General:addParam("Combo","Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
			GMenu.General:addParam("OrbWalk","Orbwalk in combo", SCRIPT_PARAM_ONOFF, true)
			GMenu.General:addParam("Harass","Harass", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
			GMenu.General:addParam("ManualPull","Ult Trick/Pull Combo", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("A"))
			GMenu.General:addParam("MoveToMousePull","Move to mouse with pullkey", SCRIPT_PARAM_ONOFF, true)	
			GMenu.General:addParam("JungleSteal","Jungle Stealer", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("X"))

	
	
			GMenu.Skills:addParam("sep", "----- [ Q Settings ] -----", SCRIPT_PARAM_INFO, "")
			GMenu.Skills:addParam("KsQ","Auto KS", SCRIPT_PARAM_ONOFF, true)
	
			GMenu.Skills:addParam("sep", "----- [ W Settings ] -----", SCRIPT_PARAM_INFO, "")
			GMenu.Skills:addParam("AutoW","Auto W", SCRIPT_PARAM_ONOFF, true)
			GMenu.Skills:addParam("ManaPct","Auto W when below(Mana %)", SCRIPT_PARAM_SLICE, 70, 1, 100, 0)		
			GMenu.Skills:addParam("sep", "----- [ E Settings ] -----", SCRIPT_PARAM_INFO, "")
			GMenu.Skills:addParam("UseE","Use in Combo", SCRIPT_PARAM_ONOFF, true)

			GMenu.Skills:addParam("sep", "----- [ R Settings ] -----", SCRIPT_PARAM_INFO, "")
			GMenu.Skills:addParam("PullKillable","Pull Killable", SCRIPT_PARAM_ONOFF, true)
			GMenu.Skills:addParam("KsR","Auto KS", SCRIPT_PARAM_ONOFF, true)
			
			GMenu.Skills:addParam("sep", "---- [ Teamfigt ] ----", SCRIPT_PARAM_INFO, "")
			GMenu.Skills:addParam("DontETeamfight","Dont use E", SCRIPT_PARAM_ONOFF, true)
			GMenu.Skills:addParam("DontUltiTeamfight","Dont use Ulti", SCRIPT_PARAM_ONOFF, true)
			GMenu.Skills:addParam("MecKsR","MEC:KS with ulti", SCRIPT_PARAM_ONOFF, true)
			GMenu.Skills:addParam("MecAmmount","MEC:Killable with ult:", SCRIPT_PARAM_SLICE, 2, 2, 5, 0)
			GMenu.Skills:addParam("AutoPull","Auto Pull", SCRIPT_PARAM_ONOFF, true)
			
			
			
			GMenu.Draw:addParam("sep", "---- [ Draw ] ----", SCRIPT_PARAM_INFO, "")
			GMenu.Draw:addParam("ScriptMenu","Show in-game menu", SCRIPT_PARAM_ONOFF, true)
			GMenu.Draw:addParam("DmgIndic","Show hp-bar indicator", SCRIPT_PARAM_ONOFF, true)
			GMenu.Draw:addParam("ShowQ","Draw Q range", SCRIPT_PARAM_ONOFF, true)
			GMenu.Draw:addParam("ShowE","Draw E range", SCRIPT_PARAM_ONOFF, true)
			GMenu.Draw:addParam("ShowR","Draw R range", SCRIPT_PARAM_ONOFF, true)
			GMenu.Draw:addParam("DisableDraw","Disable all visuals", SCRIPT_PARAM_ONOFF, false)
			GMenu.Draw:addParam("HudPosX","In-Game Hud X", SCRIPT_PARAM_SLICE, 75, 0, 2000, 0)
			GMenu.Draw:addParam("HudPosY","In-Game Hud Y", SCRIPT_PARAM_SLICE, 400, 0, 600, 0)

			GMenu.Skills.KsQ = true
			GMenu.General.HarassQ = true
			GMenu.Skills.AutoW = true
			GMenu.Skills.UseE = true
			GMenu.Skills.PullKillable = true
			GMenu.Skills.KsR = true
			GMenu.Skills.MecKsR = true
			GMenu.Skills.DontETeamfight = true
			GMenu.Skills.DontUltiTeamfight = true
			GMenu.Skills.AutoPull = false
			
end



function Vars()

ts = TargetSelector(TARGET_LOW_HP_PRIORITY, 1300, true)
ts.name = "Gragas"
_G.DrawCircle = DrawCircle2
--Spells
qReady, wReady, eReady, rReady = false, false, false, false, false
qPos, ePos, rPos = nil, nil, nil
eCol =  Collision(750, 1500, 240, 100)
AllReady = false
qText, eText, rText = "","",""
qCurrCd, eCurrCd, rCurrCd = 0,0,0
qDmg, eDmg, rDmg, iDmg, dfgDamage = 0,0,0,0,0
cqDmg, ceDmg, crDmg, ciDmg, cExtraDmg, cTotal, cMana = 0,0,0,0,0,0,0
MyMana = 0
GotMana = false
UltTime = 0
MecPos = nil
Killing = nil
--Helpers
lastAttack, lastWindUpTime, lastAttackCD = 0, 0, 0
BarrelThrown = false
Barrel = nil
UltiThrown = false
Recalling = false
dashx = nil
dashz = nil
dashy = nil
dashstart = nil
GetDash = false
THealth = 0
PeelTargetManual = nil
ChannelingW = false
Reset = false
DashEndTime = nil
EnemyTable = {}
EnemysInTable = 0
HealthLeft = 0
PctLeft = 0
BarPct = 0
EStart = nil
wTime = nil
orange = 0xFFFFE303
green = ARGB(255,0,255,0)
blue = ARGB(255,0,0,255)
red = ARGB(255,255,0,0)
MenuX = 0
MenuY = 0
--MenuX = 800
--MenuY = 200
MouseScreen = WorldToScreen(D3DXVECTOR3(mousePos.x, mousePos.y, mousePos.z))


end

function LoadJungle()

	for i = 1, objManager.maxObjects do
		local obj = objManager:getObject(i)
		if obj ~= nil and obj.type == "obj_AI_Minion" and obj.name ~= nil then
			if obj.name == "TT_Spiderboss7.1.1" then Vilemaw = obj
			elseif obj.name == "Worm12.1.1" then Nashor = obj
			elseif obj.name == "Dragon6.1.1" then Dragon = obj
			elseif obj.name == "AncientGolem1.1.1" then Golem1 = obj
			elseif obj.name == "AncientGolem7.1.1" then Golem2 = obj
			elseif obj.name == "LizardElder4.1.1" then Lizard1 = obj
			elseif obj.name == "LizardElder10.1.1" then Lizard2 = obj end
		end
	end
end

function Spells()

	-- Q
	
	ProQ = ProdictManager.GetInstance():AddProdictionObject(_Q, 950, 1100, 0.250, 200, myHero)
		
	-- E
	ProE = ProdictManager.GetInstance():AddProdictionObject(_E, 650, 1000, 0.250, 100, myHero)
		
	-- R
	ProR = ProdictManager.GetInstance():AddProdictionObject(_R, 800, 1300, 0.250, 100, myHero)

		
	
		
end	


------------------
-- Orbwalkstuff --
------------------
function trueRange()
	return myHero.range + GetDistance(myHero.minBBox)
end

function heroCanMove()
	return (GetTickCount() + GetLatency()/2 > lastAttack + lastWindUpTime + 20)
end

function timeToShoot()
	return (GetTickCount() + GetLatency()/2 > lastAttack + lastAttackCD)
end

function moveToCursor()
	if GetDistance(mousePos) > 1 or lastAnimation == "Idle1" then
		local moveToPos = myHero + (Vector(mousePos) - myHero):normalized()*300
		myHero:MoveTo(moveToPos.x, moveToPos.z)
	end	
end




-- Lag free circles (by barasia, vadash and viseversa)
function DrawCircleNextLvl(x, y, z, radius, width, color, chordlength)
    radius = radius or 300
  quality = math.max(8,round(180/math.deg((math.asin((chordlength/(2*radius)))))))
  quality = 2 * math.pi / quality
  radius = radius*.92
    local points = {}
    for theta = 0, 2 * math.pi + quality, quality do
        local c = WorldToScreen(D3DXVECTOR3(x + radius * math.cos(theta), y, z - radius * math.sin(theta)))
        points[#points + 1] = D3DXVECTOR2(c.x, c.y)
    end
    DrawLines2(points, width or 1, color or 4294967295)
end

function round(num) 
 if num >= 0 then return math.floor(num+.5) else return math.ceil(num-.5) end
end

function DrawCircle2(x, y, z, radius, color)
    local vPos1 = Vector(x, y, z)
    local vPos2 = Vector(cameraPos.x, cameraPos.y, cameraPos.z)
    local tPos = vPos1 - (vPos1 - vPos2):normalized() * radius
    local sPos = WorldToScreen(D3DXVECTOR3(tPos.x, tPos.y, tPos.z))
    if OnScreen({ x = sPos.x, y = sPos.y }, { x = sPos.x, y = sPos.y }) then
        DrawCircleNextLvl(x, y, z, radius, 1, color, 75) 
    end
end



--UPDATEURL=
--HASH=510DDC2028F04D9EEF9B8992E679969B
