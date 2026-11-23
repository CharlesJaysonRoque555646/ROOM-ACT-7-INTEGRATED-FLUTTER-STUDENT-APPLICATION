import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roque_navigation_app/demo_auth.dart';
import 'package:roque_navigation_app/login_screen.dart';
import 'package:roque_navigation_app/main_screen.dart';
import 'package:roque_navigation_app/social_media/create_post_sheet.dart';
import 'package:roque_navigation_app/social_media/post_card.dart';

import 'integration_flow_test.dart' show selectTab;
import 'social_feed_test.dart' as support;

Finder field(String label) => find.widgetWithText(TextFormField, label);

Finder input(String label) =>
    find.descendant(of: field(label), matching: find.byType(TextField));

void main() {
  testWidgets('Activity login visibility and keyboard submit work', (
    tester,
  ) async {
    await support.startApp(tester);
    expect(tester.widget<TextField>(input('Password')).obscureText, isTrue);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(tester.widget<TextField>(input('Password')).obscureText, isFalse);
    await tester.tap(find.byTooltip('Hide password'));
    await tester.pump();
    expect(tester.widget<TextField>(input('Password')).obscureText, isTrue);
    await tester.enterText(field('Username'), '  admin  ');
    await tester.enterText(field('Password'), 'admin123');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.byType(MainScreen), findsOneWidget);
    expect(DemoAuth.currentUsername, 'admin');
  });

  testWidgets('Activity registration visibility controls are independent', (
    tester,
  ) async {
    await support.startApp(tester);
    await tester.tap(find.text("Don't have an account? Register"));
    await tester.pumpAndSettle();
    for (final label in ['Password', 'Confirm Password']) {
      expect(tester.widget<TextField>(input(label)).obscureText, isTrue);
      await tester.tap(
        find.descendant(of: field(label), matching: find.byType(IconButton)),
      );
      await tester.pump();
      expect(tester.widget<TextField>(input(label)).obscureText, isFalse);
    }
    await tester.tap(
      find.descendant(of: field('Password'), matching: find.byType(IconButton)),
    );
    await tester.pump();
    expect(tester.widget<TextField>(input('Password')).obscureText, isTrue);
    expect(
      tester.widget<TextField>(input('Confirm Password')).obscureText,
      isFalse,
    );
  });

  testWidgets(
    'Activity empty registration and Back preserve logged-out state',
    (tester) async {
      await support.startApp(tester);
      await tester.tap(find.text("Don't have an account? Register"));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
      await tester.pumpAndSettle();
      expect(find.text('Use at least 3 characters.'), findsOneWidget);
      expect(find.text('Enter a password.'), findsOneWidget);
      expect(find.text('Confirm your password.'), findsOneWidget);
      expect(DemoAuth.registeredUsername, isNull);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(DemoAuth.currentUsername, isNull);
    },
  );

  testWidgets('Activity calculator accepts decimals negatives and whitespace', (
    tester,
  ) async {
    await support.startApp(tester);
    await support.login(tester);
    await selectTab(tester, 1);
    await tester.enterText(
      find.widgetWithText(TextField, 'First Number'),
      '  -2.5  ',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Second Number'),
      '0.5',
    );
    for (final entry in {
      '+': '-2.0',
      '\u2212': '-3.0',
      '\u00d7': '-1.25',
      '\u00f7': '-5.0',
    }.entries) {
      await tester.tap(find.widgetWithText(ElevatedButton, entry.key));
      await tester.pump();
      expect(find.text(entry.value), findsOneWidget);
    }
  });

  testWidgets('Activity calculator rejects text and non-finite numbers', (
    tester,
  ) async {
    await support.startApp(tester);
    await support.login(tester);
    await selectTab(tester, 1);
    await tester.enterText(
      find.widgetWithText(TextField, 'Second Number'),
      '5',
    );
    for (final value in ['abc', 'NaN', 'Infinity', '-Infinity']) {
      await tester.enterText(
        find.widgetWithText(TextField, 'First Number'),
        value,
      );
      await tester.tap(find.widgetWithText(ElevatedButton, '+'));
      await tester.pump();
      expect(find.text('Invalid input'), findsOneWidget);
    }
  });

  testWidgets('Activity dismissing Create Post leaves the feed unchanged', (
    tester,
  ) async {
    await support.startApp(tester);
    await support.login(tester);
    await support.openFeed(tester);
    final postsBefore = tester
        .widgetList<PostCard>(find.byType(PostCard))
        .map((card) => card.post)
        .toList();
    await support.openPostForm(tester);
    await support.fillPost(
      tester,
      'Unsubmitted post',
      'https://example.com/a.png',
    );
    Navigator.of(tester.element(find.byType(CreatePostSheet))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(CreatePostSheet), findsNothing);
    expect(find.text('Unsubmitted post'), findsNothing);
    expect(
      tester
          .widgetList<PostCard>(find.byType(PostCard))
          .map((card) => card.post),
      orderedEquals(postsBefore),
    );
  });

  testWidgets('Activity unavailable images display the fallback icon', (
    tester,
  ) async {
    await support.startApp(tester);
    await support.login(tester);
    await support.openFeed(tester);
    // Flutter widget tests intentionally return HTTP 400 for network images.
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.broken_image), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Activity navigation fits phone and desktop window sizes', (
    tester,
  ) async {
    await support.startApp(tester);
    await support.login(tester);
    for (final size in [const Size(390, 700), const Size(1366, 768)]) {
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      for (var index = 0; index < 4; index++) {
        await selectTab(tester, index);
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    }
  });
}
