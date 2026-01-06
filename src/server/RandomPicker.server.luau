-- Server Script (ServerScriptService)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")
local killerTeam = Teams:FindFirstChild("Killer")
local playerTeam = Teams:FindFirstChild("Player")

local noIconFound = ""

local function GetPlayerIcon(player)
	if not player or not player.UserId then
		return noIconFound
	end

	local userId = player.UserId
	local thumbType = Enum.ThumbnailType.HeadShot
	local thumbSize = Enum.ThumbnailSize.Size420x420

	local content, isReady
	local ok, err = pcall(function()
		content, isReady = Players:GetUserThumbnailAsync(userId, thumbType, thumbSize)
	end)
	if not ok then
		warn("[서버] GetUserThumbnailAsync 실패:", err)
		return noIconFound
	end

	if isReady and type(content) == "string" and content ~= "" then
		return content
	else
		return noIconFound
	end
end

local function pickRandomPlayer()
	local playerList = Players:GetPlayers()
	if #playerList == 0 then
		warn("[서버] 플레이어가 없습니다.")
		return
	end
	local randomIndex = math.random(1, #playerList)
	local selectedPlayer = playerList[randomIndex]
	print(string.format("[서버] 선택된 플레이어: %s (UserId=%d)", selectedPlayer.Name, selectedPlayer.UserId))

	local plrIcon = GetPlayerIcon(selectedPlayer)

	for row = 1, #playerList do
		if playerList[row] == selectedPlayer then
			playerList[row].Team = killerTeam
			playerList[row].TeamColor = killerTeam.TeamColor
			print(playerList[row].Name .. "을(를) Killer 팀에 배정했습니다.")
		else
			playerList[row].Team = playerTeam
			playerList[row].TeamColor = playerTeam.TeamColor
			print(playerList[row].Name .. "을(를) Player 팀에 배정했습니다.")
		end
	end

	return selectedPlayer, plrIcon
end

-- 전역 함수로 export
_G.pickRandomPlayer = pickRandomPlayer
