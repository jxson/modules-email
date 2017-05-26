// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:application.lib.app.dart/app.dart';
import 'package:application.services/service_provider.fidl.dart';
import 'package:apps.modular.services.agent.agent_controller/agent_controller.fidl.dart';
import 'package:apps.modular.services.module/module_context.fidl.dart';
import 'package:apps.modular.services.story/link.fidl.dart';
import 'package:apps.modules.email.services.email/email_content_provider.fidl.dart'
    as cp;
import 'package:email_link/document.dart';
import 'package:email_models/models.dart';
import 'package:lib.widgets/modular.dart';

void _log(String message) {
  print('[email/thread - model]: $message');
}

/// The [ModuleModel] for the email thread/detail view.
class EmailThreadModuleModel extends ModuleModel {
  /// A proxy to the [EmailContentProvider] service impl.
  final cp.EmailContentProviderProxy emailContentProvider =
      new cp.EmailContentProviderProxy();

  /// A proxy to the [AgentController], used to connect to the agent.
  final AgentControllerProxy agentController = new AgentControllerProxy();

  /// A proxy to the [ServiceProvider], used to connect to the agent.
  final ServiceProviderProxy contentProviderServices =
      new ServiceProviderProxy();

  /// A proxy to the [ComponentContext], used to connect to the agent.
  final ComponentContextProxy componentContext = new ComponentContextProxy();

  /// The title to display in the app bar.
  String get title => _title;
  String _title = '';

  /// The [Thread] to display.
  Thread get thread => _thread;
  Thread _thread;

  EmailLinkDocument _doc = new EmailLinkDocument();

  /// Is the UI in a "loading" state? Defaults to `false`.
  bool get loading => _loading;
  bool _loading = false;

  @override
  void onReady(
    ModuleContext moduleContext,
    Link link,
    ServiceProvider incomingServices,
  ) {
    super.onReady(moduleContext, link, incomingServices);

    moduleContext.getComponentContext(componentContext.ctrl.request());

    componentContext.connectToAgent(
      'file:///system/apps/email/content_provider',
      contentProviderServices.ctrl.request(),
      agentController.ctrl.request(),
    );
    connectToService(contentProviderServices, emailContentProvider.ctrl);
  }

  @override
  void onStop() {
    agentController.ctrl.close();
    componentContext.ctrl.close();
    emailContentProvider.ctrl.close();

    super.onStop();
  }

  @override
  void onNotify(String data) {
    if (data == null) return;

    Map<String, dynamic> root;

    try {
      root = JSON.decode(data);
    } catch (err) {
      // TODO(jasoncampbell): Figure out its possible to chain error causes in
      // Dart similar to Rust's error-chain or Node's verror. See SO-392.
      // TODO(SO-42): Handle errors better.
      String message = 'Unable to JSON.decode Link data: $err';
      throw new FormatException(message);
    }

    if (root == null) return;

    // NOTE: Link.watch doesn't take a query like Link.get, etc. so the
    // docroot must be checked for here.
    Map<String, dynamic> json = root[EmailLinkDocument.docroot];
    if (json == null) return;

    String previousThreadId = _doc.threadId;
    String previousLabelId = _doc.labelId;
    this._doc = new EmailLinkDocument.fromJson(json);
    bool threadUpdated = previousThreadId != _doc.threadId;
    bool labelUpdated = previousLabelId != _doc.labelId;

    if (threadUpdated) {
      this._loading = true;
      notifyListeners();

      getThread(_doc.threadId).then((Thread thread) {
        _thread = thread;
        _title = thread.subject;
        this._loading = false;

        notifyListeners();
      });
    }

    if (labelUpdated) {
      _log('Label changed, removing unrelated thread.');
      _thread = null;
      notifyListeners();
    }
  }

  /// Toggle message expansion.
  void handleSelect(Message message) {
    if (message.expanded) {
      thread.messages[message.id]?.expanded = false;
    } else {
      thread.messages[message.id]?.expanded = true;
    }

    notifyListeners();
  }

  /// Archive thread.
  void handleArchive(Thread thread) {
    _log('TODO: handle archive.');
  }

  /// Move thread to trash.
  void handleTrash(Thread thread) {
    _log('TODO: handle fowarding messages');
  }

  /// Respond to the forward button being pressed.
  void handleForward(Message message) {
    _log('TODO: handle fowarding messages');
  }

  /// Respond to the forward button being pressed.
  void handleReplyAll(Message message) {
    _log('TODO: handle reply all');
  }

  /// Respond to the forward button being pressed.
  void handleReply(Message message) {
    print('TODO: handle reply');
  }

  /// Get a [Thread]s from the content provider.
  Future<Thread> getThread(String id) {
    Completer<Thread> completer = new Completer<Thread>();

    _log('fetching thread ${id}');

    emailContentProvider.getThread(id, (cp.Thread result) {
      _log('got thread ${id}');
      String data = result.jsonPayload;

      try {
        Map<String, dynamic> json = JSON.decode(data);
        Thread thread = new Thread.fromJson(json);
        completer.complete(thread);
      } catch (err) {
        // TODO(SO-392): Don't throw, return an error.
        String message = 'Unable to decode Thread: $err';
        Exception error = new FormatException(message);
        completer.completeError(error);
      }
    });

    return completer.future;
  }
}
