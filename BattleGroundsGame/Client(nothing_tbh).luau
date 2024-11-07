local plr = game.Players.LocalPlayer
local chr = plr.Character
local cam = workspace.Camera

repeat task.wait() until game:IsLoaded()

local playerInputService = game:GetService"UserInputService"
local mouse = game.Players.LocalPlayer:GetMouse()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local repFirst = game:GetService("ReplicatedFirst")
local HumRP = chr:WaitForChild("HumanoidRootPart")

local human : Humanoid = chr.Humanoid

human:SetStateEnabled(Enum.HumanoidStateType.FallingDown,false)
human:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,false)
