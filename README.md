# Moon App & Simulator

The app is designed for Garmin Watches. It is written in Monkey C. It is to be installed on the watch via Garmin Connect IQ or Garmin Express from the [Garmin IQ Store](https://apps.garmin.com/apps/fb178fa4-b5df-4b29-ac2f-cae16b991766)

The app shows the real time moon data like rise, transit and set times, cycle, fraction, azimuth, altitude, distance, zenith angle of crescent moon, next main moon phases, apogees, perigees etc. based on the GPS position of your watch (no internet or smartphone required). Some data is presented in diagrams (screenshots are available in the [documentation](./docs/img/)).

In each view you may switch to the following or previous days to show the moon data and charts during that days (requires touch screen enabled). Especially the charts need a lot of calculation in the background. So the change of the calculation day may take up to 3 seconds (depending on your watch). If you actually don't receive GPS (or just if you want to know, how the moon looks like out of Antarctica), you may switch to simulation mode (via Garmin Express or Connect IQ) to simulate a GPS position anywhere in the world. If the simulation mode is enabled, there will be a "S" with a red circle on the diyplay.

Time zones and daylight saving times are calculated to the actual / simulated position (as stated by the Garmin firmware).

The App requires API level 4.2.2 or higher on the watch.

![](./docs/img/View_1.png)
