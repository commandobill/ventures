local imgui = require('imgui');
local config = require('configs.config');

local rows = {};

local SPAWN_SECONDS = 600; -- NM spawns 10 minutes after completion hits 100%
local SPAWN_BAR_HEIGHT = 15;
local ORANGE_ABOVE_THRESHOLD = { 1.0, 0.5, 0.0, 1.0 };
local ORANGE_FILL = { 1.0, 0.5, 0.0, 0.2 };
local GREEN_BELOW_THRESHOLD = { 0.5, 1.0, 0.5, 1.0 };
local GREEN_FILL = { 0.5, 1.0, 0.5, 0.2 };
-- Seconds left until the NM spawns, or nil when no timer applies
local function get_spawn_remaining(venture)
    local hit = venture.hit_100_time or 0;
    if hit == 0 then
        return nil;
    end
    local remaining = SPAWN_SECONDS - (os.time() - hit);
    if remaining <= 0 then
        return nil;
    end
    return remaining;
end

-- Countdown text with a thin green bar behind it, spanning the column
local function draw_spawn_bar(remaining)
    local label = string.format('%d:%02d', math.floor(remaining / 60), remaining % 60);
    -- Line the countdown up with where the '#%' text normally starts
    local indent = imgui.CalcTextSize((config.get('stopped_indicator') or 'x') .. '  ');
    local start_x, start_y = imgui.GetCursorPosX(), imgui.GetCursorPosY();
    local _, text_h = imgui.CalcTextSize(label);

    imgui.SetCursorPos({ start_x, start_y + text_h - SPAWN_BAR_HEIGHT - 2 });
    imgui.PushStyleColor(ImGuiCol_PlotHistogram, ORANGE_FILL);
    imgui.PushStyleColor(ImGuiCol_FrameBg, { 0.0, 0.0, 0.0, 0.0 }); -- no track, fill only
    imgui.PushStyleVar(ImGuiStyleVar_FrameBorderSize, 0);
    imgui.PushStyleVar(ImGuiStyleVar_FrameRounding, 0);
    imgui.ProgressBar(1 - (remaining / SPAWN_SECONDS), { -1, SPAWN_BAR_HEIGHT }, '');
    imgui.PopStyleVar(2);
    imgui.PopStyleColor(2);

    imgui.SetCursorPos({ start_x + indent, start_y });
    imgui.PushStyleColor(ImGuiCol_Text, ORANGE_ABOVE_THRESHOLD);
    imgui.TextUnformatted(label);
    imgui.PopStyleColor();
end

local function format_completion(value)
    local completion = tonumber(value) or 0
    if completion == math.floor(completion) then
        return string.format('%d', completion)
    end
    return string.format('%.1f', completion)
end

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
    local pool = venture.get_pool and venture:get_pool() or ''
    
    -- Level Range
    local level_label = venture:get_level_range();
    if pool ~= '' then
        level_label = string.format('%s %s', pool, level_label);
    end
    imgui.Text(level_label);
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

    if config.get('show_equipment_column') then
        imgui.Text(venture:get_equipment() or '');
        imgui.NextColumn();
    end

    -- Completion with time indicator, or the spawn countdown bar at 100%
    local completion = tonumber(venture:get_completion()) or 0
    local alert_threshold = tonumber(config.alert_threshold) or 90
    local indicator, time_color = get_indicator_and_color(venture);
    local spawn_remaining = get_spawn_remaining(venture);

    if spawn_remaining then
        draw_spawn_bar(spawn_remaining);
    else
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
        -- Draw completion percentage
        if completion >= alert_threshold then
            imgui.PushStyleColor(ImGuiCol_Text, ORANGE_ABOVE_THRESHOLD); -- Orange
        else
            imgui.PushStyleColor(ImGuiCol_Text, GREEN_BELOW_THRESHOLD); -- Green
        end
        imgui.TextUnformatted(format_completion(completion) .. '%');
        imgui.PopStyleColor();
    end
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
    imgui.PopStyleColor();
    imgui.NextColumn();
end

-- Draw all venture rows
function rows:draw(ventures)
    for _, venture in ipairs(ventures) do
        self:draw_venture_row(venture);
    end
end

return rows;
