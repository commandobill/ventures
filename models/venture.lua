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
    crest = '',
    progress_history = {} -- Array to store completion changes with timestamps
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
    instance.progress_history = {}; -- Initialize empty progress history
    return instance;
end

-- Update venture data
function Venture:update(data)
    local now = os.time();
    local new_completion = tonumber(data.completion) or 0;
    
    -- Track progress changes for time estimation
    if new_completion > self.completion then
        -- Add to progress history
        table.insert(self.progress_history, {
            completion = new_completion,
            timestamp = now
        });
        
        -- Keep only last 10 entries to prevent memory bloat
        if #self.progress_history > 10 then
            table.remove(self.progress_history, 1);
        end
        
        self.last_increment_time = now;
    elseif new_completion < self.completion then
        -- Reset detected, clear history and set to red
        self.progress_history = {};
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

-- Calculate progress rate and time estimate
function Venture:get_time_estimate()
    -- Get configurable threshold from config
    local config = require('configs.config');
    local min_points = config.get('min_data_points') or 4;
    

    
    if #self.progress_history < min_points then
        return nil, nil, nil; -- Not enough data
    end
    
    -- Calculate rate from last N entries based on config
    local recent_entries = {};
    for i = math.max(1, #self.progress_history - min_points + 1), #self.progress_history do
        table.insert(recent_entries, self.progress_history[i]);
    end
    
    -- Calculate progress per minute
    local total_progress = recent_entries[#recent_entries].completion - recent_entries[1].completion;
    local total_time = (recent_entries[#recent_entries].timestamp - recent_entries[1].timestamp) / 60; -- minutes

    
    if total_time <= 0 then
        return nil, nil, nil; -- No time elapsed
    end
    
    local rate_per_minute = total_progress / total_time;
    local rate_per_hour = rate_per_minute * 60;
    
    -- Calculate time to 100%
    local remaining_progress = 100 - self.completion;
    local minutes_to_complete = remaining_progress / rate_per_minute;
    local hours_to_complete = minutes_to_complete / 60;
    
    -- Calculate confidence based on consistency
    local confidence = self:calculate_confidence(recent_entries, rate_per_minute);
    
    return rate_per_hour, minutes_to_complete, confidence;
end

-- Calculate confidence level based on progress consistency
function Venture:calculate_confidence(entries, avg_rate)
    if #entries < 3 then
        return 'low';
    end
    
    -- Check for stalled progress (no recent updates)
    local now = os.time();
    local last_update = entries[#entries].timestamp;
    local minutes_since_update = (now - last_update) / 60;
    
    -- If no progress in last 10 minutes, confidence is low
    if minutes_since_update > 10 then
        return 'low';
    end
    
    -- Check if progress is consistent
    local total_variance = 0;
    for i = 2, #entries do
        local progress = entries[i].completion - entries[i-1].completion;
        local time_diff = (entries[i].timestamp - entries[i-1].timestamp) / 60;
        local rate = progress / time_diff;
        total_variance = total_variance + math.abs(rate - avg_rate);
    end
    
    local avg_variance = total_variance / (#entries - 1);
    local variance_ratio = avg_variance / math.max(avg_rate, 0.1);

    -- Variance thresholds
    if variance_ratio < 0.8 then
        return 'high';
    elseif variance_ratio < 1.5 then
        return 'medium';
    else
        return 'low';
    end
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