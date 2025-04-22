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
    
    function initialize(time as Number, type as Number) {
        lapTime = time;
        lapType = type;
    }
    
    // Convert to serializable dictionary
    function toDict() as Dictionary {
        return {
            "lapTime" => lapTime,
            "lapType" => lapType
        };
    }
    
    // Create from dictionary
    static function fromDict(dict as Dictionary) as LapData {
        return new LapData(
            dict.get("lapTime") as Number,
            dict.get("lapType") as Number
        );
    }
}

// Main stopwatch model that manages timing and lap data
class StopwatchModel {
    private var mTimer as Timer.Timer?;
    private var mStartTime as Number = 0;
    private var mAccumulatedTime as Number = 0;
    private var mLastLapTime as Number = 0;
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
                mLastLapTime = lastLapTime;
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
        mLastLapTime = 0;
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
        var currentTime = getElapsedTime();
        var lapTime = currentTime - mLastLapTime;
        mLastLapTime = currentTime;
        
        var lap = new LapData(lapTime, activityType);
        mLaps.add(lap);
        saveState();
        return lap;
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
        return getElapsedTime() - mLastLapTime;
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
            "lastLapTime" => mLastLapTime,
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