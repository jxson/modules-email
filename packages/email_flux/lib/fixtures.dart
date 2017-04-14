// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:email_models/fixtures.dart';

import 'document.dart';

/// [EmailFixtures] extension class for EmailSession tests.
class EmailFluxFixtures extends EmailFixtures {
  /// Get an EmailSessionDocument populated with mock data.
  EmailSessionDocument emailSessionDocument() {
    EmailSessionDocument doc = new EmailSessionDocument();
    doc.user = me();
    doc.labels = labels();
    doc.threads = threads();
    doc.focusedThreadId = doc.threads.keys.first;
    doc.fetchingLabels = false;
    doc.fetchingThreads = false;

    return doc;
  }
}
