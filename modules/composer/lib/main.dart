// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:application.lib.app.dart/app.dart';
import 'package:email_models/models.dart';
import 'package:email_widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:lib.widgets/modular.dart';

import 'src/modular/module_model.dart';

void main() {
  EmailComposerModuleModel model = new EmailComposerModuleModel();

  ModuleWidget<EmailComposerModuleModel> moduleWidget =
      new ModuleWidget<EmailComposerModuleModel>(
    moduleModel: model,
    applicationContext: new ApplicationContext.fromStartupInfo(),
    child: new EditorScreen(
      // TODO: hydrate this from the Link.
      draft: new Message(),
      enableSend: true,
      onSend: model.handleSubmit,
      onClose: model.handleClose,
    ),
  );

  moduleWidget.advertise();

  runApp(new MaterialApp(
    home: moduleWidget,
  ));
}
