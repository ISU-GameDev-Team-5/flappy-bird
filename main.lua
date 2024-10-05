require "settings"
local Bird = require "objects.bird"

-- Константы для спрайтов
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
local pipes = {}
local pipeSpeed = 200
local pipeInterval = 2
local timeSinceLastPipe = 0
local score = 0
local gameState = "menu" -- menu, playing, gameover

-- Создание птицы
local bird = {}

local function playBackgroundMusic()
    -- Запускаем дискотеку
    music:setLooping(true) -- so it doesnt stop
    music:play()
end

local function gameOver()
    gameState = "gameover"
    music:stop()
    damageSounds[love.math.random(1, #damageSounds)]:play()
end

local function resetGame()
    bird.y = Settings.window.height / 2
    bird.speed = 0
    bird.rotation.current = 0
    pipes = {}
    timeSinceLastPipe = 0
    score = 0
end

local function spawnPipe()
    local pipeGap = 150
    local topHeight = love.math.random(50, Settings.window.height - pipeGap - 50)
    local bottomHeight = Settings.window.height - topHeight - pipeGap
    local pipe = {
        x = Settings.window.width,
        width = pipeSprite:getWidth(),
        topY = topHeight,
        bottomY = Settings.window.height - bottomHeight
    }
    table.insert(pipes, pipe)
end


-- Проверим, врезалась ли птичка куда-то
local function isBirdCrashed()
    -- Проверка столкновения с нижней границей
    if bird.y + bird.sprite:getHeight() > Settings.window.height then
        return true
    end

    -- Проверка столкновнеия с вернхней границей
    if bird.y < 0 then
        return true
    end

    local pipeXOffset = 32

    for _, pipe in ipairs(pipes) do
        if bird.x + bird.sprite:getWidth() > pipe.x + pipeXOffset and bird.x < pipe.x + pipe.width + pipeXOffset then
            -- Проверка столкновения с верхней трубой
            -- используем высоту / 2 для того чтобы птичка не проходила в верхнюю трубу
            if bird.y < pipe.topY + bird.sprite:getHeight() / 2 then
                print("bird crashes top pipe")
                return true
            end

            -- Проверка столкновения с нижней трубой
            if bird.y + bird.sprite:getHeight() > pipe.bottomY then
                print("bird down pipe")
                return true
            end
        end
    end

    return false
end

function love.load()
    bird = Bird:new(100, Settings.window.height / 2, love.graphics.newImage("assets/sprites/bird.png"))

    -- Загрузка спрайтов
    pipeSprite = love.graphics.newImage("assets/sprites/pipe.png")
    backgroundSprite = love.graphics.newImage("assets/sprites/background.png")

    -- Установка окна
    love.window.setTitle("Flappy Bird Game")
    love.window.setMode(Settings.window.width, Settings.window.height)
    love.graphics.setFont(love.graphics.newFont("assets/fonts/PixelifySans.ttf", 30))

    resetGame()
end

function love.update(dt)
    if gameState == "menu" or gameState == "gameover" then return end

    -- Передвижение труб
    for i = #pipes, 1, -1 do
        pipes[i].x = pipes[i].x - pipeSpeed * dt

        -- Удаление труб, которые вышли за пределы экрана
        if pipes[i].x + pipes[i].width < 0 then
            table.remove(pipes, i)
            score = score + 1
        end
    end

    if isBirdCrashed() then
        gameOver()
    end

    bird:update(dt)

    timeSinceLastPipe = timeSinceLastPipe + dt
    if timeSinceLastPipe > pipeInterval then
        timeSinceLastPipe = 0
        spawnPipe()
    end
end

function love.draw()
    love.graphics.draw(backgroundSprite, 0, 0)

    bird:draw()

    for _, pipe in ipairs(pipes) do
        love.graphics.draw(pipeSprite, pipe.x, pipe.topY, 0, 1, -1) -- Вверх ногами для верхней трубы
        love.graphics.draw(pipeSprite, pipe.x, pipe.bottomY)
    end

    if gameState == "menu" then
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Flappy Bird", 0, Settings.window.height / 2 - 200, Settings.window.width, "center")
        love.graphics.printf("Press SPACE to Start", 0, Settings.window.height / 2 - 150, Settings.window.width, "center")
        return
    end

    if gameState == "gameover" then
        local r, g, b = love.math.colorFromBytes(132, 193, 238)
        love.graphics.setColor(r, g, b, 0.75)
        love.graphics.rectangle("fill", Settings.window.width / 2 - 150, 30, 300, 300)

        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Game Over", 0, Settings.window.height / 2 - 200, Settings.window.width, "center")
        love.graphics.printf("Score: " .. score, 0, Settings.window.height / 2 - 150, Settings.window.width, "center")
        love.graphics.printf("[R]estart", 0, Settings.window.height / 2 - 50, Settings.window.width, "center")
        love.graphics.printf("[Q]uit", 0, Settings.window.height / 2, Settings.window.width, "center")
        return
    end

    love.graphics.print("Score: " .. score, 10, 10)
end

function love.keypressed(key)
    -- Обработка игры
    if gameState == "playing" then
        if key == "space" then
            bird:flap()
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
