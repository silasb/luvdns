ltn12 = require'ltn12'
http = require'socket.http'
json = require'json'
lfs = require'lfs'
-- require'utils' -- print_r

if # arg < 1 then
  print "Missing argument: URL"
  return
end

url = arg[1]

-----------------
-- Meta methods
-----------------

local Meta = {}

function Meta.__concat( anObject, anotherObject )
  return tostring( anObject ) .. tostring( anotherObject )
end

function Meta.__tostring( anObject )
  return anObject:toString()
end

-----------------
-- Zone methods
-----------------

local Zone = {}

setmetatable( Zone , meta )

function Zone:new(name)
  self.zone_struct = {
    id = name,
    zone = {
      cname = {},
      a = {}
    }
  }

  return self
end

function Zone:cname( name, alias, ttl )
  table.insert(self.zone_struct.zone.cname, {
    name = name,
    alias = alias,
    ttl = ttl
  })
end

function Zone:a( name, ip, ttl )
  table.insert(self.zone_struct.zone.a, {
    name = name,
    content = ip,
    ttl = ttl
  })
end

function Zone:encode()
  return json.encode( self.zone_struct )
end

function cname( name, alias, ttl )
  zone:cname( name, ip, ttl )
end

function a( name, ip, ttl )
  zone:a( name, ip, ttl )
end

function findpattern(text, pattern, start)
  return string.sub(text, string.find(text, pattern, start))
end

function find_zones()
  local zones = {}

  for file in lfs.dir(".") do
    result = (string.find(file, '%.com.lua') ~= nil)
    if result then
      if lfs.attributes(file, 'mode') == 'file' then
        _a = string.gsub(file, '%.lua', '')
        zones[_a] = file
        print('found zone ' .. _a)
      end
    end
  end

  return zones
end

function send(params)
  source = ltn12.source.string(params)
  response = {}
  save = ltn12.sink.table(response)

  size = # params

  result, statuscode, content = http.request {

    url = url,
    headers = {
      ["Content-type"] = "application/json",
      ["content-length"] = size
    },
    method = 'POST',
    source = source,
    sink = save
  }

  print(statuscode)
end

local zones = find_zones()

for zone_name,zone_file in pairs(zones) do
  zone = Zone:new(zone_name)
  local zone_func = loadfile(zone_file)
  zone_func()
  local json = zone:encode()
  send(json)
end

