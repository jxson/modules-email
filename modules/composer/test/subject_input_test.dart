// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:composer/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'Editing text in the subject input will call the onTextChange callback '
      'with the entered text', (WidgetTester tester) async {
    String enteredText = 'Fuchsia is the new Black';
    String subjectText;

    await tester.pumpWidget(new Material(
      child: new SubjectInput(
        onTextChange: (String text) {
          subjectText = text;
        },
      ),
    ));
    await tester.enterText(find.byType(EditableText), enteredText);
    await tester.idle();
    expect(enteredText, subjectText);
  });

  testWidgets('TextInput should be pre-populated with initialText',
      (WidgetTester tester) async {
    String initialText = 'Fuchsia is the new Black';

    await tester.pumpWidget(new Material(
      child: new SubjectInput(
        initialText: initialText,
      ),
    ));
    await tester.idle();
    EditableText editableText = tester.widget(find.byType(EditableText));
    expect(editableText.controller.text, initialText);
  });
}
