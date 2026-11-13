
local cubes = {}
local particles = {}

local clicks = 0
local spawnThreshold = 25

local cubeSize = 40
local font

-- Contador
local counterScale = 1
local counterVelocity = 0

-- Save
local saveTimer = 0
local saveInterval = 5

-- Audio
local popSounds = {}
local soundIndex = 1

-- Criar som procedural
local function createPop()
    local rate = 22050
    local duration = 0.12
    local samples = math.floor(rate * duration)

    local soundData = love.sound.newSoundData(
        samples, rate, 16, 1
    )

    local frequency = math.random(350, 650)

    for i = 0, samples - 1 do
        local t = i / rate

        local envelope = math.exp(-t * 28)

        local currentFrequency = frequency * (1 - t * 2)

        local wave = math.sin(
            2 * math.pi * currentFrequency * t
        )

        soundData:setSample(
            i,
            wave * envelope * 0.35
        )
    end

    return love.audio.newSource(soundData, "static")
end

-- Reproduzir POP aleatório
local function playPop()
    local sound = popSounds[soundIndex]

    sound:stop()

    sound:setPitch(math.random(85, 115) / 100)
    sound:setVolume(math.random(80, 100) / 100)

    sound:play()

    soundIndex = soundIndex + 1

    if soundIndex > #popSounds then
        soundIndex = 1
    end
end

local function spawnCube(x, y, instant)
    table.insert(cubes, {
        x = x,
        y = y,
        size = cubeSize,
        scale = instant and 1 or 0,
        targetScale = 1,
        shake = 0
    })

    -- Som ao nascer
    playPop()
end

-- SALVAR
local function saveGame()
    local data = {}

    table.insert(data, "CUBECLICKER1")
    table.insert(data, tostring(clicks))
    table.insert(data, tostring(spawnThreshold))
    table.insert(data, tostring(#cubes))

    for _, cube in ipairs(cubes) do
        table.insert(data, tostring(cube.x))
        table.insert(data, tostring(cube.y))
    end

    local success, message = love.filesystem.write(
        "save.txt",
        table.concat(data, "\n")
    )

    if not success then
        print("Erro ao salvar: " .. tostring(message))
    else
        print("Jogo salvo!")
    end
end

-- CARREGAR
local function loadGame()
    if not love.filesystem.getInfo("save.txt") then
        return false
    end

    local contents = love.filesystem.read("save.txt")

    if not contents then return false end

    local lines = {}

    for line in contents:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end

    if lines[1] ~= "CUBECLICKER1" then
        return false
    end

    local loadedClicks = tonumber(lines[2])
    local loadedThreshold = tonumber(lines[3])
    local cubeCount = tonumber(lines[4])

    if not loadedClicks or not loadedThreshold
    or not cubeCount or cubeCount < 1
    or cubeCount > 10000
    or loadedClicks < 0 or loadedThreshold < 1 then
        return false
    end

    if #lines ~= 4 + cubeCount * 2 then
        return false
    end

    local loadedCubes = {}

    for i = 1, cubeCount do
        local x = tonumber(lines[4 + i * 2 - 1])
        local y = tonumber(lines[4 + i * 2])

        if not x or not y then
            return false
        end

        table.insert(loadedCubes, {
            x = x,
            y = y,
            size = cubeSize,
            scale = 1,
            targetScale = 1,
            shake = 0
        })
    end

    clicks = loadedClicks
    spawnThreshold = loadedThreshold
    cubes = loadedCubes

    print("Save carregado!")

    return true
end

function love.load()
    love.window.setTitle("CUBE CLICKER")
    love.window.setMode(800, 600)

    font = love.graphics.newFont(24)

    math.randomseed(os.time())

    -- Preparar 12 variações de áudio
    for i = 1, 12 do
        table.insert(popSounds, createPop())
    end

    love.audio.setVolume(0.7)

    if not loadGame() then
        spawnCube(400, 300, true)
    end
end

-- PARTICULAS
local function createParticles(x, y)
    for i = 1, 12 do
        local angle = math.random() * math.pi * 2
        local speed = math.random(80, 220)

        table.insert(particles, {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            life = 0.5,
            maxLife = 0.5,
            size = math.random(3, 7)
        })
    end
end

-- COLISAO
local function isInside(cube, x, y)
    local s = cube.size * cube.scale

    return x >= cube.x - s / 2
       and x <= cube.x + s / 2
       and y >= cube.y - s / 2
       and y <= cube.y + s / 2
end

-- CLIQUE
function love.mousepressed(x, y, button)
    if button ~= 1 then return end

    table.sort(cubes, function(a, b)
        return a.y < b.y
    end)

    for i = #cubes, 1, -1 do
        local cube = cubes[i]

        if isInside(cube, x, y) then

            clicks = clicks + #cubes

            -- Som do clique
            playPop()

            -- POP do contador
            counterVelocity = -2.5

            -- Juice
            cube.shake = 0.12
            cube.scale = 0.85

            createParticles(x, y)

            -- Novo cubo
            if clicks >= spawnThreshold then

                spawnThreshold = math.ceil(
                    spawnThreshold * 1.6
                )

                local w, h = love.graphics.getDimensions()

                local nx = math.random(50, w - 50)
                local ny = math.random(110, h - 50)

                spawnCube(nx, ny)
            end

            break
        end
    end
end

function love.update(dt)

    -- SAVE AUTOMATICO
    saveTimer = saveTimer + dt

    if saveTimer >= saveInterval then
        saveGame()
        saveTimer = 0
    end

    -- CONTADOR
    local acceleration = (1 - counterScale) * 65

    counterVelocity = counterVelocity + acceleration * dt

    counterVelocity = counterVelocity *
        math.pow(0.88, dt * 60)

    counterScale = counterScale + counterVelocity * dt

    counterScale = math.max(
        0.7,
        math.min(1.5, counterScale)
    )

    -- CUBOS
    for _, cube in ipairs(cubes) do

        cube.scale = cube.scale +
            (cube.targetScale - cube.scale) * dt * 12

        if cube.shake > 0 then
            cube.shake = math.max(0, cube.shake - dt)
        end
    end

    -- PARTICULAS
    for i = #particles, 1, -1 do
        local p = particles[i]

        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt

        p.vx = p.vx * 0.96
        p.vy = p.vy * 0.96

        p.life = p.life - dt

        if p.life <= 0 then
            table.remove(particles, i)
        end
    end
end

function love.draw()

    love.graphics.clear(0, 0, 0)

    -- CONTADOR
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1)

    love.graphics.push()

    local w = love.graphics.getWidth()

    love.graphics.translate(w / 2, 37)
    love.graphics.scale(counterScale, counterScale)

    love.graphics.printf(
        "CLICKS: " .. clicks,
        -200, -12,
        400,
        "center"
    )

    love.graphics.pop()

    -- Y-SORT
    table.sort(cubes, function(a, b)
        return a.y < b.y
    end)

    -- CUBOS
    for _, cube in ipairs(cubes) do

        local s = cube.size * cube.scale
        local offsetX = 0

        if cube.shake > 0 then
            offsetX = math.random(-3, 3)
        end

        local x = cube.x - s / 2 + offsetX
        local y = cube.y - s / 2

        love.graphics.setColor(1, 1, 1)

        love.graphics.rectangle(
            "fill", x, y, s, s
        )

        love.graphics.setColor(0, 0, 0)
        love.graphics.setLineWidth(2)

        love.graphics.rectangle(
            "line", x, y, s, s
        )
    end

    -- PARTICULAS
    for _, p in ipairs(particles) do

        local alpha = p.life / p.maxLife

        love.graphics.setColor(
            1, 1, 1, alpha
        )

        love.graphics.rectangle(
            "fill",
            p.x,
            p.y,
            p.size,
            p.size
        )
    end

    love.graphics.setColor(1, 1, 1)
end

-- SALVAR AO FECHAR
function love.quit()
    saveGame()
end
