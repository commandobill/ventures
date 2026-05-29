local venture = require('models.venture');
local vnm_loader = require('services.vnm_loader');
local vnm_data = vnm_loader:load();
local zone_names = require('data.zones');
local config = require('configs.config');

local parser = {
    parsed_ventures = {},
    last_packet_data = nil
};

local function make_venture_key(pool, level_range)
    return string.format('%s|%s', pool or '', level_range or '')
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

local function apply_mode_data(venture_data, mode)
    local mode_data = venture_data.mode_data and venture_data.mode_data[mode];
    if not mode_data then
        return venture_data;
    end

    venture_data.area = mode_data.area;
    venture_data.loc = mode_data.loc;
    venture_data.equipment = mode_data.equipment;
    venture_data.element = mode_data.element;
    venture_data.crest = mode_data.crest;
    venture_data.notes = mode_data.notes;
    return venture_data;
end

local function upsert_venture(existing, new_ventures, venture_data, mode)
    local key = make_venture_key(venture_data.pool, venture_data.level_range);
    local v = existing[key];
    venture_data = apply_mode_data(venture_data, mode);
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
        existing[make_venture_key(v.pool, v.level_range)] = v;
    end
    return existing;
end

function parser:parse_venture_packet(data)
    self.last_packet_data = data;

    local venture_mode = string.upper(config.get('venture_mode') or 'ACE');
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
            local level_range = tier_names[tier + 1];
            local ace_area = get_zone_name(ace_zone);
            local cw_area = get_zone_name(cw_zone);
            local ace_details = get_vnm_details(ace_area, level_range);
            local cw_details = get_vnm_details(cw_area, level_range);

            upsert_venture(existing, new_ventures, {
                pool = pool,
                level_range = level_range,
                completion = progress,
                mode_data = {
                    ACE = {
                        area = ace_area,
                        loc = ace_details.loc,
                        equipment = ace_details.equipment,
                        element = ace_details.element,
                        crest = ace_details.crest,
                        notes = ace_details.notes
                    },
                    CW = {
                        area = cw_area,
                        loc = cw_details.loc,
                        equipment = cw_details.equipment,
                        element = cw_details.element,
                        crest = cw_details.crest,
                        notes = cw_details.notes
                    }
                }
            }, venture_mode);
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
    }, venture_mode);

    self.parsed_ventures = new_ventures;
    return self.parsed_ventures;
end

function parser:refresh_venture_mode()
    local venture_mode = string.upper(config.get('venture_mode') or 'ACE');
    local applied_cached_mode = false;

    for _, v in ipairs(self.parsed_ventures or {}) do
        if v.mode_data and v.mode_data[venture_mode] then
            applied_cached_mode = true;
            v:update(apply_mode_data({
                pool = v.pool,
                level_range = v.level_range,
                completion = v.completion,
                mode_data = v.mode_data
            }, venture_mode));
        end
    end

    if applied_cached_mode then
        return self.parsed_ventures;
    end

    if self.last_packet_data then
        return self:parse_venture_packet(self.last_packet_data);
    end

    return self.parsed_ventures;
end

function parser:reload_vnm_data()
    vnm_data = vnm_loader:load();
end

-- Get parsed ventures
function parser:get_ventures()
    return self.parsed_ventures or {};
end

return parser;
