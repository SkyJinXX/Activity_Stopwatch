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
    public var countdownDuration as Number; // Store the countdown duration for this lap
    
    function initialize(time as Number, type as Number, startOffset as Number, duration as Number) {
        lapTime = time;
        lapType = type;
        startTimeOffset = startOffset;
        countdownDuration = duration;
    }
    
    // Convert to serializable dictionary
    function toDict() as Dictionary {
        return {
            "lapTime" => lapTime,
            "lapType" => lapType,
            "startOffset" => startTimeOffset,
            "countdownDuration" => countdownDuration
        };
    }
    
    // Create from dictionary
    static function fromDict(dict as Dictionary) as LapData {
        var startOffset = 0;
        if (dict.hasKey("startOffset") && dict.get("startOffset") instanceof Number) {
            startOffset = dict.get("startOffset");
        }
        
        var duration = 0;
        if (dict.hasKey("countdownDuration") && dict.get("countdownDuration") instanceof Number) {
            duration = dict.get("countdownDuration");
        }
        
        return new LapData(
            dict.get("lapTime") as Number,
            dict.get("lapType") as Number,
            startOffset,
            duration
        );
    }
}

// Main stopwatch model that manages timing and lap data
class StopwatchModel {
    private var mTimer as Timer.Timer?;
    
    // Time tracking
    private var mStartTime as Number = 0;         // When the stopwatch was last started/resumed
    private var mAccumulatedTime as Number = 0;   // Total accumulated time while stopwatch not running
    private var mLastLapTime as Number = 0;       // Accumulated time at last lap
    
    private var mIsRunning as Boolean = false;
    private var mLaps as Array<LapData>;
    private var mCallback;
    
    // Countdown properties
    private var mCountdownDuration as Number = 15 * 60;  // Default countdown duration in seconds (15 minutes)
    private var mCountdownReached as Boolean = false;    // Flag to track if countdown has reached zero
    
    // Initialize model
    function initialize(callback) {
        mLaps = [] as Array<LapData>;
        mCallback = callback;
        System.println("StopwatchModel initialized with callback: " + (callback != null ? "valid" : "null"));
        
        // Restore state if available
        var stored = Storage.getValue("stopwatchState") as Dictionary?;
        if (stored != null) {
            System.println("Restoring stopwatch state...");
            
            // Restore accumulated time
            var accTime = stored.get("accTime");
            if (accTime instanceof Number) {
                mAccumulatedTime = accTime;
                System.println("Restored accumulated time: " + mAccumulatedTime);
            }
            
            // Restore last lap time
            var lastLapTime = stored.get("lastLapTime");
            if (lastLapTime instanceof Number) {
                mLastLapTime = lastLapTime;
                System.println("Restored last lap time: " + mLastLapTime);
            }
            
            // Restore countdown settings
            var countdownDuration = stored.get("countdownDuration");
            if (countdownDuration instanceof Number) {
                mCountdownDuration = countdownDuration;
            }
            
            var countdownReached = stored.get("countdownReached");
            if (countdownReached instanceof Boolean) {
                mCountdownReached = countdownReached;
            }
            
            // Restore running state and startTime if it was running
            var isRunning = stored.get("isRunning");
            var storedStartTime = stored.get("startTime");
            
            if (isRunning instanceof Boolean && isRunning && storedStartTime instanceof Number && storedStartTime > 0) {
                // It was running when saved - calculate elapsed time since then
                var now = System.getTimer();
                var savedStartTime = storedStartTime;
                
                // If now < savedStartTime, timer likely overflowed
                if (now < savedStartTime && savedStartTime - now > 2000000000) {
                    // Timer overflow case - calculate based on safe max value
                    var TIMER_MAX = 2147483647; 
                    var elapsedSinceSave = (TIMER_MAX - savedStartTime) + now;
                    mAccumulatedTime += elapsedSinceSave;
                    System.println("Timer overflow: adding " + elapsedSinceSave + "ms to accumulated time");
                } else if (now >= savedStartTime) {
                    // Normal case - add elapsed time since it was saved
                    var elapsedSinceSave = now - savedStartTime;
                    mAccumulatedTime += elapsedSinceSave;
                    System.println("Adding " + elapsedSinceSave + "ms to accumulated time");
                }
                
                // Continue in running state
                mIsRunning = true;
                mStartTime = now;
                System.println("Restoring to running state with startTime=" + mStartTime);
            } else {
                // It was paused when saved (or startTime is invalid)
                mIsRunning = false;
                mStartTime = 0;
                System.println("Restoring to paused state");
            }
            
            // Restore laps
            var storedLaps = stored.get("laps");
            if (storedLaps instanceof Array) {
                // Convert dictionaries back to LapData objects
                mLaps = [] as Array<LapData>;
                for (var i = 0; i < storedLaps.size(); i++) {
                    if (storedLaps[i] instanceof Dictionary) {
                        mLaps.add(LapData.fromDict(storedLaps[i]));
                    }
                }
                System.println("Restored " + mLaps.size() + " laps");
            }
        }
            
        // Start the UI update timer
        if (mTimer == null) {
            mTimer = new Timer.Timer();
            mTimer.start(method(:onTick), 1000, true);
            System.println("Stopwatch UI timer started with " + 
                          (mAccumulatedTime > 0 ? mAccumulatedTime + "ms accumulated" : "no time") + 
                          " and " + mLaps.size() + " laps" +
                          (mIsRunning ? " (RUNNING)" : " (PAUSED)"));
            
            // Force an immediate update
            if (mCallback != null) {
                mCallback.invoke();
            }
        }
    }
    
    // Start the timer
    function start() {
        if (!mIsRunning) {
            mStartTime = System.getTimer();
            
            // Create a new timer if needed
            if (mTimer == null) {
                mTimer = new Timer.Timer();
                mTimer.start(method(:onTick), 1000, true);
            }
            
            mIsRunning = true;
            System.println("Timer started: " + mStartTime);
            saveState();
            
            // Force an immediate update
            if (mCallback != null) {
                mCallback.invoke();
            }
        }
    }
    
    // Pause the timer
    function pause() {
        if (mIsRunning) {
            // Add the time since start to the accumulated time
            var now = System.getTimer();
            mAccumulatedTime += now - mStartTime;
            mStartTime = 0; // Reset start time
            mIsRunning = false;
            
            System.println("Timer paused. Accumulated: " + mAccumulatedTime);
            saveState();
            
            // Force an immediate update
            if (mCallback != null) {
                mCallback.invoke();
            }
        }
    }
    
    // Set countdown duration in seconds
    function setCountdownDuration(durationSeconds as Number) {
        // Don't reset the timer completely; preserve lap history
        
        // Stop the timer if it's running
        if (mIsRunning) {
            pause();
        }
        
        // Reset timing state but keep laps
        mStartTime = 0;
        mAccumulatedTime = 0;
        mLastLapTime = 0;
        
        // Set countdown parameters
        mCountdownDuration = durationSeconds;
        mCountdownReached = false;
        
        // Start the timer
        start();
        
        System.println("Countdown set to: " + durationSeconds + " seconds");
        saveState();
    }
    
    // Get the current countdown state
    function getCountdownState() as Dictionary {
        var elapsedMilliseconds = getElapsedMilliseconds();
        var elapsedSeconds = elapsedMilliseconds / 1000;
        var remainingSeconds = mCountdownDuration - elapsedSeconds;
        
        return {
            "duration" => mCountdownDuration,
            "elapsed" => elapsedSeconds,
            "remaining" => remainingSeconds,
            "isCountdownReached" => mCountdownReached || remainingSeconds <= 0
        };
    }
    
    // Check and notify if countdown has reached zero
    function checkCountdownCompletion() as Boolean {
        if (mCountdownReached) {
            return false;
        }
        
        var countdownState = getCountdownState();
        var remaining = countdownState.get("remaining");
        
        // Check if remaining is a number and less than or equal to zero
        if (remaining != null && remaining instanceof Number && remaining <= 0 && !mCountdownReached) {
            mCountdownReached = true;
            saveState();
            return true;
        }
        
        return false;
    }
    
    // Reset the timer
    function reset() {
        // Preserve the timer, but reset all state
        mStartTime = 0;
        mAccumulatedTime = 0;
        mLastLapTime = 0;
        mIsRunning = false;
        mLaps = [] as Array<LapData>;
        mCountdownReached = false;
        
        System.println("Timer reset");
        saveState();
        
        // Force an immediate update
        if (mCallback != null) {
            mCallback.invoke();
        }
    }
    
    // Add a lap with the specified type
    function addLap(lapType as Number) as Void {
        var currentTotalTime = getElapsedMilliseconds();
        var lapTime = currentTotalTime - mLastLapTime;
        
        if (lapTime > 0) {
            var lap = new LapData(lapTime, lapType, mLastLapTime, mCountdownDuration);
            mLaps.add(lap);
            mLastLapTime = currentTotalTime;
            
            System.println("Lap added: " + lapTime + "ms, type: " + lapType);
            saveState();
        }
    }
    
    // Get whether the timer is currently running
    function isRunning() as Boolean {
        return mIsRunning;
    }
    
    // Get the countdown duration in seconds
    function getCountdownDuration() as Number {
        return mCountdownDuration;
    }
    
    // Get whether the countdown has reached zero
    function hasCountdownReached() as Boolean {
        return mCountdownReached;
    }
    
    // The number of recorded laps
    function getLapCount() as Number {
        return mLaps.size();
    }
    
    // Get a specific lap data object
    function getLap(index as Number) as LapData? {
        if (index >= 0 && index < mLaps.size()) {
            return mLaps[index];
        }
        return null;
    }
    
    // Get all lap data objects
    function getAllLaps() as Array<LapData> {
        return mLaps;
    }
    
    // Get the current total elapsed time in milliseconds
    function getElapsedMilliseconds() as Number {
        var elapsed = mAccumulatedTime;
        
        if (mIsRunning && mStartTime > 0) {
            var now = System.getTimer();
            elapsed += now - mStartTime;
        }
        
        return elapsed;
    }
    
    // Get the current lap time (time since last lap) in milliseconds
    function getCurrentLapMilliseconds() as Number {
        return getElapsedMilliseconds() - mLastLapTime;
    }
    
    // Save the current state to persistent storage
    function saveState() as Void {
        // Prepare an array of lap dictionaries for storage
        var lapDicts = [] as Array<Dictionary>;
        for (var i = 0; i < mLaps.size(); i++) {
            lapDicts.add(mLaps[i].toDict());
        }
        
        // Create state dictionary with all relevant state
        var state = {
            "accTime" => mAccumulatedTime,
            "lastLapTime" => mLastLapTime,
            "isRunning" => mIsRunning,
            "startTime" => mStartTime,
            "laps" => lapDicts,
            "countdownDuration" => mCountdownDuration,
            "countdownReached" => mCountdownReached
        };
        
        // Store the state
        Storage.setValue("stopwatchState", state);
    }
    
    // Called every second by the timer to update the UI
    function onTick() as Void {
        if (mCallback != null) {
            // Check countdown completion before updating UI
            if (mIsRunning) {
                checkCountdownCompletion();
            }
            
            mCallback.invoke();
        }
    }
} 