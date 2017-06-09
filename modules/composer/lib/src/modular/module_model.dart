// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:application.lib.app.dart/app.dart';
import 'package:application.services/service_provider.fidl.dart';
import 'package:apps.maxwell.services.action_log/component.fidl.dart';
import 'package:apps.maxwell.services.user/intelligence_services.fidl.dart';
import 'package:apps.modular.services.module/module_context.fidl.dart';
import 'package:apps.modular.services.story/link.fidl.dart';
import 'package:apps.modules.email.services.messages/message_composer.fidl.dart';
import 'package:email_models/models.dart';
import 'package:lib.widgets/modular.dart';

import 'message_composer_impl.dart';

/// The [ModuleModel] for the EmailStory.
class EmailComposerModuleModel extends ModuleModel {
  /// The service implementation for the composer's FIDL interface.
  MessageComposerImpl serviceImpl;

  final ServiceProviderImpl _outgoingServiceProvider =
      new ServiceProviderImpl();

  /// The message associated with this composer instance. It's obtained from the
  /// intial link.
  Message get message => _message;
  Message _message = new Message();

  @override
  ServiceProvider get outgoingServiceProvider => _outgoingServiceProvider;

  @override
  void onReady(
    ModuleContext moduleContext,
    Link link,
    ServiceProvider incomingServices,
  ) {
    super.onReady(moduleContext, link, incomingServices);

    serviceImpl = new MessageComposerImpl();

    _outgoingServiceProvider.addServiceForName(
      serviceImpl.bind,
      MessageComposer.serviceName,
    );

    notifyListeners();
  }

  @override
  void onStop() {
    serviceImpl.close();
    super.onStop();
  }

  @override
  void onNotify(String json) {
    if (json == null || json == 'null') {
      return;
    }

    dynamic decoded = JSON.decode(json);
    if (decoded == null) {
      return;
    }
    _message = new Message.fromJson(decoded['email-composer']['message']);
    notifyListeners();
  }

  /// Handle the submit event from the UI.
  void handleSubmit(Message message) {
    // Log sending of emails to TQI action log.
    IntelligenceServicesProxy intelligenceServices =
        new IntelligenceServicesProxy();
    moduleContext.getIntelligenceServices(intelligenceServices.ctrl.request());
    ComponentActionLogProxy actionLog = new ComponentActionLogProxy();
    intelligenceServices.getActionLog(actionLog.ctrl.request());
    actionLog.logAction('SendEmail', JSON.encode(message.toJson()));
    intelligenceServices.ctrl.close();
    actionLog.ctrl.close();

    serviceImpl.handleSubmit(message);
    moduleContext.done();
  }

  /// Handle the close event from the UI.
  void handleClose() {
    moduleContext.done();
  }
}
