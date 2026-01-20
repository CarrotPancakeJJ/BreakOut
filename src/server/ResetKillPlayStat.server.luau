-- local DataStoreService = game:GetService("DataStoreService")
-- local Players = game:GetService("Players")

-- -- StatManager 코드에 있는 이름과 정확히 일치해야 합니다.
-- local KILLER_DS_NAME = "KillerWinsLeaderboard"
-- local PLAYER_DS_NAME = "PlayerWinsLeaderboard"

-- -- DataStore 불러오기 (OrderedDataStore 사용 중이므로 동일하게 가져옴)
-- local killerDS = DataStoreService:GetOrderedDataStore(KILLER_DS_NAME)
-- local playerDS = DataStoreService:GetOrderedDataStore(PLAYER_DS_NAME)

-- -- ⚠️ 초기화할 유저의 정확한 아이디(Username)를 입력하세요.
-- local TARGET_USERNAME = "GreenTeaExpress"

-- local function ResetPlayerStats()
-- 	-------------------------------------------------------
-- 	-- 1. 유저 ID 가져오기
-- 	-------------------------------------------------------
-- 	local success, userId = pcall(function()
-- 		return Players:GetUserIdFromNameAsync(TARGET_USERNAME)
-- 	end)

-- 	if not success or not userId then
-- 		warn("❌ 유저를 찾을 수 없습니다: " .. TARGET_USERNAME)
-- 		warn("아이디 오타를 확인해주세요.")
-- 		return
-- 	end

-- 	print("🔄 초기화 시작... 대상: " .. TARGET_USERNAME .. " (ID: " .. userId .. ")")

-- 	-------------------------------------------------------
-- 	-- 2. 현재 게임 접속 중인지 확인 (가장 중요!)
-- 	-------------------------------------------------------
-- 	-- 접속 중이라면 DataStore만 지워봤자 나갈 때 다시 현재 점수로 덮어씌워짐.
-- 	-- 따라서 접속 중인 유저의 눈에 보이는 점수(leaderstats)도 0으로 만들어야 함.

-- 	local onlinePlayer = Players:FindFirstChild(TARGET_USERNAME)

-- 	if onlinePlayer then
-- 		local leaderstats = onlinePlayer:FindFirstChild("leaderstats")
-- 		if leaderstats then
-- 			if leaderstats:FindFirstChild("Killer Wins") then
-- 				leaderstats["Killer Wins"].Value = 0
-- 			end
-- 			if leaderstats:FindFirstChild("Player Wins") then
-- 				leaderstats["Player Wins"].Value = 0
-- 			end
-- 			print("✅ [접속 중] 해당 플레이어의 인게임 leaderstats를 0으로 변경했습니다.")
-- 		end
-- 	end

-- 	-------------------------------------------------------
-- 	-- 3. DataStore에서 영구 삭제
-- 	-------------------------------------------------------
-- 	-- RemoveAsync를 쓰면 아예 기록이 사라집니다. (리더보드에서 사라짐)
-- 	-- 만약 0점으로 남기고 싶다면 SetAsync(userId, 0)을 쓰세요.

-- 	local s1, e1 = pcall(function()
-- 		killerDS:RemoveAsync(tostring(userId))
-- 	end)

-- 	local s2, e2 = pcall(function()
-- 		playerDS:RemoveAsync(tostring(userId))
-- 	end)

-- 	if s1 and s2 then
-- 		print("--------------------------------------------------")
-- 		print("✅ [성공] 모든 데이터 스토어 기록 삭제 완료!")
-- 		print("   - KillerWinsLeaderboard 삭제됨")
-- 		print("   - PlayerWinsLeaderboard 삭제됨")
-- 		print("--------------------------------------------------")
-- 	else
-- 		warn("❌ [실패] 데이터 삭제 중 오류 발생")
-- 		if not s1 then
-- 			warn("KillerDS 오류: " .. tostring(e1))
-- 		end
-- 		if not s2 then
-- 			warn("PlayerDS 오류: " .. tostring(e2))
-- 		end
-- 	end
-- end

-- ResetPlayerStats()
