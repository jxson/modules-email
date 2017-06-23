// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../models.dart';

/// Render's an [IconButton] with [Icons.close].
class CloseIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ComposerModel model = ComposerModel.of(context);

    return new IconButton(
        onPressed: model.handleClose,
        tooltip: 'Close module.',
        icon: new Icon(
          Icons.close,
          color: Colors.grey,
        ));
  }
}
