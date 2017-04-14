// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:email_models/models.dart';
import 'package:models/user.dart';

/// The [EmailSessionDocument] holds the shared state coordinated between the
/// Modules composed into the Email Story. The coordination between the Modules
/// is achieved by storing a JSON representation of a [EmailSessionDocument]
/// instance in a Link.
///
/// Links hold a JSON string that can be updated, overwritten and/or observed.
/// Since Links use JSON exclusively the [EmailSessionDocument] exposes
/// functionality for JSON encoding/decoding.
///
/// [Link](https://goo.gl/AdvCqS)
class EmailSessionDocument {
  /// The query path to use when calling Link.get.
  static const List<String> path = const <String>[
    EmailSessionDocument.docroot,
  ];

  /// EmailSession doc id
  static const String docroot = 'emailSession';

  /// User property name
  static const String userProp = 'user';

  /// Visible labels property name
  static const String labelsProp = 'labels';

  /// Focused label property name
  static const String focusedLabelIdProp = 'focusedLabelId';

  /// Visible labels property name
  static const String threadsProp = 'threads';

  /// Focused thread property name
  static const String focusedThreadIdProp = 'focusedThreadId';

  /// Fetching labels property name
  static const String fetchingLabelsProp = 'fetchingLabels';

  /// Fetching threads property name
  static const String fetchingThreadsProp = 'fetchingThreads';

  /// Fetching user property name
  static const String fetchingUserProp = 'fetchingUser';

  /// The current user
  User user;

  /// Available labels.
  ///
  /// NOTE: The labels structure should look more like this so
  /// that label specific UI state can be isolated here and be better
  /// represented in the UI:
  ///
  ///       labels: {
  ///        loading: true
  ///        focused-id: ...
  ///        errors: [...]
  ///        items: { <label.id>: <label>}
  ///      }
  ///
  /// SEE: SO-390
  Map<String, Label> labels = <String, Label>{};

  /// Currently focused label id, defaults to INBOX.
  String focusedLabelId = 'INBOX';

  /// The currently visible threads.
  Map<String, Thread> threads = <String, Thread>{};

  /// Currently focused thread id
  String focusedThreadId;

  /// Indicates whether the labels are currently being fetched
  bool fetchingLabels = false;

  /// Indicates whether the threads are currently being fetched
  bool fetchingThreads = false;

  /// Indicates whether the user is being fetched.
  bool fetchingUser = false;

  /// Default Constructor
  EmailSessionDocument();

  /// Create a new EmailSessionDocument from a JSON map.
  ///
  ///     String data = ...
  ///     Map<String, dynamic> json = JSON.decode(data);
  ///     EmailSessionDocument doc = EmailSessionDocument.fromJson(json);
  ///
  EmailSessionDocument.fromJson(Map<String, dynamic> json) {
    // The fact that we declared the parameter to be a Map does not mean
    // that Dart checks this at run time, so we need to make sure. If this
    // asserts, then you should check that the doc object is valid before
    // creating the EmailSessionDoc and calling fromJson().
    assert(json is Map && json != null);

    try {
      if (json[userProp] != null) {
        user = new User.fromJson(json[userProp]);
      }

      labels = _labelsFromJson(json[labelsProp]);
      focusedLabelId = json[focusedLabelIdProp];
      threads = _threadsFromJson(json[threadsProp]);
      focusedThreadId = json[focusedThreadIdProp];
      fetchingLabels = _readBool(json, fetchingLabelsProp);
      fetchingThreads = _readBool(json, fetchingThreadsProp);
      fetchingUser = _readBool(json, fetchingUserProp);
    } catch (e) {
      throw new FormatException('Failed to decode EmailSessionDocument $e');
    }
  }

  /// Helper function for JSON.encode()
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      userProp: user?.toJson(),
      labelsProp: _labelsToJson(labels),
      focusedLabelIdProp: focusedLabelId,
      threadsProp: _threadsToJson(threads),
      focusedThreadIdProp: focusedThreadId,
      fetchingLabelsProp: fetchingLabels,
      fetchingThreadsProp: fetchingThreads,
      fetchingUserProp: fetchingUser,
    };
  }

  bool _readBool(Map<String, dynamic> doc, String prop) {
    if (doc[prop] is bool) return doc[prop];
    return false;
  }
}

// Note: these should really be serializable Collection objects that can contain
// paging information.
Map<String, Label> _labelsFromJson(Map<String, dynamic> json) {
  Map<String, Label> labels = <String, Label>{};

  json.forEach((String key, Map<String, dynamic> value) {
    Label label;
    try {
      label = new Label.fromJson(value);
      labels[label.id] = label;
    } catch (err) {
      String message = 'Unable to decode Label: $err';
      throw new FormatException(message);
    }
  });

  return labels;
}

/// Convert the collection into a JSON object.
Map<String, Map<String, dynamic>> _labelsToJson(Map<String, Label> labels) {
  Map<String, Map<String, dynamic>> json = <String, Map<String, dynamic>>{};

  labels.forEach((String id, Label label) {
    json[id] = label.toJson();
  });

  return json;
}

Map<String, Thread> _threadsFromJson(Map<String, dynamic> json) {
  Map<String, Thread> threads = <String, Thread>{};

  json.forEach((String key, Map<String, dynamic> value) {
    Thread thread;
    try {
      thread = new Thread.fromJson(value);
      threads[thread.id] = thread;
    } catch (err) {
      String message = 'Unable to decode Thread: $err';
      throw new FormatException(message);
    }
  });

  return threads;
}

/// Convert the collection into a JSON object.
Map<String, dynamic> _threadsToJson(Map<String, Thread> threads) {
  Map<String, Map<String, dynamic>> json = <String, Map<String, dynamic>>{};

  threads.forEach((String id, Thread thread) {
    json[id] = thread.toJson();
  });

  return json;
}
