// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:composer/models.dart';
import 'package:composer/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib.widgets/model.dart';

void main() {
  group('ComposerScaffold => AppBar', () {
    testWidgets('tap "Close" icon', (WidgetTester tester) async {
      bool closed = false;
      ComposerModel model = new ComposerModel(
        onDelete: () {},
        onClose: () => closed = true,
        onSend: () {},
        onUpdate: (Message m) {},
      );
      MaterialApp app = new MaterialApp(
        home: new ScopedModel<ComposerModel>(
          model: model,
          child: new ComposerScaffold(),
        ),
      );

      await tester.pumpWidget(app);
      await tester.idle();

      Finder finder = find.descendant(
        of: find.byType(AppBar),
        matching: find.byTooltip('Close module.'),
      );
      expect(finder, findsOneWidget);
      await tester.tap(finder);
      await tester.idle();

      expect(closed, isTrue, reason: 'should trigger close');
    });
  });

  group('ComposerScaffold #bottomNavigationBar', () {
    testWidgets('tap "Send" button', (WidgetTester tester) async {
      bool sent = false;
      ComposerModel model = new ComposerModel(
        onDelete: () {},
        onClose: () {},
        onSend: () => sent = true,
        onUpdate: (Message m) {},
      );
      MaterialApp app = new MaterialApp(
        home: new ScopedModel<ComposerModel>(
          model: model,
          child: new ComposerScaffold(),
        ),
      );

      await tester.pumpWidget(app);
      await tester.idle();

      Finder finder = find.descendant(
        of: find.byType(ButtonBar),
        matching: find.byType(SendButton),
      );

      expect(finder, findsOneWidget);
      await tester.tap(finder);
      await tester.idle();

      expect(sent, isTrue, reason: 'should trigger sent');
    });

    testWidgets('tap "Delete" icon', (WidgetTester tester) async {
      bool deleted = false;
      ComposerModel model = new ComposerModel(
        onDelete: () => deleted = true,
        onClose: () {},
        onSend: () {},
        onUpdate: (Message m) {},
      );
      MaterialApp app = new MaterialApp(
        home: new ScopedModel<ComposerModel>(
          model: model,
          child: new ComposerScaffold(),
        ),
      );

      await tester.pumpWidget(app);
      await tester.idle();

      Finder finder = find.descendant(
        of: find.byType(ButtonBar),
        matching: find.byType(DeleteIcon),
      );

      expect(finder, findsOneWidget);
      await tester.tap(finder);
      await tester.idle();

      expect(deleted, isTrue, reason: 'should trigger delete');
    });
  });
}
