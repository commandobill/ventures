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

        -- Capture content region X for manual grid lines
        local content_x, _ = imgui.GetCursorScreenPos();

        headers:draw();
        rows:draw(ventures);

        -- Draw manual vertical separator lines at column boundaries (non-grippable)
        -- Stop at the last row content, not the window bottom
        local draw_list = imgui.GetWindowDrawList();
        local _, wy = imgui.GetWindowPos();
        local top_y = wy + imgui.GetFrameHeight();
        local _, bottom_y = imgui.GetCursorScreenPos();
        local line_color = 0x40FFFFFF; -- white at ~25% alpha (ABGR)

        for i = 1, 3 do
            local x = content_x + imgui.GetColumnOffset(i);
            draw_list:AddLine({x, top_y}, {x, bottom_y}, line_color, 1.0);
        end

        imgui.Columns(1);
        imgui.PopStyleColor(4);
    end

    window:update_state(imgui);
    imgui.End();
    config.set('show_gui', open[1])
end

return ui;