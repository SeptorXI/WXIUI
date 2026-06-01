local texts = require('texts')
local prims = require('prims')
local images = require('images')

local playerhud = {}

local settings =
    require('data/settings')

playerhud.visible = true
playerhud.preview = false

-- =========================================================
-- POSITION
-- =========================================================

playerhud.x = 500
playerhud.y = 900

local function get_scale()

    return
        settings.playerhud.scale / 50

end

-- =========================================================
-- DIMENSIONS
-- =========================================================

local HP_WIDTH = 150
local MP_WIDTH = 150

local BAR_HEIGHT = 28

-- =========================================================
-- SMOOTHING
-- =========================================================

local displayed_hp = 1.0
local displayed_mp = 1.0

local delayed_hp = 1.0
local heal_hp = 1.0

local previous_hp = nil

local damage_timer = 0
local heal_timer = 0

local last_clock = nil
local last_tp_texture = nil

-- =========================================================
-- COLORS
-- =========================================================

-- HP rosa pastel
local HP_FILL = {255, 255, 150, 210}

-- HP daño (rosa apagado)
local HP_DAMAGE = {255, 190, 90, 150}

-- HP cura (verde)
local HP_HEAL = {255, 120, 255, 120}

-- MP azul pastel
local MP_FILL = {255, 170, 220, 255}

-- Fondo azul oscuro
local BG_COLOR = {255, 15, 25, 45}

-- Outline negro
local OUTLINE = {255, 0, 0, 0}

-- =========================================================
-- ELEMENTS
-- =========================================================

local hp_outline
local hp_bg

local hp_damage_fill
local hp_heal_fill
local hp_fill

local mp_outline
local mp_bg
local mp_fill

local tp_circle

local hp_text
local mp_text
local tp_text

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
-- INITIALIZE
-- =========================================================

function playerhud.initialize()

    -- =====================================================
    -- HP
    -- =====================================================

    hp_outline =
        create_rect(
            HP_WIDTH + 4,
            BAR_HEIGHT + 4,
            OUTLINE
        )

    hp_bg =
        create_rect(
            HP_WIDTH,
            BAR_HEIGHT,
            BG_COLOR
        )

    hp_damage_fill =
        create_rect(
            HP_WIDTH,
            BAR_HEIGHT,
            HP_DAMAGE
        )

    hp_heal_fill =
        create_rect(
            HP_WIDTH,
            BAR_HEIGHT,
            HP_HEAL
        )

    hp_fill =
        create_rect(
            HP_WIDTH,
            BAR_HEIGHT,
            HP_FILL
        )

    -- =====================================================
    -- MP
    -- =====================================================

    mp_outline =
        create_rect(
            MP_WIDTH + 4,
            BAR_HEIGHT + 4,
            OUTLINE
        )

    mp_bg =
        create_rect(
            MP_WIDTH,
            BAR_HEIGHT,
            BG_COLOR
        )

    mp_fill =
        create_rect(
            MP_WIDTH,
            BAR_HEIGHT,
            MP_FILL
        )

    -- =====================================================
    -- TP CIRCLE
    -- =====================================================

    tp_circle =
        images.new(
            windower.addon_path ..
            'assets/textures/tp_zero.png'
        )

    tp_circle:size(
        64,
        64
    )

    tp_circle:visible(true)

    -- =====================================================
    -- TEXTS
    -- =====================================================

    hp_text = texts.new('')

    hp_text:size(12)
    hp_text:font('Arial')
    hp_text:bold(true)
    hp_text:bg_alpha(0)
    hp_text:stroke_alpha(255)
    hp_text:stroke_width(2)

    hp_text:color(
        255,
        255,
        255
    )

    mp_text = texts.new('')

    mp_text:size(12)
    mp_text:font('Arial')
    mp_text:bold(true)
    mp_text:bg_alpha(0)
    mp_text:stroke_alpha(255)
    mp_text:stroke_width(2)

    mp_text:color(
        255,
        255,
        255
    )

    tp_text = texts.new('')

    tp_text:size(11)
    tp_text:font('Arial')
    tp_text:bold(true)
    tp_text:bg_alpha(0)
    tp_text:stroke_alpha(255)
    tp_text:stroke_width(2)

    tp_text:color(
        255,
        255,
        255
    )

end

-- =========================================================
-- UPDATE
-- =========================================================

function playerhud.update()

    if not playerhud.visible then

        hp_outline:visible(false)
        hp_bg:visible(false)

        hp_damage_fill:visible(false)
        hp_heal_fill:visible(false)
        hp_fill:visible(false)

        mp_outline:visible(false)
        mp_bg:visible(false)
        mp_fill:visible(false)

        tp_circle:visible(false)

        hp_text:hide()
        mp_text:hide()
        tp_text:hide()

        return

    end

    local player =
        windower.ffxi.get_player()

    if not player then
        return
    end

    local hp_percent =
        player.vitals.hp /
        player.vitals.max_hp

    local mp_percent = 0

    if player.vitals.max_mp > 0 then

        mp_percent =
            player.vitals.mp /
            player.vitals.max_mp

    end

    -- =====================================================
    -- DAMAGE / HEAL DETECTION
    -- =====================================================

    if previous_hp == nil then
        previous_hp = player.vitals.hp
    end

    if player.vitals.hp < previous_hp then

        delayed_hp =
            previous_hp /
            player.vitals.max_hp

        damage_timer = 0.45

    elseif player.vitals.hp > previous_hp then

        heal_hp =
            player.vitals.hp /
            player.vitals.max_hp

        heal_timer = 0.45

    end

    previous_hp = player.vitals.hp

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

    displayed_mp =
        displayed_mp +
        (
            (
                mp_percent -
                displayed_mp
            ) * 0.15
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
        playerhud.x

    local y =
        playerhud.y

        local scale =
    get_scale()

local hp_width =
    HP_WIDTH * scale

local mp_width =
    MP_WIDTH * scale

local bar_height =
    BAR_HEIGHT * scale

    -- =====================================================
    -- HP
    -- =====================================================

    hp_outline:pos(
        x - 2,
        y - 2
    )

    hp_bg:pos(
        x,
        y
    )

    hp_outline:width(
    hp_width + 4
)

hp_outline:height(
    bar_height + 4
)

hp_bg:width(
    hp_width
)

hp_bg:height(
    bar_height
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
    hp_width *
    delayed_hp
)

    hp_heal_fill:width(
    hp_width *
    heal_hp
)

    hp_fill:width(
    math.max(
        2,
        hp_width *
        displayed_hp
    )
)

hp_fill:height(
    bar_height
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
    -- MP
    -- =====================================================

    local mp_x =
    x + hp_width + (96 * scale)

    local mp_y = y

    mp_outline:pos(
        mp_x - 2,
        mp_y - 2
    )

    mp_bg:pos(
        mp_x,
        mp_y
    )

    mp_fill:pos(
        mp_x,
        mp_y
    )

mp_outline:width(
    mp_width + 4
)

mp_outline:height(
    bar_height + 4
)

mp_bg:width(
    mp_width
)

mp_bg:height(
    bar_height
)

mp_fill:height(
    bar_height
)

    mp_fill:width(
    math.max(
        2,
        mp_width *
        displayed_mp
    )
)

mp_fill:height(
    bar_height
)
    -- =====================================================
    -- TP
    -- =====================================================

    local tp_x =
    x + hp_width + (17 * scale)

    local tp_y =
    y - (22 * scale)

    local tp_texture =
        'tp_zero.png'

    if player.vitals.tp >= 3000 then

        tp_texture =
            'tp_red.png'

    elseif player.vitals.tp >= 2000 then

        tp_texture =
            'tp_yellow.png'

    elseif player.vitals.tp >= 1000 then

        tp_texture =
            'tp_green.png'

    end

tp_circle:size(
    64 * scale,
    64 * scale
)

    if tp_texture ~= last_tp_texture then

        tp_circle:path(
            windower.addon_path ..
            'assets/textures/' ..
            tp_texture
        )

        last_tp_texture = tp_texture

    end

    tp_circle:pos(
        tp_x,
        tp_y
    )

    tp_circle:visible(true)

    -- =====================================================
    -- TP DISPLAY
    -- =====================================================

    local tp_display =
        tostring(player.vitals.tp)

    if player.vitals.tp >= 1000 then

        tp_display =
            string.format(
                '%.1fK',
                player.vitals.tp / 1000
            )

        tp_display =
            tp_display:gsub(
                '%.0K',
                'K'
            )

    end

    -- =====================================================
    -- SHOW
    -- =====================================================

    hp_outline:visible(true)
    hp_bg:visible(true)
    hp_fill:visible(true)

    mp_outline:visible(true)
    mp_bg:visible(true)
    mp_fill:visible(true)

    -- =====================================================
    -- TEXT
    -- =====================================================

    hp_text:size(
    math.floor(12 * scale)
    )
  
    hp_text:text(
        tostring(player.vitals.hp)
    )

    hp_text:pos(
        x + 8,
        y + 3
    )

    hp_text:show()

    mp_text:size(
    math.floor(12 * scale)
    )

    mp_text:text(
        tostring(player.vitals.mp)
    )

    mp_text:pos(
        mp_x + 8,
        mp_y + 3
    )

    mp_text:show()

    tp_text:size(
    math.floor(11 * scale)
   )

    tp_text:text(tp_display)

    local tp_size =
    64 * scale

local tp_offset_x = 0

if string.len(tp_display) == 1 then
    tp_offset_x = tp_size * 0.38
elseif string.len(tp_display) == 2 then
    tp_offset_x = tp_size * 0.33
elseif string.len(tp_display) == 3 then
    tp_offset_x = tp_size * 0.29
else
    tp_offset_x = tp_size * 0.23
end

local tp_offset_y =
    tp_size * 0.35

tp_text:pos(
    tp_x + tp_offset_x,
    tp_y + tp_offset_y
)

    tp_text:show()

end

-- =========================================================
-- DESTROY
-- =========================================================

function playerhud.destroy()

    hp_outline:destroy()
    hp_bg:destroy()

    hp_damage_fill:destroy()
    hp_heal_fill:destroy()
    hp_fill:destroy()

    mp_outline:destroy()
    mp_bg:destroy()
    mp_fill:destroy()

    tp_circle:destroy()

    hp_text:destroy()
    mp_text:destroy()
    tp_text:destroy()

end

return playerhud