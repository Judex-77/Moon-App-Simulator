import Toybox.Application;
import Toybox.Lang;
import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Position;
import Toybox.System;
import Toybox.Timer;
import Toybox.Application.Properties;

public var activeView = 1 as Lang.Number; //1
public var DaysOffset = 0 as Lang.Number;
public var TimeOffset1 = 0.0d as Lang.Double;
public var TimeOffset2 = 0.0d as Lang.Double;
public var StatusTZO1 = 0.0d as Lang.Double;
public var StatusTZO2 = 0.0d as Lang.Double;
public var StatusDST1 = 0.0d as Lang.Double;
public var StatusDST2 = 0.0d as Lang.Double;
public var sc = 0.0d as Lang.Double;
public var sc2 = 0.0d as Lang.Double;
public var UnitMetric = true as Lang.Boolean;
public var Hour24 = true as Lang.Boolean;
public var ViewIndicator = [] as Lang.Array;
public var ViewTimeCounter = 0 as Lang.Long;
public var ViewIndicatorTime = 1 as Lang.Number;
public var ViewIndicatorColor = 0xaa5555;
public var ViewIndicatorColorActive = 0xff5555;

public var TouchScreen1 as Lang.Boolean;
public var TouchScreen2 as Lang.Boolean;

public var StatusSimulation1 = false as Lang.Boolean;
public var StatusSimulation2 = false as Lang.Boolean;

public var ViewList as Lang.Array;

public var MoonEventColors as Lang.Object;
public var SunEventColors as Lang.Object;

public var MoonPeriodicTerms_LonRange = [] as Lang.Array;
public var MoonPeriodicTerms_Lat = [] as Lang.Array;
public var MoonPeriodicTerms_NewFull = [] as Lang.Array;
public var MoonPeriodicTerms_Quarters = [] as Lang.Array;
public var MoonPeriodicTerms_ArgsPlanets = [] as Lang.Array;

public const MoonPicAngleCorrection = 20.0d as Lang.Double;

class MoonAppApp extends Application.AppBase {

    var StatusSimulation_Timer;
    
    private var _positionView as MoonAppView;
    
    function initialize() {
        /* workaround firmware 16.22 bug (no non-primitive global variables) */
        TouchScreen1 = System.getDeviceSettings().isTouchScreen as Lang.Boolean;
        TouchScreen2 = System.getDeviceSettings().isTouchScreen as Lang.Boolean;
        ViewList = [
            new MoonAppView(), 
            new MoonAppView_Moon_1(),
            new MoonAppView_Moon_2(),
            new MoonAppView_Moon_3(),
            new MoonAppView_Moon_4(),
            new MoonAppView_Moon_5(),
            new MoonAppView_Moon_6(),
            new MoonAppView_Moon_7()
        ];
        MoonEventColors = {
            "rise" => 0xFF00FF,
            "transit" => 0x55FF00,
            "set" => 0x00FFFF
        };
        SunEventColors = {
            "Night" =>      0x000055,
            "DawnAstro" =>  0x0000aa,
            "DawnNautic" => 0x0000ff,
            "DawnCivil" =>  0x0055ff,
            "BlueHour" =>   0x00aaff,
            "Sunrise" =>    0xff5500,
            "GoldenHour" => 0xffaa00,
            "Daylight" =>   0xffff55
        };

        MoonPeriodicTerms_LonRange = getMoonPeriodicTerms_LonRange();
        MoonPeriodicTerms_Lat = getMoonPeriodicTerms_Lat();
        MoonPeriodicTerms_NewFull = getMoonPeriodicTerms_NewFull();
        MoonPeriodicTerms_Quarters = getMoonPeriodicTerms_Quarters();
        MoonPeriodicTerms_ArgsPlanets = getMoonPeriodicTerms_ArgsPlanets();

        ViewIndicator = getViewIndicator();

        StatusSimulation_Timer = new Timer.Timer();

        TimeOffset1 = Properties.getValue("OverrideTimezone");
        TimeOffset2 = Properties.getValue("OverrideTimezone");
        
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        // Initialize Location of GPS
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
        // Initialize timer to check simulation status
        StatusSimulation1 = Properties.getValue("LatLonSimulator");
        StatusSimulation2 = Properties.getValue("LatLonSimulator");
        StatusTZO1 = Properties.getValue("OverrideTimezone");
        StatusTZO2 = Properties.getValue("OverrideTimezone");
        StatusDST1 = Properties.getValue("OverrideDST");
        StatusDST2 = Properties.getValue("OverrideDST");
        StatusSimulation_Timer.start(method(:StatusSimulation_Timer_Callback), 1000, true); // A 1-second timer
        // Initialize public variables
        sc = (System.getDeviceSettings().screenWidth / 280.0).toDouble();
        sc2 = (System.getDeviceSettings().screenWidth / 2).toDouble();
        UnitMetric = System.getDeviceSettings().paceUnits == 0 ? true : false;
        Hour24 = System.getDeviceSettings().is24Hour == true ? true : false;
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
        Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
        StatusSimulation_Timer.stop();
    }

    // Return the initial view of your application here
    public function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ViewList[0]];
    }

    function onPosition(info as Info) {
    }

    function StatusSimulation_Timer_Callback() {
        StatusSimulation2 = Properties.getValue("LatLonSimulator");
        if (StatusSimulation1 != StatusSimulation2) {
            StatusSimulation1 = Properties.getValue("LatLonSimulator");
            WatchUi.requestUpdate();
        }
        StatusTZO2 = Properties.getValue("OverrideTimezone");
        if (StatusTZO1 != StatusTZO2) {
            StatusTZO1 = Properties.getValue("OverrideTimezone");
            WatchUi.requestUpdate();
        }
        StatusDST2 = Properties.getValue("OverrideDST");
        if (StatusDST1 != StatusDST2) {
            StatusDST1 = Properties.getValue("OverrideDST");
            WatchUi.requestUpdate();
        }
        TouchScreen2 = System.getDeviceSettings().isTouchScreen;
        if (TouchScreen1 != TouchScreen2) {
            TouchScreen1 = System.getDeviceSettings().isTouchScreen;
            WatchUi.requestUpdate();
        }
        TimeOffset2 = Properties.getValue("OverrideTimezone");
        if (TimeOffset1 != TimeOffset2) {
            TimeOffset1 = Properties.getValue("OverrideTimezone");
            WatchUi.requestUpdate();
        }
    }

}

function getApp() as MoonAppApp {
    return Application.getApp() as MoonAppApp;
}

