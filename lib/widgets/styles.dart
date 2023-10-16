import 'package:flutter/material.dart';

ButtonStyle textButtonStyle(BuildContext context) => TextButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      padding: const EdgeInsets.all(15),
      textStyle: const TextStyle(
        fontSize: 16,
      ),
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
    );

ButtonStyle iconButtonStyle(BuildContext context) => IconButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      iconSize: 32,
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
    );
