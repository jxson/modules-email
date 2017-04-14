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
      'Test to see if tapping on a Message inside a ThreadView will call the'
      'appropiate callback with given Message', (WidgetTester tester) async {
    Thread thread = fixtures.thread();

    int taps = 0;

    void testSelectedMessage(Message message) {
      expect(message, thread.messages[message.id]);
      taps++;
    }

    await tester.pumpWidget(new StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
      return buildThreadView(thread: thread, onSelect: testSelectedMessage);
    }));

    expect(taps, 0);
    await tester.tap(find.byType(MessageListItem).first);
    expect(taps, 1);
  });

  testWidgets(
      'Test to make sure that ThreadView will render a MessageListItem for every '
      'message in the thread', (WidgetTester tester) async {
    Thread thread = fixtures.thread();

    await tester.pumpWidget(new StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
      return buildThreadView(thread: thread);
    }));

    expect(find.byType(MessageListItem), findsNWidgets(thread.messages.length));
  });

  testWidgets('Test to see the footer widget will be rendered if given',
      (WidgetTester tester) async {
    Thread thread = fixtures.thread();

    await tester.pumpWidget(new StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
      return buildThreadView(thread: thread);
    }));

    expect(find.byType(MessageActionBarFooter), findsOneWidget);
  });

  testWidgets('Test to see the header widget will be rendered if given',
      (WidgetTester tester) async {
    Thread thread = fixtures.thread();

    await tester.pumpWidget(new StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
      return buildThreadView(thread: thread);
    }));

    expect(find.byType(ThreadActionBarHeader), findsOneWidget);
  });
}
