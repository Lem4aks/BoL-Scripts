require 'Prodiction'

class 'VPrediction' -- {

function VPrediction:__init()
        return self
end

function VPrediction:GetPredictedHealth(unit, time, delay)
	return Prodiction.GetPredictedHealthTime(unit, time)
end

function VPrediction:IsImmobile(unit, delay, radius, speed, from, spelltype)
	return Prodiction.IsImmobile(unit, radius, speed, delay, 2, from)
end

function VPrediction:IsDashing(unit, delay, radius, speed, from)
	return Prodiction.IsDashing(unit, radius, speed, delay, 2, from)
end

function VPrediction:GetCircularAOECastPosition(unit, delay, radius, range, speed, from, collision)
	local pos, info = Prodiction.GetCircularAOEPrediction(unit, range, speed, delay, radius, from)
	return pos, info.hitchance
end

function VPrediction:GetLineCastPosition(unit, delay, radius, range, speed, from, collision)
	local pos, info = Prodiction.GetLineAOEPrediction(unit, range, speed, delay, radius, from)
	return pos, info.hitchance
end

function VPrediction:GetPredictedPos(unit, delay, speed, from, collision)
	local pos, info = Prodiction.GetTimeProdiction(unit, delay)
	return pos, info.hitchance
end

-- }