local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local event = ReplicatedStorage:WaitForChild("PlayDeathSound")
local deathFolder = SoundService:WaitForChild("Death")

local function getRandomSoundName()
	local sounds = {}

	for _, sound in pairs(deathFolder:GetChildren()) do
		if sound:IsA("Sound") then
			table.insert(sounds, sound.Name)
		end
	end

	if #sounds == 0 then
		return nil
	end

	return sounds[math.random(#sounds)]
end

local function connectCharacter(character)
	local humanoid = character:WaitForChild("Humanoid")

	humanoid.Died:Connect(function()
		local soundName = getRandomSoundName()
		if soundName then
			event:FireAllClients(soundName)
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(connectCharacter)
end)
