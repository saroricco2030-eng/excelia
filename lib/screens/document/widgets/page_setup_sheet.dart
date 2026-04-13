import 'package:flutter/material.dart';
import 'package:excelia/l10n/app_localizations.dart';
import 'package:excelia/models/print_setup.dart';
import 'package:excelia/utils/constants.dart';

/// Document page setup bottom sheet with header/footer fields.
class DocumentPageSetupSheet extends StatefulWidget {
  final PrintSetup setup;
  final String headerText;
  final String footerText;
  final void Function(PrintSetup setup, String header, String footer) onApply;

  const DocumentPageSetupSheet({
    super.key,
    required this.setup,
    required this.headerText,
    required this.footerText,
    required this.onApply,
  });

  @override
  State<DocumentPageSetupSheet> createState() => _DocumentPageSetupSheetState();
}

class _DocumentPageSetupSheetState extends State<DocumentPageSetupSheet> {
  late PrintSetup _draft;
  late TextEditingController _headerCtrl;
  late TextEditingController _footerCtrl;

  @override
  void initState() {
    super.initState();
    _draft = widget.setup;
    _headerCtrl = TextEditingController(text: widget.headerText);
    _footerCtrl = TextEditingController(text: widget.footerText);
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _footerCtrl.dispose();
    super.dispose();
  }

  String _paperLabel(PaperSize key, AppLocalizations l) {
    switch (key) {
      case PaperSize.a4: return l.paperSizeA4;
      case PaperSize.a5: return l.paperSizeA5;
      case PaperSize.letter: return l.paperSizeLetter;
      case PaperSize.legal: return l.paperSizeLegal;
    }
  }

  String _marginLabel(MarginPreset key, AppLocalizations l) {
    switch (key) {
      case MarginPreset.normal: return l.marginNormal;
      case MarginPreset.narrow: return l.marginNarrow;
      case MarginPreset.wide: return l.marginWide;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final bottomPad = MediaQuery.of(context).viewInsets.bottom
        + MediaQuery.of(context).viewPadding.bottom + 16;

    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24, bottom: bottomPad,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Center(
              child: Text(
                l.documentPageSetup,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 24),

            // Paper size
            Text(l.paperSize, style: const TextStyle(
              fontWeight: FontWeight.w600, color: AppColors.grey800)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: PrintSetup.paperSizes.map((s) => ChoiceChip(
                label: Text(_paperLabel(s, l)),
                selected: _draft.paperSize == s,
                onSelected: (_) =>
                    setState(() => _draft = _draft.copyWith(paperSize: s)),
              )).toList(),
            ),
            const SizedBox(height: 16),

            // Orientation
            Text(l.orientationLabel, style: const TextStyle(
              fontWeight: FontWeight.w600, color: AppColors.grey800)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(l.orientationPortrait),
                  selected: !_draft.isLandscape,
                  onSelected: (_) =>
                      setState(() => _draft = _draft.copyWith(isLandscape: false)),
                ),
                ChoiceChip(
                  label: Text(l.orientationLandscape),
                  selected: _draft.isLandscape,
                  onSelected: (_) =>
                      setState(() => _draft = _draft.copyWith(isLandscape: true)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Margins
            Text(l.marginsLabel, style: const TextStyle(
              fontWeight: FontWeight.w600, color: AppColors.grey800)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: PrintSetup.marginPresets.map((m) => ChoiceChip(
                label: Text(_marginLabel(m, l)),
                selected: _draft.marginPreset == m,
                onSelected: (_) =>
                    setState(() => _draft = _draft.copyWith(marginPreset: m)),
              )).toList(),
            ),
            const SizedBox(height: 16),

            // Header
            const Divider(),
            const SizedBox(height: 8),
            Text(l.documentHeader, style: const TextStyle(
              fontWeight: FontWeight.w600, color: AppColors.grey800)),
            const SizedBox(height: 8),
            TextField(
              controller: _headerCtrl,
              decoration: InputDecoration(
                hintText: l.documentHeaderHint,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),

            // Footer
            Text(l.documentFooter, style: const TextStyle(
              fontWeight: FontWeight.w600, color: AppColors.grey800)),
            const SizedBox(height: 8),
            TextField(
              controller: _footerCtrl,
              decoration: InputDecoration(
                hintText: l.documentFooterHint,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '{page}, {pages}, {title}, {date}',
              style: TextStyle(fontSize: 11, color: AppColors.grey600),
            ),

            const SizedBox(height: 16),

            // Page numbers toggle
            SwitchListTile(
              title: Text(l.showPageNumbers),
              value: _draft.showPageNumbers,
              onChanged: (v) =>
                  setState(() => _draft = _draft.copyWith(showPageNumbers: v)),
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 16),

            // Apply button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => widget.onApply(
                  _draft,
                  _headerCtrl.text,
                  _footerCtrl.text,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.documentBlue,
                ),
                child: Text(l.pageSetupApply),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
