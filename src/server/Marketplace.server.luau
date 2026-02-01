-- Marketplace.lua (ServerScriptService)
-- 모든 개발자 상품 결제를 중앙에서 처리하는 스크립트

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local soundService = game:GetService("SoundService")
local BGMFolder = soundService:WaitForChild("BGM")
local purchaseSound = BGMFolder:WaitForChild("Purchase")
local donateSound = BGMFolder:WaitForChild("Donate")
local reviveSound = BGMFolder:WaitForChild("Revive")

local Mode = ReplicatedStorage:WaitForChild("Mode")

-- 상품 ID 정의
local REVIVE_PRODUCT_ID = 3516958082
local FORCE_KILLER_PRODUCT_ID = 3511107004

-- Donation 상품 ID와 금액 매핑
local DONATION_PRODUCTS = {
	[3498063120] = 10, -- 예시: 10 Robux 후원
	[3498065337] = 20,
	[3498065336] = 50,
	[3498065350] = 100,
	[3498065348] = 200,
	[3498065328] = 500,
	[3498065360] = 1000,
	[3498065327] = 2000,
	[3498065359] = 5000,
	[3498065325] = 10000,
	-- [상품ID] = 후원금액,
}

-- RemoteEvents 생성/가져오기
local function getOrCreateEvent(name)
	local ev = ReplicatedStorage:FindFirstChild(name)
	if not ev then
		ev = Instance.new("RemoteEvent")
		ev.Name = name
		ev.Parent = ReplicatedStorage
	end
	return ev
end

local hideGuiEvent = getOrCreateEvent("HideKillerGui")

-- [Studio 테스트용] 부활 시뮬레이션 이벤트
local simulateReviveEvent = ReplicatedStorage:WaitForChild("SimulateRevive")
local simulateKillerEvent = ReplicatedStorage:WaitForChild("SimulateKiller")

-- 부활 처리를 위한 함수들 (RoundManager에서 가져옴)
local function getRandomMapSpawn()
	local mapSpawns = {}

	for _, obj in pairs(workspace:GetChildren()) do
		if obj:IsA("BasePart") and obj.Name:match("^MapSpawn") then
			table.insert(mapSpawns, obj)
		end
	end

	local gameObjectsFolder = workspace:FindFirstChild("GameObjects")
	local mapSpawnsFolder = gameObjectsFolder and gameObjectsFolder:FindFirstChild("MapSpawns")
	if mapSpawnsFolder then
		for _, obj in pairs(mapSpawnsFolder:GetChildren()) do
			if obj:IsA("BasePart") and obj.Name:match("^MapSpawn") then
				table.insert(mapSpawns, obj)
			end
		end
	end

	if #mapSpawns == 0 then
		warn("MapSpawn을 찾을 수 없습니다.")
		return workspace:FindFirstChild("MapSpawn")
	end

	return mapSpawns[math.random(1, #mapSpawns)]
end

local function makePlayerVisible(character)
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			if part.Name == "HumanoidRootPart" then
				part.Transparency = 1
			else
				part.Transparency = 0
			end
		else
			pcall(function()
				if part.Transparency then
					part.Transparency = 0
				end
			end)
		end
	end
	print(character.Name .. " 가시화 완료")
end

local function processRevivePurchase(player)
	local InRound = ReplicatedStorage:FindFirstChild("InRound")
	local Status = ReplicatedStorage:FindFirstChild("Status")

	-- 게임 종료 체크 (WINS 문자열 포함 여부)
	local isGameOver = Status and string.find(string.upper(Status.Value), "WINS")
	if InRound and InRound.Value == true and player.Team.Name == "Lobby" and not isGameOver then
		player.Team = Teams:FindFirstChild("Player")
		--player:LoadCharacter()

		local char = player.Character or player.CharacterAdded:Wait()
		local humanoid = char:FindFirstChild("Humanoid")
		-- 스피드 모드일때 속도처리
		if humanoid and Mode.Value == "Speed" then
			humanoid.WalkSpeed = 45
		end
		local humanRoot = char:WaitForChild("HumanoidRootPart")

		local randomSpawn = getRandomMapSpawn()
		if randomSpawn then
			humanRoot.CFrame = randomSpawn.CFrame + Vector3.new(0, 3, 0)
		end

		makePlayerVisible(char)
		humanRoot.Anchored = false

		return true
	end
	return false
end
-- 부활 처리 함수
local function processRevive(player)
	local success = processRevivePurchase(player)
	local Inform = ReplicatedStorage:FindFirstChild("Inform")
	if success then
		if reviveSound then
			reviveSound:Play()
		end

		-- 부활 알림 메시지 표시
		if Inform then
			Inform.Value = player.Name .. " has revived!"
		end
		print("=== 부활 구매 처리 완료: " .. player.Name .. " ===")

		return Enum.ProductPurchaseDecision.PurchaseGranted
	else
		-- 늦은 구매 (예약 처리됨)
		print("늦은 구매 - 예약 처리됨: " .. player.Name)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
end

-- [Studio 테스트용] 부활 시뮬레이션 처리
simulateReviveEvent.OnServerEvent:Connect(function(player)
	print("=== [테스트] 부활 시뮬레이션:", player.Name, "===")

	local success = processRevive(player)
	if success then
		print("=== [테스트] 부활 성공! ===")
	else
		print("=== [테스트] 부활 실패 (조건 미달) ===")
	end
end)

-- 킬러 강제 구매 처리 함수
local function processKiller(player)
	local Inform = ReplicatedStorage:FindFirstChild("Inform")

	-- _G에서 킬러 선택 관련 함수들 가져오기
	if not _G.processKillerPurchase then
		warn("킬러 구매 처리 함수가 아직 로드되지 않았습니다!")
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local success = _G.processKillerPurchase(player)

	if success then
		print("=== 킬러 구매 처리 완료: " .. player.Name .. " ===")
		hideGuiEvent:FireAllClients()

		if purchaseSound then
			purchaseSound:Play()
		end

		-- 킬러 구매 알림 메시지 표시
		if Inform then
			Inform.Value = player.Name .. " purchased killer item!"
		end

		return Enum.ProductPurchaseDecision.PurchaseGranted
	else
		-- 늦은 구매 (예약 처리됨)
		print("늦은 구매 - 예약 처리됨: " .. player.Name)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
end

-------------------------------------------------
-- [Studio 테스트용] 킬러 구매 시뮬레이션
-------------------------------------------------

simulateKillerEvent.OnServerEvent:Connect(function(player)
	local success = processKiller(player)
	if success then
		print("[테스트] 킬러 아이템 구매 성공")
	else
		print("=== [테스트] 킬러 아이템 구매 실패 (조건 미달) ===")
	end
end)

-- Donation 처리 함수
local function processDonation(player, receiptInfo)
	local donationAmount = DONATION_PRODUCTS[receiptInfo.ProductId]

	if not donationAmount then
		warn("알 수 없는 후원 상품:", receiptInfo.ProductId)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	print("=== 후원 처리: " .. player.Name .. " - " .. donationAmount .. " Robux ===")

	-- ⭐ 리더보드의 DataStoreName과 동일하게 사용
	local DONATION_DATASTORE_NAME = "DonateBoardDataStore_V1"

	local DataStoreService = game:GetService("DataStoreService")
	local DonationDataStore = DataStoreService:GetOrderedDataStore(DONATION_DATASTORE_NAME)

	pcall(function()
		local currentDonation = DonationDataStore:GetAsync(player.UserId) or 0
		local newTotal = currentDonation + donationAmount
		DonationDataStore:SetAsync(player.UserId, newTotal)

		print("후원 저장 완료:", player.Name, "총액:", newTotal)
	end)

	-- 알림 메시지
	local Inform = ReplicatedStorage:FindFirstChild("Inform")
	if Inform then
		Inform.Value = "💝 " .. player.Name .. " donated " .. donationAmount .. " Robux!"
	end
	if donateSound then
		donateSound:Play()
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- 중앙 결제 처리 함수
MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)

	-- 플레이어가 없으면 처리 보류
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	print("=== 결제 처리 시작 ===")
	print("플레이어:", player.Name)
	print("상품 ID:", receiptInfo.ProductId)

	-- 부활 아이템 처리
	if receiptInfo.ProductId == REVIVE_PRODUCT_ID then
		return processRevive(player)
	end

	-- 킬러 강제 구매 처리
	if receiptInfo.ProductId == FORCE_KILLER_PRODUCT_ID then
		return processKiller(player)
	end

	-- ⭐ 이 부분이 추가됨!
	-- Donation 상품 처리
	if DONATION_PRODUCTS[receiptInfo.ProductId] then
		return processDonation(player, receiptInfo)
	end

	-- 알 수 없는 상품 (미래 확장용)
	warn("알 수 없는 상품 ID:", receiptInfo.ProductId)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

print("==============================================")
print("중앙 결제 처리 시스템 초기화 완료")
print("부활 상품 ID:", REVIVE_PRODUCT_ID)
print("킬러 강제 상품 ID:", FORCE_KILLER_PRODUCT_ID)
print("==============================================")
