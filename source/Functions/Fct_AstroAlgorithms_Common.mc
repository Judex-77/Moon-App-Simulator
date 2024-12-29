import Toybox.Lang;
import Toybox.Time;

/* common calculations for celectial bodies */

function RiseTransitSet (JD0 as Lang.Double, lat as Lang.Double, lon as Lang.Double, ΔT as Lang.Double, height as Lang.Double, altitude as Lang.Double, RD, boolRefraction as Lang.Boolean) {
    // calculates the times of rise, transit and set of a celestial body of a certain day
    // the alogithms of Meeus chapt. 14 are extended by corrections of right ascension, local star time and diurnal arc to avoid a swap from 360° to 0°
    // parameters:
    //  JD0: julian day at 0:00 UTC
    //  lat: latitude of the obervers position
    //  lon: longitude of the obervers position
    //  ΔT: difference between dynamic time and universal time (in seconds)
    //  height: height of oberver above mean sea level (in meters)
    //  altitude: altitude of center of celestial body below horizon when rise or set occurs
    //  RD: object containing right ascension (ra) and declination (dec) of previous, actual and next day of celectial body
    //  boolRefraction: take into account athmospherical refraction or not 
    // returns:
    //  dictionary "rise", "transit", "set" each with sub-dictionaries: 
    //      "time": time of event
    //      "JD": julian day of event
    //      "moment": event as Toybox.Time.Moment
    var result = {};
        result["rise"] = {};
        result["transit"] = {};
        result["set"] = {};
    if (height == null) { height = 0.0d; }
    if (height < 0.0d) { height = 0.0d; }
    // Meeus: chapter 14.
    var h0 = (altitude == null) ? -0.8333d : altitude as Lang.Double;
    if (boolRefraction) {
        var Refra = Refraction(h0, null, null) as Lang.Double;
        h0 -= Refra;
    }
    var SinLAT = Sin(lat) as Lang.Double;
    var CosLAT = Cos(lat) as Lang.Double;
    var θ0 = GMST(JD0) as Lang.Double;
        θ0 *= 15.0d;
    // Meeus: formula 14.1
    var CosH0 = (Sin(h0) - SinLAT * Sin(RD[2]["dec"])) / (CosLAT * Cos(RD[2]["dec"])) as Lang.Double;
    var H0 = 0.0d as Lang.Double;
    result["circumpolar"] = false;
    result["never"] = false;
    if (CosH0 >= -1 && CosH0 <= 1) {
        H0 = _2deg * Acos(CosH0);
        H0 = Mod(H0, 180.0d);
    } else {  // circumpolar or never up
        if (CosH0 < -1) {
            result["circumpolar"] = true;
        } else {
            result["never"] = true;
        }
    } 
    
    // correction of right ascensions
    // source: https://www.hcgreier.at/ephempedia/doku.php?id=auf-_und_untergangszeiten#erdmond formula 25
    var ΔraAbs = 0.0d as Lang.Double;
    for (var i = 1; i <= 2; i++) {
        ΔraAbs = ((RD[i+1]["ra"] > RD[i]["ra"]) ? (RD[i+1]["ra"] - RD[i]["ra"]) : (RD[i]["ra"] - RD[i+1]["ra"])).abs();
        if (ΔraAbs > 180.0d) {
            if (RD[i+1]["ra"] > RD[i]["ra"]) {
                RD[i]["ra"] += 360.0d;
            } else {
                RD[i+1]["ra"] += 360.0d;
            }
        }
    }

    // Meeus: formula 14.2
    lon *= -1.0d;
    var m = {};
    var m0 = {};
    var mApx = {};
    mApx[0] = (RD[2]["ra"] + lon - θ0) / 360.0d as Lang.Double; // transit
    m0[0] = Mod(mApx[0], 1.0d) as Lang.Double;
    mApx[1] = mApx[0] - (H0 / 360.0d) as Lang.Double; // rise
    mApx[2] = mApx[0] + (H0 / 360.0d) as Lang.Double; // set
    m0[1] = Mod(mApx[1], 1.0d) as Lang.Double;
    m0[2] = Mod(mApx[2], 1.0d) as Lang.Double;

    var θ = {};
    var n = {};
    var ra = {};
    var dec = {};
    var a = 0.0 as Lang.Double;
    var b = 0.0 as Lang.Double;
    var c = 0.0 as Lang.Double;
    var H = {};
    var h = {};
    var Δm = {};
    var lmst = LSRT(θ0 / 15.0d, -1.0d * lon);
    var CosDECi = 0.0 as Lang.Double;
    
    // interpolation of right ascension and declination --> Meeus: formula 3.1 und 3.3
    for (var j = 0; j <= 2; j++) { // do recursive interpolation: 3 times
        for (var i = 0; i <= 2; i++) {
            θ[i] = lmst + 1.00273790931 * m0[i] * 24.0d;
        }
        // correction of local star time
        if (θ[1] > θ[0]) { θ[0] += 24.0d; }
        if (θ[2] < θ[0]) { θ[2] += 24.0d; }
        
        for (var i = 0; i <= 2; i++) {
            n[i] = m0[i] + ΔT / 86400.0d as Lang.Double;
            a = RD[2]["ra"] - RD[1]["ra"];
            b = RD[3]["ra"] - RD[2]["ra"];
            c = b - a;
            ra[i] = RD[2]["ra"] + (n[i] / 2.0d) * (a + b + n[i] * c) as Lang.Double;
            a = RD[2]["dec"] - RD[1]["dec"];
            b = RD[3]["dec"] - RD[2]["dec"];
            c = b - a;
            dec[i] = RD[2]["dec"] + (n[i] / 2.0d) * (a + b + n[i] * c) as Lang.Double;
            H[i] = θ[i] * 15.0d - ra[i] as Lang.Double;
            // correction of diurnal arc
            while (H[i] > 0) { 
                H[i] = Mod(H[i], 360.0d);
                H[i] -= 360.0d;
            }
            CosDECi = Cos(dec[i]);
            h[i] = _2deg * Asin(SinLAT * Sin(dec[i]) + CosLAT * CosDECi * Cos(H[i])) as Lang.Double; // Meeus: formula 12.6
            if (i == 0) {
                Δm[i] = -H[i] / 360.0d as Lang.Double;
            } else {
                Δm[i] = (h[i] - h0) / (360.0d * CosDECi * CosLAT * Sin(H[i])) as Lang.Double;
            }
            m[i] = m0[i] + Δm[i];
        }
        m0[0] = m[0];
        m0[1] = m[1];
        m0[2] = m[2];
    }

    result["transit"]["time"] = m0[0] * 24.0d;
    result["transit"]["JD"] = JD0 + m0[0];
    result["transit"]["moment"] = JD2Moment(JD0 + m0[0]);

    if (result["circumpolar"] == false && result["never"] == false) {
        result["rise"]["time"] = m0[1] * 24.0d;
        result["rise"]["JD"] = JD0 + m0[1];
        result["rise"]["moment"] = JD2Moment(JD0 + m0[1]);
        result["set"]["time"] = m0[2] * 24.0d;
        result["set"]["JD"] = JD0 + m0[2];
        result["set"]["moment"] = JD2Moment(JD0 + m0[2]);
    } else {
        result["rise"]["time"] = null;
        result["rise"]["JD"] = null;
        result["rise"]["moment"] = null;
        result["set"]["time"] = null;
        result["set"]["JD"] = null;
        result["set"]["moment"] = null;
    }

    return result;
}

function ParallacticAngle(Posit, lat as Lang.Double) as Lang.Double {
    // calculates the parallactic angle of a celestial body
    // parameters:
    // Posit: object containing declination (dec) and local hour angle of the body
    //  lat: latitude of the obervers position
    // returns:
    //  parallactic angle
    var dec = Posit["dec"];
    var H = Posit["LocalHourAngle"];
    // Meeus: formula 13.1
    var pa = _2deg * Atan2(Sin(H), Tan(lat) * Cos(dec) - Sin(dec) * Cos(H)) as Lang.Double;
    return pa;
}
