-- low_quality_soarin © 2023-2024

-- This is like the spring version of lerp. I really need to put this on the part that I want
-- to do a spring lerp because it fucks when I put it in the pose handler.
--
-- Tho it still needs the pose handler to setup the target position or else it worldn't do shit.
behaviour("RC_SpringBase")

function RC_SpringBase:Start()
	-- Base
	self.data = self.gameObject.GetComponent(DataContainer)

    -- Configuration
    self.springStrength = self.data.GetFloat("springStrength")
    self.springSpeed = self.data.GetFloat("springSpeed")
	self.rotationSpeed = self.data.GetFloat("rotationSpeed")

    -- Essentials
    self.springVec = Vector3.zero
end

function RC_SpringBase:Spring(targetPos, targetRot, isLocal, isMindControl)
	if (Time.timeScale <= 0) then return end

    local targetSpeed = self.springSpeed
    local targetStrength = self.springStrength
    local targetRotSpeed = self.rotationSpeed

    -- Check if the lerp is mind control
    -- If so then apply the recommended values for the mind control lerp.
    if (isMindControl) then
        targetSpeed = 1.25
        targetStrength = 0.15
        targetRotSpeed = 0.45
    end

    -- Start Lerping
    if (not isLocal) then
        -- Position
        self.springVec = Vector3.Lerp(self.springVec, (targetPos - self.transform.position) * targetStrength * Time.deltaTime,
            targetSpeed * Time.deltaTime)
        self.transform.position = self.transform.position + self.springVec

        -- Rotation
        self.transform.rotation = Quaternion.SlerpUnclamped(self.transform.rotation, targetRot,
            targetRotSpeed * Time.deltaTime)
    else
        -- Position
        self.springVec = Vector3.Lerp(self.springVec, (targetPos - self.transform.localPosition) * targetStrength * Time.deltaTime,
            targetSpeed * Time.deltaTime)
        self.transform.localPosition = self.transform.localPosition + self.springVec

        -- Rotation
        self.transform.localRotation = Quaternion.SlerpUnclamped(self.transform.localRotation, targetRot,
            targetRotSpeed * Time.deltaTime)
    end
end
