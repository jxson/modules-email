// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:application.lib.app.dart/app.dart';
import 'package:application.services/service_provider.fidl.dart';
import 'package:apps.modular.services.agent.agent_controller/agent_controller.fidl.dart';
import 'package:apps.modular.services.component/component_context.fidl.dart';
import 'package:apps.modular.services.component/message_queue.fidl.dart';
import 'package:apps.modular.services.story/link.fidl.dart';
import 'package:apps.modules.email.services/email_content_provider.fidl.dart'
    as ecp;
import 'package:apps.modules.email.services/email_session.fidl.dart' as es;
import 'package:email_flux/document.dart';
import 'package:email_models/models.dart';
import 'package:lib.fidl.dart/bindings.dart' hide Message;
import 'package:meta/meta.dart';
import 'package:models/user.dart';

const String _kContentProviderAgentUrl =
    'file:///system/apps/email/content_provider';

void _log(String msg) {
  print('[email_session:SessionImpl] $msg');
}

/// Implementation of the [es.EmailSession] FIDL service defined in
/// `//apps/modules/email/services/email_session.fidl`.
///
/// This service talks to the [EmailContentProvider] agent to fetch email and
/// listen for new email. It communicates email content updates to other modules
/// over a [Link].
class EmailSessionImpl extends es.EmailSession {
  /// The Story ID this UI Session belongs to.
  final String storyId;

  /// The Link object shared with UI Modules.
  final Link link;

  /// An instance of [EmailSessionDocument] that wraps UI state in an object
  /// that can be encoded/decoded to JSON for storage in Link content.
  EmailSessionDocument doc;

  /// The Proxy object for interacting with the [ComponentContext].
  final ComponentContextProxy componentContext;

  final List<es.EmailSessionBinding> _bindings = <es.EmailSessionBinding>[];

  final ecp.EmailContentProviderProxy _emailProvider =
      new ecp.EmailContentProviderProxy();
  final AgentControllerProxy _emailAgentController = new AgentControllerProxy();
  final MessageQueueProxy _notificationQueue = new MessageQueueProxy();

  /// Constructor, takes active link.
  EmailSessionImpl({
    @required this.storyId,
    @required this.link,
    @required this.componentContext,
  });

  /// Bind this object to the request.
  void bind(InterfaceRequest<es.EmailSession> request) {
    _bindings.add(new es.EmailSessionBinding()..bind(this, request));
  }

  /// Initializes the email session.
  ///
  /// Connects to necessary email services, and fetches the initial data.
  void initialize() {
    _log('initialize called');

    link.get(EmailSessionDocument.path, handleLinkRead);

    /// Connect to the EmailContentProvider agent and get the
    /// [EmailContentProvider] service.
    ServiceProviderProxy incomingServices = new ServiceProviderProxy();
    componentContext.connectToAgent(
      _kContentProviderAgentUrl,
      incomingServices.ctrl.request(),
      _emailAgentController.ctrl.request(),
    );

    _log('connecting to email provider..');
    connectToService(incomingServices, _emailProvider.ctrl);
    incomingServices.ctrl.close();

    // Setup a message queue; we receive email updates on this queue.
    componentContext.obtainMessageQueue(
      'EmailNotifications',
      _notificationQueue.ctrl.request(),
    );

    // This will only receive 1 update. We must call this again to receive
    // further updates.
    _notificationQueue.receive(_onEmailNotification);

    // Sign up for email updates; provide the message queue to receive updates
    // on.
    _notificationQueue.getToken((String token) {
      _emailProvider.registerForUpdates(storyId, token);
    });
  }

  /// Closes the bindings.
  void close() {
    _bindings.forEach((es.EmailSessionBinding binding) => binding.close());
    _emailAgentController.ctrl.close();
    _emailProvider.ctrl.close();
  }

  /// Load Link data into [this.doc].
  void handleLinkRead(String data) {
    // The very first time the session is run it is possible that the Link
    // will be empty. In that case create an empty document and populate it.
    if (data == null) {
      _log('Link content is empty, creating new document');
      doc = new EmailSessionDocument();
      this.fetchMe();
      this.fetchLabels();
      this.focusLabel('INBOX');
      return;
    }

    Map<String, dynamic> json;

    try {
      json = JSON.decode(data);
    } catch (err) {
      // TODO(SO-392): Don't throw, return an error.
      String message = 'Unable to decode Link data: $err';
      throw new FormatException(message);
    }

    doc = new EmailSessionDocument.fromJson(json);

    _log('Hydrated link, checking for stale data...');

    // Silently fetch data in the background (no spinners) to refresh
    // potentially stale data.
    this.fetchMe(showProgress: false);
    this.fetchLabels(showProgress: false);
    this.fetchThreads(labelId: doc.focusedLabelId, showProgress: false);
  }

  // TODO(SO-394): Intelligently handle updating the UI only if the message is
  // currently being viewed.
  void _onEmailNotification(String message) {
    _log('new email notification: $message');

    // Continue to receive more updates.
    _notificationQueue.receive(_onEmailNotification);
  }

  @override
  void focusLabel(String labelId) {
    _log('Focusing Label: $labelId');

    doc.focusedLabelId = labelId;
    save();

    if (doc.labels[labelId] == null) {
      fetchLabels();
    }

    fetchThreads(
      labelId: labelId,
    );
  }

  @override
  void focusThread(String id) {
    _log('focusThread($id)');

    doc.focusedThreadId = id;
    save();

    if (doc.threads[id] == null) {
      print(
          ' TODO(youngseokyoon): Verify the thread id exists before setting this ');
    }
  }

  @override
  void expandMessage(es.Message originalMessage) {
    Thread thread = doc.threads[originalMessage.threadId];

    if (thread == null) return;

    Message message = thread.messages[originalMessage.id];

    if (message != null) {
      message.expanded = true;
    }

    save();
  }

  @override
  void closeMessage(es.Message originalMessage) {
    Thread thread = doc.threads[originalMessage.threadId];

    if (thread == null) return;

    Message message = thread.messages[originalMessage.id];

    if (message != null) {
      message.expanded = false;
    }

    save();
  }

  /// Get the labels from the email_content_provider agent.
  void fetchLabels({bool showProgress: true}) {
    if (showProgress) {
      doc.fetchingLabels = true;
      save();
    }

    _emailProvider.labels((List<ecp.Label> labels) {
      labels.forEach((ecp.Label fidlLabel) {
        String data = fidlLabel.jsonPayload;
        try {
          Map<String, dynamic> json = JSON.decode(data);
          Label label = new Label.fromJson(json);
          doc.labels[label.id] = label;
        } catch (err) {
          // TODO(SO-392): Don't throw, return an error.
          String message = 'Unable to decode Label: $err';
          throw new FormatException(message);
        }
      });

      _log('Labels fetched...');
      doc.fetchingLabels = false;
      save();
    });
  }

  /// Get the currently logged in user.
  void fetchMe({bool showProgress: true}) {
    if (showProgress) {
      doc.fetchingUser = true;
      save();
    }

    _emailProvider.me((ecp.User user) {
      try {
        Map<String, String> json = JSON.decode(user.jsonPayload);
        doc.user = new User.fromJson(json);
      } catch (err) {
        // TODO(SO-392): Don't throw, return an error.
        String message = 'Unable to decode User: $err';
        throw new FormatException(message);
      }

      doc.fetchingUser = false;
      save();
    });
  }

  /// Get the threads for a given label.
  void fetchThreads({@required String labelId, bool showProgress: true}) {
    if (showProgress) {
      doc.fetchingThreads = true;
      save();
    }

    // TODO(SO-387): Paging to allow loading of more than 20
    _emailProvider.threads(labelId, 20, (List<ecp.Thread> fidlThreads) {
      _log('Recivied ${labelId} threads');

      String first;

      Map<String, Thread> threads = <String, Thread>{};

      fidlThreads.forEach((ecp.Thread thread) {
        String data = thread.jsonPayload;

        try {
          Map<String, dynamic> json = JSON.decode(data);
          Thread thread = new Thread.fromJson(json);
          threads[thread.id] = thread;
          first = first ?? thread.id;
        } catch (err) {
          // TODO(SO-392): Don't throw, return an error.
          String message = 'Unable to decode Thread: $err';
          throw new FormatException(message);
        }
      });

      _log('Decoded ${labelId} threads, saving...');

      // Replace all the threads.
      doc.threads = threads;
      doc.fetchingThreads = false;
      doc.focusedThreadId = first;
      save();
    });
  }

  /// Update the Link data with the encoded JSON string from
  /// [EmailSessionDocument].
  void save() {
    String data = JSON.encode(doc);
    link.updateObject(EmailSessionDocument.path, data);
  }
}
