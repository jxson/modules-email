// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:application.lib.app.dart/app.dart';
import 'package:flutter/material.dart';
import 'package:lib.logging/logging.dart';
import 'package:lib.widgets/model.dart';
import 'package:lib.widgets/modular.dart';

import 'models.dart';
import 'src/modular/module_model.dart';
import 'widgets.dart';

void main() {
  setupLogger(
    name: 'email/composer',
  );

  EmailComposerModuleModel moduleModel = new EmailComposerModuleModel();

  /// Create an instance of this module's UI [Model] and connect it's events to
  /// the a [moduleModel].
  ComposerModel model = new ComposerModel(
    onSend: moduleModel.handleSend,
    onDelete: moduleModel.handleDelete,
    onClose: moduleModel.handleClose,
    onUpdate: moduleModel.handleDraftChanged,
  );

  ModuleWidget<EmailComposerModuleModel> moduleWidget =
      new ModuleWidget<EmailComposerModuleModel>(
    moduleModel: moduleModel,
    applicationContext: new ApplicationContext.fromStartupInfo(),
    child: new ScopedModelDescendant<EmailComposerModuleModel>(builder: (
      BuildContext context,
      Widget child,
      EmailComposerModuleModel mm,
    ) {
      /// When the [moduleModel] updates it could have a message value fetched
      /// from a Link that is converted into a Message object. If that is the
      /// case, assign a new Message object to the UI model.
      model.message = mm.message;

      /// Add the [ComposerModel] instance to the Widget hierarchy as a
      /// [ScopedModel] so it can be accessed by leaf node Widgets (buttons,
      /// etc.).
      return new ScopedModel<ComposerModel>(
        model: model,
        child: new ComposerScaffold(),
      );
    }),
  );

  runApp(new MaterialApp(
    home: moduleWidget,
  ));
}
