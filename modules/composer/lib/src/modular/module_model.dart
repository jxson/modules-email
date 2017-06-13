// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
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
import 'package:email_composer/document.dart';
import 'package:email_models/models.dart' as models;
import 'package:lib.logging/logging.dart';
import 'package:lib.widgets/modular.dart';

import 'message_composer_impl.dart';

const Duration _kUpdateDraftDelay = const Duration(seconds: 1);

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
  /// initial link.
  models.Message get message => _message;
  final models.Message _message = new models.Message(
      recipientList: <models.Mailbox>[], subject: '', text: '');

  /// A proxy to the [Link] used for storing internal state.
  final LinkProxy stateLink = new LinkProxy();

  Timer _draftChangeTimer;

  @override
  ServiceProvider get outgoingServiceProvider => _outgoingServiceProvider;

  @override
  void onReady(
    ModuleContext moduleContext,
    Link link,
    ServiceProvider incomingServices,
  ) {
    super.onReady(moduleContext, link, incomingServices);

    log.fine('module ready');

    emailContentProvider.ctrl.onConnectionError = () {
      log.severe('email/content_provider client connection error');
      showStackTrace();
    };

    serviceImpl = new MessageComposerImpl();

    _outgoingServiceProvider.addServiceForName(
      serviceImpl.bind,
      MessageComposer.serviceName,
    );

    moduleContext.getLink('state', stateLink.ctrl.request());

    moduleContext.getComponentContext(componentContext.ctrl.request());

    componentContext.connectToAgent(
      'file:///system/apps/email/content_provider',
      contentProviderServices.ctrl.request(),
      agentController.ctrl.request(),
    );
    connectToService(contentProviderServices, emailContentProvider.ctrl);

    notifyListeners();
  }

  @override
  void onStop() {
    log.fine('module stopping...');
    serviceImpl.close();
    agentController.ctrl.close();
    componentContext.ctrl.close();
    emailContentProvider.ctrl.close();
    stateLink.ctrl.close();

    super.onStop();
  }

  @override
  void onNotify(String data) {
    // TODO(SO-547): Chase down why `mm.onNotify()` is not being called.
    log.fine('notify: $data');

    models.Message m = _parseLinkData(data);
    if (m != null) {
      // TODO(SO-503): This merging logic is kind of hacky
      if (m.id != null) _message.id = m.id;
      if (m.threadId != null) _message.threadId = m.threadId;
      if (m.draftId != null) _message.draftId = m.draftId;
      _handleMessageUpdated(m);
      notifyListeners();
    }

    // Now that we have passed-down configuration, override with stored data
    log.fine('getting state link');
    stateLink.get(null, this._mergeState);
  }

  models.Message _parseLinkData(String data) {
    models.Message result;
    if (data != null && data != 'null') {
      dynamic json = JSON.decode(data);
      if (json != null) {
        String key = EmailComposerDocument.docroot;
        if (json.containsKey(key)) {
          result = new EmailComposerDocument.fromJson(json[key]).message;
        }
      }
    }
    return result;
  }

  // Convert message from models format, used by UI clients, to fidl format,
  // used by IPC clients.
  Message _convertMessage(models.Message message) {
    String data;

    try {
      data = JSON.encode(message);
    } catch (err) {
      // TODO(SO-266): Handle errors appropriately
      log.severe('Error converting message', err);
    }

    return new Message()
      ..id = message.id
      ..threadId = message.threadId
      ..draftId = message.draftId
      ..json = data;
  }

  void _mergeState(String data) {
    log.fine('merge state called $data');

    models.Message m = _parseLinkData(data);
    if (m != null) {
      // TODO(SO-503): This merging logic is kind of hacky
      _message.id = m.id;
      _message.threadId = m.threadId;
      _message.draftId = m.draftId;
      _message.recipientList = message.recipientList;
      _message.subject = message.subject;
      _message.text = message.text;
    }
    if (_message.draftId == null) {
      Message fidlMessage = _convertMessage(_message);
      emailContentProvider.createDraft(fidlMessage, _handleDraftCreated);
    } else if (m == null) {
      // We don't have any state stored, save it
      _storeState();
    }
    notifyListeners();
  }

  void _handleDraftCreated(Message message) {
    // TODO(SO-503): This merging logic is kind of hacky
    _message.id = message.id;
    _message.threadId = message.threadId;
    _message.draftId = message.draftId;
    _storeState();
    notifyListeners();
  }

  void _storeState() {
    EmailComposerDocument doc = new EmailComposerDocument()..message = _message;
    String data = JSON.encode(doc);
    stateLink.updateObject(EmailComposerDocument.path, data);
  }

  void _handleMessageUpdated(models.Message message) {
    log.fine('updating message: $message');

    // Update our model based on new values, but keep IDs
    // TODO(SO-503): This merging logic is kind of hacky
    _message.recipientList = message.recipientList;
    _message.subject = message.subject;
    _message.text = message.text;
  }

  void _handleDraftSent(Status status) {
    log.fine('sendDraft returned: $status');

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
      log.severe('Error sending message: ' + status.message);
    }
  }

  /// Handle the draft changed event from the UI.
  void handleDraftChanged(models.Message message) {
    _handleMessageUpdated(message);

    // Cancel the last timer, if any.
    if (_draftChangeTimer != null && _draftChangeTimer.isActive) {
      _draftChangeTimer.cancel();
    }
    _draftChangeTimer = new Timer(_kUpdateDraftDelay, () {
      Message fidlMessage = _convertMessage(_message);
      emailContentProvider.updateDraft(fidlMessage, (Message m) {
        log.severe('Failed to update draft.');
      });
    });
  }

  /// Handle send events from the UI.
  void handleSend() {
    log.fine('sending message');

    // Make sure the draft is up to date
    _handleMessageUpdated(message);
    // Cancel the update timer, if any.
    if (_draftChangeTimer != null && _draftChangeTimer.isActive) {
      _draftChangeTimer.cancel();
    }
    Message fidlMessage = _convertMessage(_message);

    emailContentProvider.updateDraft(fidlMessage, (Message m) {
      log.fine('sending message: $message');
      emailContentProvider.sendDraft(m.draftId, _handleDraftSent);
    });
  }

  /// Should handle "Delete" events from the UI by:
  ///
  /// * Deleting the current draft.
  /// * Cleaning up module any pending module lifecycle work.
  void handleDelete() {
    log.fine('TODO(SO-548): Delete draft/message.');
    // TODO(SO-548): Handle UI affordances for close, delete, and send.
    moduleContext.done();
  }

  /// Should handle "Close" events from the UI by:
  ///
  /// * Saving the current draft.
  /// * Triggering any listeners.
  /// * Cleaning up module any pending module lifecycle work.
  void handleClose() {
    log.fine('TODO(SO-548): Close module.');
    // TODO(SO-548): Handle UI affordances for close, delete, and send.
    moduleContext.done();
  }
}
