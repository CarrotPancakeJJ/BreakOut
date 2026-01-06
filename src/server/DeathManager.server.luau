local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 게임 종료 플래그 추가
local lobbyTeam = Teams:FindFirstChild("Lobby")
local InRound = ReplicatedStorage:WaitForChild("InRound")
local IsRestrictMovement = ReplicatedStorage:WaitForChild("IsRestrictMovement")

-- LobbySpawn 찾기
local function getRandomLobbySpawn()
	local lobbySpawns = {}

	-- workspace에서 LobbySpawn 찾기
	for _, obj in pairs(workspace:GetChildren()) do
		if obj:IsA("BasePart") and obj.Name:match("^LobbySpawn") then
			table.insert(lobbySpawns, obj)
		end
	end

	-- LobbyObjects 폴더에서도 찾기
	local lobbyObjectsFolder = workspace:FindFirstChild("LobbyObjects")
	if lobbyObjectsFolder then
		local lobbySpawnsFolder = lobbyObjectsFolder:FindFirstChild("LobbySpawns")
		if lobbySpawnsFolder then
			for _, obj in pairs(lobbySpawnsFolder:GetChildren()) do
				if obj:IsA("BasePart") and obj.Name:match("^LobbySpawn") then
					table.insert(lobbySpawns, obj)
				end
			end
		end
	end

	if #lobbySpawns > 0 then
		return lobbySpawns[math.random(1, #lobbySpawns)]
	end

	return workspace:FindFirstChild("LobbySpawn")
end

-- 각 플레이어의 텔레포트 처리 상태 추적
local teleportingPlayers = {}

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

		-- 죽었을 때
		humanoid.Died:Connect(function()
			-- Lobby 팀으로 변경
			if lobbyTeam then
				player.Team = lobbyTeam
				player.TeamColor = lobbyTeam.TeamColor
				teleportingPlayers[player.UserId] = true
				print(player.Name .. " 사망 - Lobby 팀으로 이동")

				-- 게임 중이라면 승패 체크 (추가!)
				if InRound.Value then
					-- 잠깐 대기 후 체크 (다른 플레이어 상태도 확인하기 위해)
					task.wait(0.5)
				end
			end
		end)

		-- 리스폰 직후 처리 (중요: 약간의 딜레이 필요)
		task.wait(0.5)

		-- Lobby 팀이고 텔레포트가 필요한 경우
		if player.Team == lobbyTeam and teleportingPlayers[player.UserId] then
			-- Anchored 해제 (혹시 Killer였다면)
			humanoidRootPart.Anchored = false

			-- 로비로 텔레포트
			local lobbySpawn = getRandomLobbySpawn()
			if lobbySpawn then
				humanoidRootPart.CFrame = lobbySpawn.CFrame + Vector3.new(0, 3, 0) -- 약간 위에서 스폰
				print(player.Name .. " (Lobby 팀) 로비로 텔레포트")
			end

			teleportingPlayers[player.UserId] = false
		end
	end)
end)

-- 플레이어 나갈 때 정리
Players.PlayerRemoving:Connect(function(player)
	teleportingPlayers[player.UserId] = nil
end)
