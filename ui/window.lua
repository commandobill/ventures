local imgui = require('imgui');
local config = require('configs.config');
local window = require('models.window');
local parser = require('services.parser');
local sorter = require('services.sorter');
local rows = require('ui.rows');
local sort_button = require('ui.sort_button');
local headers = require('ui.headers');
local ui = {};

local function filter_ventures(ventures)
    local selected_pool = config.get('venture_pool_filter') or 'All';
    if selected_pool == 'All' then
        return ventures;
    end

    local filtered = {};
    for _, venture in ipairs(ventures or {}) do
        local pool = venture.get_pool and venture:get_pool() or venture.pool or '';
        local level_range = venture.get_level_range and venture:get_level_range() or venture.level_range or '';
        if pool == selected_pool or level_range == 'HVNM' then
            table.insert(filtered, venture);
        end
    end

    return filtered;
end

local function draw_pool_filter_tabs()
    local selected_pool = config.get('venture_pool_filter') or 'All';
    local tabs = {
        { label = 'All Pools', value = 'All' },
        { label = 'Pool A', value = 'A' },
        { label = 'Pool B', value = 'B' }
    };

    if imgui.BeginTabBar('##venture_pool_filter_tabs') then
        for _, tab in ipairs(tabs) do
            local flags = selected_pool == tab.value and ImGuiTabItemFlags_SetSelected or 0;
            if imgui.BeginTabItem(tab.label, nil, flags) then
                if selected_pool ~= tab.value then
                    config.set('venture_pool_filter', tab.value);
                end
                imgui.EndTabItem();
            end
        end
        imgui.EndTabBar();
    end
end

-- Draw main window
function ui:draw(ventures)
    if not config.get('show_gui') then
        return;
    end

    ventures = filter_ventures(ventures);
    ventures = sorter:sort(ventures);

    -- Get highest completion info
    local highest = sorter:get_highest_completion(ventures);

    -- Set window title
    local window_title = window:get_title(highest.completion, highest.area, highest.position);

    imgui.SetNextWindowSize(window.size, ImGuiCond_FirstUseEver);
    local open = { config.get('show_gui') };
    local use_global_imgui_style = config.get('use_global_imgui_style');

    if not use_global_imgui_style then
        imgui.PushStyleColor(ImGuiCol_WindowBg, {0,0.06,0.16,0.9});
        imgui.PushStyleColor(ImGuiCol_TitleBg, {0,0.06,0.16,0.7});
        imgui.PushStyleColor(ImGuiCol_TitleBgActive, {0,0.06,0.16,0.9});
        imgui.PushStyleColor(ImGuiCol_TitleBgCollapsed, {0,0.06,0.16,0.5});
    end

    if imgui.Begin(window_title, open) then
        -- Set window styles
        local venture_modes = { ACE = 0, CW = 1 };
        local selected_mode = venture_modes[string.upper(config.get('venture_mode') or 'ACE')] or 0;
        local combo = { selected_mode };

        imgui.PushItemWidth(90);
        if imgui.Combo('Mode', combo, 'ACE\0CW\0', 2) then
            config.set('venture_mode', combo[1] == 1 and 'CW' or 'ACE');
            ventures = parser:refresh_venture_mode();
            ventures = filter_ventures(ventures);
            ventures = sorter:sort(ventures);
        end
        imgui.PopItemWidth();

        draw_pool_filter_tabs();

        imgui.Separator();

        imgui.Columns(config.get('show_equipment_column') and 5 or 4);

        headers:draw();
        rows:draw(ventures);

        imgui.Columns(1);
        
    end

    window:update_state(imgui);
    if not use_global_imgui_style then
        imgui.PopStyleColor(4);
    end
    imgui.End();
    config.set('show_gui', open[1])
end

return ui;
