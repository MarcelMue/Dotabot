--Settings----------------------------------------------------------------------
-- Verbosity of the Logs: 0 no logs, 1 errors, 2 warnings, 3 debug logs
local LogVerbosity = 3

--Init--------------------------------------------------------------------------
local bot = GetBot()

--Util--------------------------------------------------------------------------
function GetEnemyCreeps()
    return bot:GetNearbyCreeps(1600, true)
end

function GetCreeps()
    return bot:GetNearbyCreeps(1600, false)
end

function GetEnemyTowers()
    return bot:GetNearbyTowers(1600, true)
end

function GetEnemyTeam()
    if(GetTeam() == TEAM_RADIANT) then
        return TEAM_DIRE
    else
        return TEAM_RADIANT
    end
end

function CDOTA_Bot_Script:Log(triviality, message)
    if(triviality <= LogVerbosity) then
        self:Action_Chat(message, true)
        print('Lina: ' ..  message)
    end
end


function get_closest_creep(creeps)
  local closest_creepo = 100000
  local c_creepo = nil
  for creep_k,creepo in pairs(creeps) do
    if(GetUnitToUnitDistance(bot,creepo) < closest_creepo and creepo:IsAlive()) then
      closest_creepo = GetUnitToUnitDistance(bot,creepo)
      c_creepo = creepo
    end
  end
  return c_creepo, closest_creepo
end

local home = GetAncient( GetTeam() ):GetLocation()
local mid = Vector(-500, -250)
local enemy = GetAncient( GetEnemyTeam() ):GetLocation()

--States------------------------------------------------------------------------

local _state = nil
function GetState()
    return _state
end

function SetState(x)
    bot:Action_ClearActions(true)
    _state = x
    _state.OnEnter()
end

function ThinkState()
    _state.OnThink()
end

--------------------------------------------------------------------------------


local STATE_IDLE = nil
local STATE_MOVE_TO_ENEMY = nil
local STATE_ATTACK = nil
local STATE_FLEE = nil

STATE_IDLE = {
    OnEnter = function()
    end,

    OnThink = function()
        if(not bot:IsAlive()) then
            return
        end

        local creep, cdist = get_closest_creep(GetEnemyCreeps())

        if (creep == nil) then
            SetState(STATE_MOVE_TO_ENEMY)
            bot:Log(3, "Rambo Engaged")
            return
        end


        if(creep ~= nil) then
            SetState(STATE_ATTACK)
            bot:Log(3, "Dodge this blyat")
            return
        end
    end
}

STATE_MOVE_TO_ENEMY = {
    OnEnter = function()
        bot:Action_MoveToLocation(enemy)
    end,

    OnThink = function()
        bot:Action_MoveToLocation(enemy)

        local creep, cdist = get_closest_creep(GetEnemyCreeps())
        local tower, tdist = get_closest_creep(GetEnemyTowers())

        if (tower ~= nil) and (tdist < tower:GetAttackRange()+300) then
            SetState(STATE_FLEE)
            bot:Log(3, "Nope nope nope")
            return
        end

        if(creep ~= nil) then
            SetState(STATE_ATTACK)
            bot:Log(3, "peekaboo!")
            return
        end

    end
}

STATE_ATTACK = {
    target = nil,

    OnEnter = function()
        local creep, dist = get_closest_creep(GetEnemyCreeps())
        if(creep ~= nil) then
            bot:Action_AttackUnit(creep,true)
            STATE_ATTACK.target = creep
        else
            STATE_ATTACK.target = nil
        end
    end,

    OnThink = function()
        local creep, cdist = get_closest_creep(GetEnemyCreeps())
        local tower, tdist = get_closest_creep(GetEnemyTowers())

        if(STATE_ATTACK.target == nil) then
            SetState(STATE_IDLE)
            bot:Log(3, "No Target")
            return
        end
        if (STATE_ATTACK.target ~= nil) and (not STATE_ATTACK.target:IsAlive()) then
            SetState(STATE_ATTACK)
            --bot:Log(3, "RIP in Pieces")
            return
        end

        if(tower ~= nil) and (tdist < tower:GetAttackRange()+200) then
            SetState(STATE_FLEE)
            bot:Log(3, "Too deep")
            return
        end

        if(creep ~= nil) and (cdist < bot:GetAttackRange() * 0.5) then
            SetState(STATE_FLEE)
            bot:Log(3, "Argh HAAAALP")
            return
        end
    end
}

STATE_FLEE = {
    OnEnter = function()
        bot:Action_MoveToLocation(home)
    end,

    OnThink = function()
        bot:Action_MoveToLocation(home)
        local creep, cdist = get_closest_creep(GetEnemyCreeps())
        local tower, tdist = get_closest_creep(GetEnemyTowers())

        if (creep == nil) and (tower == nil) then
            SetState(STATE_IDLE)
            bot:Log(3, "Out of my eyes out of my mind")
            return
        end

        local tower_threat = (tower ~= nil ) and (tdist < tower:GetAttackRange()+bot:GetAttackRange())
        local creep_threat = (creep ~= nil) and (cdist < bot:GetAttackRange())

        if (not tower_threat) and (not creep_threat) then
            SetState(STATE_IDLE)
            bot:Log(3, "Get baited kn0ob")
            return
        end
    end
}



--Think-------------------------------------------------------------------------
bot:Action_Chat("Im going to rape u sf xaxaxaaxaxa", true)
SetState(STATE_IDLE)
function Think()
    --Debug
    local count = 0
    for key, value in pairs(GetCreeps()) do
        count = count +  1
    end
    --bot:Action_Chat(string.format("%d", count),true)

    --Interrupts
    if(not bot:IsAlive()) then
        SetState(STATE_IDLE)
        return
    end

    --Run State Think
    ThinkState()


end



--depricated--------------------------------------------------------------------



function farm(pos, radius)
    -- move to area
    if(GetUnitToLocationDistance(bot, pos) > radius) then
        bot:Action_MoveToLocation(pos)
    else
        bot:Action_ClearActions(true)
    end

    -- keep creep distance
    creep, dist = get_closest_creep(GetEnemyCreeps())
    if( dist < bot:GetAttackRange()) then
        bot:Action_ClearActions(true)
        bot:Action_MoveToLocation(home)
    end

    local count = 0
    for key,creep in pairs(GetEnemyCreeps()) do
        if(creep:IsAlive()) then
            count = count + 1
        end
    end
    -- debug
    --DebugDrawCircle(pos, radius, 0, 1, 0)
    DebugDrawLine( bot:GetLocation(), pos, 0, 255, 0 )
    DebugDrawLine( bot:GetLocation(), home, 0, 0, 255 )
    bot:Action_Chat(string.format("%d", bot:GetRespawnTime()),true)
    --bot:Action_Chat(string.format("%d / %d", 0, 0),true)
end
