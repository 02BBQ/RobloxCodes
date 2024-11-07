--[[
	Action handler, handles inputs and general client-server communication
	Will be refactored soon
]]

--//Variables
local Players = game:GetService('Players');
local ReplicatedStorage = game:GetService('ReplicatedStorage');
local UserInputService = game:GetService('UserInputService');
local ContextActionService = game:GetService('ContextActionService');
local RunService = game:GetService("RunService")

local LocalPlayer: Player = Players.LocalPlayer;

local Map: Folder = workspace:WaitForChild('Map');

local CharacterHandler = require(script.Parent.CharacterHandler)

local ActionComponent = {}
ActionComponent.__index = ActionComponent

--Dictionary containing functions to return values to the server
local FetchTypes = {
	Camera = function()
		return workspace.CurrentCamera.CFrame;
	end;

	--MoveDirection = function()
	--	return CharacterHandler.MovementDirection;
	--end;

	RootCFrame = function()
		local Character = LocalPlayer.Character;
		if not Character or not Character:IsDescendantOf(workspace.Alive) then return end;
		local HRP = Character:FindFirstChild('HumanoidRootPart');

		return HRP.CFrame;
	end;

	LastActionCheck = function()
		local Character = LocalPlayer.Character;
		if not Character or not Character:IsDescendantOf(workspace.Alive) then return end;
		local Humanoid: Humanoid = Character:FindFirstChildOfClass('Humanoid');
		if not Humanoid then return end;

		local CurrentPunch = Character:GetAttribute('CurrentPunch')		
		if (not CurrentPunch) or (CurrentPunch+1 ~= 4) then return end;

		if Humanoid:GetState() == Enum.HumanoidStateType.Freefall then
			return 'Downslam';
		elseif UserInputService:IsKeyDown(Enum.KeyCode.Space) or Humanoid.Jump then
			return 'Uptilt';
		end;

		return 'Normal';
	end;

	FloorMaterial = function()
		local Character = LocalPlayer.Character;
		if not Character or not Character:IsDescendantOf(workspace.Alive) then return end;
		local Humanoid: Humanoid = Character:WaitForChild('Humanoid');
		if not Humanoid then return end;

		return Humanoid.FloorMaterial;
	end;
};


function ActionComponent.new()
	local self = setmetatable({}, ActionComponent)
	return self
end

function ActionComponent:Sprint(Held: boolean?)
	if not Held then return end;

	local Character = LocalPlayer.Character;
	if not Character then return end;
	if not Character:IsDescendantOf(workspace.Alive) then return end;
end


function ActionComponent:Dash(Held: boolean?, args)
	if not Held then return end;

	task.spawn(CharacterHandler.Dash);
end

function ActionComponent:Block(Held: boolean?, args)
	if not Held then return end;
end


function ActionComponent:Click(Held: boolean?, args)
	if not Held then return end;
	
	script.Parent.Parent.Parent.RemoteEvent:FireServer()
end

return ActionComponent