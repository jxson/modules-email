// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:application.lib.app.dart/app.dart';
import 'package:application.services/service_provider.fidl.dart';
import 'package:apps.modular.services.module/module_context.fidl.dart';
import 'package:apps.modular.services.module/module_controller.fidl.dart';
import 'package:apps.modular.services.module/module_state.fidl.dart';
import 'package:apps.modular.services.story/link.fidl.dart';
import 'package:apps.modules.email.services.messages/message.fidl.dart';
import 'package:apps.modules.email.services.messages/message_composer.fidl.dart';
import 'package:apps.mozart.lib.flutter/child_view.dart';
import 'package:apps.mozart.services.views/view_token.fidl.dart';
import 'package:email_composer/document.dart';
import 'package:lib.fidl.dart/bindings.dart'
    show InterfaceHandle, InterfaceRequest, InterfacePair;
import 'package:lib.fidl.dart/core.dart';
import 'package:lib.widgets/modular.dart';

import 'message_listener_impl.dart';

final String _kEmailComposerUrl = 'file:///system/apps/email/composer';
final String _kEmailSessionUrl = 'file:///system/apps/email/session';
final String _kEmailNavUrl = 'file:///system/apps/email/nav';
final String _kEmailThreadListUrl = 'file:///system/apps/email/thread_list';
final String _kEmailThreadUrl = 'file:///system/apps/email/thread';

void _log(String message) {
  print('[email/story - model]: $message');
}

class _DoneWatcher extends ModuleWatcher {
  VoidCallback onDone;
  _DoneWatcher({
    this.onDone,
  });
  @override
  void onStateChange(ModuleState newState) {
    if (newState == ModuleState.done) {
      this.onDone();
    }
  }
}

/// The [ModuleModel] for the EmailStory.
class EmailStoryModuleModel extends ModuleModel {
  String _composerLinkName;

  ChildViewConnection _navConnection;
  ChildViewConnection _threadListConnection;
  ChildViewConnection _threadConnection;
  ChildViewConnection _composerConnection;

  /// Gets the [ChildViewConnection] for the Nav Module.
  ChildViewConnection get navConnection => _navConnection;

  /// Gets the [ChildViewConnection] for the Thread List Module.
  ChildViewConnection get threadListConnection => _threadListConnection;

  /// Gets the [ChildViewConnection] for the Thread Module.
  ChildViewConnection get threadConnection => _threadConnection;

  /// Gets the [ChildViewConnection] for the message composer.
  ChildViewConnection get composerConnection => _composerConnection;

  ModuleControllerProxy _composerController;
  ModuleWatcherBinding _composerWatcherBinding;

  @override
  void onReady(
    ModuleContext moduleContext,
    Link link,
    ServiceProvider incomingServices,
  ) {
    super.onReady(moduleContext, link, incomingServices);

    // Launch modules that will be embedded.
    _navConnection = new ChildViewConnection(startModule(url: _kEmailNavUrl));

    _threadListConnection =
        new ChildViewConnection(startModule(url: _kEmailThreadListUrl));

    _threadConnection =
        new ChildViewConnection(startModule(url: _kEmailThreadUrl));

    notifyListeners();
  }

  @override
  void onNotify(String data) {
    if (data == null) return;

    /// Uses the link update as a way to detect if the email composition
    /// module should be launched.
    ///
    /// TODO(SO-467): use story shell API's to launch email modules.
    String key = EmailComposerDocument.docroot;
    Map<String, dynamic> json = JSON.decode(data);
    if (json != null && json.containsKey(key)) {
      EmailComposerDocument doc = new EmailComposerDocument.fromJson(json[key]);
      launchComposerModule(doc);
      link.erase(EmailComposerDocument.path);
    }
  }

  @override
  void onStop() {
    _navConnection = null;
    _threadListConnection = null;
    _composerConnection = null;
    super.onStop();
  }

  /// Start a module and return its [ViewOwner] handle.
  InterfaceHandle<ViewOwner> startModule({
    String url,
    InterfaceHandle<ServiceProvider> outgoingServices,
    InterfaceRequest<ServiceProvider> incomingServices,
  }) {
    InterfacePair<ViewOwner> viewOwnerPair = new InterfacePair<ViewOwner>();
    InterfacePair<ModuleController> moduleControllerPair =
        new InterfacePair<ModuleController>();

    // module name is the module url
    String name = url;

    _log('Starting sub-module: $url');
    moduleContext.startModule(
      name,
      url,
      null, // Pass the stories default link to child modules.
      outgoingServices,
      incomingServices,
      moduleControllerPair.passRequest(),
      viewOwnerPair.passRequest(),
    );
    _log('Started sub-module: $url');

    return viewOwnerPair.passHandle();
  }

  /// Launch the email composer module.
  void launchComposerModule(EmailComposerDocument doc) {
    // Leep track of the link name so the message handlers can reference the
    // Link.
    _composerLinkName = doc.linkName;

    // Create link and populated it for composer module.
    LinkProxy composerLink = new LinkProxy();
    moduleContext.getLink(doc.linkName, composerLink.ctrl.request());
    String data = JSON.encode(doc);
    composerLink.set(EmailComposerDocument.path, data);

    // Launch the composer module.
    String name = _kEmailComposerUrl;
    ServiceProviderProxy incomingServices = new ServiceProviderProxy();
    InterfacePair<ViewOwner> viewOwnerPair = new InterfacePair<ViewOwner>();
    _composerController = new ModuleControllerProxy();

    moduleContext.startModule(
      name,
      _kEmailComposerUrl,
      doc.linkName,
      null,
      incomingServices.ctrl.request(),
      _composerController.ctrl.request(),
      viewOwnerPair.passRequest(),
    );

    composerLink.ctrl.close();

    _composerWatcherBinding = new ModuleWatcherBinding();
    _composerController.watch(_composerWatcherBinding
        .wrap(new _DoneWatcher(onDone: this.handleComposerDone)));

    _composerConnection = new ChildViewConnection(viewOwnerPair.passHandle());
    MessageComposerProxy composerService = new MessageComposerProxy();

    MessageListenerImpl listenerImpl = new MessageListenerImpl(
      onSubmitted: handleMessageSubmitted,
      onChanged: handleMessageChanged,
    );

    connectToService(incomingServices, composerService.ctrl);
    composerService.addMessageListener(listenerImpl.getHandle());
    composerService.ctrl.close();
    incomingServices.ctrl.close();

    // Notify child Widgets that the module is ready to render.
    notifyListeners();
  }

  /// Callback handler for [MessageListenerImpl.onSubmitted].
  void handleMessageSubmitted(Message message) {
    print('email/story: send message not implemented: ${message?.json}');
  }

  /// Callback handler for [MessageListenerImpl.onChanged].
  void handleMessageChanged(Message message) {
    print('email/story: change event not implemented.');
  }

  /// Callback handler for handling done state in [ModuleWatcher.onStateChange].
  void handleComposerDone() {
    _composerController.stop(() {
      LinkProxy composerLink = new LinkProxy();
      moduleContext.getLink(_composerLinkName, composerLink.ctrl.request());
      composerLink.erase(EmailComposerDocument.path);
      composerLink.ctrl.close();

      _composerWatcherBinding.close();
      _composerWatcherBinding = null;
      _composerController.ctrl.close();
      _composerController = null;
      _composerConnection = null;

      notifyListeners();
    });
  }
}

/// A wrapper class for duplicating ServiceProvider
class ServiceProviderWrapper extends ServiceProvider {
  final ServiceProviderBinding _binding = new ServiceProviderBinding();

  /// The original [ServiceProvider] instance that this class wraps.
  final ServiceProvider serviceProvider;

  /// Creates a new [ServiceProviderWrapper] with the given [ServiceProvider].
  ServiceProviderWrapper(this.serviceProvider);

  /// Gets the [InterfaceHandle] for this [ServiceProvider] wrapper.
  ///
  /// The returned handle should only be used once.
  InterfaceHandle<ServiceProvider> getHandle() => _binding.wrap(this);

  /// Closes the binding.
  void close() => _binding.close();

  @override
  void connectToService(String serviceName, Channel channel) {
    serviceProvider.connectToService(serviceName, channel);
  }
}
