-----------------------------------------------------------------------------------------
--
-- level1.lua
--
-----------------------------------------------------------------------------------------

local storyboard = require( "storyboard" )
local scene = storyboard.newScene()

-- include Corona's "physics" library
local physics = require "physics"
physics.start(); physics.pause()
physics.setGravity(0,0)

--------------------------------------------

-- forward declarations and other locals
local screenW, screenH = display.contentWidth, display.contentHeight
local halfW, halfH = screenW/2, screenH/2
local dog
local dogAngularVelocity = 200 -- for circling (to the right)
local score = 0
local scoreText
local energy = 0
local maxEnergy = 10
local energyBar
local barOffset
-----------------------------------------------------------------------------------------
-- BEGINNING OF YOUR IMPLEMENTATION
-- 
-- NOTE: Code outside of listener functions (below) will only be executed once,
--		 unless storyboard.removeScene() is called.
-- 
-----------------------------------------------------------------------------------------

local function newBall()
	local ballRadius = 8
	local ball = display.newImageRect( "ball.png", ballRadius*2, ballRadius*2 )
	-- Add physics to ball
	physics.addBody( ball, { density = 1.0, friction = 0.3, bounce = 0.2, radius = ballRadius } )
	-- Name ball
	ball.name = "ball"
	-- Set as a collectable type
	ball.type = "collect"
	ball.collected = false
	return ball
end

local function showScore()
	if score == 1 then
		scoreText.text = score.." ball"
	else
		scoreText.text = score.." balls"
	end
	scoreText:toFront()
end

local function showEnergy()
	local meterWidth = 25
	--print("Energy: "..energy)
	energyBar.width = (meterWidth*energy)
	energyBar:setReferencePoint(display.TopLeftReferencePoint)
	energyBar.x = barOffset
	if energy <= 1 then
		energyBar:setFillColor(220,0,0)
	else
		energyBar:setFillColor(0,220,0)
	end
end

local function showBall(ball)
	local buffer = 20 -- so the ball stays within the walls
	--place the ball at a random position
	ball.x, ball.y = math.random(buffer, screenW-buffer), math.random(buffer, screenH-buffer)
	ball.alpha = 1
	--reset as uncollected
	ball.collected = false
end

local function hideBall(ball)
	--print("hide "..ball.name)
	ball.alpha = 0 -- hide ball
	ball.x, ball.y = -100, -100 -- move ball offscreen
	timer.performWithDelay(1000, function() showBall(ball) end, 1)
end

local function placeBall()
	local ball = newBall()
	showBall(ball)
	return ball
end

-- Called when the scene's view does not exist:
function scene:createScene( event )
	local group = self.view

	-- create a grey rectangle as the backdrop
	local background = display.newRect( 0, 0, screenW, screenH )
	background:setFillColor( 128 )
	
	-- Dog
	dog = display.newImageRect( "dog_run.png", 100, 45 ) -- make dog
	dog.x, dog.y = 160, 100 -- position dog
	dog.rotation = 15 -- rotate slightly
	physics.addBody( dog, { density=1.0, friction=0.3, bounce=0.3 } )-- add physics to the dog
	dog.angularVelocity = dogAngularVelocity -- dog starts off circling
	dog.name = "dog" -- name dog

	-- Ball
	local ball = placeBall()

	-- Walls
	local wallWidth = 10
	local wallParameters = { density=1.0, friction=0.3, bounce=0.3 }
	local topWall = display.newRect(0, 0, screenW, wallWidth)
	local bottomWall = display.newRect(0, screenH-wallWidth, screenW, wallWidth)
	local leftWall = display.newRect(0,0,wallWidth,screenH)
	local rightWall = display.newRect(screenW-wallWidth,0,wallWidth,screenH)
	physics.addBody( topWall, "static", wallParameters )
	physics.addBody( bottomWall, "static", wallParameters )
	physics.addBody( leftWall, "static", wallParameters )
	physics.addBody( rightWall, "static", wallParameters )
	topWall.name = "top wall"
	bottomWall.name = "bottom wall"
	leftWall.name = "left wall"
	rightWall.name = "right wall"
	
	-- Score
	local scoreTextOffset = 20
	scoreText = display.newText(score.." balls", 0, 0, native.systemFont, 16)
	scoreText:setReferencePoint(display.TopRightReferencePoint)
	scoreText:setTextColor(0) -- white by default
	scoreText.x = screenW - scoreTextOffset
	scoreText.y = scoreTextOffset
	--scoreText.alpha = 0
	
	-- Energy
	local meterWidth = 25
	local barWidth = meterWidth * 0.75
	local meterOffset = wallWidth * 1.25
	local barDiff = (meterWidth-barWidth)
	local energyBackground = display.newRect(0,0,meterWidth*maxEnergy+barDiff,meterWidth)
	local energyMeter = display.newGroup()
	barOffset = barDiff/2
	energyMeter.x, energyMeter.y = meterOffset, meterOffset
	energyBackground:setFillColor(80)
	energyBar = display.newRect(0,0,(meterWidth*energy),barWidth)
	energyBar:setReferencePoint(display.TopLeftReferencePoint)
	energyBar.x, energyBar.y = barOffset,barOffset
	energyBar:setFillColor(0,220,0)
	energyMeter:insert(energyBackground)
	energyMeter:insert(energyBar)
	
	-- all display objects must be inserted into group
	group:insert( background )
	group:insert( topWall )
	group:insert( bottomWall )
	group:insert( leftWall )
	group:insert( rightWall )
	group:insert( scoreText )
	group:insert( energyMeter )
	group:insert( ball )
	group:insert( dog )
end

-- touch event listener function 
local function run( event )
	--print(event.phase) -- event phases: began, moved, ended
	if (event.phase == "began") then
		dog.angularVelocity = 0 
		-- Change dog's linear velocity based on current angle
		-- Apply impulse based on facing direction
		--dog:setLinearVelocity( 10,0 )
		local deg = dog.rotation % 360
		local rad = deg * math.pi / 180 -- 1pi rad = 180 deg
		local v = 100
		local vx, vy =  math.cos(rad)*v, math.sin(rad)*v -- value for a given value in radians
		--print(rad)
		--print("vx"..vx.." vy"..vy)
		dog:applyLinearImpulse( vx, vy, dog.x, dog.y )
		--dog:translate(vx, vy)
		dog.linearDamping = 0
		-- Depleat energy
		energy = energy - 0.5
		showEnergy()
	end
	if (event.phase == "ended") then
		dog.angularVelocity = dogAngularVelocity
		dog.linearDamping = 5
	end
end

local function collectBall( ball2Collect )
	if ball2Collect.collected == false then
		ball2Collect.collected = true
		score = score + 1
		showScore()
		timer.performWithDelay(1, function() hideBall(ball2Collect) end, 1)
	end
end
	

local function onCollision( event )
    if ( event.phase == "began" ) then
        --print( "began: " .. event.object1.name .. " & " .. event.object2.name )
		if event.object1.name == "dog" and event.object2.type == "collect" then
			collectBall(event.object2)
		end
    elseif ( event.phase == "ended" ) then
        --print( "ended: " .. event.object1.name .. " & " .. event.object2.name )
    end
end

-- listener function to check every frame if game is over
local function onEveryFrame( event )
	-- depleat dog's energy slowly over time
	energy = energy - 0.01
	showEnergy()
	if energy <= 0 then
		--print( "Game Over." )
		storyboard.gotoScene( "menu", "zoomOutIn", 500 )
		Runtime:removeEventListener( "enterFrame", onEveryFrame )
	end
end

-- Called immediately after scene has moved onscreen:
function scene:enterScene( event )
	local group = self.view
	
	-- Reset energy to full
	energy = 10
	showEnergy()
	
	-- Reset score to 0
	score = 0
	showScore()
	
	Runtime:addEventListener( "touch", run )
	Runtime:addEventListener( "collision", onCollision )
	Runtime:addEventListener( "enterFrame", onEveryFrame ) -- check for end of game
	
	physics.start()
	
end

-- Called when scene is about to move offscreen:
function scene:exitScene( event )
	local group = self.view
	
	--physics.stop()
	physics.pause()
	
	Runtime:removeEventListener( "touch", run )
	Runtime:removeEventListener( "collision", onCollision )
	
end

-- If scene's view is removed, scene:destroyScene() will be called just prior to:
function scene:destroyScene( event )
	local group = self.view
	
	package.loaded[physics] = nil
	physics = nil
end

-----------------------------------------------------------------------------------------
-- END OF YOUR IMPLEMENTATION
-----------------------------------------------------------------------------------------

-- "createScene" event is dispatched if scene's view does not exist
scene:addEventListener( "createScene", scene )

-- "enterScene" event is dispatched whenever scene transition has finished
scene:addEventListener( "enterScene", scene )

-- "exitScene" event is dispatched whenever before next scene's transition begins
scene:addEventListener( "exitScene", scene )

-- "destroyScene" event is dispatched before view is unloaded, which can be
-- automatically unloaded in low memory situations, or explicitly via a call to
-- storyboard.purgeScene() or storyboard.removeScene().
scene:addEventListener( "destroyScene", scene )

-----------------------------------------------------------------------------------------

return scene