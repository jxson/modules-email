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
            model.title ?? '',
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

    // Blank slate. TODO link to an issue.
    if (model.threads.isEmpty) {
      return new Container();
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
