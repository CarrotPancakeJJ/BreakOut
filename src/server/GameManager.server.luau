-- BrickBreakerServer.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RemoteEvent 준비
local startEvent = ReplicatedStorage:FindFirstChild("StartGame")
if not startEvent then
	startEvent = Instance.new("RemoteEvent")
	startEvent.Name = "StartGame"
	startEvent.Parent = ReplicatedStorage
end

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
	local brickSize = Vector3.new(10, 4, 4)

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

-- 충돌한 면(축) 분석 함수
local function getCollisionAxis(ball, hitPart)
	local ballPos = ball.Position
	local hitPos = hitPart.Position
	local hitSize = hitPart.Size

	-- 각 축에서의 거리 차이 계산
	local dx = math.abs(ballPos.X - hitPos.X)
	local dy = math.abs(ballPos.Y - hitPos.Y)
	local dz = math.abs(ballPos.Z - hitPos.Z)

	-- 상대적 거리 (파트 크기 고려)
	local relX = dx / (hitSize.X / 2)
	local relY = dy / (hitSize.Y / 2)
	local relZ = dz / (hitSize.Z / 2)

	-- 가장 큰 상대 거리를 가진 축이 충돌 축
	if relX > relY and relX > relZ then
		return "X" -- 좌우 면 충돌
	elseif relY > relX and relY > relZ then
		return "Y" -- 위아래 면 충돌
	else
		return "Z" -- 앞뒤 면 충돌
	end
end

-- 공 생성 함수
local function createBall()
	local oldBall = workspace:FindFirstChild("Ball")
	if oldBall then
		oldBall:Destroy()
	end

	local ball = Instance.new("Part")
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(2, 2, 2)
	ball.Position = Vector3.new(0, 5, 0)
	ball.Anchored = false
	ball.CanCollide = true
	ball.BrickColor = BrickColor.new("White")
	ball.Name = "Ball"

	-- 마찰력을 0으로 설정하여 물리적 끼임 방지
	ball.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0, 1, 100, 100)

	local bv = Instance.new("BodyVelocity")
	bv.Velocity = Vector3.new(20, 20, 0)
	bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	bv.Parent = ball

	ball.Parent = workspace

	local canBounce = true

	-- GameObjects 폴더 가져오기
	local gameObjects = workspace:FindFirstChild("GameObjects")
	local leftWall, rightWall, paddle
	if gameObjects then
		leftWall = gameObjects:FindFirstChild("LeftWall")
		rightWall = gameObjects:FindFirstChild("RightWall")
		paddle = gameObjects:FindFirstChild("Paddle")

		-- CanCollide와 CanTouch 확실히 설정
		if leftWall then
			leftWall.CanCollide = true
			leftWall.CanTouch = true
		end
		if rightWall then
			rightWall.CanCollide = true
			rightWall.CanTouch = true
		end
		if paddle then
			paddle.CanCollide = true
			paddle.CanTouch = true
		end
	end

	-- 공 충돌 처리
	ball.Touched:Connect(function(hit)
		if not canBounce or not hit or hit == ball then
			return
		end
		local collisionAxis

		-- 충돌 감지되면 즉시 튕김 방지
		canBounce = false

		-- 벽돌 파괴
		if hit.Name == "Brick" then
			hit:Destroy()
		end

		-- 반사방향 결정
		if hit.Name == "LeftWall" or hit.Name == "RightWall" then
			collisionAxis = "X"
		elseif hit.Name == "Paddle" or hit.Name == "Brick" or hit.Name == "DeathFloor" then
			collisionAxis = "Y"
		end

		-- 반사 처리 (벽, 패들, 벽돌 모두 적용)
		if
			hit.Name == "LeftWall"
			or hit.Name == "RightWall"
			or hit.Name == "Paddle"
			or hit.Name == "Brick"
			or hit.Name == "DeathFloor"
		then
			-- local collisionAxis = getCollisionAxis(ball, hit)
			local velocity = bv.Velocity

			if collisionAxis == "X" then
				bv.Velocity = Vector3.new(-velocity.X, velocity.Y, velocity.Z)
			elseif collisionAxis == "Y" then
				bv.Velocity = Vector3.new(velocity.X, -velocity.Y, velocity.Z)
			else
				bv.Velocity = Vector3.new(velocity.X, velocity.Y, -velocity.Z)
			end

			print("충돌! " .. hit.Name .. " - 축: " .. collisionAxis)
		end

		-- 쿨타임
		task.delay(0.05, function()
			canBounce = true
		end)
	end)
end

-- 전역 함수로 export
_G.createBricks = createBricks
_G.createBall = createBall
