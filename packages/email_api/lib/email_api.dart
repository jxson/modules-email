// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:email_models/models.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:googleapis/oauth2/v2.dart' as oauth;
import 'package:googleapis_auth/auth_io.dart';
import 'package:lib.logging/logging.dart';
import 'package:models/user.dart';
import 'package:util/extract_uri.dart';

export 'package:googleapis_auth/auth_io.dart';
export 'package:http/http.dart';

const List<String> _kLabelSortOrder = const <String>[
  'INBOX',
  'STARRED',
  'DRAFT',
  'TRASH',
];

/// The interface to the Gmail REST API.
class EmailAPI {
  /// Google OAuth scopes.
  List<String> scopes;
  gmail.GmailApi _gmail;

  // TODO(vardhan): Do we need to track separate historyIds per-label?
  String _latestHistoryId;

  /// The [EmailAPI] constructor.
  EmailAPI(this._client) {
    assert(_client != null, 'client must not be null');
    _gmail = new gmail.GmailApi(this._client);
  }

  /// Update the authenticated HTTP client.
  set client(AuthClient newClient) {
    assert(newClient != null, 'client must not be null');
    _client = newClient;
    _gmail = new gmail.GmailApi(_client);
  }

  AuthClient _client;

  /// Get the [GmailApi] instance.
  gmail.GmailApi get gmailApi => _gmail;

  /// Get the logged in [User] object from [Oauth2Api].
  Future<User> me() async {
    oauth.Oauth2Api _oauth = new oauth.Oauth2Api(_client);
    oauth.Userinfoplus info;

    try {
      info = await _oauth.userinfo.get();
    } catch (err) {
      log.severe('failed to get userinfo', err);
      throw err;
    }

    return new User(
      id: info.id,
      email: info.email,
      name: info.name,
      picture: info.picture,
    );
  }

  /// Get a [Label] from the Gmail REST API.
  Future<Label> label(String id) async {
    assert(id != null);

    gmail.Label label = await _gmail.users.labels.get('me', id);
    String type = label.type.toLowerCase();
    String name =
        type == 'system' ? _normalizeLabelName(label.name) : label.name;

    // Available properties on [gmail.Label]s are:
    //
    //       {
    //         "id": "INBOX",
    //         "name": "INBOX",
    //         "messageListVisibility": "hide",
    //         "labelListVisibility": "labelShow",
    //         "type": "system",
    //         "messagesTotal": 87,
    //         "messagesUnread": 82,
    //         "threadsTotal": 87,
    //         "threadsUnread": 82
    //       }
    //
    return new Label(
      id: label.id,
      name: name,
      unread: label.threadsUnread,
      type: label.type,
    );
  }

  /// Get a list of [Label]s from the Gmail REST API. By default only returns
  /// those in [_kLabelSortOrder].
  Future<List<Label>> labels({bool all: false}) async {
    gmail.ListLabelsResponse response = await _gmail.users.labels.list('me');
    Iterable<Future<Label>> requests = response.labels.map((gmail.Label label) {
      return new Future<Label>(() async {
        return await this.label(label.id);
      });
    });

    Stream<Label> stream = new Stream<Label>.fromFutures(requests);
    List<Label> labels = await stream.toList();

    List<Label> top = labels.where((Label label) {
      return _kLabelSortOrder.contains(label.id);
    }).toList();

    top.sort((Label a, Label b) {
      int indexA = _kLabelSortOrder.indexOf(a.id);
      int indexB = _kLabelSortOrder.indexOf(b.id);
      return indexA.compareTo(indexB);
    });

    if (all) {
      List<Label> bottom = labels.where((Label label) {
        return !_kLabelSortOrder.contains(label.id);
      }).toList();

      bottom.sort((Label a, Label b) {
        return a.name.compareTo(b.name);
      });

      top.addAll(bottom);
    }

    return top;
  }

  /// Get a [Thread] from the Gmail REST API.
  Future<Thread> thread(String id) async {
    gmail.Thread t = await _gmail.users.threads.get('me', id);
    Map<String, Message> messages = <String, Message>{};

    await Future.wait(t.messages.map((gmail.Message m) async {
      Message message = await _message(m);
      messages[message.id] = message;
    }));

    return new Thread(
      id: t.id,
      snippet: t.snippet,
      historyId: t.historyId,
      messages: messages,
    );
  }

  /// Returns the number of new email for the given labelId since the previous
  /// threads() call on the labelId.
  // TODO(vardhan): This returns a false positive for all history events, not
  // just new email. Filter, or rework the behavior of updating emails.
  Future<bool> shouldUdateCache({
    String labelId,
    int max: 15,
  }) async {
    // It could be that we have not finished fetching initial emails yet. In
    // which case, there are no new emails.
    if (_latestHistoryId == null) {
      return false;
    }

    // NOTE: It is possible for the latest history ID to be updated while this
    // async operation is happening...
    gmail.ListHistoryResponse response = await _gmail.users.history.list(
      'me',
      labelId: labelId,
      maxResults: max,
      startHistoryId: _latestHistoryId,
    );

    if (response.history == null)
      return false;
    else
      return response.history.length > 0;
  }

  /// Get a list of [Thread]s from the Gmail REST API.
  Future<List<Thread>> threads({
    String labelId: 'INBOX',
    int max: 15,
  }) async {
    gmail.ListThreadsResponse response = await _gmail.users.threads.list(
      'me',
      labelIds: <String>[labelId],
      maxResults: max,
    );

    // TODO(jasoncampbell): handle error and empty cases.
    if (response.threads == null) {
      return <Thread>[];
    }

    Iterable<Future<Thread>> requests =
        response.threads.map((gmail.Thread thread) {
      return new Future<Thread>(() async {
        return await this.thread(thread.id);
      });
    });

    Stream<Thread> stream = new Stream<Thread>.fromFutures(requests);
    List<Thread> threads = await stream.toList();

    threads.sort((Thread a, Thread b) {
      Message lastA = a.lastMessage;
      Message lastB = b.lastMessage;

      return lastB.timestamp.compareTo(lastA.timestamp);
    });

    _latestHistoryId = threads[0].historyId;

    return threads;
  }

  /// Get a [Message]s from the Gmail REST API.
  Future<Message> _message(gmail.Message message) async {
    String subject;
    Mailbox sender;
    List<Mailbox> to = <Mailbox>[];
    List<Mailbox> cc = <Mailbox>[];

    // TODO(jxson): SO-139 Add profile fetching for all users encountered.

    // Pull [Message] meta from [gmail.MessagePartHeader]s.
    message.payload.headers.forEach((gmail.MessagePartHeader header) {
      String name = header.name.toLowerCase();
      switch (name) {
        case 'from':
          sender = new Mailbox.fromString(header.value);
          break;
        case 'subject':
          subject = header.value;
          break;
        case 'to':
          to.addAll(_split(header));
          break;
        case 'cc':
          cc.addAll(_split(header));
          break;
      }
    });

    String body = _body(message);
    List<Uri> links = extractURI(body);

    return new Message(
      id: message.id,
      threadId: message.threadId,
      timestamp: _timestamp(message.internalDate),
      isRead: !message.labelIds.contains('UNREAD'),
      sender: sender,
      subject: subject,
      senderProfileUrl: null,
      recipientList: to,
      ccList: cc,
      text: body,
      links: links,
    );
  }

  /// Marks a message as read given the ID
  /// Returns true if the message has the "UNREAD" label removed.
  Future<Null> markMessageAsRead(String id) async {
    gmail.ModifyMessageRequest request = new gmail.ModifyMessageRequest()
      ..removeLabelIds = <String>['UNREAD'];
    await _gmail.users.messages.modify(request, 'me', id);
  }

  /// Archive given thread
  /// A thread is archived when all it's messages no longer have the INBOX label
  Future<Null> archiveThread(String id) async {
    gmail.ModifyThreadRequest request = new gmail.ModifyThreadRequest()
      ..removeLabelIds = <String>['INBOX'];
    await _gmail.users.threads.modify(request, 'me', id);
  }

  /// Moves given Thread to trash
  Future<Null> moveThreadToTrash(String id) async {
    assert(id != null);
    await _gmail.users.threads.trash('me', id);
  }
}

String _normalizeLabelName(String string) {
  String value = string.replaceAll(new RegExp(r'CATEGORY_'), '');
  return value[0].toUpperCase() + value.substring(1).toLowerCase();
}

int _timestamp(String stamp) {
  return int.parse(stamp);
}

List<Mailbox> _split(gmail.MessagePartHeader header) {
  return header.value
      .split(', ')
      .map((String s) => new Mailbox.fromString(s))
      .toList();
}

String _body(gmail.Message message) {
  gmail.MessagePart part = message.payload.parts
      ?.reduce((gmail.MessagePart previous, gmail.MessagePart current) {
    if (current.mimeType == 'text/plain') {
      return current;
    }
  });

  if (part != null) {
    List<int> base64 = BASE64.decode(part.body.data);
    String utf8 = UTF8.decode(base64);
    return utf8;
  } else {
    return message.snippet;
  }
}
