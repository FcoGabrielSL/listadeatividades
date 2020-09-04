import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

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
  final _toDoController = TextEditingController();
  var _toDoList = []; // Armazena a lista de Tarefas
  var _lastRemoved = {}; // Ultimo removido
  var _lastRemovedPos = 0; // Index do ultimo removido

  void _addToDo() {
    setState(() {
      // Cria o item
      var newToDo = {"title": _toDoController.text, "ok": false};
      // Adiciona na lista
      _toDoList.add(newToDo);
      // Salvar os dados
      _saveData();
      // Limpa o input
      _toDoController.text = "";
    });
  }

  Widget _buildItem(context, index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 10),
        color: Colors.red,
        child: Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]["ok"] ? Icons.check : Icons.error),
        ),
        onChanged: (ok) {
          setState(() {
            _toDoList[index]["ok"] = ok;
            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          // Ultimo removido
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPos = index;
          // Remove
          _toDoList.removeAt(index);
          // Salva
          _saveData();

          // Snakbar
          final snack = SnackBar(
            content: Text("Tarefa \"${_lastRemoved["title"]}\" removida!"),
            duration: Duration(seconds: 2),
            action: SnackBarAction(
              label: "Desfazer",
              onPressed: () {
                setState(() {
                  // Inserindo novamente
                  _toDoList.insert(_lastRemovedPos, _lastRemoved);
                  _saveData();
                });
              },
            ),
          );

          // Limpar a pilha de SnackBar
          Scaffold.of(context).removeCurrentSnackBar();
          // Mostrar o SnackBar criado
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }

  Future<File> _getFile() async {
    // Comando executado de forma assincrona
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
      return null;
    }
  }

  @override
  void initState() {
    // Sobrescrevendo o método de init para puxar os dados
    super.initState();
    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  Future<Null> _refresh() async {
    // Esperar 1s, Só pra ficar bonito
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      // Ordenar

      _toDoList.sort((a, b) {
        if (a["ok"] && !b["ok"])
          return 1;
        else if (!a["ok"] && b["ok"])
          return a['title'].compareTo(b['title']);
        else
          return a['title'].compareTo(b['title']);
      });
      // Salvar
      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                        labelText: "Nova tarefa",
                        labelStyle: TextStyle(color: Colors.blueAccent)),
                    controller: _toDoController,
                  ),
                ),
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Text("ADD"),
                  textColor: Colors.white,
                  onPressed: _addToDo,
                )
              ],
            ),
          ),
          Expanded(
              // Constroi elemento por elemento a medida que vai sendo mostrado
              child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
                padding: EdgeInsets.only(top: 10.0),
                itemCount: _toDoList.length,

                // Função anonima
                itemBuilder: _buildItem),
          ))
        ],
      ),
    );
  }
}
