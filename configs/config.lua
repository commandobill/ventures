-- config.lua
local default_settings = T{
    show_gui = true;
    enable_alerts = true;
    enable_audio = true;
    alert_threshold = 90;
    audio_alert_threshold = 100;
    auto_refresh_interval = 60; -- seconds
    selected_sound = 0;
    sort_by = 'completion'; -- 'level', 'area', 'completion'
    sort_ascending = false;
    debug = false;
    show_config_gui = false;
    stopped_indicator = 'x';
    fast_indicator = '^';
    slow_indicator = '=';
    notes_visible = false;
    level_range_label = 'Level Range';
    area_label = 'Area';
    completion_label = 'Completion';
    hide_sorting_text = false;
};

local settings = require('settings');
local config_data = settings.load(default_settings);  -- Only holds settings data

--=============================================================================
-- Registers a callback for the settings to monitor for character switches.
--=============================================================================
settings.register('settings', 'settings_update', function (s)
    if (s ~= nil) then
        config_data = s;
    end
    settings.save();
end);

-- Define a helper table to wrap logic around the config data
local config = {};

function config.get(key)
    return config_data[key];
end;

function config.set(key, value)
    config_data[key] = value;
    settings.save();
end;

function config.toggle(key)
    if type(config_data[key]) == 'boolean' then
        config_data[key] = not config_data[key];
        settings.save();
        return config_data[key];
    end;
    return nil;
end;

function config.raw()
    return config_data;
end;

return config;
