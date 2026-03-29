-- extraction_simple_v2.lua
-- 纯撤离点：无需loot物品，成功后传送至 0 200 0
-- 优化了 playerDetector 检测逻辑，兼容 Advanced Peripherals

local monitor = peripheral.find("monitor") or term
local speaker = peripheral.find("speaker")
local redstoneSide = "back"          -- ← 修改成你的红石输出面
local detector = peripheral.find("playerDetector")

local EXTRACTION_TIME = 45           -- 撤离倒计时秒数，可改
local DETECT_RANGE = 8               -- 检测范围（方块），可改大一点

function clearMonitor()
    if monitor and monitor.clear then
        monitor.clear()
        monitor.setCursorPos(1, 1)
    else
        term.clear()
        term.setCursorPos(1, 1)
    end
end

function printCentered(text, line)
    if not monitor or not monitor.getSize then 
        print(text)
        return 
    end
    local w = monitor.getSize()
    monitor.setCursorPos(math.floor((w - #text) / 2) + 1, line)
    monitor.write(text)
end

while true do
    clearMonitor()
    printCentered("=== 撤离点 ===", 2)
    printCentered("等待玩家进入...", 4)

    local playerName = nil

    -- 等待玩家进入区域
    repeat
        if detector then
            local players = detector.getPlayersInRange(DETECT_RANGE)
            if players and #players > 0 then
                playerName = players[1]   -- 取第一个检测到的玩家
            end
        else
            -- 没有 playerDetector 时用红石触发
            os.pullEvent("redstone")
            playerName = "玩家"
        end
        sleep(0.5)
    until playerName

    -- 开始撤离流程
    clearMonitor()
    printCentered("检测到: " .. playerName, 2)
    printCentered("正在撤离...", 4)
    
    if speaker then speaker.playSound("minecraft:ui.toast.in", 1, 1) end

    local success = true
    for t = EXTRACTION_TIME, 0, -1 do
        clearMonitor()
        printCentered("撤离倒计时: " .. t .. " 秒", 3)
        printCentered("请保持在区域内！", 5)

        -- 检查玩家是否还在区域
        if detector then
            local currentPlayers = detector.getPlayersInRange(DETECT_RANGE)
            local stillHere = false
            for _, p in ipairs(currentPlayers) do
                if p == playerName then
                    stillHere = true
                    break
                end
            end
            if not stillHere then
                success = false
                break
            end
        end

        sleep(1)
    end

    if success then
        clearMonitor()
        printCentered("撤离成功！", 3)
        printCentered("正在传送...", 5)

        if speaker then speaker.playSound("minecraft:entity.player.levelup", 1, 1) end

        redstone.setOutput(redstoneSide, true)
        sleep(1)

        -- 传送玩家到 0 200 0
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

    sleep(3)  -- 重置
end
