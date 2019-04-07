import 'package:flutter/material.dart';
import 'package:flutter_swiper/flutter_swiper.dart';
import 'package:flutter_tags/input_tags.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_spinkit/flutter_spinkit.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primaryColor: Colors.orange, accentColor: Colors.orange),
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

const host = 'spoonacular-recipe-food-nutrition-v1.p.rapidapi.com';

class _HomeState extends State<Home> {
  List<String> tags = [];
  List<Recipe> recipes = [];
  bool loading = false;

  final headers = {
    "X-RapidAPI-Host": host,
    "X-RapidAPI-Key": "8b89465b20msh96f2bf14d96d26dp1c2957jsnd3bceeea4282"
  };

  Text text(String txt, double size) => Text(txt, style: style(size));

  TextStyle style(double size) =>
      TextStyle(fontFamily: 'Didot', color: Colors.white, fontSize: size);

  Widget spacer() => SizedBox(height: 30);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: text('HOMECOOKED', 36)),
      floatingActionButton: loading
          ? CircularProgressIndicator()
          : FloatingActionButton.extended(
              icon: Icon(Icons.search, color: Colors.white),
              label: text('FIND RECIPES', 17),
              onPressed: getRecipes,
            ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            spacer(),
            inputTags(),
            spacer(),
            SizedBox(height: 400, child: outerSwiper()),
            spacer()
          ],
        ),
      ),
    );
  }

  Future getRecipes() async {
    setState(() {
      recipes.clear();
      loading = true;
    });
    final uri = Uri.https(host, 'recipes/findByIngredients',
        {'number': '20', 'ingredients': tags.join(',')});
    final rsp = await http.get(uri, headers: headers);
    setState(() {
      recipes = (json.decode(rsp.body) as List)
          .map((e) => Recipe.fromJson(e))
          .toList();
      loading = false;
    });
  }

  Future getInfo(int index) async {
    if (recipes[index].info == null) {
      setState(() => loading = true);
      final uri = Uri.https(host, 'recipes/${recipes[index].id}/information');
      final rsp = await http.get(uri, headers: headers);
      setState(() {
        recipes[index].info = Info.fromJson(json.decode(rsp.body));
        loading = false;
      });
    }
  }

  Widget inputTags() {
    return InputTags(
        tags: [],
        autocorrect: true,
        placeholder: "Add Ingredient",
        backgroundContainer: Colors.transparent,
        textStyle: style(15),
        onInsert: (t) => tags.add(t),
        onDelete: (t) => tags.remove(t));
  }

  Widget outerSwiper() {
    return recipes.isNotEmpty
        ? Swiper(
            itemBuilder: (_, i) => Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: Image.network(recipes[i].url, fit: BoxFit.cover),
                    ),
                    innerSwiper(i)
                  ],
                ),
            itemCount: recipes.length,
            viewportFraction: 0.7,
            scale: 0.8)
        : null;
  }

  Widget innerSwiper(int i) {
    return Swiper(
      loop: false,
      onIndexChanged: (idx) => getInfo(i),
      itemBuilder: (_, n) => Container(
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.2)),
            padding: EdgeInsets.symmetric(vertical: 50, horizontal: 30),
            child: Center(child: card(i, n)),
          ),
      itemCount: 3,
      scrollDirection: Axis.vertical,
      pagination: new SwiperPagination(),
    );
  }

  Widget card(int outerIndex, int innerIndex) {
    final info = recipes[outerIndex].info;
    switch (innerIndex) {
      case 0:
        return text(recipes[outerIndex].name, 34);
      case 1:
        return list(info?.ingredients);
      case 2:
        return list(info?.directions);
      default:
        return SizedBox();
    }
  }

  Stack list(List<String> list) {
    return Stack(
      children: <Widget>[
        loading ? SpinKitRipple(color: Colors.white) : SizedBox(),
        ListView.builder(
            itemCount: list == null ? 0 : list.length,
            itemBuilder: (_, i) => text('-  ${list[i]}', 18))
      ],
    );
  }
}

class Recipe {
  final int id;
  final String name;
  final String url;
  Info info;

  Recipe.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['title'],
        url = json['image'];
}

class Info {
  final List<String> directions;
  final List<String> ingredients;

  Info.fromJson(Map<String, dynamic> json)
      : directions = [json['instructions'] ?? 'Good luck!'],
        ingredients = ((json['extendedIngredients']) as List)
            .map((e) => '${e['originalString']}')
            .toList();
}
