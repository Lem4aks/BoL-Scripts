--[[
	AutoCarry Script - Katarina 1.2 by Skeem

	Changelog :
   1.0 - Initial Release
   1.1 - Fixed Damage Calculation
	   - Fixed Auto Ignite
	   - Hopefully Fixed BugSplat
   1.2 - Really fixed BugSplat Now
	   - More Damage Calculation Adjustments
	   - More checks for when to ult
	   - More checks to not use W when enemy not in range
 	]] --		

-- Hero Name Check
if myHero.charName ~= "Katarina" then return end


--[Plugin OnLoad]--
function PluginOnLoad()
	AutoCarry.SkillsCrosshair.range = 675
	--> Main Load
	mainLoad()
	--> Main Menu
	mainMenu()
end
--[/Plugin OnLoad]--

--[Plugin OnTick]--
function PluginOnTick()
	if isChanneling() then
		AutoCarry.CanAttack = false
		AutoCarry.CanMove = false
	else
		AutoCarry.CanAttack = true
		AutoCarry.CanMove = true
	end
	Checks()
	smartKS()
	if Menu.hHK then Harrass() end
	if Menu.bCombo and Carry.AutoCarry then bCombo() end
	if not Menu.mFarm and not Carry.AutoCarry then Farm() end
	if Menu.wHarrass and Target and GetDistance(Target) <= wRange then
		CastSpell(_W)
	end
end
--[/Plugin OnTick]--

--[Farm Function]--
function Farm()
	for _, minion in pairs(AutoCarry.EnemyMinions().objects) do
		if ValidTarget(minion) then
			if Menu.qFarm and QREADY and GetDistance(minion) <= qRange then
				if minion.health <= getDmg("Q", minion, myHero) then CastSpell(_Q, minion) end
			end
			if Menu.wFarm and WREADY and GetDistance(minion) <= wRange then
				if minion.health < getDmg("W", minion, myHero) then CastSpell(_W, minion) end
			end
			if Menu.eFarm and EREADY and GetDistance(minion) <= eRange then
				if minion.health <= getDmg("E", minion, myHero) then CastSpell(_E, minion) end
			end
		end
	end
end
--[/Farm Function]--

--[Harrass Function]--
function Harrass()
	if Target and Menu.hHK then
		if Menu.hMode == 1 then
			if GetDistance(Target) <= qRange then CastSpell(_Q, Target) end
			if GetDistance(Target) <= eRange then CastSpell(_E, Target) end
			if GetDistance(Target) <= wRange then CastSpell(_W, Target) end
		end
		if Menu.hMode == 2 then
			if GetDistance(Target) <= qRange then CastSpell(_Q, Target) end
			if GetDistance(Target) <= wRange then CastSpell(_W, Target) end
		end
	end
end
--[/Harrass Function]--

--[Burst Combo Function]--
function bCombo()
	if Target then
		if DFGREADY then CastSpell(dfgSlot, Target) end
		if HXGREADY then CastSpell(hxgSlot, Target) end
		if BWCREADY then CastSpell(bwcSlot, Target) end
		if BRKREADY then CastSpell(brkSlot, Target) end
		if GetDistance(Target) <= qRange then CastSpell(_Q, Target) end
		if GetDistance(Target) <= eRange then CastSpell(_E, Target) end
		if GetDistance(Target) <= wRange then CastSpell(_W) end
		if not QREADY and not EREADY and GetDistance(Target) <= rRange then CastSpell(_R) end
	end
end
--[/Burst Combo Function]--

--[Smart KS Function]--
function smartKS()
	 for i=1, heroManager.iCount do
	 local enemy = heroManager:GetHero(i)
		if ValidTarget(enemy) then
			dfgDmg, hxgDmg, bwcDmg, iDmg  = 0, 0, 0, 0
			qDmg = getDmg("Q",enemy,myHero)
            wDmg = getDmg("W",enemy,myHero)
			eDmg = getDmg("E",enemy,myHero)
            rDmg = getDmg("R",enemy,myHero)*10
			if DFGREADY then dfgDmg = (dfgSlot and getDmg("DFG",enemy,myHero) or 0)	end
            if HXGREADY then hxgDmg = (hxgSlot and getDmg("HXG",enemy,myHero) or 0) end
            if BWCREADY then bwcDmg = (bwcSlot and getDmg("BWC",enemy,myHero) or 0) end
            if IREADY then iDmg = (ignite and getDmg("IGNITE",enemy,myHero) or 0) end
            onspellDmg = (liandrysSlot and getDmg("LIANDRYS",enemy,myHero) or 0)+(blackfireSlot and getDmg("BLACKFIRE",enemy,myHero) or 0)
            itemsDmg = dfgDmg + hxgDmg + bwcDmg + iDmg + onspellDmg
			------- DEBUG --------
			--if Menu.debug then PrintChat("Total Items Dmg: "..itemsDmg.." Target: "..enemy.name) end
			--if Menu.debug then PrintChat("rDmg"..rDmg) end	
			------- DEBUG --------
			if Menu.sKS then
				if enemy.health <= (qDmg + itemsDmg) and GetDistance(enemy) <= qRange and QREADY then
					if DFGREADY then CastSpell(dfgSlot, enemy) end
					if HXGREADY then CastSpell(hxgSlot, enemy) end
					if BWCREADY then CastSpell(bwcSlot, enemy) end
					if BRKREADY then CastSpell(brkSlot, enemy) end
					if QREADY then CastSpell(_Q, enemy) end
				end
				if enemy.health <= (wDmg + itemsDmg) and GetDistance(enemy) <= wRange and WREADY then
					if DFGREADY then CastSpell(dfgSlot, enemy) end
					if HXGREADY then CastSpell(hxgSlot, enemy) end
					if BWCREADY then CastSpell(bwcSlot, enemy) end
					if BRKREADY then CastSpell(brkSlot, enemy) end
					if WREADY then CastSpell(_W, enemy) end
				end
				if enemy.health <= (eDmg + itemsDmg) and GetDistance(enemy) <= eRange and EREADY then
					if DFGREADY then CastSpell(dfgSlot, enemy) end
					if HXGREADY then CastSpell(hxgSlot, enemy) end
					if BWCREADY then CastSpell(bwcSlot, enemy) end
					if BRKREADY then CastSpell(brkSlot, enemy) end
					if EREADY then CastSpell(_E, enemy) end
				end
				if enemy.health <= (qDmg + wDmg + itemsDmg) and GetDistance(enemy) <= wRange
					and WREADY and QREADY then
						if DFGREADY then CastSpell(dfgSlot, enemy) end
						if HXGREADY then CastSpell(hxgSlot, enemy) end
						if BWCREADY then CastSpell(bwcSlot, enemy) end
						if BRKREADY then CastSpell(brkSlot, enemy) end
						if WREADY and GetDistance(enemy) <= wRange then CastSpell(_W, enemy) end
						if QREADY then CastSpell(_Q, enemy) end
				end
				if enemy.health <= (qDmg + eDmg + itemsDmg) and GetDistance(enemy) <= qRange
					and EREADY and QREADY then
						if DFGREADY then CastSpell(dfgSlot, enemy) end
						if HXGREADY then CastSpell(hxgSlot, enemy) end
						if BWCREADY then CastSpell(bwcSlot, enemy) end
						if BRKREADY then CastSpell(brkSlot, enemy) end
						if QREADY then CastSpell(_Q, enemy) end
						if EREADY then CastSpell(_E, enemy) end
				end
				if enemy.health <= (wDmg + eDmg + itemsDmg) and GetDistance(enemy) <= eRange
					and EREADY and WREADY then
						if DFGREADY then CastSpell(dfgSlot, enemy) end
						if HXGREADY then CastSpell(hxgSlot, enemy) end
						if BWCREADY then CastSpell(bwcSlot, enemy) end
						if BRKREADY then CastSpell(brkSlot, enemy) end
						if ROREADY and GetDistance(enemy) <= 500 then CastSpell(roSlot) end
						if WREADY and GetDistance(enemy) <= wRange then CastSpell(_W, enemy) end
						if EREADY then CastSpell(_E, enemy) end
				end
				if enemy.health <= (qDmg + eDmg + wDmg + itemsDmg) and GetDistance(enemy) <= eRange
					and QREADY and EREADY and WREADY then
						if DFGREADY then CastSpell(dfgSlot, enemy) end
						if HXGREADY then CastSpell(hxgSlot, enemy) end
						if BWCREADY then CastSpell(bwcSlot, enemy) end
						if BRKREADY then CastSpell(brkSlot, enemy) end
						if QREADY then CastSpell(_Q, enemy) end
						if EREADY then CastSpell(_E, enemy) end
						if WREADY and GetDistance(enemy) <= wRange then CastSpell(_W, enemy) end
				end
				if enemy.health <= (qDmg + eDmg + wDmg + rDmg + itemsDmg) and GetDistance(enemy) <= qRange
					and QREADY and EREADY and WREADY and RREADY and enemy.health > (qDmg + eDmg + wDmg) then
						if DFGREADY then CastSpell(dfgSlot, enemy) end
						if HXGREADY then CastSpell(hxgSlot, enemy) end
						if BWCREADY then CastSpell(bwcSlot, enemy) end
						if BRKREADY then CastSpell(brkSlot, enemy) end
						if QREADY then CastSpell(_Q, enemy) end
						if EREADY then CastSpell(_E, enemy) end
						if WREADY and GetDistance(enemy) <= wRange then CastSpell(_W, enemy) end
						if RREADY and not QREADY and not EREADY then CastSpell(_R) end
				end
				if enemy.health <= (rDmg + itemsDmg) and GetDistance(enemy) <= rRange
					and not QREADY and not EREADY and RREADY then
						if DFGREADY then CastSpell(dfgSlot, enemy) end
						if HXGREADY then CastSpell(hxgSlot, enemy) end
						if BWCREADY then CastSpell(bwcSlot, enemy) end
						if BRKREADY then CastSpell(brkSlot, enemy) end
						if RREADY then CastSpell(_R) end
				end
				if enemy.health <= iDmg and GetDistance(enemy) <= 600 then
					if IREADY then CastSpell(ignite, enemy) end
				end
			end
		end
	end
end
--[/Smart KS Function]--

--[Plugin OnAnimation - Credits: ??nonymous]--
function PluginOnAnimation(unit, animationName)
	if unit.isMe and lastAnimation ~= animationName then lastAnimation = animationName end
end
--[/Plugin OnAnimation - Credits: ??nonymous]--

--[Channeling Function - Credits: ??nonymous]--
function isChanneling()
	if lastAnimation == "Spell4" then
		return true
	else
		return false
	end
end
--[/Channeling Function]--

--[Plugin OnDraw]--
function PluginOnDraw()
	--> Ranges
	if not Menu.mDraw and not myHero.dead then
		if QREADY and Menu.qDraw then 
			DrawCircle(myHero.x, myHero.y, myHero.z, qRange, 0x191970)
		end
		if WREADY and Menu.wDraw then
			DrawCircle(myHero.x, myHero.y, myHero.z, wRange, 0x20B2AA)
		end
		if EREADY and Menu.eDraw then
			DrawCircle(myHero.x, myHero.y, myHero.z, eRange, 0x800080)
		end
	end
end
--[/Plugin OnDraw]--

--[Function mainLoad]--
function mainLoad()
	qRange, wRange, eRange, rRange = 675, 375, 700, 550
	QREADY, WREADY, EREADY, RREADY = false, false, false, false
	lastAnimation = "Run"
	Menu = AutoCarry.PluginMenu
	Carry = AutoCarry.MainMenu
end
--[/Function mainLoad]--

--[Main Menu Function]--
function mainMenu()
	Menu:addParam("sep", "-- Combo Options --", SCRIPT_PARAM_INFO, "")
	Menu:addParam("bCombo", "Burst With AutoCarry", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("sKS", "Use Smart KS Combos", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("sep1", "-- Harrass Options --", SCRIPT_PARAM_INFO, "")
	Menu:addParam("hMode", "Harrass Mode",SCRIPT_PARAM_SLICE, 1, 1, 2, 0)
	Menu:addParam("hHK", "Harrass Hotkey", SCRIPT_PARAM_ONKEYDOWN, false, 84)
	Menu:addParam("wHarrass", "Always Sinister Steel (W)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("sep2", "-- Farm Options --", SCRIPT_PARAM_INFO, "")
	Menu:addParam("mFarm", "Disable Farming", SCRIPT_PARAM_ONKEYTOGGLE, false, 67)
	Menu:addParam("qFarm", "Farm with Bouncing Blades (Q)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("wFarm", "Sinister Steel (W)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("eFarm", "Farm with Shunpo (E)", SCRIPT_PARAM_ONOFF, false)
	Menu:addParam("sep3", "-- Draw Options --", SCRIPT_PARAM_INFO, "")
	Menu:addParam("mDraw", "Disable All Ranges Drawing", SCRIPT_PARAM_ONOFF, false)
	Menu:addParam("qDraw", "Draw Bouncing Blades (Q) Range", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("wDraw", "Draw Sinister Steel (W) Range", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("eDraw", "Draw Shunpo (E) Range", SCRIPT_PARAM_ONOFF, true)
	----------- DEBUG ----------
	--Menu:addParam("debug", "Debugging Prints", SCRIPT_PARAM_ONKEYDOWN, false, 88)
end
--[/Main Menu Function]--

--[Cooldown Checks]--
function Checks()
	if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then ignite = SUMMONER_1
	elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then ignite = SUMMONER_2 end
	Target = AutoCarry.GetAttackTarget(true)
	dfgSlot, hxgSlot, bwcSlot = GetInventorySlotItem(3128), GetInventorySlotItem(3146), GetInventorySlotItem(3144)
	brkSlot = GetInventorySlotItem(3092),GetInventorySlotItem(3143),GetInventorySlotItem(3153)
	QREADY = (myHero:CanUseSpell(_Q) == READY)
	WREADY = (myHero:CanUseSpell(_W) == READY)
	EREADY = (myHero:CanUseSpell(_E) == READY)
	RREADY = (myHero:CanUseSpell(_R) == READY)
	DFGREADY = (dfgSlot ~= nil and myHero:CanUseSpell(dfgSlot) == READY)
	HXGREADY = (hxgSlot ~= nil and myHero:CanUseSpell(hxgSlot) == READY)
	BWCREADY = (bwcSlot ~= nil and myHero:CanUseSpell(bwcSlot) == READY)
	BRKREADY = (brkSlot ~= nil and myHero:CanUseSpell(brkSlot) == READY)
	IREADY = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY)
end
--[/Cooldown Checks]--

--UPDATEURL=
--HASH=06AA4AC9DA4F903DA746C431D459EB20
