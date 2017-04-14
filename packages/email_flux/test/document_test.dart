// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:convert';

import 'package:email_flux/document.dart';
import 'package:email_flux/fixtures.dart';
import 'package:email_models/models.dart';
import 'package:test/test.dart';

void main() {
  EmailFluxFixtures fixtures = new EmailFluxFixtures();

  test('EmailSessionDocument JSON encode/decode', () {
    EmailSessionDocument doc = fixtures.emailSessionDocument();

    String encoded = JSON.encode(doc);
    Map<String, dynamic> json = JSON.decode(encoded);
    EmailSessionDocument hydrated = new EmailSessionDocument.fromJson(json);

    expect(hydrated.user.id, equals(doc.user.id));

    doc.labels.forEach((String key, Label label) {
      expect(hydrated.labels.containsKey(key), isTrue);
      expect(hydrated.labels[key].id, equals(label.id));
    });

    expect(hydrated.focusedLabelId, equals(doc.focusedLabelId));

    doc.threads.forEach((String key, Thread thread) {
      expect(hydrated.threads.containsKey(key), isTrue);
      expect(hydrated.threads[key].id, equals(thread.id));
    });

    expect(hydrated.focusedThreadId, equals(doc.focusedThreadId));
    expect(hydrated.fetchingLabels, equals(doc.fetchingLabels));
    expect(hydrated.fetchingThreads, equals(doc.fetchingThreads));
  });
}
