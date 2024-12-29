import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Position;
import Toybox.Lang;
import Toybox.Application.Properties;
import Toybox.Math;


class MoonAppView_Moon_6 extends WatchUi.View {

    var Moon_6_Timer = new Timer.Timer();
    
    function initialize() {
        View.initialize();
    }

   // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.Layout_Moon_6(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        // Initialize timer 
        ViewTimeCounter = 0;
        Moon_6_Timer.start(method(:Moon_6_Timer_Callback), 1000, true); // A 1-second timer
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
            "MoonEvents" => true,
            "MoonDay" => false,
            "MoonPeriod" => false,
            "MoonPerigeeApogee" => false,
        };
        var Moon = getAstroData(myLocation, height, astroDataContent);

        View.onUpdate(dc);

        var MoonFont_Tiny = Graphics.getVectorFont({
            :face => "RobotoCondensedRegular",
            :size => 30 * sc
        });
        var MoonFont_TinyB = Graphics.getVectorFont({
            :face => "RobotoCondensedBold",
            :size => 30 * sc
        });
        var MoonFont_XTiny = Graphics.getVectorFont({
            :face => "RobotoCondensedBold",
            :size => 19 * sc
        });

        if (MoonFont_Tiny == null) {
            MoonFont_Tiny = Graphics.getVectorFont({
                :face => "RobotoRegular",
                :size => 25 * sc
            });
            MoonFont_XTiny = Graphics.getVectorFont({
                :face => "NanumGothicBold",
                :size => 19 * sc
            });
            MoonFont_TinyB = Graphics.getVectorFont({
                :face => "NanumGothicBold",
                :size => 25 * sc
            });
        }

        // draw next 4 moon events
        var MoonPic = Application.loadResource( Rez.Drawables.MoonPic ) as BitmapResource;
        var angle = 0.0d as Lang.Double;
        var MoonScale = ((46.0d / MoonPic.getWidth()) * (sc *  1)).toDouble();
        var ShadowScale = (sc *  1).toDouble();
        var centerX = MoonPic.getWidth() / 2;
        var centerY = MoonPic.getHeight() / 2;
        var rotateScaleMatrix = new AffineTransform();
        var translateMatrix = new AffineTransform();
        var scaleMatrix = new AffineTransform();
        var initialTranslateMatrix = new AffineTransform();
        var inverseTranslateMatrix = new AffineTransform();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(sc2,  4 * sc, MoonFont_XTiny, Moon["date"], Graphics.TEXT_JUSTIFY_CENTER);
        
        var ME = Moon["MoonEvents"];
        var sStrD = "" as Lang.String;
        var sStrT = "" as Lang.String;
        var cx =  0.0d as Lang.Double;
        var cy =  0.0d as Lang.Double;
        var y0 = 30.0d as Lang.Double;
        var dy = 55.0d as Lang.Double;
        var r  = 23.0d as Lang.Double;

        for (var i = 0; i < 4; i++) {
            if (UnitMetric == true) {
                sStrD = Lang.format("$1$.$2$.$3$", [ME[i]["day"].format("%02d"), ME[i]["month"].format("%02d"),ME[i]["year"].format("%4d")]);
            } else {
                sStrD = Lang.format("$1$-$2$-$3$", [ME[i]["month"].format("%02d"), ME[i]["day"].format("%02d"),ME[i]["year"].format("%4d")]);
            }
            if (Hour24 == true) {
                sStrT = HHMM(ME[i]["time"]);
            } else {
                var Hour12 = ME[i]["time"];
                if (ME[i]["time"] > 12) {
                    Hour12 -= 12.0d;
                }
                sStrT = HHMM(Hour12);
                sStrT += (ME[i]["time"] < 12) ? " am" : " pm";
            }

            cx = 70 * sc;
            cy = (y0 + 27 + (i * dy)) * sc;

            // draw crescent moon
            rotateScaleMatrix = new AffineTransform();
            translateMatrix = new AffineTransform();
            scaleMatrix = new AffineTransform();
            initialTranslateMatrix = new AffineTransform();
            inverseTranslateMatrix = new AffineTransform();
            angle = _2rad * (ME[i]["Moon_Now_PA"] + MoonPicAngleCorrection);
            initialTranslateMatrix.setToTranslation(centerX, centerY);
            rotateScaleMatrix.setToRotation(angle);
            scaleMatrix.setToScale(MoonScale, MoonScale);
            inverseTranslateMatrix.setToTranslation(-centerX, -centerY);
            translateMatrix.concatenate(initialTranslateMatrix);
            translateMatrix.concatenate(rotateScaleMatrix);
            translateMatrix.concatenate(scaleMatrix);
            translateMatrix.concatenate(inverseTranslateMatrix);
            dc.drawBitmap2(cx-centerX, cy-centerY, MoonPic, {
                :transform => translateMatrix,
                :filterMode => Graphics.FILTER_MODE_BILINEAR
            });

            // draw shadow on the moon
            if (positionInfo.accuracy == 0 && LatLonSimulator == false) { ME[i]["Moon_Now_illu_zenithAngle"] = 270; }
            if (ME[i]["Moon_Now_illu_zenithAngle"] > 360) { ME[i]["Moon_Now_illu_zenithAngle"] -= 360; }
            var Darkness = {
                "CenterX" => cx,
                "CenterY" => cy,
                "Radius" => (r+1) * ShadowScale,
                "Step" => 10,
                "Illuminated" => ME[i]["fraction"] * 2.0d,
                "Phase" => (ME[i]["Moon_Now_moonAge"] < 0.5 ? 1 : -1),
                "zenithAngle" => Math.toRadians(-1 * (ME[i]["Moon_Now_illu_zenithAngle"] - 270 + (ME[i]["Moon_Now_moonAge"] < 0.5 ? 0 : 180))), //
            };
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            if  (dc has :setAntiAlias) {
                dc.setAntiAlias(true);
            }
            dc.fillPolygon(getCrescentMoon(Darkness));
            dc.setPenWidth(1);
            dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
            dc.drawCircle(cx, cy, 23 * sc);

            dc.setColor(0xffffff, Graphics.COLOR_TRANSPARENT);
            dc.drawText(sc2 - 30 * sc,  (y0 + (i * dy)) * sc, MoonFont_TinyB, sStrD, Graphics.TEXT_JUSTIFY_LEFT);
            if (ME[i]["alt"] < 0) {
                dc.setColor(0xff5555, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(0x55ff55, Graphics.COLOR_TRANSPARENT);
            }
            dc.drawText(sc2 - 30 * sc,  (y0 + 25 + (i * dy)) * sc, MoonFont_Tiny, sStrT, Graphics.TEXT_JUSTIFY_LEFT);
        }

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
            dc.fillCircle(140 * sc, 262 * sc, 12 * sc);
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.drawText(140 * sc, 247 * sc, MoonFont_TinyB, "S", Graphics.TEXT_JUSTIFY_CENTER);
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
        Moon_6_Timer.stop();
    }

    function Moon_6_Timer_Callback() {
        ViewTimeCounter++;
        WatchUi.requestUpdate();
    }

}
