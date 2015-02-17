--[[
	VPrediction 2.1
]]

local _FAST, _MEDIUM, _SLOW = 1, 2, 3
class 'VPrediction' --{
function VPrediction:__init()
	
	self.version = 2.1

	if not _G.VPredictionMenu then
		print("<font color=\"#FF0000\">[VPrediction "..self.version.."]: Loaded successfully!!</font>")
		_G.VPredictionMenu = scriptConfig("VPrediction", "VPrediction")
			
			_G.VPredictionMenu:addParam("Mode", "Cast Mode", SCRIPT_PARAM_LIST, 2, {"Fast", "Medium", "Slow" })
			
			--[[Collision]]
			_G.VPredictionMenu:addSubMenu("Collision", "Collision")
				_G.VPredictionMenu.Collision:addParam("Buffer", "Collision buffer", SCRIPT_PARAM_SLICE, 20, 0, 100)
				_G.VPredictionMenu.Collision:addParam("Minions", "Normal minions", SCRIPT_PARAM_ONOFF, true)
				_G.VPredictionMenu.Collision:addParam("Mobs", "Jungle minions", SCRIPT_PARAM_ONOFF, true)
				_G.VPredictionMenu.Collision:addParam("Others", "Others", SCRIPT_PARAM_ONOFF, true)

			--[[Misc]]
			_G.VPredictionMenu:addSubMenu("Misc", "Misc")
				_G.VPredictionMenu.Misc:addParam("Walls", "Use improved prediction near walls", SCRIPT_PARAM_LIST, 2, { "No", "Line skillshots", "Circular skillshots", "Both" })
			
			_G.VPredictionMenu:addSubMenu("Developers", "Developers")
				_G.VPredictionMenu.Developers:addParam("Debug", "Enable debug", SCRIPT_PARAM_ONOFF, false)
				_G.VPredictionMenu.Developers:addParam("SC", "Show collision", SCRIPT_PARAM_ONOFF, false)
				
			_G.VPredictionMenu:addParam("Version", "Version", SCRIPT_PARAM_INFO, tostring(self.version))
	end
	--[[Use waypoints from the last 10 seconds]]
	self.WaypointsTime = 10
	
	self.EnemyMinions = minionManager(MINION_ENEMY, 2000, myHero.visionPos, MINION_SORT_HEALTH_ASC)
	self.JungleMinions = minionManager(MINION_JUNGLE, 2000, myHero.visionPos, MINION_SORT_HEALTH_ASC)
	self.OtherMinions = minionManager(MINION_OTHER, 2000, myHero.visionPos, MINION_SORT_HEALTH_ASC)

	self.TargetsVisible = {}
	self.TargetsWaypoints = {}
	self.TargetsImmobile = {}
	self.TargetsDashing = {}
	self.TargetsSlowed = {}
	self.DontShoot = {}
	
	self.WayPointManager = WayPointManager()
	self.WayPointManager.AddCallback(function(NetworkID) self:OnNewWayPoints(NetworkID) end)
	
	AdvancedCallback:bind("OnGainVision", function(unit) self:OnGainVision(unit) end)
	AdvancedCallback:bind("OnGainBuff", function(unit, buff) self:OnGainBuff(unit, buff) end)
	AdvancedCallback:bind("OnDash", function(unit, dash) self:OnDash(unit, dash) end)

	AddProcessSpellCallback(function(unit, spell) self:OnProcessSpell(unit, spell) end)
	AddTickCallback(function() self:OnTick() end)
	AddDrawCallback(function() self:OnDraw() end)
	self.BlackList = 
	{
		{name = "aatroxq", duration = 0.75} --[[4 Dashes, OnDash fails]]
	}
	
	--[[Spells that don't allow movement (durations approx)]]
	self.spells = {
		{name = "katarinar", duration = 1}, --Katarinas R
		{name = "drain", duration = 1}, --Fiddle W
		{name = "crowstorm", duration = 1}, --Fiddle R
		{name = "consume", duration = 0.5}, --Nunu Q
		{name = "absolutezero", duration = 1}, --Nunu R
		{name = "rocketgrab", duration = 0.5}, --Blitzcrank Q
		{name = "staticfield", duration = 0.5}, --Blitzcrank R
		{name = "cassiopeiapetrifyinggaze", duration = 0.5}, --Cassio's R
		{name = "ezrealtrueshotbarrage", duration = 1}, --Ezreal's R
		{name = "galioidolofdurand", duration = 1}, --Ezreal's R
		{name = "gragasdrunkenrage", duration = 1}, --""Gragas W
		{name = "luxmalicecannon", duration = 1}, --Lux R
		{name = "reapthewhirlwind", duration = 1}, --Jannas R
		{name = "jinxw", duration = 0.5}, --jinxW
		{name = "jinxr", duration = 0.6}, --jinxR
		{name = "missfortunebullettime", duration = 1}, --MissFortuneR
		{name = "shenstandunited", duration = 1}, --ShenR
		{name = "threshe", duration = 0.4}, --ThreshE
		{name = "threshrpenta", duration = 0.75}, --ThreshR
		{name = "infiniteduress", duration = 1}, --Warwick R
		{name = "meditate", duration = 1} --yi W
	}

	return self
end

--R_WAYPOINT new definition
load(Base64Decode("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"))()
--

function VPrediction:GetTime()
	return GetGameTimer()--os.clock()
end

--[[Track when we lose or gain vision over an enemy]]
function VPrediction:OnGainVision(unit)
	if unit.type == myHero.type then
		self.TargetsVisible[unit.networkID] = self:GetTime()
	end
end

--[[Track when we lose or gain vision over an enemy]]
function VPrediction:OnLoseVision(unit)
	if unit.type == myHero.type then
		self.TargetsVisible[unit.networkID] = math.huge
	end
end

function VPrediction:OnGainBuff(unit, buff)
	if unit.type == myHero.type and (buff.type == BUFF_STUN or buff.type == BUFF_ROOT or buff.type == BUFF_KNOCKUP or buff.type == BUFF_SUPPRESS) then
		self.TargetsImmobile[unit.networkID] = self:GetTime() + buff.duration
	elseif unit.type == myHero.type and (buff.type == BUFF_SLOW or buff.type == BUFF_CHARM or buff.type == BUFF_FEAR or buff.type == BUFF_TAUNT) then
		self.TargetsSlowed[unit.networkID] = self:GetTime() + buff.duration
	end
end

function VPrediction:OnDash(unit, dash)
	if unit.type == myHero.type then
		dash.endPos = dash.target and dash.target or dash.endPos
		dash.startT = self:GetTime()
		dash.endT = self:GetTime() + dash.duration
		self.TargetsDashing[unit.networkID] = dash
	end
end

function VPrediction:OnProcessSpell(unit, spell)
	if unit and unit.type == myHero.type then
		for i, s in ipairs(self.spells) do
			if spell.name:lower() == s.name then
				self.TargetsImmobile[unit.networkID] = self:GetTime() + s.duration
			end
		end
		for i, s in ipairs(self.BlackList) do
			if spell.name:lower() == s.name then
				self.DontShoot[unit.networkID] = self:GetTime() + s.duration
			end
		end
	end
end

function VPrediction:OnNewWayPoints(NetworkID)
	local object = objManager:GetObjectByNetworkId(NetworkID)
	if object and object.valid and object.networkID and object.type == myHero.type then
		if self.TargetsWaypoints[NetworkID] == nil then
			self.TargetsWaypoints[NetworkID] = {}
		end
		local WaypointsToAdd = self.WayPointManager:GetWayPoints(object)
		if WaypointsToAdd and #WaypointsToAdd >= 1 then
			--[[Save only the last waypoint (where the player clicked)]]
			table.insert(self.TargetsWaypoints[NetworkID], {unitpos = Vector(object.visionPos) , waypoint = WaypointsToAdd[#WaypointsToAdd], time = self:GetTime(), n = #WaypointsToAdd})
		end
	end
end

function VPrediction:IsImmobile(unit, delay, radius, speed, from)
	if self.TargetsImmobile[unit.networkID] then
		local ExtraDelay = speed == math.huge and  0 or (GetDistance(from, unit) / speed)
		if (self.TargetsImmobile[unit.networkID] + (radius / unit.ms)) > (self:GetTime() + delay + ExtraDelay) then
			return true, unit
		end
	end
	return false, unit
end

function VPrediction:isSlowed(unit, delay, speed, from)
	if self.TargetsSlowed[unit.networkID] then
		if self.TargetsSlowed[unit.networkID] > (self:GetTime() + delay + GetDistance(unit, from) / speed) then
			return false
		end
	end
	return false
end

function VPrediction:IsDashing(unit, delay, radius, speed, from)
	local TargetDashing = false
	local CanHit = false
	local Position

	if self.TargetsDashing[unit.networkID] then
		local dash = self.TargetsDashing[unit.networkID]
		if dash.endT >= self:GetTime() then
			TargetDashing = true
			local t1, p1, t2, p2, dist = VectorMovementCollision(dash.startPos, dash.endPos, dash.speed, from, speed, delay + self:GetTime() - dash.startT)
			t1, t2 = (t1 and 0 <= t1 and t1 <= (dash.endT - self:GetTime() - delay)) and t1 or nil, (t2 and 0 <= t2 and t2 <=  (dash.endT - self:GetTime() - delay)) and t2 or nil 
			local t = t1 and t2 and math.min(t1,t2) or t1 or t2
			if t then
				Position = t==t1 and Vector(p1.x, 0, p1.y) or Vector(p2.x, 0, p2.y)
				CanHit = true
			else
				Position = Vector(dash.endPos.x, 0, dash.endPos.z)
				CanHit = (unit.ms * (delay + GetDistance(from, Position)/speed - (dash.endT - self:GetTime()))) < radius
			end
		end
	end
	return TargetDashing, CanHit, Position
end

function VPrediction:GetWaypoints(NetworkID, from, to)
	local Result = {}
	to = to and to or self:GetTime()
	if self.TargetsWaypoints[NetworkID] then
		for i, waypoint in ipairs(self.TargetsWaypoints[NetworkID]) do
			if from <= waypoint.time  and to >= waypoint.time then
				table.insert(Result, waypoint)
			end
		end
	end
	return Result, #Result
end

function VPrediction:CountWaypoints(NetworkID, from, to)
	local R, N = self:GetWaypoints(NetworkID, from, to)
	return N
end

function VPrediction:CheckWalls(unit, radius, Position, CastPosition)
	--[[Check the walls to get the optimal cast position]]
	local center = Vector(0, 0, 0)
	local n = 0
	local wallpoints = {}
	local ClosestDist = math.huge
	for theta = 0, 2 * math.pi + 0.2, 0.2  do
		local c = Vector(CastPosition.x + (radius + self:GetPathFindingRadius(unit)) * math.cos(theta), CastPosition.y, CastPosition.z + (radius + self:GetPathFindingRadius(unit)) * math.sin(theta))
		if IsWall(D3DXVECTOR3(c.x, c.y, c.z)) then
			n = n + 1
			center = center + c
			table.insert(wallpoints, c)
		end
	end
	if n > 0 then
		center = center / n
		local angle = Vector(0,0,0):angleBetween(Vector(Position - center), Vector(myHero - Position))
		if  angle > 70 and angle < 100 then
			for i, wpoint in ipairs(wallpoints) do
				local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(CastPosition, CastPosition + Vector(center - CastPosition):perpendicular(), wpoint)
				local Dist = GetDistance(wpoint, pointLine)
				if Dist <= ClosestDist then
					ClosestDist = Dist
				end
			end
						
			local p = Vector(CastPosition) + (radius + self:GetPathFindingRadius(unit) - ClosestDist) * (Vector(CastPosition) - Vector(center)):normalized()
			CastPosition = Position + math.min(radius + math.min(self:GetPathFindingRadius(unit), ClosestDist) - math.max(self:GetPathFindingRadius(unit), ClosestDist)) * Vector(p - Position):normalized()
		end
	end
	return CastPosition
end

function VPrediction:GetWaypointsLength(Waypoints)
	local result = 0
	for i = 1, #Waypoints -1 do
		result = result + GetDistance(Waypoints[i], Waypoints[i + 1])
	end
	return result
end

function VPrediction:CutWaypoints(Waypoints, distance)
	local result = {}
	local remaining = distance
	if distance > 0 then
		for i = 1, #Waypoints -1 do
			local A, B = Waypoints[i], Waypoints[i + 1]
			local dist = GetDistance(A, B)
			if dist >= remaining then
				result[1] = Vector(A) + remaining * (Vector(B) - Vector(A)):normalized()

				for j = i + 1, #Waypoints do
					result[j - i + 1] = Waypoints[j]
				end
				remaining = 0
				break
			else
				remaining = remaining - dist
			end
		end
	else
		local A, B = Waypoints[1], Waypoints[2]
		result = Waypoints
		result[1] = Vector(A) - distance * (Vector(B) - Vector(A)):normalized()
	end

	return result
end

function VPrediction:GetCurrentWayPoints(object)
    local wayPoints, lineSegment, distanceSqr, fPoint = self.WayPointManager:GetRawWayPoints(object), 0, math.huge, nil
    if not wayPoints then return { { x = object.visionPos.x, y = object.visionPos.z } } end
    for i = 1, #wayPoints - 1 do
        local p1, tmp1, tmp2 = VectorPointProjectionOnLineSegment(wayPoints[i], wayPoints[i + 1], object.visionPos)
        local distanceSegmentSqr = GetDistanceSqr(p1, object.visionPos)
        if distanceSegmentSqr <= distanceSqr then
            fPoint = p1
            lineSegment = i
            distanceSqr = distanceSegmentSqr
        else
        	break --not necessary, but makes it faster
        end
    end
    local result = { fPoint or { x = object.visionPos.x, y = object.visionPos.z } }
    for i = lineSegment + 1, #wayPoints do
        result[#result + 1] = wayPoints[i]
    end
    if #result == 2 and GetDistanceSqr(result[1], result[2]) < 400 then result[2] = nil end
    return result
end

--[[Calculate the hero position based on the last waypoints]]
function VPrediction:CalculateTargetPosition(unit, delay, radius, speed, from, type)
	local Waypoints = {}
	local Position, CastPosition
	
	Waypoints = self:GetCurrentWayPoints(unit)
	local Waypointslength = self:GetWaypointsLength(Waypoints)

	if #Waypoints == 1 then
		Position, CastPosition = Vector(Waypoints[1].x, 0, Waypoints[1].y), Vector(Waypoints[1].x, 0, Waypoints[1].y)
		if unit.type == myHero.type and (_G.VPredictionMenu.Misc.Walls == 4 or  (type == "line" and _G.VPredictionMenu.Misc.Walls == 2) or  (type == "circular" and _G.VPredictionMenu.Misc.Walls == 3)) then
			CastPosition = self:CheckWalls(unit, radius, Position, CastPosition)
		end
		return Position, CastPosition
	elseif (Waypointslength - delay * unit.ms + radius) >= 0 then
		local tA = 0
		local t
		Waypoints = self:CutWaypoints(Waypoints, delay * unit.ms - radius)

		if speed ~= math.huge then
			for i = 1, #Waypoints - 1 do
				local A, B = Waypoints[i], Waypoints[i+1]
				if i == #Waypoints - 1 then
					B = Vector(B) + radius * Vector(B - A):normalized()
				end
				local t1, p1, t2, p2, D = VectorMovementCollision(A, B, unit.ms, Vector(from.x, from.z), speed)
				local tB = tA + D / unit.ms
				t1, t2 = (t1 and tA <= t1 and t1 <= (tB - tA)) and t1 or nil, (t2 and tA <= t2 and t2 <= (tB - tA)) and t2 or nil
				t = t1 and t2 and math.min(t1, t2) or t1 or t2
				if t then
					CastPosition = t==t1 and Vector(p1.x, 0, p1.y) or Vector(p2.x, 0, p2.y)
					break
				end
				tA = tB
			end
		else
			t = 0
			CastPosition = Vector(Waypoints[1].x, 0, Waypoints[1].y)
		end

		if t then
			if (self:GetWaypointsLength(Waypoints) - t * unit.ms - radius) >= 0 then
				Waypoints = self:CutWaypoints(Waypoints, radius + t * unit.ms)
				Position = Vector(Waypoints[1].x, 0, Waypoints[1].y)
			else
				Position = CastPosition
			end
		elseif unit.type ~= myHero.type then
			CastPosition = Vector(Waypoints[#Waypoints].x, 0, Waypoints[#Waypoints].y)
			Position = CastPosition
		end

	elseif unit.type ~= myHero.type then
		CastPosition = Vector(Waypoints[#Waypoints].x, 0, Waypoints[#Waypoints].y)
		Position = CastPosition
	end

	if t and self:isSlowed(unit, 0, math.huge, from) and not self:isSlowed(unit, t, math.huge, from) and Position then
		CastPosition = Position
	end
	
	if CastPosition and Position then
		if (_G.VPredictionMenu.Misc.Walls == 2 and type == "line") or (_G.VPredictionMenu.Misc.Walls == 2 and type == "circular") or (_G.VPredictionMenu.Misc.Walls == 3) then
			CastPosition = self:CheckWalls(unit, radius, Position, CastPosition)
		end
	end

	return Position, CastPosition
end

function VPrediction:MaxAngle(unit, currentwaypoint, from)
	local WPtable, n = self:GetWaypoints(unit.networkID, from)
	local Max = 0
	local CV = (Vector(currentwaypoint.x, 0, currentwaypoint.y) - Vector(unit))
		for i, waypoint in ipairs(WPtable) do
				local angle = Vector(0, 0, 0):angleBetween(CV, Vector(waypoint.waypoint.x, 0, waypoint.waypoint.y) - Vector(waypoint.unitpos.x, 0, waypoint.unitpos.y))
				if angle > Max then
					Max = angle
				end
		end
	return Max
end

function VPrediction:WayPointAnalysis(unit, delay, radius, range, speed, from, type)
	local Position, CastPosition, HitChance
	local SavedWayPoints = self.TargetsWaypoints[unit.networkID] and self.TargetsWaypoints[unit.networkID] or {}
	local CurrentWayPoints = self:GetCurrentWayPoints(unit)
	local VisibleSince = self.TargetsVisible[unit.networkID] and self.TargetsVisible[unit.networkID] or self:GetTime()
	
	HitChance = 1
	Position, CastPosition = self:CalculateTargetPosition(unit, delay, radius, speed, from, type)

	if self:CountWaypoints(unit.networkID, self:GetTime() - 0.1) >= 1 or self:CountWaypoints(unit.networkID, self:GetTime() - 1) == 1 then
		HitChance = 2
	end
	
	local N = (_G.VPredictionMenu.Mode == _SLOW) and 3 or 2
	local t1 = (_G.VPredictionMenu.Mode == _SLOW) and 1 or 0.5
	if self:CountWaypoints(unit.networkID, self:GetTime() - 0.75) >= N then
		local angle = self:MaxAngle(unit, CurrentWayPoints[#CurrentWayPoints], self:GetTime() - t1)
		if angle > 90 then
			HitChance = 1
		elseif angle < 30 and self:CountWaypoints(unit.networkID, self:GetTime() - 0.1) >= 1 then
			HitChance = 2
		end
	end
	
	N = (_G.VPredictionMenu.Mode == _SLOW) and 2 or 1
	if self:CountWaypoints(unit.networkID, self:GetTime() - N) == 0 then
		HitChance = 2
	end
	
	if _G.VPredictionMenu.Mode == _FAST then
		HitChance = 2
	end
	
	if #CurrentWayPoints <= 1 and self:GetTime() - VisibleSince > 1 then
		HitChance = 2
	end
	
	if self:isSlowed(unit, delay, speed, from) then
		HitChance = 2
	end

	if Position and CastPosition and ((radius / unit.ms >= delay + GetDistance(from, CastPosition)/speed) or (radius / unit.ms >= delay + GetDistance(from, Position)/speed)) then
		HitChance = 3
	end
		--[[Angle too wide]]
	if Vector(from):angleBetween(Vector(unit.visionPos), Vector(CastPosition)) > 60 then
		HitChance = 1
	end
	
	if not Position or not CastPosition then
		HitChance = 0
		CastPosition = Vector(CurrentWayPoints[#CurrentWayPoints].x, 0, CurrentWayPoints[#CurrentWayPoints].y)
		Position = CastPosition
	end

	if #SavedWayPoints == 0 and (self:GetTime() - VisibleSince) > 3 then
		HitChance = 2
	end
	
	return CastPosition, HitChance, Position
end

function VPrediction:GetBestCastPosition(unit, delay, radius, range, speed, from, collision, type)
	assert(unit, "VPrediction: Target can't be nil")
	
	range = range and range - 4 or math.huge
	radius = radius == 0 and 1 or (radius + self:GetHitBox(unit)) - 4
	speed = speed and speed or math.huge
	from = from and from or Vector(myHero.visionPos)
	if from.networkID and from.networkID == myHero.networkID then
		from = Vector(myHero.visionPos)
	end
	delay = delay + (0.07 +  GetLatency() / 2000) 
	
	local Position, CastPosition, HitChance
	local TargetDashing, CanHitDashing, DashPosition = self:IsDashing(unit, delay, radius, speed, from)
	local TargetImmobile, ImmobilePos = self:IsImmobile(unit, delay, radius, speed, from)
	local VisibleSince = self.TargetsVisible[unit.networkID] and self.TargetsVisible[unit.networkID] or self:GetTime()

	if unit.type ~= myHero.type then
		--[[TODO: improve minion prediction]]
		Position, CastPosition = self:CalculateTargetPosition(unit, delay, radius, speed, from, type)
		HitChance = 2
	else
		if self.DontShoot[unit.networkID] and self.DontShoot[unit.networkID] > self:GetTime() then
			Position, CastPosition = Vector(unit.x, unit.y, unit.z),  Vector(unit.x, unit.y, unit.z)
			HitChance = 0
		elseif TargetImmobile then
			Position, CastPosition = ImmobilePos, ImmobilePos
			HitChance = 4
		elseif TargetDashing then
			if CanHitDashing then
				HitChance = 5
			else
				HitChance = 0
			end 
			Position, CastPosition = DashPosition, DashPosition
		else
			CastPosition, HitChance, Position = self:WayPointAnalysis(unit, delay, radius, range, speed, from, type)
		end
	end

	--[[Out of range]]
	if ((type == "line" and (GetDistance(myHero.visionPos, Position) >= range)) or (type == "circular" and (GetDistance(myHero.visionPos, Position) >= range + radius))  or (GetDistance(myHero.visionPos, CastPosition) > range)) then
		HitChance = 1
	end
	radius = radius - self:GetHitBox(unit) + 4
	if collision and (self:CheckMinionCollision(CastPosition, delay, radius, range, speed, from, draw) or self:CheckMinionCollision(Position, delay, radius, range, speed, from) or self:CheckMinionCollision(unit, delay, radius, range, speed, from)) then
		HitChance = -1
	end
	return CastPosition, HitChance, Position
end

function VPrediction:CheckCol(minion, Position, delay, radius, range, speed, from, draw)
	local MPos, CastPosition = self:CalculateTargetPosition(minion, delay, radius, speed, from, "line")
	local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(from, Position, Vector(MPos))
	local pointSegment2, pointLine2, isOnSegment2 = VectorPointProjectionOnLineSegment(from, Position, Vector(minion.visionPos))
	local waypoints = self:GetCurrentWayPoints(minion)
	local buffer = (#waypoints > 1) and _G.VPredictionMenu.Collision.Buffer or 8
	
	if draw then
		DrawCircle3D(minion.visionPos.x, myHero.y, minion.visionPos.z, self:GetHitBox(minion) + buffer, 1, ARGB(255, 255, 255, 255))
		DrawCircle3D(MPos.x, myHero.y, MPos.z, self:GetHitBox(minion) + buffer, 1, ARGB(255, 255, 255, 255))
		self:DLine(MPos, minion.visionPos, Color)
	end
	
	if (isOnSegment and GetDistanceSqr(MPos, pointSegment) <= (self:GetHitBox(minion) + radius + buffer) ^ 2) or (isOnSegment2 and GetDistanceSqr(minion.visionPos, pointSegment) <= (self:GetHitBox(minion) + radius + buffer) ^ 2) then
		return true
	end
	return false
end

function VPrediction:CheckMinionCollision(Position, delay, radius, range, speed, from, draw)
	self.EnemyMinions:update()
	self.JungleMinions:update()
	self.OtherMinions:update()
	
	Position = Vector(Position)
	from = from and Vector(from) or myHero.visionPos
	
	local result = false
	if _G.VPredictionMenu.Collision.Minions then
		for i, minion in ipairs(self.EnemyMinions.objects) do
			if self:CheckCol(minion, Position, delay, radius, range, speed, from, draw) then
				if not draw then
					return true
				else
					result = true
				end
			end
		end
	end
	
	if _G.VPredictionMenu.Collision.Mobs then
		for i, minion in ipairs(self.JungleMinions.objects) do
			if self:CheckCol(minion, Position, delay, radius, range, speed, from, draw) then
				if not draw then
					return true
				else
					result = true
				end
			end
		end
	end

	if _G.VPredictionMenu.Collision.Others then
		for i, minion in ipairs(self.OtherMinions.objects) do
			if minion.team ~= myHero.team and self:CheckCol(minion, Position, delay, radius, range, speed, from, draw) then
				if not draw then
					return true
				else
					result = true
				end
			end
		end
	end

	if draw then
		local Direction = Vector(Position - from):perpendicular():normalized()
		local Color = result and ARGB(255, 255, 0, 0) or ARGB(255, 0, 255, 0)
		local P1r = Vector(from) + radius * Vector(Direction)
		local P1l = Vector(from) - radius * Vector(Direction)
		local P2r = Vector(from) + radius * Direction - Vector(Direction):perpendicular() * GetDistance(from, Position)
		local P2l = Vector(from) - radius * Direction - Vector(Direction):perpendicular() * GetDistance(from, Position)

		self:DLine(P1r, P1l, Color)
		self:DLine(P1r, P2r, Color)
		self:DLine(P1l, P2l, Color)
		self:DLine(P2r, P2l, Color)
	end

	return false
end

function VPrediction:GetCircularCastPosition(unit, delay, radius, range, speed, from, collision)
	return self:GetBestCastPosition(unit, delay, radius, range, speed, from, collision, "circular")
end

function VPrediction:GetLineCastPosition(unit, delay, radius, range, speed, from, collision)
	return self:GetBestCastPosition(unit, delay, radius, range, speed, from, collision, "line")
end

function VPrediction:GetCircularAOECastPosition(unit, delay, radius, range, speed, from, collision)
	return self:GetBestCastPosition(unit, delay, radius, range, speed, from, collision, "circular")
end

function VPrediction:GetLineAOECastPosition(unit, delay, radius, range, speed, from, collision)
	return self:GetBestCastPosition(unit, delay, radius, range, speed, from, collision, "line")
end

function VPrediction:GetPredictedPos(unit, delay, speed, from, collision)
	return self:GetBestCastPosition(unit, delay, 1, math.huge, speed, from, collision, "circular")
end

function VPrediction:OnTick()
	--[[Delete the old saved Waypoints]]
	if self.lastick == nil or self:GetTime() - self.lastick > 0.5 then
		self.lastick = self:GetTime()
		for NID, TargetWaypoints in pairs(self.TargetsWaypoints) do
			local i = 1 
			while i <= #self.TargetsWaypoints[NID] do
				if self.TargetsWaypoints[NID][i]["time"] + self.WaypointsTime < self:GetTime() then
					table.remove(self.TargetsWaypoints[NID], i)
				else
					i = i + 1
				end
			end
		end
	end
end

--[[Drawing functions for debug: ]]
function VPrediction:DrawSavedWaypoints(object, time)
	local Waypoints = self:GetWaypoints(object.networkID, self:GetTime() - time)
	for i, waypoint in ipairs(Waypoints) do
		DrawCircle3D(waypoint.waypoint.x, myHero.y, waypoint.waypoint.y, 100, 2, ARGB(255, 255, 255, 255))
		DrawText3D(tostring(i), waypoint.waypoint.x, myHero.y, waypoint.waypoint.y, 13, ARGB(255, 255, 255, 255), true)
		DrawCircle3D(waypoint.unitpos.x, myHero.y, waypoint.unitpos.y, 100, 2, ARGB(255, 255, 0, 0))
	end
end

function VPrediction:DrawHitBox(object)
	DrawCircle3D(object.x, object.y, object.z, self:GetHitBox(object), 1, ARGB(255, 255, 255, 255))
	if object.visionPos then
		DrawCircle3D(object.visionPos.x, object.visionPos.y, object.visionPos.z, self:GetHitBox(object), 1, ARGB(255, 0, 255, 0))
	end
end

function VPrediction:DLine(From, To, Color)
	DrawLine3D(From.x, From.y, From.z, To.x, To.y, To.z, 1, Color)
end

function VPrediction:OnDraw()
	if _G.VPredictionMenu.Developers.Debug then
		local target = GetTarget() or myHero

		for i, enemy in ipairs(GetEnemyHeroes()) do
			self:DrawHitBox(enemy)
		end
		if _G.VPredictionMenu.Developers.SC then
			self:CheckMinionCollision(Vector(myHero.visionPos) + 1050 * (Vector(mousePos) - Vector(myHero.visionPos)):normalized(), 0.25, 70, 1050, 1800, myHero.visionPos, true)
		end
		if target then
			self:DrawHitBox(target) 
			local CastPosition,  HitChance,  Position = self:GetCircularCastPosition(target, 0.125, 60, 1500, 1300)
			if HitChance >= -1 then
				DrawCircle3D(Position.x, myHero.y, Position.z, 70 + self:GetHitBox(target), 1, ARGB(255, 0, 255, 0))
				DrawCircle3D(CastPosition.x, myHero.y, CastPosition.z, 70 + self:GetHitBox(target), 1, ARGB(255, 255, 0, 0))
			end
			local waypoint = self:GetCurrentWayPoints(target)
			for i  = 1, #waypoint-1 do
				self:DLine(Vector(waypoint[i].x, myHero.y, waypoint[i].y), Vector(waypoint[i+1].x, myHero.y, waypoint[i+1].y), ARGB(255,255,255,255))
			end
		end
	end
end

function VPrediction:GetHitBox(object)
	local hitboxTable = {['RecItemsCLASSIC'] = 65, ['TeemoMushroom'] = 50.0, ['TestCubeRender'] = 65, ['Xerath'] = 65, ['Kassadin'] = 65, ['Rengar'] = 65, ['Thresh'] = 55.0, ['RecItemsTUTORIAL'] = 65, ['Ziggs'] = 55.0, ['ZyraPassive'] = 20.0, ['ZyraThornPlant'] = 20.0, ['KogMaw'] = 65, ['HeimerTBlue'] = 35.0, ['EliseSpider'] = 65, ['Skarner'] = 80.0, ['ChaosNexus'] = 65, ['Katarina'] = 65, ['Riven'] = 65, ['SightWard'] = 1, ['HeimerTYellow'] = 35.0, ['Ashe'] = 65, ['VisionWard'] = 1, ['TT_NGolem2'] = 80.0, ['ThreshLantern'] = 65, ['RecItemsCLASSICMap10'] = 65, ['RecItemsODIN'] = 65, ['TT_Spiderboss'] = 200.0, ['RecItemsARAM'] = 65, ['OrderNexus'] = 65, ['Soraka'] = 65, ['Jinx'] = 65, ['TestCubeRenderwCollision'] = 65, ['Red_Minion_Wizard'] = 48.0, ['JarvanIV'] = 65, ['Blue_Minion_Wizard'] = 48.0, ['TT_ChaosTurret2'] = 88.4, ['TT_ChaosTurret3'] = 88.4, ['TT_ChaosTurret1'] = 88.4, ['ChaosTurretGiant'] = 88.4, ['Dragon'] = 100.0, ['LuluSnowman'] = 50.0, ['Worm'] = 100.0, ['ChaosTurretWorm'] = 88.4, ['TT_ChaosInhibitor'] = 65, ['ChaosTurretNormal'] = 88.4, ['AncientGolem'] = 100.0, ['ZyraGraspingPlant'] = 20.0, ['HA_AP_OrderTurret3'] = 88.4, ['HA_AP_OrderTurret2'] = 88.4, ['Tryndamere'] = 65, ['OrderTurretNormal2'] = 88.4, ['Singed'] = 65, ['OrderInhibitor'] = 65, ['Diana'] = 65, ['HA_FB_HealthRelic'] = 65, ['TT_OrderInhibitor'] = 65, ['GreatWraith'] = 80.0, ['Yasuo'] = 65, ['OrderTurretDragon'] = 88.4, ['OrderTurretNormal'] = 88.4, ['LizardElder'] = 65.0, ['HA_AP_ChaosTurret'] = 88.4, ['Ahri'] = 65, ['Lulu'] = 65, ['ChaosInhibitor'] = 65, ['HA_AP_ChaosTurret3'] = 88.4, ['HA_AP_ChaosTurret2'] = 88.4, ['ChaosTurretWorm2'] = 88.4, ['TT_OrderTurret1'] = 88.4, ['TT_OrderTurret2'] = 88.4, ['TT_OrderTurret3'] = 88.4, ['LuluFaerie'] = 65, ['HA_AP_OrderTurret'] = 88.4, ['OrderTurretAngel'] = 88.4, ['YellowTrinketUpgrade'] = 1, ['MasterYi'] = 65, ['Lissandra'] = 65, ['ARAMOrderTurretNexus'] = 88.4, ['Draven'] = 65, ['FiddleSticks'] = 65, ['SmallGolem'] = 80.0, ['ARAMOrderTurretFront'] = 88.4, ['ChaosTurretTutorial'] = 88.4, ['NasusUlt'] = 80.0, ['Maokai'] = 80.0, ['Wraith'] = 50.0, ['Wolf'] = 50.0, ['Sivir'] = 65, ['Corki'] = 65, ['Janna'] = 65, ['Nasus'] = 80.0, ['Golem'] = 80.0, ['ARAMChaosTurretFront'] = 88.4, ['ARAMOrderTurretInhib'] = 88.4, ['LeeSin'] = 65, ['HA_AP_ChaosTurretTutorial'] = 88.4, ['GiantWolf'] = 65.0, ['HA_AP_OrderTurretTutorial'] = 88.4, ['YoungLizard'] = 50.0, ['Jax'] = 65, ['LesserWraith'] = 50.0, ['Blitzcrank'] = 80.0, ['brush_D_SR'] = 65, ['brush_E_SR'] = 65, ['brush_F_SR'] = 65, ['brush_C_SR'] = 65, ['brush_A_SR'] = 65, ['brush_B_SR'] = 65, ['ARAMChaosTurretInhib'] = 88.4, ['Shen'] = 65, ['Nocturne'] = 65, ['Sona'] = 65, ['ARAMChaosTurretNexus'] = 88.4, ['YellowTrinket'] = 1, ['OrderTurretTutorial'] = 88.4, ['Caitlyn'] = 65, ['Trundle'] = 65, ['Malphite'] = 80.0, ['Mordekaiser'] = 80.0, ['ZyraSeed'] = 65, ['Vi'] = 50, ['Tutorial_Red_Minion_Wizard'] = 48.0, ['Renekton'] = 80.0, ['Anivia'] = 65, ['Fizz'] = 65, ['Heimerdinger'] = 55.0, ['Evelynn'] = 65, ['Rumble'] = 80.0, ['Leblanc'] = 65, ['Darius'] = 80.0, ['OlafAxe'] = 50.0, ['Viktor'] = 65, ['XinZhao'] = 65, ['Orianna'] = 65, ['Vladimir'] = 65, ['Nidalee'] = 65, ['Tutorial_Red_Minion_Basic'] = 48.0, ['ZedShadow'] = 65, ['Syndra'] = 65, ['Zac'] = 80.0, ['Olaf'] = 65, ['Veigar'] = 55.0, ['Twitch'] = 65, ['Alistar'] = 80.0, ['Akali'] = 65, ['Urgot'] = 80.0, ['Leona'] = 65, ['Talon'] = 65, ['Karma'] = 65, ['Jayce'] = 65, ['Galio'] = 80.0, ['Shaco'] = 65, ['Taric'] = 65, ['TwistedFate'] = 65, ['Varus'] = 65, ['Garen'] = 65, ['Swain'] = 65, ['Vayne'] = 65, ['Fiora'] = 65, ['Quinn'] = 65, ['Kayle'] = 65, ['Blue_Minion_Basic'] = 48.0, ['Brand'] = 65, ['Teemo'] = 55.0, ['Amumu'] = 55.0, ['Annie'] = 55.0, ['Odin_Blue_Minion_caster'] = 48.0, ['Elise'] = 65, ['Nami'] = 65, ['Poppy'] = 55.0, ['AniviaEgg'] = 65, ['Tristana'] = 55.0, ['Graves'] = 65, ['Morgana'] = 65, ['Gragas'] = 80.0, ['MissFortune'] = 65, ['Warwick'] = 65, ['Cassiopeia'] = 65, ['Tutorial_Blue_Minion_Wizard'] = 48.0, ['DrMundo'] = 80.0, ['Volibear'] = 80.0, ['Irelia'] = 65, ['Odin_Red_Minion_Caster'] = 48.0, ['Lucian'] = 65, ['Yorick'] = 80.0, ['RammusPB'] = 65, ['Red_Minion_Basic'] = 48.0, ['Udyr'] = 65, ['MonkeyKing'] = 65, ['Tutorial_Blue_Minion_Basic'] = 48.0, ['Kennen'] = 55.0, ['Nunu'] = 65, ['Ryze'] = 65, ['Zed'] = 65, ['Nautilus'] = 80.0, ['Gangplank'] = 65, ['shopevo'] = 65, ['Lux'] = 65, ['Sejuani'] = 80.0, ['Ezreal'] = 65, ['OdinNeutralGuardian'] = 65, ['Khazix'] = 65, ['Sion'] = 80.0, ['Aatrox'] = 65, ['Hecarim'] = 80.0, ['Pantheon'] = 65, ['Shyvana'] = 50.0, ['Zyra'] = 65, ['Karthus'] = 65, ['Rammus'] = 65, ['Zilean'] = 65, ['Chogath'] = 80.0, ['Malzahar'] = 65, ['YorickRavenousGhoul'] = 1.0, ['YorickSpectralGhoul'] = 1.0, ['JinxMine'] = 65, ['YorickDecayedGhoul'] = 1.0, ['XerathArcaneBarrageLauncher'] = 65, ['Odin_SOG_Order_Crystal'] = 65, ['TestCube'] = 65, ['ShyvanaDragon'] = 80.0, ['FizzBait'] = 65, ['ShopKeeper'] = 65, ['Blue_Minion_MechMelee'] = 65.0, ['OdinQuestBuff'] = 65, ['TT_Buffplat_L'] = 65, ['TT_Buffplat_R'] = 65, ['KogMawDead'] = 65, ['TempMovableChar'] = 48.0, ['Lizard'] = 50.0, ['GolemOdin'] = 80.0, ['OdinOpeningBarrier'] = 65, ['TT_ChaosTurret4'] = 88.4, ['TT_Flytrap_A'] = 65, ['TT_Chains_Order_Periph'] = 65, ['TT_NWolf'] = 65.0, ['ShopMale'] = 65, ['OdinShieldRelic'] = 65, ['TT_Chains_Xaos_Base'] = 65, ['LuluSquill'] = 50.0, ['TT_Shopkeeper'] = 65, ['redDragon'] = 100.0, ['MonkeyKingClone'] = 65, ['Odin_skeleton'] = 65, ['OdinChaosTurretShrine'] = 88.4, ['Cassiopeia_Death'] = 65, ['OdinCenterRelic'] = 48.0, ['Ezreal_cyber_1'] = 65, ['Ezreal_cyber_3'] = 65, ['Ezreal_cyber_2'] = 65, ['OdinRedSuperminion'] = 55.0, ['TT_Speedshrine_Gears'] = 65, ['JarvanIVWall'] = 65, ['DestroyedNexus'] = 65, ['ARAMOrderNexus'] = 65, ['Red_Minion_MechCannon'] = 65.0, ['OdinBlueSuperminion'] = 55.0, ['SyndraOrbs'] = 65, ['LuluKitty'] = 50.0, ['SwainNoBird'] = 65, ['LuluLadybug'] = 50.0, ['CaitlynTrap'] = 65, ['TT_Shroom_A'] = 65, ['ARAMChaosTurretShrine'] = 88.4, ['Odin_Windmill_Propellers'] = 65, ['DestroyedInhibitor'] = 65, ['TT_NWolf2'] = 50.0, ['OdinMinionGraveyardPortal'] = 1.0, ['SwainBeam'] = 65, ['Summoner_Rider_Order'] = 65.0, ['TT_Relic'] = 65, ['odin_lifts_crystal'] = 65, ['OdinOrderTurretShrine'] = 88.4, ['SpellBook1'] = 65, ['Blue_Minion_MechCannon'] = 65.0, ['TT_ChaosInhibitor_D'] = 65, ['Odin_SoG_Chaos'] = 65, ['TrundleWall'] = 65, ['HA_AP_HealthRelic'] = 65, ['OrderTurretShrine'] = 88.4, ['OriannaBall'] = 48.0, ['ChaosTurretShrine'] = 88.4, ['LuluCupcake'] = 50.0, ['HA_AP_ChaosTurretShrine'] = 88.4, ['TT_Chains_Bot_Lane'] = 65, ['TT_NWraith2'] = 50.0, ['TT_Tree_A'] = 65, ['SummonerBeacon'] = 65, ['Odin_Drill'] = 65, ['TT_NGolem'] = 80.0, ['Shop'] = 65, ['AramSpeedShrine'] = 65, ['DestroyedTower'] = 65, ['OriannaNoBall'] = 65, ['Odin_Minecart'] = 65, ['Summoner_Rider_Chaos'] = 65.0, ['OdinSpeedShrine'] = 65, ['TT_Brazier'] = 65, ['TT_SpeedShrine'] = 65, ['odin_lifts_buckets'] = 65, ['OdinRockSaw'] = 65, ['OdinMinionSpawnPortal'] = 1.0, ['SyndraSphere'] = 48.0, ['TT_Nexus_Gears'] = 65, ['Red_Minion_MechMelee'] = 65.0, ['SwainRaven'] = 65, ['crystal_platform'] = 65, ['MaokaiSproutling'] = 48.0, ['Urf'] = 65, ['TestCubeRender10Vision'] = 65, ['MalzaharVoidling'] = 10.0, ['GhostWard'] = 1, ['MonkeyKingFlying'] = 65, ['LuluPig'] = 50.0, ['AniviaIceBlock'] = 65, ['TT_OrderInhibitor_D'] = 65, ['yonkey'] = 65, ['Odin_SoG_Order'] = 65, ['RammusDBC'] = 65, ['FizzShark'] = 65, ['LuluDragon'] = 50.0, ['OdinTestCubeRender'] = 65, ['OdinCrane'] = 65, ['TT_Tree1'] = 65, ['ARAMOrderTurretShrine'] = 88.4, ['TT_Chains_Order_Base'] = 65, ['Odin_Windmill_Gears'] = 65, ['ARAMChaosNexus'] = 65, ['TT_NWraith'] = 50.0, ['TT_OrderTurret4'] = 88.4, ['Odin_SOG_Chaos_Crystal'] = 65, ['TT_SpiderLayer_Web'] = 65, ['OdinQuestIndicator'] = 1.0, ['JarvanIVStandard'] = 65, ['TT_DummyPusher'] = 65, ['OdinClaw'] = 65, ['EliseSpiderling'] = 1.0, ['QuinnValor'] = 65, ['UdyrTigerUlt'] = 65, ['UdyrTurtleUlt'] = 65, ['UdyrUlt'] = 65, ['UdyrPhoenixUlt'] = 65, ['ShacoBox'] = 10, ['HA_AP_Poro'] = 65, ['AnnieTibbers'] = 80.0, ['UdyrPhoenix'] = 65, ['UdyrTurtle'] = 65, ['UdyrTiger'] = 65, ['HA_AP_OrderShrineTurret'] = 88.4, ['HA_AP_OrderTurretRubble'] = 65, ['HA_AP_Chains_Long'] = 65, ['HA_AP_OrderCloth'] = 65, ['HA_AP_PeriphBridge'] = 65, ['HA_AP_BridgeLaneStatue'] = 65, ['HA_AP_ChaosTurretRubble'] = 88.4, ['HA_AP_BannerMidBridge'] = 65, ['HA_AP_PoroSpawner'] = 50.0, ['HA_AP_Cutaway'] = 65, ['HA_AP_Chains'] = 65, ['HA_AP_ShpSouth'] = 65, ['HA_AP_HeroTower'] = 65, ['HA_AP_ShpNorth'] = 65, ['ChaosInhibitor_D'] = 65, ['ZacRebirthBloblet'] = 65, ['OrderInhibitor_D'] = 65, ['Nidalee_Spear'] = 65, ['Nidalee_Cougar'] = 65, ['TT_Buffplat_Chain'] = 65, ['WriggleLantern'] = 1, ['TwistedLizardElder'] = 65.0, ['RabidWolf'] = 65.0, ['HeimerTGreen'] = 50.0, ['HeimerTRed'] = 50.0, ['ViktorFF'] = 65, ['TwistedGolem'] = 80.0, ['TwistedSmallWolf'] = 50.0, ['TwistedGiantWolf'] = 65.0, ['TwistedTinyWraith'] = 50.0, ['TwistedBlueWraith'] = 50.0, ['TwistedYoungLizard'] = 50.0, ['Red_Minion_Melee'] = 48.0, ['Blue_Minion_Melee'] = 48.0, ['Blue_Minion_Healer'] = 48.0, ['Ghast'] = 60.0, ['blueDragon'] = 100.0, ['Red_Minion_MechRange'] = 65.0, ['Test_CubeSphere'] = 65,}
	return (hitboxTable[object.charName] ~= nil and hitboxTable[object.charName] ~= 0) and hitboxTable[object.charName]  or 65
end

function VPrediction:GetPathFindingRadius(object)
	local pfTable = {['RecItemsCLASSIC'] = 35, ['TeemoMushroom'] = 31.7931, ['TestCubeRender'] = 1, ['Xerath'] = 35, ['Kassadin'] = 35, ['Rengar'] = 35, ['Thresh'] = 36.000, ['RecItemsTUTORIAL'] = 35, ['Ziggs'] = 30, ['ZyraPassive'] = 8.5, ['ZyraThornPlant'] = 8.5, ['KogMaw'] = 30.0000, ['HeimerTBlue'] = 1, ['EliseSpider'] = 35, ['Skarner'] = 50, ['ChaosNexus'] = 35, ['Katarina'] = 35, ['Riven'] = 35, ['SightWard'] = 5, ['HeimerTYellow'] = 1, ['Ashe'] = 35, ['VisionWard'] = 5, ['TT_NGolem2'] = 24.5747, ['ThreshLantern'] = 45.000, ['RecItemsCLASSICMap10'] = 35, ['RecItemsODIN'] = 35, ['TT_Spiderboss'] = 200, ['RecItemsARAM'] = 35, ['OrderNexus'] = 35, ['Soraka'] = 44.2, ['Jinx'] = 35.000, ['TestCubeRenderwCollision'] = 80, ['Red_Minion_Wizard'] = 35.7437, ['JarvanIV'] = 35, ['Blue_Minion_Wizard'] = 35.7437, ['TT_ChaosTurret2'] = 88.4, ['TT_ChaosTurret3'] = 88.4, ['TT_ChaosTurret1'] = 88.4, ['ChaosTurretGiant'] = 88.4, ['Dragon'] = 35.8736, ['LuluSnowman'] = 31.5208, ['Worm'] = 31.5208, ['ChaosTurretWorm'] = 88.4, ['TT_ChaosInhibitor'] = 35, ['ChaosTurretNormal'] = 88.4, ['AncientGolem'] = 31.5208, ['ZyraGraspingPlant'] = 8.5, ['HA_AP_OrderTurret3'] = 88.4, ['HA_AP_OrderTurret2'] = 88.4, ['Tryndamere'] = 35, ['OrderTurretNormal2'] = 88.4, ['Singed'] = 35, ['OrderInhibitor'] = 35, ['Diana'] = 35, ['HA_FB_HealthRelic'] = 35, ['TT_OrderInhibitor'] = 35, ['GreatWraith'] = 40, ['Yasuo'] = 32.0, ['OrderTurretDragon'] = 88.4, ['OrderTurretNormal'] = 88.4, ['LizardElder'] = 31.5208, ['HA_AP_ChaosTurret'] = 88.4, ['Ahri'] = 35, ['Lulu'] = 30, ['ChaosInhibitor'] = 35, ['HA_AP_ChaosTurret3'] = 88.4, ['HA_AP_ChaosTurret2'] = 88.4, ['ChaosTurretWorm2'] = 88.4, ['TT_OrderTurret1'] = 88.4, ['TT_OrderTurret2'] = 88.4, ['TT_OrderTurret3'] = 88.4, ['LuluFaerie'] = 35, ['HA_AP_OrderTurret'] = 88.4, ['OrderTurretAngel'] = 88.4, ['YellowTrinketUpgrade'] = 5, ['MasterYi'] = 35, ['Lissandra'] = 35.0, ['ARAMOrderTurretNexus'] = 88.4, ['Draven'] = 35, ['FiddleSticks'] = 35, ['SmallGolem'] = 24.5747, ['ARAMOrderTurretFront'] = 88.4, ['ChaosTurretTutorial'] = 88.4, ['NasusUlt'] = 50, ['Maokai'] = 50, ['Wraith'] = 24.5747, ['Wolf'] = 31.5208, ['Sivir'] = 35, ['Corki'] = 35, ['Janna'] = 35, ['Nasus'] = 50, ['Golem'] = 24.5747, ['ARAMChaosTurretFront'] = 88.4, ['ARAMOrderTurretInhib'] = 88.4, ['LeeSin'] = 35, ['HA_AP_ChaosTurretTutorial'] = 88.4, ['GiantWolf'] = 31.5208, ['HA_AP_OrderTurretTutorial'] = 88.4, ['YoungLizard'] = 31.5208, ['Jax'] = 35, ['LesserWraith'] = 31.5208, ['Blitzcrank'] = 50, ['brush_D_SR'] = 35, ['brush_E_SR'] = 35, ['brush_F_SR'] = 35, ['brush_C_SR'] = 35, ['brush_A_SR'] = 35, ['brush_B_SR'] = 35, ['ARAMChaosTurretInhib'] = 88.4, ['Shen'] = 35, ['Nocturne'] = 35, ['Sona'] = 35, ['ARAMChaosTurretNexus'] = 88.4, ['YellowTrinket'] = 5, ['OrderTurretTutorial'] = 88.4, ['Caitlyn'] = 35, ['Trundle'] = 25.7666, ['Malphite'] = 50, ['Mordekaiser'] = 50, ['ZyraSeed'] = 54.4, ['Vi'] = 35, ['Tutorial_Red_Minion_Wizard'] = 35.7437, ['Renekton'] = 50.0000, ['Anivia'] = 35, ['Fizz'] = 30, ['Heimerdinger'] = 30.5444, ['Evelynn'] = 35, ['Rumble'] = 50, ['Leblanc'] = 35, ['Darius'] = 25.7666, ['OlafAxe'] = 1, ['Viktor'] = 35, ['XinZhao'] = 35, ['Orianna'] = 35, ['Vladimir'] = 35, ['Nidalee'] = 35, ['Tutorial_Red_Minion_Basic'] = 35.7437, ['ZedShadow'] = 35, ['Syndra'] = 35, ['Zac'] = 43.0749, ['Olaf'] = 35, ['Veigar'] = 30, ['Twitch'] = 35, ['Alistar'] = 50, ['Akali'] = 35, ['Urgot'] = 50, ['Leona'] = 35, ['Talon'] = 35, ['Karma'] = 35, ['Jayce'] = 35, ['Galio'] = 50, ['Shaco'] = 35, ['Taric'] = 35, ['TwistedFate'] = 35, ['Varus'] = 35, ['Garen'] = 35, ['Swain'] = 35, ['Vayne'] = 35, ['Fiora'] = 35, ['Quinn'] = 35, ['Kayle'] = 35, ['Blue_Minion_Basic'] = 35.7437, ['Brand'] = 35, ['Teemo'] = 30, ['Amumu'] = 30, ['Annie'] = 30, ['Odin_Blue_Minion_caster'] = 35.7437, ['Elise'] = 35, ['Nami'] = 35, ['Poppy'] = 35, ['AniviaEgg'] = 54.4, ['Tristana'] = 30, ['Graves'] = 35, ['Morgana'] = 35, ['Gragas'] = 50, ['MissFortune'] = 35, ['Warwick'] = 35, ['Cassiopeia'] = 35, ['Tutorial_Blue_Minion_Wizard'] = 35.7437, ['DrMundo'] = 50, ['Volibear'] = 50.0000, ['Irelia'] = 35, ['Odin_Red_Minion_Caster'] = 35.7437, ['Lucian'] = 40.68, ['Yorick'] = 50, ['RammusPB'] = 35.0000, ['Red_Minion_Basic'] = 35.7437, ['Udyr'] = 35, ['MonkeyKing'] = 35, ['Tutorial_Blue_Minion_Basic'] = 35.7437, ['Kennen'] = 30, ['Nunu'] = 35, ['Ryze'] = 35, ['Zed'] = 35, ['Nautilus'] = 50, ['Gangplank'] = 35, ['shopevo'] = 35, ['Lux'] = 35, ['Sejuani'] = 50, ['Ezreal'] = 35, ['OdinNeutralGuardian'] = 120.000, ['Khazix'] = 35, ['Sion'] = 50, ['Aatrox'] = 35.0, ['Hecarim'] = 50, ['Pantheon'] = 35, ['Shyvana'] = 35, ['Zyra'] = 35, ['Karthus'] = 35, ['Rammus'] = 35.000, ['Zilean'] = 35, ['Chogath'] = 50, ['Malzahar'] = 35, ['YorickRavenousGhoul'] = 35, ['YorickSpectralGhoul'] = 35, ['JinxMine'] = 35, ['YorickDecayedGhoul'] = 35, ['XerathArcaneBarrageLauncher'] = 1, ['Odin_SOG_Order_Crystal'] = 44.2, ['TestCube'] = 1, ['ShyvanaDragon'] = 50, ['FizzBait'] = 35, ['ShopKeeper'] = 35, ['Blue_Minion_MechMelee'] = 55.5208, ['OdinQuestBuff'] = 1, ['TT_Buffplat_L'] = 35, ['TT_Buffplat_R'] = 35, ['KogMawDead'] = 30.0000, ['TempMovableChar'] = 38.08, ['Lizard'] = 31.5208, ['GolemOdin'] = 24.5747, ['OdinOpeningBarrier'] = 1, ['TT_ChaosTurret4'] = 240, ['TT_Flytrap_A'] = 44.2, ['TT_Chains_Order_Periph'] = 35, ['TT_NWolf'] = 31.5208, ['ShopMale'] = 35, ['OdinShieldRelic'] = 35, ['TT_Chains_Xaos_Base'] = 35, ['LuluSquill'] = 31.5208, ['TT_Shopkeeper'] = 35, ['redDragon'] = 35, ['MonkeyKingClone'] = 35, ['Odin_skeleton'] = 44.2, ['OdinChaosTurretShrine'] = 88.4, ['Cassiopeia_Death'] = 40.8, ['OdinCenterRelic'] = 38.08, ['Ezreal_cyber_1'] = 35, ['Ezreal_cyber_3'] = 35, ['Ezreal_cyber_2'] = 35, ['OdinRedSuperminion'] = 45.5208, ['TT_Speedshrine_Gears'] = 35, ['JarvanIVWall'] = 90, ['DestroyedNexus'] = 35, ['ARAMOrderNexus'] = 35, ['Red_Minion_MechCannon'] = 55.7437, ['OdinBlueSuperminion'] = 45.5208, ['SyndraOrbs'] = 35, ['LuluKitty'] = 31.5208, ['SwainNoBird'] = 35, ['LuluLadybug'] = 31.5208, ['CaitlynTrap'] = 35, ['TT_Shroom_A'] = 44.2, ['ARAMChaosTurretShrine'] = 88.4, ['Odin_Windmill_Propellers'] = 44.2, ['DestroyedInhibitor'] = 35, ['TT_NWolf2'] = 31.5208, ['OdinMinionGraveyardPortal'] = 1, ['SwainBeam'] = 40.8, ['Summoner_Rider_Order'] = 35, ['TT_Relic'] = 35, ['odin_lifts_crystal'] = 44.2, ['OdinOrderTurretShrine'] = 88.4, ['SpellBook1'] = 35.36, ['Blue_Minion_MechCannon'] = 55.7437, ['TT_ChaosInhibitor_D'] = 35, ['Odin_SoG_Chaos'] = 44.2, ['TrundleWall'] = 150, ['HA_AP_HealthRelic'] = 35, ['OrderTurretShrine'] = 88.4, ['OriannaBall'] = 35, ['ChaosTurretShrine'] = 88.4, ['LuluCupcake'] = 31.5208, ['HA_AP_ChaosTurretShrine'] = 240, ['TT_Chains_Bot_Lane'] = 35, ['TT_NWraith2'] = 31.5208, ['TT_Tree_A'] = 44.2, ['SummonerBeacon'] = 13.6, ['Odin_Drill'] = 44.2, ['TT_NGolem'] = 24.5747, ['Shop'] = 35, ['AramSpeedShrine'] = 1, ['DestroyedTower'] = 35, ['OriannaNoBall'] = 35, ['Odin_Minecart'] = 44.2, ['Summoner_Rider_Chaos'] = 35, ['OdinSpeedShrine'] = 1, ['TT_Brazier'] = 35, ['TT_SpeedShrine'] = 1, ['odin_lifts_buckets'] = 44.2, ['OdinRockSaw'] = 44.2, ['OdinMinionSpawnPortal'] = 1, ['SyndraSphere'] = 130.0000, ['TT_Nexus_Gears'] = 35, ['Red_Minion_MechMelee'] = 55.5208, ['SwainRaven'] = 35, ['crystal_platform'] = 35, ['MaokaiSproutling'] = 38.08, ['Urf'] = 35.8736, ['TestCubeRender10Vision'] = 1, ['MalzaharVoidling'] = 20.0, ['GhostWard'] = 5, ['MonkeyKingFlying'] = 35, ['LuluPig'] = 31.5208, ['AniviaIceBlock'] = 100, ['TT_OrderInhibitor_D'] = 35, ['yonkey'] = 35, ['Odin_SoG_Order'] = 44.2, ['RammusDBC'] = 35, ['FizzShark'] = 35, ['LuluDragon'] = 31.5208, ['OdinTestCubeRender'] = 1, ['OdinCrane'] = 35, ['TT_Tree1'] = 44.2, ['ARAMOrderTurretShrine'] = 88.4, ['TT_Chains_Order_Base'] = 35, ['Odin_Windmill_Gears'] = 44.2, ['ARAMChaosNexus'] = 35, ['TT_NWraith'] = 24.5747, ['TT_OrderTurret4'] = 240, ['Odin_SOG_Chaos_Crystal'] = 44.2, ['TT_SpiderLayer_Web'] = 35, ['OdinQuestIndicator'] = 1, ['JarvanIVStandard'] = 13.6, ['TT_DummyPusher'] = 1, ['OdinClaw'] = 35, ['EliseSpiderling'] = 1.0, ['QuinnValor'] = 35, ['UdyrTigerUlt'] = 36.68, ['UdyrTurtleUlt'] = 36.68, ['UdyrUlt'] = 36.68, ['UdyrPhoenixUlt'] = 36.68, ['ShacoBox'] = 1, ['HA_AP_Poro'] = 31.5208, ['AnnieTibbers'] = 50, ['UdyrPhoenix'] = 35, ['UdyrTurtle'] = 35, ['UdyrTiger'] = 35, ['HA_AP_OrderShrineTurret'] = 240, ['HA_AP_OrderTurretRubble'] = 35, ['HA_AP_Chains_Long'] = 35, ['HA_AP_OrderCloth'] = 35, ['HA_AP_PeriphBridge'] = 35, ['HA_AP_BridgeLaneStatue'] = 35, ['HA_AP_ChaosTurretRubble'] = 88.4, ['HA_AP_BannerMidBridge'] = 35, ['HA_AP_PoroSpawner'] = 31.5208, ['HA_AP_Cutaway'] = 35, ['HA_AP_Chains'] = 35, ['HA_AP_ShpSouth'] = 35, ['HA_AP_HeroTower'] = 35, ['HA_AP_ShpNorth'] = 35, ['ChaosInhibitor_D'] = 35, ['ZacRebirthBloblet'] = 54.4, ['OrderInhibitor_D'] = 35, ['Nidalee_Spear'] = 35, ['Nidalee_Cougar'] = 35, ['TT_Buffplat_Chain'] = 35, ['WriggleLantern'] = 5, ['TwistedLizardElder'] = 31.5208, ['RabidWolf'] = 31.5208, ['HeimerTGreen'] = 1, ['HeimerTRed'] = 1, ['ViktorFF'] = 35.8736, ['TwistedGolem'] = 24.5747, ['TwistedSmallWolf'] = 31.5208, ['TwistedGiantWolf'] = 31.5208, ['TwistedTinyWraith'] = 31.5208, ['TwistedBlueWraith'] = 24.5747, ['TwistedYoungLizard'] = 31.5208, ['Red_Minion_Melee'] = 35.7437, ['Blue_Minion_Melee'] = 35.7437, ['Blue_Minion_Healer'] = 35.7437, ['Ghast'] = 24.5747, ['blueDragon'] = 35.8736, ['Red_Minion_MechRange'] = 35.7437, ['Test_CubeSphere'] = 35} 	
	return (pfTable[object.charName] ~= nil and pfTable[object.charName] ~= 0) and pfTable[object.charName]  or 35 
end
--}

--UPDATEURL=
--HASH=6F96B221F7BD5305C2969ABD24B93F00
