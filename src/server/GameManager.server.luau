-- BrickBreakerServer.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RemoteEvent 준비
local startEvent = ReplicatedStorage:FindFirstChild("StartGame")
if not startEvent then
	startEvent = Instance.new("RemoteEvent")
	startEvent.Name = "StartGame"
	startEvent.Parent = ReplicatedStorage
end

local INITIAL_SPEED = 30 -- 게임 시작 시 초기 속도
local SPEED_INCREMENT = 5 -- 패들에 닿을 때마다 증가할 속도량
local currentSpeed = INITIAL_SPEED -- 현재 공의 속도를 추적하는 변수

local PhysicsService = game:GetService("PhysicsService")

-- 그룹 이름 정의
local ballGroup = "Balls"
local wallGroup = "SpecialWalls"

-- 그룹 생성 (이미 존재하면 무시)
pcall(function()
	PhysicsService:CreateCollisionGroup(ballGroup)
end)
pcall(function()
	PhysicsService:CreateCollisionGroup(wallGroup)
end)

-- 관계 설정: 공과 특수벽은 서로 충돌함
PhysicsService:CollisionGroupSetCollidable(ballGroup, wallGroup, true)
-- 관계 설정: 플레이어(Default)와 특수벽은 서로 통과함 (이게 핵심!)
PhysicsService:CollisionGroupSetCollidable("Default", wallGroup, false)

-- 색상 후보
local colors = {
	Color3.fromRGB(255, 0, 0),
	Color3.fromRGB(0, 255, 0),
	Color3.fromRGB(0, 0, 255),
	Color3.fromRGB(255, 255, 0),
	Color3.fromRGB(255, 165, 0),
	Color3.fromRGB(128, 0, 128),
}

-- 벽돌 생성 함수
local function createBricks()
	local bricksFolder = workspace:FindFirstChild("Bricks")
	if bricksFolder then
		bricksFolder:Destroy()
	end

	bricksFolder = Instance.new("Folder")
	bricksFolder.Name = "Bricks"
	bricksFolder.Parent = workspace

	local startX = -20
	local startY = 50
	local brickSize = Vector3.new(8, 4, 4)

	for row = 1, 7 do
		for col = 1, 12 do
			local brick = Instance.new("Part")
			brick.Size = brickSize
			brick.Anchored = true
			brick.Position = Vector3.new(startX + col * 12, startY - row * 6, 0)
			brick.Color = colors[math.random(1, #colors)]
			brick.Name = "Brick"
			brick.Parent = bricksFolder
		end
	end
end

-- 충돌 면의 법선 벡터(Normal)를 구하는 함수
local function getNormal(ballPos, hitPart)
	local hitPos = hitPart.Position
	local hitSize = hitPart.Size

	local dx = (ballPos.X - hitPos.X) / (hitSize.X / 2)
	local dy = (ballPos.Y - hitPos.Y) / (hitSize.Y / 2)

	-- 가장 멀리 떨어진 축의 방향을 법선 벡터로 설정
	if math.abs(dx) > math.abs(dy) then
		return Vector3.new(math.sign(dx), 0, 0) -- 좌우면 (X축 법선)
	else
		return Vector3.new(0, math.sign(dy), 0) -- 위아래면 (Y축 법선)
	end
end

-- 공 생성 함수
local function createBall()
	-- 이전 볼 제거 로직
	local oldBall = workspace:FindFirstChild("Ball")
	if oldBall then
		oldBall:Destroy()
	end

	local ball = Instance.new("Part")
	ball.CollisionGroupId = PhysicsService:GetCollisionGroupId(ballGroup)
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(2, 2, 2)
	ball.Position = Vector3.new(0, 5, 0)
	ball.Anchored = false
	ball.CanCollide = true
	ball.BrickColor = BrickColor.new("White")
	ball.Name = "Ball"
	ball.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0, 1, 100, 100)

	-- 초기 속도 설정
	currentSpeed = INITIAL_SPEED

	local bv = Instance.new("BodyVelocity")
	-- 초기 방향 (약간의 각도를 주어 시작)
	bv.Velocity = Vector3.new(INITIAL_SPEED, INITIAL_SPEED, 0).Unit * currentSpeed
	bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	bv.Parent = ball

	ball.Parent = workspace

	local canBounce = true

	ball.Touched:Connect(function(hit)
		if not canBounce or not hit or hit.CanCollide == false then
			return
		end

		local hitName = hit.Name
		canBounce = false

		-- 0. 플레이어 캐릭터인지 확인
		local character = hit.Parent
		local humanoid = character:FindFirstChildOfClass("Humanoid")

		if humanoid and humanoid.Health > 0 then
			-- 플레이어가 공에 닿으면 즉시 사망
			humanoid.Health = 0
			print(character.Name .. " 플레이어가 공에 부딪혀 사망했습니다!")
			return -- 플레이어와 부딪혔을 때는 튕김 로직을 건너뛰고 싶다면 return 사용
		end

		-- 1. 예외 처리: 좌우 벽
		if hitName == "LeftWall" then
			-- 무조건 오른쪽(+) 방향으로 속도 설정
			bv.Velocity = Vector3.new(math.abs(bv.Velocity.X), bv.Velocity.Y, 0)
		elseif hitName == "RightWall" then
			-- 무조건 왼쪽(-) 방향으로 속도 설정
			bv.Velocity = Vector3.new(-math.abs(bv.Velocity.X), bv.Velocity.Y, 0)
		elseif hitName == "TopWall" then
			-- 확실하게 아래 방향으로 튕기도록 math.abs 사용
			bv.Velocity = Vector3.new(bv.Velocity.X, -math.abs(bv.Velocity.Y), 0)
			print("천장 충돌 (플레이어는 통과 가능)")

		-- 2. 패들: 각도 조절 + 속도 0.2 증가
		elseif hitName == "Paddle" then
			-- 속도 증가
			currentSpeed = currentSpeed + SPEED_INCREMENT
			print("공 속도 증가! 현재 속도:", currentSpeed)

			local hitOffset = (ball.Position.X - hit.Position.X) / (hit.Size.X / 2)
			local newDirection = Vector3.new(hitOffset * 1.5, 1, 0).Unit
			bv.Velocity = newDirection * currentSpeed -- 증가된 속도 적용

		-- 3. 데스 플로어: 속도 초기화
		elseif hitName == "DeathFloor" then
			currentSpeed = INITIAL_SPEED
			print("공이 떨어졌습니다. 속도 초기화:", currentSpeed)

			-- 필요하다면 여기서 공의 위치를 다시 리셋하는 로직을 넣을 수 있습니다.
			-- 현재는 그냥 튕겨 올라가는 로직으로 처리 (반사각 적용)
			bv.Velocity = Vector3.new(bv.Velocity.X, math.abs(bv.Velocity.Y), 0)

		-- 4. 나머지 (벽돌, 천장 등)
		else
			local normal = getNormal(ball.Position, hit)
			local reflectVelocity = bv.Velocity - 2 * bv.Velocity:Dot(normal) * normal
			bv.Velocity = reflectVelocity.Unit * currentSpeed -- 현재 속력 유지하며 방향만 반사

			if hitName == "Brick" then
				hit:Destroy()
			end
		end

		-- [보정] Y축 최소 속도 유지
		if math.abs(bv.Velocity.Y) < (currentSpeed * 0.3) then
			local newY = math.sign(bv.Velocity.Y) * (currentSpeed * 0.5)
			if newY == 0 then
				newY = currentSpeed * 0.5
			end
			bv.Velocity = Vector3.new(bv.Velocity.X, newY, 0).Unit * currentSpeed
		end

		task.delay(0.05, function()
			canBounce = true
		end)
	end)
end

local function cleanupGame()
	-- 1. 공 제거
	local ball = workspace:FindFirstChild("Ball")
	if ball then
		ball:Destroy()
		print("공이 제거되었습니다.")
	end

	-- 2. 벽돌 폴더 제거
	local bricksFolder = workspace:FindFirstChild("Bricks")
	if bricksFolder then
		bricksFolder:Destroy()
		print("벽돌 폴더가 제거되었습니다.")
	end
end

-- 전역 함수로 등록하여 RoundManager에서 사용할 수 있게 함
_G.cleanupGame = cleanupGame
_G.createBricks = createBricks
_G.createBall = createBall
