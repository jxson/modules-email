// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:email_models/models.dart';
import 'package:email_widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:lib.widgets/model.dart';
import 'package:lib.widgets/widgets.dart';

import 'modular/module_model.dart';

/// An email menu/folder screen that shows a list of folders.
class EmailNavScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO(SO-424): Use email spec compliant colors and sizing
    return new Material(
        color: Colors.white,
        child: new ScopedModelDescendant<EmailNavModuleModel>(builder: (
          BuildContext context,
          Widget child,
          EmailNavModuleModel model,
        ) {
          return new ListView(
            children: <Widget>[
              buildUser(context, model.user),
              buildList(context, model),
            ],
          );
        }));
  }

  /// Build the [User]'s card, if the user is null show a spinner.
  Widget buildUser(BuildContext context, User user) {
    Widget avatar = user != null
        ? new Alphatar.fromNameAndUrl(
            name: user.name,
            avatarUrl: user.picture,
            size: 40.0,
          )
        : new Container(
            width: 40.0,
            height: 40.0,
            child: new CircularProgressIndicator(),
          );

    Widget title = user != null
        ? new Text(
            user.name,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
          )
        : new Text('');

    Widget subtitle = user != null
        ? new Text(
            user.email,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
          )
        : new Text('');

    return new Container(
      alignment: FractionalOffset.centerLeft,
      height: 73.0,
      child: new ListTile(
        leading: avatar,
        title: title,
        subtitle: subtitle,
      ),
    );
  }

  /// Build the list of [Label]s, if the user is null show a spinner.
  Widget buildList(BuildContext context, EmailNavModuleModel model) {
    return new Column(
      children: model.labels.values.map((Label label) {
        return new LabelListItem(
          label: label,
          selected: label.id == model.selectedLabelId,
          onSelect: model.handleSelectedLabel,
        );
      }).toList(),
    );
  }
}
