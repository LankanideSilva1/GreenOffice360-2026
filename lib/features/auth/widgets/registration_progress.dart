import 'package:flutter/material.dart';

class RegistrationProgress extends StatelessWidget {
  const RegistrationProgress({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFFF4F7),
            Color(0xFFF8E6EE),
            Color(0xFFFFD9E5),
            Color(0xFFFFD3E5),
          ],
          stops: [0.0, 0.25, 0.6, 1.0],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const stripeWidth = 11.0;
          const stripeGap = 6.0;

          final count =
              (constraints.maxWidth / (stripeWidth + stripeGap)).ceil();

          return Row(
            children: List.generate(
              count,
              (index) => Container(
                width: stripeWidth,
                height: 18,
                margin: EdgeInsets.only(
                  right: index == count - 1 ? 0 : stripeGap,
                ),
                color: index.isEven
                    ? const Color(0xFFF6D7E4)
                    : Colors.transparent,
              ),
            ),
          );
        },
      ),
    );
  }
}