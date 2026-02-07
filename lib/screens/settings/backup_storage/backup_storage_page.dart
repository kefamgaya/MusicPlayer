import 'dart:io';

import 'package:easy_folder_picker/FolderPicker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../generated/l10n.dart';
import '../../../services/bottom_message.dart';
import 'cubit/backup_storage_cubit.dart';

class BackupStoragePage extends StatelessWidget {
  const BackupStoragePage({super.key});

  static const Color _bg = Color(0xFF0A0A0A);
  static const Color _primary = Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.spaceGroteskTextTheme(Theme.of(context).textTheme);

    return BlocProvider(
      create: (_) => BackupStorageCubit(),
      child: BlocListener<BackupStorageCubit, BackupStorageState>(
        listenWhen: (_, state) => state.lastResult != null,
        listener: (context, state) {
          final result = state.lastResult;
          if (result == null) return;
          if (result is BackupSuccess) {
            BottomMessage.showText(context, '${S.of(context).Backup_Success} ${result.path}');
          } else if (result is BackupFailure) {
            BottomMessage.showText(context, S.of(context).Backup_Failed);
          } else if (result is RestoreSuccess) {
            BottomMessage.showText(context, S.of(context).Restore_Success);
          } else if (result is RestoreFailure) {
            BottomMessage.showText(context, S.of(context).Restore_Failed);
          }
        },
        child: Theme(
          data: Theme.of(context).copyWith(
            scaffoldBackgroundColor: _bg,
            textTheme: textTheme,
          ),
          child: Scaffold(
            backgroundColor: _bg,
            body: SafeArea(
              bottom: false,
              child: BlocBuilder<BackupStorageCubit, BackupStorageState>(
                builder: (context, state) {
                  final cubit = context.read<BackupStorageCubit>();

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      _header(context),
                      const SizedBox(height: 14),
                      if (Platform.isAndroid)
                        _section(
                          title: 'STORAGE',
                          children: [
                            _tile(
                              icon: Icons.folder,
                              title: 'App Folder',
                              subtitle: state.appFolder,
                              trailing: _smallTag('CHANGE'),
                              onTap: () async {
                                final dir = await FolderPicker.pick(
                                  context: context,
                                  allowFolderCreation: true,
                                  rootDirectory: Directory(state.appFolder),
                                );
                                if (dir != null) cubit.setAppFolder(dir.path);
                              },
                            ),
                          ],
                        ),
                      if (Platform.isAndroid) const SizedBox(height: 14),
                      _section(
                        title: 'BACKUP and RESTORE',
                        children: [
                          _tile(
                            icon: Icons.backup_rounded,
                            title: S.of(context).Backup,
                            subtitle: 'Export selected data',
                            onTap: () async {
                              final result = await showBackupSelector(context);
                              if (result == null) return;
                              cubit.backup(action: result.$1, items: result.$2);
                            },
                          ),
                          _tile(
                            icon: Icons.restore_rounded,
                            title: S.of(context).Restore,
                            subtitle: 'Import a backup file',
                            onTap: cubit.restore,
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 2),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2)),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              S.of(context).Backup_And_Restore.toUpperCase(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
                letterSpacing: -0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: _primary, width: 4)),
            ),
            child: Text(
              title,
              style: GoogleFonts.spaceMono(
                fontSize: 11,
                letterSpacing: 2.2,
                color: Colors.white.withValues(alpha: 0.55),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              color: _primary.withValues(alpha: 0.2),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.58)),
                  ),
                ],
              ),
            ),
            trailing ?? Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }

  Widget _smallTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
      ),
      child: Text(
        text,
        style: GoogleFonts.spaceMono(fontSize: 10, color: Colors.white.withValues(alpha: 0.7)),
      ),
    );
  }
}

Future<(String, List)?> showBackupSelector(BuildContext context) async {
  const bg = Color(0xFF0A0A0A);
  const primary = Color(0xFF10B981);

  return showModalBottomSheet<(String, List)?>(
    context: context,
    backgroundColor: bg,
    shape: const RoundedRectangleBorder(),
    builder: (context) {
      final items = ValueNotifier<List<Map<String, dynamic>>>([
        {'name': 'Favourites', 'selected': false},
        {'name': 'Playlists', 'selected': false},
        {'name': 'Settings', 'selected': false},
        {'name': 'Song History', 'selected': false},
        {'name': 'Downloads', 'selected': false},
      ]);

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    S.of(context).Select_Backup.toUpperCase(),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: items,
              builder: (_, backups, __) {
                return Column(
                  children: backups.indexed.map((el) {
                    final index = el.$1;
                    final item = el.$2;
                    return InkWell(
                      onTap: () {
                        final updated = List<Map<String, dynamic>>.from(items.value);
                        updated[index]['selected'] = !(updated[index]['selected'] == true);
                        items.value = updated;
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          border: Border.all(
                            color: item['selected'] == true
                                ? primary
                                : Colors.white.withValues(alpha: 0.15),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item['selected'] == true ? Icons.check_box : Icons.check_box_outline_blank,
                              color: item['selected'] == true ? primary : Colors.white.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item['name'],
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _backupActionButton(
                    context,
                    label: S.of(context).Share,
                    action: 'Share',
                    items: items,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _backupActionButton(
                    context,
                    label: S.of(context).Save,
                    action: 'Save',
                    items: items,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

Widget _backupActionButton(
  BuildContext context, {
  required String label,
  required String action,
  required ValueNotifier<List<Map<String, dynamic>>> items,
}) {
  return InkWell(
    onTap: () {
      final selected = items.value
          .where((e) => e['selected'] == true)
          .map((e) => e['name'].toLowerCase())
          .toList();
      Navigator.pop(context, selected.isEmpty ? null : (action, selected));
    },
    child: Container(
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF10B981),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
      ),
    ),
  );
}
