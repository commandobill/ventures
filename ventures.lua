addon.name    = 'ventures';
addon.author  = 'Commandobill, Seekey, and Phatty';
addon.version = '2.0.1';
addon.desc    = 'Capture and parse EXP Areas cleanly from the ventures packet';

require('common');
local chat = require('chat');

-- Load modules
local config = require('configs.config');
local vnm_loader = require('services.vnm_loader');
vnm_loader:update_on_load();

local parser = require('services.parser');
local sorter = require('services.sorter');
local alert = require('services.alert');
local config_ui = require('services.config_ui');
local ui = require('ui.window');

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
                print(chat.header(addon.name) .. ('- Mode: ' .. (config.get('venture_mode') or 'ACE')));
                print(chat.header(addon.name) .. ('- Pool: ' .. (config.get('venture_pool_filter') or 'All')));
                print(chat.header(addon.name) .. ('- Equipment Column: ' .. (config.get('show_equipment_column') and 'ON' or 'OFF')));
                print(chat.header(addon.name) .. ('- Global ImGui Style: ' .. (config.get('use_global_imgui_style') and 'ON' or 'OFF')));
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
            local ventures = parser:refresh_venture_mode();
            for _, venture in ipairs(ventures) do
                alert:check_venture(venture);
            end
            return true;
        elseif args[2]:lower() == 'update' then
            local ok, err = vnm_loader:update();
            if ok then
                parser:reload_vnm_data();
                parser:refresh_venture_mode();
                print(chat.header(addon.name) .. chat.success('Updated VNM data from GitHub.'));
            else
                print(chat.header(addon.name) .. chat.error('Failed to update VNM data: ' .. tostring(err)));
            end
            return true;
        end
    end
    return false;
end);

-- Handle packet input
ashita.events.register('packet_in', 'packet_in_cb', function(e)
    local id = e.id;

    if id == 0x1A3 then
        local ventures = parser:parse_venture_packet(e.data);
        for _, venture in ipairs(ventures) do
            alert:check_venture(venture);
        end
        return;
    end
end);

-- Handle GUI
ashita.events.register('d3d_present', 'ventures_present_cb', function()
    local ventures = parser:get_ventures();
    ventures = sorter:sort(ventures);
    ui:draw(ventures);
    config_ui:draw();
end);

-- Startup message
print(chat.header(addon.name) .. chat.success('Loaded. Type /ventures config to configure.'));
