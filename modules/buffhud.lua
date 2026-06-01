local images = require('images')
local texts = require('texts')
local settings =
    require('data/settings')
local res = require('resources')

local bufftracker =
    require('systems/bufftracker')

local buffhud = {}

buffhud.visible = true

local buff_icons = {}

-- PREVIEW MODE
buffhud.preview = false

-- PUBLIC ANCHORS
buffhud.x = 800
buffhud.y = 980
local function get_scale()

    return
        settings.buffhud.scale / 50

end

-- MOUSE
buffhud.mouse_x = 0
buffhud.mouse_y = 0

local MAX_BUFFS = 32
local ICON_SIZE = 20
local ICON_SPACING = 24

-- ICON PATH RESOLUTION
local ICON_PATH =
    windower.addon_path ..
    'assets/icons/'

local FALLBACK_ICON =
    ICON_PATH ..
    'fallback.png'

local icon_path_cache = {}

local function get_icon_path(buff_id)

    local cached = icon_path_cache[buff_id]

    if cached then
        return cached
    end

    local path = ICON_PATH .. tostring(buff_id) .. '.png'

    if not windower.file_exists(path) then
        path = FALLBACK_ICON
    end

    icon_path_cache[buff_id] = path

    return path

end

-- TOOLTIP (created in initialize)
local tooltip = nil

function buffhud.initialize()

    tooltip = texts.new('')

    tooltip:size(10)
    tooltip:font('Arial')
    tooltip:color(255, 255, 255)
    tooltip:stroke_color(0, 0, 0)
    tooltip:stroke_width(2)
    tooltip:bg_alpha(180)
    tooltip:hide()

    for i = 1, MAX_BUFFS do

        local icon = images.new()

        icon:hide()

        buff_icons[i] = icon

    end

end

function buffhud.update()

    if not buffhud.visible then

        tooltip:hide()

        for i = 1, MAX_BUFFS do

            buff_icons[i]:hide()

        end

        return

    end

    local scale =
    get_scale()

local icon_size =
    ICON_SIZE * scale

local icon_spacing =
    ICON_SPACING * scale

    local player =
        windower.ffxi.get_player()

    -- PREVIEW MODE
    if buffhud.preview then

        tooltip:hide()

        for i = 1, MAX_BUFFS do

            local icon = buff_icons[i]

            local x =
                buffhud.x +
                ((i - 1) * icon_spacing)

            local y = buffhud.y

            icon:path(
                windower.addon_path ..
                'assets/textures/buff.png'
            )

            icon:size(
    icon_size,
    icon_size
)

            icon:pos(x, y)

            icon:show()

        end

        return

    end

    if not player then
        return
    end

    local buffs = player.buffs

    local hovering = false

    for i = 1, MAX_BUFFS do

        local icon = buff_icons[i]

        local buff_id = buffs[i]

        if buff_id and buff_id > 0 then

            local x =
                buffhud.x +
                ((i - 1) * icon_spacing)

            local y = buffhud.y

            local icon_path = get_icon_path(buff_id)

            icon:path(icon_path)

            icon:size(
                icon_size,
                icon_size
            )

            icon:pos(x, y)

            icon:show()

            -- TOOLTIP
            if buffhud.mouse_x >= x and
               buffhud.mouse_x <= x + icon_size and
               buffhud.mouse_y >= y and
               buffhud.mouse_y <= y + icon_size then

                local buff =
                    res.buffs[buff_id]

                local buff_name =
                    buff and buff.en
                    or 'Unknown Buff'

                local tooltip_text =
                    buff_name

                local remaining =
                    tonumber(
                        bufftracker.get_remaining(
                            buff_id
                        )
                    )

                if remaining ~= nil and
                   remaining > 0 then

                    remaining = math.max(
                        math.floor(remaining),
                        0
                    )

                    local hours =
                        math.floor(
                            remaining / 3600
                        )

                    local minutes =
                        math.floor(
                            (remaining % 3600) / 60
                        )

                    local seconds =
                        math.floor(
                            remaining % 60
                        )

                    local time_text = ''

                    if hours > 0 then

                        time_text = string.format(
                            '%d:%02d:%02d',
                            hours,
                            minutes,
                            seconds
                        )

                    else

                        time_text = string.format(
                            '%02d:%02d',
                            minutes,
                            seconds
                        )

                    end

                    tooltip_text =
                        tooltip_text ..
                        '\n' ..
                        time_text

                end

                tooltip:text(
                    tooltip_text
                )

                tooltip:pos(
                    buffhud.mouse_x + 16,
                    buffhud.mouse_y + 16
                )

                tooltip:show()

                hovering = true

            end

        else

            icon:hide()

        end

    end

    if not hovering then
        tooltip:hide()
    end

end

function buffhud.destroy()

    if tooltip then
        tooltip:destroy()
        tooltip = nil
    end

    for i = 1, MAX_BUFFS do

        if buff_icons[i] then
            buff_icons[i]:destroy()
        end

    end

    buff_icons = {}

end

return buffhud