// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:email_models/fixtures.dart';
import 'package:email_models/models.dart';
import 'package:email_widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  EmailFixtures fixtures = new EmailFixtures();

  testWidgets('Header actions', (WidgetTester tester) async {
    Thread thread = fixtures.thread();

    int archiveTaps = 0;
    int deleteTaps = 0;
    int moreActionsTaps = 0;

    await tester.pumpWidget(new StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
      return new Material(
        child: new ThreadActionBarHeader(
          thread: thread,
          onArchive: (Thread t) {
            expect(t, thread);
            archiveTaps++;
          },
          onDelete: (Thread t) {
            expect(t, thread);
            deleteTaps++;
          },
          onMoreActions: (Thread t) {
            expect(t, thread);
            moreActionsTaps++;
          },
        ),
      );
    }));

    expect(archiveTaps, 0);
    expect(deleteTaps, 0);
    expect(moreActionsTaps, 0);
    await tester.tap(find.byWidgetPredicate(
        (Widget widget) => widget is Icon && widget.icon == Icons.archive));
    expect(archiveTaps, 1);
    expect(deleteTaps, 0);
    expect(moreActionsTaps, 0);
    await tester.tap(find.byWidgetPredicate(
        (Widget widget) => widget is Icon && widget.icon == Icons.delete));
    expect(archiveTaps, 1);
    expect(deleteTaps, 1);
    expect(moreActionsTaps, 0);
    await tester.tap(find.byWidgetPredicate(
        (Widget widget) => widget is Icon && widget.icon == Icons.more_vert));
    expect(archiveTaps, 1);
    expect(deleteTaps, 1);
    expect(moreActionsTaps, 1);
  });
}
