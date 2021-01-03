import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

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
  Map<String, VaccinationProgress> data;
  String selectedCountry = "World";

  VaccinationProgress get currentData {
    if (data == null) {
      return null;
    }

    return data[selectedCountry];
  }

  List<String> get countries {
    final items = data == null ? ["Germany"] : List<String>.from(data.keys)
      ..sort();
    return items;
  }

  String get yearProgress {
    final f = NumberFormat("0.0#", "en_US");
    final now = DateTime.now();
    final diff = now.difference(new DateTime(now.year, 1, 1, 0, 0));
    final diffInDays = diff.inDays + 1;
    return f.format(((diffInDays.toDouble() / 365.0) * 100.0));
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
              child: Center(child: Text("Pick County")),
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Vaccination Progress',
                            ),
                            Text(
                              "${currentData.value / 2}%",
                              style: Theme.of(context).textTheme.headline4,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '2021 Progress',
                            ),
                            Text(
                              "$yearProgress%",
                              style: Theme.of(context).textTheme.headline4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        "Based on data from ourworldindata.org. Source code available at github.com",
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
