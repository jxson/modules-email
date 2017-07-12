// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:email_models/models.dart';
import 'package:email_widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:lib.widgets/model.dart';

import 'modular/module_model.dart';

/// An email inbox screen that shows a list of email threads, built with the
/// flux pattern.
class EmailThreadListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO(SO-424): Use email spec compliant colors and sizing
    return new Material(
        color: Colors.white,
        child: new ScopedModelDescendant<EmailThreadListModuleModel>(
          builder: buildFromModel,
        ));
  }

  /// Builder for UI depending on a [EmailThreadListModuleModel] model.
  Widget buildFromModel(
    BuildContext context,
    Widget child,
    EmailThreadListModuleModel model,
  ) {
    return new Scaffold(
        // TODO(SO-424): Use email spec compliant colors and sizing.
        appBar: new AppBar(
          title: new Text(
            model.title,
            style: new TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.white,
        ),
        body: buildBody(context, model),
        floatingActionButton: new FloatingActionButton(
          onPressed: model.launchComposer,
          tooltip: 'Draft a new message.',
          child: new Icon(Icons.create),
        ));
  }

  /// Build the body of the thread list view.
  Widget buildBody(BuildContext context, EmailThreadListModuleModel model) {
    // Loading state.
    if (model.loading) {
      return new Center(child: new CircularProgressIndicator());
    }

    if (model.threads.isEmpty) {
      return buildBlankSlate(context, model);
    }

    List<Thread> threads = model.threads.values.toList();

    threads.sort((Thread a, Thread b) {
      Message lastA = a.lastMessage;
      Message lastB = b.lastMessage;

      return lastB.timestamp.compareTo(lastA.timestamp);
    });

    return new ListView(
      children: threads.map((Thread t) => buildListItem(t, model)).toList(),
    );
  }

  /// Blank slate.
  Widget buildBlankSlate(
    BuildContext context,
    EmailThreadListModuleModel model,
  ) {
    // Default values
    IconData icon = Icons.email;
    String text = 'Nothing in ${model.title}';

    if (model.label != null) {
      switch (model.label.id) {
        case 'INBOX':
          icon = Icons.inbox;
          break;
        case 'DRAFT':
          icon = Icons.drafts;
          break;
        case 'SENT':
          icon = Icons.send;
          break;
        case 'TRASH':
          icon = Icons.delete;
          break;
        case 'SPAM':
          icon = Icons.error;
          break;
        default:
          text = 'No messages labeled "${model.label.name}"';
          break;
      }
    }

    return new Center(
        child: new Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        new Icon(
          icon,
          size: 120.0,
          color: Colors.grey[500],
        ),
        new Text(
          text,
          style: new TextStyle(color: Colors.grey[600]),
        ),
      ],
    ));
  }

  /// Create the list item view for the given thread.
  Widget buildListItem(Thread thread, EmailThreadListModuleModel model) {
    // NOTE: Usage of an object key here will trigger a Flutter bug:
    // https://github.com/flutter/flutter/issues/9185

    return new ThreadListItem(
      thread: thread,
      onSelect: model.handleThreadSelected,
      isSelected: thread.id == model.selectedThreadId,
      onArchive: model.handleThreadArchived,
    );
  }
}
