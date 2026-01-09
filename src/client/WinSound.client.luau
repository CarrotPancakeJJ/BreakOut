local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 필수 오브젝트 대기
local InRound = ReplicatedStorage:WaitForChild("InRound")
local endFolder = SoundService:WaitForChild("END") -- SoundService 내의 END 폴더

-- 사운드 재생 함수
local function playEndSound()
	-- 폴더 내에 있는 'Sound' 타입의 오브젝트를 아무거나 하나 찾음
	local victorySound = endFolder:FindFirstChildWhichIsA("Sound")

	if victorySound then
		-- 소리가 겹치지 않게 중지 후 다시 재생
		victorySound:Stop()
		victorySound:Play()
		print("라운드 종료 사운드 재생됨: " .. victorySound.Name)
	else
		warn("SoundService > END 폴더 안에 사운드 오브젝트가 없습니다!")
	end
end

-- InRound 값이 바뀔 때 실행될 함수
local function onRoundChanged()
	-- true(시작)에서 false(종료)로 바뀔 때만 소리 재생
	if InRound.Value == false then
		playEndSound()
	end
end

-- 이벤트 연결
InRound.Changed:Connect(onRoundChanged)

-- 초기 실행 (게임에 중간에 들어왔을 때를 대비)
if InRound.Value == false then
	-- 게임 접속 시 바로 소리가 나는 것을 방지하려면 이 부분은 비워두셔도 됩니다.
end
