import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

class Activity_StopwatchDelegate extends WatchUi.BehaviorDelegate {
    private var mView;

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
        // Add a lap - the view's addLap method will now pause the stopwatch first
        if (mView.mStopwatch.isRunning() || mView.mStopwatch.getElapsedTime() > 0) {
            mView.addLap();
            return true;
        }
        return false;
    }
    
    // Handle Up key (Scroll up)
    function onPreviousPage() as Boolean {
        mView.scrollUp();
        return true;
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

    // Handle menu button
    function onMenu() as Boolean {
        return false;
    }
}