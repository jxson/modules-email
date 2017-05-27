// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:application.lib.app.dart/app.dart';
import 'package:apps.maxwell.services.suggestion/proposal_publisher.fidl.dart';
import 'package:apps.modular.services.agent/agent.fidl.dart';
import 'package:apps.modular.services.agent/agent_context.fidl.dart';
import 'package:apps.modular.services.auth/token_provider.fidl.dart';
import 'package:apps.modular.services.component/component_context.fidl.dart';
import 'package:apps.modules.email.services.email/email_content_provider.fidl.dart'
    as ecp;
import 'package:lib.fidl.dart/bindings.dart';
import 'package:lib.modular/modular.dart';
import 'package:meta/meta.dart';

import 'src/content_provider_impl.dart';

EmailContentProviderAgent _agent;

void _log(String msg) {
  print('[email_content_provider:main] $msg');
}

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
    _log('onReady start.');

    // Get the ProposalPublisher
    ProposalPublisherProxy proposalPublisher = new ProposalPublisherProxy();
    connectToService(
      applicationContext.environmentServices,
      proposalPublisher.ctrl,
    );

    _emailContentProviderImpl = new EmailContentProviderImpl(
      componentContext,
      tokenProvider,
      proposalPublisher,
    );

    outgoingServices.addServiceForName(
      (InterfaceRequest<ecp.EmailContentProvider> request) {
        _log('Received an EmailContentProvider request');
        _emailContentProviderImpl.addBinding(request);
      },
      ecp.EmailContentProvider.serviceName,
    );

    // NOTE: Temporarily disabling the scheduled task.
    // SEE:
    // https://fuchsia.atlassian.net/browse/FW-191
    // https://fuchsia.atlassian.net/browse/SO-389
    agentContext.deleteTask('refresh_timer');

    // Schedule a periodically running task for checking new emails.
    // final TaskInfo taskInfo = new TaskInfo();
    // taskInfo.taskId = 'refresh_timer';
    // taskInfo.triggerCondition = new TriggerCondition();
    // taskInfo.triggerCondition.alarmInSeconds = kRefreshPeriodSecs;
    // agentContext.scheduleTask(taskInfo);

    await _emailContentProviderImpl.init();

    _log('onReady end.');
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
  _agent = new EmailContentProviderAgent(
    applicationContext: new ApplicationContext.fromStartupInfo(),
  );
  _agent.advertise();
}
