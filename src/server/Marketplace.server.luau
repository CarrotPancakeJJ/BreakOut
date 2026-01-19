-- Marketplace.lua (ServerScriptService)
-- 모든 개발자 상품 결제를 중앙에서 처리하는 스크립트

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local soundService = game:GetService("SoundService")
local BGMFolder = soundService:WaitForChild("BGM")
local purchaseSound = BGMFolder:WaitForChild("Purchase")
local reviveSound = BGMFolder:WaitForChild("Revive")

-- 상품 ID 정의
local REVIVE_PRODUCT_ID = 3516958082
local FORCE_KILLER_PRODUCT_ID = 3511107004

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

-- 부활 처리 함수
local function processRevive(player)
	local InRound = ReplicatedStorage:FindFirstChild("InRound")
	local Status = ReplicatedStorage:FindFirstChild("Status")
	local Inform = ReplicatedStorage:FindFirstChild("Inform")

	-- 게임 종료 체크 (WINS 문자열 포함 여부)
	local isGameOver = Status and string.find(string.upper(Status.Value), "WINS")

	if InRound and InRound.Value == true and player.Team.Name == "Lobby" and not isGameOver then
		-- 부활 시작 (죽음 무시 플래그 설정)
		if _G.setPlayerReviving then
			_G.setPlayerReviving(player.UserId, true)
		end

		player.Team = Teams:FindFirstChild("Player")
		--player:LoadCharacter()

		local char = player.Character or player.CharacterAdded:Wait()
		local humanRoot = char:WaitForChild("HumanoidRootPart")

		local randomSpawn = getRandomMapSpawn()
		if randomSpawn then
			humanRoot.CFrame = randomSpawn.CFrame + Vector3.new(0, 3, 0)
		end

		makePlayerVisible(char)
		humanRoot.Anchored = false

		-- 부활 완료 (죽음 무시 플래그 해제)
		if _G.setPlayerReviving then
			_G.setPlayerReviving(player.UserId, false)
		end

		if reviveSound then
			reviveSound:Play()
		end

		-- 부활 알림 메시지 표시
		if Inform then
			Inform.Value = player.Name .. " has revived!"
		end

		return true
	end
	return false
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
		local success = processRevive(player)
		if success then
			print(player.Name .. " 부활 결제 완료!")
			return Enum.ProductPurchaseDecision.PurchaseGranted
		else
			warn(player.Name .. " 부활 조건 미달로 결제 보류")
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
	end

	-- 킬러 강제 구매 처리
	if receiptInfo.ProductId == FORCE_KILLER_PRODUCT_ID then
		return processKiller(player)
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
