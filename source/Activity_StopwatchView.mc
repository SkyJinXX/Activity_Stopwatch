import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Timer;
import Toybox.Lang;
import Toybox.Application;

class Activity_StopwatchView extends WatchUi.View {
    public var mStopwatch;
    private var mScrollPosition = 0;
    private var mMaxVisibleLaps = 3;
    
    function initialize() {
        View.initialize();
        mStopwatch = new StopwatchModel(method(:onStopwatchUpdate));
    }

    // Called when a lap activity type is selected
    function onActivityTypeSelected(activityType) {
        mStopwatch.addLap(activityType);
        // Resume the stopwatch after lap is added
        if (!mStopwatch.isRunning()) {
            mStopwatch.start();
        }
        WatchUi.requestUpdate();
    }
    
    // Stopwatch tick callback
    function onStopwatchUpdate() {
        WatchUi.requestUpdate();
    }
    
    // Get activity color based on type
    function getActivityColor(activityType) {
        if (activityType == ACTIVITY_FOCUSED) {
            return Graphics.COLOR_DK_GREEN;
        } else if (activityType == ACTIVITY_NEUTRAL) {
            return Graphics.COLOR_BLUE;
        } else {
            return Graphics.COLOR_LT_GRAY;
        }
    }
    
    // Scroll up in lap history
    function scrollUp() {
        if (mScrollPosition > 0) {
            mScrollPosition--;
            WatchUi.requestUpdate();
        }
    }
    
    // Scroll down in lap history
    function scrollDown() {
        var lapCount = mStopwatch.getLapCount();
        if (mScrollPosition < (lapCount - mMaxVisibleLaps) && lapCount > mMaxVisibleLaps) {
            mScrollPosition++;
            WatchUi.requestUpdate();
        }
    }
    
    // Add a new lap
    function addLap() {
        // Pause the stopwatch before showing the activity selection
        if (mStopwatch.isRunning()) {
            mStopwatch.pause();
        }
        
        // Push the activity selection view
        var activitySelectCallback = method(:onActivityTypeSelected);
        var view = new ActivitySelectionView(activitySelectCallback);
        var delegate = new ActivitySelectionDelegate(activitySelectCallback);
        WatchUi.pushView(view, delegate, WatchUi.SLIDE_UP);
    }
    
    // Toggle stopwatch state
    function toggleStopwatch() {
        mStopwatch.toggle();
        WatchUi.requestUpdate();
    }
    
    // Save activity
    function saveActivity() {
        if (!mStopwatch.isRunning()) {
            // Save stopwatch data
            var laps = mStopwatch.getLaps();
            var totalTime = mStopwatch.getElapsedTime();
            
            // Here you could save to a file or sync with the phone
            // For now, we just reset the stopwatch
            mStopwatch.reset();
            mScrollPosition = 0;
            WatchUi.requestUpdate();
        }
    }

    // Load resources
    function onLayout(dc as Dc) as Void {
        // We'll draw directly in onUpdate instead of using layouts
    }

    // Called when this View is shown
    function onShow() as Void {
        // Nothing to do here
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        // Clear the screen
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        // Get screen dimensions
        var width = dc.getWidth();
        var height = dc.getHeight();
        
        // Draw current time at top - keep at top
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var clockTime = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var timeString = Lang.format("$1$:$2$", [
            clockTime.hour.format("%02d"),
            clockTime.min.format("%02d")
        ]);
        dc.drawText(width/2, 10, Graphics.FONT_SMALL, timeString, Graphics.TEXT_JUSTIFY_CENTER);
        
        // Calculate vertical center for better spacing
        var verticalCenter = height / 2 - 80;  // Adjust to account for other elements
        
        // Draw total elapsed time - move closer to center
        var totalTime = mStopwatch.getElapsedTime();
        var totalTimeStr = StopwatchModel.formatTimeWithHours(totalTime);
        dc.drawText(width/2, verticalCenter - 30, Graphics.FONT_MEDIUM, totalTimeStr, Graphics.TEXT_JUSTIFY_CENTER);
        
        // Draw current lap time - center vertically
        var currentLapTime = mStopwatch.getCurrentLapTime();
        var currentLapTimeStr = StopwatchModel.formatTime(currentLapTime);
        dc.drawText(width/2, verticalCenter + 10, Graphics.FONT_MEDIUM, "Lap: " + currentLapTimeStr, Graphics.TEXT_JUSTIFY_CENTER);
        
        // Draw lap history section title - move below the lap time
        var laps = mStopwatch.getLaps();
        var lapCount = laps.size();
        var yPos = verticalCenter + 70;

        if (lapCount != 0) {
            dc.drawText(width/2, yPos, Graphics.FONT_SMALL, "Previous Laps", Graphics.TEXT_JUSTIFY_CENTER);
        }
        
        // Draw previous laps - adjust starting position
        yPos += 30;
        if (lapCount == 0) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            // dc.drawText(width/2, yPos, Graphics.FONT_SMALL, "No laps recorded", Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            // Calculate visible range
            var startIdx = lapCount - 1 - mScrollPosition;
            var endIdx = startIdx - (mMaxVisibleLaps - 1);
            if (endIdx < 0) { endIdx = 0; }
            
            // Draw lap entries
            for (var i = startIdx; i >= endIdx; i--) {
                var lap = laps[i];
                var color = getActivityColor(lap.lapType);
                var lapTimeStr = StopwatchModel.formatTime(lap.lapTime);
                
                // Draw color indicator
                dc.setColor(color, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(40, yPos, 10, 20);
                
                // Draw lap number and time
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(60, yPos, Graphics.FONT_SMALL, "Lap " + (i + 1), Graphics.TEXT_JUSTIFY_LEFT);
                dc.drawText(width - 60, yPos, Graphics.FONT_SMALL, lapTimeStr, Graphics.TEXT_JUSTIFY_RIGHT);
                
                yPos += 25;
            }
            
            // Draw scroll indicators if needed
            if (lapCount > mMaxVisibleLaps) {
                if (mScrollPosition > 0) {
                    // Up arrow
                    dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                    dc.drawText(width - 15, verticalCenter + 50, Graphics.FONT_SMALL, "▲", Graphics.TEXT_JUSTIFY_RIGHT);
                }
                
                if (mScrollPosition < (lapCount - mMaxVisibleLaps)) {
                    // Down arrow
                    dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                    dc.drawText(width - 15, yPos, Graphics.FONT_SMALL, "▼", Graphics.TEXT_JUSTIFY_RIGHT);
                }
            }
        }
    }

    // Called when this View is removed from the screen
    function onHide() as Void {
        // Nothing to do here
    }
}
