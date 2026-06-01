local res =
    require('resources')

local spell_data =
    require('data/spells')

local ability_data =
    require('data/abilities')

local actiontracker = {}

local pending_actions = {}

-- GC stale entries: anything older than PENDING_TTL gets cleared.
-- Without this, mobs you never re-target after casting on them leak
-- their pending entry until the addon reloads.
local PENDING_TTL = 10
local PENDING_GC_INTERVAL = 30
local last_gc_clock = 0

local function gc_pending(now)

    if now - last_gc_clock < PENDING_GC_INTERVAL then
        return
    end

    last_gc_clock = now

    for target_id, pending in pairs(pending_actions) do
        if now - pending.created_at > PENDING_TTL then
            pending_actions[target_id] = nil
        end
    end

end

-- TRACK ACTION
local function track_action(action)

    local actor_id =
        action.actor_id

    local category =
        action.category

    local targets =
        action.targets

    if not targets then
        return
    end

    for _, target in pairs(targets) do

        local actions =
            target.actions

        if actions then

            for _, act in pairs(actions) do

                local action_id =
                    act.param

                local action_info = nil
                local action_name = nil
                local action_type = nil

                -- SPELLS
                if category == 8 then

                    action_info =
                        spell_data[action_id]

                    local spell =
                        res.spells[action_id]

                    action_name =
                        spell and spell.en
                        or tostring(action_id)

                    action_type = 'spell'

                -- JOB ABILITIES
                elseif category == 6 then

                    action_info =
                        ability_data[action_id]

                    local ability =
                        res.job_abilities[action_id]

                    action_name =
                        ability and ability.en
                        or tostring(action_id)

                    action_type = 'ability'

                end

                if action_name then

                    pending_actions[target.id] = {

                        actor_id = actor_id,

                        target_id = target.id,

                        action_id = action_id,

                        action_name = action_name,

                        action_type = action_type,

                        action_info = action_info,

                        created_at =
                            os.clock(),

                    }

                   
                end

            end

        end

    end

end

-- REGISTER EVENT
windower.register_event(
    'action',
    track_action
)

-- GET PENDING ACTION
function actiontracker.get_pending(target_id)

    local now = os.clock()

    gc_pending(now)

    local pending =
        pending_actions[target_id]

    if not pending then
        return nil
    end

    -- EXPIRE OLD PENDING
    if now - pending.created_at > PENDING_TTL then

        pending_actions[target_id] = nil

        return nil

    end

    return pending

end

-- CLEAR PENDING ACTION
function actiontracker.clear_pending(target_id)

    pending_actions[target_id] = nil

end

return actiontracker