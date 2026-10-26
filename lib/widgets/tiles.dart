import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/models.dart';
import '../screens/income_form_screen.dart';
import '../screens/payment_form_screen.dart';
import '../screens/vendor_detail_screen.dart';
import '../theme.dart';
import '../utils/category_icons.dart';
import '../utils/format.dart';
import 'common.dart';

Color vendorStatusColor(VendorStatus s) => switch (s) {
      VendorStatus.unpaid => AppColors.danger,
      VendorStatus.partial => AppColors.warning,
      VendorStatus.paid => AppColors.success,
    };

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});

  final VendorStatus status;

  @override
  Widget build(BuildContext context) {
    final color = vendorStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class IncomeTile extends StatelessWidget {
  const IncomeTile({super.key, required this.income});

  final Income income;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = s.contributorById(income.contributorId);
    final color = paletteColor(c?.colorIndex ?? 0);
    final name = c?.name ?? 'Penyetor';
    final subtitle = income.note.isEmpty
        ? formatDate(income.date)
        : '${formatDate(income.date)} • ${income.note}';
    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () => pushPage(context, IncomeFormScreen(income: income)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Text(
              initialOf(name),
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '+${rupiah(income.amount)}',
            style: const TextStyle(
                color: AppColors.success, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class PaymentTile extends StatelessWidget {
  const PaymentTile({super.key, required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final category = s.categoryById(payment.categoryId);
    final vendor = s.vendorById(payment.vendorId);
    final title = vendor?.name ?? category?.name ?? 'Pengeluaran';
    final parts = <String>[
      payment.type,
      formatDate(payment.date),
      if (vendor != null && category != null) category.name,
      if (payment.note.isNotEmpty) payment.note,
    ];
    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () => pushPage(context, PaymentFormScreen(payment: payment)),
      child: Row(
        children: [
          IconBox(iconFor(category?.iconKey), size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  parts.join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '-${rupiah(payment.amount)}',
            style: const TextStyle(
                color: AppColors.danger, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class VendorTile extends StatelessWidget {
  const VendorTile({super.key, required this.vendor});

  final Vendor vendor;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final category = s.categoryById(vendor.categoryId);
    final status = s.vendorStatus(vendor);
    final paid = s.paidToVendor(vendor.id!);
    final due = vendor.dueDate;
    final overdue = due != null &&
        status != VendorStatus.paid &&
        daysBetween(DateTime.now(), due) < 0;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      onTap: () => pushPage(context, VendorDetailScreen(vendorId: vendor.id!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBox(iconFor(category?.iconKey), size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      category?.name ?? '-',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              StatusBadge(status),
            ],
          ),
          if (vendor.contractPrice > 0) ...[
            const SizedBox(height: 12),
            RoundedProgress(
              value: paid / vendor.contractPrice,
              color: vendorStatusColor(status),
              height: 8,
            ),
            const SizedBox(height: 6),
            Text(
              'Dibayar ${rupiah(paid)} dari ${rupiah(vendor.contractPrice)}',
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
          if (due != null && status != VendorStatus.paid) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.event,
                    size: 14,
                    color: overdue ? AppColors.danger : AppColors.muted),
                const SizedBox(width: 4),
                Text(
                  'Jatuh tempo ${formatDate(due)} (${dueLabel(due)})',
                  style: TextStyle(
                    fontSize: 12,
                    color: overdue ? AppColors.danger : AppColors.muted,
                    fontWeight: overdue ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
