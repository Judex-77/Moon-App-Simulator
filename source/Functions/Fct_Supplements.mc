using Toybox.Math;
using Toybox.System;
using Toybox.Lang;

/* functions for better readability of the code */

/*
    The formulas of Meeus are always using degrees (also for right ascension and local hour angle).
    So the given parameters of the trigonometric functions are always degrees. To avoid the code for conversions into radians, the conversion to radians 
    for the class Toybox.Math is executed in the following functions. 
*/
function Sin (x as Lang.Double) as Lang.Double { return Math.sin(x * _2rad); }
function Cos (x as Lang.Double) as Lang.Double { return Math.cos(x * _2rad); }
function Tan (x as Lang.Double) as Lang.Double { return Math.tan(x * _2rad); }
function Asin (x as Lang.Double) as Lang.Double { return Math.asin(x); }
function Acos (x as Lang.Double) as Lang.Double { return Math.acos(x); }
function Atan (x as Lang.Double) as Lang.Double { return Math.atan(x); }
function Atan2 (y as Lang.Double, x as Lang.Double) as Lang.Double { return Math.atan2(y, x); }
function Pow (x as Lang.Double, y as Lang.Double) as Lang.Double { return Math.pow(x, y); }
function Sqrt (x as Lang.Double) as Lang.Double { return Math.sqrt(x); }
function Frac (x as Lang.Double) as Lang.Double  { return (x - Math.floor(x)); }
function Floor (x as Lang.Double) as Lang.Double  { return (Math.floor(x)); }
function Ceil (x as Lang.Double) as Lang.Double  { return (Math.ceil(x)); }
function Int (x as Lang.Double) as Lang.Double { if (x < 0) { return Math.ceil(x); } else { return Math.floor(x); } }
function Round (x as Lang.Double, digits as Lang.Number) as Lang.Double { return Math.round(x * Pow(10.0d, digits)) / Pow(10.0d, digits); }
function Mod (x as Lang.Double, y as Lang.Double) as Lang.Double { return (x - Math.floor(x / y) * y); }
function Trunc (x as Lang.Double) as Lang.Double { return ((x >= 0) ? Math.floor(x) : Math.ceil(x)); }
function ModPM (x as Lang.Double, y as Lang.Double) as Lang.Double { return (x - Trunc(x / y) * y); }

/* conversions of time to strings */

function HHMMSS (hh as Lang.Double) as Lang.String {
    // converts a time as double into format HH:MM:SS
    if (hh instanceof Lang.String) { return hh; }
    var m = Frac(hh) * 60.0d as Lang.Double;
    var h = Int(hh) as Lang.Float;
    var s = Frac(m) * 60.0d as Lang.Double;
        m = Int(m);
    var hhmmss = h.format("%02d") as Lang.String;
    if (s >= 60) { m++; s -= 60.0d; }
    if (m >= 60)   { h++; m -= 60.0d; }
    if (h == 24 && m == 0 && s == 0) {
        h = 23;
        m = 59;
        s = 59;
    }
    hhmmss = hhmmss + ":";
    hhmmss += (m.format("%02d")) + ":";
    s = Math.round(s);
    hhmmss += s.format("%02d");
    return hhmmss;
}

function HHMM (hh as Lang.Double) as Lang.String {
    // converts a time as double into format HH:MM
    if (hh instanceof Lang.String) { return hh; }
    var m = Frac(hh) * 60.0d as Lang.Double;
    var h = Int(hh) as Lang.Float;
        m = Math.round(m);
    var hhmm = h.format("%02d") as Lang.String;
    if (m >= 60) { h++; m -= 60.0d; }
    if (h == 24 && m == 0) {
        h = 23;
        m = 59;
    }
    hhmm = hhmm + ":";
    hhmm += m.format("%02d");
    return hhmm;
}

function HMM (hh as Lang.Double) as Lang.String {
    // converts a time as double into format H:MM (no leading zero on hour)
    if (hh instanceof Lang.String) { return hh; }
    var m = Frac(hh) * 60.0d as Lang.Double;
    var h = Int(hh) as Lang.Float;
        m = Math.round(m);
    var hhmm = h.format("%u") as Lang.String;
    if (m >= 60) { h++; m -= 60.0d; }
    if (h == 24 && m == 0) {
        h = 23;
        m = 59;
    }
    hhmm = hhmm + ":";
    hhmm += m.format("%02d");
    return hhmm;
}

/* functions for sorting of data */

function swapTimes(Times, t1, t2) {
    // sub-function for function sortTimes --> swap 2 times
    var swap = [];
    swap = Times[t1];
    Times[t1] = Times[t2];
    Times[t2] = swap;
    return Times;
}

function sortTimes(Times, recursion) {
    // sorting algorithm for times
    for (var i = Times.size() - 1; i >= recursion; i--) {
        if ((Times[i-1][1] == false && Times[i][1] == false) || (Times[i][1] == false)) {
            //dont swap
        } else if (Times[i-1][1] == false && Times[i][1] == true) {
            swapTimes(Times, i-1, i);
        } else if (Times[i][2] < Times[i-1][2]) {
            swapTimes(Times, i-1, i);
        }
    }
    if (recursion < Times.size()-1) { 
        recursion++;
        Times = sortTimes(Times, recursion);
    }
    return Times;
}

/* conversion of degrees into direction */

function Direction (deg as Lang.Double) {
    // converts a given degree into an compass direction
    if (deg == null) { return empty; }
    var MoonDirection;
    if (deg > 348.75 || deg <= 11.25) {
        MoonDirection = "N";
    } else if (deg > 11.25 && deg <= 33.75) {
        MoonDirection = "NNE";
    } else if (deg > 33.75 && deg <= 56.25) {
        MoonDirection = "NE";
    } else if (deg > 56.25 && deg <= 78.75) {
        MoonDirection = "ENE";
    } else if (deg > 78.75 && deg <= 101.25) {
        MoonDirection = "E";
    } else if (deg > 101.25 && deg <= 123.75) {
        MoonDirection = "ESE";
    } else if (deg > 123.75 && deg <= 146.25) {
        MoonDirection = "SE";
    } else if (deg > 146.25 && deg <= 168.75) {
        MoonDirection = "SSE";
    } else if (deg > 168.75 && deg <= 191.25) {
        MoonDirection = "S";
    } else if (deg > 191.25 && deg <= 213.75) {
        MoonDirection = "SSW";
    } else if (deg > 213.75 && deg <= 236.25) {
        MoonDirection = "SW";
    } else if (deg > 236.25 && deg <= 258.75) {
        MoonDirection = "WSW";
    } else if (deg > 258.75 && deg <= 281.25) {
        MoonDirection = "W";
    } else if (deg > 281.25 && deg <= 303.75) {
        MoonDirection = "WNW";
    } else if (deg > 303.75 && deg <= 326.25) {
        MoonDirection = "NW";
    } else if (deg > 326.25 && deg <= 348.75) {
        MoonDirection = "NNW";
    }
    return MoonDirection;
}
