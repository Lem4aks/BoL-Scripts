--[[YasuoCrit 1.0b by TheMaynard]]

myHero = GetMyHero()
target = nil
local ts
if myHero.charName ~= "Yasuo" then return end
require "AllClass"

function OnLoad()
   -- ts = TargetSelector(TARGET_LOW_HP_PRIORITY,myHero.range + 50)
    Config = scriptConfig("YasuoCrit", "YasuoCrit")
    Config:addParam("critMode", "Crit Mode", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("K"))
end

function OnTick()
    --ts:update()
end

function OnProcessSpell(unit, spell)
	
    if unit.isMe and target and not ValidTarget(target, myHero.range + 40) then
        target = ts.target
    end

    if unit.isMe and (spell.name:find("BasicAttack")~= nil) and (Config.critMode) then --if we are attacking someone, it's not a crit and the script is on
        
        target = spell.target

        --------------------------AA Anyway logic:
        if (target.name:find("Turret_")~=nil) or not (myHero:CanUseSpell(_Q)) or (target.health <= getDmg("AD", target, myHero))
        then --if you're trying to hit a turret though OR Q is on CD OR they'll die anyway
            myHero:Attack(target) --chill
        end
        -------------------------AA Anyway Logic done
		
        myHero:MoveTo(myHero.x,myHero.z)
        CastSpell(_Q, target.x, target.z)

    end

    myHero:Attack(target)

    --wow that was easy...

end
