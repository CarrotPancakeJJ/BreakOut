local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")

local killerTeam = Teams:WaitForChild("Killer")
local playerTeam = Teams:WaitForChild("Player")

local currentKiller = nil
local currentKillerUserId = nil
local teamAssigned = false
local rouletteStarted = false
local reservationKiller = {}

local purchasingPlayer = nil

local FORCE_KILLER_PRODUCT_ID = 3511107004

-------------------------------------------------
-- RemoteEvents
-------------------------------------------------
local function getOrCreateEvent(name)
	local ev = ReplicatedStorage:FindFirstChild(name)
	if not ev then
		ev = Instance.new("RemoteEvent")
		ev.Name = name
		ev.Parent = ReplicatedStorage
	end
	return ev
end

local function getOrCreateFunction(name)
	local func = ReplicatedStorage:FindFirstChild(name)
	if not func then
		func = Instance.new("RemoteFunction")
		func.Name = name
		func.Parent = ReplicatedStorage
	end
	return func
end

local purchaseFailedEvent = getOrCreateEvent("KillerPurchaseFailed")
local showKillerEvent = getOrCreateEvent("ShowKiller")
local rouletteFinishedEvent = getOrCreateEvent("RouletteFinished")
local hideGuiEvent = getOrCreateEvent("HideKillerGui")
local showGuiEvent = getOrCreateEvent("ShowKillerGui")
local cancelPurchaseEvent = getOrCreateEvent("CancelKillerPurchase")

local requestPurchaseFunc = getOrCreateFunction("RequestKillerPurchase")

-------------------------------------------------
-- GUI 표시/숨김
-------------------------------------------------
local function hideGuiForAll()
	hideGuiEvent:FireAllClients()
	print("모든 플레이어의 구매 GUI 숨김")
end

local function showGuiForAll()
	showGuiEvent:FireAllClients()
	print("모든 플레이어의 구매 GUI 표시")
end

-------------------------------------------------
-- [Studio 테스트용] 구매 시뮬레이션
-------------------------------------------------
local simulateKillerEvent = getOrCreateEvent("SimulateKillerPurchase")

simulateKillerEvent.OnServerEvent:Connect(function(player)
	print("=== [테스트] 구매 시뮬레이션:", player.Name, "===")

	if currentKiller or rouletteStarted then
		print("늦은 구매 - 이미 킬러가 있음")
		table.insert(reservationKiller, player)
		purchasingPlayer = nil
		return
	end

	_G.processKillerPurchase()
	print("=== [테스트] 구매 성공! " .. player.Name .. " 이 킬러로 설정됨 ===")
	currentKiller = player
	currentKillerUserId = player.UserId
	teamAssigned = false
	purchasingPlayer = nil

	hideGuiForAll()
	print("=== [테스트] 구매 처리 완료 ===")
end)

-------------------------------------------------
-- 아이콘 가져오기
-------------------------------------------------
local noIconFound = ""
local function GetPlayerIcon(player)
	if not player or not player.UserId then
		return noIconFound
	end
	local content, isReady
	pcall(function()
		content, isReady =
			Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
	end)
	return (isReady and content) or ""
end

-------------------------------------------------
-- 플레이어가 나갔을 때 잠금 해제
-------------------------------------------------
Players.PlayerRemoving:Connect(function(player)
	if purchasingPlayer == player then
		purchasingPlayer = nil
		print(">>> 구매 중이던 플레이어(" .. player.Name .. ") 퇴장으로 잠금 해제")
	end
end)

-------------------------------------------------
-- 구매 취소 처리
-------------------------------------------------
cancelPurchaseEvent.OnServerEvent:Connect(function(player)
	print("=== 구매 취소됨:", player.Name, "===")

	if purchasingPlayer == player then
		purchasingPlayer = nil
		print(">>> 구매 잠금 해제됨")
	else
		print(">>> 다른 사람이 취소 신호 보냄 (무시)")
	end
end)

-------------------------------------------------
-- 구매 요청 처리
-------------------------------------------------
requestPurchaseFunc.OnServerInvoke = function(player)
	print("=== 구매 요청 받음:", player.Name, "===")

	if currentKiller or purchasingPlayer then
		if currentKillerUserId and player.UserId == currentKillerUserId then
			return false, "이미 구매했습니다!"
		elseif purchasingPlayer and purchasingPlayer ~= player then
			return false, "다른 사람이 구매 진행 중입니다!"
		else
			return false, "이미 킬러가 선택되었습니다!"
		end
	end

	purchasingPlayer = player
	print(">>> 구매 잠금 설정됨 (구매자: " .. player.Name .. ")")

	task.delay(60, function()
		if purchasingPlayer == player and not currentKiller then
			purchasingPlayer = nil
			print(">>> 시간 초과로 잠금 자동 해제")
		end
	end)

	return true, ""
end

-------------------------------------------------
-- Killer 랜덤 선택
-------------------------------------------------
local function pickRandomPlayer()
	print("=== pickRandomPlayer 호출됨 ===")

	if currentKiller then
		print(">>> 이미 킬러가 선택됨 (구매 완료)")
		local icon = GetPlayerIcon(currentKiller)
		showKillerEvent:FireAllClients(currentKiller.Name, icon)
		rouletteStarted = true
	else
		local list = Players:GetPlayers()
		if #list == 0 then
			return
		end
		currentKiller = list[math.random(#list)]
		currentKillerUserId = currentKiller.UserId
		teamAssigned = false
		purchasingPlayer = nil

		local icon = GetPlayerIcon(currentKiller)
		showKillerEvent:FireAllClients(currentKiller.Name, icon)
	end

	hideGuiForAll()
	print("=== 랜덤 킬러 선택 완료: " .. currentKiller.Name .. " ===")
	return
end

-------------------------------------------------
-- 룰렛 종료 → 팀 배정
-------------------------------------------------
rouletteFinishedEvent.OnServerEvent:Connect(function()
	if teamAssigned or not currentKiller then
		return
	end

	teamAssigned = true

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr == currentKiller then
			plr.Team = killerTeam
			plr.TeamColor = killerTeam.TeamColor
		else
			plr.Team = playerTeam
			plr.TeamColor = playerTeam.TeamColor
		end
	end
	print("팀 배정 완료")
end)

-------------------------------------------------
-- 라운드 종료 처리
-------------------------------------------------
local function resetKillerSelection()
	if #reservationKiller > 0 then
		print("예약자가 있습니다!")
		currentKiller = reservationKiller[1]
		currentKillerUserId = reservationKiller[1].UserId
		table.remove(reservationKiller, 1)
		hideGuiForAll()
	else
		print("예약자가 없어요 그냥")
		currentKiller = nil
		currentKillerUserId = nil
		showGuiForAll()
	end
	teamAssigned = false
	rouletteStarted = false
	purchasingPlayer = nil

	print("킬러 선택 초기화 및 GUI 표시")
end

-------------------------------------------------
-- Marketplace 스크립트에서 호출할 함수 export
-------------------------------------------------
-- 킬러 구매 처리 함수 (Marketplace에서 호출)
local function processKillerPurchase(player)
	print("=== 킬러 구매 처리 시작:", player.Name, "===")

	if currentKiller or rouletteStarted then
		print("늦은 구매 - 이미 킬러가 있음")
		table.insert(reservationKiller, player)
		purchasingPlayer = nil
		return false -- 예약 처리
	end

	print("=== 구매 성공! " .. player.Name .. " 이 킬러로 설정됨 ===")
	currentKiller = player
	currentKillerUserId = player.UserId
	teamAssigned = false
	purchasingPlayer = nil

	return true -- 즉시 킬러로 설정 성공
end

_G.processKillerPurchase = processKillerPurchase
_G.pickRandomPlayer = pickRandomPlayer
_G.resetKillerSelection = resetKillerSelection

print("==============================================")
print("술래 선택 시스템 초기화 완료 (Marketplace 연동)")
print("==============================================")
