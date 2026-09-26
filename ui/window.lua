local imgui = require('imgui');
local config = require('configs.config');
local window = require('models.window');
local parser = require('services.parser');
local sorter = require('services.sorter');
local rows = require('ui.rows');
local sort_button = require('ui.sort_button');
local headers = require('ui.headers');
local ui = {};

local function equipment_matches(venture)
    if not config.get('show_equipment_filter') then
        return true;
    end
    local needed = config.get('needed_equipment') or {};
    local equipment = venture.get_equipment and venture:get_equipment() or venture.equipment or '';
    return equipment ~= '' and needed[equipment] == true;
end

local function crest_matches(venture)
    if not config.get('show_crest_filter') then
        return true;
    end
    local needed = config.get('needed_crest') or {};
    local crest = venture.get_crest and venture:get_crest() or venture.crest or '';
    return crest ~= '' and needed[crest] == true;
end

local function filter_ventures(ventures)
    local selected_pool = config.get('venture_pool_filter') or 'All';
    local filtered = {};
    for _, venture in ipairs(ventures or {}) do
        local pool = venture.get_pool and venture:get_pool() or venture.pool or '';
        local level_range = venture.get_level_range and venture:get_level_range() or venture.level_range or '';
        local pool_ok = selected_pool == 'All' or pool == selected_pool or level_range == 'HVNM';
        if pool_ok and equipment_matches(venture) and crest_matches(venture) then
            table.insert(filtered, venture);
        end
    end
    return filtered;
end

-- Build a read-only "view" of a venture resolved to a specific mode (ACE/CW),
-- without mutating the shared venture object.
local function build_mode_view(v, mode)
    local view = {};
    for k, val in pairs(v) do
        view[k] = val;
    end
    local mode_entry = v.mode_data and v.mode_data[mode];
    if mode_entry then
        view.area = mode_entry.area;
        view.location = mode_entry.loc;
        view.equipment = mode_entry.equipment;
        view.element = mode_entry.element;
        view.crest = mode_entry.crest;
        view.notes = mode_entry.notes;
    end
    setmetatable(view, getmetatable(v));
    return view;
end

local function get_level_range(v)
    return v.get_level_range and v:get_level_range() or v.level_range or '';
end

-- ACE/CW groups exclude HVNM entries (HVNM has no mode_data, so it would
-- otherwise appear identically -- and redundantly -- in both groups).
local function build_mode_group(raw_ventures, mode)
    local views = {};
    for _, v in ipairs(raw_ventures or {}) do
        if get_level_range(v) ~= 'HVNM' then
            table.insert(views, build_mode_view(v, mode));
        end
    end
    views = filter_ventures(views);
    views = sorter:sort(views);
    return views;
end

-- HVNM is mode-independent, so it gets its own single group shown once.
local function build_hvnm_group(raw_ventures)
    local views = {};
    for _, v in ipairs(raw_ventures or {}) do
        if get_level_range(v) == 'HVNM' then
            table.insert(views, v);
        end
    end
    views = filter_ventures(views);
    views = sorter:sort(views);
    return views;
end

local function build_all_mode_groups()
    local raw = parser:get_ventures();
    local hvnm_group = build_hvnm_group(raw);
    local ace_group = build_mode_group(raw, 'ACE');
    local cw_group = build_mode_group(raw, 'CW');
    local display_ventures = {};
    for _, v in ipairs(hvnm_group) do table.insert(display_ventures, v); end
    for _, v in ipairs(ace_group) do table.insert(display_ventures, v); end
    for _, v in ipairs(cw_group) do table.insert(display_ventures, v); end
    return hvnm_group, ace_group, cw_group, display_ventures;
end

-- Draws a full-width label row spanning all columns, then reopens the same
-- column layout (same id, so widths are preserved).
local function draw_mode_header(label, column_count)
    imgui.Columns(1);
    imgui.Spacing();
    imgui.PushStyleColor(ImGuiCol_Text, {0.6, 0.85, 1.0, 1.0});
    imgui.Text(label);
    imgui.PopStyleColor();
    imgui.Separator();
    imgui.Columns(column_count, 'venture_columns', true);
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

    local venture_mode = string.upper(config.get('venture_mode') or 'ACE');
    local is_all_mode = venture_mode == 'ALL';

    local column_count = 4;
    if config.get('show_equipment_column') then column_count = column_count + 1; end
    if config.get('show_crest_column') then column_count = column_count + 1; end

    local hvnm_group, ace_group, cw_group, display_ventures;
    if is_all_mode then
        hvnm_group, ace_group, cw_group, display_ventures = build_all_mode_groups();
    else
        display_ventures = filter_ventures(ventures);
        display_ventures = sorter:sort(display_ventures);
    end

    -- Get highest completion info
    local highest = sorter:get_highest_completion(display_ventures);

    -- Set window title
    local window_title = window:get_title(highest.completion, highest.area, highest.position);
    imgui.SetNextWindowSize(window.size, ImGuiCond_FirstUseEver);
    imgui.SetNextWindowSizeConstraints({ window.size[1], 0 }, { window.size[1], FLT_MAX });
    local open = { config.get('show_gui') };
    local use_global_imgui_style = config.get('use_global_imgui_style');
    if not use_global_imgui_style then
        imgui.PushStyleColor(ImGuiCol_WindowBg, {0,0.06,0.16,0.9});
        imgui.PushStyleColor(ImGuiCol_TitleBg, {0,0.06,0.16,0.7});
        imgui.PushStyleColor(ImGuiCol_TitleBgActive, {0,0.06,0.16,0.9});
        imgui.PushStyleColor(ImGuiCol_TitleBgCollapsed, {0,0.06,0.16,0.5});
    end
    if imgui.Begin(window_title, open, ImGuiWindowFlags_AlwaysAutoResize) then
        local venture_mode_values = { ACE = 0, CW = 1, ALL = 2 };
        local selected_mode = venture_mode_values[venture_mode] or 0;
        local combo = { selected_mode };
        imgui.PushItemWidth(90);
        if imgui.Combo('Mode', combo, 'ACE\0CW\0All\0', 3) then
            local new_mode = 'ACE';
            if combo[1] == 1 then new_mode = 'CW';
            elseif combo[1] == 2 then new_mode = 'All'; end
            config.set('venture_mode', new_mode);
            parser:refresh_venture_mode();

            venture_mode = string.upper(new_mode);
            is_all_mode = venture_mode == 'ALL';
            if is_all_mode then
                hvnm_group, ace_group, cw_group, display_ventures = build_all_mode_groups();
            else
                display_ventures = filter_ventures(parser:get_ventures());
                display_ventures = sorter:sort(display_ventures);
            end
        end
        imgui.PopItemWidth();

        draw_pool_filter_tabs();
        imgui.Separator();

        imgui.Columns(column_count, 'venture_columns', true);
        headers:draw();

        if is_all_mode then
            if #hvnm_group > 0 then
                rows:draw(hvnm_group);
            end
            draw_mode_header('ACE', column_count);
            rows:draw(ace_group);
            draw_mode_header('CW', column_count);
            rows:draw(cw_group);
        else
            rows:draw(display_ventures);
        end

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