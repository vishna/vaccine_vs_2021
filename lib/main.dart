import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

void main() {
  runApp(VaccineVs2021App());
}

class VaccineVs2021App extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vaccine vs 2021',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final formatter = NumberFormat("0.0#", "en_US");
  Map<String, VaccinationProgress> data;
  String selectedCountry = "World";

  VaccinationProgress get currentData {
    if (data == null) {
      return null;
    }

    return data[selectedCountry];
  }

  List<String> get countries {
    final items = data == null ? ["World"] : List<String>.from(data.keys)
      ..sort();
    return items;
  }

  String get yearProgress {
    final now = DateTime.now();
    final diff = now.difference(new DateTime(now.year, 1, 1, 0, 0));
    final diffInDays = diff.inDays + 1;
    return formatter.format(((diffInDays.toDouble() / 365.0) * 100.0));
  }

  @override
  void initState() {
    super.initState();
    fetchVaccineData().then((value) {
      setState(() {
        data = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                selectedCountry = newValue;
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
      body: data == null
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
                                  "${formatter.format(currentData.value / 2)}%",
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
                            data: _footerNote(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

Future<Map<String, VaccinationProgress>> fetchVaccineData() async {
  final response = await http.get(
      'https://ourworldindata.org/grapher/covid-vaccination-doses-per-capita');
  final dataStr = response.body.split("//EMBEDDED_JSON")[1];

  final dataJson = jsonDecode(dataStr);

  // fetch latest variableId and version
  final variableId = dataJson["map"]["variableId"].toString();
  final version = dataJson["version"].toString();

  final responseVariables = await http.get(
      "https://ourworldindata.org/grapher/data/variables/$variableId.json?v=$version");
  final responseVariablesJson = jsonDecode(responseVariables.body);

  // map entities to VaccinationProgress objects
  final entities = responseVariablesJson["variables"][variableId]["entities"]
      as List<dynamic>;
  final values =
      responseVariablesJson["variables"][variableId]["values"] as List<dynamic>;
  final names = responseVariablesJson["entityKey"];

  final output = <String, VaccinationProgress>{};
  var index = 0;
  entities.forEach((entityKey) {
    final vp = VaccinationProgress(
        names[entityKey.toString()]["name"], values[index++]);
    final previousVp = output[vp.name];
    if (previousVp == null || vp.value > previousVp.value) {
      output[vp.name] = vp;
    }
  });

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

String _footerNote() => """
Based on data from [ourworldindata.org](https://ourworldindata.org/grapher/covid-vaccination-doses-per-capita) • Number of doses per 100 people, divided by 2 • Source code available at [github.com/vishna/vaccine_vs_2021](https://github.com/vishna/vaccine_vs_2021/blob/main/lib/main.dart) • Made with 💙 from Home, Berlin. • Copyright (c) 2021 Łukasz Wiśniewski"""
    .trim();
