local intermission = 30
local roundLength = 100

local InRound = game.ReplicatedStorage.InRound
local status = game.ReplicatedStorage.Status
local IsRestrictMovement = game.ReplicatedStorage.IsRestrictMovement -- 추가
local soundService = game:GetService("SoundService")
local Players = game:GetService("Players")

local gameObjects = workspace:FindFirstChild("GameObjects")
local cameraPart = gameObjects and gameObjects:FindFirstChild("CameraPart")

local Teams = game:GetService("Teams")
local gameEnded = false

-- 현재 재생 중인 음악 추적
local currentMusic = nil
local musicConnection = nil

-- GameManager의 함수들이 로드될 때까지 대기
task.wait(0.1)

-- 게임 시작 시 startGameWall 원본저장
local originalStartGameWall = nil
local gameObjectsFolder = workspace:FindFirstChild("GameObjects")
if gameObjectsFolder then
	originalStartGameWall = gameObjectsFolder:FindFirstChild("StartGameWall")
	if originalStartGameWall then
		originalStartGameWall = originalStartGameWall:Clone() -- 복사본 저장
	end
end

-- StartGameWall 생성 함수
local function createStartGameWall()
	if not originalStartGameWall then
		warn("원본 StartGameWall이 없습니다!")
		return
	end

	local gameObjectsFolder = workspace:FindFirstChild("GameObjects")
	if gameObjectsFolder then
		-- 기존 벽 제거
		local existingWall = gameObjectsFolder:FindFirstChild("StartGameWall")
		if existingWall then
			existingWall:Destroy()
		end

		-- 새 벽 생성
		local newWall = originalStartGameWall:Clone()
		newWall.Parent = gameObjectsFolder
		print("StartGameWall이 생성되었습니다.")
	end
end

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
	-- 1. 기존에 연결된 "다음 곡 재생 예약"이 있다면 해제
	if musicConnection then
		musicConnection:Disconnect()
		musicConnection = nil
	end

	-- 2. 현재 음악 정지
	if currentMusic then
		currentMusic:Stop()
		currentMusic = nil
	end
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

	-- 노래가 끝나면 다시 이 함수를 실행해서 무한 반복
	musicConnection = currentMusic.Ended:Connect(function()
		playLobbyMusic()
	end)
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

	-- 노래가 끝나면 다시 이 함수를 실행해서 무한 반복
	musicConnection = currentMusic.Ended:Connect(function()
		playGameMusic()
	end)
	print("게임 음악 재생: " .. currentMusic.Name)
end

-- 플레이어를 투명하게 만드는 함수
local function makePlayerInvisible(character)
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Transparency = 1
		else
			-- Decal, Texture 등 다른 것들
			pcall(function()
				if part.Transparency then
					part.Transparency = 1
				end
			end)
		end
	end
	print(character.Name .. " 투명화 완료")
end

-- 플레이어를 보이게 만드는 함수
local function makePlayerVisible(character)
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			if part.Name == "HumanoidRootPart" then
				part.Transparency = 1
			else
				part.Transparency = 0
			end
		else
			-- Decal, Texture 등 다른 것들
			pcall(function()
				if part.Transparency then
					part.Transparency = 0
				end
			end)
		end
	end
	print(character.Name .. " 가시화 완료")
end

-- 살아있는 Player 팀원 수 확인
local function getAlivePlayers()
	local playerTeam = Teams:FindFirstChild("Player")
	local alivePlayers = {}

	for _, player in pairs(Players:GetPlayers()) do
		if player.Team == playerTeam then
			local character = player.Character
			if character then
				local humanoid = character:FindFirstChild("Humanoid")
				if humanoid and humanoid.Health > 0 then
					table.insert(alivePlayers, player)
				end
			end
		end
	end

	return alivePlayers
end

-- 팀 승리 처리
local function handleVictory(winningTeam)
	gameEnded = true
	InRound.Value = false
	IsRestrictMovement.Value = false

	local teamName = winningTeam.Name

	-- 승리 메시지 표시
	if teamName == "Killer" then
		status.Value = "🔪 KILLER WINS! 🔪"

		-- Killer 팀 플레이어들의 Killer Wins 증가
		for _, player in pairs(Players:GetPlayers()) do
			if player.Team == winningTeam then
				local leaderstats = player:FindFirstChild("leaderstats")
				if leaderstats then
					local killerWins = leaderstats:FindFirstChild("Killer Wins")
					if killerWins then
						killerWins.Value = killerWins.Value + 1
					end
				end
			end
		end
	else -- Player 팀 승리
		status.Value = "🎉 PLAYERS WIN! 🎉"

		-- Player 팀 플레이어들의 Player Wins 증가
		for _, player in pairs(Players:GetPlayers()) do
			if player.Team == winningTeam then
				local leaderstats = player:FindFirstChild("leaderstats")
				if leaderstats then
					local playerWins = leaderstats:FindFirstChild("Player Wins")
					if playerWins then
						playerWins.Value = playerWins.Value + 1
					end
				end
			end
		end
	end

	print(teamName .. " 팀 승리!")

	-- 5초 대기
	task.wait(5)

	-- 로비로 이동
	local lobbyTeam = Teams:FindFirstChild("Lobby")
	for _, plr in pairs(Players:GetPlayers()) do
		local randomLobbySpawn = getRandomLobbySpawn()
		local char = plr.Character
		if char then
			local humanRoot = char:FindFirstChild("HumanoidRootPart")
			if humanRoot then
				humanRoot.CFrame = randomLobbySpawn.CFrame
				humanRoot.Anchored = false
			end

			-- 다시 보이게 만들기
			makePlayerVisible(char)
		end

		-- Lobby 팀으로 변경
		if lobbyTeam then
			plr.Team = lobbyTeam
			plr.TeamColor = lobbyTeam.TeamColor
		end
	end

	-- 로비 음악 재생
	playLobbyMusic()
end

InRound.Changed:Connect(function()
	-- 게임이 종료되면 공과 벽돌 삭제
	if InRound.Value == false then
		if _G.cleanupGame then
			_G.cleanupGame()
		end
	end
	if InRound.Value == false and not gameEnded then
		-- 팀들
		local Teams = game:GetService("Teams")
		local lobbyTeam = Teams:FindFirstChild("Lobby")

		-- 이동 제한 해제
		IsRestrictMovement.Value = false

		-- 라운드가 끝나면 로비로 텔레포트 + Lobby 팀으로 변경
		for i, plr in pairs(game.Players:GetChildren()) do
			local randomLobbySpawn = getRandomLobbySpawn()
			local char = plr.Character
			if char then
				local humanRoot = char:WaitForChild("HumanoidRootPart")
				humanRoot.CFrame = randomLobbySpawn.CFrame

				-- Anchored 해제
				humanRoot.Anchored = false

				-- 다시 보이게 만들기
				makePlayerVisible(char)
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

-- 플레이어를 각 팀에 맞게 텔레포트하는 함수
local function teleportPlayersByTeam()
	local Teams = game:GetService("Teams")
	local killerTeam = Teams:FindFirstChild("Killer")
	local playerTeam = Teams:FindFirstChild("Player")

	if not cameraPart then
		warn("CameraPart를 찾을 수 없습니다!")
	end

	-- 랜덤 MapSpawn 선택
	local randomMapSpawn = getRandomMapSpawn()

	for _, plr in pairs(game.Players:GetPlayers()) do
		local char = plr.Character
		if char then
			local humanRoot = char:FindFirstChild("HumanoidRootPart")
			if humanRoot then
				if plr.Team == killerTeam and cameraPart then
					-- Killer는 CameraPart 위치로
					humanRoot.CFrame = cameraPart.CFrame

					-- 즉시 고정
					humanRoot.Anchored = true

					-- 투명하게 만들기
					makePlayerInvisible(char)

					print(plr.Name .. " (Killer) - CameraPart로 텔레포트, 고정 및 투명화")
				elseif plr.Team == playerTeam and randomMapSpawn then
					-- Player는 MapSpawn 위치로
					humanRoot.CFrame = randomMapSpawn.CFrame

					-- Player는 고정하지 않음
					humanRoot.Anchored = false

					-- Player는 보이게 (혹시 몰라서)
					makePlayerVisible(char)

					print(plr.Name .. " (Player) - MapSpawn으로 텔레포트")
				end
			end
		end
	end
end

local function round()
	while true do
		InRound.Value = false
		IsRestrictMovement.Value = false -- 추가
		gameEnded = false

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
		local selectedPlayer, plrIcon
		if _G.pickRandomPlayer then
			selectedPlayer, plrIcon = _G.pickRandomPlayer() -- 반환값 받기
		end

		if selectedPlayer then
			status.Value = "Killer is: " .. selectedPlayer.Name .. "!"
		else
			status.Value = "Killer selected!"
		end
		task.wait(2)

		-- 그 다음 MapSpawn으로 텔레포트
		status.Value = "Teleporting to map..."
		teleportPlayersByTeam()

		-- 텔레포트 직후 이동 제한 시작! (중요)
		IsRestrictMovement.Value = true

		-- 텔레포트 직후 게임 음악 재생
		playGameMusic()

		-- 텔레포트 후 블럭 생성
		if _G.createBricks then
			_G.createBricks()
		end

		-- StartGameWall 생성
		createStartGameWall()

		-- 5초 대기
		for i = 5, 0, -1 do
			status.Value = "Game starting in " .. i .. " seconds"
			task.wait(1)
		end

		-- StartGameWall 제거
		removeStartGameWall()

		-- 그 다음 InRound를 true로 설정
		InRound.Value = true

		-- InRound가 true가 되면 공 생성
		if _G.createBall then
			_G.createBall()
		end

		-- 게임 진행 (승패 조건 체크)
		local killerTeam = Teams:FindFirstChild("Killer")
		local playerTeam = Teams:FindFirstChild("Player")

		for i = roundLength, 0, -1 do
			if gameEnded then
				break
			end

			-- 생존자 체크
			local alivePlayers = getAlivePlayers()

			if #alivePlayers == 0 then
				-- 모든 Player가 죽음 → Killer 승리
				status.Value = "All players eliminated!"
				task.wait(2)
				handleVictory(killerTeam)
				break
			end

			status.Value = "Time remaining: " .. i .. "s | Survivors: " .. #alivePlayers
			task.wait(1)
		end

		-- 시간 초과 → Player 승리
		if not gameEnded then
			local alivePlayers = getAlivePlayers()
			if #alivePlayers > 0 then
				status.Value = "Time's up! Players survived!"
				task.wait(2)
				handleVictory(playerTeam)
			end
		end

		task.wait(3) -- 다음 라운드 전 대기
	end
end

-- 게임 시작 시 로비 음악 재생
playLobbyMusic()

task.spawn(round)
