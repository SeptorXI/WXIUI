local texts =
    require('texts')

local prims =
    require('prims')

local images =
    require('images')

local settings =
    require('data/settings')    

local packets =
    require('packets')

local trust_jobs =
    require('libs/trusts')

local res =
    require('resources')

local partyhud = {}

partyhud.visible = true
partyhud.preview = false

local party_members = {}
local party_jobs = {}

local last_party_hash = ''

-- =========================================================
-- POSITION
-- =========================================================

partyhud.x = 1450
partyhud.y = 700
local function get_scale()

    return
        settings.partyhud.scale / 50

end
-- =========================================================
-- LAYOUT
-- =========================================================

local MEMBER_SPACING = 60

local HP_WIDTH = 185
local MP_WIDTH = 185

local BAR_HEIGHT = 18

local MP_OFFSET_X = 22
local MP_OFFSET_Y = 22

-- =========================================================
-- SMOOTHING
-- =========================================================

local HP_SMOOTH_SPEED = 0.15
local MP_SMOOTH_SPEED = 0.15

local DAMAGE_DELAY_SPEED = 0.035

-- =========================================================
-- COLORS
-- =========================================================

local HP_FILL = {
    255,
    255,
    150,
    210
}

local HP_DAMAGE = {
    180,
    120,
    40,
    60
}

local MP_FILL = {
    255,
    170,
    220,
    255
}

local BG_COLOR = {
    255,
    15,
    25,
    45
}

local OUTLINE = {
    255,
    0,
    0,
    0
}

-- =========================================================
-- TARGET RESOLVER
-- =========================================================

local current_target_index = nil

windower.register_event(
    'target change',

    function(index)

        current_target_index = index

    end
)

-- =========================================================
-- CREATE RECT
-- =========================================================

local function create_rect(
    width,
    height,
    color
)

    return prims.new({

        w = width,
        h = height,

        color = color,

        visible = true

    })

end

-- =========================================================
-- TRUST LOOKUP
-- =========================================================

local function get_trust_job(name)

    return trust_jobs[name]

end

-- =========================================================
-- JOB STRING
-- =========================================================

local function get_job_string(member)

    if not member then
        return ''
    end

    local name =
        member.name

    if not name then
        return ''
    end

    local cached =
        party_jobs[name]

    if cached and
       cached ~= 'NON'
    then
        return cached
    end

    local trust_job =
        get_trust_job(name)

    if trust_job then
        return trust_job
    end

    return ''

end

-- =========================================================
-- TP TEXTURE
-- =========================================================

local function get_tp_texture(tp)

    if tp >= 3000 then

        return 'tpparty_red.png'

    elseif tp >= 2000 then

        return 'tpparty_yellow.png'

    elseif tp >= 1000 then

        return 'tpparty_green.png'

    end

    return 'tpparty_zero.png'

end

-- =========================================================
-- JOB PACKETS
-- =========================================================

windower.register_event(
    'incoming chunk',

    function(id, data)

        if id ~= 0x0DD then
            return
        end

        local packet =
            packets.parse(
                'incoming',
                data
            )

        if not packet then
            return
        end

        local name =
            packet['Name']

        if not name then
            return
        end

        local mjob =
            packet['Main job']

        local sjob =
            packet['Sub job']

        if not mjob then
            return
        end

        local main_job =
            res.jobs[mjob] and
            res.jobs[mjob].ens or
            ''

        local sub_job =
            res.jobs[sjob] and
            res.jobs[sjob].ens or
            ''

        local job_string =
            main_job

        if sub_job ~= '' and
           sub_job ~= 'NON'
        then

            job_string =
                string.format(
                    '%s/%s',
                    main_job,
                    sub_job
                )

        end

        party_jobs[name] =
            job_string

    end
)

-- =========================================================
-- HIDE MEMBER
-- =========================================================

local function hide_member(member)

    member.hp_outline:hide()
    member.hp_bg:hide()
    member.hp_damage:hide()
    member.hp_fill:hide()

    member.mp_outline:hide()
    member.mp_bg:hide()
    member.mp_fill:hide()

    member.tp_circle:hide()

    member.target_icon:hide()

    member.name:hide()

    member.hp_text:hide()
    member.mp_text:hide()

end

-- =========================================================
-- RESET MEMBER
-- =========================================================

local function reset_member(member)

    member.displayed_hp = 1.0
    member.displayed_mp = 1.0

    member.damage_hp = 1.0

    -- Reset max_mp so an ex-WHM's max doesn't leak into a new RDM
    -- when the slot gets reused.
    member.max_mp = 1

end

-- =========================================================
-- INITIALIZE
-- =========================================================

function partyhud.initialize()

    for i = 1, 6 do

        local member = {}

        -- =================================================
        -- HP
        -- =================================================

        member.hp_outline =
            create_rect(
                HP_WIDTH + 2,
                BAR_HEIGHT + 2,
                OUTLINE
            )

        member.hp_bg =
            create_rect(
                HP_WIDTH,
                BAR_HEIGHT,
                BG_COLOR
            )

        member.hp_damage =
            create_rect(
                HP_WIDTH,
                BAR_HEIGHT,
                HP_DAMAGE
            )

        member.hp_fill =
            create_rect(
                HP_WIDTH,
                BAR_HEIGHT,
                HP_FILL
            )

        -- =================================================
        -- MP
        -- =================================================

        member.mp_outline =
            create_rect(
                MP_WIDTH + 2,
                BAR_HEIGHT + 2,
                OUTLINE
            )

        member.mp_bg =
            create_rect(
                MP_WIDTH,
                BAR_HEIGHT,
                BG_COLOR
            )

        member.mp_fill =
            create_rect(
                MP_WIDTH,
                BAR_HEIGHT,
                MP_FILL
            )

        -- =================================================
        -- TP ORB
        -- =================================================

        member.tp_circle =
            images.new(
                windower.addon_path ..
                'assets/textures/tpparty_zero.png'
            )

        -- =================================================
        -- TARGET ICON
        -- =================================================

        member.target_icon =
            images.new({

                texture = {
                    path =
                        windower.addon_path ..
                        'assets/textures/point.png'
                },

                pos = {
                    x = 0,
                    y = 0
                },

                size = {
                    width = 24,
                    height = 24
                },

                draggable = false,

                visible = false

            })

        -- =================================================
        -- NAME
        -- =================================================

        member.name =
            texts.new('')

        member.name:size(11)

        member.name:font(
            'Arial'
        )

        member.name:bold(true)

        member.name:bg_alpha(0)

        member.name:stroke_alpha(255)

        member.name:stroke_width(2)

        member.name:color(
            255,
            255,
            255
        )

        -- =================================================
        -- HP TEXT
        -- =================================================

        member.hp_text =
            texts.new('')

        member.hp_text:size(11)

        member.hp_text:font(
            'Arial'
        )

        member.hp_text:bold(true)

        member.hp_text:bg_alpha(0)

        member.hp_text:stroke_alpha(255)

        member.hp_text:stroke_width(2)

        member.hp_text:color(
            255,
            255,
            255
        )

        -- =================================================
        -- MP TEXT
        -- =================================================

        member.mp_text =
            texts.new('')

        member.mp_text:size(11)

        member.mp_text:font(
            'Arial'
        )

        member.mp_text:bold(true)

        member.mp_text:bg_alpha(0)

        member.mp_text:stroke_alpha(255)

        member.mp_text:stroke_width(2)

        member.mp_text:color(
            255,
            255,
            255
        )

        member.displayed_hp = 1.0
        member.displayed_mp = 1.0

        member.damage_hp = 1.0

        member.max_mp = 1

        party_members[i] = member

    end

end

-- =========================================================
-- UPDATE
-- =========================================================

function partyhud.update()

    if not partyhud.visible then

        for _, member in pairs(
            party_members
        ) do

            hide_member(member)

        end

        return

    end

    local party =
    windower.ffxi.get_party()

if partyhud.preview then

    party = {

        p1 = {
            name = 'Trust A',
            hp = 2450,
            mp = 890,
            hpp = 100,
            tp = 1450
        },

        p2 = {
            name = 'Trust B',
            hp = 1980,
            mp = 720,
            hpp = 87,
            tp = 1000
        },

        p3 = {
            name = 'Trust C',
            hp = 1650,
            mp = 410,
            hpp = 62,
            tp = 3000
        },

        p4 = {
            name = 'Trust D',
            hp = 2100,
            mp = 650,
            hpp = 94,
            tp = 2000
        },

        p5 = {
            name = 'Trust E',
            hp = 1750,
            mp = 300,
            hpp = 71,
            tp = 500
        }

    }

elseif not party then

    return

end

    -- =====================================================
    -- PARTY HASH
    --
    -- table.concat avoids 5 intermediate string allocations per frame
    -- that the old `..` accumulator produced.
    -- =====================================================

    local hash_parts = {}

    for i = 1, 6 do
        local p = party['p' .. i]
        hash_parts[i] = (p and p.name) or ''
    end

    local current_hash = table.concat(hash_parts, '\0')

    if current_hash ~= last_party_hash then

        for _, member in pairs(
            party_members
        ) do

            reset_member(member)

        end

        last_party_hash =
            current_hash

    end

    for i = 1, 6 do

        local member =
            party_members[i]

        local key =
            'p' .. i

        local party_member =
            party[key]

        if not party_member or
           not party_member.name
        then

            hide_member(member)

        else

            local scale =
    get_scale()

local member_spacing =
    MEMBER_SPACING * scale

local hp_width =
    HP_WIDTH * scale

local mp_width =
    MP_WIDTH * scale

local bar_height =
    BAR_HEIGHT * scale

local x =
    partyhud.x

local y =
    partyhud.y +
    (
        (i - 1)
        * member_spacing
    )

            -- =================================================
            -- ENTITY
            -- =================================================

            local mob = nil

            if party_member.mob and
               party_member.mob.id
            then

                mob =
                    windower.ffxi
                    .get_mob_by_id(
                        party_member.mob.id
                    )

            end

            local is_far =
                not mob

            -- =================================================
            -- SHOW
            -- =================================================

            member.hp_outline:show()
            member.hp_bg:show()
            member.hp_damage:show()
            member.hp_fill:show()

            member.mp_outline:show()
            member.mp_bg:show()
            member.mp_fill:show()

            member.name:show()

            member.hp_text:show()
            member.mp_text:show()

            -- =================================================
            -- CURRENT MP
            -- =================================================

            local current_mp =
                party_member.mp or
                0

            -- =================================================
            -- TP VISIBILITY
            -- =================================================

            if mob and
               current_mp > 0
            then

                member.tp_circle:show()

            else

                member.tp_circle:hide()

            end

            -- =================================================
            -- TARGET ICON
            -- =================================================

            if mob and
               current_target_index and
               mob.index and
               current_target_index == mob.index
            then

                member.target_icon:show()

                member.target_icon:size(
    24 * scale,
    24 * scale
)

                member.target_icon:pos(
                    x - (36 * scale),
                    y - (8 * scale)
                )

            else

                member.target_icon:hide()

            end

            -- =================================================
            -- NAME + JOB
            -- =================================================

            local display_name =
                party_member.name

            local job_string =
                get_job_string(
                    party_member
                )

            if job_string ~= '' then

                member.name:size(
    math.max(
        8,
        math.floor(
            11 * scale
        )
    )
)

                member.name:text(
                    string.format(
                        '%s \\cs(180,180,180)(%s)\\cr',
                        display_name,
                        job_string
                    )
                )

            else

                member.name:text(
                    display_name
                )

            end

            member.name:pos(
    x,
    y - (22 * scale)
)

            -- =================================================
            -- HP SOURCE
            -- =================================================

            local hp_percent = 1.0

            if mob and mob.hpp then

                hp_percent =
                    mob.hpp / 100

            elseif party_member.hpp then

                hp_percent =
                    party_member.hpp / 100

            end

            member.displayed_hp =
                member.displayed_hp +
                (
                    (
                        hp_percent -
                        member.displayed_hp
                    ) * HP_SMOOTH_SPEED
                )

            if member.damage_hp >
               member.displayed_hp
            then

                member.damage_hp =
                    member.damage_hp -
                    (
                        (
                            member.damage_hp -
                            member.displayed_hp
                        ) *
                        DAMAGE_DELAY_SPEED
                    )

            else

                member.damage_hp =
                    member.displayed_hp

            end

            -- =================================================
            -- HP DRAW
            -- =================================================

            member.hp_outline:pos(
                x - 1,
                y - 1
            )

            member.hp_bg:pos(
                x,
                y
            )

            member.hp_damage:pos(
                x,
                y
            )

            member.hp_fill:pos(
                x,
                y
            )

            member.hp_outline:width(
    hp_width + 2
)

member.hp_outline:height(
    bar_height + 2
)

member.hp_bg:width(
    hp_width
)

member.hp_bg:height(
    bar_height
)

member.hp_damage:height(
    bar_height
)

member.hp_fill:height(
    bar_height
)

            member.hp_damage:width(
                math.max(
                    2,
                    hp_width *
                    member.damage_hp
                )
            )

            member.hp_fill:width(
                math.max(
                    2,
                    hp_width *
                    member.displayed_hp
                )
            )

            -- =================================================
            -- MP
            -- =================================================

            if current_mp >
               member.max_mp
            then

                member.max_mp =
                    current_mp

            end

            local mp_percent =
                current_mp /
                math.max(
                    member.max_mp,
                    1
                )

            member.displayed_mp =
                member.displayed_mp +
                (
                    (
                        mp_percent -
                        member.displayed_mp
                    ) * MP_SMOOTH_SPEED
                )

            local mp_x =
    x + MP_OFFSET_X

local mp_y =
    y + (MP_OFFSET_Y * scale)

            member.mp_outline:pos(
                mp_x - 1,
                mp_y - 1
            )

            member.mp_bg:pos(
                mp_x,
                mp_y
            )

            member.mp_fill:pos(
                mp_x,
                mp_y
            )

            member.mp_outline:width(
    mp_width + 2
)

member.mp_outline:height(
    bar_height + 2
)

member.mp_bg:width(
    mp_width
)

member.mp_bg:height(
    bar_height
)

member.mp_fill:height(
    bar_height
)

            member.mp_fill:width(
                math.max(
                    2,
                    mp_width *
                    member.displayed_mp
                )
            )

            -- =================================================
            -- TP
            -- =================================================

            if mob and
               current_mp > 0
            then

                local tp =
                    party_member.tp or
                    0

                member.tp_circle:path(
                    windower.addon_path ..
                    'assets/textures/' ..
                    get_tp_texture(tp)
                )

                member.tp_circle:size(
    32 * scale,
    32 * scale
)

                member.tp_circle:pos(
    mp_x +
    mp_width - 16  ,
    mp_y - (32 * scale)
)

            else

                member.tp_circle:hide()

            end

            -- =================================================
            -- TEXT
            -- =================================================

            if is_far then

                local zone_name =
                    res.zones[
                        party_member.zone
                    ]

                if zone_name then

                    member.hp_text:text(
                        zone_name.en
                    )

                else

                    member.hp_text:text(
                        'Unknown Area'
                    )

                end

                member.mp_text:text('')

            else

                member.hp_text:text(
                    tostring(
                        party_member.hp or
                        0
                    )
                )

                member.mp_text:text(
                    tostring(
                        current_mp
                    )
                )

            end

            member.hp_text:size(
    math.max(
        8,
        math.floor(
            11 * scale
        )
    )
)

            member.hp_text:pos(
    x + (8 * scale),
    y - (1 * scale)
)

            member.mp_text:size(
    math.max(
        8,
        math.floor(
            11 * scale
        )
    )
)

            member.mp_text:pos(
    mp_x + (78 * scale),
    mp_y - (1 * scale)
)

        end

    end

end

-- =========================================================
-- DESTROY
-- =========================================================

function partyhud.destroy()

    for _, member in pairs(
        party_members
    ) do

        member.hp_outline:destroy()
        member.hp_bg:destroy()
        member.hp_damage:destroy()
        member.hp_fill:destroy()

        member.mp_outline:destroy()
        member.mp_bg:destroy()
        member.mp_fill:destroy()

        member.tp_circle:destroy()

        member.target_icon:destroy()

        member.name:destroy()

        member.hp_text:destroy()
        member.mp_text:destroy()

    end

end

return partyhud