import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roque_navigation_app/demo_auth.dart';
import 'package:roque_navigation_app/login_screen.dart';
import 'package:roque_navigation_app/main.dart';
import 'package:roque_navigation_app/main_screen.dart';
import 'package:roque_navigation_app/social_media/create_post_sheet.dart';
import 'package:roque_navigation_app/social_media/post_card.dart';

final captureKey = GlobalKey();

Future<void> startApp(WidgetTester tester) async {
  DemoAuth.registeredUsername = null;
  DemoAuth.registeredPassword = null;
  DemoAuth.logout();

  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    RepaintBoundary(key: captureKey, child: const StudentApp()),
  );
  await tester.pumpAndSettle();
}

Future<void> login(
  WidgetTester tester, [
  String username = 'admin',
  String password = 'admin123',
]) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Username'),
    username,
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Password'),
    password,
  );
  await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
  await tester.pumpAndSettle();
  // Let a registration-success SnackBar finish before tapping the feed FAB.
  await tester.pump(const Duration(seconds: 4));
  await tester.pumpAndSettle();
}

Future<void> openFeed(WidgetTester tester) async {
  await tester.tap(find.byType(NavigationDestination).at(3));
  await tester.pumpAndSettle();
}

Future<void> openPostForm(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Create Post'));
  await tester.pumpAndSettle();
}

Future<void> fillPost(WidgetTester tester, String caption, String url) async {
  await tester.enterText(find.widgetWithText(TextField, 'Caption'), caption);
  await tester.enterText(find.widgetWithText(TextField, 'Image URL'), url);
}

Future<void> submit(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(ElevatedButton, 'Submit Post'));
  await tester.pumpAndSettle();
}

Future<void> createPost(WidgetTester tester, String caption) async {
  await openPostForm(tester);
  await fillPost(tester, caption, 'https://picsum.photos/id/20/600/400');
  await submit(tester);
}

Future<void> capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('SAVE_SCREENSHOTS')) return;
  await tester.pumpAndSettle();
  final boundary =
      captureKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final output = File('docs/screenshots/$name.png');
    output.parent.createSync(recursive: true);
    output.writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Real fonts make captured Flutter widget output readable in the report.
    if (const bool.fromEnvironment('SAVE_SCREENSHOTS')) {
      final font = File('C:/Windows/Fonts/arial.ttf');
      if (await font.exists()) {
        final loader = FontLoader('Roboto')
          ..addFont(
            Future.value(ByteData.sublistView(await font.readAsBytes())),
          );
        await loader.load();
      }
    }
  });

  testWidgets('01 admin login opens MainScreen and stores session', (
    tester,
  ) async {
    await startApp(tester);
    await capture(tester, '01_login');
    await login(tester);
    expect(find.byType(MainScreen), findsOneWidget);
    expect(DemoAuth.currentUsername, 'admin');
  });

  testWidgets('02 feed shows the two sample posts', (tester) async {
    await startApp(tester);
    await login(tester);
    await openFeed(tester);
    expect(find.text('JohnDoe'), findsOneWidget);
    expect(find.text('JaneSmith'), findsOneWidget);
    await capture(tester, '03_feed');
  });

  testWidgets('03 empty post fields show validation', (tester) async {
    await startApp(tester);
    await login(tester);
    await openFeed(tester);
    await openPostForm(tester);
    await capture(tester, '04_create_post');
    await submit(tester);
    expect(
      find.text('Complete both fields before submitting!'),
      findsOneWidget,
    );
    expect(find.byType(CreatePostSheet), findsOneWidget);
  });

  testWidgets('04 invalid URL shows validation', (tester) async {
    await startApp(tester);
    await login(tester);
    await openFeed(tester);
    await openPostForm(tester);
    await fillPost(tester, 'Test caption', 'not-an-image-url');
    await submit(tester);
    expect(find.text('Enter a valid HTTP or HTTPS image URL.'), findsOneWidget);
  });

  testWidgets('05 valid post is first and uses logged-in username', (
    tester,
  ) async {
    await startApp(tester);
    await login(tester);
    await openFeed(tester);
    await createPost(tester, 'My first Flutter social media post!');
    final first = tester.widget<PostCard>(find.byType(PostCard).first);
    expect(first.post.username, 'admin');
    expect(first.post.caption, 'My first Flutter social media post!');
    expect(find.byType(CreatePostSheet), findsNothing);
  });

  testWidgets('06 like toggles on and off', (tester) async {
    await startApp(tester);
    await login(tester);
    await openFeed(tester);
    final first = find.byType(PostCard).first;
    await tester.tap(find.descendant(of: first, matching: find.text('Like')));
    await tester.pump();
    expect(
      find.descendant(of: first, matching: find.text('Liked')),
      findsOneWidget,
    );
    await tester.tap(find.descendant(of: first, matching: find.text('Liked')));
    await tester.pump();
    expect(
      find.descendant(of: first, matching: find.text('Like')),
      findsOneWidget,
    );
  });

  testWidgets('07 nonempty comment appears and increments count', (
    tester,
  ) async {
    await startApp(tester);
    await login(tester);
    await openFeed(tester);
    await createPost(tester, 'My first Flutter social media post!');
    final first = find.byType(PostCard).first;
    await tester.tap(find.descendant(of: first, matching: find.text('Like')));
    await tester.enterText(
      find.descendant(of: first, matching: find.byType(TextField)),
      'Great activity!',
    );
    await tester.tap(
      find.descendant(of: first, matching: find.byTooltip('Send comment')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Great activity!'), findsOneWidget);
    expect(
      find.descendant(of: first, matching: find.text('1 Comments')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextField>(
            find.descendant(of: first, matching: find.byType(TextField)),
          )
          .controller!
          .text,
      isEmpty,
    );
    await capture(tester, '05_post_like_comment');
  });

  testWidgets('08 whitespace-only comment is ignored', (tester) async {
    await startApp(tester);
    await login(tester);
    await openFeed(tester);
    final first = find.byType(PostCard).first;
    await tester.enterText(
      find.descendant(of: first, matching: find.byType(TextField)),
      '   ',
    );
    await tester.tap(
      find.descendant(of: first, matching: find.byTooltip('Send comment')),
    );
    await tester.pump();
    expect(
      find.descendant(of: first, matching: find.text('0 Comments')),
      findsOneWidget,
    );
  });

  testWidgets('09 sample interactions stay attached after prepending a post', (
    tester,
  ) async {
    await startApp(tester);
    await login(tester);
    await openFeed(tester);
    final samplePost = tester
        .widget<PostCard>(find.byType(PostCard).first)
        .post;
    final sample = find.byKey(ObjectKey(samplePost));
    await tester.tap(find.descendant(of: sample, matching: find.text('Like')));
    await tester.enterText(
      find.descendant(of: sample, matching: find.byType(TextField)),
      'Keep this comment',
    );
    await tester.tap(
      find.descendant(of: sample, matching: find.byTooltip('Send comment')),
    );
    await tester.pump();
    await createPost(tester, 'A newer post');
    final newestPost = tester
        .widget<PostCard>(find.byType(PostCard).first)
        .post;
    await tester.ensureVisible(
      find.descendant(of: sample, matching: find.text('Liked')),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: sample, matching: find.text('Liked')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sample, matching: find.text('Keep this comment')),
      findsOneWidget,
    );
    final newest = find.byKey(ObjectKey(newestPost));
    await tester.drag(find.byType(ListView).last, const Offset(0, 1800));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: newest, matching: find.text('Liked')),
      findsNothing,
    );
  });

  testWidgets('10 posts likes and comments survive tab switching', (
    tester,
  ) async {
    await startApp(tester);
    await login(tester);
    await openFeed(tester);
    await createPost(tester, 'Persistent during navigation');
    final first = find.byType(PostCard).first;
    await tester.tap(find.descendant(of: first, matching: find.text('Like')));
    await tester.enterText(
      find.descendant(of: first, matching: find.byType(TextField)),
      'Still here',
    );
    await tester.tap(
      find.descendant(of: first, matching: find.byTooltip('Send comment')),
    );
    await tester.tap(find.byType(NavigationDestination).at(0));
    await tester.pumpAndSettle();
    await openFeed(tester);
    expect(find.text('Persistent during navigation'), findsOneWidget);
    expect(find.text('Liked'), findsOneWidget);
    expect(find.text('Still here'), findsOneWidget);
  });

  testWidgets('11 logout clears stack and new account authors new posts', (
    tester,
  ) async {
    await startApp(tester);
    await login(tester);
    await tester.tap(find.byTooltip('Logout'));
    await tester.pumpAndSettle();
    expect(DemoAuth.currentUsername, isNull);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(MainScreen), findsNothing);
    expect(
      Navigator.of(tester.element(find.byType(LoginScreen))).canPop(),
      isFalse,
    );
    await tester.tap(find.text("Don't have an account? Register"));
    await tester.pumpAndSettle();
    await capture(tester, '02_register');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'Scyla',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'secret',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm Password'),
      'secret',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
    await tester.pumpAndSettle();
    await login(tester, 'Scyla', 'secret');
    expect(DemoAuth.currentUsername, 'Scyla');
    await openFeed(tester);
    await createPost(tester, 'Posted as a registered user');
    expect(
      tester.widget<PostCard>(find.byType(PostCard).first).post.username,
      'Scyla',
    );
  });

  testWidgets('12 registration validation and password visibility', (
    tester,
  ) async {
    await startApp(tester);
    await tester.tap(find.text("Don't have an account? Register"));
    await tester.pumpAndSettle();
    final username = find.widgetWithText(TextFormField, 'Username');
    final password = find.widgetWithText(TextFormField, 'Password');
    final confirm = find.widgetWithText(TextFormField, 'Confirm Password');
    await tester.enterText(username, 'ab');
    await tester.enterText(password, 'short');
    await tester.enterText(confirm, 'other');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
    await tester.pumpAndSettle();
    expect(find.text('Use at least 3 characters.'), findsOneWidget);
    expect(find.text('Use at least 6 characters.'), findsOneWidget);
    expect(find.text('Passwords do not match.'), findsOneWidget);
    await tester.enterText(username, 'ADMIN');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
    await tester.pumpAndSettle();
    expect(find.text('This username is reserved.'), findsOneWidget);
    final passwordInput = find.descendant(
      of: password,
      matching: find.byType(TextField),
    );
    expect(tester.widget<TextField>(passwordInput).obscureText, isTrue);
    await tester.tap(
      find.descendant(of: password, matching: find.byType(IconButton)),
    );
    await tester.pump();
    expect(tester.widget<TextField>(passwordInput).obscureText, isFalse);
    expect(DemoAuth.registeredUsername, isNull);
  });

  test(
    'failed login and registration do not authenticate; admin remains valid',
    () {
      DemoAuth.logout();
      DemoAuth.register('student', 'secret');
      expect(DemoAuth.currentUsername, isNull);
      expect(DemoAuth.login('student', 'wrong'), isFalse);
      expect(DemoAuth.currentUsername, isNull);
      expect(DemoAuth.login('admin', 'admin123'), isTrue);
      DemoAuth.logout();
      expect(DemoAuth.currentUsername, isNull);
    },
  );
}
