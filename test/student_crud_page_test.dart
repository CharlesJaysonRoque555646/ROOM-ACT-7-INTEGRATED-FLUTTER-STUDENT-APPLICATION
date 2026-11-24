// Firestore interfaces are implemented only by these isolated test doubles.
// ignore_for_file: subtype_of_sealed_class, must_be_immutable

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roque_navigation_app/student_crud_page.dart';

// Isolated test double: these tests do not contact Firebase or verify its rules.
class MemoryStudents implements CollectionReference<Map<String, dynamic>> {
  final records = <String, Map<String, dynamic>>{};
  final changes =
      StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
  int nextId = 0;
  int writes = 0;
  Completer<void>? writeGate;
  FirebaseException? writeError;

  QuerySnapshot<Map<String, dynamic>> snapshot() => MemorySnapshot([
    for (final entry in records.entries)
      MemoryRecord(entry.key, Map.of(entry.value)),
  ]);

  Future<void> write(void Function() operation) async {
    writes++;
    final gate = writeGate;
    writeGate = null;
    if (gate != null) await gate.future;
    if (writeError != null) throw writeError!;
    operation();
    changes.add(snapshot());
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) async* {
    yield snapshot();
    yield* changes.stream;
  }

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      MemoryDocument(this, path ?? 'student-${nextId++}');

  @override
  Future<DocumentReference<Map<String, dynamic>>> add(
    Map<String, dynamic> data,
  ) async {
    final reference = doc();
    await write(() => records[reference.id] = Map.of(data));
    return reference;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MemoryDocument implements DocumentReference<Map<String, dynamic>> {
  MemoryDocument(this.owner, this.id);
  final MemoryStudents owner;
  @override
  final String id;

  @override
  Future<void> update(Map<Object, Object?> data) => owner.write(() {
    if (!owner.records.containsKey(id)) {
      throw FirebaseException(plugin: 'cloud_firestore', code: 'not-found');
    }
    owner.records[id]!.addAll(data.cast<String, dynamic>());
  });

  @override
  Future<void> delete() => owner.write(() => owner.records.remove(id));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MemorySnapshot implements QuerySnapshot<Map<String, dynamic>> {
  MemorySnapshot(this.docs);
  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MemoryRecord implements QueryDocumentSnapshot<Map<String, dynamic>> {
  MemoryRecord(this.id, this.value);
  @override
  final String id;
  final Map<String, dynamic> value;
  @override
  Map<String, dynamic> data() => value;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Finder input(String label) => find.widgetWithText(TextFormField, label);
Finder action(String label) => find.widgetWithText(ElevatedButton, label);
Finder rowAction(String id, String tooltip) => find.descendant(
  of: find.byKey(ValueKey(id)),
  matching: find.byTooltip(tooltip),
);

Future<void> openPage(WidgetTester tester, MemoryStudents students) async {
  tester.view.physicalSize = const Size(1000, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(home: StudentCrudPage(studentCollection: students)),
  );
  await tester.pumpAndSettle();
}

Future<void> addStudent(WidgetTester tester, String name, String course) async {
  await tester.enterText(input('Student Name'), name);
  await tester.enterText(input('Course'), course);
  await tester.tap(action('Add Student'));
  await tester.pumpAndSettle();
}

void main() {
  late MemoryStudents students;
  setUp(() => students = MemoryStudents());

  testWidgets('Lab 9 opens the form and empty record list', (tester) async {
    await openPage(tester, students);
    expect(find.text('Student Records'), findsOneWidget);
    expect(input('Student Name'), findsOneWidget);
    expect(input('Course'), findsOneWidget);
    expect(find.text('No student records yet.'), findsOneWidget);
    expect(students.writes, 0);
  });

  testWidgets('Lab 9 rejects empty and whitespace-only fields', (tester) async {
    await openPage(tester, students);
    for (final text in ['', '   ']) {
      await addStudent(tester, text, text);
      expect(find.text('This field is required.'), findsNWidgets(2));
      expect(students.records, isEmpty);
      expect(students.writes, 0);
    }
  });

  testWidgets('Lab 9 enforces the 80 character limit on both fields', (
    tester,
  ) async {
    await openPage(tester, students);
    await addStudent(tester, 'A' * 81, 'B' * 81);
    expect(find.text('Use no more than 80 characters.'), findsNWidgets(2));
    expect(students.writes, 0);
    await addStudent(tester, 'A' * 80, 'B' * 80);
    expect(students.records.length, 1);
    expect(students.records.values.single['name'], 'A' * 80);
  });

  testWidgets('Lab 9 creates three distinct documents and trims input', (
    tester,
  ) async {
    await openPage(tester, students);
    await addStudent(tester, '  Alex Santos  ', ' BSIT ');
    await addStudent(tester, 'Jamie Cruz', 'BSCS');
    await addStudent(tester, 'Morgan Reyes', 'BSIS');
    expect(students.records.length, 3);
    expect(students.records.values.first, {
      'name': 'Alex Santos',
      'course': 'BSIT',
    });
    for (final name in ['Alex Santos', 'Jamie Cruz', 'Morgan Reyes']) {
      expect(find.text(name), findsOneWidget);
    }
    expect(
      tester.widget<TextFormField>(input('Student Name')).controller!.text,
      '',
    );
    expect(tester.widget<TextFormField>(input('Course')).controller!.text, '');
  });

  testWidgets('Lab 9 editing fills values and updates the same document', (
    tester,
  ) async {
    students.records['alex'] = {'name': 'Alex Santos', 'course': 'BSIT'};
    await openPage(tester, students);
    await tester.tap(rowAction('alex', 'Edit'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextFormField>(input('Student Name')).controller!.text,
      'Alex Santos',
    );
    expect(
      tester.widget<TextFormField>(input('Course')).controller!.text,
      'BSIT',
    );
    await tester.enterText(input('Course'), 'BSCS');
    await tester.tap(action('Update Student'));
    await tester.pumpAndSettle();
    expect(students.records.keys, ['alex']);
    expect(students.records['alex']!['course'], 'BSCS');
    expect(find.text('BSIT'), findsNothing);
    expect(find.text('BSCS'), findsOneWidget);
    expect(action('Add Student'), findsOneWidget);
  });

  testWidgets('Lab 9 cancel edit clears the form without writing', (
    tester,
  ) async {
    students.records['alex'] = {'name': 'Alex Santos', 'course': 'BSIT'};
    await openPage(tester, students);
    await tester.tap(rowAction('alex', 'Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(input('Course'), 'BSCS');
    await tester.tap(find.text('Cancel Edit'));
    await tester.pumpAndSettle();
    expect(action('Add Student'), findsOneWidget);
    expect(find.text('Cancel Edit'), findsNothing);
    expect(tester.widget<TextFormField>(input('Course')).controller!.text, '');
    expect(students.records['alex']!['course'], 'BSIT');
    expect(students.writes, 0);
  });

  testWidgets('Lab 9 cancel and confirm deletion target the correct ID', (
    tester,
  ) async {
    students.records['jamie'] = {'name': 'Jamie Cruz', 'course': 'BSCS'};
    students.records['other-jamie'] = {'name': 'Jamie Cruz', 'course': 'BSIT'};
    await openPage(tester, students);
    await tester.tap(rowAction('jamie', 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete Jamie Cruz?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(students.records.length, 2);
    expect(students.writes, 0);
    await tester.tap(rowAction('jamie', 'Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(students.records.keys, ['other-jamie']);
    expect(find.byKey(const ValueKey('jamie')), findsNothing);
    expect(find.byKey(const ValueKey('other-jamie')), findsOneWidget);
  });

  testWidgets('Lab 9 deleting an edited record resets Add Student mode', (
    tester,
  ) async {
    students.records['alex'] = {'name': 'Alex Santos', 'course': 'BSIT'};
    await openPage(tester, students);
    await tester.tap(rowAction('alex', 'Edit'));
    await tester.pumpAndSettle();
    await tester.tap(rowAction('alex', 'Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(students.records, isEmpty);
    expect(action('Add Student'), findsOneWidget);
    expect(find.text('Cancel Edit'), findsNothing);
  });

  testWidgets('Lab 9 receives external changes through the stream', (
    tester,
  ) async {
    await openPage(tester, students);
    students.records['morgan'] = {'name': 'Morgan Reyes', 'course': 'BSIS'};
    students.changes.add(students.snapshot());
    await tester.pumpAndSettle();
    expect(find.text('Morgan Reyes'), findsOneWidget);
    students.records['morgan']!['course'] = 'BSIT';
    students.changes.add(students.snapshot());
    await tester.pumpAndSettle();
    expect(find.text('BSIT'), findsOneWidget);
    students.records.clear();
    students.changes.add(students.snapshot());
    await tester.pumpAndSettle();
    expect(find.text('No student records yet.'), findsOneWidget);
  });

  testWidgets('Lab 9 leaving and reopening reloads saved records', (
    tester,
  ) async {
    await openPage(tester, students);
    await addStudent(tester, 'Morgan Reyes', 'BSIS');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      MaterialApp(home: StudentCrudPage(studentCollection: students)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Morgan Reyes'), findsOneWidget);
    expect(find.text('BSIS'), findsOneWidget);
  });

  testWidgets(
    'Lab 9 disables controls while saving and prevents duplicate writes',
    (tester) async {
      await openPage(tester, students);
      final gate = Completer<void>();
      students.writeGate = gate;
      await tester.enterText(input('Student Name'), 'Alex Santos');
      await tester.enterText(input('Course'), 'BSIT');
      await tester.tap(action('Add Student'));
      await tester.pump();
      expect(action('Saving...'), findsOneWidget);
      expect(
        tester.widget<ElevatedButton>(action('Saving...')).onPressed,
        isNull,
      );
      expect(
        tester.widget<TextFormField>(input('Student Name')).enabled,
        isFalse,
      );
      expect(students.writes, 1);
      gate.complete();
      await tester.pumpAndSettle();
      expect(students.records.length, 1);
      expect(action('Add Student'), findsOneWidget);
    },
  );

  testWidgets('Lab 9 save failure keeps input and restores controls', (
    tester,
  ) async {
    await openPage(tester, students);
    students.writeError = FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
    );
    await addStudent(tester, 'Alex Santos', 'BSIT');
    expect(find.text('Save failed: permission-denied'), findsOneWidget);
    expect(students.records, isEmpty);
    expect(
      tester.widget<TextFormField>(input('Student Name')).controller!.text,
      'Alex Santos',
    );
    expect(
      tester.widget<ElevatedButton>(action('Add Student')).onPressed,
      isNotNull,
    );
  });

  testWidgets(
    'Lab 9 read and delete failures show errors without losing data',
    (tester) async {
      students.records['alex'] = {'name': 'Alex Santos', 'course': 'BSIT'};
      await openPage(tester, students);
      students.writeError = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
      await tester.tap(rowAction('alex', 'Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Delete failed: permission-denied'), findsOneWidget);
      expect(students.records.length, 1);
      students.changes.addError(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Unable to load records. Check your connection and database rules.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('Lab 9 works at phone width without layout errors', (
    tester,
  ) async {
    await openPage(tester, students);
    tester.view.physicalSize = const Size(430, 932);
    await tester.pumpAndSettle();
    await addStudent(tester, 'Alex Santos', 'BSIT');
    expect(find.text('Alex Santos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
