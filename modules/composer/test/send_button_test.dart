// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:composer/models.dart';
import 'package:composer/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib.widgets/model.dart';

void main() {
  group('SendButton', () {
    testWidgets('tap', (WidgetTester tester) async {
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
          child: new Material(child: new SendButton()),
        ),
      );

      await tester.pumpWidget(app);
      await tester.idle();

      Finder finder = find.byType(RaisedButton);
      expect(finder, findsOneWidget);
      await tester.tap(finder);
      await tester.idle();

      expect(sent, isTrue, reason: 'should trigger sent');
    });
  });
}
