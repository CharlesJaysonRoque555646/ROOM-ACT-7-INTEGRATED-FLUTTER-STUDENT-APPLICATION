# Roque Navigation App

CCE 106: Demo Authentication, StatefulWidget, and Bottom Navigation.

The app contains four destinations in order: Dashboard, Calculator, Social, Profile.
Login and registration use DemoAuth with one account stored in memory.
Default login: admin / admin123.

## Laboratory Activity 9

Dashboard now opens **Manage Student Records**. The module uses anonymous
Firebase Authentication and Cloud Firestore at
`users/{uid}/students/{documentId}`. Records have only `name` and `course`.
It supports live records, creation, editing by document ID, confirmed deletion,
required fields, an 80-character limit, and database error messages.

Enable Anonymous sign-in, create the default Firestore database, and publish
`firestore.rules` in the existing Firebase project before launching the app.
See [the setup and screenshot instructions](docs/LAB9_SETUP.md).
Run `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\setup_lab9.ps1`
in your normal VS Code terminal to configure Web and launch Chrome.

The plain editable report is `docs/ROQUE_LAB9.docx`. Add the seven required
screenshots and actual live test results, then export it from Google Docs as
`ROQUE_LAB9.PDF`. The local automated CRUD tests use an isolated collection;
they do not establish that live Firebase services or rules are configured.
All 50 application/widget tests passed on 24 November 2026, including the
14 new CRUD tests. Static analysis found no issues and the Web release build
passed. Results are in `docs/lab9_test_results.txt`,
`docs/lab9_analysis_results.txt`, and `docs/lab9_web_build_results.txt`.

## Firebase setup activity

Run `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\setup_firebase.ps1`
from this project folder in your normal VS Code terminal. Complete Google sign-in
and choose your Firebase project when prompted. The script installs the CLIs,
adds Firebase Core, configures Web, initializes Firebase before app startup,
and starts Chrome. It keeps the existing DemoAuth login and navigation.

Firebase setup is complete for Web using project `roque-student-app-555646`.
FlutterFire generated `lib/firebase_options.dart`, and `main.dart` initializes
Firebase before app startup. The missing `flutter_web_plugins` SDK dependency
was added, dependency resolution and analysis passed, and the student confirmed
that Chrome launch and the application checks work.
See `docs/Firebase_Setup_Activity.md` for the setup details, completed
verification table, screenshot checklist, and five guide-question answers.
The completed report is in `docs/Roque_Firebase_Setup.pdf`, with five labeled
spaces for screenshots. Open `docs/Roque_Firebase_Setup.html` to add screenshots
and print the filled report as a PDF. The editable text is also available in
`docs/Firebase_Setup_Activity.md`.

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
the DemoAuth session and navigation stack. DemoAuth accounts and Social posts
are in memory and reset on restart. Student Records are stored in Firestore
under the anonymous Firebase UID; DemoAuth logout preserves that Firebase session.

## Tests and report

```powershell
flutter test
```

The 36 automated tests cover all 14 integration scenarios, calculator
operations/validation/Clear, feed interactions, authentication, validation,
password controls, keyboard login, canceled posts, image fallback, and phone
and desktop layouts. All 36 passed on 24 November 2026. The fresh results are
recorded in `docs/firebase_functionality_test_results.txt`.
To capture the earlier activity report screens:

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
The Web release build also passed on 24 November 2026. Chrome startup was
separately confirmed by the student. Successful live image downloads are not
covered by the widget tests; the unavailable-image fallback is verified.

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

