local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerScripts = player:WaitForChild("PlayerScripts")

local PlayerModule = require(playerScripts:WaitForChild("PlayerModule"))

-- inRound 값 가져오기
local inRound = ReplicatedStorage:WaitForChild("InRound")

player.CharacterAdded:Wait()
task.wait(0.1)

local Controls = PlayerModule:GetControls()

-- 플레이어 움직임 제어 함수
local function updatePlayerControls()
	if inRound.Value then
		Controls:Disable()
	else
		Controls:Enable()
	end
end

-- 초기 설정
updatePlayerControls()

-- inRound 값이 변경될 때마다 플레이어 움직임 제어 업데이트
inRound.Changed:Connect(function()
	updatePlayerControls()
end)

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

-- 패들을 움직일 수 있는지 체크
local function canMovePaddle()
	return isKiller() and inRound.Value
end

-- 패들 이동 플래그
local movingLeft = false
local movingRight = false

-- 키 입력 감지
UserInputService.InputBegan:Connect(function(input)
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

-- 서버에 이동 방향 전송
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
