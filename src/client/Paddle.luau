-- BrickBreakerClient.lua

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local paddle = Instance.new("Part")
paddle.Size = Vector3.new(10, 2, 10)
paddle.Anchored = true
paddle.Position = Vector3.new(0, 1, 0)
paddle.BrickColor = BrickColor.new("Black")
paddle.Parent = workspace

-- 게임 시작 요청
ReplicatedStorage.StartGame:FireServer()

-- 패들 이동 속도
local speed = 1

-- 좌우 이동
UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Left then
		paddle.Position = paddle.Position + Vector3.new(-speed, 0, 0)
	elseif input.KeyCode == Enum.KeyCode.Right then
		paddle.Position = paddle.Position + Vector3.new(speed, 0, 0)
	end
end)

print("heelo")
