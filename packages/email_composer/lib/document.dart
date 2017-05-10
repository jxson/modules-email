// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:email_models/models.dart';

/// The [EmailComposerDocument] manages Link content for the email_composer.
///
/// [Link](https://goo.gl/AdvCqS)
class EmailComposerDocument {
  /// The docroot.
  static const String docroot = 'email-composer';

  /// The query path to use when calling Link.get.
  static const List<String> path = const <String>[
    EmailComposerDocument.docroot,
  ];

  /// The [Message] being composed.
  Message message;

  /// Default Constructor
  EmailComposerDocument();

  /// Create a new [EmailComposerDocument] from a JSON map.
  ///
  ///     String data = ...
  ///     Map<String, dynamic> json = JSON.decode(data);
  ///     EmailSessionDocument doc = EmailComposerDocument.fromJson(json);
  ///
  EmailComposerDocument.fromJson(Map<String, dynamic> json) {
    assert(json is Map && json != null);

    try {
      if (json['message'] != null) {
        message = new Message.fromJson(json['message']);
      }
    } catch (e) {
      throw new FormatException('Failed to decode EmailComposerDocument $e');
    }
  }

  /// The name of the Link to use for this doument.
  String get linkName {
    if (message != null) {
      return '$docroot-${message.id}';
    } else {
      return '$docroot-new';
    }
  }

  /// Helper function for JSON.encode()
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'message': message?.toJson(),
    };
  }
}
