local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local killerTeam = Teams:FindFirstChild("Killer")
local inRound = ReplicatedStorage:WaitForChild("InRound")

-- inRound 변경 감지
inRound.Changed:Connect(function()
	if inRound.Value == false then
		-- 게임 종료: 모든 Killer Anchored 해제
		for _, player in pairs(Players:GetPlayers()) do
			if player.Team == killerTeam then
				local character = player.Character
				if character then
					local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
					if humanoidRootPart then
						humanoidRootPart.Anchored = false
						print(player.Name .. " (Killer) Anchored 해제")
					end
				end
			end
		end
	end
end)

-- 플레이어가 나가거나 죽었을 때 정리
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")

		humanoid.Died:Connect(function()
			-- 죽으면 Anchored 해제
			local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
			if humanoidRootPart then
				humanoidRootPart.Anchored = false
			end
		end)
	end)
end)
