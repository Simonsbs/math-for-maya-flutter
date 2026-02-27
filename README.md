# Math For Maya (Flutter)

Native Flutter mobile app for Android + iOS.

Implemented mode:
- Vertical maths equations
- Operations: addition, subtraction, multiplication, division
- Digit selection and round length selection
- One equation at a time
- Actions: Hint, Check, Show Solution, Next Equation
- Round summary with stats

## Run on Android Emulator

Prerequisites:
- Flutter installed
- Android SDK + emulator installed

Commands:
```bash
export PATH=/opt/flutter/bin:/home/simon/Android/Sdk/platform-tools:/home/simon/Android/Sdk/emulator:$PATH
cd /home/simon/math_for_maya_flutter
flutter run -d emulator-5554
```

## Build APK

```bash
cd /home/simon/math_for_maya_flutter
flutter build apk --debug
```

APK output:
- `build/app/outputs/flutter-apk/app-debug.apk`
