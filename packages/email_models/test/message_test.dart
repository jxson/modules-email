// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:convert';

import 'package:email_models/fixtures.dart';
import 'package:email_models/models.dart';
import 'package:test/test.dart';

void main() {
  EmailFixtures fixtures = new EmailFixtures();

  test('Message JSON encode/decode', () {
    Message message = fixtures.message();
    String encoded = JSON.encode(message);
    Map<String, dynamic> json = JSON.decode(encoded);
    Message hydrated = new Message.fromJson(json);

    expect(hydrated.id, equals(message.id));
    expect(hydrated.threadId, equals(message.threadId));
    expect(hydrated.sender.address, equals(message.sender.address));
    expect(hydrated.sender.displayName, equals(message.sender.displayName));
    expect(hydrated.senderProfileUrl, equals(message.senderProfileUrl));
    expect(hydrated.subject, equals(message.subject));
    expect(hydrated.text, equals(message.text));
    expect(hydrated.timestamp, equals(message.timestamp));
    expect(hydrated.isRead, equals(message.isRead));
    expect(hydrated.links, equals(message.links));

    for (int i = 0; i < hydrated.recipientList.length; i++) {
      Mailbox actual = hydrated.recipientList[i];
      Mailbox expected = message.recipientList[i];
      expect(actual.address, equals(expected.address));
      expect(actual.displayName, equals(expected.displayName));
    }

    for (int i = 0; i < hydrated.ccList.length; i++) {
      Mailbox actual = hydrated.ccList[i];
      Mailbox expected = message.ccList[i];
      expect(actual.address, equals(expected.address));
      expect(actual.displayName, equals(expected.displayName));
    }

    for (int i = 0; i < hydrated.attachments.length; i++) {
      Attachment actual = hydrated.attachments[i];
      Attachment expected = message.attachments[i];
      expect(actual.id, equals(expected.id));
    }
  });

  test('.generateSnippet() should return text of message', () {
    String messageText = 'Puppies in Paris';
    Message message = new Message(text: messageText);
    expect(message.snippet, messageText);
  });

  test('.generateSnippet() should strip newline characters of message', () {
    String messageText = 'Puppies\nin Paris';
    Message message = new Message(text: messageText);
    expect(message.snippet, 'Puppies in Paris');
  });
}
