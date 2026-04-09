local config = require('configs.config');

local sorter = {};

local function get_pool_value(venture)
    return (venture.get_pool and venture:get_pool() or ''):lower();
end

local function get_area_value(venture)
    return tostring(venture:get_area() or ''):lower();
end

local function get_completion_value(venture)
    return tonumber(venture:get_completion()) or 0;
end

local function get_level_value(venture)
    local level_range = tostring(venture:get_level_range() or '');
    return tonumber(level_range:match('(%d+)-')) or 0;
end

local function compare_strings(a, b, ascending)
    if a == b then
        return nil;
    end
    if ascending then
        return a < b;
    end
    return a > b;
end

local function compare_numbers(a, b, ascending)
    if a == b then
        return nil;
    end
    if ascending then
        return a < b;
    end
    return a > b;
end

function sorter:sort(ventures)
    table.sort(ventures, function(a, b)
        local sort_by = config.get('sort_by');
        local ascending = config.get('sort_ascending');
        local result = nil;

        if sort_by == 'level' then
            result = compare_numbers(get_level_value(a), get_level_value(b), ascending);
            if result ~= nil then return result; end

            result = compare_strings(get_area_value(a), get_area_value(b), true);
            if result ~= nil then return result; end

        elseif sort_by == 'area' then
            result = compare_strings(get_area_value(a), get_area_value(b), ascending);
            if result ~= nil then return result; end

            result = compare_numbers(get_level_value(a), get_level_value(b), true);
            if result ~= nil then return result; end

        else
            result = compare_numbers(get_completion_value(a), get_completion_value(b), ascending);
            if result ~= nil then return result; end

            result = compare_numbers(get_level_value(a), get_level_value(b), true);
            if result ~= nil then return result; end

            result = compare_strings(get_area_value(a), get_area_value(b), true);
            if result ~= nil then return result; end
        end

        result = compare_strings(get_pool_value(a), get_pool_value(b), ascending);
        if result ~= nil then
            return result;
        end

        return false;
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