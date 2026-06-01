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

-- LOAD VISIBILITY
playerhud.visible = settings.playerhud.visible
targethud.visible = settings.targethud.visible
buffhud.visible = settings.buffhud.visible
debuffhud.visible = settings.debuffhud.visible
partyhud.visible = settings.partyhud.visible
castbar.visible = settings.castbar.visible
experiencehud.visible = settings.experiencehud.visible
distancehud.visible = settings.distancehud.visible
mobinfohud.visible = settings.mobinfohud.visible

tothud.visible = true
gilhud.visible = true
zonehud.visible = true
inventoryhud.visible = true
pethud.visible = true


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

    file:write(string.format(
    '    playerhud = {\n        x = %d,\n        y = %d,\n        visible = %s,\n        scale = %d\n    },\n\n',
    playerhud.x,
    playerhud.y,
    tostring(playerhud.visible),
    settings.playerhud.scale
))

    file:write(string.format(
        '    targethud = {\n        x = %d,\n        y = %d,\n        visible = %s,\n        scale = %d\n    },\n\n',
        targethud.x,
        targethud.y,
        tostring(targethud.visible),
        settings.targethud.scale
    ))

    file:write(string.format(
        '    buffhud = {\n        x = %d,\n        y = %d,\n        visible = %s,\n        scale = %d\n    },\n\n',
        buffhud.x,
        buffhud.y,
        tostring(buffhud.visible),
        settings.buffhud.scale
    ))

    file:write(string.format(
        '    debuffhud = {\n        x = %d,\n        y = %d,\n        visible = %s,\n        scale = %d\n    },\n\n',
        debuffhud.x,
        debuffhud.y,
        tostring(debuffhud.visible),
        settings.debuffhud.scale
    ))

    file:write(string.format(
        '    partyhud = {\n        x = %d,\n        y = %d,\n        visible = %s,\n        scale = %d\n    },\n\n',
        partyhud.x,
        partyhud.y,
        tostring(partyhud.visible),
        settings.partyhud.scale
    ))

    file:write(string.format(
        '    castbar = {\n        x = %d,\n        y = %d,\n        visible = %s,\n        scale = %d\n    },\n\n',
        castbar.x,
        castbar.y,
        tostring(castbar.visible),
        settings.castbar.scale
    ))

    file:write(string.format(
        '    experiencehud = {\n        x = %d,\n        y = %d,\n        visible = %s,\n        scale = %d\n    },\n\n',
        experiencehud.x,
        experiencehud.y,
        tostring(experiencehud.visible),
        settings.experiencehud.scale
    ))

    file:write(string.format(
        '    distancehud = {\n        x = %d,\n        y = %d,\n        visible = %s,\n        scale = %d\n    },\n\n',
        distancehud.x,
        distancehud.y,
        tostring(distancehud.visible),
        settings.distancehud.scale
    ))

    file:write(string.format(
        '    mobinfohud = {\n        x = %d,\n        y = %d,\n        visible = %s,\n        scale = %d\n    },\n\n',
        mobinfohud.x,
        mobinfohud.y,
        tostring(mobinfohud.visible),
        settings.mobinfohud.scale
    ))

    file:write(string.format(
        '    gilhud = {\n        x = %d,\n        y = %d,\n        visible = %s,\n        scale = %d\n    },\n\n',
        gilhud.x,
        gilhud.y,
        tostring(gilhud.visible),
        settings.gilhud.scale
    ))

    file:write(string.format(
        '    zonehud = {\n        x = %d,\n        y = %d,\n        visible = %s,\n        scale = %d\n    },\n\n',
        zonehud.x,
        zonehud.y,
        tostring(zonehud.visible),
        settings.zonehud.scale
    ))

    file:write(string.format(
        '    inventoryhud = {\n        x = %d,\n        y = %d,\n        visible = %s,\n        scale = %d\n    },\n\n',
        inventoryhud.x,
        inventoryhud.y,
        tostring(inventoryhud.visible),
        settings.inventoryhud.scale
    ))

    file:write(string.format(
        '    pethud = {\n        x = %d,\n        y = %d,\n        visible = %s,\n        scale = %d\n    },\n\n',
        pethud.x,
        pethud.y,
        tostring(pethud.visible),
        settings.pethud.scale
    ))

    file:write(string.format(
        '    lootnotify = {\n        x = %d,\n        y = %d,\n        visible = %s,\n        scale = %d\n    },\n\n',
        lootnotify.x,
        lootnotify.y,
        tostring(lootnotify.visible),
        settings.lootnotify.scale
    ))   
   
    file:write(string.format(
        '    tothud = {\n        x = %d,\n        y = %d,\n        visible = %s,\n        scale = %d\n    }\n',
        tothud.x,
        tothud.y,
        tostring(tothud.visible),
        settings.tothud.scale
    ))

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

        if module == 'playerhud' then
            hud = playerhud

        elseif module == 'targethud' then
            hud = targethud

        elseif module == 'tothud' then
            hud = tothud

        elseif module == 'buffhud' then
            hud = buffhud

        elseif module == 'debuffhud' then
            hud = debuffhud

        elseif module == 'partyhud' then
            hud = partyhud

        elseif module == 'castbar' then
            hud = castbar

        elseif module == 'experiencehud' then
            hud = experiencehud

        elseif module == 'distancehud' then
            hud = distancehud

        elseif module == 'mobinfohud' then
            hud = mobinfohud

        elseif module == 'gilhud' then
            hud = gilhud

        elseif module == 'zonehud' then
            hud = zonehud

        elseif module == 'inventoryhud' then
            hud = inventoryhud

        elseif module == 'pethud' then
            hud = pethud

        elseif module == 'lootnotify' then
            hud = lootnotify

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

            moving_module =
                hud

            move_start_time =
                os.clock()

            create_grid()


            if hud == targethud then
                targethud.preview = true
            end

            if hud == tothud then
                tothud.preview = true
            end

            if hud == buffhud then
                buffhud.preview = true
            end

            if hud == debuffhud then
                debuffhud.preview = true
            end

            if hud == partyhud then
                partyhud.preview = true
            end

            if hud == castbar then
                castbar.preview = true
            end

            if hud == experiencehud then
                experiencehud.preview = true
            end

            if hud == distancehud then
                distancehud.preview = true
            end

            if hud == mobinfohud then
                mobinfohud.preview = true
            end

            if hud == gilhud then
                gilhud.preview = true
            end

            if hud == zonehud then
                zonehud.preview = true
            end

            if hud == inventoryhud then
                inventoryhud.preview = true
            end

            if hud == pethud then
                pethud.preview = true
            end

            if hud == lootnotify then
                lootnotify.preview = true
            end

            windower.add_to_chat(
                207,
                '[WXIUI] Moving: ' ..
                module
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

        playerhud.initialize()
        targethud.initialize()
        tothud.initialize()
        castbar.initialize()
        buffhud.initialize()
        debuffhud.initialize()
        partyhud.initialize()
        experiencehud.initialize()
        distancehud.initialize()
        mobinfohud.initialize()
        gilhud.initialize()
        zonehud.initialize()
        inventoryhud.initialize()
        pethud.initialize()
        partyinvite.initialize()
        tradeinvite.initialize()
        configmenu.initialize()

        playerhud.x =
            settings.playerhud.x

        playerhud.y =
            settings.playerhud.y

        targethud.x =
            settings.targethud.x

        targethud.y =
            settings.targethud.y

        buffhud.x =
            settings.buffhud.x

        buffhud.y =
            settings.buffhud.y

        debuffhud.x =
            settings.debuffhud.x

        debuffhud.y =
            settings.debuffhud.y

        partyhud.x =
            settings.partyhud.x

        partyhud.y =
            settings.partyhud.y

        castbar.x =
            settings.castbar.x

        castbar.y =
            settings.castbar.y

        experiencehud.x =
            settings.experiencehud.x

        experiencehud.y =
            settings.experiencehud.y

        distancehud.x =
            settings.distancehud.x

        distancehud.y =
            settings.distancehud.y

        mobinfohud.x =
            settings.mobinfohud.x

        mobinfohud.y =
            settings.mobinfohud.y

        gilhud.x =
            settings.gilhud.x

        gilhud.y =
            settings.gilhud.y

        zonehud.x =
            settings.zonehud.x

        zonehud.y =
            settings.zonehud.y

        inventoryhud.x =
            settings.inventoryhud.x

        inventoryhud.y =
            settings.inventoryhud.y

        pethud.x =
            settings.pethud.x

        pethud.y =
            settings.pethud.y

        lootnotify.x =
           settings.lootnotify.x

        lootnotify.y =
           settings.lootnotify.y
    
        tothud.x =
            settings.tothud.x

        tothud.y =
            settings.tothud.y

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

        gilhud.visible =
            not hidden_by_event and
            settings.gilhud.visible

        -- =================================================
        -- HIDE HUD OUTSIDE GAME
        -- =================================================

        if not player or
           not player.name
        then

            hidden_by_event = true

            playerhud.visible = false
            targethud.visible = false
            tothud.visible = false
            castbar.visible = false
            buffhud.visible = false
            debuffhud.visible = false
            partyhud.visible = false
            experiencehud.visible = false
            distancehud.visible = false
            mobinfohud.visible = false
            gilhud.visible = false
            zonehud.visible = false
            inventoryhud.visible = false
            pethud.visible = false

            return

        end

        -- =================================================
        -- MENU / EVENT HIDE
        -- =================================================


        playerhud.visible =
            not hidden_by_event and
            settings.playerhud.visible

        targethud.visible =
            not hidden_by_event and
            settings.targethud.visible

        partyhud.visible =
            not hidden_by_event and
            settings.partyhud.visible

        castbar.visible =
            not hidden_by_event and
            settings.castbar.visible

        buffhud.visible =
            not hidden_by_event and
            settings.buffhud.visible

        debuffhud.visible =
            not hidden_by_event and
            settings.debuffhud.visible

        experiencehud.visible =
            not hidden_by_event and
            settings.experiencehud.visible

        distancehud.visible =
            not hidden_by_event and
            settings.distancehud.visible

        mobinfohud.visible =
            not hidden_by_event and
            settings.mobinfohud.visible

        tothud.visible =
    not hidden_by_event and
    settings.tothud.visible

zonehud.visible =
    not hidden_by_event and
    settings.zonehud.visible

inventoryhud.visible =
    not hidden_by_event and
    settings.inventoryhud.visible

pethud.visible =
    not hidden_by_event and
    settings.pethud.visible

        -- =================================================
        -- SYSTEMS
        -- =================================================

        if bufftracker and
           bufftracker.update
        then

            bufftracker.update()

        end

        if targetdebuffs and
           targetdebuffs.update
        then

            targetdebuffs.update()

        end

        -- =================================================
        -- HUDS
        -- =================================================

        playerhud.update()
        targethud.update()
        tothud.update()
        castbar.update()
        buffhud.update()
        debuffhud.update()
        partyhud.update()
        experiencehud.update()
        distancehud.update()
        mobinfohud.update()
        gilhud.update()
        zonehud.update()
        inventoryhud.update()
        pethud.update()
        partyinvite.update()
        tradeinvite.update()
        lootnotify.update()
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

            if moving_module ==
               castbar
            then

                castbar.preview =
                    false

                castbar.hide()

            end

            if moving_module ==
               targethud
            then

                targethud.preview =
                    false

            end

            if moving_module ==
               tothud
            then

                tothud.preview =
                    false

            end

            if moving_module ==
               partyhud
            then

                partyhud.preview =
                    false

            end

            if moving_module ==
               buffhud
            then

                buffhud.preview =
                    false

            end

            if moving_module ==
               debuffhud
            then

                debuffhud.preview =
                    false

            end

            if moving_module ==
               experiencehud
            then

                experiencehud.preview =
                    false

            end

            if moving_module ==
               distancehud
            then

                distancehud.preview =
                    false

            end

            if moving_module ==
               mobinfohud
            then

                mobinfohud.preview =
                    false

            end

            if moving_module ==
               gilhud
            then

                gilhud.preview =
                    false

            end

            if moving_module ==
               inventoryhud
            then

                inventoryhud.preview =
                    false

            end

            if moving_module ==
               pethud
            then

               pethud.preview =
                    false

            end
            
            if moving_module ==
               lootnotify
            then

               lootnotify.preview =
                    false

             end


            if moving_module ==
               zonehud
            then

                zonehud.stop_preview()

            end

            moving_module =
                nil

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

        playerhud.destroy()
        targethud.destroy()
        tothud.destroy()
        castbar.destroy()
        buffhud.destroy()
        debuffhud.destroy()
        partyhud.destroy()
        experiencehud.destroy()
        distancehud.destroy()
        mobinfohud.destroy()
        gilhud.destroy()
        zonehud.destroy()
        inventoryhud.destroy()
        pethud.destroy()
        partyinvite.destroy()
        tradeinvite.destroy()
        lootnotify.destroy()
        configmenu.destroy()

    end
)
