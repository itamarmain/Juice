--!strict


--types :
type ShakeState = {
    isShaking : boolean,
    intensity : number,
    duration : number,
    frequency : number,
    startTime : number
}
type ImpulseState = {
    isImpulsing : boolean,
    
    position : Vector3,
    basePosition : Vector3,
    targetPosition : Vector3,
    velocity : Vector3,

    stiffness : number,
    damping : number,

    time : number,
    duration : number
}
type FOVPunchState = {
    isPunching : boolean,
    amount : number,
    duration : number,
    startTime : number,
    originalFOV : number,
    returnDuration : number
}
local Camera = {}
Camera.__index = Camera

export type CameraController = typeof(setmetatable(
	{} :: {
		_cam: Camera,
		_renderStepName: string,
		_shakeTable: ShakeState,
		_impulseTable: ImpulseState,
		_FOVPunchTable: FOVPunchState,
	},
	Camera
))
local RS = game:GetService("RunService")



--Helper Functions
local function GetShakenOffset(calculatedIntensity : number, frequency : number) : CFrame
    local noisedX = math.noise(os.clock()  * frequency,0,0) * calculatedIntensity
    local noisedY = math.noise(0,os.clock()  * frequency,0) * calculatedIntensity
    
    return CFrame.Angles(math.rad(noisedX), math.rad(noisedY), 0)
end

--Module Functions

function Camera.new(): CameraController
	local self = setmetatable({
		_cam = workspace.CurrentCamera,

		_renderStepName = "CamJuice",

		_shakeTable = {
			isShaking = false,
			intensity = 0,
			duration = 0,
			frequency = 20,
			startTime = 0,
		},

		_impulseTable = {
			isImpulsing = false,
			position = Vector3.zero,
			basePosition = Vector3.zero,
			targetPosition = Vector3.zero,
			velocity = Vector3.zero,
			stiffness = 120,
			damping = 10,
			time = 0,
			duration = 0.1,
		},

		_FOVPunchTable = {
			isPunching = false,
			amount = 0,
			duration = 0,
			startTime = 0,
			originalFOV = workspace.CurrentCamera.FieldOfView,
			returnDuration = 0.25,
		},
	}, Camera)

	RS:BindToRenderStep(
		self._renderStepName,
		Enum.RenderPriority.Camera.Value + 1,
		function(dt)
			self:Update(dt)
		end
	)

	return self
end

function Camera:CamShake(intensity : number, duration : number , frequency : number?) 
    local freq = frequency or 20
    local startTime = os.clock() -- secs
    local shakeTable = self._shakeTable
    shakeTable.isShaking = true
    shakeTable.intensity = intensity
    shakeTable.duration = duration
    shakeTable.frequency = freq
    shakeTable.startTime = startTime
end

function Camera:StopShake()
    local shakeTable = self._shakeTable
    shakeTable.isShaking = false
    shakeTable.intensity = 0
    shakeTable.duration = 0
    shakeTable.frequency = 20
    shakeTable.startTime = 0


end

function Camera:CamImpulse(direction : Vector3 , magnitude : number ,stiffness : number?, damping : number?)
    self._shakeTable.isShaking = false

    local impulse = self._impulseTable
    impulse.isImpulsing = true
    impulse.basePosition = Vector3.zero
    impulse.targetPosition = direction.Unit * magnitude
    impulse.position = Vector3.zero
    impulse.velocity = Vector3.zero
    impulse.stiffness = stiffness or 120
    impulse.damping = damping or 10
    impulse.time = 0
    impulse.duration = 0.1 -- time for cam to return to original position
end

function Camera:CamFOVPunch(amount : number, duration : number)
    local originalFOV = self._cam.FieldOfView
    local startTime = os.clock()
    local punchTable = self._FOVPunchTable
    punchTable.isPunching = true
    punchTable.amount = amount
    punchTable.duration = duration
    punchTable.startTime = startTime
    punchTable.originalFOV = originalFOV
end
function Camera:_UpdateShake(finalCFrame: CFrame) : CFrame
    local newCFrame = finalCFrame
    if self._shakeTable.isShaking then
        local elapsedTime = os.clock() - self._shakeTable.startTime
        if elapsedTime >= self._shakeTable.duration then
            self._shakeTable.isShaking = false
        else 
            local currentIntensity = self._shakeTable.intensity * (1 - elapsedTime / self._shakeTable.duration)
            newCFrame = finalCFrame * GetShakenOffset(currentIntensity, self._shakeTable.frequency)
        end
    end
    return newCFrame
end
function Camera:_UpdateImpulse(dt : number, finalCFrame: CFrame) : CFrame
    if not self._impulseTable.isImpulsing then
        return finalCFrame
    end
    local impulse = self._impulseTable

    impulse.time += dt

    if impulse.time >= impulse.duration then
        impulse.targetPosition = impulse.basePosition
    end
    local displacement = impulse.targetPosition - impulse.position

    local acceleration = impulse.stiffness * displacement - impulse.damping * impulse.velocity
    impulse.velocity += acceleration * dt
    impulse.position += impulse.velocity * dt

    if impulse.position.Magnitude < 0.01 and impulse.velocity.Magnitude < 0.01 and impulse.time >= impulse.duration then
        impulse.isImpulsing = false
        impulse.position = Vector3.zero
        impulse.velocity = Vector3.zero
    end
    return finalCFrame * CFrame.new(impulse.position)
end
function Camera:_UpdateFOVPunch()
    if self._FOVPunchTable.isPunching then
        local punch = self._FOVPunchTable
        local elapsedTime = os.clock() - punch.startTime
        if elapsedTime < punch.duration then
            local loadUpDuration = punch.duration * 0.2
            local alpha = math.clamp(elapsedTime / loadUpDuration, 0, 1)
            local easedAlpha = 1 - (1 - alpha) ^ 3
            self._cam.FieldOfView = punch.originalFOV + punch.amount * easedAlpha
        elseif elapsedTime - punch.duration < punch.returnDuration then 
            local returnElapsed = elapsedTime - punch.duration
            local returnAlpha = math.clamp(returnElapsed / punch.returnDuration, 0, 1)
            local returnEasedAlpha = 1 - (1 - returnAlpha) ^ 3
            self._cam.FieldOfView = punch.originalFOV + punch.amount *(1- returnEasedAlpha)
        else
            self._cam.FieldOfView = punch.originalFOV
            self._FOVPunchTable.isPunching = false
        end
    end
end
function Camera:Update( dt : number)

    local finalCFrame = self._cam.CFrame

    finalCFrame = self:_UpdateShake(finalCFrame)
    finalCFrame = self:_UpdateImpulse(dt, finalCFrame)

    self:_UpdateFOVPunch()

    self._cam.CFrame = finalCFrame
end



function Camera:Destroy()
    self:StopShake()
    self._FOVPunchTable.isPunching = false
    self._impulseTable.isImpulsing = false
    RS:UnbindFromRenderStep(self._renderStepName)
    setmetatable(self, nil)
end
return Camera