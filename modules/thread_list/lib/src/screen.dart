// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:email_flux/flux.dart';
import 'package:email_models/models.dart';
import 'package:email_widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_flux/flutter_flux.dart';

// Inbox header height needs to line up with the ThreadView header
const double _kInboxHeaderHeight = 73.0;

/// An email inbox screen that shows a list of email threads, built with the
/// flux pattern.
class EmailThreadListScreen extends StoreWatcher {
  /// The Flux StoreToken this screen uses for UI state.
  final StoreToken token;

  /// Create a new [EmailThreadListScreen] instance.
  EmailThreadListScreen({
    Key key,
    // NOTE: This causes a flicker when loading, it should only show title when
    // it's available, and show the spinner in the list area.
    this.fallbackTitle: '',
    this.token,
  })
      : super(key: key) {
    assert(fallbackTitle != null);
  }

  /// Header Title for this view
  final String fallbackTitle;

  @override
  void initStores(ListenToStore listenToStore) {
    listenToStore(token);
  }

  @override
  Widget build(BuildContext context, Map<StoreToken, Store> stores) {
    final EmailFluxStore fluxStore = stores[token];

    if (fluxStore.fetchingThreads) {
      return new Center(child: new CircularProgressIndicator());
    }

    if (fluxStore.errors.isNotEmpty) {
      return new Errors(
        errors: fluxStore.errors,
      );
    }

    List<Thread> threads = fluxStore.threads.values.toList();

    threads.sort((Thread a, Thread b) {
      Message lastA = a.lastMessage;
      Message lastB = b.lastMessage;

      return lastB.timestamp.compareTo(lastA.timestamp);
    });

    Widget threadList = new ListView(
      children: threads.map((Thread t) => buildListItem(t, fluxStore)).toList(),
    );

    // TODO(dayang): Use theme data
    // https://fuchsia.atlassian.net/browse/SO-43
    return new Material(
      child: new Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Container(
            height: _kInboxHeaderHeight,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: new BoxDecoration(
              border: new Border(
                bottom: new BorderSide(
                  color: Colors.grey[200],
                  width: 1.0,
                ),
              ),
            ),
            child: new Row(
              children: <Widget>[
                new Text(
                  fluxStore.focusedLabel?.name ?? fallbackTitle,
                  overflow: TextOverflow.ellipsis,
                  style: new TextStyle(
                    fontSize: 18.0,
                  ),
                ),
              ],
            ),
          ),
          new Expanded(
            flex: 1,
            child: threadList,
          ),
        ],
      ),
    );
  }

  /// Create the list item view for the given thread.
  Widget buildListItem(Thread thread, EmailFluxStore fluxStore) {
    Key key = new ObjectKey(thread);

    return new ThreadListItem(
      key: key,
      thread: thread,
      onSelect: EmailFluxActions.selectThread.call,
      isSelected: fluxStore.focusedThreadId == thread.id,
      onArchive: EmailFluxActions.archiveThread.call,
    );
  }
}
