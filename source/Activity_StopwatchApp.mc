import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class Activity_StopwatchApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        // Nothing to do here
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
        // Nothing to do here
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        var view = new Activity_StopwatchView();
        var delegate = new Activity_StopwatchDelegate();
        delegate.setView(view);
        return [ view, delegate ];
    }

}

function getApp() as Activity_StopwatchApp {
    return Application.getApp() as Activity_StopwatchApp;
}