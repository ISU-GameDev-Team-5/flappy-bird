-- object/bird.lua


local Bird = {}
Bird.__index = Bird

function Bird:new(x, y, sprite)
    local instance = setmetatable({}, Bird)

    instance.x = x or 0
    instance.y = y or 0
    instance.speed = 100
    instance.sprite = sprite

    -- Параметры наклона
    instance.rotation = {
        current = 0,
        limit = {
            up = -math.rad(20),
            down = math.rad(90),
        },
        timeout = 0.4,
        speed = 4,
        acceleration = 2  -- ускорение в секунду
    }

    instance.timeFromLastSwing = 0.0  -- время прошедшее с последнего взмаха

    return instance
end

function Bird:draw()
    love.graphics.draw(
        self.sprite,
        self.x,
        self.y,
        self.rotation.current,
        1, 1, -- scale
        self.sprite:getWidth() / 2,
        self.sprite:getHeight() / 2
    )
end

function Bird:__updateRotation(dt)
    self.rotation.current = math.max(
        self.rotation.limit.up,
        math.min(
            self.rotation.limit.down,
            self.rotation.current + self.rotation.speed * self.rotation.acceleration * dt
        )
    )
end

function Bird:update(dt)
    self.speed = self.speed + Settings.gravity * dt
    self.speed = math.min(700, self.speed)

    self.y = self.y + self.speed * dt

    if self.speed < 0 then
        self:__updateRotation(dt)
    elseif self.timeFromLastSwing > self.rotation.timeout then
        self.rotation.speed = 4
        self:__updateRotation(dt)
    end

    self.rotation.speed = self.rotation.speed + self.rotation.acceleration * dt
    self.timeFromLastSwing = self.timeFromLastSwing + dt
end

-- взмах крыльями
function Bird:flap()
    self.speed = -500
    self.rotation.speed = -16
    self.timeFromLastSwing = 0
end

function Bird:die()
    self.speed = 1000
end

return Bird
