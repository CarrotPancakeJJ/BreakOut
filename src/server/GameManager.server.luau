local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService") -- [추가] 매 프레임 연산을 위해 필요
local soundService = game:GetService("SoundService")
local BGMFolder = soundService:WaitForChild("BGM")

local gameObjects = workspace:WaitForChild("GameObjects")
local LowGravityBox = gameObjects:WaitForChild("LowGravityBox")
local Mode = ReplicatedStorage:WaitForChild("Mode")

-- 기존 RemoteEvent 및 변수 설정 유지
local startEvent = ReplicatedStorage:FindFirstChild("StartGame")
if not startEvent then
	startEvent = Instance.new("RemoteEvent")
	startEvent.Name = "StartGame"
	startEvent.Parent = ReplicatedStorage
end

local INITIAL_SPEED = 30
local SPEED_INCREMENT = 5

local colors = {
	Color3.fromRGB(255, 0, 0),
	Color3.fromRGB(0, 255, 0),
	Color3.fromRGB(0, 0, 255),
	Color3.fromRGB(255, 255, 0),
	Color3.fromRGB(255, 165, 0),
	Color3.fromRGB(128, 0, 128),
}

-- [벽돌 생성 함수 유지]
local function createBricks()
	if Mode.Value ~= "LowGravity" then
		LowGravityBox.CanTouch = false
	else
		LowGravityBox.CanTouch = true
	end

	local bricksFolder = workspace:FindFirstChild("Bricks")
	if bricksFolder then
		bricksFolder:Destroy()
	end

	bricksFolder = Instance.new("Folder")
	bricksFolder.Name = "Bricks"
	bricksFolder.Parent = workspace

	local startX = -20
	local startY = 50
	local brickSize = Vector3.new(8, 4, 15)

	for row = 1, 7 do
		for col = 1, 12 do
			local brick = Instance.new("Part")
			brick.Size = brickSize
			-- MODE에 따라 ANCHORED 변경
			-- 무중력
			if Mode.Value == "LowGravity" then
				brick.Anchored = false
			else
				brick.Anchored = true
			end
			-- 스피드
			if Mode.Value == "Double" then
				brick.Name = "DoubleBrick"
			else
				brick.Name = "Brick"
			end
			brick.CastShadow = false
			brick.Position = Vector3.new(startX + col * 12, startY - row * 6, 0)
			brick.Color = colors[math.random(1, #colors)]
			brick.Material = Enum.Material.Wood
			brick.Parent = bricksFolder
		end
	end
end

-------------------------------------------------------------
-- [핵심 변경] Raycasting 기반 공 생성 및 이동 함수
-------------------------------------------------------------

local function createBall(startPos)
	-- 2. 공 생성 (Anchored = true로 설정하여 물리 엔진 영향 제거)
	local ball = Instance.new("Part")
	ball.Name = "Ball"
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(2, 2, 2)
	ball.Position = startPos
	ball.Color = Color3.new(1, 0.615686, 0)
	ball.Material = Enum.Material.Neon
	ball.Anchored = true -- [중요] 물리 엔진이 아닌 스크립트로만 이동
	ball.CanCollide = false -- Raycast로 처리하므로 충돌 판정 불필요
	ball.Parent = workspace

	-- 3. 초기 속도 및 방향 설정
	local currentSpeed
	-- 스피드 모드면 속도 증가
	if Mode.Value == "Speed" then
		INITIAL_SPEED = 60
		SPEED_INCREMENT = 20
	else
		INITIAL_SPEED = 30
		SPEED_INCREMENT = 5
	end

	currentSpeed = INITIAL_SPEED
	local direction = Vector3.new(1, 1, 0).Unit -- 초기 발사 방향

	-- 레이캐스트 파라미터 (공 자신은 무시)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { ball, LowGravityBox }

	-- [핵심] 루프를 함수 안의 지역 변수로 만듦
	local myLoop
	myLoop = RunService.Heartbeat:Connect(function(dt)
		if not ball or not ball.Parent then
			myLoop:Disconnect() -- 공이 없어지면 이 루프만 딱 종료
			return
		end

		-- 이번 프레임에 이동할 거리 계산
		local stepDistance = currentSpeed * dt
		local origin = ball.Position
		local targetPosition = origin + (direction * stepDistance)
		local brickSound = BGMFolder:WaitForChild("break")

		-- 가려는 경로에 장애물이 있는지 레이저 발사
		local rayResult = workspace:Raycast(origin, direction * stepDistance, rayParams)

		if rayResult then
			-- [충돌 발생!]
			local hitPart = rayResult.Instance
			local hitName = hitPart.Name
			local normal = rayResult.Normal -- 충돌 면의 법선 벡터

			-- 0. 플레이어 충돌 체크
			local character = hitPart.Parent
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				humanoid.Health = 0
				return -- 플레이어 사망 시 튕김 로직 무시 가능
			end

			-- 1. 반사 벡터 계산 (기본 물리 반사 공식: V - 2(V내적N)N)
			local reflect = direction - (2 * direction:Dot(normal) * normal)
			direction = reflect -- 기본적으로 반사된 방향을 가짐

			-- 2. 특수 충돌 처리
			if hitName == "Paddle" then
				-- 패들: 속도 증가 및 각도 조절
				currentSpeed = currentSpeed + SPEED_INCREMENT
				local hitOffset = (ball.Position.X - hitPart.Position.X) / (hitPart.Size.X / 2)
				-- 패들 중심에서 멀수록 휘어지게 설정
				direction = Vector3.new(hitOffset * 1.5, 1, 0).Unit
			elseif hitName == "DeathFloor" then
				-- 바닥: 초기화 (튕겨 올라가게 처리)
				currentSpeed = INITIAL_SPEED
				direction = Vector3.new(direction.X, math.abs(direction.Y), 0).Unit
			elseif hitName == "LeftWall" then
				-- 왼쪽 벽: 무조건 오른쪽으로
				direction = Vector3.new(math.abs(direction.X), direction.Y, 0).Unit
			elseif hitName == "RightWall" then
				-- 오른쪽 벽: 무조건 왼쪽으로
				direction = Vector3.new(-math.abs(direction.X), direction.Y, 0).Unit
			elseif hitName == "TopWall" then
				-- 천장: 무조건 아래로
				direction = Vector3.new(direction.X, -math.abs(direction.Y), 0).Unit
				-- 더블 브릭이면
			elseif hitName == "DoubleBrick" then
				local brickSound = BGMFolder:WaitForChild("break")
				if brickSound then
					brickSound:Play()
				end
				-- 벽돌 파괴
				hitPart.Name = "Brick"
				hitPart.Transparency = 0.7
			elseif hitName == "Brick" then
				if brickSound then
					brickSound:Play()
				end
				-- 벽돌 파괴
				hitPart:Destroy()
			end

			-- 3. [보정] Y축 속도가 너무 느리면 수평 이동 방지 (무한 루프 방지)
			if math.abs(direction.Y) < 0.2 then
				local newY = (direction.Y >= 0) and 0.5 or -0.5
				direction = Vector3.new(direction.X, newY, 0).Unit
			end

			-- Z축 고정 (2D 게임이므로)
			direction = Vector3.new(direction.X, direction.Y, 0).Unit

			-- 4. 공 위치 강제 조정 (벽에 끼임 방지)
			-- 충돌 지점에서 법선 방향으로 살짝 띄워줌
			ball.Position = rayResult.Position + (normal * 0.1)
		else
			-- [충돌 없음] 그냥 이동
			ball.Position = targetPosition
		end
	end)
end

-- 게임 정리 함수
local function cleanupGame()
	for _, obj in ipairs(workspace:GetChildren()) do
		if obj.Name == "Ball" then
			obj:Destroy()
		end
	end

	local bricksFolder = workspace:FindFirstChild("Bricks")
	if bricksFolder then
		bricksFolder:Destroy()
	end
end

-- 전역 등록
_G.cleanupGame = cleanupGame
_G.createBricks = createBricks
_G.createBall = createBall
