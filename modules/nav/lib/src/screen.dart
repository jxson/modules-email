// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:email_flux/flux.dart';
import 'package:email_models/models.dart';
import 'package:email_widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_flux/flutter_flux.dart';
import 'package:meta/meta.dart';

/// An email menu/folder screen that shows a list of folders.
class EmailNavScreen extends StoreWatcher {
  /// The Flux StoreToken this screen uses for UI state.
  final StoreToken token;

  /// Creates a new [EmailNavScreen] instance
  EmailNavScreen({
    Key key,
    @required this.token,
  })
      : super(key: key);

  @override
  void initStores(ListenToStore listenToStore) {
    listenToStore(token);
  }

  @override
  Widget build(BuildContext context, Map<StoreToken, Store> stores) {
    EmailFluxStore fluxStore = stores[token];

    // Negotiate readiness [fluxStore] values (populated via Link content). It's
    // possible for the fluxStore.user value to be null when the the store is
    // first initialized. It might take a while for dependent modules to be in a
    // state to grab the needed values and assign a user.
    bool isFetching = fluxStore.fetchingUser || fluxStore.fetchingLabels;
    if (isFetching || fluxStore.user == null) {
      return new Center(child: new CircularProgressIndicator());
    }

    if (fluxStore.errors.isNotEmpty) {
      return new Errors(
        errors: fluxStore.errors,
      );
    }

    LabelGroup primaryLabels = new LabelGroup(
      labels: fluxStore.labels.values.toList(),
    );

    return new LabelList(
      labelGroups: <LabelGroup>[primaryLabels],
      onSelectLabel: EmailFluxActions.selectLabel,
      selectedLabel: fluxStore.focusedLabel,
      user: fluxStore.user,
    );
  }
}
