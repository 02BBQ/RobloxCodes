local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")
local ServerScriptService = game:GetService("ServerScriptService")
local HttpService = game:GetService("HttpService")
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local MessagingService = game:GetService("MessagingService")
local TweenService = game:GetService("TweenService")
local DataStoreService = game:GetService("DataStoreService")
local isStudio = RunService:IsStudio()

workspace:SetAttribute("RbxLegacyAnimationBlending", true)

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local assets = { 
	ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Animation"),
}

ContentProvider:PreloadAsync(assets)

print("All assets loaded.")


local coroutine_wrap = coroutine.wrap;
local task_delay = task.delay;
local task_spawn = task.spawn;
local math_random = math.random;
local math_max = math.max; 
local math_min = math.min;
local task_wait = task.wait;


local ServerReplicator = {};
local EffectReplicator, Replication = require(ReplicatedStorage.EffectReplicator), ReplicatedStorage.Remotes.EffectReplication
local PlayerEffects = {}
local UpdateRemote = Replication._update
local PlayerContainers = {}
local Characters = {}


local EntityManager = require(ServerScriptService.Server.Components.EntityManager)
local SoundHandler = require(ReplicatedStorage.Shared.Utility.Sound)
SoundHandler:Cache()

shared.HitboxLibrary = require(ReplicatedStorage.Shared.Hitboxes)

function shared.GetReplicator(Player)
	return PlayerEffects[Player];
end

function EffectReplicator:Destroy()
	pcall(function()
		UpdateRemote:FireClient(self.Player, {
			updateType = "clear"
		})
	end)
end

function RemoveReplicator(Player)
	local oldEffectReplicator = PlayerEffects[Player]

	if oldEffectReplicator then
		oldEffectReplicator:Destroy()
	end
end

function CreateReplicator(Player, isNPC)
	local oldEffectReplicator = PlayerEffects[Player]


	if oldEffectReplicator then
		oldEffectReplicator:Destroy()
	end

	local newPlayerContainer = {};
	local effectReplicator = EffectReplicator.new();
	effectReplicator.Player = Player;

	if not isNPC then
		effectReplicator.EffectAdded:Connect(function(effect, DebrisTime)
			task.wait();
			if (effect.Destroyed) then return end;

			if (effect.Domain == "Server") then
				UpdateRemote:FireClient(Player, {
					updateType = "update";
					sum = effectReplicator:ParseEffects()
				});

				for i,v in next, {effect, effect.TagAdded, effect.TagRemoving} do
					v:Connect(function()
						UpdateRemote:FireClient(Player, {
							updateType = "update";
							sum = {effect:ParseEffect()};
						});
					end)
				end
			end;
		end)

		effectReplicator.EffectRemoving:Connect(function(effect)
			UpdateRemote:FireClient(Player, {
				updateType = "remove";
				sum = effect.ID;
			});
		end);
	end

	PlayerEffects[Player] = effectReplicator;
	PlayerContainers[Player] = newPlayerContainer;

	if not isNPC then
		UpdateRemote:FireClient(Player, {
			updateType = "updatecontainer";
			sum = newPlayerContainer;
		});
	end
	return effectReplicator
end

local function AddItem(Item, Duration)
	task_delay(Duration, function()
		pcall(Item.Destroy, Item);
	end)
end

function InitializeCharacter(Character)
	local isPlayer = Players:GetPlayerFromCharacter(Character) or Character;
	CreateReplicator(isPlayer, not isPlayer:IsA("Player"))
	local Entity = EntityManager.Find(isPlayer)
	if not Entity then return end
	Entity:InitCharacter()
end

function OnPlayerAdded(Player : Player?)
	task.wait(isStudio and 0 or 3); --// prevents from dupe
	
	local Entity = EntityManager.new(nil, Player);
	Entity.Data.TimesVisited += 1;
	
	Player.CharacterAdded:Connect(function(Character)
		--Character = Player.Character or Player.CharacterAppearanceLoaded:Wait()
		Entity.Character.Rig = Character
		Character.Parent = workspace.Alive
	end)
	
	Player:LoadCharacter()
end

function RemovingPlayer(Player)
	if Player:GetAttribute("Loaded") then
		while not pcall(function()
				shared.SaveData(Player, nil, true);
			end) do
			task.wait(1)
		end
	end
	EntityManager.Find(Player):Destroy();
	for i,v in next, {PlayerContainers, PlayerEffects} do
		if v[Player] then
			table.clear(v[Player]);
			v[Player] = nil;
		end
	end
end

Players.PlayerAdded:Connect(OnPlayerAdded)

Players.PlayerRemoving:Connect(RemovingPlayer)

for _,v  in Players:GetPlayers() do
	if EntityManager.Find(v) then return end;
	OnPlayerAdded(v);
end;

workspace.Alive.ChildAdded:Connect(InitializeCharacter)

for _,v  in workspace.Alive:GetChildren() do
	InitializeCharacter(v)
end;

local Entity = EntityManager.Spawn("LPizza")

repeat wait() until Entity.Ready;

Entity.Character.Rig.Parent = workspace.Alive
Entity.Character.Rig:PivotTo(CFrame.new(0,0,0))