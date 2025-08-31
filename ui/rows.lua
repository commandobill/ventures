local imgui = require('imgui');
local config = require('configs.config');

local rows = {};

-- Get indicator symbol and color based on time since last completion change
local function get_indicator_and_color(venture)
    local now = os.time()
    local stopped = config.get('stopped_indicator')
    local fast = config.get('fast_indicator')
    local slow = config.get('slow_indicator')
    if not venture.last_increment_time or venture.last_increment_time == 0 then
        return stopped, {1.0, 0.0, 0.0, 1.0} -- Red (start or after reset)
    end
    local elapsed = (now - venture.last_increment_time) / 60
    if elapsed < 7 then
        return fast, {0.0, 1.0, 0.0, 1.0} -- Green
    elseif elapsed < 15 then
        return slow, {1.0, 1.0, 0.0, 1.0} -- Yellow
    else
        return stopped, {1.0, 0.0, 0.0, 1.0} -- Red
    end
end

-- Draw venture row
function rows:draw_venture_row(venture)
    imgui.PushStyleColor(ImGuiCol_Text, { 1.0, 1.0, 1.0, 1.0 });
    
    -- Level Range
    imgui.Text(venture:get_level_range());
    imgui.NextColumn();

    -- Area with tooltip
    imgui.Text(venture:get_area());
    if imgui.IsItemHovered() then
        local equipment = venture:get_equipment()
        if equipment and equipment ~= "" then
            imgui.BeginTooltip()
            imgui.Text("Equipment: " .. equipment)
            imgui.EndTooltip()
        end
    end
    imgui.NextColumn();

    -- Completion with time indicator
    local completion = tonumber(venture:get_completion()) or 0
    local alert_threshold = tonumber(config.alert_threshold) or 90
    local indicator, time_color = get_indicator_and_color(venture);
    
    -- Draw indicator first
    imgui.PushStyleColor(ImGuiCol_Text, time_color);
    imgui.TextUnformatted(indicator);
    imgui.PopStyleColor();

    if imgui.IsItemHovered() then
        local minutes
        if not venture.last_increment_time or venture.last_increment_time == 0 then
            minutes = nil
        else
            minutes = math.floor((os.time() - venture.last_increment_time) / 60)
        end
        imgui.BeginTooltip()
        if not minutes then
            imgui.TextUnformatted("Last progress: unknown")
        elseif minutes == 0 then
            imgui.TextUnformatted("Last progress: just now")
        elseif minutes == 1 then
            imgui.TextUnformatted("Last progress: 1 minute ago")
        else
            imgui.TextUnformatted("Last progress: " .. minutes .. " minutes ago")
        end
        imgui.EndTooltip()
    end
    
    imgui.SameLine(0, 0);
    imgui.TextUnformatted('  '); -- Two spaces
    imgui.SameLine(0, 0);
    -- Draw completion percentage with time estimation
    if completion >= alert_threshold then
        imgui.PushStyleColor(ImGuiCol_Text, { 1.0, 0.5, 0.0, 1.0 }); -- Orange
    else
        imgui.PushStyleColor(ImGuiCol_Text, { 0.5, 1.0, 0.5, 1.0 }); -- Green
    end
    
    -- Check if time estimation is enabled and we have enough data
    local config = require('configs.config');
    if config.get('enable_time_estimation') then
        local rate_per_hour, minutes_to_complete, confidence = venture:get_time_estimate();
        
        if rate_per_hour and config.get('show_completion_time') then
            -- Show completion percentage + time estimate: "47% → 2h 15m"
            local hours = math.floor(minutes_to_complete / 60);
            local mins = math.floor(minutes_to_complete % 60);
            local time_text;
            
            if hours > 0 then
                time_text = string.format("%dh %dm", hours, mins);
            else
                time_text = string.format("%dm", mins);
            end
            
            -- Show completion percentage first (always with alert threshold colors)
            imgui.TextUnformatted(completion .. '%');
            imgui.PopStyleColor();
            
            -- Show separator and time estimate with confidence-based colors
            imgui.SameLine(0, 0);
            imgui.TextUnformatted(' : ');
            imgui.SameLine(0, 0);
            
            -- Apply confidence-based colors to the time estimate (same schema as above)
            local confidence_color;
            if confidence == 'high' then
                confidence_color = { 0.0, 1.0, 0.0, 1.0 }; -- Green
            elseif confidence == 'medium' then
                confidence_color = { 1.0, 1.0, 0.0, 1.0 }; -- Yellow
            else
                confidence_color = { 1.0, 0.0, 0.0, 1.0 }; -- Red
            end
            imgui.PushStyleColor(ImGuiCol_Text, confidence_color);
            imgui.TextUnformatted(time_text);
            imgui.PopStyleColor();
            
            -- Enhanced tooltip with time estimate
            if imgui.IsItemHovered() then
                imgui.BeginTooltip()
                imgui.TextUnformatted(string.format("Rate: %.1f%%/hr", rate_per_hour));
                imgui.TextUnformatted(string.format("Time to 100%%: %s", time_text));
                imgui.TextUnformatted(string.format("Confidence: %s", confidence:upper()));
                imgui.EndTooltip();
            end
            
        else
            -- Show just completion percentage
            imgui.TextUnformatted(completion .. '%');
        end
        
    else
        -- Time estimation disabled, show just completion percentage
        imgui.TextUnformatted(completion .. '%');
    end
    
    imgui.PopStyleColor();
    imgui.NextColumn();

    -- Location and Notes
    local location = venture:get_location()
    local notes = venture.get_notes and venture:get_notes() or nil
    local notes_visible = config.get('notes_visible')
    if notes_visible then
        imgui.Text(location)
        if imgui.IsItemHovered() then
            if notes and notes ~= "" then
                imgui.BeginTooltip()
                imgui.Text(notes)
                imgui.EndTooltip()
            end
        end
    else
        if notes and notes ~= "" then
            imgui.Text(location .. " - " .. notes)
        else
            imgui.Text(location)
        end
    end
    imgui.NextColumn();
end

-- Draw all venture rows
function rows:draw(ventures)
    for _, venture in ipairs(ventures) do
        self:draw_venture_row(venture);
    end
end

return rows;