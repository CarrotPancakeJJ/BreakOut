local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

local lobbyTeam = Teams:FindFirstChild("Lobby")

Players.PlayerAdded:Connect(function(player)
	-- 모든 플레이어를 처음엔 Lobby 팀으로
	if lobbyTeam then
		player.Team = lobbyTeam
		player.TeamColor = lobbyTeam.TeamColor
		print(player.Name .. "을(를) Lobby 팀에 배정했습니다.")
	else
		warn("Lobby 팀을 찾을 수 없습니다!")
	end
end)
