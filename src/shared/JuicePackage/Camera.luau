--!strict

local Camera = {}
Camera.__index = Camera
local RS = game:GetService("RunService")



--Helper Functions
local function getShakenOffset(calculatedIntensity : number, frequency : number) : CFrame
    local noisedX = math.noise(os.clock()  * frequency,0,0) * calculatedIntensity
    local noisedY = math.noise(0,os.clock()  * frequency,0) * calculatedIntensity
    
    return CFrame.Angles(math.rad(noisedX), math.rad(noisedY), 0)
end

--Module Functions

function Camera.new()
    local self = setmetatable({}, Camera)
    self._cam = workspace.CurrentCamera
    self._KEY = "CamJuice"

    self._shakeTable = {
        isShaking = false,
        intensity = 0,
        duration = 0,
        frequency = 20,
        startTime = 0
    }

    self._camSmoothTable = {
        isSmoothing = false,
        followedModel = nil,
        offsetCFrame = CFrame.new(0,5,10),
        lookAtPos = nil,
        lookAtProvider = nil,
        smoothness = 10
    }
    RS:BindToRenderStep(self._KEY, Enum.RenderPriority.Camera.Value + 1, function(dt)
        self:Update(dt)
    end)
    return self
end

function Camera:CamShake(intensity : number, duration : number , frequency : number?) 
    local cam = workspace.CurrentCamera :: Camera
    local freq = frequency or 20
    local currentIntensity = intensity
    local startTime = os.clock() -- secs
    self._shakeTable = {
        isShaking = true,
        intensity = intensity,
        duration = duration,
        frequency = freq,
        startTime = startTime
    }
end

function Camera:StopShake()
    self._shakeTable = {
        isShaking = false,
        intensity = 0,
        duration = 0,
        frequency = 20,
        startTime = 0
    }
end

function Camera:SetFollowedModel(M : Model)
    self._camSmoothTable.followedModel = M
end
function Camera:SetStiffness(s : number)
    self._camSmoothTable.smoothness = s
end
function Camera:SetOffsetCFrame(o : CFrame)
    self._camSmoothTable.offsetCFrame = o
end
function Camera:SetLookAtPosition(p : Vector3)
    self._camSmoothTable.lookAtPos = p
    self._camSmoothTable.lookAtDir = nil
    self._camSmoothTable.lookAtProvider = nil
end
function Camera:SetLookAtDirection(d : Vector3)
    self._camSmoothTable.lookAtDir = d
    self._camSmoothTable.lookAtPos = nil
    self._camSmoothTable.lookAtProvider = nil
end

function Camera:SetLookAtProvider(p : () -> Vector3?)
    self._camSmoothTable.lookAtProvider = p
    self._camSmoothTable.lookAtPos = nil
    self._camSmoothTable.lookAtDir = nil
end


function Camera:Update( dt : number)
    local followedModel = self._camSmoothTable.followedModel
    if not followedModel then
        return
    end
    local hrp = followedModel:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return
    end
    local followedCFrame = hrp.CFrame

    local finalCFrame = self._cam.CFrame
    
    if self._camSmoothTable.isSmoothing then
        local targetPos = followedCFrame * self._camSmoothTable.offsetCFrame
        local targetCFrame
        if self._camSmoothTable.lookAtProvider then
            targetCFrame = CFrame.lookAt(targetPos.Position, self._camSmoothTable.lookAtProvider())
        elseif self._camSmoothTable.lookAtPos then
            targetCFrame = CFrame.lookAt(targetPos.Position, self._camSmoothTable.lookAtPos)
        else
            targetCFrame = targetPos
        end
        local alpha = 1 - math.exp(-self._camSmoothTable.smoothness * dt)
        finalCFrame = self._cam.CFrame:Lerp(targetCFrame, alpha)
    end


    if self._shakeTable.isShaking then
        local elapsedTime = os.clock() - self._shakeTable.startTime
        if elapsedTime >= self._shakeTable.duration then
            self._shakeTable.isShaking = false
        else 
            local currentIntensity = self._shakeTable.intensity * (1 - elapsedTime / self._shakeTable.duration)
            finalCFrame = finalCFrame * getShakenOffset(currentIntensity, self._shakeTable.frequency)
        end
    end
    self._cam.CFrame = finalCFrame

end






function Camera:EnableSmooth()
    if self._camSmoothTable.isSmoothing then
        return
    end
    self._cam.CameraType = Enum.CameraType.Scriptable
    self._camSmoothTable.isSmoothing = true

end




function Camera:DisableSmooth()
    if not self._camSmoothTable.isSmoothing then
        return
    end
    self._cam.CameraType = Enum.CameraType.Custom
    self._camSmoothTable.isSmoothing = false
end

function Camera:Destroy()
    self:DisableSmooth()
    self:StopShake()
    RS:UnbindFromRenderStep(self._KEY)
    setmetatable(self, nil)
end
return Camera