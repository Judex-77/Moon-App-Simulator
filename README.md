# Moon App & Simulator

The app is designed for Garmin Watches. It is written in Monkey C. It is to be installed on the watch via Garmin Connect IQ or Garmin Express from the [Garmin IQ Store](https://apps.garmin.com/apps/fb178fa4-b5df-4b29-ac2f-cae16b991766)

The app shows the real time moon data like rise, transit and set times, cycle, fraction, azimuth, altitude, distance, zenith angle of crescent moon, next main moon phases, apogees, perigees etc. based on the GPS position of your watch (no internet or smartphone required). Some data is presented in diagrams (screenshots are available in the [documentation](./docs/img/)).

In each view you may switch to the following or previous days to show the moon data and charts during that days (requires touch screen enabled). Especially the charts need a lot of calculation in the background. So the change of the calculation day may take up to 3 seconds (depending on your watch). If you actually don't receive GPS (or just if you want to know, how the moon looks like out of Antarctica), you may switch to simulation mode (via Garmin Express or Connect IQ) to simulate a GPS position anywhere in the world. If the simulation mode is enabled, there will be a "S" with a red circle on the diyplay.

Time zones and daylight saving times are calculated to the actual / simulated position (as stated by the Garmin firmware).

The App requires API level 4.2.2 or higher on the watch.

<img width="250" src="./docs/img/View_1.png">

## Terms and conditions

For detailed information consult the [license](./LICENSE.txt).

**You are free to:**

- Share: copy and redistribute the material in any medium or format
- Adapt: remix, transform, and build upon the material

**Under the following terms:**

- Attribution: You must give appropriate credit , provide a link to the license, and indicate if changes were made . You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use.
- NonCommercial: You may not use the material for commercial purposes .
- ShareAlike: If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original.
- No additional restrictions: You may not apply legal terms or technological measures that legally restrict others from doing anything the license permits.
