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
	local startY = 20
	local brickSize = Vector3.new(4, 2, 2)

	for row = 1, 5 do
		for col = 1, 10 do
			local brick = Instance.new("Part")
			brick.Size = brickSize
			brick.Anchored = true
			brick.Position = Vector3.new(startX + col * 5, startY - row * 3, 0)
			brick.Color = colors[math.random(1, #colors)]
			brick.Name = "Brick"
			brick.Parent = bricksFolder
		end
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

	local bv = Instance.new("BodyVelocity")
	bv.Velocity = Vector3.new(20, 20, 0) -- 시작 속도
	bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	bv.Parent = ball

	ball.Parent = workspace

	local hitDirection = "left"
	-- 공 충돌 처리
	ball.Touched:Connect(function(hit)
		if hit then
			if hit.Name == "Brick" then
				hit:Destroy()
			end
			local diff = ball.Position - hit.Position
			local vx, vy, vz = bv.Velocity.X, bv.Velocity.Y, bv.Velocity.Z

			-- 충돌 방향 판정 (어느 축으로 더 가까운가)
			if hitDirection == "left" then
				hitDirection = "right"
				-- 가로 방향 충돌 → X축 반전
				bv.Velocity = bv.velocity * -1
			else
				hitDirection = "left"
				-- 세로 방향 충돌 → Y축 반전
				bv.Velocity = bv.velocity * 1
			end
		end
	end)
end
-- 게임 시작 이벤트 연결
startEvent.OnServerEvent:Connect(function(player)
	createBricks()
	createBall()
end)
