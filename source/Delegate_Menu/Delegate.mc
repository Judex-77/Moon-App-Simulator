import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

class MoonAppDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() {
        var menu = new WatchUi.Menu2({
            :title => "Moon App v2.0.11"
        });
        var delegate;
        menu.addItem(
            new MenuItem(
                "Moon Data",
                "the moon in numbers",
                1,
                {}
            )
        );
        menu.addItem(
            new MenuItem(
                "Moon R-T-S",
                "rise, transit, set",
                2,
                {}
            )
        );
        menu.addItem(
            new MenuItem(
                "Moon Altitude-Time",
                "diagram",
                3,
                {}
            )
        );
        menu.addItem(
            new MenuItem(
                "Moon Azimuth-Time",
                "diagram",
                4,
                {}
            )
        );
        menu.addItem(
            new MenuItem(
                "Moon Azi-Alt-Time",
                "360°-diagram",
                5,
                {}
            )
        );
        menu.addItem(
            new MenuItem(
                "Moon Event Dates",
                "new, full, quarters",
                6,
                {}
            )
        );
        menu.addItem(
            new MenuItem(
                "Moon Distances",
                "apogee, perigee",
                7,
                {}
            )
        );
        delegate = new MoonAppMenu2Delegate();
        WatchUi.switchToView(menu, delegate, WatchUi.SLIDE_IMMEDIATE);
        return true;
    }


    function onKey(evt) {
    }

    function onNextPage() {
        if (activeView < (ViewList.size() - 1)) {
            activeView++;
        } else {
            activeView = 1;
        }
        WatchUi.switchToView(ViewList[activeView], self, WatchUi.SLIDE_IMMEDIATE);
    }

    function onPreviousPage() {
        if (activeView > 1 ) {
            activeView--;
        } else {
            activeView = ViewList.size() - 1;
        }
        WatchUi.switchToView(ViewList[activeView], self, WatchUi.SLIDE_IMMEDIATE);
    }

    function onTap(clickEvent) {
    }

    function onNextDay() {
        DaysOffset++;
    }

    function onPreviousDay() {
        DaysOffset--;
    }

    function onToday() {
        DaysOffset = 0;
    }

}