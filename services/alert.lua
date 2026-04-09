local config = require('configs.config');
local chat = require('chat');

local alert = {
    last_alerted_completion = {}
};
local function format_completion(value)
    local completion = tonumber(value) or 0;
    if completion == math.floor(completion) then
        return string.format('%d', completion);
    end
    return string.format('%.1f', completion);
end

-- Preload sounds
local function load_sounds()
    local folder = AshitaCore:GetInstallPath() .. '/addons/' .. addon.name .. '/sounds/'
    if not ashita.fs.exists(folder) then return {}, {} end

    local files = ashita.fs.get_directory(folder, '.*\\.wav') or {}
    local full = T{}

    for _, f in ipairs(files) do
        full:append(f)
    end

    return full
end

local sound_files = load_sounds()

-- Play alert sound
function alert:play_sound(sound)
    local fullpath = string.format('%s\\sounds\\%s', addon.path, sound);
    ashita.misc.play_sound(fullpath);
end

-- Check and handle alerts for a venture
function alert:check_venture(venture)
    if not config.get('enable_alerts') then
        return;
    end

    local completion = venture:get_completion();
    local pool = venture.get_pool and venture:get_pool() or '';
    local area = venture:get_area();
    local location = venture:get_location();
    local alert_key = string.format('%s|%s|%s', pool, venture:get_level_range(), area);
    local area_label = pool ~= '' and string.format('Pool %s %s', pool, area) or area;

    if completion > config.get('alert_threshold') then
        local last = self.last_alerted_completion[alert_key] or 0;
        if completion > last then
            local location_note = location ~= '' and string.format(" at %s", location) or "";
            print(chat.header('ventures') .. chat.success(
                string.format("%s is now %s%% complete%s!", area_label, format_completion(completion), location_note)
            ));

            if config.get('enable_audio') and completion >= config.get('audio_alert_threshold') then
                self:play_sound(sound_files[config.get('selected_sound')]);
            end

            self.last_alerted_completion[alert_key] = completion;
        end
    end
end

return alert;