local venture = require('models.venture');
local chat = require('chat');
local vnm_data = require('data.vnms');

local parser = {
    capture_active = false,
    capture_lines = {},
    capture_start_time = 0,
    capture_timeout = 5,
    max_lines = 50,
    header_detected = false,
    parsed_ventures = {},
    packet = struct.pack('bbbbbbbbbbbbbbbbbbbb',
    0xB5, 0x08, 0x81, 0x01, 0x00, 0x00,  -- Reserved
    0x21, 0x76, 0x65, 0x6E, 0x74, 0x75, 0x72, 0x65, 0x73, 0x20, 0x65, 0x78, 0x70, 0x00):totable()
};

-- GetEventSystemActive Code From Thorny
local pEventSystem = ashita.memory.find('FFXiMain.dll', 0, "A0????????84C0741AA1????????85C0741166A1????????663B05????????0F94C0C3", 0, 0);
local function GetEventSystemActive()
    if (pEventSystem == 0) then
        return false;
    end
    local ptr = ashita.memory.read_uint32(pEventSystem + 1);
    if (ptr == 0) then
        return false;
    end

    return (ashita.memory.read_uint8(ptr) == 1);
end

local function sanitize_string(v)
    local str = tostring(v or "");
    str = str:gsub("^EXP Areas:%s*", "");
    -- Remove non-printable / high-byte characters
    str = str:gsub("[^%g%s]", "");
    return str
end

local function make_venture_key(pool, level_range, area)
    return string.format('%s|%s|%s', pool or '', level_range or '', area or '')
end

-- Parse EXP Areas from captured lines
function parser:parse_exp_areas(lines)
    local combined_parts = {};

    for _, entry in ipairs(lines) do
        local message = sanitize_string(entry.message);
        if message ~= '' then
            table.insert(combined_parts, message);
        end
    end

    local exp_text = table.concat(combined_parts, ', ');

    if exp_text == '' then
        return self.parsed_ventures;
    end

    -- Build a lookup for existing ventures by pool + level_range + area.
    local existing = {}
    for _, v in ipairs(self.parsed_ventures or {}) do
        existing[make_venture_key(v.pool, v.level_range, v.area)] = v
    end

    local new_ventures = {}
    local current_pool = nil;

    -- Parse each venture entry
    for part in exp_text:gmatch("[^,]+") do
        part = sanitize_string(part):gsub("^%s*(.-)%s*$", "%1");
        if part ~= '' then
            local pool = part:match("^Pool%s+([A-Za-z])%s*:%s*");
            if pool then
                current_pool = pool:upper();
                part = part:gsub("^Pool%s+[A-Za-z]%s*:%s*", "");
            end

            local level_range = part:match("%((%d+%-%d+)%)");
            local completion = part:match("@(%d+)%%");
            local area = part:gsub("%b()", ""):gsub("@%d+%%", ""):gsub("^%s*(.-)%s*$", "%1");
            local vnm_position = nil;
            local vnm_equipment = nil;
            local vnm_element = nil;
            local vnm_crest = nil;
            local vnm_notes = nil;
            local is_hvnm = false;

            if part:find("^%s*HVNM:") then
                is_hvnm = true;
                level_range = 'HVNM';
                area = part:match("HVNM:%s*(.-)%s*%(");
                completion = part:match("@(%d+)%%");
                pool = nil;
            end

            local vnm_zone = vnm_data[area];

            if vnm_zone then
                for _, vnm in ipairs(vnm_zone) do
                    if vnm.level_range == level_range then
                        vnm_position = vnm.position;
                        vnm_equipment = vnm.equipment;
                        vnm_element = vnm.element;
                        vnm_crest = vnm.crest;
                        vnm_notes = vnm.notes;
                        vnm_name = vnm.name;
                        break;
                    end
                end
            end

            if level_range and area then
                local venture_data = {
                    pool = is_hvnm and '' or (pool or current_pool or ''),
                    level_range = level_range,
                    area = area,
                    completion = completion or '0',
                    loc = vnm_position and string.format("(%s)", vnm_position) or "",
                    equipment = vnm_equipment or "",
                    element = vnm_element or "",
                    crest = vnm_crest or "",
                    notes = vnm_notes and string.format("%s", vnm_notes) or ""
                };
                local key = make_venture_key(venture_data.pool, venture_data.level_range, venture_data.area);
                local v = existing[key]
                if v then
                    v:update(venture_data)
                    table.insert(new_ventures, v)
                else
                    table.insert(new_ventures, venture:new(venture_data))
                end
            end
        end
    end

    self.parsed_ventures = new_ventures;
    return self.parsed_ventures;
end

-- Send !ventures command
function parser:send_ventures_command()
    local zone_id = AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0);
    if zone_id == 0 then
        return false;
    end

    --AshitaCore:GetChatManager():QueueCommand(1, '/say !ventures');
    if not GetEventSystemActive() then
        AshitaCore:GetPacketManager():AddOutgoingPacket(0xB5, parser.packet);
        self.capture_active = true;
        self.capture_lines = {};
        self.capture_start_time = os.clock();
        self.header_detected = false;
        return true;
    else
        return false;
    end
end

-- Get parsed ventures
function parser:get_ventures()
    return self.parsed_ventures or {};
end

return parser;