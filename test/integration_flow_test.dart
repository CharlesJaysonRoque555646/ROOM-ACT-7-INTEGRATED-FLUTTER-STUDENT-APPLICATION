import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roque_navigation_app/demo_auth.dart';
import 'package:roque_navigation_app/login_screen.dart';
import 'package:roque_navigation_app/main_screen.dart';
import 'package:roque_navigation_app/social_media/post_card.dart';

import 'social_feed_test.dart' as support;

Future<void> selectTab(WidgetTester tester, int index) async {
  await tester.tap(find.byType(NavigationDestination).at(index));
  await tester.pumpAndSettle();
}

Future<void> addComment(WidgetTester tester) async {
  final card = find.byType(PostCard).first;
  await tester.tap(find.descendant(of: card, matching: find.text('Like')));
  await tester.enterText(
    find.descendant(of: card, matching: find.byType(TextField)),
    'Great activity!',
  );
  await tester.tap(
    find.descendant(of: card, matching: find.byTooltip('Send comment')),
  );
  await tester.pumpAndSettle();
}

Future<void> registerAndLogin(WidgetTester tester) async {
  await tester.tap(find.text("Don't have an account? Register"));
  await tester.pumpAndSettle();
  await support.capture(tester, 'integration/02_register');
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
  expect(find.byType(LoginScreen), findsOneWidget);
  await support.login(tester, 'Scyla', 'secret');
}

void main() {
  testWidgets('Integration 01 application starts on Login', (tester) async {
    await support.startApp(tester);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(MainScreen), findsNothing);
    await support.capture(tester, 'integration/01_login');
  });

  testWidgets('Integration 02 empty login fields show validation', (
    tester,
  ) async {
    await support.startApp(tester);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your username.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
  });

  testWidgets('Integration 03 incorrect credentials are rejected', (
    tester,
  ) async {
    await support.startApp(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'admin',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'incorrect',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();
    expect(find.text('Invalid username or password.'), findsOneWidget);
    expect(find.byType(MainScreen), findsNothing);
    expect(DemoAuth.currentUsername, isNull);
  });

  testWidgets('Integration 04 admin opens Dashboard in correct tab order', (
    tester,
  ) async {
    await support.startApp(tester);
    await support.login(tester);
    expect(find.byType(MainScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    final items = tester.widgetList<NavigationDestination>(
      find.byType(NavigationDestination),
    );
    expect(items.map((item) => item.label).toList(), [
      'Dashboard',
      'Calculator',
      'Social',
      'Profile',
    ]);
    expect(find.widgetWithText(AppBar, 'Dashboard'), findsOneWidget);
  });

  testWidgets('Integration 05 Dashboard shows current username', (
    tester,
  ) async {
    await support.startApp(tester);
    await support.login(tester);
    expect(find.text('Welcome, admin!'), findsOneWidget);
    await support.capture(tester, 'integration/03_dashboard');
  });

  testWidgets('Integration 06 calculator 10 plus 5 is 15.0', (tester) async {
    await support.startApp(tester);
    await support.login(tester);
    await selectTab(tester, 1);
    await tester.enterText(
      find.widgetWithText(TextField, 'First Number'),
      '10',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Second Number'),
      '5',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, '+'));
    await tester.pump();
    expect(find.text('15.0'), findsOneWidget);
    await support.capture(tester, 'integration/04_calculator');
  });

  testWidgets(
    'Integration 07 calculator inputs and result survive tab switches',
    (tester) async {
      await support.startApp(tester);
      await support.login(tester);
      await selectTab(tester, 1);
      await tester.enterText(
        find.widgetWithText(TextField, 'First Number'),
        '10',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Second Number'),
        '5',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, '+'));
      await tester.pump();
      await selectTab(tester, 0);
      await selectTab(tester, 1);
      expect(find.text('15.0'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'First Number'))
            .controller!
            .text,
        '10',
      );
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Second Number'))
            .controller!
            .text,
        '5',
      );
    },
  );

  testWidgets('Integration 08 created post has current username', (
    tester,
  ) async {
    await support.startApp(tester);
    await support.login(tester);
    await selectTab(tester, 2);
    await support.capture(tester, 'integration/05_social');
    await support.createPost(tester, 'My integrated Flutter app!');
    expect(
      tester.widget<PostCard>(find.byType(PostCard).first).post.username,
      'admin',
    );
  });

  testWidgets('Integration 09 like and comment update correctly', (
    tester,
  ) async {
    await support.startApp(tester);
    await support.login(tester);
    await selectTab(tester, 2);
    await support.createPost(tester, 'My integrated Flutter app!');
    await addComment(tester);
    expect(find.text('Liked'), findsOneWidget);
    expect(find.text('Great activity!'), findsOneWidget);
    expect(find.text('1 Comments'), findsOneWidget);
    await support.capture(tester, 'integration/07_social_interactions');
  });

  testWidgets('Integration 10 Social state survives tab switches', (
    tester,
  ) async {
    await support.startApp(tester);
    await support.login(tester);
    await selectTab(tester, 2);
    await support.createPost(tester, 'Keep this post');
    await addComment(tester);
    await selectTab(tester, 0);
    await selectTab(tester, 3);
    await selectTab(tester, 2);
    expect(find.text('Keep this post'), findsOneWidget);
    expect(find.text('Liked'), findsOneWidget);
    expect(find.text('Great activity!'), findsOneWidget);
  });

  testWidgets('Integration 11 Profile shows student information and session', (
    tester,
  ) async {
    await support.startApp(tester);
    await support.login(tester);
    await selectTab(tester, 3);
    expect(find.text('Charles Jayson R Roque'), findsOneWidget);
    expect(find.text('Student No. 555646'), findsOneWidget);
    expect(find.text('BSIT'), findsOneWidget);
    expect(find.text('3447'), findsOneWidget);
    expect(find.text('c.roque.555646@umindanao.edu.ph'), findsOneWidget);
    expect(find.text('Logged in as: admin'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Logout'), findsOneWidget);
    await support.capture(tester, 'integration/06_profile');
  });

  testWidgets('Integration 12 Profile logout clears username and routes', (
    tester,
  ) async {
    await support.startApp(tester);
    await support.login(tester);
    await selectTab(tester, 3);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Logout'));
    await tester.pumpAndSettle();
    expect(DemoAuth.currentUsername, isNull);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(MainScreen), findsNothing);
    expect(
      Navigator.of(tester.element(find.byType(LoginScreen))).canPop(),
      isFalse,
    );
  });

  testWidgets(
    'Integration 13 registered account changes Dashboard and Profile username',
    (tester) async {
      await support.startApp(tester);
      await registerAndLogin(tester);
      expect(find.text('Welcome, Scyla!'), findsOneWidget);
      await selectTab(tester, 3);
      expect(find.text('Logged in as: Scyla'), findsOneWidget);
      expect(find.text('Charles Jayson R Roque'), findsOneWidget);
    },
  );

  testWidgets('Integration 14 registered account authors posts', (
    tester,
  ) async {
    await support.startApp(tester);
    await registerAndLogin(tester);
    await selectTab(tester, 2);
    await support.createPost(tester, 'A registered account post');
    expect(
      tester.widget<PostCard>(find.byType(PostCard).first).post.username,
      'Scyla',
    );
  });

  testWidgets(
    'Integration calculator operations validation zero division and Clear',
    (tester) async {
      await support.startApp(tester);
      await support.login(tester);
      await selectTab(tester, 1);
      await tester.tap(find.widgetWithText(ElevatedButton, '+'));
      await tester.pump();
      expect(find.text('Invalid input'), findsOneWidget);
      final first = find.widgetWithText(TextField, 'First Number');
      final second = find.widgetWithText(TextField, 'Second Number');
      await tester.enterText(first, '20');
      await tester.enterText(second, '5');
      for (final entry in {
        '+': '25.0',
        '\u2212': '15.0',
        '\u00d7': '100.0',
        '\u00f7': '4.0',
      }.entries) {
        await tester.tap(find.widgetWithText(ElevatedButton, entry.key));
        await tester.pump();
        expect(find.text(entry.value), findsOneWidget);
      }
      await tester.enterText(second, '0');
      await tester.tap(find.widgetWithText(ElevatedButton, '\u00f7'));
      await tester.pump();
      expect(find.text('Cannot divide by zero'), findsOneWidget);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Clear'));
      await tester.pump();
      expect(tester.widget<TextField>(first).controller!.text, isEmpty);
      expect(tester.widget<TextField>(second).controller!.text, isEmpty);
      expect(find.text('0'), findsOneWidget);
    },
  );
}
