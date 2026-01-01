local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

-- 각 스탯별 DataStore 생성
local killerWinsDataStore = DataStoreService:GetOrderedDataStore("KillerWinsLeaderboard")
local playerWinsDataStore = DataStoreService:GetOrderedDataStore("PlayerWinsLeaderboard")

-- 플레이어 데이터 로드 함수
local function loadPlayerData(player)
	local data = {
		KillerWins = 0,
		PlayerWins = 0,
	}

	-- Killer Wins 로드
	local success1, killerWins = pcall(function()
		return killerWinsDataStore:GetAsync(player.UserId)
	end)
	if success1 and killerWins then
		data.KillerWins = killerWins
	end

	-- Player Wins 로드
	local success2, playerWins = pcall(function()
		return playerWinsDataStore:GetAsync(player.UserId)
	end)
	if success2 and playerWins then
		data.PlayerWins = playerWins
	end

	return data
end

-- 플레이어 데이터 저장 함수
local function savePlayerData(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end

	-- Killer Wins 저장
	pcall(function()
		killerWinsDataStore:SetAsync(player.UserId, leaderstats["Killer Wins"].Value)
	end)

	-- Player Wins 저장
	pcall(function()
		playerWinsDataStore:SetAsync(player.UserId, leaderstats["Player Wins"].Value)
	end)

	print(player.Name .. "의 데이터가 저장되었습니다.")
end

Players.PlayerAdded:Connect(function(player)
	-- 데이터 로드
	local data = loadPlayerData(player)

	-- leaderstats 폴더 생성
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	-- Killer Wins 통계
	local killerWins = Instance.new("IntValue")
	killerWins.Name = "Killer Wins"
	killerWins.Value = data.KillerWins
	killerWins.Parent = leaderstats

	-- Player Wins 통계
	local playerWins = Instance.new("IntValue")
	playerWins.Name = "Player Wins"
	playerWins.Value = data.PlayerWins
	playerWins.Parent = leaderstats

	print(player.Name .. "의 통계가 로드되었습니다.")
end)

-- 플레이어가 나갈 때 저장
Players.PlayerRemoving:Connect(function(player)
	savePlayerData(player)
end)

-- 게임이 종료될 때 모든 플레이어 데이터 저장
game:BindToClose(function()
	for _, player in pairs(Players:GetPlayers()) do
		savePlayerData(player)
	end
	task.wait(3)
end)

-- 자동 저장 (5분마다)
task.spawn(function()
	while true do
		task.wait(300)
		for _, player in pairs(Players:GetPlayers()) do
			savePlayerData(player)
		end
		print("모든 플레이어 데이터 자동 저장 완료")
	end
end)
