--

--//Variables
local ServerScriptService = game:GetService('ServerScriptService');
local ReplicatedStorage = game:GetService('ReplicatedStorage');

local Components = ServerScriptService.Server.Components
local EntityTemplates = ReplicatedStorage.Shared.Storage

--component base programming yay
local ProfileHandler = require(Components.ProfileHandler);
local CombatManager = require(Components.Game.CombatManager);
local CharacterManager = require(Components.Game.CharacterManager);
local CooldownManager = require(Components.ServerUtil.CooldownManager);

local Trove = require(ReplicatedStorage.Shared.Utility.Trove)

--//Module
local Entities = {};
Entities.__index = Entities;
Entities.__tostring = function(self )
	return self.Name;
end;

local LEADERSTATS_INSTANCES = {
	[1] = 'Kills';
	[2] = 'Join';
};

Entities.Stored = {};
Entities.new = function(PresetInfo, PlayerObject: Player?)
	local self = setmetatable({
		
		_Connections = {};
		_Class = 'Entity';
		_Trove = Trove.new();

		Name = 'N/A';
		
		Valid = true;
		Ready = false;
		
		Player = PlayerObject;
		
	}, Entities);
	
	if self.Player then
		self.ProfileHolder = ProfileHandler.new(PlayerObject);
	end;
	
	self.Data = (self.ProfileHolder and self.ProfileHolder.Data);
	if not self.Data then
		self.Data = {};
		PresetInfo = PresetInfo or {};
		for i,v in ProfileHandler.Constants.DataTemplate do
			self.Data[i] = PresetInfo[i] or v;
		end;
	end;
	
	self.Character = self._Trove:Add((CharacterManager.new(self)));
	
	self.Combat = (CombatManager.new(self));
	self.Cooldowns = (CooldownManager.new(self));
	
	if self.Player then
		self.Leaderstats = Instance.new('Folder');
		self.Leaderstats.Parent = self.Player;
		
		self.Leaderstats.Name = 'leaderstats';
		
		for i = 1,#LEADERSTATS_INSTANCES do
			local InstName = LEADERSTATS_INSTANCES[i];
			Instance.new('NumberValue', self.Leaderstats).Name = InstName;
		end;
		
		self:UpdateLeaderstats();
		self.Name = self.Player.DisplayName or self.Player.Name;
	end;
	
	self.Ready = true;
	self.Stored[self] = true;
	
	return self;
end;

Entities.Spawn = function(TemplateName: Model)
	local Template = EntityTemplates:FindFirstChild(TemplateName);
	assert(TemplateName, 'Template was not found!');

	local NewEntity = Entities.new();
	NewEntity.Character.Template = Template;
	NewEntity.Character.Rig = Template : Clone();

	return NewEntity;
end;

function Entities:InitCharacter()
	local SpawnCon = self._Connections["_Respawn"]
	if SpawnCon then
		SpawnCon = nil
	end
	local Rig = self.Character.Rig;
	self.Character.Root = Rig.PrimaryPart or Rig.HumanoidRootPart
	assert(Rig, 'There is no rig');
	self._Connections["_Respawn"] = Rig.Humanoid.Died:Connect(function()
		task.wait(5);
		self.Character:Respawn();
	end);
end

function Entities:AddKill(Amount: number?)
	for i in self.Data.LeaderboardStats do
		self.Data.LeaderboardStats[i] += (Amount or 1);
	end;
	self:UpdateLeaderstats();
end;

function Entities:UpdateLeaderstats()
	self.Leaderstats['Kills'].Value = 0;
	self.Leaderstats['Join'].Value = self.Data.TimesVisited + 1;
end;

function Entities:Destroy()
	for _,v: RBXScriptConnection in self._Connections do
		v:Disconnect();
	end;

	self.ProfileHolder:Clean();
	self._Trove:Destroy();
	
	self.Character:Destroy()

	self.Valid = false;
	self.Stored[self] = nil;
end;

function Entities.Find(Inst: (Player | Model))
	local CheckingMethods = {
		Player = function(v)
			return v.Player == Inst;
		end;
		Character = function(v)
			if not v.Character then return end;
			return v.Character.Rig == Inst;
		end;
	};

	local Method = (Inst:IsA('Player') and 'Player') or (Inst:IsA('Model') and 'Character');
	local MethodFunc = CheckingMethods[Method];

	assert(MethodFunc, 'Search method not found! Did you pass an instance?');

	for v in Entities.Stored do
		local Result = MethodFunc(v);
		if Result then return v end;
	end;
end;
return Entities;