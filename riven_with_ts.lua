-- Script Name: Just Riven
-- Script Ver: 1.2
-- Author     : Skeem

--[[ Changelog:
	1.0 -Initial Release
	1.1 - Smoothen up combo
	    - Fixed Error Spamming
	1.2 - Smoothen up Orbwalking
	    - Added some packet checks
]]--

if myHero.charName ~= 'Riven' then return end

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local SOURCELIB_URL = "https://raw.github.com/TheRealSource/public/master/common/SourceLib.lua"
local SOURCELIB_PATH = LIB_PATH.."SourceLib.lua"

if FileExist(SOURCELIB_PATH) then
	require("SourceLib")
else
	DOWNLOADING_SOURCELIB = true
	DownloadFile(SOURCELIB_URL, SOURCELIB_PATH, function() PrintChat("Required libraries downloaded successfully, please reload") end)
end

if DOWNLOADING_SOURCELIB then PrintChat("Downloading required libraries, please wait...") return end

local RequireI = Require("SourceLib")
RequireI:Add("vPrediction", "https://raw.github.com/Hellsing/BoL/master/common/VPrediction.lua")
RequireI:Add("SOW", "https://raw.github.com/Hellsing/BoL/master/common/SOW.lua")
if VIP_USER and FileExist(LIB_PATH.."Prodiction.lua") then
	require("Prodiction")
end
RequireI:Check()

if RequireI.downloadNeeded == true then return end

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--require 'VPrediction'

	Spells = {
		Q = {key = _Q, string = 'Q', name = 'Broken Wings',   range = 300, ready = false, data = nil, color = 0x663300},
		W = {key = _W, string = 'W', name = 'Ki Burst',       range = 260, ready = false, data = nil, color = 0x333300},
		E = {key = _E, string = 'E', name = 'Valor',          range = 390, ready = false, data = nil, color = 0x666600},
		R = {key = _R, string = 'R', name = 'Blade of Exile', range = 900, ready = false, data = nil, color = 0x993300}
	}

	Ignite = (myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") and SUMMONER_1) or (myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") and SUMMONER_2) or nil

	Items = {
		YGB	   = {id = 3142, range = 350, ready = false},
		BRK    = {id = 3153, range = 500, ready = false},
		HYDRA  = {id = 3074, range = 350, ready = false},
		TIAMAT = {id = 3077, range = 350, ready = false}
	}

	SpellNames = {'RivenTriCleave', 'RivenMartyr', 'RivenFeint', 'RivenFengShuiEngine', 'rivenizunablade'}

	BuffInfo = {
		P = false,
		Q = {stage  = 0}
	}

	vPred = VPrediction()

	Orbwalking = {
		lastAA     = 0,
		windUp     = 3,
		animation  = 0.6,
		updated    = false,
		range      = 0
	}

function OnLoad()
	STS = SimpleTS(STS_PRIORITY_LESS_CAST_PHYSICAL)
	TS = TargetSelector(TARGET_LESS_CAST_PRIORITY, 500, DAMAGE_PHYSICAL)
	TS.name = 'Riven'
	
	RivenMenu = scriptConfig('~[Just Riven]~', 'Riven')
		RivenMenu:addSubMenu("Target selector", "STS")
			STS:AddToMenu(RivenMenu.STS)
		RivenMenu:addSubMenu('~[Skill Settings]~', 'skills')
			RivenMenu.skills:addParam('', '--[ W Options ]--', SCRIPT_PARAM_INFO, '')
			RivenMenu.skills:addParam('autoW', 'Auto W Close Enemies', SCRIPT_PARAM_ONOFF, true)
			RivenMenu.skills:addParam('', '--[ R Options ]--',    SCRIPT_PARAM_INFO, '')
			RivenMenu.skills:addParam('comboR', 'Use in Combo',   SCRIPT_PARAM_LIST, 1, {"When other skills are not on CD", "Always", "Never"})	
			RivenMenu.skills:addParam('healthR', 'Min Health %',  SCRIPT_PARAM_SLICE, 50, 0, 100, -1)
		RivenMenu:addSubMenu('~[Kill Settings]~', 'kill')
			RivenMenu.kill:addParam('enabled', 'Enable KillSteal',    SCRIPT_PARAM_ONOFF, true)
			RivenMenu.kill:addParam('killQ',   'GapClose Q to KS',    SCRIPT_PARAM_ONOFF, true)
			RivenMenu.kill:addParam('killR',   'KillSteal with R',    SCRIPT_PARAM_LIST, 1, {"When other skills are not on CD", "Always", "Never"})
			RivenMenu.kill:addParam('killW',   'KillSteal with W',    SCRIPT_PARAM_ONOFF, true)
			RivenMenu.kill:addParam('Ignite',  'Auto Ignite Enemies', SCRIPT_PARAM_ONOFF, true)

		RivenMenu:addSubMenu('~[Draw Ranges]~', 'draw')
			for _, spell in pairs(Spells) do
				RivenMenu.draw:addParam(spell.string, 'Draw '..spell.name..' ('..spell.string..')', SCRIPT_PARAM_ONOFF, true)
			end
		RivenMenu:addParam('forceAAs', 'Force AAs with Passive', SCRIPT_PARAM_ONOFF,         true)
		RivenMenu:addParam('comboKey', 'Combo Key X'           , SCRIPT_PARAM_ONKEYDOWN, false, 88)

PrintChat("<font color='#663300'>Just Riven 1.2 Loaded</font>")
end
function OnTick()
	Target = STS:GetTarget(500)

	Orbwalking.range = myHero.range + vPred:GetHitBox(myHero)

	for _, spell in pairs(Spells) do
		spell.ready = myHero:CanUseSpell(spell.key) == READY
		spell.data  = myHero:GetSpellData(spell.key)
	end

	for _, item in pairs(Items) do
		item.ready = GetInventoryItemIsCastable(item.id)
	end

	if RivenMenu.comboKey then
		Orb(Target)
		CastCombo(Target)
	end
	if RivenMenu.skills.autoW and Spells.W.ready and Target then
		Cast(_W, Target, Spells.W.range)
	end
	if RivenMenu.kill.enabled then
		KillSteal()
	end
end 

function OnDraw()
	for _, spell in pairs(Spells) do
		if spell.ready and RivenMenu.draw[spell.string] then
			DrawCircle(myHero.x, myHero.y, myHero.z, spell.range, spell.color)
		end
	end
end

function OnGainBuff(unit, buff)
	if unit.isMe then
		if buff.name == 'rivenpassiveaaboost' then
			BuffInfo.P = true
		end
		if buff.name == 'riventricleavesoundone' then
			BuffInfo.Q.stage = 1
		end
		if buff.name == 'riventricleavesoundtwo' then
			BuffInfo.Q.stage = 2
		end
	end
end

function OnLoseBuff(unit, buff)
	if unit.isMe then
		if buff.name == 'rivenpassiveaaboost' then
			BuffInfo.P = false
		end
		if buff.name == 'RivenTriCleave' then
			BuffInfo.Q.stage = 0
		end
	end
end

function OnProcessSpell(unit, spell)
	if unit.isMe then
		if spell.name:lower():find("attack") then
			print('Attack Started')
			if Orbwalking.updated then
				Orbwalking.animation = 1 / (spell.animationTime * myHero.attackSpeed)
				Orbwalking.windUp    = 1 / (spell.windUpTime    * myHero.attackSpeed)
				Orbwalking.updated   = true
			end
			Orbwalking.lastAA  = (os.clock() - (GetLatency() / 2000))
		else
			Packet('S_MOVE', { x = mousePos.x, y = mousePos.z }):send()
			print('Anim Cancel: OnSpell - '..os.clock())
		end
	end
end

function OnSendPacket(packet)
	local p = Packet(packet)
	if p:get('name') == 'S_CAST' and p:get('sourceNetworkId') == myHero.networkID then
		Packet('S_MOVE', { x = mousePos.x, y = mousePos.z }):send()
		print('Anim Cancel: SendPacket - '..os.clock())
		if p:get('spellId') == 0 then
			Orbwalking.lastAA = 0
			print('AA Reset: Q Spell')
		end
	end
end

function OnRecvPacket(packet)
	if packet.header == 0x34 then
		packet.pos = 1
		if packet:DecodeF() == myHero.networkID then
			packet.pos = 9
			if packet:Decode1() == 0x11 then
				Orbwalking.lastAA = 0
				print('AA Reset: Canceled AA')
			end
		end
	end
	-- Thanks to Bilbao :3 --
	if packet.header == 0x65 then
  		packet.pos = 5
  		local dmgType  = packet:Decode1()
  		local targetId = packet:DecodeF()
  		local souceId  = packet:DecodeF()
  		if souceId == myHero.networkID and dmgType == (12 or 3) then
  			if RivenMenu.comboKey and Target then
  				if Spells.Q.ready then
  					Cast(_Q, Target, Spells.Q.range)
  				end
				if Items.HYDRA.ready or Items.TIAMAT.ready then
					UseItems(Target)
					Orbwalking.lastAA = 0
					print('AA Reset: Item')
				end
			end
  			print('AA info: Finished AA')
  		end
 	end
end

function GetTarget()
	STS:update()
	if STS.target ~= nil and not STS.target.dead and STS.target.type  == myHero.type and STS.target.visible then
		return STS.target
	end
end


function CastCombo(target)
	if target then
		local truerange = Orbwalking.range + vPred:GetHitBox(target) + 50
		local distance  = GetDistanceSqr(target)
		local EQRange   = Spells.E.ready and Spells.Q.ready and Spells.E.range + Spells.Q.range
		local EWRange   = Spells.E.ready and Spells.Q.ready and Spells.E.range + Spells.W.range
		if RivenMenu.skills.comboR ~= 3 and Spells.R.ready and Spells.R.data.name == 'RivenFengShuiEngine' then
			if RivenMenu.skills.comboR == 1 then
				if target.health < (target.maxHealth * (RivenMenu.skills.healthR / 100)) and ((Spells.E.ready and Spells.Q.ready) or (Spells.W.ready and Spells.Q.ready)) then
					CastSpell(_R)
				end
			elseif RivenMenu.skills.comboR == 2 then
				if target.health < (target.maxHealth * (RivenMenu.skills.healthR / 100)) then
					CastSpell(_R)
				end
			end
		end
		if Spells.E.ready and not InRange(target) then
			Cast(_E, target, Spells.E.range)
		end
		if Spells.W.ready then
			Cast(_W, target, Spells.W.range)
		end
		if not InRange(target) and Spells.Q.ready then
			Cast(_Q, target, Spells.Q.range)
		end
	end
end

function KillSteal()
	for _, enemy in pairs(GetEnemyHeroes()) do
		if ValidTarget(enemy) then
			if Spells.R.ready then
				if RivenMenu.kill.killR == 1 then
					if enemy.health < getDmg("R", enemy, myHero) and Spells.R.data.name ~= 'RivenFengShuiEngine' then
						Cast(_R, enemy, Spells.R.range)
					end
				elseif RivenMenu.kill.killR == 2 then
					if ValidTarget(enemy, Spells.R.range) and enemy.health < getDmg("R", enemy, myHero) then
						Cast(_R, enemy, Spells.R.range)
					end	
				end
			end
			if RivenMenu.kill.Ignite and GetDistanceSqr(enemy) < 600 * 600 then
				IgniteCheck(enemy)
			end
			if RivenMenu.kill.killW and enemy.health < getDmg("W", enemy, myHero) then
				Cast(_W, enemy, Spells.W.range)
			end
		end
	end
end

function IgniteCheck(target)
	return  target.health < getDmg("IGNITE", target, myHero) and CastSpell(Ignite, target)
end

function Cast(spell, target, range)
	return GetDistanceSqr(target) < range * range and CastSpell(spell, target.x, target.z)
end

function UseItems(enemy)
	if enemy and enemy.type == myHero.type then
		for _, item in pairs(Items) do
			if item.ready and GetDistanceSqr(enemy) <= item.range*item.range then
      			CastItem(item.id, enemy)
    		end
		end
	end
end

function Orb(target)
	if target and CanAttack() and InRange(target) then
		Attack(target)
	elseif CanMove() then
		if not target then
			local MovePos = Vector(myHero) + 400 * (Vector(mousePos) - Vector(myHero)):normalized()
			Packet('S_MOVE', { x = MovePos.x, y = MovePos.z }):send()
		elseif GetDistanceSqr(target) > 150*150 + math.pow(vPred:GetHitBox(target), 2) then
			local point = vPred:GetPredictedPos(target, 0, 2*myHero.ms, myHero, false)
			if GetDistanceSqr(point) < 150*150 + math.pow(vPred:GetHitBox(target), 2) then
				point = Vector(Vector(myHero) - point):normalized() * 50
			end
			Packet('S_MOVE', { x = point.x, y = point.z }):send()
		end
	end
end

function CanAttack()
	return Orbwalking.lastAA <= os.clock() and (os.clock() + (GetLatency() / 2000)  > Orbwalking.lastAA + AnimationTime()) or false
end

function AARange(target)
	return myHero.range + vPred:GetHitBox(myHero) + vPred:GetHitBox(target)
end

function InRange(target)
	return GetDistanceSqr(target.visionPos, myHero.visionPos) < AARange(target) * AARange(target)
end

function Attack(target)
	Orbwalking.lastAA = (os.clock() + (GetLatency() / 2000))
	myHero:Attack(target)
	print('Attack Function Called')
end

function CanMove()
	return Orbwalking.lastAA <= os.clock() and (os.clock() + (GetLatency() / 2000) > Orbwalking.lastAA + WindUpTime()) or false
end

function AnimationTime()
	return (1 / (myHero.attackSpeed * Orbwalking.animation))
end

function WindUpTime()
	return (1 / (myHero.attackSpeed * Orbwalking.windUp))
end