import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Position;
import Toybox.Lang;
import Toybox.Application.Properties;
import Toybox.Math;


class MoonAppView_Moon_1 extends WatchUi.View {

    var Moon_1_Timer = new Timer.Timer();
    
    function initialize() {
        View.initialize();
    }

   // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.Layout_Moon_1(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        // Initialize timer 
        ViewTimeCounter = 0;
        Moon_1_Timer.start(method(:Moon_1_Timer_Callback), 1000, true); // A 1-second timer
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
            "SunPosit" => true,
            "SunAzAlt" => false,
            "SunRTS" => false,
            "SunEvents" => false,
            "MoonAccuracy" => 15,
            "MoonPosit" => true,
            "MoonAzAlt" => true,
            "MoonDiamDist" => true,
            "MoonCycFrac" => true,
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
        var MoonFont_XTiny2 = Graphics.getVectorFont({
            :face => "RobotoCondensedRegular",
            :size => 19 * sc
        });
        var MoonFont_XTiny3 = Graphics.getVectorFont({
            :face => "RobotoCondensedBold",
            :size => 19 * sc
        });

        if (MoonFont_Tiny == null) {
            MoonFont_Tiny = Graphics.getVectorFont({
                :face => "NanumGothicBold",
                :size => 30 * sc
            });
            MoonFont_XTiny = Graphics.getVectorFont({
                :face => "NotoNaskhArabicRegular",
                :size => 25 * sc
            });
            MoonFont_XTiny2 = Graphics.getVectorFont({
                :face => "NotoNaskhArabicRegular",
                :size => 25 * sc
            });
            MoonFont_XTiny3 = Graphics.getVectorFont({
                :face => "NotoNaskhArabicRegular",
                :size => 22 * sc
            });
        }

        // draw date of calculation
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(sc2,  4 * sc, MoonFont_XTiny, Moon["date"], Graphics.TEXT_JUSTIFY_CENTER);

        // draw progress of moon phase and fraction of luminary
        var CycleBez = "Cyc: " as Lang.String;
        var CycleDat = Round(100 * Moon["cycle"], 3).format("%.1f") + "%" as Lang.String;
        var CycleW = dc.getTextWidthInPixels(CycleBez, MoonFont_XTiny) as Lang.Double;
        var FracBez = "Lum: " as Lang.String;
        var FracDat = Round(100 * Moon["fraction"], 3).format("%.1f") + "%" as Lang.String;
        var FracW = dc.getTextWidthInPixels(FracDat, MoonFont_XTiny2) as Lang.Double;
        dc.drawText( 62 * sc,          22 * sc, MoonFont_XTiny, CycleBez, Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText( 62 * sc + CycleW, 22 * sc, MoonFont_XTiny2, CycleDat, Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(216 * sc,          22 * sc, MoonFont_XTiny2, FracDat, Graphics.TEXT_JUSTIFY_RIGHT);
        dc.drawText(216 * sc - FracW,  22 * sc, MoonFont_XTiny, FracBez, Graphics.TEXT_JUSTIFY_RIGHT);

        // draw azimuth and altitude
        var AzBez = "Az: " as Lang.String;
        var AzDat = Moon["az"].format("%.2f") + "°" as Lang.String;
        var AzW = dc.getTextWidthInPixels(AzBez, MoonFont_XTiny) as Lang.Double;
        var AltBez = "Alt: " as Lang.String;
        var AltDat = Moon["alt"].format("%.2f") + "°" as Lang.String;
        var AltW = dc.getTextWidthInPixels(AltDat, MoonFont_XTiny2) as Lang.Double;
        dc.drawText(  55 * sc,         40 * sc, MoonFont_XTiny, AzBez, Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(( 55) * sc + AzW,  40 * sc, MoonFont_XTiny2, AzDat, Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText( 225 * sc,         40 * sc, MoonFont_XTiny2, AltDat, Graphics.TEXT_JUSTIFY_RIGHT);
        dc.drawText((225) * sc - AltW, 40 * sc, MoonFont_XTiny, AltBez, Graphics.TEXT_JUSTIFY_RIGHT);

        // draw diamter (in minutes of arc) and distance
        var DiamBez = "Diam: " as Lang.String;
        var DiamDat = Moon["diameter"].format("%.2f") + "'" as Lang.String;
        var DiamW = dc.getTextWidthInPixels(DiamBez, MoonFont_XTiny) as Lang.Double;
        var DistBez = "Dist: " as Lang.String;
        var DistDat = (UnitMetric == true) ? (Moon["distance"].format("%.1f") +" km") : ((Moon["distance"] * km2mil).format("%.1f") +" mi") as Lang.String;
        var DistW = dc.getTextWidthInPixels(DistDat, MoonFont_XTiny2) as Lang.Double;
        dc.drawText(  35 * sc,          58 * sc, MoonFont_XTiny, DiamBez, Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(( 35) * sc + DiamW, 58 * sc, MoonFont_XTiny2, DiamDat, Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText( 245 * sc,          58 * sc, MoonFont_XTiny2, DistDat, Graphics.TEXT_JUSTIFY_RIGHT);
        dc.drawText((245) * sc - DistW, 58 * sc, MoonFont_XTiny, DistBez, Graphics.TEXT_JUSTIFY_RIGHT);

        // draw times, azimuths / altitude of rise, transit and set
        var MoonTimes = [
            ["rise", Moon["Moon_Today_rise_bool"], Moon["Moon_Today_rise_time"]],
            ["set", Moon["Moon_Today_set_bool"], Moon["Moon_Today_set_time"]],
            ["transit", Moon["Moon_Today_transit_bool"], Moon["Moon_Today_transit_time"]]
        ];
        var MoonEventCoor = [
            [ [50*sc, 85*sc], [50*sc, 108*sc], [50*sc, 135*sc] ],
            [ [sc2, 85*sc], [sc2, 108*sc], [sc2, 135*sc] ],
            [ [230*sc, 85*sc], [230*sc, 108*sc], [230*sc, 135*sc] ]
        ];
        var TimesSequence = sortTimes(MoonTimes, 1);
        var AMPM = "" as Lang.String;
        var AMPMW = 0.0d as Lang.Double;
        var TIME = "" as Lang.String;
        var TIMEW = 0.0d as Lang.Double;
        var TIMEW2 = 0.0d as Lang.Double;
        var HOUR = 0.0d as Lang.Double;
        for (var i=0; i<=2; i++) {
            if (Moon["Moon_Today_"+TimesSequence[i][0]+"_bool"] == true) {
                if (Hour24 == false) {
                    AMPM = (Moon["Moon_Today_"+TimesSequence[i][0]+"_time"] > 12.0d) ? "pm" : "am";
                    HOUR = Moon["Moon_Today_"+TimesSequence[i][0]+"_time"];
                    if (Moon["Moon_Today_"+TimesSequence[i][0]+"_time"] >= 12) { HOUR -= 12.0d; }
                    if (HOUR < 1.0d) { HOUR += 12.0d; }
                    TIME = HMM(HOUR);               
                } else {
                    TIME = Moon["Moon_Today_"+TimesSequence[i][0]+"_time2"];
                }
            } else {
                AMPM = "";
                TIME = Moon["Moon_Today_"+TimesSequence[i][0]+"_time2"];
            }
            TIMEW = dc.getTextWidthInPixels(TIME, MoonFont_Tiny);
            AMPMW = dc.getTextWidthInPixels(AMPM, MoonFont_XTiny3);
            TIMEW2 = (TIMEW + AMPMW) / 2.0d;
            dc.setColor(MoonEventColors[TimesSequence[i][0]], Graphics.COLOR_TRANSPARENT);
            dc.drawText(MoonEventCoor[i][0][0], MoonEventCoor[i][0][1], MoonFont_Tiny, Moon["Moon_Today_"+TimesSequence[i][0]+"_label"], Graphics.TEXT_JUSTIFY_CENTER);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(MoonEventCoor[i][1][0] - TIMEW2, MoonEventCoor[i][1][1], MoonFont_Tiny, TIME, Graphics.TEXT_JUSTIFY_LEFT);
            dc.drawText(MoonEventCoor[i][1][0] + TIMEW2, MoonEventCoor[i][1][1], MoonFont_XTiny3, AMPM, Graphics.TEXT_JUSTIFY_RIGHT);
            dc.drawText(MoonEventCoor[i][2][0], MoonEventCoor[i][2][1], MoonFont_XTiny, Moon["Moon_Today_"+TimesSequence[i][0]+"_value"], Graphics.TEXT_JUSTIFY_CENTER);
        }
        dc.drawRadialText(140*sc, 140*sc, MoonFont_XTiny2, "data: topocentric", Graphics.TEXT_JUSTIFY_CENTER, 270, 135*sc, Graphics.RADIAL_TEXT_DIRECTION_COUNTER_CLOCKWISE);

        // draw crescent moon and rotate
        var MoonPic = Application.loadResource( Rez.Drawables.MoonPic ) as BitmapResource;
        var angle = _2rad * (Moon["Moon_Now_PA"] + MoonPicAngleCorrection); // angle correction of moon photo
        var MoonAvgDiameter = 31.2 as Lang.Double;
        var MoonScale = ((100.0 / MoonPic.getWidth()) * (sc *  Moon["diameter"] / MoonAvgDiameter)).toDouble();
        var ShadowScale = (sc *  Moon["diameter"] / MoonAvgDiameter).toDouble();
        var centerX = MoonPic.getWidth() / 2;
        var centerY = MoonPic.getHeight() / 2;
        var rotateScaleMatrix = new AffineTransform();
        var translateMatrix = new AffineTransform();
        var scaleMatrix = new AffineTransform();
        var initialTranslateMatrix = new AffineTransform();
        var inverseTranslateMatrix = new AffineTransform();
        initialTranslateMatrix.setToTranslation(centerX, centerY);
        rotateScaleMatrix.setToRotation(angle);
        scaleMatrix.setToScale(MoonScale, MoonScale);
        inverseTranslateMatrix.setToTranslation(-centerX, -centerY);
        translateMatrix.concatenate(initialTranslateMatrix);
        translateMatrix.concatenate(rotateScaleMatrix);
        translateMatrix.concatenate(scaleMatrix);
        translateMatrix.concatenate(inverseTranslateMatrix);
        dc.drawBitmap2(140*sc-centerX, 210*sc-centerY, MoonPic, {
            :transform => translateMatrix,
            :filterMode => Graphics.FILTER_MODE_BILINEAR
        });
        
        // draw shadow on the moon
        if (positionInfo.accuracy == 0 && LatLonSimulator == false) { Moon["Moon_Now_illu_zenithAngle"] = 270; }
        if (Moon["Moon_Now_illu_zenithAngle"] > 360) { Moon["Moon_Now_illu_zenithAngle"] -= 360; }
        var Darkness = {
            "CenterX" => 140*sc,
            "CenterY" => 210*sc,
            "Radius" => 50 * ShadowScale,
            "Step" => 6,
            "Illuminated" => Moon["fraction"] * 2.0d,
            "Phase" => (Moon["Moon_Now_moonAge"] < 0.5 ? 1 : -1),
            "zenithAngle" => Math.toRadians(-1 * (Moon["Moon_Now_illu_zenithAngle"] - 270 + (Moon["Moon_Now_moonAge"] < 0.5 ? 0 : 180))), //
        };
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        if  (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }
        dc.fillPolygon(getCrescentMoon(Darkness));
        // draw moon outline
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawCircle(Darkness["CenterX"], Darkness["CenterY"], Darkness["Radius"]);


        // draw buttons
        if (System.getDeviceSettings().isTouchScreen) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.fillPolygon(getButtonPrevDay(35*sc, 215*sc));
            dc.fillPolygon(getButtonNextDay(-35*sc, 215*sc));
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            if (DaysOffset < 0) {
                dc.drawText(67*sc, 205*sc, MoonFont_XTiny, DaysOffset.abs().toString(), Graphics.TEXT_JUSTIFY_RIGHT);
            }
            if (DaysOffset > 0) {
                dc.drawText(213*sc, 205*sc, MoonFont_XTiny, DaysOffset.toString(), Graphics.TEXT_JUSTIFY_LEFT);
            }
        }

        // draw simulation indicator
        if (LatLonSimulator == true) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(34*sc, 175*sc, 12*sc);
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.drawText(34*sc, 160*sc, MoonFont_Tiny, "S", Graphics.TEXT_JUSTIFY_CENTER);
        }

        // draw GPS quality
        dc.setPenWidth(1);
        var SatellitePic = Application.loadResource( Rez.Drawables.SatellitePic ) as BitmapResource;
        var SatelliteScale = ((20.0 / SatellitePic.getWidth()) * sc).toDouble();
        centerX = SatellitePic.getWidth() / 2;
        centerY = SatellitePic.getHeight() / 2;
        translateMatrix = new AffineTransform();
        initialTranslateMatrix = new AffineTransform();
        rotateScaleMatrix = new AffineTransform();
        scaleMatrix = new AffineTransform();
        inverseTranslateMatrix = new AffineTransform();
        
        initialTranslateMatrix.setToTranslation(centerX, centerY);
        rotateScaleMatrix.setToRotation(Math.toRadians(-90));
        scaleMatrix.setToScale(SatelliteScale, SatelliteScale);
        inverseTranslateMatrix.setToTranslation(-centerX, -centerY);
        translateMatrix.concatenate(initialTranslateMatrix);
        translateMatrix.concatenate(rotateScaleMatrix);
        translateMatrix.concatenate(scaleMatrix);
        translateMatrix.concatenate(inverseTranslateMatrix);
        dc.drawBitmap2(240 * sc - centerX, 175 * sc - centerY, SatellitePic, {
            :transform => translateMatrix,
            :filterMode => Graphics.FILTER_MODE_BILINEAR
        });
        
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        var GPScolors = [0xff0000, 0xffaa00, 0xffff00, 0x00aaff, 0x00ff00];
        var GPSradians = [
            [ 1*sc,   0, 360],
            [ 5*sc, 270,   0],
            [ 9*sc, 270,   0],
            [13*sc, 270,   0],
            [17*sc, 270,   0]
            ];
        dc.setPenWidth(2*sc);
        dc.setColor(GPScolors[positionInfo.accuracy], Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i <= positionInfo.accuracy; i++) {
            dc.drawArc(248*sc, 183*sc, GPSradians[i][0], Graphics.ARC_COUNTER_CLOCKWISE, GPSradians[i][1], GPSradians[i][2]);
        }
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        for (var i = positionInfo.accuracy + 1; i < GPSradians.size(); i++) {
            dc.drawArc(248*sc, 183*sc, GPSradians[i][0], Graphics.ARC_COUNTER_CLOCKWISE, GPSradians[i][1], GPSradians[i][2]);
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
        Moon_1_Timer.stop();
    }

    function Moon_1_Timer_Callback() {
        ViewTimeCounter++;
        WatchUi.requestUpdate();
    }

}
