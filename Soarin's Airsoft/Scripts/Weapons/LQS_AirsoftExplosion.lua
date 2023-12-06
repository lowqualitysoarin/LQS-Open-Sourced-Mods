behaviour("LQS_AirsoftExplosion")

function LQS_AirsoftExplosion:Awake()
	-- Base
	self.data = self.gameObject.GetComponent(DataContainer)
	self.airsoftProjectile = self.targets.airsoftProjectile

	-- Configuration
	self.explosionIterations = self.data.GetInt("explosionIterations")

	-- Get the source and source weapon from the parent
	local parentProj = self.transform.parent.gameObject.GetComponent(ExplodingProjectile)
	self.source = parentProj.source
end

function LQS_AirsoftExplosion:OnEnable()
	-- Explode when enabled
	self:Explode()
end

function LQS_AirsoftExplosion:Explode()
	-- Literally the explosion thing
	for i = 1, self.explosionIterations do
		-- Calculate explosion direction
		local direction = self.transform.position + Random.insideUnitSphere * 1
		local finalExplosionRot = (direction - self.transform.position)

		-- Instantiate and setup airsoft projectile
		local projectile = GameObject.Instantiate(self.airsoftProjectile, self.transform.position, Quaternion.LookRotation(finalExplosionRot)).GetComponent(ExplodingProjectile)
		projectile.source = self.source
	end

	-- Disable this gameobject
	self.gameObject.SetActive(false)
end
