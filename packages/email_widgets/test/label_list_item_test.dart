// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:email_models/models.dart';
import 'package:email_widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'Test to see if tapping on a LabelListItem will call the'
      'appropiate callback with given Label', (WidgetTester tester) async {
    Key folderListItemKey = new UniqueKey();
    Label label = new Label(name: 'Inbox');

    int taps = 0;

    await tester.pumpWidget(new StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
      return new Material(
        child: new LabelListItem(
          key: folderListItemKey,
          label: label,
          onSelect: (Label f) {
            expect(f, label);
            taps++;
          },
        ),
      );
    }));

    expect(taps, 0);
    await tester.tap(find.byKey(folderListItemKey));
    expect(taps, 1);
  });

  testWidgets(
      'Test to see if an icon from the LabelIdToIcon mapping is used if no '
      'folder icon is explicity given and icon is of type system',
      (WidgetTester tester) async {
    Key folderListItemKey = new UniqueKey();
    Label label = new Label(
      name: 'Inbox',
      type: 'system',
      id: 'INBOX',
    );

    await tester.pumpWidget(new StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
      return new Material(
        child: new LabelListItem(
          key: folderListItemKey,
          label: label,
        ),
      );
    }));

    expect(
        find.byWidgetPredicate(
            (Widget widget) => widget is Icon && widget.icon == Icons.inbox),
        findsOneWidget);
  });

  testWidgets(
      'Test to see if a default folder icon is used if there is no '
      'LabelToIcon mapping, no folder icon is explicity given and folder is '
      'of type system', (WidgetTester tester) async {
    Key folderListItemKey = new UniqueKey();
    Label label = new Label(
      name: 'Junk',
      type: 'system',
      id: 'JUNK',
    );

    await tester.pumpWidget(new StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
      return new Material(
        child: new LabelListItem(
          key: folderListItemKey,
          label: label,
        ),
      );
    }));

    expect(
        find.byWidgetPredicate(
            (Widget widget) => widget is Icon && widget.icon == Icons.folder),
        findsOneWidget);
  });

  testWidgets(
      'Test to see if default folder icon is folder is not of type system and '
      'no folder icon is explicity given', (WidgetTester tester) async {
    Key folderListItemKey = new UniqueKey();
    Label label = new Label(
      name: 'Inbox',
      type: 'system',
      id: 'INBOX',
    );

    await tester.pumpWidget(new StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
      return new Material(
        child: new LabelListItem(
          key: folderListItemKey,
          label: label,
        ),
      );
    }));

    expect(
        find.byWidgetPredicate(
            (Widget widget) => widget is Icon && widget.icon == Icons.inbox),
        findsOneWidget);
  });
}
