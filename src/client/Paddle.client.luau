local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerScripts = player:WaitForChild("PlayerScripts")

local PlayerModule = require(playerScripts:WaitForChild("PlayerModule"))

-- inRound 값 가져오기
local inRound = ReplicatedStorage:WaitForChild("InRound")

player.CharacterAdded:Wait() -- 캐릭터 스폰 기다리기
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

-- 패들 파트
local paddle = workspace:WaitForChild("Paddle")
paddle.Anchored = true -- 캐릭터 영향 없이 움직이게

-- Killer 팀 체크
local function isKiller()
	return player.Team and player.Team.Name == "Killer"
end

-- 패들 이동 플래그
local movingLeft = false
local movingRight = false
local speed = 50 --?스터드씩 이동, 필요 시 조절

-- 키 입력 감지
UserInputService.InputBegan:Connect(function(input)
	if not isKiller() then
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

-- 패들 이동 루프
game:GetService("RunService").RenderStepped:Connect(function(dt)
	if not isKiller() then
		return
	end
	if movingLeft then
		paddle.CFrame = paddle.CFrame * CFrame.new(-speed * dt, 0, 0)
	elseif movingRight then
		paddle.CFrame = paddle.CFrame * CFrame.new(speed * dt, 0, 0)
	end
end)
