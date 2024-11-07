local manager = require(script:WaitForChild("Manager"))
local configs = require(script:WaitForChild("Configuration"))
local soundsFolder = manager:CreateSoundsFolder(game:GetService("SoundService"))
local humanoid = script.Parent:WaitForChild("Humanoid")
local soundEvent = game:GetService("ReplicatedStorage"):WaitForChild("PlayFootstepSound")
while true do
	if humanoid.MoveDirection.Magnitude > 0 and humanoid.WalkSpeed ~= 0 then
		local material = string.lower(tostring(humanoid.FloorMaterial))
		local bits = string.split(material, ".")
		material = bits[3]
		local id, vol = manager:GetRandomSound({tostring(material), soundsFolder})
		soundEvent:FireServer(id)
		task.wait(configs.Factor / humanoid.WalkSpeed)
	else
		task.wait()
	end
end