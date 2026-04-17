local chat = require('chat');
local http = require('socket.http');
local ltn12 = require('socket.ltn12');

local vnm_loader = {
    url = 'http://raw.githubusercontent.com/commandobill/ventures/main/data/vnms.lua',
    cache_path = addon.path .. '\\data\\vnms_remote.lua',
    temp_path = addon.path .. '\\data\\vnms_remote.tmp'
};

local function load_lua_table(path)
    local fn, err = loadfile(path);
    if not fn then
        return nil, err;
    end

    local ok, data = pcall(fn);
    if not ok then
        return nil, data;
    end

    if type(data) ~= 'table' then
        return nil, 'VNM data did not return a table.';
    end

    return data;
end

local function write_file(path, content)
    local file, err = io.open(path, 'wb');
    if not file then
        return false, err;
    end

    file:write(content);
    file:close();
    return true;
end

local function download_url(url)
    local chunks = {};
    local ok, code, headers = http.request({
        url = url,
        sink = ltn12.sink.table(chunks)
    });

    code = tonumber(code);
    if ok and code and code >= 300 and code < 400 and headers and headers.location then
        chunks = {};
        ok, code = http.request({
            url = headers.location,
            sink = ltn12.sink.table(chunks)
        });
        code = tonumber(code);
    end

    if not ok or code ~= 200 then
        return nil, string.format('download failed with status %s', tostring(code));
    end

    return table.concat(chunks);
end

function vnm_loader:load()
    local data = load_lua_table(self.cache_path);
    if data then
        return data, 'remote';
    end

    return require('data.vnms'), 'bundled';
end

function vnm_loader:update()
    local previous_timeout = http.TIMEOUT;
    http.TIMEOUT = 10;

    local content, download_err = download_url(self.url);
    http.TIMEOUT = previous_timeout;

    if not content then
        return false, download_err;
    end

    if content == '' then
        return false, 'downloaded file was empty';
    end

    local written, write_err = write_file(self.temp_path, content);
    if not written then
        return false, write_err;
    end

    local data, load_err = load_lua_table(self.temp_path);
    if not data then
        os.remove(self.temp_path);
        return false, load_err;
    end

    os.remove(self.cache_path);
    local renamed, rename_err = os.rename(self.temp_path, self.cache_path);
    if not renamed then
        os.remove(self.temp_path);
        return false, rename_err;
    end

    return true;
end

function vnm_loader:update_on_load()
    local ok, err = self:update();
    if ok then
        print(chat.header(addon.name) .. chat.success('Updated VNM data from GitHub.'));
    else
        print(chat.header(addon.name) .. chat.warning('Using cached/bundled VNM data: ' .. tostring(err)));
    end

    return ok;
end

return vnm_loader;
