-- low_quality_soarin © 2023-2024
-- Similar how does the weapon pose handler works but for the flashlight.
behaviour("RC_FlashlightPoseHandler")

function RC_FlashlightPoseHandler:Awake()
	-- Main Flashlight Script
	if (self.targets.flashScript) then
		self.flashScript = self.targets.flashScript.GetComponent(ScriptedBehaviour).self
	end
end

function RC_FlashlightPoseHandler:Start()
	-- Base
	if (self.targets.flashTransform) then
		self.flashTransform = self.targets.flashTransform.transform
	end
	if (self.targets.flashPoses) then
		self.flashPoses = self.targets.flashPoses.GetComponent(ScriptedBehaviour).self
	end

	-- Vars
	if (self.flashTransform) then
		self.targetFlashPose = self.flashTransform
	end
end

function RC_FlashlightPoseHandler:Update()
	-- Flash Animator
	self:SetFlashPose()

	-- Flash Handler
	self:FlashPoseHandler()
end

function RC_FlashlightPoseHandler:ProceduralAnimator(baseTransform, endKey, speed, isLocal)
	local startPosTransform = nil
    local startRotTransform = nil

    local endPosTransform = nil
    local endRotTransform = nil

    local prevPos = nil

    -- Pass local pos and rot else normal pos and rot
    if (isLocal) then
        startPosTransform = baseTransform.localPosition
        startRotTransform = baseTransform.localRotation

        endPosTransform = endKey.localPosition
        endRotTransform = endKey.localRotation

        prevPos = baseTransform.localPosition
    else
        startPosTransform = baseTransform.position
        startRotTransform = baseTransform.rotation

        endPosTransform = endKey.position
        endRotTransform = endKey.rotation

        prevPos = baseTransform.position
    end

    -- Spring Lerp
	local springScript = baseTransform.gameObject.GetComponent(RC_SpringBase)

	if (springScript) then
		springScript:Spring(endPosTransform, endRotTransform, isLocal, false)
	end
end

function RC_FlashlightPoseHandler:SetFlashPose()
	self:ProceduralAnimator(self.flashTransform, self.targetFlashPose, 7.5, false)
end

function RC_FlashlightPoseHandler:FlashPoseHandler()
	if (not self.flashScript) then return end
	if (not self.flashPoses) then return end
	
	if (self.flashScript.aim and not self.flashScript.isTwoHanded) then
		if (self.flashScript.flashAimPose) then
			self.targetFlashPose = self.flashScript.flashAimPose
		end
	elseif (self.flashScript.mouthHold) then
		if (self.flashPoses.flashlightMouthHold) then
			self.targetFlashPose = self.flashPoses.flashlightMouthHold
		end
	elseif (self.flashScript.forceHolster) then
		if (self.flashPoses.flashlightHolsteredPose) then
			self.targetFlashPose = self.flashPoses.flashlightHolsteredPose
		end
	else
		if (self.flashPoses.flashlightIdlePose) then
			self.targetFlashPose = self.flashPoses.flashlightIdlePose
		end
	end
end