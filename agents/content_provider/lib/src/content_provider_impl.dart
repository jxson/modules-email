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
import 'package:email_link/document.dart';
import 'package:email_models/models.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:lib.fidl.dart/bindings.dart' as bindings;
import 'package:lib.logging/logging.dart';
import 'package:models/user.dart';
import 'package:util/extract_uri.dart';

import 'api.dart';

/// Period at which we check for new email.
const int kRefreshPeriodSecs = 30;

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
    log.fine('New client for EmailContentProvider');
    _bindings.add(new ecp.EmailContentProviderBinding()..bind(this, request));
  }

  /// Close all our bindings; called by our owner during termination.
  void close() =>
      _bindings.forEach((ecp.EmailContentProviderBinding b) => b.close());

  /// Preloads the results for [me] and [labels]. Threads for each label and
  /// loaded on demand. Kicks off periodic email updates.
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

    // TODO(SO-607): Fetching should happen in parallel.
    _labelToThreads.keys.forEach((String key) async {
      bool shouldFetch = await _api.shouldUdateCache(labelId: key);

      if (shouldFetch) {
        await _fetchThreads(key, 20);
        log.fine('updated cache for $key');

        /// Notify modules that are subscribed to updates.
        _notificationSubscribers.forEach((
          String token,
          NotificationSubscriber subscriber,
        ) {
          Map<String, String> update = <String, String>{
            'label-id': key,
          };

          subscriber.senderProxy.send(JSON.encode(update));
        });

        /// Create an interruptive notification proposal if new messages are
        /// available for the inbox.
        if (key == 'INBOX') {
          log.fine('creating interruptive proposal');

          Proposal proposal = new Proposal()
            ..id = 'New $key message'
            ..onSelected = <Action>[
              // TODO(SO-610): Focus an email story if it is currently viewing
              // the new message's thread.
              new Action()
                ..createStory = (new CreateStory()
                  ..moduleId = 'email/nav'
                  ..initialData =
                      JSON.encode((new EmailLinkDocument(labelId: key))))
            ]
            ..display = (new SuggestionDisplay()
              ..headline = 'New email'
              ..subheadline = ''
              ..details = ''
              ..color = 0xFFFF0080
              ..iconUrls = <String>[
                'https://www.gstatic.com/images/branding/product/1x/inbox_96dp.png'
              ]
              ..imageType = SuggestionImageType.other
              ..imageUrl = ''
              ..annoyance = AnnoyanceType.interrupt);

          log.fine('publishing proposal');
          _proposalPublisher.propose(proposal);
        }
      }
    });
  }

  Future<Null> _fetchThreads(String labelId, int max) async {
    _labelToThreads[labelId] = new Completer<List<Thread>>();
    EmailAPI _api = await API.fromTokenProvider(_tokenProvider);

    List<Thread> threads = await _api.threads(labelId: labelId, max: max);

    if (labelId == 'DRAFT') {
      final gmail.GmailApi _gmail = await _gmailApi();
      gmail.ListDraftsResponse response =
          await _gmail.users.drafts.list('me', maxResults: max);

      // Might be null if there are no messages labled "Drafts".
      response.drafts ??= <gmail.Draft>[];

      Map<String, String> draftIds = <String, String>{};
      for (gmail.Draft d in response.drafts) {
        draftIds[d.message.id] = d.id;
      }
      for (Thread t in threads) {
        for (String id in t.messages.keys) {
          if (draftIds[id] != null) {
            t.messages[id].draftId = draftIds[id];
          } else {
            log.fine('Couldn\'t find any draft ID for message $id');
          }
        }
      }
    }

    _labelToThreads[labelId].complete(threads);
  }

  @override
  Future<Null> me(void callback(ecp.User user)) async {
    log.fine('* me() called');
    callback(await _user.future);
    log.fine('* me() called back');
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
    // already exists?
    if (_notificationSubscribers.containsKey(messageQueueToken)) {
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

  m.Message _fidlMessageFromGmail(String draftId, gmail.Message g) {
    final m.Message message = new m.Message();
    message.id = g.id;
    message.threadId = g.threadId;
    message.draftId = draftId;

    final Message messageModel = _message(g);
    message.json = JSON.encode(messageModel.toJson());

    return message;
  }

  /// Create a GMail API message object for saving as a draft.
  gmail.Message _gmailMessageFromFidl(m.Message f) {
    final gmail.Message message = new gmail.Message()
      ..id = f.id
      ..threadId = f.threadId;

    final Message messageModel = new Message.fromJson(JSON.decode(f.json));

    // Check that id & threadId match for f and messageModel.
    assert(f.id == messageModel.id);
    assert(f.threadId == messageModel.threadId);
    // Check that there are no attachments.
    assert(messageModel.attachments == null ||
        messageModel.attachments.length == 0);

    List<Header> headers = <Header>[
      new Header('From', messageModel.sender.toString()),
      new Header(
          'To',
          messageModel.recipientList
              .map((Mailbox m) => m.toString())
              .join(', ')),
      new Header('Cc',
          messageModel.ccList.map((Mailbox m) => m.toString()).join(', ')),
      new Header('Subject', messageModel.subject),
    ];

    message.rawAsBytes =
        ASCII.encode(encodePlainTextEmailMessage(headers, messageModel.text));
    return message;
  }

  @override
  Future<Null> createDraft(
      m.Message message, void callback(m.Message message)) async {
    final gmail.GmailApi _gmail = await _gmailApi();
    final gmail.Draft gmailDraft = new gmail.Draft()
      ..message = _gmailMessageFromFidl(message);
    final gmail.Draft newDraft =
        await _gmail.users.drafts.create(gmailDraft, 'me');
    callback(_fidlMessageFromGmail(newDraft.id, newDraft.message));
  }

  @override
  Future<Null> drafts(int max, void callback(List<m.Message> drafts)) async {
    final gmail.GmailApi _gmail = await _gmailApi();
    gmail.ListDraftsResponse response =
        await _gmail.users.drafts.list('me', maxResults: max);
    callback(response.drafts.map(
        (gmail.Draft draft) => _fidlMessageFromGmail(draft.id, draft.message)));
  }

  @override
  Future<Null> getDraftMessage(
      String draftId, void callback(m.Message message)) async {
    final gmail.GmailApi _gmail = await _gmailApi();
    final gmail.Draft gmailDraft = await _gmail.users.drafts.get('me', draftId);
    callback(_fidlMessageFromGmail(gmailDraft.id, gmailDraft.message));
  }

  @override
  Future<Null> updateDraft(
      m.Message message, void callback(m.Message updatedMessage)) async {
    final gmail.GmailApi _gmail = await _gmailApi();
    final gmail.Draft gmailDraft = new gmail.Draft()
      ..id = message.draftId
      ..message = _gmailMessageFromFidl(message);
    gmail.Draft updatedDraft;
    try {
      updatedDraft =
          await _gmail.users.drafts.update(gmailDraft, 'me', message.draftId);
    } catch (e) {
      log.fine('exception: $e');
    }
    if (updatedDraft != null) {
      callback(_fidlMessageFromGmail(updatedDraft.id, updatedDraft.message));
    } else {
      callback(_fidlMessageFromGmail(null, new gmail.Message()));
    }
  }

  @override
  Future<Null> sendDraft(
      String draftId, void callback(ecp.Status status)) async {
    final gmail.GmailApi _gmail = await _gmailApi();
    final gmail.Draft gmailDraft = new gmail.Draft();
    // The GMail API only needs a draftId to send an existing draft.
    gmailDraft.id = draftId;
    ecp.Status result = new ecp.Status();
    try {
      await _gmail.users.drafts.send(gmailDraft, 'me');
      result.success = true;
    } catch (e) {
      result.success = false;
      result.message = e.toString();
    }
    callback(result);
  }

  @override
  Future<Null> deleteDraft(String draftId, void callback()) async {
    final gmail.GmailApi _gmail = await _gmailApi();
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
  if (message.payload != null) {
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
  }

  String body = _body(message);
  List<Uri> links = body != null ? extractURI(body) : <Uri>[];

  bool isRead =
      message.labelIds == null ? false : !message.labelIds.contains('UNREAD');

  return new Message(
    id: message.id,
    threadId: message.threadId,
    timestamp: _timestamp(message.internalDate),
    isRead: isRead,
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
  return stamp != null ? int.parse(stamp) : 0;
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
  gmail.MessagePart part;
  if (message.payload != null) {
    part = message.payload.parts
        ?.reduce((gmail.MessagePart previous, gmail.MessagePart current) {
      if (current.mimeType == 'text/plain') {
        return current;
      }
    });
  }

  if (part != null) {
    List<int> base64 = BASE64.decode(part.body.data);
    String utf8 = UTF8.decode(base64);
    return utf8;
  } else {
    return message.snippet;
  }
}
