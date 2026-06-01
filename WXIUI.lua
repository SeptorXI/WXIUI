_addon.name = 'WXIUI'
_addon.author = 'Taru Gaming'
_addon.version = '1.0'
_addon.commands = {'wxiui'}

require('tables')
require('strings')
require('resources')

local images = require('images')

-- MODULES
local playerhud = require('modules/playerhud')
local targethud = require('modules/targethud')
local tothud = require('modules/tothud')
local castbar = require('modules/castbar')
local buffhud = require('modules/buffhud')
local debuffhud = require('modules/debuffhud')
local partyhud = require('modules/partyhud')
local experiencehud = require('modules/experiencehud')
local distancehud = require('modules/distancehud')
local mobinfohud = require('modules/mobinfohud')
local gilhud = require('modules/gilhud')
local zonehud = require('modules/zonehud')
local inventoryhud = require('modules/inventoryhud')
local pethud = require('modules/pethud')
local partyinvite = require('modules/partyinvite')
local tradeinvite = require('modules/tradeinvite')
local lootnotify = require('modules/lootnotify')
local configmenu = require('modules/configmenu')
        

-- SYSTEMS
local actiontracker = require('systems/actiontracker')
local bufftracker = require('systems/bufftracker')
local targetdebuffs = require('systems/targetdebuffs')

local settings = require('data/settings')

local moving_module = nil
local hidden_by_event = false
local move_start_time = 0

-- =========================================================
-- EVENT / CUTSCENE HIDE
-- =========================================================

local STATUS_ID_CUTSCENES = 0x04


windower.register_event(
    'status change',

    function(new_status_id)

        if new_status_id ==
           STATUS_ID_CUTSCENES
        then

            hidden_by_event = true

        else

            hidden_by_event = false

        end

    end
)


-- TRADE REQUEST
windower.register_event(
    'incoming chunk',

    function(id, data)

        if id ~= 0x021 then
            return
        end

        local trader =
            windower.ffxi.get_mob_by_id(
                data:unpack('I', 5)
            )

        if not trader then
            return
        end

        windower.add_to_chat(
            207,
             '[WXIUI] Trade request from '..trader.name
        )

        tradeinvite.trader =
            trader.name

        tradeinvite.show_time =
            os.time()

        tradeinvite.visible =
            true

    end
)

-- PARTY INVITATION
windower.register_event(
    'party invite',

    function(sender)

        partyinvite.sender =
            sender

        partyinvite.show_time =
            os.time()

        partyinvite.visible =
            true

    end
)

-- =========================================================
-- HUD REGISTRY
--
-- Single source of truth for everything driven per-HUD: settings,
-- visibility, command dispatch, drag preview, save/restore.
-- Adding a HUD = adding one row here.
--
-- Fields:
--   name             - command-string name (also key in settings.lua)
--   module           - the required module table
--   has_preview      - module supports a `preview` boolean flag
--   has_stop_preview - module exposes `stop_preview()` (zonehud)
--   visibility       - 'settings' (toggleable + saved) or 'always'
-- =========================================================

local huds = {
    { name = 'playerhud',     module = playerhud,     has_preview = true,  visibility = 'settings' },
    { name = 'targethud',     module = targethud,     has_preview = true,  visibility = 'settings' },
    { name = 'tothud',        module = tothud,        has_preview = true,  visibility = 'always'   },
    { name = 'castbar',       module = castbar,       has_preview = true,  visibility = 'settings' },
    { name = 'buffhud',       module = buffhud,       has_preview = true,  visibility = 'settings' },
    { name = 'debuffhud',     module = debuffhud,     has_preview = true,  visibility = 'settings' },
    { name = 'partyhud',      module = partyhud,      has_preview = true,  visibility = 'settings' },
    { name = 'experiencehud', module = experiencehud, has_preview = true,  visibility = 'settings' },
    { name = 'distancehud',   module = distancehud,   has_preview = true,  visibility = 'settings' },
    { name = 'mobinfohud',    module = mobinfohud,    has_preview = true,  visibility = 'settings' },
    { name = 'gilhud',        module = gilhud,        has_preview = true,  visibility = 'always'   },
    { name = 'zonehud',       module = zonehud,       has_preview = true,  has_stop_preview = true, visibility = 'always' },
    { name = 'inventoryhud',  module = inventoryhud,  has_preview = true,  visibility = 'always'   },
    { name = 'pethud',        module = pethud,        has_preview = true,  visibility = 'always'   },
    { name = 'lootnotify',    module = lootnotify,    has_preview = true,  visibility = 'always'   },
}

-- Lookup table by name for the command dispatcher.
local hud_by_name = {}
for _, h in ipairs(huds) do hud_by_name[h.name] = h end

-- LOAD VISIBILITY
for _, h in ipairs(huds) do
    if h.visibility == 'settings' then
        h.module.visible = settings[h.name].visible
    else
        h.module.visible = true
    end
end


-- GRID
local snap_size = 8

local grid_tiles = {}

local GRID_TILE_SIZE = 256

-- =========================================================
-- CREATE GRID
-- =========================================================

local function create_grid()

    if #grid_tiles > 0 then
        return
    end

    local screen_w =
        windower
        .get_windower_settings()
        .ui_x_res

    local screen_h =
        windower
        .get_windower_settings()
        .ui_y_res

    local texture =
        windower.addon_path ..
        'assets/textures/grid_overlay.png'

    for x = 0,
        screen_w,
        GRID_TILE_SIZE
    do

        for y = 0,
            screen_h,
            GRID_TILE_SIZE
        do

            local tile =
                images.new()

            tile:path(texture)

            tile:width(
                GRID_TILE_SIZE
            )

            tile:height(
                GRID_TILE_SIZE
            )

            tile:pos(x, y)

            tile:alpha(120)

            tile:show()

            table.insert(
                grid_tiles,
                tile
            )

        end

    end

end

-- =========================================================
-- DESTROY GRID
-- =========================================================

local function destroy_grid()

    for _, tile in
        pairs(grid_tiles)
    do

        tile:destroy()

    end

    grid_tiles = {}

end

-- =========================================================
-- SAVE SETTINGS
-- =========================================================

local function save_settings()

    local path =
        windower.addon_path ..
        'data/settings.lua'

    local file =
        io.open(path, 'w+')

    if not file then
        return
    end

    file:write('return {\n')

    for i, h in ipairs(huds) do

        local sep = (i < #huds) and ',\n\n' or '\n'

        file:write(string.format(
            '    %s = {\n        x = %d,\n        y = %d,\n        visible = %s,\n        scale = %d\n    }%s',
            h.name,
            h.module.x,
            h.module.y,
            tostring(h.module.visible),
            settings[h.name].scale,
            sep
        ))

    end

    file:write('}')

    file:close()

end

_G.save_settings = save_settings
-- =========================================================
-- COMMANDS
-- =========================================================

windower.register_event(
    'addon command',
    function(...)

        local args = {...}

        local cmd =
            args[1] and
            args[1]:lower()

        local module =
            args[2] and
            args[2]:lower()

        local hud =
            nil

        if cmd == 'config' then

            configmenu.show()

            return

        end

        if cmd == 'help' or cmd == nil then

            windower.add_to_chat(207, '[WXIUI] Commands:')
            windower.add_to_chat(207, '  //wxiui config              - Open config menu')
            windower.add_to_chat(207, '  //wxiui show <hud>          - Show a HUD')
            windower.add_to_chat(207, '  //wxiui hide <hud>          - Hide a HUD')
            windower.add_to_chat(207, '  //wxiui toggle <hud>        - Toggle a HUD')
            windower.add_to_chat(207, '  //wxiui move <hud>          - Drag-position a HUD')

            local names = {}
            for _, h in ipairs(huds) do names[#names + 1] = h.name end
            windower.add_to_chat(207, '  Known HUDs: ' .. table.concat(names, ', '))

            return

        end

        local registry_entry = module and hud_by_name[module]

        if registry_entry then
            hud = registry_entry.module
        end

        if module and not hud then

            windower.add_to_chat(
                167,
                '[WXIUI] Unknown module.'
            )

            return

        end

        -- HIDE
if cmd == 'hide' and hud then

    hud.visible = false

    if settings[module] then
        settings[module].visible = false
    end

    save_settings()

    return

end

        -- SHOW
if cmd == 'show' and hud then

    hud.visible = true

    if settings[module] then
        settings[module].visible = true
    end

    save_settings()

    return

end

        -- TOGGLE
if cmd == 'toggle' and hud then

    hud.visible =
        not hud.visible

    if settings[module] then
        settings[module].visible =
            hud.visible
    end

    save_settings()

    return

end

        -- MOVE
        if cmd == 'move' and hud then

            moving_module = hud

            move_start_time = os.clock()

            create_grid()

            if registry_entry and registry_entry.has_preview then
                hud.preview = true
            end

            windower.add_to_chat(
                207,
                '[WXIUI] Moving: ' .. module
            )

            return

        end

    end
)

-- =========================================================
-- LOAD
-- =========================================================

windower.register_event(
    'load',
    function()

        -- Initialize every HUD that has a lifecycle method (lootnotify
        -- doesn't — it allocates per-notification).
        for _, h in ipairs(huds) do
            if h.module.initialize then
                h.module.initialize()
            end
        end

        partyinvite.initialize()
        tradeinvite.initialize()
        configmenu.initialize()

        -- Restore saved positions.
        for _, h in ipairs(huds) do
            h.module.x = settings[h.name].x
            h.module.y = settings[h.name].y
        end

    end
)

-- =========================================================
-- UPDATE
-- =========================================================

windower.register_event(
    'prerender',
    function()

        local player =
            windower.ffxi.get_player()

        -- =================================================
        -- HIDE HUD OUTSIDE GAME
        -- =================================================

        if not player or
           not player.name
        then

            hidden_by_event = true

            for _, h in ipairs(huds) do
                h.module.visible = false
            end

            return

        end

        -- =================================================
        -- MENU / EVENT HIDE
        -- =================================================

        for _, h in ipairs(huds) do
            h.module.visible =
                not hidden_by_event and
                settings[h.name].visible
        end

        -- =================================================
        -- SYSTEMS
        -- =================================================

        if bufftracker and bufftracker.update then
            bufftracker.update()
        end

        if targetdebuffs and targetdebuffs.update then
            targetdebuffs.update()
        end

        -- =================================================
        -- HUDS
        -- =================================================

        for _, h in ipairs(huds) do
            h.module.update()
        end

        partyinvite.update()
        tradeinvite.update()
        configmenu.update()

    end
)

-- =========================================================
-- DRAG SYSTEM
-- =========================================================

windower.register_event(
    'mouse',

    function(
        type,
        x,
        y,
        delta,
        blocked
    )

-- MOUSE BUTTONS

if type == 1 then

    if partyinvite.click(x, y) then
        return true
    end

    if tradeinvite.click(x, y) then
        return true
    end

    if configmenu.click(x, y) then
        return true
    end

end
        buffhud.mouse_x = x
        buffhud.mouse_y = y

        debuffhud.mouse_x = x
        debuffhud.mouse_y = y

        configmenu.mouse_move(x, y)

        if not moving_module then
            return
        end

-- LEFT CLICK

if type == 2 and
   os.clock() - move_start_time > 0.25
then
            destroy_grid()

            -- Find the registry row for the module being moved, then
            -- exit preview using whatever mechanism it supports.
            for _, h in ipairs(huds) do
                if moving_module == h.module then
                    if h.has_preview then
                        h.module.preview = false
                    end
                    if h.has_stop_preview then
                        h.module.stop_preview()
                    end
                    break
                end
            end

            -- Castbar still needs its explicit hide() to tear down
            -- the bar prim when preview ends.
            if moving_module == castbar then
                castbar.hide()
            end

            moving_module = nil

            save_settings()

            if configmenu.resume_after_move then

                configmenu.resume_after_move = false

                configmenu.show()

            end

            windower.add_to_chat(
                207,
                '[WXIUI] Position saved.'
            )

            return

        end

        -- MOUSE MOVE
        if type == 0 then

            local snapped_x =
                math.floor(
                    x / snap_size
                ) *
                snap_size

            local snapped_y =
                math.floor(
                    y / snap_size
                ) *
                snap_size

            moving_module.x =
                snapped_x

            moving_module.y =
                snapped_y

        end

    end
)

-- =========================================================
-- UNLOAD
-- =========================================================

windower.register_event(
    'unload',
    function()

        destroy_grid()

        for _, h in ipairs(huds) do
            if h.module.destroy then
                h.module.destroy()
            end
        end

        partyinvite.destroy()
        tradeinvite.destroy()
        configmenu.destroy()

    end
)
