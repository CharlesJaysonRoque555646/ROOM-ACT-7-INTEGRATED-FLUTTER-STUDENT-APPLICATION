# Roque Navigation App

CCE 106: Demo Authentication, StatefulWidget, and Bottom Navigation.

The app contains four destinations in order: Dashboard, Calculator, Social, Profile.
Login and registration use DemoAuth with one account stored in memory.
Default login: admin / admin123.

The calculator comes from Laboratory Activity 4. The profile uses the student's
actual information from the existing student_profile activity.
MainScreen uses setState and IndexedStack to preserve page state between tabs.
It reads the active username once in initState and passes it to Dashboard,
Social, and Profile. Dashboard greets that account. Profile retains the fixed
student information and displays the active username separately, as required
by the activity; separate editable student profiles are not part of this demo.

## Social Media feed

The `lib/social_media` folder contains `post.dart`, `create_post_sheet.dart`,
`post_card.dart`, and `social_media.dart`, using relative imports.
DemoAuth records the logged-in username. The feed starts with two sample posts
and supports captions, HTTP/HTTPS image URLs, likes/unlikes, and nonempty comments.
Posts appear newest first. Card keys, index lookup, and keep-alive retain the
correct interactions after inserting a post or scrolling.

Registration requires a username of at least three characters and a password
of at least six characters; admin is reserved and confirmation must match.
Eye icons toggle password visibility. Logout is in Profile and clears
the session and navigation stack. All data is in memory and resets on restart.

## Tests and report

```powershell
flutter test
```

The 28 automated tests cover all 14 current activity scenarios, calculator
operations/validation/Clear, and the previous feed, authentication, validation,
and password-visibility checks. To capture the report screens:

```powershell
flutter test --dart-define=SAVE_SCREENSHOTS=true
```

See `docs/Roque_Integrated_Student_App_Activity.md`,
`docs/Roque_Integrated_Student_App_Activity.pdf`, and
`docs/screenshots/integration/` for the completed testing table, five guide
answers, and seven screenshots. The older Social Feed report belongs to the
previous activity.
The captures use Flutter widget rendering; network images show the fallback
because the test harness blocks HTTP. Live image loading and the Android/browser
demonstration still need a manual check. `docs/integration_test_results.txt` records the
passing test output. Tests were run directly in the Flutter test engine because
this environment blocked the standard test runner's local socket.
The web release build was attempted but blocked by a sandbox restriction on
the SDK telemetry cache; a successful browser build is not claimed.

The existing repository is
https://github.com/CharlesJaysonRoque555646/ROOM-ACT-7-INTEGRATED-FLUTTER-STUDENT-APPLICATION.
The current integration update is local; it has not been pushed or submitted
to Blackboard. The report is a local PDF, not a Google Docs export.

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
- Check that Dashboard welcomes the logged-in username and Profile shows it.
- Create, like, and comment on Social posts, then switch tabs and verify they persist.
- Log out from Profile and confirm Back cannot
  reopen MainScreen. Register a new account and verify the post author changes.

