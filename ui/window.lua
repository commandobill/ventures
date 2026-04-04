local imgui = require('imgui');
local config = require('configs.config');
local window = require('models.window');
local sorter = require('services.sorter');
local rows = require('ui.rows');
local sort_button = require('ui.sort_button');
local headers = require('ui.headers');
local ui = {};

-- Filter ventures by pool, always including HVNM
local function filter_by_pool(ventures, pool_name)
    local filtered = {};
    for _, v in ipairs(ventures) do
        if v:get_pool() == pool_name or v:get_pool() == "HVNM" then
            table.insert(filtered, v);
        end
    end
    return filtered;
end

-- Draw main window
function ui:draw(ventures)
    if not config.get('show_gui') then
        return;
    end

    -- Get highest completion info
    local highest = sorter:get_highest_completion(ventures);

    -- Set window title
    local window_title = window:get_title(highest.completion, highest.area, highest.position);

    imgui.SetNextWindowSize(window.size, ImGuiCond_FirstUseEver);
    local open = { config.get('show_gui') };
    imgui.PushStyleColor(ImGuiCol_WindowBg, {0,0.06,0.16,0.9});
    imgui.PushStyleColor(ImGuiCol_TitleBg, {0,0.06,0.16,0.7});
    imgui.PushStyleColor(ImGuiCol_TitleBgActive, {0,0.06,0.16,0.9});
    imgui.PushStyleColor(ImGuiCol_TitleBgCollapsed, {0,0.06,0.16,0.5});
    if imgui.Begin(window_title, open) then

        if imgui.BeginTabBar('venture_pools') then
            if imgui.BeginTabItem('Pool A') then
                imgui.Columns(4);
                headers:draw();
                rows:draw(filter_by_pool(ventures, "Pool A"));
                imgui.Columns(1);
                imgui.EndTabItem();
            end
            if imgui.BeginTabItem('Pool B') then
                imgui.Columns(4);
                headers:draw();
                rows:draw(filter_by_pool(ventures, "Pool B"));
                imgui.Columns(1);
                imgui.EndTabItem();
            end
            imgui.EndTabBar();
        end

    end

    window:update_state(imgui);
    imgui.PopStyleColor(4);
    imgui.End();
    config.set('show_gui', open[1])
end

return ui;