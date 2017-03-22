// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:email_models/fixtures.dart';

import 'session.dart';

/// [EmailFixtures] extension class for EmailSession tests.
class EmailSessionFixtures extends EmailFixtures {
  /// Get an EmailSessionDocument populated with mock data.
  EmailSessionDocument emailSessionDocument() {
    EmailSessionDocument doc = new EmailSessionDocument();
    doc.user = me();
    doc.visibleLabels = labels();
    doc.visibleThreads = threads();
    doc.focusedThreadId = doc.visibleThreads[0].id;
    doc.fetchingLabels = false;
    doc.fetchingThreads = false;

    return doc;
  }
}
