// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:apps.maxwell.services.suggestion/proposal.fidl.dart';
import 'package:apps.maxwell.services.suggestion/proposal_publisher.fidl.dart';
import 'package:apps.maxwell.services.suggestion/suggestion_display.fidl.dart';
import 'package:apps.modular.services.auth/token_provider.fidl.dart';
import 'package:apps.modular.services.component/component_context.fidl.dart';
import 'package:apps.modular.services.component/message_queue.fidl.dart';
import 'package:apps.modules.email.agents.content_provider..content_provider_dart_package/src/email_message.dart';
import 'package:apps.modules.email.services.email/email_content_provider.fidl.dart'
    as ecp;
import 'package:apps.modules.email.services.messages/message.fidl.dart' as m;
import 'package:email_api/email_api.dart';
import 'package:email_models/models.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:lib.fidl.dart/bindings.dart' as bindings;
import 'package:models/user.dart';
import 'package:util/extract_uri.dart';

import 'api.dart';

/// Period at which we check for new email.
const int kRefreshPeriodSecs = 60;

void _log(String msg) {
  print('[email_content_provider] $msg');
}

/// This datastructure is used to keep a record of subscribers that want email
/// updates. This is constructed when
/// [EmailContentProviderImpl.registerForUpdates] is called.
class NotificationSubscriber {
  /// The [storyId] to focus when new email arrives.
  String storyId;

  /// The [MessageSender] we will send a message to when new emails arrive. The
  /// interested module will listen for updates by receiving on their end of the
  /// MessageQueue.
  MessageSenderProxy senderProxy;

  /// Constructor.
  NotificationSubscriber(this.storyId, this.senderProxy);
}

/// Implementation for email_service.
class EmailContentProviderImpl extends ecp.EmailContentProvider {
  final List<ecp.EmailContentProviderBinding> _bindings =
      new List<ecp.EmailContentProviderBinding>();

  final ComponentContextProxy _componentContext;
  final TokenProviderProxy _tokenProvider;
  final ProposalPublisherProxy _proposalPublisher;

  // We keep our email state here in these completers, which act as barriers
  // for setting and getting state. If any callers try to await for this state
  // before it is ready, they will continue to await until it is ready. After
  // that unchanged state can be awaited repeatedly and it is fine.
  final Completer<ecp.User> _user = new Completer<ecp.User>();
  final Completer<List<ecp.Label>> _labels = new Completer<List<ecp.Label>>();

  // label id -> list of threads
  final Map<String, Completer<List<Thread>>> _labelToThreads =
      new Map<String, Completer<List<Thread>>>();

  final Map<String, NotificationSubscriber> _notificationSubscribers =
      new Map<String, NotificationSubscriber>();

  /// Constructor.
  EmailContentProviderImpl(
    this._componentContext,
    this._tokenProvider,
    this._proposalPublisher,
  );

  /// Binds this implementation to the incoming [bindings.InterfaceRequest].
  ///
  /// This should only be called once. In other words, a new
  /// [EmailContentProviderImpl] object needs to be created per interface
  /// request.
  void addBinding(bindings.InterfaceRequest<ecp.EmailContentProvider> request) {
    _log('New client for EmailContentProvider');
    _bindings.add(new ecp.EmailContentProviderBinding()..bind(this, request));
  }

  /// Close all our bindings; called by our owner during termination.
  void close() =>
      _bindings.forEach((ecp.EmailContentProviderBinding b) => b.close());

  /// Preloads the results for [me] and [labels]. Threads for each label and
  /// loaded on demand. Kicks of periodic email updates.
  Future<Null> init() async {
    EmailAPI _api = await API.fromTokenProvider(_tokenProvider);

    User me = await _api.me();
    List<Label> labels = await _api.labels();

    /// load the user information; served by me()
    String payload = JSON.encode(me);
    _user.complete(new ecp.User.init(me.id, payload));

    /// load the labels; served by labels()
    _labels.complete(labels.map((Label label) {
      return new ecp.Label()
        ..id = label.id
        ..name = label.name
        ..jsonPayload = JSON.encode(label);
    }).toList());
  }

  /// Called every [kRefreshPeriodSecs] to refresh labels. It will check for new
  /// email for each loaded labelId, and if they exist, send a notification to
  /// all interested parties (who subscribed using [registerForUpdates]).
  Future<Null> onRefresh() async {
    EmailAPI _api = await API.fromTokenProvider(_tokenProvider);

    for (String labelId in _labelToThreads.keys) {
      int numEmail = await _api.fetchNewEmail(labelId: labelId);
      if (numEmail > 0) {
        await _fetchThreads(
            labelId, (await _labelToThreads[labelId].future).length);
        _notificationSubscribers.forEach(
            (String messageQueueToken, NotificationSubscriber subscriber) {
          subscriber.senderProxy.send('New Email!');

          Proposal p = new Proposal();
          p.id = 'EmailContentProvider';
          p.onSelected = <Action>[new Action()];
          p.onSelected[0].focusStory = new FocusStory.init(subscriber.storyId);
          // TODO(vardhan): Revisit display params.
          p.display = new SuggestionDisplay.init(
              'You have mail',
              '...',
              '......',
              0xffffffff,
              SuggestionImageType.person,
              new List<String>(),
              '',
              AnnoyanceType.none);

          _proposalPublisher.propose(p);
        });
      }
    }
  }

  Future<Null> _fetchThreads(String labelId, int max) async {
    _labelToThreads[labelId] = new Completer<List<Thread>>();
    EmailAPI _api = await API.fromTokenProvider(_tokenProvider);

    List<Thread> threads = await _api.threads(labelId: labelId, max: max);

    _log('fetched ${threads.length} emails.');

    _labelToThreads[labelId].complete(threads);
  }

  @override
  Future<Null> me(void callback(ecp.User user)) async {
    _log('* me() called');
    callback(await _user.future);
    _log('* me() called back');
  }

  @override
  Future<Null> getLabel(String id, void callback(ecp.Label label)) async {
    EmailAPI _api = await API.fromTokenProvider(_tokenProvider);
    Label label = await _api.label(id);
    ecp.Label result = new ecp.Label()
      ..id = label.id
      ..name = label.name
      ..jsonPayload = JSON.encode(label);
    callback(result);
  }

  @override
  Future<Null> labels(void callback(List<ecp.Label> labels)) async {
    callback(await _labels.future);
  }

  @override
  Future<Null> getThread(String id, void callback(ecp.Thread thread)) async {
    EmailAPI _api = await API.fromTokenProvider(_tokenProvider);
    Thread thread = await _api.thread(id);
    ecp.Thread result = new ecp.Thread()
      ..id = thread.id
      ..jsonPayload = JSON.encode(thread);
    callback(result);
  }

  @override
  Future<Null> threads(
      String labelId, int max, void callback(List<ecp.Thread> threads)) async {
    if (_labelToThreads[labelId] == null) {
      await _fetchThreads(labelId, max);
    }

    List<ecp.Thread> retval =
        (await _labelToThreads[labelId].future).map((Thread thread) {
      String payload;
      try {
        payload = JSON.encode(thread);
      } catch (err) {
        String message = 'Failed to encode Thread: $err';
        throw new FormatException(message);
      }

      return new ecp.Thread()
        ..id = thread.id
        ..jsonPayload = payload;
    }).toList();

    callback(retval);
  }

  @override
  void registerForUpdates(String storyId, String messageQueueToken) {
    _log('* registerForUpdates($storyId, $messageQueueToken) called');

    // already exists?
    if (_notificationSubscribers.containsKey(messageQueueToken)) {
      _log('$messageQueueToken already subscribed to notifications');
      return;
    }

    NotificationSubscriber subscriber =
        new NotificationSubscriber(storyId, new MessageSenderProxy());
    _notificationSubscribers[messageQueueToken] = subscriber;
    _componentContext.getMessageSender(
        messageQueueToken, subscriber.senderProxy.ctrl.request());
  }

  Future<gmail.GmailApi> _gmailApi() async {
    final EmailAPI api = await API.fromTokenProvider(_tokenProvider);
    return api.gmailApi;
  }

  m.Message _fidlMessageFromGmail(gmail.Message g) {
    final m.Message message = new m.Message();
    message.id = g.id;
    message.threadId = g.threadId;

    final messageModel = _message(g);
    message.json = JSON.encode(messageModel.toJson());

    return message;
  }

  /// Create a GMail API message object for saving as a draft.
  gmail.Message _gmailMessageFromFidl(m.Message f) {
    final message = new gmail.Message()
      ..id = f.id
      ..threadId = f.threadId;

    final messageModel = new Message.fromJson(JSON.decode(f.json));

    // Check that id & threadId match for f and messageModel.
    assert(f.id == messageModel.id);
    assert(f.threadId == messageModel.threadId);
    // Check that there are no attachments.
    assert(messageModel.attachments == null ||
        messageModel.attachments.length == 0);

    List<Header> headers = [
      new Header('From', messageModel.sender.toString()),
      new Header(
          'To', messageModel.recipientList.map((m) => m.toString()).join(', ')),
      new Header('Cc', messageModel.ccList.map((m) => m.toString()).join(', ')),
      new Header('Subject', messageModel.subject),
    ];

    message.rawAsBytes =
        ASCII.encode(encodePlainTextEmailMessage(headers, messageModel.text));
    return message;
  }

  @override
  Future<Null> createDraft(m.Message message,
      void callback(ecp.Draft draft, m.Message message)) async {
    final _gmail = await _gmailApi();
    final gmailDraft = new gmail.Draft()
      ..message = _gmailMessageFromFidl(message);
    final newDraft = await _gmail.users.drafts.create(gmailDraft, 'me');
    callback(
        new ecp.Draft()
          ..id = newDraft.id
          ..messageId = newDraft.message.id
          ..threadId = newDraft.message.threadId,
        _fidlMessageFromGmail(newDraft.message));
  }

  @override
  Future<Null> drafts(int max, void callback(List<ecp.Draft> drafts)) async {
    final _gmail = await _gmailApi();
    gmail.ListDraftsResponse response =
        await _gmail.users.drafts.list('me', maxResults: max);
    callback(response.drafts.map((gmail.Draft draft) => new ecp.Draft.init(
        draft.id, draft.message.id, draft.message.threadId)));
  }

  @override
  Future<Null> getDraftMessage(
      String draftId, void callback(m.Message message)) async {
    final _gmail = await _gmailApi();
    final gmail.Draft gmailDraft = await _gmail.users.drafts.get('me', draftId);
    callback(_fidlMessageFromGmail(gmailDraft.message));
  }

  @override
  Future<Null> updateDraft(String draftId, m.Message message,
      void callback(m.Message updatedMessage)) async {
    final _gmail = await _gmailApi();
    final gmailDraft = new gmail.Draft()
      ..id = draftId
      ..message = _gmailMessageFromFidl(message);
    final updatedDraft =
        await _gmail.users.drafts.update(gmailDraft, 'me', draftId);
    callback(_fidlMessageFromGmail(updatedDraft.message));
  }

  @override
  Future<Null> sendDraft(
      String draftId, void callback(m.Message sentMessage)) async {
    final _gmail = await _gmailApi();
    final gmail.Draft gmailDraft = new gmail.Draft();
    // The GMail API only needs a draftId to send an existing draft.
    gmailDraft.id = draftId;
    final gmail.Message sentMessage =
        await _gmail.users.drafts.send(gmailDraft, 'me');
    callback(_fidlMessageFromGmail(sentMessage));
  }

  @override
  Future<Null> deleteDraft(String draftId, void callback()) async {
    final _gmail = await _gmailApi();
    await _gmail.users.drafts.delete('me', draftId);
    callback();
  }
}

// From email_api.dart.
Message _message(gmail.Message message) {
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

// From email_api.dart.
int _timestamp(String stamp) {
  return int.parse(stamp);
}

// From email_api.dart.
List<Mailbox> _split(gmail.MessagePartHeader header) {
  return header.value
      .split(', ')
      .map((String s) => new Mailbox.fromString(s))
      .toList();
}

// From email_api.dart.
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
