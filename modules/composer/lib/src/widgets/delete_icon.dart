// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../models.dart';

/// Render's an [IconButton] with [Icons.delete].
class DeleteIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ComposerModel model = ComposerModel.of(context);

    return new IconButton(
        onPressed: model.handleDelete,
        tooltip: 'Delete draft.',
        icon: new Icon(
          Icons.delete,
          color: Colors.grey,
        ));
  }
}
