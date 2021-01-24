import 'dart:convert';
import 'dart:math';

import 'package:country_code/country_code.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:vaccine_vs_2021/widget/ambient_bar.dart';
import 'package:voyager/voyager.dart';

const initialStack = VoyagerStack(
  [VoyagerPage("/world")],
);

final paths = loadPathsFromYamlSync('''
'/:country':
  type: home
  widget: HomeWidget
''');

final plugins = [
  WidgetPlugin({"HomeWidget": (context) => HomePage()})
];

final appKey = GlobalKey<_VaccineVs2021AppState>();

void selectCountry(String name) {
  final newPath = "/$name".toLowerCase().replaceAll(" ", "_");
  appKey.currentState.updateStack(VoyagerStack(
    [
      VoyagerPage(newPath),
    ],
  ));
}

void main() async {
  runApp(VaccineVs2021App(
      key: appKey, router: VoyagerRouter.from(paths, plugins)));
}

class VaccineVs2021App extends StatefulWidget {
  VaccineVs2021App({Key key, this.router}) : super(key: key);
  final VoyagerRouter router;

  @override
  _VaccineVs2021AppState createState() => _VaccineVs2021AppState();
}

class _VaccineVs2021AppState extends State<VaccineVs2021App> {
  var stack = initialStack;

  void updateStack(VoyagerStack value) {
    setState(() {
      stack = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return VoyagerStackApp(
      stack: stack,
      router: widget.router,
      createApp: (context, parser, delegate) => MaterialApp.router(
        title: 'Vaccine vs 2021',
        routerDelegate: delegate,
        routeInformationParser: parser,
        theme: blackAndWhiteTheme(context),
      ),
      onBackPressed: () {
        // ignore
      },
      onNewPage: (page) {
        if (page is VoyagerStack) {
          setState(() {
            stack = page;
          });
        }

        if (page is VoyagerPage) {
          setState(() {
            stack = VoyagerStack([page]);
          });
        }
      },
      onInitialPage: (page) {
        if (page is VoyagerPage) {
          if (page.path != "/") {
            setState(() {
              stack = VoyagerStack([page]);
            });
          }
        }
      },
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// whatever the param is in the url
  String _selectedCountryKey = "world";

  /// maps the param to entry from json
  String get selectedCountry {
    final c = countries;
    final index = c.indexWhere((element) =>
        element.toLowerCase().replaceAll(" ", "_") ==
        _selectedCountryKey.toLowerCase());
    if (index == -1) {
      return "World";
    } else {
      return c[index];
    }
  }

  VaccinationProgress get vaccinationProgress {
    if (vaccineData == null) {
      return null;
    }

    return vaccineData[selectedCountry];
  }

  List<String> get countries {
    final items =
        vaccineData == null ? ["World"] : List<String>.from(vaccineData.keys)
          ..sort();
    return items;
  }

  double get yearProgress {
    final now = DateTime.now();
    final diff = now.difference(new DateTime(now.year, 1, 1, 0, 0));
    final diffInDays = diff.inDays + 1;
    return (diffInDays.toDouble() / 365.0);
  }

  @override
  void initState() {
    super.initState();
    _selectedCountryKey = context.voyager.pathParams["country"];
    if (vaccineData == null) {
      fetchVaccineData().then((value) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: "hero_scaffold",
      child: Scaffold(
        appBar: AppBar(
          title: Text("Vaccine vs 2021"),
          actions: [
            PopupMenuButton<String>(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Center(child: Text("Pick Country")),
              ),
              onSelected: (String newValue) {
                selectCountry(newValue);
              },
              itemBuilder: (BuildContext context) {
                return countries.map((String choice) {
                  return PopupMenuItem<String>(
                    value: choice,
                    child: Text(choice),
                  );
                }).toList();
              },
            ),
          ],
        ),
        body: vaccineData == null
            ? Center(
                child: CircularProgressIndicator(),
              )
            : Center(
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: Text(
                          "$selectedCountry",
                          style: Theme.of(context).textTheme.headline2,
                        ),
                      ),
                    ),
                    LayoutBuilder(builder: (context, constraints) {
                      final contentWidth =
                          max(constraints.maxWidth / 2, contentWidthBreak);
                      final isSmall =
                          constraints.maxWidth / 2 < contentWidthBreak;
                      return Wrap(
                        children: <Widget>[
                          SizedBox(
                            width: contentWidth,
                            child: _ProgressInfoWidget(
                              title: 'Vaccination Progress',
                              progress: vaccinationProgress
                                      .peopleFullyVaccinated
                                      .toDouble() /
                                  100.0,
                              frontProgress: vaccinationProgress
                                      .peopleVaccinated
                                      .toDouble() /
                                  100.0,
                              isSmall: isSmall,
                              reverse: !isSmall,
                              description: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    " ■ Partial (${vaccinationProgress.peopleVaccinated}%)",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: linkColor),
                                  ),
                                  Text(
                                    " ■ Full (${vaccinationProgress.peopleFullyVaccinated}%)",
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            width: contentWidth,
                            child: _ProgressInfoWidget(
                              title: '2021 Progress',
                              progress: yearProgress,
                              isSmall: isSmall,
                            ),
                          ),
                        ],
                      );
                    }),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            MarkdownBody(
                              styleSheet: MarkdownStyleSheet.fromTheme(
                                      Theme.of(context))
                                  .copyWith(
                                      a: const TextStyle(
                                color: linkColor,
                              )),
                              onTapLink: (text, href, title) {
                                url_launcher.launch(href);
                              },
                              data: footerNote,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

String _locationIsoCode;
Future<void> _resolveLocation() async {
  try {
    final response = await http.get('https://api.ipregistry.co?key=tryout');
    final value = jsonDecode(response.body);
    String code2 = value["location"]["country"]["code"];
    final cc = CountryCode.tryParse(code2);
    _locationIsoCode = cc.alpha3;
  } catch (_) {}
}

Map<String, VaccinationProgress> vaccineData;
Future<Map<String, VaccinationProgress>> fetchVaccineData() async {
  if (vaccineData != null) {
    return vaccineData;
  }

  await _resolveLocation();

  final response = await http.get(
      'https://raw.githubusercontent.com/owid/covid-19-data/master/public/data/vaccinations/vaccinations.csv');

  List<List<dynamic>> vaccinations = const CsvToListConverter()
      .convert(response.body, fieldDelimiter: ",", eol: "\n");

  final indexOf = Map.fromIterable(vaccinations.first,
      key: (v) => v, value: (v) => vaccinations.first.indexOf(v));

  final output = <String, VaccinationProgress>{};
  for (var index = 1; index < vaccinations.length; index++) {
    final row = vaccinations[index];

    final vp = VaccinationProgress(
        name: row[indexOf["location"]].toString().trim(),
        isoCode: row[indexOf["iso_code"]].toString().trim(),
        peopleFullyVaccinated: double.tryParse(
                row[indexOf["people_fully_vaccinated_per_hundred"]]
                    .toString()) ??
            0.0,
        peopleVaccinated: double.tryParse(
                row[indexOf["people_vaccinated_per_hundred"]].toString()) ??
            0.0);
    final previousVp = output[vp.name];
    if (previousVp == null ||
        vp.peopleVaccinated > previousVp.peopleVaccinated) {
      output[vp.name] = vp;
    }
  }

  vaccineData = output;

  if (_locationIsoCode != null) {
    final preselectedEntry = output.values.firstWhere(
      (element) => element.isoCode == _locationIsoCode,
      orElse: () => null,
    );

    if (preselectedEntry != null && appKey.currentState.stack == initialStack) {
      selectCountry(preselectedEntry.name);
    }
  }

  return output;
}

class VaccinationProgress {
  const VaccinationProgress({
    this.name,
    this.isoCode,
    this.peopleVaccinated,
    this.peopleFullyVaccinated,
  });
  final String name;
  final String isoCode;
  final num peopleVaccinated;
  final num peopleFullyVaccinated;
}

class _ProgressInfoWidget extends StatelessWidget {
  const _ProgressInfoWidget({
    Key key,
    this.progress,
    this.frontProgress,
    this.title,
    this.reverse = false,
    @required this.isSmall,
    this.description,
  }) : super(key: key);
  final double progress;
  final double frontProgress;
  final String title;
  final bool reverse;
  final bool isSmall;
  final Widget description;

  @override
  Widget build(BuildContext context) {
    final progressPretty = ((frontProgress ?? progress) * 100).toStringPretty();
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "$progressPretty%",
            textAlign: TextAlign.center,
            style: isSmall
                ? Theme.of(context).textTheme.headline4
                : Theme.of(context).textTheme.headline2,
          ),
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: SizedBox.fromSize(
                size: progressSize(isSmall),
                child: Stack(
                  children: [
                    if (frontProgress != null)
                      Positioned.fill(
                        child: AmbientBar(
                          value: AmbientBarValue(
                              reverse: reverse,
                              radius: progressRadius,
                              backgroundColor: progressBgColor(),
                              progressColor: linkColor,
                              progress: frontProgress,
                              gapSize: progressInterval,
                              stepCount: progressMax),
                        ),
                      ),
                    if (progress != null)
                      Positioned.fill(
                        child: AmbientBar(
                          value: AmbientBarValue(
                              reverse: reverse,
                              radius: progressRadius,
                              backgroundColor: frontProgress != null
                                  ? Colors.transparent
                                  : progressBgColor(),
                              progressColor: progressActiveColor,
                              progress: progress,
                              gapSize: progressInterval,
                              stepCount: progressMax),
                        ),
                      ),
                  ],
                ),
              )),
          Text(
            title,
            textAlign: TextAlign.center,
            style: isSmall ? null : Theme.of(context).textTheme.headline4,
          ),
          if (description != null) description,
        ],
      ),
    );
  }
}

const footerNote =
    """Based on data from [ourworldindata.org](https://ourworldindata.org/grapher/covid-vaccination-doses-per-capita) • Source [github.com/vishna/vaccine_vs_2021](https://github.com/vishna/vaccine_vs_2021) • Made with 💙 from Home by [Łukasz Wiśniewski](https://twitter.com/vishna)""";

extension DoublePretty on double {
  /// formats 0.1234 to "0.12"
  String toStringPretty() => NumberFormat("0.0#", "en_US").format(this);
}

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
Size progressSize(bool isSmall) => isSmall ? Size(400, 8) : Size(400, 12);
