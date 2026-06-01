local actiontracker =
    require('systems/actiontracker')

local spellparser =
    require('systems/spellparser')

local res =
    require('resources')

local bufftracker = {}

local active_buffs = {}

local previous_buffs = {}

-- LOAD RUNTIME FILE
local function load_runtime()

    local path =
        windower.addon_path ..
        'data/runtime_buffs.lua'

    local chunk =
        loadfile(path)

    if not chunk then
        return {}
    end

    local success, data =
        pcall(chunk)

    if success and
       type(data) == 'table' then

        return data

    end

    return {}

end

-- SAVE RUNTIME
local function save_runtime()

    local path =
        windower.addon_path ..
        'data/runtime_buffs.lua'

    local file =
        io.open(path, 'w+')

    if not file then
        return
    end

    file:write('return {\n')

    for buff_id, buff in pairs(active_buffs) do

        file:write(string.format(
            '    [%d] = {\n',
            buff_id
        ))

        file:write(string.format(
            '        gained_at = %d,\n',
            buff.gained_at
        ))

        file:write(string.format(
            '        expires_at = %d,\n',
            buff.expires_at
        ))

        file:write(string.format(
            '        duration = %d,\n',
            buff.duration
        ))

        -- Use %q so quotes/backslashes in action names don't corrupt the file.
        file:write(string.format(
            '        source_action = %q,\n',
            buff.source_action or ''
        ))

        file:write('    },\n')

    end

    file:write('}')

    file:close()

end

-- Dirty flag: flush at most once per update tick, not per mutation.
local runtime_dirty = false

local function mark_dirty()
    runtime_dirty = true
end

local function flush_runtime()
    if runtime_dirty then
        save_runtime()
        runtime_dirty = false
    end
end

-- RESTORE RUNTIME
local function restore_runtime()

    local runtime_buffs =
        load_runtime()

    for buff_id, buff in pairs(runtime_buffs) do

        if buff.expires_at > os.time() then

            active_buffs[buff_id] = buff

        end

    end

end

-- CREATE OR REFRESH TIMER
local function track_buff(
    buff_id,
    duration,
    source_action
)

    if not duration then
        return
    end

    active_buffs[buff_id] = {

        gained_at = os.time(),

        expires_at =
            os.time() + duration,

        duration =
            duration,

        source_action =
            source_action,

    }

    mark_dirty()

end

-- UPDATE
function bufftracker.update()

    local player =
        windower.ffxi.get_player()

    if not player then
        return
    end

    -- Hoist invariants out of the player.buffs loop.
    local pending =
        actiontracker.get_pending(player.id)

    local parsed_buffs = nil

    if pending and pending.action_info then

        local parsed =
            spellparser.parse(pending.action_info)

        if parsed and parsed.buffs then
            parsed_buffs = parsed.buffs
        end

    end

    local current_buffs = {}

    for _, buff_id in pairs(player.buffs) do

        if buff_id and buff_id > 0 then

            current_buffs[buff_id] = true

            if parsed_buffs then

                for _, buff in pairs(parsed_buffs) do

                    if buff.id == buff_id then

                        track_buff(
                            buff_id,
                            buff.duration,
                            pending.action_name
                        )

                        actiontracker.clear_pending(player.id)

                        -- The pending action was consumed; stop matching.
                        parsed_buffs = nil

                        break

                    end

                end

            end

        end

    end

    -- LOST BUFFS
    for buff_id, _ in pairs(previous_buffs) do

        if not current_buffs[buff_id] then

            active_buffs[buff_id] = nil

            mark_dirty()

        end

    end

    previous_buffs = current_buffs

    -- One disk write per tick at most.
    flush_runtime()

end

-- GET BUFF
function bufftracker.get_buff(buff_id)

    return active_buffs[buff_id]

end

-- GET REMAINING
function bufftracker.get_remaining(buff_id)

    local buff =
        active_buffs[buff_id]

    if not buff then
        return nil
    end

    return math.max(
        buff.expires_at - os.time(),
        0
    )

end

-- GET ALL
function bufftracker.get_all()

    return active_buffs

end

-- INITIALIZE
restore_runtime()

return bufftracker