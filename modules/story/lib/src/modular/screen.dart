// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:apps.mozart.lib.flutter/child_view.dart';
import 'package:flutter/material.dart';
import 'package:lib.widgets/model.dart';

import 'module_model.dart';

/// Top-level widget for email_story.
class EmailStoryScreen extends StatelessWidget {
  /// Create an instance of [EmailStoryScreen].
  EmailStoryScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Material(
        color: Colors.white,
        child: new ScopedModelDescendant<EmailStoryModuleModel>(builder: (
          BuildContext context,
          Widget child,
          EmailStoryModuleModel storyModel,
        ) {
          return new Row(children: <Widget>[
            nav(context, storyModel),
            list(context, storyModel),
            detail(context, storyModel),
          ]);
        }));
  }

  /// Build the space on the left side for the navigation module.
  Widget nav(BuildContext context, EmailStoryModuleModel storyModel) {
    return new Expanded(
        flex: 2,
        child: new Column(children: <Widget>[
          new Expanded(
            flex: 1,
            // TODO: log time to resolve.
            child: storyModel.navConnection != null
                ? new ChildView(connection: storyModel.navConnection)
                : new Container(),
          )
        ]));
  }

  /// Build the thread_list view in the middle.
  Widget list(BuildContext context, EmailStoryModuleModel storyModel) {
    return new Expanded(
      flex: 3,
      child: new Container(
        padding: new EdgeInsets.symmetric(horizontal: 4.0),
        child: new Material(
          elevation: 2,
          child: storyModel.threadListConnection != null
              ? new ChildView(connection: storyModel.threadListConnection)
              : new Container(),
        ),
      ),
    );
  }

  /// Build the thread view on the right.
  Widget detail(BuildContext context, EmailStoryModuleModel storyModel) {
    return new Expanded(
      flex: 4,
      child: storyModel.threadConnection != null
          ? new ChildView(connection: storyModel.threadConnection)
          : new Container(),
    );
  }
}
