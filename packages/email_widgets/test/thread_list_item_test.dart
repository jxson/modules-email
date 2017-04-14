// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:email_models/fixtures.dart';
import 'package:email_models/models.dart';
import 'package:email_widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  EmailFixtures fixtures = new EmailFixtures();

  testWidgets(
      'Test to see if tapping on a ThreadListItem will call the'
      'appropiate callback with given Thread', (WidgetTester tester) async {
    Key key = new UniqueKey();
    Thread thread = fixtures.thread();

    int taps = 0;

    await tester.pumpWidget(new StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
      return new Material(
        child: new ThreadListItem(
          key: key,
          thread: thread,
          onSelect: (Thread t) {
            expect(t, thread);
            taps++;
          },
        ),
      );
    }));

    expect(taps, 0);
    await tester.tap(find.byKey(key));
    expect(taps, 1);
  });

  testWidgets(
      'Test to see if swiping right will call the appropiate archive callback '
      'with given Thread', (WidgetTester tester) async {
    Thread thread = fixtures.thread();

    int swipes = 0;

    Key threadListItemKey = new UniqueKey();

    await tester.pumpWidget(new StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
      return new Material(
        child: new ThreadListItem(
          key: threadListItemKey,
          thread: thread,
          onArchive: (Thread t) {
            expect(t, thread);
            swipes++;
          },
        ),
      );
    }));

    expect(swipes, 0);

    //Swipe Left
    await swipeDissmissable(
      tester: tester,
      key: threadListItemKey,
      direction: DismissDirection.endToStart,
    );

    expect(swipes, 1);
  });

  testWidgets(
      'Test to see if swiping left will call the appropiate archive callback '
      'with given Thread', (WidgetTester tester) async {
    Thread thread = fixtures.thread();

    int swipes = 0;

    Key threadListItemKey = new UniqueKey();

    await tester.pumpWidget(new StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
      return new Material(
        child: new ThreadListItem(
          key: threadListItemKey,
          thread: thread,
          onArchive: (Thread t) {
            expect(t, thread);
            swipes++;
          },
        ),
      );
    }));

    expect(swipes, 0);

    //Swipe Left
    await swipeDissmissable(
      tester: tester,
      key: threadListItemKey,
      direction: DismissDirection.startToEnd,
    );

    expect(swipes, 1);
  });
}
