// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

/// Builds the background for the [Dismissible] in a ThreadListItem and SingleLineThreadListItem.
///
/// A [Dismissible.direction] must be set to determine if the archive [Icon]
/// should be on the right or left.
/// If the user swipes left, then the archive [Icon] needs to be on the right
/// and vice versa.
class ArchiveDismissibleBackground extends StatelessWidget {
  /// Swipe direction for [Dismissible]
  DismissDirection direction;

  /// Creates a archive background for a [Dismissible]
  ArchiveDismissibleBackground({
    Key key,
    @required this.direction,
  })
      : super(key: key) {
    assert(direction != null);
  }

  @override
  Widget build(BuildContext context) {
    Widget archiveIcon = new Expanded(
      flex: null,
      child: new Container(
        padding: new EdgeInsets.symmetric(horizontal: 16.0),
        child: new Icon(
          Icons.archive,
          color: Colors.white,
          size: 24.0,
        ),
      ),
    );

    List<Widget> backgroundChildren = <Widget>[
      new Expanded(
        flex: 1,
        child: new Container(), //Empty container to space out icons
      ),
    ];

    // Position Archive Icon on left/right depending on Swipe Direction
    if (direction == DismissDirection.startToEnd) {
      backgroundChildren.insert(0, archiveIcon);
    } else {
      backgroundChildren.add(archiveIcon);
    }

    return new Container(
      color: Colors.green[500],
      child: new Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: backgroundChildren,
      ),
    );
  }
}
