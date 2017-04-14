// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:email_models/models.dart';
import 'package:flutter/material.dart';
import 'package:lib.widgets/model.dart';
import 'package:meta/meta.dart';

import 'resolver_model.dart';

/// The fixed height value to be used for the embedded attachment modules. Due
/// to the current limitation of Mozart composition, the parent always has to
/// specify how big the child should be, and the child cannot determine its own
/// size.
const double _kEmbeddedChildHeight = 800.0;

/// Renders the content of a [Message]
class MessageContent extends StatelessWidget {
  /// [Message] to render content for
  final Message message;

  /// Creates a new MessageContent widget
  MessageContent({
    Key key,
    @required this.message,
  })
      : super(key: key) {
    assert(message != null);
  }

  /// The default embedded module builder if a [ResolverModel] is not available.
  Widget buildDefaultEmbeddedModule(Uri attachment) {
    return new Text('Default emebeded module');
  }

  /// Build the embedded module.
  Widget buildEmbeddedModules(
    BuildContext context,
    Widget child,
    ResolverModel model,
  ) {
    List<Widget> children;

    if (model == null) {
      children = message.links.map(buildDefaultEmbeddedModule).toList();
    } else {
      children = message.links
          .map((Uri uri) => model.build(context, uri))
          .where((Widget child) => child != null)
          .toList();
    }

    return new Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = <Widget>[];

    Widget content = new Text(
      message.text ?? '',
      softWrap: true,
      style: new TextStyle(
        fontSize: 16.0,
        color: Colors.black,
        height: 1.5,
      ),
    );

    children.add(content);

    if (message.expanded) {
      Widget embeddedModule = new ScopedModelDescendant<ResolverModel>(
        builder: buildEmbeddedModules,
      );
      children.add(embeddedModule);
    }

    return new Container(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        bottom: 16.0,
      ),
      child: new Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
