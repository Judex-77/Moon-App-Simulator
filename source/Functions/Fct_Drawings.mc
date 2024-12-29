import Toybox.Math;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Application.Properties;
import Toybox.Position;

function getCrescentMoon(Darkness) {
    // calculates the not illuminated part of the crescent moon
    // parameters:
    //  Darkness = array of dictionary
    //      "CenterX": center x coordinate of moon in the display of the watch
    //      "CenterY": center y coordinate of moon in the display of the watch
    //      "Radius": radius of the "dark" moon part in px
    //      "Step": calculation steps in degrees (e.g. 6 = 360 / 6 = 60 steps)
    //      "Illuminated": illumination as number: 0 = 0%, 1 = 100%
    //      "Phase": progress of the moon period
    //      "zenithAngle": zenith angle of the moon
    // returns:
    //  array of points to be drawn in the display
    var pointsDarkness = [];
    var x = 0;
    var y = 0;
    var x2 = 0;
    var y2 = 0;
    var CosZA = Cos(Darkness["zenithAngle"] * _2deg) as Lang.Double;
    var SinZA = Sin(Darkness["zenithAngle"] * _2deg) as Lang.Double;
    // rotation of crescent moon
    for (var i = 360; i >= 180; i -= Darkness["Step"]) {
        x = Darkness["CenterX"] + Sin(i) * Darkness["Radius"] * Darkness["Phase"];
        y = Darkness["CenterY"] - Cos(i) * Darkness["Radius"] * Darkness["Phase"];
        x2 = Math.round(Darkness["CenterX"] + (x - Darkness["CenterX"]) * CosZA - (y - Darkness["CenterY"]) * SinZA).toNumber();
        y2 = Math.round(Darkness["CenterY"] + (x - Darkness["CenterX"]) * SinZA + (y - Darkness["CenterY"]) * CosZA).toNumber();
        pointsDarkness.add([x2, y2]);
    }
    for (var i = 180; i >= 0; i -= Darkness["Step"]) {
        x = Darkness["CenterX"] + Sin(i) * Darkness["Radius"] * (1 - Darkness["Illuminated"]) * Darkness["Phase"];
        y = Darkness["CenterY"] - Cos(i) * Darkness["Radius"] * Darkness["Phase"];
        x2 = Math.round(Darkness["CenterX"] + (x - Darkness["CenterX"]) * CosZA - (y - Darkness["CenterY"]) * SinZA).toNumber();
        y2 = Math.round(Darkness["CenterY"] + (x - Darkness["CenterX"]) * SinZA + (y - Darkness["CenterY"]) * CosZA).toNumber();
        pointsDarkness.add([x2, y2]);
    }
    return pointsDarkness;
}

function getSkyMapPoint(Az as Lang.Double, Alt as Lang.Double, DayTime) {
    // calculates the point of the moon in the 360° sky map = azimuth-altitude-time-diagram
    // parameters:
    //  Az: azimuth
    //  Alt: altitude
    //  DayTime: time of the calculated point
    // returns:
    //  array of points to be drawn in the display
    var xAz = 280.0/360.0 as Lang.Double;
    var x = 0.0 as Lang.Double;
    var y = -140.0 as Lang.Double;
    var r = 0.0 as Lang.Double;
    var rx = 0.0 as Lang.Double;
    var xc = 0.0 as Lang.Double;
    var yc = 140.0 as Lang.Double;
    var x2 = 0.0 as Lang.Double;
    var y2 = 0.0 as Lang.Double;
    var alpha = 0.0 as Lang.Double;
    var alpha90 = 0.0 as Lang.Double;
    
    rx = Az * xAz - 140.0;
    if (rx != 0) {
        r = (140.0 * 140.0)/(2.0 * rx.abs()) + (0.5 * rx.abs());
        alpha90 = Math.asin(140.0 / r) / 90;
        xc = (rx > 0) ? 140.0 - r + rx : 140.0 + r + rx;
        yc = yc * -1;
        if (rx > 0 && Alt >= 0) {
            alpha = alpha90 * Alt;
            x = rx + 140;
        } else if (rx < 0 && Alt >= 0) {
            alpha = 180.0 * _2rad - alpha90 * Alt;
            x = xc + r;
        } else if (rx < 0 && Alt < 0) {
            alpha = 180.0 * _2rad + alpha90 * -Alt;
            x = xc + r;
        } else if (rx > 0 && Alt < 0) {
            alpha = 360.0 * _2rad - alpha90 * -Alt;
            x = rx + 140;
        }
        x2 = xc + (x-xc)*Math.cos(alpha) - (y-yc)*Math.sin(alpha);
        y2 = (yc + (x-xc)*Math.sin(alpha) + (y-yc)*Math.cos(alpha)).abs();
    } else {
        x2 = 140.0;
        y2 = 140 - (Alt * 140.0 / 90.0);
    }
    return [x2, y2, DayTime, x, Az, Alt];
}

function getButtonPrevDay(x as Lang.Number, y as Lang.Number) {
    // calculates the points of a button to be displayed
    // parameters:
    //  x: base x coordinate of point
    //  y: base y coordinate of point
    // returns:
    //  array of points to be drawn in the display
    var points = [];
    points.add([    0+x,   0+y]);
    points.add([35*sc+x, -30*sc+y]);
    points.add([35*sc+x,  30*sc+y]);
    return points;
}

function getButtonNextDay(x, y) {
    // calculates the points of a button to be displayed
    // parameters:
    //  x: base x coordinate of point
    //  y: base y coordinate of point
    // returns:
    //  array of points to be drawn in the display
    var points = [];
    points.add([280*sc+x,   0+y]);
    points.add([245*sc+x, -30*sc+y]);
    points.add([245*sc+x,  30*sc+y]);
    return points;
}

function getDawnPhases(DP, IdxPolarDayNight) {
    // calculates the angles for the circle of dawn phases
    // parameters:
    //  DP: array with data of dawn phases
    //  IdxPolarDayNight: index for polar day or polar night
    // returns:
    //  array of angles for drawing arcs on the display

    // check for polar day or polar night
    var ColPolarDayNight = 0 as Lang.Number;
    if (IdxPolarDayNight == 1) {
        for (var i = 0; i < DP.size() - 1; i++) {
            if (DP[i][1].equals("Daylight")) {
                ColPolarDayNight = DP[i][2];
                break;
            }
        }
    }
    if (IdxPolarDayNight == -1) {
        for (var i = 0; i < DP.size() - 1; i++) {
            if (DP[i][1].equals("Midnight")) {
                ColPolarDayNight = DP[i][2];
                break;
            }
        }
    }

    // delete not existing phases from list
    for (var i = 1; i < DP.size() - 1; i++) {
        if (DP[i][0].toString().toUpper().find("NAN") != null) {
            DP[i][0] = 0.0;
            DP.remove(DP[i-1]);
            i--;
        } else { break; }
    }
    for (var i = DP.size() - 2; i > 0; i--) {
        if (DP[i][0].toString().toUpper().find("NAN") != null) {
            DP[i][0] = 24.0;
            DP.remove(DP[i+1]);
        } else { break; }
    }
    for (var i = 0; i < DP.size() - 2; i++) {
        if (DP[i+1][0].toString().toUpper().find("NAN") != null) {
            DP.remove(DP[i+1]);
            if (DP[i+1][0].toString().toUpper().find("NAN") == null) {
                break;
            }
            i--;
        }
    }

    // check if phase ends next day
    for (var i = DP.size() - 2; i > 0; i--) {
        if (DP[i][0] < DP[i-1][0]) {
            DP[i][0] += 24.0;
            DP.remove(DP[i+1]);
        } else { break; }
    }

    var points = [];

    // no phases if full polar day or polar night --> break
    if (IdxPolarDayNight != 0 && DP.size() == 2){
        points.add([270, 270, ColPolarDayNight]);
        return points;
    }

    var degS = 0 as Lang.Number;
    var degE = 270;
    for (var i = 0; i < DP.size()-1; i++) {
        degS = degE;
        degE = Math.round(270 - DP[i+1][0] * 15).toNumber(); // 1 hour = 15 degrees
        if (degE < 0) { degE += 360; }
        if (degS == degE) {
            if (DP[i][1].equals("SunRise")) {
                degE--; 
            } else if (DP[i][1].equals("SunSetStart")) {
                points[i-1][1]++;
                degS++; 
            } else {
                degE--;
            }
        }
        points.add([degS, degE, DP[i][2]]);
    }
    if (points[points.size()-1][1] < points[0][0]) {
        points[0][0] = points[points.size()-1][1];
    }
    return points;
}

function getMoonEventMarker(MEtime, cx, cy, r) {
    // calculates the points of moon event markers
    // parameters:
    //  MEtime: time of moon event
    //  cx: coordinate of x center of the display
    //  cy: coordinate of y center of the display
    //  r: radius out of cx, cy
    // returns:
    //  array of points to display
    var marker = [
        [ 8 * sc,  0],
        [-8 * sc,  8 * sc],
        [-8 * sc, -8 * sc]
    ];
    var points = [];
    cy = cy * -1;
    
    for (var i = 0; i < marker.size(); i++) {
        marker[i][0] = marker[i][0] + cx + r;
        marker[i][1] = marker[i][1] + cy;
    }
    var x2 = 0 as Lang.Number;
    var y2 = 0 as Lang.Number;
    var dt = 0.0d as Lang.Double;
    var CosA = 0.0d as Lang.Double;
    var SinA = 0.0d as Lang.Double;
    if (MEtime <= 18) {
        dt = 18.0d - MEtime;
    } else {
        dt = 42.0d - MEtime;
    }
    var angle = dt * 15.0d as Lang.Double;
    CosA = Cos(angle);
    SinA = Sin(angle);

    for (var i = 0; i < marker.size(); i++) {
        x2 = Math.round(cx + (marker[i][0]-cx)*CosA - (marker[i][1]-cy)*SinA).toNumber();
        y2 = Math.round(cy + (marker[i][0]-cx)*SinA + (marker[i][1]-cy)*CosA).toNumber().abs();
        points.add([x2, y2]);
    }
    return points;
}

function getMoonAltPoints(Alts) {
    // calculates the points of altitudes of the moon
    // parameters:
    //  Alts: array containing altitudes
    // returns:
    //  array of points to display
    var points = [];
    var cx = 140.0d as Lang.Double;
    var cy = -140.0d as Lang.Double;
    var x = 0.0d as Lang.Double;
    var y = 0.0d as Lang.Double;
    var x0 = 140.0d as Lang.Double;
    var y0 = -220.0d as Lang.Double;
    var h = 0.0d as Lang.Double;
    var angle = 0.0d as Lang.Double;
    var CosA = 0.0d as Lang.Double;
    var SinA = 0.0d as Lang.Double;
    var f = 60.0d / 90.0d as Lang.Double;
    for (var i = 0; i < Alts.size(); i++) {
        h = y0 - Alts[i][2] * f;
        angle = (24.0d - Alts[i][0]) * 15.0d;
        CosA = Cos(angle);
        SinA = Sin(angle);
        x = Math.round(cx + (x0-cx)*CosA - (h-cy)*SinA).toNumber();
        y = Math.round(cy + (x0-cx)*SinA + (h-cy)*CosA).toNumber().abs();
        points.add([x, y]);
    }
    return points;
}

function getMoonAzPoints(Az) {
    // calculates the points of azimuths of the moon
    // parameters:
    //  Az: array containing altitudes
    // returns:
    //  array of points to display
    var points = [];
    var cx = 140.0d as Lang.Double;
    var cy = -140.0d as Lang.Double;
    var x = 0.0d as Lang.Double;
    var y = 0.0d as Lang.Double;
    var x0 = 140.0d as Lang.Double;
    var y0 = -160.0d as Lang.Double;
    var h = 0.0d as Lang.Double;
    var angle = 0.0d as Lang.Double;
    var CosA = 0.0d as Lang.Double;
    var SinA = 0.0d as Lang.Double;
    var f = 60.0d / 180.0d as Lang.Double;
    for (var i = 0; i < Az.size(); i++) {
        h = y0 - Az[i][1] * f;
        angle = (24.0d - Az[i][0]) * 15.0d;
        CosA = Cos(angle);
        SinA = Sin(angle);
        x = Math.round(cx + (x0-cx)*CosA - (h-cy)*SinA).toNumber();
        y = Math.round(cy + (x0-cx)*SinA + (h-cy)*CosA).toNumber().abs();
        points.add([x, y]);
    }
    return points;
}

function getViewIndicator() {
    // calculates the points for the indicator of the actual view
    // returns:
    //  array of points to display
    var iCntViews = ViewList.size() - 1.0d as Lang.Double;
    var angleStep = 7 as Lang.Number;
    var points = [];
    var angleStart = 180 - (iCntViews / 2.0d) * angleStep + (angleStep / 2.0d) as Lang.Double;
    var cx = 140.0d as Lang.Double;
    var cy = -140.0d as Lang.Double;
    var x = 0.0d as Lang.Double;
    var y = 0.0d as Lang.Double;
    var x0 = 270.0d as Lang.Double;
    var y0 = -140.0d as Lang.Double;
    var CosA = 0.0d as Lang.Double;
    var SinA = 0.0d as Lang.Double;
    var angle = 0.0d as Lang.Double;
    for (var i = 0; i < iCntViews; i++) {
        angle = angleStart + i * angleStep;
        CosA = Cos(angle);
        SinA = Sin(angle);
        x = Math.round(cx + (x0-cx)*CosA - (y0-cy)*SinA).toNumber();
        y = Math.round(cy + (x0-cx)*SinA + (y0-cy)*CosA).toNumber().abs();
        points.add([x, y]);
    }
    return points;
}