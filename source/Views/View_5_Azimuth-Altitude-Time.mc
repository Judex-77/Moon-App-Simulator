import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Position;
import Toybox.Lang;
import Toybox.Application.Properties;
import Toybox.Math;


class MoonAppView_Moon_5 extends WatchUi.View {

    var Moon_5_Timer = new Timer.Timer();
    var Grid_Lat;
    var Grid_Lon;
    var Grid_Marks;
    var GridFont;
    
    function initialize() {
        
        /*** the points of the grid of the 360° sky map are calculated once at the load of the view to reduce calculation time ***/
        Grid_Lat = [];
        Grid_Lon = [];
        Grid_Marks = [];
        var ColGridUp = 0x0000ff;
        var ColGridDn = 0x00aa00;
        var ColGridMark = 0xffff00;

        // calc Lat-Grid
        var yAlt2 = 0.0 as Lang.Double;
        var r2 = 0.0 as Lang.Double;
        var s = 0.0 as Lang.Double;
        var alpha = 0.0 as Lang.Double;
        var h1 = 0.0 as Lang.Double;
        var h2 = 0.0 as Lang.Double;
        var h3 = 0.0 as Lang.Double;
        for (var i = 10; i < 90; i += 10) {
            alpha = Math.toRadians(i);
            h1 = 140.0/90.0 * i;
            h3 = 140 - 140 * Math.sin(alpha);
            h2 = 140 - h1 - h3;
            s  = 140 * Math.cos(alpha);
            r2 = 0.5 * ((s * s / h2) + h2);
            yAlt2 = r2 - h2 - h3;
            Grid_Lat.add([140, -yAlt2, r2, ColGridUp]);
            Grid_Lat.add([140, 280+yAlt2, r2, ColGridDn]);
        }
        // calc Lon-Grid
        var xAzW = 0.0 as Lang.Double;
        var xAzE = 0.0 as Lang.Double;
        var xAz2 = 280.0/12.0 as Lang.Double;
        var r = 0.0 as Lang.Double;
        var rx = 0.0 as Lang.Double;
        for (var i = 1; i <= 6; i++) {
            rx = i.toDouble() * xAz2;
            r = (140.0 * 140.0)/(2.0 * rx) + (0.5 * rx);
            xAzW = 140.0 - ( r - rx );
            xAzE = 140.0 + ( r - rx );
            if (i < 6) { 
                Grid_Lon.add([xAzW, 140, r, Graphics.ARC_COUNTER_CLOCKWISE,   0,  90, ColGridUp, 1]);
                Grid_Lon.add([xAzE, 140, r, Graphics.ARC_COUNTER_CLOCKWISE,  90, 180, ColGridUp, 1]);
                Grid_Lon.add([xAzE, 140, r, Graphics.ARC_COUNTER_CLOCKWISE, 180, 270, ColGridDn, 1]);
                Grid_Lon.add([xAzW, 140, r, Graphics.ARC_COUNTER_CLOCKWISE, 270, 360, ColGridDn, 1]);
            } else {
                Grid_Lon.add([xAzW, 140-1, r, Graphics.ARC_COUNTER_CLOCKWISE,   0,  90, ColGridUp, 3]);
                Grid_Lon.add([xAzE, 140-1, r, Graphics.ARC_COUNTER_CLOCKWISE,  90, 180, ColGridUp, 3]);
                Grid_Lon.add([xAzE, 140,   r, Graphics.ARC_COUNTER_CLOCKWISE, 180, 270, ColGridDn, 3]);
                Grid_Lon.add([xAzW, 140,   r, Graphics.ARC_COUNTER_CLOCKWISE, 270, 360, ColGridDn, 3]);
            }
        }

        // calc Grid-Marks
        for (var i = 3; i <= 9; i+=3) { // Lat
            switch(i) {
                case 9:
                    Grid_Marks.add([140, 140 - (140.0/90.0)*i*10 - 1, (i*10).toString(), Graphics.TEXT_JUSTIFY_CENTER, ColGridMark]);
                    Grid_Marks.add([140, 140 + (140.0/90.0)*i*10 - 13, (-i*10).toString(), Graphics.TEXT_JUSTIFY_CENTER, ColGridMark]);
                    break;
                default:
                    Grid_Marks.add([140, 140 - (140.0/90.0)*i*10 - 7, (i*10).toString(), Graphics.TEXT_JUSTIFY_CENTER, ColGridMark]);
                    Grid_Marks.add([140, 140 + (140.0/90.0)*i*10 - 7, (-i*10).toString(), Graphics.TEXT_JUSTIFY_CENTER, ColGridMark]);
                    break;
            }
        }
        for (var i = 0; i <= 36; i+=9) { // Lon
            switch(i) {
                case 0:
                    Grid_Marks.add([(280.0/360.0)*i*10, 142-9, Direction(i*10), Graphics.TEXT_JUSTIFY_LEFT, ColGridMark]);
                    break;
                case 36:
                    Grid_Marks.add([(280.0/360.0)*i*10 - 1, 142-9, Direction(i*10), Graphics.TEXT_JUSTIFY_RIGHT, ColGridMark]);
                    break;
                default:
                    Grid_Marks.add([(280.0/360.0)*i*10, 142-9, Direction(i*10), Graphics.TEXT_JUSTIFY_CENTER, ColGridMark]);
                    break;
            }
        }
        
        View.initialize();
    }

   // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.Layout_Moon_5(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        // Initialize timer 
        ViewTimeCounter = 0;
        Moon_5_Timer.start(method(:Moon_5_Timer_Callback), 1000, true);
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
            "SunEvents" => false,
            "MoonAccuracy" => 1,
            "MoonPosit" => false,
            "MoonAzAlt" => false,
            "MoonDiamDist" => false,
            "MoonCycFrac" => false,
            "MoonRTS" => false,
            "MoonEvents" => false,
            "MoonDay" => true,
            "MoonPeriod" => false,
            "MoonPerigeeApogee" => false,
        };
        var Moon = getAstroData(myLocation, height, astroDataContent);

        View.onUpdate(dc);

        // font for Grid-Marks
        GridFont = Graphics.getVectorFont({
            :face => "RobotoCondensedRegular",
            :size => 15 * sc
        });
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
            :size => 15 * sc
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
            GridFont = Graphics.getVectorFont({
                :face => "RobotoRegular",
                :size => 17 * sc
            });
            DateFont = Graphics.getVectorFont({
                :face => "RobotoRegular",
                :size => 15 * sc
            });
        }


        // draw buttons
        if (System.getDeviceSettings().isTouchScreen) {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.fillPolygon(getButtonPrevDay(0, 140 * sc));
            dc.fillPolygon(getButtonNextDay(0, 140 * sc));
        }

        
        dc.setPenWidth(1);
        // draw grid lines of altitude
        for (var i = 0; i < Grid_Lat.size(); i++) {
            dc.setColor(Grid_Lat[i][3], Graphics.COLOR_TRANSPARENT);
            dc.drawCircle(Grid_Lat[i][0] * sc, Grid_Lat[i][1] * sc, Grid_Lat[i][2] * sc);
        }
        // draw grid lines of azimuth
        for (var i = 0; i < Grid_Lon.size(); i++) {
            dc.setColor(Grid_Lon[i][6], Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(Grid_Lon[i][7]);
            dc.drawArc(Grid_Lon[i][0] * sc, Grid_Lon[i][1] * sc, Grid_Lon[i][2] * sc, Grid_Lon[i][3], Grid_Lon[i][4], Grid_Lon[i][5]);
        }
        // draw horizon
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawLine(0, 140 * sc, 280 * sc, 140 * sc);
        // draw meridian
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(140 * sc, 0, 140 * sc, 280 * sc);
        // draw grid marks
        for (var i = 0; i < Grid_Marks.size(); i++) {
            dc.setColor(Grid_Marks[i][4], Graphics.COLOR_TRANSPARENT);
            dc.drawText(Grid_Marks[i][0] * sc, Grid_Marks[i][1] * sc, GridFont, Grid_Marks[i][2], Grid_Marks[i][3]);
        }

        // draw path of moon
        var MoonPath = [];
        var MD = Moon["MoonDay"];
        var bPathCrossDate = false as Lang.Boolean;
        for (var i=0; i < MD.size(); i++) {
            MoonPath.add(getSkyMapPoint(MD[i][1], MD[i][2], (MD[i][0]*3600).toNumber()));
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2 * sc);
        for (var i=1; i < MoonPath.size(); i++) {
            if ( !(MoonPath[i-1][4] < 90 && MoonPath[i][4] > 270) && !(MoonPath[i-1][4] > 270 && MoonPath[i][4] < 90)) {
                dc.drawLine(MoonPath[i-1][0] * sc, MoonPath[i-1][1] * sc, MoonPath[i][0] * sc, MoonPath[i][1] * sc);
            }
        }
        for (var i=0; i < MoonPath.size(); i++) {
            if (MoonPath[i][0] * sc <= 32 * sc && MoonPath[i][1] * sc >= 65 * sc && MoonPath[i][1] * sc <= 124 * sc) {
                bPathCrossDate = true;
                break;
            }
        }

        // draw hour-markers
        dc.setPenWidth(2);
        for (var i=1; i < MoonPath.size(); i++) {
            if (MoonPath[i][2] % (3600 * 1) == 0) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(MoonPath[i][0] * sc, MoonPath[i][1] * sc, 3 * sc);
            }
            if (MoonPath[i][2] % (3600 * 2) == 0) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(MoonPath[i][0] * sc, MoonPath[i][1] * sc, 4 * sc);
            }
        }

        var xT = 0.0;
        var xT2 = 0.0;
        var yT = 0.0;
        var yT2 = 0.0;
        var L1 = 0.0;
        var xd = 0.0;
        var yd = 0.0;
        var alpha1 = 0.0;
        var alpha2 = 0.0;
        var alpha3 = 0.0;
        var iTime = (Moon["time0"]*3600).toNumber();
        var iPathNr = 0;
        var marker = [
            [ 0,  0],
            [16 * sc,  5 * sc],
            [16 * sc, -5 * sc]
        ];
        var points = [];
        var x2 = 0.0;
        var y2 = 0.0;
        for (var i=0; i < MoonPath.size()-1; i++) {
            if (iTime >= MoonPath[i][2] && iTime < MoonPath[i+1][2]) {
                iPathNr = (i == 0) ? 1 : i;
                xT = MoonPath[iPathNr][0]-MoonPath[iPathNr-1][0];
                yT = -1*(MoonPath[iPathNr][1]-MoonPath[iPathNr-1][1]);
                L1 = Math.sqrt(xT * xT + yT * yT);
                alpha1 = Math.asin(yT / L1) * _2deg;
                if (alpha1 > 0 && xT < 0) { alpha1 = 180 - alpha1; } 
                if (alpha1 < 0) {
                    if (xT > 0) { alpha1 += 360; }
                    if (xT < 0) { alpha1 = 180 + alpha1.abs(); }
                }

                xT = MoonPath[iPathNr+1][0]-MoonPath[iPathNr][0];
                yT = -1*(MoonPath[iPathNr+1][1]-MoonPath[iPathNr][1]);
                L1 = Math.sqrt(xT * xT + yT * yT);
                alpha2 = Math.asin(yT / L1) * _2deg;
                if (alpha2 > 0 && xT < 0) { alpha2 = 180 - alpha2; } 
                if (alpha2 < 0) {
                    if (xT > 0) { alpha2 += 360; }
                    if (xT < 0) { alpha2 = 180 + alpha2.abs(); }
                }
                alpha3 = alpha2;

                xT = MoonPath[i][0] + 12;
                yT = -1 * MoonPath[i][1];
                if (alpha1 < alpha2) {
                    if (alpha2-alpha1 > 180){
                        alpha3 += 90.0;
                    } else {
                        alpha3 += 270.0;
                    }
                    if (alpha3 >= 360.0) { alpha3 -=360.0; }
                }
                if (alpha1 > alpha2) {
                    alpha3 += 90.0;
                    if (alpha3 >= 360.0) { alpha3 -=360.0; }
                }
                alpha3 += 180.0;
                if (alpha3 >= 360.0) { alpha3 -=360.0; }
                alpha3 = alpha3 * _2rad;

                var dx = (MoonPath[i+1][0] - MoonPath[i][0]) as Lang.Double;
                var dy = (MoonPath[i+1][1] - MoonPath[i][1]) as Lang.Double;
                var dt1 = (iTime - MoonPath[i][2]).toDouble();
                var dt2 = (MoonPath[i+1][2] - MoonPath[i][2]).toDouble();
                var dt3 = (dt1.toDouble() / dt2.toDouble()) as Lang.Double;
                xd = MoonPath[i][0] + (dx * dt3);
                yd = MoonPath[i][1] + (dy * dt3);
                yd *= -1;
                for (var j=0; j < marker.size(); j++) {
                    marker[j][0] = marker[j][0] + xd;
                    marker[j][1] = marker[j][1] + yd;
                    x2 = xd + (marker[j][0] - xd)*Math.cos(alpha3) - (marker[j][1] - yd)*Math.sin(alpha3);
                    y2 = yd + (marker[j][0] - xd)*Math.sin(alpha3) + (marker[j][1] - yd)*Math.cos(alpha3);
                    points.add([x2 * sc, -y2 * sc]);
                }
                dc.setColor(0xFF5555, Graphics.COLOR_TRANSPARENT);
                dc.fillPolygon(points);
                break;
            }
        }


        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        for (var i=1; i < MoonPath.size()-1; i++) {
            if (MoonPath[i][2] % (3600 * 2) == 0 && i > 0 && i < MoonPath.size()-1) {
                xT = MoonPath[i][0]-MoonPath[i-1][0];
                yT = -1*(MoonPath[i][1]-MoonPath[i-1][1]);
                L1 = Math.sqrt(xT * xT + yT * yT);
                alpha1 = Math.asin(yT / L1) * _2deg;
                if (alpha1 > 0 && xT < 0) { alpha1 = 180 - alpha1; } 
                if (alpha1 < 0) {
                    if (xT > 0) { alpha1 += 360; }
                    if (xT < 0) { alpha1 = 180 + alpha1.abs(); }
                }

                xT = MoonPath[i+1][0]-MoonPath[i][0];
                yT = -1*(MoonPath[i+1][1]-MoonPath[i][1]);
                L1 = Math.sqrt(xT * xT + yT * yT);
                alpha2 = Math.asin(yT / L1) * _2deg;
                if (alpha2 > 0 && xT < 0) { alpha2 = 180 - alpha2; } 
                if (alpha2 < 0) {
                    if (xT > 0) { alpha2 += 360; }
                    if (xT < 0) { alpha2 = 180 + alpha2.abs(); }
                }

                xT = MoonPath[i+1][0]-MoonPath[i-1][0];
                yT = -1*(MoonPath[i+1][1]-MoonPath[i-1][1]);
                L1 = Math.sqrt(xT * xT + yT * yT);
                alpha3 = Math.asin(yT / L1) * _2deg;
                if (alpha3 > 0 && xT < 0) { alpha3 = 180 - alpha3; } 
                if (alpha3 < 0) {
                    if (xT > 0) { alpha3 += 360; }
                    if (xT < 0) { alpha3 = 180 + alpha3.abs(); }
                }

                xT = MoonPath[i][0] + 12;
                yT = -1 * MoonPath[i][1];
                if (alpha1 < alpha2) {
                    if (alpha2-alpha1 > 180){
                        alpha3 += 90.0;
                    } else {
                        alpha3 += 270.0;
                    }
                    if (alpha3 >= 360.0) { alpha3 -=360.0; }
                }
                if (alpha1 > alpha2) {
                    alpha3 += 90.0;
                    if (alpha3 >= 360.0) { alpha3 -=360.0; }
                }

                alpha3 = alpha3 * _2rad;
                xT2 = MoonPath[i][0] + (xT - MoonPath[i][0])*Math.cos(alpha3) - (yT - -1*MoonPath[i][1])*Math.sin(alpha3);
                yT2 = -1*MoonPath[i][1] + (xT - MoonPath[i][0])*Math.sin(alpha3) + (yT - -1*MoonPath[i][1])*Math.cos(alpha3);
                dc.drawText(xT2 * sc, -yT2 * sc -7 * sc, GridFont, (MoonPath[i][2] / 3600).toString(), Graphics.TEXT_JUSTIFY_CENTER);
            }
            
        }
        

        // draw midnight markers
        dc.setPenWidth(1);
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(MoonPath[0][0] * sc, MoonPath[0][1] * sc, 4 * sc);
        dc.setPenWidth(2 * sc);
        dc.drawCircle(MoonPath[MoonPath.size()-1][0] * sc, MoonPath[MoonPath.size()-1][1] * sc, 3 * sc);
        
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

        // draw date
        var DateAngle = (bPathCrossDate == false) ? 160 : 130;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawRadialText(140 * sc, 140 * sc, DateFont, Moon["date"], Graphics.TEXT_JUSTIFY_CENTER, DateAngle, 128 * sc, Graphics.RADIAL_TEXT_DIRECTION_CLOCKWISE);

        // draw simulation indicator
        if (LatLonSimulator == true) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(140 * sc, 140 * sc, 12 * sc);
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.drawText(140 * sc, 125 * sc, MoonFont_Tiny, "S", Graphics.TEXT_JUSTIFY_CENTER);
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
        Moon_5_Timer.stop();
    }

    function Moon_5_Timer_Callback() {
        ViewTimeCounter++;
        WatchUi.requestUpdate();
    }

}
