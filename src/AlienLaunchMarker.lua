--[[
    GD50
    Angry Birds

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

AlienLaunchMarker = Class{}

function AlienLaunchMarker:init(world)
    self.world = world

    -- starting coordinates for launcher used to calculate launch vector
    self.baseX = 90
    self.baseY = VIRTUAL_HEIGHT - 100

    -- shifted coordinates when clicking and dragging launch alien
    self.shiftedX = self.baseX
    self.shiftedY = self.baseY

    -- whether our arrow is showing where we're aiming
    self.aiming = false

    -- whether we launched the alien and should stop rendering the preview
    self.launched = false
    self.canSplit = false

    -- our aliens that we will eventually spawn
    self.aliens = {}
end

function AlienLaunchMarker:update(dt)
    -- if we can split and space bar was clicked add 2 more player-aliens to game
    if self.canSplit and love.keyboard.wasPressed('space') then
        -- disable splitting (so we can only split once per launch)
        self.canSplit = false

        -- Get velocity, and position for original player-alien
        Vx, Vy = self.aliens[1].body:getLinearVelocity()
        posX, posY = self.aliens[1].body:getPosition()

        -- create two player-aliens (a and b) passing in position of original-alien
        a = Alien(self.world, 'round', posX, posY, 'Player')
        b = Alien(self.world, 'round', posX, posY, 'Player')

        -- Adjust velocity for both by adding and subtracting 40 percent from Y-velocity
        a.body:setLinearVelocity(Vx, Vy - Vy * 0.4)
        b.body:setLinearVelocity(Vx, Vy + Vy * 0.4)

        -- make the a-alien pretty bouncy
        a.fixture:setRestitution(0.5)
        a.body:setAngularDamping(1)

        -- make the b-alien pretty bouncy
        b.fixture:setRestitution(0.5)
        b.body:setAngularDamping(1)

        -- Add to negative -1 group for no collision between player-aliens
        a.fixture:setGroupIndex(-1)
        b.fixture:setGroupIndex(-1)

        -- Add both aliens to aliens table
        table.insert(self.aliens, a)
        table.insert(self.aliens, b)
    end
    
    -- perform everything here as long as we haven't launched yet
    if not self.launched then

        -- grab mouse coordinates
        local x, y = push:toGame(love.mouse.getPosition())
        
        -- if we click the mouse and haven't launched, show arrow preview
        if love.mouse.wasPressed(1) and not self.launched then
            self.aiming = true

        -- if we release the mouse, launch an Alien
        elseif love.mouse.wasReleased(1) and self.aiming then
            self.launched = true
            self.canSplit = true

            -- spawn new alien in the world, passing in user data of player
            original_alien = Alien(self.world, 'round', self.shiftedX-10, self.shiftedY-10, 'Player')

            -- apply the difference between current X,Y and base X,Y as launch vector impulse
            original_alien.body:setLinearVelocity((self.baseX - self.shiftedX) * 10, (self.baseY - self.shiftedY) * 10)

            -- make the alien pretty bouncy
            original_alien.fixture:setRestitution(0.4)
            original_alien.body:setAngularDamping(1)

            -- Add to negative -1 group for no collision between player-aliens
            original_alien.fixture:setGroupIndex(-1)
            
            -- add aliens table
            table.insert(self.aliens, original_alien)

            -- we're no longer aiming
            self.aiming = false

        -- re-render trajectory
        elseif self.aiming then
            
            self.shiftedX = math.min(self.baseX + 30, math.max(x, self.baseX - 30))
            self.shiftedY = math.min(self.baseY + 30, math.max(y, self.baseY - 30))
        end
    end
end

function AlienLaunchMarker:render()
    if not self.launched then
        
        -- render base alien, non physics based
        love.graphics.draw(gTextures['aliens'], gFrames['aliens'][9], 
            self.shiftedX - 17.5, self.shiftedY - 17.5)

        if self.aiming then
            
            -- render arrow if we're aiming, with transparency based on slingshot distance
            local impulseX = (self.baseX - self.shiftedX) * 10
            local impulseY = (self.baseY - self.shiftedY) * 10

            -- draw 18 circles simulating trajectory of estimated impulse
            local trajX, trajY = self.shiftedX, self.shiftedY
            local gravX, gravY = self.world:getGravity()

            -- http://www.iforce2d.net/b2dtut/projected-trajectory
            for i = 1, 90 do
                
                -- magenta color that starts off slightly transparent
                love.graphics.setColor(255/255, 80/255, 255/255, ((255 / 24) * i) / 255)
                
                -- trajectory X and Y for this iteration of the simulation
                trajX = self.shiftedX + i * 1/60 * impulseX
                trajY = self.shiftedY + i * 1/60 * impulseY + 0.5 * (i * i + i) * gravY * 1/60 * 1/60

                -- render every fifth calculation as a circle
                if i % 5 == 0 then
                    love.graphics.circle('fill', trajX, trajY, 3)
                end
            end
        end
        
        love.graphics.setColor(1, 1, 1, 1)
    else
        for k, alien in pairs(self.aliens) do
            alien:render()
        end
    end
end