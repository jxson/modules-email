// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:application.lib.app.dart/app.dart';
import 'package:email_flux/flux.dart';
import 'package:email_session/client.dart';
import 'package:flutter/material.dart';
import 'package:lib.widgets/modular.dart';

import 'src/screen.dart';

void main() {
  EmailFluxStore fluxStore = new EmailFluxStore();
  StoreToken token = new StoreToken(fluxStore);

  ModuleWidget<EmailSessionModuleModel> moduleWidget =
      new ModuleWidget<EmailSessionModuleModel>(
    applicationContext: new ApplicationContext.fromStartupInfo(),
    moduleModel: new EmailSessionModuleModel(
      name: 'thread_list',
      fluxStore: fluxStore,
    ),
    child: new EmailThreadListScreen(
      token: token,
    ),
  );

  moduleWidget.advertise();

  runApp(new MaterialApp(
    title: 'Email Thread List Module',
    home: moduleWidget,
    theme: new ThemeData(primarySwatch: Colors.blue),
    debugShowCheckedModeBanner: false,
  ));
}
