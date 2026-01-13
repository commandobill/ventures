local config = require('configs.config');

local sorter = {};

-- Sort ventures based on current settings
function sorter:sort(ventures)
    table.sort(ventures, function(a, b)
        local a_val, b_val;

        if config.get('sort_by') == 'level' then
            a_val = tonumber(a:get_level_range():match("(%d+)-")) or 0;
            b_val = tonumber(b:get_level_range():match("(%d+)-")) or 0;
        elseif config.get('sort_by') == 'area' then
            a_val = a:get_area():lower();
            b_val = b:get_area():lower();
        elseif config.get('sort_by') == 'completion' then
            a_val = a:get_completion();
            b_val = b:get_completion();
            if a_val == b_val then
                -- Secondary: area name
                a_val = a:get_level_range():lower();
                b_val = b:get_level_range():lower();
            end
        end

        if config.get('sort_ascending') then
            return a_val < b_val;
        else
            return a_val > b_val;
        end
    end);

    return ventures;
end

-- Set sort column
function sorter:set_column(column)
    if config.get('sort_by') == column then
        config.toggle('sort_ascending');
    else
        config.set('sort_by', column);
        config.set('sort_ascending', true);
    end
end

-- Find highest completion
function sorter:get_highest_completion(ventures)
    local highest_completion = 0;
    local highest_area = '';
    local highest_position = '';
    for _, venture in ipairs(ventures) do
        local completion = venture:get_completion();
        local level_range = venture:get_level_range()
        local show_hvnm = config.get('show_hvnm_title')
        local is_hvnm = (level_range == "HVNM")
        if completion > highest_completion and (show_hvnm or not is_hvnm) then
            highest_completion = completion;
            highest_area = venture:get_area();
            highest_position = venture:get_location();
        end
    end

    return {
        completion = highest_completion,
        area = highest_area,
        position = highest_position
    };
end

return sorter;