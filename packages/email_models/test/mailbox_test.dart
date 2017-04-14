// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:email_models/models.dart';
import 'package:test/test.dart';

void main() {
  test('fromString() should correctly parse the string into a Mailbox', () {
    <String>[
      'John Doe <john.doe@example.com>',
      '  John Doe   <john.doe@example.com>   ',
      '"John Doe" <john.doe@example.com>',
    ].forEach((String string) {
      Mailbox mailbox = new Mailbox.fromString(string);
      expect(mailbox.displayName, equals('John Doe'));
      expect(mailbox.address, equals('john.doe@example.com'));
    });

    <String>[
      'john.doe@example.com',
      '<john.doe@example.com>',
    ].forEach((String string) {
      Mailbox mailbox = new Mailbox.fromString(string);
      expect(mailbox.address, equals('john.doe@example.com'));
    });
  });

  test('toString() should show: displayName <address>', () {
    Mailbox mailbox = new Mailbox(
      displayName: 'Coco',
      address: 'coco@cu.te',
    );
    expect(mailbox.toString(), 'Coco <coco@cu.te>');
  });

  test('displayText should show displayName if it is present', () {
    Mailbox mailbox = new Mailbox(
      displayName: 'Coco',
      address: 'coco@cu.te',
    );
    expect(mailbox.displayText, 'Coco');
  });

  test('displayText should show address if displayName is not present', () {
    Mailbox mailbox = new Mailbox(
      address: 'coco@cu.te',
    );
    expect(mailbox.displayText, 'coco@cu.te');
  });

  test('Mailbox JSON encode/decode', () {
    Mailbox mailbox = new Mailbox(
      displayName: 'Coco',
      address: 'coco@cu.te',
    );

    String encoded = JSON.encode(mailbox);
    Map<String, dynamic> json = JSON.decode(encoded);
    Mailbox hydrated = new Mailbox.fromJson(json);

    expect(hydrated.displayName, equals(mailbox.displayName));
    expect(hydrated.address, equals(mailbox.address));
  });
}
