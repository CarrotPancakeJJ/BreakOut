local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- 1. 오브젝트 참조 (경로가 정확해야 합니다)
local lobbyObjects = Workspace:WaitForChild("LobbyObjects")
local outField = lobbyObjects:WaitForChild("OutField") -- 대소문자 주의

-- 로비 스폰 찾기 (기존 코드 로직 참고하여 안전하게 찾기)
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
	local lobbySpawnsFolder = lobbyObjects:FindFirstChild("LobbySpawns")
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

-- 디바운스 (연속 닿음 방지)
local cooldowns = {}

outField.Touched:Connect(function(hit)
	local character = hit.Parent
	local player = Players:GetPlayerFromCharacter(character)

	-- 플레이어의 캐릭터인 경우에만 실행
	if player and character:FindFirstChild("HumanoidRootPart") then
		-- 쿨타임 체크 (이미 텔레포트 중이면 무시)
		if cooldowns[player.UserId] then
			return
		end
		cooldowns[player.UserId] = true

		local hrp = character.HumanoidRootPart
		local lobbySpawn = getRandomLobbySpawn()

		if lobbySpawn then
			-- 텔레포트 실행
			-- 물리적 관성 제거 (미끄러짐 방지)
			hrp.Velocity = Vector3.zero
			hrp.AssemblyLinearVelocity = Vector3.zero

			-- 위치 이동 (스폰 위치보다 3스터드 위로)
			hrp.CFrame = lobbySpawn.CFrame + Vector3.new(0, 3, 0)

			print(player.Name .. "님이 OutFiled에 닿아 로비로 복귀했습니다.")
		else
			warn("LobbySpawn을 찾을 수 없습니다!")
		end

		-- 1초 후 쿨타임 해제
		task.wait(1)
		cooldowns[player.UserId] = nil
	end
end)
