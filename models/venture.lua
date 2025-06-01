local Venture = {
    level_range = '',
    area = '',
    completion = 0,
    location = '',
    notes = '',
    last_update_time = 0,
    last_increment_time = 0,
    equipment = '',
    element = '',
    crest = ''
};

-- Create new venture instance
function Venture:new(data)
    local instance = setmetatable({}, { __index = Venture });
    local now = os.time();
    instance.level_range = data.level_range;
    instance.area = data.area;
    instance.completion = tonumber(data.completion) or 0;
    instance.location = data.loc;
    instance.equipment = data.equipment or '';
    instance.element = data.element or '';
    instance.crest = data.crest or '';
    instance.notes = data.notes;
    instance.last_update_time = now;
    instance.last_increment_time = 0; -- Start as red
    return instance;
end

-- Update venture data
function Venture:update(data)
    local now = os.time();
    local new_completion = tonumber(data.completion) or 0;
    if new_completion > self.completion then
        self.last_increment_time = now;
    elseif new_completion < self.completion then
        -- Reset detected, set to red
        self.last_increment_time = 0;
    end
    self.level_range = data.level_range;
    self.area = data.area;
    self.completion = new_completion;
    self.location = data.loc;
    self.equipment = data.equipment or self.equipment;
    self.element = data.element or self.element;
    self.crest = data.crest or self.crest;
    self.notes = data.notes;

    self.last_update_time = now;
end

-- Get completion percentage
function Venture:get_completion()
    return self.completion;
end

-- Get area name
function Venture:get_area()
    return self.area;
end

-- Get level range
function Venture:get_level_range()
    return self.level_range;
end

-- Get location
function Venture:get_location()
    return self.location;
end


-- Get equipment
function Venture:get_equipment()
    return self.equipment;
end

-- Get element
function Venture:get_element()
    return self.element;
end

-- Get crest
function Venture:get_crest()
    return self.crest;
end

-- Get notes
function Venture:get_notes()
    return self.notes;
end

return Venture;