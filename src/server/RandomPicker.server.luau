-- Server Script (ServerScriptService 권장)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")
local killerTeam = Teams:FindFirstChild("Killer")
local playerTeam = Teams:FindFirstChild("Player")

-- PickTagEvent는 ReplicatedStorage 안에 RemoteEvent로 존재해야 합니다.
local PickTagEvent = ReplicatedStorage:WaitForChild("PickTagEvent")

local noIconFound = "" -- 빈 문자열 또는 기본 아이콘 rbxassetid://123456 를 넣어두세요

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
		else
			playerList[row].Team = playerTeam
			playerList[row].TeamColor = playerTeam.TeamColor
		end
	end
end

-- ===== 테스트용: 게임 시작 시 또는 5초마다 랜덤 선택 (개발용) =====
-- 서버에서 바로 테스트하려면 아래 호출을 사용하세요. 실제 게임에선 라운드 시작/종료에 맞춰 호출.
wait(2)
pickRandomPlayer()

-- 또는 주기적으로 테스트하려면:
-- while true do
--     wait(10)
--     pickRandomPlayer()
-- end
