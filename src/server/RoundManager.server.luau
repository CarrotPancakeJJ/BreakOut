local intermission = 10
local roundLength = 30

local inRound = game.ReplicatedStorage.InRound
local status = game.ReplicatedStorage.Status
local soundService = game:GetService("SoundService")
local Players = game:GetService("Players")

-- 현재 재생 중인 음악 추적
local currentMusic = nil

-- GameManager의 함수들이 로드될 때까지 대기
task.wait(0.1)

-- MapSpawn 목록 가져오기 함수
local function getMapSpawns()
	local mapSpawns = {}

	-- 방법 1: "MapSpawn"으로 시작하는 모든 파트 찾기
	for _, obj in pairs(workspace:GetChildren()) do
		if obj:IsA("BasePart") and obj.Name:match("^MapSpawn") then
			table.insert(mapSpawns, obj)
		end
	end

	-- 방법 2: GameObjects 폴더 안에서 "MapSpawn"으로 시작하는 파트만 찾기
	local gameObjectsFolder = workspace:FindFirstChild("GameObjects")
	local mapSpawnsFolder = gameObjectsFolder:FindFirstChild("MapSpawns")
	if mapSpawnsFolder then
		for _, obj in pairs(mapSpawnsFolder:GetChildren()) do
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

-- LobbySpawn 목록 가져오기 함수
local function getLobbySpawns()
	local lobbySpawns = {}

	-- 방법 1: "LobbySpawn"으로 시작하는 모든 파트 찾기
	for _, obj in pairs(workspace:GetChildren()) do
		if obj:IsA("BasePart") and obj.Name:match("^LobbySpawn") then
			table.insert(lobbySpawns, obj)
		end
	end

	-- 방법 2: GameObjects 폴더 안에서 "LobbySpawn"으로 시작하는 파트만 찾기
	local lobbyObjectsFolder = workspace:FindFirstChild("LobbyObjects")
	local lobbySpawnsFolder = lobbyObjectsFolder:FindFirstChild("LobbySpawns")
	if lobbySpawnsFolder then
		for _, obj in pairs(lobbySpawnsFolder:GetChildren()) do
			if obj:IsA("BasePart") and obj.Name:match("^LobbySpawn") then
				table.insert(lobbySpawns, obj)
			end
		end
	end

	return lobbySpawns
end

-- 랜덤 LobbySpawn 선택 함수
local function getRandomLobbySpawn()
	local lobbySpawns = getLobbySpawns()

	if #lobbySpawns == 0 then
		warn("LobbySpawn을 찾을 수 없습니다. 기본 LobbySpawn을 사용합니다.")
		local defaultSpawn = workspace:FindFirstChild("LobbySpawn")
		if defaultSpawn and defaultSpawn:IsA("BasePart") then
			return defaultSpawn
		end
		return nil
	end

	-- 랜덤하게 하나 선택
	local randomIndex = math.random(1, #lobbySpawns)
	return lobbySpawns[randomIndex]
end

-- 플레이어를 MapSpawn으로 텔레포트하는 함수
local function teleportPlayersToMapSpawn()
	for i, plr in pairs(game.Players:GetChildren()) do
		local randomMapSpawn = getRandomMapSpawn() -- 각 플레이어마다 랜덤
		local char = plr.Character
		if char then
			local humanRoot = char:WaitForChild("HumanoidRootPart")
			humanRoot.CFrame = randomMapSpawn.CFrame
		end
	end
end

-- StartGameWall 제거 함수
local function removeStartGameWall()
	local gameObjectsFolder = workspace:FindFirstChild("GameObjects")
	local startGameWall = gameObjectsFolder:WaitForChild("StartGameWall")
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
		local Teams = game:GetService("Teams")
		local lobbyTeam = Teams:FindFirstChild("Lobby")

		-- 라운드가 끝나면 로비로 텔레포트 + Lobby 팀으로 변경
		for i, plr in pairs(game.Players:GetChildren()) do
			local randomLobbySpawn = getRandomLobbySpawn()
			local char = plr.Character
			if char then
				local humanRoot = char:WaitForChild("HumanoidRootPart")
				humanRoot.CFrame = randomLobbySpawn.CFrame
			end

			-- Lobby 팀으로 리셋
			if lobbyTeam then
				plr.Team = lobbyTeam
				plr.TeamColor = lobbyTeam.TeamColor
			end
		end

		-- 로비 음악 재생
		playLobbyMusic()
	end
end)

local function round()
	while true do
		inRound.Value = false

		repeat
			for i = intermission, 0, -1 do
				local playerCount = #Players:GetPlayers()
				status.Value = "Game will start in "
					.. i
					.. " seconds\nMinimum 2 players to start!\nPlayers: "
					.. playerCount
					.. "/15: "
				task.wait(1)
			end

			-- 플레이어 수 확인
			local playerCount = #Players:GetPlayers()
			if playerCount < 2 then
				status.Value = "Not enough players! Waiting...\nPlayers: " .. playerCount .. "/15"
				task.wait(2)
			end
		until #Players:GetPlayers() >= 2

		-- intermission이 끝나면 팀 배정
		status.Value = "Selecting Killer..."
		if _G.pickRandomPlayer then
			_G.pickRandomPlayer()
		end
		task.wait(2) -- 팀 배정 후 잠깐 대기

		-- 그 다음 MapSpawn으로 텔레포트
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
		inRound.Value = false
	end
end

-- 게임 시작 시 로비 음악 재생
playLobbyMusic()

task.spawn(round)
