import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/models/asset_type.dart';
import 'asset_avatar.dart';

/// Seçili varlığı gösteren, dokununca seçim listesini açan alan.
class AssetField extends StatelessWidget {
  const AssetField({
    super.key,
    required this.type,
    required this.code,
    required this.name,
    required this.onTap,
  });

  final AssetType type;
  final String? code;
  final String? name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.field,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (code != null) ...[
                AssetAvatar(type: type, code: code!, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ] else
                Expanded(
                  child: SizedBox(
                    height: 30,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Varlık seç',
                          style: TextStyle(color: palette.muted, fontSize: 16)),
                    ),
                  ),
                ),
              Icon(Icons.unfold_more_rounded, color: palette.muted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
