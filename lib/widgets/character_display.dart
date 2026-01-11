import 'package:flutter/material.dart';
import '../constants.dart';

class CharacterDisplay extends StatelessWidget {
  const CharacterDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, 0),
      child: Transform.scale(
        scale: 1.0,
        child: Image.asset(
          AppConstants.characterImagePath,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
