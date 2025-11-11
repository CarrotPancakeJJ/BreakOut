local intermission = 10
local roundLength = 15

local inRound = game.ReplicatedStorage.InRound
local status = game.ReplicatedStorage.Status

inRound.Changed:Connect(function()
	if inRound.Value == true then
		for i, plr in pairs(game.Players:GetChildren()) do
			local char = plr.Character
			local humanRoot = char:WaitForChild("HumanoidRootPart")

			humanRoot.CFrame = game.Workspace.MapSpawn.CFrame
		end
	else
		for i, plr in pairs(game.Players:GetChildren()) do
			local char = plr.Character
			local humanRoot = char:WaitForChild("HumanoidRootPart")

			humanRoot.CFrame = game.Workspace.LobbySpawn.CFrame
		end
	end
end)

local function round()
	while true do
		inRound.Value = false

		for i = intermission, 0, -1 do
			status.Value = "Game will start in " .. i .. " seconds"
			wait(1)
		end

		inRound.Value = true

		for i = roundLength, 0, -1 do
			status.Value = "Game will end in " .. i .. " seconds"
			wait(1)
		end
	end
end

spawn(round)
