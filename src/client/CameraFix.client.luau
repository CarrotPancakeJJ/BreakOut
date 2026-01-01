-- StarterPlayer > StarterPlayerScripts에 LocalScript로 넣으세요

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- inRound 값 가져오기
local inRound = ReplicatedStorage:WaitForChild("InRound")

-- 카메라 고정 연결 변수 (나중에 해제하기 위해)
local cameraConnection = nil

-- 방법 1: 특정 Part에 카메라 고정
local function lockCameraToPart(part)
	if not part then
		warn("Part를 찾을 수 없습니다!")
		return nil
	end

	camera.CameraType = Enum.CameraType.Scriptable

	-- 기존 연결이 있으면 해제
	if cameraConnection then
		cameraConnection:Disconnect()
		cameraConnection = nil
	end

	-- 카메라를 Part의 위치로 계속 업데이트
	cameraConnection = RunService.RenderStepped:Connect(function()
		camera.CFrame = part.CFrame
	end)

	print("카메라가 " .. part.Name .. "에 고정되었습니다.")
	return cameraConnection
end

-- 방법 2: 특정 위치에 카메라 고정 (위치와 바라보는 방향 설정)
local function lockCameraToPosition(position, lookAtPosition)
	camera.CameraType = Enum.CameraType.Scriptable

	-- position: Vector3 - 카메라가 위치할 곳
	-- lookAtPosition: Vector3 (선택사항) - 카메라가 바라볼 곳

	if lookAtPosition then
		camera.CFrame = CFrame.new(position, lookAtPosition)
	else
		camera.CFrame = CFrame.new(position)
	end

	print("카메라가 특정 위치에 고정되었습니다.")
end

-- 방법 3: 특정 Part를 향해 바라보며 거리 유지
local function lockCameraLookingAtPart(targetPart, distance, height)
	if not targetPart then
		warn("Part를 찾을 수 없습니다!")
		return
	end

	camera.CameraType = Enum.CameraType.Scriptable
	distance = distance or 20 -- 기본 거리
	height = height or 10 -- 기본 높이

	RunService.RenderStepped:Connect(function()
		local targetPos = targetPart.Position
		local cameraPos = targetPos + Vector3.new(0, height, distance)
		camera.CFrame = CFrame.new(cameraPos, targetPos)
	end)

	print("카메라가 " .. targetPart.Name .. "을(를) 바라보도록 고정되었습니다.")
end

-- 카메라 고정 해제 함수
local function unlockCamera()
	camera.CameraType = Enum.CameraType.Custom
	print("카메라 고정이 해제되었습니다.")
end

-- Killer 팀인지 확인하는 함수
local function isKillerTeam()
	local killerTeam = Teams:FindFirstChild("Killer")
	if killerTeam and player.Team == killerTeam then
		return true
	end
	return false
end

-- 팀에 따라 카메라 설정
local function setupCameraForTeam()
	-- 기존 연결이 있으면 해제
	if cameraConnection then
		cameraConnection:Disconnect()
		cameraConnection = nil
	end

	-- inRound가 true이고 Killer 팀일 때만 카메라 고정
	if inRound.Value and isKillerTeam() then
		print(player.Name .. "은(는) Killer 팀입니다. 카메라를 고정합니다.")

		-- ========== 여기서 원하는 카메라 설정을 적용하세요 ==========

		-- 예시 1: Workspace에 있는 "CameraPart"에 카메라 고정
		task.wait(0.5)
		local cameraPart = workspace:FindFirstChild("CameraPart")
		if cameraPart then
			cameraConnection = lockCameraToPart(cameraPart)
		end

		-- 예시 2: 특정 좌표에 카메라 고정
		-- lockCameraToPosition(Vector3.new(0, 50, 0), Vector3.new(0, 0, 0))

		-- 예시 3: 특정 Part를 바라보도록 설정
		-- local targetPart = workspace:FindFirstChild("LookAtThis")
		-- if targetPart then
		--     lockCameraLookingAtPart(targetPart, 30, 15)
		-- end
	else
		print(
			player.Name
				.. "은(는) Player 팀이거나 라운드가 진행 중이 아닙니다. 일반 카메라를 사용합니다."
		)
		unlockCamera()
	end
end

-- inRound 값이 변경될 때마다 카메라 재설정
inRound.Changed:Connect(function()
	setupCameraForTeam()
end)

-- 캐릭터가 추가될 때 팀 확인
player.CharacterAdded:Connect(function(character)
	task.wait(0.5) -- 팀이 설정될 때까지 잠시 대기
	setupCameraForTeam()
end)

-- 팀이 변경될 때마다 카메라 재설정
player:GetPropertyChangedSignal("Team"):Connect(function()
	setupCameraForTeam()
end)

-- 게임 시작 시 팀 확인 (이미 캐릭터가 있는 경우)
if player.Character then
	task.wait(1) -- 팀이 설정될 때까지 대기
	setupCameraForTeam()
end
