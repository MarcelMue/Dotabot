local bot = GetBot()

function Think()
    --bot:Action_MoveToLocation(Vector(-1663,-1510))
    farm(Vector(0,0), 1000)
end

function GetEnemyCreeps()
    return bot:GetNearbyCreeps(1600, true)
end

function farm(pos, radius)
    -- move to area
    if(GetUnitToLocationDistance(bot, pos) > radius) then
        bot:Action_MoveToLocation(pos)
    end

    count = 0
    for key,creep in pairs(GetEnemyCreeps()) do
        count = count + 1
    end

    bot:Action_Chat(string.format("%d", count),true)
end
