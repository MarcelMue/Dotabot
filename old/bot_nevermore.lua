STATE_IDLE = "STATE_IDLE"
STATE_MOVE_TO_MID = "STATE_MOVE_TO_MID"
STATE_FARM_LANE = "STATE_FARM_LANE"
STATE_ATTACKING_CAMP = "STATE_ATTACKING_CAMP"

local state = STATE_IDLE
local bot = GetBot()
local previousstate = STATE_IDLE

function Think()
  if(state ~= previousstate) then
    bot:Action_Chat(state,true)
    previousstate = state
  end
  bot:Action_Chat(string.format("%.2f", GameTime()), true)
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
end

function move_mid()

  if(DotaTime() < 20) then
    bot:Action_MoveToLocation(Vector(-1663,-1510))
    state = STATE_MOVE_TO_MID
    return
  end

  local creepos = bot:GetNearbyCreeps( bot:GetAttackRange(), true )
  if(creepos[1] == nil) then
    bot:Action_MoveToLocation(Vector(1002,330))
    state = STATE_MOVE_TO_MID
  else
    state = STATE_FARM_LANE
    bot:Action_ClearActions(true)
  end
end

function farm_mid()
  bot:Action_Chat('finding creepos', true)
  local creepos = bot:GetNearbyCreeps( bot:GetAttackRange(), true )
  bot:Action_Chat('found creepos',true)
  local weakest_creep
  bot:Action_Chat('hit creepo',true)
  local lowest_hp = bot:GetAttackDamage()
  bot:Action_Chat('hit creepo',true)
  for creep_k,creep in pairs(creepos) do
    if(creep:IsAlive()) then
      local creep_hp = creep:GetHealth()
      if(lowest_hp > creep_hp) then
        lowest_hp = creep_hp
        weakest_creep = creep
      end
    end
  end
  if(weakest_creep ~= nil) then
    bot:Action_Chat('hit creepo',true)
    bot:Action_AttackUnit(weakest_creep,true)
  end

end
