// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:application.services/service_provider.fidl.dart';
import 'package:apps.modular.services.module/module_context.fidl.dart';
import 'package:apps.modular.services.module/module_controller.fidl.dart';
import 'package:apps.modular.services.story/link.fidl.dart';
import 'package:apps.mozart.lib.flutter/child_view.dart';
import 'package:apps.mozart.services.views/view_token.fidl.dart';
import 'package:lib.fidl.dart/bindings.dart';
import 'package:lib.fidl.dart/core.dart';
import 'package:lib.widgets/modular.dart';

final String _kEmailSessionUrl = 'file:///system/apps/email/session';
final String _kEmailNavUrl = 'file:///system/apps/email/nav';
final String _kEmailThreadListUrl = 'file:///system/apps/email/thread_list';
final String _kEmailThreadUrl = 'file:///system/apps/email/thread';

/// The [ModuleModel] for the EmailStory.
class EmailStoryModuleModel extends ModuleModel {
  /// A list used for holding references to the [ServiceProviderWrapper]
  /// objects for the lifetime of this module.
  final List<ServiceProviderWrapper> serviceProviders =
      <ServiceProviderWrapper>[];

  ChildViewConnection _navConnection;
  ChildViewConnection _threadListConnection;
  ChildViewConnection _threadConnection;

  /// Gets the [ChildViewConnection] for the Nav Module.
  ChildViewConnection get navConnection => _navConnection;

  /// Gets the [ChildViewConnection] for the Thread List Module.
  ChildViewConnection get threadListConnection => _threadListConnection;

  /// Gets the [ChildViewConnection] for the Thread Module.
  ChildViewConnection get threadConnection => _threadConnection;

  /// [ServiceProviderProxy] between email session and UI modules.
  final ServiceProviderProxy emailSessionProvider = new ServiceProviderProxy();

  @override
  void onReady(
    ModuleContext moduleContext,
    Link link,
    ServiceProvider incomingServices,
  ) {
    super.onReady(moduleContext, link, incomingServices);

    // Starting EmailSession Module.
    startModule(
      url: _kEmailSessionUrl,
      incomingServices: emailSessionProvider.ctrl.request(),
    );

    // Launch modules that will be embedded.
    _navConnection = new ChildViewConnection(
      startModule(
          url: _kEmailNavUrl,
          outgoingServices: duplicateServiceProvider(emailSessionProvider)),
    );

    _threadListConnection = new ChildViewConnection(
      startModule(
          url: _kEmailThreadListUrl,
          outgoingServices: duplicateServiceProvider(emailSessionProvider)),
    );

    _threadConnection = new ChildViewConnection(
      startModule(
          url: _kEmailThreadUrl,
          outgoingServices: duplicateServiceProvider(emailSessionProvider)),
    );

    notifyListeners();
  }

  @override
  void onStop() {
    emailSessionProvider.ctrl.close();
    serviceProviders.forEach((ServiceProviderWrapper s) => s.close());
    _navConnection = null;
    _threadListConnection = null;
    super.onStop();
  }

  /// Start a module and return its [ViewOwner] handle.
  InterfaceHandle<ViewOwner> startModule({
    String url,
    InterfaceHandle<ServiceProvider> outgoingServices,
    InterfaceRequest<ServiceProvider> incomingServices,
  }) {
    InterfacePair<ViewOwner> viewOwnerPair = new InterfacePair<ViewOwner>();
    InterfacePair<ModuleController> moduleControllerPair =
        new InterfacePair<ModuleController>();

    // module name is the module url
    String name = url;

    print('Starting sub-module: $url');
    moduleContext.startModule(
      name,
      url,
      null, // Pass on our default link to our child.
      outgoingServices,
      incomingServices,
      moduleControllerPair.passRequest(),
      viewOwnerPair.passRequest(),
    );
    print('Started sub-module: $url');

    return viewOwnerPair.passHandle();
  }

  /// Duplicates a [ServiceProvider] and returns its handle.
  InterfaceHandle<ServiceProvider> duplicateServiceProvider(ServiceProvider s) {
    ServiceProviderWrapper dup = new ServiceProviderWrapper(s);
    serviceProviders.add(dup);
    return dup.getHandle();
  }
}

/// A wrapper class for duplicating ServiceProvider
class ServiceProviderWrapper extends ServiceProvider {
  final ServiceProviderBinding _binding = new ServiceProviderBinding();

  /// The original [ServiceProvider] instance that this class wraps.
  final ServiceProvider serviceProvider;

  /// Creates a new [ServiceProviderWrapper] with the given [ServiceProvider].
  ServiceProviderWrapper(this.serviceProvider);

  /// Gets the [InterfaceHandle] for this [ServiceProvider] wrapper.
  ///
  /// The returned handle should only be used once.
  InterfaceHandle<ServiceProvider> getHandle() => _binding.wrap(this);

  /// Closes the binding.
  void close() => _binding.close();

  @override
  void connectToService(String serviceName, Channel channel) {
    serviceProvider.connectToService(serviceName, channel);
  }
}
