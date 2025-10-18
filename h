local HttpService = game:GetService("HttpService")
local RbxAnalytics = game:GetService("RbxAnalyticsService")
local RunService = game:GetService('RunService')
local Players = game:GetService('Players')
local LocalPlayer = Players.LocalPlayer

local Module = {}

Module.CONFIG = {
    VERSION = '1.3.4',
    MIN_VERSION = '1.3.3',
    HTTP_TIMEOUT = 15,
    VALIDATION_API_URL = "https://v0-remix-of-roblox-executor-system.vercel.app",
    SUPABASE_URL = "https://yrlxosurmcpxrlmxckke.supabase.co",
    SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlybHhvc3VybWNweHJsbXhja2tlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA0MjQ2NzQsImV4cCI6MjA2NjAwMDY3NH0.F6y_yw26UOJPGDFyhBQ0u__QNf0FPzL2uwbuGhntWYQ",
    CACHE_FILE = "hwid_cache.json",
    KEY_FILE = "validation_key.dat",
    MASTER_KEY = "checkdeezfuckingnuts",
    VERSION_URL = "https://pastebin.com/raw/ptHNczy5",
    VERSION_TOKEN_FALLBACK = 'VAULT_1_3_4_AUTH',
    MAX_RETRIES = 3,
    RETRY_DELAY = 0.5,
}

Module.VALIDATION_STATE = {
    authenticated = false,
    sessionToken = nil,
    lastValidation = 0,
    tamperChecks = 0,
    failedAttempts = 0
}

Module.RATE_LIMIT = {
    maxAttempts = 5,
    windowSeconds = 60,
    attempts = {},
    blocked = false
}

Module.ORIGINAL_FUNCTIONS = {
    httpRequest = nil,
    HttpGet = nil
}

if not bit32 then
    bit32 = {}
    function bit32.bxor(a,b)
        local res = 0
        local bitval = 1
        while a > 0 or b > 0 do
            local abit = a % 2
            local bbit = b % 2
            if (abit + bbit) % 2 == 1 then res = res + bitval end
            bitval = bitval * 2
            a = math.floor(a/2)
            b = math.floor(b/2)
        end
        return res
    end
end

local SECRET_KEY = HttpService:GenerateGUID(false)
local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

function Module.httpRequest(options)
    if not Module.ORIGINAL_FUNCTIONS.httpRequest then
        Module.ORIGINAL_FUNCTIONS.httpRequest = request or http_request or (syn and syn.request)
    end
    
    local func = Module.ORIGINAL_FUNCTIONS.httpRequest
    if not func then
        error("No HTTP request function found")
    end
    
    options.Headers = options.Headers or {}
    options.Headers["X-Session-Token"] = Module.VALIDATION_STATE.sessionToken or "none"
    options.Headers["X-Client-Timestamp"] = tostring(os.time())
    
    return func(options)
end

function Module.hashString(str)
    local hash = 0
    for i = 1, #str do
        hash = ((hash * 31) + string.byte(str, i)) % 4294967296
    end
    return string.format("%08x", hash)
end

function Module.generateSessionToken(clientId)
    local timestamp = tostring(os.time())
    local random = tostring(math.random(100000000, 999999999))
    local combined = clientId .. timestamp .. random .. SECRET_KEY
    return Module.hashString(combined)
end

function Module.xorEncrypt(text, key)
    local result = {}
    local keyLen = #key
    for i = 1, #text do
        local textByte = string.byte(text, i)
        local keyByte = string.byte(key, ((i - 1) % keyLen) + 1)
        table.insert(result, string.char(bit32.bxor(textByte, keyByte)))
    end
    return table.concat(result)
end

function Module.base64Encode(data)
    return ((data:gsub('.', function(x) 
        local r,bits = '', x:byte()
        for i=8,1,-1 do r = r .. (bits % 2 ^ i - bits % 2 ^ (i-1) > 0 and '1' or '0') end
        return r
    end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if #x < 6 then return '' end
        local c=0
        for i=1,6 do c = c*2 + (x:sub(i,i) == '1' and 1 or 0) end
        return b64chars:sub(c+1,c+1)
    end) .. ({ '', '==', '=' })[#data % 3 + 1])
end

function Module.base64Decode(data)
    data = string.gsub(data, '[^'..b64chars..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b64chars:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

function Module.encrypt(plain, key)
    local x = Module.xorEncrypt(plain, key)
    return Module.base64Encode(x)
end

function Module.decrypt(cipher_b64, key)
    local decoded = Module.base64Decode(cipher_b64)
    return Module.xorEncrypt(decoded, key)
end

function Module.saveKey(key)
    if not writefile then
        return false
    end
    
    local success = pcall(function()
        local sessionBound = key .. "|" .. Module.VALIDATION_STATE.sessionToken .. "|" .. tostring(os.time())
        local encrypted = Module.encrypt(sessionBound, Module.CONFIG.MASTER_KEY)
        writefile(Module.CONFIG.KEY_FILE, encrypted)
    end)
    
    return success
end

function Module.loadKey()
    if not isfile or not readfile then
        return nil
    end
    
    local success, result = pcall(function()
        if isfile(Module.CONFIG.KEY_FILE) then
            local encrypted = readfile(Module.CONFIG.KEY_FILE)
            local decrypted = Module.decrypt(encrypted, Module.CONFIG.MASTER_KEY)
            
            local parts = {}
            for part in decrypted:gmatch("[^|]+") do
                table.insert(parts, part)
            end
            
            if #parts >= 3 then
                local key = parts[1]
                local timestamp = tonumber(parts[3])
                
                if os.time() - timestamp < 86400 then
                    return key
                end
            end
        end
    end)
    
    if success and result then
        return result
    end
    
    return nil
end

function Module.deleteKey()
    if not delfile or not isfile then
        return false
    end
    
    local success = pcall(function()
        if isfile(Module.CONFIG.KEY_FILE) then
            delfile(Module.CONFIG.KEY_FILE)
        end
    end)
    
    return success
end

function Module.performTamperCheck()
    Module.VALIDATION_STATE.tamperChecks = Module.VALIDATION_STATE.tamperChecks + 1
    
    local currentHttpRequest = request or http_request or (syn and syn.request)
    if Module.ORIGINAL_FUNCTIONS.httpRequest and currentHttpRequest ~= Module.ORIGINAL_FUNCTIONS.httpRequest then
        return false
    end
    
    if type(Module.VALIDATION_STATE) ~= "table" then
        return false
    end
    
    return true
end

function Module.checkRateLimit()
    local currentTime = os.time()
    
    local newAttempts = {}
    for _, timestamp in ipairs(Module.RATE_LIMIT.attempts) do
        if currentTime - timestamp < Module.RATE_LIMIT.windowSeconds then
            table.insert(newAttempts, timestamp)
        end
    end
    Module.RATE_LIMIT.attempts = newAttempts
    
    if #Module.RATE_LIMIT.attempts >= Module.RATE_LIMIT.maxAttempts then
        Module.RATE_LIMIT.blocked = true
        return false, "Rate limit exceeded. Please wait " .. Module.RATE_LIMIT.windowSeconds .. " seconds."
    end
    
    table.insert(Module.RATE_LIMIT.attempts, currentTime)
    return true
end

function Module.trim(s)
    return (s or ""):match("^%s*(.-)%s*$") or ""
end

function Module.loadCache()
    if not isfile then
        return nil
    end
    
    local success, result = pcall(function()
        if isfile(Module.CONFIG.CACHE_FILE) then
            local content = readfile(Module.CONFIG.CACHE_FILE)
            return HttpService:JSONDecode(content)
        end
    end)
    
    if success and result then
        return result
    end
    
    return nil
end

function Module.saveCache(data)
    if not writefile then
        return false
    end
    
    local success = pcall(function()
        local json = HttpService:JSONEncode(data)
        writefile(Module.CONFIG.CACHE_FILE, json)
    end)
    
    return success
end

function Module.setValidated(clientId, value)
    local cache = Module.loadCache() or {}
    
    if not cache[clientId] then
        cache[clientId] = {
            lastCheck = os.time(),
            validated = value,
            accessDenied = false
        }
    else
        cache[clientId].validated = value
    end
    
    Module.saveCache(cache)
end

function Module.setAccessDenied(clientId, value)
    local cache = Module.loadCache() or {}
    
    if not cache[clientId] then
        cache[clientId] = {
            lastCheck = os.time(),
            validated = false,
            accessDenied = value
        }
    else
        cache[clientId].accessDenied = value
    end
    
    Module.saveCache(cache)
end

function Module.getCacheData(clientId)
    local cache = Module.loadCache()
    
    if not cache or not cache[clientId] then
        return {
            validated = false,
            accessDenied = false
        }
    end
    
    return cache[clientId]
end

function Module.resetCache(clientId)
    local cache = Module.loadCache() or {}
    cache[clientId] = {
        lastCheck = os.time(),
        validated = false,
        accessDenied = false
    }
    Module.saveCache(cache)
end

function Module.checkSupabaseHWID(clientId, encryptedClientId)
    local url = Module.CONFIG.SUPABASE_URL .. "/rest/v1/keys?hwid=eq." .. HttpService:UrlEncode(encryptedClientId) .. "&key_type=eq.hwid&is_active=eq.true&select=*"
    
    local success, response = pcall(function()
        return Module.httpRequest({
            Url = url,
            Method = "GET",
            Headers = {
                ["apikey"] = Module.CONFIG.SUPABASE_ANON_KEY,
                ["Authorization"] = "Bearer " .. Module.CONFIG.SUPABASE_ANON_KEY,
                ["Content-Type"] = "application/json"
            }
        })
    end)
    
    if not success then
        return false, nil, "access_denied"
    end
    
    local parseSuccess, data = pcall(function()
        return HttpService:JSONDecode(response.Body)
    end)
    
    if not parseSuccess then
        return false, nil, "access_denied"
    end
    
    if type(data) ~= "table" or #data == 0 then
        return false, nil, "access_denied"
    end
    
    local keyData = data[1]
    
    local expiresAt = keyData.expires_at
    local now = os.time()
    
    if expiresAt then
        local year, month, day, hour, min, sec = string.match(expiresAt, "(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)")
        if year then
            local expiryTime = os.time({
                year = tonumber(year),
                month = tonumber(month),
                day = tonumber(day),
                hour = tonumber(hour),
                min = tonumber(min),
                sec = tonumber(sec)
            })
            
            if expiryTime <= now then
                return false, nil, "key_expired"
            end
        end
    end
    
    return true, {
        source = "supabase",
        key = keyData.key_value,
        username = keyData.username,
        expires_at = keyData.expires_at,
        is_global_timer_dependent = keyData.is_global_timer_dependent
    }, nil
end

function Module.isClientIdWhitelisted(clientId, encryptedClientId)
    if not Module.performTamperCheck() then
        return false, nil, "tamper_detected"
    end
    
    local cacheData = Module.getCacheData(clientId)
    
    if cacheData.accessDenied then
        if os.time() - cacheData.lastCheck < 3600 then
            return false, nil, "access_denied"
        else
            Module.resetCache(clientId)
        end
    end
    
    local found, matchData, errorType = Module.checkSupabaseHWID(clientId, encryptedClientId)
    
    if errorType == "access_denied" or errorType == "key_expired" then
        Module.setAccessDenied(clientId, true)
        return false, nil, errorType
    end
    
    if found then
        return true, matchData, nil
    end
    
    Module.setAccessDenied(clientId, true)
    return false, nil, "access_denied"
end

function Module.validateKey(key, clientId, Library)
    local rateLimitOk, rateLimitMsg = Module.checkRateLimit()
    if not rateLimitOk then
        Library:Notify({
            Title = "⚠️ Rate Limit",
            Description = rateLimitMsg,
            Time = 5
        })
        return false
    end
    
    if not Module.performTamperCheck() then
        Library:Notify({
            Title = "⚠️ Security Warning",
            Description = "Tampering detected. Please restart.",
            Time = 5
        })
        return false
    end
    
    Library:Notify({
        Title = "🔒 Key Validation",
        Description = "Validating your key...",
        Time = 3
    })
    
    local url = Module.CONFIG.VALIDATION_API_URL .. "/api/roblox-validate-hwid?key=" .. HttpService:UrlEncode(key) .. "&hwid=" .. HttpService:UrlEncode(tostring(clientId))
    
    local success, response = pcall(function()
        return Module.httpRequest({
            Url = url,
            Method = "GET"
        })
    end)
    
    if not success then
        Module.VALIDATION_STATE.failedAttempts = Module.VALIDATION_STATE.failedAttempts + 1
        Library:Notify({
            Title = "❌ Validation Failed",
            Description = "Request failed: Network error",
            Time = 5
        })
        return false
    end
    
    local responseBody = response.Body or response
    local parseSuccess, data = pcall(function()
        return HttpService:JSONDecode(responseBody)
    end)
    
    if parseSuccess and data and data.success then
        Module.VALIDATION_STATE.sessionToken = Module.generateSessionToken(clientId)
        Module.VALIDATION_STATE.authenticated = true
        Module.VALIDATION_STATE.lastValidation = os.time()
        Module.VALIDATION_STATE.failedAttempts = 0
        
        Library:Notify({
            Title = "✅ Success",
            Description = "Key validated successfully!",
            Time = 3
        })
        
        pcall(function()
            Module.httpRequest({
                Url = Module.CONFIG.VALIDATION_API_URL .. "/api/add-client-to-github",
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HttpService:JSONEncode({
                    clientId = clientId
                })
            })
        end)
        
        Module.setValidated(clientId, true)
        Module.setAccessDenied(clientId, false)
        Module.saveKey(key)
        return true
    else
        Module.VALIDATION_STATE.failedAttempts = Module.VALIDATION_STATE.failedAttempts + 1
        
        if Module.VALIDATION_STATE.failedAttempts >= 5 then
            Library:Notify({
                Title = "🔒 Locked Out",
                Description = "Too many failed attempts. Wait 5 minutes.",
                Time = 10
            })
            wait(300)
            Module.VALIDATION_STATE.failedAttempts = 0
        end
        
        Library:Notify({
            Title = "❌ Validation Failed",
            Description = "Invalid key or HWID",
            Time = 5
        })
        return false
    end
end

function Module.compareVersions(v1, v2)
    local v1Parts = { v1:match('(%d+)%.(%d+)%.(%d+)') }
    local v2Parts = { v2:match('(%d+)%.(%d+)%.(%d+)') }
    for i = 1, 3 do
        local n1, n2 = tonumber(v1Parts[i]) or 0, tonumber(v2Parts[i]) or 0
        if n1 < n2 then
            return -1
        end
        if n1 > n2 then
            return 1
        end
    end
    return 0
end

function Module.safeHttpGet(url, retries)
    retries = retries or 3
    local data, success, errorMsg

    for i = 1, retries do
        local requestComplete = false
        local requestThread = coroutine.create(function()
            success, data = pcall(function()
                return game:HttpGet(url)
            end)
            if not success then
                errorMsg = data
                data = nil
            end
            requestComplete = true
        end)

        coroutine.resume(requestThread)

        local startTime = tick()
        while not requestComplete and (tick() - startTime) < Module.CONFIG.HTTP_TIMEOUT do
            task.wait(0.1)
        end

        if requestComplete and success then
            return true, data
        end

        if i < retries then
            task.wait(2)
        end
    end

    return false, errorMsg or 'Request timed out or blocked'
end

function Module.checkVersionAndToken()
    local success, response = Module.safeHttpGet(Module.CONFIG.VERSION_URL)
    if success then
        local version, token = response:match('([^|]+)|(.+)')
        if not version or not token then
            return false, 'Invalid version format in Pastebin', Module.CONFIG.VERSION_TOKEN_FALLBACK
        end
        if Module.compareVersions(Module.CONFIG.VERSION, version) < 0 then
            return false, 'Script outdated. Please update to v' .. version, token
        elseif Module.compareVersions(Module.CONFIG.VERSION, Module.CONFIG.MIN_VERSION) < 0 then
            return false, 'Version below minimum required (' .. Module.CONFIG.MIN_VERSION .. ')', token
        end
        return true, version, token
    end
    return true, Module.CONFIG.VERSION, Module.CONFIG.VERSION_TOKEN_FALLBACK
end

function Module.startSessionMonitoring(clientId)
    spawn(function()
        while Module.VALIDATION_STATE.authenticated do
            wait(30)
            
            if os.time() - Module.VALIDATION_STATE.lastValidation > 86400 then
                Module.VALIDATION_STATE.authenticated = false
                Module.deleteKey()
                break
            end
            
            if not Module.performTamperCheck() then
                Module.VALIDATION_STATE.authenticated = false
                Module.deleteKey()
                break
            end
        end
    end)
end

function Module.constructScriptUrl(parts)
    return table.concat(parts, '')
end

function Module.getScriptApiUrl()
    local scriptParts = {}
    scriptParts[1] = string.char(104, 116, 116, 112, 115, 58, 47, 47)
    scriptParts[2] = 'combo0-chroncile'
    scriptParts[3] = '.vercel'
    scriptParts[4] = '.app/api/roblox'
    return table.concat(scriptParts)
end

function Module.getDefaultScriptUrl()
    local defaultParts = {}
    defaultParts[1] = string.char(104, 116, 116, 112, 115, 58, 47, 47)
    defaultParts[2] = 'raw.githubusercontent'
    defaultParts[3] = '.com/checkurasshole/'
    defaultParts[4] = 'Script/refs/heads/main/'
    defaultParts[5] = 'Default'
    return table.concat(defaultParts)
end

function Module.getVersionUrl()
    local urlParts = {}
    urlParts[1] = string.char(104, 116, 116, 112, 115, 58, 47, 47)
    urlParts[2] = 'pastebin'
    urlParts[3] = '.com/raw/'
    urlParts[4] = 'ptHNczy5'
    return table.concat(urlParts)
end

Module.memoryCleanup = {
    connections = {},
    cleanup_interval = 30,
    last_cleanup = tick(),
    
    addConnection = function(self, connection)
        table.insert(self.connections, connection)
    end,
    
    cleanupMemory = function(self)
        if tick() - self.last_cleanup < self.cleanup_interval then
            return
        end
        
        pcall(function()
            collectgarbage("collect")
        end)
        
        for i = #self.connections, 1, -1 do
            local connection = self.connections[i]
            if connection and connection.Connected == false then
                table.remove(self.connections, i)
            end
        end
        
        self.last_cleanup = tick()
    end,
    
    disconnectAll = function(self)
        for _, connection in ipairs(self.connections) do
            if connection and connection.Connected then
                connection:Disconnect()
            end
        end
        self.connections = {}
        pcall(function()
            collectgarbage("collect")
        end)
    end
}

local cleanupConnection = RunService.Heartbeat:Connect(function()
    Module.memoryCleanup:cleanupMemory()
end)
Module.memoryCleanup:addConnection(cleanupConnection)

game.Players.PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then
        Module.memoryCleanup:disconnectAll()
    end
end)

return Module
