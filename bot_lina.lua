--Settings----------------------------------------------------------------------
-- Verbosity of the Logs: 0 no logs, 1 errors, 2 warnings, 3 debug logs
local LogVerbosity = 3

--Init--------------------------------------------------------------------------
local bot = GetBot()

--Util--------------------------------------------------------------------------
local M = {}
M["creeps"] = {}
M["hp_buf_pos"] = 0
M["hp_buf_size"] = 30
function M:AddCreep(creep, bFriendly)
    if self["creeps"][creep] == nil then
        self["creeps"][creep] = {}
        self["creeps"][creep]["friendly"] = bFriendly
        self["creeps"][creep]["hp_buf"] = {}
        for i=0,M["hp_buf_size"]-1 do
            self["creeps"][creep]["hp_buf"][i] = {hp=creep:GetHealth(), time=GameTime()}
        end
    end
end
function M:UpdateCreeps()
    local pos_cur = self["hp_buf_pos"]
    local pos_lst = (self["hp_buf_pos"] + 1 ) % M["hp_buf_size"]

    for creep,data in pairs(self["creeps"]) do
        data["hp_buf"][pos_cur] = {hp=creep:GetHealth(), time=GameTime()}
    end
    self["hp_buf_pos"] = (self["hp_buf_pos"] + 1 ) % M["hp_buf_size"]
end

function M:GetCreeps()
    res = {}
    for creep, data in pairs(self["creeps"]) do
        res[#res+1] = creep
    end
    return res
end

function M:GetEnemyCreeps()
    res = {}
    for creep, data in pairs(self["creeps"]) do
        if( not data["friendly"]) then
            res[#res+1] = creep
        end
    end
    return res
end

function M:GetFriendlyCreeps()
    res = {}
    for creep, data in pairs(self["creeps"]) do
        if(data["friendly"]) then
            res[#res+1] = creep
        end
    end
    return res
end

function M:GetCreeps()
    res = {}
    for creep, data in pairs(self["creeps"]) do
        res[#res+1] = creep
    end
    return res
end

function M:EstimateCreepHealthDeltaPerSec(creep)
    local pos_cur = (self["hp_buf_pos"] - 1 ) % M["hp_buf_size"]
    local pos_lst = self["hp_buf_pos"]
    local data = self["creeps"][creep]["hp_buf"]

    local delta_hp = data[pos_cur]["hp"] - data[pos_lst]["hp"]
    local delta_time = data[pos_cur]["time"] - data[pos_lst]["time"]

    if(delta_time == 0) then
        return 0
    end

    return (delta_hp / delta_time)
end

function M:GCCreeps()
    for creep,data in pairs(self["creeps"]) do
        if(not creep:IsAlive()) then
            self["creeps"][creep] = nil
        end
    end
end
--------------------------------------------------------------------------------
function GetEnemyCreeps()
    return bot:GetNearbyCreeps(1600, true)
end

function GetFriendlyCreeps()
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

function CDOTA_Bot_Script:Action_MoveDelta(vec)
    bot:Action_MoveToLocation(self:GetLocation()+vec)
end

function GetThreat()
    local res = 0
    for key, creep in pairs(GetEnemyCreeps()) do
        if(GetUnitToUnitDistance( creep, bot ) < 300 or  GetUnitToUnitDistance( creep, bot ) < creep:GetAttackRange() ) then
            res = res + bot:GetActualDamage(creep:GetBaseDamage(),DAMAGE_TYPE_PHYSICAL)
        end
    end
    return res
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

function get_weakest_creep(creeps)
  local weakest_creepo = 100000
  local c_creepo = nil
  for creep_k,creepo in pairs(creeps) do
    if(GetUnitToUnitDistance(bot,creepo) < weakest_creepo and creepo:IsAlive()) then
      weakest_creepo = creepo:GetHealth()
      c_creepo = creepo
    end
  end
  return c_creepo, weakest_creepo
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
    if(x == nil) then
        bot:Log(2, "Tried to set invalid State")
    end

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
local STATE_LASTHIT = nil

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
            SetState(STATE_LASTHIT)
            bot:Log(3, "$$$ get rich $$$")
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
            SetState(STATE_IDLE)
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
            --bot:Log(3, "Get baited kn0ob")
            return
        end
    end
}

STATE_LASTHIT = {
    last_attack_time = 0,

    OnEnter = function()
        STATE_LASTHIT.last_attack_time = 0
    end,

    OnThink = function()
        --State Switches
        local creep, cdist = get_closest_creep(GetEnemyCreeps())
        local tower, tdist = get_closest_creep(GetEnemyTowers())

        if(creep == nil) then
            SetState(STATE_IDLE)
            return
        end

        if(tower ~= nil) and (tdist < tower:GetAttackRange()+200) then
            SetState(STATE_FLEE)
            bot:Log(3, "Too deep")
            return
        end

        if(creep ~= nil) and (cdist < 200) then
            SetState(STATE_FLEE)
            bot:Log(3, "Argh HAAAALP")
            return
        end

        --Find creep closest to ck time
        local ncreep = nil
        local ncreep_ck_time = 9999
        for key, creep in pairs(M:GetCreeps()) do
            --print(GameTime() - bot:GetLastAttackTime())
            local dmg = creep:GetActualDamage(bot:GetAttackDamage(),DAMAGE_TYPE_PHYSICAL) - bot:GetBaseDamageVariance()/2
            local creep_ck_time = 9999
            --is in ck range?
            if(creep:GetHealth()-dmg <= 0) then
                creep_ck_time = 0
            else
                --is getting dmg?
                if(M:EstimateCreepHealthDeltaPerSec(creep) < 0) then
                    creep_ck_time = (creep:GetHealth()-dmg) / M:EstimateCreepHealthDeltaPerSec(creep) * (-1)
                else
                    creep_ck_time = (creep:GetHealth()-dmg)
                end
            end


            if(creep_ck_time <= ncreep_ck_time) then
                ncreep = creep
                ncreep_ck_time = creep_ck_time
            end
        end
        if(ncreep == nil) then return end
        DebugDrawLine(ncreep:GetLocation(), bot:GetLocation(), 255,0,0)

        --Move in Attack Range of creep
        if(GetUnitToUnitDistance(bot,ncreep) > bot:GetAttackRange()) then
            local dir = ncreep:GetLocation() - bot:GetLocation()
            local dist = GetUnitToUnitDistance(bot,ncreep) - bot:GetAttackRange()

            --Only move shortly before ck
            local time = dist / bot:GetCurrentMovementSpeed()
            if(ncreep_ck_time < time + 3) then
                bot:Action_MoveDelta(dir:Normalized()*dist)
            end
        end
        --Try Last Hitting
        local safety = 3
        local dmg = ncreep:GetActualDamage(bot:GetAttackDamage(),DAMAGE_TYPE_PHYSICAL) - bot:GetBaseDamageVariance()/2 - safety
        local atk_time = bot:GetAttackPoint() / ( 1 + bot:GetAttackSpeed())
        local travel_time =  GetUnitToUnitDistance(bot,ncreep) / 1000
        local dmg_delay =  atk_time + travel_time
        local hp = ncreep:GetHealth() + M:EstimateCreepHealthDeltaPerSec(ncreep) * dmg_delay

        --only attack if in ck range AND doesnt cancle attack animation
        if(hp < dmg and hp > 0) and (GameTime() - STATE_LASTHIT.last_attack_time > atk_time) then
            bot:Action_AttackUnit(ncreep,true)
            STATE_LASTHIT.last_attack_time = GameTime()
        end

    end
}



--Think-------------------------------------------------------------------------
bot:Action_Chat("Im going to rape u sf xaxaxaaxaxa", true)
SetState(STATE_IDLE)
function Think()
    --Debug
    for key, value in pairs(GetEnemyCreeps()) do
        M:AddCreep(value, false)
    end
    for key, value in pairs(GetFriendlyCreeps()) do
        M:AddCreep(value, true)
    end
    M:GCCreeps()
    M:UpdateCreeps()
    --bot:Action_Chat(string.format("%d", count),true)
    --bot:Action_Chat(string.format("%d", GetThreat()),true)



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
