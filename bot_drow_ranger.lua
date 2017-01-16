--[[ bot_axe.lua

function Think()

    local bot = GetBot();

    if(bot:DistanceFromFountain() < 750) then
      bot:Action_AttackMove(Vector(1002,330));
    end

end]]
function Think()
end
