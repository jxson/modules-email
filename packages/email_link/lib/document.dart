// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The [EmailLinkDocument] holds the coordinated state shared between the UI
/// Modules composed into the Email Story. The coordination between the
/// Modules is achieved by storing a JSON representation of a
/// [EmailLinkDocument] instance in a Link.
///
/// Links hold a JSON string that can be updated, overwritten and/or observed.
/// Since Links use JSON exclusively the [EmailLinkDocument] exposes
/// serialization methods for JSON encoding/decoding.
///
/// [Link](https://goo.gl/AdvCqS)
class EmailLinkDocument {
  /// The JSON serialization key for labelId.
  static const String labelIdkey = 'label-id';

  /// The JSON serialization key for threadId.
  static const String threadIdkey = 'thread-id';

  /// The query path to use when calling Link.get.
  static const List<String> path = const <String>[
    EmailLinkDocument.docroot,
  ];

  /// The doc-root to use as the top-level key for this document.
  static const String docroot = 'email-session';

  final Map<String, String> _json = <String, String>{
    labelIdkey: null,
    threadIdkey: null,
  };

  /// Constructor
  EmailLinkDocument({
    String labelId,
    String threadId,
  }) {
    _json[labelIdkey] = labelId;
    _json[threadIdkey] = threadId;
  }

  /// Create a new [EmailLinkDocument] from a JSON map.
  ///
  ///     String data = ...
  ///     Map<String, String> json = JSON.decode(data);
  ///     EmailLinkDocument doc = EmailLinkDocument.fromJson(json);
  ///
  EmailLinkDocument.fromJson(Map<String, String> json) {
    // The fact that we declared the parameter to be a Map does not mean
    // that Dart checks this at run time, so we need to make sure. If this
    // asserts, then you should check that the doc object is valid before
    // creating the EmailLinkDocument and calling fromJson().
    assert(json is Map && json != null);

    json.forEach((String key, String value) {
      if (_json.containsKey(key)) {
        _json[key] = value;
      } else {
        String message = 'Invalid key "$key"';
        throw new FormatException(message);
      }
    });
  }

  /// Currently focused label id, defaults to INBOX.
  String get labelId => _json['label-id'];

  /// Set/update the 'link-id';
  set labelId(String id) {
    _json[labelIdkey] = id;
  }

  /// Currently focused thread id
  String get threadId => _json['thread-id'];

  /// Set/update the 'thread-id';
  set threadId(String id) {
    _json[threadIdkey] = id;
  }

  /// Helper function for JSON.encode()
  Map<String, dynamic> toJson() {
    return _json;
  }
}
