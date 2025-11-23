-- -- LocalScript (StarterPlayerScripts)
-- local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local Players = game:GetService("Players")
-- local Player = Players.LocalPlayer

-- local PickTagEvent = ReplicatedStorage:WaitForChild("PickTagEvent") -- RemoteEvent

-- -- GUI 경로: PlayerGui 아래의 ScreenGui (이름은 실제 프로젝트에 맞춰 바꿔주세요)
-- local RPGui = Player:WaitForChild("PlayerGui"):WaitForChild("ScreenGui")
-- local RPPlrIcon = RPGui:WaitForChild("plrIcon") -- ImageLabel 이름 확인
-- local RPPlrName = RPGui:WaitForChild("plrName")

-- -- 룰렛이 실행 중인지 체크하는 플래그
-- local rouletteRunning = false

-- -- 서버에서 이벤트가 올 때 처리
-- PickTagEvent.OnClientEvent:Connect(function(tagName, tagIconUrl)
-- 	-- 안전 검사: ImageLabel이 존재하는지와 URL이 문자열인지 확인
-- 	if RPPlrIcon and type(tagIconUrl) == "string" then
-- 		RPPlrIcon.Image = tagIconUrl
-- 	else
-- 		warn("[클라이언트] 이미지 또는 URL이 유효하지 않습니다:", tagIconUrl)
-- 	end

-- 	-- (선택) 이름 표시가 있으면 업데이트
-- 	local nameLabel = RPGui:FindFirstChild("plrName")
-- 	if nameLabel and nameLabel:IsA("TextLabel") then
-- 		nameLabel.Text = tagName
-- 	end

-- 	print(
-- 		string.format("[클라이언트] 새로운 술래 %s의 아이콘이 표시되었습니다.", tostring(tagName))
-- 	)
-- end)

-- -- local testUserIds = { 1, 2, 3, 4, 5 }

-- -- local function getRandomPlayerIcon()
-- -- 	local id = testUserIds[math.random(1, #testUserIds)]
-- -- 	local content, ready =
-- -- 		Players:GetUserThumbnailAsync(id, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)

-- -- 	if ready then
-- -- 		return content
-- -- 	else
-- -- 		return ""
-- -- 	end
-- -- end

-- -- 랜덤 플레이어 아이콘과 이름 가져오기
-- local function getRandomPlayerIconAndName()
-- 	local list = Players:GetPlayers()
-- 	if #list == 0 then
-- 		return "", "NoPlayer" -- 플레이어 없으면 빈 아이콘, 이름 "NoPlayer" 반환
-- 	end

-- 	local randomPlr = list[math.random(1, #list)]

-- 	-- 아이콘 가져오기
-- 	local content, ready =
-- 		Players:GetUserThumbnailAsync(randomPlr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)

-- 	local icon = (ready and type(content) == "string") and content or ""
-- 	local name = randomPlr.Name or "Unknown"

-- 	return icon, name
-- end

-- -- 룰렛 시작 함수
-- local function startRoulette()
-- 	rouletteRunning = true

-- 	task.spawn(function()
-- 		while rouletteRunning do
-- 			local icon, name = getRandomPlayerIconAndName()
-- 			RPPlrIcon.Image = icon
-- 			RPPlrName.Text = name
-- 			task.wait(0.05) -- 돌리는 속도
-- 		end
-- 	end)
-- end

-- -- 서버에서 최종 술래 결과가 오면 멈춤
-- PickTagEvent.OnClientEvent:Connect(function(tagName, tagIconUrl)
-- 	-- 1) 먼저 룰렛 실행
-- 	startRoulette()

-- 	-- 2) 2~3초 후 실제 술래 아이콘으로 멈추기
-- 	task.delay(math.random(2, 3), function()
-- 		rouletteRunning = false
-- 		RPPlrIcon.Image = tagIconUrl
-- 		print("[클라이언트] 최종 술래:", tagName)
-- 	end)
-- end)
