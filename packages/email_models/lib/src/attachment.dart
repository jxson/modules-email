// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:email_models/fixtures.dart';
import 'package:meta/meta.dart';
import 'package:widgets_meta/widgets_meta.dart';

/// Some basic attachment types
enum AttachmentType {
  /// Youtube Video
  youtubeVideo,

  /// USPS Shipping code
  uspsShipping,

  /// A order receipt for an online purchase
  orderReceipt,
}

/// Simple representation of an email attachment
@Generator(EmailFixtures, 'attachment')
class Attachment {
  /// Type of the attachment
  final AttachmentType type;

  /// String representation of the value/data of the attachment
  final String value;

  /// ID for given attachment
  String id;

  /// Constructor
  Attachment({
    @required this.type,
    @required this.value,
    @required this.id,
  });

  /// Construct a new [Attachment] from JSON.
  factory Attachment.fromJson(Map<String, dynamic> json) {
    int type = int.parse(json['type']);

    return new Attachment(
      id: json['id'],
      value: json['value'],
      type: AttachmentType.values[type],
    );
  }

  /// Helper function for JSON.encode().
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'type': type.index.toString(),
      'value': value,
    };
  }
}
