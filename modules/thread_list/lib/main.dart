// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:application.lib.app.dart/app.dart';
import 'package:flutter/material.dart';
import 'package:lib.widgets/modular.dart';

import 'src/modular/module_model.dart';
import 'src/screen.dart';

void main() {
  ModuleWidget<EmailThreadListModuleModel> moduleWidget =
      new ModuleWidget<EmailThreadListModuleModel>(
    applicationContext: new ApplicationContext.fromStartupInfo(),
    moduleModel: new EmailThreadListModuleModel(),
    child: new EmailThreadListScreen(),
  );

  moduleWidget.advertise();

  runApp(new MaterialApp(
    title: 'Email Thread List Module',
    home: moduleWidget,
    theme: new ThemeData(primarySwatch: Colors.red),
    debugShowCheckedModeBanner: false,
  ));
}
