import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../../features/loads/domain/bid_model.dart';
import '../../features/loads/domain/load_model.dart';
import '../../features/route_intelligence/domain/route_models.dart';

class FirebaseService {
  static final FirebaseService instance = FirebaseService._internal();
  factory FirebaseService() => instance;
  FirebaseService._internal();

  /// Reactive live streams without Riverpod
  static Stream<List<LoadModel>> get loadsStream => instance.watchLoads();
  static Stream<List<RoadReport>> get roadReportsStream => instance.watchRoadReports();
  static Stream<List<CityTimingRule>> get cityTimingsStream => instance.watchCityTimings();
  static Stream<List<BidModel>> bidsStream(String loadId) => instance.watchBids(loadId);
  FirebaseFirestore? get firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseAuth? get auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseStorage? get storage {
    try {
      return FirebaseStorage.instance;
    } catch (_) {
      return null;
    }
  }

  static final List<LoadModel> defaultSampleLoads = [
    LoadModel(
      id: 'load-1',
      ownerId: 'own-1',
      originCity: 'Lahore (Badami Bagh)',
      destinationCity: 'Karachi (Port Qasim)',
      vehicleTypeRequired: '22_wheeler',
      weightTons: 35.0,
      heightFt: 15.2,
      goodsType: 'General Cargo',
      offeredRatePkr: 245000,
      contactPhone: '+923001234567',
      createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
    ),
    LoadModel(
      id: 'load-2',
      ownerId: 'own-2',
      originCity: 'Faisalabad (Industrial Area)',
      destinationCity: 'Rawalpindi (I-9 Sector)',
      vehicleTypeRequired: '10_wheeler',
      weightTons: 16.0,
      heightFt: 13.5,
      goodsType: 'Textile Yarn',
      offeredRatePkr: 85000,
      contactPhone: '+923219876543',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    LoadModel(
      id: 'load-3',
      ownerId: 'own-3',
      originCity: 'Multan (Chowk Kumharan)',
      destinationCity: 'Quetta (Eastern Bypass)',
      vehicleTypeRequired: 'container',
      weightTons: 28.0,
      heightFt: 14.8,
      goodsType: 'Agricultural Produce',
      offeredRatePkr: 190000,
      contactPhone: '+923334567890',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    LoadModel(
      id: 'load-4',
      ownerId: 'own-4',
      originCity: 'Karachi (S.I.T.E)',
      destinationCity: 'Peshawar (Hayatabad)',
      vehicleTypeRequired: 'tanker',
      weightTons: 40.0,
      goodsType: 'Industrial Solvents',
      offeredRatePkr: 320000,
      contactPhone: '+923456789012',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  Stream<List<LoadModel>> watchLoads() {
    try {
      final fs = firestore;
      if (fs == null) return Stream.value(defaultSampleLoads);

      return fs
          .collection('loads')
          .orderBy('created_at', descending: true)
          .snapshots()
          .map((snapshot) {
            if (snapshot.docs.isEmpty) {
              return defaultSampleLoads;
            }
            return snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return LoadModel.fromJson(data);
            }).toList();
          })
          .handleError((e) {
            debugPrint('Firestore loads error (fallback to sample data): $e');
            return defaultSampleLoads;
          });
    } catch (e) {
      debugPrint('Firestore watchLoads initialization failed: $e');
      return Stream.value(defaultSampleLoads);
    }
  }

  Future<void> postLoad(LoadModel load) async {
    try {
      final fs = firestore;
      if (fs != null) {
        await fs.collection('loads').add(load.toJson());
      }
    } catch (e) {
      debugPrint('Firestore postLoad failed: $e');
      rethrow;
    }
  }

  Stream<List<BidModel>> watchBids(String loadId) {
    try {
      final fs = firestore;
      if (fs == null) return Stream.value(<BidModel>[]);

      return fs
          .collection('loads')
          .doc(loadId)
          .collection('bids')
          .orderBy('created_at', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return BidModel.fromJson(data);
            }).toList();
          })
          .handleError((e) {
            debugPrint('Firestore watchBids error: $e');
            return <BidModel>[];
          });
    } catch (e) {
      debugPrint('Firestore watchBids init failed: $e');
      return Stream.value(<BidModel>[]);
    }
  }

  Future<void> submitBid(String loadId, BidModel bid) async {
    try {
      final fs = firestore;
      if (fs != null) {
        final docRef = await fs
            .collection('loads')
            .doc(loadId)
            .collection('bids')
            .add(bid.toJson());
        
        await fs.collection('loads').doc(loadId).update({
          'bids_count': FieldValue.increment(1),
          'status': 'bidding',
        });
        debugPrint('Bid submitted successfully with ID: ${docRef.id}');

        // Dispatch notification to load owner
        try {
          final loadDoc = await fs.collection('loads').doc(loadId).get();
          final ownerId = loadDoc.data()?['owner_id'] ?? loadDoc.data()?['ownerId'] ?? 'owner-all';
          await createNotification(
            recipientId: ownerId,
            title: 'New Bid: PKR ${bid.proposedRatePkr}',
            body: '${bid.driverName} submitted a counter-offer for load',
            type: 'new_bid',
            loadId: loadId,
          );
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Firestore submitBid failed: $e');
      rethrow;
    }
  }

  Future<void> acceptBid({
    required String loadId,
    required String bidId,
    required String driverId,
  }) async {
    try {
      final fs = firestore;
      if (fs != null) {
        await fs
            .collection('loads')
            .doc(loadId)
            .collection('bids')
            .doc(bidId)
            .update({'status': 'accepted'});

        await fs.collection('loads').doc(loadId).update({
          'status': 'assigned',
          'assigned_driver_id': driverId,
        });

        // Dispatch notification to assigned driver
        await createNotification(
          recipientId: driverId,
          title: 'Bid Accepted / بولی منظور ہو گئی!',
          body: 'Your bid on load #$loadId was accepted! Prepare for pickup.',
          type: 'bid_accepted',
          loadId: loadId,
        );
      }
    } catch (e) {
      debugPrint('Firestore acceptBid failed: $e');
      rethrow;
    }
  }

  Future<void> updateLoadStatus(String loadId, String newStatus) async {
    try {
      final fs = firestore;
      if (fs != null) {
        await fs.collection('loads').doc(loadId).update({
          'status': newStatus,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Firestore updateLoadStatus failed: $e');
      rethrow;
    }
  }

  Future<String> uploadDriverDocument({
    required String uid,
    required String docType, // 'cnic', 'license', 'registration'
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    try {
      final st = storage;
      final fs = firestore;
      if (st == null || fs == null) {
        return 'https://storage.googleapis.com/demo/$fileName';
      }

      final storageRef = st.ref().child('driver_docs/$uid/$docType-$fileName');
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final uploadTask = await storageRef.putData(fileBytes, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      final fieldName = '${docType}_url';
      await fs.collection('profiles').doc(uid).set({
        fieldName: downloadUrl,
        'verification_status': 'pending',
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await fs.collection('users').doc(uid).set({
        fieldName: downloadUrl,
        'verificationStatus': 'pending',
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return downloadUrl;
    } catch (e) {
      debugPrint('Firebase Storage upload error: $e');
      rethrow;
    }
  }

  Stream<List<RoadReport>> watchRoadReports() {
    try {
      final fs = firestore;
      if (fs == null) return Stream.value(<RoadReport>[]);

      return fs
          .collection('hazard_reports')
          .orderBy('created_at', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              final data = doc.data();
              final loc = data['location'] as String?;
              final desc = data['description'] as String?;
              final combined = (loc != null && loc.isNotEmpty)
                  ? (desc != null && desc.isNotEmpty ? '$loc — $desc' : loc)
                  : desc;
              return RoadReport(
                id: doc.id,
                reporterId: data['reported_by'] ?? data['reporter_id'] ?? 'unknown',
                reportType: data['category_id'] ?? data['report_type'] ?? 'broken',
                description: combined,
                confidence: (data['confidence'] as num?)?.toDouble() ?? 0.9,
                createdAt: data['created_at'] != null
                    ? (data['created_at'] is Timestamp
                        ? (data['created_at'] as Timestamp).toDate()
                        : (DateTime.tryParse(data['created_at'].toString()) ?? DateTime.now()))
                    : DateTime.now(),
              );
            }).toList();
          })
          .handleError((e) {
            debugPrint('Firestore road reports error: $e');
            return <RoadReport>[];
          });
    } catch (e) {
      return Stream.value(<RoadReport>[]);
    }
  }

  Stream<List<CityTimingRule>> watchCityTimings() {
    try {
      final fs = firestore;
      if (fs == null) return Stream.value(<CityTimingRule>[]);

      return fs
          .collection('city_timings')
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              final data = doc.data();
              return CityTimingRule(
                id: doc.id,
                cityName: data['city_name'] ?? data['cityName'] ?? doc.id,
                vehicleCategory: data['vehicle_category'] ?? data['vehicleCategory'] ?? 'heavy',
                entryFrom: data['entry_from'] ?? data['entryFrom'] ?? '23:00',
                entryUntil: data['entry_until'] ?? data['entryUntil'] ?? '05:00',
                notes: data['notes'] ?? '',
                confidence: (data['confidence'] as num?)?.toDouble() ?? 0.95,
              );
            }).toList();
          })
          .handleError((e) {
            debugPrint('Firestore city_timings error: $e');
            return <CityTimingRule>[];
          });
    } catch (e) {
      return Stream.value(<CityTimingRule>[]);
    }
  }

  Future<void> saveUserFcmToken(String uid, String token) async {
    try {
      final fs = firestore;
      if (fs != null) {
        // Save in users/{uid}
        await fs.collection('users').doc(uid).set({
          'fcmTokens': FieldValue.arrayUnion([token]),
          'notificationsEnabled': true,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Save in profiles/{uid}
        await fs.collection('profiles').doc(uid).set({
          'fcm_tokens': FieldValue.arrayUnion([token]),
          'notifications_enabled': true,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        debugPrint('[FCM] Token synced to Firestore for user $uid');
      }
    } catch (e) {
      debugPrint('Firestore saveUserFcmToken failed: $e');
    }
  }

  Future<void> createNotification({
    required String recipientId,
    required String title,
    required String body,
    required String type, // 'new_bid', 'bid_accepted', 'hazard_alert', 'bridge_alert'
    String? loadId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final fs = firestore;
      if (fs != null) {
        await fs.collection('notifications').add({
          'recipientId': recipientId,
          'title': title,
          'body': body,
          'type': type,
          'loadId': loadId,
          'metadata': metadata,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
        debugPrint('[Notification Queue] Dispatched notification to $recipientId: $title');
      }
    } catch (e) {
      debugPrint('Firestore createNotification failed: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> watchUserNotifications(String uid) {
    try {
      final fs = firestore;
      if (fs == null) return Stream.value(<Map<String, dynamic>>[]);

      return fs
          .collection('notifications')
          .where('recipientId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return data;
              }).toList())
          .handleError((e) {
            debugPrint('Firestore watchUserNotifications error: $e');
            return <Map<String, dynamic>>[];
          });
    } catch (e) {
      return Stream.value(<Map<String, dynamic>>[]);
    }
  }

  Future<void> markNotificationAsRead(String notifId) async {
    try {
      final fs = firestore;
      if (fs != null) {
        await fs.collection('notifications').doc(notifId).update({'read': true});
      }
    } catch (e) {
      debugPrint('Firestore markNotificationAsRead failed: $e');
    }
  }

  Future<void> reportHazard({
    required String categoryId,
    required String location,
    required String description,
  }) async {
    try {
      final fs = firestore;
      if (fs != null) {
        await fs.collection('hazard_reports').add({
          'category_id': categoryId,
          'report_type': categoryId,
          'location': location,
          'description': description,
          'created_at': DateTime.now().toIso8601String(),
          'reported_by': auth?.currentUser?.uid ?? 'anonymous',
        });

        // Broadcast to notifications queue
        await createNotification(
          recipientId: 'broadcast',
          title: 'Road Alert: $location',
          body: '$categoryId hazard reported: $description',
          type: 'hazard_alert',
        );
      }
    } catch (e) {
      debugPrint('Firestore reportHazard failed: $e');
      rethrow;
    }
  }
}
