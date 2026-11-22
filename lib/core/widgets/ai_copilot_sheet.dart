import 'package:flutter/material.dart';
import '../ai/models/intent_classification_network.dart';
import '../ai/models/rate_prediction_network.dart';
import '../ai/trucklink_ai_service.dart';
import '../constants/vehicle_types.dart';
import '../services/audio_alert_service.dart';
import '../services/speech/native_speech.dart';
import '../theme/colors.dart';
import '../utils/formatters.dart';

class AiCopilotSheet extends StatefulWidget {
  const AiCopilotSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AiCopilotSheet(),
    );
  }

  @override
  State<AiCopilotSheet> createState() => _AiCopilotSheetState();
}

class _AiCopilotSheetState extends State<AiCopilotSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _queryController = TextEditingController();
  bool _isListening = false;

  // Rate Estimator State
  String _origin = 'Lahore';
  String _destination = 'Karachi';
  String _selectedVehicleId = '22_wheeler';
  final double _weightTons = 35.0;
  bool _useMotorway = true;
  RatePredictionResult? _rateResult;

  // Assistant Query Response State
  NlpIntentResult? _lastNlpResult;
  bool _isProcessing = false;

  // Model Training State
  bool _isTraining = false;
  String? _trainingStatus;

  final List<String> _cities = [
    'Lahore', 'Karachi', 'Faisalabad', 'Multan', 'Rawalpindi', 'Islamabad', 'Peshawar', 'Quetta'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _computeRateEstimate();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _queryController.dispose();
    super.dispose();
  }

  void _computeRateEstimate() {
    final res = TruckLinkAiService.instance.predictRate(
      origin: _origin,
      destination: _destination,
      weightTons: _weightTons,
      vehicleType: _selectedVehicleId,
      isMotorway: _useMotorway,
    );
    setState(() {
      _rateResult = res;
    });
  }

  void _handleAsk(String query, bool isUrdu) {
    if (query.trim().isEmpty) return;
    setState(() => _isProcessing = true);

    final nlp = TruckLinkAiService.instance.queryAssistant(query);
    setState(() {
      _lastNlpResult = nlp;
      _isProcessing = false;
    });

    // Speak audio answer
    AudioAlertService().speakWarning(
      text: isUrdu ? nlp.responseUr : nlp.responseEn,
      languageCode: isUrdu ? 'ur' : 'en',
    );
  }

  void _toggleVoiceInput(bool isUrdu) {
    if (_isListening) {
      NativeSpeech.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      NativeSpeech.startListening(
        lang: isUrdu ? 'ur-PK' : 'en-US',
        onResult: (text) {
          _queryController.text = text;
          setState(() => _isListening = false);
          _handleAsk(text, isUrdu);
        },
        onDone: () {
          if (mounted) setState(() => _isListening = false);
        },
      );
    }
  }

  void _runInEngineTraining() async {
    setState(() {
      _isTraining = true;
      _trainingStatus = 'Training PakFreight-Net & LoadMatch-Net on Pakistan corridors...';
    });

    final metrics = await TruckLinkAiService.instance.trainNetwork(epochs: 20);
    setState(() {
      _isTraining = false;
      _trainingStatus = 'Trained ${metrics.totalEpochs} epochs. Final Loss: ${metrics.finalLoss.toStringAsFixed(3)}, MAE: Rs. ${metrics.meanAbsoluteErrorPkr.toStringAsFixed(0)}';
    });
    _computeRateEstimate();
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, spreadRadius: 4)],
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome, color: AppColors.accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isUrdu ? 'ٹرک لنک اے آئی کو پائلٹ' : 'TruckLink AI Co-Pilot',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                      Text(
                        isUrdu ? 'پاکستانی لاجسٹکس نیورل نیٹ ورکس' : 'In-Engine Neural Network Intelligence',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            indicatorColor: AppColors.accent,
            indicatorWeight: 3,
            tabs: [
              Tab(
                icon: const Icon(Icons.record_voice_over_outlined, size: 18),
                text: isUrdu ? 'صوتی معاون' : 'AI Voice Assistant',
              ),
              Tab(
                icon: const Icon(Icons.calculate_outlined, size: 18),
                text: isUrdu ? 'کرایہ تخمینہ' : 'Rate Estimator',
              ),
              Tab(
                icon: const Icon(Icons.memory, size: 18),
                text: isUrdu ? 'ماڈل ٹریننگ' : 'Neural Models',
              ),
            ],
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildVoiceAssistantTab(isUrdu),
                _buildRateEstimatorTab(isUrdu),
                _buildNeuralModelTab(isUrdu),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceAssistantTab(bool isUrdu) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Voice & Text Input Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _queryController,
                        decoration: InputDecoration(
                          hintText: isUrdu ? 'سوال پوچھیں یا مائیک دبائیں...' : 'Ask about freight rates, bridge safety...',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onSubmitted: (q) => _handleAsk(q, isUrdu),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? Colors.red : AppColors.primary,
                      ),
                      onPressed: () => _toggleVoiceInput(isUrdu),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: AppColors.accent),
                      onPressed: () => _handleAsk(_queryController.text, isUrdu),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Quick Prompt Chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildChip(isUrdu ? 'لاہور تا کراچی کرایہ؟' : 'Lahore to Karachi rate?', isUrdu),
              _buildChip(isUrdu ? 'پلوں کی اونچائی محفوظ ہے؟' : 'Are bridge clearances safe?', isUrdu),
              _buildChip(isUrdu ? 'ڈیزل کا خرچہ اور منافع؟' : 'Calculate trip profit margin', isUrdu),
              _buildChip(isUrdu ? 'کراچی میں داخلے کے اوقات؟' : 'Karachi city curfew entry?', isUrdu),
            ],
          ),

          const SizedBox(height: 16),

          // AI Response Card
          if (_isProcessing)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (_lastNlpResult != null)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: AppColors.primary.withValues(alpha: 0.04),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.smart_toy, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          isUrdu ? 'نیورل اے آئی کا جواب' : 'TruckLink Neural AI Response',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${(_lastNlpResult!.confidence * 100).round()}% Confidence',
                            style: const TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Text(
                      isUrdu ? _lastNlpResult!.responseUr : _lastNlpResult!.responseEn,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.volume_up, size: 18),
                        label: Text(isUrdu ? 'دوبارہ سنیں' : 'Replay Voice'),
                        onPressed: () {
                          AudioAlertService().speakWarning(
                            text: isUrdu ? _lastNlpResult!.responseUr : _lastNlpResult!.responseEn,
                            languageCode: isUrdu ? 'ur' : 'en',
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool isUrdu) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.grey.shade100,
      onPressed: () {
        _queryController.text = label;
        _handleAsk(label, isUrdu);
      },
    );
  }

  Widget _buildRateEstimatorTab(bool isUrdu) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Origin / Destination Selectors
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _origin,
                  decoration: InputDecoration(
                    labelText: isUrdu ? 'روانگی' : 'Origin',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _origin = v);
                      _computeRateEstimate();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _destination,
                  decoration: InputDecoration(
                    labelText: isUrdu ? 'منزل' : 'Destination',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _destination = v);
                      _computeRateEstimate();
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Vehicle Type & Weight
          Row(
            children: [
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedVehicleId,
                  decoration: InputDecoration(
                    labelText: isUrdu ? 'گاڑی کی قسم' : 'Vehicle Type',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: VehicleType.all.map((vt) {
                    return DropdownMenuItem(
                      value: vt.id,
                      child: Text(isUrdu ? vt.nameUr : vt.nameEn),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _selectedVehicleId = v);
                      _computeRateEstimate();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_weightTons.toInt()} Tons / ٹن',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Motorway Toggle
          SwitchListTile(
            title: Text(isUrdu ? 'موٹروے بائی پاس استعمال کریں' : 'Prefer Motorway Corridor'),
            value: _useMotorway,
            activeThumbColor: AppColors.primary,
            onChanged: (val) {
              setState(() => _useMotorway = val);
              _computeRateEstimate();
            },
          ),

          const SizedBox(height: 14),

          // Rate Result Card
          if (_rateResult != null)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              color: AppColors.primary,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Text(
                      isUrdu ? 'نیورل فیئر مارکیٹ کرایہ' : 'Predicted Spot Freight Tariff',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppFormatters.formatPkr(_rateResult!.recommendedRatePkr),
                      style: const TextStyle(color: AppColors.accent, fontSize: 28, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      '${AppFormatters.formatPkr(_rateResult!.minRatePkr)} – ${AppFormatters.formatPkr(_rateResult!.maxRatePkr)}',
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                    const Divider(height: 24, color: Colors.white24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricCol(
                          isUrdu ? 'ڈیزل خرچہ' : 'Diesel Cost',
                          AppFormatters.formatPkr(_rateResult!.estimatedDieselCostPkr),
                          Icons.local_gas_station,
                        ),
                        _buildMetricCol(
                          isUrdu ? 'ٹول ٹیکس' : 'Tolls',
                          AppFormatters.formatPkr(_rateResult!.estimatedTollCostPkr),
                          Icons.toll,
                        ),
                        _buildMetricCol(
                          isUrdu ? 'خالص بچت' : 'Driver Profit',
                          AppFormatters.formatPkr(_rateResult!.estimatedNetDriverProfitPkr),
                          Icons.account_balance_wallet,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricCol(String title, String val, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.accent, size: 18),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  Widget _buildNeuralModelTab(bool isUrdu) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isUrdu ? 'آن ڈیوائس نیورل نیٹ ورکس' : 'Bespoke In-Engine Neural Networks',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildModelCard(
            title: 'PakFreight-Net (Tariff Estimator)',
            architecture: '13 Inputs ➔ Dense(32, GELU) ➔ ResidualBlock(32) ➔ Dense(16, ReLU) ➔ Output(3)',
            task: 'Spot rate forecasting, diesel consumption & toll budgeting for all Pakistani corridors.',
          ),
          const SizedBox(height: 10),
          _buildModelCard(
            title: 'LoadMatch-Net (Two-Tower Embedding)',
            architecture: 'Driver Tower (8➔24➔16) + Load Tower (8➔24➔16) ➔ Cosine Affinity Scoring',
            task: 'Evaluates compatibility percentage between driver vehicle capacity and freight demands.',
          ),
          const SizedBox(height: 10),
          _buildModelCard(
            title: 'LogisticsIntent-Net (Urdu & Roman Urdu NLP)',
            architecture: 'Embedding(64, 16) ➔ MeanPooling ➔ Dense(16, Softmax) ➔ 7 Intent Classes',
            task: 'Parses driver voice and text queries in native Pakistani vocabulary and slot entities.',
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: _isTraining
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.play_circle_fill),
            label: Text(
              _isTraining
                  ? (isUrdu ? 'ماڈل ٹریننگ جاری ہے...' : 'Training Neural Weights...')
                  : (isUrdu ? 'نیورل نیٹ ورکس ری ٹرین کریں' : 'Train & Calibrate In-Engine Weights'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: _isTraining ? null : _runInEngineTraining,
          ),
          if (_trainingStatus != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Text(
                _trainingStatus!,
                style: TextStyle(color: Colors.green.shade800, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModelCard({required String title, required String architecture, required String task}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.hub, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const Chip(
                  label: Text('Pure Dart', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(architecture, style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.blueGrey.shade800)),
            const SizedBox(height: 6),
            Text(task, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }
}
