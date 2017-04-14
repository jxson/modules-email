// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:email_models/models.dart';
import 'package:flutter_flux/flutter_flux.dart';

/// Email specific Flux [Action]s.
class EmailFluxActions {
  /// Select a label whose threads should be displayed.
  static final Action<Label> selectLabel = new Action<Label>();

  /// Select a thread whose messages should be displayed.
  static final Action<Thread> selectThread = new Action<Thread>();

  /// Expand a message to reveal it's contents.
  static final Action<Message> expandMessage = new Action<Message>();

  /// Close a message to hide it's contents.
  static final Action<Message> closeMessage = new Action<Message>();

  /// Archive a given message.
  static final Action<Thread> archiveThread = new Action<Thread>();

  /// Move a thread to the trash.
  static final Action<Thread> trashThread = new Action<Thread>();
}
