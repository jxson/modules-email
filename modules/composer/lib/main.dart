// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:application.lib.app.dart/app.dart';
import 'package:email_models/models.dart';
import 'package:flutter/widgets.dart';
import 'package:lib.widgets/modular.dart';

import 'src/modular/module_model.dart';
import 'src/screen.dart';

void main() {
  EmailComposerModuleModel model = new EmailComposerModuleModel();

  ModuleWidget<EmailComposerModuleModel> moduleWidget =
      new ModuleWidget<EmailComposerModuleModel>(
    moduleModel: model,
    applicationContext: new ApplicationContext.fromStartupInfo(),
    child: new EmailComposerScreen(
      // TODO: hydrate this from the Link.
      message: new Message(),
      onSubmit: model.handleSubmit,
    ),
  );

  moduleWidget.advertise();

  runApp(moduleWidget);
}
