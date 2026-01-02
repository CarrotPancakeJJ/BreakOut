local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RemoteEvent 생성/가져오기
local movePaddleEvent = ReplicatedStorage:FindFirstChild("MovePaddle")
if not movePaddleEvent then
	movePaddleEvent = Instance.new("RemoteEvent")
	movePaddleEvent.Name = "MovePaddle"
	movePaddleEvent.Parent = ReplicatedStorage
end

-- Paddle 가져오기
local gameObjects = workspace:WaitForChild("GameObjects")
local paddle = gameObjects:WaitForChild("Paddle")
local leftWall = gameObjects:WaitForChild("LeftWall")
local rightWall = gameObjects:WaitForChild("RightWall")

paddle.Anchored = true
paddle.CanCollide = true
paddle.CanTouch = true

local speed = 50

-- 벽과 충돌 중인지 체크
local function isTouchingWall(wallName)
	local touchingParts = paddle:GetTouchingParts()
	for _, part in pairs(touchingParts) do
		if part.Name == wallName then
			return true
		end
	end
	return false
end

-- 클라이언트로부터 이동 명령 받기
movePaddleEvent.OnServerEvent:Connect(function(player, direction)
	-- Killer 팀인지 확인
	if not player.Team or player.Team.Name ~= "Killer" then
		return
	end

	local dt = 1 / 60 -- 약 60fps 기준

	-- 왼쪽 이동
	if direction == -1 and not isTouchingWall("LeftWall") then
		paddle.CFrame = paddle.CFrame * CFrame.new(-speed * dt, 0, 0)
	end

	-- 오른쪽 이동
	if direction == 1 and not isTouchingWall("RightWall") then
		paddle.CFrame = paddle.CFrame * CFrame.new(speed * dt, 0, 0)
	end
end)
