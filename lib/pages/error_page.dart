import 'package:flutter/material.dart';

class ErrorPage extends StatefulWidget {
  final String errorMessage;
  final String? subtext;

  const ErrorPage({super.key, required this.errorMessage, this.subtext});

  @override
  State<ErrorPage> createState() => _ErrorPageState();
}

class _ErrorPageState extends State<ErrorPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error,
              color: Colors.redAccent,
              size: 128,
            ),
            Text(
              widget.errorMessage,
              textAlign: TextAlign.center,
              softWrap: true,
              maxLines: 4,
            ),
            widget.subtext == null
                ? Container()
                : Text(
                    widget.subtext!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
          ],
        ),
      ),
    );
  }
}
