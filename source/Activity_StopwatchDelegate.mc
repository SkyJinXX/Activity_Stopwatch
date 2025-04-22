import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Application;

class Activity_StopwatchDelegate extends WatchUi.BehaviorDelegate {
    private var mView;
    private var mKeyPressedTime = 0;
    private var mIsKeyHeld = false;
    private const LONG_PRESS_THRESHOLD = 1000; // milliseconds
    private var mIsSwipeDetected = false;   // 用于追踪是否检测到滑动手势

    function initialize() {
        BehaviorDelegate.initialize();
    }
    
    // Set the view reference
    function setView(view) {
        mView = view;
    }

    // Handle Enter key (Start/Stop)
    function onSelect() as Boolean {
        mView.toggleStopwatch();
        return true;
    }
    
    // Handle Back key (Add lap)
    function onBack() as Boolean {
        System.println("onBack called");
        
        // 对于物理Back按键，按原有逻辑处理
        if (mView.mStopwatch.isRunning() || mView.mStopwatch.getElapsedTime() > 0) {
            mView.addLap();
            return true;
        }
        
        // 如果秒表停止且无累计时间，则退出
        return false;
    }
    
    // Handle Up key (Scroll up)
    function onPreviousPage() as Boolean {
        if (!mIsKeyHeld) {
            mView.scrollUp();
            return true;
        }
        return false;
    }
    
    // Handle Down key (Scroll down or save)
    function onNextPage() as Boolean {
        if (mView.mStopwatch.isRunning()) {
            mView.scrollDown();
        } else {
            mView.saveActivity();
        }
        return true;
    }

    // Handle physical button press
    function onKeyPressed(keyEvent) {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_UP) {
            mKeyPressedTime = System.getTimer();
            mIsKeyHeld = false;
            return true;
        }
        return false;
    }

    // Handle physical button release
    function onKeyReleased(keyEvent) {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_UP) {
            var pressDuration = System.getTimer() - mKeyPressedTime;
            if (pressDuration >= LONG_PRESS_THRESHOLD) {
                // Long press detected - exit to watch face
                mIsKeyHeld = true;
                System.println("Long press detected - exiting to watch face");
                
                // 使用手动退出方法
                exitToWatchFace();
                return true;
            }
        }
        return false;
    }

    // Handle swipe gestures
    function onSwipe(swipeEvent) {
        System.println("Swipe detected, direction=" + swipeEvent.getDirection());
        
        // 从右向左滑动时退出应用
        if (swipeEvent.getDirection() == WatchUi.SWIPE_LEFT) {
            System.println("Right-to-left swipe detected - exiting app");
            exitToWatchFace();
            return true;
        }
        return false;
    }

    // Disable touch screen except for swipes
    function onTap(clickEvent) {
        // Return true to consume the event without doing anything
        return true;
    }

    // 手动退出到表盘的方法
    function exitToWatchFace() {
        System.println("Executing exitToWatchFace");
        
        // 尝试多次弹出视图直到退出应用
        var popped = false;
        
        for (var i = 0; i < 3; i++) {
            if (WatchUi.popView(WatchUi.SLIDE_IMMEDIATE)) {
                popped = true;
                System.println("popView success");
            } else {
                System.println("popView failed, iteration " + i);
                break;
            }
        }
        
        // 如果无法弹出视图，尝试System.exit()
        if (!popped) {
            System.println("All popView failed, trying System.exit()");
            System.exit();
        }
        
        return true;
    }

    // Handle menu button - let system handle it for going to glances
    function onMenu() as Boolean {
        return false;
    }
}