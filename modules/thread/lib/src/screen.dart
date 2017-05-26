// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:email_models/models.dart';
import 'package:email_widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:lib.widgets/modular.dart';

import 'modular/module_model.dart';

/// An email thread screen that shows all the messages in a particular email
/// [Thread], built with the flux pattern.
class EmailThreadScreen extends StatelessWidget {
  /// Creates a new [EmailThreadScreen] instance.
  EmailThreadScreen({
    Key key,
  })
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO(SO-424): Use email spec compliant colors and sizing
    return new Material(
        color: Colors.white,
        child: new ScopedModelDescendant<EmailThreadModuleModel>(
            builder: buildFromModel));
  }

  /// Builder for UI depending on a [EmailThreadModuleModel] model.
  Widget buildFromModel(
    BuildContext context,
    Widget child,
    EmailThreadModuleModel model,
  ) {
    // TODO(SO-42): Error related display code should be here.

    // Loading state.
    if (model.loading) {
      return new Center(child: new CircularProgressIndicator());
    }

    // TODO(SO-465): get a better blank slate UI.
    if (model.thread == null) {
      return new Container();
    }

    return new Scaffold(
      backgroundColor: Colors.white,
      appBar: new AppBar(
        backgroundColor: Colors.white,
        title: new Text(
          model.title,
          style: new TextStyle(color: Colors.black),
        ),
        actions: <Widget>[
          new IconButton(
            icon: new Icon(Icons.delete),
            onPressed: () {
              model.handleTrash(model.thread);
            },
            color: Colors.grey[600],
          ),
          new IconButton(
            icon: new Icon(Icons.archive),
            onPressed: () {
              model.handleArchive(model.thread);
            },
            color: Colors.grey[600],
          ),
        ],
      ),
      body: buildBody(context, model),
      bottomNavigationBar: buildFooter(context, model),
    );
  }

  /// Build the body of the thread view.
  Widget buildBody(BuildContext context, EmailThreadModuleModel model) {
    List<Widget> children = model.thread.messages.values.map((Message message) {
      return new MessageListItem(
        message: message,
        key: new ObjectKey(message.id),
        onHeaderTap: model.handleSelect,
        onForward: model.handleForward,
        onReply: model.handleReply,
        onReplyAll: model.handleReplyAll,
      );
    }).toList();

    return new ListView(
      children: children,
    );
  }

  /// Build the footer of the thread view.
  Widget buildFooter(BuildContext context, EmailThreadModuleModel model) {
    return new DecoratedBox(
      decoration: new BoxDecoration(
        border: new Border(
            top: new BorderSide(
          color: Colors.black12,
          width: 0.5,
        )),
      ),
      child: new MessageActionBarFooter(
        message: model.thread.lastMessage,
        onForward: model.handleForward,
        onReply: model.handleReply,
        onReplyAll: model.handleReplyAll,
      ),
    );
  }
}
