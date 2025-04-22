import Toybox.Lang;
import Toybox.WatchUi;

class Activity_StopwatchDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() as Boolean {
        WatchUi.pushView(new Rez.Menus.MainMenu(), new Activity_StopwatchMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

}