local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 필수 오브젝트 대기
local InRound = ReplicatedStorage:WaitForChild("InRound")
local endFolder = SoundService:WaitForChild("END")

-- 승자 정보를 담을 값
local Winner = ReplicatedStorage:WaitForChild("Winner") -- "Player" 또는 "Killer"

-- 사운드 재생 함수
local function playEndSound(winner)
	local soundToPlay

	if winner == "Player" then
		soundToPlay = endFolder:FindFirstChild("PlayerWin")
	elseif winner == "Killer" then
		soundToPlay = endFolder:FindFirstChild("KillerWin")
	end

	if soundToPlay and soundToPlay:IsA("Sound") then
		-- 소리가 겹치지 않게 중지 후 다시 재생
		soundToPlay:Stop()
		soundToPlay:Play()
		print("라운드 종료 사운드 재생됨: " .. soundToPlay.Name)
	else
		warn("해당 승리 사운드를 찾을 수 없습니다: " .. tostring(winner))
	end
end

-- InRound 값이 바뀔 때 실행될 함수
local function onRoundChanged()
	-- true(시작)에서 false(종료)로 바뀔 때만 소리 재생
	if InRound.Value == false then
		playEndSound(Winner.Value)
	end
end

-- 이벤트 연결
InRound.Changed:Connect(onRoundChanged)
