# Roque Navigation App

CCE 106: StatefulWidget and Bottom Navigation.

The app contains four destinations: Home, Calculator, Profile, and Social Media.
Login and registration use DemoAuth with one account stored in memory.
Default login: admin / admin123.

The calculator comes from Laboratory Activity 4. The profile uses the student's
actual information from the existing student_profile activity.
MainScreen uses setState and IndexedStack to preserve page state between tabs.

## Run

```powershell
flutter pub get
flutter run -d chrome
```

For Android, select your connected Android device with flutter run.
Build the web version using flutter build web.

## Check

- Register an account, then log in with it. Confirm the default admin still works.
- Check validation, password visibility, invalid credentials, and password confirmation.
- Calculate a result, switch tabs, and return; inputs and result should remain.
- Check all four operations, division by zero, invalid input, and Clear.
- Check the profile and tap each sample social account to display its username.
