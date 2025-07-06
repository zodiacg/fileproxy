-- Lua dependencies: only lua-resty-http (OPM install) ◆
local http = require "resty.http"

local MAX_REDIRECTS = 5

local function fix_scheme(u)
    return (u:gsub("^(https?):/+", "%1://", 1))
end

local function resolve(loc, base)
    if loc:match("^https?://") then return loc end
    local origin = base:match("^(https?://[^/]+)")
    if loc:sub(1,1) == "/" then return origin .. loc end
    local dir = base:match("^(https?://.*/)") or (origin .. "/")
    return dir .. loc
end

local raw = ngx.var.raw_url
if not raw or raw == "" then return ngx.exit(400) end
ngx.log(ngx.INFO, "[fileproxy] IN  → ", target)

local url  = fix_scheme(raw)
local hops = 0
local httpc = http.new()
httpc:set_timeouts(6000, 60000, 60000)

while true do
    local res, err = httpc:request_uri(url, {
        method       = "HEAD",
        ssl_verify   = true,
        http_version = 1.1,
        max_body_size = 0
    })
    if not res then
        ngx.log(ngx.ERR, "[fileproxy] HEAD error: ", err)
        return ngx.exit(502)
    end

    if res.status >= 300 and res.status < 400 and res.headers.location then
        hops = hops + 1
        if hops > MAX_REDIRECTS then
            return ngx.exit(502)
        end
        url = resolve(res.headers.location, url)
    else
        break
    end
end

ngx.var.final_url = url
ngx.log(ngx.INFO, "[fileproxy] OUT → ", url)
ngx.exec("@relay")
