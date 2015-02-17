if myHero.charName ~= "Ahri" then return end

local curVersion = 1.42
local GetVersionURL, hasUpdated, newVersion, newMessage, newDownloadURL = "http://bit.ly/1fxudeA", true, nil, nil, nil

local SCRIPT_PATH = BOL_PATH.."Scripts\\Common\\SidasAutoCarryPlugin - "..myHero.charName..".lua"
local VER_PATH = os.getenv("APPDATA").."\\"..myHero.charName.."Version.ini"
DownloadFile(GetVersionURL, VER_PATH, function() end)
local UpdateChat = {}

local QRange, QSpeed, QDelay, QWidth = 915, 1.67, 240, 50
local WRange, WSpeed, WDelay, WWidth = 605, nil, nil, 225
local ERange, ESpeed, EDelay, EWidth = 940, 1.55, 240, 50
local RRange, RSpeed, RDelay, RWidth = 500, math.huge, 100, 100
local QReady, WReady, EReady, RReady = false, false, false, false

local DFGSlot, HXGSlot, BWCSlot, STDSlot, SheenSlot, TrinitySlot, LichBaneSlot = nil, nil, nil, nil, nil, nil, nil
local DFGReady, HXGReady, BWCReady, STDReady, IReady = false, false, false, false, false


function PluginOnLoad()
	AhriMenu()
	AutoCarry.SkillsCrosshair.range = ERange
	
	if AutoCarry.Skills then IsSACReborn = true else IsSACReborn = false end
	
	if IsSACReborn then
		SkillQ = AutoCarry.Skills:NewSkill(true, _Q, QRange, "Orb Of Deception", AutoCarry.SPELL_LINEAR, 0, false, false, QSpeed, QDelay, QWidth, false)
		SkillW = AutoCarry.Skills:NewSkill(true, _W, WRange, "Fox Fire", AutoCarry.SPELL_TARGETED, 0, false, false, WSpeed, WDelay, WWidth, false)
		SkillE = AutoCarry.Skills:NewSkill(true, _E, ERange, "Charm", AutoCarry.SPELL_LINEAR_COL, 0, false, false, ESpeed, EDelay, EWidth, true)
		SkillR = AutoCarry.Skills:NewSkill(true, _R, RRange, "Spirit Rush", AutoCarry.SPELL_SELF_AT_MOUSE, 0, false, false, RSpeed, RDelay, RWidth, false)
	else
		SkillQ = {spellKey = _Q, range = QRange, speed = QSpeed, delay = QDelay, width = QWidth, configName = "orbofdeception", displayName = "Q (Orb of Deception)", enabled = true, skillShot = true, minions = false, reset = false, reqTarget = false }
		SkillW = {spellKey = _W, range = WRange, speed = WSpeed, delay = WDelay, width = WWidth, configName = "foxfire", displayName = "W (Fox-Fire)", enabled = true, skillShot = false, minions = false, reset = false, reqTarget = false }
		SkillE = {spellKey = _E, range = ERange, speed = ESpeed, delay = EDelay, width = EWidth, configName = "charm", displayName = "E (Charm)", enabled = true, skillShot = true, minions = true, reset = false, reqTarget = false }
		SkillR = {spellKey = _R, range = RRange, speed = RSpeed, delay = RDelay, width = RWidth, configName = "spiritrush", displayName = "R (Spirit Rush)", enabled = true, skillShot = false, minions = false, reset = false, reqTarget = false }
	end
		
	if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then
		ignite = SUMMONER_1
    elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then
		ignite = SUMMONER_2
	else
		ignite = nil
	end
end

function PluginOnTick()
	if hasUpdated then 
		if FileExist(VER_PATH) then
			AutoUpdate() 
		end 
	end
	
	
	SpellCheck()
	if Menu.other.DrawKillable then DamageCalc() end
	
	if Target ~= nil and  AutoCarry.MainMenu.AutoCarry then
		FullCombo()
	end
	
	if Target ~= nil and AutoCarry.MainMenu.MixedMode and CheckMana() then
		HarassCombo()
	end
	
	if Menu.other.OtherIgnite and ignite and IReady then doIgnite() end
end

function PluginOnDraw()
	if Menu.other.DrawRange and EReady then
		DrawCircle(myHero.x, myHero.y, myHero.z, SkillE.Range, 0xe066a3)
	elseif Menu.other.DrawRange and QReady then
		DrawCircle(myHero.x, myHero.y, myHero.z, SkillQ.Range, 0xe066a3)
	elseif Menu.other.DrawRange and WReady then
		DrawCircle(myHero.x, myHero.y, myHero.z, SkillW.Range, 0xe066a3)
	end
end

function FullCombo()
		if EReady and not Target.dead and GetDistance(Target) <= ERange then 
			if EReady and IsValid(Target, SkillE.Range) then
				if IsSACReborn then
					SkillE:ForceCast(Target)
				else
					AutoCarry.CastSkillshot(SkillE, Target)
				end
			end
		end
		
		if QReady and not Target.dead and GetDistance(Target) <= QRange then 
			if QReady and IsValid(Target, SkillQ.Range) then
				if IsSACReborn then
					SkillQ:ForceCast(Target)
				else
					AutoCarry.CastSkillshot(SkillQ, Target)
				end
			end
		end
		
		if WReady and not Target.dead and ValidTarget(Target, WRange) then CastSpell(_W) end 
end

function HarassCombo()
	if EReady and Menu.mixedmode.MixedUseE and not Target.dead and CheckMana() and GetDistance(Target) <= ERange then 
		if EReady and IsValid(Target, SkillE.Range) then
			if IsSACReborn then
				SkillE:ForceCast(Target)
			else
				AutoCarry.CastSkillshot(SkillE, Target)
			end
		end
	end
		
	if QReady and Menu.mixedmode.MixedUseQ and not Target.dead and CheckMana() and GetDistance(Target) <= QRange then 
		if QReady and IsValid(Target, SkillQ.Range) then
			if IsSACReborn then
				SkillQ:ForceCast(Target)
			else
				AutoCarry.CastSkillshot(SkillQ, Target)
			end
		end
	end
		
	if WReady and Menu.mixedmode.MixedUseW and not Target.dead and CheckMana() and ValidTarget(Target, WRange) then CastSpell(_W) end 
end

function CheckMana()
	if myHero.mana >= myHero.maxMana*(Menu.mixedmode.MixedMinMana/100) then
		return true
	else
		return false
	end	
end

function doIgnite()
    for _, enemy in pairs(GetEnemyHeroes()) do
	if ValidTarget(enemy, 600) and enemy.health <= 50 + (20 * player.level) then
        	CastSpell(ignite, enemy)
        end
    end
end

function IsValid(enemy, dist)
	if enemy and enemy.valid and not enemy.dead and enemy.bTargetable and ValidTarget(enemy, dist) then
		return true
	else
		return false
	end
end

function SpellCheck()
	Target = AutoCarry.GetAttackTarget()
	DFGSlot = GetInventorySlotItem(3128)

	QReady = (myHero:CanUseSpell(_Q) == READY)
	WReady = (myHero:CanUseSpell(_W) == READY)
	EReady = (myHero:CanUseSpell(_E) == READY)
	RReady = (myHero:CanUseSpell(_R) == READY)

	DFGReady = (DFGSlot ~= nil and myHero:CanUseSpell(DFGSlot) == READY)
	IReady = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY)
end

function DamageCalc()
	for i=1, heroManager.iCount do
        local Unit = heroManager:GetHero(i)
		if ValidTarget(Unit) then
			dfgdamage, ignitedamage = 0, 0
			myDamage, QDamage, WDamage, EDamage, RDamage = getDmg("AD", Unit, myHero), getDmg("Q", Unit, myHero), getDmg("E", Unit, myHero), getDmg("W", Unit, myHero), getDmg("R", Unit, myHero)
			
			dfgdamage = (DFGSlot and getDmg("DFG",Unit,myHero) or 0)
			ignitedamage = (ignite and getDmg("IGNITE",Unit,myHero) or 0)
			
			if QReady then
				myDamage = myDamage + QDamage
			end
			if WReady then
				myDamage = myDamage + WDamage
			end
			if EReady then
				myDamage = myDamage + EDamage
			end
			if RReady then
				myDamage = myDamage + RDamage
			end
			if DFGReady then
				myDamage = myDamage + dfgdamage
			end
			if IReady then
				myDamage = myDamage + ignitedamage
			end
			
			if myDamage >= Unit.health then PrintFloatText(Unit,10,"Killable") end
		end
	end
end

function AhriMenu()
	Menu = AutoCarry.PluginMenu
		Menu:addSubMenu("["..myHero.charName.." Auto Carry: Mixed Mode]", "mixedmode")
			Menu.mixedmode:addParam("MixedUseQ", "Use Orb Of Deception", SCRIPT_PARAM_ONOFF, true)
			Menu.mixedmode:addParam("MixedUseW", "Use Fox Fire", SCRIPT_PARAM_ONOFF, false)
			Menu.mixedmode:addParam("MixedUseE", "Use Charm", SCRIPT_PARAM_ONOFF, false)
			Menu.mixedmode:addParam("MixedMinMana", "Harass if my mana > %", SCRIPT_PARAM_SLICE, 40, 0, 100, 0)
	
		Menu:addSubMenu("["..myHero.charName.." Auto Carry: Other]", "other")
			Menu.other:addParam("OtherIgnite", "Use Ignite", SCRIPT_PARAM_ONOFF, true)
			Menu.other:addParam("DrawKillable", "Draw Killable", SCRIPT_PARAM_ONOFF, true)
			Menu.other:addParam("DrawRange","Draw Skill Range", SCRIPT_PARAM_ONOFF, true)
		
		Menu:addSubMenu("["..myHero.charName.." Auto Carry: Info]", "scriptinfo")
			Menu.scriptinfo:addParam("sep", "["..myHero.charName.." Auto Carry: Version "..curVersion.."]", SCRIPT_PARAM_INFO, "")
			Menu.scriptinfo:addParam("sep1", "Script will not automatically use ultimate", SCRIPT_PARAM_INFO, "")
end

function NewIniReader()
	local reader = {};
	function reader:Read(fName)
		self.root = {};
		self.reading_section = "";
		for line in io.lines(fName) do
			if startsWith(line, "[") then
				local section = string.sub(line,2,-2);
				self.root[section] = {};
				self.reading_section = section;
			elseif not startsWith(line, ";") then
				if self.reading_section then
					local var,val = line:usplit("=");
					local var,val = var:utrim(), val:utrim();
					if string.find(val, ";") then
						val,comment = val:usplit(";");
						val = val:utrim();
					end
					self.root[self.reading_section] = self.root[self.reading_section] or {};
					self.root[self.reading_section][var] = val;
				else
					return error("No element set for setting");
				end
			end
		end
	end
	function reader:GetValue(Section, Key)
		return self.root[Section][Key];
	end
	function reader:GetKeys(Section)
		return self.root[Section];
	end
	return reader;
end

function startsWith(text,prefix)
	return string.sub(text, 1, string.len(prefix)) == prefix
end

function string:usplit(sep)
	return self:match("([^" .. sep .. "]+)[" .. sep .. "]+(.+)")
end

function string:utrim()
	return self:match("^%s*(.-)%s*$")
end

function AutoUpdate()
	reader = NewIniReader();
	
	if FileExist(VER_PATH) then 
		reader:Read(VER_PATH);
	
		newDownloadURL = reader:GetValue("Version", "Download")
		newVersion = reader:GetValue("Version", "Version")
		newMessage = reader:GetValue("Version", "Message")
		
		UpdateChat = {
			"<font color='#e066a3'> >> "..myHero.charName.." Auto Carry Plugin:</font> <font color='#f4cce0'> Checking for update... </font>",
			"<font color='#e066a3'> >> "..myHero.charName.." Auto Carry Plugin:</font> <font color='#f4cce0'> Running Version "..curVersion.."</font>",
			"<font color='#e066a3'> >> "..myHero.charName.." Auto Carry Plugin:</font> <font color='#f4cce0'> New Version Released "..newVersion.."</font>",
			"<font color='#e066a3'> >> "..myHero.charName.." Auto Carry Plugin:</font> <font color='#f4cce0'> Updated to version "..newVersion.." press F9 two times to use updated script. </font>",
			"<font color='#e066a3'> >> "..myHero.charName.." Auto Carry Plugin:</font> <font color='#f4cce0'> Script is Up-To-Date </font>",
			"<font color='#e066a3'> >> "..myHero.charName.." Auto Carry Plugin:</font> <font color='#f4cce0'> Update Message ("..newVersion.."): "..newMessage.."</font>",
			"<font color='#e066a3'> >> "..myHero.charName.." Auto Carry Plugin:</font> <font color='#f4cce0'> Failed to check for update, press F9 two times if first run </font>"
					}
					
		local results, reason = os.remove(VER_PATH)
		
		if tonumber(newVersion) > tonumber(curVersion) then
			DownloadFile(newDownloadURL, SCRIPT_PATH, function()
			if FileExist(SCRIPT_PATH) then
			ChatUpdate("update")
            end
			end)
		else
		ChatUpdate("uptodate")
		end	
	else 
		ChatUpdate("failed")
	end 
	hasUpdated = false
end

function ChatUpdate(stats)
		PrintChat(UpdateChat[1])
		PrintChat(UpdateChat[2])
	if stats == "update" then
		PrintChat(UpdateChat[3])
		PrintChat(UpdateChat[4])
		PrintChat(UpdateChat[6])
	elseif stats == "uptodate" then
		PrintChat(UpdateChat[5])
		PrintChat(UpdateChat[6])
	else
		PrintChat(UpdateChat[7])
	end
end


--UPDATEURL=
--HASH=00351E80A703ECB4F06EF3CB26EBF39B
