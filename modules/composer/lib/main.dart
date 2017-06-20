// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:application.lib.app.dart/app.dart';
import 'package:email_widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:lib.logging/logging.dart';
import 'package:lib.widgets/modular.dart';

import 'src/modular/module_model.dart';

void main() {
  setupLogger(name: 'email/composer');

  EmailComposerModuleModel model = new EmailComposerModuleModel();

  ModuleWidget<EmailComposerModuleModel> moduleWidget =
      new ModuleWidget<EmailComposerModuleModel>(
    moduleModel: model,
    applicationContext: new ApplicationContext.fromStartupInfo(),
    child: new ScopedModelDescendant<EmailComposerModuleModel>(builder:
        (BuildContext context, Widget child, EmailComposerModuleModel model) {
      return new EditorScreen(
        draft: model.message,
        enableSend: true,
        onDraftChanged: model.handleDraftChanged,
        onSend: model.handleSubmit,
        onClose: model.handleClose,
      );
    }),
  );

  moduleWidget.advertise();

  runApp(new MaterialApp(
    home: moduleWidget,
  ));
}
