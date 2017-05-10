// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:convert';

import 'package:email_composer/document.dart';
import 'package:email_composer/fixtures.dart';
import 'package:test/test.dart';

void main() {
  EmailFluxFixtures fixtures = new EmailFluxFixtures();

  test('EmailSessionDocument JSON encode/decode', () {
    EmailComposerDocument doc = fixtures.emailComposerDocument();

    String encoded = JSON.encode(doc);
    Map<String, dynamic> json = JSON.decode(encoded);
    EmailComposerDocument hydrated = new EmailComposerDocument.fromJson(json);

    expect(hydrated.message, isNotNull);
    expect(hydrated.message.id, equals(doc.message.id));
  });
}
