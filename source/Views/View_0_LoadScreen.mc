import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Position;
import Toybox.Lang;
import Toybox.Application.Properties;

/*** loading screen, displayed at start of app and if no GPS position is available ***/

class MoonAppView extends WatchUi.View {

    private var CircleGPS = 0 as Lang.Number;
    private var CircleGPS2 = 0 as Lang.Number;
    private var CircleGPSPhase = 1 as Lang.Number;
    private var TimerCircleGPS = new Timer.Timer();
    private var TimerCircleGPSset = false as Lang.Boolean;
    
    function initialize() {
        View.initialize();
    }

   // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        TimerCircleGPS.start(method(:TimerCircleGPSCallback), 50, true);
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        // Call the parent onUpdate function to redraw the layout
        
        var LatLonSimulator = Properties.getValue("LatLonSimulator");
        if (LatLonSimulator == true) {
            WatchUi.switchToView(ViewList[activeView], new MoonAppDelegate(), WatchUi.SLIDE_IMMEDIATE);
        }

        var positionInfo = Position.getInfo();
        
        // Draw welcome-screen while waiting for GPS
        if (positionInfo.accuracy == 0) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
            dc.clear();
            var AppName = Application.loadResource(Rez.Strings.AppName);
            var AppAuthor = Application.loadResource(Rez.Strings.App_Author);
            var AppVersion = Application.loadResource(Rez.Strings.App_Version);
            var WaitingGPS = Application.loadResource(Rez.Strings.label_waiting_gps);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            var MoonFont_Large = Graphics.getVectorFont({
                :face => "RobotoCondensedBold",
                :size => 43 * sc
            });
            var MoonFont_Tiny = Graphics.getVectorFont({
                :face => "RobotoCondensedBold",
                :size => 30 * sc
            });
            var MoonFont_XTiny = Graphics.getVectorFont({
                :face => "RobotoCondensedBold",
                :size => 19 * sc
            });
            dc.drawText(dc.getWidth()/2, 20 * sc, MoonFont_Large, AppName, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(dc.getWidth()/2, 60 * sc, MoonFont_Tiny, AppVersion, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(dc.getWidth()/2, 210 * sc, MoonFont_XTiny, AppAuthor, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(dc.getWidth()/2, 230 * sc, MoonFont_Tiny, WaitingGPS, Graphics.TEXT_JUSTIFY_CENTER);
            
            var MoonPic = Application.loadResource( Rez.Drawables.MoonPic ) as BitmapResource;
            var MoonScale = ((100.0 / MoonPic.getWidth()) * sc).toDouble();
            var angle = CircleGPS2 * _2rad;
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
            dc.drawBitmap2(140 * sc - centerX, 150 * sc - centerY, MoonPic, {
                :transform => translateMatrix,
                :filterMode => Graphics.FILTER_MODE_BILINEAR
            });            
            
            var Darkness = {
                "CenterX" => 140 * sc,
                "CenterY" => 150 * sc,
                "Radius" => 51 * sc,
                "Step" => 6,
                "Illuminated" => CircleGPSPhase == 1 ? ((CircleGPS.toFloat() / 360.0) * 2.0).toFloat() : 2 - ((CircleGPS.toFloat() / 360.0) * 2.0).toFloat(),
                "Phase" => (CircleGPSPhase.toNumber() == (1).toNumber() ? 1 : -1),
                "zenithAngle" => Math.toRadians(-1 * (CircleGPS2 - 270)),
            };
            CircleGPS += 10;
            if (CircleGPS > 359) {
                CircleGPS = 0;
                if (CircleGPSPhase == 1) {
                    CircleGPSPhase = 2;
                } else {
                    CircleGPSPhase = 1;
                }
            }
            CircleGPS2 += 3;
            if (CircleGPS2 > 359) {
                CircleGPS2 = 0;
            }
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.fillPolygon(getCrescentMoon(Darkness));
            return;
        } else {
            WatchUi.switchToView(ViewList[activeView], new MoonAppDelegate(), WatchUi.SLIDE_IMMEDIATE);
        }

       View.onUpdate(dc);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
        TimerCircleGPS.stop();
    }

    function TimerCircleGPSCallback(){
        WatchUi.requestUpdate();
    }

}
