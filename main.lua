-- Константы для спрайтов
local birdSprite
local pipeSprite
local backgroundSprite

-- МЬЮЗИК
local music = love.audio.newSource("assets/audio/sledstvie-veli-theme.mp3", "static")
local respawnSounds = {
    love.audio.newSource("assets/audio/sounds/respawn/1.mp3", "static"),
    love.audio.newSource("assets/audio/sounds/respawn/2.mp3", "static"),
    love.audio.newSource("assets/audio/sounds/respawn/3.mp3", "static"),
}
local damageSounds = {
    love.audio.newSource("assets/audio/sounds/damage/1.mp3", "static"),
}

-- Основные переменные
local bird = {}
local pipes = {}
local gravity = 1500
local pipeSpeed = 200
local pipeInterval = 2
local timeSinceLastPipe = 0
local score = 0
local gameState = "menu" -- menu, playing, gameover

-- Размеры окна
local window_width = 800
local window_height = 500

-- Параметры наклона
local maxTiltUp = -math.rad(25)
local maxTiltDown = math.rad(45)
local tiltSpeed = 5

function love.load()
    -- Загрузка спрайтов
    birdSprite = love.graphics.newImage("assets/sprites/bird.png")
    pipeSprite = love.graphics.newImage("assets/sprites/pipe.png")
    backgroundSprite = love.graphics.newImage("assets/sprites/background.png")

    -- Установка окна
    love.window.setTitle("Flappy Bird Game")
    love.window.setMode(window_width, window_height)
    love.graphics.setFont(love.graphics.newFont("assets/fonts/PixelifySans.ttf", 30))


    -- Параметры птицы
    bird.x = 100
    bird.y = window_height / 2
    bird.width = birdSprite:getWidth()
    bird.height = birdSprite:getHeight()
    bird.speedY = 0
    bird.rotation = 0  -- Начальный угол наклона

    resetGame()
end

function love.update(dt)
    if gameState == "menu" or gameState == "gameover" then return end

    if isBirdCrashed(bird) then
        gameOver()
    end

    -- Падение птицы под действием гравитации
    bird.speedY = bird.speedY + gravity * dt
    bird.y = bird.y + bird.speedY * dt

    print(bird.y, bird.speedY)

    -- Обновление наклона птицы в зависимости от скорости
    bird.rotation = bird.rotation + tiltSpeed * (bird.speedY < 0 and -1 or 1) * dt

    -- Ограничение угла наклона
    bird.rotation = math.max(maxTiltUp, math.min(maxTiltDown, bird.rotation))

    timeSinceLastPipe = timeSinceLastPipe + dt
    if timeSinceLastPipe > pipeInterval then
        timeSinceLastPipe = 0
        spawnPipe()
    end

    -- Передвижение труб
    for i = #pipes, 1, -1 do
        pipes[i].x = pipes[i].x - pipeSpeed * dt

        -- Удаление труб, которые вышли за пределы экрана
        if pipes[i].x + pipes[i].width < 0 then
            table.remove(pipes, i)
            score = score + 1
        end
    end
end

function love.draw()
    love.graphics.draw(backgroundSprite, 0, 0)

    -- отрисовка игры
    love.graphics.draw(birdSprite, bird.x, bird.y, bird.rotation, 1, 1, bird.width / 2, bird.height / 2)

    for _, pipe in ipairs(pipes) do
        love.graphics.draw(pipeSprite, pipe.x, pipe.topY, 0, 1, -1) -- Вверх ногами для верхней трубы
        love.graphics.draw(pipeSprite, pipe.x, pipe.bottomY)
    end

    if gameState == "menu" then
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Flappy Bird", 0, window_height / 2 - 200, window_width, "center")
        love.graphics.printf("Press SPACE to Start", 0, window_height / 2 - 150, window_width, "center")
        return
    end

    if gameState == "gameover" then
        r, g, b = love.math.colorFromBytes(132, 193, 238)
        love.graphics.setColor(r, g, b, 0.75)
        love.graphics.rectangle("fill", window_width / 2 - 150, 30, 300, 300)

        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Game Over", 0, window_height / 2 - 200, window_width, "center")
        love.graphics.printf("Score: " .. score, 0, window_height / 2 - 150, window_width, "center")
        love.graphics.printf("[R]estart", 0, window_height / 2 - 50, window_width, "center")
        love.graphics.printf("[Q]uit", 0, window_height / 2, window_width, "center")
        return
    end

    love.graphics.print("Score: " .. score, 10, 10)
end

function love.keypressed(key)
    -- Обработка игры
    if gameState == "playing" then
        if key == "space" then
            bird.speedY = -500
        end
    end

    -- Обработка меню
    if gameState == "menu" then
        if key == "space" then
            gameState = "playing"
            playBackgroundMusic()
        end
    end

    -- Обработка окончания игры
    if gameState == "gameover" then
        if key == "r" then
            resetGame()
            gameState = "playing"

            respawnSounds[love.math.random(1, #respawnSounds)]:play()
            playBackgroundMusic()
        end

        if key == "q" then
            love.event.quit()
        end
    end
end

function spawnPipe()
    local pipeGap = 150
    local topHeight = love.math.random(50, window_height - pipeGap - 50)
    local bottomHeight = window_height - topHeight - pipeGap
    local pipe = {
        x = window_width,
        width = pipeSprite:getWidth(),
        topY = topHeight,
        bottomY = window_height - bottomHeight
    }
    table.insert(pipes, pipe)
end


-- Проверим, врезалась ли птичка куда-то
function isBirdCrashed(bird)

    -- Проверка столкновения с нижней границей
    if bird.y + bird.height > window_height then
        bird.speedY = 0
        bird.y = window_height - bird.height - 1
        bird.rotation = 0

        return false
    end

    -- Проверка столкновнеия с вернхней границей
    if bird.y < 0 then
        bird.speedY = 0
        bird.y = 0
        return false
    end

    for _, pipe in ipairs(pipes) do
        if bird.x + bird.width > pipe.x and bird.x < pipe.x + pipe.width then
            -- Проверка столкновения с верхней трубой
            -- используем высоту / 2 для того чтобы птичка не проходила в верхнюю трубу
            if bird.y < pipe.topY + bird.height / 2 then
                print("bird crashes top pipe")
                return true
            end

            -- Проверка столкновения с нижней трубой
            if bird.y + bird.height > pipe.bottomY then
                print("bird down pipe")
                return true
            end
        end
    end

    return false
end

function gameOver()
    gameState = "gameover"
    music:stop()
    damageSounds[love.math.random(1, #damageSounds)]:play()
end

function resetGame()
    bird.y = window_height / 2
    bird.speedY = 0
    bird.rotation = 0
    pipes = {}
    timeSinceLastPipe = 0
    score = 0
end

function playBackgroundMusic()
    -- Запускаем дискотеку
    music:setLooping( true ) --so it doesnt stop
    music:play()
end