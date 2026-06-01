local texts = require('texts')
local prims = require('prims')

local settings =
    require('data/settings')

local targethud = {}

targethud.visible = true
targethud.preview = false

-- =========================================================
-- POSITION
-- =========================================================

targethud.x = 760
targethud.y = 820

local function get_scale()

    return
        settings.targethud.scale / 50

end

-- =========================================================
-- DIMENSIONS
-- =========================================================

local BAR_WIDTH = 395
local BAR_HEIGHT = 26

local OUTLINE_SIZE = 2
local CLAIM_OUTLINE_SIZE = 4

-- =========================================================
-- SMOOTHING
-- =========================================================

local displayed_hp = 1.0
local delayed_hp = 1.0
local heal_hp = 1.0

local previous_hp = nil

local damage_timer = 0
local heal_timer = 0

local last_spawn_type = nil
local last_target_id = nil
local last_clock = nil

local function reset_smoothing(initial_percent)

    displayed_hp = initial_percent
    delayed_hp = initial_percent
    heal_hp = initial_percent
    previous_hp = nil
    damage_timer = 0
    heal_timer = 0

end

-- =========================================================
-- COLORS
-- =========================================================

-- MAIN CYAN
local HP_FILL = {255, 48, 182, 216}

-- NPC / OBJECT GREEN
local NPC_FILL = {255, 38, 170, 82}

-- DAMAGE PREVIEW
local HP_DAMAGE = {255, 35, 120, 145}

-- HEAL PREVIEW
local HP_HEAL = {255, 120, 255, 120}

-- BACKGROUND
local BG_COLOR = {255, 15, 25, 45}

-- NORMAL OUTLINE
local OUTLINE = {255, 0, 0, 0}

-- CLAIM OUTLINE
local CLAIM_OUTLINE = {
    255,
    145,
    60,
    220
}

-- =========================================================
-- ELEMENTS
-- =========================================================

-- NORMAL OUTLINE
local outline_top
local outline_bottom
local outline_left
local outline_right

-- CLAIM OUTLINE
local claim_top
local claim_bottom
local claim_left
local claim_right

local hp_bg

local hp_damage_fill
local hp_heal_fill
local hp_fill

local hp_percent_text
local target_name_text

-- =========================================================
-- CREATE RECT
-- =========================================================

local function create_rect(
    width,
    height,
    color
)

    local rect =
        prims.new({

            w = width,
            h = height,

            color = color,

            visible = true

        })

    return rect

end

-- =========================================================
-- CREATE NORMAL OUTLINE
-- =========================================================

local function create_outline()

    outline_top =
        create_rect(
            BAR_WIDTH + (OUTLINE_SIZE * 2),
            OUTLINE_SIZE,
            OUTLINE
        )

    outline_bottom =
        create_rect(
            BAR_WIDTH + (OUTLINE_SIZE * 2),
            OUTLINE_SIZE,
            OUTLINE
        )

    outline_left =
        create_rect(
            OUTLINE_SIZE,
            BAR_HEIGHT,
            OUTLINE
        )

    outline_right =
        create_rect(
            OUTLINE_SIZE,
            BAR_HEIGHT,
            OUTLINE
        )

end

-- =========================================================
-- CREATE CLAIM OUTLINE
-- =========================================================

local function create_claim_outline()

    claim_top =
        create_rect(
            BAR_WIDTH + (CLAIM_OUTLINE_SIZE * 2),
            CLAIM_OUTLINE_SIZE,
            CLAIM_OUTLINE
        )

    claim_bottom =
        create_rect(
            BAR_WIDTH + (CLAIM_OUTLINE_SIZE * 2),
            CLAIM_OUTLINE_SIZE,
            CLAIM_OUTLINE
        )

    claim_left =
        create_rect(
            CLAIM_OUTLINE_SIZE,
            BAR_HEIGHT + (CLAIM_OUTLINE_SIZE * 2),
            CLAIM_OUTLINE
        )

    claim_right =
        create_rect(
            CLAIM_OUTLINE_SIZE,
            BAR_HEIGHT + (CLAIM_OUTLINE_SIZE * 2),
            CLAIM_OUTLINE
        )

end

-- =========================================================
-- INITIALIZE
-- =========================================================

function targethud.initialize()

    create_outline()
    create_claim_outline()

    hp_bg =
        create_rect(
            BAR_WIDTH,
            BAR_HEIGHT,
            BG_COLOR
        )

    hp_damage_fill =
        create_rect(
            BAR_WIDTH,
            BAR_HEIGHT,
            HP_DAMAGE
        )

    hp_heal_fill =
        create_rect(
            BAR_WIDTH,
            BAR_HEIGHT,
            HP_HEAL
        )

    hp_fill =
        create_rect(
            BAR_WIDTH,
            BAR_HEIGHT,
            HP_FILL
        )

    -- =====================================================
    -- HP %
    -- =====================================================

    hp_percent_text =
        texts.new('')

    hp_percent_text:size(12)

    hp_percent_text:font('Arial')

    hp_percent_text:bold(true)

    hp_percent_text:bg_alpha(0)

    hp_percent_text:stroke_alpha(255)

    hp_percent_text:stroke_width(2)

    hp_percent_text:color(
        255,
        255,
        255
    )

    -- =====================================================
    -- TARGET NAME
    -- =====================================================

    target_name_text =
        texts.new('')

    target_name_text:size(11)

    target_name_text:font('Arial')

    target_name_text:bold(true)

    target_name_text:bg_alpha(0)

    target_name_text:stroke_alpha(255)

    target_name_text:stroke_width(2)

    target_name_text:color(
        255,
        255,
        255
    )

end

-- =========================================================
-- UPDATE
-- =========================================================

function targethud.update()

    if not targethud.visible then

        outline_top:visible(false)
        outline_bottom:visible(false)
        outline_left:visible(false)
        outline_right:visible(false)

        claim_top:visible(false)
        claim_bottom:visible(false)
        claim_left:visible(false)
        claim_right:visible(false)

        hp_bg:visible(false)

        hp_damage_fill:visible(false)
        hp_heal_fill:visible(false)
        hp_fill:visible(false)

        hp_percent_text:hide()
        target_name_text:hide()

        return

    end

    local mob =
        windower.ffxi.get_mob_by_target(
            't'
        )

    local player =
        windower.ffxi.get_player()

    if not mob then

        if not targethud.preview then

            outline_top:visible(false)
            outline_bottom:visible(false)
            outline_left:visible(false)
            outline_right:visible(false)

            claim_top:visible(false)
            claim_bottom:visible(false)
            claim_left:visible(false)
            claim_right:visible(false)

            hp_bg:visible(false)

            hp_damage_fill:visible(false)
            hp_heal_fill:visible(false)
            hp_fill:visible(false)

            hp_percent_text:hide()
            target_name_text:hide()

            return

        end

        mob = {
            id = -1,
            name = 'Target Preview',
            hpp = 72,
            spawn_type = 16,
            claim_id = 0
        }

    end

    -- =====================================================
    -- TARGET CHANGED: RESET SMOOTHING STATE
    -- =====================================================

    if mob.id ~= last_target_id then

        reset_smoothing(mob.hpp / 100)

        last_target_id = mob.id

    end

    -- =====================================================
    -- TARGET TYPE COLOR
    -- =====================================================

    if mob.spawn_type ~= last_spawn_type then

        hp_fill:destroy()

        if mob.spawn_type == 2 then

            hp_fill =
                create_rect(
                    BAR_WIDTH,
                    BAR_HEIGHT,
                    NPC_FILL
                )

        else

            hp_fill =
                create_rect(
                    BAR_WIDTH,
                    BAR_HEIGHT,
                    HP_FILL
                )

        end

        last_spawn_type =
            mob.spawn_type

    end

    local hp_percent =
        mob.hpp / 100

    -- =====================================================
    -- DAMAGE / HEAL DETECTION
    -- =====================================================

    if previous_hp == nil then
        previous_hp = mob.hpp
    end

    if mob.hpp < previous_hp then

        delayed_hp =
            previous_hp / 100

        damage_timer = 0.45

    elseif mob.hpp > previous_hp then

        heal_hp =
            mob.hpp / 100

        heal_timer = 0.45

    end

    previous_hp = mob.hpp

    -- =====================================================
    -- SMOOTHING
    -- =====================================================

    displayed_hp =
        displayed_hp +
        (
            (
                hp_percent -
                displayed_hp
            ) * 0.12
        )

    delayed_hp =
        delayed_hp +
        (
            (
                displayed_hp -
                delayed_hp
            ) * 0.05
        )

    local x =
        targethud.x

    local y =
        targethud.y
        
    local scale =
    get_scale()

local bar_width =
    BAR_WIDTH * scale

local bar_height =
    BAR_HEIGHT * scale

local outline_size =
    OUTLINE_SIZE * scale

local claim_outline_size =
    CLAIM_OUTLINE_SIZE * scale

    -- =====================================================
    -- NORMAL OUTLINE POSITIONS
    -- =====================================================

    outline_top:pos(
    x - outline_size,
    y - outline_size
)

outline_bottom:pos(
    x - outline_size,
    y + bar_height
)

outline_left:pos(
    x - outline_size,
    y
)

outline_right:pos(
    x + bar_width,
    y
)

outline_top:width(
    bar_width + (outline_size * 2)
)

outline_bottom:width(
    bar_width + (outline_size * 2)
)

outline_top:height(
    outline_size
)

outline_bottom:height(
    outline_size
)

outline_left:width(
    outline_size
)

outline_right:width(
    outline_size
)

outline_left:height(
    bar_height
)

outline_right:height(
    bar_height
)
    -- =====================================================
    -- CLAIM OUTLINE POSITIONS
    -- =====================================================

    claim_top:pos(
    x - claim_outline_size,
    y - claim_outline_size
)

claim_bottom:pos(
    x - claim_outline_size,
    y + bar_height
)

claim_left:pos(
    x - claim_outline_size,
    y - claim_outline_size
)

claim_right:pos(
    x + bar_width,
    y - claim_outline_size
)

claim_top:width(
    bar_width +
    (claim_outline_size * 2)
)

claim_bottom:width(
    bar_width +
    (claim_outline_size * 2)
)

claim_top:height(
    claim_outline_size
)

claim_bottom:height(
    claim_outline_size
)

claim_left:width(
    claim_outline_size
)

claim_right:width(
    claim_outline_size
)

claim_left:height(
    bar_height +
    (claim_outline_size * 2)
)

claim_right:height(
    bar_height +
    (claim_outline_size * 2)
)
    -- =====================================================
    -- CLAIM VISIBILITY
    -- =====================================================

    local claimed_by_you =
        player and
        (
            mob.claim_id == player.id or
            mob.claimed_by_id == player.id
        )

    claim_top:visible(claimed_by_you)
    claim_bottom:visible(claimed_by_you)
    claim_left:visible(claimed_by_you)
    claim_right:visible(claimed_by_you)

    -- =====================================================
    -- BAR
    -- =====================================================

    hp_bg:pos(
        x,
        y
    )

    hp_damage_fill:pos(
        x,
        y
    )

    hp_heal_fill:pos(
        x,
        y
    )

    hp_fill:pos(
        x,
        y
    )

    hp_bg:width(
    bar_width
)

hp_bg:height(
    bar_height
)

hp_damage_fill:height(
    bar_height
)

hp_heal_fill:height(
    bar_height
)

hp_fill:height(
    bar_height
)

    hp_damage_fill:width(
    bar_width *
    delayed_hp
)

    hp_heal_fill:width(
    bar_width *
    heal_hp
)

    hp_fill:width(
    math.max(
        2,
        bar_width *
        displayed_hp
    )
)

    local now = os.clock()
    local dt = last_clock and (now - last_clock) or 0.016
    last_clock = now

    if damage_timer > 0 then

        hp_damage_fill:visible(true)

        damage_timer = damage_timer - dt

    else

        hp_damage_fill:visible(false)

    end

    if heal_timer > 0 then

        hp_heal_fill:visible(true)

        heal_timer = heal_timer - dt

    else

        hp_heal_fill:visible(false)

    end

    -- =====================================================
    -- SHOW
    -- =====================================================

    outline_top:visible(true)
    outline_bottom:visible(true)
    outline_left:visible(true)
    outline_right:visible(true)

    hp_bg:visible(true)
    hp_fill:visible(true)

    -- =====================================================
    -- HP %
    -- =====================================================

    local percent_text =
        tostring(mob.hpp) .. '%'

    hp_percent_text:size(
    math.floor(12 * scale)
)

    hp_percent_text:text(
        percent_text
    )

    local text_offset = 0

    if string.len(percent_text) == 2 then

        text_offset = 8

    elseif string.len(percent_text) == 3 then

        text_offset = 12

    elseif string.len(percent_text) == 4 then

        text_offset = 16

    end

    hp_percent_text:pos(
    x + (
        bar_width / 2
    ) - (text_offset * scale),
    y + (3 * scale)
)

    hp_percent_text:show()

    -- =====================================================
    -- TARGET NAME
    -- =====================================================
    target_name_text:size(
    math.floor(11 * scale)
)
     
    target_name_text:text(
        mob.name
    )

    target_name_text:pos(
    x,
    y - (22 * scale)
)

    target_name_text:show()

end

-- =========================================================
-- DESTROY
-- =========================================================

function targethud.destroy()

    outline_top:destroy()
    outline_bottom:destroy()
    outline_left:destroy()
    outline_right:destroy()

    claim_top:destroy()
    claim_bottom:destroy()
    claim_left:destroy()
    claim_right:destroy()

    hp_bg:destroy()

    hp_damage_fill:destroy()
    hp_heal_fill:destroy()
    hp_fill:destroy()

    hp_percent_text:destroy()
    target_name_text:destroy()

end

return targethud