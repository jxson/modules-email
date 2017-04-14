// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:convert';

import 'package:email_models/fixtures.dart';
import 'package:email_models/models.dart';
import 'package:models/user.dart';
import 'package:test/test.dart';

void main() {
  EmailFixtures fixtures = new EmailFixtures();

  group('thread.subject', () {
    User sender = fixtures.user(name: 'Coco Yang');
    List<User> to = <User>[fixtures.user(name: 'David Yang')];
    String subject = 'PLEAZE Feed Me!!!';

    test('populated message subject', () {
      Thread thread = fixtures.thread(<Message>[
        fixtures.message(
          sender: sender,
          to: to,
          timestamp: fixtures.timestamp(),
        ),
        fixtures.message(
          sender: sender,
          to: to,
          timestamp: fixtures.timestamp() + 500,
          subject: subject,
        ),
      ]);

      expect(thread.subject, subject);
    });

    test('null message subject', () {
      Thread thread = fixtures.thread(<Message>[
        fixtures.message(
            sender: sender,
            to: to,
            subject: null,
            text: 'Woof Woof. I\'m so hungry. You need to feed me!'),
      ]);

      expect(thread.subject, '(No Subject)');
    });

    test('empty message subject', () {
      Thread thread = fixtures.thread(<Message>[
        fixtures.message(
            sender: sender,
            to: to,
            subject: '',
            text: 'Woof Woof. I\'m so hungry. You need to feed me!'),
      ]);

      expect(thread.subject, '(No Subject)');
    });
  });

  group('JSON encode/decode', () {
    EmailFixtures fixtures = new EmailFixtures();

    test('message with attachments', () {
      User coco = fixtures.user(name: 'Coco Yang');
      User david = fixtures.user(name: 'David Yang');
      User jason = fixtures.user(name: 'Jason C');
      int timestamp = fixtures.timestamp();
      Message message = fixtures.message(
        sender: coco,
        to: <User>[david],
        cc: <User>[jason],
        text: "Woof Woof. I'm so hungry. You need to feed me!",
        timestamp: timestamp,
        isRead: true,
        attachments: <Attachment>[
          fixtures.attachment(
            type: AttachmentType.youtubeVideo,
          ),
        ],
      );
      Thread thread = fixtures.thread(<Message>[message]);

      String payload = JSON.encode(thread);
      Map<String, dynamic> json = JSON.decode(payload);
      Thread hydrated = new Thread.fromJson(json);

      expect(hydrated.id, equals(thread.id));
      expect(hydrated.snippet, equals(thread.snippet));
      expect(hydrated.historyId, equals(thread.historyId));

      Message hydratedMessage = hydrated.messages[message.id];
      expect(hydratedMessage, isNotNull);
      expect(hydratedMessage.sender.displayName, equals(coco.name));
      expect(hydratedMessage.sender.address, equals(coco.email));
      expect(hydratedMessage.text,
          equals("Woof Woof. I'm so hungry. You need to feed me!"));
      expect(hydratedMessage.timestamp, equals(timestamp));
      expect(hydratedMessage.isRead, isTrue);

      Attachment attachment = hydratedMessage.attachments[0];
      expect(attachment, isNotNull);
      expect(attachment.type, equals(AttachmentType.youtubeVideo));

      Mailbox to = message.recipientList[0];
      expect(to, isNotNull);
      expect(to.displayName, equals(david.name));
      expect(to.address, equals(david.email));

      Mailbox cc = message.ccList[0];
      expect(cc, isNotNull);
      expect(cc.displayName, equals(jason.name));
      expect(cc.address, equals(jason.email));
    });
  });
}
