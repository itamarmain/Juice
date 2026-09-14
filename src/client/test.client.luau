local plr = game.Players.LocalPlayer

local replicatedStorage = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local campackage = require(replicatedStorage:WaitForChild("Shared"):WaitForChild("JuicePackage"):WaitForChild("Camera"))
local camObj = campackage.new()
local char = plr.Character or plr.CharacterAdded:Wait()

UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.Q then
        camObj:Shake(1, 1, 10)
    elseif input.KeyCode == Enum.KeyCode.E then
        camObj:SetFollowedModel(char)
        camObj:SetOffsetCFrame(CFrame.new(3,5,10))
        camObj:SetStiffness(10)
        camObj:SetLookAtProvider(function()
            local hrp = Workspace.Rig:FindFirstChild("HumanoidRootPart")
            return hrp.CFrame.Position
        end)
        camObj:EnableSmooth()
    end
end)