local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")

local killerTeam = Teams:WaitForChild("Killer")
local playerTeam = Teams:WaitForChild("Player")

-------------------------------------------------
-- RemoteEvents
-------------------------------------------------

-- 룰렛 시작 (기존)
local showKillerEvent = ReplicatedStorage:FindFirstChild("ShowKiller")
if not showKillerEvent then
	showKillerEvent = Instance.new("RemoteEvent")
	showKillerEvent.Name = "ShowKiller"
	showKillerEvent.Parent = ReplicatedStorage
end

-- 룰렛 종료 (신규)
local rouletteFinishedEvent = ReplicatedStorage:FindFirstChild("RouletteFinished")
if not rouletteFinishedEvent then
	rouletteFinishedEvent = Instance.new("RemoteEvent")
	rouletteFinishedEvent.Name = "RouletteFinished"
	rouletteFinishedEvent.Parent = ReplicatedStorage
end

-------------------------------------------------
-- 아이콘 가져오기 (기존 유지)
-------------------------------------------------

local noIconFound = ""

local function GetPlayerIcon(player)
	if not player or not player.UserId then
		return noIconFound
	end

	local content, isReady
	local ok, err = pcall(function()
		content, isReady =
			Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
	end)

	if ok and isReady and type(content) == "string" then
		return content
	end

	return noIconFound
end

-------------------------------------------------
-- Killer 선택 (팀 배정 X)
-------------------------------------------------

local currentKiller = nil
local teamAssigned = false

local function pickRandomPlayer()
	local playerList = Players:GetPlayers()
	if #playerList == 0 then
		warn("[서버] 플레이어가 없습니다.")
		return
	end

	currentKiller = playerList[math.random(1, #playerList)]
	teamAssigned = false

	print(string.format("[서버] Killer 후보 선택: %s (UserId=%d)", currentKiller.Name, currentKiller.UserId))

	local plrIcon = GetPlayerIcon(currentKiller)

	-- 🔥 여기서는 팀 배정 안 함
	showKillerEvent:FireAllClients(currentKiller.Name, plrIcon)
	print("[서버] 룰렛 시작 알림 전송")

	return currentKiller, plrIcon
end

-------------------------------------------------
-- 룰렛 종료 → 팀 배정
-------------------------------------------------

rouletteFinishedEvent.OnServerEvent:Connect(function(playerWhoFired)
	if teamAssigned then
		return
	end
	if not currentKiller then
		return
	end

	teamAssigned = true

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr == currentKiller then
			plr.Team = killerTeam
			plr.TeamColor = killerTeam.TeamColor
			print(plr.Name .. " → Killer 팀")
		else
			plr.Team = playerTeam
			plr.TeamColor = playerTeam.TeamColor
			print(plr.Name .. " → Player 팀")
		end
	end

	print("[서버] 팀 배정 완료 (트리거:", playerWhoFired.Name, ")")
end)

-------------------------------------------------
-- 전역 함수 export (기존 유지)
-------------------------------------------------

_G.pickRandomPlayer = pickRandomPlayer
