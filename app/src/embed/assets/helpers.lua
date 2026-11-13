local helpers = {}

local function safeInsets()
    if love.window and love.window.getSafeArea then
        local x, y = love.window.getSafeArea()
        return x or 0, y or 0
    end
    return 0, 0
end

function helpers.drawStats()
    local major, minor, revision = love.getVersion()
    local x, y = safeInsets()

    love.graphics.print("FPS: " .. love.timer.getFPS(), x + 10, y + 10)
    love.graphics.print(string.format("LÖVE %d.%d.%d", major, minor, revision), x + 10, y + 20)
end

return helpers
