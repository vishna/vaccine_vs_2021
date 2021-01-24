import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:vaccine_vs_2021/main.dart';
import 'package:vaccine_vs_2021/model/vaccination_progress.dart';
import 'package:vaccine_vs_2021/repo.dart';
import 'package:vaccine_vs_2021/theme.dart';
import 'package:vaccine_vs_2021/widget/ambient_bar.dart';
import 'package:voyager/voyager.dart';

class CountryWidget extends StatefulWidget {
  CountryWidget({Key key}) : super(key: key);

  @override
  _CountryWidgetState createState() => _CountryWidgetState();
}

class _CountryWidgetState extends State<CountryWidget> {
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
    if (Repo.vaccineData == null) {
      return null;
    }

    return Repo.vaccineData[selectedCountry];
  }

  List<String> get countries {
    final items = Repo.vaccineData == null
        ? ["World"]
        : List<String>.from(Repo.vaccineData.keys)
      ..sort();
    return items;
  }

  double yearProgress(DateTime now) {
    final diff = now.difference(new DateTime(now.year, 1, 1, 0, 0));
    final diffInDays = diff.inDays + 1;
    return (diffInDays.toDouble() / 365.0);
  }

  @override
  void initState() {
    super.initState();
    _selectedCountryKey = context.voyager.pathParams["country"];
    if (Repo.vaccineData == null) {
      Repo.fetchVaccineData().then((value) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // workaround for failing to implement NoTransitionDelegate
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
                Vaxx2021App.selectCountry(newValue);
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
        body: Repo.vaccineData == null
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
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: progressSize(isSmall).height * 0.75,
                                    height: progressSize(isSmall).height * 1.25,
                                    color: linkColor,
                                  ),
                                  SizedBox(
                                    width: 4.0,
                                  ),
                                  Text(
                                    "Partial (${vaccinationProgress.peopleVaccinated}%)",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: linkColor),
                                  ),
                                  SizedBox(
                                    width: 8.0,
                                  ),
                                  Container(
                                    width: progressSize(isSmall).height * 0.75,
                                    height: progressSize(isSmall).height * 1.25,
                                    color: progressActiveColor,
                                  ),
                                  SizedBox(
                                    width: 4.0,
                                  ),
                                  Text(
                                    "Full (${vaccinationProgress.peopleFullyVaccinated}%)",
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
                              progress: yearProgress(vaccinationProgress.date),
                              isSmall: isSmall,
                              description: Text(
                                DateFormat("MMMM d")
                                    .format(vaccinationProgress.date),
                                textAlign: TextAlign.center,
                                style: TextStyle(color: linkColor),
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

const footerNote =
    """Based on data from [ourworldindata.org](https://ourworldindata.org/grapher/covid-vaccination-doses-per-capita) • Source [github.com/vishna/vaccine_vs_2021](https://github.com/vishna/vaccine_vs_2021) • Made with 💙 from Home by [Łukasz Wiśniewski](https://twitter.com/vishna)""";

extension _DoublePretty on double {
  /// formats 0.1234 to "0.12"
  String toStringPretty() => NumberFormat("0.0#", "en_US").format(this);
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
