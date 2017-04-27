// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:apps.modular.services.auth/token_provider.fidl.dart';
import 'package:email_api/email_api.dart';

/// Helper to access and contain an EmailAPI singleton.
class API {
  static EmailAPI _api;

  /// Async getter/loader.
  static Future<EmailAPI> get() async {
    if (_api != null) {
      return _api;
    }

    _api = await EmailAPI.fromConfig('/system/data/modules/config.json');
    return _api;
  }

  static Future<EmailAPI> fromTokenProvider(
    TokenProviderProxy tokenProvider,
  ) async {
    Completer<String> _clientIdCompleter = new Completer<String>();
    tokenProvider.getClientId(_clientIdCompleter.complete);
    Completer<String> _accessTokenCompleter = new Completer<String>();
    tokenProvider.getAccessToken(_accessTokenCompleter.complete);
    return new EmailAPI(
        id: await _clientIdCompleter.future,
        token: await _accessTokenCompleter.future,
        expiry: new DateTime.now().add(new Duration(hours: 1)).toUtc(),
        scopes: ['openid', 'email',
        'https://www.googleapis.com/auth/gmail.modify',
        'https://www.googleapis.com/auth/assistant',
        'https://www.googleapis.com/auth/userinfo.email',
        'https://www.googleapis.com/auth/userinfo.profile',
        'https://www.googleapis.com/auth/contacts',
        'https://www.googleapis.com/auth/plus.login',]);
  }
}
