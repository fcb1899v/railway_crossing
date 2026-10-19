import 'package:flutter/material.dart';

/// Background and image of the launch splash.
/// They match the iOS launch screen.
const splashColor = Color(0xFFC84D3E);
const splashImageAsset = 'assets/icon/icon.png';
/// Fixed, not a share of the screen: the iOS launch screen centres LaunchImage at its 256 pt size.
const splashImageWidth = 256.0;
const splashImageHeight = 256.0;
const splashFit = BoxFit.contain;
/// True draws the image across the whole screen width instead of at a fixed size.
const splashFillWidth = false;
