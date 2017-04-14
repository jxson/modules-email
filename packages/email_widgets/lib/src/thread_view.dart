// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:email_models/models.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import 'message_action_bar_footer.dart';
import 'message_list_item.dart';
import 'thread_action_bar_header.dart';
import 'type_defs.dart';

/// View for a single email [Thread].
class ThreadView extends StatelessWidget {
  /// Given thread to render
  final Thread thread;

  /// Callback for when a given message is selected in thread
  final MessageCallback onSelect;

  /// Callback for selecting forward for a message
  final MessageCallback onForward;

  /// Callback for selecting reply all for a message
  final MessageCallback onReplyAll;

  /// Callback for selecting reply for a message
  final MessageCallback onReply;

  /// Callback for archiving a message.
  final ThreadCallback onArchive;

  /// Callback for archiving a message.
  final ThreadCallback onMoreActions;

  /// Callback for archiving a message.
  final ThreadCallback onDelete;

  // onMoreActions: this.onMoreActions,
  // onDelete: this.onDelete,

  /// Creates a ThreadView for given [Thread]
  ThreadView({
    Key key,
    @required this.onArchive,
    @required this.onDelete,
    @required this.onForward,
    @required this.onMoreActions,
    @required this.onReply,
    @required this.onReplyAll,
    @required this.onSelect,
    @required this.thread,
  })
      : super(key: key) {
    assert(thread != null);
  }

  @override
  Widget build(BuildContext context) {
    // Column is used to create the "sticky header"
    // The first child will be the header, while the last child will
    // be the scrollable block of MessageListItems (listChildren)
    List<Widget> columnChildren = <Widget>[];
    List<Widget> listChildren = <Widget>[];

    // Add the messages.
    thread.messages.values.forEach((Message message) {
      listChildren.add(new Container(
        decoration: new BoxDecoration(
          border: new Border(
            bottom: new BorderSide(
              color: Colors.grey[200],
              width: 1.0,
            ),
          ),
        ),
        child: new MessageListItem(
          message: message,
          key: new ObjectKey(message),
          onHeaderTap: onSelect,
          onForward: onForward,
          onReply: onReply,
          onReplyAll: onReplyAll,
        ),
      ));
    });

    listChildren.add(new MessageActionBarFooter(
      message: thread.lastMessage,
      onForward: this.onForward,
      onReplyAll: this.onReplyAll,
      onReply: this.onReply,
    ));

    columnChildren.add(new ThreadActionBarHeader(
      thread: thread,
      onArchive: this.onArchive,
      onMoreActions: this.onMoreActions,
      onDelete: this.onDelete,
    ));

    columnChildren.add(new Expanded(
      flex: 1,
      child: new ListView(
        children: listChildren,
      ),
    ));

    return new Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: columnChildren,
    );
  }
}
