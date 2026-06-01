import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../config/api_config.dart';
import '../../providers/task_provider.dart';
import '../../providers/platform_provider.dart';

class TrainSearchScreen extends StatefulWidget {
  final bool embedded;
  const TrainSearchScreen({super.key, this.embedded = false});

  @override
  State<TrainSearchScreen> createState() => _TrainSearchScreenState();
}

class _TrainSearchScreenState extends State<TrainSearchScreen> {
  final _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  // Station search
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  final _fromFocus = FocusNode();
  final _toFocus = FocusNode();
  final _fromLayer = LayerLink();
  final _toLayer = LayerLink();
  OverlayEntry? _fromOverlay;
  OverlayEntry? _toOverlay;
  List<Map<String, dynamic>> _fromResults = [];
  List<Map<String, dynamic>> _toResults = [];
  Timer? _fromDebounce;
  Timer? _toDebounce;
  Map<String, dynamic>? _fromStation;
  Map<String, dynamic>? _toStation;

  DateTime _date = DateTime.now();
  List<Map<String, dynamic>> _trains = [];
  bool _loading = false;
  String? _error;
  bool _queried = false;

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _fromFocus.dispose();
    _toFocus.dispose();
    _fromDebounce?.cancel();
    _toDebounce?.cancel();
    _removeFromOverlay();
    _removeToOverlay();
    _dio.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fromCtrl.addListener(_onFromChanged);
    _toCtrl.addListener(_onToChanged);
    _fromFocus.addListener(_onFromFocusChange);
    _toFocus.addListener(_onToFocusChange);
  }

  void _onFromChanged() {
    _fromDebounce?.cancel();
    final q = _fromCtrl.text;
    if (q.isEmpty) {
      _removeFromOverlay();
      return;
    }
    _fromDebounce = Timer(const Duration(milliseconds: 300), () => _fetchStations(q, true));
  }

  void _onToChanged() {
    _toDebounce?.cancel();
    final q = _toCtrl.text;
    if (q.isEmpty) {
      _removeToOverlay();
      return;
    }
    _toDebounce = Timer(const Duration(milliseconds: 300), () => _fetchStations(q, false));
  }

  void _onFromFocusChange() {
    if (!_fromFocus.hasFocus) {
      _fromDebounce?.cancel();
      Future.delayed(const Duration(milliseconds: 150), _removeFromOverlay);
    }
  }

  void _onToFocusChange() {
    if (!_toFocus.hasFocus) {
      _toDebounce?.cancel();
      Future.delayed(const Duration(milliseconds: 150), _removeToOverlay);
    }
  }

  Future<void> _fetchStations(String q, bool isFrom) async {
    try {
      final resp = await _dio.get('/api/v1/12306/stations', queryParameters: {'q': q});
      final List data = resp.data;
      if (isFrom) {
        _fromResults = data.cast<Map<String, dynamic>>();
        _showFromOverlay();
      } else {
        _toResults = data.cast<Map<String, dynamic>>();
        _showToOverlay();
      }
    } catch (_) {}
  }

  void _showFromOverlay() {
    _removeFromOverlay();
    if (_fromResults.isEmpty) return;
    _fromOverlay = OverlayEntry(
      builder: (ctx) => Positioned(
        child: CompositedTransformFollower(link: _fromLayer, offset: const Offset(0, 48), child: _stationList(_fromResults, true)),
      ),
    );
    Overlay.of(context).insert(_fromOverlay!);
  }

  void _showToOverlay() {
    _removeToOverlay();
    if (_toResults.isEmpty) return;
    _toOverlay = OverlayEntry(
      builder: (ctx) => Positioned(
        child: CompositedTransformFollower(link: _toLayer, offset: const Offset(0, 48), child: _stationList(_toResults, false)),
      ),
    );
    Overlay.of(context).insert(_toOverlay!);
  }

  void _removeFromOverlay() {
    _fromOverlay?.remove();
    _fromOverlay = null;
  }

  void _removeToOverlay() {
    _toOverlay?.remove();
    _toOverlay = null;
  }

  void _selectStation(Map<String, dynamic> s, bool isFrom) {
    if (isFrom) {
      _fromCtrl.text = s['name'] as String;
      _fromStation = s;
      _removeFromOverlay();
      _fromFocus.unfocus();
    } else {
      _toCtrl.text = s['name'] as String;
      _toStation = s;
      _removeToOverlay();
      _toFocus.unfocus();
    }
  }

  Widget _stationList(List<Map<String, dynamic>> items, bool isFrom) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 200),
        color: Theme.of(context).colorScheme.surface,
        child: ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          itemCount: items.length,
          itemBuilder: (_, i) {
            final s = items[i];
            return ListTile(
              dense: true,
              title: Text(s['name'] as String),
              trailing: Text(s['code'] as String, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              onTap: () => _selectStation(s, isFrom),
            );
          },
        ),
      ),
    );
  }

  Future<void> _query() async {
    if (_fromStation == null || _toStation == null) {
      setState(() => _error = '请选择出发站和到达站');
      return;
    }
    setState(() { _loading = true; _error = null; _queried = false; _trains = []; });

    try {
      final dateStr = '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';
      final resp = await _dio.get('/api/v1/12306/query', queryParameters: {
        'from_station': _fromStation!['name'],
        'to_station': _toStation!['name'],
        'date': dateStr,
      });
      final data = resp.data;
      final note = data['note'] as String?;
      if (data['error'] != null && data['trains'].isEmpty) {
        setState(() => _error = data['error'] as String);
      } else {
        setState(() {
          _trains = (data['trains'] as List).cast<Map<String, dynamic>>();
          _queried = true;
          if (note != null) _error = note;
        });
      }
    } catch (e) {
      setState(() => _error = '查询失败，请检查网络连接');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _showGrabSheet(Map<String, dynamic> train, String seatType) {
    final dateStr = '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';
    final trainCode = train['train_code'] as String;
    final fromName = train['from_station'] as String;
    final toName = train['to_station'] as String;
    final startTime = train['start_time'] as String;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _GrabTicketSheet(
        trainCode: trainCode,
        fromStation: fromName,
        toStation: toName,
        seatType: seatType,
        date: dateStr,
        startTime: startTime,
        dio: _dio,
      ),
    );
  }

  void _showAlertSheet(Map<String, dynamic> train, String seatType) {
    final dateStr = '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';
    final trainCode = train['train_code'] as String;
    final fromName = train['from_station'] as String;
    final toName = train['to_station'] as String;
    final startTime = train['start_time'] as String;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _AlertTicketSheet(
        trainCode: trainCode,
        fromStation: fromName,
        toStation: toName,
        seatType: seatType,
        date: dateStr,
        startTime: startTime,
        dio: _dio,
      ),
    );
  }

  void _swapStations() {
    final tmpStation = _fromStation;
    final tmpText = _fromCtrl.text;
    setState(() {
      _fromStation = _toStation;
      _toStation = tmpStation;
      _fromCtrl.text = _toCtrl.text;
      _toCtrl.text = tmpText;
    });
    if (_queried) _query();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: widget.embedded ? null : AppBar(title: const Text('12306 余票查询'), elevation: 0),
      body: Column(
        children: [
          _buildHeader(theme),
          if (_loading) const Expanded(child: Center(child: CircularProgressIndicator())),
          if (!_loading && _error != null && !_queried)
            Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Colors.grey[600], fontSize: 15)),
            ]))),
          if (!_loading && _queried && _trains.isEmpty)
            Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.train_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text('未找到符合条件的车次', style: TextStyle(color: Colors.grey[600], fontSize: 15)),
            ]))),
          if (!_loading && !_queried && _trains.isEmpty)
            Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.search, size: 56, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text('选择出发站和到达站，开始查询', style: TextStyle(color: Colors.grey[500], fontSize: 15)),
            ]))),
          if (_error != null && _queried)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: TextStyle(color: Colors.blue.shade700, fontSize: 12))),
              ]),
            ),
          if (!_loading && _trains.isNotEmpty)
            Expanded(child: _buildTrainList()),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CompositedTransformTarget(
                  link: _fromLayer,
                  child: TextField(
                    controller: _fromCtrl,
                    focusNode: _fromFocus,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '出发站',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                      prefixIcon: const Icon(Icons.trip_origin, color: Colors.white70, size: 20),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.15),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: IconButton(
                  icon: const Icon(Icons.swap_horiz, color: Colors.white, size: 28),
                  onPressed: _swapStations,
                  style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.2)),
                ),
              ),
              Expanded(
                child: CompositedTransformTarget(
                  link: _toLayer,
                  child: TextField(
                    controller: _toCtrl,
                    focusNode: _toFocus,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '到达站',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                      prefixIcon: const Icon(Icons.location_on, color: Colors.white70, size: 20),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.15),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.date_range, size: 18, color: Colors.white),
                  label: Text('${_date.month}月${_date.day}日', style: const TextStyle(color: Colors.white, fontSize: 15)),
                  onPressed: _pickDate,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.search, size: 20),
                  label: const Text('查询', style: TextStyle(fontSize: 15)),
                  onPressed: _loading ? null : _query,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrainList() {
    return RefreshIndicator(
      onRefresh: _query,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        itemCount: _trains.length,
        itemBuilder: (_, i) => _trainCard(_trains[i]),
      ),
    );
  }

  Widget _trainCard(Map<String, dynamic> train) {
    final seats = train['seats'] as Map<String, dynamic>;
    final seatColors = {
      '商务座': const Color(0xFFE53935),
      '特等座': const Color(0xFFEF6C00),
      '一等座': const Color(0xFF1E88E5),
      '二等座': const Color(0xFF43A047),
      '软座': const Color(0xFF00ACC1),
      '硬座': const Color(0xFF78909C),
      '软卧': const Color(0xFF8E24AA),
      '硬卧': const Color(0xFF6D4C41),
      '高级软卧': const Color(0xFFFF6F00),
      '无座': const Color(0xFF9E9E9E),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFF1565C0), borderRadius: BorderRadius.circular(4)),
                  child: Text(train['train_code'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text('${train['duration'] ?? ''}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(train['start_time'] ?? '', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFFE65100))),
                const SizedBox(width: 6),
                Text(train['from_station'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                const Expanded(child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Divider(indent: 4, endIndent: 4),
                )),
                Icon(Icons.arrow_forward, size: 16, color: Colors.grey[400]),
                const Expanded(child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Divider(indent: 4, endIndent: 4),
                )),
                Text(train['to_station'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                const SizedBox(width: 6),
                Text(train['arrive_time'] ?? '', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: const Color(0xFFE65100))),
              ],
            ),
            if (seats.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: seats.entries.map<Widget>((e) {
                  final color = seatColors[e.key] ?? Colors.teal;
                  final val = e.value.toString();
                  final canGrab = val == '有票' || (int.tryParse(val) ?? 0) > 0;
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: canGrab ? () => _showGrabSheet(train, e.key) : () => _showAlertSheet(train, e.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: canGrab ? color.withValues(alpha: 0.08) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: canGrab ? color.withValues(alpha: 0.3) : Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: canGrab ? color : Colors.grey.shade400, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Text(e.key, style: TextStyle(color: Colors.grey[800], fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(val, style: TextStyle(color: canGrab ? color : Colors.grey, fontSize: 13, fontWeight: FontWeight.w700)),
                          if (canGrab) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade700,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('抢', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                            ),
                          ] else ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade600,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('提醒', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


class _GrabTicketSheet extends ConsumerStatefulWidget {
  final String trainCode;
  final String fromStation;
  final String toStation;
  final String seatType;
  final String date;
  final String startTime;
  final Dio dio;

  const _GrabTicketSheet({
    required this.trainCode,
    required this.fromStation,
    required this.toStation,
    required this.seatType,
    required this.date,
    required this.startTime,
    required this.dio,
  });

  @override
  ConsumerState<_GrabTicketSheet> createState() => _GrabTicketSheetState();
}

class _GrabTicketSheetState extends ConsumerState<_GrabTicketSheet> {
  int? _selectedAccountId;
  int _quantity = 1;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    ref.read(platformProvider.notifier).loadAccounts();
  }

  Future<void> _create() async {
    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择12306平台账号')));
      return;
    }
    setState(() => _saving = true);

    final saleTime = DateTime.now().add(const Duration(minutes: 1));
    final saleTimeStr = '${saleTime.year}-${saleTime.month.toString().padLeft(2, '0')}-${saleTime.day.toString().padLeft(2, '0')}T${saleTime.hour.toString().padLeft(2, '0')}:${saleTime.minute.toString().padLeft(2, '0')}:00';

    try {
      final task = await ref.read(taskProvider.notifier).createTask({
        'platform_account_id': _selectedAccountId,
        'show_name': '${widget.trainCode} ${widget.fromStation}-${widget.toStation}',
        'show_url': 'https://kyfw.12306.cn/otn/leftTicket/init',
        'target_date': widget.date,
        'sale_time': saleTimeStr,
        'ticket_type': widget.seatType,
        'quantity': _quantity,
        'status': 'monitoring',
      });
      if (mounted) {
        if (task != null) {
          ref.read(taskProvider.notifier).startTask(task.id);
        }
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('抢票任务已创建并启动'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('创建失败'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final platformState = ref.watch(platformProvider);
    final accounts = platformState.accounts.where((a) =>
      a.platform?.name == 'train_12306'
    ).toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            const Icon(Icons.train, color: Color(0xFF1565C0)),
            const SizedBox(width: 8),
            Text(widget.trainCode, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('${widget.fromStation} → ${widget.toStation}', style: const TextStyle(color: Colors.grey, fontSize: 14)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Chip(label: Text(widget.seatType, style: const TextStyle(fontSize: 13))),
            const SizedBox(width: 8),
            Text('${widget.date}  ${widget.startTime}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ]),
          const Divider(height: 20),
          if (accounts.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
              child: const Row(children: [
                Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                SizedBox(width: 8),
                Expanded(child: Text('暂无12306平台账号，请先在"平台账号管理"中添加', style: TextStyle(fontSize: 13))),
              ]),
            ),
          DropdownButtonFormField<int>(
            decoration: const InputDecoration(labelText: '12306账号', border: OutlineInputBorder()),
            value: _selectedAccountId,
            hint: const Text('选择已绑定的12306账号'),
            items: accounts.map((a) => DropdownMenuItem(
              value: a.id,
              child: Text(a.accountLabel.isNotEmpty ? a.accountLabel : a.accountUsername),
            )).toList(),
            onChanged: (v) => setState(() => _selectedAccountId = v),
          ),
          const SizedBox(height: 12),
          Row(children: [
            const Text('购买数量', style: TextStyle(fontSize: 14)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(6)),
              child: Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
            IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: _quantity < 5 ? () => setState(() => _quantity++) : null),
          ]),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saving ? null : _create,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('立即抢票', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}


class _AlertTicketSheet extends ConsumerStatefulWidget {
  final String trainCode;
  final String fromStation;
  final String toStation;
  final String seatType;
  final String date;
  final String startTime;
  final Dio dio;

  const _AlertTicketSheet({
    required this.trainCode,
    required this.fromStation,
    required this.toStation,
    required this.seatType,
    required this.date,
    required this.startTime,
    required this.dio,
  });

  @override
  ConsumerState<_AlertTicketSheet> createState() => _AlertTicketSheetState();
}

class _AlertTicketSheetState extends ConsumerState<_AlertTicketSheet> {
  int? _selectedAccountId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    ref.read(platformProvider.notifier).loadAccounts();
  }

  Future<void> _createAlert() async {
    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择12306平台账号')));
      return;
    }
    setState(() => _saving = true);

    final now = DateTime.now();
    final saleTimeStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}T${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00';

    try {
      await ref.read(taskProvider.notifier).createTask({
        'platform_account_id': _selectedAccountId,
        'show_name': '${widget.trainCode} ${widget.fromStation}-${widget.toStation}',
        'show_url': 'https://kyfw.12306.cn/otn/leftTicket/init',
        'target_date': widget.date,
        'sale_time': saleTimeStr,
        'ticket_type': widget.seatType,
        'quantity': 1,
        'status': 'monitoring',
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('已设置余票提醒，有票时将自动响铃通知'),
          backgroundColor: Colors.blue,
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('设置提醒失败'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final platformState = ref.watch(platformProvider);
    final accounts = platformState.accounts.where((a) =>
      a.platform?.name == 'train_12306'
    ).toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Icon(Icons.notifications_active, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            Text(widget.trainCode, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('${widget.fromStation} → ${widget.toStation}', style: const TextStyle(color: Colors.grey, fontSize: 14)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Chip(
              avatar: Icon(Icons.block, size: 16, color: Colors.red.shade400),
              label: Text('${widget.seatType} 已售罄', style: const TextStyle(fontSize: 13, color: Colors.red)),
            ),
            const SizedBox(width: 8),
            Text('${widget.date}  ${widget.startTime}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ]),
          const Divider(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
            child: const Row(children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text('系统将自动监控该车次余票，有票时立即提醒您', style: TextStyle(fontSize: 13, color: Colors.blue))),
            ]),
          ),
          if (accounts.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
              child: const Row(children: [
                Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                SizedBox(width: 8),
                Expanded(child: Text('暂无12306平台账号，请先在"平台账号管理"中添加', style: TextStyle(fontSize: 13))),
              ]),
            ),
          DropdownButtonFormField<int>(
            decoration: const InputDecoration(labelText: '12306账号', border: OutlineInputBorder()),
            value: _selectedAccountId,
            hint: const Text('选择已绑定的12306账号'),
            items: accounts.map((a) => DropdownMenuItem(
              value: a.id,
              child: Text(a.accountLabel.isNotEmpty ? a.accountLabel : a.accountUsername),
            )).toList(),
            onChanged: (v) => setState(() => _selectedAccountId = v),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _saving ? null : _createAlert,
            icon: const Icon(Icons.notifications_active),
            label: const Text('设置余票提醒', style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}
