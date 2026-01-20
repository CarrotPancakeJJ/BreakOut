local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

local PLAYER_GROUP = "PlayersGroup"
local WALL_GROUP = "PassableWallGroup"

-- 1. 충돌 그룹 생성
pcall(function()
	PhysicsService:RegisterCollisionGroup(PLAYER_GROUP)
end)
pcall(function()
	PhysicsService:RegisterCollisionGroup(WALL_GROUP)
end)

-- 2. 플레이어 그룹과 벽 그룹 사이의 충돌을 무시하도록 설정
PhysicsService:CollisionGroupSetCollidable(PLAYER_GROUP, WALL_GROUP, false)

-- 3. 이 스크립트가 들어있는 파트를 벽 그룹에 할당
local gameObjectsFolder = workspace:FindFirstChild("GameObjects")
if gameObjectsFolder then
	topWall = gameObjectsFolder:FindFirstChild("TopWall")
	topWall.CollisionGroup = WALL_GROUP
end

-- 4. 플레이어가 접속할 때마다 캐릭터 파트들을 플레이어 그룹에 할당
local function setCharacterGroup(character)
	for _, child in pairs(character:GetDescendants()) do
		if child:IsA("BasePart") then
			child.CollisionGroup = PLAYER_GROUP
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(setCharacterGroup)
end)

-- 이미 접속 중인 플레이어 처리
for _, player in pairs(Players:GetPlayers()) do
	if player.Character then
		setCharacterGroup(player.Character)
	end
end
