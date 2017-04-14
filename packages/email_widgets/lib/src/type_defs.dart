// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:email_models/models.dart';

/// Common Type Definitions

/// Callback function signature for an action on a message
typedef void MessageCallback(Message message);

/// Callback function signature for an action on a thread
typedef void ThreadCallback(Thread thread);

/// Callback function signature for an action on a folder
typedef void LabelCallback(Label folder);

/// Void callback function signature for a string
typedef void StringCallback(String string);
