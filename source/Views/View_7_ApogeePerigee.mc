import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Position;
import Toybox.Lang;
import Toybox.Application.Properties;
import Toybox.Math;


class MoonAppView_Moon_7 extends WatchUi.View {

    var Moon_7_Timer = new Timer.Timer();
    
    function initialize() {
        View.initialize();
    }

   // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.Layout_Moon_7(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        // Initialize timer 
        ViewTimeCounter = 0;
        Moon_7_Timer.start(method(:Moon_7_Timer_Callback), 1000, true); // A 1-second timer
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
            "Time" => false,
            "SunPosit" => false,
            "SunAzAlt" => false,
            "SunRTS" => false,
            "SunEvents" => false,
            "MoonAccuracy" => 15,
            "MoonPosit" => false,
            "MoonAzAlt" => false,
            "MoonDiamDist" => false,
            "MoonCycFrac" => false,
            "MoonRTS" => false,
            "MoonEvents" => false,
            "MoonDay" => false,
            "MoonPeriod" => false,
            "MoonPerigeeApogee" => true,
        };
        var Moon = getAstroData(myLocation, height, astroDataContent);

        View.onUpdate(dc);

        var MoonFont_Type = Graphics.getVectorFont({
            :face => "RobotoCondensedBold",
            :size => 30 * sc
        });
        var MoonFont_DateTime = Graphics.getVectorFont({
            :face => "RobotoCondensedBold",
            :size => 25 * sc
        });
        var MoonFont_Data = Graphics.getVectorFont({
            :face => "RobotoCondensedRegular",
            :size => 25 * sc
        });
        var MoonFont_Tiny = Graphics.getVectorFont({
            :face => "RobotoCondensedBold",
            :size => 30 * sc
        });
        var MoonFont_XTiny = Graphics.getVectorFont({
            :face => "RobotoCondensedBold",
            :size => 19 * sc
        });
        var MoonFont_XTiny2 = Graphics.getVectorFont({
            :face => "RobotoCondensedRegular",
            :size => 19 * sc
        });

        if (MoonFont_Tiny == null) {
            MoonFont_Tiny = Graphics.getVectorFont({
                :face => "RobotoRegular",
                :size => 30 * sc
            });
            MoonFont_XTiny = Graphics.getVectorFont({
                :face => "NanumGothicBold",
                :size => 19 * sc
            });
            MoonFont_Type = Graphics.getVectorFont({
                :face => "NanumGothicBold",
                :size => 30 * sc
            });
            MoonFont_Data = Graphics.getVectorFont({
                :face => "RobotoRegular",
                :size => 23 * sc
            });
            MoonFont_DateTime = Graphics.getVectorFont({
                :face => "NanumGothicBold",
                :size => 23 * sc
            });
            MoonFont_XTiny2 = Graphics.getVectorFont({
                :face => "RobotoRegular",
                :size => 19 * sc
            });
        }

        // draw next apogee and perigee
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(sc2,  4 * sc, MoonFont_XTiny, Moon["date"], Graphics.TEXT_JUSTIFY_CENTER);
        
        var AP = Moon["MoonPerigeeApogee"];
        var sStrD = "" as Lang.String;
        var sStrT = "" as Lang.String;
        var sDist = "" as Lang.String;
        var sDiam = "" as Lang.String;
        var sAz = "" as Lang.String;
        var sAlt = "" as Lang.String;
        var y0 = 25.0d as Lang.Double;

        for (var i = 0; i < AP.size(); i++) {
            if (UnitMetric == true) {
                sStrD = Lang.format("$1$.$2$.$3$", [AP[i]["day"].format("%02d"), AP[i]["month"].format("%02d"),AP[i]["year"].format("%4d")]);
            } else {
                sStrD = Lang.format("$1$-$2$-$3$", [AP[i]["month"].format("%02d"), AP[i]["day"].format("%02d"),AP[i]["year"].format("%4d")]);
            }
            if (Hour24 == true) {
                sStrT = HHMM(AP[i]["time"]);
            } else {
                var Hour12 = AP[i]["time"];
                if (AP[i]["time"] > 12) { Hour12 -= 12.0d; }
                if (Hour12 < 1.0d) { Hour12 += 12.0d; }
                sStrT = HHMM(Hour12);
                sStrT += (AP[i]["time"] < 12) ? " am" : " pm";
            }

            if (UnitMetric == true) {
                sDist = AP[i]["distance"].format("%.1f") +" km";
            } else {
                sDist = (AP[i]["distance"] * km2mil).format("%.1f") +" mi";
            }
            sDist = "Δ: " + sDist;

            sDiam = "Ø: " + (AP[i]["diameter"] * 60.0d).format("%.2f") + "'";

            sAz = "Az: " + AP[i]["az"].format("%.1f") + "°";
            sAlt = "Alt: " + AP[i]["alt"].format("%.1f") + "°";

            if (AP[i]["alt"] < 0) {
                dc.setColor(0xff5555, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(0x55ff55, Graphics.COLOR_TRANSPARENT);
            }
            dc.drawText(sc2, (y0 + (i * (140 - y0)) + 0) * sc, MoonFont_Type, AP[i]["type"], Graphics.TEXT_JUSTIFY_CENTER);
            dc.setColor(0xffffff, Graphics.COLOR_TRANSPARENT);
            dc.drawText(sc2, (y0 + (i * (140 - y0)) + 30) * sc, MoonFont_DateTime, sStrD + "   " + sStrT, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(sc2, (y0 + (i * (140 - y0)) + 55) * sc, MoonFont_Data, sDist + "   " + sDiam, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(sc2, (y0 + (i * (140 - y0)) + 77) * sc, MoonFont_Data, sAz + "   " + sAlt, Graphics.TEXT_JUSTIFY_CENTER);

        }
        dc.drawRadialText(140*sc, 140*sc, MoonFont_XTiny2, "data: geocentric", Graphics.TEXT_JUSTIFY_CENTER, 270, 135*sc, Graphics.RADIAL_TEXT_DIRECTION_COUNTER_CLOCKWISE);

        // draw buttons
        if (System.getDeviceSettings().isTouchScreen) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.fillPolygon(getButtonPrevDay(0, 140 * sc));
            dc.fillPolygon(getButtonNextDay(0, 140 * sc));
        }
        // draw days offset
        if (System.getDeviceSettings().isTouchScreen) {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            if (DaysOffset < 0) {
                dc.drawText(32 * sc, 130 * sc, MoonFont_XTiny, DaysOffset.abs().toString(), Graphics.TEXT_JUSTIFY_RIGHT);
            }
            if (DaysOffset > 0) {
                dc.drawText(248 * sc, 130 * sc, MoonFont_XTiny, DaysOffset.toString(), Graphics.TEXT_JUSTIFY_LEFT);
            }
        }

        // draw simulation indicator
        if (LatLonSimulator == true) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(140 * sc, 260 * sc, 12 * sc);
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.drawText(140 * sc, 245 * sc, MoonFont_Tiny, "S", Graphics.TEXT_JUSTIFY_CENTER);
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
        Moon_7_Timer.stop();
    }

    function Moon_7_Timer_Callback() {
        ViewTimeCounter++;
        WatchUi.requestUpdate();
    }

}
