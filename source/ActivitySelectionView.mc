import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Timer;
import Toybox.Lang;
import Toybox.Application;

// View for selecting activity type after a lap is added
class ActivitySelectionView extends WatchUi.View {
    private var mCallback;
    private var mTimer as Timer.Timer?;
    private var mTimeoutSeconds = 5;
    private var mTimeLeft;
    
    // Initialize with callback for selection result
    function initialize(callback) {
        View.initialize();
        mCallback = callback;
        mTimeLeft = mTimeoutSeconds;
    }
    
    // Load resources
    function onLayout(dc as Dc) as Void {
        // No layout needed, we'll draw directly in onUpdate
    }
    
    // Setup timeout timer when view is shown
    function onShow() as Void {
        mTimeLeft = mTimeoutSeconds;
        mTimer = new Timer.Timer();
        mTimer.start(method(:onTimerTick), 1000, true);
    }
    
    // Timer tick callback for timeout
    function onTimerTick() as Void {
        mTimeLeft = mTimeLeft - 1;
        if (mTimeLeft <= 0) {
            // Time's up, select vague activity by default
            if (mTimer != null) {
                mTimer.stop();
                mTimer = null;
            }
            mCallback.invoke(ACTIVITY_VAGUE);
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        }
        WatchUi.requestUpdate();
    }
    
    // Draw activity selection options
    function onUpdate(dc as Dc) as Void {
        // Clear the screen
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        // Get screen dimensions
        var width = dc.getWidth();
        var height = dc.getHeight();
        
        // Title
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width/2, 10, Graphics.FONT_SMALL, "Select activity type", Graphics.TEXT_JUSTIFY_CENTER);
        
        // Timeout indicator
        dc.drawText(width/2, 30, Graphics.FONT_TINY, "(" + mTimeLeft + "s)", Graphics.TEXT_JUSTIFY_CENTER);
        
        // Calculate box dimensions
        var boxHeight = (height - 80) / 3;
        var boxMargin = 10;
        var boxWidth = width - (2 * boxMargin);
        
        // Draw focused activity option (top)
        dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_BLACK);
        dc.fillRectangle(boxMargin, 50, boxWidth, boxHeight);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width/2, 50 + (boxHeight/2), Graphics.FONT_MEDIUM, "Focused", Graphics.TEXT_JUSTIFY_CENTER);
        
        // Draw neutral activity option (middle)
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLACK);
        dc.fillRectangle(boxMargin, 50 + boxHeight + 5, boxWidth, boxHeight);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width/2, 50 + boxHeight + 5 + (boxHeight/2), Graphics.FONT_MEDIUM, "Neutral", Graphics.TEXT_JUSTIFY_CENTER);
        
        // Draw vague activity option (bottom)
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
        dc.fillRectangle(boxMargin, 50 + (2 * boxHeight) + 10, boxWidth, boxHeight);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width/2, 50 + (2 * boxHeight) + 10 + (boxHeight/2), Graphics.FONT_MEDIUM, "Vague", Graphics.TEXT_JUSTIFY_CENTER);
    }
    
    // Clean up when view is hidden
    function onHide() as Void {
        if (mTimer != null) {
            mTimer.stop();
            mTimer = null;
        }
    }
}

// Input delegate for the activity selection view
class ActivitySelectionDelegate extends WatchUi.BehaviorDelegate {
    private var mCallback;
    
    // Initialize with callback for selection result
    function initialize(callback) {
        BehaviorDelegate.initialize();
        mCallback = callback;
    }
    
    // Handle UP button press for Focused activity
    function onPreviousPage() as Boolean {
        // Focused activity (green)
        mCallback.invoke(ACTIVITY_FOCUSED);
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
    
    // Handle DOWN button press for Neutral activity
    function onNextPage() as Boolean {
        // Neutral activity (blue)
        mCallback.invoke(ACTIVITY_NEUTRAL);
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
    
    // Handle BACK button press for Vague activity
    function onBack() as Boolean {
        // Vague activity (gray)
        mCallback.invoke(ACTIVITY_VAGUE);
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
} 