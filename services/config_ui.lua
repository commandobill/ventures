local config = require('configs.config');
local imgui = require('imgui');
local config_ui = {};
local chat = require('chat');
local parser = require('services.parser');


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

local function draw_equipment_filter()
    imgui.Separator();

    local filter_enabled = { config.get('show_equipment_filter') };
    if imgui.Checkbox('Filter by Needed Equipment', filter_enabled) then
        config.set('show_equipment_filter', filter_enabled[1]);
    end

    if not filter_enabled[1] then
        return;
    end

    imgui.Indent();
    imgui.TextDisabled('Check the equipment you still need.');
	imgui.TextDisabled('Only zones dropping a checked item will be shown.');

    local needed = config.get('needed_equipment') or {};
    local options = parser:get_equipment_options();

    local function draw_checkbox(label)
        local checked = { needed[label] == true };
        if imgui.Checkbox('##eq_' .. label, checked) then
            local current = config.get('needed_equipment') or {};
            if checked[1] then
                current[label] = true;
            else
                current[label] = nil;
            end
            config.set('needed_equipment', current);
        end
    end

    local all_checked = true;
    for _, label in ipairs(options) do
        if needed[label] ~= true then
            all_checked = false;
            break;
        end
    end

    if imgui.Button(all_checked and 'Uncheck All' or 'Check All') then
        local current = config.get('needed_equipment') or {};
        local new_value = not all_checked;
        for _, label in ipairs(options) do
            current[label] = new_value or nil;
        end
        config.set('needed_equipment', current);
        needed = current;
    end

    imgui.Separator();

    for _, label in ipairs(options) do
        draw_checkbox(label);
        imgui.SameLine();
        imgui.Text(label);
    end

    imgui.Unindent();
end

local function draw_crest_filter()
    imgui.Separator();

    local filter_enabled = { config.get('show_crest_filter') };
    if imgui.Checkbox('Filter by Needed Crest', filter_enabled) then
        config.set('show_crest_filter', filter_enabled[1]);
    end

    if not filter_enabled[1] then
        return;
    end

    imgui.Indent();
    imgui.TextDisabled('Check the crest types you still need.');
    imgui.TextDisabled('Only zones dropping a checked crest will be shown.');

    local needed = config.get('needed_crest') or {};
    local options = parser:get_crest_options();

    local function draw_checkbox(label)
        local checked = { needed[label] == true };
        if imgui.Checkbox('##crest_' .. label, checked) then
            local current = config.get('needed_crest') or {};
            if checked[1] then
                current[label] = true;
            else
                current[label] = nil;
            end
            config.set('needed_crest', current);
        end
    end

    local all_checked = true;
    for _, label in ipairs(options) do
        if needed[label] ~= true then
            all_checked = false;
            break;
        end
    end

    if imgui.Button(all_checked and 'Uncheck All##crest' or 'Check All##crest') then
        local current = config.get('needed_crest') or {};
        local new_value = not all_checked;
        for _, label in ipairs(options) do
            current[label] = new_value or nil;
        end
        config.set('needed_crest', current);
        needed = current;
    end

    imgui.Separator();

    for _, label in ipairs(options) do
        draw_checkbox(label);
        imgui.SameLine();
        imgui.Text(label);
    end

    imgui.Unindent();
end

-- Draw main window
function config_ui:draw()
    if not config.get('show_config_gui') then
        return;
    end
    --imgui.SetNextWindowSize({400, 400}, ImGuiCond_FirstUseEver);
	imgui.SetNextWindowSizeConstraints({0, 0}, {FLT_MAX, 700});
    local open = { config.get('show_config_gui') };
    local use_global_imgui_style = config.get('use_global_imgui_style');

    if not use_global_imgui_style then
        imgui.PushStyleColor(ImGuiCol_WindowBg, {0,0.06,0.16,0.9});
        imgui.PushStyleColor(ImGuiCol_TitleBg, {0,0.06,0.16,0.7});
        imgui.PushStyleColor(ImGuiCol_TitleBgActive, {0,0.06,0.16,0.9});
        imgui.PushStyleColor(ImGuiCol_TitleBgCollapsed, {0,0.06,0.16,0.5});
    end

    if imgui.Begin('Configuration##simpleconfig', open, ImGuiWindowFlags_AlwaysAutoResize) then

        -- Show GUI
        local gui = { config.get('show_gui') };
        if imgui.Checkbox('Show GUI', gui) then
            config.set('show_gui', gui[1]);
        end

        local venture_modes = { ACE = 0, CW = 1, ALL = 2 };
        local selected_mode = venture_modes[string.upper(config.get('venture_mode') or 'ACE')] or 0;
        local mode_combo = { selected_mode };

        imgui.PushItemWidth(120);
        if imgui.Combo('Venture Mode', mode_combo, 'ACE\0CW\0All\0', 3) then
            local new_mode = 'ACE';
            if mode_combo[1] == 1 then new_mode = 'CW';
            elseif mode_combo[1] == 2 then new_mode = 'All'; end
            config.set('venture_mode', new_mode);
            parser:refresh_venture_mode();
        end
        imgui.PopItemWidth();

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
		
		-- Equipment Column Toggle
        local show_equipment_column = { config.get('show_equipment_column') }
        if imgui.Checkbox('Show Equipment Column', show_equipment_column) then
            config.set('show_equipment_column', show_equipment_column[1])
        end
		
		-- Crest Column Toggle
        local show_crest_column = { config.get('show_crest_column') }
        if imgui.Checkbox('Show Crest Column', show_crest_column) then
            config.set('show_crest_column', show_crest_column[1])
        end

        draw_equipment_filter();
		draw_crest_filter();

        -- Global ImGui Style Toggle
        local use_global_imgui_style = { config.get('use_global_imgui_style') }
        if imgui.Checkbox('Use Global ImGui Style', use_global_imgui_style) then
            config.set('use_global_imgui_style', use_global_imgui_style[1])
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


    end
    if not use_global_imgui_style then
        imgui.PopStyleColor(4);
    end
    imgui.End();
    config.set('show_config_gui', open[1])
end

return config_ui;
