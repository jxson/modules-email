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

  testWidgets(
      'Test to see if tapping the header for a MessageListItem will call the'
      'appropiate callback with given Message', (WidgetTester tester) async {
    Message message = fixtures.message(
      expanded: true,
    );

    int taps = 0;

    await tester.pumpWidget(new StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
      return new Material(
        child: new MessageListItem(
          message: message,
          onForward: (Message m) {},
          onReply: (Message m) {},
          onReplyAll: (Message m) {},
          onHeaderTap: (Message m) {
            expect(m, message);
            taps++;
          },
        ),
      );
    }));

    expect(taps, 0);
    await tester.tap(find.byType(ListTile));
    expect(taps, 1);
  });

  testWidgets(
      'Test to see if tapping REPLY in the quick actions popup-menu '
      'will call the appropiate callback with given Message',
      (WidgetTester tester) async {
    Message message = fixtures.message(
      expanded: true,
    );

    int forwardTaps = 0;
    int replyTaps = 0;
    int replayAllTaps = 0;
    int moreTaps = 0;
    int headerTaps = 0;

    await tester.pumpWidget(new StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
      return new MaterialApp(
        routes: <String, WidgetBuilder>{
          '/next': (BuildContext context) {
            return new Text('Next');
          }
        },
        home: new Material(
          child: new MessageListItem(
              message: message,
              onForward: (Message m) {
                // [expect] statements currently silently fail in this callback
                // waiting on https://github.com/flutter/flutter/pull/6203
                // to get merged to Flutter which will fix this issue
                // TODO(dayang): Put back check for correct message being passed
                // through callback once Flutter issue is fixed.;
                forwardTaps++;
              },
              onReply: (Message m) {
                replyTaps++;
              },
              onReplyAll: (Message m) {
                replayAllTaps++;
              },
              onHeaderTap: (Message m) {
                m.expanded = true;
                headerTaps++;
              }),
        ),
      );
    }));

    expect(forwardTaps, 0);
    expect(headerTaps, 0);
    expect(moreTaps, 0);
    expect(replayAllTaps, 0);
    expect(replyTaps, 0);

    // Expand the message by tapping on the message's header.
    await tester.tap(find.text(message.sender.displayText));
    await tester.pump();
    expect(message.expanded, isTrue);
    expect(headerTaps, 1);

    // Open Popup Menu and tap 'Forward'
    await tester.tap(find.byWidgetPredicate(
        (Widget widget) => widget is Icon && widget.icon == Icons.more_vert));
    // finish the menu animation
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Forward'), findsOneWidget);
    await tester.tap(find.text('Forward'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(forwardTaps, 1);
    expect(replyTaps, 0);
    expect(replayAllTaps, 0);

    // Open Popup Menu and tap 'Reply'
    await tester.tap(find.byWidgetPredicate(
        (Widget widget) => widget is Icon && widget.icon == Icons.more_vert));
    // finish the menu animation
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Reply'), findsOneWidget);
    await tester.tap(find.text('Reply'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(forwardTaps, 1);
    expect(replyTaps, 1);
    expect(replayAllTaps, 0);

    // Open Popup Menu and tap 'ReplyAll'
    await tester.tap(find.byWidgetPredicate(
        (Widget widget) => widget is Icon && widget.icon == Icons.more_vert));
    // finish the menu animation
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Reply All'), findsOneWidget);
    await tester.tap(find.text('Reply All'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(forwardTaps, 1);
    expect(replyTaps, 1);
    expect(replayAllTaps, 1);
  });
}
