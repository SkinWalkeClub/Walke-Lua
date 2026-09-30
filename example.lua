local WalkeLua = loadstring(game:HttpGet("https://raw.githubusercontent.com/SkinWalkeClub/Walke-Lua/main/walkelua.lua"))()

local ugly = [[local a=1;local b=2 if a<b then print("smaller")else print("bigger")end for i=1,3 do print(i)end local t={1,2,3,x=10,y=20}return t]]

local clean, err = WalkeLua.safe(ugly)

if err then
	warn("Walke Lua could not parse it: " .. err)
else
	print(clean)
end

local cb = (getgenv and getgenv().setclipboard) or setclipboard
if cb and not err then
	cb(clean)
	print("clean version copied to clipboard")
end

local target = game:GetService("ReplicatedStorage"):FindFirstChild("SomeModule")
if target and target:IsA("ModuleScript") then
	local src = decompile and decompile(target)
	if src then
		local pretty = WalkeLua.safe(src, { indent = "\t" })
		writefile("SomeModule_clean.lua", pretty)
		print("saved beautified module to SomeModule_clean.lua")
	end
end
