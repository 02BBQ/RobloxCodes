-- InputComponent.lua
local UserInputService = game:GetService("UserInputService")

local InputComponent = {}
InputComponent.__index = InputComponent

function InputComponent.new()
	local self = setmetatable({}, InputComponent)
	self.actions = {}

	return self
end

function InputComponent:BindAction(keyCode, callback, ...)
	self.actions[keyCode] = {callback = callback, args = {...}}
end

function InputComponent:HandleInput(Input: InputObject, isHeld)
	local action
	
	if Input.UserInputType == Enum.UserInputType.Keyboard then
		action = self.actions[Input.KeyCode]
	elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
		action = self.actions[Input.UserInputType]	
	end
	
	if action then
		action:callback(Input.UserInputState == Enum.UserInputState.Begin and true or false, table.unpack(action.args))
	end
end

return InputComponent
