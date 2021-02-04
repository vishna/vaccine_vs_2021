import 'package:flutter/material.dart';

import 'package:vaccine_vs_2021/theme.dart';
import 'package:vaccine_vs_2021/widget/country_widget.dart';
import 'package:voyager/voyager.dart';

void main() async {
  runApp(Vaxx2021App(router: VoyagerRouter.from(paths, plugins)));
}

/// show the statisics for entire world until we figure out
/// where the user is based on his IP address
const initialStack = VoyagerStack(
  [VoyagerPage("/world")],
);

/// Voyager's navigation map
final paths = loadPathsFromYamlSync('''
'/:country':
  type: home
  widget: CountryWidget
''');

/// Voyager's plugin
final plugins = [
  WidgetPlugin({"CountryWidget": (context) => CountryWidget()})
];

/// Wraps [VoyagerStackApp] with a state that carries information about
/// navigation stack.
///
/// This is Web based app so it makes sense to support browser history
/// thru Navigator 2.0, Voyager removes that boilerplate.
class Vaxx2021App extends StatefulWidget {
  Vaxx2021App({this.router}) : super(key: _appKey);
  final VoyagerRouter router;

  @override
  _Vaxx2021AppState createState() => _Vaxx2021AppState();

  /// returns immutable value of the current navigation stack
  static VoyagerStack get stack => _appKey.currentState.stack;

  static final _appKey = GlobalKey<_Vaxx2021AppState>();

  static void selectCountry(String name) {
    final newPath = "/$name".toLowerCase().replaceAll(" ", "_");
    _appKey.currentState._updateStack(VoyagerStack(
      [
        VoyagerPage(newPath),
      ],
    ));
  }
}

class _Vaxx2021AppState extends State<Vaxx2021App> {
  var stack = initialStack;

  void _updateStack(VoyagerStack value) {
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
