local venture = require('models.venture');
local vnm_loader = require('services.vnm_loader');
local vnm_data = vnm_loader:load();
local zone_names = require('data.zones');
local config = require('configs.config');

local parser = {
    parsed_ventures = {},
    last_packet_data = nil
};

local function make_venture_key(pool, level_range, area)
    return string.format('%s|%s|%s', pool or '', level_range or '', area or '')
end

local function get_zone_name(zone_id)
    return zone_names[zone_id] or string.format('Unknown Zone %d', tonumber(zone_id) or 0);
end

local function get_vnm_details(area, level_range)
    local details = {
        loc = '',
        equipment = '',
        element = '',
        crest = '',
        notes = ''
    };

    local vnm_zone = vnm_data[area];
    if not vnm_zone then
        return details;
    end

    for _, vnm in ipairs(vnm_zone) do
        if vnm.level_range == level_range then
            details.loc = vnm.position and string.format('(%s)', vnm.position) or '';
            details.equipment = vnm.equipment or '';
            details.element = vnm.element or '';
            details.crest = vnm.crest or '';
            details.notes = vnm.notes and string.format('%s', vnm.notes) or '';
            break;
        end
    end

    return details;
end

local function upsert_venture(existing, new_ventures, venture_data)
    local key = make_venture_key(venture_data.pool, venture_data.level_range, venture_data.area);
    local v = existing[key];
    if v then
        v:update(venture_data);
        table.insert(new_ventures, v);
    else
        table.insert(new_ventures, venture:new(venture_data));
    end
end

local function build_existing_lookup(ventures)
    local existing = {};
    for _, v in ipairs(ventures or {}) do
        existing[make_venture_key(v.pool, v.level_range, v.area)] = v;
    end
    return existing;
end

function parser:parse_venture_packet(data)
    self.last_packet_data = data;

    local venture_mode = string.upper(config.get('venture_mode') or 'ACE');
    local use_cw_zones = venture_mode == 'CW';
    local tier_names = { '10-19', '20-29', '30-39', '40-49', '50-59', '60-69' };
    local pool_names = { 'A', 'B' };
    local existing = build_existing_lookup(self.parsed_ventures);
    local new_ventures = {};

    for pool_idx = 0, 1 do
        local pool = pool_names[pool_idx + 1];
        for tier = 0, 5 do
            local off = 0x08 + (pool_idx * 0x24) + (tier * 6) + 1;
            local ace_zone = struct.unpack('H', data, off);
            local cw_zone = struct.unpack('H', data, off + 2);
            local progress = struct.unpack('B', data, off + 4);
            local zone_id = use_cw_zones and cw_zone or ace_zone;
            local area = get_zone_name(zone_id);
            local level_range = tier_names[tier + 1];
            local details = get_vnm_details(area, level_range);

            upsert_venture(existing, new_ventures, {
                pool = pool,
                level_range = level_range,
                area = area,
                completion = progress,
                loc = details.loc,
                equipment = details.equipment,
                element = details.element,
                crest = details.crest,
                notes = details.notes
            });
        end
    end

    local hvnm_zone = struct.unpack('H', data, 0x51);
    local hvnm_progress = struct.unpack('B', data, 0x53) / 2;
    local hvnm_area = get_zone_name(hvnm_zone);
    local hvnm_details = get_vnm_details(hvnm_area, 'HVNM');

    upsert_venture(existing, new_ventures, {
        pool = '',
        level_range = 'HVNM',
        area = hvnm_area,
        completion = hvnm_progress,
        loc = hvnm_details.loc,
        equipment = hvnm_details.equipment,
        element = hvnm_details.element,
        crest = hvnm_details.crest,
        notes = hvnm_details.notes
    });

    self.parsed_ventures = new_ventures;
    return self.parsed_ventures;
end

function parser:refresh_venture_mode()
    if not self.last_packet_data then
        return self.parsed_ventures;
    end

    return self:parse_venture_packet(self.last_packet_data);
end

function parser:reload_vnm_data()
    vnm_data = vnm_loader:load();
end

-- Get parsed ventures
function parser:get_ventures()
    return self.parsed_ventures or {};
end

return parser;
