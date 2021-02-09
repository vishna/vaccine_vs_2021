import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData blackAndWhiteTheme(BuildContext context) => ThemeData(
    primarySwatch: _pitchBlack,
    canvasColor: Colors.white,
    textTheme: GoogleFonts.oswaldTextTheme(
      Theme.of(context).textTheme,
    ).apply(bodyColor: Colors.black, displayColor: Colors.black));

MaterialColor _pitchBlack = _monoColor(0xFF000000);

MaterialColor _monoColor(int value) {
  return MaterialColor(
    value,
    <int, Color>{
      50: Color(value),
      100: Color(value),
      200: Color(value),
      300: Color(value),
      400: Color(value),
      500: Color(value),
      600: Color(value),
      700: Color(value),
      800: Color(value),
      900: Color(value),
    },
  );
}

const linkColor = Colors.blueGrey;
Color progressBgColor() => Colors.grey.withAlpha(170);
const progressActiveColor = Colors.black;
const progressRadius = 2.0;
const progressInterval = 1.0;
const progressMax = 40;
const contentWidthBreak = 256.0;
const countryPickerHeight = 56.0;
const countryPickerPadding = 16.0;
Size progressSize(bool isSmall) => isSmall ? Size(400, 8) : Size(400, 12);
