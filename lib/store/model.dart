import 'dart:developer';

import 'package:personal_finance/store/store.dart';
import 'package:personal_finance/utils/month.dart';
import 'package:sqflite/sqflite.dart';

class Category {
  final int id;
  final String name;
  final String type;
  final double? goal;

  const Category(
      {this.id = 0, required this.name, required this.type, this.goal});

  Map<String, dynamic> toMap() {
    return {"name": name, "type_id": type == "income" ? 0 : 1};
  }

  static Future<List<CategoryContent>> all(Database db, Timeframe tf) async {
    final List<Map<String, dynamic>> maps =
        await db.rawQuery('SELECT * FROM category');

    var between = MonthUtils.getBetween(tf.year, tf.month);
    final List<Map<String, dynamic>> statements = await db.rawQuery(
        'SELECT * FROM statement WHERE created > ? AND created < ?', between);

    // log("${statements.length} ${statements[2]['category_id']} ${maps[0]['id']}");

    return List.generate(maps.length, (i) {
      return CategoryContent(
          Category(
            id: maps[i]['id'],
            name: maps[i]['name'],
            goal: maps[i]["goal"],
            type: maps[i]['type_id'] == 0 ? "income" : "expense",
          ),
          statements
              .where((x) => x["category_id"] == maps[i]["id"])
              .map<Statement>((x) => Statement(
                  title: x["title"],
                  description: x["description"],
                  amount: x["amount"],
                  created: x["created"]))
              .toList());
    });
  }

  static Future insert(Database db, Category category) async {
    return db.insert("category", category.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }
  
  static Future updateGoal(Database db, int id, double amount) async {
    return db.rawUpdate("UPDATE category SET goal = ? WHERE id = ?", [amount, id]);
  }
}

class Statement {
  final int id;
  final String title;
  final String description;
  final double amount;
  final int created;
  final bool recurring;
  final int? categoryId;

  const Statement(
      {this.id = 0,
      required this.title,
      required this.description,
      required this.amount,
      required this.created,
      this.recurring = false,
      this.categoryId = 0});

  Map<String, dynamic> toMap() {
    return {
      "title": title,
      "description": description,
      "amount": amount,
      "created": created,
      "recurring": recurring ? 1 : 0,
      "category_id": categoryId
    };
  }

  static Future insert(Database db, Statement statement) async {
    log("INSERTING ${statement.title} INTO ${statement.categoryId}");
    return db.insert("statement", statement.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}
