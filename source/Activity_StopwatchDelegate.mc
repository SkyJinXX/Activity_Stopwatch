import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Application;

class Activity_StopwatchDelegate extends WatchUi.InputDelegate {
    private var mView;
    private var mKeyPressedTime = 0;
    private var mIsKeyHeld = false;
    private const LONG_PRESS_THRESHOLD = 500; // milliseconds
    private var mIsSwipeDetected = false;   // 用于追踪是否检测到滑动手势

    function initialize() {
        InputDelegate.initialize();
    }
    
    // Set the view reference
    function setView(view) {
        mView = view;
    }

    // Handle key events
    function onKey(evt) as Boolean {
        var key = evt.getKey();
        
        // Enter key (START/STOP button)
        if (key == WatchUi.KEY_ENTER) {
            if (mView != null && mView.mStopwatch != null) {
                if (mView.mStopwatch.isRunning()) {
                    mView.mStopwatch.pause();
                } else {
                    mView.mStopwatch.start();
                }
            }
            return true;
        }
        
        // Back button (always records current countdown and shows countdown selection)
        if (key == WatchUi.KEY_ESC) {
            if (mView != null && mView.mStopwatch != null) {
                // Record the current countdown as completed
                if (mView.mStopwatch.isRunning()) {
                    mView.mStopwatch.pause();
                }
                
                // Calculate the current lap duration before adding a new lap
                var currentCount = mView.mStopwatch.getLapCount();
                
                // Add a lap with ACTIVITY_NEUTRAL type to record the completed countdown
                mView.addLap(ACTIVITY_NEUTRAL);
                
                // Verify that the lap was added successfully
                if (mView.mStopwatch.getLapCount() > currentCount) {
                    System.println("Successfully recorded lap for countdown");
                } else {
                    System.println("Failed to record lap for countdown");
                }
                
                // Show the countdown selection view to set a new duration
                var countdownView = new CountdownSelectionView();
                var countdownDelegate = new CountdownSelectionDelegate(countdownView, mView);
                WatchUi.pushView(countdownView, countdownDelegate, WatchUi.SLIDE_IMMEDIATE);
            }
            return true;
        }
        
        // Handle Up key (Scroll up)
        else if (key == WatchUi.KEY_UP) {
            System.println("key onKey:"+key);
            if (!mIsKeyHeld) {
                mView.scrollUp();
                return true;
            }
            return false;
        }
        
        // Handle Down key (Scroll down or save)
        else if (key == WatchUi.KEY_DOWN) {
            if (mView.mStopwatch.isRunning()) {
                mView.scrollDown();
            } else {
                mView.saveActivity();
            }
            return true;
        }
        
        // Handle Menu button
        else if (key == WatchUi.KEY_MENU) {
            return false; // Let system handle it for going to glances
        }
        
        return false;
    }

    // Handle physical button press
    function onKeyPressed(keyEvent) {
        var key = keyEvent.getKey();

        System.println("key Pressed:"+key);
        
        if (key == WatchUi.KEY_UP) {
            mKeyPressedTime = System.getTimer();
            System.println("mKeyPressedTime:"+mKeyPressedTime);
            mIsKeyHeld = false;
            return false;
        }
        return false;
    }

    // Handle physical button release
    function onKeyReleased(keyEvent) {
        var key = keyEvent.getKey();

        System.println("key released:"+key);

        if (key == WatchUi.KEY_UP) {
            var pressDuration = System.getTimer() - mKeyPressedTime;

            System.println("pressDuration: "+pressDuration + " system_time: " + System.getTimer() + " mKeyPressedTime: "+mKeyPressedTime);
            System.println("LONG_PRESS_THRESHOLD: "+LONG_PRESS_THRESHOLD);
            if (pressDuration >= LONG_PRESS_THRESHOLD) {
                // Long press detected - exit to watch face
                mIsKeyHeld = true;
                System.println("Long press detected - exiting to watch face");
                
                // 使用手动退出方法
                exitToWatchFace();
                return true;
            }
        } else if (key == WatchUi.KEY_MENU) { // forerunner 165 doesn't have a menu button, so long pressing Key_UP will be regarded as menu button pressed
            mIsKeyHeld = true;
            System.println("Long press detected - exiting to watch face");
            exitToWatchFace();
            return true;
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
        System.println("touch blocked?");
        return true;
    }

    // 手动退出到表盘的方法
    function exitToWatchFace() {
        System.println("Executing exitToWatchFace");
        
        // Make sure state is saved before exiting
        if (mView != null && mView.mStopwatch != null) {
            System.println("Saving state before exit...");
            mView.mStopwatch.saveState();
        }
        
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
}