# Putting the game on the kids' Fire tablets (later step, NOT YET TESTED)

Status: placeholder. Spike 1b in docs/plan.md must be run before following this.

Known so far (to verify):
- Godot exports Android apps (APK files) itself, but needs: the Godot export templates (about 1 GB, matching 4.7.2), Java (JDK 17), the Android SDK command-line tools, and a "debug keystore" (a signing file). The kit should download all of these into `.tools/` like it does Godot.
- Fire tablets run Fire OS (based on Android) without the Google Play store. Installing an APK needs "Apps from Unknown Sources" turned on for the app used to open the file (e.g. Files or Silk browser). Which Fire model and Fire OS version matters.
- Amazon Kids profiles only show apps a parent adds; check whether sideloaded apps can be added, or play from the parent profile with screen pinning.
- Alternative to setting up Android tools on her laptop: build the APK in GitHub Actions and download it.
