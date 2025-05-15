import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Timer;
import Toybox.Lang;
import Toybox.Application;
import Toybox.System;
import Toybox.Attention;

class Activity_StopwatchView extends WatchUi.View {
    public var mStopwatch;
    private var mDisplayedLapIndex = 0;
    private var mMaxVisibleLaps = 3;
    private var mLastFiveMinuteAlert = false; // Track if 5-minute alert has been triggered
    
    function initialize() {
        View.initialize();
        System.println("Activity_StopwatchView initializing");
        
        // Initialize the stopwatch model
        mStopwatch = new StopwatchModel(method(:updateUI));
    }
    
    // Called when a lap activity type is selected
    function onActivityTypeSelected(activityType) {
        // Add a new lap with the selected activity type
        if (mStopwatch != null) {
            mStopwatch.addLap(activityType);
            WatchUi.requestUpdate();
        }
    }
    
    // Load resources
    function onLayout(dc as Dc) as Void {
        System.println("onLayout called");
        setLayout(Rez.Layouts.MainLayout(dc));
    }
    
    // Called when the view becomes visible
    function onShow() as Void {
        // Force an update
        WatchUi.requestUpdate();
        System.println("View shown");
    }
    
    // Called when the view needs to update
    function onUpdate(dc as Dc) as Void {
        // Draw the background
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        var width = dc.getWidth();
        var height = dc.getHeight();
        var watchTime = System.getClockTime();
        
        // Draw the system clock time at the top
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            width/2, 
            height * 0.05, 
            Graphics.FONT_TINY, 
            Lang.format("$1$:$2$", [watchTime.hour.format("%02d"), watchTime.min.format("%02d")]),
            Graphics.TEXT_JUSTIFY_CENTER
        );
        
        // Get battery percentage (removing it from top)
        var batteryLevel = System.getSystemStats().battery;
        
        // Draw countdown state
        var countdownState = mStopwatch.getCountdownState();
        var elapsedMs = mStopwatch.getElapsedMilliseconds();
        var remainingSeconds = countdownState.get("remaining");
        var countdownDuration = mStopwatch.getCountdownDuration();
        
        // Draw circular progress indicator around the watch face
        if (mStopwatch.isRunning() && remainingSeconds > 0) {
            // Calculate progress percentage (0.0 to 1.0)
            var progressPercentage = remainingSeconds.toFloat() / countdownDuration.toFloat();
            
            // Draw progress circle
            var centerX = width / 2;
            var centerY = height / 2;
            var radius = (width < height ? width : height) / 2 - 5; // Slightly inset from edge
            
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(4);
            
            // Calculate the start and end angles for an arc that goes counterclockwise
            var startAngle = -Math.PI / 2; // Start at top (12 o'clock position)
            var endAngle = startAngle + (Math.PI * 2 * progressPercentage);
            
            // Draw the arc in segments to create a smooth circle
            var segments = 72; // Number of segments (more = smoother)
            var angleIncrement = (Math.PI * 2) / segments;
            
            for (var i = 0; i < segments * progressPercentage; i++) {
                var angle1 = startAngle - (i * angleIncrement);
                var angle2 = angle1 - angleIncrement;
                
                var x1 = centerX + radius * Math.cos(angle1);
                var y1 = centerY + radius * Math.sin(angle1);
                var x2 = centerX + radius * Math.cos(angle2);
                var y2 = centerY + radius * Math.sin(angle2);
                
                dc.drawLine(x1.toNumber(), y1.toNumber(), x2.toNumber(), y2.toNumber());
            }
        }
        
        // Check for 5-minute alert (300 seconds)
        if (mStopwatch.isRunning() && 
            remainingSeconds > 0 && 
            remainingSeconds <= 300 && 
            !mLastFiveMinuteAlert) {
            
            mLastFiveMinuteAlert = true; // Set flag to prevent repeated alerts
            
            // Vibrate once for 5-minute warning
            Attention.vibrate([new Attention.VibeProfile(50, 300)]);
        } else if (remainingSeconds > 300 || !mStopwatch.isRunning()) {
            // Reset flag when we're above 5 minutes or stopped
            mLastFiveMinuteAlert = false;
        }
        
        // If countdown has reached zero and we're running, vibrate
        if (mStopwatch.isRunning() && 
            countdownState.get("isCountdownReached") && 
            countdownState.get("remaining") > -1 && 
            countdownState.get("remaining") <= 0) {
            // Vibrate twice and play a tone when crossing zero
            Attention.vibrate([
                new Attention.VibeProfile(50, 500), 
                new Attention.VibeProfile(0, 200),
                new Attention.VibeProfile(50, 500),
                new Attention.VibeProfile(0, 200),
                new Attention.VibeProfile(50, 500)
            ]);
            
            // Play an alert tone if supported
            // if (Attention has :playTone) {
            //     Attention.playTone(Attention.TONE_ALARM);
            // }
            if (Attention has :ToneProfile) {
                var toneProfile =
                [
                    new Attention.ToneProfile( 2500, 250),
                    new Attention.ToneProfile( 5000, 250),
                    new Attention.ToneProfile(10000, 250),
                    new Attention.ToneProfile( 5000, 250),
                    new Attention.ToneProfile( 2500, 250),
                ];
                Attention.playTone({:toneProfile=>toneProfile});
            }

        }
        
        // Display the countdown duration at the top
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var durationText = formatCountdownDuration(mStopwatch.getCountdownDuration());
        
        dc.drawText(
            width/2, 
            height * 0.20, 
            Graphics.FONT_MEDIUM, 
            durationText, 
            Graphics.TEXT_JUSTIFY_CENTER
        );
        
        // Display remaining time in large font
        var remainingText = formatRemainingTime(remainingSeconds);
        var textColor = Graphics.COLOR_WHITE;
        
        // Set color based on remaining time
        if (remainingSeconds <= 0) {
            textColor = Graphics.COLOR_RED;  // Red for overtime
        } else if (remainingSeconds <= 300) {
            textColor = Graphics.COLOR_YELLOW; // Yellow for <= 5 minutes
        }
        
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            width/2, 
            height * 0.35, 
            Graphics.FONT_LARGE, 
            remainingText, 
            Graphics.TEXT_JUSTIFY_CENTER
        );
        
        // Draw lap history
        var lapsToShow = 3;
        var lapCount = mStopwatch.getLapCount();
        var startIndex = 0;
        
        if (lapCount > 0) {
            // For reverse order (newest laps first), calculate starting index differently
            if (lapCount <= lapsToShow) {
                // Show all laps if there are fewer than lapsToShow
                startIndex = lapCount - 1;
            } else {
                // With scrolling support
                startIndex = lapCount - 1 - mDisplayedLapIndex;
                if (startIndex < 0) {
                    startIndex = 0;
                }
            }
            
            var yPosStart = height * 0.55;
            var yPosIncrement = height * 0.10;
            
            // Draw laps in reverse order (newest at top)
            for (var i = 0; i < lapsToShow && startIndex - i >= 0; i++) {
                var lapIndex = startIndex - i;
                var lapData = mStopwatch.getLap(lapIndex);
                var yPos = yPosStart + (i * yPosIncrement);
                
                if (lapData != null) {
                    // Set default color for lap number
                    dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                    dc.drawText(
                        width * 0.15, 
                        yPos, 
                        Graphics.FONT_SMALL, 
                        (lapIndex + 1).toString(), 
                        Graphics.TEXT_JUSTIFY_LEFT
                    );
                    
                    // For history display, show actual time vs target (e.g., "35:00/30m")
                    var lapTimeSeconds = lapData.lapTime / 1000;
                    var targetSeconds = lapData.countdownDuration;
                    var durationMinutes = targetSeconds / 60;
                    
                    // Format lap time as MM:SS
                    var actualTime = formatTime(lapTimeSeconds * 1000);
                    var targetTime = formatTargetTime(durationMinutes);
                    
                    // Calculate positions for consistent alignment
                    var slashX = width * 0.65; // Fixed position for the slash
                    var timeRightX = slashX - 8; // Actual time right edge (with some space before slash)
                    var targetLeftX = slashX + 8; // Target time left edge (with some space after slash)
                    
                    // If over target time, draw the actual time in red
                    if (lapTimeSeconds > targetSeconds) {
                        // Draw the actual time in red (right aligned to slash position)
                        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                        dc.drawText(
                            timeRightX, 
                            yPos, 
                            Graphics.FONT_SMALL, 
                            actualTime, 
                            Graphics.TEXT_JUSTIFY_RIGHT
                        );
                        
                        // Draw the slash (centered on fixed position)
                        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                        dc.drawText(
                            slashX, 
                            yPos, 
                            Graphics.FONT_SMALL, 
                            "/", 
                            Graphics.TEXT_JUSTIFY_CENTER
                        );
                        
                        // Draw the target time (left aligned from slash position)
                        dc.drawText(
                            targetLeftX,
                            yPos, 
                            Graphics.FONT_SMALL, 
                            targetTime, 
                            Graphics.TEXT_JUSTIFY_LEFT
                        );
                    } else {
                        // Draw normal time (right aligned to slash position)
                        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                        dc.drawText(
                            timeRightX, 
                            yPos, 
                            Graphics.FONT_SMALL, 
                            actualTime, 
                            Graphics.TEXT_JUSTIFY_RIGHT
                        );
                        
                        // Draw the slash (centered on fixed position)
                        dc.drawText(
                            slashX, 
                            yPos, 
                            Graphics.FONT_SMALL, 
                            "/", 
                            Graphics.TEXT_JUSTIFY_CENTER
                        );
                        
                        // Draw the target time (left aligned from slash position)
                        dc.drawText(
                            targetLeftX,
                            yPos, 
                            Graphics.FONT_SMALL, 
                            targetTime, 
                            Graphics.TEXT_JUSTIFY_LEFT
                        );
                    }
                }
            }
        }
        
        // Draw battery percentage at the bottom
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            width/2, 
            height * 0.92, 
            Graphics.FONT_TINY, 
            Lang.format("$1$%", [batteryLevel.format("%d")]),
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }
    
    // Scroll up in the lap display
    function scrollUp() {
        if (mDisplayedLapIndex > 0) {
            mDisplayedLapIndex--;
            WatchUi.requestUpdate();
        }
    }
    
    // Scroll down in the lap display
    function scrollDown() {
        var totalLaps = mStopwatch.getLapCount();
        
        if (totalLaps > mMaxVisibleLaps && mDisplayedLapIndex < totalLaps - mMaxVisibleLaps) {
            mDisplayedLapIndex++;
            WatchUi.requestUpdate();
        }
    }
    
    // Add a lap with activity type
    function addLap(activityType) {
        if (mStopwatch != null) {
            mStopwatch.addLap(activityType);
            WatchUi.requestUpdate();
        }
    }
    
    // Save activity and reset
    function saveActivity() {
        if (!mStopwatch.isRunning()) {
            // Save stopwatch data to storage, then reset
            mStopwatch.reset();
            mDisplayedLapIndex = 0;
            WatchUi.requestUpdate();
        }
    }
    
    // Set countdown duration and start
    function startCountdown(durationSeconds as Number) {
        if (mStopwatch != null) {
            mStopwatch.setCountdownDuration(durationSeconds);
            WatchUi.requestUpdate();
        }
    }
    
    // Update the UI, called by the stopwatch model
    function updateUI() {
        WatchUi.requestUpdate();
    }
    
    // Format time to display string (MM:SS)
    function formatTime(time as Number) as String {
        // Ensure we're working with a positive number
        if (time < 0) {
            time = 0;
        }
        
        // Round to nearest second
        var totalSeconds = (time / 1000).toNumber();
        var seconds = totalSeconds % 60;
        var minutes = (totalSeconds / 60) % 60;
        
        return Lang.format("$1$:$2$", [
            minutes.format("%02d"),
            seconds.format("%02d")
        ]);
    }
    
    // Format time to display string with hours (HH:MM:SS)
    function formatTimeWithHours(time as Number) as String {
        // Ensure we're working with a positive number
        if (time < 0) {
            time = 0;
        }
        
        // Round to nearest second
        var totalSeconds = (time / 1000).toNumber();
        var seconds = totalSeconds % 60;
        var minutes = (totalSeconds / 60) % 60;
        var hours = totalSeconds / 3600;
        
        return Lang.format("$1$:$2$:$3$", [
            hours.format("%02d"),
            minutes.format("%02d"),
            seconds.format("%02d")
        ]);
    }
    
    // Format countdown duration for display (e.g., "30m")
    function formatCountdownDuration(seconds as Number) as String {
        var minutes = seconds / 60;
        return Lang.format("$1$m", [minutes.format("%.0f")]);
    }
    
    // Format remaining countdown time for display
    function formatRemainingTime(seconds as Number) as String {
        if (seconds >= 0) {
            var mins = (seconds / 60).toNumber();
            var secs = seconds % 60;
            return Lang.format("$1$:$2$", [mins.format("%02d"), secs.format("%02d")]);
        } else {
            // For negative times (overtime)
            var absSeconds = (-seconds).toNumber();
            var mins = (absSeconds / 60).toNumber();
            var secs = absSeconds % 60;
            return Lang.format("-$1$:$2$", [mins.format("%02d"), secs.format("%02d")]);
        }
    }
    
    // Format target time for display (e.g., "30m")
    function formatTargetTime(minutes as Number) as String {
        // Use zero padding to ensure all numbers are 2-digits wide
        // This ensures the "m" will be aligned for all entries
        return minutes.format("%02.0f") + "m";
    }
}
