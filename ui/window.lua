local imgui = require('imgui');
local config = require('configs.config');
local window = require('models.window');
local sorter = require('services.sorter');
local rows = require('ui.rows');
local sort_button = require('ui.sort_button');
local headers = require('ui.headers');
local ui = {};

-- Draw main window
function ui:draw(ventures)
    if not config.get('show_gui') then
        return;
    end

    -- Get highest completion info
    local highest = sorter:get_highest_completion(ventures);

    -- Set window title
    local window_title = window:get_title(highest.completion, highest.area, highest.position);

    imgui.SetNextWindowSize(window:get_size(), ImGuiCond_Always);
    local open = { config.get('show_gui') };
    if imgui.Begin(window_title, open) then
        -- Set window styles
        imgui.PushStyleColor(ImGuiCol_WindowBg, {0,0.06,0.16,0.9});
        imgui.PushStyleColor(ImGuiCol_TitleBg, {0,0.06,0.16,0.7});
        imgui.PushStyleColor(ImGuiCol_TitleBgActive, {0,0.06,0.16,0.9});
        imgui.PushStyleColor(ImGuiCol_TitleBgCollapsed, {0,0.06,0.16,0.5});

        imgui.Columns(4, nil, false);

        headers:draw();
        rows:draw(ventures);

        -- Draw manual vertical separator lines at column boundaries
        local draw_list = imgui.GetWindowDrawList();
        local wx, wy = imgui.GetWindowPos();
        local cy = wy + imgui.GetFrameHeight() + 2; -- below title bar
        local ch = imgui.GetWindowHeight() - imgui.GetFrameHeight() - 2;
        local scroll_y = imgui.GetScrollY();
        local line_color = imgui.GetColorU32({1.0, 1.0, 1.0, 0.25});
        local col_x = 0;
        for i = 0, 2 do
            col_x = col_x + imgui.GetColumnWidth(i);
            local x = wx + col_x + imgui.GetStyle().WindowPadding.x;
            draw_list:AddLine({x, cy}, {x, cy + ch}, line_color, 1.0);
        end

        -- Draw horizontal separator below headers
        local header_y = cy + imgui.GetTextLineHeightWithSpacing() + 2;
        local content_width = wx + imgui.GetWindowContentRegionWidth() + imgui.GetStyle().WindowPadding.x;
        draw_list:AddLine({wx, header_y}, {content_width, header_y}, line_color, 1.0);

        imgui.Columns(1);
        imgui.PopStyleColor(4);
    end

    window:update_state(imgui);
    imgui.End();
    config.set('show_gui', open[1])
end

return ui;