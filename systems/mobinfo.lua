local mobinfo = {}

local sqlite3 =
    require('sqlite3')

local res =
    require('resources')

local db = nil

-- Prepared statement, reused per query. We probe support lazily and
-- fall back to escaped inline queries if the binding lacks :prepare.
local query_stmt = nil
local prepare_supported = nil

-- Per-target cache. We re-query only when the target id (or its
-- name/zone — used as a stability fingerprint) changes.
local cache_key = nil
local cache_info = nil

-- SQLite literal escape: double single-quotes per SQL standard.
local function sql_escape(s)
    return (tostring(s):gsub("'", "''"))
end

-- =========================================================
-- OPEN DB
-- =========================================================

local function open_db()

    if db then
        return
    end

    local path =
        windower.addon_path ..
        'database.db'

    db =
        sqlite3.open(path)

    if not db then

        windower.add_to_chat(
            167,
            '[WXIUI] Failed to open database.db'
        )

    end

end

-- =========================================================
-- GET TARGET INFO
-- =========================================================

function mobinfo.get_target_info()

    open_db()

    if not db then
        return nil
    end

    local player =
        windower.ffxi
        .get_player()

    if not player then
        return nil
    end

    local target =
        windower.ffxi
        .get_mob_by_target('t')

    if not target or
       not target.name
    then
        cache_key = nil
        cache_info = nil
        return nil
    end

    local zone_id =
        windower.ffxi
        .get_info()
        .zone

    local zone_resource = res.zones[zone_id]

    if not zone_resource then
        return nil
    end

    local zone = zone_resource.name

    -- Cache by (id, name, zone). Re-query only on change.
    local key =
        tostring(target.id) .. '|' ..
        target.name .. '|' ..
        zone

    if key == cache_key then
        return cache_info
    end

    -- Probe prepare support on first use.
    if prepare_supported == nil then
        prepare_supported = (type(db.prepare) == 'function')
    end

    local info = nil

    -- Real DB column names (verified against schema). Order here must
    -- match the destructured iterator variables below.
    local SELECT_COLS =
        'level_min, level_max, is_aggressive, is_linking, is_nm, ' ..
        'detects_sight, detects_sound, detects_magic, detects_lowhp, ' ..
        'detects_healing, detects_truesight, detects_truesound, tracks_scent'

    if prepare_supported then

        if not query_stmt then
            query_stmt = db:prepare(
                'SELECT ' .. SELECT_COLS ..
                ' FROM monster WHERE name = ? AND zone = ? LIMIT 1'
            )
        end

        if query_stmt then

            query_stmt:bind_values(target.name, zone)

            for
                levelmin, levelmax,
                isaggressive, islinking, isnm,
                sight, sound, magic, lowhp, healing,
                ts, th, scent
            in query_stmt:urows()
            do

                info = {
                    MinLevel = tonumber(levelmin),
                    MaxLevel = tonumber(levelmax),
                    Aggro = isaggressive == 1,
                    Link = islinking == 1,
                    NM = isnm == 1,
                    Sight = sight == 1,
                    Sound = sound == 1,
                    Magic = tonumber(magic) == 1,
                    Blood = lowhp == 1,
                    Healing = healing == 1,
                    TrueSight = ts == 1,
                    TrueHearing = th == 1,
                    Scent = scent == 1,
                }

                break

            end

            query_stmt:reset()

        end

    else

        -- Fallback path: escape inputs to defend against quote injection
        -- and against accidentally-malformed queries from names with apostrophes.
        local query =
            "SELECT " .. SELECT_COLS ..
            " FROM monster WHERE name = '" .. sql_escape(target.name) ..
            "' AND zone = '" .. sql_escape(zone) .. "' LIMIT 1"

        for
            levelmin, levelmax,
            isaggressive, islinking, isnm,
            sight, sound, magic, lowhp, healing,
            ts, th, scent
        in db:urows(query)
        do

            info = {
                MinLevel = tonumber(levelmin),
                MaxLevel = tonumber(levelmax),
                Aggro = isaggressive == 1,
                Link = islinking == 1,
                NM = isnm == 1,
                Sight = sight == 1,
                Sound = sound == 1,
                Magic = tonumber(magic) == 1,
                Blood = lowhp == 1,
                Healing = healing == 1,
                TrueSight = ts == 1,
                TrueHearing = th == 1,
                Scent = scent == 1,
            }

            break

        end

    end

    cache_key = key
    cache_info = info

    return info

end

-- =========================================================
-- LEVEL STRING
-- =========================================================

function mobinfo.get_level_string(info)

    if not info then
        return '?'
    end

    local min =
        info.MinLevel

    local max =
        info.MaxLevel

    if not min then
        return '?'
    end

    if min == max or
       not max
    then
        return tostring(min)
    end

    return
        tostring(min) ..
        '-' ..
        tostring(max)

end

-- =========================================================
-- AGGRO STRING
-- =========================================================

function mobinfo.get_aggro_string(info)

    if not info or
       not info.Aggro
    then
        return nil
    end

    local t = {}

    if info.TrueSight then
        table.insert(t, 'TrueSight')
    end

    if info.TrueHearing then
        table.insert(t, 'TrueHearing')
    end

    if info.Sight then
        table.insert(t, 'Sight')
    end

    if info.Sound then
        table.insert(t, 'Sound')
    end

    if info.Magic then
        table.insert(t, 'Magic')
    end

    if info.Blood then
        table.insert(t, 'Low HP')
    end

    if info.Healing then
        table.insert(t, 'Healing')
    end

    if info.Scent then
        table.insert(t, 'Scent')
    end

    if #t == 0 then
        return 'Aggro'
    end

    return table.concat(
        t,
        ' / '
    )

end

return mobinfo