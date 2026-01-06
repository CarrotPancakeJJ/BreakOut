local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerScripts = player:WaitForChild("PlayerScripts")
local PlayerModule = require(playerScripts:WaitForChild("PlayerModule"))
local Controls = PlayerModule:GetControls()
local IsRestrictMovement = ReplicatedStorage:WaitForChild("IsRestrictMovement")

-- 차단할 키 목록
local blockedKeys = {
	Enum.KeyCode.W,
	Enum.KeyCode.S,
	Enum.KeyCode.Up,
	Enum.KeyCode.Down,
}

-- 키가 차단 대상인지 확인
local function isBlockedKey(keyCode)
	for _, blocked in ipairs(blockedKeys) do
		if keyCode == blocked then
			return true
		end
	end
	return false
end

-- 키 입력 차단
local inputConnection

local function updateMovementRestriction()
	if IsRestrictMovement.Value then
		-- 이동 제한 활성화: W, S, 위, 아래 막기
		if not inputConnection then
			inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
				if isBlockedKey(input.KeyCode) then
					-- 아무것도 하지 않음 (입력 무시)
				end
			end)
		end

		-- ContextActionService로 키 바인딩 차단
		game:GetService("ContextActionService"):BindAction(
			"BlockForwardBackward",
			function(actionName, inputState, inputObject)
				-- 입력 차단 (Sink로 반환)
				return Enum.ContextActionResult.Sink
			end,
			false, -- UI에 버튼 생성 안 함
			Enum.KeyCode.W,
			Enum.KeyCode.S,
			Enum.KeyCode.Up,
			Enum.KeyCode.Down
		)

		print("앞뒤 이동 차단 활성화")
	else
		-- 이동 제한 해제
		if inputConnection then
			inputConnection:Disconnect()
			inputConnection = nil
		end

		game:GetService("ContextActionService"):UnbindAction("BlockForwardBackward")

		print("앞뒤 이동 차단 해제")
	end
end

-- 캐릭터가 죽었을 때 제한 일시 해제 (추가!)
player.CharacterAdded:Connect(function(character)
	local humanoid = character:WaitForChild("Humanoid")

	humanoid.Died:Connect(function()
		-- 죽었을 때 키 차단 해제
		if inputConnection then
			inputConnection:Disconnect()
			inputConnection = nil
		end
		game:GetService("ContextActionService"):UnbindAction("BlockForwardBackward")
		print("사망으로 인한 이동 제한 일시 해제")
	end)
end)

-- 초기 설정
updateMovementRestriction()

-- IsRestrictMovement 값 변경 감지
IsRestrictMovement.Changed:Connect(function()
	-- ★ 중요: 내 팀이 로비라면 이동 제한을 무시함
	updateMovementRestriction()
end)
