// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:lib.widgets/model.dart';

import '../../models.dart';
import 'close_icon.dart';
import 'delete_icon.dart';
import 'message_text_input.dart';
import 'recipient_input.dart';
import 'send_button.dart';
import 'subject_input.dart';

/// Render's a [Scaffold] for a [MaterialApp].
class ComposerScaffold extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      // TODO(SO-424): Use email spec compliant colors and sizing
      appBar: new AppBar(
        backgroundColor: Colors.white,
        actions: <Widget>[new CloseIcon()],
      ),
      body: buildBody(context),
      bottomNavigationBar: new Container(
        color: Colors.white,
        child: new ButtonBar(
          alignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            new SendButton(),
            new DeleteIcon(),
          ],
        ),
      ),
    );
  }

  /// Builds the body of the [Scaffold].
  Widget buildBody(BuildContext context) {
    return new ScopedModelDescendant<ComposerModel>(
      builder: (
        BuildContext context,
        Widget child,
        ComposerModel model,
      ) {
        return new Material(
          child: new Column(
            children: <Widget>[
              // The input field for "To: ...".
              new RecipientInput(
                model: model,
                backgroundColor: Colors.white,
              ),
              // TODO(SO-549): Add missing "From:" field.
              // The input field for "Subject: ...".
              new SubjectInput(
                initialText: model.subject,
                onTextChange: model.handleSubjectChanged,
                backgroundColor: Colors.white,
              ),
              // Message text input.
              new Expanded(
                child: new MessageTextInput(
                  initialText: model.body,
                  onTextChange: model.handleBodyChanged,
                  backgroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
