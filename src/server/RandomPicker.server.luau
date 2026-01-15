local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")
local MarketplaceService = game:GetService("MarketplaceService")

local killerTeam = Teams:WaitForChild("Killer")
local playerTeam = Teams:WaitForChild("Player")

local currentKiller = nil
local currentKillerUserId = nil
local teamAssigned = false
local rouletteStarted = false
local reservationKiller = {}

-- [수정 1] 단순 true/false가 아니라 '누가' 구매 중인지 저장하는 변수로 변경
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
-- simulatePurchaseEvent는 더 이상 필요 없어서 삭제해도 됨

-- 구매 시도 함수
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
local simulatePurchaseEvent = getOrCreateEvent("SimulateKillerPurchase")

simulatePurchaseEvent.OnServerEvent:Connect(function(player)
	print("=== [테스트] 구매 시뮬레이션:", player.Name, "===")

	-- 실제 ProcessReceipt와 동일한 로직
	if currentKiller or rouletteStarted then
		print("늦은 구매 - 이미 킬러가 있음")
		table.insert(reservationKiller, player)
		purchasingPlayer = nil
		return
	end

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
-- [중요] 플레이어가 나갔을 때 잠금 해제 (추가됨!)
-------------------------------------------------
Players.PlayerRemoving:Connect(function(player)
	-- 만약 구매창 띄우고 있던 놈이 나갔으면?
	if purchasingPlayer == player then
		purchasingPlayer = nil -- 잠금 해제!
		print(">>> 구매 중이던 플레이어(" .. player.Name .. ") 퇴장으로 잠금 해제")
	end
end)

-------------------------------------------------
-- 구매 취소 처리
-------------------------------------------------
cancelPurchaseEvent.OnServerEvent:Connect(function(player)
	print("=== 구매 취소됨:", player.Name, "===")

	-- 구매 취소한 사람이 현재 잠금 건 사람이 맞는지 확인
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

	-- 이미 킬러가 있거나, 누군가(purchasingPlayer)가 구매 창을 보고 있다면?
	if currentKiller or purchasingPlayer then
		if currentKillerUserId and player.UserId == currentKillerUserId then
			return false, "이미 구매했습니다!"
		elseif purchasingPlayer and purchasingPlayer ~= player then
			return false, "다른 사람이 구매 진행 중입니다!"
		else
			return false, "이미 킬러가 선택되었습니다!"
		end
	end

	-- [수정 2] 구매 잠금: 이제 '누가' 잠갔는지 기록함
	purchasingPlayer = player
	print(">>> 구매 잠금 설정됨 (구매자: " .. player.Name .. ")")

	-- [안전장치] 혹시 모르니 60초 뒤에도 이 사람이 결제 안하면 강제 잠금 해제
	task.delay(60, function()
		if purchasingPlayer == player and not currentKiller then
			purchasingPlayer = nil
			print(">>> 시간 초과로 잠금 자동 해제")
		end
	end)

	-- 구매 가능
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
		purchasingPlayer = nil -- 혹시 모를 잠금 해제

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
	purchasingPlayer = nil -- 잠금 초기화

	print("킬러 선택 초기화 및 GUI 표시")
end

-------------------------------------------------
-- 아이템 구매 처리 (ProcessReceipt 하나로 통합)
-------------------------------------------------
MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)

	print("레시피")
	-- 플레이어가 없으면(구매하고 바로 나감) 처리 보류
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if receiptInfo.ProductId ~= FORCE_KILLER_PRODUCT_ID then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	print("=== 구매 처리 시작:", player.Name, "===")

	-- 아주 드문 경우지만, 결제하는 사이에 랜덤 픽이 되어버렸거나 다른 사람이 샀다면?
	if currentKiller or rouletteStarted then
		print("늦은 구매 - 이미 킬러가 있음")
		table.insert(reservationKiller, player)
		-- 돈은 먹지만 킬러는 안 시켜줌 (어쩔 수 없음, 로직상)
		purchasingPlayer = nil
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- 구매 성공 처리
	print("=== 구매 성공! " .. player.Name .. " 이 킬러로 설정됨 ===")
	currentKiller = player
	currentKillerUserId = player.UserId
	teamAssigned = false

	-- [수정 3] 구매 완료됐으니 잠금 해제 (변수 비우기)
	purchasingPlayer = nil

	hideGuiForAll()
	print("=== 구매 처리 완료 ===")

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-------------------------------------------------
-- 전역 함수 export
-------------------------------------------------
_G.pickRandomPlayer = pickRandomPlayer
_G.resetKillerSelection = resetKillerSelection

print("==============================================")
print("술래 선택 시스템 초기화 완료 (안전모드)")
print("==============================================")
