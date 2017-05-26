// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:email_models/fixtures.dart';
import 'package:widgets_meta/widgets_meta.dart';

import 'message.dart';

const MapEquality<String, Message> _messageListEquality =
    const MapEquality<String, Message>();

/// Represents a single Gmail Thread
/// https://developers.google.com/gmail/api/v1/reference/users/threads#resource
@Generator(EmailFixtures, 'thread')
class Thread {
  /// The unique ID of the thread
  final String id;

  /// A short part of the message text
  final String snippet;

  /// The ID of the last history record that modified this thread
  final String historyId;

  Map<String, Message> _messages;

  /// Constructor
  Thread({
    this.id,
    this.snippet: '',
    this.historyId,
    Map<String, Message> messages,
  }) {
    this._messages = messages;
  }

  /// Create a [Thread] from JSON.
  factory Thread.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> jsonMessages = json['messages'];
    Map<String, Message> messages = <String, Message>{};

    if (jsonMessages != null) {
      jsonMessages.values.forEach((dynamic json) {
        try {
          Message message = new Message.fromJson(json);
          messages[message.id] = message;
        } catch (err) {
          String message = 'Failed to decode Message: $err';
          throw new FormatException(message);
        }
      });
    }

    return new Thread(
      id: json['id'],
      snippet: json['snippet'],
      historyId: json['historyId'],
      messages: messages,
    );
  }

  /// The list of messages in the thread
  Map<String, Message> get messages =>
      new UnmodifiableMapView<String, Message>(_messages);

  @override
  String toString() {
    return 'Thread('
        'id: $id"'
        'snippet: $snippet"'
        'historyId: $historyId"'
        'messages: $messages"'
        ')';
  }

  /// Helper function for JSON.encode().
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = <String, dynamic>{};

    json['id'] = id;
    json['snippet'] = snippet;
    json['historyId'] = historyId;
    json['messages'] = <String, dynamic>{};

    messages.forEach((String id, Message message) {
      try {
        json['messages'][id] = message.toJson();
      } catch (err) {
        String message = 'Failed to encode Message: $err';
        throw new FormatException(message);
      }
    });

    return json;
  }

  List<Message> _sortedMessages = <Message>[];

  /// Get the last message.
  Message get lastMessage =>
      sortedMessages.isEmpty ? null : sortedMessages.last;

  /// Get the first message.
  Message get firstMessage =>
      sortedMessages.isEmpty ? null : sortedMessages.first;

  /// A the list of messages sorted from newest to oldest.
  List<Message> get sortedMessages {
    if (_sortedMessages.isNotEmpty) return _sortedMessages;

    _sortedMessages = messages.values.toList();
    _sortedMessages.sort((Message a, Message b) {
      return b.timestamp.compareTo(a.timestamp);
    });

    return _sortedMessages;
  }

  /// Gets the subject of the thread
  /// For now, this will return the subject of the first message of the thread
  /// If there is no subject specified, a default of '(no subject)' will be set
  String get subject {
    Message message = firstMessage;
    String subject = message?.subject;
    bool useDefault = (subject == null || subject.isEmpty);

    return useDefault ? '(No Subject)' : subject;
  }
}
