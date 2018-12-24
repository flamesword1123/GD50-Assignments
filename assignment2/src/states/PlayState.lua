--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.ball = params.ball
    self.level = params.level

    --ball powerup:
    self.powerup = Powerup()

    self.usedPowerUp = false
    self.bonusHasSpawned = false

    --key powerup
    self.key = Powerup()
    self.key.image = 10

    self.usedKey = false
    self.keyHasSpawned = false


    self.recoverPoints = 5000

    -- give ball random starting velocity
    self.ball.dx = math.random(-200, 200)
    self.ball.dy = math.random(-50, -60)


    self.timer = 0
    self.powerupSpawnTime = math.random(5, 10)


end

function PlayState:update(dt)

    self.timer = self.timer + dt

    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end



    -- update positions based on velocity
    self.paddle:update(dt)
    self.ball:update(dt)

    self.powerup:update(dt)
    self.key:update(dt)


    if self.powerup:collides(self.paddle) and self.usedPowerUp == false then
        self.usedPowerUp = true

        self.bonusBall1 = Ball()
        self.bonusBall1.skin = math.random(7)

        self.bonusBall2 = Ball()
        self.bonusBall2.skin = math.random(7)

        -- set the starting position of the two bonus balls at the paddle
        self.bonusBall1.x = self.paddle.x + (self.paddle.width / 2) - 4 + 2
        self.bonusBall1.y = self.paddle.y - 10

        self.bonusBall2.x = self.paddle.x + (self.paddle.width / 2) - 4 - 2
        self.bonusBall2.y = self.paddle.y - 10

        -- set the starting velocity of the two bonus balls
        self.bonusBall1.dx = math.random(-200, 200)
        self.bonusBall1.dy = math.random(-50, -60)

        self.bonusBall2.dx = math.random(-200, 200)
        self.bonusBall2.dy = math.random(-50, -60)

    end

    if self.key:collides(self.paddle) and self.usedKey == false then
        self.usedKey = true
        -- now collisions will occur with the locked brick
    end

    -- once the bonus balls have spawned, start updating them
    if self.bonusHasSpawned == true then
        self.bonusBall1:update(dt)
        self.bonusBall2:update(dt)
    end

    -- ball to paddle collision handling
    if self.ball:collides(self.paddle) then
        -- raise ball above paddle in case it goes below it, then reverse dy
        self.ball.y = self.paddle.y - 8
        self.ball.dy = -self.ball.dy

        --
        -- tweak angle of bounce based on where it hits the paddle
        --

        -- if we hit the paddle on its left side while moving left...
        if self.ball.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
            self.ball.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - self.ball.x))

        -- else if we hit the paddle on its right side while moving right...
        elseif self.ball.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
            self.ball.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - self.ball.x))
        end

        gSounds['paddle-hit']:play()
    end

    -- bonus ball to paddle collision handling
    if self.bonusHasSpawned == true then
        if self.bonusBall1:collides(self.paddle) then
            -- raise bonusBall1 above paddle in case it goes below it, then reverse dy
            self.bonusBall1.y = self.paddle.y - 8
            self.bonusBall1.dy = -self.bonusBall1.dy

            --
            -- tweak angle of bounce based on where it hits the paddle
            --

            -- if we hit the paddle on its left side while moving left...
            if self.bonusBall1.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
                self.bonusBall1.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - self.bonusBall1.x))

            -- else if we hit the paddle on its right side while moving right...
            elseif self.bonusBall1.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
                self.bonusBall1.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - self.bonusBall1.x))
            end

            gSounds['paddle-hit']:play()
        end

        if self.bonusBall2:collides(self.paddle) then
            -- raise bonusBall1 above paddle in case it goes below it, then reverse dy
            self.bonusBall2.y = self.paddle.y - 8
            self.bonusBall2.dy = -self.bonusBall2.dy

            --
            -- tweak angle of bounce based on where it hits the paddle
            --

            -- if we hit the paddle on its left side while moving left...
            if self.bonusBall2.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
                self.bonusBall2.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - self.bonusBall2.x))

            -- else if we hit the paddle on its right side while moving right...
            elseif self.bonusBall2.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
                self.bonusBall2.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - self.bonusBall2.x))
            end

            gSounds['paddle-hit']:play()
        end
    end

    -- detect collision across all bricks with the ball
    for k, brick in pairs(self.bricks) do

        -- only check collision if we're in play and the brick is not locked
        -- until the brick is unlocked, the ball will just pass through
        if brick.inPlay and self.ball:collides(brick) and (not brick.locked or self.usedKey) then

            -- add to score
            self.score = self.score + (brick.tier * 200 + brick.color * 25)

            -- trigger the brick's hit function, which removes it from play
            brick:hit()

            -- if we have enough points, recover a point of health
            if self.score > self.recoverPoints then
                -- can't go above 3 health
                self.health = math.min(3, self.health + 1)

                -- multiply recover points by 2
                self.recoverPoints = math.min(100000, self.recoverPoints * 2)

                -- increase the size of the paddle
                    if self.paddle.size < 4 then
                        self.paddle.size = self.paddle.size + 1
                    end

                -- play recover sound effect
                gSounds['recover']:play()
            end

            -- go to our victory screen if there are no more bricks left
            if self:checkVictory() then
                gSounds['victory']:play()

                gStateMachine:change('victory', {
                    level = self.level,
                    paddle = self.paddle,
                    health = self.health,
                    score = self.score,
                    highScores = self.highScores,
                    ball = self.ball,
                    recoverPoints = self.recoverPoints
                })
            end

            --
            -- collision code for bricks
            --
            -- we check to see if the opposite side of our velocity is outside of the brick;
            -- if it is, we trigger a collision on that side. else we're within the X + width of
            -- the brick and should check to see if the top or bottom edge is outside of the brick,
            -- colliding on the top or bottom accordingly
            --

            -- left edge; only check if we're moving right, and offset the check by a couple of pixels
            -- so that flush corner hits register as Y flips, not X flips
            if self.ball.x + 2 < brick.x and self.ball.dx > 0 then

                -- flip x velocity and reset position outside of brick
                self.ball.dx = -self.ball.dx
                self.ball.x = brick.x - 8

            -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
            -- so that flush corner hits register as Y flips, not X flips
            elseif self.ball.x + 6 > brick.x + brick.width and self.ball.dx < 0 then

                -- flip x velocity and reset position outside of brick
                self.ball.dx = -self.ball.dx
                self.ball.x = brick.x + 32

            -- top edge if no X collisions, always check
            elseif self.ball.y < brick.y then

                -- flip y velocity and reset position outside of brick
                self.ball.dy = -self.ball.dy
                self.ball.y = brick.y - 8

            -- bottom edge if no X collisions or top collision, last possibility
            else

                -- flip y velocity and reset position outside of brick
                self.ball.dy = -self.ball.dy
                self.ball.y = brick.y + 16
            end

            -- slightly scale the y velocity to speed up the game, capping at +- 150
            if math.abs(self.ball.dy) < 150 then
                self.ball.dy = self.ball.dy * 1.02
            end

            -- only allow colliding with one brick, for corners
            break
        end

        -- brick collision detection for bonus ball 1
        if self.bonusHasSpawned == true then
            if brick.inPlay and self.bonusBall1:collides(brick) then

                -- add to score
                self.score = self.score + (brick.tier * 200 + brick.color * 25)

                -- trigger the brick's hit function, which removes it from play
                brick:hit()

                -- if we have enough points, recover a point of health
                if self.score > self.recoverPoints then
                    -- can't go above 3 health
                    self.health = math.min(3, self.health + 1)

                    -- increase the size of the paddle
                    if self.paddle.size < 4 then
                        self.paddle.size = self.paddle.size + 1
                    end

                    -- multiply recover points by 2
                    self.recoverPoints = math.min(100000, self.recoverPoints * 2)

                    -- play recover sound effect
                    gSounds['recover']:play()
                end

                -- go to our victory screen if there are no more bricks left
                if self:checkVictory() then
                    gSounds['victory']:play()

                    gStateMachine:change('victory', {
                        level = self.level,
                        paddle = self.paddle,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        ball = self.ball,
                        recoverPoints = self.recoverPoints
                    })
                end

                --
                -- collision code for bricks
                --
                -- we check to see if the opposite side of our velocity is outside of the brick;
                -- if it is, we trigger a collision on that side. else we're within the X + width of
                -- the brick and should check to see if the top or bottom edge is outside of the brick,
                -- colliding on the top or bottom accordingly
                --

                -- left edge; only check if we're moving right, and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                if self.bonusBall1.x + 2 < brick.x and self.bonusBall1.dx > 0 then

                    -- flip x velocity and reset position outside of brick
                    self.bonusBall1.dx = -self.bonusBall1.dx
                    self.bonusBall1.x = brick.x - 8

                -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                elseif self.bonusBall1.x + 6 > brick.x + brick.width and self.bonusBall1.dx < 0 then

                    -- flip x velocity and reset position outside of brick
                    self.bonusBall1.dx = -self.bonusBall1.dx
                    self.bonusBall1.x = brick.x + 32

                -- top edge if no X collisions, always check
                elseif self.bonusBall1.y < brick.y then

                    -- flip y velocity and reset position outside of brick
                    self.bonusBall1.dy = -self.bonusBall1.dy
                    self.bonusBall1.y = brick.y - 8

                -- bottom edge if no X collisions or top collision, last possibility
                else

                    -- flip y velocity and reset position outside of brick
                    self.bonusBall1.dy = -self.bonusBall1.dy
                    self.bonusBall1.y = brick.y + 16
                end

                -- slightly scale the y velocity to speed up the game, capping at +- 150
                if math.abs(self.bonusBall1.dy) < 150 then
                    self.bonusBall1.dy = self.bonusBall1.dy * 1.02
                end


                -- only allow colliding with one brick, for corners
                break
            end





            -- brick collision detection for bonus ball 2
            if brick.inPlay and self.bonusBall2:collides(brick) then

                -- add to score
                self.score = self.score + (brick.tier * 200 + brick.color * 25)

                -- trigger the brick's hit function, which removes it from play
                brick:hit()

                -- if we have enough points, recover a point of health
                if self.score > self.recoverPoints then
                    -- can't go above 3 health
                    self.health = math.min(3, self.health + 1)

                    -- increase the size of the paddle
                    if self.paddle.size < 4 then
                        self.paddle.size = self.paddle.size + 1
                    end

                    -- multiply recover points by 2
                    self.recoverPoints = math.min(100000, self.recoverPoints * 2)

                    -- play recover sound effect
                    gSounds['recover']:play()
                end

                -- go to our victory screen if there are no more bricks left
                if self:checkVictory() then
                    gSounds['victory']:play()

                    gStateMachine:change('victory', {
                        level = self.level,
                        paddle = self.paddle,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        ball = self.ball,
                        recoverPoints = self.recoverPoints
                    })
                end

                --
                -- collision code for bricks
                --
                -- we check to see if the opposite side of our velocity is outside of the brick;
                -- if it is, we trigger a collision on that side. else we're within the X + width of
                -- the brick and should check to see if the top or bottom edge is outside of the brick,
                -- colliding on the top or bottom accordingly
                --

                -- left edge; only check if we're moving right, and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                if self.bonusBall2.x + 2 < brick.x and self.bonusBall2.dx > 0 then

                    -- flip x velocity and reset position outside of brick
                    self.bonusBall2.dx = -self.bonusBall2.dx
                    self.bonusBall2.x = brick.x - 8

                -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                elseif self.bonusBall2.x + 6 > brick.x + brick.width and self.bonusBall2.dx < 0 then

                    -- flip x velocity and reset position outside of brick
                    self.bonusBall2.dx = -self.bonusBall2.dx
                    self.bonusBall2.x = brick.x + 32

                -- top edge if no X collisions, always check
                elseif self.bonusBall2.y < brick.y then

                    -- flip y velocity and reset position outside of brick
                    self.bonusBall2.dy = -self.bonusBall2.dy
                    self.bonusBall2.y = brick.y - 8

                -- bottom edge if no X collisions or top collision, last possibility
                else

                    -- flip y velocity and reset position outside of brick
                    self.bonusBall2.dy = -self.bonusBall2.dy
                    self.bonusBall2.y = brick.y + 16
                end

                -- slightly scale the y velocity to speed up the game, capping at +- 150
                if math.abs(self.bonusBall2.dy) < 150 then
                    self.bonusBall2.dy = self.bonusBall2.dy * 1.02
                end

                -- only allow colliding with one brick, for corners
                break
            end
        end
    end

    -- if ball goes below bounds, revert to serve state and decrease health
    if self.ball.y >= VIRTUAL_HEIGHT or (self.bonusHasSpawned == true and self.bonusBall1.y >=VIRTUAL_HEIGHT) or (self.bonusHasSpawned == true and self.bonusBall2.y >=VIRTUAL_HEIGHT) then
        self.health = self.health - 1
        gSounds['hurt']:play()

        if self.health == 0 then
            gStateMachine:change('game-over', {
                score = self.score,
                highScores = self.highScores
            })
        else
            gStateMachine:change('serve', {
                paddle = self.paddle,
                bricks = self.bricks,
                health = self.health,
                score = self.score,
                highScores = self.highScores,
                level = self.level,
                recoverPoints = self.recoverPoints
            })
        end
    end


    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
    if love.keyboard.wasPressed('lctrl') then
        debug.debug()
    end
end

function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    self.paddle:render()
    self.ball:render()

    -- spawn powerup after set amount of time
    if self.timer >= self.powerupSpawnTime and self.usedPowerUp ~= true then
        self.powerup:render()
        self.powerup.dy = 50

    end
    if self.usedPowerUp == true then
        self.bonusBall1:render()
        self.bonusBall2:render()

        self.bonusHasSpawned = true
    end

    --spawn key powerup after a set amount of time only if this is a game with a locked brick
    if (self.timer >= self.powerupSpawnTime + math.random(5,10)) and self.usedKey ~= true and LevelMaker.getAddLock() then
        self.key:render()
        self.key.dy = 50
    end


    renderScore(self.score)
    renderHealth(self.health)

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')

    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end
    end

    return true
end
