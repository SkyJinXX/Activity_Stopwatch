import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Timer;
import Toybox.Lang;
import Toybox.Application;
import Toybox.System;

class Activity_StopwatchView extends WatchUi.View {
    public var mStopwatch;
    private var mScrollPosition = 0;
    private var mMaxVisibleLaps = 3;
    private var mPendingLapIndex = -1;  // Index of lap waiting for activity type selection
    
    function initialize() {
        View.initialize();
        mStopwatch = new StopwatchModel(method(:onStopwatchUpdate));
        System.println("Activity_StopwatchView initialized with StopwatchModel");
    }

    // Called when a lap activity type is selected
    function onActivityTypeSelected(activityType) {
        // Instead of adding a new lap, update the type of the previous lap
        if (mPendingLapIndex >= 0 && mPendingLapIndex < mStopwatch.getLapCount()) {
            // Update the type of the previously created lap
            mStopwatch.updateLapType(mPendingLapIndex, activityType);
            mPendingLapIndex = -1;  // Reset pending index
        }
        WatchUi.requestUpdate();
    }
    
    // Stopwatch tick callback
    function onStopwatchUpdate() {
        // System.println("Stopwatch update callback received");
        WatchUi.requestUpdate();
    }
    
    // Get activity color based on type
    function getActivityColor(activityType) {
        if (activityType == ACTIVITY_FOCUSED) {
            return Graphics.COLOR_DK_GREEN;
        } else if (activityType == ACTIVITY_NEUTRAL) {
            return Graphics.COLOR_YELLOW;
        } else {
            return Graphics.COLOR_LT_GRAY;
        }
    }
    
    // Format time based on duration
    function formatTimeDisplay(timeMs) {
        var hours = timeMs / 3600000;
        
        if (hours >= 1) {
            // Format as HH:MM:SS if time is an hour or more
            return StopwatchModel.formatTimeWithHours(timeMs);
        } else {
            // Format as MM:SS if less than an hour
            return StopwatchModel.formatTime(timeMs);
        }
    }
    
    // Get current lap time color based on duration
    function getLapTimeColor(timeMs) {
        var minutes = timeMs / 60000.0; // make sure it's a float
        var maxMinutes = 60;
        if (minutes > maxMinutes) {
            minutes = maxMinutes;
        }
        
        var ratio = minutes / maxMinutes; // 0 ~ 1

        if (ratio < 0.1) {
            return 0xFFFFFF; // White
        } else if (ratio < 0.2) {
            return 0xFFFFAA; // White-Yellow
        } else if (ratio < 0.3) {
            return 0xFFFF55; // Light Yellow
        } else if (ratio < 0.4) {
            return 0xFFFF00; // Yellow
        } else if (ratio < 0.5) {
            return 0xFFDD00; // Yellow-Orange
        } else if (ratio < 0.6) {
            return 0xFFBB00; // Light Orange
        } else if (ratio < 0.7) {
            return 0xFF9900; // Orange
        } else if (ratio < 0.8) {
            return 0xFF6600; // Dark Orange
        } else if (ratio < 0.9) {
            return 0xFF3300; // Orange-Red
        } else {
            return 0xFF0000; // Red
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
        if (!mStopwatch.isRunning()) {
            // If stopped, start the timer first
            mStopwatch.start();
        }
        
        // Create a new lap immediately with ACTIVITY_NEUTRAL type
        var newLap = mStopwatch.addLap(ACTIVITY_VAGUE);
        
        // No need to store the index or launch activity selection
        WatchUi.requestUpdate();
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
            mPendingLapIndex = -1;  // Reset pending index
            WatchUi.requestUpdate();
        }
    }

    // Load resources
    function onLayout(dc as Dc) as Void {
        // We'll draw directly in onUpdate instead of using layouts
    }

    // Called when this View is shown
    function onShow() as Void {
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
        
        // Get synchronized times to ensure consistent display
        var syncTimes = mStopwatch.getSynchronizedTimes();
        
        // Get elapsed time in milliseconds
        var elapsedTimeMs = syncTimes.get("elapsedTime");
        var lapTimeMs = syncTimes.get("lapTime");
        
        // Format the times dynamically based on duration
        var elapsedTimeFormatted = formatTimeDisplay(elapsedTimeMs);
        var lapTimeFormatted = formatTimeDisplay(lapTimeMs);
        
        // Draw total elapsed time - move closer to center
        dc.drawText(width/2, verticalCenter - 30, Graphics.FONT_MEDIUM, elapsedTimeFormatted, Graphics.TEXT_JUSTIFY_CENTER);
        
        // Draw current lap time - center vertically
        dc.setColor(getLapTimeColor(lapTimeMs), Graphics.COLOR_TRANSPARENT);
        dc.drawText(width/2, verticalCenter + 25, Graphics.FONT_NUMBER_MILD, lapTimeFormatted, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var laps = mStopwatch.getLaps();
        var lapCount = laps.size();
        var yPos = verticalCenter + 75;

        // no need to show hint
        // if (lapCount != 0) {
        //     dc.drawText(width/2, yPos, Graphics.FONT_SMALL, "Previous Laps", Graphics.TEXT_JUSTIFY_CENTER);
        // }
        
        // Draw previous laps - adjust starting position
        yPos += 35;
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
                var color = getLapTimeColor(lap.lapTime);
                var lapTimeStr = formatTimeDisplay(lap.lapTime); // Use the dynamic formatting
                
                // Draw color indicator
                // dc.setColor(color, Graphics.COLOR_TRANSPARENT);
                // dc.fillRectangle(15, yPos + 15, 10, 20);
                
                // Draw lap number and time
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(50, yPos, Graphics.FONT_SMALL, "Lap " + (i + 1), Graphics.TEXT_JUSTIFY_LEFT);
                dc.setColor(color, Graphics.COLOR_TRANSPARENT);
                dc.drawText(width - 50, yPos, Graphics.FONT_SMALL, lapTimeStr, Graphics.TEXT_JUSTIFY_RIGHT);
                
                yPos += 30;
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
        
        // Draw battery level at the bottom of the screen
        var battery = System.getSystemStats().battery;
        var batteryStr = battery.format("%d") + "%";
        
        // Choose color based on battery level
        if (battery <= 20) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        } else if (battery <= 40) {
            dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        }
        
        // Draw battery text at the bottom center
        dc.drawText(width/2, height - 35, Graphics.FONT_TINY, batteryStr, Graphics.TEXT_JUSTIFY_CENTER);
    }

    // Called when this View is removed from the screen
    function onHide() as Void {
    }
}
