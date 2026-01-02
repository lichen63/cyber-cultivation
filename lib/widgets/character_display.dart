import 'package:flutter/material.dart';
import '../constants.dart';

class CharacterDisplay extends StatelessWidget {
  const CharacterDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        AppConstants.characterImagePath,
        fit: BoxFit.contain,
      ),
    );
  }
}
