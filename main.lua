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

local GameStatuses = {
    MENU = 1,
    PLAYING = 2,
    GAME_OVER = -1,
}

local flashDuration = 0.5

-- Основные переменные
local pipes = {}
local pipeSpeed = 200
local pipeInterval = 2
local timeSinceLastPipe = 0
local score = 0
local gameState = GameStatuses.MENU

-- Создание птицы
local bird = {}

local function playBackgroundMusic()
    -- Запускаем дискотеку
    music:setLooping(true) -- so it doesnt stop
    music:play()
end

local function gameOver()
    gameState = GameStatuses.GAME_OVER
    music:stop()
    bird:die()
    damageSounds[love.math.random(1, #damageSounds)]:play()
end

local function resetGame()
    bird.y = Settings.window.height / 2
    bird.speed = 0
    bird.rotation.current = math.rad(0)
    bird.timeFromLastSwing = 0
    flashDuration = 0.5
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
    -- Получим реальные координаты
    local bx = bird:getX()
    local by = bird:getY()

    -- Проверка столкновения с нижней границей
    if by + bird.height > Settings.window.height then
        return true
    end

    -- Проверка столкновнеия с верхней границей
    if by < 0 then
        return true
    end

    for _, pipe in ipairs(pipes) do
        if bx + bird.width > pipe.x and bx < pipe.x + pipe.width then
            -- Проверка столкновения с верхней трубой
            if by < pipe.topY then
                return true
            end

            -- Проверка столкновения с нижней трубой
            if by + bird.height > pipe.bottomY then
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
    if gameState == GameStatuses.MENU then return end

    if bird:getY() + bird.height > Settings.window.height then
        return true
    end

    bird:update(dt)

    if gameState == GameStatuses.GAME_OVER then return end

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

    if gameState == GameStatuses.MENU then
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Flappy Bird", 0, Settings.window.height / 2 - 200, Settings.window.width, "center")
        love.graphics.printf("Press SPACE to Start", 0, Settings.window.height / 2 - 150, Settings.window.width, "center")
        return
    end

    if gameState == GameStatuses.GAME_OVER then
        -- рисуем вспышку
        flashDuration = flashDuration - 0.1
        if flashDuration > 0 then
            local r, g, b = love.math.colorFromBytes(255, 255, 255)
            love.graphics.setColor(r, g, b, flashDuration)
            love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        end

        -- рисуем меню
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
    if gameState == GameStatuses.PLAYING then
        if key == "space" then
            bird:flap()
        end
    end

    -- Обработка меню
    if gameState == GameStatuses.MENU then
        if key == "space" then
            gameState = GameStatuses.PLAYING
            playBackgroundMusic()
        end
    end

    -- Обработка окончания игры
    if gameState == GameStatuses.GAME_OVER then
        if key == "r" then
            resetGame()
            gameState = GameStatuses.PLAYING

            respawnSounds[love.math.random(1, #respawnSounds)]:play()
            playBackgroundMusic()
        end

        if key == "q" then
            love.event.quit()
        end
    end
end
