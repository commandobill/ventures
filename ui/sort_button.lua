local imgui = require('imgui');
local config = require('configs.config');
local sorter = require('services.sorter');

local sort_button = {};

-- Draw sort button
function sort_button:draw_sort_button(label, sort_by)
    -- Hide/show based on hide_sorting_text
    local asc = ' (Asc)'
    local desc = ' (Desc)'
    if config.get('hide_sorting_text') then
        asc = ''
        desc = ''
    end

    if config.get('sort_by') == sort_by then
        imgui.PushStyleColor(ImGuiCol_Button, {0.2, 0.4, 0.8, 1.0});
        imgui.PushStyleColor(ImGuiCol_ButtonHovered, {0.2, 0.4, 0.8, 1.0});
        imgui.PushStyleColor(ImGuiCol_ButtonActive, {0.2, 0.4, 0.8, 1.0});
    end

    local button_text = label;
    if config.get('sort_by') == sort_by then
        button_text = button_text .. (config.get('sort_ascending') and asc or desc);
    end

    if imgui.Button(button_text) then
        sorter:set_column(sort_by);
    end

    if config.get('sort_by') == sort_by then
        imgui.PopStyleColor(3);
    end
end

return sort_button;