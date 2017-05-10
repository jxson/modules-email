// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:email_models/fixtures.dart';

import 'document.dart';

/// [EmailFixtures] extension class for EmailSession tests.
class EmailFluxFixtures extends EmailFixtures {
  /// Get an EmailSessionDocument populated with mock data.
  EmailComposerDocument emailComposerDocument() {
    EmailComposerDocument doc = new EmailComposerDocument();
    doc.message = message();

    return doc;
  }
}
