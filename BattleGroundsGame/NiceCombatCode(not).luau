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

local hitbox = require(ServerStorage.Hitboxes)
local ServerFunctions = require(ServerStorage.ServerFunctions)
local EffectReplicator = require(ReplicatedStorage.EffectReplicator);
local VoxBreaker = require(ReplicatedStorage.Modules.VoxBreaker)

local coroutine_wrap = coroutine.wrap;
local task_delay = task.delay;
local task_spawn = task.spawn;
local math_random = math.random;
local math_max = math.max;
local math_min = math.min;
local task_wait = task.wait;





local eventConnections = {}


local usingMove = Instance.new("Folder")
usingMove.Name = "UsingMove"

local function AddItem(Item, Duration)
	task_delay(Duration, function()
		pcall(Item.Destroy, Item);
	end)
end

shared.HitboxLibrary = require(ServerStorage.Hitboxes)
shared.ServerFunctions = require(ServerStorage.ServerFunctions)

shared.UsingMove = function(chr,Duration)
	local effect = shared.GetReplicator(Players:GetPlayerFromCharacter(chr) or chr):CreateEffect("UsingMove")
	effect:Debris(Duration)
	return effect
end

local combat = require(ServerStorage.Combat)
ReplicatedStorage.Remotes["NPC Combat"].Event:Connect(function(chr,state)
	combat.LMB(chr,state)
end)

ReplicatedStorage.Remotes.Dash.OnServerEvent:Connect(function(plr,chr,action)
	if plr.Character ~= chr then return end
	for i,v in pairs(Players:GetPlayers()) do
		if v ~= plr then
			if action ~= "Dash" and action ~= "SideDash" then return end
			ReplicatedStorage.Remotes.ClientEffect:FireAllClients(action,{
				Origin = chr
			})
		end
	end
end)

local Info = require(ReplicatedStorage.Info)

ReplicatedStorage.Remotes.BasicCombat.OnServerEvent:Connect(function(plr, state)
	local chr = plr.Character
	local origin = chr.HumanoidRootPart
	EffectReplicator = shared.GetReplicator(plr)
	if EffectReplicator == nil then return end
	
	if not origin or not chr.Parent then return end
	
	
	local ChrInfo = Info[chr.CharacterData.Value]
	
	
	
	local AnimFolder = ReplicatedStorage.Shared.Anims.BasicCombo
	local try = ReplicatedStorage.Shared.Anims:FindFirstChild(chr.CharacterData.Value)
	if (try) and try:FindFirstChild("Combo1") then
		AnimFolder = try
	end
	
	local Cancel = false
	local CancelConnection = false
	
	if EffectReplicator:FindEffect("UsingMove")or chr:FindFirstChild("Ragdoll") or EffectReplicator:FindEffect("Stunned") or EffectReplicator:FindEffect("Block") or ServerFunctions.addCD({
		Plr = plr;
		Ability = "LMB";
		checkCD = true;
		}) then return end
	shared.UsingMove(chr,.3)
	
	CancelConnection = EffectReplicator.EffectAdded:Connect(function(Effect)
		if Effect.Class == "Stunned" then
			Cancel = true
		end
	end)
	
	if not shared.Cache[chr] then return end
	
	local ComboTick = shared.Cache[chr]["ComboTick"]
	if tick() - ComboTick >= 1.2 and not EffectReplicator:FindEffect("KeepCombo") then
		shared.Cache[chr]["Combo"] = 1
	end
	if EffectReplicator:FindEffect("KeepCombo") and shared.Cache[chr]["DidComboEnd"] == true then
		shared.Cache[chr]["Combo"] = 4
	end
	local combo = shared.Cache[chr]["Combo"]
	
	shared.Cache[chr]["ComboTick"] = tick()
	
	
	local IsFlourish = false
	
	local duration = (combo == 3 and state ~="Space") and .45 or combo <= 3 and 0.6 or 1
	EffectReplicator:CreateEffect("LightAttack"):Debris(duration)
	
	local anim : AnimationTrack, hits
	local hitboxData = {
		--Shape = "Ball";
		Origin = origin;
		Size = Vector3.new(5.5,5.5,5.5);
		Offset = CFrame.new(0,0,-2.2)
	}
	local damageData = {
		Origin = chr;
		BlockAble = true;
		Damage = 3;
		Knockback = chr.HumanoidRootPart.CFrame.LookVector * 7;
		Stun = .7;
		Sound = ChrInfo["M1Hit"] or ReplicatedStorage.Shared.Sound.BasicCombo["panHit"..#ReplicatedStorage.Shared.Sound.BasicCombo:GetChildren()]
	}
	
	if chr:FindFirstChild"CharacterData" then
		damageData.Visual = chr.CharacterData.Value
	end
	
	local effect,effect2
	
	local Action
	 
	if combo <= 3 then 
		anim = chr.Humanoid:LoadAnimation(AnimFolder["Combo"..combo])
		damageData["Type"] = "Follow"
		shared.SFX(origin,ChrInfo["GetM1Sound"] and ChrInfo["GetM1Sound"]() or ReplicatedStorage.Shared.Sound.Combat.Bocchi["swoosh"..combo])
	else	
		damageData["Damage"] = 5
		Action = state
		if state == "Freefall" then
			shared.SFX(origin,ReplicatedStorage.Shared.Sound.Combat.Downslam)
			anim = chr.Humanoid:LoadAnimation(ReplicatedStorage.Shared.Anims.Downslam)
			hitboxData = {
				Origin = origin;
				Size = Vector3.new(7,7,6);
				Offset = CFrame.new(0,-2,-2.8)
			}
			damageData["Ragdoll"] = 2
			damageData["Type"] = "Slam"
			damageData["Sound"] = ReplicatedStorage.Shared.Sound.Downslam
			damageData["HitsRagdoll"] = true
			damageData.BlockAble = false;
			damageData.Execute = function(chr,victim)
				anim:Stop(0)
				local bp = Instance.new("BodyPosition")
				bp.D = 100
				bp.P = 1000
				bp.MaxForce = Vector3.new(0,1e6,0)
				bp.Position = origin.Position + Vector3.new(0,1.5,0)
				bp.Parent = origin
				AddItem(bp,0.5)
				
				local stun = EffectReplicator:CreateEffect("Stunned")
				local iframe = EffectReplicator:CreateEffect("IFrame")
				
				local anim : AnimationTrack = chr.Humanoid:LoadAnimation(ServerStorage.Assets.Anims.DownslamFinisher)
				anim:Play()
				
				local CraterData = {
					Origin = origin;
					Cframe = origin.CFrame;
					RayLength = -7;
					Amount = 4;
					Distance = 3.5;
					Despawn = 2;
					Stack = 2;
					Size = 1;
				}

				ReplicatedStorage.Remotes.ClientEffect:FireAllClients("SlamFinisher",CraterData)
				
				anim:GetMarkerReachedSignal("Downslam"):Connect(function()
					stun:Destroy()
					iframe:Destroy()
					
					local hits = shared.HitboxLibrary.Region3({
						Origin = origin;
						Size = Vector3.new(21,45,21);
						Offset = CFrame.new(0,0,-2)
					})
					for i,v in hits do
						ServerFunctions.Damage({
							Origin = chr;
							Victim = v;
							BlockAble = false;
							Damage = 5;
							Knockback = Vector3.new(0,51,0);
							Stun = 2;
							Ragdoll = 2;
							HitsRagdoll = true;
						})
					end
				end)
			end
		elseif state == "Space" then
			shared.SFX(origin,ReplicatedStorage.Shared.Sound.Combat.Uppercut)
			anim = chr.Humanoid:LoadAnimation(ReplicatedStorage.Shared.Anims.Uppercut)
			damageData["Ragdoll"] = 2
			damageData["Knockback"] = (chr.HumanoidRootPart.CFrame).LookVector * 3 + Vector3.new(0,45,0)
			damageData["Sound"] = {"rbxassetid://5534385248",1.5}
		else
			shared.SFX(origin,ChrInfo["GetM1Sound"] and ChrInfo["GetM1Sound"]() or ReplicatedStorage.Shared.Sound.Combat.Bocchi["swoosh"..combo])
			anim = chr.Humanoid:LoadAnimation(AnimFolder["Combo"..combo])
			damageData["Ragdoll"] = 2
			damageData.Knockback = chr.HumanoidRootPart.CFrame.LookVector * 27 + Vector3.new(0,30,0);	
		end
	end
	
	anim:Play()
	
	
	shared.Cache[chr]["Combo"] += 1
	if combo >= 4 then
		IsFlourish = true
		shared.Cache[chr]["DidComboEnd"] = true
		shared.Cache[chr]["Combo"] = 1
		ServerFunctions.addCD({
			Plr = plr;
			Ability = "LMB";
			Dura = 2;
		})
	else
		shared.Cache[chr]["DidComboEnd"] = false
	end
	
	anim:GetMarkerReachedSignal("Hit"):Wait()
	CancelConnection:Disconnect()	
	if Cancel then return end
	
	if state == "Freefall" and IsFlourish then
		local parts = VoxBreaker:CreateHitbox(Vector3.new(5,5,5),origin.CFrame * CFrame.new(0,-2,-2),Enum.PartType.Block, 4, 25)
	elseif IsFlourish then
		local parts = VoxBreaker:CreateHitbox(Vector3.new(5,5,5),origin.CFrame * CFrame.new(0,0, -2.5),Enum.PartType.Block, 4, 25)
		
		for _,part : BasePart in pairs(parts) do
			part.Anchored = false
			local bv = Instance.new("BodyVelocity")
			bv.MaxForce = Vector3.new(1e6,1e6,1e6)
			bv.P = 1200
			bv.Velocity = origin.CFrame.LookVector * 45
			bv.Parent = part
			Debris:AddItem(bv,.1)
		end
	end
	
	if IsFlourish then
		effect = EffectReplicator:CreateEffect("Endlag")
		effect:Debris(.7)
		effect2 = EffectReplicator:CreateEffect("UsingMove")
		effect2:Debris(.7)
	end
	
	hits = hitbox.Region3(hitboxData)
	for _,hit in pairs(hits) do
		damageData["Victim"] = hit
		if ServerFunctions.Damage(damageData) then
			if effect then
				effect:Destroy()
				effect2:Destroy()
			end
			if Action == "Space" then
				ReplicatedStorage.Remotes.ClientEffect:FireAllClients("Shockwave",{Origin = hit.HumanoidRootPart,Duration = 0.15,StartSize = Vector3.new(.3,7,.3),EndSize = Vector3.new(.8,0,.8),
					OffsetGoal = CFrame.new(0,6.5,0)
				})
			elseif Action == "Freefall" then
				ReplicatedStorage.Remotes.ClientEffect:FireAllClients("Shockwave",{Origin = hit.HumanoidRootPart,Duration = 0.2,StartSize = Vector3.new(.3,7,.3),EndSize = Vector3.new(.8,0,.8),
					OffsetGoal = CFrame.new(0,-.25,0);
					usePosition = true;
				})
			end
		end
	end	
end)


ReplicatedStorage.Remotes.Block.OnServerEvent:Connect(function(plr, Action)
	local chr = plr.Character
	EffectReplicator = shared.GetReplicator(plr)
	
	if Action == "Start" then
		if EffectReplicator:FindEffect("Block") or EffectReplicator:FindEffect("Stunned") or EffectReplicator:FindEffect("UsingMove") then return end
		local block = EffectReplicator:CreateEffect("Block")
	else
		if not EffectReplicator:FindEffect("Block") then return end
		pcall(function()
			local block = EffectReplicator:FindEffect("Block")
			block:Destroy()
		end)
	end
	
end)


eventConnections["Slot Interaction"] = ReplicatedStorage.Remotes.slotInteraction.OnServerEvent:Connect(function(player, Tool, Action)

	--// Variables \\--

	local Character = player.Character
	local characterStates = Character:FindFirstChild("States")

	local backpack = player:FindFirstChildOfClass("Backpack")
	local Humanoid = Character:FindFirstChildOfClass("Humanoid")

	--// Getting action \\--

	if Action == "Equip" and Tool then
		if Tool.Parent ~= nil and Tool.Parent == backpack then

			Tool.Parent = Character

		end
	elseif Action == "Unequip" and Tool then
		if Tool.Parent ~= nil and Tool.Parent == Character then

			Tool.Parent = backpack

		end
	elseif Action == "Activate" and Tool then
		 --if Tool.Parent ~= nil and Tool.Enabled == true and not characterStates:FindFirstChild("Stunned") and not characterStates:FindFirstChild("Ragdolled") and Humanoid.Health > 0 and not characterStates:FindFirstChild("Using Skill") then

			if Tool.Parent == backpack then
				Tool.Parent = Character
				Tool:Activate()
				Tool.Parent = backpack			
			else
				Tool:Activate()
			end

		--end
	end

end)
