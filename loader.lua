local URL = "https://raw.githubusercontent.com/solidvhdx/bomb-fishing/main/main.lua"

local body = game:HttpGet(URL)
if type(body) ~= "string" or #body < 100 then
	error("[Bomb Fishing] HttpGet failed or returned empty response")
end

local compile = loadstring or load
if not compile then
	error("[Bomb Fishing] Executor has no loadstring or load")
end

local fn, err = compile(body)
if not fn then
	error("[Bomb Fishing] Compile failed: " .. tostring(err))
end

fn()
