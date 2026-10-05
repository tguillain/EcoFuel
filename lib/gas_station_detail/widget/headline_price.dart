import 'package:ecofuel/theme/app_colors.dart';
import 'package:flutter/material.dart';

class HeadlinePrice extends StatelessWidget {
  const HeadlinePrice({super.key, required this.price});

  final String price;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: 8,
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              price,
              style: const TextStyle(
                fontSize: 82,
                height: .82,
                fontWeight: FontWeight.w800,
                letterSpacing: 82 * -0.05,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 2),
          child: Text(
            '€/L',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceMuted,
            ),
          ),
        ),
      ],
    );
  }
}
