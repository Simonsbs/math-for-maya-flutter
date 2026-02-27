# Math For Maya (Flutter, Android Focus)

Native Flutter app for **Math For Maya**.

Current implemented mode:
- Vertical maths equations
- Operations: addition, subtraction, multiplication, division
- Digit and round-size selection
- One equation at a time
- Actions: Hint, Check, Show Solution, Next Equation
- Round summary and progress stats

## Android Run (Emulator)

```bash
export PATH=/opt/flutter/bin:/home/simon/Android/Sdk/platform-tools:/home/simon/Android/Sdk/emulator:$PATH
cd /home/simon/math_for_maya_flutter
emulator -avd Maya_Pixel_API_34 -no-snapshot-load -crash-report-mode disabled &
flutter run -d emulator-5554
```

## Android Build (APK)

```bash
cd /home/simon/math_for_maya_flutter
/opt/flutter/bin/flutter build apk --debug
```

APK output:
- `build/app/outputs/flutter-apk/app-debug.apk`
