local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerScripts = player:WaitForChild("PlayerScripts")

local PlayerModule = require(playerScripts:WaitForChild("PlayerModule"))

player.CharacterAdded:Wait() -- 캐릭터 스폰 기다리기
task.wait(0.1)

local Controls = PlayerModule:GetControls()
Controls:Disable()

-- 패들 파트
local paddle = workspace:WaitForChild("Paddle")
paddle.Anchored = true -- 캐릭터 영향 없이 움직이게

-- Killer 팀 체크
local function isKiller()
	return player.Team and player.Team.Name == "Player"
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
		print("ㅇㄹㅇㄹㅇ")
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
