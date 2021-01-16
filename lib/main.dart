import 'dart:math';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:url_strategy/url_strategy.dart';
import 'package:voyager/voyager.dart';

final paths = loadPathsFromYamlSync('''
'/:country':
  type: home
  widget: HomeWidget
''');

final plugins = [
  WidgetPlugin({"HomeWidget": (context) => HomePage()})
];

final appKey = GlobalKey<_VaccineVs2021AppState>();

void main() async {
  setPathUrlStrategy();
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
  var stack = VoyagerStack([VoyagerPage("/world")]);

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
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
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

  String get yearProgress {
    final now = DateTime.now();
    final diff = now.difference(new DateTime(now.year, 1, 1, 0, 0));
    final diffInDays = diff.inDays + 1;
    return ((diffInDays.toDouble() / 365.0) * 100.0).toStringPretty();
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
                setState(() {
                  final newPath =
                      "/$newValue".toLowerCase().replaceAll(" ", "_");
                  appKey.currentState.updateStack(VoyagerStack(
                    [
                      VoyagerPage(newPath),
                    ],
                  ));
                });
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
                      final contentWidth = max(constraints.maxWidth / 2, 200.0);
                      final isSmall = constraints.maxWidth / 2 < 200.0;
                      return Wrap(
                        children: <Widget>[
                          SizedBox(
                            width: contentWidth,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Vaccination Progress',
                                    textAlign: TextAlign.center,
                                    style: isSmall
                                        ? null
                                        : Theme.of(context).textTheme.headline4,
                                  ),
                                  Text(
                                    "${(vaccinationProgress.value / 2).toStringPretty()}%",
                                    textAlign: TextAlign.center,
                                    style: isSmall
                                        ? Theme.of(context).textTheme.headline4
                                        : Theme.of(context).textTheme.headline2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            width: contentWidth,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '2021 Progress',
                                    textAlign: TextAlign.center,
                                    style: isSmall
                                        ? null
                                        : Theme.of(context).textTheme.headline4,
                                  ),
                                  Text(
                                    "$yearProgress%",
                                    textAlign: TextAlign.center,
                                    style: isSmall
                                        ? Theme.of(context).textTheme.headline4
                                        : Theme.of(context).textTheme.headline2,
                                  ),
                                ],
                              ),
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

Map<String, VaccinationProgress> vaccineData;
Future<Map<String, VaccinationProgress>> fetchVaccineData() async {
  if (vaccineData != null) {
    return vaccineData;
  }

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
        row[indexOf["location"]].toString().trim(),
        double.tryParse(
                row[indexOf["total_vaccinations_per_hundred"]].toString()) ??
            0.0);
    final previousVp = output[vp.name];
    if (previousVp == null || vp.value > previousVp.value) {
      output[vp.name] = vp;
    }
  }

  vaccineData = output;

  return output;
}

class VaccinationProgress {
  const VaccinationProgress(this.name, this.value);
  final String name;
  final num value;

  @override
  String toString() {
    return "$runtimeType[$name:$value]";
  }
}

const footerNote =
    """Based on data from [ourworldindata.org](https://ourworldindata.org/grapher/covid-vaccination-doses-per-capita) • Number of doses per 100 people, divided by 2 • Source code available at [github.com/vishna/vaccine_vs_2021](https://github.com/vishna/vaccine_vs_2021/blob/main/lib/main.dart) • Made with 💙 from Home, Berlin. • Copyright (c) 2021 Łukasz Wiśniewski""";

extension DoublePretty on double {
  /// formats 0.1234 to "0.12"
  String toStringPretty() => NumberFormat("0.0#", "en_US").format(this);
}
