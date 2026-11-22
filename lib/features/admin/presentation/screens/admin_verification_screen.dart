import 'package:flutter/material.dart';
import '../../../../core/constants/vehicle_types.dart';
import '../../../../core/providers/app_scope.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/language_toggle_button.dart';
import '../../../../core/widgets/notification_bell_button.dart';
import '../../../../core/widgets/verified_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/domain/user_profile.dart';

class AdminVerificationScreen extends StatefulWidget {
  const AdminVerificationScreen({super.key});

  @override
  State<AdminVerificationScreen> createState() => _AdminVerificationScreenState();
}

class _AdminVerificationScreenState extends State<AdminVerificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _customReasonCtrl = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customReasonCtrl.dispose();
    super.dispose();
  }

  void _showDocumentZoomDialog(
    BuildContext context, {
    required String title,
    required String? imageUrl,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 8),
                    Expanded(
                      child: InteractiveViewer(
                        minScale: 0.8,
                        maxScale: 4.0,
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.contain,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.broken_image, size: 64, color: Colors.white54),
                                        SizedBox(height: 8),
                                        Text('Image could not be loaded', style: TextStyle(color: Colors.white70)),
                                      ],
                                    ),
                                  );
                                },
                              )
                            : const Center(
                                child: Text('No document uploaded', style: TextStyle(color: Colors.white54)),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pinch or scroll to zoom / دستاویز کو بڑا کرنے کے لیے زوم کریں',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _approveDriver(UserProfile driver) async {
    setState(() => _isProcessing = true);
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    try {
      await FirebaseService.instance.updateDriverVerificationStatus(
        uid: driver.id,
        status: 'verified',
      );
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text('${driver.fullName}: ${l10n.driverApprovedSuccess}'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('Failed to approve driver: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showRejectBottomSheet(UserProfile driver) {
    final l10n = AppLocalizations.of(context)!;
    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';
    String? selectedPresetReason;
    _customReasonCtrl.clear();

    final presetReasons = [
      l10n.reasonBlurryPhoto,
      l10n.reasonExpiredLicense,
      l10n.reasonCnicMismatch,
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.rejectButton,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.danger,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(sheetCtx),
                      ),
                    ],
                  ),
                  Text(
                    '${driver.fullName} (${driver.phone})',
                    style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.rejectionReasonPrompt,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  ...presetReasons.map((reason) {
                    final isSelected = selectedPresetReason == reason;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: InkWell(
                        onTap: () {
                          setSheetState(() {
                            selectedPresetReason = reason;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.danger.withValues(alpha: 0.1) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? AppColors.danger : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: isSelected ? AppColors.danger : Colors.grey,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  reason,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _customReasonCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: l10n.enterCustomReason,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      final reason = _customReasonCtrl.text.trim().isNotEmpty
                          ? _customReasonCtrl.text.trim()
                          : (selectedPresetReason ?? (isUrdu ? 'دستاویزات نامکمل ہیں' : 'Documents incomplete'));

                      Navigator.pop(sheetCtx);

                      setState(() => _isProcessing = true);
                      try {
                        await FirebaseService.instance.updateDriverVerificationStatus(
                          uid: driver.id,
                          status: 'rejected',
                          rejectionReason: reason,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.danger,
                              content: Text(l10n.driverRejectedSuccess),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.danger,
                              content: Text('Failed to reject driver: $e'),
                            ),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _isProcessing = false);
                      }
                    },
                    child: Text(
                      l10n.rejectButton,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDocumentThumbnail({
    required BuildContext context,
    required String title,
    required String? imageUrl,
    required IconData icon,
  }) {
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Expanded(
      child: InkWell(
        onTap: () => _showDocumentZoomDialog(context, title: title, imageUrl: imageUrl),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 70,
                  width: double.infinity,
                  child: hasImage
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(
                            color: Colors.grey.shade200,
                            child: Icon(icon, color: Colors.grey),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: Icon(icon, color: Colors.grey),
                        ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.zoom_in, size: 14, color: AppColors.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDriverCard(UserProfile driver, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';
    final isPending = driver.verificationStatus == 'pending';
    final isVerified = driver.verificationStatus == 'verified';
    final isRejected = driver.verificationStatus == 'rejected';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Driver Profile Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    driver.fullName.isNotEmpty ? driver.fullName[0] : 'D',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              driver.fullName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 8),
                          VerifiedBadge(isVerified: isVerified),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${driver.phone} • CNIC: ${driver.cnicNumber ?? "N/A"}',
                        style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                      ),
                      if (driver.vehicleTypes.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          children: driver.vehicleTypes.map((v) {
                            final vType = VehicleType.findById(v);
                            final name = isUrdu ? (vType?.nameUr ?? v) : (vType?.nameEn ?? v);
                            return Chip(
                              label: Text(
                                name,
                                style: const TextStyle(fontSize: 11),
                              ),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              backgroundColor: Colors.amber.shade50,
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPending
                        ? Colors.orange.shade100
                        : (isVerified ? Colors.green.shade100 : Colors.red.shade100),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isPending
                        ? l10n.pendingReview
                        : (isVerified ? l10n.verifiedDrivers : l10n.rejectedDrivers),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isPending
                          ? Colors.orange.shade900
                          : (isVerified ? Colors.green.shade900 : Colors.red.shade900),
                    ),
                  ),
                ),
              ],
            ),

            if (isRejected && driver.rejectionReason != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.danger, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        driver.rejectionReason!,
                        style: const TextStyle(color: AppColors.danger, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),
            Text(
              isUrdu ? 'اپ لوڈ کردہ دستاویزات (دیکھنے کیلئے ٹیپ کریں):' : 'Uploaded Verification Documents (Tap to inspect):',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
            const SizedBox(height: 8),

            // Document Thumbnails Row
            Row(
              children: [
                _buildDocumentThumbnail(
                  context: context,
                  title: l10n.cnicDocument,
                  imageUrl: driver.cnicFrontUrl,
                  icon: Icons.badge,
                ),
                const SizedBox(width: 8),
                _buildDocumentThumbnail(
                  context: context,
                  title: l10n.licenseDocument,
                  imageUrl: driver.licenseUrl,
                  icon: Icons.drive_eta,
                ),
                const SizedBox(width: 8),
                _buildDocumentThumbnail(
                  context: context,
                  title: l10n.registrationDocument,
                  imageUrl: driver.registrationUrl,
                  icon: Icons.description,
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isRejected)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _isProcessing ? null : () => _showRejectBottomSheet(driver),
                    icon: const Icon(Icons.close, size: 18),
                    label: Text(l10n.rejectButton),
                  ),
                if (!isRejected) const SizedBox(width: 12),
                if (!isVerified)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _isProcessing ? null : () => _approveDriver(driver),
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(l10n.approveButton),
                  )
                else
                  Text(
                    driver.verifiedAt != null
                        ? '${l10n.verifiedDrivers}: ${driver.verifiedAt!.day}/${driver.verifiedAt!.month}/${driver.verifiedAt!.year}'
                        : l10n.verifiedDrivers,
                    style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';
    final auth = context.auth;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminVerificationTitle),
        actions: [
          IconButton(
            icon: Icon(
              auth.isAdmin ? Icons.admin_panel_settings : Icons.person_outline,
              color: auth.isAdmin ? Colors.amber : Colors.white70,
            ),
            tooltip: l10n.toggleAdminMode,
            onPressed: () {
              context.authActions.toggleAdminMode();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    context.auth.isAdmin
                        ? (isUrdu ? 'ایڈمن موڈ آن ہے' : 'Admin mode enabled')
                        : (isUrdu ? 'ایڈمن موڈ بند ہے' : 'Admin mode disabled'),
                  ),
                ),
              );
            },
          ),
          const NotificationBellButton(),
          const Center(child: LanguageToggleButton(compact: true)),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          tabs: [
            Tab(text: l10n.pendingReview),
            Tab(text: l10n.verifiedDrivers),
            Tab(text: l10n.rejectedDrivers),
          ],
        ),
      ),
      body: StreamBuilder<List<UserProfile>>(
        stream: FirebaseService.instance.watchAllDrivers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDrivers = snapshot.data ?? FirebaseService.defaultSampleDrivers;
          final pendingDrivers = allDrivers.where((d) => d.verificationStatus == 'pending').toList();
          final verifiedDrivers = allDrivers.where((d) => d.verificationStatus == 'verified').toList();
          final rejectedDrivers = allDrivers.where((d) => d.verificationStatus == 'rejected').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              // Pending Tab
              pendingDrivers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
                          const SizedBox(height: 12),
                          Text(l10n.noPendingDrivers, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: pendingDrivers.length,
                      itemBuilder: (ctx, idx) => _buildDriverCard(pendingDrivers[idx], ctx),
                    ),

              // Verified Tab
              verifiedDrivers.isEmpty
                  ? Center(
                      child: Text(l10n.noVerifiedDrivers, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                    )
                  : ListView.builder(
                      itemCount: verifiedDrivers.length,
                      itemBuilder: (ctx, idx) => _buildDriverCard(verifiedDrivers[idx], ctx),
                    ),

              // Rejected Tab
              rejectedDrivers.isEmpty
                  ? Center(
                      child: Text(l10n.noRejectedDrivers, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                    )
                  : ListView.builder(
                      itemCount: rejectedDrivers.length,
                      itemBuilder: (ctx, idx) => _buildDriverCard(rejectedDrivers[idx], ctx),
                    ),
            ],
          );
        },
      ),
    );
  }
}
