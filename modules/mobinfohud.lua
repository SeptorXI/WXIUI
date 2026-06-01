local texts =
    require('texts')

local images =
    require('images')    

local mobinfo =
    require('systems/mobinfo')

local settings =
    require('data/settings')

local function get_scale()
    return settings.mobinfohud.scale / 50
end    

local mobinfohud = {}

mobinfohud.visible = true
mobinfohud.preview = false

mobinfohud.x = 1000
mobinfohud.y = 800

local info_text = nil
local state_icon = nil
local sight_icon = nil
local sound_icon = nil
local blood_icon = nil
local scent_icon = nil
local truesight_icon = nil
local truehearing_icon = nil
local link_icon = nil

local current_icon = ''

-- =========================================================
-- INITIALIZE
-- =========================================================

function mobinfohud.initialize()

    local scale = get_scale()    

    info_text =
        texts.new('')

    info_text:size(
    math.floor(10 * scale)
)

    info_text:font(
        'Arial'
    )

    info_text:stroke_width(2)

    info_text:stroke_color(
        0,
        0,
        0
    )

    info_text:bg_alpha(0)

    info_text:hide()

    state_icon =
    images.new()

state_icon:path(
    windower.addon_path ..
    'assets/icons/AggroN.png'
)

state_icon:hide()

sight_icon =
    images.new()

sight_icon:path(
    windower.addon_path ..
    'assets/icons/Sight.png'
)

sight_icon:hide()

sound_icon =
    images.new()

sound_icon:path(
    windower.addon_path ..
    'assets/icons/Sound.png'
)

sound_icon:hide()

blood_icon =
    images.new()

blood_icon:path(
    windower.addon_path ..
    'assets/icons/Blood.png'
)

blood_icon:hide()

scent_icon =
    images.new()

scent_icon:path(
    windower.addon_path ..
    'assets/icons/Scent.png'
)

scent_icon:hide()

truesight_icon =
    images.new()

truesight_icon:path(
    windower.addon_path ..
    'assets/icons/TrueSight.png'
)

truesight_icon:hide()

truehearing_icon =
    images.new()

truehearing_icon:path(
    windower.addon_path ..
    'assets/icons/TrueHearing.png'
)

truehearing_icon:hide()

link_icon =
    images.new()

link_icon:path(
    windower.addon_path ..
    'assets/icons/Link.png'
)

link_icon:hide()

end

-- =========================================================
-- HIDE
-- =========================================================

local function hide()

    info_text:hide()

    state_icon:hide()
    sight_icon:hide()
    sound_icon:hide()
    blood_icon:hide()
    scent_icon:hide()
    truesight_icon:hide()
    truehearing_icon:hide()
    link_icon:hide()

end

-- =========================================================
-- UPDATE
-- =========================================================

-- Cache the scale we last applied so we only push :size() calls when it
-- actually changes (every frame otherwise — needlessly).
local last_applied_scale = nil

function mobinfohud.update()

    if not mobinfohud.visible then

        hide()

        return

    end

    local scale = get_scale()

    if scale ~= last_applied_scale then

        local s = 20 * scale

        state_icon:size(s, s)
        sight_icon:size(s, s)
        sound_icon:size(s, s)
        blood_icon:size(s, s)
        scent_icon:size(s, s)
        truesight_icon:size(s, s)
        truehearing_icon:size(s, s)
        link_icon:size(s, s)

        info_text:size(math.floor(10 * scale))

        last_applied_scale = scale

    end

    -- =====================================================
    -- PREVIEW
    -- =====================================================

    if mobinfohud.preview then

        info_text:text(
            'Lv 120-125'
       )

        info_text:pos(
            mobinfohud.x,
            mobinfohud.y
        )

        info_text:show()


state_icon:pos(
    mobinfohud.x + 110,
    mobinfohud.y - 4
)

state_icon:show()

local preview_icons = {
    truesight_icon,
    truehearing_icon,
    sight_icon,
    sound_icon,
    blood_icon,
    scent_icon,
    link_icon
}

local icon_start =
    110 + (40 * scale)

local icon_spacing =
    28 * scale

for i, icon in ipairs(preview_icons) do

    icon:pos(
        mobinfohud.x +
        icon_start +
        ((i - 1) * icon_spacing),
        mobinfohud.y - 4
    )

    icon:show()

end

return

    end

    -- =====================================================
    -- TARGET
    -- =====================================================

    local target =
        windower.ffxi
        .get_mob_by_target('t')

    if not target then

        hide()

        return

    end

    -- =====================================================
    -- ONLY ENEMIES
    -- =====================================================

    if target.spawn_type ~= 16 then

        hide()

        return

    end

    -- =====================================================
    -- INFO
    -- =====================================================

    local info =
    mobinfo.get_target_info()

if not info then

    hide()

    return

end

local icon_name = 'PassiveNQ.png'

if info.Aggro and info.NM then

    icon_name = 'AggroNM.png'

elseif info.Aggro then

    icon_name = 'AggroN.png'

elseif info.NM then

    icon_name = 'PassiveHQ.png'

end

if current_icon ~= icon_name then

    current_icon = icon_name

    state_icon:path(
        windower.addon_path ..
        'assets/icons/' ..
        icon_name
    )

end

    -- =====================================================
    -- LEVEL
    -- =====================================================

    local level =
        mobinfo.get_level_string(
            info
        )

    -- =====================================================
    -- STATUS ICONS
    -- =====================================================

    local visible_icons = {}

if info.Aggro then

    if info.TrueSight then
       table.insert(visible_icons, truesight_icon)
    end

    if info.TrueHearing then
       table.insert(visible_icons, truehearing_icon)
    end

    if info.Sight then
       table.insert(visible_icons, sight_icon)
    end

    if info.Sound then
        table.insert(visible_icons, sound_icon)
    end

    if info.Blood then
        table.insert(visible_icons, blood_icon)
    end

    if info.Scent then
    table.insert(visible_icons, scent_icon)
end

    if info.Link then
    table.insert(visible_icons, link_icon)
end

end

local icon_start =
    110 + (40 * scale)

local icon_spacing =
    28 * scale

for i, icon in ipairs(visible_icons) do

    icon:pos(
        mobinfohud.x +
        icon_start +
        ((i - 1) * icon_spacing),
        mobinfohud.y - 4
    )

    icon:show()

end
    
        if not info.Aggro or not info.Sight then

    sight_icon:hide()

end
  
        if not info.Aggro or not info.Sound then

    sound_icon:hide()

end

        if not info.Aggro or not info.TrueSight then

    truesight_icon:hide()

end

if not info.Aggro or not info.TrueHearing then

    truehearing_icon:hide()

end

        if not info.Aggro or not info.Scent then

    scent_icon:hide()

end

        if not info.Aggro or not info.Blood then

    blood_icon:hide()

end

        if not info.Link then

    link_icon:hide()

end
    -- =====================================================
    -- DRAW
    -- =====================================================

    info_text:text(
    'Lv ' ..
    tostring(level)
)

    info_text:pos(
        mobinfohud.x,
        mobinfohud.y
    )

    state_icon:pos(
    mobinfohud.x + 110,
    mobinfohud.y - 4
)

    state_icon:show()

    info_text:show()

end
-- =========================================================
-- DESTROY
-- =========================================================

function mobinfohud.destroy()

    if info_text then

        info_text:destroy()

    end

    if state_icon then
    state_icon:destroy()
end

if sight_icon then
    sight_icon:destroy()
end

if sound_icon then
    sound_icon:destroy()
end

if blood_icon then
    blood_icon:destroy()
end

if scent_icon then
    scent_icon:destroy()
end

if truesight_icon then
    truesight_icon:destroy()
end

if truehearing_icon then
    truehearing_icon:destroy()
end

if link_icon then
    link_icon:destroy()
end

end

return mobinfohud