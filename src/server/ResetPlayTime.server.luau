-- local DataStoreService = game:GetService("DataStoreService")
-- local Players = game:GetService("Players")

-- -- [[ 설정 구간: Settings 스크립트 내용을 보고 똑같이 적으세요 ]] --
-- local CONFIG_DATA_STORE_NAME = "TopTimePlayed_V2" -- Settings의 DATA_STORE 값
-- local CONFIG_STAT_NAME = "TimePlayed" -- Settings의 NAME_OF_STAT 값 (없으면 "" 빈칸)

-- -- 초기화할 유저 닉네임
-- local TARGET_USERNAME = "GreenTeaExpress"

-- --------------------------------------------------------------

-- local DataStore = DataStoreService:GetOrderedDataStore(CONFIG_DATA_STORE_NAME)

-- local function ResetTimePlayed()
-- 	-- 1. 유저 아이디 가져오기
-- 	local success, userId = pcall(function()
-- 		return Players:GetUserIdFromNameAsync(TARGET_USERNAME)
-- 	end)

-- 	if not success or not userId then
-- 		warn("❌ 유저를 찾을 수 없습니다: " .. TARGET_USERNAME)
-- 		return
-- 	end

-- 	print("🔄 [" .. TARGET_USERNAME .. "] 플레이 시간 초기화 시도 중...")

-- 	-- 2. 키(Key) 생성
-- 	-- 원본 스크립트 로직: self._dataStoreStatName .. player.UserId
-- 	local key = CONFIG_STAT_NAME .. userId

-- 	-- 3. 접속 중인 유저 처리 (매우 중요)
-- 	-- 플레이어가 게임 중이면 메모리에 시간이 계속 카운트되고 있으므로,
-- 	-- DataStore를 지워도 나갈 때 다시 저장되어버림. 이를 방지하기 위해 인게임 수치도 0으로 만듦.
-- 	local onlinePlayer = Players:FindFirstChild(TARGET_USERNAME)
-- 	if onlinePlayer then
-- 		-- 리더스탯(Leaderstats) 찾아서 0으로 초기화
-- 		local leaderstats = onlinePlayer:FindFirstChild("leaderstats")
-- 		if leaderstats then
-- 			-- Settings의 NAME_LEADERSTATS 값을 몰라도, 보통 숫자값(NumberValue/IntValue)을 찾음
-- 			for _, child in pairs(leaderstats:GetChildren()) do
-- 				if child:IsA("NumberValue") or child:IsA("IntValue") then
-- 					child.Value = 0
-- 					print("✅ 접속 중인 플레이어의 리더스탯(" .. child.Name .. ")을 0으로 변경함.")
-- 				end
-- 			end
-- 		end
-- 	end

-- 	-- 4. 데이터 삭제 (RemoveAsync)
-- 	local removeSuccess, err = pcall(function()
-- 		DataStore:RemoveAsync(key)
-- 	end)

-- 	if removeSuccess then
-- 		print("--------------------------------------------------")
-- 		print("✅ [성공] 플레이 시간 데이터 삭제 완료!")
-- 		print("   - 대상: " .. TARGET_USERNAME)
-- 		print("   - 삭제된 키: " .. key)
-- 		print("   (리더보드 갱신 주기 후 목록에서 사라집니다)")
-- 		print("--------------------------------------------------")
-- 	else
-- 		warn("❌ [실패] 데이터 삭제 중 오류 발생: " .. tostring(err))
-- 	end
-- end

-- ResetTimePlayed()
