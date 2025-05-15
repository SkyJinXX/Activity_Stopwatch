import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;

// CountdownSelectionView - Displays UI for selecting countdown duration
class CountdownSelectionView extends WatchUi.View {
    // Countdown options in minutes
    private const COUNTDOWN_OPTIONS = [5, 15, 30, 45, 60];
    private var mSelectedIndex = 1; // Default to 15 minutes (index 1)
    
    function initialize() {
        View.initialize();
    }
    
    // Called when the view is shown
    function onShow() {
        System.println("CountdownSelectionView shown");
    }
    
    // Load resources and layout
    function onLayout(dc as Dc) {
        setLayout(Rez.Layouts.MainLayout(dc));
    }
    
    // Handle drawing the countdown selection UI
    function onUpdate(dc as Dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        var width = dc.getWidth();
        var height = dc.getHeight();
        
        // Draw title
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width/2, height/10, Graphics.FONT_SMALL, "Countdown", Graphics.TEXT_JUSTIFY_CENTER);
        
        // Draw countdown options with selected one highlighted
        var yPos = height/4;
        var spacing = height/8;
        
        for (var i = 0; i < COUNTDOWN_OPTIONS.size(); i++) {
            var minutes = COUNTDOWN_OPTIONS[i];
            var text = minutes + " min";
            
            // Highlight selected option
            if (i == mSelectedIndex) {
                dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
                dc.drawText(width/2, yPos, Graphics.FONT_LARGE, "> " + text + " <", Graphics.TEXT_JUSTIFY_CENTER);
            } else {
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawText(width/2, yPos, Graphics.FONT_MEDIUM, text, Graphics.TEXT_JUSTIFY_CENTER);
            }
            
            yPos += spacing;
        }
        
        // Draw instructions at the bottom
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width/2, height*9/10, Graphics.FONT_TINY, "Back = 0 min", Graphics.TEXT_JUSTIFY_CENTER);
    }
    
    // Get the selected countdown duration in seconds
    function getSelectedDurationSeconds() {
        return COUNTDOWN_OPTIONS[mSelectedIndex] * 60;
    }
    
    // Select the next option (move down)
    function selectNext() {
        mSelectedIndex = (mSelectedIndex + 1) % COUNTDOWN_OPTIONS.size();
        WatchUi.requestUpdate();
    }
    
    // Select the previous option (move up)
    function selectPrevious() {
        mSelectedIndex = (mSelectedIndex - 1 + COUNTDOWN_OPTIONS.size()) % COUNTDOWN_OPTIONS.size();
        WatchUi.requestUpdate();
    }
}

// Input delegate for the countdown selection
class CountdownSelectionDelegate extends WatchUi.InputDelegate {
    private var mView;
    private var mStopwatchView;
    
    function initialize(view, stopwatchView) {
        InputDelegate.initialize();
        mView = view;
        mStopwatchView = stopwatchView;
    }
    
    // Handle key presses
    function onKey(keyEvent) {
        var key = keyEvent.getKey();
        
        if (key == WatchUi.KEY_UP) {
            // Move to previous option
            mView.selectPrevious();
            return true;
        } else if (key == WatchUi.KEY_DOWN) {
            // Move to next option
            mView.selectNext();
            return true;
        } else if (key == WatchUi.KEY_ENTER) {
            // Start countdown with selected duration
            var durationSeconds = mView.getSelectedDurationSeconds();
            mStopwatchView.startCountdown(durationSeconds);
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            return true;
        } else if (key == WatchUi.KEY_ESC) {
            // Start a 0-minute countdown (immediate overtime)
            mStopwatchView.startCountdown(0);
            // Return to stopwatch view
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            return true;
        }
        
        return false;
    }
} 