--[[		Config		]]
KEY_DOWN = 0x100
KEY_UP = 0x101
critchanceaddkey = 187 --press = to increase crit
critchanceminuskey = 189 --press - to decrease crit
critcreepskey = 75 -- press k to toggle creep crits.
critflag = false
player = GetMyHero()
enemyTable = {}
startingcritthreshold = 0.3

function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

function OnWndMsg( msg, keycode )
    if keycode == critchanceaddkey and msg ==  KEY_UP then
    	local player = GetMyHero()
    	startingcritthreshold = startingcritthreshold + 0.05
    	roundedvalue = startingcritthreshold*100
    	if startingcritthreshold > 100 then
    		startingcritthreshold = 100
    	end
    	PrintChat("critchancethreshold:"..round(roundedvalue,0).."%")
    	if player.critChance > startingcritthreshold then
    		PrintChat("Critting!")
    	else
    		PrintChat("Attacking Normally!")
    	end
    elseif keycode == critchanceminuskey and msg ==  KEY_UP then
    	local player = GetMyHero()
    	startingcritthreshold = startingcritthreshold - 0.05
    	if startingcritthreshold < 0 then
    		startingcritthreshold = 0
    	end
    	roundedvalue = startingcritthreshold*100
    	PrintChat("critchancethreshold:"..round(roundedvalue,0).."%")
    	if player.critChance > startingcritthreshold then
    		PrintChat("Critting!")
    	else
    		PrintChat("Attacking Normally!")
    	end
    elseif keycode == critcreepskey and msg ==  KEY_UP then
    	if critflag == false then
    		critflag = true
    		PrintChat("Critting Creeps ON!")
    	else
    		critflag = false
    		PrintChat("Critting Creeps OFF!")
    	end
    end
end

function OnTick()
	
end

function OnProcessSpell(unit, spell)
    if unit.isMe then
        --PrintChat("Player used spell: "..spell.name)
    end
	name = spell.name
	level = spell.level
	posEnd = spell.endPos
			if unit.isMe and (name:find("BasicAttack")~= nil) and player.critChance > startingcritthreshold then
				for i, tower in pairs(towersTable) do
					if math.floor(math.sqrt((tower.posx-spell.startPos.x)^2 + (tower.posz - spell.startPos.z)^2)) < 80 then
					return
					end
				end
				if critflag == true then
					PrintChat("Attack Cancelled")
    				player:MoveTo(player.x,player.z)
					else
					--PrintChat("CRIT?")
    			end
				for i, enemy in pairs(enemyTable) do
                	if math.floor(math.sqrt((enemy.x-spell.startPos.x)^2 + (enemy.z-spell.startPos.z)^2)) < 150 then
                		if critflag ~= true then
    						player:MoveTo(player.x,player.z)
                            PrintChat("Attack Cancelled")
    					end
    					player:Attack(enemy)
    				end
    			end
			else
				if unit.isMe then  
					--PrintChat("CRIT?")
				end
			end
end


function findTargetOtherThan(ptarget)
	for i = 0, heroManager.iCount, 1 do
		temp = heroManager:getHero(i)
		if temp.team ~= player.team and temp.name ~= ptarget.name and (distance(player,heroManager:getHero(i))) < (player.range + 30) then
			return temp
		end
	end
    return  player -- nothing found
	--LOOP THROUGH AND RETURN A NEARBY ENEMY MINION IF ONE CAN BE FOUND IN RANGE
end

function loadignoretower()
    towersTable = {}
    for i = 1, objManager.iCount, 1 do
        local obj = objManager:getObject(i)
        if obj ~= nil and (string.find(obj.name,"Turret_") ~= nil or string.find(obj.name,"Barracks_") ~= nil or string.find(obj.name,"HQ_") ~= nil) then        
                obj.posx= obj.x
        		obj.posz= obj.z
                table.insert(towersTable, obj)
        end
    end
    for i=0, heroManager.iCount, 1 do
        critplayerObj = heroManager:GetHero(i)
        if critplayerObj and critplayerObj.team ~= player.team then
        	--playerObj.posx= playerObj.x
        	--playerObj.posz= playerObj.z
            table.insert(enemyTable,critplayerObj)
        end
    end
    PrintChat("AutoCrit Loaded! Press - or = to increase/Decrease crit threshold. press K to toggle crit on creeps(OFF by default).")
end
loadignoretower()
