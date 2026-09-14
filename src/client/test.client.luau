local plr = game.Players.LocalPlayer

local replicatedStorage = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local campackage = require(replicatedStorage:WaitForChild("Shared"):WaitForChild("JuicePackage"):WaitForChild("Camera"))
task.wait(1)
local camObj = campackage.new()
local char = plr.Character or plr.CharacterAdded:Wait()

UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.Q then
        camObj:CamShake(1, 1, 10)
    elseif input.KeyCode == Enum.KeyCode.E then
        camObj:CamImpulse(Vector3.new(0, 0, 1), 5)
    elseif input.KeyCode == Enum.KeyCode.R then
        camObj:CamFOVPunch(20, 3)
    end
end)