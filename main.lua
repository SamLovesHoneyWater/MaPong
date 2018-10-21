--[[
    GD50 2018
    Pong Assignment 0

    by Sam Huang
    sammy5673@hotmail.com

]]

push = require 'push'

Class = require 'class'

require 'Paddle'

require 'Ball'

WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

-- speed for paddle
PADDLE_SPEED = 200

AI_REFRESH_RATE = 0.2

-- check for LOVE version 11
IS_LOVE11 = love.getVersion() == 11

--[[
    Runs when the game first starts up, only once; used to initialize the game.
]]
function love.load()
    love.graphics.setDefaultFilter('nearest', 'nearest')

    love.window.setTitle('Pong')

    math.randomseed(os.time())

    timer = 0

    -- more "retro-looking" font object we can use for any text
    smallFont = love.graphics.newFont('font.ttf', 8)

    -- score font
    scoreFont = love.graphics.newFont('font.ttf',32)

    -- set LÖVE2D's active font to the smallFont obect
    love.graphics.setFont(smallFont)

    sounds = {
	    ['paddle_hit']=love.audio.newSource('sounds/paddle_hit.wav','static'),
	    ['score']=love.audio.newSource('sounds/score.wav','static'),
	    ['wall_hit']=love.audio.newSource('sounds/wall_hit.wav','static')
	}


    -- initialize window with virtual resolution
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = true,
        vsync = true
    })
    player1Score = 0
	player2Score = 0
	servingPlayer = math.random(0,1)

	player1 = Paddle(10,30,5,20,false)
	player2 = Paddle(VIRTUAL_WIDTH-10,VIRTUAL_HEIGHT-30,5,20,true)

	ball = Ball(VIRTUAL_WIDTH/2-2,VIRTUAL_HEIGHT/2-2,4,4)

	gameState = 'start'
end

function love.resize(w,h)
	push:resize(w,h)
end

function love.update(dt)
    -- player 1 movement
    if love.keyboard.isDown('w') then
        player1.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('s') then
        player1.dy = PADDLE_SPEED
    else
    	player1.dy = 0
    end

    -- player 2 movement
    if love.keyboard.isDown('up') then
        player2.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('down') then
        player2.dy = PADDLE_SPEED
    else
    	player2.dy = 0
    end

    if gameState == 'serve' then
    	ball.dy = math.random(-50,50)
    	if servingPlayer == 1 then
    		ball.dx = math.random(170,220)
    	else
    		ball.dx = -math.random(170,220)
    	end

	elseif gameState == 'play' then
    	if ball:collides(player1) then
    		sounds['paddle_hit']:play()
    		ball.dx = -ball.dx * 1.03
    		ball.x = player1.x + 5

	    	if ball.dy < 0 then
	    		ball.dy = -math.random(10,150)
	    	else
	    		ball.dy = math.random(10,150)
	    	end
    	end

    	if ball:collides(player2) then
    		sounds['paddle_hit']:play()
            ball.dx = -ball.dx * 1.03
            ball.x = player2.x - 4

            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end
        end

        if ball.y <= 0 then
        	sounds['wall_hit']:play()
        	ball.dy = -ball.dy
        	ball.y = 0
        end

        if ball.y >= VIRTUAL_HEIGHT - 4 then
        	sounds['wall_hit']:play()
        	ball.dy = -ball.dy
        	ball.y = VIRTUAL_HEIGHT - 4
        end

        if ball.x < 0 then
        	sounds['score']:play()
            servingPlayer = 1
            player2Score = player2Score + 1

            -- if we've reached a score of 10, the game is over; set the
            -- state to done so we can show the victory message
            if player2Score == 10 then
                winner= 2
                gameState = 'done'
            else
                gameState = 'serve'
                -- places the ball in the middle of the screen, no velocity
                ball:reset()
            end
        end

        if ball.x > VIRTUAL_WIDTH then
        	sounds['score']:play()
            servingPlayer = 2
            player1Score = player1Score + 1

            if player1Score == 10 then
                winner= 1
                gameState = 'done'
            else
                gameState = 'serve'
                ball:reset()
            end
        end

    	ball:update(dt)
    end

    timer = timer + dt
    if timer > AI_REFRESH_RATE then
        if player1.isAI then player1:update(dt) end
        if player2.isAI then player2:update(dt) end
        timer = timer % AI_REFRESH_RATE
        
    end

    if not player1.isAI then player1:update(dt) end
    if not player2.isAI then player2:update(dt) end
end



--[[
    Keyboard handling, called by LÖVE2D each frame; 
    passes in the key we pressed so we can access.
]]
function love.keypressed(key)
    -- keys can be accessed by string name
    if key == 'escape' then
        -- function LÖVE gives us to terminate application
        love.event.quit()
    elseif key == 'enter' or key == 'return' then
    	if gameState == 'start' then
    		gameState = 'serve'
    	elseif gameState == 'serve' then
    		gameState = 'play'
    	elseif gameState == 'done' then
    		gameState = 'serve'
    		ball:reset()
    		player1Score = 0
    		player2Score = 0
    		if winner == 1 then
    			servingPlayer = 2
    		else
    			servingPlayer = 1
    		end
    	end
    end
end

--[[
    Called after update by LÖVE2D, used to draw anything to the screen, 
    updated or otherwise.
]]
function love.draw()
    -- begin rendering at virtual resolution
    push:apply('start')

    --[[
        LOVE 11 changed the color value range from 0-255 to 0-1
    ]]
    local r, g, b, a =
        (IS_LOVE11 and 40 / 255) or 40,
        (IS_LOVE11 and 45 / 255) or 45,
        (IS_LOVE11 and 52 / 255) or 52,
        (IS_LOVE11 and 255 / 255) or 255

    -- clear the screen with a specific color; in this case, a color similar
    -- to some versions of the original Pong
    love.graphics.clear(r, g, b, a)

    if gameState == 'start' then
        love.graphics.setFont(smallFont)
        love.graphics.printf('Welcome to Pong!', 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Enter to begin!', 0, 20, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'serve' then
        love.graphics.setFont(smallFont)
        love.graphics.printf('Player ' .. tostring(servingPlayer) .. "'s serve!", 
            0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Enter to serve!', 0, 20, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'play' then
        -- no UI messages to display in play
    elseif gameState == 'done' then
        -- UI messages
        love.graphics.setFont(scoreFont)
        love.graphics.printf('Player ' .. tostring(winner) .. ' wins!',
            0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf('Press Enter to restart!', 0, 50, VIRTUAL_WIDTH, 'center')
    end

    player1:render()
    player2:render()
    ball:render()
 	
 	displayFPS()	

 	displayScore()
    -- end rendering at virtual resolution
    push:apply('end')
end

function displayFPS()
	love.graphics.setFont(smallFont)
	love.graphics.setColor(0,1,0,1)
	love.graphics.print('FPS:'..tostring(love.timer.getFPS()),10,10)
end

function displayScore()
    -- score display
    love.graphics.setFont(scoreFont)
    love.graphics.setColor(1,1,1,1)
    love.graphics.print(tostring(player1Score), VIRTUAL_WIDTH / 2 - 50,
        VIRTUAL_HEIGHT / 3)
    love.graphics.print(tostring(player2Score), VIRTUAL_WIDTH / 2 + 30,
        VIRTUAL_HEIGHT / 3)
end