// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:application.lib.app.dart/app.dart';
import 'package:application.services/service_provider.fidl.dart';
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

  /// Handle the submit event from the UI.
  void handleSubmit(Message message) {
    serviceImpl.handleSubmit(message);
  }
}
