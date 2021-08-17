import "package:flutter/material.dart";
import "package:path_provider/path_provider.dart";
import "dart:io";
import "dart:async";
import "dart:convert";

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List _toDoList = [];

  @override
  void initState() {
    super.initState();

    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  final _toDoController = TextEditingController();

  Map<String, dynamic> _lastRemoved = Map();
  int _lastRemovedPos = 0;

  void _addTodo() {
    if (_toDoController.text.isEmpty) {
    } else {
      setState(() {
        Map<String, dynamic> newTodo = Map();
        newTodo["title"] = _toDoController.text;
        _toDoController.text = "";
        newTodo["ok"] = false;
        _toDoList.add(newTodo);
        _saveData();
      });
    }
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _toDoList.sort((a, b) {
        if (a["ok"] && !b["ok"])
          return 1;
        else if (!a["ok"] && b["ok"])
          return -1;
        else
          return 0;
      });
      _saveData();
    });
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("Lista de tarefas"),
          backgroundColor: Colors.purpleAccent,
          centerTitle: true),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _toDoController,
                    decoration: InputDecoration(
                      labelText: "Nova tarefa",
                      labelStyle: TextStyle(color: Colors.purpleAccent),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _addTodo,
                  child: Icon(Icons.add),
                  style: ElevatedButton.styleFrom(primary: Colors.purpleAccent),
                )
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                padding: EdgeInsets.only(top: 10.0),
                itemCount: _toDoList.length,
                itemBuilder: buildItem,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget buildItem(context, index) {
    return Dismissible(
      key: Key(DateTime.now().microsecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
            alignment: Alignment(-0.9, 0.0),
            child: Icon(
              Icons.delete,
              color: Colors.white,
            )),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        onChanged: (c) {
          setState(() {
            _toDoList[index]["ok"] = c;
            _saveData();
            _refresh();
          });
        },
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
          backgroundColor: Colors.purpleAccent,
          child: Icon(_toDoList[index]["ok"] ? Icons.check : Icons.error),
        ),
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPos = index;
          _toDoList.removeAt(index);
          _saveData();

          final snack = SnackBar(
            content: Text("Tarefa ${_lastRemoved["title"]} removida!"),
            action: SnackBarAction(
              label: "Desfazer",
              onPressed: () {
                setState(() {
                  _toDoList.insert(_lastRemovedPos, _lastRemoved);
                  _saveData();
                });
              },
            ),
            duration: Duration(seconds: 2),
          );
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(snack);
        });
      },
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return "null";
    }
  }
}
