import Toybox.Lang;
import Toybox.Time;
import Toybox.Timer;
import Toybox.Application.Storage;
import Toybox.System;

// Activity types
enum {
    ACTIVITY_VAGUE = 0,
    ACTIVITY_NEUTRAL = 1,
    ACTIVITY_FOCUSED = 2
}

// Lap data structure
class LapData {
    public var lapTime as Number;
    public var lapType as Number;
    public var startTimeOffset as Number;  // Store when the lap started relative to total time
    
    function initialize(time as Number, type as Number, startOffset as Number) {
        lapTime = time;
        lapType = type;
        startTimeOffset = startOffset;
    }
    
    // Convert to serializable dictionary
    function toDict() as Dictionary {
        return {
            "lapTime" => lapTime,
            "lapType" => lapType,
            "startOffset" => startTimeOffset
        };
    }
    
    // Create from dictionary
    static function fromDict(dict as Dictionary) as LapData {
        var startOffset = 0;
        if (dict.hasKey("startOffset") && dict.get("startOffset") instanceof Number) {
            startOffset = dict.get("startOffset");
        }
        
        return new LapData(
            dict.get("lapTime") as Number,
            dict.get("lapType") as Number,
            startOffset
        );
    }
}

// Main stopwatch model that manages timing and lap data
class StopwatchModel {
    private var mTimer as Timer.Timer?;
    private var mStartTime as Number = 0;
    private var mAccumulatedTime as Number = 0;
    private var mLastLapTimeOffset as Number = 0;  // Store lap time as offset from total elapsed time
    private var mIsRunning as Boolean = false;
    private var mLaps as Array<LapData>;
    private var mCallback;
    
    // Initialize model
    function initialize(callback) {
        mLaps = [] as Array<LapData>;
        mCallback = callback;
        
        // Restore state if available
        var stored = Storage.getValue("stopwatchState") as Dictionary?;
        if (stored != null) {
            var accTime = stored.get("accTime");
            if (accTime instanceof Number) {
                mAccumulatedTime = accTime;
            }
            
            var lastLapTime = stored.get("lastLapTime");
            if (lastLapTime instanceof Number) {
                mLastLapTimeOffset = lastLapTime;
            }
            
            var isRunning = stored.get("isRunning");
            if (isRunning instanceof Boolean) {
                mIsRunning = isRunning;
            }
            
            var storedLaps = stored.get("laps");
            if (storedLaps instanceof Array) {
                // Convert dictionaries back to LapData objects
                mLaps = [] as Array<LapData>;
                for (var i = 0; i < storedLaps.size(); i++) {
                    if (storedLaps[i] instanceof Dictionary) {
                        mLaps.add(LapData.fromDict(storedLaps[i]));
                    }
                }
            }
            
            if (mIsRunning) {
                // Don't auto-start when restoring
                mIsRunning = false;
                // Reset accumulated time to avoid negative values
                if (mAccumulatedTime < 0) {
                    mAccumulatedTime = 0;
                }
            }
        }
    }
    
    // Start the stopwatch
    function start() {
        if (!mIsRunning) {
            mStartTime = System.getTimer();
            mTimer = new Timer.Timer();
            mTimer.start(method(:onTick), 100, true);
            mIsRunning = true;
            System.println("Stopwatch started: " + mStartTime);
            saveState();
        }
    }
    
    // Pause the stopwatch
    function pause() {
        if (mIsRunning) {
            if (mTimer != null) {
                mTimer.stop();
                mTimer = null;
            }
            mAccumulatedTime += System.getTimer() - mStartTime;
            mIsRunning = false;
            System.println("Stopwatch paused. Accumulated: " + mAccumulatedTime);
            saveState();
        }
    }
    
    // Reset the stopwatch
    function reset() {
        if (mTimer != null) {
            mTimer.stop();
            mTimer = null;
        }
        mStartTime = 0;
        mAccumulatedTime = 0;
        mLastLapTimeOffset = 0;
        mIsRunning = false;
        mLaps = [] as Array<LapData>;
        saveState();
    }
    
    // Toggle between start and pause
    function toggle() {
        System.println("Toggle called. Current state: " + (mIsRunning ? "running" : "stopped"));
        if (mIsRunning) {
            pause();
        } else {
            start();
        }
    }
    
    // Add a new lap
    function addLap(activityType as Number) {
        // Get the precise current elapsed time
        var currentElapsedTime = getElapsedTime();
        
        // Calculate lap time as the difference between current elapsed time and last lap offset
        var lapTime = currentElapsedTime - mLastLapTimeOffset;
        
        // Update last lap time offset to current elapsed time
        mLastLapTimeOffset = currentElapsedTime;
        
        System.println("New lap - Elapsed: " + currentElapsedTime + 
                      ", Lap time: " + lapTime + 
                      ", Last offset: " + mLastLapTimeOffset);
        
        // Create the lap with exact timing
        var lap = new LapData(lapTime, activityType, mLastLapTimeOffset);
        mLaps.add(lap);
        saveState();
        return lap;
    }
    
    // Update the activity type for a specific lap
    function updateLapType(index as Number, activityType as Number) {
        if (index >= 0 && index < mLaps.size()) {
            mLaps[index].lapType = activityType;
            System.println("Updated lap " + index + " type to " + activityType);
            saveState();
        }
    }
    
    // Get total elapsed time
    function getElapsedTime() as Number {
        if (mIsRunning) {
            var currentTime = System.getTimer();
            var elapsed = mAccumulatedTime + (currentTime - mStartTime);
            return elapsed;
        } else {
            return mAccumulatedTime;
        }
    }
    
    // Get current lap time
    function getCurrentLapTime() as Number {
        // Current lap time is exactly (total elapsed time - last lap time offset)
        return getElapsedTime() - mLastLapTimeOffset;
    }
    
    // Get the formatted display times that are guaranteed to be synchronized
    function getSynchronizedTimes() as Dictionary {
        var elapsedTime = getElapsedTime();
        var lapTime = elapsedTime - mLastLapTimeOffset;
        
        // Process the times to ensure they're perfectly in sync
        var elapsedSeconds = (elapsedTime / 1000).toNumber();
        var lapSeconds = (lapTime / 1000).toNumber();
        
        return {
            "elapsedTime" => elapsedTime,
            "lapTime" => lapTime,
            "elapsedSeconds" => elapsedSeconds,
            "lapSeconds" => lapSeconds,
            "elapsedTimeFormatted" => formatTimeWithHours(elapsedTime),
            "lapTimeFormatted" => formatTime(lapTime)
        };
    }
    
    // Get all laps
    function getLaps() as Array<LapData> {
        return mLaps;
    }
    
    // Get the number of laps
    function getLapCount() as Number {
        return mLaps.size();
    }
    
    // Check if stopwatch is running
    function isRunning() as Boolean {
        return mIsRunning;
    }
    
    // Timer tick callback
    function onTick() as Void {
        if (mCallback != null) {
            mCallback.invoke();
        }
    }
    
    // Save state to storage
    function saveState() as Void {
        // Convert LapData objects to serializable dictionaries
        var lapDicts = [] as Array<Dictionary>;
        for (var i = 0; i < mLaps.size(); i++) {
            lapDicts.add(mLaps[i].toDict());
        }
        
        var state = {
            "accTime" => mAccumulatedTime,
            "lastLapTime" => mLastLapTimeOffset,
            "isRunning" => mIsRunning,
            "laps" => lapDicts
        };
        Storage.setValue("stopwatchState", state);
    }
    
    // Format time to display string (MM:SS)
    static function formatTime(time as Number) as String {
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
    static function formatTimeWithHours(time as Number) as String {
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
} 