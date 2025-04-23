import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

class Activity_StopwatchApp extends Application.AppBase {
    private var mView;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        // Nothing to do here - state will be loaded in the view
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
        // Save the stopwatch state
        if (mView != null && mView.mStopwatch != null) {
            System.println("Saving stopwatch state...");
            mView.mStopwatch.saveState();
        }
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        mView = new Activity_StopwatchView();
        var delegate = new Activity_StopwatchDelegate();
        delegate.setView(mView);
        return [ mView, delegate ];
    }

}

function getApp() as Activity_StopwatchApp {
    return Application.getApp() as Activity_StopwatchApp;
}