local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- inRound 값 가져오기
local inRound = ReplicatedStorage:WaitForChild("InRound")

-- RemoteEvent 생성/가져오기
local movePaddleEvent = ReplicatedStorage:FindFirstChild("MovePaddle")
if not movePaddleEvent then
	movePaddleEvent = Instance.new("RemoteEvent")
	movePaddleEvent.Name = "MovePaddle"
	movePaddleEvent.Parent = ReplicatedStorage
end

-- Killer 팀 체크
local function isKiller()
	return player.Team and player.Team.Name == "Killer"
end

-- 패들을 움직일 수 있는지 체크 (Killer이고 라운드 중일 때만)
local function canMovePaddle()
	return isKiller() and inRound.Value
end

-- 패들 이동 플래그
local movingLeft = false
local movingRight = false

-- 키 입력 감지 (패들 조작은 유지)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end -- 채팅 중 입력 방지
	if not canMovePaddle() then
		return
	end

	if input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.Left then
		movingLeft = true
	elseif input.KeyCode == Enum.KeyCode.D or input.KeyCode == Enum.KeyCode.Right then
		movingRight = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.Left then
		movingLeft = false
	elseif input.KeyCode == Enum.KeyCode.D or input.KeyCode == Enum.KeyCode.Right then
		movingRight = false
	end
end)

-- 서버에 패들 이동 방향 전송 (RunService 루프 유지)
game:GetService("RunService").RenderStepped:Connect(function()
	if not canMovePaddle() then
		return
	end

	local direction = 0
	if movingLeft then
		direction = -1
	elseif movingRight then
		direction = 1
	end

	-- 서버로 방향 전송
	movePaddleEvent:FireServer(direction)
end)

print("이동 제한 해제 완료: 모든 팀이 자유롭게 이동할 수 있습니다.")
