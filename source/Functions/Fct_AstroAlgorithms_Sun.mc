import Toybox.Lang;
import Toybox.Time;

/* calculations for sun */

function SunPosition (JD as Lang.Double, lat as Lang.Double, lon as Lang.Double, height as Lang.Double) {
    // calculates the position of the sun
    // parameters:
    //  JD: julian day
    //  lat: latitude of the observer
    //  lon: longitude of the observer
    //  height: height of the observer above mean sea level
    // returns of data:
    //  ecliptic latitude and longitude
    //  geocentric distance
    //  geocentric right ascension and declination
    //  topocentric distance
    //  topocentric right ascension and declination
    if (height == null) { height = 0.0d; }
    if (height < 0.0d) { height = 0.0d; }
    // Meeus: formula 24.1
    var T = (JD - J2000) / 36525.0d as Lang.Double;
    // Meeus: formula 24.2
    var L0 = Mod(280.46645d + T * (36000.76983d + T * 0.0003032), 360.0d) as Lang.Double; // geometrische mittlere Länge der Sonne
    // Meeus: formula 24.3
    var M = Mod(357.52910d + T * (35999.05030d - T * (0.0001559d - T * 0.00000048d)), 360.0d) as Lang.Double; // Mittlere Anomalie der Sonne
    // Meeus: formula 24.4
    var e = 0.016708617d - T * (0.000042037d - T * 0.0000001236d) as Lang.Double; // Exzentrizität der Erdbahn
    var C = (1.914600d - T * (0.004817d - T * 0.000014d)) * Sin(M) + (0.019993d - 0.000101 * T) * Sin(2 * M) + 0.000290d * Sin(3 * M) as Lang.Double; // Mittelpunktsgleichung C der Sonne
    var lonSunTrue = L0 + C as Lang.Double; // wahre geometrische Länge der Sonne
    var v = M + C as Lang.Double; // wahre Anomalie
    // Meeus: formula 24.5
    var R = (1.000001018d * (1.0d - e * e)) / (1.0d + e * Cos(v)) as Lang.Double; // Entfernung der Erde von der Sonne in Astronomischen Einheiten
    // Meeus: formula 21.1 präziser als 24.5
    var Ω = 125.04452d - T * (1934.136261d + T * (0.0020708d + T * (1.0d / 450000.0d))) as Lang.Double; // Longitude of the ascending node of the Moon
    var λ = lonSunTrue - 0.00569d - 0.00478d * Sin(Ω) as Lang.Double; // scheinbare geometrische Länge der Sonne

    // Meeus: formula 21.2 (Schiefe der Ekliptik)
    var ϵ0 = (84381.448d - T * (46.8150d - T * (0.00059d + T * 0.001813d))) / 3600.0d as Lang.Double; // mittlere Schiefe der Ekliptik
    var Δϵ = 0.00256d * Cos(Ω) as Lang.Double; // Nutation in der Schiefe der Ekliptik
    var ϵ = ϵ0 + Δϵ; // wahre Schiefe der Ekliptik

    // Meeus: formula 24.6
    //var raT = _2deg * Atan2( Cos(ϵ0) * Sin(lonSunTrue), Cos(lonSunTrue)) as Lang.Double; // Rektaszension true
    //if (raT < 0) { raT += 360.0d; }
    var raA = _2deg * Atan2( Cos(ϵ) * Sin(λ), Cos(λ)) as Lang.Double; // Rektaszension apparent
    if (raA < 0) { raA += 360.0d; }
    var ra = raA as Lang.Double;
    // Meeus: formula 24.7
    //var decT = _2deg * Asin( Sin(ϵ0) * Sin(lonSunTrue) ) as Lang.Double; // Deklination true
    var decA = _2deg * Asin( Sin(ϵ) * Sin(λ) ) as Lang.Double; // Deklination apparent
    var dec = decA as Lang.Double;

    var result = {};
    var LonLatEcl = Equ2Ecl(ra, dec, ϵ);
    result["lon"] = LonLatEcl["lonEcl"] as Lang.Double;
    result["lat"] = LonLatEcl["latEcl"] as Lang.Double;

    // Meeus: formula 22.2 (Abberation)
    var aberration = {};
    aberration = Aberration(T, ra, dec, lonSunTrue, ϵ, e);
    var Δra2 = aberration["delta_ra_aberration"] as Lang.Double;
    var Δdec2 = aberration["delta_dec_aberration"] as Lang.Double;
    ra += Δra2 / 3600.0d;
    dec += Δdec2 / 3600.0d;
    var κ = aberration["kappa"];
    var π = aberration["pi"];
    var ΔLonEcl = (-κ * Cos(lonSunTrue - LonLatEcl["lonEcl"]) + e * κ * Cos(π - LonLatEcl["lonEcl"])) / Cos(LonLatEcl["latEcl"]) as Lang.Double;
    var ΔLatEcl = -κ * Sin(LonLatEcl["latEcl"]) * (Sin(lonSunTrue - LonLatEcl["lonEcl"]) - e * Sin(π - LonLatEcl["lonEcl"])) as Lang.Double;
    result["lon"] += ΔLonEcl;
    result["lat"] += ΔLatEcl;
    
    result["ra"] = ra;
    result["dec"] = dec;
    result["R_geo"] = R;
    result["R_geo_km"] = R * 149597870.7d;
    result["ra_geo"] = ra;
    result["dec_geo"] = dec;

    var topo = Geo2Topo(lat, lon, height, result, GAST(JD));
    result["ra_topo"] = topo["ra_topo"];
    result["dec_topo"] = topo["dec_topo"];
    result["R_topo_km"] = topo["R_topo"];
    return result;
}

function SunRiseTransitSet (JD0 as Lang.Double, lat as Lang.Double, lon as Lang.Double, ΔT as Lang.Double, height as Lang.Double, TZ as Lang.Double) {
    // calculates the times of rise, transit and set of the sun
    // parameters:
    //  JD0: julian day at 0:00 UTC
    //  lat: latitude of the observer
    //  lon: longitude of the observer
    //  ΔT: difference between dynamic time and universal time
    //  height: height of the observer above mean sea level
    //  TZ: time zone at observers position
    // returns of data:
    //  bool whether rise, transit and/or set will occur during the day
    //  local times of rise, transit and set
    //  azimuth and alitude at rise, transit and set
    //  rise, transit and set as Toybox.Time.Moment
    var ΔTd = ΔT / 86400.0d as Lang.Double;
    var RD = {};
    var RD2 = {};
        RD[1] = SunPosition(JD0 + ΔTd - 1.0d, lat, lon, height);
        RD[2] = SunPosition(JD0 + ΔTd       , lat, lon, height);
        RD[3] = SunPosition(JD0 + ΔTd + 1.0d, lat, lon, height);
    var h0 = -0.8333d as Lang.Double;
    var RTS = RiseTransitSet(JD0, lat, lon, ΔT, height, h0, RD, false);

    var RTSprev = {};
    var RTSnext = {};
    var riseBool = true as Lang.Boolean;
    var setBool = true as Lang.Boolean;
    var transitBool = true as Lang.Boolean;

    // calculation of local times
    if (RTS["circumpolar"] == false && RTS["never"] == false) {
        if (TZ > 0) {
            if ( (RTS["transit"]["time"] + TZ >= 24.0d || RTS["transit"]["time"] < -TZ) || (RTS["rise"]["time"] + TZ >= 24.0d || RTS["rise"]["time"] < -TZ) || (RTS["set"]["time"] + TZ >= 24.0 || RTS["set"]["time"] < -TZ) ) {
                
                RD2[1] = SunPosition(JD0 + ΔTd - 2.0d, lat, lon, height);
                RD2[2] = RD[1];
                RD2[3] = RD[2];
                RTSprev = RiseTransitSet(JD0 - 1.0d, lat, lon, ΔT, height, h0, RD2, false); 
                
                if (RTS["transit"]["time"] + TZ >= 24.0d || RTS["transit"]["time"] < -TZ) {
                    if (RTSprev["transit"]["time"] != null) {
                        if (RTSprev["transit"]["time"] + TZ < 24.0d) {
                            RTS["transit"]["time"] = null;
                            transitBool = false;
                        } else {
                            RTS["transit"]  = RTSprev["transit"];
                        }
                    } else {
                        transitBool = false;
                    }
                }
                if (RTS["rise"]["time"] + TZ >= 24.0d || RTS["rise"]["time"] < -TZ) {
                    if (RTSprev["rise"]["time"] != null) {
                        if (RTSprev["rise"]["time"] + TZ < 24.0) {
                            RTS["rise"]["time"] = null;
                            riseBool = false;
                        } else {
                            RTS["rise"]  = RTSprev["rise"];
                        }
                    } else {
                        riseBool = false;
                    }
                }
                if (RTS["set"]["time"] + TZ >= 24.0 || RTS["set"]["time"] < -TZ) {
                    if (RTSprev["set"]["time"] != null) {
                        if (RTSprev["set"]["time"] + TZ < 24.0) {
                            RTS["set"]["time"] = null;
                            setBool = false;
                        } else {
                            RTS["set"]  = RTSprev["set"];
                        }
                    } else {
                        setBool = false;
                    }
                }
            }
        } else if (TZ < 0) {
            if (RTS["rise"]["time"] < -TZ || RTS["set"]["time"] < -TZ || RTS["transit"]["time"] < -TZ) { 
                
                RD2[1] = RD[2];
                RD2[2] = RD[3];
                RD2[3] = SunPosition(JD0 + ΔTd + 2.0d, lat, lon, height);
                RTSnext = RiseTransitSet(JD0 + 1.0d, lat, lon, ΔT, height, h0, RD2, false); 
                
                if (RTS["transit"]["time"] < -TZ) {
                    
                    if (RTSnext["transit"]["time"] != null) {
                        if (RTSnext["transit"]["time"] > -TZ) {
                            RTS["transit"]["time"] = null;
                            transitBool = false;
                        } else {
                            RTS["transit"]  = RTSnext["transit"];
                        }
                    } else {
                        transitBool = false;
                    }
                }
                if (RTS["rise"]["time"] < -TZ) {
                    if (RTSnext["rise"]["time"] != null) {
                        if (RTSnext["rise"]["time"] > -TZ) {
                            RTS["rise"]["time"] = null;
                            riseBool = false;
                        } else {
                            RTS["rise"] = RTSnext["rise"];
                        }
                    } else {
                        riseBool = false;
                    }
                }
                if (RTS["set"]["time"] < -TZ) {
                    if (RTSnext["set"]["time"] != null) {
                        if (RTSnext["set"]["time"] > -TZ) {
                            RTS["set"]["time"] = null;
                            setBool = false;
                        } else {
                            RTS["set"]  = RTSnext["set"];
                        }
                    } else {
                        setBool = false;
                    }
                }
            }
        }
    } else if (RTS["circumpolar"] == true) {
        riseBool = false;
        setBool = false;
        if (TZ > 0) {
            if ( (RTS["transit"]["time"] + TZ >= 24.0d || RTS["transit"]["time"] < -TZ) ) {
                
                RD2[1] = SunPosition(JD0 + ΔTd - 2.0d, lat, lon, height);
                RD2[2] = RD[1];
                RD2[3] = RD[2];
                RTSprev = RiseTransitSet(JD0 - 1.0d, lat, lon, ΔT, height, h0, RD2, false); 
                
                if (RTS["transit"]["time"] + TZ >= 24.0d || RTS["transit"]["time"] < -TZ) {
                    if (RTSprev["transit"]["time"] != null) {
                        if (RTSprev["transit"]["time"] + TZ < 24.0d) {
                            RTS["transit"]["time"] = null;
                            transitBool = false;
                        } else {
                            RTS["transit"]  = RTSprev["transit"];
                        }
                    } else {
                        transitBool = false;
                    }
                }
            }
        } else if (TZ < 0) {
            if (RTS["transit"]["time"] < -TZ) { 
                
                RD2[1] = RD[2];
                RD2[2] = RD[3];
                RD2[3] = SunPosition(JD0 + ΔTd + 2.0d, lat, lon, height);
                RTSnext = RiseTransitSet(JD0 + 1.0d, lat, lon, ΔT, height, h0, RD2, false); 
                
                if (RTS["transit"]["time"] < -TZ) {
                    if (RTSnext["transit"]["time"] != null) {
                        if (RTSnext["transit"]["time"] > -TZ) {
                            RTS["transit"]["time"] = null;
                            transitBool = false;
                        } else {
                            RTS["transit"]  = RTSnext["transit"];
                        }
                    } else {
                        transitBool = false;
                    }
                }
            }
        }
    } else if (RTS["never"] == true) {
        riseBool = false;
        setBool = false;
        transitBool = false;
    }
    
    var AzAlt = {};
    var Pos = {};
    if (riseBool) {
        RTS["rise"]["local"] = Mod(RTS["rise"]["time"] + TZ, 24.0d);
        RTS["rise"]["local2"] = HHMM(RTS["rise"]["local"]);
        Pos = SunPosition(RTS["rise"]["JD"] + ΔTd, lat, lon, height);
        AzAlt = Equ2AzAlt(RTS["rise"]["JD"] + ΔTd, lat, lon, Pos);
        RTS["rise"]["az"] = AzAlt["az"];
        RTS["rise"]["alt"] = AzAlt["alt"];
        RTS["rise"]["moment"] = JD2Moment(RTS["rise"]["JD"] + ΔTd); 
    }
    if (transitBool) {
        RTS["transit"]["local"] = Mod(RTS["transit"]["time"] + TZ, 24.0d);
        RTS["transit"]["local2"] = HHMM(RTS["transit"]["local"]);
        Pos = SunPosition(RTS["transit"]["JD"] + ΔTd, lat, lon, height);
        AzAlt = Equ2AzAlt(RTS["transit"]["JD"] + ΔTd, lat, lon, Pos);
        RTS["transit"]["az"] = AzAlt["az"];
        RTS["transit"]["alt"] = AzAlt["alt"];
        RTS["transit"]["moment"] = JD2Moment(RTS["transit"]["JD"] + ΔTd);
    }
    if (setBool) {
        RTS["set"]["local"] = Mod(RTS["set"]["time"] + TZ, 24.0d);
        RTS["set"]["local2"] = HHMM(RTS["set"]["local"]);
        Pos = SunPosition(RTS["set"]["JD"] + ΔTd, lat, lon, height);
        AzAlt = Equ2AzAlt(RTS["set"]["JD"] + ΔTd, lat, lon, Pos);
        RTS["set"]["az"] = AzAlt["az"];
        RTS["set"]["alt"] = AzAlt["alt"];
        RTS["set"]["moment"] = JD2Moment(RTS["set"]["JD"] + ΔTd);
    }

    RTS["rise_bool"] = riseBool;
    RTS["set_bool"] = setBool;
    RTS["transit_bool"] = transitBool;
    return RTS;
}

function SunEventTimes (JD0U as Lang.Double, lat as Lang.Double, lon as Lang.Double, ΔT as Lang.Double, height as Lang.Double, TZ as Lang.Double) {
    // calculates the twilights, blue hour and golden hour
    // parameters:
    //  JD0U: julian day at 0:00 UTC
    //  lat: latitude of the observer
    //  lon: longitude of the observer
    //  ΔT: difference between dynamic time and universal time
    //  height: height of the observer above mean sea level
    //  TZ: time zone at observers position
    // returns:
    //  array containing an array with local time, type, color of display of the sun events
    var SunEvents = [
        [  6.0d,    "Daylight",    SunEventColors["Daylight"],   "GoldenHourE", SunEventColors["GoldenHour"]],
        [ -0.3d,    "GoldenHourM", SunEventColors["GoldenHour"], "SunSetStart", SunEventColors["Sunrise"]],
        [ -0.8333d, "SunRise",     SunEventColors["Sunrise"],    "SunSetEnd",   SunEventColors["BlueHour"]],
        [ -4.0d,    "BlueHourM",   SunEventColors["BlueHour"],   "BlueHourE",   SunEventColors["DawnCivil"]],
        [ -6.0d,    "CivilDawnM",  SunEventColors["DawnCivil"],  "CivilDawnE",  SunEventColors["DawnNautic"]],
        [-12.0d,    "NauticDawnM", SunEventColors["DawnNautic"], "NauticDawnE", SunEventColors["DawnAstro"]],
        [-18.0d,    "AstroDawnM",  SunEventColors["DawnAstro"],  "AstroDawnE",  SunEventColors["Night"]]        
    ];

    var EventTemp = {};
    var SunEventSeq = [];
    var SunEventSeq2 = [];
    SunEventSeq.add([0.0d, "Midnight", SunEventColors["Night"], HHMM(0.0d)]);
    SunEventSeq2.add([24.0d, "Midnight", SunEventColors["Night"], HHMM(24.0d)]);

    var RD = {};
        RD[1] = SunPosition(JD0U - 1, lat, lon, height);
        RD[2] = SunPosition(JD0U    , lat, lon, height);
        RD[3] = SunPosition(JD0U + 1, lat, lon, height);

    for (var i = SunEvents.size()-1; i >= 0; i--) {
        EventTemp = RiseTransitSet(JD0U, lat, lon, ΔT, height, SunEvents[i][0], RD, false);
        if (EventTemp["circumpolar"] == false && EventTemp["never"] == false) {
            // convert UTC into local time
            if ((EventTemp["rise"]["time"] + TZ) < 0.0d) { 
                EventTemp["rise"]["time"] = 24.0d + (EventTemp["rise"]["time"] + TZ);
            } else if ((EventTemp["rise"]["time"] + TZ) >= 24.0d) { 
                EventTemp["rise"]["time"] = (EventTemp["rise"]["time"] + TZ) - 24.0d;
            } else {
                EventTemp["rise"]["time"] = EventTemp["rise"]["time"] + TZ;
            }
            if ((EventTemp["set"]["time"] + TZ) < 0.0d) { 
                EventTemp["set"]["time"] = 24 + (EventTemp["set"]["time"] + TZ); 
            } else if ((EventTemp["set"]["time"] + TZ) >= 24.0d) { 
                EventTemp["set"]["time"] = (EventTemp["set"]["time"] + TZ) - 24.0d;
            } else {
                EventTemp["set"]["time"] = EventTemp["set"]["time"] + TZ;
            }
            // append events to morning and evening stack
            SunEventSeq.add([EventTemp["rise"]["time"], SunEvents[i][1], SunEvents[i][2], HHMM(EventTemp["rise"]["time"])]);
            SunEventSeq2.add([EventTemp["set"]["time"], SunEvents[i][3], SunEvents[i][4], HHMM(EventTemp["set"]["time"])]);
        } else {
            // remove previous event from stack and set actual event as start event, if event is circumpolar
            if (EventTemp["circumpolar"] == true) {
                SunEventSeq.remove(SunEventSeq[0]);
                SunEventSeq2.remove(SunEventSeq2[0]);
                SunEventSeq.add([0.0d, SunEvents[i][1], SunEvents[i][2]]);
                SunEventSeq2.add([24.0d, SunEvents[i][3], SunEvents[i][4]]);
            }
        }
    }
    // reverse stack of evening events and append to morning stack as return stack
    SunEventSeq2 = SunEventSeq2.reverse();
    SunEventSeq.addAll(SunEventSeq2);
    return SunEventSeq;
}
