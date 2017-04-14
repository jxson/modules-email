// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:application.lib.app.dart/app.dart';
import 'package:application.services/service_provider.fidl.dart';
import 'package:apps.modular.services.module/module_context.fidl.dart';
import 'package:apps.modular.services.story/link.fidl.dart';
import 'package:apps.modules.email.services/email_session.fidl.dart' as es;
import 'package:email_flux/document.dart';
import 'package:email_flux/flux.dart';
import 'package:email_models/models.dart';
import 'package:lib.widgets/modular.dart';
import 'package:meta/meta.dart';

void _log(String message) {
  print('[email_session] $message');
}

/// A generic [ModuleModel] that can be used by any UI model consuming the
/// shared Link content manages by the email session service.
class EmailSessionModuleModel extends ModuleModel {
  /// Name of the Module using this [EmailSessionModuleModel], for debugging.
  String name;

  /// The [EmailFluxStore] used to trigger UI updates from the [Link] content.
  EmailFluxStore fluxStore;

  /// [EmailSession] service obtained from the incoming [ServiceProvider].
  final es.EmailSessionProxy service = new es.EmailSessionProxy();

  /// Construct [EmailSessionModuleModel].
  EmailSessionModuleModel({
    @required this.fluxStore,
    @required this.name,
  });

  /// Print a message for this specific instance.
  void log(String message) {
    _log('[$name] $message');
  }

  @override
  void onReady(
    ModuleContext moduleContext,
    Link link,
    ServiceProvider incomingServices,
  ) {
    super.onReady(moduleContext, link, incomingServices);

    // NOTE: The path is explicitly set to "null" instead of
    // [EmailSessionDocument.path] since handleLinkUpdate will negotiate
    // hydrating from the correct docroot.
    link.get(null, handleLinkUpdate);

    // Connect to the email_session module's FIDL interface.
    connectToService(incomingServices, service.ctrl);

    // Listen to triggered UI actions.
    EmailFluxActions.selectLabel.listen(handleSelectedLabel);
    EmailFluxActions.selectThread.listen(handleSelectedThread);
    EmailFluxActions.expandMessage.listen(handleMessageExpanded);
    EmailFluxActions.closeMessage.listen(handleMessageClosed);

    notifyListeners();
  }

  @override
  void onNotify(String data) {
    handleLinkUpdate(data);
  }

  @override
  void onStop() {
    fluxStore.dispose();
    service.ctrl.close();

    super.onStop();
  }

  /// Use the email session service to expand the message.
  void handleMessageExpanded(Message message) {
    service.expandMessage(new es.Message.init(
      message.id,
      message.threadId,
    ));
  }

  /// Use the email session service to close the message.
  void handleMessageClosed(Message message) {
    service.closeMessage(new es.Message.init(
      message.id,
      message.threadId,
    ));
  }

  /// Focus the given Label through the email session service.
  void handleSelectedLabel(Label label) {
    if (label.id == fluxStore.focusedLabelId) return;

    service.focusLabel(label.id);
  }

  /// Listener for Thread selection.
  void handleSelectedThread(Thread thread) {
    if (thread.id == fluxStore.focusedThreadId) return;
    service.focusThread(thread.id);
  }

  /// Listener for Link updates.
  void handleLinkUpdate(String data) {
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

    // The first time this runs it could be empty, if that is the case the
    // email_session module will handle populating content.
    if (root == null) return;

    // NOTE: Link.watch doesn't take a query like Link.get, etc. so the docroot
    // must be checked for here.
    Map<String, dynamic> json = root[EmailSessionDocument.docroot];
    if (json == null) return;

    EmailSessionDocument doc = new EmailSessionDocument.fromJson(json);
    fluxStore.update(doc);
  }
}
