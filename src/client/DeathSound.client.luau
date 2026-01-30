local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local deathFolder = SoundService:WaitForChild("Death")
local event = ReplicatedStorage:WaitForChild("PlayDeathSound")

-- 서버에서 이벤트 오면 재생
event.OnClientEvent:Connect(function(soundName)
	local sound = deathFolder:FindFirstChild(soundName)
	if sound then
		sound:Play()
	end
end)
