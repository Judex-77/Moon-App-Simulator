import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class MoonAppMenu2Delegate extends WatchUi.Menu2InputDelegate  {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item) {
        activeView = item.getId();
        WatchUi.switchToView(ViewList[item.getId()], new MoonAppDelegate(), WatchUi.SLIDE_IMMEDIATE);
    }

    function onBack() {
        WatchUi.switchToView(ViewList[activeView], new MoonAppDelegate(), WatchUi.SLIDE_IMMEDIATE);
    }

}