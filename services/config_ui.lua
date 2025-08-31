local config = require('configs.config');
local imgui = require('imgui');
local config_ui = {};
local chat = require('chat');

-- Preload sounds
local function load_sounds()
    local folder = AshitaCore:GetInstallPath() .. '/addons/' .. addon.name .. '/sounds/';
    if not ashita.fs.exists(folder) then return {}, {}; end

    local files = ashita.fs.get_directory(folder, '.*\\.wav') or {};
    local full = T{};
    local names = T{};

    for _, f in ipairs(files) do
        full:append(f);
        names:append(f:gsub('%.wav$', ''));
    end

    return full, names
end

local sound_files, sound_labels = load_sounds();

-- Draw main window
function config_ui:draw()
    if not config.get('show_config_gui') then
        return;
    end
    --imgui.SetNextWindowSize({400, 400}, ImGuiCond_FirstUseEver);
    local open = { config.get('show_config_gui') };
    if imgui.Begin('Configuration##simpleconfig', open, ImGuiWindowFlags_AlwaysAutoResize) then

        -- Show GUI
        local gui = { config.get('show_gui') };
        if imgui.Checkbox('Show GUI', gui) then
            config.set('show_gui', gui[1]);
        end

        -- Show Alerts
        local alerts = { config.get('enable_alerts') };
        if imgui.Checkbox('Show Alerts', alerts) then
            config.set('enable_alerts', alerts[1]);
        end

        -- Notes Tooltip Visible Toggle
        local notes_visible = { config.get('notes_visible') }
        if imgui.Checkbox('Show Notes as Tooltip', notes_visible) then
            config.set('notes_visible', notes_visible[1])
        end
        
        -- Suppress Sorting Text Description (Asc) (Desc)
        local hide_sorting_text = { config.get('hide_sorting_text') }
        if imgui.Checkbox('Hide Sorting Text', hide_sorting_text) then
            config.set('hide_sorting_text', hide_sorting_text[1])
        end

        imgui.Separator();  -- visual divider between sections

        -- Play Audio
        local audio = { config.get('enable_audio') };
        if imgui.Checkbox('Play Audio', audio) then
            config.set('enable_audio', audio[1]);
        end

        -- Sound Dropdown
        local selected = config.get('selected_sound') or 0;
        local combo = { selected - 1 };
        local combo_items = table.concat(sound_labels, '\0') .. '\0';

        imgui.PushItemWidth(200);
        if imgui.Combo("Select Sound", combo, combo_items, #sound_labels) then
            config.set('selected_sound', combo[1] + 1);
        end
        imgui.PopItemWidth();

        imgui.SameLine();
        if imgui.Button(string.char(62) .. " Play") then
            local path = string.format(
                "%s\\addons\\%s\\sounds\\%s",
                AshitaCore:GetInstallPath(),
                addon.name,
                sound_files[selected]
            );
            ashita.misc.play_sound(path);
        end

        if sound_files[selected] then
            imgui.Text(string.format("File: %s", sound_files[selected]));
        end

        imgui.Separator();  -- visual divider between sections
        
        -- Alert Threshold Slider
        local alert_threshold = { config.get('alert_threshold') }
        if imgui.SliderInt('Alert Threshold', alert_threshold, 1, 100) then
            config.set('alert_threshold', alert_threshold[1]);
        end

        -- Sound Threshold
        local audio_alert_threshold = { config.get('audio_alert_threshold') }
        if imgui.SliderInt('Audio Threshold', audio_alert_threshold, 1, 100) then
            config.set('audio_alert_threshold', audio_alert_threshold[1]);
        end

        imgui.Separator();  -- visual divider between sections

        -- Indicator Characters
        local stopped_indicator = { config.get('stopped_indicator')}
        imgui.PushItemWidth(100)
        if imgui.InputText('Stopped Indicator', stopped_indicator, 2) then
            config.set('stopped_indicator', stopped_indicator[1])
        end
        imgui.PopItemWidth()
        local fast = { config.get('fast_indicator')}
        imgui.PushItemWidth(100)
        if imgui.InputText('Fast Indicator', fast, 2) then
            config.set('fast_indicator', fast[1])
        end
        imgui.PopItemWidth()
        local slow = { config.get('slow_indicator')}
        imgui.PushItemWidth(100)
        if imgui.InputText('Slow Indicator', slow, 2) then
            config.set('slow_indicator', slow[1])
        end
        imgui.PopItemWidth()

        imgui.Separator();  -- visual divider between sections

        -- Header Label Editors
        local level_range_label = { config.get('level_range_label') or 'Level Range' }
        if imgui.InputText('Level Range Header', level_range_label, 64) then
            config.set('level_range_label', level_range_label[1])
        end
        local area_label = { config.get('area_label') or 'Area' }
        if imgui.InputText('Area Header', area_label, 64) then
            config.set('area_label', area_label[1])
        end
        local completion_label = { config.get('completion_label') or 'Completion' }
        if imgui.InputText('Completion Header', completion_label, 64) then
            config.set('completion_label', completion_label[1])
        end

        imgui.Separator();  -- visual divider between sections

        -- Time Estimation Settings
        imgui.Text('Time Estimation Settings');
        imgui.Separator();
        
        -- Enable Time Estimation
        local time_estimation = { config.get('enable_time_estimation') };
        if imgui.Checkbox('Enable Time Estimation', time_estimation) then
            config.set('enable_time_estimation', time_estimation[1]);
        end
        
        -- Minimum Data Points
        local min_data_points = { config.get('min_data_points') };
        if imgui.SliderInt('Min Data Points for Prediction', min_data_points, 3, 8) then
            config.set('min_data_points', min_data_points[1]);
        end
        
        -- Show Completion Time
        local show_completion_time = { config.get('show_completion_time') };
        if imgui.Checkbox('Show Completion Time', show_completion_time) then
            config.set('show_completion_time', show_completion_time[1]);
        end


    end
    imgui.End();
    config.set('show_config_gui', open[1])
end

return config_ui;