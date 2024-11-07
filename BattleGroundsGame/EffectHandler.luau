-- just we can put other effect modules as children
local isClient = game:GetService("RunService"):IsClient();
local check1 = {};
local check2 = {};
local Funcs = {};
if isClient then
	local index, value = script:GetChildren();
	while true do
		local nextIndex, nextValue = next(index, value);
		if not nextIndex then
			break;
		end;
		value = nextIndex;
		if nextValue:IsA("ModuleScript") then
			table.insert(check1, nextValue);
			spawn(function()
				Funcs[nextValue.Name] = require(nextValue);
				table.insert(check2, nextValue);
			end);
		end;	
	end;
	while #check1 ~= #check2 do
		wait();	
	end;
	print("Done requiring all modules");
end;
local metatable = {};
function metatable.__index(p1, p2)
	return isClient and Funcs[p2] or require(script[p2]);
end;
return setmetatable({}, metatable);