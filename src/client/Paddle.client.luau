local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
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

-- 플레이어 움직임 제어 함수
local function updatePlayerControls()
	-- Lobby 팀이면 무조건 자유 이동 (최우선 체크!)
	if player.Team and player.Team.Name == "Lobby" then
		Controls:Enable()
		ContextActionService:UnbindAction("BlockAllMovement")
		ContextActionService:UnbindAction("BlockForwardBackward")
		print("Lobby 팀: 모든 제한 해제")
		return
	end

	-- Lobby가 아닐 때만 inRound 체크
	if inRound.Value then
		if isKiller() then
			-- Killer: 모든 움직임 차단 (패들만 조작 가능)
			Controls:Disable()
			ContextActionService:BindAction("BlockAllMovement", function()
				return Enum.ContextActionResult.Sink
			end, false, Enum.KeyCode.W, Enum.KeyCode.S, Enum.KeyCode.Up, Enum.KeyCode.Down)
			print("Killer: 캐릭터 움직임 차단, 패들만 조작 가능")
		else
			-- Player: 앞뒤만 차단 (좌우는 허용)
			Controls:Enable()
			ContextActionService:UnbindAction("BlockAllMovement")
			ContextActionService:BindAction("BlockForwardBackward", function()
				return Enum.ContextActionResult.Sink
			end, false, Enum.KeyCode.W, Enum.KeyCode.S, Enum.KeyCode.Up, Enum.KeyCode.Down)
			print("Player: 좌우만 이동 가능")
		end
	else
		-- 게임 중 아님: 모든 움직임 허용
		Controls:Enable()
		ContextActionService:UnbindAction("BlockAllMovement")
		ContextActionService:UnbindAction("BlockForwardBackward")
		print("로비: 자유 이동")
	end
end

-- 키 입력 감지 (패들 조작)
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

-- 서버에 패들 이동 방향 전송
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

-- 초기 설정
updatePlayerControls()

-- inRound 값이 변경될 때마다 업데이트
inRound.Changed:Connect(function()
	updatePlayerControls()
end)

-- 팀 변경 시에도 즉시 업데이트 (중요!)
player:GetPropertyChangedSignal("Team"):Connect(function()
	print("팀 변경 감지: " .. tostring(player.Team and player.Team.Name or "없음"))
	updatePlayerControls()
end)

-- 캐릭터 리스폰 시에도 적용
player.CharacterAdded:Connect(function()
	task.wait(0.5)
	print("캐릭터 리스폰 - 제어 업데이트")
	updatePlayerControls()
end)
