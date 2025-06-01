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
    imgui.SetNextWindowSize({400, 400}, ImGuiCond_FirstUseEver);
    local open = { config.get('show_config_gui') };
    if imgui.Begin('Configuration##simpleconfig', open) then

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
    end
    imgui.End();
    config.set('show_config_gui', open[1])
end

return config_ui;