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
    imgui.PushStyleColor(ImGuiCol_WindowBg, {0,0.06,0.16,0.9});
    imgui.PushStyleColor(ImGuiCol_TitleBg, {0,0.06,0.16,0.7});
    imgui.PushStyleColor(ImGuiCol_TitleBgActive, {0,0.06,0.16,0.9});
    imgui.PushStyleColor(ImGuiCol_TitleBgCollapsed, {0,0.06,0.16,0.5});

    local open = { config.get('show_gui') };
    local ok, err = pcall(function()
        if imgui.Begin(window_title, open) then
            local show_vgrid = config.get('show_vertical_grid');
            imgui.Columns(4, nil, show_vgrid);

            headers:draw();
            rows:draw(ventures);

            imgui.Columns(1);
        end
        window:update_state(imgui);
    end);

    if not ok then
        print(string.format('[ventures] UI error: %s', tostring(err)));
    end

    imgui.End();
    imgui.PopStyleColor(4);

    if open[1] ~= config.get('show_gui') then
        config.set('show_gui', open[1]);
    end
end

return ui;