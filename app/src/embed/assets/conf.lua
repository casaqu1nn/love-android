function love.conf(t)
    t.window.title = "CubeClicker"
    t.window.resizable = true
    t.window.highdpi = true
    t.window.fullscreen = true
    t.window.vsync = 1
    
    t.graphics.renderers = {"opengl"}

    -- Android packaging (used when exporting this project as an APK)
    t.packageName = "com.app.cubeclicker"
    -- auto | portrait | landscape | sensorLandscape
    t.screenOrientation = "landscape"
end