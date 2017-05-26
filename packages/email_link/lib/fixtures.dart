// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fixtures/fixtures.dart';

import 'document.dart';

/// [EmailLinkFixtures] extension class for EmailLink tests.
class EmailLinkFixtures extends Fixtures {
  /// Get an EmailSessionDocument populated with mock data.
  EmailLinkDocument document() {
    int seq = this.sequence('thread');

    return new EmailLinkDocument(
      labelId: 'STARRED',
      threadId: 'thread-$seq',
    );
  }
}
