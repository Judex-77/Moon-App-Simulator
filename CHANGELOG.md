# Changelog

## v2.0.10
- Changed to SDK Build 8.3.0
- Added support for Devices:
    - fēnix® 8 47mm / 51mm / tactix 8 47mm / 51mm / quatix 8 47mm 51mm
    - fēnix® 8 Pro 47mm / 51mm / MicroLED
    - Venu® 4 41mm
    - Venu® 4 45mm

## v2.0.9
- Changed to SDK Build 8.2.1
- Added support for Devices:
    - Forerunner® 570 42mm
    - Forerunner® 570 47mm
    - Forerunner® 970
    - vívoactive® 6

## v2.0.8

- Bugfixes:
    - Correction of calculation of actual azimuth and altitude of moon with consideration to time zones.
    - Correction of parallactic angle of the moon picture.

## v2.0.7

- Bugfix: When the difference between the actual time and midnight was smaller than the difference between UTC and time zone, the calculation of moon data was executed for the wrong day.

## v2.0.6

- The astronomical algorithms are completely new designed. There are now the procedures of Jean Meeus (Meeus, Jean: Astronomische Algorithmen, 2. Edition, Verlag Johann Ambrosius Barth, Leipzig - Berlin - Heidelberg, 1994) implemented (by that there are now correct calculations during the equinoxes).
- Nutation, refraction and abberation are taken into account. 
- The calculated times like moon rise, set and so on have an accuracy of round abount +/- 10 seconds (theoretically the accuracy could be better than +/- 1 second, but the watches doesn't allow the neccessary amount of iterations).
- There are two new views available:
    - Date and time of comming up new moon, first quarter, full moon and last moon (green color: moon is above horizon at that times, red color: moon is below horizon)
    - Date, time, diameter, distance, altitude and azimuth of comming up apogee and perigee (green color: moon is above horizon at that times, red color: moon is below horizon)
- Changed to SDK Build 7.4.3
- Added support for Devices:
    - Venu® 3
    - Venu® 3S

## v1.2.5

- Changed to SDK Build 7.3.0
- Changed system fonts into vector fonts
- Added support for Devices:
    - Enduro 3
    - Forerunner 165, 165 Music
    - Forerunner 265, 265S
    - Forerunner 955, 955 Solar
    - Forerunner 965
    - fenix 8 AMOLED 43mm, 47mm, 51mm
    - fenix 8 Solar 47mm, 51mm
    - fenix E

## v1.2.3

- Changed to SDK Build 7.2.1
- Added support for Devices: 
    - Approach® S70
    - D2™ Mach 1 Pro
    - Descent™ MK3
    - MARQ® (Gen 2)
    - MARQ® Commander (Gen 2) Carbon Edition
    - MARQ™ Aviator (Gen 2)
    - epix™ (Gen 2)
    - epix™ Pro (Gen 2)
    - fēnix® 7
    - fēnix® 7 Pro
    - fēnix® 7S
    - fēnix® 7S Pro

## v1.1.2

- New view: 360° Sky Map with path of moon during the whole day (Azimuth-Altitude-Time chart)
- Crescent moon is rotating as real.
- Size of moon changes equivalent to distance between moon and observer.
- Changed to SDK Build 7.1.1
- Bugfixes:
    - fixed time zones with daylight saving time
    - fixed Azimuth-Time-Chart for locations near the equator

## v1.0.1

- Workaround for bug in firmware version 16.22 (avoiding global non-primitive variables at declaration)
