# Laboratory Activity 9

Project folder: `C:\Users\charl\OneDrive\Desktop\Flutter\roque_navigation_app`

## Firebase Console

Use the existing project **roque-student-app-555646**.

1. Open **Authentication**, complete Get started if needed, then **Sign-in method**.
2. Enable **Anonymous** and save.
3. Open **Firestore Database > Create database**. Choose **Standard edition**, the **(default)** database ID, and **Production mode** if prompted.
4. Choose an appropriate location. Singapore (`asia-southeast1`) is a nearby option for the Philippines; the database location cannot be changed later.
5. Open **Firestore Database > Rules**. Replace the editor contents with the project's `firestore.rules` file and click **Publish**. The rule path must be `users/{userId}/students/{studentId}`.

To copy the rules from a terminal in the project folder:

```powershell
Get-Content .\firestore.rules -Raw | Set-Clipboard
```

The rules file and `firebase.json` are prepared locally. They have not been published by the local widget tests.

## Run

Stop the running app and run this in your normal VS Code terminal:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\setup_lab9.ps1
```

The script gets packages, runs FlutterFire configuration against the existing project for Web, analyzes the app, and opens Chrome. It reuses the patched Node runtime from Activity 8 when available.

Log in with **admin / admin123**, then open **Dashboard > Manage Student Records**.

For later launches after configuration:

```powershell
flutter run -d chrome
```

DemoAuth controls the classroom login screen. Firebase uses a separate anonymous identity. DemoAuth logout preserves that Firebase session. Different DemoAuth usernames in the same Firebase session access the same student records. Keep the same browser profile and app origin when verifying records; another browser session or cleared storage can create a different UID.

## Live tests and required screenshots

Use **Win + Shift + S**, capture the relevant app or Console area, and paste into `ROQUE_LAB9.docx`. Save images in `docs\screenshots\lab9` if separate files are needed.

| Screenshot space | What to capture | Where |
| --- | --- | --- |
| 1. CRUD form | Student Name, Course, Add Student, and Saved Students | Dashboard > Manage Student Records |
| 2. Three saved records | Alex Santos — BSIT; Jamie Cruz — BSCS; Morgan Reyes — BSIS | Student Records after adding each record |
| 3. Before update | Alex Santos showing BSIT, with the selected values in Edit Student | Tap Alex's Edit icon |
| 4. After update | Alex Santos showing BSCS | Change the course and tap Update Student |
| 5. Delete confirmation | Delete Jamie Cruz? with Cancel and Delete | Tap Jamie's Delete icon |
| 6. Deletion result | Jamie removed; Alex and Morgan remain | Confirm deletion |
| 7. Firestore saved documents | Student documents with name/course fields visible | Firestore Database > Data > users > UID > students > document |

Before deleting Jamie, choose **Cancel** once and verify that the record remains. Before changing Alex, capture the three-record screenshot and the before-update screenshot. An update should retain the same document ID and document count.

Also test both fields empty, spaces only, more than 80 characters, Cancel Edit, and returning to Dashboard then reopening Student Records. Confirm the records in the live Firestore Console, rather than relying only on the app list. Record Pass or Fail in the Word table only after the actual check.

## Documentation and submission

The editable report is `docs\ROQUE_LAB9.docx`. It contains identity details, seven screenshot spaces, the teacher's nine-row testing table, and five guide answers. Live checks initially remain **Not tested**.

Upload the Word document to Google Docs, insert the actual screenshots, complete the live testing table, then choose **File > Download > PDF Document**. Submit it as **ROQUE_LAB9.PDF** together with the GitHub repository link:

https://github.com/CharlesJaysonRoque555646/ROOM-ACT-7-INTEGRATED-FLUTTER-STUDENT-APPLICATION

The implementation is local until the changes are committed and pushed. No Blackboard submission is performed by this setup.

## Automated checks

`test\student_crud_page_test.dart` tests the actual CRUD widgets with an isolated collection double. It checks form validation, document IDs, create/read/update/delete, cancellation, live stream changes, reopening, disabled controls, database errors, and phone layout. It does not test live Firebase Authentication, network persistence, or published security rules.

```powershell
flutter test
flutter analyze
flutter build web
```
