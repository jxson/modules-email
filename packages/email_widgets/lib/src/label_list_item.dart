// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:email_models/models.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import 'type_defs.dart';

/// [IconData] for [Icon] that represents a Label ID.
// TODO(dayang): Fill this out based on Gmail Label names & icons
const Map<String, IconData> _kIcons = const <String, IconData>{
  'STARRED': Icons.star,
  'INBOX': Icons.inbox,
  'TRASH': Icons.delete,
  'DRAFT': Icons.drafts,
};

/// List item that represents a single Gmail style [Label]
class LabelListItem extends StatelessWidget {
  /// Given [Label] that this [LabelListItem] is associated with
  final Label label;

  /// Callback if folder is selected
  final LabelCallback onSelect;

  /// True if the folder is 'selected', this will highlight the item with a
  /// grey background.
  final bool selected;

  /// Creates new LabelListItem
  LabelListItem({
    Key key,
    @required this.label,
    this.onSelect,
    this.selected: false,
  })
      : super(key: key) {
    assert(label != null);
  }

  void _handleSelect() {
    if (onSelect != null) {
      onSelect(label);
    }
  }

  /// The Icon for the [label].
  Widget buildIcon(BuildContext context) {
    IconData iconData;

    if (label.type == 'system') {
      iconData = _kIcons[label.id] ?? Icons.folder;
    } else {
      iconData = Icons.folder;
    }

    return new Icon(
      iconData,
      color: Colors.grey[600],
      size: 20.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Material(
      color: selected ? Colors.grey[200] : Colors.white,
      child: new ListTile(
        enabled: true,
        onTap: _handleSelect,
        isThreeLine: false,
        leading: buildIcon(context),
        title: new Text(label.name),
        trailing: label.unread > 0
            ? new Text(
                '${label.unread}',
                style: new TextStyle(color: Colors.grey[600]),
              )
            : null,
      ),
    );
  }
}
