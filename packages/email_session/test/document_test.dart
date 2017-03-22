// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:convert';

import 'package:email_session/fixtures.dart';
import 'package:email_session/session.dart';
import 'package:test/test.dart';

void main() {
  EmailSessionFixtures fixtures = new EmailSessionFixtures();

  test('EmailSessionDocument JSON encode/decode', () {
    EmailSessionDocument doc = fixtures.emailSessionDocument();

    String encoded = JSON.encode(doc);
    Map<String, dynamic> json = JSON.decode(encoded);
    EmailSessionDocument hydrated = new EmailSessionDocument.fromJson(json);

    expect(hydrated.user, equals(doc.user));
    expect(hydrated.visibleLabels, equals(doc.visibleLabels));
    expect(hydrated.focusedLabelId, equals(doc.focusedLabelId));
    expect(hydrated.visibleThreads, equals(doc.visibleThreads));
    expect(hydrated.focusedThreadId, equals(doc.focusedThreadId));
    expect(hydrated.fetchingLabels, equals(doc.fetchingLabels));
    expect(hydrated.fetchingThreads, equals(doc.fetchingThreads));
  }, skip: true);
}
