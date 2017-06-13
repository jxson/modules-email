// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../models.dart';

/// Render's an [IconButton] with [Icons.send].
class SendIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ComposerModel model = ComposerModel.of(context);

    return new IconButton(
      onPressed: model.handleSend,
      tooltip: 'Send message.',
      icon: new Icon(
        Icons.send,
        color: Colors.grey,
      ),
    );
  }
}
