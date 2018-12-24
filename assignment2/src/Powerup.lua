Powerup = Class{}

function Powerup:init()

    self.x = math.random(0, VIRTUAL_WIDTH - 16)
    -- spawns right above screen
    self.y = -16

    self.width = 16
    self.height = 16

    -- powerup only moves down y axis so no need for dx
    self.dy = 0

    -- index of image for powerup. 7 for ball powerup, 10 for key powerup
    self.image = 7

end

function Powerup:collides(target)
	--same AABB collision as ball

	-- first, check to see if the left edge of either is farther to the right
    -- than the right edge of the other
	if self.x > target.x + target.width or target.x > self.x + self.width then
        return false
    end

    -- then check to see if the bottom edge of either is higher than the top
    -- edge of the other
    if self.y > target.y + target.height or target.y > self.y + self.height then
        return false
    end

    -- if the above aren't true, they're overlapping
    return true


end

function Powerup:update(dt)
	self.y = self.y + self.dy * dt


end

function Powerup:render()
	love.graphics.draw(gTextures['main'], gFrames['powerups'][self.image], self.x, self.y)
end

