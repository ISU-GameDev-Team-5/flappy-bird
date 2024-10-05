-- object/bird.lua


local Bird = {}
Bird.__index = Bird

function Bird:new(x, y, sprite)
    local instance = setmetatable({}, Bird)

    instance.x = x or 0
    instance.y = y or 0
    instance.speed = 0
    instance.sprite = sprite

    instance.width = sprite:getWidth()
    instance.height = sprite:getHeight()

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
        self.width / 2,
        self.height / 2
    )
end

-- получаем x с учетом смещения спрайта
function Bird:getX()
    return self.x - self.width / 2
end

-- получаем y с учетом смещения спрайта
function Bird:getY()
    return self.y - self.height / 2
end

local function updateRotation(self, dt)
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
        updateRotation(self, dt)
    elseif self.timeFromLastSwing > self.rotation.timeout then
        self.rotation.speed = 4
        updateRotation(self, dt)
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

-- птичку жалко :(
function Bird:die()
    self.speed = 0
    self.rotation.current = self.rotation.limit.down
end

return Bird
