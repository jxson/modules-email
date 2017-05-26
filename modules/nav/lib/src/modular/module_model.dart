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
  print('[email/nav]: $message');
}

/// The [ModuleModel] for the EmailStory.
class EmailNavModuleModel extends ModuleModel {
  /// A proxy to the [EmailContentProvider] service impl.
  final cp.EmailContentProviderProxy emailContentProvider =
      new cp.EmailContentProviderProxy();

  /// A proxy to the [AgentController], used to connect to the agent.
  final AgentControllerProxy agentController = new AgentControllerProxy();

  /// A proxy to the [ServiceProvider], used to connect to the agent.
  ServiceProviderProxy contentProviderServices = new ServiceProviderProxy();

  /// Getter for the [User] object retreived from the [emailContentProvider].
  User get user => _user;
  User _user;

  Map<String, Label> _labels = <String, Label>{};

  /// Getter for the [Label]s retreived from the [emailContentProvider].
  Map<String, Label> get labels => _labels;

  /// The currently selected [Label]'s id.
  String get selectedLabelId => _doc.labelId;

  EmailLinkDocument _doc = new EmailLinkDocument();

  @override
  void onReady(
    ModuleContext moduleContext,
    Link link,
    ServiceProvider incomingServices,
  ) {
    super.onReady(moduleContext, link, incomingServices);

    ComponentContextProxy componentContext = new ComponentContextProxy();
    moduleContext.getComponentContext(componentContext.ctrl.request());

    componentContext.connectToAgent(
      'file:///system/apps/email/content_provider',
      contentProviderServices.ctrl.request(),
      agentController.ctrl.request(),
    );
    connectToService(contentProviderServices, emailContentProvider.ctrl);

    // Fetch data needed for the UI in paralell, close connections when done.
    Future.wait(<Future<Null>>[
      getUser().then((User user) {
        _user = user;
        notifyListeners();
      }).catchError((Error error) => _log('error fetching user: $error')),
      getLabels().then((Map<String, Label> labels) {
        _labels = labels;
        notifyListeners();
      }).catchError((Error error) => _log('error fetching user: $error')),
    ]).then((List<Null> results) {
      _log('ready');

      componentContext.ctrl.close();
      emailContentProvider.ctrl.close();
      agentController.ctrl.close();
    });

    link.get(EmailLinkDocument.path, (String data) {
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
    });
  }

  /// Fetches a [User], asyncronously from the [emailContentProvider].
  Future<User> getUser() {
    Completer<User> completer = new Completer<User>();

    _log('fetching user');
    // TODO(SO-392): Calls should accomodate possible errors.
    emailContentProvider.me((cp.User res) {
      _log('got user');

      try {
        Map<String, String> json = JSON.decode(res.jsonPayload);
        User user = new User.fromJson(json);
        completer.complete(user);
      } catch (err) {
        String message = 'Unable to decode User: $err';
        Exception error = new FormatException(message);
        completer.completeError(error);
      }
    });

    return completer.future;
  }

  /// Fetches [Label]s, asyncronously from the [emailContentProvider].
  Future<Map<String, Label>> getLabels() {
    Completer<Map<String, Label>> completer =
        new Completer<Map<String, Label>>();
    Map<String, Label> labels = <String, Label>{};

    _log('fetching labels');
    emailContentProvider.labels((List<cp.Label> list) {
      _log('got labels');

      // Because it is possible to error while looping over the results an
      // iterator is used to to control the loop in the error case.
      for (final cp.Label item in list) {
        String data = item.jsonPayload;
        try {
          Map<String, dynamic> json = JSON.decode(data);
          Label label = new Label.fromJson(json);
          labels[label.id] = label;
        } catch (err) {
          String message = 'Unable to decode Label: $err';
          Exception error = new FormatException(message);
          completer.completeError(error);
          break;
        }
      }

      completer.complete(labels);
    });

    return completer.future;
  }

  @override
  void onStop() {
    super.onStop();
  }

  /// Method to handle label selection triggered by the UI.
  void handleSelectedLabel(Label label) {
    if (label.id == selectedLabelId) return;

    _doc.labelId = label.id;

    String data = JSON.encode(_doc);
    link.updateObject(EmailLinkDocument.path, data);

    notifyListeners();
  }
}
