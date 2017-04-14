// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

/// A non-optimal list of errors.
/// SEE: SO-266
class Errors extends StatelessWidget {
  /// A list of errors to display.
  final List<Error> errors;

  /// Creates new Errors Widget.
  Errors({
    Key key,
    @required this.errors,
  })
      : super(key: key) {
    assert(errors != null);
  }

  /// Builder for a single Error object.
  Widget buildError(Error error) {
    Widget text = new Text('Error occurred while retrieving email folders: '
        '$error');
    return new ListTile(
      title: text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return new ListView(
      children: errors.map(buildError).toList(),
    );
  }
}
