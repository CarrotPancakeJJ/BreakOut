local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")

local BADGE_ID = 3088079574284595

local function awardBadge(player)
	local userId = player.UserId

	-- 1. 플레이어가 배지를 이미 가지고 있는지 확인
	local success, hasBadge = pcall(function()
		return BadgeService:UserHasBadgeAsync(userId, BADGE_ID)
	end)

	if success then
		if not hasBadge then
			-- 2. 배지가 없다면 지급 시도
			local awardSuccess, result = pcall(function()
				return BadgeService:AwardBadge(userId, BADGE_ID)
			end)

			if awardSuccess then
				print(player.Name .. "님에게 배지를 지급했습니다!")
			else
				warn("배지 지급 실패: " .. tostring(result))
			end
		else
			print(player.Name .. "님은 이미 배지를 가지고 있습니다.")
		end
	else
		warn("배지 확인 중 오류 발생: " .. tostring(hasBadge))
	end
end

-- 플레이어가 입장할 때 실행
Players.PlayerAdded:Connect(awardBadge)
