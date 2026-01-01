local intermission = 5
local roundLength = 120

local SoundService = game:GetService("SoundService")
local inRound = game.ReplicatedStorage.InRound
local status = game.ReplicatedStorage.Status

-- GameManager의 함수들이 로드될 때까지 대기
task.wait(0.1)

-- SoundService에서 모든 Sound 찾기 함수
local function getAllSounds()
	local sounds = {}

	for _, obj in pairs(SoundService:GetChildren()) do
		if obj:IsA("Sound") then
			table.insert(sounds, obj)
		end
	end

	return sounds
end

-- 현재 재생 중인 Sound
local currentSound = nil

-- 랜덤 오디오 재생 함수
local function playRandomAudio()
	local sounds = getAllSounds()

	if #sounds == 0 then
		warn("SoundService에서 오디오를 찾을 수 없습니다.")
		return
	end

	-- 기존에 재생 중인 오디오 정지
	if currentSound and currentSound.IsPlaying then
		currentSound:Stop()
	end

	-- 랜덤으로 하나 선택하여 재생
	local randomIndex = math.random(1, #sounds)
	currentSound = sounds[randomIndex]

	-- 노래가 끝나면 다음 노래 재생
	currentSound.Ended:Connect(function()
		if inRound.Value then
			playRandomAudio()
		end
	end)

	currentSound:Play()
	print("오디오 재생: " .. currentSound.Name)
end

-- 오디오 정지 함수
local function stopAudio()
	if currentSound and currentSound.IsPlaying then
		currentSound:Stop()
		currentSound = nil
	end
end

-- StartGameWall 제거 함수
local function removeStartGameWall()
	local startGameWall = workspace:FindFirstChild("StartGameWall")
	if startGameWall then
		startGameWall:Destroy()
		print("StartGameWall이 제거되었습니다.")
	else
		-- StartGameWall 폴더나 모델일 수도 있음
		local startGameWallFolder = workspace:FindFirstChild("StartGameWall")
		if startGameWallFolder then
			startGameWallFolder:Destroy()
			print("StartGameWall 폴더/모델이 제거되었습니다.")
		end
	end
end

inRound.Changed:Connect(function()
	if inRound.Value == false then
		-- 라운드가 끝나면 로비로 텔레포트
		for i, plr in pairs(game.Players:GetChildren()) do
			local char = plr.Character
			if char then
				local humanRoot = char:WaitForChild("HumanoidRootPart")
				humanRoot.CFrame = game.Workspace.LobbySpawn.CFrame
			end
		end
		-- 오디오 정지
		stopAudio()
	elseif inRound.Value == true then
		-- inRound가 true가 되면 공 생성
		if _G.createBall then
			_G.createBall()
		end
		-- 게임 시작 시 랜덤 오디오 재생
		playRandomAudio()
	end
end)

local function round()
	while true do
		inRound.Value = false

		for i = intermission, 0, -1 do
			status.Value = "Game will start in " .. i .. " seconds"
			task.wait(1)
		end

		-- intermission이 끝나면 먼저 MapSpawn으로 텔레포트
		status.Value = "Teleporting to map..."
		for i, plr in pairs(game.Players:GetChildren()) do
			local char = plr.Character
			if char then
				local humanRoot = char:WaitForChild("HumanoidRootPart")
				humanRoot.CFrame = game.Workspace.MapSpawn.CFrame
			end
		end

		-- 텔레포트 후 블럭 생성
		if _G.createBricks then
			_G.createBricks()
		end

		-- 5초 대기
		for i = 5, 0, -1 do
			status.Value = "Game starting in " .. i .. " seconds"
			task.wait(1)
		end

		-- StartGameWall 제거
		removeStartGameWall()

		-- 그 다음 inRound를 true로 설정 (공은 inRound.Changed에서 생성됨)
		inRound.Value = true

		for i = roundLength, 0, -1 do
			status.Value = "Game will end in " .. i .. " seconds"
			task.wait(1)
		end
	end
end

task.spawn(round)
