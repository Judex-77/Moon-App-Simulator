import Toybox.Lang;
import Toybox.Time;

/* calculations for moon */

function MoonPosition (JD as Lang.Double, lat as Lang.Double, lon as Lang.Double, height as Lang.Double, calcSteps as Lang.Number, EquatorialOnly as Lang.Boolean) {
    // calculates the position of the moon
    // parameters:
    //  JD: julian day
    //  lat: latitude of the observer
    //  lon: longitude of the observer
    //  height: height of the observer above mean sea level
    //  calcSteps: number of iterations for accuracy of moon position
    //  EquatorialOnly: return result, if only right ascension and declination is required
    // returns of data:
    //  ecliptic latitude and longitude
    //  geocentric distance and diameter
    //  geocentric right ascension and declination
    //  topocentric distance and diameter
    //  topocentric right ascension and declination

    // Meeus: formula 21.1
    var T = (JD - J2000) / 36525.0d as Lang.Double;
    // Meeus: formula 45.1
    var L_ = 218.3164591d + T * (481267.88134236d - T * (0.0013268d + T * (1.0d / 538841.0d - T * (1.0d / 65194000.0d)))) as Lang.Double; // Mittlere Länge des Mondes
        L_ = Mod(L_, 360.0d);
    // Meeus: formula 45.2
    var D = 297.8502042d + T * (445267.1115168d - T * (0.0016300d + T * (1.0d / 545868.0d - T * (1.0d / 113065000.0d)))) as Lang.Double; // Mittlere Elongation des Mondes
        D = Mod(D, 360.0d);
    // Meeus: formula 45.3
    var M = 357.5291092d + T * (35999.0502909d - T * (0.0001536d + T * (1.0d / 24490000.0d))) as Lang.Double; // Mittlere Anomalie der Sonne
        M = Mod(M, 360.0d);
    // Meeus: formula 45.4
    var M_ = 134.9634114d + T * (477198.8676313d + T * (0.0089970d + T * (1.0d / 69699.0d - T * (1.0d / 14712000.0d))))  as Lang.Double; // Mittlere Anomalie des Mondes
        M_ = Mod(M_, 360.0d);
    // Meeus: formula 45.5
    var F = 93.2720993d + T * (483202.0175273d - T * (0.0034029d - T * (1.0d / 3526000.0d + T * (1.0d / 863310000.0d))))  as Lang.Double; // Argument der Breite des Mondes (mittlerer Abstand des Mondes von seinem aufsteigenden Knoten)
        F = Mod(F, 360.0d);
    var A1 = 119.75d + 131.849d * T as Lang.Double;
        A1 = Mod(A1, 360.0d);
    var A2 = 53.09d + 479264.290d * T as Lang.Double;
        A2 = Mod(A2, 360.0d);
    var A3 = 313.45d + 481266.484d * T as Lang.Double;
        A3 = Mod(A3, 360.0d);
    // Meeus: formula 45.6
    var E = 1.0d - T * (0.002516d - T * 0.0000074d) as Lang.Double;

    var Σl = 0.0d as Lang.Double;
    var Σr = 0.0d as Lang.Double;
    var Σb = 0.0d as Lang.Double;
    var Σl0 = 0.0d as Lang.Double;
    var Σr0 = 0.0d as Lang.Double;
    var Σb0 = 0.0d as Lang.Double;

    //  Meeus, Seite 337
    var Terms_lr = MoonPeriodicTerms_LonRange;
    var Terms_b = MoonPeriodicTerms_Lat;
    if (calcSteps == null || calcSteps == 0) { calcSteps = Terms_lr.size(); }
    for (var i = 0; i < calcSteps; i++) {
        if (Terms_lr[i][4] != null) {
            Σl0 = Terms_lr[i][4] * Sin(Terms_lr[i][0] * D + Terms_lr[i][1] * M + Terms_lr[i][2] * M_ + Terms_lr[i][3] * F);
            if (Terms_lr[i][1] != 0) {
                Σl0 *= (Terms_lr[i][1].abs() == 1) ? E : (E * E);
            }
            Σl += Σl0;
        }
        if (Terms_lr[i][5] != null) {
            Σr0 = Terms_lr[i][5] * Cos(Terms_lr[i][0] * D + Terms_lr[i][1] * M + Terms_lr[i][2] * M_ + Terms_lr[i][3] * F);
            if (Terms_lr[i][1] != 0) {
                Σr0 *= (Terms_lr[i][1].abs() == 1) ? E : (E * E);
            }
            Σr += Σr0;
        }
        Σb0 = Terms_b[i][4] * Sin(Terms_b[i][0] * D + Terms_b[i][1] * M + Terms_b[i][2] * M_ + Terms_b[i][3] * F);
        if (Terms_b[i][1] != 0) {
            Σb0 *= (Terms_b[i][1].abs() == 1) ? E : (E * E);
        }
        Σb += Σb0;
    }

    // Meeus, Seite 338
    Σl += 3958.0d * Sin(A1) + 1962.0d * Sin(L_ - F) + 318.0d * Sin(A2);
    Σb += -2235.0d * Sin(L_) + 382.0d * Sin(A3) + 175.0d * Sin(A1 - F) + 175.0d * Sin(A1 + F) + 127.0d * Sin(L_ - M_) - 115.0d * Sin(L_ + M_);

    var λ = L_ + Σl / 1000000.0d as Lang.Double; // geozentrische Länge des Mondes
    var β = Σb / 1000000.0d as Lang.Double; // geozentrische Breite des Mondes
    var Δ = 385000.56d + Σr / 1000.0d as Lang.Double; // Entfernung der Mittelpunkte Erde - Mond
    // Meeus, Seite 336
    var π = _2deg * Asin(6378.14d / Δ) as Lang.Double; // Äquatorial-Horizontalparallaxe des Mondes
    
    var result = {};
    result["lon"] = λ;
    result["lat"] = β;
    result["R_geo_km"] = Δ;
    result["diam_geo"] = _2deg * 2.0d * Atan2(3474.8d, 2.0d * Δ); // angular diamter of moon in degrees

    // Meeus, Seite 339
    var nutation = Nutation(T);
    var ε = nutation["epsilon"];
    var Δψ = nutation["deltapsi"];
    var Δε = nutation["deltaepsilon"];
    λ += Δψ;
    var Posit = Ecl2Equ(λ, β, ε);
    var ra = Posit["ra"] as Lang.Double;
    var dec = Posit["dec"] as Lang.Double;
    if (EquatorialOnly == true) {
        result["ra"] = ra;
        result["dec"] = dec;
        return result;
    }
    var SinEPS = Sin(ε) as  Lang.Double;
    var SinRA = Sin(ra) as  Lang.Double;
    var CosRA = Cos(ra) as  Lang.Double;
    var TanDEC = Tan(dec) as  Lang.Double;
    var Δra1 = _2deg * ((Cos(ε) + SinEPS * SinRA * TanDEC) * Δψ - (CosRA * TanDEC) * Δε) as Lang.Double;
    var Δdec1 = _2deg * ((SinEPS * CosRA) * Δψ + SinRA * Δε) as Lang.Double;
    ra += Δra1;
    dec += Δdec1;

    result["ra_geo"] = ra;
    result["ra_geo_hour"] = HHMMSS(ra / 15.0d);
    result["dec_geo"] = dec;
    result["hPx"] = π;
    var topo = Geo2Topo(lat, lon, height, result, GAST(JD));
    result["ra_topo"] = topo["ra_topo"];
    result["ra_topo_hour"] = HHMMSS(topo["ra_topo"] / 15.0d);
    result["dec_topo"] = topo["dec_topo"];
    result["R_topo_km"] = topo["R_topo"];
    result["diam_topo"] = _2deg * 2.0d * Atan2(3474.8d, 2.0d * result["R_topo_km"]); // angular diamter of moon in degrees
    result["ra"] = result["ra_topo"];
    result["dec"] = result["dec_topo"];

    return result;
}

function MoonRiseTransitSet (JD0 as Lang.Double, lat as Lang.Double, lon as Lang.Double, ΔT as Lang.Double, height as Lang.Double, TZ as Lang.Double, Accuracy as Lang.Number) {
    // calculates the times of rise, transit and set of the moon
    // parameters:
    //  JD0: julian day at 0:00 UTC
    //  lat: latitude of the observer
    //  lon: longitude of the observer
    //  ΔT: difference between dynamic time and universal time
    //  height: height of the observer above mean sea level
    //  TZ: time zone at observers position
    //  Accuracy: number of iterations for determination of the position of the moon
    // returns of data:
    //  bool whether rise, transit and/or set will occur during the day
    //  local times of rise, transit and set
    //  azimuth and alitude at rise, transit and set
    //  rise, transit and set as Toybox.Time.Moment
    var RD = {};
    var RD2 = {};
    var ΔTd = ΔT / 86400.0d as Lang.Double;
    RD[1] = MoonPosition(JD0 + ΔTd - 1.0d, lat, lon, height, Accuracy, false);
    RD[2] = MoonPosition(JD0 + ΔTd             , lat, lon, height, Accuracy, false);
    RD[3] = MoonPosition(JD0 + ΔTd + 1.0d, lat, lon, height, Accuracy, false);
    var h0 = 0.7275d * RD[2]["hPx"] - 0.34d as Lang.Double; // horizontal parallax correction for altitude 
    var RTS = RiseTransitSet(JD0, lat, lon, ΔT, height, h0, RD, true);

    var RTSprev = {};
    var RTSnext = {};
    var riseBool = true as Lang.Boolean;
    var setBool = true as Lang.Boolean;
    var transitBool = true as Lang.Boolean;

    // calculation of local times
    if (RTS["circumpolar"] == false && RTS["never"] == false) {
        if (TZ > 0) {
            if ( (RTS["transit"]["time"] + TZ >= 24.0d || RTS["transit"]["time"] < -TZ) || (RTS["rise"]["time"] + TZ >= 24.0d || RTS["rise"]["time"] < -TZ) || (RTS["set"]["time"] + TZ >= 24.0 || RTS["set"]["time"] < -TZ) ) {
                
                RD2[1] = MoonPosition(JD0 + ΔTd - 2.0d, lat, lon, height, Accuracy, false);
                RD2[2] = RD[1];
                RD2[3] = RD[2];
                h0 = 0.7275d * RD2[2]["hPx"] - 0.34d as Lang.Double;
                //h0 = 0.125d;
                RTSprev = RiseTransitSet(JD0 - 1.0d, lat, lon, ΔT, height, h0, RD2, true); 
                
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
                RD2[3] = MoonPosition(JD0 + ΔTd + 2.0d, lat, lon, height, Accuracy, false);
                h0 = 0.7275d * RD2[2]["hPx"] - 0.34d as Lang.Double;
                //h0 = 0.125d;
                RTSnext = RiseTransitSet(JD0 + 1.0d, lat, lon, ΔT, height, h0, RD2, true); 
                
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
                
                RD2[1] = MoonPosition(JD0 + ΔTd - 2.0d, lat, lon, height, Accuracy, false);
                RD2[2] = RD[1];
                RD2[3] = RD[2];
                h0 = 0.7275d * RD2[2]["hPx"] - 0.34d as Lang.Double;
                //h0 = 0.125d;
                RTSprev = RiseTransitSet(JD0 - 1.0d, lat, lon, ΔT, height, h0, RD2, true); 
                
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
                RD2[3] = MoonPosition(JD0 + ΔTd + 2.0d, lat, lon, height, Accuracy, false);
                h0 = 0.7275d * RD2[2]["hPx"] - 0.34d as Lang.Double;
                //h0 = 0.125d;
                RTSnext = RiseTransitSet(JD0 + 1.0d, lat, lon, ΔT, height, h0, RD2, true); 
                
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
        Pos = MoonPosition(RTS["rise"]["JD"] + ΔTd, lat, lon, height, null, false);
        AzAlt = Equ2AzAlt(RTS["rise"]["JD"] + ΔTd, lat, lon, Pos);
        RTS["rise"]["az"] = AzAlt["az"];
        RTS["rise"]["alt"] = AzAlt["alt"];
        RTS["rise"]["moment"] = JD2Moment(RTS["rise"]["JD"] + ΔTd); 
    }
    if (transitBool) {
        RTS["transit"]["local"] = Mod(RTS["transit"]["time"] + TZ, 24.0d);
        RTS["transit"]["local2"] = HHMM(RTS["transit"]["local"]);
        Pos = MoonPosition(RTS["transit"]["JD"] + ΔTd, lat, lon, height, null, false);
        AzAlt = Equ2AzAlt(RTS["transit"]["JD"] + ΔTd, lat, lon, Pos);
        RTS["transit"]["az"] = AzAlt["az"];
        RTS["transit"]["alt"] = AzAlt["alt"];
        RTS["transit"]["moment"] = JD2Moment(RTS["transit"]["JD"] + ΔTd);
    }
    if (setBool) {
        RTS["set"]["local"] = Mod(RTS["set"]["time"] + TZ, 24.0d);
        RTS["set"]["local2"] = HHMM(RTS["set"]["local"]);
        Pos = MoonPosition(RTS["set"]["JD"] + ΔTd, lat, lon, height, null, false);
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

function MoonIllumination (Sun, Moon) {
    // calculates data for illumination of moon
    // parameters:
    //  Sun: object with position data of the sun
    //  Moon: object with position data of the moon
    // returns of data:
    //  fraction of illumination 
    //  zenith angle
    //  phase (inaccurate calculation of the progress of the moon phase between last and next new moon --> not used in the app)
    var result = {};
    var Sra = Sun["ra"] as Lang.Double;
    var Sdec = Sun["dec"] as Lang.Double;
    var Slon = Sun["lon"] as Lang.Double;
    var Mra = Moon["ra_topo"] as Lang.Double;
    var Mdec = Moon["dec_topo"] as Lang.Double;
    var Mlon = Moon["lon"] as Lang.Double;
    var Mlat = Moon["lat"] as Lang.Double;

    var CosSdec = Cos(Sdec) as Lang.Double;
    var CosMdec = Cos(Mdec) as Lang.Double;
    var CosSraMra = Cos(Sra - Mra) as Lang.Double;
    var SinSdec = Sin(Sdec) as Lang.Double;
    var SinMdec = Sin(Mdec) as Lang.Double;
    var SinSraMra = Sin(Sra - Mra) as Lang.Double;
    
    // Meeus: formula 46.2 Variante 2
    var ψ = _2deg * Acos(Cos(Mlat) * Cos(Mlon - Slon)) as Lang.Double;
    var i = _2deg * Atan2(Sun["R_topo_km"] * Sin(ψ), Moon["R_topo_km"] - Sun["R_topo_km"] * Cos(ψ)) as Lang.Double;
    var angle = _2deg * Atan2(CosSdec * SinSraMra, SinSdec * CosMdec - CosSdec * SinMdec * CosSraMra) as Lang.Double;
    var positionAngle1 = CosSdec * SinSraMra as Lang.Double;
    var positionAngle2 = SinSdec * CosMdec - CosSdec * SinMdec * CosSraMra as Lang.Double;
    var positionAngle  = _2deg * Atan2(positionAngle1, positionAngle2) as Lang.Double;
    var zenithAngle = Mod(positionAngle - Moon["pa"] + 360.0d, 360.0d) as Lang.Double;
    // Meeus: formula 46.1
    result["fraction"] = (1.0d + Cos(i)) / 2.0d as Lang.Double;
    result["zenithAngle"] = zenithAngle;
    result["phase"] = 0.5d + 0.5d * (i * _2rad) * (angle < 0 ? -1 : 1) / pi as Lang.Double;
    return result;
}

function MoonEventDates (JD as Lang.Double, tNow as Lang.Double, tUTC as Lang.Object, ΔT as Lang.Double, TZ as Lang.Object, lat as Lang.Double, lon as Lang.Double, AnzEvents as Lang.Number, TypeEvent as Lang.String, Period as Lang.Boolean) {
    // calculates data for illumination of moon
    // parameters:
    //  JD: julian day
    //  tNow: actual time as Toybox.Time.Moment
    //  tUTC: object as Toybox.Time.Moment containing the actual year in UTC
    //  ΔT: difference between dynamic time and universal time
    //  TZ: time zone of the observer
    //  lat: latitude of the observer
    //  lon: longitude of the observer
    //  AnzEvents: amount of events to be returned
    //  TypeEvent: type of moon events to be returnes ("NM": new moon, "FQ": first quarter, "FM": full moon, "LQ": last quarter)
    //  Period: flag, that only the last and the next new moon is to be return (for calculation of progress of moon period)
    // returns of data:
    //  array of dictionaries: 
    //      "type": type of moon event 
    //      "time": local time of moon event
    //      "year": year of moon event
    //      "month": month of moon event
    //      "day": day of moon event
    //      "moment": moon event as Toybox.Time.Moment
    //      "JD": julian day of moon event
    var optionsY0 = {
        :year   => tUTC.year,
        :month  => 1,
        :day    => 1,
        :hour   => 0,
        :minute => 0,
        :second => 0
    };
    if (AnzEvents > 4) { AnzEvents = 4; }
    var tY0 = Gregorian.moment(optionsY0);
    var YearDays = ((tUTC.year % 4) == 0) ? 366.0d : 365.0d as Lang.Double;
    var y = 0.0d as Lang.Double;
    var k = 0.0d as Lang.Double;
    var k0 = 0.0d as Lang.Double;
    y = tNow.subtract(tY0).value() as Lang.Double;
    y = y / 86400.0d;
    y = tUTC.year + y / YearDays;
    // Meeus: formula 47.2
    k = (y - 2000.0d) * 12.3685d as Lang.Double;

    if (Period == true) {
        k  -= 1.0d;
    }

    k0 = Floor(k) as Lang.Double;
    k = Round(k * 4.0d, 0) / 4.0d;

    var ki = 0.0d as Lang.Double;
    var T = 0.0d as Lang.Double;
    var M = 0.0d as Lang.Double;
    var M_ = 0.0d as Lang.Double;
    var F = 0.0d as Lang.Double;
    var Ω = 0.0d as Lang.Double;
    var E = 0.0d as Lang.Double;
    var JDE0 = 0.0d as Lang.Double;
    var JDE = [];
    var NF = MoonPeriodicTerms_NewFull;
    var Q = MoonPeriodicTerms_Quarters;
    var A = MoonPeriodicTerms_ArgsPlanets;
    var ΔJDE = 0.0d as Lang.Double;
    var ΔJDE0 = 0.0d as Lang.Double;
    var W = 0.0d as Lang.Double;
    var ΔA = 0.0d as Lang.Double;
    var phase = 0 as Lang.Number;
    var local = {};

    for (var i = 0; i < AnzEvents; i += 1) {
        // Meeus: formula 47.1
        //ki = k + (i / 4.0d);
        ki = k + (i / 4.0d) - 0.25d;
        // Meeus: formula 47.3
        T = k0 / 1236.85d as Lang.Double;
        // Meeus: formula 47.4
        M = 2.5534d + 29.10535669d * ki - T * T * (0.0000218d - T * 0.00000011d) as Lang.Double; // Mittlere Anomalie der Sonne zur Zeit
        M = Mod(M, 360.0d);
        // Meeus: formula 47.5
        M_ = 201.5643d + 385.81693528d * ki + T * T * (0.0107438d + T * (0.00001239d - T * 0.000000058d)) as Lang.Double; // Mittlere Anomalie des Mondes
        M_ = Mod(M_, 360.0d);
        // Meeus: formula 47.6
        F =  160.7108d + 390.67050274d * ki - T * T * (0.0016341d - T * (0.00000227d + T * 0.000000011d)) as Lang.Double; // Argument der Breite des Mondes
        F = Mod(F, 360.0d);
        // Meeus: formula 47.7
        Ω = 124.7746d - 1.56375580d * ki + T * T * (0.0020691d + T * 0.00000215d) as Lang.Double; // Länge des aufsteigenden Knotens der Mondbahn
        Ω = Mod(Ω, 360.0d);
        // Meeus: formula 45.6
        E = 1.0d - T * (0.002516d - T * 0.0000074d) as Lang.Double;
        ΔJDE = 0.0d;
        for (var j = 0; j < NF.size(); j++) {
            phase = Mod((Frac(ki) * 4).toNumber(), 4);
            switch (phase) {
                case 0:
                    ΔJDE0 = NF[j][0] * Sin(NF[j][3] * M_ + NF[j][4] * M + NF[j][5] * F + NF[j][6] * Ω);
                    if (NF[j][2] > 0) {
                        ΔJDE0 *= (NF[j][2] == 1) ? E : (E * E);
                    }
                    ΔJDE += ΔJDE0;
                    break;
                case 2:
                    ΔJDE0 = NF[j][1] * Sin(NF[j][3] * M_ + NF[j][4] * M + NF[j][5] * F + NF[j][6] * Ω);
                    if (NF[j][2] > 0) {
                        ΔJDE0 *= (NF[j][2] == 1) ? E : (E * E);
                    }
                    ΔJDE += ΔJDE0;
                    break;
                default:
                    ΔJDE0 = Q[j][0] * Sin(Q[j][2] * M_ + Q[j][3] * M + Q[j][4] * F + Q[j][5] * Ω);
                    if (Q[j][1] > 0) {
                        ΔJDE0 *= (Q[j][1] == 1) ? E : (E * E);
                    }
                    ΔJDE += ΔJDE0;
            }
        }
        // Meeus: formula 47.1
        JDE0 = 2451550.09765d + 29.530588853d * ki + T * T * (0.0001337d - T * (0.00000015d + T * 0.00000000073d));
        JDE0 += ΔJDE;
        JDE0 -= ΔT / 86400.0d;
        if (phase == 1 || phase == 3) {
            W = 0.00306d - 0.00038d * E * Cos(M) + 0.00026d * Cos(M_) - 0.00002d * Cos(M_ - M) + 0.00002d * Cos(M_ + M) + 0.00002d * Cos(2 * F);
            JDE0 += W * ((phase == 1) ? 1.0d : -1.0d);
        }

        // Argumente der Planeten
        ΔA = 0.0d;
        ΔA += 0.000325d * Sin(299.77d + 0.107408d * ki - 0.009173d * T * T);
        for (var j = 0; j < A.size(); j++) {
            ΔA += A[j][0] * Sin(A[j][1] + A[j][2] * ki);
        }
        JDE0 += ΔA;
        
        var tDate = JD2Moment(JDE0);
        var ΔDate = tDate.value() - tNow.value() as Lang.Double;
        var tDuration = new Time.Duration(TZ * 3600.0d) as Lang.Object; // difference UTC -> time zone in seconds as duration
        var tDateLocal = tDate.add(tDuration); // add differnce UTC -> time zone to UTC to get local time
        var tLocal = Gregorian.utcInfo(tDateLocal, Time.FORMAT_SHORT);
        if ((ΔDate >= 0 && (TypeEvent == null || TypeEvent == phase)) || (Period == true && TypeEvent == phase)) {
            local = null;
            local = {
                "type" => (phase == 0) ? "NM" : (phase == 1) ? "FQ" : (phase == 2) ? "FM" : "LQ",
                "time" => tLocal.hour + tLocal.min / 60.0d + tLocal.sec / 3600.0d,
                "year" => tLocal.year,
                "month" => tLocal.month,
                "day" => tLocal.day,
                "moment" => tDate,
                "JD" => JDE0
            };
            JDE.add(local);
        } else {
            AnzEvents++;
        }
        if (JDE.size() > 0 && Period == false) {
            if (tDate.compare(tNow) < 0) {
                JDE.remove(JDE[0]);
            }
        }
        if (JDE.size() == 2 && Period == true) {
            if (JDE[1]["moment"].compare(tNow) < 0) {
                JDE.remove(JDE[0]);
                AnzEvents++;
            }
        }
    }
    return JDE;
}

function MoonApogeePerigee (JD as Lang.Double, tNow as Lang.Double, tUTC as Lang.Object, ΔT as Lang.Double, TZ as Lang.Object, lat as Lang.Double, lon as Lang.Double) {
    // calculates data for the next upcoming apogee and perigee
    // parameters:
    //  JD: julian day
    //  tNow: actual time as Toybox.Time.Moment
    //  tUTC: object as Toybox.Time.Moment containing the actual year in UTC
    //  ΔT: difference between dynamic time and universal time
    //  TZ: time zone of the observer
    //  lat: latitude of the observer
    //  lon: longitude of the observer
    // returns of data:
    //  array of dictionaries: 
    //      "type": type of moon event 
    //      "time": local time of moon event
    //      "year": year of moon event
    //      "month": month of moon event
    //      "day": day of moon event
    //      "JD": julian day of moon event
    var optionsY0 = {
        :year   => tUTC.year,
        :month  => 1,
        :day    => 1,
        :hour   => 0,
        :minute => 0,
        :second => 0
    };
    var AnzEvents = 2 as Lang.Number;
    var tY0 = Gregorian.moment(optionsY0);
    var YearDays = ((tUTC.year % 4) == 0) ? 366.0d : 365.0d as Lang.Double;
    var y = tNow.subtract(tY0).value() as Lang.Double;
        y = y / 86400.0d;
        y = tUTC.year + y / YearDays;
    // Meeus: formula 48.2
    var k = (y - 1999.97d) * 13.2555d as Lang.Double;
        k = Round(k * 2.0d, 0) / 2.0d;
    var ki = 0.0d as Lang.Double;
    var T = 0.0d as Lang.Double;
    var D = 0.0d as Lang.Double;
    var M = 0.0d as Lang.Double;
    var F = 0.0d as Lang.Double;
    var JDE0 = 0.0d as Lang.Double;
    var JDE = [];
    var PT = getMoonPeriodicTerms_PerigeeTime();
    var AT = getMoonPeriodicTerms_ApogeeTime();
    var ΔJDE = 0.0d as Lang.Double;
    var phase = 0 as Lang.Number;
    var local = {};
    for (var i = 0; i < AnzEvents; i += 1) {
        ki = k + (i / 2.0d);
        // Meeus: formula 48.3
        T = ki / 1325.55d as Lang.Double;
        // Meeus: formula 48.1
        JDE0 = 2451534.6698d + 27.55454988d * ki - T * T * (0.0006886d - T * (0.000001098d + T * 0.0000000052d));
        // Meeus: formula 48 page 356
        D = 171.9179d + 335.9106046d * ki - T * T * (0.0100250d - T * (0.00001156d + T * 0.000000055d));
        D = Mod(D, 360.0d);
        M = 347.3477d + 27.1577721d * ki - T * T * (0.0008323d + T * 0.0000010d);
        M = Mod(M, 360.0d);
        F = 316.6109d + 364.5287911d * ki - T * T * (0.0125131d - T * 0.0000148d);
        F = Mod(F, 360.0d);

        phase = Mod((Frac(ki) * 2).toNumber(), 2);
        ΔJDE = 0.0d;
        switch (phase) {
            case 0:
                for (var j = 0; j < PT.size(); j++) {
                    ΔJDE += (PT[j][3] * T + PT[j][4]) * Sin(PT[j][0] * D + PT[j][1] * M + PT[j][2] * F);
                }
                break;
            case 1:
                for (var j = 0; j < AT.size(); j++) {
                    ΔJDE += (AT[j][3] * T + AT[j][4]) * Sin(AT[j][0] * D + AT[j][1] * M + AT[j][2] * F);
                }
                break;
        }
        JDE0 += ΔJDE;
        //JDE0 -= ΔT / 86400.0d;
        var tDate = JD2Moment(JDE0);
        var ΔDate = tDate.value() - tNow.value() as Lang.Double;
        var tDuration = new Time.Duration(TZ * 3600.0d) as Lang.Object;
        var tDateLocal = tDate.add(tDuration);
        var tLocal = Gregorian.utcInfo(tDateLocal, Time.FORMAT_SHORT);
        if (ΔDate >= 0) {
            local = null;
            local = {};
            local["type"] = (phase == 0) ? "Perigee" : "Apogee";
            local["JD"] = JDE0;
            local["time"] = tLocal.hour + tLocal.min / 60.0d + tLocal.sec / 3600.0d;
            local["year"] = tLocal.year;
            local["month"] = tLocal.month;
            local["day"] = tLocal.day;
            JDE.add(local);
        } else {
            AnzEvents++;
        }
    }
    return JDE;
}