// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:lib.widgets/model.dart';

/// Abstract ResolverModel.
abstract class ResolverModel extends Model {
  /// Widget builder for ResolverModel implementations. Used in widget trees to
  /// access top-level Fuchsia features if available.
  Widget build(BuildContext context, Uri uri);
}
