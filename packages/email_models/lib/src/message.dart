// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:email_models/fixtures.dart';
import 'package:util/time_util.dart';
import 'package:widgets_meta/widgets_meta.dart';

import 'attachment.dart';
import 'mailbox.dart';

const ListEquality<Mailbox> _mailboxListEquality =
    const ListEquality<Mailbox>(const DefaultEquality<Mailbox>());

/// Represents a single Gmail Message
/// https://developers.google.com/gmail/api/v1/reference/users/messages
@Generator(EmailFixtures, 'message')
class Message {
  /// Unique Identifier for given email message
  String id;

  /// Unique Identifier for the thread that contains this message
  String threadId;

  /// If this message is a draft, its Unique Identifier, otherwise null
  String draftId;

  /// List of recipient mailboxes
  List<Mailbox> recipientList;

  /// List of mailboxes that are CCed in email message
  List<Mailbox> ccList;

  /// Mailbox of sender
  Mailbox sender;

  /// URL pointing to Avatar of sender
  String senderProfileUrl;

  /// Subject line of email
  String subject;

  /// Main body text of email
  String text;

  /// List of links (URIs) that are found within email
  List<Uri> links;

  /// List of attachments for given email
  List<Attachment> attachments;

  /// Timestamp (epoch ms) used for ordering.
  int timestamp;

  /// True if Email Message has been read
  bool isRead;

  /// If a message is expanded or not, this is UI state not derived from REST
  /// API.
  bool expanded;

  /// Constructor
  Message({
    this.id,
    this.threadId,
    this.draftId,
    this.sender,
    this.senderProfileUrl,
    this.subject,
    this.text,
    this.timestamp,
    this.isRead,
    this.expanded: false,
    List<Uri> links,
    List<Attachment> attachments,
    List<Mailbox> recipientList,
    List<Mailbox> ccList,
  })
      : links = new List<Uri>.unmodifiable(links ?? <Uri>[]),
        attachments =
            new List<Attachment>.unmodifiable(attachments ?? <Attachment>[]),
        recipientList =
            new List<Mailbox>.unmodifiable(recipientList ?? <Mailbox>[]),
        ccList = new List<Mailbox>.unmodifiable(ccList ?? <Mailbox>[]);

  /// Create a message from JSON.
  factory Message.fromJson(Map<String, dynamic> json) {
    if (json == null) return new Message();

    Iterable<Uri> links = json['links']?.map((String link) => Uri.parse(link));

    Iterable<Attachment> attachments = json['attachments']
        ?.map((Map<String, dynamic> a) => new Attachment.fromJson(a));

    Iterable<Mailbox> to =
        json['to']?.map((Map<String, dynamic> u) => new Mailbox.fromJson(u));

    Iterable<Mailbox> cc =
        json['cc']?.map((Map<String, dynamic> u) => new Mailbox.fromJson(u));

    return new Message(
      id: json['id'],
      threadId: json['threadId'],
      draftId: json['draftId'],
      sender: new Mailbox.fromJson(json['sender']),
      senderProfileUrl: json['senderProfileUrl'],
      subject: json['subject'],
      text: json['text'],
      timestamp: json['timestamp'],
      isRead: json['isRead'],
      links: links != null ? links.toList() : const <Uri>[],
      attachments:
          attachments != null ? attachments.toList() : const <Attachment>[],
      recipientList: to != null ? to.toList() : const <Mailbox>[],
      ccList: cc != null ? cc.toList() : const <Mailbox>[],
      expanded: json['expanded'],
    );
  }

  /// Helper function for JSON.encode() creates JSON-encoded Thread object.
  Map<String, dynamic> toJson() {
    // TODO(jxson): MailBox models should be moved to User models, MailBox
    // representation should then user the standard User model for it's
    // backing data. See #SO-341
    Map<String, dynamic> json = <String, dynamic>{
      'id': id,
      'threadId': threadId,
      'draftId': draftId,
      'sender': sender?.toJson(),
      'senderProfileUrl': senderProfileUrl,
      'subject': subject,
      'text': text,
      'timestamp': timestamp,
      'isRead': isRead,
      'links': links.map((Uri l) => l.toString()).toList(),
      'to': recipientList.map((Mailbox r) => r.toJson()).toList(),
      'cc': ccList.map((Mailbox r) => r.toJson()).toList(),
      'attachments': attachments.map((Attachment a) => a.toJson()).toList(),
      'expanded': expanded,
    };

    return json;
  }

  // Message, as a [String].
  @override
  String toString() {
    return 'Message('
        'id: $id'
        'subject: $subject'
        'test: $text'
        ')';
  }

  /// Preview text
  ///
  /// Strips all newline characters
  String get snippet {
    return (text ?? '').replaceAll('\r\n', ' ').replaceAll('\n', ' ');
  }

  /// Get 'Display Date' for [Message] as the relative display date
  String get displayDate {
    return TimeUtil.relativeDisplayDate(
      date: new DateTime.fromMillisecondsSinceEpoch(timestamp),
    );
  }
}
