import Toybox.Lang;
import Toybox.Time;

/* conversions of celectial coordinate systems */

function Equ2AzAlt (JD as Lang.Double, lat as Lang.Double, lon as Lang.Double, Posit as Lang.Object) {
    // converts equatorial coordinates into azimuth, altitude and local hour angle
    // parameters:
    //  JD: julian day 
    //  lat: latitude of the observer
    //  lon: longitude of the observer
    //  Posit: object containing right ascension and declination of a celestial body
    // returns:
    //  dictionary with
    //      "az": azimuth
    //      "alt": altitude
    //      "LocalHourAngle": local hour angle
    var ra = Posit["ra"] as Lang.Double;
    var dec = Posit["dec"] as Lang.Double;
    var gast = GMST(JD) as Lang.Double;
    var last = LSRT(gast, lon) as Lang.Double;
    // Meeus: formula 12.
    var H = last * 15.0d - ra as Lang.Double; // local hour angle in degrees
    var result = {};
    var CosH = Cos(H) as Lang.Double;
    var SinLAT = Sin(lat) as Lang.Double;
    var CosLAT = Cos(lat) as Lang.Double;
    // Meeus: formula 12.5
    result["az"] = 180.0d + _2deg * Atan2(Sin(H), CosH * SinLAT - Tan(dec) * CosLAT) as Lang.Double;
    if (result["az"] >= 360.0d) { result["az"] -= 360.0d; }
    // Meeus: formula 12.6
    result["alt"] = _2deg * Asin(SinLAT * Sin(dec) + CosLAT * Cos(dec) * CosH) as Lang.Double;
    result["LocalHourAngle"] = H;
    return result;
}

function Equ2Ecl (ra as Lang.Double, dec as Lang.Double, ϵ as Lang.Double) {
    // converts equatorial coordinates into ecliptical coordinates
    // parameters:
    //  ra: right ascension
    //  dec: declination
    //  ϵ: obliquity of the ecliptic
    // returns:
    //  dictionary with
    //      "lonEcl": ecliptic longitude
    //      "latEcl": ecliptic latitude
    var result = {};
    var SinRA = Sin(ra) as Lang.Double;
    var CosEPS = Cos(ϵ) as Lang.Double;
    var SinEPS = Sin(ϵ) as Lang.Double;
    // Meeus: formula 12.1
    result["lonEcl"] = _2deg * Atan2(SinRA * CosEPS + Tan(dec) * SinEPS, Cos(ra)) as Lang.Double;
    if (result["lonEcl"] < 0.0d) { result["lonEcl"] += 360.0d; }
    // Meeus: formula 12.2
    result["latEcl"] = _2deg * (Sin(dec) * CosEPS - Cos(dec) * SinEPS * SinRA) as Lang.Double;
    return result;
}

function Ecl2Equ (λ as Lang.Double, β as Lang.Double, ϵ as Lang.Double) {
    // converts ecliptical coordinates into equatorial coordinates
    // parameters:
    //  λ: ecl. longitude
    //  β: ecl. latitude
    //  ϵ: obliquity of the ecliptic
    // returns:
    //  dictionary with
    //      "ra": right ascension
    //      "dec": declination

    // Meeus: formula 12.3
    var SinLAM = Sin(λ) as Lang.Double;
    var CosEPS = Cos(ϵ) as Lang.Double;
    var SinEPS = Sin(ϵ) as Lang.Double;
    var ra = _2deg * Atan2(SinLAM * CosEPS - Tan(β) * SinEPS, Cos(λ)) as Lang.Double;
        ra = Mod(ra, 360.0d);
    // Meeus: formula 12.4
    var dec = _2deg * Asin(Sin(β) * CosEPS + Cos(β) * SinEPS * SinLAM) as Lang.Double;
    var result = {};
    result["ra"] = ra;
    result["dec"] = dec;
    return result;
}

/* calculations for corrections of coordinates */

function Nutation (T as Lang.Double) as Lang.Double {
    // calculates the nutation of the earth
    // parameters:
    //  T: julian millennia from the epoch J2000.0
    // returns:
    //  dictionary with nutation data:
    //      "epsilon"
    //      "deltapsi"
    //      "deltaepsilon"

    // Meeus: formula 21.1
    var Ω = 125.04452d - T * (1934.136261d + T * (0.0020708d + T * (1.0d / 450000.0d))) as Lang.Double; // Longitude of the ascending node of the Moon
    var Ls = 280.4665d + 36000.7698d * T as Lang.Double; // mean Longitude of the sun
    var Lm = 218.3165d + 481267.8813d * T as Lang.Double; // mean Longitude of the moon
    // Meeus: formula 21.2
    var ε0 = 23.439291111111d - T * (0.01300416666666d - T * (0.00000016388888d + T * 0.0000005036111111111d)); // mean obliquity of the ecliptic
    // Meeus: formula 21.1
    var Δε = (9.20d * Cos(Ω) + 0.57d * Cos(2 * Ls) + 0.10 * Cos(2 * Lm) - 0.09d * Cos(2 * Ω)) / 3600.0d as Lang.Double; //nutation in obliquity
    // Meeus: formula 21.3
    var ε = ε0 + Δε as Lang.Double; // true obliquity of the ecliptic
    var Δψ = (-17.20d * Sin(Ω) - 1.32d * Sin(2.0d * Ls) - 0.23d * Sin(2.0d * Lm) + 0.21d * Sin(2.0d * Ω)) / 3600.0d as Lang.Double; // nutation in longitude
    var result = {};
    result["epsilon"] = ε;
    result["deltapsi"] = Δψ;
    result["deltaepsilon"] = Δε;
    return result;
}

function Aberration (T as Lang.Double, ra as Lang.Double, dec as Lang.Double, lonSunTrue as Lang.Double, ε as Lang.Double, e as Lang.Double) as Lang.Double {
    // calculates the abberation of a celectial body
    // parameters:
    //  T: julian millennia from the epoch J2000.0
    //  ra: right ascension
    //  dec: declination
    //  lonSunTrue: true longitude of the sun
    //  ε: obliquity of the ecliptic
    //  e: eccentricity of the earth's orbit
    // returns:
    //  dictionary with aberration data:
    //      "delta_ra_aberration"
    //      "deltdelta_dec_aberrationapsi"
    //      "pi"
    //      "kappa"

    // Meeus: formula 22.2
    var π = 102.93735d + 1.71953d * T + 0.00046d * Pow(T, 2) as Lang.Double; // Länge des Perihels der Erdbahn
    var κ = 20.49552d / 3600.0d as Lang.Double; // Abberationskonstante
    var CosRA = Cos(ra) as Lang.Double;
    var CosDEC = Cos(dec) as Lang.Double;
    var CosLST = Cos(lonSunTrue) as Lang.Double;
    var CosEPS = Cos(ε) as Lang.Double;
    var CosPI = Cos(π) as Lang.Double;
    var SinRA = Sin(ra) as Lang.Double;
    var SinDEC = Sin(dec) as Lang.Double;
    var SinLST = Sin(lonSunTrue) as Lang.Double;
    var SinPI = Sin(π) as Lang.Double;
    var TanEPS = Tan(ε) as Lang.Double;
    var Δra = -κ * ((CosRA * CosLST * CosEPS + SinRA * SinLST) / CosDEC) as Lang.Double;
        Δra += e * κ * ((CosRA * CosPI * CosEPS + SinRA + SinPI) / CosDEC);
    // Meeus: formula 22.3
    var Δdec = -κ * (CosLST * CosEPS * (TanEPS * CosDEC - SinRA * SinDEC) + CosRA * SinDEC * SinLST) as Lang.Double;
        Δdec += e * κ * (CosPI * CosEPS * (TanEPS * CosDEC - SinRA * SinDEC) + CosRA * SinDEC * SinPI);
    var result = {};
    result["delta_ra_aberration"] = Δra;
    result["delta_dec_aberration"] = Δdec;
    result["pi"] = π;
    result["kappa"] = κ;
    return result;
}

function Refraction (h as Lang.Double, P as Lang.Double, T as Lang.Double) as Lang.Double {
    // calculates the correction of altitude of a celectial body because of the atmospheric refraction
    // parameters:
    //  h: apparent height in degrees
    //  P: pressure in hectopascal
    //  T: temperature in degrees celsius
    // returns:
    //  correction value for altitude
    if (P == null) { P = 1013.246d; } 
    if (T == null) { T = 10.0d; }
    // Meeus: formula 15.3
    var R = 1.0d / Tan(h + 7.31d / (h + 4.4d)) as Lang.Double; // in minutes of arc
    var C = (h == 90.0d) ? 0.0013515d : 0.0d;
    var K = (h != 90.0d) ? (-0.06d * Sin(14.7d * R + 13.0d)) : 0.0d;
    var W = (P / 1013.246d) * (283.16d / (273.16d + T));
    R = W * (R + C + K) / 60.0d; // conversion into degrees
    return R;
}

function Geo2Topo (lat as Lang.Double, lon as Lang.Double, height as Lang.Double, Posit, gast as Lang.Double) {
    // converts geocentric coordinates into topocentric coordinates
    // parameters:
    //  lat: latitude of the observer
    //  lon: longitude of the observer
    //  height: height of the observer above mean sea level
    //  Posit: object containing right ascension, declination and distance (all geocentric) of a celestial body
    //  gast: Greenwich apparent sidereal time
    // returns:
    //  dictionary with
    //      "ra_topo": topocentric right ascension
    //      "dec_topo": topocentric declination
    //      "R_topo": topocentric distance
    var ra = Posit["ra_geo"] as Lang.Double;
    var dec = Posit["dec_geo"] as Lang.Double;
    var SinLAT = Sin(lat) as Lang.Double;
    var CosDEC = Cos(dec) as Lang.Double;
    var rho = 6378.14 - 21.38d * SinLAT * SinLAT + height / 1000.0d as Lang.Double;
    var Φ = lat - 0.1924d * Sin(2.0d * lat) as Lang.Double;
    var CosPHI = Cos(Φ) as Lang.Double;
    var θ = LSRT(gast, -1.0d * lon) * 15.0d as Lang.Double;
    var Δ = Posit["R_geo_km"] as Lang.Double;
    var xe = rho * CosPHI * Cos(θ) as Lang.Double;
    var ye = rho * CosPHI * Sin(θ) as Lang.Double;
    var ze = rho * Sin(Φ) as Lang.Double;
    var xm = Δ * CosDEC * Cos(ra) as Lang.Double;
    var ym = Δ * CosDEC * Sin(ra) as Lang.Double;
    var zm = Δ * Sin(dec) as Lang.Double;
    var x = xm - xe as Lang.Double;
    var y = ym - ye as Lang.Double;
    var z = zm - ze as Lang.Double;
    var Δ2 = Sqrt(x*x + y*y + z*z) as Lang.Double;
    var result = {};
    result["ra_topo"] = Mod(_2deg * Atan2(y, x), 360.0d) as Lang.Double;
    result["dec_topo"] = _2deg * Asin(z / Δ2) as Lang.Double;
    result["R_topo"] = Δ2 as Lang.Double;
    return result;
}