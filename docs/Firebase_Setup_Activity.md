# Firebase Setup Documentation

**Name:** Charles Jayson R Roque  
**Student ID:** 555646  
**Course:** BSIT - CCE 106 Mobile Development  
**Section:** 3447  
**Date:** 24 November 2026  

For this activity, I connected my existing Flutter app to Firebase and configured it for Web. After completing the setup, I was able to run the app in Chrome.

## Project details

**Project ID:** roque-student-app-555646  
**Web app:** roque_navigation_app  
**Web App ID:** 1:735669725582:web:7637530e5812de8fc25cdf  
**Firebase CLI version:** 15.37.0  
**FlutterFire CLI version:** 1.5.0  
**Flutter and Dart versions:** 3.47.7 and 3.13.5  
**Firebase Core version:** 5.2.0  
**Platform:** Web using Chrome  

## Setup

I installed the Firebase CLI and FlutterFire CLI, signed in with my Google account, and created the Firebase project. I then added firebase_core to the app and used FlutterFire to configure Web. This registered the Web app and generated firebase_options.dart inside the lib folder.

In main.dart, I added Firebase initialization before runApp(). I also added flutter_web_plugins to fix the missing dependency in the Web build. After that, the app opened in Chrome. The login and registration screens still use DemoAuth.

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const StudentApp());
}
```

## Testing

The 36 automated tests all passed. Code analysis found no issues, and the Web build finished without errors.

| Feature tested | What happened | Result |
| --- | --- | --- |
| Login | Valid details opened Dashboard. Empty or wrong details were rejected. | Pass |
| Registration | Valid registration worked. Empty, short, reserved or mismatched entries were rejected. | Pass |
| Show and hide passwords | The eye buttons showed and hid the passwords correctly. | Pass |
| Keyboard login | Submitting the password from the keyboard opened Dashboard. | Pass |
| Navigation | All four tabs opened in order and showed the correct username. | Pass |
| Calculator operations | All four operations gave the correct integer, decimal and negative answers. | Pass |
| Invalid calculator input | Invalid numbers were rejected, and division by zero was handled. | Pass |
| Clear and calculator state | Clear reset the fields. Switching tabs kept the inputs and result. | Pass |
| Creating posts | The new post appeared first with the logged-in username. | Pass |
| Post form | Empty fields and invalid URLs were rejected. Canceling did not add a post. | Pass |
| Like and unlike | The Like button changed correctly on the selected post. | Pass |
| Comments | Comments appeared and the count changed. Blank comments were ignored. | Pass |
| Keeping social activity | Posts, likes and comments stayed after scrolling, adding posts and changing tabs. | Pass |
| Profile | My student information and the logged-in username appeared correctly. | Pass |
| Logout | The app returned to Login. Back did not reopen the previous session. | Pass |
| Broken images | The fallback icon appeared when an image could not load. | Pass |
| Phone and desktop sizes | The pages worked at 390 by 700 and 1366 by 768 without layout errors. | Pass |
| Online image loading | Successful loading of images from online URLs was not checked. | Not tested |

## Guide questions

### 1. What is the difference between the Firebase CLI and FlutterFire CLI?

The Firebase CLI is used to sign in and manage Firebase projects from the terminal. The FlutterFire CLI connects the Flutter app to Firebase and creates its configuration file.

### 2. Why must configuration commands run inside the Flutter project root?

The commands need to run in the project root because this is where pubspec.yaml is located. The tools use that file to identify the app and its dependencies. This also helps them place the generated files in the correct folder.

### 3. What is the purpose of firebase_options.dart?

The firebase_options.dart file stores the Firebase settings for the platforms configured in the app. The app uses these settings to connect to the correct Firebase project.

### 4. Why is Firebase initialized before runApp()?

Firebase needs to be ready before the app uses its services. That is why Firebase.initializeApp() is awaited before runApp(). WidgetsFlutterBinding.ensureInitialized() prepares Flutter before this setup runs.

### 5. Why does installing Firebase not automatically replace DemoAuth?

Firebase Core sets up Firebase in the app, but it does not change the existing login code. The app still uses DemoAuth until login and registration are connected to Firebase Authentication.

## Screenshots

### Screenshot 1 Firebase CLI and FlutterFire CLI versions

[Insert screenshot 1 here]

<!-- Space for screenshot -->

### Screenshot 2 Firebase project and registered Web app

[Insert screenshot 2 here]

<!-- Space for screenshot -->

### Screenshot 3 Generated firebase_options.dart file

[Insert screenshot 3 here]

<!-- Space for screenshot -->

### Screenshot 4 Firebase initialization in main.dart

[Insert screenshot 4 here]

<!-- Space for screenshot -->

### Screenshot 5 Application running in Chrome

[Insert screenshot 5 here]

<!-- Space for screenshot -->

## GitHub repository

https://github.com/CharlesJaysonRoque555646/ROOM-ACT-7-INTEGRATED-FLUTTER-STUDENT-APPLICATION

## References

https://firebase.google.com/docs/cli

https://firebase.google.com/docs/flutter/setup
