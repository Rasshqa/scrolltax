// ponytail: Direct screenshot-to-share workflow with Web download fallback.

import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/services/usage_tracker_service.dart';
import '../../core/theme/hypercar_theme.dart';
import 'widgets/serrated_receipt_card.dart';

class ReceiptScreen extends ConsumerStatefulWidget {
  const ReceiptScreen({super.key});

  @override
  ConsumerState<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends ConsumerState<ReceiptScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  ReceiptSkin _skin = ReceiptSkin.mattePaper;
  bool _isExporting = false;
  late final String _receiptSerial;

  @override
  void initState() {
    super.initState();
    // Unique serial number based on date and millisecond nonce
    final now = DateTime.now();
    _receiptSerial = 'STX-${now.year}-${(now.millisecondsSinceEpoch % 100000).toString().padLeft(5, '0')}';
  }

  Future<void> _exportAndShare() async {
    setState(() => _isExporting = true);
    try {
      final imageBytes = await _screenshotController.capture(
        pixelRatio: 2.5,
        delay: const Duration(milliseconds: 100),
      );

      if (imageBytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to generate image capture.')),
          );
        }
        return;
      }

      if (kIsWeb) {
        // Web share or clipboard/download
        final xFile = XFile.fromData(
          imageBytes,
          name: 'scrolltax_receipt_$_receiptSerial.png',
          mimeType: 'image/png',
        );
        await SharePlus.instance.share(
          ShareParams(
            files: [xFile],
            text: 'My ScrollTax Doomscroll Invoice ($_receiptSerial). Check your opportunity cost!',
          ),
        );
      } else {
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/scrolltax_receipt_$_receiptSerial.png';
        final file = File(filePath);
        await file.writeAsBytes(imageBytes);

        final xFile = XFile(filePath, mimeType: 'image/png');
        await SharePlus.instance.share(
          ShareParams(
            files: [xFile],
            text: 'My ScrollTax Doomscroll Invoice ($_receiptSerial). Total Tax Levied.',
          ),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: HypercarColors.carbonElevated,
            content: Text(
              'Receipt exported successfully!',
              style: HypercarTheme.monoStyle(color: HypercarColors.matrixGreen),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: HypercarColors.carbonElevated,
            content: Text(
              'Export failed: $e',
              style: HypercarTheme.monoStyle(color: HypercarColors.laserRed),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(usageTrackerProvider);

    if (state.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: HypercarColors.solarOrange),
        ),
      );
    }

    final telemetry = state.telemetry;

    return Scaffold(
      backgroundColor: HypercarColors.obsidianBg,
      appBar: AppBar(
        backgroundColor: HypercarColors.obsidianBg,
        elevation: 0,
        title: Text(
          '9:16 THERMAL RECEIPT',
          style: HypercarTheme.monoStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          // Skin switcher toggle
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              tooltip: 'Switch receipt style',
              icon: Icon(
                _skin == ReceiptSkin.mattePaper ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                color: HypercarColors.cyberCyan,
              ),
              onPressed: () {
                setState(() {
                  _skin = _skin == ReceiptSkin.mattePaper ? ReceiptSkin.stealthCarbon : ReceiptSkin.mattePaper;
                });
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              // Style Selector Pills
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: HypercarColors.carbonSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: HypercarColors.carbonBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _skin = ReceiptSkin.mattePaper),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _skin == ReceiptSkin.mattePaper ? HypercarColors.solarOrange : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'MATTE THERMAL',
                            style: HypercarTheme.monoStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _skin == ReceiptSkin.mattePaper ? Colors.black : HypercarColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _skin = ReceiptSkin.stealthCarbon),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _skin == ReceiptSkin.stealthCarbon ? HypercarColors.solarOrange : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'STEALTH CARBON',
                            style: HypercarTheme.monoStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _skin == ReceiptSkin.stealthCarbon ? Colors.black : HypercarColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 9:16 Canvas for Social Media Story Export
              Center(
                child: Screenshot(
                  controller: _screenshotController,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _skin == ReceiptSkin.mattePaper ? const Color(0xFFE4E4DC) : const Color(0xFF0C0D10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: HypercarColors.carbonBorder, width: 1.5),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: SerratedReceiptCard(
                      telemetry: telemetry,
                      skin: _skin,
                      receiptNumber: _receiptSerial,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Export button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isExporting ? null : _exportAndShare,
                  icon: _isExporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Icon(Icons.share_rounded, size: 20),
                  label: Text(_isExporting ? 'EXPORTING INVOICE...' : 'EXPORT 9:16 RECEIPT TO STORY'),
                ),
              ),

              const SizedBox(height: 12),
              Text(
                'High-contrast thermal invoice ready for Instagram Story and social accountability.',
                textAlign: TextAlign.center,
                style: HypercarTheme.monoStyle(
                  fontSize: 10,
                  color: HypercarColors.textMuted,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
