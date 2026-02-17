#!/usr/bin/swift

// Required parameters:
// @raycast.schemaVersion 1
// @raycast.title Jump Cursor to Next Screen 
// @raycast.mode silent
// @raycast.packageName Mouse Jump 

// Optional parameters:
// @raycast.icon 🖥️

import ApplicationServices
import CoreGraphics
import Foundation

// 1. 获取屏幕列表
var displayCount: UInt32 = 0
var activeDisplay = CGMainDisplayID()
CGGetActiveDisplayList(0, nil, &displayCount)

// 如果只有一个屏幕，直接退出
if displayCount <= 1 {
    exit(0)
}

var displays = [CGDirectDisplayID](repeating: 0, count: Int(displayCount))
CGGetActiveDisplayList(displayCount, &displays, &displayCount)

// 2. 找到鼠标当前所在的屏幕
// 使用 CGEvent 获取的坐标是【全局坐标】
let mouseLocation = CGEvent(source: nil)?.location ?? CGPoint.zero
var currentDisplayId: CGDirectDisplayID = displays[0]

for display in displays {
    let bounds = CGDisplayBounds(display)
    if bounds.contains(mouseLocation) {
        currentDisplayId = display
        break
    }
}

// 3. 计算“下一个”屏幕
guard let currentIndex = displays.firstIndex(of: currentDisplayId) else { exit(1) }
let nextIndex = (currentIndex + 1) % displays.count
let nextDisplayId = displays[nextIndex]

// 4. 计算新屏幕的中心点
// CGDisplayBounds 返回的也是【全局坐标】，这正是我们需要的
let nextBounds = CGDisplayBounds(nextDisplayId)
let centerPoint = CGPoint(x: nextBounds.midX, y: nextBounds.midY)

// 5. 【关键修改】使用 CGWarpMouseCursorPosition
// 这个 API 接受全局坐标，无需把坐标转换成屏幕内的相对坐标
// 这样无论屏幕是横是竖，怎么排列，它都能准确飞到中心
CGWarpMouseCursorPosition(centerPoint)

// 补充：模拟一次微小的移动事件，确保系统刷新光标状态（解决有时候光标不显示的问题）
// 不加这一步在某些系统版本上光标虽然过去了，但如果不动一下鼠标，光标是不可见的
if let moveEvent = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: centerPoint, mouseButton: .left) {
    moveEvent.post(tap: .cghidEventTap)
}
