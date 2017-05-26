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
import 'package:email_composer/document.dart';
import 'package:email_link/document.dart';
import 'package:email_models/models.dart';
import 'package:lib.widgets/modular.dart';

void _log(String message) {
  print('[email/thread_list - model]: $message');
}

/// The [ModuleModel] for the EmailStory.
class EmailThreadListModuleModel extends ModuleModel {
  /// A proxy to the [EmailContentProvider] service impl.
  final cp.EmailContentProviderProxy emailContentProvider =
      new cp.EmailContentProviderProxy();

  /// A proxy to the [AgentController], used to connect to the agent.
  final AgentControllerProxy agentController = new AgentControllerProxy();

  /// A proxy to the [ServiceProvider], used to connect to the agent.
  ServiceProviderProxy contentProviderServices = new ServiceProviderProxy();

  /// A proxy to the [ComponentContext], used to connect to the agent.
  ComponentContextProxy componentContext = new ComponentContextProxy();

  /// The [Thread] objects to display: retreived from the
  /// [emailContentProvider].
  Map<String, Thread> get threads => _threads;
  Map<String, Thread> _threads = <String, Thread>{};

  /// ID of the currently active thread: retreived from the
  /// [link].
  String get selectedThreadId => _doc.threadId;

  /// The title to display in the app bar.
  String title = '';

  EmailLinkDocument _doc = new EmailLinkDocument();

  /// Is the UI in a "loading" state?
  bool loading = false;

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

    link.get(EmailLinkDocument.path, (String data) {
      _log('initial link value: $data');

      /// This should never happen but it should be accounted for.
      if (data == null) return;

      try {
        Map<String, String> json = JSON.decode(data);
        _doc = new EmailLinkDocument.fromJson(json);
      } catch (err) {
        // TODO(SO-392): Don't throw, return an error.
        String message = 'Unable to decode Link data: $err';
        throw new FormatException(message);
      }

      notifyListeners();

      _update();
    });
  }

  @override
  void onStop() {
    super.onStop();

    componentContext.ctrl.close();
    emailContentProvider.ctrl.close();
    agentController.ctrl.close();
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
      String message = 'Unable to JSON.decode Link data: $err';
      throw new FormatException(message);
    }

    // The first time this runs it could be empty.
    if (root == null) return;

    // NOTE: Link.watch doesn't take a query like Link.get, etc. so the
    // docroot must be checked for here.
    Map<String, dynamic> json = root[EmailLinkDocument.docroot];
    if (json == null) return;

    String _last = _doc.labelId;
    _doc = new EmailLinkDocument.fromJson(json);
    bool labelUpdated = _doc.labelId != _last;

    if (labelUpdated) {
      _update();
    }

    notifyListeners();
  }

  /// Method for handling events triggered by the UI when a [Thread] is
  /// selected.
  void handleThreadSelected(Thread thread) {
    if (thread.id == _doc.threadId) return;

    _doc.threadId = thread.id;

    String data = JSON.encode(_doc);
    link.updateObject(EmailLinkDocument.path, data);

    notifyListeners();
  }

  /// Method for handling events triggered by the UI when the "archive thread"
  /// affordance is used.
  void handleThreadArchived(Thread thread) {
    _log('TODO: handle thread archived "${thread.id}"');
  }

  /// Method to trigger the launching of the email/composer module from the
  /// UI.
  ///
  /// NOTE: Currently this method signals the email/story module to launch the
  /// composer by updating the Link object with an email/composer specific
  /// document.
  ///
  /// TODO(SO-467): use story shell API's to launch email modules.
  void launchComposer() {
    _log('launching email/composer via link');
    EmailComposerDocument doc = new EmailComposerDocument();
    String data = JSON.encode(doc);
    link.updateObject(EmailComposerDocument.path, data);
  }

  /// Fetches data needed to render UI.
  void _update() {
    _log('fetching data for UI update');

    this.loading = true;
    notifyListeners();

    // Fetch Label and Thread in paralell.
    Future.wait(<Future<Null>>[
      getLabel(_doc.labelId).then((Label label) {
        this.title = label.name;
        // Partially loaded, trigger a render to display the title.
        notifyListeners();
      }),
      getThreads(_doc.labelId).then((Map<String, Thread> threads) {
        _threads = threads;
      }),
    ]).then((List<Null> results) {
      _log('data fetched, rendering.');
      this.loading = false;
      notifyListeners();
    });
  }

  /// Get a [Label] from the content provider.
  Future<Label> getLabel(String id) {
    Completer<Label> completer = new Completer<Label>();

    _log('fetching label "$id"');
    emailContentProvider.getLabel(id, (cp.Label label) {
      _log('got label "$id"');

      completer.complete(new Label(
        id: label.id,
        name: label.name,
      ));
    });

    return completer.future;
  }

  /// Get a [Thread]s from the content provider.
  Future<Map<String, Thread>> getThreads(String labelId) {
    Completer<Map<String, Thread>> completer =
        new Completer<Map<String, Thread>>();

    _log('fetching threads for ${labelId}');

    // TODO(SO-387): Paging to allow loading of more than 20
    emailContentProvider.threads(labelId, 20, (List<cp.Thread> results) {
      _log('fetched threads for ${labelId}');

      Map<String, Thread> threads = <String, Thread>{};

      results.forEach((cp.Thread thread) {
        String data = thread.jsonPayload;

        try {
          Map<String, dynamic> json = JSON.decode(data);
          Thread thread = new Thread.fromJson(json);
          threads[thread.id] = thread;
        } catch (err) {
          // TODO(SO-392): Don't throw, return an error.
          String message = 'Unable to decode Thread: $err';
          Exception error = new FormatException(message);
          completer.completeError(error);
        }
      });

      completer.complete(threads);
    });

    return completer.future;
  }
}
