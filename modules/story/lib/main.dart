// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:application.lib.app.dart/app.dart';
import 'package:flutter/widgets.dart';
import 'package:lib.widgets/modular.dart';

import 'src/modular/module_model.dart';
import 'src/modular/screen.dart';

void main() {
  ModuleWidget<EmailStoryModuleModel> moduleWidget =
      new ModuleWidget<EmailStoryModuleModel>(
    applicationContext: new ApplicationContext.fromStartupInfo(),
    moduleModel: new EmailStoryModuleModel(),
    child: new EmailStoryScreen(),
  );

  moduleWidget.advertise();

  runApp(moduleWidget);
}
