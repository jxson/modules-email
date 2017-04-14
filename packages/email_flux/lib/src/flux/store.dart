// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:email_models/models.dart';
import 'package:flutter_flux/flutter_flux.dart';
import 'package:models/user.dart';

import '../../document.dart';

/// Represents an active view session into an Email repository
class EmailFluxStore extends Store {
  EmailSessionDocument _doc = new EmailSessionDocument();

  /// Constructs a new Store to read the email session from the link
  EmailFluxStore();

  /// The current user profile
  User get user => _doc.user;

  /// Proxy to private [EmailSessionDocument.fetchingUser];
  bool get fetchingUser => _doc.fetchingUser;

  /// Respond to trigger for selecting a Label.
  void handleSelectLabel(Label label) {
    if (label == null) {
      return;
    }

    _doc.focusedLabelId = label.id;
  }

  /// Map of [Label]s that are currently visible and should be displayed.
  Map<String, Label> get labels => _doc.labels;

  /// The currently selected label.
  String get focusedLabelId => _doc.focusedLabelId;

  /// Respond to trigger for expanding a Message.
  // TODO: remove this.
  Label get focusedLabel {
    String id = _doc?.focusedLabelId;

    return labels[id];
  }

  /// Map of [Thread]s that are currently visible and should be displayed.
  Map<String, Thread> get threads => _doc.threads;

  /// The currently selected thread that has focus, if any.
  String get focusedThreadId => _doc.focusedThreadId;

  /// The currently outstanding errors with the store.
  /// (e.g. Network errors, API errors, etc. )
  /// TODO(alangardner): Implement. This is only a mock.
  /// * See SO-137
  List<Error> get errors => <Error>[];

  /// Returns true if currently fetching labels from server
  // TODO(alangardner): Current status? (e.g. empty, loading, errored, etc.)
  bool get fetchingLabels => _doc.fetchingLabels ?? false;

  /// Returns true if currently fetching threads from server
  bool get fetchingThreads => _doc.fetchingThreads ?? false;

  /// Update the internal [EmailSessionDocument].
  void update(EmailSessionDocument doc) {
    if (doc == null) return;

    _doc = doc;

    trigger();
  }
}
