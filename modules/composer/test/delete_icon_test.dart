// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:composer/models.dart';
import 'package:composer/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib.widgets/model.dart';

void main() {
  group('DeleteIcon', () {
    testWidgets('tap', (WidgetTester tester) async {
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
          child: new Material(child: new DeleteIcon()),
        ),
      );

      await tester.pumpWidget(app);
      await tester.idle();

      Finder finder = find.byTooltip('Delete draft.');
      expect(finder, findsOneWidget);
      await tester.tap(finder);
      await tester.idle();

      expect(deleted, isTrue, reason: 'should trigger delete');
    });
  });
}
