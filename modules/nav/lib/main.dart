// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:application.lib.app.dart/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:lib.widgets/modular.dart';

import 'src/modular/module_model.dart';
import 'src/screen.dart';

void main() {
  ApplicationContext applicationContext =
      new ApplicationContext.fromStartupInfo();

  ModuleWidget<EmailNavModuleModel> moduleWidget =
      new ModuleWidget<EmailNavModuleModel>(
    applicationContext: applicationContext,
    moduleModel: new EmailNavModuleModel(),
    child: new EmailNavScreen(),
  );

  moduleWidget.advertise();

  runApp(moduleWidget);
}
