// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:application.lib.app.dart/app.dart';
import 'package:email_widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:lib.logging/logging.dart';
import 'package:lib.widgets/modular.dart';

import 'src/modular/module_model.dart';
import 'src/modular/resolver_model.dart';
import 'src/screen.dart';

void main() {
  setupLogger(name: 'email/thread');

  ApplicationContext applicationContext =
      new ApplicationContext.fromStartupInfo();

  EmailThreadModuleModel moduleModel = new EmailThreadModuleModel();

  ModuleWidget<EmailThreadModuleModel> moduleWidget =
      new ModuleWidget<EmailThreadModuleModel>(
    applicationContext: applicationContext,
    moduleModel: moduleModel,
    child: new ScopedModel<ResolverModel>(
      model: new ModularResolverModel(
        context: applicationContext,
        moduleModel: moduleModel,
      ),
      child: new EmailThreadScreen(),
    ),
  );

  moduleWidget.advertise();

  runApp(new MaterialApp(
    title: 'Email Thread Module',
    home: moduleWidget,
    theme: new ThemeData(primarySwatch: Colors.blue),
  ));
}
