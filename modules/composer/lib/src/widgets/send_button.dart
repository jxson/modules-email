// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../models.dart';

/// Render's an [RaisedButton] with the text "SEND".
class SendButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ComposerModel model = ComposerModel.of(context);

    return new RaisedButton(
      color: Colors.blue,
      onPressed: model.handleSend,
      child: new Text('SEND', style: new TextStyle(color: Colors.white)),
    );
  }
}
