// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:models/user.dart';

import '../../models.dart';

/// The [EmailSessionDocument] holds the shared state coordinated between the
/// Modules composed into the Email Story. The coordination between the Modules
/// is acheived by storing a JSON representation of a [EmailSessionDocument]
/// instance in a Link.
///
/// Links hold a JSON string that can be updated, overwritten and/or observed.
/// Since Links use JSON exclusively the [EmailSessionDocument] exposes
/// functionality for JSON encoding/decoding.
///
/// [Link](https://goo.gl/AdvCqS)
class EmailSessionDocument {
  // TODO(jasoncampbell): Should there be a JSON schema defined for
  // EmailSessionDocument?

  /// EmailSession doc id
  // QESTION(jimbe): does the document id/root need to be unique?
  static const String docroot = 'emailSession';

  /// User property name
  static const String userProp = 'user';

  /// Visible labels property name
  static const String visibleLabelsProp = 'visibleLabels';

  /// Focused label property name
  static const String focusedLabelIdProp = 'focusedLabelId';

  /// Visible labels property name
  static const String visibleThreadsProp = 'visibleThreads';

  /// Focused thread property name
  static const String focusedThreadIdProp = 'focusedThreadId';

  /// Fetching labels property name
  static const String fetchingLabelsProp = 'fetchingLabels';

  /// Fetching threads property name
  static const String fetchingThreadsProp = 'fetchingThreads';

  /// The current user
  User user;

  /// Available labels
  List<Label> visibleLabels;

  /// Currently focused label id
  String focusedLabelId;

  /// The currently visible threads.
  List<Thread> visibleThreads;

  /// Currently focused thread id
  String focusedThreadId;

  /// Indicates whether the labels are currently being fetched
  bool fetchingLabels;

  /// Indicates whether the threads are currently being fetched
  bool fetchingThreads;

  /// Default Constructor
  EmailSessionDocument();

  // /// Construct from data in link document.
  // bool readFromLink(String jsonString) {
  //   // ignore: STRONG_MODE_DOWN_CAST_COMPOSITE
  //   Map<String, dynamic> json = JSON.decode(jsonString);
  //
  //   if (json == null) {
  //     return false;
  //   }
  //
  //   return fromJson(json);
  // }

  // /// Write state to link
  // void writeToLink(Link link) {
  //   link.updateObject(<String>[docroot], JSON.encode(this));
  // }

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
    assert(json is Map && json[docroot] is Map);

    try {
      Map<String, dynamic> root = json[docroot];
      user = new User.fromJson(root[userProp]);
      visibleLabels = _labelsFromJson(root[visibleLabelsProp]);
      focusedLabelId = root[focusedLabelIdProp];
      visibleThreads = _threadsFromJson(root[visibleThreadsProp]);
      focusedThreadId = root[focusedThreadIdProp];
      fetchingLabels = _readBool(root, fetchingLabelsProp);
      fetchingThreads = _readBool(root, fetchingThreadsProp);
    } catch (e) {
      throw new StateError('Failed to cast Link properties $e');
    }
  }

  /// Helper function for JSON.encode()
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = <String, dynamic>{};

    json[docroot] = <String, dynamic>{
      userProp: user?.toJson(),
      visibleLabelsProp: _labelsToJson(visibleLabels),
      focusedLabelIdProp: focusedLabelId,
      visibleThreadsProp: _threadsToJson(visibleThreads),
      focusedThreadIdProp: focusedThreadId,
      fetchingLabelsProp: fetchingLabels ?? false,
      fetchingThreadsProp: fetchingThreads ?? false,
    };

    return json;
  }

  bool _readBool(Map<String, dynamic> doc, String prop) {
    if (doc[prop] is bool) return doc[prop];
    return false;
  }
}

List<Label> _labelsFromJson(List<Map<String, dynamic>> json) {
  List<Label> labels = <Label>[];

  if (json != null) {
    labels = json
        .map((Map<String, dynamic> value) => new Label.fromJson(value))
        .toList();
  }

  return labels;
}

/// Convert the collection into a JSON object.
List<Map<String, dynamic>> _labelsToJson(List<Label> labels) {
  List<Map<String, dynamic>> json = <Map<String, dynamic>>[];

  if (labels != null) {
    json = labels.map((Label label) => label.toJson()).toList();
  }

  return json;
}

List<Thread> _threadsFromJson(List<Map<String, dynamic>> json) {
  List<Thread> threads;

  if (json is List) {
    threads = json
        .map((Map<String, dynamic> value) => new Thread.fromJson(value))
        .toList();
  }

  return threads ?? <Thread>[];
}

/// Convert the collection into a JSON object.
List<Map<String, String>> _threadsToJson(List<Thread> labels) {
  List<Map<String, dynamic>> json = <Map<String, dynamic>>[];

  if (labels != null) {
    json = labels.map((Thread label) => label.toJson()).toList();
  }

  return json;
}
