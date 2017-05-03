// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:application.lib.app.dart/app.dart';
import 'package:apps.maxwell.services.resolver/resolver.fidl.dart';
import 'package:apps.modular.services.module/module_context.fidl.dart';
import 'package:apps.modular.services.module/module_controller.fidl.dart';
import 'package:apps.modular.services.story/link.fidl.dart';
import 'package:apps.mozart.lib.flutter/child_view.dart';
import 'package:apps.mozart.services.views/view_token.fidl.dart';
import 'package:email_widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:lib.fidl.dart/bindings.dart';
import 'package:lib.widgets/modular.dart';
import 'package:meta/meta.dart';

const double _kHeight = 800.0;

void _log(String message) {
  print('[email/thread - resolver] $message');
}

/// Used to resolve modules to embed from any links in the message content.
class ModularResolverModel extends ResolverModel {
  /// Needed to launch the resolver with
  final ApplicationContext context;

  /// The enclosing [ModuleModel] instance from which the [ModuleContext] can be
  /// obtained.
  final ModuleModel moduleModel;

  /// [Resolver] proxy.
  final ResolverProxy resolver = new ResolverProxy();

  /// A list of requests to the Resolver service.
  final Map<String, ModuleRequest> requests = <String, ModuleRequest>{};

  /// [ModularResolverModel] Constructor.
  ModularResolverModel({
    @required this.context,
    @required this.moduleModel,
  }) {
    connectToService(context.environmentServices, resolver.ctrl);
  }

  /// Build a widget for the [Uri] based on module resolution:
  ///
  /// Note: temporarily disabled, see #SO-391.
  @override
  Widget build(BuildContext context, Uri uri) {
    ModuleRequest req = resolve(uri);
    Widget widget;

    switch (req.status) {
      case ModuleRequestStatus.loading:
        widget = buildLoader();
        break;
      case ModuleRequestStatus.resolved:
        widget = buildEmbeddedModule(req.connection);
        break;
      case ModuleRequestStatus.notFound:
        return null;
    }

    // TODO(SO-393): Transition embedded module state.
    return widget;
  }

  /// Build the loading widget.
  Widget buildLoader() {
    return new SizedBox(
      width: 50.0,
      height: 50.0,
      child: new CircularProgressIndicator(),
    );
  }

  /// Build a widget with the embedded module.
  Widget buildEmbeddedModule(ChildViewConnection connection) {
    return new SizedBox(
        height: _kHeight,
        child: new Align(
            alignment: FractionalOffset.topCenter,
            child: new Card(
                color: Colors.grey[200],
                child: new Center(
                  child: new ChildView(connection: connection),
                ))));
  }

  /// Method to resolve a module for a given [Uri]. Will return an existing
  /// [ModuleRequest] or kick off a new one.
  ModuleRequest resolve(Uri uri) {
    String id = uri.toString();
    if (requests.containsKey(id)) {
      return requests[id];
    }

    _log('resolving module for "$uri"');

    String contract = 'view';
    Map<String, dynamic> json = <String, dynamic>{
      'uri': uri.toString(),
      'scheme': uri.scheme,
      'host': uri.host,
      'path': uri.path,
      'query parameters': uri.queryParameters,
    };

    requests[id] = new ModuleRequest();

    String data = JSON.encode(json);

    resolver.resolveModules(contract, data, (List<ModuleInfo> modules) async {
      ModuleInfo module = modules[0];

      if (module == null) {
        requests[id].status = ModuleRequestStatus.notFound;
        _log('module not found for "$uri"');
        return;
      }

      await moduleModel.ready;

      LinkProxy link = new LinkProxy();
      moduleModel.moduleContext.getLink(contract, link.ctrl.request());
      if (data != null) {
        link.set(<String>[contract], data);
      }
      link.ctrl.close();
      ChildViewConnection connection = startModule(
        url: module.componentId,
        contract: contract,
      );

      requests[id].status = ModuleRequestStatus.resolved;
      requests[id].connection = connection;

      _log('module resolved for "$uri"');
      notifyListeners();
    });

    return requests[id];
  }

  /// Start a module and return its [ViewOwner] handle.
  ChildViewConnection startModule({
    String url,
    String contract,
  }) {
    InterfacePair<ViewOwner> viewOwnerPair = new InterfacePair<ViewOwner>();
    InterfacePair<ModuleController> moduleControllerpair =
        new InterfacePair<ModuleController>();
    String name = url;

    moduleModel.moduleContext.startModule(
      name,
      url,
      contract,
      null,
      null,
      moduleControllerpair.passRequest(),
      viewOwnerPair.passRequest(),
    );

    return new ChildViewConnection(viewOwnerPair.passHandle());
  }
}

/// Enum of Module Resolution Status.
///
/// Cases not yet covered:
/// * Error - something went wrong.
/// * Not supported for embedding.
enum ModuleRequestStatus {
  /// Loading.
  loading,

  /// Resolved/ready.
  resolved,

  /// Module Not Found.
  notFound,
}

/// Helper class to contain Module Resolution status.
class ModuleRequest {
  /// Current status of Module Resolution.
  ModuleRequestStatus status = ModuleRequestStatus.loading;

  /// Once resolved a [ChildViewConnection] will be available.
  ChildViewConnection connection;

  /// Constructor.
  ModuleRequest();
}
