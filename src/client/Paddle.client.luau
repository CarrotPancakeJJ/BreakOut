local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local inRound = ReplicatedStorage:WaitForChild("InRound")
local movePaddleEvent = ReplicatedStorage:WaitForChild("MovePaddle")

-------------------------------------------------
-- Killer / Round 체크
-------------------------------------------------
local function isKiller()
	return player.Team and player.Team.Name == "Killer"
end

local function canMovePaddle()
	return isKiller() and inRound.Value
end

-------------------------------------------------
-- 이동 상태 변수
-------------------------------------------------
local movingLeft = false
local movingRight = false

-- 마지막으로 서버에 보낸 방향 (중복 전송 방지용)
local lastSentDirection = 0

-------------------------------------------------
-- 서버 전송 최적화 함수
-------------------------------------------------
local function updateMovement()
	if not canMovePaddle() then
		return
	end

	local targetDirection = 0
	if movingLeft then
		targetDirection = -1
	elseif movingRight then
		targetDirection = 1
	end

	-- **중요: 방향이 변경되었을 때만 서버에 전송**
	if targetDirection ~= lastSentDirection then
		lastSentDirection = targetDirection
		movePaddleEvent:FireServer(targetDirection)
		-- print("방향 전송:", targetDirection) -- 디버깅용
	end
end

-------------------------------------------------
-- PC 키보드 입력
-------------------------------------------------
local function setKeyState(keyCode, isDown)
	if keyCode == Enum.KeyCode.A or keyCode == Enum.KeyCode.Left then
		movingLeft = isDown
	elseif keyCode == Enum.KeyCode.D or keyCode == Enum.KeyCode.Right then
		movingRight = isDown
	end
	updateMovement() -- 키 입력 상태가 변할 때 즉시 체크
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then
		return
	end
	setKeyState(input.KeyCode, true)
end)

UserInputService.InputEnded:Connect(function(input)
	setKeyState(input.KeyCode, false)
end)

-------------------------------------------------
-- 📱 모바일 스와이프
-------------------------------------------------
local touchStartX = nil
local SWIPE_THRESHOLD = 35

UserInputService.TouchStarted:Connect(function(touch, gp)
	if gp then
		return
	end
	touchStartX = touch.Position.X
end)

UserInputService.TouchMoved:Connect(function(touch, gp)
	if not touchStartX then
		return
	end

	-- Killer나 라운드 체크는 updateMovement에서 한 번 더 하므로 여기선 단순화 가능

	local deltaX = touch.Position.X - touchStartX

	if deltaX > SWIPE_THRESHOLD then
		movingRight = true
		movingLeft = false
	elseif deltaX < -SWIPE_THRESHOLD then
		movingLeft = true
		movingRight = false
	else
		movingLeft = false
		movingRight = false
	end

	updateMovement() -- 터치 이동 중 상태 변화 체크
end)

UserInputService.TouchEnded:Connect(function()
	touchStartX = nil
	movingLeft = false
	movingRight = false
	updateMovement() -- 손을 뗐을 때 멈춤 전송
end)

-- RenderStepped 루프 제거됨: 이제 이벤트 기반으로 작동하여 네트워크 부하가 획기적으로 줄어듭니다.
print("✅ 최적화된 입력 시스템 로드 완료")
