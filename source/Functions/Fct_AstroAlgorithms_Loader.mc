import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Math;
import Toybox.System;
import Toybox.Position;

function getAstroData (myLocation, height as Lang.Double, astroDataContent as Lang.Object) {
    // collects the nesseccary data of the moon for the view, where the function is called from
    // parameters:
    // myLocation: array of size 2: 
    //             [0] = latitude of the observer
    //                   north: positive, south: negative
    //             [1] = longitude of the observer
    //                   east: positive, west: negative
    // height: height of the observer above mean sea level
    // astroDataContent: dictionary of requested data of the moon
    var result = {};
    var DayOffset = (DaysOffset * 86400).toNumber() as Lang.Number;
    var TimeZoneOffset = TimeOffset1 as Lang.Double;
    // Test-Location:
    //myLocation[0] = 51.558477d;
    //myLocation[1] = 13.004272d;

    myLocation[0] = (myLocation[0] > 89.99d) ? 89.99d : (myLocation[0] < -89.99d) ? -89.99d : myLocation[0];
    myLocation[1] = (myLocation[1] > 179.99d) ? 179.99d : (myLocation[1] < -179.99d) ? -179.99d : myLocation[1];

    // Test-date
    /*
    var options = {
        :year   => 2024,
        :month  => 12,
        :day    => 1,
        :hour   => 0,
        :minute => 0,
        :second => 0
    };
    var tDuration = new Time.Duration(DayOffset) as Lang.Object;
    var tNow = Gregorian.moment(options);
        tNow = tNow.add(tDuration);
    */
    var tNow = new Time.Moment(Time.now().value() + DayOffset);

    var lat = myLocation[0] as Lang.Double; 
    var lon = myLocation[1] as Lang.Double;
    var where = new Position.Location({
        :latitude  =>  lat,
        :longitude => lon,
        :format    => :degrees,
    });
    var local = Gregorian.localMoment(where, tNow);
    var TimeZone = local.getOffset() / 3600.0d + TimeZoneOffset as Lang.Double;

    var t = Gregorian.info(tNow, Time.FORMAT_SHORT);
    
    var tUTC = Gregorian.utcInfo(tNow, Time.FORMAT_SHORT);
    var HU = (tUTC.hour + (tUTC.min.toDouble() / 60.0d) + (tUTC.sec.toDouble() / 3600.0d)) as Lang.Double;
    //var JD0U = Date2JD0(tUTC.day, tUTC.month, tUTC.year) as Lang.Double; // JD at midnight
    var JD0U = Date2JD0(t.day, t.month, t.year) as Lang.Double; // JD at midnight
    var JDU  = JD0U + HU / 24.0d as Lang.Double; // JD now in UTC

    var ΔT = DeltaT(tUTC.year) as Lang.Double; // difference between dynamic time and UTC (TDT-UT), in seconds
    var TDT = JDU + (ΔT / 86400.0d) as Lang.Double; // true day time

    if (astroDataContent["Date"] == true) {
        if (UnitMetric == true) {
            result["date"] = Lang.format("$1$.$2$.$3$", [t.day.format("%02d"), t.month.format("%02d"),t.year.format("%4d")]);
        } else {
            result["date"] = Lang.format("$1$-$2$-$3$", [t.month.format("%2d"), t.day.format("%2d"),t.year.format("%4d")]);
        }
    }

    if (astroDataContent["Time"] == true) {
        if (Hour24 == true) {
            result["time"] = Lang.format("$1$:$2$:$3$", [t.hour.format("%02d"), t.min.format("%02d"),t.sec.format("%02d")]);
        } else {
            var Hour12 = t.hour;
            if (t.hour > 12) {
                Hour12 -= 12;
            }
            result["time"] = Lang.format("$1$:$2$:$3$", [Hour12.format("%02d"), t.min.format("%02d"),t.sec.format("%02d")]);
            result["time"] += (t.hour < 12) ? " am" : " pm";
        }
        result["time0"] = t.hour.toDouble() + t.min.toDouble() / 60.0 + t.sec.toDouble() / 3600.0;
    }

    var Sun = {};
    var SunNow = {};
    var SunRTS = {};
    var SunEvents = {};
    
    if (astroDataContent["SunPosit"] == true) { Sun = SunPosition(TDT, lat, lon, height); }
    if (astroDataContent["SunAzAlt"] == true) {
        SunNow = Equ2AzAlt(JDU, lat, lon, Sun);
        result["Sun_Now_AzAlt"] = SunNow;
    }
    if (astroDataContent["SunRTS"] == true) { 
        SunRTS = SunRiseTransitSet(JD0U, lat, lon, ΔT, height, TimeZone);
        result["Sun_Today_RTS"] = SunRTS;
    }
    if (astroDataContent["SunEvents"] == true) { 
        SunEvents = SunEventTimes(JD0U, lat, lon, ΔT, height, TimeZone);
        result["Sun_Today_events"] = SunEvents;
    }
        
    var Moon = {};
    var MoonNow = {};
    var MoonIllu = {};
    var Refra = {};
    var MoonEvents = {};
    var MoonPeriod = {};
    var MoonPerigeeApogee = [];
    
    if (astroDataContent["MoonPosit"] == true) {
        Moon = MoonPosition(TDT, lat, lon, height, null, false);
    }

    if (astroDataContent["MoonAzAlt"] == true) {
        MoonNow = Equ2AzAlt(TDT, lat, lon, Moon);
        Moon["LocalHourAngle"] = MoonNow["LocalHourAngle"];
        Moon["pa"] = ParallacticAngle(Moon, lat);
        result["Moon_Now_PA"] = Moon["pa"];
        Refra = Refraction(MoonNow["alt"], null, null) as Lang.Double;
        MoonNow["alt"] += Refra;
        result["az"] = MoonNow["az"];
        result["alt"] = MoonNow["alt"];
    }

    if (astroDataContent["MoonCycFrac"] == true) {
        MoonIllu = MoonIllumination(Sun, Moon);
        result["fraction"] = MoonIllu["fraction"];
        result["Moon_Now_illu_zenithAngle"] = MoonIllu["zenithAngle"];
        result["Moon_Now_moonAge"] = MoonIllu["phase"];

        MoonPeriod = MoonEventDates(JD0U, tNow, tUTC, ΔT, TimeZone, lat, lon, 2, 0, true);
        var tB = MoonPeriod[0]["moment"];
        var tE = MoonPeriod[1]["moment"];
        var durationPeriod = tE.subtract(tB);
        var Period = tNow.subtract(tB);
        var Cycle = Period.value().toDouble() / durationPeriod.value().toDouble() as Lang.Double;;
        result["cycle"] = Cycle;
        result["fraction"] = MoonIllu["fraction"];
    }
  
    if (astroDataContent["MoonDiamDist"] == true) {
        result["diameter"] = Moon["diam_topo"] * 60.0d;
        result["distance"] = Moon["R_topo_km"];
    }

    if (astroDataContent["MoonRTS"] == true) {
        var MoonRTS = MoonRiseTransitSet(JD0U, lat, lon, ΔT, height, TimeZone, astroDataContent["MoonAccuracy"]);
        result["Moon_Today_rise_bool"] = MoonRTS["rise_bool"];
        result["Moon_Today_rise_label"] = "Rise";
        if (MoonRTS["rise_bool"] == true) {
            result["Moon_Today_rise_time"] = MoonRTS["rise"]["local"];
            result["Moon_Today_rise_time2"] = MoonRTS["rise"]["local2"];
            MoonRTS["Moon_Today_rise_direction"] = Direction(MoonRTS["rise"]["az"]);
            result["Moon_Today_rise_value"] = (MoonRTS["rise"]["az"]).format("%.1f") + "° " + MoonRTS["Moon_Today_rise_direction"];
        } else {
            result["Moon_Today_rise_time"] = null;
            result["Moon_Today_rise_time2"] = empty;
            result["Moon_Today_rise_value"] = empty;
        }
        result["Moon_Today_set_bool"] = MoonRTS["set_bool"];
        result["Moon_Today_set_label"] = "Set";
        if (MoonRTS["set_bool"] == true) {
            result["Moon_Today_set_time"] = MoonRTS["set"]["local"];
            result["Moon_Today_set_time2"] = MoonRTS["set"]["local2"];
            MoonRTS["Moon_Today_set_direction"] = Direction(MoonRTS["set"]["az"]);
            result["Moon_Today_set_value"] = (MoonRTS["set"]["az"]).format("%.1f") + "° " + MoonRTS["Moon_Today_set_direction"];
        } else {
            result["Moon_Today_set_time"] = null;
            result["Moon_Today_set_time2"] = empty;
            result["Moon_Today_set_value"] = empty;
        }
        result["Moon_Today_transit_bool"] = MoonRTS["transit_bool"];
        result["Moon_Today_transit_label"] = "Transit";
        if (MoonRTS["transit_bool"] == true) {
            result["Moon_Today_transit_time"] = MoonRTS["transit"]["local"];
            result["Moon_Today_transit_time2"] = MoonRTS["transit"]["local2"];
            result["Moon_Today_transit_value"] = "Alt " + (MoonRTS["transit"]["alt"]).format("%.1f") + "°";
        } else {
            result["Moon_Today_transit_time"] = null;
            result["Moon_Today_transit_time2"] = empty;
            result["Moon_Today_transit_value"] = empty;
        }
    }

    if (astroDataContent["MoonDay"] == true) {
        var Azi = [];
        var MoonDayStep = 0.5d as Lang.Double;
        var ti = 0.0d as Lang.Double;
        var MoonDay = {};
        var MoonDayAA = {};
        var ΔTday = ΔT / 86400.0d as Lang.Double;
        for (var i = 0; i <= (24.0d / MoonDayStep); i++) {
            ti = i.toDouble() * (MoonDayStep);
            JDU  = JD0U + ΔTday + (ti - TimeZone) / 24.0d;
            MoonDay = MoonPosition(JDU, lat, lon, height, 1, true);
            MoonDayAA = Equ2AzAlt(JDU, lat, lon, MoonDay);
            MoonDay["az"] = MoonDayAA["az"];
            MoonDay["alt"] = MoonDayAA["alt"];
            Azi.add([ti, Round(MoonDay["az"], 1), Round(MoonDay["alt"], 1), ""]);
        }
        result["MoonDay"] = Azi;
    }

    if (astroDataContent["MoonEvents"] == true) {
        MoonEvents = MoonEventDates(JD0U, tNow, tUTC, ΔT, TimeZone, lat, lon, 5, null, false);
        for (var i = 0; i < MoonEvents.size(); i++) {
            Sun = SunPosition(MoonEvents[i]["JD"], lat, lon, height);
            Moon = MoonPosition(MoonEvents[i]["JD"], lat, lon, height, astroDataContent["MoonAccuracy"], false);
            MoonNow = Equ2AzAlt(MoonEvents[i]["JD"], lat, lon, Moon);
            Moon["LocalHourAngle"] = MoonNow["LocalHourAngle"];
            Moon["pa"] = ParallacticAngle(Moon, lat);
            MoonEvents[i]["Moon_Now_PA"] = Moon["pa"];
            MoonEvents[i]["az"] = MoonNow["az"];
            MoonEvents[i]["alt"] = MoonNow["alt"];
            MoonIllu = MoonIllumination(Sun, Moon);
            MoonEvents[i]["Moon_Now_phaseNumber"] = MoonIllu["phase"];
            MoonEvents[i]["fraction"] = MoonIllu["fraction"];
            MoonEvents[i]["Moon_Now_illu_zenithAngle"] = MoonIllu["zenithAngle"];
            MoonEvents[i]["Moon_Now_moonAge"] = MoonIllu["phase"];
        }
        result["MoonEvents"] = MoonEvents;
    }

    if (astroDataContent["MoonPeriod"] == true) {
        MoonPeriod = MoonEventDates(JD0U, tNow, tUTC, ΔT, TimeZone, lat, lon, 2, 0, true);
        var tB = MoonPeriod[0]["moment"];
        var tE = MoonPeriod[1]["moment"];
        var durationPeriod = tE.subtract(tB);
        var actualPeriod = tNow.subtract(tB);
        var Cycle = actualPeriod.value().toDouble() / durationPeriod.value().toDouble() as Lang.Double;;
        result["MoonPeriod"] = Cycle;
    }

    if (astroDataContent["MoonPerigeeApogee"] == true) {
        MoonPerigeeApogee = MoonApogeePerigee(JD0U, tNow, tUTC, ΔT, TimeZone, lat, lon);
        for (var i = 0; i < MoonPerigeeApogee.size(); i++) {
            Moon = MoonPosition(MoonPerigeeApogee[i]["JD"], lat, lon, height, null, false);
            MoonNow = Equ2AzAlt(MoonPerigeeApogee[i]["JD"], lat, lon, Moon);
            MoonPerigeeApogee[i]["az"] = MoonNow["az"];
            MoonPerigeeApogee[i]["alt"] = MoonNow["alt"];
            MoonPerigeeApogee[i]["distance"] = Moon["R_geo_km"];
            MoonPerigeeApogee[i]["diameter"] = Moon["diam_topo"];
        }
        result["MoonPerigeeApogee"] = MoonPerigeeApogee;
    }

    return result;
}
