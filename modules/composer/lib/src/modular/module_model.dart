// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:application.lib.app.dart/app.dart';
import 'package:application.services/service_provider.fidl.dart';
import 'package:apps.maxwell.services.action_log/component.fidl.dart';
import 'package:apps.maxwell.services.user/intelligence_services.fidl.dart';
import 'package:apps.modular.services.agent.agent_controller/agent_controller.fidl.dart';
import 'package:apps.modular.services.module/module_context.fidl.dart';
import 'package:apps.modular.services.story/link.fidl.dart';
import 'package:apps.modules.email.services.email/email_content_provider.fidl.dart';
import 'package:apps.modules.email.services.messages/message.fidl.dart';
import 'package:apps.modules.email.services.messages/message_composer.fidl.dart';
import 'package:email_models/models.dart' as models;
import 'package:lib.widgets/modular.dart';

import 'message_composer_impl.dart';

/// The [ModuleModel] for the EmailStory.
class EmailComposerModuleModel extends ModuleModel {
  /// The service implementation for the composer's FIDL interface.
  MessageComposerImpl serviceImpl;

  final ServiceProviderImpl _outgoingServiceProvider =
      new ServiceProviderImpl();

  /// A proxy to the [EmailContentProvider] service impl.
  final EmailContentProviderProxy emailContentProvider =
      new EmailContentProviderProxy();

  /// A proxy to the [AgentController], used to connect to the agent.
  final AgentControllerProxy agentController = new AgentControllerProxy();

  /// A proxy to the [ServiceProvider], used to connect to the agent.
  final ServiceProviderProxy contentProviderServices =
      new ServiceProviderProxy();

  /// A proxy to the [ComponentContext], used to connect to the agent.
  final ComponentContextProxy componentContext = new ComponentContextProxy();

  /// The message associated with this composer instance. It's obtained from the
  /// intial link.
  models.Message get message => _message;
  final models.Message _message = new models.Message(
      recipientList: <models.Mailbox>[], subject: '', text: '');

  /// The draft associated with this composer instance. It's obtained from the
  /// intial link.
  Draft get draft => _draft;
  Draft _draft = new Draft();

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

    moduleContext.getComponentContext(componentContext.ctrl.request());

    componentContext.connectToAgent(
      'file:///system/apps/email/content_provider',
      contentProviderServices.ctrl.request(),
      agentController.ctrl.request(),
    );
    connectToService(contentProviderServices, emailContentProvider.ctrl);

    Message fidlMessage = _convertMessage(message);
    emailContentProvider.createDraft(fidlMessage, _handleDraftCreated);

    notifyListeners();
  }

  @override
  void onStop() {
    serviceImpl.close();
    agentController.ctrl.close();
    componentContext.ctrl.close();
    emailContentProvider.ctrl.close();
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
    models.Message m =
        new models.Message.fromJson(decoded['email-composer']['message']);
    _handleMessageUpdated(m);
    notifyListeners();
  }

  // Convert message from models format, used by UI clients, to fidl format,
  // used by IPC clients.
  Message _convertMessage(models.Message message) {
    String data;

    try {
      data = JSON.encode(message);
    } catch (err) {
      // TODO(SO-266): Handle errors appropriately
      print('Error converting message: $err');
    }

    return new Message()
      ..id = message.id
      ..threadId = message.threadId
      ..json = data;
  }

  void _handleDraftCreated(Draft draft, Message message) {
    _draft = draft;
    // TODO(SO-503): This merging logic is kind of hacky
    _message.id = message.id;
    _message.threadId = message.threadId;
  }

  void _handleMessageUpdated(models.Message message) {
    // Update our model based on new values, but keep IDs
    // TODO(SO-503): This merging logic is kind of hacky
    _message.recipientList = message.recipientList;
    _message.subject = message.subject;
    _message.text = message.text;
  }

  void _handleDraftSent(Status status) {
    if (status.success) {
      // Notify listeners of the submit event
      serviceImpl.handleSubmit(_convertMessage(message));

      // Log sending of emails to TQI action log.
      IntelligenceServicesProxy intelligenceServices =
          new IntelligenceServicesProxy();
      moduleContext
          .getIntelligenceServices(intelligenceServices.ctrl.request());
      ComponentActionLogProxy actionLog = new ComponentActionLogProxy();
      intelligenceServices.getActionLog(actionLog.ctrl.request());
      actionLog.logAction('SendEmail', JSON.encode(message.toJson()));
      intelligenceServices.ctrl.close();
      actionLog.ctrl.close();

      // This module's task is done
      moduleContext.done();
    } else {
      // TODO(SO-266): Handle errors appropriately
      print('Error sending message: ' + status.message);
    }
  }

  /// Handle the draft changed event from the UI.
  void handleDraftChanged(models.Message message) {
    _handleMessageUpdated(message);
  }

  /// Handle the submit event from the UI.
  void handleSubmit(models.Message message) {
    // Make sure the draft is up to date
    _handleMessageUpdated(message);
    Message fidlMessage = _convertMessage(_message);
    emailContentProvider.updateDraft(draft.id, fidlMessage, (Message m) {
      // Send the message
      emailContentProvider.sendDraft(draft.id, _handleDraftSent);
    });
  }

  /// Handle the close event from the UI.
  void handleClose() {
    moduleContext.done();
  }
}
