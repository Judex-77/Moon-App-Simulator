import Toybox.Lang;
import Toybox.Time;

/* calculation of date and time formats */

function Date2JD0 (day as Lang.Double, month as Lang.Double, year as Lang.Double) as Lang.Double {
    // converts a date day/month/year at 0:00 UTC into the respective julian day
    // parameter:
    //  day, month and year
    // returns:
    //  julian day

    // Meeus: formula 7.1
    if (month <= 2) { year--; month += 12.0d; }
    var A = Int(year / 100.0d) as Lang.Double;
    var B = 2 - A + Int(A / 4.0d) as Lang.Double;
    var jd = Int(365.25d * (year + 4716.0d)) + Int(30.6001d * (month + 1)) + day + B - 1524.5d as Lang.Double;
    return jd;
}

function JD2Moment (JD as Lang.Double) {
    // converts a julian day into a Toybox.Time.Moment object
    // parameter:
    //  JD: julian day
    // returns:
    //  object as Toybox.Time.Moment
    JD += 0.5d;
    var Z = Floor(JD) as Lang.Double;
    var F = Frac(JD) as Lang.Double;
    var A = 0.0d as Lang.Double;
    var a = 0.0d as Lang.Double;
    if (Z < 2299161) {
        A = Z;
    } else {
        a = Int((Z - 1867216.25d) / 36524.25d);
        A = Z + 1.0d + a - Int(a / 4.0d);
    }
    var B = A + 1524.0d as Lang.Double;
    var C = Int((B - 122.1d) / 365.25d) as Lang.Double;
    var D = Int(365.25d * C) as Lang.Double;
    var E = Int((B - D) / 30.6001d) as Lang.Double;
    var mo = (E < 14) ? (E - 1.0d) : (E - 13.0d) as Lang.Double;
    var ye = (mo > 2) ? (C - 4716.0d) : (C - 4715.0d) as Lang.Double;
    var da = B - D - Int(30.6001d * E) + F as Lang.Double;
    var ho = Frac(da) * 24.0d as Lang.Double;;
    da = Floor(da);
    var mi = Frac(ho) * 60.0d as Lang.Double;;
    ho = Floor(ho);
    var se = Frac(mi) * 60.0d as Lang.Double;;
    mi = Floor(mi);
    se = Round(se, 0);
    var OverflowSecond = false as Lang.Boolean;
    if (se == 60) {
        OverflowSecond = true;
        se = 59.0d;
    }
    var options = {
        :year   => ye.toNumber(),
        :month  => mo.toNumber(),
        :day    => da.toNumber(),
        :hour   => ho.toNumber(),
        :minute => mi.toNumber(),
        :second => se.toNumber()
    };
    var tDate = Gregorian.moment(options) as Lang.Object;
    // add 1 sec to moment if OverflowSecond occurs
    if (OverflowSecond == true) {
        var tDuration = new Time.Duration(1) as Lang.Object;
        tDate = tDate.add(tDuration);
    }
    return tDate;
}

function GMST (JD as Lang.Double) as Lang.Double {
    // converts julian day into respective Greenwich mean sidereal time
    // parameter:
    //  JD: julian day
    // returns:
    //  Greenwich mean sidereal time

    // Meeus: formula 11.1
    var T = (JD - J2000) / 36525.0d as Lang.Double;
    // Meeus: formula 11.4
    var GMST = Mod(280.46061837d + 360.98564736629d * (JD - 2451545.0d) + T * T * (0.000387933d - T * (1.0d / 38710000.0d)), 360.0d) / 15.0d as Lang.Double;
    return GMST;
}

function GAST (JD as Lang.Double) as Lang.Double {
    // converts julian day into respective Greenwich apparent sidereal time
    // parameter:
    //  JD: julian day
    // returns:
    //  Greenwich apparent sidereal time

    // Meeus: formula 11.1
    var T = (JD - J2000) / 36525.0d as Lang.Double;
    var nutation = Nutation(T);
    var ε = nutation["epsilon"];
    var Δψ = nutation["deltapsi"];
    // Meeus: formula 11.4
    var GMST = Mod(280.46061837d + 360.98564736629d * (JD - 2451545.0d) + 0.000387933d * Pow(T, 2) - Pow(T, 3) / 38710000.0d, 360.0d) / 15.0d as Lang.Double;
    var eqeq = Δψ * Cos(ε) as Lang.Double; // equation of the equinoxes
        eqeq = eqeq / 15.0d; // conversion seconds of arc in seconds of time
    var GAST = GMST + eqeq as Lang.Double;
    return GAST;
}

function LSRT (MSRT as Lang.Double, lon as Lang.Double) as Lang.Double {
    // converts a sidereal time into respective local sidereal time
    // parameter:
    //  MSRT: mean sidereal time
    // returns:
    //  local sidereal time
    var LSRT = Mod(MSRT + lon / 15.0d, 24.0d) as Lang.Double;
    return LSRT;
}

function DeltaT (year as Lang.Double) as Lang.Double {
    // calculation of difference between dynamic time and universal time
    // source: https://eclipse.gsfc.nasa.gov/SEcat5/deltatpoly.html
    // parameters
    //  year: year of which ΔT is to be calculated
    // returns:
    //  difference between dynamic time and universal time
    var t = 0.0d as Lang.Double;
    var ΔT = 0.0d as Lang.Double;
    var y = 0.0d as Lang.Double;
    var c = 0.0d as Lang.Double;

    if (year < 2050) {
        t = year - 2000.0d;
        ΔT = 62.92d + t * (0.32217d + t * 0.005589d);
    } else {
        t = (year - 1820.0d) / 100.0d;
        ΔT = -20.0d + 32.0d * t * t - 0.5628d * (2150.0d - year);
    }
    y = year - 1955.0d;
    c = -0.000012932d * y * y;
    
    return (ΔT + c);
}
