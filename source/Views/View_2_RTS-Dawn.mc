import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Position;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Application.Properties;

class MoonAppView_Moon_2 extends WatchUi.View {

    var Moon_2_Timer = new Timer.Timer();
    
    function initialize() {
        View.initialize();
    }

   // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.Layout_Moon_2(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        ViewTimeCounter = 0;
        Moon_2_Timer.start(method(:Moon_2_Timer_Callback), 1000, true); 
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        // Call the parent onUpdate function to redraw the layout
        var LatLonSimulator = Properties.getValue("LatLonSimulator");
        var height = 0.0 as Lang.Double;
        var myLocation = [];
        var positionInfo = Position.getInfo();

        if (LatLonSimulator == false) {
            if (positionInfo.accuracy == 0) {
                WatchUi.switchToView(ViewList[0], null, WatchUi.SLIDE_IMMEDIATE);
            }
            if (positionInfo has :altitude && positionInfo.altitude != null) {
                height = positionInfo.altitude;
            }
            myLocation = positionInfo.position.toDegrees();
        } else {
            myLocation = [Properties.getValue("LatSimulator"), Properties.getValue("LonSimulator")];
        }

        var astroDataContent = {
            "Date" => true,
            "Time" => true,
            "SunPosit" => false,
            "SunAzAlt" => false,
            "SunRTS" => false,
            "SunEvents" => true,
            "MoonAccuracy" => 15,
            "MoonPosit" => false,
            "MoonAzAlt" => false,
            "MoonDiamDist" => false,
            "MoonCycFrac" => false,
            "MoonRTS" => true,
            "MoonEvents" => false,
            "MoonDay" => false,
            "MoonPeriod" => false,
            "MoonPerigeeApogee" => false,
        };
        var Moon = getAstroData(myLocation, height, astroDataContent);

        View.onUpdate(dc);

        var MoonFont_Tiny = Graphics.getVectorFont({
            :face => "RobotoCondensedBold",
            :size => 30 * sc
        });
        var MoonFont_XTiny = Graphics.getVectorFont({
            :face => "RobotoCondensedBold",
            :size => 19 * sc
        });
        var DateFont = Graphics.getVectorFont({
            :face => "RobotoCondensedRegular", 
            :size => 19 * sc
        });
        var DawnPhasesTimeFont = Graphics.getVectorFont({
            :face => "RobotoCondensedRegular",
            :size => 15 * sc
        });
        var MoonTimeFont = Graphics.getVectorFont({
            :face => "RobotoCondensedRegular",
            :size => 20 * sc
        });
        
        if (MoonFont_Tiny == null) {
            MoonFont_Tiny = Graphics.getVectorFont({
                :face => "NanumGothicBold",
                :size => 30 * sc
            });
            MoonFont_XTiny = Graphics.getVectorFont({
                :face => "RobotoRegular",
                :size => 19 * sc
            });
            DawnPhasesTimeFont = Graphics.getVectorFont({
                :face => "RobotoRegular",
                :size => 15 * sc
            });
            MoonTimeFont = Graphics.getVectorFont({
                :face => "NanumGothicBold",
                :size => 20 * sc
            });
            DateFont = Graphics.getVectorFont({
                :face => "RobotoRegular",
                :size => 17 * sc
            });
        }


        // draw buttons
        if (System.getDeviceSettings().isTouchScreen) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.fillPolygon(getButtonPrevDay( 65 * sc, 140 * sc)); 
            dc.fillPolygon(getButtonNextDay(-65 * sc, 140 * sc)); 
            // draw days offset
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            if (DaysOffset < 0) {
                dc.drawText(97 * sc, 130 * sc, MoonFont_XTiny, DaysOffset.abs().toString(), Graphics.TEXT_JUSTIFY_RIGHT);
            }
            if (DaysOffset > 0) {
                dc.drawText(183 * sc, 130 * sc, MoonFont_XTiny, DaysOffset.toString(), Graphics.TEXT_JUSTIFY_LEFT);
            }
        }

        // draw date
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(140 * sc, 130 * sc, DateFont, Moon["date"], Graphics.TEXT_JUSTIFY_CENTER);

        // draw dawn phases
        var IdxPolarDayNight = 0 as Lang.Number;
        if (Moon["Sun_Today_polarDay"] == true) { IdxPolarDayNight = 1; }
        if (Moon["Sun_Today_polarNight"] == true) { IdxPolarDayNight = -1; }
        var DP = getDawnPhases(Moon["Sun_Today_events"], IdxPolarDayNight);
        var DPx = 140 * sc;
        var DPy = 140 * sc;
        var DPr = 123 * sc;
        dc.setPenWidth(4 * sc);
        for (var i = 0; i < DP.size(); i++) {
            dc.setColor(DP[i][2], Graphics.COLOR_TRANSPARENT);
            dc.drawArc(DPx, DPy, DPr, Graphics.ARC_CLOCKWISE, DP[i][0], DP[i][1]);
        }

        // draw moon arc
        var t1 = (Moon["Moon_Today_rise_bool"] == true) ? Moon["Moon_Today_rise_time"] : 0.0;
        var t2 = (Moon["Moon_Today_set_bool"] == true) ? Moon["Moon_Today_set_time"] : 24.0;
        var degS = Math.round(270 - t1 * 15).toNumber();
        var degE = Math.round(270 - t2 * 15).toNumber();
        if (degE < 0) { degE += 360; }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(4 * sc);
        dc.drawArc(DPx, DPy, DPr - 8 * sc, Graphics.ARC_CLOCKWISE, degS, degE);
        


        // draw 24h-clock
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        var H24 = "" as Lang.String;
        var H24angle = 270;
        var H24direction = 0;
        var H24radius = 130 * sc;
        var H24x1 = 0;
        var H24x2 = 0;
        var H24y1 = 0;
        var H24y2 = 0;
        var H24r0 = 126;
        for (var i = 1; i <= 24; i++) {
            H24angle = 270 - i * 15;
            H24angle += (H24angle < 0) ? 360 : 0;
            H24 = ((i <= 9) ? "0" : "") + i.toString();
            H24direction = (H24angle <= 180) ? Graphics.RADIAL_TEXT_DIRECTION_CLOCKWISE : Graphics.RADIAL_TEXT_DIRECTION_COUNTER_CLOCKWISE;
            H24radius = 130 * sc + 9 * sc * H24direction;
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawRadialText(140 * sc, 140 * sc, DawnPhasesTimeFont, H24, Graphics.TEXT_JUSTIFY_CENTER, H24angle, H24radius, H24direction);
            
            H24x1 = 140 - (H24r0 * Math.sin(i * 15 * _2rad));
            H24y1 = 140 + (H24r0 * Math.cos(i * 15 * _2rad));
            H24x2 = 140 - ((H24r0 - 7) * Math.sin(i * 15 * _2rad));
            H24y2 = 140 + ((H24r0 - 7) * Math.cos(i * 15 * _2rad));
            dc.drawLine(H24x1 * sc, H24y1 * sc, H24x2 * sc, H24y2 * sc);
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            H24x1 = 140 - ((H24r0 - 8) * Math.sin(i * 15 * _2rad));
            H24y1 = 140 + ((H24r0 - 8) * Math.cos(i * 15 * _2rad));
            H24x2 = 140 - ((H24r0 - 13) * Math.sin(i * 15 * _2rad));
            H24y2 = 140 + ((H24r0 - 13) * Math.cos(i * 15 * _2rad));
            dc.drawLine(H24x1 * sc, H24y1 * sc, H24x2 * sc, H24y2 * sc);
        }
        dc.setPenWidth(4);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT); // 24h - divider
        H24x1 = 140 - ((H24r0 - 0) * Math.sin(24 * 15 * _2rad));
        H24y1 = 140 + ((H24r0 - 0) * Math.cos(24 * 15 * _2rad));
        H24x2 = 140 - ((H24r0 - 13) * Math.sin(24 * 15 * _2rad));
        H24y2 = 140 + ((H24r0 - 13) * Math.cos(24 * 15 * _2rad));
        dc.drawLine(H24x1 * sc, H24y1 * sc, H24x2 * sc, H24y2 * sc);
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT); // actual time
        H24x1 = 140 - ((H24r0 - 0) * Math.sin(Moon["time0"] * 15 * _2rad));
        H24y1 = 140 + ((H24r0 - 0) * Math.cos(Moon["time0"] * 15 * _2rad));
        H24x2 = 140 - ((H24r0 - 13) * Math.sin(Moon["time0"] * 15 * _2rad));
        H24y2 = 140 + ((H24r0 - 13) * Math.cos(Moon["time0"] * 15 * _2rad));
        dc.drawLine(H24x1 * sc, H24y1 * sc, H24x2 * sc, H24y2 * sc);
        

        // draw markers for moon events
        var MEcolors = [MoonEventColors["rise"], MoonEventColors["transit"], MoonEventColors["set"]];
        var PointsMEmarker = [];
        if (Moon["Moon_Today_rise_bool"] == true) {
            dc.setColor(MEcolors[0], Graphics.COLOR_TRANSPARENT);
            PointsMEmarker = getMoonEventMarker(Moon["Moon_Today_rise_time"], 140 * sc, 140 * sc, 102 * sc);
            dc.fillPolygon(PointsMEmarker);
        }
        if (Moon["Moon_Today_set_bool"] == true) {
            dc.setColor(MEcolors[1], Graphics.COLOR_TRANSPARENT);
            PointsMEmarker = getMoonEventMarker(Moon["Moon_Today_set_time"], 140 * sc, 140 * sc, 102 * sc);
            dc.fillPolygon(PointsMEmarker);
        }
        if (Moon["Moon_Today_transit_bool"] == true) {
            dc.setColor(MEcolors[2], Graphics.COLOR_TRANSPARENT);
            PointsMEmarker = getMoonEventMarker(Moon["Moon_Today_transit_time"], 140 * sc, 140 * sc, 102 * sc);
            dc.fillPolygon(PointsMEmarker);
        }

        // draw rise, set, transit
        var MoonTimes = [
            ["rise", Moon["Moon_Today_rise_bool"], Moon["Moon_Today_rise_time"]],
            ["set", Moon["Moon_Today_set_bool"], Moon["Moon_Today_set_time"]],
            ["transit", Moon["Moon_Today_transit_bool"], Moon["Moon_Today_transit_time"]]
        ];
        var TimesSequence = sortTimes(MoonTimes, 1);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        for (var i=0; i<=2; i++) {
            if (TimesSequence[i][0].equals("rise"))    { dc.setColor(MEcolors[0], Graphics.COLOR_TRANSPARENT); }
            if (TimesSequence[i][0].equals("set"))     { dc.setColor(MEcolors[1], Graphics.COLOR_TRANSPARENT); }
            if (TimesSequence[i][0].equals("transit")) { dc.setColor(MEcolors[2], Graphics.COLOR_TRANSPARENT); }
            if (Moon["Moon_Today_"+TimesSequence[i][0]+"_bool"]) {
                H24angle = 270 - Moon["Moon_Today_"+TimesSequence[i][0]+"_time"] * 15;
                H24angle += (H24angle < 0) ? 360 : 0;
                H24direction = (H24angle <= 180) ? Graphics.RADIAL_TEXT_DIRECTION_CLOCKWISE : Graphics.RADIAL_TEXT_DIRECTION_COUNTER_CLOCKWISE;
                H24radius = 78 * sc + 12 * sc * H24direction;
                dc.drawRadialText(140 * sc, 140 * sc, MoonTimeFont, Moon["Moon_Today_"+TimesSequence[i][0]+"_label"], Graphics.TEXT_JUSTIFY_CENTER, H24angle, H24radius, H24direction);
            }
        }

        // draw simulation indicator
        if (LatLonSimulator == true) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(140 * sc, 100 * sc, 12 * sc);
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.drawText(140 * sc, 85 * sc, MoonFont_Tiny, "S", Graphics.TEXT_JUSTIFY_CENTER);
        }

        // draw view indicator
        if (ViewTimeCounter <= ViewIndicatorTime) {
            var VI = ViewIndicator as Lang.Array;
            dc.setPenWidth(2 * sc);
            for (var i = 0; i < VI.size(); i++) {
                dc.setColor(0x00000, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(VI[i][0] * sc, VI[i][1] * sc, 8 * sc);
                if ((i + 1) == activeView) {
                    dc.setColor(ViewIndicatorColorActive, Graphics.COLOR_TRANSPARENT);
                    dc.fillCircle(VI[i][0] * sc, VI[i][1] * sc, 5 * sc);
                } else {
                    dc.setColor(ViewIndicatorColor, Graphics.COLOR_TRANSPARENT);
                    dc.drawCircle(VI[i][0] * sc, VI[i][1] * sc, 5 * sc);
                }
            }
        }


    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
        Moon_2_Timer.stop();
    }

    function Moon_2_Timer_Callback() {
        ViewTimeCounter++;
        WatchUi.requestUpdate();
    }

}
