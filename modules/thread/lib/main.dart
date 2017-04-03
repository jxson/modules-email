// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:application.lib.app.dart/app.dart';
import 'package:apps.maxwell.services.resolver/resolver.fidl.dart' as resolver;
import 'package:apps.modular.services.module/module_controller.fidl.dart';
import 'package:apps.modular.services.story/link.fidl.dart';
import 'package:apps.modules.email.services/email_session.fidl.dart' as es;
import 'package:apps.mozart.lib.flutter/child_view.dart';
import 'package:email_session_client/client.dart';
import 'package:email_session_store/email_session_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_flux/flutter_flux.dart';
import 'package:lib.fidl.dart/bindings.dart';
import 'package:widgets/email.dart';

const String _moduleName = 'email_thread';
final ApplicationContext _context = new ApplicationContext.fromStartupInfo();
EmailSessionModule _module;
resolver.ResolverProxy _resolver;

void _log(String msg) {
  print('[$_moduleName] $msg');
}

void _created(EmailSessionModule module) {
  _module = module;
  _resolver = new resolver.ResolverProxy();
  connectToService(_context.environmentServices, _resolver.ctrl);
}

void _initialize(es.EmailSession service, EmailSessionLinkStore store) {
  // HACK: Global reference must be set before store is accessed by widgets.
  kEmailSessionStoreToken = new StoreToken(store);

  _addEmbeddedChildBuilder();

  runApp(new MaterialApp(
    title: 'Email Thread Module',
    home: new EmailThreadScreen(),
    theme: new ThemeData(primarySwatch: Colors.blue),
    debugShowCheckedModeBanner: false,
  ));
}

void _stop(void callback()) {
  callback();
}

/// Main entry point to the email thread module.
void main() {
  _log('Email thread module started with context: $_context');
  addEmailSessionModule(_context, _moduleName, _created, _initialize, _stop);
}

void _addEmbeddedChildBuilder() {
  kEmbeddedChildProvider.setGeneralEmbeddedChildBuilder(({
    String docRoot,
    String type,
    String propKey,
    String contract,
    dynamic value,
    EmbeddedChildAdder childAdder,
  }) {
    String encodedChildDoc = null;
    if (docRoot != null && propKey != null && propKey is String) {
      Map<String, dynamic> childDoc = <String, dynamic>{
        propKey: value,
        '@type': type
      };
      encodedChildDoc = JSON.encode(childDoc);
    }

    _resolver.resolveModules(contract, encodedChildDoc,
        (List<resolver.ModuleInfo> modules) {
      if (modules.length < 1) {
        throw new Exception("No modules found to display attachment!");
      }
      String moduleUrl = modules[0].componentId;

      // Create a new link, add necessary data to it, and create a duplicate of
      // it to be passed to the sub-module.
      LinkProxy link = new LinkProxy();
      _module.moduleContext.createLink(type, link.ctrl.request());
      if (encodedChildDoc != null) {
        link.set(<String>[docRoot], encodedChildDoc);
      }
      ModuleControllerProxy moduleController = new ModuleControllerProxy();
      InterfacePair<ViewOwner> viewOwnerPair = new InterfacePair<ViewOwner>();

      _module.moduleContext.startModule(
        moduleUrl,  // module name
        moduleUrl,
        link.ctrl.unbind(),
        null,
        null,
        moduleController.ctrl.request(),
        viewOwnerPair.passRequest(),
      );

      InterfaceHandle<ViewOwner> viewOwner = viewOwnerPair.passHandle();
      ChildViewConnection conn = new ChildViewConnection(viewOwner);

      childAdder(new EmbeddedChild(
        widgetBuilder: (_) => new ChildView(connection: conn),
        disposer: () {
          viewOwner.close();
          moduleController.ctrl.close();
        },
        additionalData: moduleController,
      ));
    });
  });
}
