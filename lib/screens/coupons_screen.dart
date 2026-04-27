import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => CouponsScreenState();
}

class CouponsScreenState extends State<CouponsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<Map<String, dynamic>> _coupons = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  // Public so GlobalKey can call it from AdminShell FAB
  void reload() => _load();

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final snap = await FirebaseService.instance.getAllCoupons();
    setState(() {
      _coupons = snap;
      _loading = false;
    });
  }

  // ── Filter helpers ──────────────────────────────────────────────
  bool _isExpired(Map<String, dynamic> c) {
    // 1. Date-based expiry — applies to ALL coupons.
    final exp = c['expiresAt'] as String?;
    if (exp != null &&
        (DateTime.tryParse(exp)?.isBefore(DateTime.now()) ?? false)) {
      return true;
    }
    // 2. Generated coupons move to Expired once fully used.
    //    Existing (pre-generated) coupons lack this flag → old logic only.
    if (c['isGenerated'] == true && _isExhausted(c)) return true;
    return false;
  }

  bool _isExhausted(Map<String, dynamic> c) {
    final max = c['maxUses'] as int?;
    final used = (c['usedCount'] as num?)?.toInt() ?? 0;
    return max != null && used >= max;
  }

  bool _isActive(Map<String, dynamic> c) =>
      !_isExpired(c) && !_isExhausted(c) && (c['active'] == true);

  List<Map<String, dynamic>> get _active =>
      _coupons.where(_isActive).toList();
  List<Map<String, dynamic>> get _expired =>
      _coupons.where(_isExpired).toList();
  List<Map<String, dynamic>> get _exhausted =>
      _coupons.where((c) => !_isExpired(c) && _isExhausted(c)).toList();

  // ── Build ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Tab bar
        Container(
          color: const Color(0xFF2C1A12),
          child: TabBar(
            controller: _tabs,
            tabs: [
              Tab(text: 'Active (${_active.length})'),
              Tab(text: 'Expired (${_expired.length})'),
            ],
            indicatorColor: colorScheme.primary,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurface.withAlpha(150),
          ),
        ),

        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _CouponList(coupons: _active, onRefresh: _load, labelColor: Colors.green),
                      _CouponList(coupons: _expired, onRefresh: _load, labelColor: Colors.redAccent, badge: 'EXPIRED'),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

// ── Coupon list tab ─────────────────────────────────────────────────
class _CouponList extends StatelessWidget {
  final List<Map<String, dynamic>> coupons;
  final VoidCallback onRefresh;
  final Color labelColor;
  final String? badge;

  const _CouponList({
    required this.coupons,
    required this.onRefresh,
    required this.labelColor,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    if (coupons.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_offer_outlined,
                size: 48, color: Theme.of(context).colorScheme.onSurface.withAlpha(50)),
            const SizedBox(height: 10),
            Text(
              'No coupons here',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(100)),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: coupons.length,
      itemBuilder: (_, i) => _CouponCard(
        coupon: coupons[i],
        onRefresh: onRefresh,
        labelColor: labelColor,
        badge: badge,
        rotatable: badge == null, // only active (no badge) cards rotate
      ),
    );
  }
}

// ── Individual coupon card ──────────────────────────────────────────
class _CouponCard extends StatefulWidget {
  final Map<String, dynamic> coupon;
  final VoidCallback onRefresh;
  final Color labelColor;
  final String? badge;
  // Whether this card allows rotation (only active tab)
  final bool rotatable;

  const _CouponCard({
    required this.coupon,
    required this.onRefresh,
    required this.labelColor,
    this.badge,
    this.rotatable = false,
  });

  @override
  State<_CouponCard> createState() => _CouponCardState();
}

class _CouponCardState extends State<_CouponCard> {
  bool _rotating = false;

  Future<void> _copyAndRotate() async {
    if (_rotating) return;
    final code = widget.coupon['code'] as String? ?? '';

    // Copy old code to clipboard first
    await Clipboard.setData(ClipboardData(text: code));

    if (!widget.rotatable) {
      // Non-active tabs: just copy, no rotation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied: $code'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _rotating = true);
    try {
      final newCode = await FirebaseService.instance
          .rotateCouponCode(code, widget.coupon);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied: $code  →  New code ready: $newCode'),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green.shade800,
          ),
        );
        widget.onRefresh();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _rotating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rotating code: $e')),
        );
      }
    }
  }

  Future<void> _deleteCoupon() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Coupon?'),
        content: Text('Are you sure you want to permanently delete ${widget.coupon['code']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseService.instance.deleteCoupon(widget.coupon['code']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coupon deleted')),
        );
        widget.onRefresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final code = widget.coupon['code'] as String? ?? '—';
    final type = widget.coupon['discountType'] as String? ?? 'flat';
    final value = (widget.coupon['discountValue'] as num?)?.toDouble() ?? 0;
    final desc = widget.coupon['description'] as String? ?? '';
    final expires = widget.coupon['expiresAt'] as String?;

    final discountLabel = type == 'percent'
        ? '${value.toStringAsFixed(0)}% OFF'
        : '₹${value.toStringAsFixed(0)} OFF';
    final expiryLabel = expires != null
        ? DateFormat('dd MMM yyyy').format(DateTime.parse(expires))
        : 'No expiry';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: _copyAndRotate,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Discount badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: widget.labelColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: widget.labelColor.withAlpha(100)),
                    ),
                    child: Text(
                      discountLabel,
                      style: TextStyle(
                        color: widget.labelColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _rotating
                                  ? Row(children: [
                                      const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2)),
                                      const SizedBox(width: 8),
                                      const Text('Refreshing…',
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontStyle: FontStyle.italic)),
                                    ])
                                  : Row(children: [
                                      Text(
                                        code,
                                        style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 17,
                                            letterSpacing: 1.5),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(Icons.copy_rounded,
                                          size: 14,
                                          color: colorScheme.onSurface
                                              .withAlpha(100)),
                                    ]),
                            ),
                            if (widget.badge != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color:
                                      widget.labelColor.withAlpha(25),
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: Text(
                                  widget.badge!,
                                  style: TextStyle(
                                      color: widget.labelColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          desc,
                          style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withAlpha(160)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Footer: expiry + rotate hint (active) or just expiry (others)
              Row(
                children: [
                  Icon(Icons.event_rounded,
                      size: 13,
                      color: colorScheme.onSurface.withAlpha(130)),
                  const SizedBox(width: 4),
                  Text(expiryLabel,
                      style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withAlpha(150))),
                  if (widget.rotatable) ...[
                    const Spacer(),
                    Icon(Icons.touch_app_rounded,
                        size: 13,
                        color: colorScheme.primary.withAlpha(160)),
                    const SizedBox(width: 4),
                    Text('Tap to copy & rotate',
                        style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.primary.withAlpha(160),
                            fontStyle: FontStyle.italic)),
                  ],
                  if (!widget.rotatable) const Spacer(),
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded,
                        size: 18, color: Colors.redAccent.withAlpha(200)),
                    onPressed: _deleteCoupon,
                    tooltip: 'Delete Coupon',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Generate coupon dialog ─────────────────────────────────────────
class GenerateCouponDialog extends StatefulWidget {
  final VoidCallback onCreated;

  const GenerateCouponDialog({super.key, required this.onCreated});

  @override
  State<GenerateCouponDialog> createState() => _GenerateCouponDialogState();
}

class _GenerateCouponDialogState extends State<GenerateCouponDialog> {
  final _codeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  DateTime? _expiry;
  String _discountType = 'percent';
  bool _saving = false;

  final _currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

  // Auto-generate a random code
  void _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final buf = StringBuffer();
    for (var i = 0; i < 8; i++) {
      buf.write(chars[(DateTime.now().microsecondsSinceEpoch + i * 31) % chars.length]);
    }
    _codeCtrl.text = buf.toString();
  }

  Future<void> _pickExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _expiry = picked);
  }

  Future<void> _save() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    final value = double.tryParse(_valueCtrl.text.trim());
    final desc = _descCtrl.text.trim();

    if (code.isEmpty || value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid code and discount value')),
      );
      return;
    }

    setState(() => _saving = true);
    await FirebaseService.instance.createCoupon({
      'code': code,
      'discountType': _discountType,
      'discountValue': value,
      'description': desc.isEmpty
          ? (_discountType == 'percent'
              ? '${value.toStringAsFixed(0)}% off'
              : '${_currency.format(value)} off')
          : desc,
      'maxUses': 1,   // Always single-use
      'usedCount': 0,
      'expiresAt': _expiry != null
          ? '${_expiry!.toIso8601String().substring(0, 10)}T23:59:59'
          : '2026-12-31T23:59:59',
      'active': true,
      // Flag that marks this coupon as admin-generated.
      // Used by _isExpired() to move it to the Expired tab once redeemed.
      'isGenerated': true,
    });

    if (mounted) Navigator.pop(context);
    widget.onCreated();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _descCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.add_card_rounded, color: Color(0xFFD4A574)),
          SizedBox(width: 10),
          Text('Generate Coupon',
              style: TextStyle(color: Color(0xFFF5E6D3))),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Code row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Coupon Code *',
                        prefixIcon: Icon(Icons.local_offer_rounded),
                        hintText: 'e.g. SUMMER20',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Auto-generate code',
                    onPressed: () => setState(_generateCode),
                    icon: const Icon(Icons.shuffle_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.primaryContainer,
                      foregroundColor: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Discount type
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'percent', label: Text('Percentage %')),
                  ButtonSegment(value: 'flat', label: Text('Flat ₹')),
                ],
                selected: {_discountType},
                onSelectionChanged: (s) =>
                    setState(() => _discountType = s.first),
              ),
              const SizedBox(height: 12),

              // Value
              TextField(
                controller: _valueCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText:
                      _discountType == 'percent' ? 'Discount %' : 'Discount ₹',
                  prefixIcon: Icon(
                    _discountType == 'percent'
                        ? Icons.percent_rounded
                        : Icons.currency_rupee_rounded,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Description
              TextField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  prefixIcon: Icon(Icons.short_text_rounded),
                ),
              ),
              const SizedBox(height: 12),

              // Single-use info chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withAlpha(40),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colorScheme.primary.withAlpha(60)),
                ),
                child: Row(children: [
                  Icon(Icons.info_outline_rounded,
                      size: 14, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Each code is single-use. Rotate on copy.',
                    style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.primary.withAlpha(200)),
                  ),
                ]),
              ),
              const SizedBox(height: 12),

              // Expiry picker
              InkWell(
                onTap: _pickExpiry,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withAlpha(60),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: colorScheme.outline.withAlpha(60)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_rounded, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        _expiry != null
                            ? 'Expires: ${DateFormat('dd MMM yyyy').format(_expiry!)}'
                            : 'Set expiry date (default Dec 2026)',
                        style: TextStyle(
                            color: colorScheme.onSurface.withAlpha(180)),
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel',
              style: TextStyle(color: Color(0xFFD4A574))),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.check_rounded),
          label: const Text('Create',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
