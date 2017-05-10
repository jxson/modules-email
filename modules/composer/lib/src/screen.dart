// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:email_models/models.dart';
import 'package:email_widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

/// The screen to composing email drafts.
class EmailComposerScreen extends StatelessWidget {
  /// The message being composed.
  final Message message;

  /// The callback to trigger when the user submits the form.
  final MessageCallback onSubmit;

  /// Constructor.
  EmailComposerScreen({
    Key key,
    @required this.message,
    @required this.onSubmit,
  })
      : super(key: key);

  /// Manages conversion from UI trigger to onSubmit callback.
  void handleSend() {
    onSubmit(this.message);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      // TODO(SO-424): Use email spec compliant colors and sizing
      appBar: new AppBar(
        title: new Text(
          message.subject ?? 'No subject',
          style: new TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        actions: <Widget>[
          new IconButton(
            icon: new Icon(
              Icons.delete,
              color: Colors.grey,
            ),
            onPressed: handleSend,
          )
        ],
      ),
      body: new Center(
        child: new Text('TODO(SO-422): Add the text input fields.'),
      ),
    );
  }
}
