local intermission = 5
local roundLength = 30

local inRound = game.ReplicatedStorage.InRound
local status = game.ReplicatedStorage.Status
local soundService = game:GetService("SoundService")

-- 현재 재생 중인 음악 추적
local currentMusic = nil

-- GameManager의 함수들이 로드될 때까지 대기
task.wait(0.1)

-- MapSpawn 목록 가져오기 함수
local function getMapSpawns()
	local mapSpawns = {}

	-- 방법 1: "MapSpawn"으로 시작하는 모든 파트 찾기 (workspace 최상위)
	for _, obj in pairs(workspace:GetChildren()) do
		if obj:IsA("BasePart") and obj.Name:match("^MapSpawn") then
			table.insert(mapSpawns, obj)
		end
	end

	-- 방법 2: GameObjects 폴더 안에서 "MapSpawn"으로 시작하는 파트만 찾기
	local gameObjectsFolder = workspace:FindFirstChild("GameObjects")
	if gameObjectsFolder then
		for _, obj in pairs(gameObjectsFolder:GetChildren()) do
			if obj:IsA("BasePart") and obj.Name:match("^MapSpawn") then
				table.insert(mapSpawns, obj)
			end
		end
	end

	return mapSpawns
end

-- 랜덤 MapSpawn 선택 함수
local function getRandomMapSpawn()
	local mapSpawns = getMapSpawns()

	if #mapSpawns == 0 then
		warn("MapSpawn을 찾을 수 없습니다. 기본 MapSpawn을 사용합니다.")
		local defaultSpawn = workspace:FindFirstChild("MapSpawn")
		if defaultSpawn and defaultSpawn:IsA("BasePart") then
			return defaultSpawn
		end
		return nil
	end

	-- 랜덤하게 하나 선택
	local randomIndex = math.random(1, #mapSpawns)
	return mapSpawns[randomIndex]
end

-- 플레이어를 MapSpawn으로 텔레포트하는 함수
local function teleportPlayersToMapSpawn()
	local randomMapSpawn = getRandomMapSpawn()

	if randomMapSpawn then
		for i, plr in pairs(game.Players:GetChildren()) do
			local char = plr.Character
			if char then
				local humanRoot = char:WaitForChild("HumanoidRootPart")
				humanRoot.CFrame = randomMapSpawn.CFrame
			end
		end
	else
		warn("MapSpawn을 찾을 수 없어 플레이어를 텔레포트할 수 없습니다.")
	end
end

-- StartGameWall 제거 함수
local function removeStartGameWall()
	local gameObjects = workspace:WaitForChild("GameObjects")
	local startGameWall = gameObjects:WaitForChild("StartGameWall")
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

-- 현재 음악 정지 함수
local function stopCurrentMusic()
	if currentMusic and currentMusic.IsPlaying then
		currentMusic:Stop()
	end
	currentMusic = nil
end

-- 로비 음악 재생 함수
local function playLobbyMusic()
	stopCurrentMusic()

	local lobbyMusicFolder = soundService:FindFirstChild("LobbyMusic")
	if not lobbyMusicFolder then
		warn("SoundService에서 LobbyMusic 폴더를 찾을 수 없습니다.")
		return
	end

	local musicTracks = {}
	for _, sound in pairs(lobbyMusicFolder:GetChildren()) do
		if sound:IsA("Sound") then
			table.insert(musicTracks, sound)
		end
	end

	if #musicTracks == 0 then
		warn("LobbyMusic 폴더에 음악이 없습니다.")
		return
	end

	-- 랜덤으로 하나 선택하여 재생
	local randomIndex = math.random(1, #musicTracks)
	currentMusic = musicTracks[randomIndex]
	currentMusic:Play()
	print("로비 음악 재생: " .. currentMusic.Name)
end

-- 게임 음악 재생 함수
local function playGameMusic()
	stopCurrentMusic()

	local gameMusicFolder = soundService:FindFirstChild("GameMusic")
	if not gameMusicFolder then
		warn("SoundService에서 GameMusic 폴더를 찾을 수 없습니다.")
		return
	end

	local musicTracks = {}
	for _, sound in pairs(gameMusicFolder:GetChildren()) do
		if sound:IsA("Sound") then
			table.insert(musicTracks, sound)
		end
	end

	if #musicTracks == 0 then
		warn("GameMusic 폴더에 음악이 없습니다.")
		return
	end

	-- 랜덤으로 하나 선택하여 재생
	local randomIndex = math.random(1, #musicTracks)
	currentMusic = musicTracks[randomIndex]
	currentMusic:Play()
	print("게임 음악 재생: " .. currentMusic.Name)
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

		-- 로비 음악 재생
		playLobbyMusic()
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
		teleportPlayersToMapSpawn()

		-- 텔레포트 직후 게임 음악 재생
		playGameMusic()

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

		-- 그 다음 inRound를 true로 설정
		inRound.Value = true

		-- inRound가 true가 되면 공 생성
		if _G.createBall then
			_G.createBall()
		end

		for i = roundLength, 0, -1 do
			status.Value = "Game will end in " .. i .. " seconds"
			task.wait(1)
		end
	end
end

-- 게임 시작 시 로비 음악 재생
playLobbyMusic()

task.spawn(round)
