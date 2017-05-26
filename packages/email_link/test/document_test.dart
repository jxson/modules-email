// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:email_link/document.dart';
import 'package:email_link/fixtures.dart';
import 'package:test/test.dart';

void main() {
  EmailLinkFixtures fixtures = new EmailLinkFixtures();

  test('EmailSessionDocument JSON encode/decode', () {
    EmailLinkDocument doc = fixtures.document();

    String encoded = JSON.encode(doc);
    Map<String, dynamic> json = JSON.decode(encoded);
    EmailLinkDocument hydrated = new EmailLinkDocument.fromJson(json);

    expect(hydrated.threadId, equals(doc.threadId));
    expect(hydrated.labelId, equals(doc.labelId));
  });
}
