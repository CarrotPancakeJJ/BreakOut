local intermission = 15
local roundLength = 110

local InRound = game.ReplicatedStorage.InRound
local status = game.ReplicatedStorage.Status
local IsRestrictMovement = game.ReplicatedStorage.IsRestrictMovement
local soundService = game:GetService("SoundService")
local Players = game:GetService("Players")

local gameObjects = workspace:FindFirstChild("GameObjects")
local cameraPart = gameObjects and gameObjects:FindFirstChild("CameraPart")

local Teams = game:GetService("Teams")
local gameEnded = false

local Winner = game.ReplicatedStorage:WaitForChild("Winner")

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
		originalStartGameWall = originalStartGameWall:Clone()
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
		local existingWall = gameObjectsFolder:FindFirstChild("StartGameWall")
		if existingWall then
			existingWall:Destroy()
		end

		local newWall = originalStartGameWall:Clone()
		newWall.Parent = gameObjectsFolder
		print("StartGameWall이 생성되었습니다.")
	end
end

-- MapSpawn 목록 가져오기 함수
local function getMapSpawns()
	local mapSpawns = {}

	for _, obj in pairs(workspace:GetChildren()) do
		if obj:IsA("BasePart") and obj.Name:match("^MapSpawn") then
			table.insert(mapSpawns, obj)
		end
	end

	local gameObjectsFolder = workspace:FindFirstChild("GameObjects")
	local mapSpawnsFolder = gameObjectsFolder and gameObjectsFolder:FindFirstChild("MapSpawns")
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

	local randomIndex = math.random(1, #mapSpawns)
	return mapSpawns[randomIndex]
end

-- LobbySpawn 목록 가져오기 함수
local function getLobbySpawns()
	local lobbySpawns = {}

	for _, obj in pairs(workspace:GetChildren()) do
		if obj:IsA("BasePart") and obj.Name:match("^LobbySpawn") then
			table.insert(lobbySpawns, obj)
		end
	end

	local lobbyObjectsFolder = workspace:FindFirstChild("LobbyObjects")
	local lobbySpawnsFolder = lobbyObjectsFolder and lobbyObjectsFolder:FindFirstChild("LobbySpawns")
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

	local randomIndex = math.random(1, #lobbySpawns)
	return lobbySpawns[randomIndex]
end

-- StartGameWall 제거 함수
local function removeStartGameWall()
	local gameObjectsFolder = workspace:FindFirstChild("GameObjects")
	local startGameWall = gameObjectsFolder and gameObjectsFolder:WaitForChild("StartGameWall")
	if startGameWall then
		startGameWall:Destroy()
		print("StartGameWall이 제거되었습니다.")
	else
		local startGameWallFolder = workspace:FindFirstChild("StartGameWall")
		if startGameWallFolder then
			startGameWallFolder:Destroy()
			print("StartGameWall 폴더/모델이 제거되었습니다.")
		end
	end
end

-- 현재 음악 정지 함수
local function stopCurrentMusic()
	if musicConnection then
		musicConnection:Disconnect()
		musicConnection = nil
	end

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

	local randomIndex = math.random(1, #musicTracks)
	currentMusic = musicTracks[randomIndex]
	currentMusic:Play()

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

	local randomIndex = math.random(1, #musicTracks)
	currentMusic = musicTracks[randomIndex]
	currentMusic:Play()

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

	if teamName == "Killer" then
		Winner.Value = "Killer"
	else
		Winner.Value = "Player"
	end

	if teamName == "Killer" then
		status.Value = "🔪 KILLER WINS! 🔪"

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
	else
		status.Value = "🎉 PLAYERS WIN! 🎉"

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

	task.wait(5)

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

			makePlayerVisible(char)
		end

		if lobbyTeam then
			plr.Team = lobbyTeam
			plr.TeamColor = lobbyTeam.TeamColor
		end
	end

	Winner.Value = "None"
	playLobbyMusic()
end

InRound.Changed:Connect(function()
	if InRound.Value == false then
		if _G.cleanupGame then
			_G.cleanupGame()
		end
	end

	if gameEnded then
		if _G.resetKillerSelection then
			_G.resetKillerSelection()
		end
	end

	if InRound.Value == false and not gameEnded then
		local Teams = game:GetService("Teams")
		local lobbyTeam = Teams:FindFirstChild("Lobby")

		IsRestrictMovement.Value = false

		for i, plr in pairs(game.Players:GetChildren()) do
			local randomLobbySpawn = getRandomLobbySpawn()
			local char = plr.Character
			if char then
				local humanRoot = char:WaitForChild("HumanoidRootPart")
				humanRoot.CFrame = randomLobbySpawn.CFrame
				humanRoot.Anchored = false
				makePlayerVisible(char)
			end

			if lobbyTeam then
				plr.Team = lobbyTeam
				plr.TeamColor = lobbyTeam.TeamColor
			end
		end

		playLobbyMusic()
	end
end)

-- 팀에 맞게 텔레포트
local function teleportPlayersByTeam()
	local Teams = game:GetService("Teams")
	local killerTeam = Teams:FindFirstChild("Killer")
	local playerTeam = Teams:FindFirstChild("Player")

	if not cameraPart then
		warn("CameraPart를 찾을 수 없습니다!")
	end

	for _, plr in pairs(game.Players:GetPlayers()) do
		local char = plr.Character
		if char then
			local humanRoot = char:FindFirstChild("HumanoidRootPart")
			if humanRoot then
				if plr.Team == killerTeam and cameraPart then
					humanRoot.CFrame = cameraPart.CFrame
					humanRoot.Anchored = true
					makePlayerInvisible(char)
					print(plr.Name .. " (Killer) - CameraPart로 텔레포트")
				elseif plr.Team == playerTeam then
					local randomMapSpawn = getRandomMapSpawn()

					if randomMapSpawn then
						humanRoot.CFrame = randomMapSpawn.CFrame
						humanRoot.Anchored = false
						makePlayerVisible(char)
						print(plr.Name .. " (Player) - " .. randomMapSpawn.Name .. "으로 텔레포트")
					else
						warn(plr.Name .. "에게 줄 MapSpawn이 없습니다!")
					end
				end
			end
		end
	end
end

local function isKillerAlive()
	local killerTeam = Teams:FindFirstChild("Killer")
	if not killerTeam then
		return false
	end

	for _, player in pairs(Players:GetPlayers()) do
		if player.Team == killerTeam then
			local character = player.Character
			if character then
				local humanoid = character:FindFirstChild("Humanoid")
				if humanoid and humanoid.Health > 0 then
					return true
				end
			end
		end
	end

	return false
end

local function round()
	while true do
		InRound.Value = false
		IsRestrictMovement.Value = false
		gameEnded = false

		repeat
			for i = intermission, 0, -1 do
				status.Value = "Game will start in " .. i .. " seconds. Need 2 or more players"
				task.wait(1)
			end

			local playerCount = #Players:GetPlayers()
			if playerCount < 2 then
				status.Value = "Not enough players! Waiting..."
				task.wait(2)
			end
		until #Players:GetPlayers() >= 2

		status.Value = "Selecting Killer..."
		_G.pickRandomPlayer()
		task.wait(3.5)

		status.Value = "Teleporting to map..."
		teleportPlayersByTeam()

		IsRestrictMovement.Value = true

		playGameMusic()

		if _G.createBricks then
			_G.createBricks()
		end

		createStartGameWall()

		for i = 10, 0, -1 do
			status.Value = "Game starting in " .. i .. " seconds"
			task.wait(1)
		end

		removeStartGameWall()

		InRound.Value = true

		if _G.createBall then
			_G.createBall()
		end

		local killerTeam = Teams:FindFirstChild("Killer")
		local playerTeam = Teams:FindFirstChild("Player")

		for i = roundLength, 0, -1 do
			if gameEnded then
				break
			end

			if not isKillerAlive() then
				status.Value = "Killer has left the game!"
				task.wait(2)

				local playerTeam = Teams:FindFirstChild("Player")
				handleVictory(playerTeam)
				break
			end

			local alivePlayers = getAlivePlayers()

			if #alivePlayers == 0 then
				status.Value = "All players eliminated!"
				task.wait(2)
				handleVictory(killerTeam)
				break
			end

			status.Value = "Time remaining: " .. i .. "s | Survivors: " .. #alivePlayers
			task.wait(1)
		end

		if not gameEnded then
			local alivePlayers = getAlivePlayers()
			if #alivePlayers > 0 then
				status.Value = "Time's up! Players survived!"
				task.wait(2)
				handleVictory(playerTeam)
			end
		end

		task.wait(3)
	end
end

-- 게임 시작 시 로비 음악 재생
playLobbyMusic()

-- 부활 관련 함수를 _G에 export (Marketplace 스크립트에서 사용)
_G.getRandomMapSpawn = getRandomMapSpawn
_G.makePlayerVisible = makePlayerVisible

task.spawn(round)
