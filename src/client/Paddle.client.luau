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
-- 이동 상태 (PC / 모바일 공용)
-------------------------------------------------
local movingLeft = false
local movingRight = false

-------------------------------------------------
-- PC 키보드 입력 (기존 그대로)
-------------------------------------------------
local function setKeyState(keyCode, isDown)
	if keyCode == Enum.KeyCode.A or keyCode == Enum.KeyCode.Left then
		movingLeft = isDown
	elseif keyCode == Enum.KeyCode.D or keyCode == Enum.KeyCode.Right then
		movingRight = isDown
	end
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp or not canMovePaddle() then
		return
	end
	setKeyState(input.KeyCode, true)
end)

UserInputService.InputEnded:Connect(function(input)
	setKeyState(input.KeyCode, false)
end)

-------------------------------------------------
-- 📱 모바일 스와이프 → 키 입력처럼 변환
-------------------------------------------------
local touchStartX = nil
local SWIPE_THRESHOLD = 35

UserInputService.TouchStarted:Connect(function(touch, gp)
	if gp or not canMovePaddle() then
		return
	end
	touchStartX = touch.Position.X
end)

UserInputService.TouchMoved:Connect(function(touch, gp)
	if not touchStartX or not canMovePaddle() then
		return
	end

	local deltaX = touch.Position.X - touchStartX

	if deltaX > SWIPE_THRESHOLD then
		-- 오른쪽 키 누른 것처럼
		movingRight = true
		movingLeft = false
	elseif deltaX < -SWIPE_THRESHOLD then
		-- 왼쪽 키 누른 것처럼
		movingLeft = true
		movingRight = false
	else
		movingLeft = false
		movingRight = false
	end
end)

UserInputService.TouchEnded:Connect(function()
	touchStartX = nil
	movingLeft = false
	movingRight = false
end)

-------------------------------------------------
-- 서버 전송 루프 (기존 구조 유지)
-------------------------------------------------
RunService.RenderStepped:Connect(function()
	if not canMovePaddle() then
		return
	end

	local direction = 0
	if movingLeft then
		direction = -1
	elseif movingRight then
		direction = 1
	end

	if direction ~= 0 then
		movePaddleEvent:FireServer(direction)
	end
end)

print("✅ PC 키보드 + 모바일 스와이프 = 동일 입력 체계 완료")
