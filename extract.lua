-- extraction_simple.lua
-- 纯撤离点：不需要loot，成功后传送到 0 200 0

local monitor = peripheral.find("monitor") or term
local speaker = peripheral.find("speaker")
local redstoneSide = "back"   -- 修改成你红石输出的面（back / top / left 等）

local EXTRACTION_TIME = 45    -- 撤离等待时间（秒），可自行修改

function clearMonitor()
    monitor.clear()
    monitor.setCursorPos(1, 1)
end

function printCentered(text, line)
    if not monitor then return end
    local w = monitor.getSize()
    monitor.setCursorPos(math.floor((w - #text) / 2) + 1, line)
    monitor.write(text)
end

while true do
    clearMonitor()
    printCentered("=== 撤离点 ===", 2)
    printCentered("等待玩家进入...", 4)

    -- 等待玩家进入（优先用 Advanced Peripherals）
    local detector = peripheral.find("playerDetector")
    local playerName = nil

    repeat
        if detector then
            local players = detector.getPlayersInRange(8)  -- 调整检测范围（方块）
            if #players > 0 then
                playerName = players[1]
            end
        else
            -- 没有 playerDetector 时，用红石触发（压力板连到 computer）
            os.pullEvent("redstone")
            playerName = "玩家"  -- 简化处理
        end
        sleep(0.5)
    until playerName

    -- 开始撤离流程
    clearMonitor()
    printCentered("检测到玩家: " .. playerName, 2)
    printCentered("正在撤离...", 4)
    
    if speaker then speaker.playSound("minecraft:ui.toast.in", 1, 1) end

    local success = true
    for t = EXTRACTION_TIME, 0, -1 do
        clearMonitor()
        printCentered("撤离倒计时: " .. t .. " 秒", 3)
        printCentered("请保持在区域内！", 5)

        -- 检查是否还在区域
        if detector then
            local playersNow = detector.getPlayersInRange(8)
            if #playersNow == 0 or playersNow[1] ~= playerName then
                success = false
                break
            end
        end

        sleep(1)
    end

    if success then
        clearMonitor()
        printCentered("撤离成功！", 3)
        printCentered("正在传送至安全点...", 5)

        if speaker then 
            speaker.playSound("minecraft:entity.player.levelup", 1, 1) 
        end

        redstone.setOutput(redstoneSide, true)   -- 触发红石（可接灯/特效）
        sleep(1.5)

        -- 关键：传送玩家到 0 200 0
        commands.exec("tp " .. playerName .. " 0 200 0")

        redstone.setOutput(redstoneSide, false)
        sleep(2)
    else
        clearMonitor()
        printCentered("撤离失败！", 3)
        printCentered("已离开区域", 5)
        if speaker then speaker.playSound("minecraft:entity.generic.explode", 1, 0.8) end
        sleep(2)
    end

    sleep(3)  -- 重置等待
end
