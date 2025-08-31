addon.name    = 'ventures';
addon.author  = 'Commandobill, Seekey, Phatty, and Chunk';
addon.version = '1.6.0';
addon.desc    = 'Capture and parse EXP Areas cleanly from !ventures response';

require('common');
local chat = require('chat');

-- Load modules
local config = require('configs.config');
local parser = require('services.parser');
local sorter = require('services.sorter');
local alert = require('services.alert');
local config_ui = require('services.config_ui');
local ui = require('ui.window');
local time = require('utils.time');

-- Runtime state
local zoning = false;
local zone_loaded = false;
local zone_entry_time = 0;
local auto_refresh_timer = time.now();

-- Handle command input
ashita.events.register('command', 'ventures_command_cb', function(e)
    local args = e.command:args();
    if #args == 0 then
        return;
    end

    local cmd = args[1]:lower();

    if cmd == '/ventures' then
        if args[2] == nil then
            config.toggle('show_config_gui');
        elseif args[2]:lower() == 'settings' then
            if args[3] == nil then
                print(chat.header(addon.name) .. chat.message('Current Settings:'));
                print(chat.header(addon.name) .. ('- GUI: ' .. (config.get('show_gui') and 'ON' or 'OFF')));
                print(chat.header(addon.name) .. ('- Alerts: ' .. (config.get('enable_alerts') and 'ON' or 'OFF')));
                print(chat.header(addon.name) .. ('- Audio: ' .. (config.get('enable_audio') and 'ON' or 'OFF')));
                print(chat.header(addon.name) .. ('- Sort: ' .. config.get('sort_by') .. ' ' .. (config.get('sort_ascending') and 'Ascending' or 'Descending')));
            else
                local setting = args[3]:lower();
                if setting == 'gui' then
                    config.toggle('show_gui');
                    print(chat.header(addon.name) .. chat.message('GUI toggled ' .. (config.get('show_gui') and 'ON' or 'OFF')));
                elseif setting == 'alerts' then
                    config.toggle('enable_alerts');
                    print(chat.header(addon.name) .. chat.message('Alerts toggled ' .. (config.get('enable_alerts') and 'ON' or 'OFF')));
                elseif setting == 'audio' then
                    config.toggle('enable_audio');
                    print(chat.header(addon.name) .. chat.message('Audio alerts toggled ' .. (config.get('enable_audio') and 'ON' or 'OFF')));
                elseif setting == 'debug' then
                    config.toggle('debug');
                    print(chat.header(addon.name) .. chat.message('Debug toggled ' .. (config.get('debug') and 'ON' or 'OFF')));
                else
                    print(chat.header(addon.name) .. chat.error('Unknown settings option: ' .. setting));
                end
            end
            return true;
        elseif args[2]:lower() == 'config' then
            config.toggle('show_config_gui');
        elseif args[2]:lower() == 'force' then
            parser:send_ventures_command();
            return true;
        end
    end
    return false;
end);

-- Handle text input
ashita.events.register('text_in', 'ventures_textin_cb', function(e) 
    if not parser.capture_active then
        return;
    end

    if e.injected then
        return;
    end

    if not e.message or e.message == '' then
        return;
    end

    local mode = e.mode % 256;

    if not parser.header_detected then
        if (mode == 121) and string.find(e.message, "=== Today's Goblin Ventures ===") then
            parser.header_detected = true;
            e.blocked = true;
        end
        return;
    end

    if mode == 9 and (string.find(e.message, "%(%d+%-%d+%)") or string.find(e.message, "HVNM")) then

        e.blocked = true;
        local entry = { mode = mode, message = e.message };
        table.insert(parser.capture_lines, entry);

        if string.find(e.message, "HVNM:") then
            parser.capture_active = false;
            local ventures = parser:parse_exp_areas(parser.capture_lines);
            for _, venture in ipairs(ventures) do
                alert:check_venture(venture);
            end
            return;
        end

        
    end

    if #parser.capture_lines >= parser.max_lines then
        parser.capture_active = false;
        local ventures = parser:parse_exp_areas(parser.capture_lines);
        for _, venture in ipairs(ventures) do
            alert:check_venture(venture);
        end
    end
end);

-- Handle packet input
ashita.events.register('packet_in', 'packet_in_cb', function(e)
    local id = e.id;

    -- Zone enter packet
    if id == 0x0A then
        zoning = true;
        zone_loaded = false;
        zone_entry_time = time.now();
        auto_refresh_timer = time.now();
        return;
    end

    -- Wait for first 0x111 packet after zoning starts
    if zoning and not zone_loaded and id == 0x05E then
        zone_loaded = true;
        zoning = false;
        if parser:send_ventures_command() then
            auto_refresh_timer = time.now();
        end
        return;
    end
end);

-- Handle GUI and auto-refresh
ashita.events.register('d3d_present', 'ventures_present_cb', function()
    local ventures = parser:get_ventures();
    ventures = sorter:sort(ventures);
    ui:draw(ventures);
    config_ui:draw();

    if zoning and not zone_loaded and time.has_elapsed(zone_entry_time, config.get('auto_refresh_interval')) then
        zoning = false;
        zone_loaded = true;
        print(chat.header(addon.name) .. chat.warning('Fallback: Zone timer expired. Proceeding.'));
        parser:send_ventures_command();
        return;
    end

    if time.has_elapsed(auto_refresh_timer, config.get('auto_refresh_interval')) then
        
        if parser:send_ventures_command() then
            auto_refresh_timer = time.now();
        end

    end

    if parser.capture_active and time.has_elapsed(parser.capture_start_time, parser.capture_timeout) then
        parser.capture_active = false;
        local ventures = parser:parse_exp_areas(parser.capture_lines);
        for _, venture in ipairs(ventures) do
            alert:check_venture(venture);
        end
    end
end);

-- Startup message
print(chat.header(addon.name) .. chat.success('Loaded. Type /ventures config to configure.'));

-- Auto-populate data on load
parser:send_ventures_command();