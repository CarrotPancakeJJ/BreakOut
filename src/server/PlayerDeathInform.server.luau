-- PlayerDeathTracker.lua (ServerScriptService)
-- Player 팀원이 죽으면 탈락 메시지 표시
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InRound = ReplicatedStorage:WaitForChild("InRound")
local Status = ReplicatedStorage:WaitForChild("Status")
local Inform = ReplicatedStorage:WaitForChild("Inform")

-- 플레이어가 추가될 때마다 설정
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")

		-- 플레이어가 죽었을 때
		humanoid.Died:Connect(function()
			-- 게임이 진행 중이고, Player 팀일 때만
			if InRound.Value and player.Team and player.Team.Name == "Player" then
				-- 현재 Status가 WINS를 포함하지 않을 때만 (게임 종료 아닐 때)
				if not string.find(string.upper(Status.Value), "WINS") then
					-- 탈락 메시지 표시
					Inform.Value = "💀 " .. player.Name .. " Eliminated!"
				end
			end
		end)
	end)
end)

-- 이미 접속한 플레이어들도 설정
for _, player in pairs(Players:GetPlayers()) do
	if player.Character then
		local humanoid = player.Character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.Died:Connect(function()
				if InRound.Value and player.Team and player.Team.Name == "Player" then
					if not string.find(string.upper(Status.Value), "WINS") then
						Inform.Value = "💀 " .. player.Name .. " Eliminated!"
					end
				end
			end)
		end
	end

	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")

		humanoid.Died:Connect(function()
			if InRound.Value and player.Team and player.Team.Name == "Player" then
				if not string.find(string.upper(Status.Value), "WINS") then
					Inform.Value = "💀 " .. player.Name .. " eliminated!"
				end
			end
		end)
	end)
end

print("플레이어 탈락 알림 시스템 초기화 완료")
