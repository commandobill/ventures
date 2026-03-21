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

        -- Show HVNM in header
        local show_hvnm_title = { config.get('show_hvnm_title') };
        if imgui.Checkbox('Show HVNM when collapsed', show_hvnm_title) then
            config.set('show_hvnm_title', show_hvnm_title[1]);
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

        -- Grid Visibility
        local show_vgrid = { config.get('show_vertical_grid') }
        if imgui.Checkbox('Show Vertical Grid', show_vgrid) then
            config.set('show_vertical_grid', show_vgrid[1])
        end
        local show_hgrid = { config.get('show_horizontal_grid') }
        if imgui.Checkbox('Show Horizontal Grid', show_hgrid) then
            config.set('show_horizontal_grid', show_hgrid[1])
        end

        imgui.Separator();  -- visual divider between sections

        -- Window & Column Widths
        imgui.Text('Window & Column Widths (px)');

        local window_width = { config.get('window_width') or 700 }
        imgui.PushItemWidth(200)
        if imgui.SliderInt('Window Width', window_width, 300, 1200) then
            config.set('window_width', window_width[1])
        end
        imgui.PopItemWidth()

        local col_lr = { config.get('col_level_range_width') or 125 }
        imgui.PushItemWidth(200)
        if imgui.SliderInt('Level Range Col', col_lr, 50, 400) then
            config.set('col_level_range_width', col_lr[1])
        end
        imgui.PopItemWidth()

        local col_area = { config.get('col_area_width') or 175 }
        imgui.PushItemWidth(200)
        if imgui.SliderInt('Area Col', col_area, 50, 400) then
            config.set('col_area_width', col_area[1])
        end
        imgui.PopItemWidth()

        local col_comp = { config.get('col_completion_width') or 150 }
        imgui.PushItemWidth(200)
        if imgui.SliderInt('Completion Col', col_comp, 50, 400) then
            config.set('col_completion_width', col_comp[1])
        end
        imgui.PopItemWidth()

        local col_loc = { config.get('col_location_width') or 250 }
        imgui.PushItemWidth(200)
        if imgui.SliderInt('Location Col', col_loc, 50, 500) then
            config.set('col_location_width', col_loc[1])
        end
        imgui.PopItemWidth()

    end
    imgui.End();
    config.set('show_config_gui', open[1])
end

return config_ui;