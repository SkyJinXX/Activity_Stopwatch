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
    
    // Time tracking
    private var mStartTime as Number = 0;         // When the stopwatch was last started/resumed
    private var mAccumulatedTime as Number = 0;   // Total accumulated time while stopwatch not running
    private var mLastLapTime as Number = 0;       // Accumulated time at last lap
    
    private var mIsRunning as Boolean = false;
    private var mLaps as Array<LapData>;
    private var mCallback;
    
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
            
        // 确保UI每秒更新一次
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
    
    // Start the stopwatch
    function start() {
        if (!mIsRunning) {
            mStartTime = System.getTimer();
            
            // 如果定时器不存在，创建一个新的
            if (mTimer == null) {
                mTimer = new Timer.Timer();
                mTimer.start(method(:onTick), 1000, true);
            }
            
            mIsRunning = true;
            System.println("Stopwatch started: " + mStartTime);
            saveState();
            
            // Force an immediate update
            if (mCallback != null) {
                mCallback.invoke();
            }
        }
    }
    
    // Pause the stopwatch
    function pause() {
        if (mIsRunning) {
            // 保留定时器用于UI更新，但停止实际计时
            // Add the time since start to the accumulated time
            var now = System.getTimer();
            mAccumulatedTime += now - mStartTime;
            mStartTime = 0; // Reset start time
            mIsRunning = false;
            
            System.println("Stopwatch paused. Accumulated: " + mAccumulatedTime);
            saveState();
            
            // Force an immediate update
            if (mCallback != null) {
                mCallback.invoke();
            }
        }
    }
    
    // Reset the stopwatch
    function reset() {
        // 保留定时器，但重置所有状态
        mStartTime = 0;
        mAccumulatedTime = 0;
        mLastLapTime = 0;
        mIsRunning = false;
        mLaps = [] as Array<LapData>;
        saveState();
        
        // Force an immediate update
        if (mCallback != null) {
            mCallback.invoke();
        }
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
        
        // Calculate lap time as the difference between current elapsed time and last lap time
        var lapTime = currentElapsedTime - mLastLapTime;
        
        // Update last lap time to current elapsed time
        mLastLapTime = currentElapsedTime;
        
        System.println("New lap - Elapsed: " + currentElapsedTime + 
                      ", Lap time: " + lapTime);
        
        // Create the lap with timing info
        var lap = new LapData(lapTime, activityType, currentElapsedTime - lapTime);
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
            var runningTime = currentTime - mStartTime;
            return mAccumulatedTime + runningTime;
        } else {
            return mAccumulatedTime;
        }
    }
    
    // Get current lap time
    function getCurrentLapTime() as Number {
        // Current lap time is exactly (total elapsed time - last lap time)
        return getElapsedTime() - mLastLapTime;
    }
    
    // Get the formatted display times that are guaranteed to be synchronized
    function getSynchronizedTimes() as Dictionary {
        // 直接获取当前时间，确保每次调用都是最新值
        var elapsedTime = getElapsedTime();
        var lapTime = getCurrentLapTime();
        
        /* 减少日志输出
        System.println("getSynchronizedTimes called:");
        System.println(" - System time: " + System.getTimer());
        System.println(" - Elapsed: " + elapsedTime + "ms, Lap: " + lapTime + "ms");
        System.println(" - Running: " + mIsRunning + ", StartTime: " + mStartTime + ", AccTime: " + mAccumulatedTime);
        */
        
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
    
    // Timer tick callback - 每秒更新一次UI
    function onTick() as Void {
        // This is called every second to update the UI
        if (mCallback != null) {
            // 减少日志输出，仅在调试时需要时开启
            // System.println("Tick: UI update at " + System.getTimer());
            
            // 检查是否有时间在运行
            /* 减少日志输出
            if (mIsRunning) {
                System.println("Running mode - Time: " + getElapsedTime() + "ms");
            } else if (mAccumulatedTime > 0) {
                System.println("Paused mode - Accumulated: " + mAccumulatedTime + "ms");
            }
            */
            
            // 强制更新UI
            mCallback.invoke();
        } else {
            System.println("Tick: WARNING - no callback registered");
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
            "startTime" => mIsRunning ? mStartTime : 0,  // Only save real start time if running
            "laps" => lapDicts
        };
        
        System.println("Saving state - accTime: " + mAccumulatedTime + 
                      ", lastLapTime: " + mLastLapTime + 
                      ", isRunning: " + mIsRunning + 
                      ", startTime: " + (mIsRunning ? mStartTime : 0));
                      
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