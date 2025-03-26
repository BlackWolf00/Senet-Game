import 'package:flutter/material.dart';

void main() {
  runApp(SenetGame());
}

class SenetGame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: Text('Senet')),
        body: Center(
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 10, // 10 colonne per fila
            ),
            itemCount: 30, // 30 caselle totali
            itemBuilder: (context, index) {
              return Container(
                margin: EdgeInsets.all(2),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  color: Colors.brown[300],
                ),
                height: 50,
                width: 50,
              );
            },
          ),
        ),
      ),
    );
  }
}
