# Roque Navigation App

CCE 106: StatefulWidget, Navigation, Lists, and User Interaction.

The app contains four destinations: Home, Calculator, Profile, and Social Media.
Login and registration use DemoAuth with one account stored in memory.
Default login: admin / admin123.

The calculator comes from Laboratory Activity 4. The profile uses the student's
actual information from the existing student_profile activity.
MainScreen uses setState and IndexedStack to preserve page state between tabs.

## Social Media feed

The `lib/social_media` folder contains `post.dart`, `create_post_sheet.dart`,
`post_card.dart`, and `social_media.dart`, using relative imports.
DemoAuth records the logged-in username. The feed starts with two sample posts
and supports captions, HTTP/HTTPS image URLs, likes/unlikes, and nonempty comments.
Posts appear newest first. Card keys, index lookup, and keep-alive retain the
correct interactions after inserting a post or scrolling.

Registration requires a username of at least three characters and a password
of at least six characters; admin is reserved and confirmation must match.
Eye icons toggle password visibility. Logout is in the Home app bar and clears
the session and navigation stack. All data is in memory and resets on restart.

## Tests and report

```powershell
flutter test
```

The 13 automated tests cover the activity's 11 scenarios, registration validation,
eye icons, and authentication failures. To capture the report screens:

```powershell
flutter test --dart-define=SAVE_SCREENSHOTS=true
```

See `docs/Social_Feed_Report.md`, `docs/Social_Feed_Report.pdf`, and
`docs/screenshots/` for the completed testing/tracing tables and screenshots.
The captures use Flutter widget rendering; network images show the fallback
because the test harness blocks HTTP. Live image loading and the Android/browser
demonstration still need a manual check. `docs/test_results.txt` records the
passing test output. Tests were run directly in the Flutter test engine because
this environment blocked the standard test runner's local socket.
The web release build was attempted but blocked by a sandbox restriction on
the SDK telemetry cache; a successful browser build is not claimed.

The existing repository is
https://github.com/CharlesJaysonRoque555646/roomactivity5-navigation-flutter.
Changes are local and have not been pushed or submitted to Blackboard.

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
- Check the profile, then create, like, and comment on Social Media posts.
- Switch tabs and verify the feed persists. Log out and confirm Back cannot
  reopen MainScreen. Register a new account and verify the post author changes.
