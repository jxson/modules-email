// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:application.lib.app.dart/app.dart';
import 'package:email_flux/flux.dart';
import 'package:email_session/client.dart';
import 'package:email_widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:lib.widgets/modular.dart';

import 'src/resolver_model.dart';
import 'src/screen.dart';

void main() {
  EmailFluxStore fluxStore = new EmailFluxStore();
  StoreToken token = new StoreToken(fluxStore);
  ApplicationContext applicationContext =
      new ApplicationContext.fromStartupInfo();

  ModuleWidget<EmailSessionModuleModel> moduleWidget =
      new ModuleWidget<EmailSessionModuleModel>(
    applicationContext: applicationContext,
    moduleModel: new EmailSessionModuleModel(
      fluxStore: fluxStore,
      name: 'thread',
    ),
    child: new ScopedModel<ResolverModel>(
      model: new ModularResolverModel(
        context: applicationContext,
      ),
      child: new EmailThreadScreen(
        token: token,
      ),
    ),
  );

  moduleWidget.advertise();

  runApp(new MaterialApp(
    title: 'Email Thread Module',
    home: moduleWidget,
    theme: new ThemeData(primarySwatch: Colors.blue),
    debugShowCheckedModeBanner: false,
  ));
}
