// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:email_widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:lib.logging/logging.dart';
import 'package:lib.widgets/model.dart';
import 'package:util/extract_uri.dart';

/// Input for email message text
class MessageTextInput extends StatefulWidget {
  /// Initial text to prepopulate the input
  final String initialText;

  /// Callback function that is called everytime the subject text is changed
  final ValueChanged<String> onTextChange;

  /// Background color.
  final Color backgroundColor;

  /// Constructor
  MessageTextInput({
    Key key,
    this.initialText,
    this.onTextChange,
    this.backgroundColor,
  })
      : super(key: key);

  @override
  _MessageTextInputState createState() => new _MessageTextInputState();
}

class _MessageTextInputState extends State<MessageTextInput> {
  TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = new TextEditingController(text: widget.initialText);
  }

  @override
  void didUpdateWidget(MessageTextInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialText != widget.initialText) {
      _controller.text = widget.initialText;
    }
  }

  /// The default embedded module builder if a [ResolverModel] is not available.
  Widget buildDefaultEmbeddedModule(Uri attachment) {
    return new Text('Default emebeded module');
  }

  /// Build the embedded module.
  // TODO(youngseokyoon): this now happens at every character change, which is
  // very inefficient, especially when a link is actively being edited. Use a
  // timer to update the embedded modules only when the editor is idle.
  // https://fuchsia.atlassian.net/browse/SO-571
  Widget buildEmbeddedModules(
    BuildContext context,
    Widget child,
    ResolverModel model,
  ) {
    List<Widget> children;
    List<Uri> links = extractURI(_controller.text);
    log.fine('extracted links: $links');

    if (model == null) {
      children = links.map(buildDefaultEmbeddedModule).toList();
    } else {
      children = links
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
    ThemeData theme = Theme.of(context);
    TextStyle inputStyle = theme.textTheme.subhead;
    TextStyle labelStyle = inputStyle.copyWith(color: Colors.grey[500]);

    return new Container(
      color: widget.backgroundColor,
      padding: const EdgeInsets.all(16.0),
      child: new AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget child) {
          return new ListView(
            children: <Widget>[
              child,
              new ScopedModelDescendant<ResolverModel>(
                builder: buildEmbeddedModules,
              ),
            ],
          );
        },
        child: new TextField(
          controller: _controller,
          onChanged: widget.onTextChange,
          style: inputStyle,
          decoration: new InputDecoration.collapsed(
            hintText: '',
            hintStyle: labelStyle,
          ),
          maxLines: null,
        ),
      ),
    );
  }
}
