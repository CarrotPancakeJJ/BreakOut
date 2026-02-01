local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService") -- 추가

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

local IsSolo = ReplicatedStorage:WaitForChild("IsSolo")
local Mode = ReplicatedStorage:WaitForChild("Mode")

paddle.Anchored = true
paddle.CanCollide = true
paddle.CanTouch = true

local speed = 50
local currentDirection = 0 -- 현재 이동 방향 저장 (-1, 0, 1)

-- 벽과 충돌 중인지 체크 (최적화를 위해 필요할 때만 호출하거나 수학적 계산 권장)
local function isTouchingWall(wallName)
	local touchingParts = paddle:GetTouchingParts()
	for _, part in pairs(touchingParts) do
		if part.Name == wallName then
			return true
		end
	end
	return false
end

-- 클라이언트로부터 "방향 변경" 요청만 받음
movePaddleEvent.OnServerEvent:Connect(function(player, direction)
	-- Killer 팀인지 확인
	if not player.Team or player.Team.Name ~= "Killer" then
		return
	end

	-- 방향 상태 업데이트 (유효성 검사 포함)
	if direction == -1 or direction == 0 or direction == 1 then
		currentDirection = direction
	end
end)

local function SoloPaddle()
	if IsSolo.Value then
		currentDirection = -1
	end
end

SoloPaddle()
-- 서버 자체 루프에서 이동 처리 (끊김 없는 이동의 핵심)
RunService.Heartbeat:Connect(function(dt)
	-- 스피드 모드면 속도 증가
	if Mode.Value == "Speed" then
		speed = 100
	else
		speed = 50
	end

	if currentDirection == 0 then
		if IsSolo.Value then
			currentDirection = -1
		end
		return
	end -- 움직임 없으면 무시
	-- 왼쪽 이동
	if currentDirection == -1 then
		if not isTouchingWall("LeftWall") then
			paddle.CFrame = paddle.CFrame * CFrame.new(-speed * dt, 0, 0)
		elseif isTouchingWall("LeftWall") and IsSolo.Value then
			-- 벽에 닿았는데 계속 가려고 하면 멈춤 처리 (선택 사항)
			-- currentDirection = 0
			currentDirection = 1
		end
	end

	-- 오른쪽 이동
	if currentDirection == 1 then
		if not isTouchingWall("RightWall") then
			paddle.CFrame = paddle.CFrame * CFrame.new(speed * dt, 0, 0)
		elseif isTouchingWall("RightWall") and IsSolo.Value then
			currentDirection = -1
			-- currentDirection = 0
		end
	end
end)
