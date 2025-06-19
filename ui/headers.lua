local imgui = require('imgui');
local sort_button = require('ui.sort_button');
local config = require('configs.config');

local headers = {};

-- Draw location header with wiki link
function headers:draw_location_header()
    imgui.Text('Location ');
    imgui.SameLine(0, 0);
    imgui.PushStyleColor(ImGuiCol_Text, {0.0, 0.7, 1.0, 1.0});
    if imgui.Selectable('(wiki)', false, ImGuiSelectableFlags_None, {0, 0}) then
        os.execute('start https://www.bg-wiki.com/ffxi/CatsEyeXI_Content/Ventures#Venture_Bosses');
    end
    imgui.PopStyleColor();
end

-- Draw all headers
function headers:draw()
    sort_button:draw_sort_button(config.get('level_range_label') or 'Level Range', 'level');
    imgui.NextColumn();
    sort_button:draw_sort_button(config.get('area_label') or 'Area', 'area');
    imgui.NextColumn();
    sort_button:draw_sort_button(config.get('completion_label') or 'Completion', 'completion');
    imgui.NextColumn();
    headers:draw_location_header();
    imgui.NextColumn();
    imgui.Separator();
end

return headers;