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



-- Parse EXP Areas from captured lines
function parser:parse_exp_areas(lines)
    local exp_text = '';
    local found_exp_start = false;

    -- Find and combine EXP Areas text
    for _, entry in ipairs(lines) do
        if not found_exp_start then
            if string.find(entry.message, '^EXP Areas:') then
                exp_text = exp_text .. entry.message;
                found_exp_start = true;
            end
        elseif found_exp_start then
            exp_text = exp_text .. ', ' .. entry.message;
        end
    end

    if exp_text == '' then
        return self.parsed_ventures;
    end

    -- Build a lookup for existing ventures by level_range
    local existing = {}
    for _, v in ipairs(self.parsed_ventures or {}) do
        existing[v.level_range] = v
    end

    local new_ventures = {}
    exp_text = exp_text:gsub("^EXP Areas:%s*", "");
    

    -- Parse each venture entry
    for part in exp_text:gmatch("[^,]+") do
        
        local level_range = part:match("%((%d+%-%d+)%)");
        local completion = part:match("@(%d+)%%");
        local area = part:gsub("%b()", ""):gsub("@%d+%%", ""):gsub("^%s*(.-)%s*$", "%1");
        local vnm_position = nil;
        local vnm_equipment = nil;
        local vnm_element = nil;
        local vnm_crest = nil;
        local vnm_notes = nil;        

        if part:find("^%s*HVNM:") then
            level_range = part:match("HVNM");
            area = part:match("HVNM:%s*(.-)%s*%(");
            completion = part:match("@(%d+)%%");
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
                level_range = level_range,
                area = area,
                completion = completion or '0',
                loc = vnm_position and string.format("(%s)", vnm_position) or "",
                equipment = vnm_equipment or "",
                element = vnm_element or "",
                crest = vnm_crest or "",
                notes = vnm_notes and string.format("%s", vnm_notes) or ""
            };
            local v = existing[level_range]
            if v then
                v:update(venture_data)
                table.insert(new_ventures, v)
            else
                table.insert(new_ventures, venture:new(venture_data))
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