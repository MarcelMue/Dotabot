STATE_IDLE = "STATE_IDLE"
STATE_MOVE_TO_MID = "STATE_MOVE_TO_MID"
STATE_FARM_LANE = "STATE_FARM_LANE"
STATE_ATTACKING_CAMP = "STATE_ATTACKING_CAMP"
STATE_RUN_FROM_CREEPS = "STATE_RUN_FROM_CREEPS"

local state = STATE_IDLE
local bot = GetBot()
local previousstate = STATE_IDLE

function Think()
  if(state ~= previousstate) then
    --bot:Action_Chat(state,true)
    previousstate = state
  end
  Consider()
end

function Consider()
  if(not bot:IsAlive()) then
    state = STATE_IDLE
    return
  end
  if(state == STATE_IDLE) then
    move_mid()
  end
  if(state == STATE_MOVE_TO_MID) then
    move_mid()
  end
  if(state == STATE_FARM_LANE) then
    farm_mid()
  end
  if(state == STATE_RUN_FROM_CREEPS) then
    run_from_creeps()
  end
end

function move_mid()

  if(DotaTime() < 20) then
    bot:Action_MoveToLocation(Vector(-1663,-1510))
    state = STATE_MOVE_TO_MID
    return
  end

  local creepos = bot:GetNearbyCreeps( bot:GetAttackRange() + 200, true )
  if(creepos[1] == nil) then
    bot:Action_MoveToLocation(Vector(7137,6548))
    state = STATE_MOVE_TO_MID
  else
    if(get_closest_creep_dist(bot,creepos) < 300) then
      state = STATE_FARM_LANE
      bot:Action_ClearActions(true)
    else
      bot:Action_MoveToUnit(get_closest_creep(bot,creepos))
      state = STATE_MOVE_TO_MID
    end
  end
end

function run_from_creeps()
  local creepos = bot:GetNearbyCreeps( bot:GetAttackRange() + 200, true )
  if(creepos[1] ~= nil and get_closest_creep_dist(bot,creepos) < 300) then
    bot:Action_MoveToLocation(Vector(-7200,-6666))
    state = STATE_RUN_FROM_CREEPS
  else
    state = STATE_FARM_LANE
    bot:Action_ClearActions(true)
  end
end

function farm_mid()
  local creeps = bot:GetNearbyCreeps( bot:GetAttackRange() + 300 , true )
  local weakest_creep
  local lowest_hp = 1000
  local safety = 10
  local enemy_alive_counter = 0
  local closest_enemy_distance = 2000


  for creep_k,creep in pairs(creeps) do
    if(creep:IsAlive()) then
      enemy_alive_counter = enemy_alive_counter + 1
      local creep_hp = creep:GetHealth()
      local creep_distance = GetUnitToUnitDistance(bot,creep)
      --schätze den damage output, mit safety für damage der vielleicht kommt
      local damage_output = creep:GetActualDamage(bot:GetBaseDamage(),DAMAGE_TYPE_PHYSICAL)
                            + safety
                            + bot:GetAttackPoint() / (1 + bot:GetAttackSpeed())
                            + GetUnitToUnitDistance(bot,creep) / 1200

      if(lowest_hp > creep_hp and damage_output > creep_hp) then
        lowest_hp = creep_hp
        weakest_creep = creep
      end
      if(creep_distance < closest_enemy_distance) then
        closest_enemy_distance = creep_distance
      end
    end
  end
  --Kann ich ein creep sofort töten? Direkt hitten
  if(weakest_creep ~= nil) then
    --bot:Action_Chat('hit creepo',true)
    bot:Action_AttackUnit(weakest_creep,true)
    return
  end

  if(enemy_alive_counter > 0 and closest_enemy_distance < 300) then
    state = STATE_RUN_FROM_CREEPS
    return
  end

  if(enemy_alive_counter == 0 or closest_enemy_distance > 500) then
    state = STATE_MOVE_TO_MID
    return
  end
end


function get_closest_creep_dist(bot, creepos)
  local closest_creepo = 100000
  for creep_k,creepo in pairs(creepos) do
    if(GetUnitToUnitDistance(bot,creepo) < closest_creepo and creepo:IsAlive()) then
      closest_creepo = GetUnitToUnitDistance(bot,creepo)
    end
  end
  return closest_creepo
end

function get_closest_creep(bot, creepos)
  local closest_creepo = 100000
  local c_creepo
  for creep_k,creepo in pairs(creepos) do
    if(GetUnitToUnitDistance(bot,creepo) < closest_creepo and creepo:IsAlive()) then
      closest_creepo = GetUnitToUnitDistance(bot,creepo)
      c_creepo = creepo
    end
  end
  return creepo
end
