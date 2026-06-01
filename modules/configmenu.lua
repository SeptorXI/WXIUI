local texts = require('texts')
local prims = require('prims')

local settings =
    require('data/settings')

local scale_settings = {

    settings.playerhud,
    settings.targethud,
    settings.tothud,
    settings.partyhud,
    settings.buffhud,
    settings.debuffhud,
    settings.castbar,
    settings.experiencehud,

    settings.pethud,
    settings.inventoryhud,
    settings.distancehud,
    settings.mobinfohud,
    settings.zonehud,
    settings.gilhud,
    settings.lootnotify

}

local configmenu = {}

configmenu.visible = false

configmenu.width = 500
configmenu.height = 400

configmenu.x = 700
configmenu.y = 250

configmenu.resume_after_move = false
configmenu.pending_move = nil
configmenu.page = 1

-- =========================================================
-- COLORS
-- =========================================================

local BG_COLOR = {
    255,
    15,
    25,
    45
}

local HEADER_COLOR = {
    255,
    48,
    182,
    216
}

local WHITE_TEXT = {
    255,
    255,
    255
}

local HOVER_TEXT = {
    255,
    105,
    180
}
-- =========================================================
-- ELEMENTS
-- =========================================================

local button_labels = {

    'Player HUD',
    'Target HUD',
    'ToT HUD',
    'Party HUD',
    'Buff HUD',
    'Debuff HUD',
    'Cast Bar',
    'Experience HUD',

    'Pet HUD',
    'Inventory HUD',
    'Distance HUD',
    'MobInfo HUD',
    'Zone HUD',
    'Gil HUD',
    'Loot Notify'

}

local button_modules = {

    'playerhud',
    'targethud',
    'tothud',
    'partyhud',
    'buffhud',
    'debuffhud',
    'castbar',
    'experiencehud',

    'pethud',
    'inventoryhud',
    'distancehud',
    'mobinfohud',
    'zonehud',
    'gilhud',
    'lootnotify'

}

local scale_values = {

    settings.playerhud.scale,
    settings.targethud.scale,
    settings.tothud.scale,
    settings.partyhud.scale,
    settings.buffhud.scale,
    settings.debuffhud.scale,
    settings.castbar.scale,
    settings.experiencehud.scale,

    settings.pethud.scale,
    settings.inventoryhud.scale,
    settings.distancehud.scale,
    settings.mobinfohud.scale,
    settings.zonehud.scale,
    settings.gilhud.scale,
    settings.lootnotify.scale

}

local background
local header

local title_text
local subtitle_text

local close_text
local x_text

local page_text
local next_text
local prev_text

local button_texts = {}
local scale_texts = {}

local hover_index = nil

local BUTTON_START_Y = 95
local BUTTON_ROW_HEIGHT = 32

local BUTTON_LEFT_X = 80
local BUTTON_RIGHT_X = 300

-- =========================================================
-- CREATE RECT
-- =========================================================

local function create_rect(width, height, color)

    return prims.new({
        w = width,
        h = height,
        color = color,
        visible = true
    })

end

-- =========================================================
-- INITIALIZE
-- =========================================================

function configmenu.initialize()

    background =
        create_rect(
            configmenu.width,
            configmenu.height,
            BG_COLOR
        )

    header =
        create_rect(
            configmenu.width,
            32,
            HEADER_COLOR
        )

    title_text =
        texts.new('')

    title_text:size(12)
    title_text:font('Arial')
    title_text:bold(true)
    title_text:bg_alpha(0)
    title_text:stroke_alpha(255)
    title_text:stroke_width(2)

    x_text = texts.new('')

    page_text = texts.new('')
    next_text = texts.new('')
    prev_text = texts.new('')

x_text:size(12)
x_text:font('Arial')
x_text:bold(true)
x_text:bg_alpha(0)
x_text:stroke_alpha(255)
x_text:stroke_width(2)

page_text:size(10)
page_text:font('Arial')
page_text:bold(true)
page_text:bg_alpha(0)
page_text:stroke_alpha(255)
page_text:stroke_width(2)

next_text:size(10)
next_text:font('Arial')
next_text:bold(true)
next_text:bg_alpha(0)
next_text:stroke_alpha(255)
next_text:stroke_width(2)

prev_text:size(10)
prev_text:font('Arial')
prev_text:bold(true)
prev_text:bg_alpha(0)
prev_text:stroke_alpha(255)
prev_text:stroke_width(2)

for i = 1, #button_labels do

    local t =
        texts.new('')

    t:size(10)
    t:font('Arial')
    t:bold(true)
    t:bg_alpha(0)
    t:stroke_alpha(255)
    t:stroke_width(2)

    table.insert(
        button_texts,
        t
    )

        local scale_t =
        texts.new('')

    scale_t:size(10)
    scale_t:font('Arial')
    scale_t:bold(true)
    scale_t:bg_alpha(0)
    scale_t:stroke_alpha(255)
    scale_t:stroke_width(2)

    table.insert(
        scale_texts,
        scale_t
    )

end

    subtitle_text =
        texts.new('')

    subtitle_text:size(10)
    subtitle_text:font('Arial')
    subtitle_text:bold(true)
    subtitle_text:bg_alpha(0)
    subtitle_text:stroke_alpha(255)
    subtitle_text:stroke_width(2)

    configmenu.hide()

   
end

-- =========================================================
-- SHOW
-- =========================================================

function configmenu.show()

    configmenu.visible = true

end

-- =========================================================
-- HIDE
-- =========================================================

function configmenu.hide()

    configmenu.visible = false

    background:visible(false)
    header:visible(false)

    title_text:hide()
    subtitle_text:hide()

    x_text:hide()

    page_text:hide()
    next_text:hide()
    prev_text:hide()

    for _, t in ipairs(button_texts) do
        t:hide()
    end

    for _, t in ipairs(scale_texts) do
    t:hide()
end

end

-- =========================================================
-- UPDATE
-- =========================================================

function configmenu.update()

    if configmenu.pending_move then

        windower.send_command(
            'wxiui move ' ..
            configmenu.pending_move
        )

        configmenu.pending_move = nil

    end

    if not configmenu.visible then
        return
    end

    background:visible(true)
    header:visible(true)

    background:pos(
        configmenu.x,
        configmenu.y
    )

    header:pos(
        configmenu.x,
        configmenu.y
    )

    title_text:text(
        'WXIUI Configuration'
    )

    title_text:pos(
        configmenu.x + 12,
        configmenu.y + 6
    )

    title_text:show()


   if configmenu.page == 1 then

    subtitle_text:text(
        'Select a HUD to reposition'
    )

else

    subtitle_text:text(
        'Adjust the size of each HUD'
    )

end

    subtitle_text:pos(
        configmenu.x + 155,
        configmenu.y + 50
    )

    subtitle_text:show()

    -- X

    x_text:text('[X]')

    x_text:pos(
        configmenu.x +
        configmenu.width -
        40,

        configmenu.y + 6
    )

    x_text:show()

if configmenu.page == 1 then

    local left_x =
        configmenu.x +
        BUTTON_LEFT_X

    local right_x =
        configmenu.x +
        BUTTON_RIGHT_X

    local start_y =
        configmenu.y +
        BUTTON_START_Y

    for i, text_obj in ipairs(button_texts) do

        local pos_x
        local pos_y

        if i <= 8 then

            pos_x = left_x

            pos_y =
                start_y +
                (
                    (i - 1) *
                    BUTTON_ROW_HEIGHT
                )

        else

            pos_x = right_x

            pos_y =
                start_y +
                (
                    (i - 9) *
                    BUTTON_ROW_HEIGHT
                )

        end

        text_obj:text(
    button_labels[i]
)

        if hover_index == i then

            text_obj:color(
                HOVER_TEXT[1],
                HOVER_TEXT[2],
                HOVER_TEXT[3]
            )

        else

            text_obj:color(
                WHITE_TEXT[1],
                WHITE_TEXT[2],
                WHITE_TEXT[3]
            )

        end

        text_obj:pos(
            pos_x,
            pos_y
        )

        text_obj:show()

        scale_texts[i]:hide()

    end

else

    local left_x =
        configmenu.x +
        BUTTON_LEFT_X

    local right_x =
        configmenu.x +
        BUTTON_RIGHT_X

    local start_y =
        configmenu.y +
        BUTTON_START_Y

    for i, text_obj in ipairs(button_texts) do

        local pos_x
        local pos_y

        if i <= 8 then

            pos_x = left_x

            pos_y =
                start_y +
                (
                    (i - 1) *
                    BUTTON_ROW_HEIGHT
                )

        else

            pos_x = right_x

            pos_y =
                start_y +
                (
                    (i - 9) *
                    BUTTON_ROW_HEIGHT
                )

        end

        text_obj:color(
            WHITE_TEXT[1],
            WHITE_TEXT[2],
            WHITE_TEXT[3]
        )

        text_obj:text(
    button_labels[i]
)

        text_obj:pos(
            pos_x,
            pos_y
        )

        text_obj:show()

        scale_texts[i]:text(
    '[' ..
    scale_values[i] ..
    ']'
)

scale_texts[i]:color(
    WHITE_TEXT[1],
    WHITE_TEXT[2],
    WHITE_TEXT[3]
)

scale_texts[i]:pos(
    pos_x + 120,
    pos_y
)

scale_texts[i]:show()

    end

end
        page_text:text(
    'Page ' ..
    configmenu.page ..
    ' / 2'
)

page_text:pos(
    configmenu.x + 215,
    configmenu.y + 360
)

page_text:show()

         if configmenu.page == 1 then

    next_text:text('[ Next > ]')

    next_text:pos(
        configmenu.x + 400,
        configmenu.y + 360
    )

    next_text:show()

    prev_text:hide()

else

    prev_text:text('[ < Prev ]')

    prev_text:pos(
        configmenu.x + 30,
        configmenu.y + 360
    )

    prev_text:show()

    next_text:hide()

end

end

-- =========================================================
-- CLICK
-- =========================================================

function configmenu.click(x, y)

    if not configmenu.visible then
        return false
    end

    -- X

    if x >= configmenu.x + 455 and
       x <= configmenu.x + 490 and
       y >= configmenu.y + 5 and
       y <= configmenu.y + 25
    then

        configmenu.hide()

        return true

    end

    -- NEXT PAGE

if configmenu.page == 1 and
   x >= configmenu.x + 390 and
   x <= configmenu.x + 490 and
   y >= configmenu.y + 350 and
   y <= configmenu.y + 380
then

    configmenu.page = 2

    return true

end

-- PREVIOUS PAGE

if configmenu.page == 2 and
   x >= configmenu.x + 20 and
   x <= configmenu.x + 120 and
   y >= configmenu.y + 350 and
   y <= configmenu.y + 380
then

    configmenu.page = 1

    return true

end
 
if configmenu.page == 1 then

        -- HUD BUTTONS

    local left_x =
        configmenu.x +
        BUTTON_LEFT_X

    local right_x =
        configmenu.x +
        BUTTON_RIGHT_X

    local start_y =
        configmenu.y +
        BUTTON_START_Y

    for i = 1, #button_labels do

        local button_x
        local button_y

        if i <= 8 then

            button_x = left_x

            button_y =
                start_y +
                (
                    (i - 1) *
                    BUTTON_ROW_HEIGHT
                )

        else

            button_x = right_x

            button_y =
                start_y +
                (
                    (i - 9) *
                    BUTTON_ROW_HEIGHT
                )

        end

        if x >= button_x and
           x <= button_x + 180 and
           y >= button_y and
           y <= button_y + 20
        then

            configmenu.resume_after_move =
                true

            configmenu.hide()

            configmenu.pending_move =
                button_modules[i]

            return true

        end

    end

end

if configmenu.page == 2 then

    local left_x =
        configmenu.x +
        BUTTON_LEFT_X

    local right_x =
        configmenu.x +
        BUTTON_RIGHT_X

    local start_y =
        configmenu.y +
        BUTTON_START_Y

    for i = 1, #button_labels do

        local value_x
        local value_y

        if i <= 8 then

            value_x =
                left_x + 105

            value_y =
                start_y +
                (
                    (i - 1) *
                    BUTTON_ROW_HEIGHT
                )

        else

            value_x =
                right_x + 105

            value_y =
                start_y +
                (
                    (i - 9) *
                    BUTTON_ROW_HEIGHT
                )

        end

        if x >= value_x and
           x <= value_x + 45 and
           y >= value_y and
           y <= value_y + 20
        then

            scale_values[i] =
                scale_values[i] + 10

            if scale_values[i] > 100 then
                scale_values[i] = 30
            end

            scale_settings[i].scale =
                scale_values[i]

    save_settings()

            return true

        end

    end

end

    return false

end

-- =========================================================
-- DESTROY
-- =========================================================

function configmenu.mouse_move(x, y)

    hover_index = nil

    if not configmenu.visible then
        return
    end

    local left_x =
        configmenu.x +
        BUTTON_LEFT_X

    local right_x =
        configmenu.x +
        BUTTON_RIGHT_X

    local start_y =
        configmenu.y +
        BUTTON_START_Y

    for i = 1, #button_labels do

        local button_x
        local button_y

        if i <= 8 then

            button_x = left_x

            button_y =
                start_y +
                (
                    (i - 1) *
                    BUTTON_ROW_HEIGHT
                )

        else

            button_x = right_x

            button_y =
                start_y +
                (
                    (i - 9) *
                    BUTTON_ROW_HEIGHT
                )

        end

        if x >= button_x and
           x <= button_x + 180 and
           y >= button_y and
           y <= button_y + 20
        then

            hover_index = i

            return

        end

    end

end

function configmenu.destroy()

    background:destroy()
    header:destroy()

    title_text:destroy()
    subtitle_text:destroy()

    x_text:destroy()

    for _, t in ipairs(button_texts) do
        t:destroy()
    end

    for _, t in ipairs(scale_texts) do
    t:destroy()
end

end

return configmenu