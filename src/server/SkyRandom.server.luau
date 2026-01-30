local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Skybox들이 들어있는 폴더 참조
local skyFolder = ReplicatedStorage:WaitForChild("Skyboxes")
local allSkies = skyFolder:GetChildren() -- 폴더 안의 모든 Sky 객체를 리스트로 가져옴

local function SkyRandomSelect()
	if #allSkies > 0 then
		-- 1. 기존 Lighting에 있는 Sky 객체 삭제 (중복 방지)
		for _, child in pairs(Lighting:GetChildren()) do
			if child:IsA("Sky") then
				child:Destroy()
			end
		end

		-- 2. 랜덤으로 하나 선택
		local randomIndex = math.random(1, #allSkies)
		local selectedSky = allSkies[randomIndex]:Clone() -- 원본 보존을 위해 복제

		-- 3. Lighting에 배치
		selectedSky.Parent = Lighting

		print("선택된 하늘: " .. selectedSky.Name)
	else
		warn("Skyboxes 폴더가 비어있습니다!")
	end
end

SkyRandomSelect()

_G.skyRandomSelect = SkyRandomSelect
