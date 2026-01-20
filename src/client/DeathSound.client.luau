local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local deathFolder = SoundService:WaitForChild("Death")
local event = ReplicatedStorage:WaitForChild("PlayDeathSound")

-- 랜덤 사망 사운드 재생 함수
local function playRandomDeathSound()
	local deathSounds = {}

	for _, sound in pairs(deathFolder:GetChildren()) do
		if sound:IsA("Sound") then
			table.insert(deathSounds, sound)
		end
	end

	if #deathSounds == 0 then
		warn("Death 폴더에 사운드가 없습니다!")
		return
	end

	local selectedSound = deathSounds[math.random(#deathSounds)]
	selectedSound:Play()

	print("사망 사운드 재생:", selectedSound.Name)
end

-- 서버에서 이벤트 오면 재생
event.OnClientEvent:Connect(function(soundName)
	local sound = deathFolder:FindFirstChild(soundName)
	if sound then
		sound:Play()
	end
end)
