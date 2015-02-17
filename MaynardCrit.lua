--[[MaynardCrit 1.1b by TheMaynard]]

--[[        Config      ]]

player = GetMyHero()
ptarget = nil
starget = nil
skip = false
mobTable = {}
minionTable = {}

function OnLoad()
Config = scriptConfig("MaynardCrit", "MaynardCrit")
Config:addParam("circleDraw", "Draw Circles", SCRIPT_PARAM_ONOFF, true)
Config:addParam("focusMode", "Focus Mode", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("L"))
Config:addParam("dpsMode", "DPS Mode", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("K"))

end

function OnDraw()
    if Config.circleDraw then
       DrawCircle(player.x, player.y, player.z, player.range + 40, 0x111111)
        if ptarget ~= nil and Config.focusMode then
            DrawCircle(ptarget.x, ptarget.y, ptarget.z, 0xFF6666)
        end
    end
end

function OnProcessSpell(unit, spell)
    if unit.isMe and skip and config.focusMode and spell.name:find("Attack") ~= nil then 
        skip = false
        player:Attack(ptarget)
    end
    if unit.isMe and spell.name:find("Crit")~=nil then
        player:Attack(spell.target)
    end
    if unit.isMe and (spell.name:find("BasicAttack")~= nil) and (Config.dpsMode or Config.focusMode) then --if we are attacking someone and it's not a crit
    --PrintChat("Basic attack attempted on target ".. spell.target.name)
        if (spell.target.name:find("Turret_")~=nil) or (player == findTargetOtherThan(ptarget)) or (spell.target.health <= getDmg("AD", spell.target, player))
        then --if you're trying to hit a turret though OR if there's no viable secondary target OR they'll die anyway
            player:Attack(spell.target) --chill
        end

        tempTarget = ptarget
        --ptarget = targetOf(spell) --find the target
        ptarget = spell.target -- find the target EASILY lol
        if tempTarget == nil or tempTarget == ptarget or distance(player,tempTarget) > (player.range + 40) or tempTarget.dead then --if we no longer have another valid target
            starget = findTargetOtherThan(ptarget) --add another one!
            PrintChat("Secondary Target found: "..starget.name)
        else
            starget = tempTarget --otherwise use the old one
        end
        if starget ~= nil then --if we have two valid targets 
            player:MoveTo(player.x,player.z)--cancel your aa
            if Config.focusMode and not skip then
                skip = true
            end
            player:Attack(starget)--and attack the other guy
        else
            return
        end
    end
end


function getJungleMobs()--straight up stolen from SAC.lua, not sure if the names are all right
        return {"Dragon6.1.1", "Worm12.1.1", "GiantWolf8.1.1", "Wolf8.1.2", "Wolf8.1.3","AncientGolem7.1.1", "YoungLizard7.1.2", "YoungLizard7.1.3", "Wraith9.1.1","LesserWraith9.1.2", "LesserWraith9.1.3", "LesserWraith9.1.4", "LizardElder10.1.1", "YoungLizard10.1.2",  "YoungLizard10.1.3", "Golem11.1.2", "SmallGolem11.1.1", "GiantWolf2.1.1", "Wolf2.1.2", "GreatWraith13.1.1","GreatWraith14.1.1", "Wolf2.1.3", "AncientGolem1.1.1", "YoungLizard1.1.2", "YoungLizard1.1.3", "Wraith3.1.1", "LesserWraith3.1.2", "LesserWraith3.1.3", "LesserWraith3.1.4", "LizardElder4.1.1", "YoungLizard4.1.2", "YoungLizard4.1.3", "Golem5.1.2", "SmallGolem5.1.1", "TT_Spiderboss8.1.1", "TT_NWolf3.1.1", "TT_NWraith1.1.1", "TT_NGolem2.1.1", "TT_NWolf6.1.1", "TT_NWraith4.1.1", "TT_NGolem5.1.1"}
end

function findTargetOtherThan(ptarget)
    local temp
    for i = 0, heroManager.iCount, 1 do
        temp = heroManager:getHero(i)
        if temp.team ~= player.team and temp ~= ptarget and ValidTarget(temp,player.range + 40) then
            return temp --we found a valid hero!
        end
    end
    for k = 0, objManager.maxObjects do
        temp = objManager:GetObject(k)
        if temp and ((temp.name:find("Minion_")~=nil)
         --or (temp.name:find(".1."))~=nil --source of bugsplat?
            ) and temp ~= ptarget and ValidTarget(temp,player.range + 40) then
            return temp -- we found a valid minion
        end
    end
    for i = 0, objManager.maxObjects do
        temp = objManager:getObject(i)
        for _, mob in pairs(getJungleMobs()) do
            if temp and ValidTarget(temp,player.range + 40) and temp.name:find(mob) then
                return temp -- we found a valid jungle mob
            end
        end
    end
    return  player -- nothing found
end


function distance(a,b)
    return math.floor(math.sqrt((a.x-b.x)^2 + (a.z - b.z)^2))
end