// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:application.lib.app.dart/app.dart';
import 'package:apps.maxwell.services.suggestion/proposal_publisher.fidl.dart';
import 'package:apps.maxwell.services.user/intelligence_services.fidl.dart';
import 'package:apps.modular.services.agent/agent.fidl.dart';
import 'package:apps.modular.services.agent/agent_context.fidl.dart';
import 'package:apps.modular.services.auth/token_provider.fidl.dart';
import 'package:apps.modular.services.component/component_context.fidl.dart';
import 'package:apps.modules.email.services.email/email_content_provider.fidl.dart'
    as ecp;
import 'package:lib.fidl.dart/bindings.dart';
import 'package:lib.logging/logging.dart';
import 'package:lib.modular/modular.dart';
import 'package:meta/meta.dart';

import 'src/content_provider_impl.dart';

EmailContentProviderAgent _agent;

/// An implementation of the [Agent] interface, which manages the connection to
/// the email server and handles email related API call requests.
class EmailContentProviderAgent extends AgentImpl {
  EmailContentProviderImpl _emailContentProviderImpl;

  /// Creates a new instance of [EmailContentProviderAgent].
  EmailContentProviderAgent({@required ApplicationContext applicationContext})
      : super(applicationContext: applicationContext);

  @override
  Future<Null> onReady(
    ApplicationContext applicationContext,
    AgentContext agentContext,
    ComponentContext componentContext,
    TokenProvider tokenProvider,
    ServiceProviderImpl outgoingServices,
  ) async {
    log.fine('onReady start.');

    ProposalPublisherProxy proposalPublisher = new ProposalPublisherProxy();
    IntelligenceServicesProxy intelligenceServices =
        new IntelligenceServicesProxy();
    agentContext.getIntelligenceServices(intelligenceServices.ctrl.request());
    intelligenceServices.getProposalPublisher(
      proposalPublisher.ctrl.request(),
    );
    intelligenceServices.ctrl.close();

    _emailContentProviderImpl = new EmailContentProviderImpl(
      componentContext,
      tokenProvider,
      proposalPublisher,
    );

    outgoingServices.addServiceForName(
      (InterfaceRequest<ecp.EmailContentProvider> request) {
        log.fine('Received an EmailContentProvider request');
        _emailContentProviderImpl.addBinding(request);
      },
      ecp.EmailContentProvider.serviceName,
    );

    // Schedule a periodically running task for checking new emails.
    final TaskInfo taskInfo = new TaskInfo();
    taskInfo.taskId = 'refresh_timer';
    taskInfo.triggerCondition = new TriggerCondition();
    taskInfo.triggerCondition.alarmInSeconds = kRefreshPeriodSecs;
    agentContext.scheduleTask(taskInfo);

    await _emailContentProviderImpl.init();

    log.fine('onReady end.');
  }

  @override
  Future<Null> onStop() async {
    _emailContentProviderImpl.close();
  }

  @override
  Future<Null> onRunTask(String taskId) async {
    await _emailContentProviderImpl.onRefresh();
  }
}

/// Main entry point.
Future<Null> main(List<String> args) async {
  setupLogger(
    name: 'email/agent',
    level: Level.INFO,
  );

  _agent = new EmailContentProviderAgent(
    applicationContext: new ApplicationContext.fromStartupInfo(),
  );
  _agent.advertise();
}
