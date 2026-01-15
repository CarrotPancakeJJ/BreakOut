local Players = game:GetService("Players")
local lobbyObjects = workspace:WaitForChild("LobbyObjects")
local happyBall = lobbyObjects:WaitForChild("HappyBall")
local howtoplay = lobbyObjects:WaitForChild("HowToPlay")
local outField = lobbyObjects:WaitForChild("OutField")
-- HappyBall 안의 사운드
local oofSound = happyBall:WaitForChild("OOF")

-- 쿨타임
local playerCooldowns = {}
local happyBallTeleportCooldown = false
local happyBallSoundCooldown = false
local howtoplayTeleportCooldown = false

------------------------------------------------
-- 로비 스폰 랜덤
------------------------------------------------
local function getRandomLobbySpawn()
	local spawnsFolder = lobbyObjects:WaitForChild("LobbySpawns")
	local spawns = spawnsFolder:GetChildren()

	if #spawns == 0 then
		return nil
	end

	return spawns[math.random(1, #spawns)]
end

------------------------------------------------
-- 텔레포트 함수
------------------------------------------------
local function teleportToLobby(part)
	if not part or not part:IsA("BasePart") then
		return
	end

	local lobbySpawn = getRandomLobbySpawn()
	if not lobbySpawn then
		warn("LobbySpawn을 찾을 수 없습니다!")
		return
	end

	part.Velocity = Vector3.zero
	part.AssemblyLinearVelocity = Vector3.zero
	part.CFrame = lobbySpawn.CFrame + Vector3.new(0, 3, 0)
end

------------------------------------------------
-- OutField 충돌 처리
------------------------------------------------
outField.Touched:Connect(function(hit)
	local character = hit.Parent

	-- 플레이어
	if character then
		local player = Players:GetPlayerFromCharacter(character)
		if player and character:FindFirstChild("HumanoidRootPart") then
			if not playerCooldowns[player.UserId] then
				playerCooldowns[player.UserId] = true
				teleportToLobby(character.HumanoidRootPart)

				task.delay(0.1, function()
					playerCooldowns[player.UserId] = nil
				end)
			end
		end
	end

	-- HappyBall
	if hit == happyBall then
		if not happyBallTeleportCooldown then
			happyBallTeleportCooldown = true
			teleportToLobby(happyBall)

			task.delay(0.1, function()
				happyBallTeleportCooldown = false
			end)
		end
	end

	-- HappyBall
	if hit == howtoplay then
		if not howtoplayTeleportCooldown then
			howtoplayTeleportCooldown = true
			teleportToLobby(howtoplay)

			task.delay(0.1, function()
				howtoplayTeleportCooldown = false
			end)
		end
	end
end)

------------------------------------------------
-- HappyBall ↔ 플레이어 충돌 시 사운드 (3D)
------------------------------------------------
happyBall.Touched:Connect(function(hit)
	local character = hit.Parent
	if not character then
		return
	end

	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end

	if happyBallSoundCooldown then
		return
	end
	happyBallSoundCooldown = true

	oofSound:Play() -- 🔊 공 위치에서 3D 사운드 재생

	task.delay(3, function()
		happyBallSoundCooldown = false
	end)
end)
