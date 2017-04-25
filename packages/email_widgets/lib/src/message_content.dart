// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:email_models/models.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:widgets/common.dart';

const double _kEmbeddedChildHeight = 800.0;

/// Renders the content of a [Message]
// TODO(dayang) Render rich text
class MessageContent extends StatefulWidget {
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

  @override
  _MessageContentState createState() => new _MessageContentState();
}

class _MessageContentState extends State<MessageContent> {
  /// List of [EmbeddedChild] for displaying attachments in separate modules.
  final List<EmbeddedChild> embeddedChildren = <EmbeddedChild>[];

  @override
  void initState() {
    super.initState();

    void childAdder(EmbeddedChild child) {
      if (mounted) {
        setState(() => embeddedChildren.add(child));
      }
    }

    widget.message.links.forEach((Uri link) {
      kEmbeddedChildProvider.buildGeneralEmbeddedChild(
        contract: 'view',
        initialData: <String, dynamic>{
          'uri': link.toString(),
          'scheme': link.scheme,
          'host': link.host,
          'path': link.path,
          'query parameters': link.queryParameters,
        },
        childAdder: childAdder,
      );
    });
  }

  @override
  void dispose() {
    // Dispose all the embedded children.
    embeddedChildren.forEach((EmbeddedChild ec) => ec.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = <Widget>[
      new Text(
        widget.message.text ?? '',
        softWrap: true,
        style: new TextStyle(
          fontSize: 16.0,
          color: Colors.black,
          height: 1.5,
        ),
      ),
    ];

    embeddedChildren.forEach((EmbeddedChild ec) {
      children.add(new SizedBox(
        height: _kEmbeddedChildHeight,
        child: new Align(
          alignment: FractionalOffset.topCenter,
          child: new Card(
            color: Colors.grey[200],
            child: ec.widgetBuilder(context),
          ),
        ),
      ));
    });

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
